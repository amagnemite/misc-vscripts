foreach(a,b in Constants){foreach(k,v in b){if(!(k in getroottable())){getroottable()[k]<-v;}}} //takes all constant keyvals and puts them in global

PrecacheScriptSound("Breakable.Glass");
::PERMANENT_SHIELD <- -1;

function OnGameEvent_medigun_shield_blocked_damage(params) {
	local player = GetPlayerFromUserID(params.userid);
	local playerScope = player.GetScriptScope();
	
	if(player.GetPlayerClass() == TF_CLASS_DEMOMAN && playerScope.totalHealth != PERMANENT_SHIELD) {
		playerScope.currentHealth = playerScope.currentHealth - params.damage;
		printl(playerScope.currentHealth)
		if(playerScope.currentHealth <= 0) {
			AddThinkToEnt(player, "BrokenShieldThink");
		}
	}
}

function OnGameEvent_mvm_reset_stats(params) { //mvm_reset_stats runs before InitWaveOutput
	ClientPrint(null, 3, "reset stats");
}

__CollectGameEventCallbacks(this);