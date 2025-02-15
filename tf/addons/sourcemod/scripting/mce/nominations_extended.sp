
#include <sourcemod>
#include <mapchooser>
#include <mapchooser_extended>
#include <colors>
#include <prettymap>
#pragma semicolon 1

#define MCE_VERSION "1.10.4"

public Plugin:myinfo =
{
	name            = "Map Nominations Extended",
	author          = "Powerlord and AlliedModders LLC",
	description     = "Provides Map Nominations",
	version         = MCE_VERSION,
	url             = "https://forums.alliedmods.net/showthread.php?t=156974"
};

new Handle:g_Cvar_ExcludeOld = INVALID_HANDLE;
new Handle:g_Cvar_ExcludeCurrent = INVALID_HANDLE;

new Handle:g_MapList = INVALID_HANDLE;
new Handle:g_MapMenu = INVALID_HANDLE;
new g_mapFileSerial = -1;

#define MAPSTATUS_ENABLED (1<<0)
#define MAPSTATUS_DISABLED (1<<1)
#define MAPSTATUS_EXCLUDE_CURRENT (1<<2)
#define MAPSTATUS_EXCLUDE_PREVIOUS (1<<3)
#define MAPSTATUS_EXCLUDE_NOMINATED (1<<4)

new Handle:g_mapTrie;

// Nominations Extended Convars
new Handle:g_Cvar_MarkCustomMaps = INVALID_HANDLE;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("nominations.phrases");
	LoadTranslations("basetriggers.phrases"); // for Next Map phrase
	LoadTranslations("mapchooser_extended.phrases");

	new arraySize = ByteCountToCells(PLATFORM_MAX_PATH);
	g_MapList = CreateArray(arraySize);

	g_Cvar_ExcludeOld = CreateConVar("sm_nominate_excludeold", "1", "Specifies if the current map should be excluded from the Nominations list", 0, true, 0.00, true, 1.0);
	g_Cvar_ExcludeCurrent = CreateConVar("sm_nominate_excludecurrent", "1", "Specifies if the MapChooser excluded maps should also be excluded from Nominations", 0, true, 0.00, true, 1.0);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	RegConsoleCmd("sm_nominate", Command_Nominate);

	RegAdminCmd("sm_nominate_addmap", Command_Addmap, ADMFLAG_CHANGEMAP, "sm_nominate_addmap <mapname> - Forces a map to be on the next mapvote.");

	// Nominations Extended cvars
	CreateConVar("ne_version", MCE_VERSION, "Nominations Extended Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);


	g_mapTrie = CreateTrie();
}

public OnAllPluginsLoaded()
{
	// This is an MCE cvar... this plugin requires MCE to be loaded.  Granted, this plugin SHOULD have an MCE dependency.
	g_Cvar_MarkCustomMaps = FindConVar("mce_markcustommaps");
}

public OnConfigsExecuted()
{
	if (ReadMapList(g_MapList,
					g_mapFileSerial,
					"nominations",
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		== INVALID_HANDLE)
	{
		if (g_mapFileSerial == -1)
		{
			SetFailState("Unable to create a valid map list.");
		}
	}

	BuildMapMenu();
}

public OnNominationRemoved(const String:map[], owner)
{
	new status;

	char resolvedMap[PLATFORM_MAX_PATH];
	FindMap(map, resolvedMap, sizeof(resolvedMap));

	/* Is the map in our list? */
	if (!GetTrieValue(g_mapTrie, resolvedMap, status))
	{
		return;
	}

	/* Was the map disabled due to being nominated */
	if ((status & MAPSTATUS_EXCLUDE_NOMINATED) != MAPSTATUS_EXCLUDE_NOMINATED)
	{
		return;
	}

	SetTrieValue(g_mapTrie, resolvedMap, MAPSTATUS_ENABLED);
}

public Action:Command_Addmap(client, args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "[NE] Usage: sm_nominate_addmap <mapname>");
		return Plugin_Handled;
	}

	char mapname[PLATFORM_MAX_PATH];
	char resolvedMap[PLATFORM_MAX_PATH];
	GetCmdArg(1, mapname, sizeof(mapname));

	if (FindMap(mapname, resolvedMap, sizeof(resolvedMap)) == FindMap_NotFound)
	{
		// We couldn't resolve the map entry to a filename, so...
		ReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;
	}

	char displayName[PLATFORM_MAX_PATH];
	GetMapDisplayName(resolvedMap, displayName, sizeof(displayName));

	new status;
	if (!GetTrieValue(g_mapTrie, resolvedMap, status))
	{
		CReplyToCommand(client, "%t", "Map was not found", displayName);
		return Plugin_Handled;
	}

	new NominateResult:result = NominateMap(resolvedMap, true, 0);

	if (result > Nominate_Replaced)
	{
		/* We assume already in vote is the casue because the maplist does a Map Validity check and we forced, so it can't be full */
		CReplyToCommand(client, "%t", "Map Already In Vote", displayName);

		return Plugin_Handled;
	}


	SetTrieValue(g_mapTrie, resolvedMap, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);


	CReplyToCommand(client, "%t", "Map Inserted", displayName);
	LogAction(client, -1, "\"%L\" inserted map \"%s\".", client, mapname);

	return Plugin_Handled;
}

public Action:Command_Say(client, args)
{
	if (!client)
	{
		return Plugin_Continue;
	}

	char text[192];
	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}

	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);

	if (strcmp(text[startidx], "nominate", false) == 0)
	{
		if (IsNominateAllowed(client))
		{
			AttemptNominate(client);
		}
	}

	SetCmdReplySource(old);

	return Plugin_Continue;
}

public Action:Command_Nominate(client, args)
{
	if (!client || !IsNominateAllowed(client))
	{
		return Plugin_Handled;
	}

	if (args == 0)
	{
		AttemptNominate(client);
		return Plugin_Handled;
	}

	char mapname[PLATFORM_MAX_PATH];
	char arg1[PLATFORM_MAX_PATH];
	char displayName[PLATFORM_MAX_PATH];
	GetCmdArg(1, arg1, sizeof(arg1));

	new status;

	// This breaks with event maps.
	/*
	if (FindMap(arg1, mapname, sizeof(mapname)) == FindMap_NotFound)
	{
		CReplyToCommand(client, "%t", "Map was not found", mapname);
		return Plugin_Handled;
	}
	*/

	//----------------------------------------------------------//
	// This is a fix to the problem above,
	//----------------------------------------------------------//
	bool bFound = false;
	char sNeedle[PLATFORM_MAX_PATH];
	for (int i = 0; i < GetArraySize(g_MapList); i++)
	{
		GetArrayString(g_MapList, i, sNeedle, sizeof(sNeedle));
		GetMapDisplayName(sNeedle, displayName, sizeof displayName);
		if (StrContains(displayName, arg1) != -1)
		{
			if (FindMap(sNeedle, mapname, sizeof(mapname)) != FindMap_NotFound)
			{
				bFound = true;
				break;
			}
		}
	}
	if(!bFound)
	{
		CReplyToCommand(client, "[NE] %t", "Map was not found", arg1);
		return Plugin_Handled;
	}
	//----------------------------------------------------------//

	GetPrettyMapName(displayName, displayName, sizeof displayName);

	if (!GetTrieValue(g_mapTrie, mapname, status))
	{
		CReplyToCommand(client, "[NE] %t", "Map was not found", displayName);
		return Plugin_Handled;
	}

	if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
	{
		if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
		{
			CReplyToCommand(client, "[NE] %t", "Can't Nominate Current Map");
		}

		if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
		{
			CReplyToCommand(client, "[NE] %t", "Map in Exclude List");
		}

		if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
		{
			CReplyToCommand(client, "[NE] %t", "Map Already Nominated");
		}

		return Plugin_Handled;
	}

	new NominateResult:result = NominateMap(mapname, false, client);

	if (result > Nominate_Replaced)
	{
		if (result == Nominate_AlreadyInVote)
		{
			CReplyToCommand(client, "%t", "Map Already In Vote", displayName);
		}
		else
		{
			CReplyToCommand(client, "[NE] %t", "Map Already Nominated");
		}

		return Plugin_Handled;
	}

	/* Map was nominated! - Disable the menu item and update the trie */

	SetTrieValue(g_mapTrie, mapname, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	PrintToChatAll("[NE] %t", "Map Nominated", name, displayName);
	LogMessage("%s nominated %s", name, mapname);

	return Plugin_Continue;
}

AttemptNominate(client)
{
	SetMenuTitle(g_MapMenu, "%T", "Nominate Title", client);
	DisplayMenu(g_MapMenu, client, 80);

	return;
}

BuildMapMenu()
{
	if (g_MapMenu != INVALID_HANDLE)
	{
		CloseHandle(g_MapMenu);
		g_MapMenu = INVALID_HANDLE;
	}

	ClearTrie(g_mapTrie);

	g_MapMenu = CreateMenu(Handler_MapSelectMenu, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem);

	char map[PLATFORM_MAX_PATH];

	ArrayList excludeMaps;
	char currentMap[32];

	if (GetConVarBool(g_Cvar_ExcludeOld))
	{
		excludeMaps = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
		GetExcludeMapList(excludeMaps);
	}

	if (GetConVarBool(g_Cvar_ExcludeCurrent))
	{
		GetCurrentMap(currentMap, sizeof(currentMap));
	}


	for (new i = 0; i < GetArraySize(g_MapList); i++)
	{
		new status = MAPSTATUS_ENABLED;

		GetArrayString(g_MapList, i, map, sizeof(map));

		FindMap(map, map, sizeof(map));

		char displayName[PLATFORM_MAX_PATH];
		GetMapDisplayName(map, displayName, sizeof(displayName));

		if (GetConVarBool(g_Cvar_ExcludeCurrent))
		{
			if (StrEqual(map, currentMap))
			{
				status = MAPSTATUS_DISABLED | MAPSTATUS_EXCLUDE_CURRENT;
			}
		}

		/* Dont bother with this check if the current map check passed */
		if (GetConVarBool(g_Cvar_ExcludeOld) && status == MAPSTATUS_ENABLED)
		{
			if (FindStringInArray(excludeMaps, map) != -1)
			{
				status = MAPSTATUS_DISABLED | MAPSTATUS_EXCLUDE_PREVIOUS;
			}
		}

		char sPrettyName[128];
		GetPrettyMapName(displayName, sPrettyName, sizeof(sPrettyName));

		AddMenuItem(g_MapMenu, map, sPrettyName);
		SetTrieValue(g_mapTrie, map, status);
	}

	SetMenuExitButton(g_MapMenu, true);

	if (excludeMaps != INVALID_HANDLE)
	{
		CloseHandle(excludeMaps);
	}
}

public Handler_MapSelectMenu(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char map[PLATFORM_MAX_PATH];
			char name[MAX_NAME_LENGTH];
			char sDisplay[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, map, sizeof(map), _, sDisplay, sizeof(sDisplay));

			FindMap(map, map, sizeof map);

			GetClientName(param1, name, MAX_NAME_LENGTH);

			new NominateResult:result = NominateMap(map, false, param1);

			/* Don't need to check for InvalidMap because the menu did that already */
			if (result == Nominate_AlreadyInVote)
			{
				PrintToChat(param1, "[NE] %t", "Map Already Nominated");
				return 0;
			}
			else if (result == Nominate_VoteFull)
			{
				PrintToChat(param1, "[NE] %t", "Max Nominations");
				return 0;
			}

			SetTrieValue(g_mapTrie, map, MAPSTATUS_DISABLED|MAPSTATUS_EXCLUDE_NOMINATED);

			if (result == Nominate_Replaced)
			{
				PrintToChatAll("[NE] %t", "Map Nomination Changed", name, sDisplay);
				return 0;
			}

			PrintToChatAll("[NE] %t", "Map Nominated", name, sDisplay);
			LogMessage("%s nominated %s", name, map);
		}

		case MenuAction_DrawItem:
		{
			char map[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, map, sizeof(map));

			new status;

			if (!GetTrieValue(g_mapTrie, map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return ITEMDRAW_DEFAULT;
			}

			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				return ITEMDRAW_DISABLED;
			}

			return ITEMDRAW_DEFAULT;

		}

		case MenuAction_DisplayItem:
		{
			char map[PLATFORM_MAX_PATH];
			char sDisplay[PLATFORM_MAX_PATH];
			GetMenuItem(menu, param2, map, sizeof(map), _, sDisplay, sizeof(sDisplay));

			new mark = GetConVarInt(g_Cvar_MarkCustomMaps);
			new bool:official;

			new status;

			if (!GetTrieValue(g_mapTrie, map, status))
			{
				LogError("Menu selection of item not in trie. Major logic problem somewhere.");
				return 0;
			}

			char buffer[100];
			char display[150];

			if (mark)
			{
				// They're all official.
				official = true;

				//official = IsMapOfficial(map);
			}

			if (mark && !official)
			{
				switch (mark)
				{
					case 1:
					{
						Format(buffer, sizeof(buffer), "%T", "Custom Marked", param1, map);
					}

					case 2:
					{
						Format(buffer, sizeof(buffer), "%T", "Custom", param1, map);
					}
				}
			}
			else
			{
				strcopy(buffer, sizeof(buffer), map);
			}

			if ((status & MAPSTATUS_DISABLED) == MAPSTATUS_DISABLED)
			{
				if ((status & MAPSTATUS_EXCLUDE_CURRENT) == MAPSTATUS_EXCLUDE_CURRENT)
				{
					Format(display, sizeof(display), "%s (%T)", sDisplay, "Current Map", param1);
					return RedrawMenuItem(display);
				}

				if ((status & MAPSTATUS_EXCLUDE_PREVIOUS) == MAPSTATUS_EXCLUDE_PREVIOUS)
				{
					Format(display, sizeof(display), "%s (%T)", sDisplay, "Recently Played", param1);
					return RedrawMenuItem(display);
				}

				if ((status & MAPSTATUS_EXCLUDE_NOMINATED) == MAPSTATUS_EXCLUDE_NOMINATED)
				{
					Format(display, sizeof(display), "%s (%T)", sDisplay, "Nominated", param1);
					return RedrawMenuItem(display);
				}
			}

			if (mark && !official)
				return RedrawMenuItem(buffer);

			return 0;
		}
	}

	return 0;
}

stock bool:IsNominateAllowed(client)
{
	new CanNominateResult:result = CanNominate();

	switch(result)
	{
		case CanNominate_No_VoteInProgress:
		{
			CReplyToCommand(client, "[ME] %t", "Nextmap Voting Started");
			return false;
		}

		case CanNominate_No_VoteComplete:
		{
			new String:map[PLATFORM_MAX_PATH];
			GetNextMap(map, sizeof(map));
			GetMapDisplayName(map, map, sizeof map);
			GetPrettyMapName(map, map, sizeof map);
			CReplyToCommand(client, "[NE] %t", "Next Map", map);
			return false;
		}

		case CanNominate_No_VoteFull:
		{
			CReplyToCommand(client, "[ME] %t", "Max Nominations");
			return false;
		}
	}

	return true;
}
