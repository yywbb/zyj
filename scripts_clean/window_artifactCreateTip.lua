--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/6
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local artifactCreateTip = {
    rootNode = nil,
    rootItems = nil,
    isSelect = false,
    needcallback = true,
    selectToContinue = false,
}

function artifactCreateTip.open(self,touchPriority,data,callback)

    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_tishi", nil, true, "shenqi_tishi")
    self:initFixedString()
    self.touchPriority = touchPriority
    self.callback = callback
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        
        gameWindows:closeWindow("artifactCreateTip")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.noButton:addHandleOfControlEvent(function()
        
        gameWindows:closeWindow("artifactCreateTip")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    self.rootItems.yesButton:addHandleOfControlEvent(function()
        self.selectToContinue = true
        gameWindows:closeWindowDirect("artifactCreateTip")
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

    self.rootItems.selectSp2:setVisible(self.isSelect)
    self.rootItems.selectUse:addHandleOfControlEvent(function()
        self.isSelect = not self.isSelect
        self.rootItems.selectSp2:setVisible(self.isSelect)
    end, CCControlEventTouchUpInside)
    self.rootItems.selectUse:setSwallowsTouch(true)
    self.rootItems.selectUse:setTouchPriority(self.touchPriority)

    self.rootItems.castNode:setVisible(data.showType == "cast")
    self.rootItems.checkNode:setVisible(data.showType ~= "cast")
    if data.showType == "cast" then
        ui.setLabelString(self.rootItems.starttext1,gameConfig.strings:string_common("artifact",122),19)
        local rich = {
            {fontID = 9,content = gameConfig.strings:string_common("equips",8),},
            {fontID = 48,content = " "..gameConfig.strings:string_common("artifact",128).." ",},
            {fontID = 9,content = gameConfig.strings:string_common("artifact",129),},
        }
        ui.createRichLabel(rich,self.rootItems.castNode1,false)

        local rich = {
            {fontID = 48,content = gameConfig.strings:string_common("artifact",133),},
            {fontID = 9,content = " "..gameConfig.strings:string_common("equips",8).." ",},
            {fontID = 48,content = gameConfig.strings:string_common("artifact",130),},
            {fontID = 9,content = " "..gameConfig.strings:string_common("attr_type","atk").." ",},
            {fontID = 48,content = gameConfig.strings:string_common("artifact",131),},
            {fontID = 9,content = " "..gameConfig.strings:string_common("artifact",132),},
        }
        ui.createRichLabel(rich,self.rootItems.castNode2,false)
    else
        ui.setLabelString(self.rootItems.starttext1,gameConfig.strings:string_common("artifact",126),19)
    end
    
    return self.rootNode
end

function artifactCreateTip.initFixedString(self)
    self.rootItems.tip1:setString(gameConfig.strings:string_common("artifact",127))
    --self.rootItems.tip2:setString(gameConfig.strings:string_common("artifact",120))
    self.rootItems.tip3:setString(gameConfig.strings:string_common("artifact",121))
    self.rootItems.tip4:setString(gameConfig.strings:string_common("artifact",123))
    self.rootItems.tip5:setString(gameConfig.strings:string_common("artifact",125))
    ui.setLabelString(self.rootItems.tip6,gameConfig.strings:string_common("artifact",124),5)
    ui.setLabelString(self.rootItems.starttext,gameConfig.strings:string_common("buttontext","fanhui"),19)
end


function artifactCreateTip.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    
    if self.callback then
        self.callback(self.isSelect,self.selectToContinue)
    end
    self.isSelect = false
    self.selectToContinue = false
end


return artifactCreateTip