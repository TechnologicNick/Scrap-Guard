RestrictionHandler = class()

RestrictionHandler.restrictions = {
    game = {},
    world = {},
    creation = {},
    body = {}
}

function RestrictionHandler:setRestriction( mode, subject, restriction, restricted)
    local restrictionSet

    if mode == "game" then

        -- Global, no subject required
        restrictionSet = self.restrictions.game

    elseif mode == "world" then

        -- Get the world id
        local worldId

        if type(subject) == "number" then
            worldId = subject
        elseif type(subject) == "World" then
            worldId = subject.id
        elseif type(subject) == "Body" then
            worldId = subject:getWorld().id
        else
            error("Unknown subject type \"" .. type(subject) .. "\"")
        end

        -- World restrictions are indexed by world id
        self.restrictions.world[worldId] = self.restrictions.world[worldId] or {}
        restrictionSet = self.restrictions.world[worldId]

    elseif mode == "creation" then
        error("Unimplemented mode \"" .. tostring(mode) .. "\"")
    elseif mode == "body" then
        error("Unimplemented mode \"" .. tostring(mode) .. "\"")
    else
        error("Unknown mode \"" .. tostring(mode) .. "\"")
    end

    restrictionSet[restriction] = restricted

    print("restrictionSet", restrictionSet)
end

function RestrictionHandler:getBodyRestrictions( body )
    local game = self.restrictions.game
    local world = self.restrictions.world[body:getWorld().id]
    local creation = self.restrictions.creation[body:getCreationId()] -- The creation id changes for every part added/removed
    local body = self.restrictions.body[body]

    local restrictions = {}

    -- Merge all restrictions, already assigned values are kept
    for _, tbl in ipairs({ game, world, creation, body }) do
        for k, v in pairs(tbl or {}) do
            if restrictions[k] == nil then
                restrictions[k] = v
            end
        end
    end

    print(restrictions)
    return restrictions
end
