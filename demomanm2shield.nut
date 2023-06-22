//made by watermelon
//replaces demo shield charge with a projectile shield

local hasShield = false;
local shield = null;
local projShield = null;
local shieldModelString = null;
local terminateOnDeath = false;

while(shield = Entities.FindByClassname(shield, "tf_wearable_demoshield")) {
	if(shield.GetOwner() == self) { //only need to find one entity
		break;
	}
}

function UpgradeCheck(level) {
	switch(level) {
		case 1:
			shieldModelString = "models/props_mvm/mvm_comically_small_player_shield.mdl";
			break;
		case 2:
			//lvl 1 is default
			break;
		case 3:
			shieldModelString = "models/props_mvm/mvm_player_shield2.mdl";
			shield.AddAttribute("generate rage on heal", 2, -1);
			break;
		default:
			RemoveUpgrade();
			break;
	}
	
	//since popfile applies new instances of script to player, reference to old shield gets lost
	//need to kill manually
	local oldShield = null
	while(oldShield = Entities.FindByClassname(shield, "entity_medigun_shield")) {
		if(oldShield.GetOwner() == self) {
			oldShield.Kill();
		}
	}
	
	AddThinkToEnt(self, "Think");
}

function RemoveUpgrade() { //separate func so it can also be called by the popfile
	NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
	AddThinkToEnt(self, null);
	NetProps.SetPropBool(self, "m_Shared.m_bRageDraining", false);
	if(shield.IsValid()) {
		shield.RemoveAttribute("no_attack"); //safety
	}
	self.SetForcedTauntCam(0);
	self.TerminateScriptScope();
}

function SetTerminateOnDeath(val) {
	terminateOnDeath = val;
}

function Think() {
	if(terminateOnDeath) {
		if(NetProps.GetPropInt(self, "m_lifeState") != 0) {
			RemoveUpgrade();
		}
	}
	
	if(!shield.IsValid()) { //class change but upgrade wasn't refunded or otherwise handled by rafmod
		RemoveUpgrade();
	}

	if(NetProps.GetPropInt(self, "m_nButtons") & Constants.FButtons.IN_ATTACK2) {
		NetProps.SetPropFloat(self, "m_Shared.m_flChargeMeter", 0); //prevents charge, if meter is full mini charges may occur
		NetProps.SetPropFloat(self, "m_Shared.m_flRageMeter", 100);
		
		self.SetForcedTauntCam(1);
		shield.AddAttribute("no_attack", 1, -1);
		hasShield = true
		
		if(projShield == null || !projShield.IsValid()) { //only create a new shield if we don't have one
			NetProps.SetPropBool(self, "m_Shared.m_bRageDraining", true); //needs to be true for no rage classes to use shield
			
			projShield = SpawnEntityFromTable("entity_medigun_shield", {
				//targetname = "shield"
				teamnum = self.GetTeam()
				skin = self.GetTeam() == Constants.ETFTeam.TF_TEAM_RED ? 0 : 1
			})
			projShield.SetOwner(self)
			
			if(shieldModelString) {
				projShield.SetModelSimple(shieldModelString)
			}
		}	
	}
	else {
		if(hasShield) {
			if(NetProps.GetPropFloat(self, "m_Shared.m_flRageMeter") > 2.5) {
				NetProps.SetPropFloat(self, "m_Shared.m_flRageMeter", 2.5);
			}
			hasShield = false;
			
			self.SetForcedTauntCam(0);
			shield.RemoveAttribute("no_attack");
		}
	}
}