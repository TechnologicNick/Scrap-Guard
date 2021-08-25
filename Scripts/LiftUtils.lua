LiftUtils = class()
LiftUtils.lifts = {}
LiftUtils.liftCaptures = {}
LiftUtils.tickFound = 0

function LiftUtils:installHooks()

    o_sm_player_placeLift = o_sm_player_placeLift or sm.player.placeLift

    function sm.player.placeLift( player, creation, position, level, rotation )
        o_sm_player_placeLift( player, creation, position, level, rotation )
        
        self.liftCaptures[player.id] = {
            player = player,
            creation = creation,
            position = position,
            level = level,
            rotation = rotation
        }

    end

end

function LiftUtils:findLifts()
    local currentTick = sm.game.getCurrentTick()

    if self.tickFound ~= currentTick then
        self.lifts = {}

        for playerId, liftCapture in pairs(self.liftCaptures) do
            if sm.exists(liftCapture.player) then
                local position = liftCapture.position * sm.construction.constants.subdivideRatio
                local hit, raycastResult = sm.physics.raycast(position + sm.vec3.new(0, 0, 0), position + sm.vec3.new(0, 0, 1))
    
                if hit and raycastResult.type == "lift" then
                    local lift, topShape = raycastResult:getLiftData()
    
                    self.lifts[playerId] = lift
                end
            else
                self.liftCaptures[playerId] = nil
                self.lifts[playerId] = nil
            end
        end
    end

    self.tickFound = currentTick

    return self.lifts
end

function LiftUtils:isBodyLiftable( body )
    if not sm.exists(body) or body:isStatic() or not body.liftable then
        return false
    end

    for _, shape in ipairs(body:getShapes()) do
        if not shape.liftable then
            return false
        end
    end

    return true
end

function LiftUtils:isCreationLiftable( creation )
    local bodies = type(creation) == "table" and creation or creation:getCreationBodies()

    for _, body in ipairs(bodies) do
        if not self:isBodyLiftable(body) then
            return false
        end
    end

    return true
end
