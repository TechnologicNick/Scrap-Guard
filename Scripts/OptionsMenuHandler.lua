--print("OptionsMenuHandler Reloaded!")

function OptionsMenu(scriptedClass, title, rowsPerColumn)
    local object = {}
    
    object.scriptedClass = scriptedClass
    object.title = title
    object.rowsPerColumn = rowsPerColumn or 9
    object.items = {}
    object.decreaseButtons = {}
    object.increaseButtons = {}
    
    function object.setupGui(self)
        self.guiBg = sm.gui.load("ChallengeMessage.layout", true)
        self.gui = sm.gui.load("OptionsMenuPage.layout", false)
        
        self.guiBg.bgMainPanel = self.guiBg:find("MainPanel")
        self.gui.mainPanel = self.gui:find("OptionsMenuPageMainPanel")
        
        self.guiBg.bgMainPanel.title = self.guiBg.bgMainPanel:find("Title")
        self.guiBg.bgMainPanel.btnNext = self.guiBg.bgMainPanel:find("Next")
        self.guiBg.bgMainPanel.btnReset = self.guiBg.bgMainPanel:find("Reset")
        
        self:resize(nil)
        
        -- Hide all items
        for i=0,17 do
            self.gui.mainPanel:find("ITEM_" .. i).visible = false
        end
    end
    
    function object.resize(self, wideMode)
        if wideMode == nil then
            wideMode = #object.items > self.rowsPerColumn
        end
    
        local screenWidth, screenHeight = sm.gui.getScreenSize()
        local bgWidth = wideMode and 1440 or 739
        local bgHeight = 163 + 53 * self:getRowCount()
        local bgPosX = screenWidth/2 - bgWidth/2
        local bgPosY = screenHeight/2 - bgHeight/2
        
        self.guiBg.bgMainPanel:setSize(bgWidth, bgHeight)
        self.guiBg.bgMainPanel:setPosition(bgPosX, bgPosY)
        
        self.guiBg.bgMainPanel.title:setPosition(0, 0)
        self.guiBg.bgMainPanel.title:setSize(bgWidth, 90)
        self.guiBg.bgMainPanel.title:setText(self.title)
        
        self.guiBg.bgMainPanel.btnNext.visible = false
        
        self.guiBg.bgMainPanel.btnReset.visible = false
        
        self.gui.mainPanel:setSize(bgWidth, bgHeight)
        self.gui.mainPanel:setPosition(bgPosX, bgPosY)
    end
    
    function object.getRowCount(self)
        local highestRow = 0
        for k,v in pairs(self.items) do
            local currentRow = v.rowIndex % self.rowsPerColumn
            if currentRow > highestRow then
                highestRow = currentRow
            end
        end
        return highestRow
    end
    
    function object.show(self)
        self.guiBg.visible = true
    end
    
    function object.hide(self)
        self.guiBg.visible = false
    end
    
    function object.update(self, dt)
        if self.gui and self.guiBg then
            self.gui.visible = self.guiBg.visible
        end
    end
    
    function object.addOptionsMenuItem(self, id, rowIndex, name, displayName, options, defaultIndex)
        self.items[id] = OptionsMenuItem(self, id, rowIndex, name, displayName, options, defaultIndex)
    end
    
    return object
end



--[[
    optionsMenu  = OptionsMenu - The OptionsMenu. (parent)
    id           = Number      - The id of the item.
    rowIndex     = Number      - The index to draw the item in the GUI. (use 'nil' to default 'rowIndex' to 'id')
    name         = String      - The name used in storage. (not implemented yet)
    displayName  = String      - The name to be displayed in the GUI. (use 'nil' to default 'displayName' to 'name')
    options      = {String}    - Table of strings of options to choose from. Has support for i18n. (use 'nil' to default to "On/Off")
    defaultIndex = Number      - The index of the default option. (use 'nil' to default to the first option)
]]
function OptionsMenuItem(optionsMenu, id, rowIndex, name, displayName, options, defaultIndex)
    -- Create object
    local object = {}
    
    -- Initialisation
    object.optionsMenu = optionsMenu
    object.widgetAll = object.optionsMenu.gui.mainPanel
    object.id = id
    object.rowIndex = rowIndex or object.id
    object.name = name
    object.displayName = displayName or name
    object.options = options or {"#{MENU_OPTION_ON}", "#{MENU_OPTION_OFF}"}
    object.defaultIndex = defaultIndex or 1
    
    object.scriptedClass = optionsMenu.scriptedClass
    object.widgetItem = object.widgetAll:find("ITEM_" .. tostring(id))
    object.selectedIndex = object.defaultIndex
    
    object.tbLabel = object.widgetItem:find("Label")
    object.tbValue = object.widgetItem:find("Value")
    object.btnDecrease = object.widgetItem:find("Decrease")
    object.btnIncrease = object.widgetItem:find("Increase")
    
    object.optionsMenu.decreaseButtons[object.btnDecrease.id] = object.id
    object.optionsMenu.increaseButtons[object.btnIncrease.id] = object.id
    
    -- OptionsMenuItem Functions
    function object.selectIndex(self, index)
        --print(type(index))
        --print("1", index)
        self.selectedIndex = index
        if not sm.isServerMode() then
            --print("2", sm.isServerMode(), self.selectedIndex)
            self.tbValue:setText(tostring(self.options[self.selectedIndex]))
        end
    end
    
    function object.decrease(self)
        local newIndex = self.selectedIndex - 1
        if newIndex < 1 then
            newIndex = #self.options
        end
        self.selectIndex(object, newIndex)
        self.optionsMenu.scriptedClass.network:sendToServer("server_onOptionsMenuValueChanged", {id = self.id, selectedIndex = newIndex, change = -1})
    end
    
    function object.increase(self)
        local newIndex = self.selectedIndex % #self.options + 1
        self.selectIndex(self, newIndex)
        self.optionsMenu.scriptedClass.network:sendToServer("server_onOptionsMenuValueChanged", {id = self.id, selectedIndex = newIndex, change = 1})
    end
    
    function object.getSelectedIndex()
        return object.selectedIndex
    end
    
    function object.getSelectedOption()
        return object.options[object.selectedIndex]
    end
    
    object.widgetItem.visible = true
    object.widgetItem.posY = select(2, object.widgetItem:getPosition())
    
    -- Widget parameters
    object.widgetItem.height = 50
    object.widgetItem.rowDivider = 3
    object.widgetItem.buttonWidth = 27
    object.widgetItem.buttonHeight = 40
    
    
    
    object.widgetItem:setSize(720, object.widgetItem.height)
    if object.id < object.optionsMenu.rowsPerColumn then
        object.widgetItem:setPosition(40, 92 + (object.widgetItem.height + object.widgetItem.rowDivider) * object.rowIndex)
    else
        object.widgetItem:setPosition(741, 92 + (object.widgetItem.height + object.widgetItem.rowDivider) * (object.rowIndex - object.optionsMenu.rowsPerColumn))
    end
    
    object.tbLabel:setPosition(0, 0)
    object.tbLabel:setSize(720, object.widgetItem.height)
    
    object.tbLabel:setText(object.displayName)
    object:selectIndex(object.defaultIndex)
    
    object.btnDecrease:setSize(object.widgetItem.buttonWidth, object.widgetItem.buttonHeight)
    object.btnIncrease:setSize(object.widgetItem.buttonWidth, object.widgetItem.buttonHeight)
    
    object.btnDecrease:setPosition(314, (object.widgetItem.height - object.widgetItem.buttonHeight) / 2) --test stuff
    object.btnIncrease:setPosition(621, (object.widgetItem.height - object.widgetItem.buttonHeight) / 2)
    
    object.tbValue:setPosition(314+object.widgetItem.buttonWidth, 0)
    object.tbValue:setSize(622-315-object.widgetItem.buttonWidth, object.widgetItem.height)
    
    object.btnDecrease:bindOnClick("decrease")
    object.btnIncrease:bindOnClick("increase")
    
    --print("decrease =", scriptedClass.decrease)
    
    -- ScriptedClass Functions
    function object.scriptedClass.decrease(self, widget)
        self.optionsMenu.items[self.optionsMenu.decreaseButtons[widget.id]]:decrease()
    end
    
    function object.scriptedClass.increase(self, widget)
        self.optionsMenu.items[self.optionsMenu.increaseButtons[widget.id]]:increase()
    end
    
    return object
end