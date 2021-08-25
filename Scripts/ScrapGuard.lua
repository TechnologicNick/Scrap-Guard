-- ScrapGuard.lua --

-- Backwards compatibility
if sm.version:sub(1, 3) == "0.3" then
    dofile("0.3/ScrapGuard.lua")
    return
end



dofile("RestrictionHandler.lua")
dofile("LiftUtils.lua")

LiftUtils:installHooks()

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

local triggerTracker = {}

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
    self.sv_executeNextTick = {}

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

    -- Execute functions scheduled in the previous tick
    for _, executeData in ipairs(self.sv_executeNextTick) do
        executeData.func()
    end
    self.sv_executeNextTick = {}

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

        local creationsOutsideBounds = {}
        local isAnyCreationOutsideBounds = false

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

            if restrictions["scrapguard:out_of_world_protection"]
                and not body:isStatic()
                and body.worldPosition:length2() > 900
            then
                creationsOutsideBounds[body:getCreationId()] = body
                isAnyCreationOutsideBounds = true
            end
            
        end

        if isAnyCreationOutsideBounds then
            local creationId, body = next(creationsOutsideBounds)
            if body then
                self:sv_saveCreation(body)
            end
        end

        -- Respawn players out of bounds too
        for _, player in ipairs(sm.player.getAllPlayers()) do
            if player.character and not player.character:getLockingInteractable() then

                local pos = player.character.worldPosition
                if sm.vec3.new(pos.x, pos.y, 0):length2() > 4000000 or math.abs(pos.z) > 100000 then

                    local char = sm.character.createCharacter(
                        player,
                        player.character:getWorld(),
                        sm.vec3.new(16, 16, -100), -- Default creative mode spawn, inside the teleportation border
                        0,
                        0,
                        player.character
                    )
                    player:setCharacter(char)

                end
            end
        end

        restrictionsTick = currentTick
    end
end

function ScrapGuard.sv_saveCreation( self, body )

    -- Find a position to place the creation on a lift
    local hit, raycastResult = sm.physics.raycast(sm.vec3.new(0, 0, 1000), sm.vec3.new(0, 0, -10))
    local pos = hit and raycastResult.pointWorld * sm.construction.constants.subdivisions or sm.vec3.new(0, 0, 0)

    local bodies = body:getCreationBodies()

    local okPosition, liftLevel = sm.tool.checkLiftCollision( bodies, pos, 0 )
    while not okPosition do
        pos = pos + sm.vec3.new(0, 0, 1)
        okPosition, liftLevel = sm.tool.checkLiftCollision( bodies, pos, 0 )
    end


    -- Backup the placement of the current lift
    local playerId, lift = next(LiftUtils:findLifts())
    local liftCapture = LiftUtils.liftCaptures[playerId]

    local player = liftCapture and liftCapture.player or sm.player.getAllPlayers()[1]

    -- Put the out of bounds creation on the lift
    o_sm_player_placeLift(player, bodies, pos, liftLevel, 0)

    -- Put the original creation back
    if liftCapture and sm.exists(lift) then
        
        --[[
            Put the creation on the lift for a second time in the same tick.
            This lift will be removed next tick to return the lift we lend,
            while leaving the first lift with our rescued creation in place.
        ]]
        o_sm_player_placeLift(player, bodies, pos, liftLevel, 0)
        
        local liftedBodies = {}

        local lift_hasBodies = lift:hasBodies()
        local lift_getWorldPosition = lift:getWorldPosition()
        local lift_getLevel = lift:getLevel()
        
        local head = lift_getWorldPosition + sm.vec3.new(0, 0, (lift_getLevel + 2) * sm.construction.constants.subdivideRatio)

        local replaceLift = function(creation)
            o_sm_player_placeLift(
                liftCapture.player,
                creation or {},
                liftCapture.position,
                lift_getLevel,
                liftCapture.rotation
            )
        end

        if lift_hasBodies then
            local size = sm.vec3.new(4, 4, 1) * sm.construction.constants.subdivideRatio

            local trigger = sm.areaTrigger.createBox(
                size,
                head - size / 2,
                sm.quat.identity(),
                sm.areaTrigger.filter.dynamicBody
            )

            triggerTracker[trigger.id] = {
                expiresAt = sm.game.getCurrentTick() + 10,
                replaceLift = replaceLift
            }

            trigger:bindOnEnter("sv_onEnterLiftTrigger")
        else
            table.insert(self.sv_executeNextTick, {
                func = replaceLift
            })
        end
    end
    
end

function ScrapGuard.sv_onEnterLiftTrigger( self, trigger, enteredBodies )

    local tracker = triggerTracker[trigger.id]
    if tracker and sm.game.getCurrentTick() < tracker.expiresAt then
        
        -- There might be multiple creations in the areaTrigger
        
        -- Get a single body of each creation
        local creationsIds = {}
        for _, enteredBody in ipairs(enteredBodies) do
            creationsIds[enteredBody:getCreationId()] = enteredBody
        end
        
        -- Get all liftable creations
        local liftableCreations = {}
        for creationId, body in pairs(creationsIds) do
            local creation = body:getCreationBodies()

            if LiftUtils:isCreationLiftable(creation) then
                table.insert(liftableCreations, creation)
            end
        end

        -- Select the creation we want to put on the lift
        local creation = nil
        if #liftableCreations == 1 then

            -- Only a single creation, no need to compare
            creation = liftableCreations[1]

        elseif #liftableCreations >= 2 then

            -- Select the biggest creation (most childshapes)
            local shapeCountMax = 0

            for i, liftableCreation in ipairs(liftableCreations) do
                local shapeCount = 0

                for _, body in ipairs(liftableCreation) do
                    shapeCount = shapeCount + #body:getShapes()
                end

                if shapeCount > shapeCountMax then
                    shapeCountMax = shapeCount
                    creation = liftableCreation
                end
            end

        end

        if creation then
            tracker.replaceLift(creation)
        end

    end

    triggerTracker[trigger.id] = nil

    sm.areaTrigger.destroy(trigger)
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
