//plays the unused teleporter activation sound
local soundtable = {
	sound_name = "mvm/mvm_tele_activate.wav",
	filter = Constants.EScriptRecipientFilter.RECIPIENT_FILTER_GLOBAL
}

function OnGameEvent_player_builtobject(params) {
	local player = GetPlayerFromUserID(params.userid)

	if(player.GetTeam() == 3 && params.object == 1) {
		local tele = EntIndexToHScript(params.index)
		
		tele.ValidateScriptScope()
		tele.GetScriptScope().started <- false
		tele.GetScriptScope().Think <- function() {
			if(!started) {
				started = true
				return 21;
			}
			
			EntFire("tf_gamerules", "playvo", "mvm/mvm_tele_activate.wav")
			//EmitSoundEx(soundtable)
			AddThinkToEnt(self, null);
			NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
		}
		AddThinkToEnt(tele, "Think")	
	}
}

PrecacheSound("mvm/mvm_tele_activate.wav")
__CollectGameEventCallbacks(this)
