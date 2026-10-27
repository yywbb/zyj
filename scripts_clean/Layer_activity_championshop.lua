--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:09
-- To change this template use File | Settings | File Templates.
--

local activity_championshop = {
    isscrolltouched = false,
    buttontouch = -103,
    data = {},
}

function activity_championshop.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("chamipon/chamipon_shop",nil, true, "champion_shop")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)

    self.coveritems.scrollnode = tolua.cast(self.coveritems.scrollnode, "CCScrollView")
    self.coveritems.scrollnode:setTouchPriority(self.buttontouch)
    -- self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    self.coveritems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))

    self.coveritems.container:setContentSize(CCSize(1080,1000))

    self.scrollNode, self.scrollItems = CCBReaderLoad("chamipon/shopmap", nil, true, "shopmap")
    self.scrollNode:setPosition(0,0)
    self.scrollNode:setVisible(false)
    self.coveritems.container:addChild(self.scrollNode)

    self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,self.contentsize.y-520-462 - 1000),0)

    self.coveritems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,self.contentsize.y-520-462))

    -- ui.setLabelString(self.coveritems.pointLab,nil,150)
    -- ui.setLabelString(self.coveritems.refreshTxt, nil, 14)


    ui.setLabelString(self.coveritems.gotoLab,nil,18)
    self.coveritems.gotoButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)
        GameScene:shiftLayerById(179)
    end, CCControlEventTouchUpInside)
    self.coveritems.gotoButton:setSwallowsTouch(true)
    self.coveritems.gotoButton:setTouchPriority(self.buttontouch)


    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","activity_championshop",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.scrollnode_touch and ui.isTouched(self.coveritems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","activity_championshop",touchend)
    --

    return self.coverccb
end



function activity_championshop.setone(self,item,id)
    local key_Ex
    if id == nil or id == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(id-1)
    end

    local configdata = gamedata.config.champion_goods[tostring(self.data.itemsdata[tostring(id)].id)]

    if not configdata then
        return
    end

    local spenddata = ui.getIDandNUMs(configdata.consume)
    local gooddata = ui.getIDandNUMs(configdata.good)

    if tonumber(spenddata[1]["cid"]) == 1001 then
        item["goldNode"..key_Ex]:setVisible(true)
        item["pointNode"..key_Ex]:setVisible(false)
        ui.setLabelString(item["buttontext"..key_Ex],gameConfig.strings:string_common("buttontext","goumai"),18)
    else
        item["pointNode"..key_Ex]:setVisible(true)
        item["goldNode"..key_Ex]:setVisible(false)
        ui.setLabelString(item["buttontext"..key_Ex],gameConfig.strings:string_common("buttontext","duihuan"),18)
    end

    ui.setNewIconName(item,{cid = gooddata[1].cid, num = gooddata[1].num},id-1)
    item["i_button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        local propConfig = ui.IDconfig(gooddata[1].cid)
        if propConfig.staffType == "token_fragment" then
            ui.setPopwindowByCid(gooddata[1].cid,{cid = gooddata[1].cid})
        else
            ui.setPopwindowByCid(gooddata[1].cid)
        end
    end, CCControlEventTouchUpInside)
    item["i_button"..key_Ex]:setTouchPriority(self.buttontouch)

    local aaa = configdata.limit
    local bbb = self.data.itemsdata[tostring(id)].num

    if configdata.recommend and configdata.recommend == 1 then  -- 显示推荐
        item["hotnode" .. key_Ex]:setVisible(true)
    else
        item["hotnode" .. key_Ex]:setVisible(false)
    end
    item["battleNode" .. key_Ex]:setVisible(false)

    -- ui.setLabelString(item["buyNumText"..key_Ex],nil,14)
    -- ui.setLabelString(item["buyNumLabel"..key_Ex],configdata.limit-self.data.itemsdata[tostring(id)].num,14)
    item["buyNumLabel"..key_Ex]:setString(configdata.limit-self.data.itemsdata[tostring(id)].num)
    ui.setLabelString(item["gold"..key_Ex],spenddata[1]["num"],14)


    if self.data.itemsdata[tostring(id)].num < configdata.limit then
        item["soldoutNode"..key_Ex]:setVisible(false)
        ui.removeGray("CCControlButton",item["button"..key_Ex])
        ui.removeGray("CCLabelTTF",item["buttontext"..key_Ex])

        item["button"..key_Ex]:setTouchPriority(self.buttontouch)
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            --UIRequest({type = 2711,id = id,goodid = self.data.itemsdata[tostring(id)].id})

            function shopExchangeRequest(num)
                UIRequest({type = 2711, id = id,goodid = self.data.itemsdata[tostring(id)].id,num = num})            
            end
            local exchangeNum = configdata.limit-self.data.itemsdata[tostring(id)].num
            if exchangeNum > 5 then
                gameWindows:openWindow("shopExchange",{cid = gooddata[1].cid,num = gooddata[1].num,cost = spenddata,exchangeNum = exchangeNum},shopExchangeRequest)
            else
                UIRequest({type = 2711, id = id,goodid = self.data.itemsdata[tostring(id)].id,num = 1}) 
            end    
        end, CCControlEventTouchUpInside)
    else
        item["soldoutNode"..key_Ex]:setVisible(true)
        ui.addGray("CCControlButton",item["button"..key_Ex])
        ui.addGray("CCLabelTTF",item["buttontext"..key_Ex])

        item["button"..key_Ex]:setTouchPriority(self.buttontouch)
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","yigoumai")})
        end, CCControlEventTouchUpInside)
    end
end

function activity_championshop.reloadData(self,data)

    if not self.show then return end
    self.data = data.data
    if not self.data.championpoint then return end

    self.scrollNode:setVisible(true)

    -- ui.setLabelString(self.coveritems.pointNum,self.data.championpoint or 0,14)
    self.coveritems.pointNum:setString(self.data.championpoint or 0)
    --
    self:updatetimeFunc()
    --
    --todo
    local costid,costnum = ui.getIDandNUM(gamedata.config.global_kv.champion_refreshgold.value)
    local xgold = costnum or 0
    self.coveritems.resetgoldnode:setVisible(false)
--    local tempconfig = gamedata.config.buycount_price
--    local resetnum = data.data.resetnum
--    if resetnum > 59 then
--        resetnum = 59
--    end
--    if tempconfig[tostring(resetnum+1)] and tempconfig[tostring(resetnum+1)].champion_refreshgold then
--        xgold = tempconfig[tostring(resetnum+1)].champion_refreshgold
--    end
    if xgold > 0 then
        self.coveritems.resetgoldnode:setVisible(true)
        -- ui.setLabelString(self.coveritems.resetgold,xgold,21)
        self.coveritems.resetgold:setString(xgold)
    end
    -- 刷新按钮
    self.coveritems.resetbutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        gameTouch:clickprofbytime(1)

        local refresh = self:refreshJudge()
        if not refresh then
            runGamePrompt({msg = "马上就要刷新了，请稍等一会儿"})
            return
        end

        if self.data.championpoint < xgold then
            runGamePrompt({msg = "试炼点不足"})
        else
            UIRequest({type = 2712, xgold = 0})   --已改为消耗试炼点，不消耗元宝
        end
    end, CCControlEventTouchUpInside)
    self.coveritems.resetbutton:setSwallowsTouch(true)
    self.coveritems.resetbutton:setTouchPriority(self.buttontouch-1)


    for i=1, 6 do
        self:setone(self.scrollItems,i)
    end
end

function activity_championshop.clear(self)

    gameTouch:UnrigistFunc("begin","activity_championshop")
    gameTouch:UnrigistFunc("end","activity_championshop")
    if gameTimer.times["championshop_reset"] then
        gameTimer:UnrigistTimeFunc("championshop_reset")
    end

    if self.coverccb then
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end

    if self.scrollNode then
        self.scrollNode = nil
        self.scrollItems = nil
    end
    self.data = {}
    self.show = false
end

function activity_championshop.updatetimeFunc(self)

    local refreshconfig = gamedata.config.champion_refresh or {}
    local refreshArr = {}

    for k,v in pairs(refreshconfig) do
        if v.hour == 0 then
            v.hour = 24
        end
        table.insert(refreshArr,tonumber(v.hour))
    end

    local sortfunction = function( a, b )
        return a < b
    end
    table.sort( refreshArr, sortfunction )

    local nowtime = os.date("*t", gamedata:time())

    local addtime = 0

    for i,v in ipairs(refreshArr) do
        if nowtime.hour < v then
            addtime = v
            break
        end
    end

    local remaintime = addtime*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec+2

    gameTimer:rigistTime("championshop_reset", remaintime)
    gameTimer:rigistTimeFunc("championshop_reset",function()
        if gameTimer.times["championshop_reset"] >= 0 then
            -- ui.setLabelString(self.coveritems.updatetime, ui.makeTimeText(gameTimer.times["championshop_reset"],"hour"), 136)
            self.coveritems.updatetime:setString(ui.makeTimeText(gameTimer.times["championshop_reset"],"hour"))
        end
        if gameTimer.times["championshop_reset"] == 0 then
            UIRequest({type = 2710, update = true})
            gameTimer:UnrigistTimeFunc("championshop_reset")
        end
    end)

end

function activity_championshop.refreshJudge(self)
    local refreshconfig = gamedata.config.champion_refresh or {}
    local nowtime = os.date("*t", gamedata:time())
    local refreshstatus = true
    for k,v in pairs(refreshconfig) do
        if (nowtime.hour+1) == v.hour and nowtime.min >= 57 then
            refreshstatus = false
            break
        elseif v.hour == 0 and nowtime.hour == 23  and nowtime.min >= 57 then
            refreshstatus = false
            break
        end
    end
    return refreshstatus
end

return activity_championshop