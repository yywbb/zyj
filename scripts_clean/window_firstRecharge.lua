--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local firstrecharge = {
    rootNode = nil,
    rootItems = nil,
}

function firstrecharge.open(self,touchPriority,data,callback)
    print("firstrecharge.open===")
    self.rootNode, self.rootItems = CCBReaderLoad("recharge/window_firstrecharge2", nil, true, "window_firstrecharge")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function firstrecharge.reload(self,data,callback)
    self.callback = callback


    local firstconfig = gamedata.config.firstpay[tostring(1)]

    ui.setNewIconName(self.rootItems,{cid = firstconfig["goods1"], num = (firstconfig["goods1coefficient"]),})
    local idnums = {}
    for i=1,3 do
        if firstconfig["goods"..(i+1)] and firstconfig["goods"..(i+1).."num"] then
            table.insert( idnums, {cid = firstconfig["goods"..(i+1)], num = firstconfig["goods"..(i+1).."num"]} )
        end
    end

    -- ui.setNewIconName(self.rootItems,{cid = 1001, num = gameConfig.strings:string_common("popups","sanbei"),})

    -- local idnums = ui.getIDandNUMs(gamedata.config.props["20127"].param1)
    print("idnums====")
    printT(idnums)
    for i=1,3 do
        if not next(idnums[i]) then
            break
        end
        ui.setNewIconName(self.rootItems,{cid = idnums[i].cid, num = idnums[i].num},i)
        --
        local config = ui.IDconfig(idnums[i].cid)
        self.rootItems["i_button_"..i]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(idnums[i].cid)
        end, CCControlEventTouchUpInside)
        self.rootItems["i_button_"..i]:setTouchPriority(self.touchPriority)
        --
    end
    --

    if GameScene.vip.firststatus== 0 then
        
        print("firststatus==0")
        self.rootItems.chargeNode:setVisible(true)
        self.rootItems.buyNode:setVisible(false)
        self.rootItems.chargeNode:setPositionX(540)
        self.rootItems.buyNode:setPositionX(9999)


        -- ui.addGray("CCControlButton",self.rootItems.buybutton)
        -- ui.addGray("CCLabelBMFont",self.rootItems.bytext)
    else
        print("firststatus==1")
        self.rootItems.chargeNode:setVisible(false)
        self.rootItems.buyNode:setVisible(true)
        self.rootItems.chargeNode:setPositionX(9999)
        self.rootItems.buyNode:setPositionX(540)

        -- ui.removeGray("CCControlButton",self.rootItems.buybutton)
        -- ui.removeGray("CCLabelBMFont",self.rootItems.bytext)
    end

    self.rootItems.buybutton:addHandleOfControlEvent(function()
        if not GameScene.vip or not GameScene.vip.firststatus then
        elseif GameScene.vip.firststatus== 0 then
            -- runGamePrompt({msg = "尚未充值"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","shangcz")})
        else
            gameWindows:closeWindowDirect("firstrecharge")
            UIRequest({type = 2098})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.buybutton:setSwallowsTouch(true)
    self.rootItems.buybutton:setTouchPriority(self.touchPriority)

    self.rootItems.chargebutton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("firstrecharge")
        --GameScene:shiftLayer("recharge","up")
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)
    self.rootItems.chargebutton:setSwallowsTouch(true)
    self.rootItems.chargebutton:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("firstrecharge")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    if GameScene.vip and GameScene.vip.firststatus and GameScene.vip.firststatus == 2 then
        runGamePrompt({msg = "首充奖励已领取"})
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.1),CCCallFunc:create(function()
            gameWindows:closeWindowDirect("firstrecharge")
        end)))
    end
end

function firstrecharge.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return firstrecharge

