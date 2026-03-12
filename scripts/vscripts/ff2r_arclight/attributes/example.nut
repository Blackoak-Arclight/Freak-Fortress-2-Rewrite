g_AttributeList["mod example attib"] <-
{
	"OnDealDamage" : function(params, attribValue)
	{
		printl("OnDealDamage")
		printl("   weapon = " + params.weapon)
		printl("   attribValue = " + attribValue)
	}
}