#pragma semicolon 1
#pragma newdecls required

static bool Loaded;
static ScriptCall ScriptSetPhysAngularVelocity;
static ScriptCall ScriptGetSequenceActivityName;
static ScriptCall ScriptTakeDamageCustom;
static ScriptCall ScriptPrimaryAttack;

void ArclightVScript_PluginStart()
{
	Loaded = LibraryExists(VSCRIPT_LIBRARY);
	if(Loaded)
		RequestFrame(SetupCalls);
}

void ArclightVScript_LibraryAdded(const char[] name)
{
	if(!Loaded && StrEqual(name, VSCRIPT_LIBRARY))
	{
		Loaded = true;
		RequestFrame(SetupCalls);
	}
}

void ArclightVScript_LibraryRemoved(const char[] name)
{
	if(Loaded && StrEqual(name, VSCRIPT_LIBRARY))
		Loaded = false;
}

static void SetupCalls()
{
	ScriptSetPhysAngularVelocity = new ScriptCall("SetPhysAngularVelocity", ScriptField_Void, ScriptField_Vector);
	ScriptGetSequenceActivityName = new ScriptCall("GetSequenceActivityName", ScriptField_String, ScriptField_Int);
	ScriptTakeDamageCustom = new ScriptCall("TakeDamageCustom", ScriptField_Void, ScriptField_HScript, ScriptField_HScript, ScriptField_HScript, ScriptField_Vector, ScriptField_Vector, ScriptField_Float, ScriptField_Int, ScriptField_Int);
	ScriptPrimaryAttack = new ScriptCall("PrimaryAttack", ScriptField_Void);
}

void VScript_SetPhysAngularVelocity(int entity, const float vec[3])
{
	if(Loaded && ScriptSetPhysAngularVelocity)
	{
		ScriptHandle hentity = VScript_EntityToHScript(entity, true);
		if(hentity)
		{
			ScriptSetPhysAngularVelocity.ExecuteInScope(hentity, vec);
			return;
		}
	}

	char buffer[96];
	FormatEx(buffer, sizeof(buffer), "self.SetPhysAngularVelocity(Vector(%.0f, %.0f, %.0f))", vec[0], vec[1], vec[2]);
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode");
}

int VScript_GetSequenceActivityName(int entity, int sequence, char[] name, int length)
{
	if(Loaded && ScriptGetSequenceActivityName)
	{
		ScriptHandle hentity = VScript_EntityToHScript(entity, true);
		if(hentity)
		{
			if(ScriptGetSequenceActivityName.ExecuteInScope(hentity, sequence) == ScriptStatus_Done)
				return ScriptGetSequenceActivityName.GetReturnString(name, length);
		}
	}

	return 0;
}

void VScript_TakeDamageCustom(int entity, int inflictor, int attacker, float damage, int damageType = DMG_GENERIC, int weapon = -1, const float damageForce[3] = NULL_VECTOR, const float damagePosition[3] = NULL_VECTOR, int damagecustom = 0)
{
	if(Loaded && ScriptTakeDamageCustom)
	{
		ScriptHandle hentity = VScript_EntityToHScript(entity, true);
		if(hentity)
		{
			ScriptHandle hattacker = (attacker && IsValidEntity(attacker)) ? VScript_EntityToHScript(attacker, true) : null;
			ScriptHandle hinflictor = (inflictor && IsValidEntity(inflictor)) ? VScript_EntityToHScript(inflictor, true) : null;
			ScriptHandle hweapon = IsValidEntity(weapon) ? VScript_EntityToHScript(weapon, true) : null;

			if(ScriptTakeDamageCustom.ExecuteInScope(hentity, hinflictor, hattacker, hweapon, damageForce, damagePosition, damage, damageType, damagecustom) == ScriptStatus_Done)
				return;
		}
	}

	SDKHooks_TakeDamage(entity, inflictor, attacker, damage, damageType, weapon, damageForce, damagePosition, false);
}

void VScript_PrimaryAttack(int entity)
{
	if(Loaded && ScriptPrimaryAttack)
	{
		ScriptHandle hentity = VScript_EntityToHScript(entity, true);
		if(hentity)
			ScriptPrimaryAttack.ExecuteInScope(hentity);
	}
}