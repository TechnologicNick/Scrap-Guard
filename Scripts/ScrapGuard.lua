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
ScrapGuard.connectionInput = sm.interactable.connectionType.seated
ScrapGuard.connectionOutput = sm.interactable.connectionType.none
ScrapGuard.colorNormal = sm.color.new( 0x404040ff )
ScrapGuard.colorHighlight = sm.color.new( 0x606060ff )

local idTracker = {
    trackedTick = 0,
    creation = {},
    body = {}
}

function ScrapGuard.client_onInteract( self, character, state )
    if not state then return end

    -- self.gui = sm.gui.createGuiFromLayout('$MOD_DATA/Gui/Layouts/ScrapGuard.layout')

    -- self.gui:open()

    self.network:sendToServer("sv_onInteract")
end

function ScrapGuard.sv_onInteract( self, data, player )
    RestrictionHandler:getBodyRestrictions( self.shape.body )
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

    local currentTick = sm.game.getCurrentTick()
    idTracker.creation[self.sv_creationId] = currentTick
    idTracker.body[self.sv_bodyId] = currentTick
    
    -- Testing
    RestrictionHandler:setRestriction("game", nil, "game_restriction", true)
    RestrictionHandler:setRestriction("world", self.shape.body, "world_restriction", true)
    RestrictionHandler:setRestriction("creation", self.shape.body, "creation_restriction", true)
    RestrictionHandler:setRestriction("body", self.shape.body, "body_restriction", true)
end

function ScrapGuard.server_onFixedUpdate( self, timeStep )
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

    -- Garbage collect indexes
    local currentTick = sm.game.getCurrentTick()

    -- Trigger once on new tick
    if currentTick ~= idTracker.trackedTick then

        for _, mode in ipairs({ "creation", "body" }) do
            local untracked = {}
            local foundUntracked = false

            for index, _ in pairs(RestrictionHandler.restrictions[mode]) do
                if (idTracker[mode][index] or 0) + 20 <= currentTick then
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

    idTracker.creation[newCreationId] = currentTick
    idTracker.body[newBodyId] = currentTick

end
