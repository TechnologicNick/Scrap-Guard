--------------------------------------
--Copyright (c) 2019 TechnologicNick--
--------------------------------------

dofile("OptionsMenuHandler.lua")

-- ScrapGuard.lua --

ScrapGuard = class( nil )
ScrapGuard.maxChildCount = 0
ScrapGuard.maxParentCount = -1
ScrapGuard.connectionInput = sm.interactable.connectionType.seated
ScrapGuard.connectionOutput = sm.interactable.connectionType.none
ScrapGuard.colorNormal = sm.color.new( 0x404040ff )
ScrapGuard.colorHighlight = sm.color.new( 0x606060ff )

ScrapGuard.idOutOfWorldProtection = 0
ScrapGuard.idDestructable         = 1
ScrapGuard.idBuildable            = 2
ScrapGuard.idPaintable            = 3
ScrapGuard.idConnectable          = 4
ScrapGuard.idErasable             = 5
ScrapGuard.idUsable               = 6
ScrapGuard.idLiftable             = 7



function ScrapGuard.client_onCreate( self )
    self.optionsMenu = OptionsMenu(self, "Scrap Guard", 9)
end

function ScrapGuard.client_onSetupGui( self )
    self.optionsMenu:setupGui()
    
    self.optionsMenu:addOptionsMenuItem(self.idOutOfWorldProtection,  0, "protection_OutOfWorld", "Out of world protection", nil, nil)
    self.optionsMenu:addOptionsMenuItem(self.idDestructable,          2, "property_Destructable", "Destructable", nil, nil)
    self.optionsMenu:addOptionsMenuItem(self.idBuildable,             3, "property_Buildable",    "Buildable", nil, nil)
    self.optionsMenu:addOptionsMenuItem(self.idPaintable,             4, "property_Paintable",    "Paintable", nil, nil)
    self.optionsMenu:addOptionsMenuItem(self.idConnectable,           5, "property_Connectable",  "Connectable", nil, nil)
    self.optionsMenu:addOptionsMenuItem(self.idErasable,              6, "property_Erasable",     "Erasable", nil, nil)
    self.optionsMenu:addOptionsMenuItem(self.idUsable,                7, "property_Usable",       "Usable", nil, nil)
  --self.optionsMenu:addOptionsMenuItem(self.idLiftable,              8, "property_Liftable",     "Liftable", nil, nil)
    --self.optionsMenu:addOptionsMenuItem(8,  nil, "Boolean test", nil, nil)
    --self.optionsMenu:addOptionsMenuItem(9,  nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(10, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(11, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(12, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(13, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(14, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(15, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(16, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(17, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    
    --[[
    -- Bug
    local layout_0 = sm.gui.load("ChallengeMessage.layout", true)
    layout_0.foo = {"abc"}
    
    local layout_1 = sm.gui.load("ChallengeMessage.layout", true)
    layout_1.foo = {"def"}
    
    print("layout_0.foo =", layout_0.foo, "layout_1.foo =", layout_1.foo)
    --]]
    
    --self.optionsMenu:importFromTable
    self.optionsMenu:resize(nil)
    self.optionsMenu:importData()
end

function ScrapGuard.client_onInteract( self )
    self.optionsMenu:show()
end

function ScrapGuard.client_onUpdate( self, dt )
    self.optionsMenu:update(dt)
    if self.optionsMenu:isVisible() then
        self.optionsMenu.items[self.idDestructable]:selectIndex(self.shape.body.destructable and 1 or 2)
        self.optionsMenu.items[self.idBuildable   ]:selectIndex(self.shape.body.buildable and 1 or 2)
        self.optionsMenu.items[self.idPaintable   ]:selectIndex(self.shape.body.paintable and 1 or 2)
        self.optionsMenu.items[self.idConnectable ]:selectIndex(self.shape.body.connectable and 1 or 2)
        self.optionsMenu.items[self.idErasable    ]:selectIndex(self.shape.body.erasable  and 1 or 2)
        self.optionsMenu.items[self.idUsable      ]:selectIndex(self.shape.body.usable and 1 or 2)
      --self.optionsMenu.items[self.idLiftable    ]:selectIndex(self.shape.body.liftable and 1 or 2)
    end
end

function ScrapGuard.client_onOptionsMenuValueChanged( self, data )
    if not sm.isHost then
        self.optionsMenu.items[data.id]:selectIndex(data.selectedIndex)
    end
end

function ScrapGuard.server_onOptionsMenuValueChanged( self, data )
    self.optionsMenu.items[data.id]:selectIndex(data.selectedIndex)
    if data.id == self.idDestructable then
        self.shape.body.destructable = data.selectedIndex == 1 and true or false
    elseif data.id == self.idBuildable then
        self.shape.body.buildable = data.selectedIndex == 1 and true or false
    elseif data.id == self.idPaintable then
        self.shape.body.paintable = data.selectedIndex == 1 and true or false
    elseif data.id == self.idConnectable then
        self.shape.body.connectable = data.selectedIndex == 1 and true or false
    elseif data.id == self.idErasable then
        self.shape.body.erasable = data.selectedIndex == 1 and true or false 
    elseif data.id == self.idUsable then
        self.shape.body.usable = data.selectedIndex == 1 and true or false
  --elseif data.id == self.idLiftable then
  --    self.shape.body.liftable = data.selectedIndex == 1 and true or false
    end
    self.network:sendToClients("client_onOptionsMenuValueChanged", data)
    
    self:server_save()
end


function ScrapGuard.server_onCreate( self )
    local loadedData = self.storage:load()
    if loadedData then
        self.network:sendToClients("client_loadFromStorage", loadedData)
    end
end

function ScrapGuard.client_loadFromStorage( self, data )
    self.optionsMenu:queueDataToImport(data.itemData)
end



function ScrapGuard.server_save( self )
    local toSave = {
        mode = "body",
        itemData = self.optionsMenu:exportToTable()
    }
    self.storage:save(toSave)
end



function ScrapGuard.server_onFixedUpdate( self, timeStep )
    if self.optionsMenu.items[0] ~= nil then
        if self.optionsMenu.items[0]:getSelectedIndex() == 1 then
            local position = self.shape:getWorldPosition()
            if position:length2() > 2000000 then
                --print("Put it on a lift")
                sm.player.placeLift(
                    server_getNearestPlayer(position),
                    self.shape.body:getCreationBodies(),
                    sm.vec3.new(0, 0, 0),
                    0,
                    0
                )
            end
        end
    end
end

function server_getNearestPlayer( position )
    local nearestPlayer = nil
    local nearestDistance = nil
    for id,player in pairs(sm.player.getAllPlayers()) do
        if sm.exists(player.character) then
            local length2 = sm.vec3.length2(position - player.character:getWorldPosition())
            if nearestDistance == nil or length2 < nearestDistance then
                nearestDistance = length2
                nearestPlayer = player
            end
        end
    end
    return nearestPlayer
end