/*
	https://github.com/Batfoxkid/FF2-Library/blob/edited/addons/sourcemod/scripting/freaks/ff2_phatrages.sp
	
	"rage_delirium"
	{
		"slot"			"0"		// Ability slot
		"distance"		"800.0"	// Distance
		"duration"		"8.0"	// Duration
		
		"plugin_name"	"ff2r_arclight_abilities"
	}


	"rage_hellfire"
	{
		"slot"			"0"		// Ability slot
		"distance"		"600.0"	// Distance
		"damage"		"30.0"	// First explosion damage

		"burninterval"	"1.0"	// Time between aftershocks
		"burnticks"		"8"		// Amount of aftershocks
		"burndamage"	"5.0"	// Aftershock damage
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	"sound_hellfire"
	{
		"misc/flame_engulf.wav"
		{
			"volume"	"2.0"
		}
	}
*/

static Handle DrugTimer[MAXTF2PLAYERS];
static int gLaser1;
static int gHalo1;

void PhatRages_MapStart()
{
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
	gHalo1 = PrecacheModel("materials/sprites/halo01.vmt");
}

void PhatRages_Ability(int client, const char[] ability, AbilityData cfg)
{
	if(!StrContains(ability, "rage_delirium", false))
	{
		Delirium(client, cfg);
	}
	else if(!StrContains(ability, "rage_hellfire", false))
	{
		Hellfire(client, cfg);
	}
}

static void Delirium(int client, AbilityData cfg)
{
	float distance = cfg.GetFloat("distance", 800.0);
	distance *= distance;

	float duration = GetGameTime() + cfg.GetFloat("duration", 8.0);	

	int team = GetClientTeam(client);
	
	float pos1[3], pos2[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos1);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != team)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < distance)
			{
				delete DrugTimer[i];

				float angs[3];
				GetClientEyeAngles(i, angs);

				DataPack pack;
				DrugTimer[i] = CreateDataTimer(duration / 6.1, fxDrug_Timer, pack, TIMER_REPEAT);
				pack.WriteCell(i);
				pack.WriteFloat(duration);

				pack = new DataPack();
				pack.WriteCell(GetClientUserId(i));
				pack.WriteFloat(duration);
				pack.WriteFloat(angs[0]);
				pack.WriteFloat(angs[1]);
				pack.WriteFloat(angs[2]);
				RequestFrame(AngleSetFrame, pack);
			}
		}	
	}
	
	pos1[2] += 10;
			
	TE_SetupBeamRingPoint(pos1, 10.0, distance/2.0, gLaser1, gHalo1, 0, 15, 0.5, 10.0, 0.0, { 128, 128, 128, 255 }, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, 10.0, distance/2.0, gLaser1, gHalo1, 0, 10, 0.6, 20.0, 0.5, { 75, 75, 255, 255 }, 10, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, 0.0, distance, gLaser1, gHalo1, 0, 0, 0.5, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, 0.0, distance, gLaser1, gHalo1, 0, 0, 5.0, 100.0, 5.0, {64, 64, 128, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, 0.0, distance, gLaser1, gHalo1, 0, 0, 2.5, 100.0, 5.0, {32, 32, 64, 255}, 0, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(pos1, 0.0, distance, gLaser1, gHalo1, 0, 0, 6.0, 100.0, 5.0, {16, 16, 32, 255}, 0, 0);
	TE_SendToAll();
}

static Action fxDrug_Timer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client) && pack.ReadFloat() > GetGameTime())
		{
			SetEntProp(client, Prop_Send, "m_iFOV", 160);

			ClientCommand(client, "playgamesound ambient/halloween/mysterious_perc_01.wav");
			
			SetVariantString("effects/tp_eyefx/tpeye.vmt");
			AcceptEntityInput(client, "SetScriptOverlayMaterial");
			
			return Plugin_Continue;
		}

		SetVariantString("");
		AcceptEntityInput(client, "SetScriptOverlayMaterial");
		
		SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iSpawnCounter") - 8, 0, _, true);	// m_iPreTauntFov
		SetEntProp(client, Prop_Send, "m_iFOV", 0);
	}

	DrugTimer[client] = null;
	return Plugin_Stop;
}

static void AngleSetFrame(DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		if(IsPlayerAlive(client) && pack.ReadFloat() > GetGameTime())
		{
			float angs[3];
			for(int i; i < 3; i++)
			{
				angs[i] = pack.ReadFloat();
			}

			TeleportEntity(client, _, angs);

			RequestFrame(AngleSetFrame, pack);
			return;
		}

		float angs[3];
		GetClientEyeAngles(client, angs);
		angs[2] = 0.0;
		TeleportEntity(client, _, angs);	
	}

	delete pack;
}

static void Hellfire(int client, AbilityData cfg)
{
	float distance = cfg.GetFloat("distance", 800.0);
	distance *= distance;

	float damage = cfg.GetFloat("damage", 25.0);

	int team = GetClientTeam(client);

	float pos1[3], pos2[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos1);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != team)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < distance)
				TF2_AddCondition(i, TFCond_Gas, 0.5, client);
		}
	}

	float interval = cfg.GetFloat("burninterval", 1.0);
	int ticks = cfg.GetInt("burnticks");
	float burndamage = cfg.GetFloat("burndamage", 5.0);

	FF2R_EmitBossSoundToAll("sound_hellfire", client);
	
	for(int i; i <= ticks; i++)
	{
		DataPack pack;
		BossTimers[client].Push(CreateDataTimer(i * interval, HellfireTimer, pack, TIMER_FLAG_NO_MAPCHANGE));
		pack.WriteCell(client);
		pack.WriteFloat(distance);
		pack.WriteFloat(i ? burndamage : damage);
		pack.WriteCell(i ? DMG_BURN : DMG_BLAST);
	}
}

static Action HellfireTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	float distance = pack.ReadFloat();
	float damage = pack.ReadFloat();
	int damagetype = pack.ReadCell();

	int team = GetClientTeam(client);
	SetKillIcon("purgatory", "rage_hellfire");

	float pos1[3], pos2[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos1);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != team)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if(GetVectorDistance(pos1, pos2, true) < distance)
				SDKHooks_TakeDamage(i, client, client, damage, damagetype);
		}
	}

	SetKillIcon();

	ParticleEffectAt(pos1, "cinefx_goldrush", 2.0);
	
	BossTimers[client].Erase(BossTimers[client].FindValue(timer));
	return Plugin_Stop;
}