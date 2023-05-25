//adds filters and modifies the shutter's trigger so tanks can open the shutter door on hoovydam
local table = {}
local path = Entities.FindByName(null, "tank_path_a_71")
local trigger = Entities.FindByName(null, "shutter_trigger")
local elements = EntityOutputs.GetNumElements(trigger, "OnStartTouchAll")
local playerFilter = SpawnEntityFromTable("filter_activator_class", {
	targetname = "playerfilter"
	filterclass = "player"
})
local tankFilter = SpawnEntityFromTable("filter_activator_class", {
	targetname = "tankfilter"
	filterclass = "tank_boss"
})
local combinedFilter = SpawnEntityFromTable("filter_multi", {
	targetname = "combinedfilter"
	filtertype = 1
	filter01 = "playerfilter"
	filter02 = "tankfilter"
})

EntFire("shutter_trigger", "AddOutput", "spawnflags 65")
NetProps.SetPropEntity(trigger, "m_hFilter", combinedFilter)

//printl(NetProps.GetPropString(trigger, "m_iFilterName"))
//printl(NetProps.GetPropEntity(trigger, "m_hFilter"))
//printl(NetProps.GetPropInt(trigger, "m_spawnflags"))

EntityOutputs.RemoveOutput(path, "OnPass", "shutter_trigger", "Disable", "")
EntityOutputs.RemoveOutput(path, "OnPass", "door_any_trackdoor_1", "Open", "")
EntityOutputs.RemoveOutput(path, "OnPass", "door_any_trackdoor_1_prop", "SetAnimation", "Open")