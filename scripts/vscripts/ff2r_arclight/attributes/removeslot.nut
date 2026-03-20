g_AttributeList["mod remove primary"] <-
{
	"OnPostInventory" : function(hClient, hWeapon, attribValue)
	{
		local iLength = GetPropArraySize(hClient, "m_hMyWeapons")
		for(local i = 0; i < iLength; i++)
		{
			local hEntity = GetPropEntityArray(hClient, "m_hMyWeapons", i)
			if(hEntity != null && hEntity.GetSlot() == 0)
			{
				RemoveItem(hClient, hEntity)
				break
			}
		}
	}
}

g_AttributeList["mod remove secondary"] <-
{
	"OnPostInventory" : function(hClient, hWeapon, attribValue)
	{
		local iLength = GetPropArraySize(hClient, "m_hMyWeapons")
		for(local i = 0; i < iLength; i++)
		{
			local hEntity = GetPropEntityArray(hClient, "m_hMyWeapons", i)
			if(hEntity != null && hEntity.GetSlot() == 1)
			{
				RemoveItem(hClient, hEntity)
				break
			}
		}
	}
}