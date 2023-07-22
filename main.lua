if not ResdaynCore then return end

---@param seconds integer The amount of seconds you wish to hold the script by
local function Wait(seconds)
    local clock = os.clock
    local t0 = clock()
    while clock() - t0 <= seconds do end
end

---@func log message to console
---@param message string The message that is sent to log
---@return nil
local function log(message)
    tes3mp.LogMessage(enumerations.log.VERBOSE, "[ Herbalism ]: " .. message)
end

---@class herbalism
local herbalism = {}

herbalism.config = require('custom.resdaynHerbalism.config')
herbalism.lootTable = require("custom.resdaynHerbalism.lootTables")

---@return string|nil ore
---@return integer|nil amount
function herbalism.determineLoot()
	for herb, info in pairs(herbalism.lootTable) do
		local chance = math.random(1, 100)
		if info.limit > chance and chance > info.chance then
			log(herb)
			local amount = math.random(info.min, info.max)
			return herb, amount
		end
	end
	return nil, nil
end

---@param player table
function herbalism.addLoot(player)
	local herb, amount = nil, nil
	repeat
		herb, amount = herbalism.determineLoot()
	until herb and amount
	ResdaynCore.functions.addItem(player, herb, amount)
end

---@param pid integer PlayerID
function herbalism.gatherHerbs(pid)
	local player = Players[pid]
	log(player.name .. " is picking herbs.")
	ResdaynCore.functions.sendSpell(pid, 'burden_enable', enumerations.spellbook.ADD)
	Wait(3)
	ResdaynCore.functions.sendSpell(pid, 'burden_enable', enumerations.spellbook.REMOVE)
	herbalism.addLoot(player)
end

---@param obj table
---@return boolean isItPlant 
function herbalism.isItPlant(obj)
	return herbalism.config.plants[obj.refId]
end

function herbalism.CreateRecord()
    local recordStore = RecordStores["spell"]
    recordStore.data.permanentRecords["gathering_herbs"] = {
		name = "Gathering Herbs",
		subtype = 1,
		cost = 0,
		flags = 0,
		effects = {
			{
				attribute = -1,
				area = 0,
				duration = 10,
				id = 7,
				rangeType = 0,
				skill = -1,
				magnitudeMin = 900,
				magnitudeMax = 900
			}
		}
	}
	recordStore:Save()
end

---@param pid integer
function herbalism.updatePlayerSpellbook(pid)
    Players[pid]:LoadSpellbook()
end

---@param pid integer PlayerID
---@param id string Spell ID
---@param action integer Add/Remove
function herbalism.sendSpell(pid, id, action)
    tes3mp.ClearSpellbookChanges(pid)
    tes3mp.SetSpellbookChangesAction(pid, action)
    tes3mp.AddSpell(pid, id)
    tes3mp.SendSpellbookChanges(pid)
end

---@param eventStatus table
---@param pid integer PlayerID
---@param cellDescription string Location of player
---@param objects table Activated object(s)
---@param players table Target Players
function herbalism.OnPlantActivation(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        eventStatus.validDefaultHandler = not herbalism.isItPlant(object)
    end
    
    if eventStatus.validDefaultHandler then return eventStatus end
    
    herbalism.gatherHerbs(pid)
    return eventStatus
end

customEventHooks.registerValidator('OnObjectActivate', herbalism.OnPlantActivation)

return herbalism