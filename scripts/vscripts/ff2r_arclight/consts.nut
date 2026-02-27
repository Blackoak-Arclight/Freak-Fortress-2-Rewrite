foreach(k, v in NetProps.getclass())
{
	if(k != "IsValid")
	{
		ROOT[k] <- NetProps[k].bindenv(NetProps)
	}
}

FindByClassname <- Entities.FindByClassname.bindenv(Entities)
FindByClassnameNearest <- Entities.FindByClassnameNearest.bindenv(Entities)
FindByClassnameWithin <- Entities.FindByClassnameWithin.bindenv(Entities)
FindByName <- Entities.FindByName.bindenv(Entities)
FindInSphere <- Entities.FindInSphere.bindenv(Entities)

::MaxPlayers <- MaxClients().tointeger()