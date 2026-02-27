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

