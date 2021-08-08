RestrictionHandler = class()

RestrictionHandler.restrictions = {
    game = {},
    world = {},
    creation = {},
    body = {}
}

function RestrictionHandler:setRestrictions( mode, subject, interactable, restrictions)
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

        -- Get the creation id
        local creationId

        if type(subject) == "number" then
            creationId = subject
        elseif type(subject) == "Body" then
            creationId = subject:getCreationId()
        else
            error("Unknown subject type \"" .. type(subject) .. "\"")
        end

        -- Creation restrictions are indexed by creation id
        self.restrictions.creation[creationId] = self.restrictions.creation[creationId] or {}
        restrictionSet = self.restrictions.creation[creationId]

    elseif mode == "body" then

        -- Get the body id
        local bodyId

        if type(subject) == "number" then
            bodyId = subject
        elseif type(subject) == "Body" then
            bodyId = subject.id
        else
            error("Unknown subject type \"" .. type(subject) .. "\"")
        end

        -- Body restrictions are indexed by body id
        self.restrictions.body[bodyId] = self.restrictions.body[bodyId] or {}
        restrictionSet = self.restrictions.body[bodyId]

    else
        error("Unknown mode \"" .. tostring(mode) .. "\"")
    end

    restrictionSet[interactable.id] = {
        interactable = interactable,
        restrictions = restrictions
    }

    print("restrictionSet", restrictionSet)
end

function RestrictionHandler:shouldUseRestrictions( interactable )
    if not sm.exists(interactable) then
        return false
    end

    local parents = interactable:getParents()
    if #parents == 0 then
        return true
    end

    for _, parent in ipairs(parents) do
        if parent.active then
            return true
        end
    end

    return false
end

function RestrictionHandler:getBodyRestrictions( body )
    local hierarchy = {
        self.restrictions.game,
        self.restrictions.world[body:getWorld().id],
        self.restrictions.creation[body:getCreationId()],
        self.restrictions.body[body.id],
    }

    local restrictions = {}

    -- Merge all restrictions, already assigned values are kept
    for _, tbl in pairs(hierarchy) do

        -- The order in which restrictions of the same hierarchy are processed is undefined
        for interactableId, restrictionData in pairs(tbl) do

            -- Check if the restrictions should be used
            if restrictionData.interactable and self:shouldUseRestrictions(restrictionData.interactable) then
                
                -- Actual merging
                for k, v in pairs(restrictionData.restrictions) do
                    if restrictions[k] == nil then
                        restrictions[k] = v
                    end
                end

            end
        end
    end

    -- print("restrictions", restrictions)
    return restrictions
end

function RestrictionHandler:updateRestrictionIndex( mode, indexFrom, indexTo )
    if mode == "game" then
        error("Mode \"" .. tostring(mode) .. "\" is not indexed!")
    elseif mode == "world" or mode == "creation" or mode == "body" then

        local tbl = self.restrictions[mode]
        tbl[indexTo] = tbl[indexTo] or tbl[indexFrom]
        tbl[indexFrom] = nil

    else
        error("Unknown mode \"" .. tostring(mode) .. "\"")
    end
end

function RestrictionHandler:removeRestrictionIndexes( mode, indexes )
    print("removing", mode, indexes, self.restrictions[mode][indexes[1]])

    if mode == "game" then
        error("Mode \"" .. tostring(mode) .. "\" is not indexed!")
    elseif mode == "world" or mode == "creation" or mode == "body" then

        local tbl = self.restrictions[mode]
        for _, index in ipairs(indexes) do
            tbl[index] = nil
        end

    else
        error("Unknown mode \"" .. tostring(mode) .. "\"")
    end
end

function RestrictionHandler:removeRestrictionIndex( mode, index )
    self:removeRestrictionIndexes( mode, { index } )
end
