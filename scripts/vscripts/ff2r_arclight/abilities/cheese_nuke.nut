/*
	"rage_cheese_nuke"
	{
		"slot"			"0"			// Ability slot
		"delay"			"4.5"		// Delay in seconds
		"range"			"300000.0"	// Effect range

		"damage"		"10.0"						// Damage to players
		"knockback"		"500.0"						// Knockback to players
		"duration"		"10.0"						// Particle lifetime
		"particle"		"superrare_confetti_green"	// Particle effect

		"buildings"		"5"	// Buildings to destory (1 = Dispenser, 2 = Teleporter, 4 = Sentry, 8 = Sapper)

		"shake"			"1.0"	// Shake duration
		"amplitude"		"120.0"	// Shake amplitude
		"frequency"		"250.0"	// Shake frequency

		"script_name"	"ff2r_arclight"
	}

	"sound_cheese_nuke"
	{
	}
*/
g_AbilityList["rage_cheese_nuke"] <-
{
	"OnAbility" : function(hClient, tBoss, tAbility)
	{
		local flDelay = GetArgFloat(tAbility, "delay", 0.0)
		tAbility._timer <- CreateTimer(@() CheeseNuke(hClient, tAbility), flDelay)
	}
	"OnRemoved" : function(hClient, tBoss, tAbility)
	{
		if("_timer" in tAbility)
		{
			KillTimer(tAbility._timer)
			delete tAbility._timer
		}
	}
}

function CheeseNuke(hClient, tAbility)
{
	if("_timer" in tAbility)
		delete tAbility._timer

	local flDamage = GetArgFloat(tAbility, "damage", 0.0)
	local flRange = GetArgFloat(tAbility, "range", 0.0)
	local flKnockback = GetArgFloat(tAbility, "knockback", 0.0)
	local flShake = GetArgFloat(tAbility, "shake", 0.0)
	local flAmplitude = GetArgFloat(tAbility, "amplitude", 0.0)
	local flFrequency = GetArgFloat(tAbility, "frequency", 0.0)
	local iBuildings = GetArgInt(tAbility, "buildings", 0)
	local flDuration = GetArgFloat(tAbility, "duration", 0.0)
	local strParticle = GetArgString(tAbility, "particle")

	local iTeam = hClient.GetTeam()
	local vecOrigin = hClient.GetOrigin()

	local hEntity = null
	while(hEntity = FindByClassname(hEntity, "player"))
	{
		if(hEntity != hClient && PlayerAlive(hEntity) && hEntity.GetTeam() != iTeam)
		{
			local vecOther = hEntity.GetOrigin()
			local vecKnockback = vecOrigin - vecOther
			local flDist = vecKnockback.Length()
			if(flDist > flRange)
				continue

			if(flDamage > 0.0)
				hEntity.TakeDamage(flDamage, DMG_PREVENT_PHYSICS_FORCE, hClient)

			if(flKnockback > 0.0)
			{
				vecKnockback.Norm()
				if(vecKnockback.z < 0.1)
					vecKnockback.z = 0.1;

				vecKnockback.Scale(flKnockback * (((flRange - flDist) * 2.0) / flRange))
				hEntity.SetAbsVelocity(vecKnockback)
			}

			if(strParticle != null)
			{
				local hParticle = SpawnEntityFromTable("info_particle_system", {
					origin = vecOther
					effect_name = strParticle
				})

				hParticle.AcceptInput("SetParent", "!activator", hClient, null)
				hParticle.AcceptInput("Start", "", null, null)
				EntFireByHandle(hParticle, "Kill", "", flDuration, null, null)
			}
		}
	}

	while(hEntity = FindByClassname(hEntity, "obj_*"))
	{
		if(hEntity != hClient && hEntity.GetTeam() != iTeam)
		{
			/*
				OBJ_DISPENSER 	0
				OBJ_TELEPORTER 	1
				OBJ_SENTRYGUN 	2
				OBJ_ATTACHMENT_SAPPER 	3
			*/
			if(!(iBuildings & (1 << GetPropInt(hEntity, "m_iObjectType"))))
				continue;

			local vecDist = vecOrigin - hEntity.GetOrigin()
			local flDist = vecDist.Length()
			if(flDist > flRange)
				continue

			hEntity.TakeDamage(5000.0, DMG_PREVENT_PHYSICS_FORCE, hClient)
		}
	}

	if(flShake > 0.0)
	{
		local hShake = SpawnEntityFromTable("env_shake", {
			origin = vecOrigin
			amplitude = flAmplitude
			radius = flRange
			duration = flShake
			frequency = flFrequency
			spawnflags = 8
		})

		hShake.AcceptInput("StartShake", "", null, null)
		EntFireByHandle(hShake, "Kill", "", flShake + 1.0, null, null)
	}

	FF2_EmitBossSound(hClient, {sound_name = "sound_cheese_nuke"})
	return null
}
