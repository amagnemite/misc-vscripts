local rockets = {};
local rocketLauncher = null;
local customWeapon = null;
local projectileType = null;
const INTERVAL = 1;

for(local i = 0; i < NetProps.GetPropArraySize(self, "m_hMyWeapons"); i++) {
	local weapon = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i);
	if(weapon == null) continue;
	
	if(weapon.GetClassname() == "tf_weapon_rocketlauncher") {
		rocketLauncher = weapon;
	}
	else if(weapon.GetSlot() == 1) {
		customWeapon = weapon;
	}
}

function Think() {
	if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
		AddThinkToEnt(self, null);
		NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
		self.TerminateScriptScope();
	}

	if((Time() - NetProps.GetPropFloat(rocketLauncher, "m_flNextPrimaryAttack")) <= INTERVAL) {
		//if fired in the last second
		local rocket = null;
		while(rocket = Entities.FindByClassnameWithin(rocket, "tf_projectile_rocket", self.GetOrigin(), 2200)) {
			if(rocket.GetOwner() == self && !(rocket in rockets)) {
				rockets[rocket] <- {};
				rockets[rocket].velocity <- rocket.GetAbsVelocity();
				rockets[rocket].origin <- rocket.GetOrigin();
				rockets[rocket].angles <- rocket.GetAbsAngles();
			}
		}
	}
	
	foreach(rocket, data in rockets) {
		if(!rocket.IsValid()) { //rocket blew up on something and isn't valid anymore
			local grenade = SpawnEntityFromTable(projectileType, {
				teamnum = self.GetTeam()
				//basevelocity = data.velocity
				origin = data.origin
				angles = data.angles
			});
			grenade.SetOwner(self);
			if(NetProps.HasProp(grenade, "m_hThrower")) { // i hate grenades
				//grenade.ApplyAbsVelocityImpulse(data.velocity); 
				NetProps.SetPropFloat(grenade, "m_flDamage", 100); //as it turns out, you need to manually set grenade dmg
				NetProps.SetPropEntity(grenade, "m_hLauncher", customWeapon);
			}
			
			delete rockets[rocket];
		}
		else { //update data
			//rockets[rocket].velocity = rocket.GetAbsVelocity();
			rockets[rocket].origin = rocket.GetOrigin();
			rockets[rocket].angles = rocket.GetAbsAngles();
		}
	}
}

local first = true;
function TempThink() {
	if(first) { //mostly to add a delay between the primary attack and grabbing the proj
		first = false
		
		if(IsPlayerABot(self)) {
			self.Weapon_Switch(customWeapon);
			self.PressFireButton();
		} 
		else {
			customWeapon.PrimaryAttack();
		}
	}
	else {
		if(IsPlayerABot(self)) {
			self.Weapon_Switch(rocketLauncher);
		}
	
		if(customWeapon.GetClassname() != "tf_weapon_pipebomblauncher") { //sticky launchers interact weirdly with PrimaryAttack()
			local proj = null;
			while(proj = Entities.FindByClassnameWithin(proj, "tf_projectile*", self.GetOrigin(), 4000)) {
				ClientPrint(null, 3, proj + " " + proj.GetOwner() + " " + NetProps.GetPropEntity(proj, "m_hThrower"));
				if(proj.GetOwner() == self || NetProps.GetPropEntity(proj, "m_hThrower")) { //grenades don't have owners apparently
					projectileType = proj.GetClassname();
				}
			}
		}
		else {
			projectileType = "tf_projectile_pipe_remote";
		}
		
		if(!projectileType) { //failed to get projectile, quit 
			AddThinkToEnt(self, null);
			NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
			self.TerminateScriptScope();
		}
		AddThinkToEnt(self, "Think");
	}
	return 0.5;
}
AddThinkToEnt(self, "TempThink");