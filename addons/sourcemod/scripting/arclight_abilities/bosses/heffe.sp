/*
	https://github.com/Batfoxkid/FF2-Library/blob/edited/addons/sourcemod/scripting/freaks/ff2_death.sp
	
	"rage_heffe_rapture"
	{
		"slot"			"0"		// Ability slot
		"distance"		"800.0"	// Max spawn distance
		"delay"			"0.2"	// Spawn delay
		"count"			"15"	// Spawn count
		"range"			"100.0"	// Beam size
		"push"			"30.0"	// Beam push force
		"lifetime"		"10.0"	// Beam lifetime
		"slay"			"850.0"	// Kill height
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"rage_heffe_smite"
	{
		"slot"			"0"		// Ability slot
		"distance"		"600.0"	// Distance
		"delay"			"10.0"	// Delay
		"limit"			"3"		// Kill limit
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"rage_heffe_taunt"
	{
		"slot"			"0"		// Ability slot
		"taunt"			""		// Taunt index to play
		"duration"		"5.0"	// Knocback immunity time
		"low"			"9"		// Low ability slot to call on taunt
		"high"			"9"		// High ability slot to call on taunt
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"rage_heffe_dome"
	{
		"slot"			"0"			// Ability slot
		"distance"		"600.0"		// Distance
		"duration"		"10.0"		// Duration
		"color"			"255 255 0"	// RGB
		"fade"			"155"		// Fade Alpha (0 to disable)
		
		"plugin_name"	"ff2r_arclight_abilities"
	}
*/

#pragma semicolon 1
#pragma newdecls required

static int g_Smoke;
static int g_Glow;
static int g_Laser;
static int g_SmokeSprite;
static int g_LightningSprite;
static float NextDamageAt[MAXTF2PLAYERS];

void Heffe_MapStart()
{
	g_Laser = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_Smoke = PrecacheModel("materials/effects/fire_cloud1.vmt");
	g_Glow = PrecacheModel("sprites/yellowglow1.vmt");
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
	g_LightningSprite = PrecacheModel("sprites/lgtning.vmt");
	PrecacheSound("ambient/explosions/explode_9.wav");
}

void Heffe_PlayerSpawn(int client)
{
	if(NextDamageAt[client])
	{
		NextDamageAt[client] = 0.0;
		SetEntityGravity(client, 1.0);
	}
}

void Heffe_Ability(int client, const char[] ability, AbilityData cfg)
{
	if(!StrContains(ability, "rage_heffe_rapture", false))
	{
		Rapture(client, ability, cfg);
	}
	else if(!StrContains(ability, "rage_heffe_smite", false))
	{
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(cfg.GetFloat("delay"), SmiteTimer, pack));
		pack.WriteCell(client);
		pack.WriteString(ability);
	}
	else if(!StrContains(ability, "rage_heffe_taunt", false))
	{
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(0.1, TauntTimer, pack, TIMER_REPEAT));
		pack.WriteCell(client);
		pack.WriteString(ability);
	}
	else if(!StrContains(ability, "rage_heffe_dome", false))
	{
		int dome = CreateEntityByName("prop_dynamic");
		if(dome != -1)
		{
			float pos[3];
			GetClientAbsOrigin(client, pos);

			float radius = cfg.GetFloat("distance", 800.0);
			
			int r = cfg.GetInt("red", 255);
			int g = cfg.GetInt("green", 255);
			int b = cfg.GetInt("blue", 255);

			DispatchKeyValueVector(dome, "origin", pos);
			DispatchKeyValue(dome, "model", "models/kirillian/brsphere_huge.mdl");
			DispatchKeyValue(dome, "disableshadows", "1");
			SetEntPropFloat(dome, Prop_Send, "m_flModelScale", SquareRoot(radius / 10000.0));

			DispatchSpawn(dome);

			SetEntityRenderColor(dome, r, g, b, 255);

			char buffer[64];
			FormatEx(buffer, sizeof(buffer), "OnUser1 !self:Kill::%f:1", cfg.GetFloat("duration", 5.0));
			SetVariantString(buffer);
			AcceptEntityInput(dome, "AddOutput");
			AcceptEntityInput(dome, "FireUser1");

			DataPack pack;
			BossTimers[client].Push(CreateDataTimer(0.1, DomeTimer, pack, TIMER_REPEAT));
			pack.WriteCell(client);
			pack.WriteCell(EntIndexToEntRef(dome));
			pack.WriteString(ability);
		}
	}
}

static void Rapture(int client, const char[] ability, AbilityData cfg)
{
	float delay = cfg.GetFloat("delay", 0.2);
	int count = cfg.GetInt("count", 15);

	for(int i = 1; i <= count; i++)
	{
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(i * delay, SpawnRapture, pack, TIMER_FLAG_NO_MAPCHANGE));
		pack.WriteCell(client);
		pack.WriteString(ability);
	}
}

static Action SpawnRapture(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	BossTimers[client].Erase(BossTimers[client].FindValue(timer));

	if(IsPlayerAlive(client))
	{
		char buffer[64];
		pack.ReadString(buffer, sizeof(buffer));
		BossData boss = FF2R_GetBossData(client);
		AbilityData cfg = boss.GetAbility(buffer);
		if(cfg.IsMyPlugin())
		{
			float distance = cfg.GetFloat("distance", 800.0) / 2.0;
			float range = cfg.GetFloat("range", 100.0) / 2.0;
			float push = cfg.GetFloat("push", 30.0);
			float lifetime = cfg.GetFloat("lifetime", 10.0);
			float slay = cfg.GetFloat("slay", 850.0);

			float pos[3];
			GetClientAbsOrigin(client, pos);
			pos[0] += GetRandomFloat(-distance, distance);
			pos[1] += GetRandomFloat(-distance, distance);
			Handle trace = TR_TraceRayEx(pos, {90.0, 0.0, 0.0}, MASK_SHOT, RayType_Infinite);
			if(TR_DidHit(trace))
			{
				TR_GetEndPosition(pos, trace);
				pos[2] += 5.0;
			}
			delete trace;

			int trigger = CreateEntityByName("trigger_push");
			if(trigger != -1)
			{
				CreateTimer(lifetime, RemoveRapture, EntIndexToEntRef(trigger), TIMER_FLAG_NO_MAPCHANGE);
				
				DispatchKeyValueVector(trigger, "origin", pos);
				DispatchKeyValueFloat(trigger, "speed", push);
				DispatchKeyValue(trigger, "StartDisabled", "0");
				DispatchKeyValue(trigger, "spawnflags", "1");
				DispatchKeyValueVector(trigger, "pushdir", view_as<float>({-90.0, 0.0, 0.0}));
				DispatchKeyValue(trigger, "alternateticksfix", "0");
				DispatchKeyValue(trigger, "OnUser1", "!self,Kill,,0.1,-1");
				DispatchSpawn(trigger);
				
				ActivateEntity(trigger);

				SetEntPropEnt(trigger, Prop_Send, "m_hOwnerEntity", client);
				AcceptEntityInput(trigger, "Enable");
				
				SetEntityModel(trigger, "models/items/ammopack_small.mdl");

				float vecMins[3];
				vecMins[0] = -range;
				vecMins[1] = -range;
				SetEntPropVector(trigger, Prop_Send, "m_vecMins", vecMins);

				float vecMaxs[3];
				vecMaxs[0] = range;
				vecMaxs[1] = range;
				vecMaxs[2] = slay * 1.1;
				SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", vecMaxs);

				SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);

				SDKHook(trigger, SDKHook_StartTouch, RaptureStartTouch);
				SDKHook(trigger, SDKHook_Touch, RaptureTouch);
				SDKHook(trigger, SDKHook_EndTouch, RaptureEndTouch);

				float minEnd = pos[2] + vecMaxs[2];
				float endpos[3];
				trace = TR_TraceRayEx(pos, {-90.0, 0.0, 0.0}, MASK_SHOT, RayType_Infinite);
				if(TR_DidHit(trace))
				{
					TR_GetEndPosition(endpos, trace);
					if(endpos[2] < minEnd)
						endpos[2] = minEnd;
				}
				else
				{
					endpos[0] = pos[0];
					endpos[1] = pos[1];
					endpos[2] = minEnd;
				}
				delete trace;

				TE_SetupBeamPoints(pos, endpos, g_Laser, 0, 0, 0, lifetime, range, range * 0.85, 0, 0.80, {255, 215, 0, 155}, 1);
				TE_SendToAll();

				TE_SetupSmoke(pos, g_Smoke, 30.0, 6);
				TE_SendToAll();
				TE_SetupGlowSprite(pos, g_Glow, lifetime, 3.0, 235);
				TE_SendToAll();
			}
		}
	}
	
	return Plugin_Continue;
}

static Action RemoveRapture(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != -1)
	{
		AcceptEntityInput(entity, "Disable");
		AcceptEntityInput(entity, "FireUser1");
	}
	
	return Plugin_Continue;
}

static Action RaptureStartTouch(int entity, int target)
{
	if(target > 0 && target <= MaxClients)
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(owner != -1 && GetClientTeam(owner) != GetClientTeam(target))
		{
			NextDamageAt[target] = GetGameTime() + 1.0;
			SetEntityGravity(target, 0.001);
			TF2_StunPlayer(target, 15.0, 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, owner);
			return Plugin_Continue;
		}
	}
	return Plugin_Handled;
}

public Action RaptureEndTouch(int entity, int target)
{
	if(target > 0 && target <= MaxClients)
	{
		NextDamageAt[target] = 0.0;
		SetEntityGravity(target, 1.0);
		TF2_RemoveCondition(target, TFCond_Dazed);
	}
	return Plugin_Continue;
}

public Action RaptureTouch(int entity, int target)
{
	if(target > 0 && target <= MaxClients)
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(owner != -1 && GetClientTeam(owner) != GetClientTeam(target))
		{
			float pos1[3], pos2[3];
			GetClientAbsOrigin(target, pos1);
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos2);
			
			float distance = GetVectorDistance(pos1, pos2);

			float vec[3];
			GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vec);

			SetKillIcon("merasmus_zap", "rage_heffe_rapture");
			if(distance > (vec[2] / 1.1))
			{
				SDKHooks_TakeDamage(target, owner, owner, 9001.0, DMG_SHOCK|DMG_PREVENT_PHYSICS_FORCE);
			}
			else if(NextDamageAt[target] < GetGameTime())
			{
				NextDamageAt[target] = GetGameTime() + 1.0;

				float ratio = (distance / vec[2]);
				SDKHooks_TakeDamage(target, owner, owner, ratio * 12.0, DMG_PREVENT_PHYSICS_FORCE);
			}
			SetKillIcon();

			if(GetEntityFlags(target) & FL_ONGROUND)
			{
				TeleportEntity(target, _, _, {0.0, 0.0, 300.0});
			}
			else
			{
				GetEntPropVector(target, Prop_Data, "m_vecVelocity", vec);
				vec[0] = 0.0;
				vec[1] = 0.0;

				if(vec[2] > GetEntPropFloat(entity, Prop_Data, "m_flSpeed"))
					vec[2] -= vec[2] / 8;

				TeleportEntity(target, _, _, vec); 
			}

			return Plugin_Continue;
		}
	}
	return Plugin_Handled;
}

Action SmiteTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	BossTimers[client].Erase(BossTimers[client].FindValue(timer));
	
	char buffer[64];
	pack.ReadString(buffer, sizeof(buffer));
	BossData boss = FF2R_GetBossData(client);
	AbilityData cfg = boss.GetAbility(buffer);
	if(cfg.IsMyPlugin() && IsPlayerAlive(client))
	{
		float distance = cfg.GetFloat("distance", 800.0);
		distance *= distance;

		int limit = cfg.GetInt("limit", 3);
		int team = GetClientTeam(client);

		float pos1[3], pos2[3];
		GetClientAbsOrigin(client, pos1);
		
		int victims;
		int[][] victim = new int[MaxClients][2];
		for(int target = 1; target <= MaxClients; target++)
		{
			if(target == client || !IsClientInGame(target) || !IsPlayerAlive(target))
				continue;
			
			if(GetClientTeam(target) == team)
				continue;
			
			if(IsInvuln(target))
				continue;
			
			GetClientAbsOrigin(target, pos2);
			if(GetVectorDistance(pos1, pos2, true) > distance)
				continue;

			FF2R_GetClientScore(client, victim[victims][1]);
			victim[victims++][0] = target;
		}

		if(victims > 1)
			SortCustom2D(victim, victims, SmiteHighestDamage);

		for(int i; i < victims && i < limit; i++)
		{
			PerformSmite(client, victim[i][0]);
		}
	}

	return Plugin_Continue;
}

static int SmiteHighestDamage(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
	if(elem1[1] > elem2[1])
		return -1;
	
	if(elem1[1] < elem2[1])
		return 1;
	
	return (elem1[0] > elem2[0]) ? 1 : -1;
}

static void PerformSmite(int client, int target)
{
	float startpos[3], endpos[3];
	GetClientAbsOrigin(target, endpos);
	
	Handle trace = TR_TraceRayEx(endpos, {-90.0, 0.0, 0.0}, MASK_SHOT, RayType_Infinite);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(startpos, trace);
	}
	else
	{
		startpos[2] = endpos[2] + 1500.0;
	}
	delete trace;
	
	endpos[2] -= 26; // increase y-axis by 26 to strike at player's chest instead of the ground
	
	// define where the lightning strike start
	startpos[0] = endpos[0] + GetRandomFloat(-500.0, 500.0);
	startpos[1] = endpos[1] + GetRandomFloat(-500.0, 500.0);
	
	TE_SetupBeamPoints(startpos, endpos, g_LightningSprite, 0, 0, 0, 0.2, 20.0, 10.0, 0, 1.0, { 255, 255, 255, 255 }, 3);
	TE_SendToAll();
	
	TE_SetupSparks(endpos, { 0.0, 0.0, 0.0 }, 5000, 1000);
	TE_SendToAll();
	
	TE_SetupEnergySplash(endpos, { 0.0, 0.0, 0.0 }, false);
	TE_SendToAll();
	
	TE_SetupSmoke(endpos, g_SmokeSprite, 5.0, 10);
	TE_SendToAll();
	
	EmitAmbientSound("ambient/explosions/explode_9.wav", startpos, target, SNDLEVEL_RAIDSIREN);
	
	SetKillIcon("purgatory", "rage_heffe_smite");
	SDKHooks_TakeDamage(target, client, client, 9001.0, DMG_PREVENT_PHYSICS_FORCE, -1);
	SetKillIcon();

	PrintCenterText(target, "Thou hast been smitten!");
}

Action TauntTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();

	if(!(GetEntityFlags(client) & FL_ONGROUND))
		return Plugin_Continue;
	
	char buffer[64];
	pack.ReadString(buffer, sizeof(buffer));
	BossData boss = FF2R_GetBossData(client);
	AbilityData cfg = boss.GetAbility(buffer);
	if(cfg.IsMyPlugin() && IsPlayerAlive(client))
	{
		TF2_RemoveCondition(client, TFCond_Taunting);

		// https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/VScript_Examples#Giving_a_taunt
		int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		int entity = CreateEntityByName("tf_weapon_bat");
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", cfg.GetInt("taunt"));
		SetEntProp(entity, Prop_Send, "m_bInitialized", true);
		SetEntProp(entity, Prop_Data, "m_bForcePurgeFixedupStrings", true);
		
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
		SetEntProp(client, Prop_Send, "m_iFOV", 0);

		SetVariantString("self.HandleTauntCommand(0)");
		AcceptEntityInput(client, "RunScriptCode");

		bool success = TF2_IsPlayerInCondition(client, TFCond_Taunting);

		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", active);

		AcceptEntityInput(entity, "Kill");

		if(!success)
			return Plugin_Continue;
		
		int low = cfg.GetInt("low", cfg.GetInt("high"));
		FF2R_DoBossSlot(client, low, cfg.GetInt("high", low));

		float duration = cfg.GetFloat("duration", 3.0);
		if(duration > 0.0)
			TF2_AddCondition(client, TFCond_MegaHeal, duration);
	}

	BossTimers[client].Erase(BossTimers[client].FindValue(timer));
	return Plugin_Stop;
}

Action DomeTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int entity = EntRefToEntIndex(pack.ReadCell());

	if(entity != -1)
	{
		if(client && IsPlayerAlive(client))
		{
			char buffer[64];
			pack.ReadString(buffer, sizeof(buffer));
			BossData boss = FF2R_GetBossData(client);
			AbilityData cfg = boss.GetAbility(buffer);
			if(cfg.IsMyPlugin())
			{
				float pos1[3], pos2[3];
				GetClientAbsOrigin(client, pos1);

				if(entity != -1)
					TeleportEntity(entity, pos1);
				
				int fade = cfg.GetInt("fade");
				if(fade > 0)
				{
					int r = cfg.GetInt("red", 255);
					int g = cfg.GetInt("green", 255);
					int b = cfg.GetInt("blue", 255);

					float distance = cfg.GetFloat("distance", 800.0);
					distance *= distance;

					int team = GetClientTeam(client);

					for(int target = 1; target <= MaxClients; target++)
					{
						if(target == client || !IsClientInGame(target) || !IsPlayerAlive(target))
							continue;
						
						if(GetClientTeam(target) == team)
							continue;
						
						GetClientAbsOrigin(target, pos2);
						if(GetVectorDistance(pos1, pos2, true) > distance)
							continue;
						
						CreateFade(target, 1000, r, g, b, fade);
					}
				}

				return Plugin_Continue;
			}
		}

		RemoveEntity(entity);
	}

	BossTimers[client].Erase(BossTimers[client].FindValue(timer));
	return Plugin_Stop;
}