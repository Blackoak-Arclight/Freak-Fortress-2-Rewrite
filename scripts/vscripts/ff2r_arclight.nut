::ROOT  <- getroottable()
::CONST <- getconsttable()

if(!("ConstantNamingConvention" in CONST))
{
	foreach(a, b in Constants)
	{
		foreach(c, d in b)
		{
			CONST[c] <- d == null ? 0 : d
		}
	}
}

IncludeScript("ff2r_arclight/consts", ROOT)
IncludeScript("ff2r_arclight/utils", ROOT)

if("ArclightFF2Events" in ROOT)
{
	ArclightFF2Events.clear()
}
else
{
	::ArclightFF2Events <- {}
}

IncludeScript("ff2r_arclight/events", ArclightFF2Events)
__CollectGameEventCallbacks(ArclightFF2Events)