
#pragma semicolon 1
#pragma newdecls required

float f_JorkingStarted[MAXPLAYERS];
float f_JorkingFinish[MAXPLAYERS];
int i_JorkingWeaponIndex[MAXPLAYERS];
float f_JorkParticleCooldown[MAXPLAYERS];

void CK_Ability(int client, const char[] ability, AbilityData cfg)
{
	if(!StrContains(ability, "mobility_self_slap", false))
	{
		DataPack pack;
		CreateDataTimer(cfg.GetFloat("time_between_slaps", 0.25), CK_SelfSlapTimer, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		pack.WriteCell(EntIndexToEntRef(client));
		pack.WriteFloat(cfg.GetFloat("duration", 5.0) + GetGameTime());
		pack.WriteFloat(cfg.GetFloat("slap_power", 250.0));
		pack.WriteFloat(cfg.GetFloat("aoe_randomness", 15.0));

		CK_SelfSlapTimer(INVALID_HANDLE, pack);
	}
	else if(!StrContains(ability, "lifeloss_ejaculation", false))
	{
		
		SDKUnhook(client, SDKHook_PreThink, CK_JorkAnimation);
		SDKHook(client, SDKHook_PreThink, CK_JorkAnimation);
		i_JorkingWeaponIndex[client] = -1;

		f_JorkingFinish[client] = cfg.GetFloat("time_untill_bust", 4.0);
		cfg.GetFloat("aoe_range", 550.0);

		f_JorkingStarted[client] = GetGameTime();
		static WeaponData items[1];
		if(!items[0].Index)
		{
			// Weapon
			items[0].Setup("tf_weapon_raygun", 442, "", false);
			items[0].Quality = 6;
			items[0].Level = 5;
			items[0].Alpha = 128;
			items[0].Show = false;
		}
		int weapon = TF2Items_CreateFromStruct(client, items[0]);
		if(weapon != -1)
		{
			Attrib_Set(weapon, "clip size bonus upgrade", _, 5.0);
			Attrib_Set(weapon, "Reload time decreased", _, 1.0);
			Attrib_Set(weapon, "deploy time decreased", _, 0.01);
			i_JorkingWeaponIndex[client] = EntIndexToEntRef(weapon);
			TF2U_SetPlayerActiveWeapon(client, weapon);
			Attrib_Set(weapon, "disable weapon switch", _, 1.0);
			SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", 0.0);
		}
		SetForceButtonState(client, true, IN_RELOAD);
		SetForceButtonState(client, true, IN_DUCK);
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		SetEntProp(client, Prop_Send, "m_bAllowAutoMovement", 0);
		SetEntProp(client, Prop_Send, "m_bDucked", true);
		SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
		f_JorkParticleCooldown[client] = 0.0;
		FF2R_DoBossSlot(client, 12);
	}
}

public void CK_JorkAnimation(int client)
{
	if((f_JorkingStarted[client] + f_JorkingFinish[client]) < GetGameTime())
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		int weapon = EntRefToEntIndex(i_JorkingWeaponIndex[client]);
		if(IsValidEntity(weapon))
			TF2_RemoveItem(client, weapon);
		
		i_JorkingWeaponIndex[client] = -1;
		int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(entity != -1)
			TF2U_SetPlayerActiveWeapon(client, entity);

		for(int jorks; jorks < 25; jorks++)
		{
			float VecAbsClient[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", VecAbsClient);
			VecAbsClient[0] += GetRandomFloat(-70.0, 70.0);
			VecAbsClient[1] += GetRandomFloat(-70.0, 70.0);
			VecAbsClient[2] += GetRandomFloat(20.0, 50.0);
			ParticleEffectAt(VecAbsClient, "peejar_impact_milk", 0.25);
			FF2R_EmitBossSoundToAll("sound_jorking", client);
		}
		FF2R_DoBossSlot(client, 11);
		
		SetForceButtonState(client, false, IN_RELOAD);
		SetForceButtonState(client, false, IN_DUCK);
		SetEntProp(client, Prop_Send, "m_bAllowAutoMovement", 1);
		SetEntProp(client, Prop_Send, "m_bDucked", false);
		SetEntityFlags(client, GetEntityFlags(client)&~FL_DUCKING);	
		SDKUnhook(client, SDKHook_PreThink, CK_JorkAnimation);
		return;
	}
	else
	{
		int weapon = EntRefToEntIndex(i_JorkingWeaponIndex[client]);
		if(!IsValidEntity(weapon))
		{
			SDKUnhook(client, SDKHook_PreThink, CK_JorkAnimation);
			return;
		}
		float FinalJorkTime = (f_JorkingStarted[client] + f_JorkingFinish[client]) - GetGameTime();
		FinalJorkTime /= f_JorkingFinish[client];
		if(FinalJorkTime <= 0.15)
			FinalJorkTime = 0.15;
		Attrib_Set(weapon, "Reload time decreased", _, FinalJorkTime);
		//never full
		if( f_JorkParticleCooldown[client] < GetGameTime())
		{
			f_JorkParticleCooldown[client] = GetGameTime() + (FinalJorkTime * 0.5);
			FF2R_EmitBossSoundToAll("sound_jorking", client);
			if(FinalJorkTime <= 0.5)
			{
				float VecAbsClient[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", VecAbsClient);
				VecAbsClient[2] += 30.0;
				ParticleEffectAt(VecAbsClient, "peejar_impact_milk", 0.25);
			}
		}

		SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", 0.0);
		float AnglesForce[3];
		GetClientEyeAngles(client, AnglesForce);
		AnglesForce[0] = 70.0; 
		TeleportEntity(client, NULL_VECTOR, AnglesForce, NULL_VECTOR);
	}
}

//This is like shitty little spamable dash
static Action CK_SelfSlapTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	if(!client)
		return Plugin_Stop;
	if(!FF2R_GetBossData(client))
		return Plugin_Stop;
	if(GetGameTime() > pack.ReadFloat())
		return Plugin_Stop;


	float SlapPower = pack.ReadFloat();
	float RandomAngles = pack.ReadFloat();

	float Angles[3];
	GetClientEyeAngles(client, Angles);
	Angles[0] = GetRandomFloat(-RandomAngles, RandomAngles);
	Angles[1] = GetRandomFloat(-RandomAngles, RandomAngles);
	Angles[2] = GetRandomFloat(-(RandomAngles * 0.5), (RandomAngles * 0.5));
	float CurrentVel[3];
	CurrentVel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	CurrentVel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	CurrentVel[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

	static float velocity[3];
	GetAngleVectors(Angles, velocity, NULL_VECTOR, NULL_VECTOR);
	float knockback = SlapPower;
			
	ScaleVector(velocity, knockback);
	if ((GetEntityFlags(client) & FL_ONGROUND) != 0 || GetEntProp(client, Prop_Send, "m_nWaterLevel") >= 1)
		velocity[2] = fmax(velocity[2], 300.0);
	else
		velocity[2] += 150.0; // a little boost to alleviate arcing issues

	//Add the 2 vectors together
	velocity[0] += CurrentVel[0];
	velocity[1] += CurrentVel[1];
	velocity[2] += CurrentVel[2];
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	FF2R_EmitBossSoundToAll("sound_self_slap", client);
	
	return Plugin_Stop;
}