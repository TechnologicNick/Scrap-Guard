-- ScrapGuard.lua --

-- Backwards compatibility
if sm.version:sub(1, 3) == "0.3" then
    dofile("0.3/ScrapGuard.lua")
    return
end



dofile("RestrictionHandler.lua")

ScrapGuard = class( nil )
ScrapGuard.maxChildCount = 0
ScrapGuard.maxParentCount = -1
ScrapGuard.connectionInput = sm.interactable.connectionType.logic
ScrapGuard.connectionOutput = sm.interactable.connectionType.none
ScrapGuard.colorNormal = sm.color.new( 0x404040ff )
ScrapGuard.colorHighlight = sm.color.new( 0x606060ff )

local idTracker = {
    trackedTick = 0,
    creation = {},
    body = {}
}

local restrictionsTick = 0

local indexToRestriction = {
    [1] = "scrapguard:out_of_world_protection",
    [2] = "vanilla:destructable",
    [3] = "vanilla:buildable",
    [4] = "vanilla:paintable",
    [5] = "vanilla:connectable",
    [6] = "vanilla:erasable",
    [7] = "vanilla:usable",
    [8] = "vanilla:liftable"
}

local modes = {
    [1] = "body",
    [2] = "creation",
    [3] = "world",
    [4] = "game"
}

function ScrapGuard.client_onInteract( self, character, state )
    if not state then return end

    if self.gui then
        self.gui:destroy()
        self.gui = nil
    end

    self.gui = sm.gui.createGuiFromLayout('$MOD_DATA/Gui/Layouts/ScrapGuard.layout')

    -- Restriction buttons
    for _, name in ipairs({ "On", "Unset", "Off" }) do
        for i, restrictionName in ipairs(indexToRestriction) do
            self.gui:setButtonCallback(name .. i, "cl_onButtonRestriction")
        end
    end

    -- Mode buttons
    for i, modeName in ipairs(modes) do
        self.gui:setButtonCallback("Tab" .. i, "cl_onButtonMode")
    end

    self.gui:setOnCloseCallback("cl_onGuiClose")
    
    self.network:sendToServer("sv_requestSyncGui")
    
    self.gui:open()
end

function ScrapGuard.cl_onGuiClose( self )

    -- Clean up when no longer needed
    if self.gui then
        self.gui:destroy()
        self.gui = nil
    end

end

function ScrapGuard.cl_onButtonRestriction( self, buttonName )
    local index = tonumber(buttonName:sub(-1))
    local action = buttonName:sub(0, -2)

    local restrictionName = indexToRestriction[index]

    local value
    if action == "On" then
        value = true
    elseif action == "Unset" then
        value = nil
    elseif action == "Off" then
        value = false
    end

    self.network:sendToServer("sv_setRestriction", {
        mode = self.cl_mode,
        restriction = restrictionName,
        value = value
    })
end

function ScrapGuard.cl_onButtonMode( self, buttonName )
    local index = tonumber(buttonName:sub(-1))
    local mode = modes[index]

    self.network:sendToServer("sv_setMode", mode)
end

function ScrapGuard.sv_setMode( self, mode, player )
    
    RestrictionHandler:removeRestrictions( self.sv_mode, self.shape.body, self.interactable )
    RestrictionHandler:setRestrictions( mode, self.shape.body, self.interactable, self.sv_restrictions )
    
    self.sv_mode = mode

    self:sv_syncGui( player )

    self:sv_saveState()

end

function ScrapGuard.sv_setRestriction( self, data, player )
    
    -- Make sure the client's mode is in sync with the server
    if not data.mode or data.mode ~= self.sv_mode then
        self:sv_syncGui( player )
        return
    end

    self.sv_restrictions[data.restriction] = data.value

    self:sv_syncGui( player )

    self:sv_saveState()

end

function ScrapGuard.sv_saveState( self )
    self.storage:save({
        version = 2,
        mode = self.sv_mode,
        restrictions = self.sv_restrictions
    })
end

function ScrapGuard.sv_requestSyncGui( self, data, player )
    self:sv_syncGui( player )
end

function ScrapGuard.sv_syncGui( self, player )
    self.network:sendToClient(player, "cl_onSyncGui", {
        mode = self.sv_mode,
        restrictions = self.sv_restrictions
    })
end

function ScrapGuard.cl_onSyncGui( self, data )
    self.cl_mode = data.mode
    self.cl_restrictions = data.restrictions

    self:cl_updateButtons()
end

function ScrapGuard.cl_updateButtons( self )

    -- Mode buttons
    for i, mode in ipairs(modes) do
        self.gui:setButtonState("Tab" .. i, mode == self.cl_mode)
    end

    -- Restriction buttons
    for i, restrictionName in ipairs(indexToRestriction) do
        local value = self.cl_restrictions[restrictionName]

        self.gui:setButtonState("On"    .. i, value == true)
        self.gui:setButtonState("Unset" .. i, value == nil)
        self.gui:setButtonState("Off"   .. i, value == false)
    end

    -- Mode buttons
    for i, modeName in ipairs(modes) do
        self.gui:setButtonState("Tab" .. i, self.cl_mode == modeName)
    end

end









function ScrapGuard.server_onCreate( self )
    self:server_onInit()
end

function ScrapGuard.server_onRefresh( self )
    self:server_onInit()
end

function ScrapGuard.server_onInit( self )
    self.sv_bodyId = self.shape.body.id
    self.sv_creationId = self.shape.body:getCreationId()

    idTracker.creation[self.sv_creationId] = true
    idTracker.body[self.sv_bodyId] = true

    -- Storage
    local stored = self.storage:load()
    if stored then
        -- Part already existed
        if not stored.version or stored.version < 2 then
            -- Migrate from Scrap Guard v1
            self.sv_mode = stored.mode
            self.sv_restrictions = {}

            local lookupRestrictions = {
                protection_OutOfWorld = "scrapguard:out_of_world_protection",
                property_Destructable = "vanilla:destructable",
                property_Buildable = "vanilla:buildable",
                property_Paintable = "vanilla:paintable",
                property_Connectable = "vanilla:connectable",
                property_Erasable = "vanilla:erasable",
                property_Usable = "vanilla:usable",
                property_Liftable = "vanilla:liftable"
            }

            for key, value in pairs(stored.itemData) do
                local migratedValue = value.selectedOption == "#{MENU_OPTION_ON}" and true or false

                self.sv_restrictions[lookupRestrictions[key]] = migratedValue
            end
        elseif stored.version == 2 then
            self.sv_mode = stored.mode
            self.sv_restrictions = stored.restrictions
        end
    else
        -- New part
        self.sv_mode = "body"
        self.sv_restrictions = {}
    end

    RestrictionHandler:setRestrictions( self.sv_mode, self.shape.body, self.interactable, self.sv_restrictions )
end

function ScrapGuard.server_onFixedUpdate( self, timeStep )
    local currentTick = sm.game.getCurrentTick()

    local newBodyId = self.shape.body.id
    local newCreationId = self.shape.body:getCreationId()

    -- Update restriction indexes
    if self.sv_bodyId ~= newBodyId then
        print("Body id changed from", self.sv_bodyId, "to", newBodyId)

        RestrictionHandler:updateRestrictionIndex( "body", self.sv_bodyId, newBodyId )
        
        self.sv_bodyId = newBodyId
    end

    if self.sv_creationId ~= newCreationId then
        print("Creation id changed from", self.sv_creationId, "to", newCreationId)

        RestrictionHandler:updateRestrictionIndex( "creation", self.sv_creationId, newCreationId )

        self.sv_creationId = newCreationId
    end

    -- Garbage collect indexes every 30 seconds
    if (sm.game.getCurrentTick() % (30 * 40)) == 0 then
        self.sv_collectGarbageIndexes()
    end

    idTracker.creation[newCreationId] = true
    idTracker.body[newBodyId] = true



    -- Apply restrictions (at the start of a new tick)
    if restrictionsTick ~= currentTick then

        -- TODO: Optimise applying the restrictions
        --[[
            This feels very inefficient, but I can't measure any impact
            on the performance. Looping over all bodies only if there are any
            game or world restrictions would be better, but this'll do for now.
        ]]
        for _, body in ipairs(sm.body.getAllBodies()) do
            local restrictions = RestrictionHandler:getBodyRestrictions(body)

            for restriction, restricted in pairs(restrictions) do
                if restriction:sub(1, 8) == "vanilla:" then
                    body[restriction:sub(9)] = restricted
                end
            end
        end

        restrictionsTick = currentTick
    end
end

function ScrapGuard.sv_collectGarbageIndexes( self )
    local currentTick = sm.game.getCurrentTick()

    -- Prevent multiple triggers
    if currentTick ~= idTracker.trackedTick then

        for _, mode in ipairs({ "creation", "body" }) do
            local untracked = {}
            local foundUntracked = false

            for index, _ in pairs(RestrictionHandler.restrictions[mode]) do
                if not idTracker[mode][index] then
                    table.insert(untracked, index)
                    foundUntracked = true
                end
            end
            
            if foundUntracked then
                RestrictionHandler:removeRestrictionIndexes( mode, untracked )
            end
        end
        
        idTracker = {
            trackedTick = currentTick,
            creation = {},
            body = {}
        }
    end
end

function ScrapGuard.server_onDestroy( self )

    RestrictionHandler:removeRestrictions( self.sv_mode, self.sv_bodyId, self.interactable )

end
