--------------------------------------
--Copyright (c) 2019 TechnologicNick--
--------------------------------------

--dofile("OptionsMenuHandler.lua")
dofile("globalgui.lua")
dofile("globalguiExtension.lua")

-- ScrapGuard.lua --

ScrapGuard = class( nil )
ScrapGuard.maxChildCount = 0
ScrapGuard.maxParentCount = -1
ScrapGuard.connectionInput = sm.interactable.connectionType.seated
ScrapGuard.connectionOutput = sm.interactable.connectionType.none
ScrapGuard.colorNormal = sm.color.new( 0x404040ff )
ScrapGuard.colorHighlight = sm.color.new( 0x606060ff )
ScrapGuard.poseWeightCount = 1

ScrapGuard.remoteguiposition = sm.vec3.new(0,0,2000) -- don't touch
ScrapGuard.remotedistance = 100 -- don't touch

ScrapGuard.rowCount = 9

function ScrapGuard.client_onCreate( self )
    self.interactable:setUvFrameIndex(6)
end

function ScrapGuard.server_onCreate( self )
    -- Create remote gui instance
    if not ScrapGuard.guiCreated and (self.shape.worldPosition - self.remoteguiposition):length()>self.remotedistance then
		ScrapGuard.guiCreated = true 
		sm.shape.createPart( self.shape.shapeUuid, self.remoteguiposition, sm.quat.identity(), false, true ) 
	end
end

function ScrapGuard.client_onSetupGui( self )
	-- only the remote shape can initialize a global gui:
	if (self.shape.worldPosition - self.remoteguiposition):length()>self.remotedistance then
        --print("too far from remoteguiposition, this block cannot initialize gui")
		return -- too far from remoteguiposition, this block cannot initialize gui
	elseif (guitestgui and guitestgui.instantiated) then -- kill duplicate remote gui blocks
        --print("kill duplicate remote gui blocks")
		function self.server_onFixedUpdate(self, dt) self.shape:destroyPart(0) end 
		return
	end
    
    local gui = sm.globalgui.create(
        self,
        "Scrap Guard",
        739,
        163 + 53 * self.rowCount,
        function() end,
        50,
        false
    )
    
    gui.instantiated = true
    local bx, by = gui.bgPosX, gui.bgPosY
    
    --local headerModeBody = collectionItems({})
    --headerModeBody:addItemWithId("button", buttonItem(bx + 100, by + 100, 100, 50, ""))
    --headerModeBody:addItemWithId("label",  labelItem(bx + 100, by + 100, 100, 50, "Body"))
    
    -- 10/10 spelling #blamebrent
    local tabControlMode = sm.globalgui.tabControll(
        {
            --sm.globalgui.collection({ --Body mode
            --    button = sm.globalgui.button(bx + 100, by + 100, 100, 50, "")--,
            --    --label = sm.globalgui.label(bx + 100, by + 100, 100, 50, "Body")
            --}),
            --sm.globalgui.collection({ --Creation mode
            --    button = sm.globalgui.button(bx + 200, by + 100, 100, 50, "")--,
            --    --label = sm.globalgui.label(bx + 200, by + 100, 100, 50, "Creation")
            --})
            sm.globalgui.button(bx + 100, by + 100, 100, 50, ""),
            sm.globalgui.button(bx + 200, by + 100, 100, 50, "")
        },
        {
            sm.globalgui.label(bx + 100, by + 200, 100, 50, "ABC"),
            sm.globalgui.label(bx + 200, by + 200, 100, 50, "DEF")
        }
    )
    
    gui:addItemWithId("tabControlMode", tabControlMode)
    gui:addItemWithId("test", sm.globalgui.toggleButton(bx + 100, by + 300, 100, 50, "Test"))
    
    ScrapGuard.gui = gui
    print("GUI setup completed.")
end

function ScrapGuard.client_onUpdate(self, dt)
	if self.settings then
		self.network:sendToServer("server_onSettingsChange", self.settings)
		self.settings = nil
	end
end

function ScrapGuard.client_onInteract(self)
	if not ScrapGuard.gui then
        sm.log.warning("[ScrapGuard] Global gui does not exist! Try placing a new block.")
        return
    end
	
	--paintgungui.items.optionmenu1.items.spread.valueBox.widget:setText(tostring(math.floor(self.clientsettings.spread)))
	--paintgungui.items.optionmenu1.items.speed.valueBox.widget:setText(tostring(math.floor(self.clientsettings.speed*10)))
	--paintgungui.items.optionmenu1.items.size.valueBox.widget:setText(tostring(math.floor(self.clientsettings.size*4)))
	--paintgungui.items.optionmenu1.items.bucketmode.valueBox.widget:setText(tostring(self.clientsettings.bucket_mode))
	--paintgungui.items.optionmenu1.items.colormode.valueBox.widget:setText(tostring(self.clientsettings.colormode))
    
	ScrapGuard.gui:show() 
	ScrapGuard.gui.on_hide = function()
		self.settings = {
			spread = tonumber(paintgungui.items.optionmenu1.items.spread.valueBox.widget:getText()),
			speed = tonumber(paintgungui.items.optionmenu1.items.speed.valueBox.widget:getText())/10,
			size = tonumber(paintgungui.items.optionmenu1.items.size.valueBox.widget:getText())/4,
			bucket_mode = tostring(paintgungui.items.optionmenu1.items.bucketmode.valueBox.widget:getText()),
			colormode = paintgungui.items.optionmenu1.items.colormode.valueBox.widget:getText()
		}
	end
end





--[[ Server-side ]]

function ScrapGuard.server_onSettingsChange( self, settings )

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