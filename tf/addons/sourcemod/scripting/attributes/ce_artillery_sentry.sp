#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cecon>
#include <cecon_items>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[Creators.TF] Artillery Sentry Attribute",
	author = "Creators.TF Team",
	description = "Functionality for a custom sentry gun.",
	version = "1.0",
	url = "https://creators.tf"
};

public void OnPluginStart()
{

}

public void OnEntityCreated(int entity, const char[] classname)
{
	// Hook the entity creation of this new sentry gun.
	if (StrEqual(classname, "obj_sentrygun"))
	{
		SDKHook(entity, SDKHook_Spawn, Sentry_OnSpawn);
	}
}

public Action Sentry_OnSpawn(int entity)
{
	// Grab the owner of this sentry gun so we can grab their weapon:
	int iBuilder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	char temp_debug_name_shhh[MAX_NAME_LENGTH];
	
	GetClientName(iBuilder, temp_debug_name_shhh, sizeof(temp_debug_name_shhh));
	PrintToChatAll("%s", temp_debug_name_shhh);
	
	if (IsClientValid(iBuilder) && TF2_GetPlayerClass(iBuilder) == TFClass_Engineer)
	{
		// Grab their PDA weapon which is in slot 3:
		int iWeapon = GetPlayerWeaponSlot(entity, 3);
		
		// Does this weapon have the "sentry gun override" attribute?
		if (CEconItems_GetEntityAttributeInteger(iWeapon, "sentry gun override") == 2)
		{
			PrintToChat(iBuilder, "Artillery Sentry!");
		}
	}
}

public bool IsClientReady(int client)
{
	if (!IsClientValid(client))return false;
	if (IsFakeClient(client))return false;
	return true;
}

public bool IsClientValid(int client)
{
	if (client <= 0 || client > MaxClients)return false;
	if (!IsClientInGame(client))return false;
	if (!IsClientAuthorized(client))return false;
	return true;
}