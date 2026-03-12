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

// Creates a timer that executes the given function after a delay
// The function may return a float value to repeat the function again after the new delay
// If the function returns nothing or null, the timer is killed
// Returns a handle to the timer, like an entity
function CreateTimer(on_timer_func, delay)
{
	local relay = CreateEntitySafe("logic_relay")
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
	return FF2_PullBossKey(hPlayer, "charge" + slot)
}

// Charge, eg. slot 0 is RAGE
function SetBossCharge(hPlayer, slot, flAmount)
{
	FF2_PushBossKey(hPlayer, "charge" + slot, flAmount)
}