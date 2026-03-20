function RAD2DEG(x)
{
	return (x * (180.0 / PI))
}

function DEG2RAD(x)
{
	return (x * (PI / 180.0))
}

function VectorAngles(vecVector)
{
	local flYaw, flPitch
	if(vecVector.y == 0.0 && vecVector.x == 0.0)
	{
		flYaw = 0.0
		flPitch = vecVector.z > 0.0 ? 270.0 : 90.0
	}
	else
	{
		flYaw = RAD2DEG(atan2(vecVector.y, vecVector.x))
		if(flYaw < 0.0)
			flYaw += 360.0

		flPitch = RAD2DEG(atan2(-vecVector.z, vecVector.Length2D()))
		if(flPitch < 0.0)
			flPitch += 360.0
	}
	return QAngle(flPitch, flYaw, 0.0)
}

function GetArg(tTable, strKey, defaul = null)
{
	return (strKey in tTable) ? tTable[strKey] : defaul
}

function GetArgInt(tTable, strKey, defaul = null)
{
	return ((strKey in tTable) && typeof(tTable[strKey]) == "string") ? tTable[strKey].tointeger() : defaul
}

function GetArgFloat(tTable, strKey, defaul = null)
{
	return ((strKey in tTable) && typeof(tTable[strKey]) == "string") ? tTable[strKey].tofloat() : defaul
}

function GetArgString(tTable, strKey, defaul = null)
{
	return ((strKey in tTable) && typeof(tTable[strKey]) == "string") ? tTable[strKey] : defaul
}

function GetArgTable(tTable, strKey, defaul = null)
{
	return ((strKey in tTable) && typeof(tTable[strKey]) == "table") ? tTable[strKey] : defaul
}

local _PostInputScope = null
local _PostInputFunc  = null

// Sets functions that execute before and/or after a given input is received on the entity
// Both pre_func and post_func are optional
function SetInputHook(entity, input, pre_func, post_func)
{
	entity.ValidateScriptScope()
	local scope = entity.GetScriptScope()
	if (post_func)
	{
		local wrapper_func = function()
		{
			_PostInputScope = scope
			_PostInputFunc  = post_func
			if (pre_func)
				return pre_func.call(scope)
			return true
		}

		scope["Input" + input]           <- wrapper_func
		scope["Input" + input.tolower()] <- wrapper_func
	}
	else if (pre_func)
	{
		scope["Input" + input]           <- pre_func
		scope["Input" + input.tolower()] <- pre_func
	}
}

// Internal wrapper for SetInputHook
ROOT.setdelegate(
{
	_delslot = function(k)
	{
		if (_PostInputScope && k == "activator" && "activator" in this)
		{
			_PostInputFunc.call(_PostInputScope)
			_PostInputFunc = null
		}

		rawdelete(k)
	}
})

// Creates a timer that executes the given function after a delay
// The function may return a float value to repeat the function again after the new delay
// If the function returns nothing or null, the timer is killed
// Returns a handle to the timer, like an entity
function CreateTimer(on_timer_func, delay)
{
	local relay = Entities.CreateByClassname("logic_relay")
	SetPropBool(relay, "m_bForcePurgeFixedupStrings", true)
	relay.ValidateScriptScope()
	local relay_scope = relay.GetScriptScope()
	relay_scope.scope <- this
	relay_scope.repeat <- false

	SetInputHook(relay, "Trigger",
	function()
	{
		local delay = (on_timer_func.bindenv(scope))()
		if (delay != null)
		{
			repeat = true
			EntFireByHandle(self, "Trigger", "", delay, null, null)
		}
		return false
	}
	function()
	{
		if (repeat)
			repeat = false
		else if (self.IsValid())
			self.Kill()
	})

	EntFireByHandle(relay, "Trigger", "", delay, null, null)
	return relay
}

// Executes the function of a timer
function FireTimer(timer)
{
	if (timer && timer.IsValid())
	{
		timer.GetScriptScope().InputTrigger()
		KillTimer(timer)
	}
}

// Kills the timer, it will not execute any pending function
function KillTimer(timer)
{
	if (timer && timer.IsValid())
	{
		timer.TerminateScriptScope()
		timer.Kill()
	}
}

function PlayerAlive(hPlayer)
{
	return GetPropInt(hPlayer, "m_lifeState") == 0;
}

// Charge, eg. slot 0 is RAGE
function GetBossCharge(hPlayer, slot)
{
	local rage = FF2_PullBossKey(hPlayer, "charge" + slot)
	if(rage != null && typeof(rage) == "string")
		return rage.tofloat()

	return 0.0
}

// Charge, eg. slot 0 is RAGE
function SetBossCharge(hPlayer, slot, flAmount)
{
	FF2_PushBossKey(hPlayer, "charge" + slot, flAmount)
}

function RemoveItem(hClient, hItem)
{
	local hEntity = GetPropEntity(hItem, "m_hExtraWearable");
	if(hEntity != null)
		hEntity.Kill()

	hEntity = GetPropEntity(hItem, "m_hExtraWearableViewModel")
	if(hEntity != null)
		hEntity.Kill()

	local iLength = GetPropArraySize(hClient, "m_hMyWeapons")
	for(local i = 0; i < iLength; i++)
	{
		if(GetPropEntityArray(hClient, "m_hMyWeapons", i) == hItem)
		{
			SetPropEntityArray(hClient, "m_hMyWeapons", null, i)
			break
		}
	}

	hItem.Kill()
}