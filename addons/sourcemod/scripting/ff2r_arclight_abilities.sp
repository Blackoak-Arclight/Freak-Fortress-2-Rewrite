#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
//#include <dhooks>
#include <tf_econ_data>
#include <tf_econ_dynamic>
#include <cfgmap>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <ff2r>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION	"Custom"

#define MAXTF2PLAYERS	MAXPLAYERS+1
#define FAR_FUTURE	100000000.0
#define MAXENTITIES	2048

#define TFTeam_Unassigned	0
#define TFTeam_Spectator	1
#define TFTeam_Red		2
#define TFTeam_Blue		3
#define TFTeam_MAX		4

int PlayersAlive[4];
bool SpecTeam;
char KillIcon[64];
char KillName[64];

ArrayList BossTimers[MAXTF2PLAYERS];

ConVar CvarFriendlyFire;

#include "freak_fortress_2/econdata.sp"
#include "freak_fortress_2/formula_parser.sp"
#include "freak_fortress_2/subplugin.sp"
#include "freak_fortress_2/tf2attributes.sp"
#include "freak_fortress_2/tf2items.sp"
#include "freak_fortress_2/tf2utils.sp"
#include "freak_fortress_2/vscript.sp"

#include "arclight_abilities/stocks.sp"
#include "arclight_abilities/customattrib.sp"
//#include "arclight_abilities/custommelee.sp"
//#include "arclight_abilities/dhooks.sp"
#include "arclight_abilities/sdkcalls.sp"
#include "arclight_abilities/sdkhooks.sp"

#include "arclight_abilities/weapons/goomba.sp"

#include "arclight_abilities/bosses/announcer.sp"
#include "arclight_abilities/bosses/captain_kinky.sp"
#include "arclight_abilities/bosses/heffe.sp"
#include "arclight_abilities/bosses/hhh.sp"
#include "arclight_abilities/bosses/improved_saxton.sp"
#include "arclight_abilities/bosses/phatrages.sp"
#include "arclight_abilities/bosses/pyromancer.sp"
#include "arclight_abilities/bosses/rock.sp"
#include "arclight_abilities/bosses/sarysamods9.sp"
#include "arclight_abilities/bosses/sarysapub1.sp"
#include "arclight_abilities/bosses/spellbook.sp"
#include "arclight_abilities/bosses/vagineer.sp"

public Plugin myinfo =
{
	name		=	"Freak Fortress 2: Rewrite - Arclight Abilities",
	author		=	"arclight.tf",
	description	=	"vsh suggestions",
	version		=	PLUGIN_VERSION,
	url		=	"arclight.tf"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	// FF2 Files
	Attrib_PluginLoad();
	Goomba_PluginLoad();
	TF2Items_PluginLoad();
	TF2U_PluginLoad();
	TFED_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	CvarFriendlyFire = FindConVar("mp_friendlyfire");

	HookEvent("player_builtobject", OnBuiltObject);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("deploy_buff_banner", OnDeployBanner);
	HookEvent("object_deflected", OnObjectDeflected);
	
	// FF2 Files
	Attrib_PluginStart();
	TF2U_PluginStart();
	TFED_PluginStart();
	VScript_PluginStart();

	// Arclight Files
	//DHooks_PluginStart();
	SDKCalls_PluginStart();
	SDKHook_PluginStart();
	Sarysapub1_PluginStart();
	Saxton_PluginStart();

	// Subplugin Last
	Subplugin_PluginStart();
}

public void OnAllPluginsLoaded()
{
	CustomAttrib_AllPluginsLoaded();
}

void FF2R_PluginLoaded()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPutInServer(client);
			
			BossData cfg = FF2R_GetBossData(client);
			if(cfg)
			{
				FF2R_OnBossCreated(client, cfg, false);
				FF2R_OnBossEquipped(client, true);
			}
		}
	}
}

public void OnPluginEnd()
{
	//CustomMelee_PluginEnd();
	Sarysapub1_PluginEnd();
	OnMapEnd();
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
			if(Subplugin_Enabled() && FF2R_GetBossData(client))
				FF2R_OnBossRemoved(client);
		}
	}
}

public void OnMapStart()
{
	//CustomMelee_MapStart();
	Goomba_MapStart();
	Heffe_MapStart();
	PhatRages_MapStart();
	Saxton_MapStart();
}

public void OnMapEnd()
{
	
}

public void OnLibraryAdded(const char[] name)
{
	Attrib_LibraryAdded(name);
	SDKHook_LibraryAdded(name);
	Subplugin_LibraryAdded(name);
	TF2U_LibraryAdded(name);
	TFED_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	Attrib_LibraryRemoved(name);
	SDKHook_LibraryRemoved(name);
	Subplugin_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
	TFED_LibraryRemoved(name);
}

public void OnClientPutInServer(int client)
{
	SDKHooks_PutInServer(client);
}

public void OnClientDisconnect(int client)
{
	
}

public void OnGameFrame()
{
	Sarysamods9_GameFrame();
	Sarysapub1_GameFrame();
	Saxton_GameFrame();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	CustomAttrib_PlayerRunCmd(client);
	Sarysapub1_PlayerRunCmd(client, buttons);
	return Saxton_PlayerRunCmd(client, buttons);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	Sarysapub1_EntityCreated(entity, classname);
	SDKHooks_EntityCreated(entity, classname);
}

public void OnEntityDestroyed(int entity)
{
	//CustomMelee_EntityRemoved(entity);
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	CustomAttrib_CalcIsAttackCritical(client, weapon);
	//CustomMelee_CalcIsAttackCritical(weapon, weaponname);
	return Plugin_Continue;
}

public void FF2R_OnBossCreated(int client, BossData cfg, bool setup)
{
	if(!BossTimers[client])
		BossTimers[client] = new ArrayList();
	
	Pyromancer_BossCreated(client, cfg);
	Sarysamods9_BossCreated(client, cfg, setup);
	Sarysapub1_BossCreated(client, cfg, setup);
	Saxton_BossCreated(client, cfg, setup);
}

public void FF2R_OnBossEquipped(int client, bool weapons)
{
	Pyromancer_BossEquipped(client, weapons);
	Saxton_BossEquipped(client, weapons);
}

public void FF2R_OnBossRemoved(int client)
{
	Pyromancer_BossRemoved(client);
	Sarysamods9_BossRemoved(client);
	Sarysapub1_BossRemoved(client);
	Saxton_BossRemoved(client);

	int length = BossTimers[client].Length;
	for(int i; i < length; i++)
	{
		CloseHandle(BossTimers[client].Get(i));
	}
	delete BossTimers[client];
}

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
	Heffe_Ability(client, ability, cfg);
	HHH_Ability(client, ability, cfg);
	Rock_Ability(client, ability, cfg);
	CK_Ability(client, ability, cfg);
	PhatRages_Ability(client, ability, cfg);
	Sarysamods9_Ability(client, ability);
	Sarysapub1_Ability(client, ability, cfg);
	Saxton_Ability(client, ability);
	Spellbook_Ability(client, ability, cfg);
	Vagineer_Ability(client, ability, cfg);
}

public void FF2R_OnAliveChanged(const int alive[4], const int total[4])
{
	for(int i; i < 4; i++)
	{
		PlayersAlive[i] = alive[i];
	}
	
	SpecTeam = (total[TFTeam_Unassigned] || total[TFTeam_Spectator]);
}

static void OnBuiltObject(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int building = event.GetInt("index");

	if(client)
	{
		Vagineer_BuiltObject(client, building);
	}
}

void SetKillIcon(const char[] icon = "", const char[] name = "")
{
	strcopy(KillIcon, sizeof(KillIcon), icon);
	strcopy(KillName, sizeof(KillName), name);
}

static Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Action action;
	
	UpdateAction(action, Rock_PlayerDeath(event));
	Saxton_PlayerDeath(event);

	if(KillIcon[0])
	{
		event.SetString("weapon", KillIcon);
		if(KillName[0])
			event.SetString("weapon_logclassname", KillName);
		
		UpdateAction(action, Plugin_Changed);
	}

	return action;
}

static void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client)
	{
		Announcer_PlayerSpawn(client);
	}
}

static void OnDeployBanner(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("buff_owner"));

	if(client)
	{
		CustomAttrib_DeployBanner(client);
	}
}

static Action OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if(attacker)
		CustomAttrib_ObjectDeflected(attacker);
	
	return Plugin_Continue;
}