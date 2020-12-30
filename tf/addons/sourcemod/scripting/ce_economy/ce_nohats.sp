#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <ce_manager_items>
#include <morecolors>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required


bool bHatsOff[MAXPLAYERS+1];
Handle ctfHatsCookie;

public Plugin myinfo =
{
    name        = "CreatorsTF Hat Removal",
    author      = "Jaro 'Monkeys' Vanderheijden, steph&",
    description = "Gives players the choice to locally toggle CreatorsTF hat visibility",
    version     = "0.0.5",
    url         = ""
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_noctfhats", 		ToggleCTFHat, "Locally toggles CreatorsTF custom cosmetic visibility");
    RegConsoleCmd("sm_togglectfhats", 	ToggleCTFHat, "Locally toggles CreatorsTF custom cosmetic visibility");
    RegConsoleCmd("sm_togglehats", 		ToggleCTFHat, "Locally toggles CreatorsTF custom cosmetic visibility");
    RegConsoleCmd("sm_ctfhats", 		ToggleCTFHat, "Locally toggles CreatorsTF custom cosmetic visibility");

    ctfHatsCookie = RegClientCookie("ctfHatsTransmitCookie", "Cookie for determining if CTF hats are transmitted to player or not", CookieAccess_Protected);
}

public void OnClientCookiesCached(int client)
{
    char sValue[8];
    // Gets stored value for specific client and stores in sValue
    GetClientCookie(client, ctfHatsCookie, sValue, sizeof(sValue));
    // If the string is null, it'll be set to true - we want hats defaulted on
    if (!sValue[0])
    {
        SetClientCookie(client, ctfHatsCookie, "1");
        sValue = "1";
        // convert cookie value to string
        bHatsOff[client] = (StringToInt(sValue) != 0);
        // save to cookie
        SetClientCookie(client, ctfHatsCookie, sValue);
    }
    else
    {
        // convert cookie value to string
        bHatsOff[client] = (StringToInt(sValue) != 0);
    }
}

public Action ToggleCTFHat(int client, int args)
{
    // toggle
    bHatsOff[client] = !bHatsOff[client];

    if (bHatsOff[client])
    {
        MC_PrintToChatEx(client, client, "[{creators}Creators.TF{default}] Toggled Creators.TF custom cosmetics {red}OFF{default}! Be warned, this may cause invisible heads or feet on some cosmetics!", client);
    }
    else
    {
        MC_PrintToChatEx(client, client, "[{creators}Creators.TF{default}] Toggled Creators.TF custom cosmetics {green}ON{default}!", client);
    }

    if (AreClientCookiesCached(client))
    {
        char sValue[8];
        GetClientCookie(client, ctfHatsCookie, sValue, sizeof(sValue));
        // convert cookie value to string
        IntToString(bHatsOff[client], sValue, sizeof(sValue));
        // save to cookie
        SetClientCookie(client, ctfHatsCookie, sValue);
    }

    return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
    bHatsOff[client] = false;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrEqual(classname, "tf_wearable"))
    {
        CreateTimer(0.1, timerHookDelay, entity);
    }
}

public Action timerHookDelay(Handle Timer, int entity)
{
    if (IsValidEdict(entity) && IsValidEntity(entity))
    {
        char sClass[32];
        GetEntityNetClass(entity, sClass, sizeof(sClass));
        if (StrContains(sClass, "CTFWearable") != -1)
        {
            if (CE_IsEntityCustomEcomItem(entity))
            {
                SDKHook(entity, SDKHook_SetTransmit, SetTransmitHat);
            }
        }
    }
}

public Action SetTransmitHat(int entity, int client)
{
    //Transmit when plugin's off OR if the player didn't turn it on
    if (!bHatsOff[client])
    {
        return Plugin_Continue;
    }
    else
    {
        return Plugin_Handled;
    }
}