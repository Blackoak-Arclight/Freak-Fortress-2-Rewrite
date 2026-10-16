/*
	"rage_glitched_transform"
	{
		"slot"			"0"		// Ability slot
		"cooldown"		"-1.0"	// Cooldown before another transform can trigger
		"duration"		"-1.0"	// Duration before swapping back to previous form

		"model"			""		// Player model
		"class"			""		// Player class
		"resize"		"1.0"	// Player resize
		
		"tf_weapon_shovel"
		{
			// Weapon Params (rage_new_weapon)
		}

		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"rage_glitched_classrage"
	{
		"slot"			"0"		// Ability slot

		// Ability slot to activate based on current class
		"scout"			"31"
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"special_glitched_onkill"
	{
		"start"			"11"	// Ability slot to trigger on round start

		// Ability slot to activate on melee kill
		"scout"			"21"
		
		"plugin_name"	"ff2r_arclight_abilities"
	}
*/

#pragma semicolon 1
#pragma newdecls required

static Handle TransformTimer[MAXTF2PLAYERS];
static float TransformCooldown[MAXTF2PLAYERS];
static int PreviousTransform[MAXTF2PLAYERS] = {1, ...};
static int CurrentTransform[MAXTF2PLAYERS] = {1, ...};

void Glitched_BossCreated(int client, BossData cfg, bool setup)
{
	if(!setup)
	{
		AbilityData ability = cfg.GetAbility("special_glitched_onkill");
		if(ability.IsMyPlugin())
			BossTimers[client].Push(CreateTimer(0.0, BossCreatedFrame, client));
	}
}

static Action BossCreatedFrame(Handle timer, int client)
{
	BossTimers[client].Erase(BossTimers[client].FindValue(timer));

	BossData boss = FF2R_GetBossData(client);
	if(boss != null)
	{
		AbilityData ability = boss.GetAbility("special_glitched_onkill");
		if(ability.IsMyPlugin())
		{
			int slot = ability.GetInt("start", -69420);
			if(slot != -69420)
				FF2R_DoBossSlot(client, slot);
		}
	}

	return Plugin_Continue;
} 

void Glitched_Ability(int client, const char[] ability, AbilityData cfg)
{
	if(!StrContains(ability, "rage_glitched_transform", false))
	{
		Transform(client, ability, cfg);
	}
	else if(!StrContains(ability, "rage_glitched_classrage", false))
	{
		int class = view_as<int>(TF2_GetPlayerClass(client));
		if(class < 0 || class >= sizeof(ClassName))
			class = -1;
		
		char buffer[16] = "other";
		if(class != -1)
			TF2Tools_GetClassName(view_as<TFClassType>(class), buffer, sizeof(buffer));
		
		int thisslot = cfg.GetInt("slot");
		int slot = cfg.GetInt(buffer, thisslot);
		if(slot == thisslot && class != -1)
			slot = cfg.GetInt("other", thisslot);
		
		if(slot != thisslot)
			FF2R_DoBossSlot(client, slot);
	}
}

void Glitched_BossRemoved(int client)
{
	TransformCooldown[client] = 0.0;
	delete TransformTimer[client];
	PreviousTransform[client] = 1;
	CurrentTransform[client] = 1;
}

void Glitched_PlayerDeath(int victim, int attacker, int damagetype)
{
	if(victim != attacker && victim != 0 && attacker != 0 && ((damagetype & DMG_CLUB) || (damagetype & DMG_SLASH)))
	{
		BossData boss = FF2R_GetBossData(attacker);
		if(boss != null)
		{
			AbilityData ability = boss.GetAbility("special_glitched_onkill");
			if(ability.IsMyPlugin())
			{
				int class = view_as<int>(TF2_GetPlayerClass(victim));
				if(class < 0 || class >= sizeof(ClassName))
					class = -1;
				
				char buffer[16] = "other";
				if(class != -1)
					TF2Tools_GetClassName(view_as<TFClassType>(class), buffer, sizeof(buffer));

				int slot = ability.GetInt(buffer, -69420);
				if(slot == -69420 && class != -1)
					slot = ability.GetInt("other", -69420);
				
				if(slot != -69420)
				{
					float test = TransformCooldown[attacker];
					FF2R_DoBossSlot(attacker, slot);
					if(TransformCooldown[attacker] != test)
						CreateTimer(0.05, Timer_RemoveRagdoll, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

static Action Timer_RemoveRagdoll(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(ragdoll != -1)
			AcceptEntityInput(ragdoll, "Kill");
	}
	return Plugin_Continue;
}

static void Transform(int client, const char[] ability, AbilityData cfg)
{
	if(TransformCooldown[client] > GetGameTime())
	{
		// Extend duration if we're on a cooldown
		if(TransformTimer[client] != null)
		{
			float duration = cfg.GetFloat("duration");
			float cooldown = cfg.GetFloat("cooldown");
			if(duration > 0.0 && cooldown > 0.0)
			{
				TransformCooldown[client] = GetGameTime() + cooldown;

				delete TransformTimer[client];
				TransformTimer[client] = CreateTimer(duration, EndTransform, client);
			}
		}
	}
	else
	{
		PreviousTransform[client] = CurrentTransform[client];
		CurrentTransform[client] = ability[0] ? cfg.GetInt("slot") : 1;
		
		TransformCooldown[client] = GetGameTime() + cfg.GetFloat("cooldown");
		
		float duration = cfg.GetFloat("duration");
		if(duration > 0.0)
		{
			delete TransformTimer[client];
			TransformTimer[client] = CreateTimer(duration, EndTransform, client);
		}

		char buffer[PLATFORM_MAX_PATH];
		if(cfg.GetString("class", buffer, sizeof(buffer)) != 0)
		{
			TFClassType class = TF2Tools_GetClass(buffer);
			if(class != TF2_GetPlayerClass(client))
				TF2_SetPlayerClass(client, class, false, false);
		}

		if(cfg.GetString("model", buffer, sizeof(buffer)) > 4)
		{
			SetVariantString(buffer);
			AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
		}

		TF2_RemoveAllItems(client);
		TF2_RemoveAllWearables(client, .actions = false);

		StringMapSnapshot snap = cfg.Snapshot();
		
		char classname[36];
		bool equip = true;
		int length = snap.Length;
		for(int i = 0; i < length; i++)
		{
			int size = snap.KeyBufferSize(i);
			char[] section = new char[size];
			snap.GetKey(i, section, size);

			if(!StrContains(section, "weapon") || !StrContains(section, "wearable") || !StrContains(section, "tf_") || !StrContains(section, "tf2c_") || StrEqual(section, "saxxy"))
			{
				ConfigData weapon = cfg.GetSection(section);

				if(!weapon.GetString("classname", classname, sizeof(classname)))
					weapon.GetString("name", classname, sizeof(classname), section);
				
				TFClassType class = TF2_GetPlayerClass(client);
				GetClassWeaponClassname(class, classname, sizeof(classname));
				
				TF2Items_CreateFromCfg(client, classname, weapon, equip);
			}
		}

		delete snap;

		FF2R_UpdateBossAttributes(client);

		float size = ability[0] ? cfg.GetFloat("resize") : 1.0;
		if(size > 0.0)
		{
			if(!AttemptResize(client, size))
			{
				// Try to find alt spots
				float pos[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				pos[2] += 20.0;

				if(IsSpotSafe(client, pos, size))
				{
					TeleportEntity(client, pos);
					SetEntPropFloat(client, Prop_Send, "m_flModelScale", size);
				}
				else if(duration > 0.0)
				{
					// Resize failed, lock duration-based rage
					TF2_StunPlayer(client, duration, 1.0, TF_STUNFLAG_SLOWDOWN);
					TF2_AddCondition(client, TFCond_MegaHeal, duration);
				}
			}
		}
	}
}

static Action EndTransform(Handle timer, int client)
{
	TransformTimer[client] = null;

	if(PreviousTransform[client] != 1)
	{
		int slot = PreviousTransform[client];
		PreviousTransform[client] = 1;
		FF2R_DoBossSlot(client, slot);
	}
	else
	{
		Transform(client, "", view_as<AbilityData>(FF2R_GetBossData(client)));
	}

	return Plugin_Continue;
}
