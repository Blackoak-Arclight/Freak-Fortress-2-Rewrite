g_AttributeList <- {}

IncludeScript("ff2r_arclight/attributes/example", ROOT)

function Attributes_OnTakeDamage(params)
{
	if(params.weapon != null)
	{
		local m = params.weapon.GetScriptScope()
		if(m != null && "ff2attributes" in m)
		{
			foreach(strName, value in m.ff2attributes)
			{
				if(strName in g_AttributeList)
				{
					if("OnDealDamage" in g_AttributeList[params.name])
						g_AttributeList[params.name]["OnDealDamage"](params, value)
				}
			}
		}
	}
}