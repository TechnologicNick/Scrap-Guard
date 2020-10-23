----------------------------------
--Copyright (c) 2019 Brent Batch--
----------------------------------
-- the global gui instance in this class is called 'guitestgui', please use unique names in your script

-- gui test --

guitest = class( nil )
guitest.maxChildCount = 0
guitest.maxParentCount = 1
guitest.connectionInput = sm.interactable.connectionType.power + sm.interactable.connectionType.logic
guitest.connectionOutput = 0
guitest.colorNormal = sm.color.new(0xe54500ff)
guitest.colorHighlight = sm.color.new(0xff7033ff)
guitest.poseWeightCount = 1
guitest.remoteguiposition = sm.vec3.new(0,0,2000) -- don't touch
guitest.remotedistance = 100 -- don't touch

if not guiBuilder then
	dofile("guiBuilder.lua")
end

--[[server]]
function guitest.server_onCreate(self) -- spawn remote global gui block on first block placement which instantiates GLOBALGUI ~ magix ~ :o
	if not guitest.remoteShape and (self.shape.worldPosition - self.remoteguiposition):length()>self.remotedistance then
		guitest.remoteShape = true
		local uuid = self.shape:getShapeUuid()
		sm.shape.createPart( uuid, self.remoteguiposition, sm.quat.identity(), false, true ) 
	end
end

function guitest.server_onFixedUpdate(self, dt) -- do not remove this callback, put code in it or keep empty

end


--[[client]]

function guitest.client_onCreate(self)

end

function guitest.client_onSetupGui( self )
	-- only the remote shape can initialize a global gui:
	if (self.shape.worldPosition - self.remoteguiposition):length()>self.remotedistance then
		return -- too far from remoteguiposition, this block cannot initialize gui
	elseif (guitestgui and guitestgui.instantiated) then -- kill duplicate remote gui blocks
		function self.server_onFixedUpdate(self, dt) self.shape:destroyShape(0) end 
		return
	end 
	
	-- guiBuilder(title, width, height, on_hide_callback, protectionlayers, auto-scale)
	guitestgui = guiBuilder("gui - test", 1100, 700, function()--[[onhide]]end, 50, true)
	guitestgui.instantiated = true
	print("==gui setup loading==")
	
	guitestgui:setupGui(self)
	
	local bx, by = guitestgui.bgPosX, guitestgui.bgPosY -- background gui pos
	
	
	local optionmenu = optionMenuItem(bx + 100, by + 100, 500, 50)
	local item = optionmenu:addItemWithId("option1",0,0,500,50)
	
	local valuebox = item:addValueBox(250,0,150,50, "1")
	item:addLabel(0,0,250-27,50, "label for this value:")
	local testlabel = labelItem(bx + 50, by + 200, 200, 100, "1" )
	
	item:addDecreaseButton(250-27,5,27,40, "decreasebutton",  
		function()
			print(testlabel)
			valuebox:setText(tostring(tonumber(valuebox:getText())-1)) 
		end)
	item:addIncreaseButton(400,5,27,40, "increasebutton",
		function()
			valuebox:setText(tostring(tonumber(valuebox:getText())+1)) 
		end) 
	guitestgui:addItemWithId("optionmenu1", optionmenu) -- HOW TO GET ITEMS BY CUSTOM ID IN ONINTERACT
	
	local collection = collectionItems({})
	collection:addItem(buttonSmallItem(bx + 700, by + 200, 100, 50, "tab abc 1111", function() collection:setVisible(false) end, "GUI Inventory highlight") )
	collection:addItem(buttonSmallItem(bx + 800, by + 200, 100, 50, "tab def 1111") )
	collection:addItem(buttonSmallItem(bx + 700, by + 250, 100, 50, "tab ghi 1111") )
	collection:addItem(buttonSmallItem(bx + 800, by + 250, 100, 50, "tab jkl 1111") )
	local collection2 = collectionItems({})
	collection2:addItem(buttonSmallItem(bx + 700, by + 200, 100, 50, "tab mno 222") )
	collection2:addItem(buttonSmallItem(bx + 800, by + 200, 100, 50, "tab pqr 222") )
	collection2:addItem(buttonSmallItem(bx + 700, by + 250, 100, 50, "tab stu 222") )
	collection2:addItem(buttonSmallItem(bx + 800, by + 250, 100, 50, "tab vwx 222") )
	
	local button1 = buttonSmallItem(bx + 650, by + 120, 150, 70, "tab 1", function()end, "GUI Inventory highlight"--[[makes sure there is a bound onClick]])
	local button2 = buttonSmallItem(bx + 800, by + 120, 150, 70, "tab 2", function() print("tab2") end, "GUI Inventory highlight")
	
	button1.onClick =
	function(btn, widgetid) -- the onclick provides 2 variables, the button itself and the widgetid for the button
		button2:setVisible(true)
		btn:setVisible(false) 
		print(btn:getText())  -- example of onClick doing stuff to button itself
		sm.audio.play("GUI Inventory highlight") -- kills its playsound defined in the button initialize on line 79 so add it again
	end 
	button2.onClick = 
	function(btn, widgetid)
		button1:setVisible(true)
		btn:setVisible(false)
		print(btn:getText())  -- example of onClick doing stuff to button itself,
		sm.audio.play("GUI Inventory highlight") -- kills its playsound so add it again
	end 
	
	local tabcontroll = 
		tabControllItem( -- makes it possible for the gui to manage collections visibility properly
			{
				button1,
				button2
			},
			{
				collection,
				collection2
			}
		)
		
	local pbutton1 = buttonSmallItem(bx + 650, by + 50, 150, 50, "parent tab1", nil, "GUI Inventory highlight")
	-- example nested tabControllItem:
	guitestgui:addItem(
		tabControllItem(
			{
				pbutton1,
				buttonSmallItem(bx + 800, by + 50, 150, 50, "parent tab2", nil, "GUI Inventory highlight")
			},
			{
				tabcontroll,
				buttonSmallItem(bx + 650, by+ 150, 300, 200, "parent tab\ncontent 2")
			}
		)
	)
	
	guitestgui:addItem(buttonItem(bx + 650, by + 400, 200, 100, "<button no border>", function()print('lol')end, "GUI Inventory highlight", false ))
	
	guitestgui:addItem(labelItem(bx + 250, by + 400, 200, 100, "#ff0000label\nnoborder", nil , nil, false))
	local textbox = textBoxItem(bx + 450, by + 400, 100, 100, "#00ff00textboxvalue")
	guitestgui:addItem(textbox)
	
	guitestgui:addItem(buttonSmallItem(bx + 450, by + 250, 100, 50, "small", 
		function()
			sm.gui.displayAlertText("HEHE\t\t\tLOL", 1)
			print('test')
			print(textbox:getText())
		end), "GUI Inventory highlight")
	
	
	guitestgui:addItem(buttonItem(bx + guitestgui.width - 50, by + 0, 50, 50, "#ff0000X", 
		function()
			guitestgui:hide()
		end))
	--guitestgui:addItem(invisibleBoxItem(bx, by,0, 0, guitestgui.width - 50, 50,
	--	function()
	--		guitestgui:hide() 
	--	end))  
	
	guitestgui:addItem(labelSmallItem(bx + 50, by + 400, 200, 100, "smalllabel\nborder"))
end


function guitest.client_onInteract(self)
	if not guitestgui then sm.gui.displayAlertText("ERROR:NotInitialized; place a new gui block") return end
	
	-- fill GLOBAL gui with self.values first (example given:)
	guitestgui.items.optionmenu1.items.option1.valueBox.widget:setText(self.savedvalue or "0")
	
	guitestgui:show() 
	guitestgui.on_hide =
	function() -- gets called when the gui is hidden
		-- save values in self here:
		self.savedvalue = guitestgui.items.optionmenu1.items.option1.valueBox.widget:getText()
		-- self.guisettingschanged = self.savedvalue -- server syncing (uses "client_onUpdate"-code as pass-through to server)
	end
	guitestgui.onClick = 
	function() -- when any clickable item in the gui is clicked upon
		-- could save values here or whatever
	end
end

function guitest.client_onUpdate(self, dt)-- has to exist for gui to function, guibuilder overwrites this for remotegui-block >> DO NOT REMOVE
	--[[ -- possible gui settings sync: check if settings changed by local player, send to server if changed
		if self.guisettingschanged then 
			self.network:sendToServer("server_settingsChanged", self.guisettingschanged)
			self.guisettingschanged = nil
		end
	]]
end

function guitest.client_onDestroy(self)
	if guitestgui then guitestgui:setVisible(false, true) end -- sets gui invisible without showing messages (displayalert)
	-- it is possible to not hide the gui(if it is open) when the block is broken, all callbacks that use self(the instance of this broken block) will cause errors tho.
end



-- /* Script Developer tools: '-dev' mode required
function guitest.client_onRefresh(self) -- has to exist for gui to properly reload ~ can be removed upon workshop release
	self:client_onCreate() -- optional
end
function guitest.server_onRefresh(self) -- has to exist for gui to properly reload ~ can be removed upon workshop release
	self:server_onCreate() -- optional
end
-- */ Script Developer tools

