//makes a base_boss "fly"
//unfinished
local locomotion = self.GetLocomotionInterface();
local target = GetListenServerHost();
local currentPos = self.GetOrigin();
const SPEED = 75;

IncludeScript("vs_math")

function Think() {
	
	//randomize target
	//build nav path
	//calculate next pos
	//check if next pos is possible and run traces if not
	//move
	
	local angleVector = CalculatePosition();
	angleVector.Norm();
	
	local newPos = currentPos + angleVector * (SPEED * 0.01);
	self.SetAbsVelocity(Vector(0, 0, 0))
	DebugDrawText(newPos, "newPos", false, 0.1)
	
	locomotion.Reset(); //prevents locomotion desyncing from model
	//locomotion.DriveTo(newPos);
	self.SetAbsOrigin(newPos);
	//locomotion.Approach(newPos, 1000);
	locomotion.FaceTowards(target.GetOrigin());
	DebugDrawLine(currentPos, newPos, 0, 255, 0, false, 20);
	currentPos = newPos;
	
	return 0.0
}

function CalculatePosition() {
	const HITBOXWIDTH = 156
	const HITBOXLENGTH = 233;
	const HITBOXHEIGHT = 168;
	const REACHED = 25;
	const HOVERABOVETARGET = 400;
	const upwardAngle = 330;
	local targetPos = target.GetOrigin() + Vector(0, 0, HOVERABOVETARGET);
	local topPosition = currentPos + self.GetAbsAngles().Forward() * 116.5 + Vector(0, 0, HITBOXHEIGHT);
	local bottomPosition = currentPos + self.GetAbsAngles().Forward() * 116.5;
	
	DebugDrawText(topPosition, "top", false, 0.1);
	DebugDrawText(bottomPosition, "bot", false, 0.1);

	if((targetPos - currentPos).Length() < REACHED) { //check if close enough, if so don't do anything
		//printl("idle")
		return QAngle(0, 0, 0).Forward();
	}
	
	local distance = targetPos - currentPos;
	
	//local start_time = RealTime();
	if(Trace(topPosition, topPosition + distance * SPEED * 0.01) == null) {
		//printl(RealTime() - start_time);
		DebugDrawBox(topPosition, self.GetBoundingMinsOriented(), self.GetBoundingMaxsOriented(), 255, 0, 0, 255, 0.1)
		return distance;
	}
	
	distance.Norm()
	local toAngle = VectorAngles(distance);
	
	
	if(Trace(topPosition, topPosition + QAngle(-30, 0, 0).Forward() * HITBOXLENGTH) == null) { //fly up
		//horizontal = 0 deg
		//vertical upward = 270 deg
		//target deg = 330 upward, -30 downward
		
		
		local angleAdjustment = upwardAngle - toAngle.x;
		local futureAngle = toAngle + QAngle(angleAdjustment, 0, 0);
		
		local finalAngle = VS.QuaternionSlerp(toAngle.ToQuat(), futureAngle.ToQuat(), 0.01).ToQAngle();
		
		local rotatedVector = VS.VectorRotateByAngle(distance, finalAngle)
		
		DebugDrawText(topPosition + Vector(0, 0, 50), finalAngle.tostring(), false, 0.1)
		DebugDrawText(topPosition + Vector(0, 0, 25), toAngle.tostring(), false, 0.1)
		
		DebugDrawLine(topPosition, topPosition + rotatedVector * HITBOXLENGTH, 255, 0, 0, false, 0.1);
		printl(VectorAngles((topPosition + rotatedVector * HITBOXLENGTH) - topPosition))
		
		if(Trace(topPosition, topPosition + rotatedVector * HITBOXLENGTH) == null) { //fly up
			return rotatedVector;
		}
	}
	else if(Trace(bottomPosition, bottomPosition + QAngle(30, 0, 0).Forward() * HITBOXLENGTH) == null) { //fly down
		//printl("down")
		return QAngle(30, 0, 0).Forward();
	}
	else { //likely solid wall, try to turn around
		//return Vector(250 * sin(Time() * 1.25), 250 * cos(Time() * 1.25), 0.0)
		return QAngle(0, 30, 0).Forward()
	}
}

function Trace(start, end) { //ideally should only hit on worldspawn and not players
	const HITBOXLENGTH = 233;
	
	local traceTable = {};
	//traceTable.start <- self.Weapon_ShootPosition();
	//traceTable.end <- traceTable.start + self.GetAbsAngles().Forward() * HITBOXLENGTH;
	traceTable.start <- start;
	traceTable.end <- end;
	traceTable.ignore <- self;
	traceTable.hullmin <- self.GetBoundingMinsOriented();
	traceTable.hullmax <- self.GetBoundingMaxsOriented();
	//hull box center follows line
	
	DebugDrawText(currentPos - self.GetBoundingMinsOriented(), "bounding mins oriented", false, 0.1)
	DebugDrawText(currentPos - self.GetBoundingMins(), "bounding mins", false, 0.1)
	
	//DebugDrawClear()
	//DebugDrawLine(traceTable.start, traceTable.end, 255, 0, 0, false, 3)
	
	//TraceLineEx(traceTable);
	TraceHull(traceTable)
	
	if(traceTable.hit) {
		return traceTable.enthit;
	}
}

AddThinkToEnt(self, "Think");

//from samisalreadytaken vs_math
const RAD2DEG = 57.295779513;
const DEG2RAD = 0.017453293;

//converts vector to qangle
function VectorAngles(forward)
{
	local yaw = 0.0, pitch = yaw;

	if ( !forward.y && !forward.x )
	{
		if ( forward.z > 0.0 )
			pitch = 270.0;
		else
			pitch = 90.0;
	}
	else
	{
		yaw = atan2( forward.y, forward.x ) * RAD2DEG;
		if ( yaw < 0.0 )
			yaw += 360.0;

		pitch = atan2( -forward.z, forward.Length2D() ) * RAD2DEG;
		if ( pitch < 0.0 )
			pitch += 360.0;
	};

	return QAngle(pitch, yaw, 0.0);
}

// Euler QAngle -> Basis Vectors.  Each vector is optional
// input vector pointers
function AngleVectors( angle, right = null, up = null )
{
	local forward = Vector();
	local sr, cr,

		yr = DEG2RAD*angle.y,
		sy = sin(yr), cy = cos(yr),

		pr = DEG2RAD*angle.x,
		sp = sin(pr), cp = cos(pr);

	if ( angle.z )
	{
		local rr = DEG2RAD*angle.z;
		sr = -sin(rr);
		cr = cos(rr);
	}
	else
	{
		sr = 0.0;
		cr = 1.0;
	};

	if ( forward )
	{
		forward.x = cp*cy;
		forward.y = cp*sy;
		forward.z = -sp;
	};

	if ( right )
	{
		right.x = sr*sp*cy+cr*sy;
		right.y = sr*sp*sy-cr*cy;
		right.z = sr*cp;
	};

	if ( up )
	{
		up.x = cr*sp*cy-sr*sy;
		up.y = cr*sp*sy+sr*cy;
		up.z = cr*cp;
	};

	return forward;
}