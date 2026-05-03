/*
	"special_gordon_gravity"
	{
		"index"			"197"	// Weapon index to act as the gravity gun
		"convert"		"30.0"	// Rage cost to convert an object (-1 to disable converts)
		
		"pullcost"		"1.666"	// Rage cost per second to hold an object
		"pullrange"		"600.0"	// Max pickup range

		"pushcost"		"2.0"		// Rage cost to push an non-held object
		"pushrange"		"300.0"		// Max push range
		"pushforce"		"1000.0"	// Push force

		"crushres"		"0.01"	// Damage reduction to crush damage taken
		"crushdmg"		"10.0"	// Damage increase to crush damage dealt

		"Entities"
		{
			"player"	// Classname
			{
				"convert"	"false"	// Convert the entity a physics object
				"pickup"	"true"	// Can pickup the object
				"push"		"true"	// Can push the object
				"movetype"	"false"	// If to set movetype to vphys
				"pullcost"	"4.0"	// Cost multiplier to hold
				"return"	"false"	// If to restore speed after dropping
				"damage"	"55.0"	// Push damage dealt
				"pushcost"	"10.0"	// Cost multiplier to push
			}
		}
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	"sound_gordon_gravity"
	{
		"weapons/physcannon/physcannon_drop.wav"	"drop"
		"weapons/physcannon/physcannon_tooheavy.wav"	"fail"
		"weapons/physcannon/superphys_launch2.wav"	"launch"
		"weapons/physcannon/physcannon_pickup.wav"	"pickup"
	}

	
	"special_gordon_viewmodel"
	{
		"197"	// Weapon index
		{
			"model"		"models/weapons/v_rpg.mdl"	// Model path
			"offset"	"-10"						// Offset from camera
			"skin"		"0"							// Model skin

			// Replace named animations
			"ACT_RELOAD_FINISH"	"ACT_VM_IDLE"
		}
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"special_gordon_hevsuit"
	{
		"plugin_name"	"ff2r_arclight_abilities"
	}

	"sound_gordon_hevsuit"
	{
		"hl1/fvox/chemical_detected.wav"	"liquid"
		"hl1/fvox/health_critical.wav"		"30"
	}

	
	"rage_gordon_modify"
	{
		"slot"			"0"	// Ability slot
		
		"Mods"
		{
			// List of keys and values to set
			"special_gordon_gravity.convert"	"20.0"
		}
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"rage_gordon_ammo"
	{
		"slot"	"0"		// Ability slot
		"type"	"3"		// Ammo type
		"ammo"	"100"	// Ammo amount
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"rage_gordon_overlaytip"
	{
		"slot"			"0"		// Ability slot
		"button"		"11"	// Button type (11=M2, 13=Reload, 25=M3)
		"overlay1"		"freak_fortress_2/dots/alt_fire_overlay1"
		"overlay2"		"freak_fortress_2/dots/alt_fire_overlay2"
		
		"plugin_name"	"ff2r_arclight_abilities"
	}
*/

#pragma semicolon 1
#pragma newdecls required

static int OverlayTipButton[MAXTF2PLAYERS];
static int OverlayTipCycle[MAXTF2PLAYERS];
static Handle OverlayTipTimer[MAXTF2PLAYERS];
static int HevSuitEnabled[MAXTF2PLAYERS];
static int GravityGunEnabled[MAXTF2PLAYERS] = {-1, ...};
static bool GravityGunHeldButton[MAXTF2PLAYERS];
static int GravityGunHeldProp[MAXTF2PLAYERS] = {-1, ...};
static float GravityGunHeldVec[MAXTF2PLAYERS][3];
static bool GravityGunHeldType[MAXTF2PLAYERS];
static int GravityGunLastProp[MAXTF2PLAYERS] = {-1, ...};
static float GravityGunDrainIn[MAXTF2PLAYERS];
static float GravityGunDrainCost[MAXTF2PLAYERS];
static int ViewmodelLastSequence[MAXTF2PLAYERS];
static int ViewmodelRef[MAXTF2PLAYERS] = {-1, ...};
static bool ViewmodelForceAnim[MAXTF2PLAYERS];

void Gordon_MapStart()
{
	PrecacheSound("weapons/grenade_launcher1.wav");
	PrecacheSound("weapons/irifle/irifle_fire2.wav");
	PrecacheSound("weapons/cguard/charging.wav");
	PrecacheSound("weapons/physcannon/energy_bounce1.wav");
	PrecacheModel("models/weapons/ar2_grenade.mdl");
	PrecacheModel("models/effects/combineball.mdl");
}

void Gordon_BossCreated(int client, BossData cfg)
{
	AbilityData ability = cfg.GetAbility("special_gordon_gravity");
	if(ability.IsMyPlugin())
	{
		GravityGunEnabled[client] = ability.GetInt("index", -2);
	}

	ability = cfg.GetAbility("special_gordon_hevsuit");
	if(ability.IsMyPlugin())
	{
		HevSuitEnabled[client] = 100;
	}
}

void Gordon_BossEquipped(int client, bool weapons)
{
	if(weapons)
	{
		AbilityData ability = FF2R_GetBossData(client).GetAbility("special_gordon_viewmodel");
		if(ability.IsMyPlugin())
		{
			Gordon_WeaponSwitch(client, -1);
		}
	}
}

void Gordon_BossRemoved(int client)
{
	HevSuitEnabled[client] = 0;
	GravityGunEnabled[client] = -1;
	Gordon_WeaponSwitch(client, -1);
	
	if(OverlayTipTimer[client])
		EndTipOverlay(client);
}

void Gordon_Ability(int client, const char[] ability, AbilityData cfg)
{
	if(!StrContains(ability, "rage_gordon_modify", false))
	{
		BossData boss = FF2R_GetBossData(client);
		ConfigData mods = cfg.GetSection("Mods");
		if(mods)
		{
			PackVal val;
			StringMapSnapshot snap = mods.Snapshot();
			int length = snap.Length;
			for(int i; i < length; i++)
			{
				int size = snap.KeyBufferSize(i);
				char[] key = new char[size];
				snap.GetKey(i, key, size);

				view_as<StringMap>(mods).GetArray(key, val, sizeof(val));
				ReplaceString(key, size, "\\.", ".");
				boss.SetString(key, val.data);
			}

			delete snap;
		}
	}
	else if(!StrContains(ability, "rage_gordon_ammo", false))
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", cfg.GetInt("ammo"), _, cfg.GetInt("type", 1));
	}
	else if(!StrContains(ability, "rage_gordon_overlaytip", false))
	{
		delete OverlayTipTimer[client];
		char buffer[PLATFORM_MAX_PATH];

		OverlayTipCycle[client] = -1;
		OverlayTipButton[client] = cfg.GetInt("button", 11);

		DataPack pack;
		OverlayTipTimer[client] = CreateDataTimer(0.5, OverlayTip, pack, TIMER_REPEAT);
		pack.WriteCell(client);

		cfg.GetString("overlay1", buffer, sizeof(buffer));
		pack.WriteString(buffer);

		cfg.GetString("overlay2", buffer, sizeof(buffer));
		pack.WriteString(buffer);
	}
}

void Gordon_CalcIsAttackCritical(int client)
{
	ViewmodelLastSequence[client] = -1;
}

Action Gordon_TakeDamage(int victim, int &attacker, int inflictor, float &damage, int damagetype)
{
	if(damagetype & DMG_CRUSH)
	{
		if(GravityGunEnabled[victim] != -1)
		{
			damage *= FF2R_GetBossData(victim).GetAbility("special_gordon_gravity").GetFloat("crushres", 1.0);
			return Plugin_Changed;
		}

		for(int other = 1; other <= MaxClients; other++)
		{
			if(GravityGunEnabled[other] != -1)
			{
				if(EntRefToEntIndex(GravityGunHeldProp[other]) == inflictor || EntRefToEntIndex(GravityGunLastProp[other]) == inflictor)
				{
					attacker = other;
					damage *= FF2R_GetBossData(other).GetAbility("special_gordon_gravity").GetFloat("crushdmg", 1.0);
					return Plugin_Changed;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

void Gordon_TakeDamagePost(int victim)
{
	if(HevSuitEnabled[victim] > 0)
	{
		BossData boss = FF2R_GetBossData(victim);
		if(boss.Lives == 1)
		{
			int maxhealth = boss.MaxHealth > 0 ? boss.MaxHealth : SDKCall_GetMaxHealth(victim);
			int health = GetClientHealth(victim) * 100 / maxhealth;

			char key[6];
			for(; HevSuitEnabled[victim] > health; HevSuitEnabled[victim]--)
			{
				IntToString(HevSuitEnabled[victim], key, sizeof(key));
				FF2R_EmitBossSoundToAll("sound_gordon_hevsuit", victim, key, victim, SNDCHAN_VOICE, 140);
			}
		}
	}
}

static void EndTipOverlay(int client)
{
	delete OverlayTipTimer[client];
	
	SetVariantString("");
	AcceptEntityInput(client, "SetScriptOverlayMaterial");
}

static Action OverlayTip(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	
	char buffer[PLATFORM_MAX_PATH];
	pack.ReadString(buffer, sizeof(buffer));

	if(OverlayTipCycle[client])
		pack.ReadString(buffer, sizeof(buffer));

	SetVariantString(buffer);
	AcceptEntityInput(client, "SetScriptOverlayMaterial");

	OverlayTipCycle[client] = !OverlayTipCycle[client];
	return Plugin_Continue;
}

void Gordon_ThinkPost(int client)
{
	if(!IsPlayerAlive(client))
	{
		if(OverlayTipTimer[client])
			EndTipOverlay(client);

		return;
	}
	
	int buttons = GetClientButtons(client);

	if(OverlayTipTimer[client])
	{
		if(buttons & (1 << OverlayTipButton[client]))
			EndTipOverlay(client);
	}
	
	if(buttons & IN_ATTACK2)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1)
		{
			float gameTime = GetGameTime();
			float primary = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
			float secondary = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack");
			
			if((secondary > gameTime && primary != secondary) || primary < gameTime)
			{
				float value;

				if(GetEntProp(weapon, Prop_Send, "m_iClip1") > 1)
				{
					if(Attrib_Get(weapon, "mod shotgun altfire", _, value))
					{
						float dmg = 1.0;
						float rate = 1.0;
						float spread = 1.0;
						float ammo = 1.0;
						Attrib_Get(weapon, "damage bonus", 2, dmg);
						Attrib_Get(weapon, "fire rate penalty", 5, rate);
						Attrib_Get(weapon, "spread penalty", 36, spread);
						Attrib_Get(weapon, "mod ammo per shot", 298, ammo);

						Attrib_Set(weapon, "damage bonus", 2, dmg * value);
						Attrib_Set(weapon, "fire rate penalty", 5, rate * 1.172);
						Attrib_Set(weapon, "spread penalty", 36, spread * 1.25);
						Attrib_Set(weapon, "mod ammo per shot", 298, 2.0);

						VScript_PrimaryAttack(weapon);

						if(GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack") > GetGameTime())
						{
							ClientCommand(client, "playgamesound weapons/shotgun/shotgun_dbl_fire7.wav");
							ViewmodelForceAnim[client] = true;
						}

						Attrib_Set(weapon, "damage bonus", 2, dmg);
						Attrib_Set(weapon, "fire rate penalty", 5, rate);
						Attrib_Set(weapon, "spread penalty", 36, spread);
						Attrib_Set(weapon, "mod ammo per shot", 298, ammo);

						SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack"));
					}
				}

				if(Attrib_Get(weapon, "mod metal grenade altfire", _, value))
				{
					int cost = RoundFloat(value);
					int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, 3);
					if(ammo >= cost)
					{
						SetEntProp(client, Prop_Data, "m_iAmmo", ammo - cost, _, 3);
						EmitSoundToAll("weapons/grenade_launcher1.wav", client);
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime + 1.0);
						SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", gameTime + 1.0);
						ViewmodelForceAnim[client] = true;
						ViewmodelLastSequence[client] = -1;

						static const float speed = 1100.0;

						float pos[3], ang[3], vel[3];
						GetClientEyePosition(client, pos);
						GetClientEyeAngles(client, ang);
						
						vel[0] = Cosine(DegToRad(ang[0])) * Cosine(DegToRad(ang[1])) * speed;
						vel[1] = Cosine(DegToRad(ang[0])) * Sine(DegToRad(ang[1])) * speed;
						vel[2] = Sine(DegToRad(ang[0])) * -speed;

						int entity = CreateEntityByName("tf_projectile_rocket");
						if(entity != -1)
						{
							SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
							SetEntPropEnt(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
							SetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher", weapon);
							SetEntPropEnt(entity, Prop_Send, "m_hLauncher", weapon);
							SetEntDataFloat(entity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, FF2R_GetBossData(client) ? 500.0 : 100.0, true);
							SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vel);

							TeleportEntity(entity, pos, ang);
							DispatchSpawn(entity);
							
							SetEntityModel(entity, "models/weapons/ar2_grenade.mdl");
							TeleportEntity(entity, _, _, vel);
							SetEntityCollisionGroup(entity, 24);
						}

						RequestFrame(MetalRocketGravity, EntIndexToEntRef(entity));
					}
				}
				else if(Attrib_Get(weapon, "mod metal ball altfire", _, value))
				{
					int cost = RoundFloat(value);
					int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, 3);
					if(ammo >= cost)
					{
						SetEntProp(client, Prop_Data, "m_iAmmo", ammo - cost, _, 3);
						EmitSoundToAll("weapons/cguard/charging.wav", client);
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", gameTime + 1.5);
						SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", gameTime + 1.5);

						DataPack pack;
						CreateDataTimer(1.0, FireRocketDelay, pack, TIMER_FLAG_NO_MAPCHANGE);
						pack.WriteCell(GetClientUserId(client));
						pack.WriteCell(EntIndexToEntRef(weapon));
					}
				}
			}
		}
	}
}

static Action FireRocketDelay(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		int weapon = EntRefToEntIndex(pack.ReadCell());
		if(weapon != -1 && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == weapon)
		{
			EmitSoundToAll("weapons/irifle/irifle_fire2.wav", client);
			ViewmodelForceAnim[client] = true;
			ViewmodelLastSequence[client] = -1;

			static const float speed = 1100.0;

			float pos[3], ang[3], vel[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, ang);
			
			vel[0] = Cosine(DegToRad(ang[0])) * Cosine(DegToRad(ang[1])) * speed;
			vel[1] = Cosine(DegToRad(ang[0])) * Sine(DegToRad(ang[1])) * speed;
			vel[2] = Sine(DegToRad(ang[0])) * -speed;

			int entity = CreateEntityByName("tf_projectile_rocket");
			if(entity != -1)
			{
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SetEntPropEnt(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
				SetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher", weapon);
				SetEntPropEnt(entity, Prop_Send, "m_hLauncher", weapon);
				SetEntDataFloat(entity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, 300.0, true);
				SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vel);

				TeleportEntity(entity, pos, ang);
				DispatchSpawn(entity);
				
				SetEntityModel(entity, "models/effects/combineball.mdl");
				TeleportEntity(entity, _, _, vel);
				SetEntityCollisionGroup(entity, 24);

				SDKHook(entity, SDKHook_StartTouch, ProjectileStartTouch);
				SDKHook(entity, SDKHook_Touch, ProjectileTouch);
			}
		}
	}

	return Plugin_Continue;
}

static Action ProjectileStartTouch(int entity, int target)
{
	if(target > 0 && target <= MaxClients)
	{
		SDKHooks_TakeDamage(target, entity, GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"), 180.0, DMG_BULLET|DMG_CRIT, GetEntPropEnt(entity, Prop_Send, "m_hOriginalLauncher"), _, _, false);
		CreateTimer(0.1, Timer_DissolveRagdoll, GetClientUserId(target), TIMER_FLAG_NO_MAPCHANGE);
	}

	if(GetEntProp(entity, Prop_Send, "m_iDeflected") > 5)
	{
		SDKUnhook(entity, SDKHook_Touch, ProjectileTouch);
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

static Action Timer_DissolveRagdoll(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(ragdoll))
		{
			int dissolver = CreateEntityByName("env_entity_dissolver");
			if(dissolver != -1)
			{
				DispatchKeyValue(dissolver, "dissolvetype", "1");
				DispatchKeyValue(dissolver, "magnitude", "200");
				DispatchKeyValue(dissolver, "target", "!activator");
				
				AcceptEntityInput(dissolver, "Dissolve", ragdoll);
				AcceptEntityInput(dissolver, "Kill");
			}
		}
	}
	return Plugin_Continue;
}

static Action ProjectileTouch(int entity, int target)
{
	float vec1[3], vec2[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vec1);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vec2);
	
	Handle trace = TR_TraceRayFilterEx(vec1, vec2, MASK_SHOT, RayType_Infinite, Trace_DontHitEntity, entity);
	if(!TR_DidHit(trace) || (TR_GetSurfaceFlags(trace) & SURF_SKY))
	{
		delete trace;
		return Plugin_Continue;
	}
	
	TR_GetPlaneNormal(trace, vec1);
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vec2);
	delete trace;
	
	ScaleVector(vec1, GetVectorDotProduct(vec1, vec2) * 2.0);
	
	SubtractVectors(vec2, vec1, vec2);
	GetVectorAngles(vec2, vec1);
	
	TeleportEntity(entity, _, vec1, vec2);
	SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vec2);

	EmitSoundToAll("weapons/physcannon/energy_bounce1.wav", entity, SNDCHAN_STATIC, 80);
	SetEntProp(entity, Prop_Send, "m_iDeflected", GetEntProp(entity, Prop_Send, "m_iDeflected") + 1);
	return Plugin_Handled;
}

static void MetalRocketGravity(int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != -1)
	{
		float vel[3];
		GetEntPropVector(entity, Prop_Data, "m_vecVelocity", vel);
		vel[2] -= 10.0;
		TeleportEntity(entity, _, _, vel);
		RequestFrame(MetalRocketGravity, ref);
	}
}

void Gordon_PluginRunCmd(int client, int buttons)
{
	if(ViewmodelRef[client] != -1)
	{
		int entity = EntRefToEntIndex(ViewmodelRef[client]);
		if(entity != -1)
		{
			int viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
			if(viewmodel != -1)
			{
				int sequence = GetEntProp(viewmodel, Prop_Send, "m_nSequence");
				if(sequence != ViewmodelLastSequence[client])
				{
					ViewmodelLastSequence[client] = sequence;

					char activity[64];
					if(ViewmodelForceAnim[client])
					{
						strcopy(activity, sizeof(activity), "ACT_VM_SECONDARYATTACK");
						ViewmodelForceAnim[client] = false;
					}
					else
					{
						VScript_GetSequenceActivityName(viewmodel, sequence, activity, sizeof(activity));
					}

					ReplaceString(activity, sizeof(activity), "_PRIMARY_", "_");
					ReplaceString(activity, sizeof(activity), "_SECONDARY2_", "_");
					ReplaceString(activity, sizeof(activity), "_SECONDARY_", "_");
					ReplaceString(activity, sizeof(activity), "_MELEE_", "_");
					ReplaceString(activity, sizeof(activity), "_ITEM1_", "_");
					ReplaceString(activity, sizeof(activity), "_ITEM2_", "_");
					ReplaceString(activity, sizeof(activity), "_ITEM3_", "_");
					ReplaceString(activity, sizeof(activity), "_ITEM4_", "_");
					ReplaceString(activity, sizeof(activity), "_ENGINEER_PDA1_", "_");
					ReplaceString(activity, sizeof(activity), "_ENGINEER_PDA2_", "_");

					int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
					if(weapon != -1)
					{
						BossData boss = FF2R_GetBossData(client);
						if(boss)
						{
							AbilityData ability = boss.GetAbility("special_gordon_viewmodel");
							if(ability.IsMyPlugin())
							{
								if(ability.GetBool("debug"))
									PrintToChat(client, "Activity: '%s'", activity);

								char buffer[64];
								IntToString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), buffer, sizeof(buffer));
								ConfigData cfg = ability.GetSection(buffer);
								if(cfg)
								{
									view_as<ConfigMap>(cfg).Get(activity, activity, sizeof(activity));
								}
							}
						}
					}

					SetAnimation(entity, activity);
				}
			}
		}
	}

	bool gunout;

	if(GravityGunEnabled[client] != -1)
	{
		if(GravityGunEnabled[client] < 0)
		{
			gunout = true;
		}
		else
		{
			int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
			if(weapon != -1)
				gunout = GravityGunEnabled[client] == GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		}
	}

	if(GravityGunHeldProp[client] != -1)
	{
		if(GravityGunDrainCost[client] > 0.0 && GravityGunDrainIn[client] < GetGameTime())
		{
			BossData boss = FF2R_GetBossData(client);
			float rage = GetBossCharge(boss, "0");
			if(rage < GravityGunDrainCost[client])
			{
				gunout = false;
				FF2R_EmitBossSoundToClient(client, "sound_gordon_gravity", client, "fail", client, SNDCHAN_WEAPON);
			}
			else
			{
				SetBossCharge(boss, "0", rage - GravityGunDrainCost[client]);
				GravityGunDrainIn[client] = GetGameTime() + 0.1;
			}
		}

		int entity = EntRefToEntIndex(GravityGunHeldProp[client]);
		if(entity == -1)
		{
			GravityGunHeldProp[client] = -1;
			
			if(gunout && ViewmodelRef[client] != -1)
			{
				int viewmodel = EntRefToEntIndex(ViewmodelRef[client]);
				if(viewmodel != -1)
				{
					SetDefaultAnimation(viewmodel, "ACT_VM_IDLE");
					SetAnimation(viewmodel, "ACT_VM_PRIMARYATTACK");
				}
			}
		}
		else if(!gunout || (!GravityGunHeldButton[client] && (buttons & (IN_ATTACK|IN_ATTACK2))))
		{
			// Drop object
			GravityGunHeldButton[client] = true;
			GravityGunLastProp[client] = GravityGunHeldProp[client];
			GravityGunHeldProp[client] = -1;

			if(gunout && (buttons & IN_ATTACK))
			{
				// Push object
				char classname[64];
				GetEntityClassname(entity, classname, sizeof(classname));

				BossData boss = FF2R_GetBossData(client);
				AbilityData ability = boss.GetAbility("special_gordon_gravity");
				
				float multi = 1.0;
				float power = ability.GetFloat("pushforce", 1000.0);
				ConfigData cfg = FindEntityData(ability, classname);
				if(cfg)
				{
					// If too little rage, push force decreased
					float cost = ability.GetFloat("pushcost") * (cfg.GetFloat("pushcost", 1.0) - 1.0);
					if(cost > 0.0)
					{
						float rage = GetBossCharge(boss, "0");
						if(rage < cost)
						{
							multi = rage / cost;
							power *= multi;
							SetBossCharge(boss, "0", 0.0);
						}
						else
						{
							SetBossCharge(boss, "0", rage - cost);
						}
					}
				}

				float pos[3], vel[3];
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, vel);
				GetAngleVectors(vel, vel, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(vel, power);

				TeleportEntity(entity, _, _, vel);
				
				if(cfg && multi > 0.0)
				{
					float damage = cfg.GetFloat("damage");
					if(damage > 0.0)
					{
						SDKHooks_TakeDamage(entity, client, client, damage * multi, DMG_CRUSH);
					}
				}

				FF2R_EmitBossSoundToAll("sound_gordon_gravity", client, "launch", client, SNDCHAN_WEAPON, 100);

				if(ViewmodelRef[client] != -1)
				{
					int viewmodel = EntRefToEntIndex(ViewmodelRef[client]);
					if(viewmodel != -1)
					{
						SetDefaultAnimation(viewmodel, "ACT_VM_IDLE");
						SetAnimation(viewmodel, "ACT_VM_SECONDARYATTACK");
					}
				}
			}
			else
			{
				if(GravityGunHeldType[client])	// Return velocity
					TeleportEntity(entity, _, _, GravityGunHeldVec[client]);
				
				if(gunout)
				{
					FF2R_EmitBossSoundToAll("sound_gordon_gravity", client, "drop", client, SNDCHAN_WEAPON);
			
					if(ViewmodelRef[client] != -1)
					{
						int viewmodel = EntRefToEntIndex(ViewmodelRef[client]);
						if(viewmodel != -1)
						{
							SetDefaultAnimation(viewmodel, "ACT_VM_IDLE");
							SetAnimation(viewmodel, "ACT_VM_PRIMARYATTACK");
						}
					}
				}
			}

			if(entity <= MaxClients)
				TF2_RemoveCondition(entity, TFCond_Dazed);
		}
		else
		{
			if(GravityGunHeldButton[client])
			{
				// Holding button
				if((buttons & (IN_ATTACK|IN_ATTACK2)) == 0)
					GravityGunHeldButton[client] = false;
			}

			// Hold object
			float ang[3], vec1[3], vec2[3];
			GetClientEyeAngles(client, ang);
			GetEntPropVector(entity, Prop_Send, "m_vecMins", vec1);
			GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vec2);

			float sideways = (90.0 - fabs(ang[0])) / 90.0;	// Looking up moves towards your center
			float upwards = 1.0 - (ang[0] / 45.0);	// Looking downwards atleast at 45 allows you to prop surf
			if(upwards > 1.0)
			{
				upwards = 1.0;
			}
			else if(upwards < 0.0)
			{
				upwards = 0.0;
			}

			float distance = (vec2[0] - vec1[0]) * sideways;

			float dist = (vec2[1] - vec1[1]) * sideways;
			if(distance < dist)
				distance = dist;
			
			dist = (vec2[2] - vec1[2]) * upwards;
			if(distance < dist)
				distance = dist;

			distance += (100.0 * upwards);

			GetAngleVectors(ang, ang, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(ang, distance);

			GetClientEyePosition(client, vec1);
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec2);

			AddVectors(vec1, ang, vec1);
			SubtractVectors(vec1, vec2, vec2);
			ScaleVector(vec2, 10.0);

			TeleportEntity(entity, _, _, vec2);
			
			if(HasEntProp(entity, Prop_Send, "m_iDeflected"))
				SDKCall_Deflected(entity, client, vec2);

			if(entity > MaxClients && !GravityGunHeldType[client])
			{
				float vec3[3];
				if(buttons & IN_ATTACK3)
					vec3[1] += 150.0;

				if(buttons & IN_RELOAD)
					vec3[2] -= 150.0;
				
				VScript_SetPhysAngularVelocity(entity, vec3);
			}
		}
	}
	else if(gunout)
	{
		if(GravityGunHeldButton[client])
		{
			// Holding button
			if((buttons & (IN_ATTACK|IN_ATTACK2)) == 0)
			{
				GravityGunHeldButton[client] = false;
				PrintCenterText(client, "");
			}
		}
		else if(buttons & (IN_ATTACK|IN_ATTACK2))
		{
			// Pickup object
			float pos[3], ang[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, ang);

			// TODO: Holding M1 cooldown

			Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_SOLID, RayType_Infinite, Trace_DontHitEntity, client);
			if(TR_DidHit(trace))
			{
				BossData boss = FF2R_GetBossData(client);
				AbilityData ability = boss.GetAbility("special_gordon_gravity");
				float distance = ability.GetFloat((buttons & IN_ATTACK2) ? "pullrange" : "pushrange", FAR_FUTURE);
				distance *= distance;
				
				TR_GetEndPosition(ang, trace);
				if(GetVectorDistance(pos, ang, true) < distance)
				{
					int entity = TR_GetEntityIndex(trace);
					if(entity)
					{
						AttemptPickup(client, entity, buttons, boss, ability);
					}
					else
					{
						char buffer[4];
						for(entity = MaxClients	+ 1; entity < 2048; entity++)
						{
							// If their valid
							if(!IsValidEntity(entity))
								continue;
							
							// If they even have a model
							if(!GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, sizeof(buffer)) || !StrEqual(buffer, "mod", false))
								continue;

							// Replicated origin to the player
							if(!HasEntProp(entity, Prop_Send, "m_vecOrigin"))
								continue;

							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
							if(GetVectorDistance(pos, ang, true) < 3000.0)
							{
								if(AttemptPickup(client, entity, buttons, boss, ability))
									break;
							}
						}
					}
				}
			}
			delete trace;
		}
	}
}

static bool AttemptPickup(int client, int entity, int buttons, BossData boss, AbilityData ability)
{
	char classname[64];
	if(GetEntityClassname(entity, classname, sizeof(classname)))
	{
		bool success, failed;
		ConfigData cfg = FindEntityData(ability, classname);

		float extracost = cfg ? cfg.GetFloat("objcost") : 0.0;
		if(extracost)
		{
			if(!HasEntProp(entity, Prop_Send, "m_bDisabled") || GetEntProp(entity, Prop_Send, "m_bDisabled"))
				extracost = 0.0;
		}
		
		if(extracost > 0.0 && (ability.GetFloat("convert") < 0.0 || GetEntProp(entity, Prop_Send, "m_iTeamNum") == GetClientTeam(client)))
		{
			PrintCenterText(client, "%s is locked in place", classname);
			failed = true;
		}
		else if(cfg && cfg.GetBool("convert"))
		{
			// Convert object
			float cost = ability.GetFloat("convert") + extracost;
			if(cost < 0.0)
			{
				PrintCenterText(client, "%s is locked in place", classname);
				failed = true;
			}
			else if(cost != 0.0 && GetBossCharge(boss, "0") < cost)
			{
				PrintCenterText(client, "Need %d%% RAGE to disassemble %s", RoundFloat(cost), classname);
				failed = true;
			}
			else
			{
				char buffer[PLATFORM_MAX_PATH];
				if(GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, sizeof(buffer)) && (buffer[0] == '*' || (ReplaceStringEx(buffer, sizeof(buffer), ".mdl", ".phy") != -1 && FileExists(buffer, true))))
				{
					int converter = CreateEntityByName("phys_convert");
					if(converter != -1)
					{
						static int index;
						FormatEx(classname, sizeof(classname), "_ff2gordon%d", index++);
						DispatchKeyValue(converter, "target", classname);
						DispatchKeyValue(converter, "massoverride", "10000");
						DispatchSpawn(converter);

						DispatchKeyValue(entity, "targetname", classname);

						AcceptEntityInput(converter, "ConvertTarget");
						RemoveEntity(converter);

						if(cost > 0.0)
							SetBossCharge(boss, "0", GetBossCharge(boss, "0") - cost);
						
						return true;
					}
				}
				else
				{
					int pos1 = FindCharInString(buffer, '/', true);
					int pos2 = FindCharInString(buffer, '\\', true);
					if(pos2 > pos1)
						pos1 = pos2;
					
					if(pos1 != -1)
						strcopy(buffer, sizeof(buffer), buffer[pos1 + 1]);
					
					ReplaceStringEx(buffer, sizeof(buffer), ".phy", ".mdl");
					PrintCenterText(client, "Can't pickup %s", buffer);
					failed = true;
				}
			}
		}
		else if(buttons & IN_ATTACK2)
		{
			// Pull object
			if(cfg && cfg.GetBool("pickup", true))
			{
				float total = (ability.GetFloat("pullcost") * cfg.GetFloat("pullcost", 1.0) * 3.0) + extracost;
				if(GetBossCharge(boss, "0") < total)
				{
					PrintCenterText(client, "Need %d%% RAGE to pickup %s", RoundFloat(total), classname);
					failed = true;
				}
				else
				{
					FF2R_EmitBossSoundToAll("sound_gordon_gravity", client, "pickup", client, SNDCHAN_WEAPON);
					GravityGunHeldButton[client] = true;
					success = true;
				}
			}
			else
			{
				PrintCenterText(client, "Can't pickup %s", classname);
				failed = true;
			}
		}
		else
		{
			// Push object
			if(cfg && cfg.GetBool("push", true))
			{
				float rage = GetBossCharge(boss, "0");
				float cost = ability.GetFloat("pushcost");
				float total = (cost * cfg.GetFloat("pushcost", 1.0)) + extracost;
				if(rage < total)
				{
					PrintCenterText(client, "Need %d%% RAGE to push %s", RoundFloat(total), classname);
					failed = true;
				}
				else
				{
					success = true;
					SetBossCharge(boss, "0", rage - ((total < cost) ? total : cost));
				}
			}
			else
			{
				PrintCenterText(client, "Can't push %s", classname);
				failed = true;
			}
		}

		if(success)
		{
			if(HasEntProp(entity, Prop_Data, "m_hPhysicsAttacker"))
				SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
			
			if(HasEntProp(entity, Prop_Send, "m_iDeflected"))
				SDKCall_Deflected(entity, client, {0.0, 0.0, 0.0});
			
			if(entity <= MaxClients)
			{
				if((buttons & IN_ATTACK2) && !TF2_IsPlayerInCondition(entity, TFCond_Bonked) && !TF2_IsPlayerInCondition(entity, TFCond_MegaHeal))
					TF2_StunPlayer(entity, 14.9, 0.0, TF_STUNFLAGS_LOSERSTATE, client);
			}
			else if(cfg.GetBool("movetype", true))
			{
				AcceptEntityInput(entity, "EnableMotion");
				SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
			}

			if(extracost)
			{
				SetBossCharge(boss, "0", GetBossCharge(boss, "0") - extracost);
				SetEntProp(entity, Prop_Send, "m_bDisabled", true);
			}

			if(cfg.GetBool("return"))
			{
				GetEntPropVector(entity, Prop_Data, "m_vecVelocity", GravityGunHeldVec[client]);
				GravityGunHeldType[client] = true;
			}
			else
			{
				GetClientEyeAngles(client, GravityGunHeldVec[client]);
				GravityGunHeldType[client] = false;
			}
			
			if(ViewmodelRef[client] != -1)
			{
				int viewmodel = EntRefToEntIndex(ViewmodelRef[client]);
				if(viewmodel != -1)
				{
					SetDefaultAnimation(viewmodel, "ACT_VM_RELOAD");
					SetAnimation(viewmodel, "ACT_VM_PRIMARYATTACK");
				}
			}

			GravityGunHeldProp[client] = EntIndexToEntRef(entity);
			GravityGunDrainIn[client] = 0.0;
			GravityGunDrainCost[client] = ability.GetFloat("pullcost") * cfg.GetFloat("pullcost", 1.0) * 0.1;
			PrintCenterText(client, "");
			return true;
		}
		else if(failed)
		{
			GravityGunHeldButton[client] = true;
			FF2R_EmitBossSoundToClient(client, "sound_gordon_gravity", client, "fail", client, SNDCHAN_WEAPON);
			
			if(ViewmodelRef[client] != -1)
			{
				int viewmodel = EntRefToEntIndex(ViewmodelRef[client]);
				if(viewmodel != -1)
					SetAnimation(viewmodel, "ACT_VM_PRIMARYATTACK");
			}

			return true;
		}
	}

	return false;
}

static ConfigData FindEntityData(AbilityData ability, const char[] classname)
{
	char currentmatch[64];

	ConfigData cfg = ability.GetSection("Entities");
	if(cfg)
	{
		StringMapSnapshot snap = cfg.Snapshot();
		
		int entries = snap.Length;
		if(entries)
		{
			int size;
			for(int i; i < entries; i++)
			{
				int length = snap.KeyBufferSize(i);
				if(size > length)
					continue;
				
				char[] matchname = new char[length];
				snap.GetKey(i, matchname, length);
				
				char[] match = new char[length];
				strcopy(match, length, matchname);

				int amount = ReplaceString(match, length, "*", NULL_STRING);
				if(StrEqual(classname, match, false) || (amount == 1 && !StrContains(classname, match, false)) || (amount > 1 && StrContains(classname, match, false) != -1))
				{
					size = strcopy(currentmatch, sizeof(currentmatch), matchname);
				}
			}
		}
		
		delete snap;
	}

	if(!currentmatch[0])
		return null;
	
	return cfg.GetSection(currentmatch);
}

void Gordon_WeaponSwitch(int client, int weapon)
{
	if(OverlayTipTimer[client] && OverlayTipCycle[client] != -1)
		EndTipOverlay(client);
	
	int setviewmodel = -1;

	if(ViewmodelRef[client] != -1)
	{
		int entity = EntRefToEntIndex(ViewmodelRef[client]);
		if(entity != -1)
			RemoveEntity(entity);
		
		ViewmodelRef[client] = -1;
		setviewmodel = 0;
	}
	
	if(weapon != -1)
	{
		BossData boss = FF2R_GetBossData(client);
		if(boss)
		{
			AbilityData ability = boss.GetAbility("special_gordon_viewmodel");
			if(ability.IsMyPlugin())
			{
				char buffer[PLATFORM_MAX_PATH];
				IntToString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), buffer, sizeof(buffer));
				ConfigData cfg = ability.GetSection(buffer);
				if(cfg)
				{
					cfg.GetString("model", buffer, sizeof(buffer));
					if(buffer[0])
					{
						ApplyViewmodel(client, buffer, cfg.GetFloat("offset", 0.0), cfg.GetInt("skin"));
						setviewmodel = EF_NODRAW;
					}
				}

				// Fixes client-side period where the weapon is still visible
				int entity, i;
				while(TF2_GetItem(client, entity, i))
				{
					if(weapon == entity)
					{
						SetEntityRenderMode(entity, RENDER_NORMAL);
						SetEntityRenderColor(entity, _, _, _, 255);
					}
					else
					{
						SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
						SetEntityRenderColor(entity, _, _, _, 0);
					}
				}
			}
		}
	}

	if(setviewmodel != -1)
	{
		int viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
		if(viewmodel != -1)
			SetEntProp(viewmodel, Prop_Send, "m_fEffects", setviewmodel);
	}
}

void Gordon_ConditionAdded(int client, TFCond cond)
{
	if(HevSuitEnabled[client] > 0)
	{
		switch(cond)
		{
			case TFCond_Jarated, TFCond_Milked, TFCond_Gas:
				FF2R_EmitBossSoundToAll("sound_gordon_hevsuit", client, "liquid", client, SNDCHAN_VOICE, 140);
		}
	}
}

void Gordon_ConditionRemoved(int client, TFCond cond)
{
	if(cond == TFCond_Taunting && ViewmodelRef[client] != -1)
	{
		int viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
		if(viewmodel != -1)
			SetEntProp(viewmodel, Prop_Send, "m_fEffects", EF_NODRAW);
	}
}
/*
static void PlayViewmodelAnim(int client, const char[] anim)
{
	if(ViewmodelRef[client] != -1)
	{
		int entity = EntRefToEntIndex(ViewmodelRef[client]);
		if(entity != -1)
		{
			SetVariantString(anim);
			AcceptEntityInput(entity, "SetAnimation");
		}
	}
}
*/
static void SetDefaultAnimation(int entity, const char[] anim)
{
	SetVariantString(anim);
	AcceptEntityInput(entity, "SetDefaultAnimation");
	DispatchKeyValue(entity, "DefaultAnim", anim);
}

static void SetAnimation(int entity, const char[] anim)
{
	SetVariantString(anim);
	AcceptEntityInput(entity, "SetAnimation");
}

static void ApplyViewmodel(int client, const char[] model, float offset, int skin)
{
	int entity = CreateEntityByName("prop_dynamic");
	if(entity != -1)
	{
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		
		DispatchKeyValue(entity, "model", model);
		DispatchKeyValueInt(entity, "skin", skin);
		DispatchKeyValue(entity, "disablereceiveshadows", "0");
		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchKeyValue(entity, "DefaultAnim", "ACT_VM_IDLE");
		
		float pos[3], ang[3];
		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, ang);
		
		if(offset)
		{
			float vec[3];
			GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(vec, offset);
			AddVectors(pos, vec, pos);
		}
		
		TeleportEntity(entity, pos, ang, NULL_VECTOR);
		DispatchSpawn(entity);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", GetEntPropEnt(client, Prop_Send, "m_hViewModel"));

		ViewmodelRef[client] = EntIndexToEntRef(entity);
		
		SDKHook(entity, SDKHook_SetTransmit, ViewmodelTransmit);

		//SetVariantString("ACT_VM_IDLE");
		//AcceptEntityInput(entity, "SetDefaultAnimation");

		SetAnimation(entity, "ACT_VM_DRAW");
	}
}

static Action ViewmodelTransmit(int entity, int client)
{
	if(client < 1 || client > MaxClients)
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(owner == -1 || !IsPlayerAlive(owner))
	{
		RemoveEntity(entity);
		return Plugin_Handled;
	}
	
	if(client == owner)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Taunting) || GetEntProp(client, Prop_Send, "m_nForceTauntCam"))
			return Plugin_Handled;
		
		return Plugin_Continue;
	}

	if(GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == owner && GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
		return Plugin_Continue;
	
	return Plugin_Handled;
}