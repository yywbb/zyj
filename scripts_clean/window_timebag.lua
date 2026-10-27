--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local timebag = {
    rootNode = nil,
    rootItems = nil,

    bagData = nil,

    createdItems = {},
    sid = 1,
    maxsid = 0,

    isContentScroll = false,
    touchX = 0,
    contentoffsetx = 0,

    needcallback = true,
}

function timebag.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("MainScene/timebagroot", nil, true, "cdk")

    self.touchPriority = touchPriority

    ui.setLabelString(self.rootItems.desc,"礼包",18)
    ui.setLabelString(self.rootItems.desc2,"在此页面充值可获得",18)
    ui.setLabelString(self.rootItems.desc3,"若充值成功后礼包无法领取请尝试重新登录",14)

    local function ccTouchBegan(x, y)
        self.isContentScroll = false
        self.touchX = x
        self.contentoffsetx = self.rootItems.pagenode:getPositionX()
        return true
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end

        if math.abs(x - self.touchX) > 30 then
            local offsetX = self.contentoffsetx + (x - self.touchX)
            self.rootItems.pagenode:setPositionX(offsetX)
        end
    end

    local function ccTouchEnded(x, y)
        if self.touchX - x > 20 then
            if self.sid+1 <= self.maxsid then
                self:reload(self.sid+1)
            else
                self:reload(self.sid)
            end
        elseif self.touchX - x < -20 then
            if self.sid-1 >0 then
                self:reload(self.sid-1)
            else
                self:reload(self.sid)
            end
        else
            --self:reload(self.sid)
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority, true)
    self.rootItems.touchLayer:setTouchPriority(self.touchPriority)
    self.rootItems.touchLayer:setTouchEnabled(true)

    self:reloadData(data,callback)

    return self.rootNode
end

function timebag.reloadData(self,data,callback)
    self.callback = callback 

    for k,v in pairs(self.createdItems) do
        self:removePage(k)
    end

    self.bagData =  data.timebag
    self.maxsid = table.getTableLength(self.bagData)  

    print("timebagreloadData",self.maxsid)  

    if self.maxsid<=0 then 
        gameWindows:closeWindowDirect("timebag")
    end

    if not self.rootItems then return end 

    if data.showcid and data.showcid>0 then
        for k,v in pairs(self.bagData) do
            if v.cid==data.showcid then
                self.sid = tonumber(k)
                break
            end
        end
    end

    self:reload(self.sid,true)

end

function timebag.reload( self,sid,isfirst )
    if sid > self.maxsid then
        sid = self.maxsid
    end
    self.sid = sid

    if self.rootItems then
        if isfirst then
            self.rootItems.pagenode:setPosition(ccp(-1080*(self.sid-1)+500, 600))
            self:loadPages()
        else
            local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.sid-1)+500, 600))
            self.rootItems.pagenode:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
                self:loadPages()
            end)))
        end
    end

    self.rootItems.pageidx:setString(self.sid.."/"..self.maxsid)

    self.rootItems.leftnode:setVisible(self.sid>1)
    self.rootItems.rightnode:setVisible(self.sid<self.maxsid)

    self.rootItems.leftbutton:addHandleOfControlEvent(function()
        if self.sid>1 then
            self:reload(self.sid-1)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.leftbutton:setSwallowsTouch(true)
    self.rootItems.leftbutton:setTouchPriority(self.touchPriority-1)

    self.rootItems.rightbutton:addHandleOfControlEvent(function()
        if self.sid<self.maxsid then
            self:reload(self.sid+1)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.rightbutton:setSwallowsTouch(true)
    self.rootItems.rightbutton:setTouchPriority(self.touchPriority-1)

end

function timebag.loadPages(self)
    self:loadPage(self.sid)
    self:loadPage(self.sid+1)
    self:loadPage(self.sid-1)
end

function timebag.loadPage(self,sid)
    if sid >=1 and sid<= self.maxsid then
        local CCB,ccbDoc
        if not self.createdItems[sid] then
            CCB, ccbDoc = CCBReaderLoad("MainScene/yiduixianshilibao.ccbi", nil, true, "yiduixianshilibao")
            CCB:setPosition(1080*(sid-1),0)
            self.rootItems.pagenode:addChild(CCB)
            self.createdItems[sid] = {ccb = CCB,item = ccbDoc}
        else
            CCB,ccbDoc = self.createdItems[sid].ccb,self.createdItems[sid].item
        end
        self.createdItems[sid].datacid = self.bagData[tostring(sid)].cid
        self:setOne(ccbDoc,self.bagData[tostring(sid)])        
    end
end

function timebag.removePage(self,sid)
    if self.createdItems[sid] then
        self.createdItems[sid].ccb:removeAllChildrenWithCleanup(true)
        self.createdItems[sid].ccb:removeFromParentAndCleanup(true)
        gameTimer:UnrigistTime("timebag_"..self.createdItems[sid].datacid)
        gameTimer:UnrigistTimeFunc("timebag_"..self.createdItems[sid].datacid)          
        self.createdItems[sid] = nil
    end
end

function timebag.setOne( self,item,data )
    local config = gamedata.config.trigger_gift2[tostring(data.cid)]

    ui.setLabelString(item.timedes,"限时倒计时:",14)

    item.timenode:setVisible(data.status==0)

    setSpriteFrameByName(item.bg, config.icon or "")

    if data.status == 0 then
        local now = gamedata:time()
        if data.time - (now - data.recivetime) > 0 then
            gameTimer:rigistTime("timebag_"..data.cid, data.time - (now - data.recivetime))
        end
    end

    if gameTimer.times["timebag_"..data.cid] and gameTimer.times["timebag_"..data.cid] > 0 then
        gameTimer:rigistTimeFunc("timebag_"..data.cid,function()
            if gameTimer.times["timebag_"..data.cid] > 0 then
                if item and item.time then
                    ui.setLabelString(item.time,ui.makeTimeText(gameTimer.times["timebag_"..data.cid],"hour"),23)
                end
            else
                if item and item.time then
                    ui.setLabelString(item.time,"00:00:00",23)
                end
                gameTimer:UnrigistTime("timebag_"..data.cid)
                gameTimer:UnrigistTimeFunc("timebag_"..data.cid)
                UIRequest({type = 28801, id = data.cid})
            end
        end)
    else
        ui.setLabelString(item.time,"00:00:00",23)
    end

    local rewards = ui.getIDandNUMs(config.gift_id)
    local rewardnum = #rewards
    local maxw = 760*(0.4+rewardnum*0.15)
    local statx = 120+760*(1-(0.4+rewardnum*0.15))/2
    for i=1,4 do
        local reward = rewards[i]
        if reward then
            ui.setNewIconName(item,reward,i-1)
            item["reward"..i]:setPositionX(statx+(maxw/rewardnum)*(i-0.5))
            local key_Ex = i-1>0 and "_"..(i-1) or ""
            item["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(reward.cid)
            end, CCControlEventTouchUpInside)
            item["i_button"..key_Ex]:setTouchPriority(self.touchPriority-1)
        else
            item["reward"..i]:setVisible(false)
        end
    end


    item.buyButton:setSwallowsTouch(true)
    item.buyButton:setTouchPriority(self.touchPriority-1)

    if data.status==0 then
        local rechargeconfig = gamedata.config.recharge[tostring(config.recharge_id)]
        ui.setLabelString(item.buyLab,rechargeconfig.rmb.."元",18)
        item.buyButton:addHandleOfControlEvent(function()
            --
            if gameConfig:checkBuildOpen(364) and gamedata.sdk.idCardStatus then 
                if gamedata.sdk.idCardStatus==0 then
                    gameWindows:openWindow("shiming",{page = "renzheng"})
                    return
                elseif gamedata.sdk.idCardStatus==1 then
                    gameWindows:openWindow("shiming",{page = "tishi2"})
                    return
                end
            end
            --
            UIRequest({type = 115,cid = rechargeconfig.id,bagid=config.id})
        end, CCControlEventTouchUpInside)
    elseif data.status==1 then
        ui.setLabelString(item.buyLab,gameConfig.strings:string_common("buttontext","lingqu"),18)
        item.buyButton:addHandleOfControlEvent(function()
            UIRequest({type = 2881,id=data.cid})
        end, CCControlEventTouchUpInside)
    end

    item.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("timebag")
    end, CCControlEventTouchUpInside)
    item.closeButton:setSwallowsTouch(true)
    item.closeButton:setTouchPriority(self.touchPriority-1)

end

function timebag.close(self)

    for k,v in pairs(self.createdItems) do
        self:removePage(k)
    end
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return timebag

