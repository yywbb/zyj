--
-- Created by IntelliJ IDEA.
-- User: lipurpose
-- Date: 2/4/2018
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local accRecharge = {
    rootNode = nil,
    rootItems = nil,
}

function accRecharge.open(self,touchPriority,data,callback)
    print("accRecharge.open===")
    self.rootNode, self.rootItems = CCBReaderLoad("recharge/window_foreverrecharge", nil, true, "window_foreverrecharge")
    self:initFixedString()
    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function accRecharge.reload(self,data,callback)
    self.callback = callback
    printT(data,"foreverrechargedata   ---  ")
    local rechargeData = data or {totalRmb = 1000,id = 1,status = 0}  --后面数据为测试数据
    local index = rechargeData.id or 1
    local accRecCfg = gamedata.config.lifelong_recharge or {["1"] = {file = 31,reward = "20390,2;23102,1;26302,1;"}, 
    ["2"] = {file = 1117,reward = "91002,30;20099,3000;20017,200;33024,1;"} }
    
    local currentCfg = accRecCfg[tostring(index)]
    if currentCfg then
        local needMoney = currentCfg.file < rechargeData.totalRmb and 0 or currentCfg.file - rechargeData.totalRmb
        --self.rootItems.needNum:setString(needMoney)
        self.rootItems.neednode:removeAllChildrenWithCleanup(true)
        ui.createRichLabel({
                {fontID = 0,content = "yongjiuleichongzi2.png"},
                {fontID = 60,content = needMoney},
                {fontID = 0,content = "yongjiuleichongzi3.png"},
            },self.rootItems.neednode,false)

        local rewardData = ui.getIDandNUMs(currentCfg.reward)
        for i = 1,#rewardData do
            self.rootItems["reward"..i]:setVisible(true)
            ui.setNewIconName(self.rootItems,rewardData[i],i - 1)

            local k_add = (i - 1 == 0) and "" or "_"..(i-1)
            self.rootItems["i_button"..k_add]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(rewardData[i].cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..k_add]:setTouchPriority(self.touchPriority)
        end
        for i = #rewardData + 1,4 do
            self.rootItems["reward"..i]:setVisible(false)
            --ui.setNewIconName(self.rootItems,{},i - 1)
        end
    else
        for i = 1,4 do
            self.rootItems["reward"..i]:setVisible(false)
            --ui.setNewIconName(self.rootItems,{},i - 1)
        end
    end

    self.rootItems.rechargeNum:setString(rechargeData.totalRmb.."元")
    if rechargeData.status == 0 then
        self.rootItems.getNode:setVisible(false)
    else
        self.rootItems.getNode:setVisible(true)
    end
    

    self.rootItems.chargeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("accRecharge")
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)
    self.rootItems.chargeBtn:setSwallowsTouch(true)
    self.rootItems.chargeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("accRecharge")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    
    self.rootItems.getBtn:addHandleOfControlEvent(function()
        if rechargeData.status== 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("recharge",13)})
        elseif rechargeData.status== 1 then
            UIRequest({type = 5320})
        else
            runGamePrompt({msg = gameConfig.strings:string_common("nightclub",12)})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.getBtn:setSwallowsTouch(true)
    self.rootItems.getBtn:setTouchPriority(self.touchPriority)
    
end

function accRecharge.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

function accRecharge.initFixedString(self)
    self.rootItems.leijiRe:setString(gameConfig.strings:string_common("recharge",14))
end

return accRecharge

