#pragma semicolon 1

#include <ce_coordinator>
#include <ce_util>
#include <ccc>

bool g_bCCC = false;
bool g_bCreators = false;

public Plugin myinfo =
{
	name = "Custom Chat Colors Patreon Module",
	author = "Creators.TF Team",
	description = "Adds chat tags to players who are a Creators.TF patron.",
	version = "1.0",
	url = "https://creators.tf"
};

public void OnPluginStart()
{
	AddCommandListener(Cmd_ReloadCCC, "sm_reloadccc");

	ApplyTags();
}

public Action Cmd_ReloadCCC(int client, const char[] command, int argc)
{
	ApplyTags();
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "ccc"))
	{
		g_bCCC = true;
	}
	if (StrEqual(name, "ce_coordinator"))
	{
		g_bCCC = true;
	}
	if(g_bCCC && g_bCreators)
	{
		ApplyTags();
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "ccc")) g_bCCC = false;
	if (StrEqual(name, "ce_coordinator")) g_bCreators = false;
}

public void OnClientPostAdminCheck(int client)
{
	if ((!IsClientInGame(client) || IsFakeClient(client)) || GetUserAdmin(client) != INVALID_ADMIN_ID) return;
	ApplyTags(client);
}

void ApplyTags(int client = 0)
{
	if (client == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetUserAdmin(i) == INVALID_ADMIN_ID)
			{
				ApplyTagsClient(i);
			}
		}
	}
	else
	{
		ApplyTagsClient(client);
	}
}

public void ApplyTagsClient(int client)
{
	char sSteamID[PLATFORM_MAX_PATH];
	GetClientAuthId(client, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	char sURL[128];
	Format(sURL, sizeof(sURL), "/api/IDonations/GUserDonations?steamid=%s", sSteamID);
	
	CESC_SendAPIRequest(sURL, RequestType_GET, httpPlayerDonation, client, _, _, client);
}

public void httpPlayerDonation(const char[] content, int size, int status, any client)
{
	if (!IsClientReady(client))return;
	
	if(status == StatusCode_Success)
	{
		KeyValues kv = new KeyValues("Response");
		kv.ImportFromString(content);
		
		int centsAmount = kv.GetNum("amount");
		delete kv;
		
		char tag[32], color[32];

		if (centsAmount >= 200 && centsAmount < 500)
		{
			Format(tag, sizeof(tag), "Patreon Tier I | ");
			Format(color, sizeof(color), "f0cca5");
		}
		else if (centsAmount >= 500 && centsAmount < 1000)
		{
			Format(tag, sizeof(tag), "Patreon Tier II | ");
			Format(color, sizeof(color), "e8af72");
		}
		else if (centsAmount >= 1000)
		{
			Format(tag, sizeof(tag), "Patreon Tier III | ");
			Format(color, sizeof(color), "e38a2b");
		}

		if (g_bCCC)
		{
			CCC_SetTag(client, tag);
			CCC_SetColor(client, CCC_TagColor, StringToInt(color, 16), false);
		}
		else
		{
			LogError("Custom-ChatColors was not detected, therefore patreon tags cannot be set.");
		}
	}
}