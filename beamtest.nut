//a modified version of the damaging beam from recalled to life
//allows healing/upgrading friendly sentries
//unfinished
local scope = self.GetScriptScope();

scope.medigun <- null;
scope.sentry <- null;
scope.charge <- 0;
scope.team <- self.GetTeam();
scope.counter <- 0;

function FindTargetThink() { //if not damaging bot, look for one
	local buttonPress = NetProps.GetPropInt(self, "m_nButtons");
	local fired = false;
	
	//if not attacking or in a state we can't/shouldn't drain
	//if(!fired || self.IsRageDraining() || self.InCond(Constants.ETFCond.TF_COND_TAUNTING)) { 
	if(!NetProps.GetPropBool(medigun, "m_bAttacking") || self.IsRageDraining() || self.InCond(Constants.ETFCond.TF_COND_TAUNTING)) { 
		return;
	}
	else if(NetProps.GetPropBool(medigun, "m_bHolstered")) {
		return;
	}

	if(!NetProps.GetPropBool(medigun, "m_bHealing")) { //not already healing someone
		if(NetProps.GetPropBool(medigun, "m_bAttacking")) {
			//no target, can look for a new one
			
			local enthit = FindTargetTrace();
			//printl(enthit)
			if(enthit && !enthit.IsPlayer() && enthit.GetTeam() == team) {
				//hit enemy player
				
				NetProps.SetPropEntity(medigun, "m_hHealingTarget", enthit);
				NetProps.SetPropEntity(medigun, "m_hLastHealingTarget", null);
				
				charge = NetProps.GetPropFloat(medigun, "m_flChargeLevel");
				AddThinkToEnt(self, "HaveTargetThink");
			}
		}
	}
}

function HaveTargetThink() { //we have a target, damage it
	//outside of shield activation, disconnects handled by actual game
	
	local target = NetProps.GetPropEntity(medigun, "m_hHealingTarget");
	
	if(self.IsRageDraining()) {
		NetProps.SetPropEntity(medigun, "m_hHealingTarget", null);
		AddThinkToEnt(self, "FindTargetThink");
	}
	else if(target && target.GetTeam() == team) { //might need a better sanity check here
		HealBuilding();
	}
	else {
		AddThinkToEnt(self, "FindTargetThink");
	}
}

function FindTargetTrace() {
	const MEDIRANGE = 450;
	local MASK_SHOT = Constants.FContents.CONTENTS_SOLID | Constants.FContents.CONTENTS_MOVEABLE 
		| Constants.FContents.CONTENTS_MONSTER | Constants.FContents.CONTENTS_WINDOW 
			| Constants.FContents.CONTENTS_DEBRIS;
	//so masks aren't in constants by default
	//filter out shield here?
	
	local traceTable = {};
	traceTable.start <- self.Weapon_ShootPosition();
	traceTable.end <- traceTable.start + self.EyeAngles().Forward() * MEDIRANGE;
	traceTable.mask <- MASK_SHOT;
	traceTable.ignore <- self;
	//see if shield is rejectable
	
	//DebugDrawClear()
	//DebugDrawLine(traceTable.start, traceTable.end, 0, 255, 0, false, 7)
	
	TraceLineEx(traceTable);
	
	if(traceTable.hit) {
		return traceTable.enthit;
	}
}

function HealBuilding() {
	const KRITZKRIEG = 35;
	const QUICKFIX = 411;
	const VACCINATOR = 998;
	const QFBONUS = 1.4;
	local UBER = Constants.ETFCond.TF_COND_INVULNERABLE_USER_BUFF;
	local CRIT = Constants.ETFCond.TF_COND_CRITBOOSTED_USER_BUFF;
	const UPGRADE = 10;
	//anything not those 3 is stock/reskin
	
	const HEAL = 2.4;
	//const ATTRIBUTENAME = "mod see enemy health"
	local target = NetProps.GetPropEntity(medigun, "m_hHealingTarget");
	//local fullDamage = DAMAGE * (1 + medigun:GetAttributeValueByClass("healing_mastery", 0) * .25)
	local fullHeal = HEAL; //can't look for attrs in vscript right now
	
	if(NetProps.GetPropBool(medigun, "m_bChargeRelease")) {
		if(type == QUICKFIX) {
			fullHeal *= 3; 
		}
	}
	
	if(type == QUICKFIX) {
		fullHeal *= QFBONUS;
	}
	
	local health = target.GetHealth() + fullHeal > target.GetMaxHealth() ? target.GetMaxHealth() : target.GetHealth() + fullHeal;
	target.SetHealth(health)
	
	counter++;
	if(counter >= UPGRADE && target.GetHealth() == target.GetMaxHealth()) { //should probably check if it'st he player's sentry or something
		local upgrade = NetProps.GetPropInt(target, "m_iHighestUpgradeLevel");
		if(upgrade < 2) {
			local metal = NetProps.GetPropInt(target, "m_iUpgradeMetal");
			//printl("metal " + metal)
			NetProps.SetPropInt(target, "m_iUpgradeMetal", metal + 25);
			if(metal + 25 >= 200) {
				NetProps.SetPropInt(target, "m_iHighestUpgradeLevel", upgrade + 1);
				NetProps.SetPropInt(target, "m_iUpgradeMetal", 0);
			}
		}
		counter = 0;
	}
}

for(local i = 0; i < NetProps.GetPropArraySize(self, "m_hMyWeapons"); i++) {
	if(NetProps.GetPropEntityArray(self, "m_hMyWeapons", i).GetClassname() == "tf_weapon_medigun") {
		medigun = NetProps.GetPropEntityArray(self, "m_hMyWeapons", i);
		i = NetProps.GetPropArraySize(self, "m_hMyWeapons");
	}
}
type = NetProps.GetPropInt(medigun, "m_AttributeManager.m_Item.m_iItemDefinitionIndex");

AddThinkToEnt(self, "FindTargetThink");