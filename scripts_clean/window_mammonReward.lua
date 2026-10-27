--
-- Created by IntelliJ IDEA.
-- User: caoxiang
-- Date: 15/6/26
-- Time: 下午6:07
-- To change this template use File | Settings | File Templates.
--

--财神奖励弹窗

local mammonReward = {
    rootNode = nil,
    rootItems = nil,
    needcallback=true
};

function mammonReward.open(self,touchPriority,data,callback)
    self.rootNode,self.rootItems = CCBReaderLoad("activitymammon/mammon_pop",nil,true,"mammon_pop");
    self.touchPriority = touchPriority;
    self:reload(data,callback);
    return self.rootNode;
end

function mammonReward.reload(self,data,callback)
    self.callback = callback;
    self.rootItems.get:setString(data.get)
    ui.setLabelString(self.rootItems.get,data.get,21);

    -- ui.setLabelString(self.rootItems.change_label,"您的       变成了：",12);
    ui.setLabelString(self.rootItems.change_label,gameConfig.strings:string_common("popups","youBi"),121);
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("mammon_pop")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.oklabel,nil,18);
    self.rootItems.okButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("mammon_pop")
    end, CCControlEventTouchUpInside)
    self.rootItems.okButton:setSwallowsTouch(true)
    self.rootItems.okButton:setTouchPriority(self.touchPriority)

end

function mammonReward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true);
    self.rootNode:removeFromParentAndCleanup(true);
    self.rootNode = nil;
    self.rootItems = nil;
    if self.callback then
        self.callback();
    end
end

return mammonReward;
