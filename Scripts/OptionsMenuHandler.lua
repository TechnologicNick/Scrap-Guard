print("OptionsMenuHandler Reloaded!")

function OptionsMenuItem(scriptedClass, widgetAll, id, name, displayName, options, defaultIndex)
    -- Create object
    local object = {}
    
    -- Initialisation
    object.scriptedClass = scriptedClass
    object.widgetAll = widgetAll
    object.id = id
    object.name = name
    object.displayName = displayName or name
    object.options = options or {"#{MENU_OPTION_ON}", "#{MENU_OPTION_OFF}"}
    object.defaultIndex = defaultIndex or 1
    
    object.widgetItem = object.widgetAll:find("ITEM_" .. tostring(id))
    object.selectedIndex = object.defaultIndex
    
    object.tbLabel = object.widgetItem:find("Label")
    object.tbValue = object.widgetItem:find("Value")
    object.btnDecrease = object.widgetItem:find("Decrease")
    object.btnIncrease = object.widgetItem:find("Increase")
    
    object.scriptedClass.decreaseButtons[object.btnDecrease.id] = object.id
    object.scriptedClass.increaseButtons[object.btnIncrease.id] = object.id
    
    -- OptionsMenuItem Functions
    function object.selectIndex(index)
        --print(object.selectedIndex, index)
        object.selectedIndex = index
        object.tbValue:setText(object.options[object.selectedIndex])
    end
    
    function object.decrease()
        --object.selectIndex(((object.selectedIndex + 2) % (#object.options + 0)) + 1)
        local tmp = object.selectedIndex - 1
        if tmp < 1 then
            tmp = #object.options
        end
        object.selectIndex(tmp)
        --print("Decrease the value!", (object.selectedIndex + 1) % #object.options))
    end
    
    function object.increase()
        object.selectIndex(object.selectedIndex % #object.options + 1)
        --print("Increase the value!", (object.selectedIndex + 1) % #object.options))
    end
    
    object.widgetItem.visible = true
    object.widgetItem.posY = select(2, object.widgetItem:getPosition())
    --print("here", object.widgetItem.posY, object.widgetItem:getPosition())
    
    -- Widget parameters
    object.widgetItem.height = 50
    object.widgetItem.horizontalDivider = 3
    object.widgetItem.buttonWidth = 27
    object.widgetItem.buttonHeight = 40
    
    
    
    object.widgetItem:setSize(720, object.widgetItem.height)
    if object.id < 9 then
        object.widgetItem:setPosition(40, 92 + (object.widgetItem.height + object.widgetItem.horizontalDivider) * object.id)
    else
        object.widgetItem:setPosition(741, 92 + (object.widgetItem.height + object.widgetItem.horizontalDivider) * (object.id - 9))
    end
    
    object.tbLabel:setPosition(0, 0)
    object.tbLabel:setSize(720, object.widgetItem.height)
    
    object.tbLabel:setText(object.displayName)
    object.selectIndex(object.defaultIndex)
    
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
    function scriptedClass.decrease(self, widget)
        self.optionsMenuItems[self.decreaseButtons[widget.id]]:decrease()
    end
    
    function scriptedClass.increase(self, widget)
        self.optionsMenuItems[self.increaseButtons[widget.id]]:increase()
    end
    
    return object
end