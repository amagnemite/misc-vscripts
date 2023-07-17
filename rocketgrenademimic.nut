local rockets = {};
local originQueue = [];
local angleQueue = [];
local rocketLauncher = null;
const INTERVAL = 1;

//ClientPrint(null, 3, Convars.GetBool("sig_pop_tfbot_extensions"));
//Assert(Convars.GetBool("sig_pop_tfbot_extensions"), "error - not a rafmod server");

//NetProps.SetPropString(self, "m_iName", self.GetEntityIndex().tostring());

/*
local mimic = SpawnEntityFromTable("tf_point_weapon_mimic", {
	teamnum = self.GetTeam(),
	spawnflags = 4,
	["$preventshootparent"] = 1,
	["$weaponname"] = "nuke", //edit here
	//"OnUser4#1" = self.GetEntityIndex() + ",RunScriptCode,UpdateProjectile(activator),0,-1"
	["$OnFire#1"] = self.GetEntityIndex() + ",RunScriptCode,UpdateProjectile(activator),0,-1"
});
mimic.SetOwner(self);
*/
//EntityOutputs.AddOutput(mimic, "OnUser4", self.GetEntityIndex().tostring(), "RunScriptCode", "UpdateProjectile(activator)", 0, -1);

function UpdateProjectile(projectile) {
	//ClientPrint(null, 2, "projectile")
	//ClientPrint(null, 2, projectile)
	projectile.SetAbsOrigin(originQueue.remove(0));
	projectile.SetAbsAngles(angleQueue.remove(0));
}

for(local i = 0; i < NetProps.GetPropArraySize(self, "m_hMyWeapons"); i++) {
	local weapon = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i);
	if(weapon == null) continue;
	
	if(weapon.GetClassname() == "tf_weapon_rocketlauncher") {
		rocketLauncher = weapon;
	}
}

function Think() {
	if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
		AddThinkToEnt(self, null);
		NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
		mimic.Kill();
		self.TerminateScriptScope();
	}

	if((Time() - NetProps.GetPropFloat(rocketLauncher, "m_flNextPrimaryAttack")) <= INTERVAL) {
		//if fired in the last second
		local rocket = null;
		while(rocket = Entities.FindByClassnameWithin(rocket, "tf_projectile_rocket", self.GetOrigin(), 2200)) {
			if(rocket.GetOwner() == self && !(rocket in rockets)) {
				rockets[rocket] <- {};
				//rockets[rocket].velocity <- rocket.GetAbsVelocity();
				rockets[rocket].origin <- rocket.GetOrigin();
				rockets[rocket].angles <- rocket.GetAbsAngles();
			}
		}
	}
	
	foreach(rocket, data in rockets) {
		if(!rocket.IsValid()) { //rocket blew up on something and isn't valid anymore
			//ClientPrint(null, 3, "rocket " + data.origin.tostring())
			
			originQueue.append(data.origin);
			angleQueue.append(data.angles);
			
			local mimic = SpawnEntityFromTable("tf_point_weapon_mimic", {
				teamnum = self.GetTeam(),
				spawnflags = 4,
				["$preventshootparent"] = 1,
				["$weaponname"] = "nuke", //edit here
				angles = angleQueue.remove(0)
			});
			mimic.SetOwner(self);
			mimic.SetAbsOrigin(originQueue.remove(0))
			
			//ClientPrint(null, 3, mimic.GetOrigin().tostring())
			
			mimic.ValidateScriptScope()
			mimic.GetScriptScope().first <- true
			mimic.GetScriptScope().think <- function() {
				if(first) {
					first = false
				}
				else {
					self.Kill()
				}
				return 5
			}
			
			
			EntFireByHandle(mimic, "FireOnce", null, -1, null, null);
			
			
			delete rockets[rocket];
		}
		else { //update data
			//rockets[rocket].velocity = rocket.GetAbsVelocity();
			rockets[rocket].origin = rocket.GetOrigin();
			rockets[rocket].angles = rocket.GetAbsAngles();
		}
	}
}

AddThinkToEnt(self, "Think");