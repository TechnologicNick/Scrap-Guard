LiftUtils = class()
LiftUtils.lifts = {}
LiftUtils.liftPositions = {}
LiftUtils.tickFound = 0

function LiftUtils:installHooks()

    o_sm_player_placeLift = o_sm_player_placeLift or sm.player.placeLift

    function sm.player.placeLift( player, body, position, level, rotation )
        o_sm_player_placeLift( player, body, position, level, rotation )
        
        self.liftPositions[player.id] = position * sm.construction.constants.subdivideRatio

    end

end

function LiftUtils:findLifts()
    local currentTick = sm.game.getCurrentTick()

    if self.tickFound ~= currentTick then
        self.lifts = {}

        for playerId, position in pairs(self.liftPositions) do
            local hit, raycastResult = sm.physics.raycast(position + sm.vec3.new(0, 0, 0), position + sm.vec3.new(0, 0, 1))

            if hit and raycastResult.type == "lift" then
                local lift, topShape = raycastResult:getLiftData()

                self.lifts[playerId] = lift
            end
        end
    end

    self.tickFound = currentTick

    return self.lifts
end
