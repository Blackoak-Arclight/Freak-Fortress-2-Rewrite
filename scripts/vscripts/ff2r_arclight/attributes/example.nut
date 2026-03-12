g_AttributeList["mod example attib"] <-
{
	"OnEquipped" : function(hClient, hWeapon, attribValue)
	{
		printl("OnEquipped")
		printl("   client = " + hClient)
		printl("   weapon = " + hWeapon)
		printl("   attribValue = " + attribValue)
	}
	"OnDealDamage" : function(params, attribValue)
	{
		printl("OnDealDamage")
		printl("   weapon = " + params.weapon)
		printl("   attribValue = " + attribValue)
	}
}