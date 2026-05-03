#pragma semicolon 1
#pragma newdecls required

static Handle SDKEquipWearable;
static Handle SDKGetMaxHealth;
static Handle SDKAddObject;
static Handle SDKRemoveObject;
static Handle SDKDeflected;

void SDKCalls_PluginStart()
{
	GameData gamedata = new GameData("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find RemoveWearable");
	
	delete gamedata;
	
	gamedata = new GameData("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxHealth = EndPrepSDKCall();
	if(!SDKGetMaxHealth)
		LogError("[Gamedata] Could not find GetMaxHealth");
	
	delete gamedata;
	
	gamedata = new GameData("ff2");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::AddObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKAddObject = EndPrepSDKCall();
	if(!SDKAddObject)
		LogError("[Gamedata] Could not find CTFPlayer::AddObject");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::RemoveObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKRemoveObject = EndPrepSDKCall();
	if(!SDKRemoveObject)
		LogError("[Gamedata] Could not find CTFPlayer::RemoveObject");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::Deflected");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	SDKDeflected = EndPrepSDKCall();
	if(!SDKDeflected)
		LogError("[Gamedata] Could not find CBaseEntity::Deflected");
	
	delete gamedata;
}

void SDKCall_EquipWearable(int client, int entity)
{
	if(SDKEquipWearable)
	{
		SDKCall(SDKEquipWearable, client, entity);
	}
	else
	{
		RemoveEntity(entity);
	}
}

int SDKCall_GetMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

void SDKCall_AddObject(int client, int entity)
{
	if(SDKAddObject)
		SDKCall(SDKAddObject, client, entity);
}

void SDKCall_RemoveObject(int client, int entity)
{
	if(SDKRemoveObject)
		SDKCall(SDKRemoveObject, client, entity);
}

void SDKCall_Deflected(int entity, int deflector, const float dir[3])
{
	if(SDKDeflected)
		SDKCall(SDKDeflected, entity, deflector, dir);
}