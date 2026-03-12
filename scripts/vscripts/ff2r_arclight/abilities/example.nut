g_AbilityList["rage_example"] <-
{
	"OnAbility" : function(hClient, tBoss, tAbility)
	{
		printl("OnAbility")
		printl("   client = " + hClient)
		printl("   boss = " + tBoss["name"])
		printl("   ability = " + tAbility["script_name"])
	}
	"OnCreated" : function(hClient, tBoss, tAbility)
	{
		printl("OnCreated")
		printl("   client = " + hClient)
		printl("   boss = " + tBoss["name"])
		printl("   ability = " + tAbility["script_name"])
	}
	"OnEquipped" : function(hClient, tBoss, tAbility)
	{
		printl("OnEquipped")
		printl("   client = " + hClient)
		printl("   boss = " + tBoss["name"])
		printl("   ability = " + tAbility["script_name"])
	}
	"OnRemoved" : function(hClient, tBoss, tAbility)
	{
		printl("OnRemoved")
		printl("   client = " + hClient)
		printl("   boss = " + tBoss["name"])
		printl("   ability = " + tAbility["script_name"])
	}
	"OnTakeDamage" : function(params, tBoss, tAbility)
	{
		printl("OnTakeDamage")
		printl("   const_entity = " + params.const_entity)
		printl("   boss = " + tBoss["name"])
		printl("   ability = " + tAbility["script_name"])
	}
	"OnDealDamage" : function(params, tBoss, tAbility)
	{
		printl("OnDealDamage")
		printl("   attacker = " + params.attacker)
		printl("   boss = " + tBoss["name"])
		printl("   ability = " + tAbility["script_name"])
	}
}