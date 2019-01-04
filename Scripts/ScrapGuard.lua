dofile("OptionsMenuHandler.lua")

-- ScrapGuard.lua --

--print("[ScrapGuard] file init")

ScrapGuard = class( nil )
ScrapGuard.maxChildCount = -1
ScrapGuard.maxParentCount = -1
ScrapGuard.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
ScrapGuard.connectionOutput = sm.interactable.connectionType.logic
ScrapGuard.colorNormal = sm.color.new( 0x404040ff )
ScrapGuard.colorHighlight = sm.color.new( 0x606060ff )

function ScrapGuard.client_onCreate( self )
    self.optionsMenuItems = {}
    self.decreaseButtons = {}
    self.increaseButtons = {}
end

function ScrapGuard.client_onSetupGui( self )
    --self.guiAntiHUD = sm.gui.load("ChallengeMessage.layout", true)
    self.guiBg = sm.gui.load("ChallengeMessage.layout", true)
    self.gui = sm.gui.load("OptionsMenuPage.layout", false)
    
    self.guiBg.bgMainPanel = self.guiBg:find("MainPanel")
    self.gui.mainPanel = self.gui:find("OptionsMenuPageMainPanel")
    
    local screenWidth, screenHeight = sm.gui.getScreenSize()
    --local bgWidth, bgHeight = self.guiBg.bgMainPanel:getSize()
    local bgWidth = 1440
    local bgHeight = 640
    self.guiBg.bgMainPanel:setSize(bgWidth, bgHeight)
    
    --local bgPosX, bgPosY = self.guiBg.bgMainPanel:getPosition()
    local bgPosX = screenWidth/2 - bgWidth/2
    local bgPosY = screenHeight/2 - bgHeight/2
    
    --print(bgPosX, bgPosY, screenWidth, screenHeight, bgWidth, bgHeight)
    
    --self.guiBg.bgMainPanel:setSize(bgWidth, bgHeight)
    self.guiBg.bgMainPanel:setPosition(bgPosX, bgPosY)
    self.guiBg.bgMainPanel.title = self.guiBg.bgMainPanel:find("Title")
    self.guiBg.bgMainPanel.title:setText("Scrap Guard")
    self.guiBg.bgMainPanel.btnNext = self.guiBg.bgMainPanel:find("Next")
    self.guiBg.bgMainPanel.btnNext.visible = false
    self.guiBg.bgMainPanel.btnReset = self.guiBg.bgMainPanel:find("Reset")
    self.guiBg.bgMainPanel.btnReset.visible = false
    
    self.gui.mainPanel:setSize(bgWidth, bgHeight)
    self.gui.mainPanel:setPosition(bgPosX, bgPosY)
    
    
    
    for i=0,17 do
        self.gui.mainPanel:find("ITEM_" .. i).visible = false
    end
    
    self.optionsMenuItems[0]  = OptionsMenuItem(self, self.gui.mainPanel, 0,  "Shadow", nil, {"#{MENU_OPTION_LOW}", "#{MENU_OPTION_MEDIUM}", "#{MENU_OPTION_HIGH}"}, nil)
    self.optionsMenuItems[1]  = OptionsMenuItem(self, self.gui.mainPanel, 1,  "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[2]  = OptionsMenuItem(self, self.gui.mainPanel, 2,  "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[3]  = OptionsMenuItem(self, self.gui.mainPanel, 3,  "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[4]  = OptionsMenuItem(self, self.gui.mainPanel, 4,  "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[5]  = OptionsMenuItem(self, self.gui.mainPanel, 5,  "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[6]  = OptionsMenuItem(self, self.gui.mainPanel, 6,  "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[7]  = OptionsMenuItem(self, self.gui.mainPanel, 7,  "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[8]  = OptionsMenuItem(self, self.gui.mainPanel, 8,  "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[9]  = OptionsMenuItem(self, self.gui.mainPanel, 9,  "Dynamic Lights", nil, nil, nil)
    self.optionsMenuItems[10] = OptionsMenuItem(self, self.gui.mainPanel, 10, "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[11] = OptionsMenuItem(self, self.gui.mainPanel, 11, "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[12] = OptionsMenuItem(self, self.gui.mainPanel, 12, "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[13] = OptionsMenuItem(self, self.gui.mainPanel, 13, "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[14] = OptionsMenuItem(self, self.gui.mainPanel, 14, "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[15] = OptionsMenuItem(self, self.gui.mainPanel, 15, "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[16] = OptionsMenuItem(self, self.gui.mainPanel, 16, "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    self.optionsMenuItems[17] = OptionsMenuItem(self, self.gui.mainPanel, 17, "Shadow2", nil, {"1", "2", "3", "4", "5", "6", "7"}, nil)
    
    print(sm.gui.load("GraphicsOptions.layout", false):find("GraphicsMainPanel"):find("GraphicsQuality"):getSize())
    
    --for i=0,1 do
    --    print(self.optionsMenuItems[i])
    --end
end

function ScrapGuard.client_onInteract( self )
    if self.gui and self.guiBg then
        self.guiBg.visible = true
        --self.gui.visible = true
        
    end
end

function ScrapGuard.client_onUpdate( self, dt )
    if self.gui and self.guiBg then
        self.gui.visible = self.guiBg.visible
        --self.guiBg.visible = self.gui.visible
    end
end

--function ScrapGuard.decrease( self, widget )
--    print("decrease", self, idk, idk2)
--end