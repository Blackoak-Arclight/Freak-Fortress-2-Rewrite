// Adds a new argument to special_democharge, blocks using shield charge if there's not enough rage

#pragma semicolon 1
#pragma newdecls required

static Handle ChargeTimer[MAXTF2PLAYERS];

void Demopan_ConditionRemoved(int client, TFCond cond)
{
	if(cond == TFCond_Charging && !ChargeTimer[client])
	{
		BossData boss = FF2R_GetBossData(client);
		if(boss)
		{
			AbilityData ability = boss.GetAbility("special_democharge");
			if(ability && ability.GetBool("arclight"))
			{
				char slot[8];
				ability.GetString("slot", slot, sizeof(slot), "0");
				float charge = GetBossCharge(boss, slot);
				
				int alive = TotalPlayersAliveEnemy(CvarFriendlyFire.BoolValue ? -1 : GetClientTeam(client));
				
				float required = GetFormula(ability, "minimum", alive, 10.0) + GetFormula(ability, "rage", alive, 1.0);
				if(required <= charge)
				{
					int entity = -1;
					while((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1)
					{
						if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
						{
							SetEntProp(client, Prop_Send, "m_flChargeMeter", 0.0);
							Attrib_Set(entity, "charge recharge rate increased", _, 0.1);
							break;
						}
					}
					
					DataPack pack;
					ChargeTimer[client] = CreateDataTimer(0.1, DemopanTimer, pack, TIMER_REPEAT);
					pack.WriteCell(client);
					pack.WriteCell(GetClientUserId(client));
					pack.WriteString(slot);
					pack.WriteFloat(required);
				}
			}
		}
	}
}

static Action DemopanTimer(Handle timer, DataPack pack)
{
	int client = pack.ReadCell();
	if(GetClientOfUserId(pack.ReadCell()))
	{
		BossData boss = FF2R_GetBossData(client);
		if(boss)
		{
			char slot[8];
			pack.ReadString(slot, sizeof(slot));
			float charge = GetBossCharge(boss, slot);

			if(charge < pack.ReadFloat())
				return Plugin_Continue;
			
			int entity = -1;
			while((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) != -1)
			{
				if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
				{
					SetEntProp(client, Prop_Send, "m_flChargeMeter", 100.0);
					Attrib_Set(entity, "charge recharge rate increased", _, 69421.0);
					break;
				}
			}
		}
	}

	ChargeTimer[client] = null;
	return Plugin_Stop;
}