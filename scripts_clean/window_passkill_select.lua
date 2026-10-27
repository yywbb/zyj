--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/12/17
-- Time: 15:52
-- To change this template use File | Settings | File Templates.
--



local passkillselect = {
    rootNode = nil,
    rootItems = nil,
}

function passkillselect.open(self,touchPriority,data,callback)
    -- print("passkillselect..open")
    -- printT(data)
    self.touchPriority = touchPriority

    if data.index == "rule" then
        self.rootNode, self.rootItems = CCBReaderLoad("passkill/passkill_rule", nil, true, "passkill_rule")
        self:rulereload()
    else
        self.rootNode, self.rootItems = CCBReaderLoad("passkill/passkill_select", nil, true, "passkill_select")
        self:reload()
    end
    
    



    return self.rootNode
end


function passkillselect.reload(self)


    ui.setLabelString(self.rootItems.backText,nil,19)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("passkillselect")
    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.touchPriority)


    self.rootItems.leftBtn:addHandleOfControlEvent(function()
        print("leftBtn＝＝＝＝")
        gameWindows:closeWindowDirect("passkillselect")

        GameScene:shiftLayer("passkillmain","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.leftBtn:setSwallowsTouch(true)
    self.rootItems.leftBtn:setTouchPriority(self.touchPriority)

    self.rootItems.rightBtn:addHandleOfControlEvent(function()
        print("rightBtn＝＝＝＝")
        gameWindows:closeWindowDirect("passkillselect")
        if gamedata.config.build[tostring(178)].switch == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("passkill",2)})
        end
        
    end, CCControlEventTouchUpInside)
    self.rootItems.rightBtn:setSwallowsTouch(true)
    self.rootItems.rightBtn:setTouchPriority(self.touchPriority)

    printT(gamedata.config.build,"build====")
    if gamedata.config.build[tostring(178)].switch == 0 then
        print("addGray====")
        ui.addGray("CCControlButton",self.rootItems.rightBtn)
    else
        print("removeGray====")
        ui.removeGray("CCControlButton",self.rootItems.rightBtn)
    end


end


function passkillselect.rulereload(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        print("closeButton＝＝＝＝")
        gameWindows:closeWindowDirect("passkillselect")
        
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end


function passkillselect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    
end



return passkillselect
