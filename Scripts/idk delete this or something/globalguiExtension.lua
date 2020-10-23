function sm.globalgui.toggleButton( posX, posY, width, height, value, onclick_callback, play_sound, border, active )
	assert(type(posX) == "number", "toggleButton: posX, number expected! got: "..type(posX))
	assert(type(posY) == "number", "toggleButton: posY, number expected! got: "..type(posY))
	assert(type(width) == "number", "toggleButton: width, number expected! got: "..type(width))
	assert(type(height) == "number", "toggleButton: height, number expected! got: "..type(height))
	assert(type(value) == "string", "toggleButton: value, string expected! got: "..type(value))
	assert(type(onclick_callback) == "function" or onclick_callback == nil, "toggleButton: onclick_callback, function or nil expected! got: "..type(onclick_callback))
	assert(type(play_sound) == "string" or play_sound == nil, "toggleButton: play_sound, string or nil expected! got: "..type(play_sound))
	assert(type(border) == "boolean" or border == nil, "toggleButton: border, boolean or nil expected! got: "..type(border))
    assert(type(active) == "boolean" or active == nil, "toggleButton: active, boolean or nil expected! got: "..type(border))
	
	posX, posY, width, height = posX*sm.globalgui.scaleX, posY*sm.globalgui.scaleY, width*sm.globalgui.scaleX, height*sm.globalgui.scaleY
	
	local extra = (border == false and 10 or 0)
	local item = {}
	item.visible = true
	item.gui = sm.gui.load("ChallengeMessage.layout", true)
	item.gui:setPosition(posX , posY )
	item.gui:setSize(width, height)
	

	local MainPanel = item.gui:find("MainPanel")
	sm.gui.widget.destroy(MainPanel:find("Title"))
	sm.gui.widget.destroy(MainPanel:find("Reset"))
	MainPanel:setSize(width, height)
	
	item.widget = MainPanel:find("Next")
	item.widget:setPosition(extra/-2,extra/-2)
	item.widget:setSize(width + extra, height+ extra)
	item.widget:setText(value)
    
    item.guiActive = sm.gui.load("TimerGui.layout", true)
    item.guiActive:setPosition(posX + 1, posY + 1)
    item.guiActive:setSize(width - 2, height - 2)
    
    sm.gui.widget.destroy(item.guiActive:find("Button"))
    sm.gui.widget.destroy(item.guiActive:find("Title"))
    sm.gui.widget.destroy(item.guiActive:find("Container"))
    sm.gui.widget.destroy(item.guiActive:find("Seconds"))
    
    item.widgetActive = item.guiActive:find("Ticks")
    item.widgetActive:setPosition(0, 0)
    item.widgetActive:setSize(width - 2, 101)
	
	item.id = item.widget.id
	
	function item.getClickRoutes(self)
		self.getClickRoutes = nil -- destroy function, only called once
		return {self.widget.id}
	end
	if onclick_callback or play_sound then 
		function item.onClick(self, widgetid)
			if play_sound then sm.audio.play(play_sound) end
			if onclick_callback then onclick_callback() end
		end
		item.widget:bindOnClick("client_onclick")
	end
	function item.setVisible(self, visible)
		self.visible = visible
		self.gui.visible = visible
        self.guiActive.visible = visible
	end
	
	function item.setText(self, text)
		self.widget:setText(text)
	end
	function item.getText(self)
		return self.widget:getText()
	end
	return item
end