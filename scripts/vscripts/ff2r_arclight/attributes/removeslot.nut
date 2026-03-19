g_AttributeList["mod remove primary"] <-
{
	"OnEquipped" : function(hClient, hWeapon, attribValue)
	{
		local iLength = GetPropArraySize(hClient, "m_hMyWeapons")
		for(local i = 0; i < iLength; i++)
		{
			local hEntity = GetPropEntityArray(hClient, "m_hMyWeapons", i)
			if(hEntity != null && hEntity.Slot() == 0)
			{
				RemoveItem(hClient, hEntity)
				break
			}
		}
	}
}

g_AttributeList["mod remove secondary"] <-
{
	"OnEquipped" : function(hClient, hWeapon, attribValue)
	{
		local iLength = GetPropArraySize(hClient, "m_hMyWeapons")
		for(local i = 0; i < iLength; i++)
		{
			local hEntity = GetPropEntityArray(hClient, "m_hMyWeapons", i)
			if(hEntity != null && hEntity.Slot() == 1)
			{
				RemoveItem(hClient, hEntity)
				break
			}
		}
	}
}