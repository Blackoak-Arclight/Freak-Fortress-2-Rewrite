/*
	"think_cheese_manic"
	{
		"normal_index"		"264"										// Normal weapon index
		"normal_particle"	"ghost_smoke"								// Normal particle effect
		"normal_model"		"models/sarysa/cheese/cheese_normal.mdl"	// Normal model swap
		"manic_index"		"999"										// Rage weapon index
		"manic_particle"	"bday_confetti"								// Rage particle effect
		"manic_model"		"models/sarysa/cheese/cheese_manic.mdl"		// Rage model swap

		"minrage"	"10.0"	// Min rage to activate
		"button"	"13"	// Button to activate (11=M2, 13=Reload, 25=M3)
		"cost"		"10.0"	// Rage drain per second

		// Overlays when rage is ready
		"overlay1"	"freak_fortress_2/dots/reload_overlay1"
		"overlay2"	"freak_fortress_2/dots/reload_overlay2"

		"script_name"	"ff2r_arclight"
	}

	"sound_cheese_manic"
	{
		"normal.mp3"	"normal"
		"manic.mp3"		"manic"
	}
*/
g_AbilityList["think_cheese_manic"] <-
{
	"OnCreated" : function(hClient, tBoss, tAbility)
	{
		local m = player.GetScriptScope()
		m.think_cheese_manic <- tAbility
		m.think_cheese_manic._holding <- false
		m.think_cheese_manic._checkin <- 0.0
		m.think_cheese_manic._overlayin <- 0.0
		m.think_cheese_manic._overlaymode <- false
		AddThinkToEnt(hClient, "DotManicThink")
	}
	"OnEquipped" : function(hClient, tBoss, tAbility)
	{
		DotManicSwitch(hClient, tAbility, "normal", false)
	}
	"OnRemoved" : function(hClient, tBoss, tAbility)
	{
		hClient.SetScriptOverlayMaterial("")
		hClient.RemoveCustomAttribute("disable weapon switching")
		SetPropString(hClient, "m_iszScriptThinkFunction", "")

		local m = player.GetScriptScope()
		if("think_cheese_manic" in m)
			delete m.think_cheese_manic
	}
	"OnTakeDamage" : function(params, tBoss, tAbility)
	{
		if(params.inflictor != null && params.inflictor.GetClassname() == "obj_sentrygun")
		{
			local hActive = GetPropEntity(params.const_entity, "m_hActiveWeapon")
			if(GetPropInt(hActive, "m_Item.m_iItemDefinitionIndex") == GetArgInt(tAbility, "manic_index"))
				params.damage_type = params.damage_type | DMG_PREVENT_PHYSICS_FORCE
		}
	}
}

function DotManicThink()
{
	local m = self.GetScriptScope()

	if(!PlayerAlive(self))
	{
		if(m.think_cheese_manic._overlayin != 0.0)
		{
			self.SetScriptOverlayMaterial("")
			m.think_cheese_manic._overlayin = 0.0
		}
		return -1.0
	}

	local iButtons = GetPropInt(self, "m_nButtons")
	if(m.think_cheese_manic._holding)
	{
		if(!(iButtons & GetArgInt(m.think_cheese_manic, "button", 13)))
			m.think_cheese_manic._holding = false
	}
	else if(iButtons & GetArgInt(m.think_cheese_manic, "button", 13))
	{
		m.think_cheese_manic._holding = true

		local hActive = GetPropEntity(self, "m_hActiveWeapon")
		if(hActive != null && GetPropInt(hActive, "m_Item.m_iItemDefinitionIndex") == GetArgInt(m.think_cheese_manic, "manic_index"))
		{
			DotManicSwitch(self, m.think_cheese_manic, "normal", true)
		}
		else
		{
			local flRage = GetBossCharge(self, 0)
			if(flRage >= GetArgFloat(m.think_cheese_manic, "minrage", 0.0))
			{
				self.SetScriptOverlayMaterial("")
				m.think_cheese_manic._overlayin = 0.0

				DotManicSwitch(self, m.think_cheese_manic, "manic", true)
			}
		}
	}

	if(m.think_cheese_manic._checkin < Time())
	{
		m.think_cheese_manic._checkin = Time() + 0.1

		local hActive = GetPropEntity(self, "m_hActiveWeapon")
		local flRage = GetBossCharge(self, 0)

		if(hActive != null && GetPropInt(hActive, "m_Item.m_iItemDefinitionIndex") == GetArgInt(m.think_cheese_manic, "manic_index"))
		{
			local flCost = GetArgFloat(m.think_cheese_manic, "cost") / 10.0
			if(flRage < flCost)
			{
				DotManicSwitch(self, m.think_cheese_manic, "normal", true)
			}
			else
			{
				SetBossCharge(self, 0, flRage - flCost)
			}
		}
		else if(flRage >= GetArgFloat(m.think_cheese_manic, "minrage", 0.0))
		{
			if(m.think_cheese_manic._overlayin == 0.0)
				m.think_cheese_manic._overlayin = 1.0
		}
		else if(m.think_cheese_manic._overlayin != 0.0)
		{
			self.SetScriptOverlayMaterial("")
			m.think_cheese_manic._overlayin = 0.0
		}

		if(m.think_cheese_manic._overlayin != 0.0 && m.think_cheese_manic._overlayin < Time())
		{
			m.think_cheese_manic._overlayin = Time() + 0.5
			m.think_cheese_manic._overlaymode = !m.think_cheese_manic._overlaymode

			if(m.think_cheese_manic._overlaymode)
			{
				self.SetScriptOverlayMaterial(GetArgString(m.think_cheese_manic, "overlay1", ""))
			}
			else
			{
				self.SetScriptOverlayMaterial(GetArgString(m.think_cheese_manic, "overlay2", ""))
			}
		}
	}

	return -1.0
}

function DotManicSwitch(hClient, tAbility, strMode, bEffects)
{
	hClient.RemoveCustomAttribute("disable weapon switching")

	local hActive = GetPropEntity(hClient, "m_hActiveWeapon")
	local iLength = GetPropArraySize(hClient, "m_hMyWeapons")
	local iIndex = GetArgInt(tAbility, strMode + "_index", -1)
	for(local i = 0; i < iLength; i++)
	{
		local hWeapon = GetPropEntityArray(hClient, "m_hMyWeapons", i)
		if(GetPropInt(hWeapon, "m_Item.m_iItemDefinitionIndex") == iIndex)
		{
			hClient.Weapon_Switch(hWeapon)
			SetPropEntity(hClient, "m_hActiveWeapon", hWeapon)
			break
		}
	}

	hClient.AddCustomAttribute("disable weapon switching")

	if(bEffects)
	{
		local strParticle = GetArgString(tAbility, strMode + "_particle")
		if(strParticle != null)
		{
			local hParticle = SpawnEntityFromTable("info_particle_system", {
				origin = hClient.GetOrigin()
				effect_name = strParticle
			})

			hParticle.AcceptInput("Start", "", null, null)
			EntFireByHandle(hParticle, "Kill", "", 3.0, null, null)
		}

		local strModel = GetArgString(tAbility, strMode + "_model")
		if(strModel != null)
			self.SetCustomModelWithClassAnimations(strModel)

		FF2_EmitBossSound(hClient, {
			sound_name = "sound_cheese_manic"
			required = strMode
			entity = hClient
			sound_level = 100
		})
	}
}