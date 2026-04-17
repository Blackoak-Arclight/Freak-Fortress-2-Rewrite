/*
	"special_pyromancer_rageammo"
	{
		"rage_per_ammo"	"10.0"	// RAGE amount for 1 ammo
		
		"plugin_name"	"ff2r_arclight_abilities"
	}
*/

#pragma semicolon 1
#pragma newdecls required

static Handle RageAmmoTimer[MAXTF2PLAYERS];

void Pyromancer_BossCreated(int client, BossData cfg)
{
	AbilityData ability = cfg.GetAbility("special_pyromancer_rageammo");
	if(ability.IsMyPlugin())
	{
		if(!RageAmmoTimer[client])
			RageAmmoTimer[client] = CreateTimer(0.1, Timer_RageAmmo, client, TIMER_REPEAT);
	}
}

void Pyromancer_BossEquipped(int client, bool weapons)
{
	if(weapons)
	{
		AbilityData ability = FF2R_GetBossData(client).GetAbility("special_pyromancer_rageammo");
		if(ability.IsMyPlugin() && ability.GetBool("forcetype"))
		{
			int entity, i;
			while(TF2_GetItem(client, entity, i))
			{
				SetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType", 1);
			}
		}
	}
}

void Pyromancer_BossRemoved(int client)
{
	delete RageAmmoTimer[client];
}

static Action Timer_RageAmmo(Handle timer, int client)
{
	BossData boss = FF2R_GetBossData(client);
	AbilityData ability = boss.GetAbility("special_pyromancer_rageammo");
	if(ability.IsMyPlugin())
	{
		float cost = ability.GetFloat("rage_per_ammo", 1.0);
		if(cost > 0.0)
		{
			int lastAmmo = ability.GetInt("__lastammo", -1);
			float rage = GetBossCharge(boss, "0");

			if(lastAmmo != -1)
			{
				// Check if we consumed any
				int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, 1);
				if(ammo != lastAmmo)
				{
					rage += (ammo - lastAmmo) * cost;
					SetBossCharge(boss, "0", rage);
				}
			}

			lastAmmo = RoundToFloor(rage / cost);
			if(lastAmmo < 0)
				lastAmmo = 0;
			
			ability.SetInt("__lastammo", lastAmmo);
			SetEntProp(client, Prop_Data, "m_iAmmo", lastAmmo, _, 1);
			return Plugin_Continue;
		}
	}
	
	RageAmmoTimer[client] = null;
	return Plugin_Stop;
}
