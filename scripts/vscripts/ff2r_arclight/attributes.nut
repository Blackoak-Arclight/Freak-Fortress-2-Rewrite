g_AttributeList <- {}

IncludeScript("ff2r_arclight/attributes/removeslot", ROOT)

function Attributes_Call(hClient, hWeapon, strFunc)
{
	local m = hWeapon.GetScriptScope()
	if(m != null && "ff2attributes" in m)
	{
		foreach(strName, value in m.ff2attributes)
		{
			if(strName in g_AttributeList)
			{
				if(strFunc in g_AttributeList[strName])
					g_AttributeList[strName][strFunc](hClient, hWeapon, value)
			}
		}
	}
}

function Attributes_CallByPlayer(hClient, strFunc)
{
	local iLength = GetPropArraySize(hClient, "m_hMyWeapons")
	local iIndex = GetArgInt(tAbility, strMode + "_index", -1)
	for(local i = 0; i < iLength; i++)
	{
		local hWeapon = GetPropEntityArray(hClient, "m_hMyWeapons", i)
		if(hWeapon != null)
			Attributes_Call(hClient, hWeapon, strFunc)
	}
}

function Attributes_CallDelayed()
{
	local iLength = GetPropArraySize(self, "m_hMyWeapons")
	for(local i = 0; i < iLength; i++)
	{
		local hEntity = GetPropEntityArray(self, "m_hMyWeapons", i)
		if(hEntity != null)
			Attributes_Call(self, hEntity, "OnPostInventory")
	}
}

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
					if("OnDealDamage" in g_AttributeList[strName])
						g_AttributeList[strName]["OnDealDamage"](params, value)
				}
			}
		}
	}
}