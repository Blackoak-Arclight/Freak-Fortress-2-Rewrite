/*
	Noelle from Marxvee

	"rage_noelle_ams"
	{
		"slot"		"0"			// Ability slot, if 0, will override "ragemode" and "ragemin" values
		"altfire"	"false"		// Can use alt-fire to activate/cycle abilities
		"reload"	"true"		// Can use reload to activate/cycle abilities
		"special"	"true"		// Can use special attack to activate/cycle abilities
		"cycler"	"false"		// Force to use a cycler regardless of other factors
		
		"spells"
		{
			"0"	// Sorted in number and ABC order
			{
				"name"		"RAGE"				// Name, can use "name_en", etc. If left blank, section name is used instead
				"desc"		"Use your magic"	// Description, can use "desc_en", etc.
				"delay"		"10.0"				// Initial cooldown
				"cooldown"	"30.0"				// Cooldown on use
				"cost"		"100.0"				// RAGE cost to use
				"consume"	"true"				// Consumes RAGE on use
				"flags"		"3"					// Casting flags
				// 1: Magic (Sapper effect prevents casting)
				// 2: Mind (Stun effects DOESN'T prevent casting)
				// 4: Summon (Requires a dead summonable player to cast)
				// 8: Partner (Requires a teammate boss alive to cast)
				// 16: Last Life (Requires a single life left to cast)
				// 32: Grounded (Requires being on the ground to cast)
				// 32768: Snowgrave
				
				"cast"		"8"		// Ability slot to activate on cast.
				"nocast"	"9"		// Ability slot to activate trying to cast but unable.
				"radius"	"128.0"	// Cast display radius
				"maxdist"	"256.0"	// Cast display range
			}
		}
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	
	"special_noelle_effects"
	{
		"resize"		"0.75"	// Resize the player

		"graze_size"	"80.0"	// Graze range
		"graze_base"	"0.05"	// RAGE gain per tick
		"graze_add"		"0.01"	// Additional RAGE for each player

		"levelup"		"0.02"	// Max health increase on kill
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	"sound_graze"
	{
	}


	"special_noelle_defend"
	{
		"button"		"25"	// Button type (11=M2, 13=Reload, 25=M3)
		"cooldown"		"15.0"	// Cooldown
		"delay"			"15.0"	// Initial delay
		"duration"		"8.0"	// Effect duration
		"rage"			"16.0"	// Rage gain
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	"sound_defend"
	{
	}


	"rage_noelle_iceshock"
	{
		"slot"			"0"											// Ability slot
		"radius"		"256.0"										// Radius
		"maxdist"		"1000.0"									// Range
		"model"			"models/noname/snowdrop/snowflake-3d.mdl"	// Snowflake model
		"damage"		"80.0"										// Damage
		"slow"			"2.0"										// Slow duration
		
		"plugin_name"	"ff2r_arclight_abilities"
	}


	"rage_noelle_sleepmist"
	{
		"slot"			"0"		// Ability slot
		"radius"		"128.0"	// Radius
		"maxdist"		"500.0"	// Range
		"duration"		"4.0"	// Stun duration
		
		"plugin_name"	"ff2r_arclight_abilities"
	}


	"rage_noelle_healprayer"
	{
		"slot"			"0"			// Ability slot
		"amount"		"1000.0"	// Heal amount
		
		"plugin_name"	"ff2r_arclight_abilities"
	}


	"rage_noelle_snowgrave"
	{
		"slot"			"0"										// Ability slot
		"radius"		"768.0"									// Radius
		"maxdist"		"1000.0"								// Range
		"model"			"models/noname/megapony/gem_rocket.mdl"	// Ice model

		"require"		"0.8"									// Frozen players required
		"dumpmodel"		"models/props_frontline/dumpster.mdl"	// Dumpster model
		"thinkafter"	"true"									// Block boss after use

		"msg_appear_boss"		"* (A mysterious dumpster appeared. Go to it.)"
		"msg_appear_player"		"A mysterious dumpster appeared. Defend it."
		"msg_collect"			"* (Noelle got the ThornRing.)"
		"msg_transfer_boss"		"* (Transferring KROMER... %d left.)"
		"msg_attack_player"		"Push Noelle back from the dumpster before it's too late!"
		"msg_defended_player"	"Currently defending the dumpster..."
		"msg_defended_boss"		"* (They're defending the dumpster. Stop them.)"
		"msg_transfer_player"	"Stealing KROMER... %d left."
		
		"plugin_name"	"ff2r_arclight_abilities"
	}

	"sound_dumpster_collect"
	{
	}
	"sound_dumpster_noise"
	{
	}
	"sound_dumpster_spawn"
	{
	}
	"sound_snowgrave"
	{
	}
	"sound_weird"
	{
	}
	"sound_weirdbackout"
	{
	}
	"sound_battle_start"
	{
	}
	"sound_bgm_battle"
	{
	}
	"sound_bgm_alt"
	{
	}
	"sound_last_battle"
	{
	}
	"sound_lastman"
	{
	}
*/

#pragma semicolon 1
#pragma newdecls required

#define AMS_DENYUSE	"common/wpn_denyselect.wav"
#define AMS_SWITCH	"common/wpn_moveselect.wav"

#define MAG_MAGIC		0x0001	// Can be blocked by sapper effect
#define MAG_MIND		0x0002	// Can't be blocked by stun effects
#define MAG_SUMMON		0x0004	// Require dead players to use
#define MAG_PARTNER		0x0008	// Require an teammate to use
#define MAG_LASTLIFE	0x0010	// Require having no extra lives left
#define MAG_GROUND		0x0020	// Require being on the ground
#define MAG_SNOWGRAVE	0x8000	// Special (32768)

static Handle SyncHud[2];
static int BEACON_BEAM_GRAZE;
static int BEACON_BEAM;
static int BEACON_HALO;
static int BEACON_POINT;

static int FreezeKnife = -1;
static int WeirdState;
static int SnowGraveState;
static float SnowGraveRequire;
static int FrozenVictims;
static Handle ColdTimer;
static int SnowGraveTarget;
static int SnowGraveCaster;
static int SnowGravePhase;
static float SnowGravePhaseChangeTime;
static float SnowGrave_Location[3];
static char SnowGrave_Model[PLATFORM_MAX_PATH];
static int DumpsterRef = -1;
static float DumpsterPos[3];
static float DumpsterSoundIn;
static float DumpsterMsgIn;
static int DumpsterKROMER;
static char DumpsterModel[PLATFORM_MAX_PATH];
static char MessageAppearedBoss[128];
static char MessageAppearedPlayer[128];
static char MessageDefendedBoss[128];
static char MessageDefendedPlayer[128];
static char MessageKROMERBoss[128];
static char MessageKROMERPlayer[128];
static char MessageAttackingPlayer[128];
static char MessageGrave[128];

static int HasAbility[MAXTF2PLAYERS];
static bool PressedInspectKey[MAXTF2PLAYERS];

static int GrazeCount[MAXTF2PLAYERS];
static int GrazeTriggerRef[MAXTF2PLAYERS] = {-1, ...};
static float GrazeBaseRage[MAXTF2PLAYERS];
static float GrazeBaseAdd[MAXTF2PLAYERS];

static int DefendButton[MAXTF2PLAYERS];

static int MusicPlayer;
static Handle BattleMusicTimer[MAXTF2PLAYERS];
static bool RoundActive;

void Noelle_PluginStart()
{
	SyncHud[0] = CreateHudSynchronizer();
	SyncHud[1] = CreateHudSynchronizer();
	RoundActive = true;
}

void Noelle_MapStart()
{
	BEACON_BEAM_GRAZE = PrecacheModel("materials/sprites/laser.vmt");
	BEACON_BEAM = PrecacheModel("materials/sprites/lgtning.vmt");
	BEACON_HALO = PrecacheModel("materials/sprites/halo01.vmt");
	BEACON_POINT = PrecacheModel("materials/sprites/blueglow2.vmt");
}

void Noelle_PluginEnd()
{
	if(IsValidEntity(FreezeKnife))
		RemoveEntity(FreezeKnife);
}

void Noelle_RoundStart()
{
	if(SnowGraveState > 2)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				FF2R_SetClientHud(client, true);
		}
	}
	else
	{
		delete ColdTimer;
	}

	if(WeirdState > 1)
	{
		RemoveCommandListener(BlockKillCommand, "kill");
		RemoveCommandListener(BlockKillCommand, "explode");
		RemoveCommandListener(BlockKillCommand, "spectate");
		RemoveCommandListener(BlockKillCommand, "jointeam");
		RemoveCommandListener(BlockKillCommand, "autoteam");
	}

	WeirdState = 0;
	SnowGraveState = 0;
	RoundActive = true;
}

void Noelle_RoundEnd()
{
	RoundActive = false;
	MusicPlayer = 0;

	for(int client = 1; client <= MaxClients; client++)
	{
		delete BattleMusicTimer[client];
	}
}

void Noelle_BossCreated(int client, BossData boss, bool setup)
{
	if(!MusicPlayer && boss.GetSection("sound_bgm_alt"))
		MusicPlayer = client;
	
	AbilityData ability = boss.GetAbility("special_noelle_effects");
	if(ability.IsMyPlugin())
	{
		float size = ability.GetFloat("resize", 1.0);
		if(size != 1.0)
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", size);
			UpdatePlayerHitbox(client, size);
		}

		if(GrazeTriggerRef[client] == -1 || !IsValidEntity(GrazeTriggerRef[client]))
		{
			GrazeCount[client] = 0;
			GrazeBaseRage[client] = ability.GetFloat("graze_base", 0.05);
			GrazeBaseAdd[client] = ability.GetFloat("graze_base", 0.01);
			
			size = ability.GetFloat("graze_size", 80.0);
			if(size)
			{
				float clientpos[3];
				GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientpos);

				int trigger = CreateEntityByName("trigger_multiple"); //create our trigger box.
				DispatchKeyValue(trigger, "spawnflags", "1");
				PrecacheModel("models/error.mdl");
				SetEntityModel(trigger, "models/error.mdl");
				DispatchSpawn(trigger);

				TeleportEntity(trigger, clientpos);
				SetVariantString("!activator");
				AcceptEntityInput(trigger, "SetParent", client, trigger);
				float mins[3];
				float maxs[3];
				FormatBounds(mins, maxs, size);
				SetEntPropVector(trigger, Prop_Send, "m_vecMins", mins);
				SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", maxs);
				ActivateEntity(trigger);
				int m_fEffects = GetEntProp(trigger, Prop_Send, "m_fEffects");
				m_fEffects |= 32;
				SetEntProp(trigger, Prop_Send, "m_fEffects", m_fEffects);
				SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
				SDKHook(trigger, SDKHook_StartTouch, OnTriggerOverlapStart);
				SDKHook(trigger, SDKHook_EndTouch, OnTriggerOverlapEnd);

				GrazeTriggerRef[client] = EntIndexToEntRef(trigger);
			}
		}

		CreateTimer(0.2, SwitchToMeleeTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}

	if(!setup || FF2R_GetGamemodeType() != 2)
	{
		if(!DefendButton[client])
		{
			ability = boss.GetAbility("special_noelle_defend");
			if(ability.IsMyPlugin())
			{
				DefendButton[client] = ability.GetInt("button", 25);

				float delay = ability.GetFloat("delay");
				if(delay > 0.0)
					ability.SetFloat("delayfor", delay + GetGameTime());
				
				FF2R_SetClientHud(client, false);
			}
		}
		
		if(!SnowGraveState)
		{
			ability = boss.GetAbility("rage_noelle_snowgrave");
			if(ability.IsMyPlugin())
			{
				delete ColdTimer;
				FrozenVictims = 0;
				SnowGraveRequire = ability.GetFloat("require");

				SnowGraveState = 1;
				ability.GetString("dumpmodel", DumpsterModel, sizeof(DumpsterModel), "models/error.mdl");
				if(DumpsterModel[0])
					PrecacheModel(DumpsterModel);
				
				ability.GetString("msg_appear_boss", MessageAppearedBoss, sizeof(MessageAppearedBoss));
				ability.GetString("msg_appear_player", MessageAppearedPlayer, sizeof(MessageAppearedPlayer));
				ability.GetString("msg_defended_boss", MessageDefendedBoss, sizeof(MessageDefendedBoss));
				ability.GetString("msg_defended_player", MessageDefendedPlayer, sizeof(MessageDefendedPlayer));
				ability.GetString("msg_attack_player", MessageAttackingPlayer, sizeof(MessageAttackingPlayer));
				ability.GetString("msg_transfer_boss", MessageKROMERBoss, sizeof(MessageKROMERBoss));
				ability.GetString("msg_transfer_player", MessageKROMERPlayer, sizeof(MessageKROMERPlayer));
				ability.GetString("msg_collect", MessageGrave, sizeof(MessageGrave));
			}
		}
		
		if(!HasAbility[client])
		{
			ability = boss.GetAbility("rage_noelle_ams");
			if(ability.IsMyPlugin())
			{
				HasAbility[client] = -1;
				
				bool medic;
				int buttons;
				if(ability.GetInt("slot") == 0)
				{
					boss.SetInt("ragemode", 1);
					buttons++;
					medic = true;
				}
				
				if(ability.GetBool("altfire", false))
					buttons++;
				
				if(ability.GetBool("reload", true))
					buttons++;
				
				if(ability.GetBool("special", true))
					buttons++;
				
				ConfigData cfg = ability.GetSection("spells");
				if(cfg)
				{
					SortedSnapshot snap = CreateSortedSnapshot(cfg);
					
					int entries = snap.Length;
					if(entries)
					{
						float gameTime = GetGameTime();
						for(int i; i < entries; i++)
						{
							int length = snap.KeyBufferSize(i)+1;
							char[] key = new char[length];
							snap.GetKey(i, key, length);
							
							ConfigData spell = cfg.GetSection(key);
							if(spell)
							{
								float cost = spell.GetFloat("cost");
								
								float delay = spell.GetFloat("delay");
								if(delay > 0.0)
									spell.SetFloat("delayfor", delay + gameTime);
								
								if(medic && !i)
									boss.SetFloat("ragemin", cost);
							}
						}
						
						if(entries > buttons || ability.GetBool("cycler"))
						{
							HasAbility[client] = entries;
							ChangeAbility(client, boss, ability, cfg, snap, false);
						}
						
						delete snap;
						return;
					}
					
					delete snap;
				}
				
				HasAbility[client] = 0;
			}
		}
	}
}

static Action SwitchToMeleeTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(weapon != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
		{
			if(weapon != -1)
				TF2U_SetPlayerActiveWeapon(client, weapon);
			
			return Plugin_Continue;
		}
	}

	return Plugin_Stop;
}

void Noelle_Ability(int client, const char[] ability, AbilityData cfg)
{
	if(HasAbility[client] && !StrContains(ability, "rage_noelle_ams", false))
	{
		ConfigData spells = cfg.GetSection("spells");
		if(spells)
		{
			bool hud;
			SortedSnapshot snap;
			
			if(HasAbility[client] != -1)
			{
				snap = CreateSortedSnapshot(spells);
				if(snap.Length >= HasAbility[client])
					hud = ActivateAbility(client, FF2R_GetBossData(client), spells, snap, HasAbility[client] - 1, GetGameTime());
			}
			else if(cfg.GetInt("slot") == 0)
			{
				snap = CreateSortedSnapshot(spells);
				hud = ActivateAbility(client, FF2R_GetBossData(client), spells, snap, 0, GetGameTime());
			}
			
			delete snap;
			
			if(hud)
				cfg.SetFloat("hudin", 0.0);
		}
	}
	else if(!StrContains(ability, "rage_noelle_iceshock", false))
	{
		IceShock(client, ability, cfg);
	}
	else if(!StrContains(ability, "rage_noelle_sleepmist", false))
	{
		SleepMist(client, cfg);
	}
	else if(!StrContains(ability, "rage_noelle_healprayer", false))
	{
		HealPrayer(client, cfg);
	}
	else if(StrEqual(ability, "rage_noelle_snowgrave", false))
	{
		SnowGraveStart(client, cfg);
	}
}

void Noelle_BossRemoved(int client)
{
	if(GrazeTriggerRef[client] != -1)
	{
		int entity = EntRefToEntIndex(GrazeTriggerRef[client]);
		if(entity != -1)
			RemoveEntity(entity);
		
		GrazeTriggerRef[client] = -1;
	}

	if(MusicPlayer == client)
		MusicPlayer = 0;
	
	HasAbility[client] = 0;

	if(DefendButton[client])
	{
		DefendButton[client] = 0;
		FF2R_SetClientHud(client, true);
	}
}

void Noelle_ClientDisconnect(int client)
{
	delete BattleMusicTimer[client];

	if(SnowGraveCaster == client)
		SnowGraveCaster = 0;

	if(SnowGraveTarget == client)
		SnowGraveTarget = 0;
}

void Noelle_PlayerSpawned(int client)
{
	if(SnowGraveTarget && SnowGraveTarget == client)
	{
		SetEntProp(client, Prop_Send, "m_bIsPlayerSimulated", 1);
		SetEntProp(client, Prop_Send, "m_bAnimatedEveryTick", 1);
		SetEntProp(client, Prop_Send, "m_bSimulatedEveryTick", 1);
		SetEntProp(client, Prop_Send, "m_bClientSideAnimation", 1);
		SetEntProp(client, Prop_Send, "m_bClientSideFrameReset", 0);
		SetEntProp(client, Prop_Data, "m_takedamage", 2);

		SetVariantString("");
		AcceptEntityInput(client, "SetScriptOverlayMaterial");
		
		SnowGraveTarget = 0;
	}
}

void Noelle_PlayerRunCmdPost(int client, int buttons)
{
	if(GrazeTriggerRef[client] != -1 && IsPlayerAlive(client) && GrazeCount[client] > 0 && SnowGraveState < 3)
	{
		BossData boss = FF2R_GetBossData(client);
		
		float maxrage = boss.RageMax;
		float rage = GetBossCharge(boss, "0");
		if(rage < maxrage)
		{
			rage += (GrazeBaseRage[client] + (GrazeCount[client] * GrazeBaseAdd[client])) * (SnowGraveState > 1 ? 2.0 : 1.0);
			if(rage > maxrage)
				rage = maxrage;
			
			SetBossCharge(boss, "0", rage);
		}
		
		DrawBoundingBox(client, client, 0.1);
	}

	if(SnowGraveState == 2)
	{
		BossData boss = FF2R_GetBossData(client);
		if(boss)
		{
			int maxhealth = boss.MaxHealth;
			if(maxhealth)
			{
				int health = GetClientHealth(client);
				if(health > (maxhealth / 3))
				{
					SetEntityHealth(client, GetClientHealth(client) - TotalPlayersEnemy());
					FF2R_UpdateBossAttributes(client);
				}
			}
		}
	}

	static int holding[MAXTF2PLAYERS];

	if(DefendButton[client] && IsPlayerAlive(client))
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		if(boss && (ability = boss.GetAbility("special_noelle_defend")))
		{
			bool hud;
			float gameTime = GetGameTime();
			float cooldown = ability.GetFloat("delayfor");
			float rage = GetBossCharge(boss, "0");
			
			if(holding[client])
			{
				if(!(buttons & holding[client]))
					holding[client] = 0;
			}
			else if(buttons & (1 << DefendButton[client]))
			{
				holding[client] = 1 << DefendButton[client];

				if(cooldown < gameTime)
				{
					hud = true;
					cooldown = gameTime + ability.GetFloat("cooldown", 10.0);
					ability.SetFloat("delayfor", cooldown);

					float duration = ability.GetFloat("duration", 5.0);

					TF2_AddCondition(client, TFCond_RuneResist, duration);
					TF2_AddCondition(client, TFCond_Sapped, duration);
					int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if(weapon != -1)
						SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 8.0);
					
					float maxrage = boss.RageMax;
					if(rage < maxrage)
					{
						rage += ability.GetFloat("rage");
						if(rage > maxrage)
							rage = maxrage;
						
						SetBossCharge(boss, "0", rage);
					}

					FF2R_EmitBossSoundToAll("sound_defend", client);

					CreateParticle("xms_icicle_impact", client, 0, 1.0);
					CreateParticle("xms_icicle_impact", client, 0, 1.0);
				}
			}

			if(!(buttons & IN_SCORE) && RoundActive)
			{
				if(hud || ability.GetFloat("hudin") < gameTime)
				{
					ability.SetFloat("hudin", gameTime + 0.1);

					char buffer[128], button[16];
					FormatEx(button, sizeof(button), "Short %d", DefendButton[client]);

					if(cooldown > gameTime)
					{
						Format(buffer, sizeof(buffer), "%.1fs", cooldown - gameTime + 0.1);
					}
					else
					{
						strcopy(buffer, sizeof(buffer), "        ");
					}

					#define SPACE_DIFF	"                                                            "

					Format(buffer, sizeof(buffer), "%s%s", SPACE_DIFF, buffer);

					int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if(weapon != -1)
					{
						cooldown = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
						if(cooldown > gameTime)
						{
							Format(buffer, sizeof(buffer), "%.1fs%s", cooldown - gameTime + 0.1, buffer);
						}
						else
						{
							Format(buffer, sizeof(buffer), "      %s", buffer);
						}
					}

					SetHudTextParams(-1.0, 0.68, 0.9, 255, 255, 255, 255, _, _, 0.01, 0.5);
					ShowSyncHudText(client, SyncHud[0], "FIGHT" ... SPACE_DIFF ... "DEFEND\n%s\n[M1]" ... SPACE_DIFF ... "[%t]", buffer, button);
				}

				int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				if(weapon != -1 && HasEntProp(weapon, Prop_Send, "m_flChargeLevel"))
				{
					float display = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") * 100.0;
					if(rage != display)
					{
						if(display < rage)
						{
							display += 0.5;
							if(display > rage)
								display = rage;
						}
						else if(display > rage)
						{
							display -= 0.5;
							if(display < rage)
								display = rage;
						}

						SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", display / 100.0);
					}
				}
			}
		}
	}
	
	if(HasAbility[client] && IsPlayerAlive(client))
	{
		BossData boss = FF2R_GetBossData(client);
		AbilityData ability;
		ConfigData spells;
		if(boss && (ability = boss.GetAbility("rage_noelle_ams")) && (spells = ability.GetSection("spells")))
		{
			bool hud;
			float gameTime = GetGameTime();
			
			int summonable = -1;
			int allies = -1;
			int count = -1;
			static int button[4];
			SortedSnapshot snap;
			
			if(holding[client])
			{
				if(!(buttons & holding[client]))
					holding[client] = 0;
			}
			else if(buttons & IN_ATTACK2)
			{
				holding[client] = IN_ATTACK2;
				
				GetButtons(ability, HasAbility[client] != -1, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 1)
					{
						snap = CreateSortedSnapshot(spells);
						
						int length = snap.Length;
						if(HasAbility[client] == -1 && length > i)
						{
							hud = ActivateAbility(client, boss, spells, snap, i, gameTime, summonable, allies);
						}
						else
						{
							hud = ChangeAbility(client, boss, ability, spells, snap, (i == count - 1));
						}
						break;
					}
				}
			}
			else if(buttons & IN_RELOAD)
			{
				holding[client] = IN_RELOAD;
				
				GetButtons(ability, HasAbility[client] != -1, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 2)
					{
						snap = CreateSortedSnapshot(spells);
						
						int length = snap.Length;
						if(HasAbility[client] == -1 && length > i)
						{
							hud = ActivateAbility(client, boss, spells, snap, i, gameTime, summonable, allies);
						}
						else
						{
							hud = ChangeAbility(client, boss, ability, spells, snap, (i == count - 1));
						}
						break;
					}
				}
			}
			else if(buttons & IN_ATTACK3)
			{
				holding[client] = IN_ATTACK3;
				
				GetButtons(ability, HasAbility[client] != -1, count, button);
				for(int i; i < count; i++)
				{
					if(button[i] == 3)
					{
						snap = CreateSortedSnapshot(spells);
						
						int length = snap.Length;
						if(HasAbility[client] == -1 && length > i)
						{
							hud = ActivateAbility(client, boss, spells, snap, i, gameTime, summonable, allies);
						}
						else
						{
							hud = ChangeAbility(client, boss, ability, spells, snap, (i == count - 1));
						}
						break;
					}
				}
			}
			
			if(!(buttons & IN_SCORE) && GameRules_GetRoundState() != RoundState_TeamWin)
			{
				if(!hud)
				{
					static bool wasInspect[MAXTF2PLAYERS];
					if(PressedInspectKey[client])
					{
						if(!wasInspect[client])
						{
							hud = true;
							wasInspect[client] = true;
						}
					}
					else if(!wasInspect[client])
					{
						hud = true;
						wasInspect[client] = false;
					}
				}
				
				if(hud || ability.GetFloat("hudin") < gameTime)
				{
					ability.SetFloat("hudin", gameTime + 0.09);
					
					SetGlobalTransTarget(client);
					int lang = GetClientLanguage(client);
					
					static char buffer[512];
					static PackVal val;
					if(HasAbility[client] == -1)
					{
						GetButtons(ability, false, count, button);
						
						if(!snap)
							snap = CreateSortedSnapshot(spells);
						
						int entries = snap.Length;
						if(entries > count)
						{
							HasAbility[client] = 1;
							delete snap;
							return;
						}
						
						for(int i; i < entries; i++)
						{
							int length = snap.KeyBufferSize(i)+1;
							char[] key = new char[length];
							snap.GetKey(i, key, length);
							spells.GetArray(key, val, sizeof(val));
							
							if(val.tag == KeyValType_Section && val.cfg)
							{
								ConfigData cfg = view_as<ConfigData>(val.cfg);
								if(!PressedInspectKey[client] || !GetBossNameCfg(cfg, val.data, sizeof(val.data), lang, "desc"))
								{
									if(!GetBossNameCfg(cfg, val.data, sizeof(val.data), lang))
										strcopy(val.data, sizeof(val.data), key);
								}
								
								bool blocked = true;
								
								if(PressedInspectKey[client])
								{
									switch(button[i])
									{
										case 0:
											Format(val.data, sizeof(val.data), "[%t] %s", "Button E", val.data);
										
										case 1:
											Format(val.data, sizeof(val.data), "[%t] %s", "Button 11", val.data);
										
										case 2:
											Format(val.data, sizeof(val.data), "[%t] %s", "Button 13", val.data);
										
										case 3:
											Format(val.data, sizeof(val.data), "[%t] %s", "Button 25", val.data);
									}
									
									int cost = RoundToCeil(cfg.GetFloat("cost"));
									if(cost > 0)
										Format(val.data, sizeof(val.data), "%s (%d$)", val.data, cost);
								}
								else
								{
									switch(button[i])
									{
										case 0:
											Format(val.data, sizeof(val.data), "[%t] %s", "Short E", val.data);
										
										case 1:
											Format(val.data, sizeof(val.data), "[%t] %s", "Short 11", val.data);
										
										case 2:
											Format(val.data, sizeof(val.data), "[%t] %s", "Short 13", val.data);
										
										case 3:
											Format(val.data, sizeof(val.data), "[%t] %s", "Short 25", val.data);
									}
									
									int flags = cfg.GetInt("flags");
									if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs One Life");
									}
									else if((flags & MAG_PARTNER) && GetDeadCount(client, summonable, allies) && !allies)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Partner");
									}
									else if((flags & MAG_SUMMON) && GetDeadCount(client, summonable, allies) && !summonable)
									{
										Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Summon");
									}
									else
									{
										float delay = cfg.GetFloat("delayfor");
										if(delay > gameTime)
										{
											Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Ability Delay", delay - gameTime + 0.1);
										}
										else if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
										{
											Format(val.data, sizeof(val.data), "%s (%t)", val.data, "Rage Needs Ground");
										}
										else
										{
											float fcost = cfg.GetFloat("cost");
											int cost = RoundToCeil(fcost);
											if(cost > 0)
												Format(val.data, sizeof(val.data), "%s (%d$)", val.data, cost);
											
											if(button[i] == 0 && GetBossCharge(boss, "0") >= fcost)
												blocked = false;
										}
									}
								}
								
								if(button[i] == 0)
									boss.SetInt("ragemode", blocked ? 2 : 1);
								
								if(i)
								{
									Format(buffer, sizeof(buffer), "%s\n%s", buffer, val.data);
								}
								else
								{
									strcopy(buffer, sizeof(buffer), val.data);
								}
							}
						}
						
						if(boss.GetInt("lives") < 2)
							entries--;
						
						SetHudTextParams(-1.0, 0.78 - (float(entries) * 0.05), 1.9, 255, 255, 255, 255, _, _, 0.01, 0.5);
					}
					else
					{
						if(!snap)
							snap = CreateSortedSnapshot(spells);
						
						int entries = snap.Length;
						if(!entries)
						{
							HasAbility[client] = 0;
							delete snap;
							return;
						}
						
						if(HasAbility[client] > entries)
							HasAbility[client] = 1;
						
						int length = snap.KeyBufferSize(HasAbility[client] - 1) + 1;
						char[] key = new char[length];
						snap.GetKey(HasAbility[client] - 1, key, length);
						spells.GetArray(key, val, sizeof(val));
						
						if(val.tag == KeyValType_Section && val.cfg)
						{
							ConfigData cfg = view_as<ConfigData>(val.cfg);
							if(!GetBossNameCfg(cfg, val.data, sizeof(val.data), lang))
								strcopy(val.data, sizeof(val.data), key);
							
							GetButtons(ability, true, count, button);
							
							bool blocked = true;
							if(count)
							{
								switch(button[0])
								{
									case 1:
										Format(val.data, sizeof(val.data), "%s [%t] -->", val.data, "Short 11");
									
									case 2:
										Format(val.data, sizeof(val.data), "%s [%t] -->", val.data, "Short 13");
									
									case 3:
										Format(val.data, sizeof(val.data), "%s [%t] -->", val.data, "Short 25");
								}
								
								if(count > 1)
								{
									switch(button[count - 1])
									{
										case 1:
											Format(val.data, sizeof(val.data), "<-- [%t] %s", "Short 11", val.data);
										
										case 2:
											Format(val.data, sizeof(val.data), "<-- [%t] %s", "Short 13", val.data);
										
										case 3:
											Format(val.data, sizeof(val.data), "<-- [%t] %s", "Short 25", val.data);
									}
								}
							}
							
							float fcost = cfg.GetFloat("cost");
							int cost = RoundToCeil(fcost);
							if(cost > 0)
							{
								Format(buffer, sizeof(buffer), "(%d$ TP)", cost);
							}
							else
							{
								buffer[0] = 0;
							}
							
							if(ability.GetInt("slot") == 0 && GetBossCharge(boss, "0") >= fcost)
								blocked = false;
							
							bool extraDesc = false;
							float delay = cfg.GetFloat("delayfor");
							if(delay > gameTime)
							{
								Format(buffer, sizeof(buffer), "(%t) %s", "Ability Delay", delay - gameTime + 0.1, buffer);
								blocked = true;
								extraDesc = true;
							}
							
							int flags = cfg.GetInt("flags");
							if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
							{
								Format(buffer, sizeof(buffer), "%t %s", "Rage Needs One Life", buffer);
								blocked = true;
								extraDesc = true;
							}
							
							if((flags & MAG_PARTNER) && GetDeadCount(client, summonable, allies) && !allies)
							{
								Format(buffer, sizeof(buffer), "%t %s", "Rage Needs Partner", buffer);
								blocked = true;
								extraDesc = true;
							}
							
							if((flags & MAG_SUMMON) && GetDeadCount(client, summonable, allies) && !summonable)
							{
								Format(buffer, sizeof(buffer), "%t %s", "Rage Needs Summon", buffer);
								blocked = true;
								extraDesc = true;
							}
							
							if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
							{
								Format(buffer, sizeof(buffer), "%t %s", "Rage Needs Ground", buffer);
								blocked = true;
								extraDesc = true;
							}

							if(!extraDesc)
							{
								char buffer2[128];
								GetBossNameCfg(cfg, buffer2, sizeof(buffer2), lang, "desc");
								Format(buffer, sizeof(buffer), "%s %s", buffer2, buffer);
							}

							if(!blocked)
							{
								float radius = cfg.GetFloat("radius");
								if(radius > 0.0)
								{
									float IceSpell_Location[3];
									IceSpell_GetDistance(client, cfg.GetFloat("maxdist", 99999.9), IceSpell_Location);
									TE_SetupBeamRingPoint(IceSpell_Location, radius, radius-0.1, BEACON_BEAM, BEACON_HALO, 0, 15, 0.1, 5.0, 0.0, {127, 255, 255, 63}, 10, 0);
									TE_SendToClient(client);
								}
							}
							
							Format(buffer, sizeof(buffer), "%s\n%s\n[E]", val.data, buffer);
							
							if(ability.GetInt("slot") == 0)
								boss.SetInt("ragemode", blocked ? 2 : 1);
						}
						
						SetHudTextParams(-1.0, 0.68, 0.9, 255, 255, 255, 255, _, _, 0.01, 0.5);
					}
					
					ReplaceString(buffer, sizeof(buffer), "$", "%%");
					ShowSyncHudText(client, SyncHud[1], buffer);
				}
			}
			
			delete snap;
		}
		else
		{
			HasAbility[client] = 0;
		}
	}
}

void Noelle_AliveChanged()
{
	if(!SnowGraveState || WeirdState < 0 || WeirdState > 1)
		return;
	
	int total = TotalPlayersEnemy() - 1;
	int alive = TotalPlayersAliveEnemy() - 1;

	if(SnowGraveRequire > 0.1)
	{
		float progress = float(FrozenVictims + alive) / float(total);
		if(progress < SnowGraveRequire)
		{
			if(WeirdState == 1)
			{
				if(MusicPlayer)
					FF2R_EmitBossSoundToAll("sound_weirdbackout", MusicPlayer);
			}

			WeirdState = -1;
		}
	}

	switch(WeirdState)
	{
		case 0:
		{
			if(alive <= (total / 2))// && total > (SnowGraveRequire > 0.1 ? 7 : 1))
			{
				WeirdState = 1;
				ColdTimer = CreateTimer(0.75, BreathTimer, _, TIMER_REPEAT);
				
				if(MusicPlayer)
					FF2R_EmitBossSoundToAll("sound_weird", MusicPlayer);
			}
		}
		case 1:
		{
			if(alive == 1)// && total > (SnowGraveRequire > 0.1 ? 15 : 1))
			{
				WeirdState = 2;

				AddCommandListener(BlockKillCommand, "kill");
				AddCommandListener(BlockKillCommand, "explode");
				AddCommandListener(BlockKillCommand, "spectate");
				AddCommandListener(BlockKillCommand, "jointeam");
				AddCommandListener(BlockKillCommand, "autoteam");

				if(MusicPlayer)
					FF2_StartMusic(0);
				
				int entity = FindEntityByClassname(-1, "team_control_point");
				if(entity != -1)
				{
					DumpsterKROMER = 0;
					DumpsterMsgIn = 0.0;
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", DumpsterPos);
					DumpsterPos[2] -= 10.0;
				
					int stoneEntity = CreateEntityByName("prop_physics_override");
					if(IsValidEntity(stoneEntity))
					{
						// the actual spawning process
						SetEntityModel(stoneEntity, DumpsterModel);
						DispatchKeyValue(stoneEntity, "targetname", "Dumpster");
						DispatchSpawn(stoneEntity);
						TeleportEntity(stoneEntity, DumpsterPos, NULL_VECTOR, NULL_VECTOR);
						SetEntProp(stoneEntity, Prop_Data, "m_takedamage", 0);

						SetEntityMoveType(stoneEntity, MOVETYPE_NONE);
						SetEntProp(stoneEntity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
						SetEntProp(stoneEntity, Prop_Send, "m_usSolidFlags", 4);
						SetEntProp(stoneEntity, Prop_Send, "m_nSolidType", 0);
						SetEntProp(stoneEntity, Prop_Send, "m_nSkin", 1);

						int ent = CreateEntityByName("tf_glow", -1);
						DispatchKeyValue(ent, "target", "Dumpster");
						DispatchKeyValue(ent, "Mode", "0");
						DispatchSpawn(ent);
						AcceptEntityInput(ent, "Enable", -1, -1, 0);

						int color[4] = {255, 255, 255, 255};

						SetVariantColor(color);
						AcceptEntityInput(ent, "SetGlowColor");

						// notify all players and the hale that it exists. it's a one time HUD message.
						for(int client = 1; client <= MaxClients; client++)
						{
							if(IsClientInGame(client) && IsPlayerAlive(client))
							{
								bool boss = FF2R_GetBossData(client) != null;
								PrintCenterText(client, boss ? MessageAppearedBoss : MessageAppearedPlayer);

								if(boss)
									FF2R_EmitBossSoundToAll("sound_dumpster_spawn", client);
							}
						}

						// save the entity ref
						DumpsterRef = EntIndexToEntRef(stoneEntity);

						// next beacon time
						DumpsterSoundIn = GetGameTime() + 5.0;
					}
				}
			}
		}
	}
}

static Action BreathTimer(Handle timer)
{
	static int breathplayers;
	breathplayers++;

	for(int client = 1 + (breathplayers % 6); client <= MaxClients; client += 6)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && !FF2R_GetBossData(client) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Stealthed) && !TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade))
		{
			CreateParticle("taunt_soldier_coffee_steam", client, 4, 1.5, _, _, -4.0);
			CreateParticle("taunt_soldier_coffee_steam", client, 5, 1.5, _, _, -4.0);
		}
	}
	
	return Plugin_Handled;
}

static Action BlockKillCommand(int client, const char[] command, int args)
{
	return IsPlayerAlive(client) ? Plugin_Handled : Plugin_Continue;
}

void Noelle_GameFrame()
{
	if(WeirdState != 2)
		return;
	
	if(DumpsterRef != -1 && IsValidEntity(DumpsterRef))
	{
		float gameTime = GetGameTime();

		bool nearby, defended;

		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				float clientOrigin[3];
				GetEntPropVector(client, Prop_Data, "m_vecOrigin", clientOrigin);
				if (CylinderCollision(DumpsterPos, clientOrigin, 150.0, DumpsterPos[2] - 103.0, DumpsterPos[2] + 150.0))
				{
					if(FF2R_GetBossData(client))
					{
						nearby = true;
					}
					else
					{
						TF2_AddCondition(client, TFCond_DefenseBuffed, 0.3);
						defended = true;
						break;
					}
				}
			}
		}
		
		if(defended)
		{
			if(nearby || DumpsterKROMER < 1)
			{
				if(DumpsterMsgIn < gameTime)
				{
					DumpsterMsgIn = gameTime + 0.2;

					for(int client = 1; client <= MaxClients; client++)
					{
						if(IsClientInGame(client) && IsPlayerAlive(client))
							PrintCenterText(client, FF2R_GetBossData(client) ? MessageDefendedBoss : MessageDefendedPlayer);
					}
				}
			}
			else
			{
				DumpsterKROMER--;

				for(int client = 1; client <= MaxClients; client++)
				{
					if(IsClientInGame(client) && IsPlayerAlive(client))
						PrintCenterText(client, FF2R_GetBossData(client) ? MessageDefendedBoss : MessageKROMERPlayer, DumpsterKROMER);
				}
			}
		}
		else if(nearby)
		{
			DumpsterKROMER += 3;
			if(DumpsterKROMER > 1996)
			{
				for(int client = 1; client <= MaxClients; client++)
				{
					if(IsClientInGame(client) && IsPlayerAlive(client))
					{
						bool boss = FF2R_GetBossData(client) != null;
						PrintCenterText(client, MessageGrave);

						if(boss)
							FF2R_EmitBossSoundToAll("sound_dumpster_collect", client);
					}
				}

				SnowGraveState = 2;

				int dissolver = CreateEntityByName("env_entity_dissolver");
				if(dissolver != -1)
				{
					DispatchKeyValue(dissolver, "dissolvetype", "3");
					DispatchKeyValue(dissolver, "magnitude", "1");
					DispatchKeyValue(dissolver, "target", "!activator");

					AcceptEntityInput(dissolver, "Dissolve", DumpsterRef);
					AcceptEntityInput(dissolver, "Kill");
				}

				DumpsterRef = -1;
			}
			else
			{
				for(int client = 1; client <= MaxClients; client++)
				{
					if(IsClientInGame(client) && IsPlayerAlive(client))
						PrintCenterText(client, FF2R_GetBossData(client) ? MessageKROMERBoss : MessageAttackingPlayer, 2000 - DumpsterKROMER);
				}
			}
		}

		if(DumpsterSoundIn < gameTime)
		{
			DumpsterSoundIn = gameTime + 5.0;

			for(int client = 1; client <= MaxClients; client++)
			{
				if(IsClientInGame(client) && IsPlayerAlive(client) && FF2R_GetBossData(client))
				{
					FF2R_EmitBossSoundToAll("sound_dumpster_noise", client, _, DumpsterRef, _, 95);
					break;
				}
			}
		}
	}

	if(SnowGraveState == 3 && SnowGraveCaster)
	{
		if(SnowGravePhaseChangeTime < GetEngineTime())
		{
			SnowGravePhase++;
			switch(SnowGravePhase)
			{
				case 1:
				{
					SnowGravePhaseChangeTime = GetEngineTime()+0.5;

					TF2_AddCondition(SnowGraveCaster, TFCond_UberchargedCanteen, -1.0);
					TE_Start("PlayerAnimEvent");
					TE_WriteNum("m_hPlayer", EntIndexToEntRef(SnowGraveCaster));
					TE_WriteNum("m_iEvent", 6);
					TE_SendToAll();
					float origin[3];
					GetClientAbsOrigin(SnowGraveCaster, origin);
					origin[2] += 2.0;
					TeleportEntity(SnowGraveCaster, origin, NULL_VECTOR, NULL_VECTOR);
					SetEntityMoveType(SnowGraveCaster, MOVETYPE_NONE);
					SetEntityGravity(SnowGraveCaster, 0.01);
				}
				case 2:
				{
					FF2R_EmitBossSoundToAll("sound_snowgrave", SnowGraveCaster);
					SnowGravePhaseChangeTime = GetEngineTime()+0.5;
				}
				case 3:
				{
					SnowGravePhaseChangeTime = GetEngineTime()+3.0;
				}
				case 4:
				{
					float angle[3];
					GetClientAbsAngles(SnowGraveCaster, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					CreateParticle("env_snow_stormfront_001", SnowGraveCaster, 0, 8.0, _, _, -128.0, angle);
					SnowGravePhaseChangeTime = GetEngineTime()+1.0;
				}
				case 5:
				{
					if(SnowGraveTarget)
					{
						int color[4] = {100,100,255,255};
						Fade(SnowGraveTarget, 250, 1500, color, 10);
					}
					SnowGravePhaseChangeTime = GetEngineTime()+0.25;
				}
				case 6:
				{
					if(SnowGraveTarget)
					{
						switch (TF2_GetPlayerClass(SnowGraveTarget))
						{
							case TFClass_Scout:
							{
								EmitGameSoundToAll("Scout.CritDeath", SnowGraveTarget);
							}
							case TFClass_Pyro:
							{
								EmitGameSoundToAll("Pyro.CritDeath", SnowGraveTarget);
							}
							case TFClass_DemoMan:
							{
								EmitGameSoundToAll("Demoman.CritDeath", SnowGraveTarget);
							}
							case TFClass_Heavy:
							{
								EmitGameSoundToAll("Heavy.CritDeath", SnowGraveTarget);
							}
							case TFClass_Engineer:
							{
								EmitGameSoundToAll("Engineer.CritDeath", SnowGraveTarget);
							}
							case TFClass_Medic:
							{
								EmitGameSoundToAll("Medic.CritDeath", SnowGraveTarget);
							}
							case TFClass_Sniper:
							{
								EmitGameSoundToAll("Sniper.CritDeath", SnowGraveTarget);
							}
							case TFClass_Spy:
							{
								EmitGameSoundToAll("Spy.CritDeath", SnowGraveTarget);
							}
							default:
							{
								EmitGameSoundToAll("Soldier.CritDeath", SnowGraveTarget);
							}
						}
					}

					SnowGravePhaseChangeTime = GetEngineTime()+1.75;
				}
				case 7:
				{
					if(SnowGraveTarget)
					{
						int color[4] = {100,100,255,255};
						Fade(SnowGraveTarget, 1500, 1000, color, 17);

						SetEntProp(SnowGraveTarget, Prop_Send, "m_bIsPlayerSimulated", 0);
						SetEntProp(SnowGraveTarget, Prop_Send, "m_bSimulatedEveryTick", 0);
						SetEntProp(SnowGraveTarget, Prop_Send, "m_bAnimatedEveryTick", 0);
						SetEntProp(SnowGraveTarget, Prop_Send, "m_bClientSideAnimation", 0);
						SetEntProp(SnowGraveTarget, Prop_Send, "m_bClientSideFrameReset", 1);

						int base = CreateEntityByName("prop_dynamic_override");
						float origin[3], angle[3];
						GetClientAbsOrigin(SnowGraveTarget, origin);
						GetClientAbsAngles(SnowGraveTarget, angle);
						origin[2] += 41.0;
						TeleportEntity(SnowGraveTarget, origin, NULL_VECTOR, NULL_VECTOR);
						origin[2] += 41.0;
						angle[0] = 0.0;
						angle[2] = 0.0;
						TeleportEntity(base, origin, angle, NULL_VECTOR);
						PrecacheModel(SnowGrave_Model, true);
						DispatchKeyValue(base, "model", SnowGrave_Model);
						DispatchKeyValue(base, "modelscale", "3.0");
						DispatchKeyValue(base, "solid", "2");
						float mins[3];
						float maxs[3];
						FormatBounds(mins, maxs, 80.0);
						SetEntPropVector(base, Prop_Send, "m_vecMins", mins);
						SetEntPropVector(base, Prop_Send, "m_vecMaxs", maxs);
						DispatchSpawn(base);
						ActivateEntity(base);

						SetEntityRenderMode(base, RENDER_TRANSALPHA);
						SetEntityRenderColor(base, 255, 255, 255, 200);

						CreateParticle("xms_icicle_impact_dryice", base, 0, 15.0);
						CreateParticle("xms_icicle_impact_dryice", base, 0, 15.0);
						CreateParticle("xms_icicle_impact_dryice", base, 0, 15.0);
						CreateParticle("xms_icicle_impact_dryice", base, 0, 15.0);
						CreateParticle("xms_icicle_impact_dryice", base, 0, 15.0);
						CreateParticle("xms_icicle_impact_dryice", base, 0, 15.0);

						TF2_AddCondition(SnowGraveTarget, TFCond_FreezeInput, TFCondDuration_Infinite);
						TF2_AddCondition(SnowGraveTarget, TFCond_GrappledToPlayer, TFCondDuration_Infinite);
						PrecacheSound("misc/null.wav");
						EmitSoundToAll("misc/null.wav", SnowGraveTarget, SNDCHAN_VOICE);
						SetVariantString("effects/invuln_overlay_blue_dx80");
						AcceptEntityInput(SnowGraveTarget, "SetScriptOverlayMaterial");
						FF2R_SetClientMinion(SnowGraveTarget, 1);
					}
					
					SnowGravePhaseChangeTime = GetEngineTime()+1.5;
				}
				case 8:
				{
					if(SnowGraveTarget)
					{
						Handle SnowGraveEvent=CreateEvent("player_hurt", true);
						SetEventInt(SnowGraveEvent, "userid", GetClientUserId(SnowGraveTarget));
						SetEventInt(SnowGraveEvent, "attacker", GetClientUserId(SnowGraveCaster));
						SetEventInt(SnowGraveEvent, "damageamount", GetRandomInt(1600, 2000));
						SetEventBool(SnowGraveEvent, "crit", true);
						SetEventBool(SnowGraveEvent, "allseecrit", true);
						FireEvent(SnowGraveEvent);
						SetEntProp(SnowGraveTarget, Prop_Data, "m_takedamage", 0);
					}
					SnowGravePhaseChangeTime = GetEngineTime()+2.0;
				}
				case 9:
				{
					SnowGravePhaseChangeTime = GetEngineTime()+5.0;
					TF2_RemoveCondition(SnowGraveCaster, TFCond_FreezeInput);
					TF2_RemoveCondition(SnowGraveCaster, TFCond_UberchargedCanteen);
					SetEntityMoveType(SnowGraveCaster, MOVETYPE_WALK);
					SetEntityGravity(SnowGraveCaster, 0.5);
				}
				case 10:
				{
					if(SnowGraveTarget)
					{
						SetEntProp(SnowGraveTarget, Prop_Send, "m_lifeState", 2);
						SetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPlayerClassWhenKilled", GetEntProp(SnowGraveTarget, Prop_Send, "m_iClass"), _, SnowGraveTarget);
					}
					
					SetEntityGravity(SnowGraveCaster, 1.0);
					SnowGraveState = 4;
				}
			}
		}
		if (SnowGravePhase > 2 && SnowGravePhase < 9)
		{
			float rot[3], velocity[3];
			GetClientEyeAngles(SnowGraveCaster,rot);
			if (SnowGravePhase == 3)
			{
				velocity[0]=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*125.0;
				velocity[1]=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*125.0;
				velocity[2]=125.0;
			}
			else
			{
				velocity[0]=GetRandomFloat(-100.0, 100.0);
				velocity[1]=GetRandomFloat(-100.0, 100.0);
				velocity[2]=GetRandomFloat(-100.0, 100.0);
			}
			SetEntityMoveType(SnowGraveCaster, MOVETYPE_FLY);
			TeleportEntity(SnowGraveCaster, NULL_VECTOR, NULL_VECTOR, velocity);
		}
		if (SnowGravePhase > 4 && SnowGravePhase < 8)
		{
			if(SnowGraveTarget)
			{
				float SnowGrave_Point[3], SnowGrave_Angle[3];

				TR_TraceRayFilter(SnowGrave_Location, SnowGrave_Angle, MASK_PLAYERSOLID, RayType_Infinite, SnowGraveTrace);
				TR_GetEndPosition(SnowGrave_Point);
				float distance = GetVectorDistance(SnowGrave_Location, SnowGrave_Point);
				if (distance > 150.0)
					constrainDistance(SnowGrave_Location, SnowGrave_Point, distance, 150.0);

				TE_SetupGlowSprite(SnowGrave_Point, BEACON_POINT, 3.1, 2.0, 255);
				TE_SendToAll();
				SnowGrave_Angle[1] += 90.0;
				if (SnowGrave_Angle[1] > 360.0)
				{
					SnowGrave_Angle[1] -= 360.0;
				}

				SnowGrave_Point[0] = SnowGrave_Location[0];
				SnowGrave_Point[1] = SnowGrave_Location[1];
				SnowGrave_Point[2] = SnowGrave_Location[2];

				TR_TraceRayFilter(SnowGrave_Location, SnowGrave_Angle, MASK_PLAYERSOLID, RayType_Infinite, SnowGraveTrace);
				TR_GetEndPosition(SnowGrave_Point);
				distance = GetVectorDistance(SnowGrave_Location, SnowGrave_Point);
				if (distance > 150.0)
					constrainDistance(SnowGrave_Location, SnowGrave_Point, distance, 150.0);

				TE_SetupGlowSprite(SnowGrave_Point, BEACON_POINT, 3.1, 2.0, 255);
				TE_SendToAll();
				SnowGrave_Angle[1] += 90.0;
				if (SnowGrave_Angle[1] > 360.0)
				{
					SnowGrave_Angle[1] -= 360.0;
				}

				SnowGrave_Point[0] = SnowGrave_Location[0];
				SnowGrave_Point[1] = SnowGrave_Location[1];
				SnowGrave_Point[2] = SnowGrave_Location[2];

				TR_TraceRayFilter(SnowGrave_Location, SnowGrave_Angle, MASK_PLAYERSOLID, RayType_Infinite, SnowGraveTrace);
				TR_GetEndPosition(SnowGrave_Point);
				distance = GetVectorDistance(SnowGrave_Location, SnowGrave_Point);
				if (distance > 150.0)
					constrainDistance(SnowGrave_Location, SnowGrave_Point, distance, 150.0);

				TE_SetupGlowSprite(SnowGrave_Point, BEACON_POINT, 3.1, 2.0, 255);
				TE_SendToAll();
				SnowGrave_Angle[1] += 90.0;
				if (SnowGrave_Angle[1] > 360.0)
				{
					SnowGrave_Angle[1] -= 360.0;
				}

				SnowGrave_Point[0] = SnowGrave_Location[0];
				SnowGrave_Point[1] = SnowGrave_Location[1];
				SnowGrave_Point[2] = SnowGrave_Location[2];

				TR_TraceRayFilter(SnowGrave_Location, SnowGrave_Angle, MASK_PLAYERSOLID, RayType_Infinite, SnowGraveTrace);
				TR_GetEndPosition(SnowGrave_Point);
				distance = GetVectorDistance(SnowGrave_Location, SnowGrave_Point);
				if (distance > 150.0)
					constrainDistance(SnowGrave_Location, SnowGrave_Point, distance, 150.0);

				TE_SetupGlowSprite(SnowGrave_Point, BEACON_POINT, 3.1, 2.0, 255);
				TE_SendToAll();
				SnowGrave_Angle[1] -= 265.0;

				TE_SetupBeamRingPoint(SnowGrave_Location, 160.0, 159.9, BEACON_BEAM, BEACON_HALO, 0, 0, 3.0, 100.0, 0.5, {100,100,255,255}, 0, 0);
				TE_SendToAll();

				SnowGrave_Location[2]+=10.0;
			}
		}
	}
}

void Noelle_PlayerDeath(int victim, int attacker, int flags)
{
	if(victim && attacker)
	{
		BossData boss = FF2R_GetBossData(attacker);
		if(boss)
		{
			AbilityData ability = boss.GetAbility("special_noelle_effects");
			if(ability.IsMyPlugin())
			{
				float levelup = ability.GetFloat("levelup");
				if(levelup)
				{
					int maxhealth = boss.MaxHealth;
					if(maxhealth)
					{
						int increase = RoundFloat(maxhealth * levelup);

						if(!(flags & TF_DEATHFLAG_DEADRINGER))
						{
							boss.MaxHealth += increase;
							SetEntityHealth(attacker, GetClientHealth(attacker) + increase);
							FF2R_UpdateBossAttributes(attacker);
						}

						ApplySelfHealEvent(attacker, increase);
					}
				}
			}
		}
	}
}

void Noelle_TakeDamagePost(int victim, int attacker)
{
	if(victim != attacker && attacker > 0 && attacker <= MaxClients)
		UpdateCombatTimers(victim, attacker);
}

Action Noelle_OnStomp(int attacker, int victim)
{
	if(SnowGraveState > 2 || (DefendButton[attacker] && TF2_IsPlayerInCondition(attacker, TFCond_RuneResist)))
		return Plugin_Handled;

	UpdateCombatTimers(victim, attacker);
	return Plugin_Continue;
}

public Action FF2_OnMusicEx(char path[PLATFORM_MAX_PATH], float &time, int client)
{
	if(MusicPlayer)
	{
		BossData boss = FF2R_GetBossData(MusicPlayer);
		
		static const char keys[][][] = {
			{ "sound_bgm_battle", "sound_bgm" },
			{ "sound_bgm_battle", "sound_bgm_alt" },
			{ "sound_last_battle", "sound_last_bgm" }
		};

		int weird = WeirdState;
		if(weird < 0)
			weird = 0;

		for(int i = BattleMusicTimer[client] ? 0 : 1; i < sizeof(keys[]); i++)
		{
			if(weird == 0 && i == 1)
				return Plugin_Continue;
			
			ConfigData cfg = boss.GetSection(keys[weird][i]);
			if(cfg)
			{
				cfg.GetString("path1", path, sizeof(path), path);
				time = cfg.GetFloat("time1", time);
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

static void UpdateCombatTimers(int victim, int attacker)
{
	if(!RoundActive)
		return;
	
	int bossplayer = attacker;
	BossData boss = FF2R_GetBossData(attacker);
	if(!boss || !boss.ContainsKey("sound_bgm_battle"))
	{
		if(victim < 1 || victim > MaxClients)
			return;
		
		bossplayer = victim;
		boss = FF2R_GetBossData(victim);
		if(!boss || !boss.ContainsKey("sound_bgm_battle"))
			return;
	}

	float duration = WeirdState == 2 ? 60.0 : 10.0;

	int amount;
	int[] players = new int[MaxClients+1];

	for(int player = 1; player <= MaxClients; player++)
	{
		if(victim == player || attacker == player || (IsClientInGame(player) && IsClientObserver(player) && (GetEntPropEnt(player, Prop_Send, "m_hObserverTarget") == victim || GetEntPropEnt(player, Prop_Send, "m_hObserverTarget") == attacker)))
		{
			if(BattleMusicTimer[player])
			{
				delete BattleMusicTimer[player];
				BattleMusicTimer[player] = CreateTimer(duration, EndBattleMusic, player);
			}
			else
			{
				players[amount++] = player;
				BattleMusicTimer[player] = CreateTimer(duration, EndBattleMusic, player);

				if(MusicPlayer)
					FF2_StartMusic(player);
			}
		}
	}

	if(amount)
	{
		FF2R_EmitBossSound(players, amount, "sound_battle_start", bossplayer);

		if(!MusicPlayer)
			FF2R_EmitBossSound(players, amount, "sound_bgm_battle", bossplayer);
	}
}

static Action EndBattleMusic(Handle timer, int client)
{
	BattleMusicTimer[client] = null;
	FF2_StartMusic(client);
	return Plugin_Continue;
}

static void IceShock(int iClient, const char[] name, AbilityData ability)
{
	float radius = ability.GetFloat("radius");
	float maxdist = ability.GetFloat("maxdist");

	char model[PLATFORM_MAX_PATH];
	ability.GetString("model", model, sizeof(model), "models/error.mdl");

	TF2U_StartLagCompensation(iClient);

	float IceSpell_Location[3];
	IceSpell_GetDistance(iClient, maxdist, IceSpell_Location);

	int rotator = CreateEntityByName("func_rotating");
	TeleportEntity(rotator, IceSpell_Location, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(rotator, "maxspeed", "1080");
	DispatchKeyValue(rotator, "fanfriction", "100");
	DispatchKeyValue(rotator, "spawnflags", "0");
	DispatchSpawn(rotator);
	ActivateEntity(rotator);
//	SetVariantFloat(1080.0);
//	AcceptEntityInput(rotator, "SetSpeed");
	AcceptEntityInput(rotator, "Start");

	int base = CreateEntityByName("prop_dynamic_override");
	float angle[3];
	GetClientEyeAngles(iClient, angle);
	angle[0] = -90.0;
	TeleportEntity(base, IceSpell_Location, angle, NULL_VECTOR);
	PrecacheModel(model, true);
	DispatchKeyValue(base, "model", model);
	DispatchKeyValue(base, "modelscale", "1.5");
	DispatchKeyValue(base, "disableshadows", "1");
	DispatchSpawn(base);
	ActivateEntity(base);

	SetVariantString("!activator");
	AcceptEntityInput(base, "SetParent", rotator, base, 0);

	SetVariantString("OnUser1 !self:KillHierarchy::1.0:1");
	AcceptEntityInput(rotator, "AddOutput");
	AcceptEntityInput(rotator, "FireUser1");

	CreateParticle("xms_icicle_impact", rotator, 0, 1.0);
	CreateParticle("xms_icicle_impact_dryice", rotator, 0, 1.0);
	CreateParticle("xms_icicle_impact", rotator, 0, 1.0);
	CreateParticle("xms_icicle_impact_dryice", rotator, 0, 1.0);
	CreateParticle("xms_icicle_impact", rotator, 0, 1.0);
	CreateParticle("xms_icicle_impact_dryice", rotator, 0, 1.0);
	CreateParticle("xms_snowburst", rotator, 0, 1.0);

	float damage = ability.GetFloat("damage", 80.0);
	float slow = ability.GetFloat("slow", 2.0);

	SetKillIcon("sticky_resistance", name);
	for (int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		if (IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx) && clientIdx != iClient)
		{
			float playerPos[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", playerPos);
			if (CylinderCollision(IceSpell_Location, playerPos, radius*0.5+20.5, IceSpell_Location[2]-radius*0.75, IceSpell_Location[2]+radius*0.75))
			{
				DealFreezeDamage(clientIdx, iClient, iClient, damage, DMG_ENERGYBEAM|DMG_PREVENT_PHYSICS_FORCE);
				TF2_StunPlayer(clientIdx, slow, 0.7, TF_STUNFLAG_SLOWDOWN, iClient);
			}
		}
	}
	for(int i = 1; i <= 2048; i++)
	{
		if(i > MaxClients && IsValidEntity(i) && HasEntProp(i, Prop_Send, "m_hMyWeapons") && HasEntProp(i, Prop_Send, "m_iObjectType"))
		{
			float playerPos[3];
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", playerPos);
//			if (IsPlayerInRange(i, IceSpell_Location, radius*0.5))
			if (CylinderCollision(IceSpell_Location, playerPos, radius*0.5+20.5, IceSpell_Location[2]-radius*0.75, IceSpell_Location[2]+radius*0.75))
			{
				SDKHooks_TakeDamage(i, iClient, iClient, damage * 2.0, DMG_ENERGYBEAM|DMG_PREVENT_PHYSICS_FORCE, GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee), .bypassHooks = false);
				SetEntProp(i, Prop_Send, "m_bDisabled", 1);
				CreateTimer(4.0, Timer_EnableSentry, EntIndexToEntRef(i));
			}
		}
	}
	SetKillIcon();

	TF2U_FinishLagCompensation(iClient);
}

static void SleepMist(int iClient, AbilityData ability)
{
	float radius = ability.GetFloat("radius");
	float maxdist = ability.GetFloat("maxdist");
	float duration = ability.GetFloat("duration");

	TF2U_StartLagCompensation(iClient);

	float IceSpell_Location[3];
	IceSpell_GetDistance(iClient, maxdist, IceSpell_Location);

	int base = CreateEntityByName("prop_dynamic_override");
	TeleportEntity(base, IceSpell_Location, NULL_VECTOR, NULL_VECTOR);
	PrecacheModel("models/empty.mdl", true);
	DispatchKeyValue(base, "model", "models/empty.mdl");
	DispatchKeyValue(base, "modelscale", "1.0");
	DispatchKeyValue(base, "disableshadows", "1");
	DispatchSpawn(base);
	ActivateEntity(base);
	SetVariantString("OnUser1 !self:KillHierarchy::1.0:1");
	AcceptEntityInput(base, "AddOutput");
	AcceptEntityInput(base, "FireUser1");

	CreateParticle("xms_icicle_impact_dryice", base, 0, 1.0);
	CreateParticle("xms_icicle_impact_dryice", base, 0, 1.0);
	CreateParticle("xms_icicle_impact_dryice", base, 0, 1.0);

	for (int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		if (IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx) && clientIdx != iClient)
		{
			float playerPos[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", playerPos);
			if (CylinderCollision(IceSpell_Location, playerPos, radius*0.5+20.5, IceSpell_Location[2]-radius*0.75, IceSpell_Location[2]+radius*0.75))
//			if (IsPlayerInRange(clientIdx, IceSpell_Location, radius*0.5))
			{
				TF2_StunPlayer(clientIdx, duration, 1.0, TF_STUNFLAGS_LOSERSTATE|TF_STUNFLAG_BONKSTUCK, iClient);
				CreateParticle("xms_icicle_impact_dryice", clientIdx, 0, 1.0);
				CreateParticle("xms_icicle_impact_dryice", clientIdx, 0, 1.0);
				CreateParticle("xms_icicle_impact_dryice", clientIdx, 0, 1.0);
			}
		}
	}
	for(int i = 1; i <= 2048; i++)
	{
		if(i > MaxClients && IsValidEntity(i) && HasEntProp(i, Prop_Send, "m_hMyWeapons") && HasEntProp(i, Prop_Send, "m_iObjectType"))
		{
			float playerPos[3];
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", playerPos);

			if (CylinderCollision(IceSpell_Location, playerPos, radius*0.5+20.5, IceSpell_Location[2]-radius*0.75, IceSpell_Location[2]+radius*0.75))
//			if (IsPlayerInRange(i, IceSpell_Location, radius*0.5))
			{
				SetEntProp(i, Prop_Send, "m_bDisabled", 1);
				CreateTimer(duration * 2.0, Timer_EnableSentry, EntIndexToEntRef(i));
			}
		}
	}

	TF2U_FinishLagCompensation(iClient);
}

static void HealPrayer(int client, AbilityData ability)
{
	int health = GetClientHealth(client);

	int maxhealth = FF2R_GetBossData(client).MaxHealth;
	if(maxhealth && health > maxhealth)
		return;
	
	int amount = ability.GetInt("amount");
	health += amount;
	if(maxhealth && health > maxhealth)
	{
		amount = health - maxhealth;
		health = maxhealth;
	}

	SetEntityHealth(client, health);
	FF2R_UpdateBossAttributes(client);
	ApplySelfHealEvent(client, amount);
}

static void SnowGraveStart(int iClient, AbilityData ability)
{
	if(SnowGraveState != 2)
		return;
	
	float radius = ability.GetFloat("radius");
	float maxdist = ability.GetFloat("maxdist");
	
	float IceSpell_Location[3];
	IceSpell_GetDistance(iClient, maxdist, IceSpell_Location);

	int target = -1;
	for (int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		if (IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx) && clientIdx != iClient)
		{
			float playerPos[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecOrigin", playerPos);
			if (CylinderCollision(IceSpell_Location, playerPos, radius*0.5+20.5, IceSpell_Location[2]-radius*0.75, IceSpell_Location[2]+radius*0.75))
//			if (IsPlayerInRange(clientIdx, IceSpell_Location, radius*0.5))
			{
				target = clientIdx;
				break;
			}
		}
	}

	if(target == -1)
		return;

	BossData boss = FF2R_GetBossData(iClient);
	SetBossCharge(boss, "0", 0.0);

	ability.GetString("model", SnowGrave_Model, sizeof(SnowGrave_Model), "models/error.mdl");

	if(ability.GetBool("thinkafter"))
	{
		int special = boss.Special;
		if(special > 0)
		{
			boss = FF2R_GetSpecialData(special);
			if(boss)
			{
				boss.SetBool("blocked", true);
				boss.SetBool("preview", true);
				boss.SetString("description_en", "* Noelle became stronger.");
			}
		}
	}

	SnowGraveState = 3;
	SnowGraveCaster = iClient;
	SnowGraveTarget = target;
	SnowGravePhase = 0;
	SnowGravePhaseChangeTime = GetEngineTime()+3.0;
	TF2_AddCondition(iClient, TFCond_FreezeInput, 20.0);
	HasAbility[iClient] = 0;
	DefendButton[iClient] = 0;
	ClearSyncHud(iClient, SyncHud[0]);
	ClearSyncHud(iClient, SyncHud[1]);

	TF2_StunPlayer(target, 999.9, 1.0, TF_STUNFLAGS_LOSERSTATE, iClient);
	SetEntityMoveType(target, MOVETYPE_NONE);
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, {0.0, 0.0, 0.0});
	GetEntPropVector(target, Prop_Data, "m_vecOrigin", SnowGrave_Location);
	SetEntProp(target, Prop_Data, "m_takedamage", 1);
	
	FF2_StopMusic(0);

	for (int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
	{
		if (IsClientInGame(clientIdx))
		{
			FF2R_SetClientHud(clientIdx, false);
		}
	}
	
	for(int i = 1; i <= 2048; i++)
	{
		if(i > MaxClients && IsValidEntity(i) && HasEntProp(i, Prop_Send, "m_hMyWeapons") && HasEntProp(i, Prop_Send, "m_iObjectType"))
		{
			SetEntProp(i, Prop_Send, "m_bDisabled", 1);
		}
	}

	// Kill the dome
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		if(GetEntityRenderMode(entity) == RENDER_TRANSCOLOR)
			RemoveEntity(entity);
	}
}

static Action OnTriggerOverlapStart(int trigger, int other)
{
	int client = GetEntPropEnt(trigger, Prop_Send, "moveparent");
	if(client > 0 && client <= MaxClients && other > 0 && other <= MaxClients && client != other)
	{
		if(IsPlayerAlive(client) && SnowGraveState < 3)
			FF2R_EmitBossSoundToAll("sound_graze", client, _, client, _, 95);
		
		GrazeCount[client]++;
	}

	return Plugin_Continue;
}

static Action OnTriggerOverlapEnd(int trigger, int other)
{
	int client = GetEntPropEnt(trigger, Prop_Send, "moveparent");
	if(client > 0 && client <= MaxClients && other > 0 && other <= MaxClients && client != other)
	{
		GrazeCount[client]--;
	}

	return Plugin_Continue;
}

void IceSpell_GetDistance(int client, float maxDistance = 999999.9, float endPos[3])
{
	float startPos[3], eyeAngles[3];
	GetClientEyePosition(client, startPos);
	GetClientEyeAngles(client, eyeAngles);
	TR_TraceRayFilter(startPos, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, IceSpellTrace, GetClientTeam(client));
	TR_GetEndPosition(endPos);

	float distance = GetVectorDistance(startPos, endPos);
	if(distance > maxDistance)
		constrainDistance(startPos, endPos, distance, maxDistance);
}

static bool IceSpellTrace(int entity, int contentsMask, any data)
{
	if(entity > 0 && entity <= MaxClients)
		return GetClientTeam(entity) != data;

	return IsValidEntity(entity);
}

static bool SnowGraveTrace(int entity, int contentsMask)
{
	if(entity > 0 && entity <= MaxClients)
		return false;

	return IsValidEntity(entity);
}

static void UpdatePlayerHitbox(int client, float scale)
{
	float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	float vecScaledPlayerMin[3];
	float vecScaledPlayerMax[3];
	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
	ScaleVector(vecScaledPlayerMin, scale);
	ScaleVector(vecScaledPlayerMax, scale);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

static void FormatBounds(float mins[3], float maxs[3], float bounds)
{
	for (int i = 0; i < 3; i++)
	{
		if (i == 2)
		{
			bounds*=2.0;
		}
		maxs[i] = bounds;
		if (i != 2)
			mins[i] = bounds * -1.0;
		else
			mins[i] = bounds * -0.25;
	}
}

static void DrawBoundingBox_Internal(const float start[3], const float end[3], int client = 0, float time = 0.1)
{
	TE_SetupBeamPoints(start, end, BEACON_BEAM_GRAZE, 0, 0, 0, time, 3.0, 3.0, 7, 0.0, {255, 255, 255, 63}, 0);
	TE_SendToAll();
	if(client) {}
}

static void DrawBoundingBox(int ent, int client = 0, float time = 0.1)
{
	float posMin[4][3], posMax[4][3];
	float orig[3];

	GetEntPropVector(ent, Prop_Send, "m_vecMins", posMin[0]);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", posMax[0]);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", orig);

	posMin[0][2]-=(posMax[0][2]*0.25);
	posMax[0][2]-=(posMax[0][2]*0.25);

	ScaleVector(posMin[0], 2.0);
	ScaleVector(posMax[0], 2.0);

	// Incase the entity is a player i want to make the box fit..

	posMin[1][0] = posMax[0][0];
	posMin[1][1] = posMin[0][1];
	posMin[1][2] = posMin[0][2];
	posMax[1][0] = posMin[0][0];
	posMax[1][1] = posMax[0][1];
	posMax[1][2] = posMax[0][2];
	posMin[2][0] = posMin[0][0];
	posMin[2][1] = posMax[0][1];
	posMin[2][2] = posMin[0][2];
	posMax[2][0] = posMax[0][0];
	posMax[2][1] = posMin[0][1];
	posMax[2][2] = posMax[0][2];
	posMin[3][0] = posMax[0][0];
	posMin[3][1] = posMax[0][1];
	posMin[3][2] = posMin[0][2];
	posMax[3][0] = posMin[0][0];
	posMax[3][1] = posMin[0][1];
	posMax[3][2] = posMax[0][2];

	AddVectors(posMin[0], orig, posMin[0]);
	AddVectors(posMax[0], orig, posMax[0]);
	AddVectors(posMin[1], orig, posMin[1]);
	AddVectors(posMax[1], orig, posMax[1]);
	AddVectors(posMin[2], orig, posMin[2]);
	AddVectors(posMax[2], orig, posMax[2]);
	AddVectors(posMin[3], orig, posMin[3]);
	AddVectors(posMax[3], orig, posMax[3]);

	//DrawBoundingBox_Internal(posMin[0], posMax[0], client, time);
	//DrawBoundingBox_Internal(posMin[1], posMax[1], client, time);
	//DrawBoundingBox_Internal(posMin[2], posMax[2], client, time);
	//DrawBoundingBox_Internal(posMin[3], posMax[3], client, time);

	//UP & DOWN

	//BORDER
	DrawBoundingBox_Internal(posMin[0], posMax[3], client, time);
	DrawBoundingBox_Internal(posMin[1], posMax[2], client, time);
	DrawBoundingBox_Internal(posMin[3], posMax[0], client, time);
	DrawBoundingBox_Internal(posMin[2], posMax[1], client, time);

	//TOP

	//BORDER
	DrawBoundingBox_Internal(posMax[0], posMax[1], client, time);
	DrawBoundingBox_Internal(posMax[1], posMax[3], client, time);
	DrawBoundingBox_Internal(posMax[3], posMax[2], client, time);
	DrawBoundingBox_Internal(posMax[2], posMax[0], client, time);

	//BOTTOM

	//BORDER
	DrawBoundingBox_Internal(posMin[0], posMin[1], client, time);
	DrawBoundingBox_Internal(posMin[1], posMin[3], client, time);
	DrawBoundingBox_Internal(posMin[3], posMin[2], client, time);
	DrawBoundingBox_Internal(posMin[2], posMin[0], client, time);
}

static int CreateParticle(const char[] type, int entity, int attach = 0, float temp = 0.0, float xOffs = 0.0, float yOffs = 0.0, float zOffs = 0.0, float angles[3] = {0.0, 0.0, 0.0})
{
	int particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEdict(particle))
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos, 0);
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		TeleportEntity(particle, pos, angles, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);
		if (attach)
		{
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
			if (attach == 2)
			{
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
			else if (attach == 3)
			{
				SetVariantString("flag");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
			else if (attach == 4)
			{
				SetVariantString("eyeglow_L");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
			else if (attach == 5)
			{
				SetVariantString("eyeglow_R");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		DispatchKeyValue(particle, "targetname", "present");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start", -1, -1, 0);
		if (temp)
			SetEntitySelfDestruct(particle, temp);
	}
	else
	{
		LogError("(CreateParticle): Could not create info_particle_system");
	}
	return particle;
}

static void SetEntitySelfDestruct(int entity, float duration)
{
	char output[64];
	Format(output, 64, "OnUser1 !self:kill::%.1f:1", duration);
	SetVariantString(output);
	AcceptEntityInput(entity, "AddOutput", -1, -1, 0);
	AcceptEntityInput(entity, "FireUser1", -1, -1, 0);
}

static bool CylinderCollision(float cylinderOrigin[3], float colliderOrigin[3], float maxDistance, float zMin, float zMax)
{
	if (colliderOrigin[2] < zMin || colliderOrigin[2] > zMax)
		return false;

	static float tmpVec1[3];
	tmpVec1[0] = cylinderOrigin[0];
	tmpVec1[1] = cylinderOrigin[1];
	tmpVec1[2] = 0.0;
	static float tmpVec2[3];
	tmpVec2[0] = colliderOrigin[0];
	tmpVec2[1] = colliderOrigin[1];
	tmpVec2[2] = 0.0;

	return GetVectorDistance(tmpVec1, tmpVec2, true) <= maxDistance * maxDistance;
}

static Action Timer_EnableSentry(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != INVALID_ENT_REFERENCE)
		SetEntProp(entity, Prop_Send, "m_bDisabled", false);
	
	return Plugin_Continue;
}

static void constrainDistance(const float startPoint[3], float endPoint[3], float distance, float maxDistance)
{
	if (distance <= maxDistance)
		return; // nothing to do

	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

static bool ActivateAbility(int client, BossData boss, ConfigData spells, SortedSnapshot snap, int index, float gameTime, int &summonable = -2, int &allies = -2)
{
	bool refund = summonable == -2;
	
	int length = snap.KeyBufferSize(index)+1;
	char[] key = new char[length];
	snap.GetKey(index, key, length);
	
	static PackVal val;
	spells.GetArray(key, val, sizeof(val));
	if(val.tag == KeyValType_Section && val.cfg)
	{
		ConfigData cfg = view_as<ConfigData>(val.cfg);
		if(cfg.GetFloat("delayfor") < gameTime)
		{
			int flags = cfg.GetInt("flags");
			if((flags & MAG_SUMMON) && GetDeadCount(client, summonable, allies) && !summonable)
			{
			}
			else if((flags & MAG_PARTNER) && GetDeadCount(client, summonable, allies) && !allies)
			{
			}
			else if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
			{
			}
			else if((flags & MAG_GROUND) && !(GetEntityFlags(client) & FL_ONGROUND))
			{
			}
			else if((flags & MAG_MAGIC) && TF2_IsPlayerInCondition(client, TFCond_Sapped))
			{
			}
			else
			{
				float rage = GetBossCharge(boss, "0") + (refund ? boss.GetFloat("ragemin") : 0.0);
				float cost = cfg.GetFloat("cost");
				if(rage >= cost)
				{
					if(cfg.GetBool("consume", true))
					{
						SetBossCharge(boss, "0", rage - cost);
					}
					else if(refund)
					{
						SetBossCharge(boss, "0", rage);
					}
					
					cfg.SetFloat("delayfor", gameTime + cfg.GetFloat("cooldown"));
					
					FF2R_DoBossSlot(client, cfg.GetInt("cast"));
					return true;
				}
				
				if(refund)
				{
					SetBossCharge(boss, "0", rage);
					refund = false;
				}
			}
		}
		
		if(refund)
			SetBossCharge(boss, "0", GetBossCharge(boss, "0") + boss.GetFloat("ragemin"));
		
		int slot = cfg.GetInt("nocast", -2147483647);
		if(slot != -2147483647)
		{
			FF2R_DoBossSlot(client, slot);
			return true;
		}
	}
	
	ClientCommand(client, "playgamesound " ... AMS_DENYUSE);
	return false;
}

static bool ChangeAbility(int client, BossData boss, ConfigData ability, ConfigData spells, SortedSnapshot snap, bool backwards, int attempt = 0)
{
	int length = snap.Length;
	if(length == 1)
		return false;
	
	if(backwards)
	{
		if(--HasAbility[client] < 1)
			HasAbility[client] = length;
	}
	else if(++HasAbility[client] > length)
	{
		HasAbility[client] = 1;
	}

	if(attempt < length)
	{
		length = snap.KeyBufferSize(HasAbility[client] - 1) + 1;
		char[] key = new char[length];
		snap.GetKey(HasAbility[client] - 1, key, length);
		
		static PackVal val;
		spells.GetArray(key, val, sizeof(val));
		if(val.tag != KeyValType_Section || !val.cfg)
			return false;
		
		int flags = view_as<ConfigData>(val.cfg).GetInt("flags");
		if((flags & MAG_LASTLIFE) && boss.GetInt("livesleft", 1) != 1)
		{
			return ChangeAbility(client, boss, ability, spells, snap, backwards, attempt + 1);
		}
		
		if((flags & MAG_SNOWGRAVE) && SnowGraveState < 2)
		{
			return ChangeAbility(client, boss, ability, spells, snap, backwards, attempt + 1);
		}
	}
	
	if(ability.GetInt("slot") == 0)
	{
		length = snap.KeyBufferSize(HasAbility[client] - 1) + 1;
		char[] key = new char[length];
		snap.GetKey(HasAbility[client] - 1, key, length);
		
		static PackVal val;
		spells.GetArray(key, val, sizeof(val));
		if(val.tag != KeyValType_Section || !val.cfg)
			return false;
		
		boss.SetFloat("ragemin", view_as<ConfigData>(val.cfg).GetFloat("cost"));
	}
	
	ClientCommand(client, "playgamesound " ... AMS_SWITCH);
	return true;
}

static bool GetDeadCount(int client, int &summonable, int &allies)
{
	if(summonable < 0 || allies < 0)
	{
		summonable = 0;
		allies = 0;
		
		int team1 = GetClientTeam(client);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i != client && IsClientInGame(i))
			{
				int team2 = GetClientTeam(i);

				if(FF2R_GetBossData(i))
				{
					if(IsPlayerAlive(i) && team1 == team2)
						allies++;
				}
				else if(team1 == team2 || team2 > view_as<int>(TFTeam_Spectator))
				{
					if(team1 == team2 || !IsPlayerAlive(i))
						summonable++;
				}
			}
		}
	}
	return true;
}

static void GetButtons(ConfigData ability, bool cycle, int &count, int button[4])
{
	if(count == -1)
	{
		count = 0;
		
		if(!cycle && ability.GetInt("slot") == 0)
			button[count++] = 0;
		
		if(ability.GetBool("altfire", false))
			button[count++] = 1;
		
		if(ability.GetBool("reload", true))
			button[count++] = 2;
		
		if(ability.GetBool("special", true))
			button[count++] = 3;
	}
}

// https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/VScript_Examples#Special_death_effects_on_triggers
static void DealFreezeDamage(int entity, int inflictor, int attacker, float damage, int damageType = DMG_GENERIC, const float damageForce[3] = NULL_VECTOR, const float damagePosition[3] = NULL_VECTOR)
{
	if(!IsValidEntity(FreezeKnife))
	{
		FreezeKnife = CreateEntityByName("tf_weapon_knife");
		SetEntProp(FreezeKnife, Prop_Send, "m_iItemDefinitionIndex", 649);
		SetEntProp(FreezeKnife, Prop_Send, "m_bInitialized", 649);
		DispatchSpawn(FreezeKnife);
		SetEntityRenderMode(FreezeKnife, RENDER_NONE);
		Attrib_Set(FreezeKnife, "freeze backstab victim", 347, 1.0);
		FreezeKnife = EntIndexToEntRef(FreezeKnife);
	}

	FrozenVictims++;
	
    SetEntPropEnt(FreezeKnife, Prop_Send, "m_hOwner", attacker);
	VScript_TakeDamageCustom(entity, inflictor, attacker, damage, damageType, FreezeKnife, damageForce, damagePosition, TF_CUSTOM_BACKSTAB);
	
	if(IsPlayerAlive(entity) && GetClientHealth(entity) > 0)
		FrozenVictims--;

    // I don't remember why this is needed
    int ragdoll = GetEntPropEnt(entity, Prop_Send, "m_hRagdoll");
    if(ragdoll != -1)
        SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", 0);
}

static void Fade(int iClient, int duration, int time, const int color[4], int flag)
{
	Handle hBf = StartMessageOne("Fade", iClient, 0);
	if (hBf)
	{
		BfWriteShort(hBf, duration);
		BfWriteShort(hBf, time);
		BfWriteShort(hBf, flag);
		BfWriteByte(hBf, color[0]);
		BfWriteByte(hBf, color[1]);
		BfWriteByte(hBf, color[2]);
		BfWriteByte(hBf, color[3]);
		EndMessage();
	}
}