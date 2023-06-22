//adds a projectile shield to demo charge
//unfinished

local hasShield = false;
local shieldModel = 1; //1 = lvl 1, 2 = lvl 2, 3 = comically small

function setShieldStats(level) {
	shieldModel = level;
	
	for(local i = 0; i < NetProps.GetPropArraySize(self, "m_hMyWeapons"); i++) {
		if(NetProps.GetPropEntityArray(self, "m_hMyWeapons", i).GetSlot == 2) {
			local melee = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i);
			melee.AddAttribute("generate rage on heal", 0, -1);
		}
	}
}

function Think() {
	if(self.InCond(Constants.ETFCond.TF_COND_SHIELD_CHARGE) && !hasShield) {
		NetProps.SetPropFloat(self, "m_Shared.m_flRageMeter", 100);
		NetProps.SetPropBool(self, "m_Shared.m_bRageDraining", true);

		local shield = SpawnEntityFromTable("entity_medigun_shield", {
			//targetname = "shield"
			teamnum = self.GetTeam()
			skin = self.GetTeam() - 2
			//deal with bodygroups/model later
		})
		shield.SetOwner(self)
		//shield.SetModelSimple("models/props_mvm/mvm_comically_small_player_shield.mdl")
		shield.SetModelSimple("models/props_mvm/mvm_player_shield2.mdl")
		hasShield = true
	}
	else if(!self.InCond(Constants.ETFCond.TF_COND_SHIELD_CHARGE) && hasShield) {
		if(NetProps.GetPropFloat(self, "m_Shared.m_flRageMeter") > 5) {
			NetProps.SetPropFloat(self, "m_Shared.m_flRageMeter", 5);
		}
		hasShield = false;
	}
}

AddThinkToEnt(self, "Think")