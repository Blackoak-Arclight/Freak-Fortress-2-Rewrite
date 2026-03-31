/**
 * My ninth VSP rage pack, rages for Zecora, Spike, Starlight Glimmer, ?, ?
 *
 * JaratePotion: Takes the humble Sniper Jarate and turns it into a potion the hale can use to apply various effects.
 *
 * FF2SpeedOverride: Override FF2 speed management, do it right. :P
 *
 * RageLoveCurse: Pairs up players in a radius, forces attraction and causes damage relative to distance separated from "mate".
 *
 * Rage/DOTIllusions: Creates multiple self-illusions by reskinning players to the boss.
 * Known Issues: - Some classes may break horribly depending on the class of the swap model.
 *               - Not recommended for multiple bosses in one battle to have this ability, due to efficiency modifications that were necessary.
 */

/**
 * RageLoveCurse
 */
#define LC_STRING "rage_love_curse"
#define LC_BEAM_DURATION 0.2
#define LC_HUD_Y 0.68
#define LC_MATERIAL "materials/sprites/laser.vmt"
#define LC_FLAG_NO_BEAM 0x0001
#define LC_FLAG_UBER_IMMUNE 0x0002
#define LC_FLAG_ADDITIVE 0x0004
int LC_MATERIAL_INT;
bool LC_ActiveThisRound;
bool LC_IsAffected[MAXTF2PLAYERS]; // internal (victim use)
float LC_AffectUntil[MAXTF2PLAYERS]; // internal (victim use)
int LC_Mate[MAXTF2PLAYERS]; // internal (victim use)
int LC_Curser[MAXTF2PLAYERS]; // internal (victim use)
int LC_ParticleEntRef[MAXTF2PLAYERS]; // internal (victim use)
float LC_NextAttractionAt[MAXTF2PLAYERS]; // internal (victim use)
float LC_NextDamageAt[MAXTF2PLAYERS]; // internal (victim use)
float LC_NextBeamAt[MAXTF2PLAYERS]; // internal (victim use)
float LC_NextHUDAt[MAXTF2PLAYERS]; // internal (victim use)
float LC_Duration[MAXTF2PLAYERS]; // arg1
float LC_Radius[MAXTF2PLAYERS]; // arg2
float LC_MinDistance[MAXTF2PLAYERS]; // arg3
int LC_BeamColor[MAXTF2PLAYERS]; // arg4
float LC_AttractionIntensity[MAXTF2PLAYERS]; // arg5
float LC_AttractionInterval[MAXTF2PLAYERS]; // arg6
float LC_DamageIntensity[MAXTF2PLAYERS]; // arg7
float LC_DamageInterval[MAXTF2PLAYERS]; // arg8
float LC_DamageOnMateDeath[MAXTF2PLAYERS]; // arg9
char LC_EffectName[48]; // arg10
float LC_BeamInterval[MAXTF2PLAYERS]; // arg11
char LC_AfflictionMessage[256]; // arg12
char LC_CureMessage[256]; // arg13
int LC_Flags[MAXTF2PLAYERS]; // arg19

void Sarysamods9_BossCreated(int clientIdx, BossData boss, bool setup)
{
	if(setup)
		return;
	
	AbilityData cfg = boss.GetAbility(LC_STRING);
	if (cfg)
	{
		LC_ActiveThisRound = true;
		LC_MATERIAL_INT = PrecacheModel(LC_MATERIAL);
		
		LC_Duration[clientIdx] = cfg.GetFloat("duration");
		LC_Radius[clientIdx] = cfg.GetFloat("radius");
		LC_MinDistance[clientIdx] = cfg.GetFloat("mindistance");
		LC_BeamColor[clientIdx] = ReadHexOrDecString(cfg, "beamcolor");
		LC_AttractionIntensity[clientIdx] = cfg.GetFloat("attractionintensity");
		LC_AttractionInterval[clientIdx] = cfg.GetFloat("attractioninterval");
		LC_DamageIntensity[clientIdx] = cfg.GetFloat("damageintensity");
		LC_DamageInterval[clientIdx] = cfg.GetFloat("damageinterval");
		LC_DamageOnMateDeath[clientIdx] = cfg.GetFloat("damageonmatedeath");
		cfg.GetString("effectname", LC_EffectName, 48);
		LC_BeamInterval[clientIdx] = cfg.GetFloat("beaminterval");
		ReadCenterText(cfg, "afflictionmessage", LC_AfflictionMessage);
		ReadCenterText(cfg, "curemessage", LC_CureMessage);
		LC_Flags[clientIdx] = ReadHexOrDecString(cfg, "flags");
	}
}

void Sarysamods9_BossRemoved(int clientIdx)
{
	if (LC_ActiveThisRound)
	{
		LC_Duration[clientIdx] = 0.0;

		// wait for all bosses to be removed
		bool found;
		for (int target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				if(LC_Duration[target])
				{
					found = true;
					break;
				}
			}
		}

		if(!found)
		{
			LC_ActiveThisRound = false;
			
			for (int victim = 1; victim <= MaxClients; victim++)
			{
				if (LC_IsAffected[victim])
					LC_RemoveCurse(victim);
				
				LC_IsAffected[victim] = false;
				LC_ParticleEntRef[victim] = INVALID_ENT_REFERENCE;
			}
		}
	}
}

void Sarysamods9_Ability(int clientIdx, const char[] ability_name)
{
	if (!strcmp(ability_name, LC_STRING))
	{
		Rage_LoveCurse(clientIdx);
	}
}

void Sarysamods9_GameFrame()
{
	if(LC_ActiveThisRound)
		LC_Tick(GetEngineTime());
}

/**
 * Love Curse
 */
static void Rage_LoveCurse(int clientIdx)
{
	float curTime = GetEngineTime();

	// first, find valid potential targets.
	// anyone who's invalid but is already affected, just extend their existing rage. (ubers included, can't have mates on different timers)
	static bool isValid[MAXTF2PLAYERS];
	int validCount = 0;
	static float bossPos[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPos);
	for (int victim = 1; victim <= MaxClients; victim++)
	{
		if (!IsLivingPlayer(victim) || GetClientTeam(victim) == GetClientTeam(clientIdx))
			isValid[victim] = false;
		else if (LC_IsAffected[victim])
		{
			// just extend in a ragespam case, regardless of distance or uber.
			// since rage works in pairs, would be too messy to do anything else.
			isValid[victim] = false;
			LC_AffectUntil[victim] = curTime + LC_Duration[clientIdx];
		}
		else if ((LC_Flags[clientIdx] & LC_FLAG_UBER_IMMUNE) != 0 && TF2_IsPlayerInCondition(victim, TFCond_Ubercharged))
			isValid[victim] = false;
		else
		{
			static float victimPos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
			isValid[victim] = GetVectorDistance(bossPos, victimPos) <= LC_Radius[clientIdx];
			if (isValid[victim])
				validCount++;
		}
	}
	
	// now make parings. if validCount is 1, a random player gets off the hook.
	int firstVictim;
	bool isSecond = false;
	while (validCount > 0)
	{
		int random = GetRandomInt(0, validCount - 1);
		for (int victim = 1; victim <= MaxClients; victim++)
		{
			if (isValid[victim])
			{
				if (random > 0)
					random--;
				else
				{
					if (isSecond)
					{
						// pair victim and firstVictim
						LC_IsAffected[victim] = LC_IsAffected[firstVictim] = true;
						LC_AffectUntil[victim] = LC_AffectUntil[firstVictim] = curTime + LC_Duration[clientIdx];
						LC_Curser[victim] = LC_Curser[firstVictim] = clientIdx;
						LC_NextAttractionAt[victim] = LC_NextAttractionAt[firstVictim] = curTime;
						LC_NextDamageAt[victim] = LC_NextDamageAt[firstVictim] = curTime + LC_DamageInterval[clientIdx]; // grace period
						LC_NextHUDAt[victim] = LC_NextHUDAt[firstVictim] = curTime;
						LC_Mate[victim] = firstVictim;
						LC_Mate[firstVictim] = victim;
						
						// since you don't want the beam drawing twice, only one player gets it
						LC_NextBeamAt[victim] = ((LC_Flags[clientIdx] & LC_FLAG_NO_BEAM) != 0) ? FAR_FUTURE : curTime;
						LC_NextBeamAt[firstVictim] = FAR_FUTURE;
						
						// create the lovey dovey particle
						if (strlen(LC_EffectName) > 0)
						{
							int effect = AttachParticle(victim, LC_EffectName, 80.0);
							if (IsValidEntity(effect))
								LC_ParticleEntRef[victim] = EntIndexToEntRef(effect);
							effect = AttachParticle(firstVictim, LC_EffectName, 80.0);
							if (IsValidEntity(effect))
								LC_ParticleEntRef[firstVictim] = EntIndexToEntRef(effect);
						}
						
						CreateAttachedAnnotation(victim, firstVictim, true, LC_Duration[clientIdx], LC_AfflictionMessage, firstVictim);
						CreateAttachedAnnotation(firstVictim, victim, true, LC_Duration[clientIdx], LC_AfflictionMessage, victim);
						
						isSecond = false;
					}
					else
					{
						firstVictim = victim;
						isSecond = true;
					}

					isValid[victim] = false;
					validCount--;
					break;
				}
			}
		}
	}
}

static void LC_RemoveCurse(int victim)
{
	LC_IsAffected[victim] = false;
	if (LC_ParticleEntRef[victim] != INVALID_ENT_REFERENCE)
		Timer_RemoveEntity(INVALID_HANDLE, LC_ParticleEntRef[victim]);
	LC_ParticleEntRef[victim] = INVALID_ENT_REFERENCE;
	
	if (IsLivingPlayer(victim) && LC_ActiveThisRound)
		PrintCenterText(victim, LC_CureMessage);
}

static void LC_Tick(float curTime)
{
	// for this rage, the hale does nothing that needs ticking. how nice.
	for (int victim = 1; victim <= MaxClients; victim++)
	{
		if (!LC_IsAffected[victim])
			continue;
		
		// need to clean up stuff like the beam, even if the player's dead
		if (!IsLivingPlayer(victim) || curTime >= LC_AffectUntil[victim])
		{
			LC_RemoveCurse(victim);
			continue;
		}
		
		// remove curse if the curser is dead
		int curser = LC_Curser[victim];
		if (!IsLivingPlayer(curser))
		{
			LC_RemoveCurse(victim);
			continue;
		}
		
		// check if partner died, apply damage if that happens
		int partner = LC_Mate[victim];
		if (!IsLivingPlayer(partner))
		{
			if (LC_DamageOnMateDeath[curser] > 0.0)
				SDKHooks_TakeDamage(victim, curser, curser, LC_DamageOnMateDeath[curser] / 3.0, DMG_CRIT | DMG_PREVENT_PHYSICS_FORCE, -1);
			LC_RemoveCurse(victim);
			continue;
		}
		
		// draw the HUD
		/*if (curTime >= LC_NextHUDAt[victim])
		{
			static char partnerStr[65];
			GetClientName(partner, partnerStr, sizeof(partnerStr));
			SetHudTextParams(-1.0, LC_HUD_Y, 0.1 + 0.05, GetR(LC_BeamColor[curser]), GetG(LC_BeamColor[curser]), GetB(LC_BeamColor[curser]), 192);
			ShowHudText(victim, -1, LC_AfflictionMessage, partnerStr);
			
			LC_NextHUDAt[victim] = curTime + 0.1;
		}*/
		
		// any reason to go on?
		if (!(curTime >= LC_NextAttractionAt[victim] || curTime >= LC_NextDamageAt[victim] || curTime >= LC_NextBeamAt[victim]))
			continue;
		
		// get distance now
		static float victimPos[3];
		static float partnerPos[3];
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimPos);
		GetEntPropVector(partner, Prop_Send, "m_vecOrigin", partnerPos);
		float distance = GetVectorDistance(victimPos, partnerPos);
		
		// draw the beam
		if (curTime >= LC_NextBeamAt[victim])
		{
			victimPos[2] += 41.5;
			partnerPos[2] += 41.5;
			static beamColor[4];
			beamColor[0] = GetR(LC_BeamColor[curser]);
			beamColor[1] = GetG(LC_BeamColor[curser]);
			beamColor[2] = GetB(LC_BeamColor[curser]);
			beamColor[3] = 255;
			TE_SetupBeamPoints(victimPos, partnerPos, LC_MATERIAL_INT, 0, 0, 0, LC_BEAM_DURATION, 5.0, 5.0, 0, 10.0, beamColor, 0);
			TE_SendToAll();
			victimPos[2] -= 41.5;
			partnerPos[2] -= 41.5;
		
			LC_NextBeamAt[victim] += LC_BeamInterval[curser];
		}
		
		// with all that death stuff out of the way, lets work on attraction...
		if (curTime >= LC_NextAttractionAt[victim])
		{
			if (distance > LC_MinDistance[curser])
			{
				static float angles[3];
				GetVectorAnglesTwoPoints(victimPos, partnerPos, angles);
				if (GetEntityFlags(victim) & FL_ONGROUND)
					angles[0] = 0.0; // toss out pitch if on ground
				static float velocity[3];
				GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(velocity, distance * LC_AttractionIntensity[curser]);
				
				// is it additive?
				if (LC_Flags[curser] & LC_FLAG_ADDITIVE)
				{
					// even if it is, gotta cap it...
					static float oldVelocity[3];
					GetEntPropVector(victim, Prop_Data, "m_vecVelocity", oldVelocity);
					oldVelocity[0] = fmin(300.0, fmax(-300.0, oldVelocity[0]));
					oldVelocity[1] = fmin(300.0, fmax(-300.0, oldVelocity[1]));
					velocity[0] += oldVelocity[0];
					velocity[1] += oldVelocity[1];
					// velocity[2] intentionally omitted
				}
				
				// min Z if on ground
				if (GetEntityFlags(victim) & FL_ONGROUND)
					velocity[2] = fmax(325.0, velocity[2]);
				
				// apply velocity
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
			}
			
			LC_NextAttractionAt[victim] += LC_AttractionInterval[curser];
		}
		
		// and then damage
		if (curTime >= LC_NextDamageAt[victim])
		{
			if (distance > LC_MinDistance[curser])
			{
				float damage = distance * LC_DamageIntensity[curser];
				QuietDamage(victim, curser, curser, damage, DMG_PREVENT_PHYSICS_FORCE, -1);
			}

			LC_NextDamageAt[victim] += LC_DamageInterval[curser];
		}
	}
}

static int ReadHexOrDecInt(const char[] hexOrDecString)
{
	if (StrContains(hexOrDecString, "0x") == 0)
	{
		int result = 0;
		for (int i = 2; i < 10 && hexOrDecString[i] != 0; i++)
		{
			result = result<<4;
				
			if (hexOrDecString[i] >= '0' && hexOrDecString[i] <= '9')
				result += hexOrDecString[i] - '0';
			else if (hexOrDecString[i] >= 'a' && hexOrDecString[i] <= 'f')
				result += hexOrDecString[i] - 'a' + 10;
			else if (hexOrDecString[i] >= 'A' && hexOrDecString[i] <= 'F')
				result += hexOrDecString[i] - 'A' + 10;
		}
		
		return result;
	}
	else
		return StringToInt(hexOrDecString);
}

static int ReadHexOrDecString(ConfigData cfg, const char[] arg_name)
{
	char hexOrDecString[12];
	cfg.GetString(arg_name, hexOrDecString, 12);
	return ReadHexOrDecInt(hexOrDecString);
}

static void ReadCenterText(ConfigData cfg, const char[] arg_name, char centerText[256])
{
	cfg.GetString(arg_name, centerText, 256);
	ReplaceString(centerText, 256, "\\n", "\n");
}

static bool IsLivingPlayer(int clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAXTF2PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}

static int AttachParticle(int entity, const char[] particleType, float offset=0.0, bool attach=true)
{
	int particle = CreateEntityByName("info_particle_system");
	
	if (!IsValidEntity(particle))
		return -1;

	static float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	if (attach)
	{
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", entity, entity, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

static int GetR(int c) { return abs((c>>16)&0xff); }
static int GetG(int c) { return abs((c>>8 )&0xff); }
static int GetB(int c) { return abs((c    )&0xff); }

static void QuietDamage(int victim, int inflictor, int attacker, float damage, int damageType=DMG_GENERIC, int weapon=-1)
{
	int takedamage = GetEntProp(victim, Prop_Data, "m_takedamage");
	SetEntProp(victim, Prop_Data, "m_takedamage", 0);
	SDKHooks_TakeDamage(victim, inflictor, attacker, damage, damageType, weapon);
	SetEntProp(victim, Prop_Data, "m_takedamage", takedamage);
	SDKHooks_TakeDamage(victim, victim, victim, damage, damageType, weapon);
}

static void GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}
