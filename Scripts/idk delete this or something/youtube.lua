
dofile "globalgui.lua"

tutorial1 = class( nil )
tutorial1.maxChildCount = -1
tutorial1.maxParentCount = -1
tutorial1.connectionInput = sm.interactable.connectionType.logic
tutorial1.connectionOutput = sm.interactable.connectionType.logic -- none, logic, power, bearing, seated, piston, any
tutorial1.colorNormal = sm.color.new(0xdf7000ff)
tutorial1.colorHighlight = sm.color.new(0xef8010ff)
tutorial1.remoteguiposition = sm.vec3.new(0,0,2000) -- don't touch
tutorial1.remotedistance = 100 -- don't touch


--[[ client ]]
function tutorial1.client_onCreate( self )
	self.clientmode = 0
	self.network:sendToServer( 'server_requestsetting')
end
function tutorial1.client_onRefresh( self ) 
	self:client_onCreate()
end

function tutorial1.client_onSetupGui(self)
	-- only the remote shape can initialize a global gui:
	if (self.shape.worldPosition - self.remoteguiposition):length()>self.remotedistance then
		return -- too far from remoteguiposition, this block cannot initialize gui
	elseif (tutorial1.gui and tutorial1.gui.instantiated) then -- kill duplicate remote gui blocks
		function self.server_onFixedUpdate(self, dt) self.shape:destroyShape(0) print("destroyed dupe") end 
		return
	end 
	
	-- guiBuilder(title, width, height, on_hide_callback, protectionlayers, auto-scale)
	local gui = sm.globalgui.create(self, "gui - test", 1100, 700, function()--[[onhide]] end)
	gui.instantiated = true
	print("==gui setup loading==")
	
	local bgx, bgy = gui.bgPosX , gui.bgPosY 
	
	
	local button1 = sm.globalgui.buttonSmall(bgx + 100, bgy + 100, 100, 50, "AND", function() end)
	local button2 = sm.globalgui.buttonSmall(bgx + 100, bgy + 150, 100, 50, "OR", function() end)
	local button3 = sm.globalgui.buttonSmall(bgx + 100, bgy + 200, 100, 50, "XOR", function() end)
	
	local button4 = sm.globalgui.buttonSmall(bgx + 400, bgy + 400, 300, 100, "blow up\n all players", function() end)
	

	gui:addItemWithId("custombutton1", button1)
	gui:addItemWithId("custombutton2", button2)
	gui:addItemWithId("custombutton3", button3)
	gui:addItemWithId("special",button4)
	tutorial1.gui = gui
end

function tutorial1.client_newsetting(self, setting)
	self.clientmode = setting
end

function tutorial1.client_onUpdate( self, deltaTime )
	if self.interactable.active then
		self.interactable:setUvFrameIndex(6 + self.clientmode)
	else
		self.interactable:setUvFrameIndex(0 + self.clientmode)
	end
	if self.guimode then
		self.network:sendToServer( 'server_changeSetting', self.guimode )
		self.guimode = nil
	end
	if self.killplayers then
		self.network:sendToServer( 'server_killplayers', sm.localPlayer.getPlayer().id )
		self.killplayers = nil
	end
end

function tutorial1.client_onInteract(self)
	if not tutorial1.gui then print('failed to open gui') return end 
	tutorial1.gui:show()
	tutorial1.gui.items["custombutton1"].onClick = function() sm.audio.play("GUI Inventory highlight") self.guimode = 0 end
	tutorial1.gui.items["custombutton2"].onClick = function() sm.audio.play("GUI Inventory highlight") self.guimode = 1 end
	tutorial1.gui.items["custombutton3"].onClick = function() sm.audio.play("GUI Inventory highlight") self.guimode = 2 end
	tutorial1.gui.items["special"].onClick = function() sm.audio.play("GUI Inventory highlight") self.killplayers = true end
	
	
	tutorial1.gui.onHide = function()
		
	end
end


function tutorial1.client_onDestroy(self)
	if tutorial1.gui then tutorial1.gui:setVisible(false, true) end -- sets gui invisible without showing messages (displayalert)
	-- it is possible to not hide the gui(if it is open) when the block is broken, all callbacks that use self(the instance of this broken block) will cause errors tho.
end


--[[ server ]]
function tutorial1.server_onCreate( self )
	self.mode = 0
	
	local stored = self.storage:load()
	
	if stored then
		self.mode = stored
	end
	
	if not tutorial1.createdgui and (self.shape.worldPosition - self.remoteguiposition):length()>self.remotedistance then
		tutorial1.createdgui = true 
		local uuid = self.shape:getShapeUuid() 
		sm.shape.createPart( uuid, self.remoteguiposition, sm.quat.identity(), false, true ) 
	end
end
function tutorial1.server_onRefresh( self )
	self:server_onCreate()
end

function tutorial1.server_changeSetting(self, setting)
	self.mode = setting
	self.storage:save(setting)
	self.network:sendToClients('client_newsetting', setting)
end

function tutorial1.server_requestsetting(self)
	self.network:sendToClients('client_newsetting', self.mode)
end

function tutorial1.server_killplayers(self, id)
	for k, player in pairs(sm.player.getAllPlayers()) do
		if player.id ~= id then
			local location = player.character.worldPosition
			sm.physics.explode( location, 10, 10, 10, 10,  "PropaneTank - ExplosionSmall")
		end
	end
end

function tutorial1.server_onFixedUpdate( self, deltaTime )
	local parents = self.interactable:getParents()
	
	local output = false
	if self.mode == 0 then -- AND gate
		if #parents>0 then
			output = true
			for id, parent in pairs(parents) do
				if not parent.active then
					output = false
				end
			end
		end
	elseif self.mode == 1 then -- or gate
		if #parents>0 then
			output = false
			for id, parent in pairs(parents) do
				if parent.active then
					output = true
				end
			end
		end
	elseif self.mode == 2 then -- xor gate
		if #parents>0 then
			for id, parent in pairs(parents) do
				if parent.active then
					output = not output
				end
			end
		end
	end
	
	self.interactable.active = output
end