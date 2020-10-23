--------------------------------------
--Copyright (c) 2019 TechnologicNick--
--------------------------------------

sm.isDev = true --Delete this on release

dofile "SE_Loader.lua"

-- the following code prevents re-load of this file, except if in '-dev' mode.  -- fixes broken sh*t by devs.
if ScrapGuard and not sm.isDev then -- increases performance for non '-dev' users.
	return -- perform sm.checkDev(shape) in server_onCreate to set sm.isDev
end 

-- ScrapGuard.lua --

ScrapGuard = class( guiClass ) -- Inherits functions GlobalGUI needs
ScrapGuard.maxChildCount = 0
ScrapGuard.maxParentCount = -1
ScrapGuard.connectionInput = sm.interactable.connectionType.seated
ScrapGuard.connectionOutput = sm.interactable.connectionType.none
ScrapGuard.colorNormal = sm.color.new( 0x404040ff )
ScrapGuard.colorHighlight = sm.color.new( 0x606060ff )
ScrapGuard.poseWeightCount = 1

ScrapGuard.rowCount = 8

function ScrapGuard.client_onCreate( self )
    self.interactable:setUvFrameIndex(6)
    self.client_settings = {
        mode = "body"
    }
end

function ScrapGuard.server_onCreate( self )
    -- Create remote gui instance
    ScrapGuard:createRemote(self)
    self.server_mode = "body"
end

function ScrapGuard.client_onSetupGui( self )
	if self:wasCreated(ScrapGuard_GUI) then return end
    
    local bgPadding = 40
    local padding = 16
    local modeButtonsHeight = 50
    
    local bgWidth = wideMode and 1440 or 739
    local bgHeight = 163 + 53 * self.rowCount + modeButtonsHeight + padding
    
    ScrapGuard_GUI = GlobalGUI.create(
        self,
        "Scrap Guard",
        bgWidth,
        bgHeight,
        nil, --onHide
        nil, --onUpdate
        nil, --onShow
        50,
        true,
        2560,
        1440
    )
    
    local bgX, bgY = ScrapGuard_GUI.bgPosX, ScrapGuard_GUI.bgPosY
    local innerW = bgWidth - bgPadding*2
    
    
    
   
    local btnModeBody = GlobalGUI.buttonSmall(
		bgX + bgPadding,
		bgY + 92,
		innerW/3,
		modeButtonsHeight,
		"BODY",
		function(item, self)
			self:client_setMode("body")
		end,
		function(item, self) end,
		"GUI Inventory highlight",
		true
	)
    
    local btnModeCreation = GlobalGUI.buttonSmall(
		bgX + bgPadding + innerW/3,
		bgY + 92,
		innerW/3,
		modeButtonsHeight,
		"CREATION",
		function(item, self)
			self:client_setMode("creation")
		end,
		function(item, self) end,
		"GUI Inventory highlight",
		true
	)
    
    local btnModeWorld = GlobalGUI.buttonSmall(
		bgX + bgPadding + innerW/3 * 2,
		bgY + 92,
		innerW/3,
		modeButtonsHeight,
		"WORLD",
		function(item, self)
			self:client_setMode("world")
		end,
		function(item, self) end,
		"GUI Inventory highlight",
		true
	)
    
    ScrapGuard_GUI:addItemWithId("btnModeBody", btnModeBody)
    ScrapGuard_GUI:addItemWithId("btnModeCreation", btnModeCreation)
    ScrapGuard_GUI:addItemWithId("btnModeWorld", btnModeWorld)
    
    local optionMenu = GlobalGUI.optionMenu(
        bgX + bgPadding,
        bgY + 92 + modeButtonsHeight + padding,
        bgWidth,
        bgHeight - (92 + modeButtonsHeight + padding),
        nil
    )
    
    local options = {
        ["OutOfWorld"] = {
            index = 0,
            name = "protection_OutOfWorld",
            displayName = "Out of world protection",
            options = nil,
            defaultIndex = nil
        },
        ["Destructable"] = {
            index = 2,
            name = "property_Destructable",
            displayName = "Destructable",
            options = nil,
            defaultIndex = nil
        },
        ["Buildable"] = {
            index = 3,
            name = "property_Buildable",
            displayName = "Buildable",
            options = nil,
            defaultIndex = nil
        },
        ["Paintable"] = {
            index = 4,
            name = "property_Paintable",
            displayName = "Paintable",
            options = nil,
            defaultIndex = nil
        },
        ["Connectable"] = {
            index = 5,
            name = "property_Connectable",
            displayName = "Connectable",
            options = nil,
            defaultIndex = nil
        },
        ["Erasable"] = {
            index = 6,
            name = "property_Erasable",
            displayName = "Erasable",
            options = nil,
            defaultIndex = nil
        },
        ["Usable"] = {
            index = 7,
            name = "property_Usable",
            displayName = "Usable",
            options = nil,
            defaultIndex = nil
        },
        ["Liftable"] = {
            index = 8,
            name = "property_Liftable",
            displayName = "Liftable",
            options = nil,
            defaultIndex = nil
        },
    }
    
    for name, option in pairs(options) do
        option.options = option.options or {"#{MENU_OPTION_ON}", "#{MENU_OPTION_OFF}"}
        option.defaultIndex = option.defaultIndex or 1
        
        local rowHeight = 50
        local rowDivider = 3
        local buttonWidth = 27
        local buttonHeight = 40
    
        local oiX = 0
        local oiY = (rowHeight + rowDivider) * option.index
        local oiW = innerW
        local oiH = rowHeight
        
        local optionItem = optionMenu:addItemWithId(name, oiX, oiY, oiW, oiH)
        
        --local decrease = function(a, b, c)
        --    print(a, b, c)
        --end
        
        optionItem:addLabel         (0, 0, oiW, oiH, option.displayName)
        optionItem:addValueBox      (314 + buttonWidth, 0, 626-315-buttonWidth, oiH, option.options[option.defaultIndex])
        optionItem:addDecreaseButton(314, (rowHeight - buttonHeight) / 2, buttonWidth, buttonHeight, decrease)
        optionItem:addIncreaseButton(629, (rowHeight - buttonHeight) / 2, buttonWidth, buttonHeight, nil)
    end
    
    
    
    ScrapGuard_GUI:addItemWithId("optionMenu", optionMenu)
    
    
    
    self:client_setMode("body")
    
    print("GUI setup completed.")
end

function ScrapGuard.client_onUpdate(self, dt)
	if self.settings then
		self.network:sendToServer("server_onSettingsChange", self.settings)
		self.settings = nil
	end
end

function ScrapGuard.client_onInteract(self)
	if not ScrapGuard_GUI then
        sm.log.warning("[ScrapGuard] Global gui does not exist! Try placing a new block.")
        return
    end
	
	--paintgungui.items.optionmenu1.items.spread.valueBox.widget:setText(tostring(math.floor(self.clientsettings.spread)))
	--paintgungui.items.optionmenu1.items.speed.valueBox.widget:setText(tostring(math.floor(self.clientsettings.speed*10)))
	--paintgungui.items.optionmenu1.items.size.valueBox.widget:setText(tostring(math.floor(self.clientsettings.size*4)))
	--paintgungui.items.optionmenu1.items.bucketmode.valueBox.widget:setText(tostring(self.clientsettings.bucket_mode))
	--paintgungui.items.optionmenu1.items.colormode.valueBox.widget:setText(tostring(self.clientsettings.colormode))
    
	ScrapGuard_GUI:show(self) 
	--ScrapGuard_GUI.on_hide = function()
	--	self.settings = {
	--		spread = tonumber(paintgungui.items.optionmenu1.items.spread.valueBox.widget:getText()),
	--		speed = tonumber(paintgungui.items.optionmenu1.items.speed.valueBox.widget:getText())/10,
	--		size = tonumber(paintgungui.items.optionmenu1.items.size.valueBox.widget:getText())/4,
	--		bucket_mode = tostring(paintgungui.items.optionmenu1.items.bucketmode.valueBox.widget:getText()),
	--		colormode = paintgungui.items.optionmenu1.items.colormode.valueBox.widget:getText()
	--	}
	--end
end

function ScrapGuard.client_setMode( self, mode )
    self.client_settings.mode = mode
    
    ScrapGuard_GUI.items.btnModeBody:setText(mode == "body" and "#df7000BODY" or "BODY")
    ScrapGuard_GUI.items.btnModeCreation:setText(mode == "creation" and "#df7000CREATION" or "CREATION")
    ScrapGuard_GUI.items.btnModeWorld:setText(mode == "world" and "#df7000WORLD" or "WORLD")
end



--[[ Server-side ]]

function ScrapGuard.server_onSettingsChange( self, settings )

end

function ScrapGuard.server_onFixedUpdate( self, timeStep )
    --local a = self.shape.body:hasChanged(sm.game.getCurrentTick() - 1)
    --local a = sm.body.getAllBodies()
    --print(a)
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