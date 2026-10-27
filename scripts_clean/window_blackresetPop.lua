--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local blackresetPop = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

}


function blackresetPop.open(self,touchPriority,data,callback)
    -- print("i...am...open...")
    -- printT(data)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.spendnum = data.data
    self.rootNode, self.rootItems = CCBReaderLoad("tanchuang/heishiresetPop", nil, true, "heishiresetPop")
    self:resetReload()
    
    self.root:addChild(self.rootNode)
    return self.root
end




function blackresetPop.resetReload(self)
    -- print("resetReload====")
    -- printT(self.petskill)


    self.rootItems.spendLabel:setString(self.spendnum)
    -- 返回
    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("blackreset")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)




    -- 重置
    ui.setLabelString(self.rootItems.resetText, nil, 19)
    self.rootItems.resetBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("blackreset")

        UIRequest({type = 3632, spendnum = self.spendnum})

    end, CCControlEventTouchUpInside)
    self.rootItems.resetBtn:setSwallowsTouch(true)
    self.rootItems.resetBtn:setTouchPriority(self.touchPriority)
end

function blackresetPop.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return blackresetPop