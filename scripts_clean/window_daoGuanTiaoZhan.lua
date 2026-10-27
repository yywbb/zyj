--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/11/3
-- Time: 下午2:17
-- To change this template use File | Settings | File Templates.
--

local daoGuanTiaoZhan = {
    rootNode = nil,
    rootItems = nil,

    buynum = 0,
    totalprice = 0,

    data = {},

}

function daoGuanTiaoZhan.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("daoguanshouwei/daoguanshouwei_tiaozhan", nil, true, "tc_property")

    self.touchPriority = touchPriority

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("daoGuanTiaoZhan")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("daoGuanTiaoZhan")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.buynum >0 then
            if self.totalprice > GameScene.roleinfo.gold then
                shortGold()
            else
                UIRequest({type = 301,cid = self.data.id, count = self.buynum, gold = self.totalprice})
                gameWindows:closeWindowDirect("daoGuanTiaoZhan")
            end
        else
            -- runGamePrompt({msg = "请选择数量"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","ch_num")})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    -- self:reload(data,callback)

    return self.rootNode
end


function daoGuanTiaoZhan.reload(self,data,callback)
    self.callback = callback
end

function daoGuanTiaoZhan.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.needeffect = nil

    if self.callback then
        self.callback()
    end
    self.buynum = 0
    self.totalprice = 0
end

return daoGuanTiaoZhan