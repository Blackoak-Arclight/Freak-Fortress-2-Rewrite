g_AbilityList <- {}

IncludeScript("ff2r_arclight/abilities/cheese_manic", ROOT)
IncludeScript("ff2r_arclight/abilities/cheese_nuke", ROOT)

function Abilities_CallByName(params, strFunc)
{
	if(params.name in g_AbilityList)
	{
		if(strFunc in g_AbilityList[params.name])
			g_AbilityList[params.name][strFunc](params.client, params.boss, params.ability)
	}
}

function Abilities_Call(params, strFunc)
{
	foreach(strName, tData in params.boss)
	{
		if(strName in g_AbilityList)
		{
			if(strFunc in g_AbilityList[strName])
				g_AbilityList[strName][strFunc](params.client, params.boss, tData)
		}
	}
}

function Abilities_OnTakeDamage(params)
{
	local tBoss = FF2_GetBossConfig(params.const_entity)
	if(tBoss != null)
	{
		foreach(strName, tData in tBoss)
		{
			if(strName in g_AbilityList)
			{
				if("OnTakeDamage" in g_AbilityList[strName])
					g_AbilityList[strName]["OnTakeDamage"](params, tBoss, tData)
			}
		}
	}

	if(params.attacker != null)
	{
		tBoss = FF2_GetBossConfig(params.attacker)
		if(tBoss != null)
		{
			foreach(strName, tData in tBoss)
			{
				if(strName in g_AbilityList)
				{
					if("OnDealDamage" in g_AbilityList[strName])
						g_AbilityList[strName]["OnDealDamage"](params, tBoss, tData)
				}
			}
		}
	}
}