dofile("OptionsMenuHandler.lua")

-- ScrapGuard.lua --

ScrapGuard = class( nil )
ScrapGuard.maxChildCount = 0
ScrapGuard.maxParentCount = -1
ScrapGuard.connectionInput = sm.interactable.connectionType.seated
ScrapGuard.connectionOutput = sm.interactable.connectionType.none
ScrapGuard.colorNormal = sm.color.new( 0x404040ff )
ScrapGuard.colorHighlight = sm.color.new( 0x606060ff )

function ScrapGuard.client_onCreate( self )
    self.optionsMenu = OptionsMenu(self, "Scrap Guard", 9)
end

function ScrapGuard.client_onSetupGui( self )
    self.optionsMenu:setupGui()
    
    self.optionsMenu:addOptionsMenuItem(0,  0, "Out of world protection", nil, nil, nil)
    self.optionsMenu:addOptionsMenuItem(1,  2, "Connectable", nil, nil, nil)
    self.optionsMenu:addOptionsMenuItem(2,  3, "Desctructable", nil, nil, nil)
    self.optionsMenu:addOptionsMenuItem(3,  4, "Buildable", nil, nil, nil)
    self.optionsMenu:addOptionsMenuItem(4,  5, "Paintable", nil, nil, nil)
    self.optionsMenu:addOptionsMenuItem(5,  6, "Liftable", nil, nil, nil)
    --self.optionsMenu:addOptionsMenuItem(6,  nil, "Boolean test", nil, nil, nil)
    --self.optionsMenu:addOptionsMenuItem(7,  nil, "Boolean test", nil, nil, nil)
    --self.optionsMenu:addOptionsMenuItem(8,  nil, "Boolean test", nil, nil, nil)
    --self.optionsMenu:addOptionsMenuItem(9,  nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(10, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(11, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(12, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(13, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(14, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(15, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(16, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    --self.optionsMenu:addOptionsMenuItem(17, nil, "Number test", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    
    self.optionsMenu:resize(nil)
end

function ScrapGuard.client_onInteract( self )
    self.optionsMenu:show()
end

function ScrapGuard.client_onUpdate( self, dt )
    self.optionsMenu:update(dt)
end

function ScrapGuard.client_onOptionsMenuValueChanged( self, data )
    if sm.isHost then
        self.optionsMenu.items[data.id]:selectIndex(data.selectedIndex)
    end
end

function ScrapGuard.server_onOptionsMenuValueChanged( self, data )
    --print(data, data.selectedIndex, type(data.selectedIndex))
    self.optionsMenu.items[data.id]:selectIndex(data.selectedIndex)
    self.network:sendToClients("client_onOptionsMenuValueChanged", data)
end



function ScrapGuard.server_onFixedUpdate( self, timeStep )
    if self.optionsMenu.items[0] ~= nil then
        if self.optionsMenu.items[0]:getSelectedIndex() == 1 then
            local position = self.shape:getWorldPosition()
            if position:length2() > 2000000 then
                print("Put it on a lift")
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