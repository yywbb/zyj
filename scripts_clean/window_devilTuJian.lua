--
-- 魔宠被动技能列表
-- 魔宠说明
-- User: zjh
--
local devilTuJian = {
    rootNode = nil,
    rootItems = nil,
    quality = 4,--技能品质等级
    dataNum = 0 ,--数据总个数	
}

function devilTuJian.open(self,touchPriority,data,callback)
    print("devilSkills...am...open...")
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    --加载魔宠说明
    self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochong_tujian_rule", nil, true, "mochong_rule")
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("devilTuJian")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)    

    return self.rootNode        
end

function devilTuJian.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end


return devilTuJian