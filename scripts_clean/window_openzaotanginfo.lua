--
-- Created by IntelliJ IDEA.
-- User: dhope
-- Date: 19/11/8
-- Time: 上午10:58
--

local openzaotanginfo = {
    rootNode = nil,
    rootItems = nil,
    needProp = {},
    gangData = nil
}

function openzaotanginfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui3/tc_zaotangselect", nil, true, "tc_zaotangselect")
    self.show = true
    self.touchPriority = touchPriority
    if data and data.gang then
        self.gangData = data.gang
    end

    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
        ui.popCommonRule(571)
    end, CCControlEventTouchUpInside)
    self.rootItems.ruleBtn:setSwallowsTouch(true)
    self.rootItems.ruleBtn:setTouchPriority(self.touchPriority)

    self:reload()
    UIRequest({type = 2281})
    UIRequest({type = 10321,notupdate = 1,ids = {122}})  
    return self.rootNode
end


function openzaotanginfo.reload(self,data)
    self.callback = callback
    self.data = data

    local configData = gamedata.config.gang2_bath_award
    local configTypeData = gamedata.config.gang2_bath_type

    self.config = configData[tostring(self.gangData.level)]
    -- print("self.config=="..GameScene.roleinfo.level)
    -- printT(self.config)

    if data then
        local alltimes = gamedata.config.global_kv["gang2_bath_partake"].value
        local curtimes = alltimes - data.openCount
        ui.setLabelString(self.rootItems.openTimes,curtimes.."次",1015,34)
        --参与次数
        -- local alljointimes = gamedata.config.global_kv["gang2_bath_start"].value
        -- local curtimes = alljointimes - data.joinCount
        -- ui.setLabelString(self.rootItems.joinTimes,curtimes.."次",1015,34)

        if data.normalRoom then
            if data.normalRoom.roomTime > 0 then
                self.rootItems.xiaohaoNode1:setVisible(false)
                self.rootItems.normalbtn_lab:setString("加 入")
                setControlButtonFrame(self.rootItems.normal_btn,"b_n_button1","b_n_button1","b_n_button1")
                self.rootItems.normalFeastSprite:setVisible(true)
                self.rootItems.joinNum1:setVisible(true)
                ui.setLabelString(self.rootItems.normalFeastTime,ui.makeTimeText(data.normalRoom.roomTime,"minute"),989)
                ui.setLabelString(self.rootItems.normalFeastLabel,"剩余时间",1015,34)
                ui.setLabelString(self.rootItems.joinNum1,"出席人数"..data.normalRoom.roomPersonNum.."/"..configTypeData["1"].number,1015,34)
                gameTimer:rigistTime("normalbathtime",data.normalRoom.roomTime)
                gameTimer:rigistTimeFunc("normalbathtime",function()
                    if  gameTimer.times["normalbathtime"] ~= 0 then
                        ui.setLabelString(self.rootItems.normalFeastTime,ui.makeTimeText(gameTimer.times["normalbathtime"],"minute"),989)
                    else
                        setControlButtonFrame(self.rootItems.normal_btn,"b_n_button2","b_n_button2","b_n_button2")
                        ui.setLabelString(self.rootItems.normalFeastTime,ui.makeTimeText(configTypeData["1"].time,"minute"),1015,34)
                        ui.setLabelString(self.rootItems.normalFeastLabel,"持续时间",1015,34)
                        self.rootItems.normalFeastSprite:setVisible(false)
                        self.rootItems.joinNum3:setVisible(false)
                        self.rootItems.normalbtn_lab:setString("举 办")
                        self.rootItems.xiaohaoNode2:setVisible(true)
                    end
                end)
            else
                ui.setLabelString(self.rootItems.normalFeastTime,ui.makeTimeText(configTypeData["1"].time,"minute"),1015,34)
                ui.setLabelString(self.rootItems.normalFeastLabel,"持续时间",1015,34)
                self.rootItems.normalFeastSprite:setVisible(false)
                self.rootItems.joinNum3:setVisible(false)
                self.rootItems.normalbtn_lab:setString("举 办")
                self.rootItems.xiaohaoNode2:setVisible(true)
            end
        end

        if data.highRoom then
            if data.highRoom.roomTime > 0 then
                self.rootItems.xiaohaoNode2:setVisible(false)
                self.rootItems.highbtn_lab:setString("加 入")
                setControlButtonFrame(self.rootItems.high_btn,"b_n_button1","b_n_button1","b_n_button1")
                self.rootItems.highFeastSprite:setVisible(true)
                self.rootItems.joinNum2:setVisible(true)
                ui.setLabelString(self.rootItems.highFeastTime,ui.makeTimeText(data.highRoom.roomTime,"minute"),989)
                ui.setLabelString(self.rootItems.highFeastLabel,"剩余时间",1015,34)
                ui.setLabelString(self.rootItems.joinNum2,"出席人数"..data.highRoom.roomPersonNum.."/"..configTypeData["2"].number,1015,34)
                gameTimer:rigistTime("highbathtime",data.highRoom.roomTime)
                gameTimer:rigistTimeFunc("highbathtime",function()
                    if  gameTimer.times["highbathtime"] ~= 0 then
                        ui.setLabelString(self.rootItems.highFeastTime,ui.makeTimeText(gameTimer.times["highbathtime"],"minute"),989)
                    else
                        setControlButtonFrame(self.rootItems.high_btn,"b_n_button2","b_n_button2","b_n_button2")
                        ui.setLabelString(self.rootItems.highFeastTime,ui.makeTimeText(configTypeData["2"].time,"minute"),1015,34)
                        ui.setLabelString(self.rootItems.highFeastLabel,"持续时间",1015,34)
                        self.rootItems.highFeastSprite:setVisible(false)
                        self.rootItems.joinNum2:setVisible(false)
                        self.rootItems.highbtn_lab:setString("举 办")
                        self.rootItems.xiaohaoNode2:setVisible(true)
                    end
                end)
            else
                ui.setLabelString(self.rootItems.highFeastTime,ui.makeTimeText(configTypeData["2"].time,"minute"),1015,34)
                ui.setLabelString(self.rootItems.highFeastLabel,"持续时间",1015,34)
                self.rootItems.highFeastSprite:setVisible(false)
                self.rootItems.joinNum2:setVisible(false)
                self.rootItems.highbtn_lab:setString("举 办")
                self.rootItems.xiaohaoNode2:setVisible(true)
            end
        end

        if data.superRoom then
            if data.superRoom.roomTime > 0 then
                self.rootItems.xiaohaoNode3:setVisible(false)
                self.rootItems.superbtn_lab:setString("加 入")
                setControlButtonFrame(self.rootItems.super_btn,"b_n_button1","b_n_button1","b_n_button1")
                self.rootItems.superFeastTime:setVisible(true)
                self.rootItems.superFeastSprite:setVisible(true)
                self.rootItems.joinNum3:setVisible(true)
                ui.setLabelString(self.rootItems.superFeastTime,ui.makeTimeText(data.superRoom.roomTime,"minute"),989)
                ui.setLabelString(self.rootItems.superFeastLabel,"剩余时间",1015,34)
                ui.setLabelString(self.rootItems.joinNum3,"出席人数"..data.superRoom.roomPersonNum.."/"..configTypeData["3"].number,1015,34)
                gameTimer:rigistTime("superbathtime",data.superRoom.roomTime)
                gameTimer:rigistTimeFunc("superbathtime",function()
                    if  gameTimer.times["superbathtime"] ~= 0 then
                        ui.setLabelString(self.rootItems.superFeastTime,ui.makeTimeText(gameTimer.times["superbathtime"],"minute"),989)
                    else
                        setControlButtonFrame(self.rootItems.super_btn,"b_n_button2","b_n_button2","b_n_button2")
                        ui.setLabelString(self.rootItems.superFeastTime,ui.makeTimeText(configTypeData["3"].time,"minute"),1015,34)
                        ui.setLabelString(self.rootItems.superFeastLabel,"持续时间",1015,34)
                        self.rootItems.superbtn_lab:setString("举 办")
                        self.rootItems.superFeastSprite:setVisible(false)
                        self.rootItems.joinNum3:setVisible(false)
                        self.rootItems.xiaohaoNode3:setVisible(true)
                    end
                end)
            else
                ui.setLabelString(self.rootItems.superFeastTime,ui.makeTimeText(configTypeData["3"].time,"minute"),1015,34)
                ui.setLabelString(self.rootItems.superFeastLabel,"持续时间",1015,34)
                self.rootItems.superbtn_lab:setString("举 办")
                self.rootItems.superFeastSprite:setVisible(false)
                self.rootItems.joinNum3:setVisible(false)
                self.rootItems.xiaohaoNode3:setVisible(true)
            end
        end
    end

    ui.setLabelString(self.rootItems.normalbtn_lab,nil,18) 
    ui.setLabelString(self.rootItems.highbtn_lab,nil,18) 
    ui.setLabelString(self.rootItems.superbtn_lab,nil,18) 
    
    --低
    local awardArr = ui.getIDandNUMs(self.config["1"].award)
    local icondata = ui.IDconfig(awardArr[1].cid)
    local totalReward = configTypeData["1"].time * awardArr[1].num
    setSpriteFrameByName(self.rootItems.normalDropIcon1,icondata.icon..".png")
    ui.setLabelString(self.rootItems.normalProfit1,"公会经验获得收益"..totalReward,1015,29)
    icondata = ui.IDconfig(awardArr[2].cid)
    totalReward = configTypeData["3"].time * awardArr[2].num
    setSpriteFrameByName(self.rootItems.normalDropIcon2,icondata.icon..".png")
    ui.setLabelString(self.rootItems.normalProfit2,"个人贡献获得收益"..totalReward,1015,29)
    local awardArr1 = ui.getIDandNUMs(configTypeData["1"].props)
    icondata = ui.IDconfig(awardArr1[1].cid)
    setSpriteFrameByName(self.rootItems.xiaohaoIconNormal,icondata.icon..".png")
    ui.setLabelString(self.rootItems.normalNum,"X"..awardArr1[1].num,13)
    --中
    awardArr = ui.getIDandNUMs(self.config["2"].award)
    icondata = ui.IDconfig(awardArr[1].cid)
    totalReward = configTypeData["2"].time * awardArr[1].num
    setSpriteFrameByName(self.rootItems.highDropIcon1,icondata.icon..".png")
    ui.setLabelString(self.rootItems.highProfit1,"公会经验获得收益"..totalReward,1015,29)
    icondata = ui.IDconfig(awardArr[2].cid)
    totalReward = configTypeData["2"].time * awardArr[2].num
    setSpriteFrameByName(self.rootItems.highDropIcon2,icondata.icon..".png")
    ui.setLabelString(self.rootItems.highProfit2,"个人贡献获得收益"..totalReward,1015,29)
    local awardArr2 = ui.getIDandNUMs(configTypeData["2"].props)
    icondata = ui.IDconfig(awardArr2[1].cid)
    setSpriteFrameByName(self.rootItems.xiaohaoIconHigh,icondata.icon..".png")
    ui.setLabelString(self.rootItems.highNum,"X"..awardArr2[1].num,13)
    --高
    awardArr = ui.getIDandNUMs(self.config["3"].award)
    icondata = ui.IDconfig(awardArr[1].cid)
    totalReward = configTypeData["3"].time * awardArr[1].num
    setSpriteFrameByName(self.rootItems.superDropIcon1,icondata.icon..".png")
    ui.setLabelString(self.rootItems.superProfit1,"公会经验获得收益"..totalReward,1015,29)
    icondata = ui.IDconfig(awardArr[2].cid)
    totalReward = configTypeData["3"].time * awardArr[2].num
    setSpriteFrameByName(self.rootItems.superDropIcon2,icondata.icon..".png")
    ui.setLabelString(self.rootItems.superProfit2,"个人贡献获得收益"..totalReward,1015,29)
    local awardArr3 = ui.getIDandNUMs(configTypeData["3"].props)
    icondata = ui.IDconfig(awardArr3[1].cid)
    setSpriteFrameByName(self.rootItems.xiaohaoIconSuper,icondata.icon..".png")

    ui.setLabelString(self.rootItems.superNum,"X"..awardArr3[1].num,13)

    UIRequest({type = 12001, order = 50001, cids = {awardArr1[1].cid,awardArr2[1].cid,awardArr3[1].cid}})

    self.rootItems.normal_btn:addHandleOfControlEvent(function()
        if self.data then
            self:joinFeastControl(self.data.normalRoom,1,awardArr1[1])
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.normal_btn:setSwallowsTouch(true)
    self.rootItems.normal_btn:setTouchPriority(self.touchPriority)

    self.rootItems.high_btn:addHandleOfControlEvent(function()
        if self.data then
            self:joinFeastControl(self.data.highRoom,2,awardArr2[1])
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.high_btn:setSwallowsTouch(true)
    self.rootItems.high_btn:setTouchPriority(self.touchPriority)

    self.rootItems.super_btn:addHandleOfControlEvent(function()
        if self.data then
            self:joinFeastControl(self.data.superRoom,3,awardArr3[1])
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.super_btn:setSwallowsTouch(true)
    self.rootItems.super_btn:setTouchPriority(self.touchPriority)
end

function openzaotanginfo.joinFeastControl(self,roomData,roomid,propinfo)
    local configTypeData = gamedata.config.gang2_bath_type
    --消耗物品
    local awardArr = ui.getIDandNUMs(configTypeData[tostring(roomid)].props)
                
    local alltimes = gamedata.config.global_kv["gang2_bath_partake"].value
    --参与次数
    local alljointimes = gamedata.config.global_kv["gang2_bath_start"].value
    local curtimes = alltimes - self.data.openCount
    -- local jointimes = alljointimes - self.data.joinCount
    if roomData.roomStatus == 0 then
        if curtimes == 0 then
            runGamePrompt({msg = "开启次数不足"})
            return
        end
        if self.needProp[tostring(propinfo.cid)] and self.needProp[tostring(propinfo.cid)] >= propinfo.num then
            UIRequest({type = 2282, roomid = roomid, controltype = 2, useProp = awardArr[1]})
        elseif  self.needProp[tostring(propinfo.cid)] then

            local useProp = awardArr[1]
            useProp.num = self.needProp[tostring(propinfo.cid)]

            local callback = function(gold)
                UIRequest({type = 2282, roomid = roomid, controltype = 2, useProp = useProp,gold = gold })
            end
            local data = {}
            data.prop = {{cid = propinfo.cid, num = propinfo.num - self.needProp[tostring(propinfo.cid)]}}
            data.msg = "举办公会篝火"
            gameWindows:openWindow("price_props",data,callback)   
        else
            runGamePrompt({msg = "道具不足"})
        end
    else
        -- if jointimes > 0 then
            -- GameScene:shiftLayer("guildfeast","up",{roomid = roomid, roomstatus = 1})
            if roomData.roomPersonNum >= configTypeData[tostring(roomid)].number then
                runGamePrompt({msg = "参与人数已达上限"})
            else
                UIRequest({type = 2282, roomid = roomid, controltype = 1})
            end
        -- else
        --     runGamePrompt({msg = "参与次数不足"})
        -- end
    end
end

function openzaotanginfo.setpropNum(self,data)
    self.needProp = data
end

function openzaotanginfo.close(self)
    gameTimer:UnrigistTime("normalbathtime")
    gameTimer:UnrigistTimeFunc("normalbathtime")
    gameTimer:UnrigistTime("highbathtime")
    gameTimer:UnrigistTimeFunc("highbathtime")
    gameTimer:UnrigistTime("superbathtime")
    gameTimer:UnrigistTimeFunc("superbathtime")
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.show = false
    if self.callback then
        self.callback()
    end
end

return openzaotanginfo
