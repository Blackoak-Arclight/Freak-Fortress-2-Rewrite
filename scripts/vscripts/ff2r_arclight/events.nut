function OnScriptHook_FF2_OnAbility(params)
{
	Abilities_CallByName(params, "OnAbility")
}

function OnScriptHook_FF2_OnBossCreated(params)
{
	Abilities_Call(params, "OnCreated")
}

function OnScriptHook_FF2_OnBossEquipped(params)
{
	Abilities_Call(params, "OnEquipped")
}

function OnScriptHook_FF2_OnBossRemoved(params)
{
	Abilities_Call(params, "OnRemoved")
}

function OnScriptHook_OnTakeDamage(params)
{
	Abilities_OnTakeDamage(params)
	Attributes_OnTakeDamage(params)
}
