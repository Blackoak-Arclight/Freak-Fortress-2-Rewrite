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
				SetVariantInt(0);
				AcceptEntityInput(i, "SetForcedTauntCam");

				delete DrugTimer[i];

				DataPack pack;
				DrugTimer[i] = CreateDataTimer(0.1, fxDrug_Timer, pack, TIMER_REPEAT);
				pack.WriteCell(i);
				pack.WriteFloat(duration);
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
			static int Repeat;
			
			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
			
			float angs[3];
			GetClientEyeAngles(client, angs);

			static const float g_DrugAngles[] = {0.0, 3.0, 6.0, 9.0, 12.0, 15.0, 18.0, 21.0, 24.0, 27.0, 30.0, 33.0, 36.0, 39.0, 42.0, 39.0, 36.0, 33.0, 30.0, 27.0, 24.0, 21.0, 18.0, 15.0, 12.0, 9.0, 6.0, 3.0, 0.0, -3.0, -6.0, -9.0, -12.0, -15.0, -18.0, -21.0, -24.0, -27.0, -30.0, -33.0, -36.0, -39.0, -42.0, -39.0, -36.0, -33.0, -30.0, -27.0, -24.0, -21.0, -18.0, -15.0, -12.0, -9.0, -6.0, -3.0 };
			angs[2] = g_DrugAngles[Repeat % sizeof(g_DrugAngles)];
			angs[1] = g_DrugAngles[(Repeat+14) % sizeof(g_DrugAngles)];
			angs[0] = g_DrugAngles[(Repeat+21) % sizeof(g_DrugAngles)];

			TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);
			
			SetEntProp(client, Prop_Send, "m_iFOV", 160);
			SetEntProp(client, Prop_Send, "m_iDefaultFOV", 160);
			
			if((Repeat%15) == 0)
				ClientCommand(client, "playgamesound ambient/halloween/mysterious_perc_01.wav");
			
			SetVariantString("effects/tp_eyefx/tpeye.vmt");
			AcceptEntityInput(client, "SetScriptOverlayMaterial"); // rainbow flashes
			
			Repeat++;
			
			ScreenFade(client, 255, 255, 0x0002, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 150);
			return Plugin_Continue;
		}

		float angs[3];
		GetClientEyeAngles(client, angs);
		angs[2] = 0.0;
		TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);	
		
		SetVariantString("");
		AcceptEntityInput(client, "SetScriptOverlayMaterial");
		
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", 90);
	}

	DrugTimer[client] = null;
	return Plugin_Stop;
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