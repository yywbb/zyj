--

--

local gambling = {

    buttontouch = -103,
    animationManager = nil,
    animationManager1 = nil,
    animationManager2 = nil,
    animationManager3 = nil,
    showNode1 = nil,
    showNode2 = nil,
    showNode3 = nil,
    showItems1 = nil,
    showItems2 = nil,
    showItems3 = nil,

    costone = 0,
    costid = 1021,
    hasnum = 0,

    gambling = {},

    isten = false,

}

function gambling.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitylaohuji/laohuji",nil, true, "laohuji")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.midnode:setPositionY(self.contentsize.y/2)
    self.animationManager = getAnimationManager(self.coveritems)
    --
    local endString = ""
    if gamedata.config.activity_time["74"]["open_type"] and gamedata.config.activity_time["74"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = 0
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["74"]["continued_time"]+(gamedata.config.activity_time["74"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["74"]["continued_time"]+(gamedata.config.activity_time["74"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        local endtab = os.date("*t", timediff-1)
        --endString = endtab.year..gameConfig.strings:string_common("goddownrank",13)..endtab.month..gameConfig.strings:string_common("goddownrank",14)..endtab.day..gameConfig.strings:string_common("goddownrank",15)
        endString = endtab.month.."月"..endtab.day.."日24时"
    elseif gamedata.config.activity_time["74"]["end"] and gamedata.config.activity_time["74"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["74"]["end"])
        endString = year.."."..month.."."..day
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            --endString = endtab.year.."."..endtab.month.."."..endtab.day
            endString = endtab.month.."月"..endtab.day.."日24时"
        end
    end
    self.coveritems.activitytime:setString(endString)   --todo
    --
    self.showNode1,self.showItems1 = CCBReaderLoad("UIEffect/laohuji2/laohuji2_1", nil, true, "laohuji2_1")
    self.showNode1:setPosition(0,0)
    self.coveritems.shownode1:addChild(self.showNode1)
    self.coveritems.shownode1:setScale(1)
    self.animationManager1 = getAnimationManager(self.showItems1)
    self.animationManager1:runAnimationsForSequenceNamed("begin")
    --
    --
    self.showNode2,self.showItems2 = CCBReaderLoad("UIEffect/laohuji2/laohuji2_2", nil, true, "laohuji2_2")
    self.showNode2:setPosition(0,0)
    self.coveritems.shownode2:addChild(self.showNode2)
    self.coveritems.shownode2:setScale(1)
    self.animationManager2 = getAnimationManager(self.showItems2)
    self.animationManager2:runAnimationsForSequenceNamed("begin")
    --
    --
    self.showNode3,self.showItems3 = CCBReaderLoad("UIEffect/laohuji2/laohuji2_3", nil, true, "laohuji2_3")
    self.showNode3:setPosition(0,0)
    self.coveritems.shownode3:addChild(self.showNode3)
    self.coveritems.shownode3:setScale(1)
    self.animationManager3 = getAnimationManager(self.showItems3)
    self.animationManager3:runAnimationsForSequenceNamed("begin")
    --
    --说明  todo
    self.coveritems.ruleButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        print("ruleButton")
        gameWindows:openWindow("gamblingRule")
    end, CCControlEventTouchUpInside)
    self.coveritems.ruleButton:setSwallowsTouch(true)
    self.coveritems.ruleButton:setTouchPriority(self.buttontouch)

    --兑换  todo
    self.coveritems.shopButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        print("shopButton")
        GameScene:shiftLayerById(306)
    end, CCControlEventTouchUpInside)
    self.coveritems.shopButton:setSwallowsTouch(true)
    self.coveritems.shopButton:setTouchPriority(self.buttontouch)

    ui.setLabelString(self.coveritems.fixstring1, nil, 21)
    ui.setLabelString(self.coveritems.costLab, nil, 13)
    ui.setLabelString(self.coveritems.hasLab, nil, 13)
    ui.setLabelString(self.coveritems.tenLab, nil, 13)
    ui.setLabelString(self.coveritems.doLab, nil, 19)

    if gamedata.config.global_kv["game_consoles_consume"] and tonumber(gamedata.config.global_kv["game_consoles_consume"].value) then
        self.costid = 1021
        self.costone = gamedata.config.global_kv["game_consoles_consume"] and tonumber(gamedata.config.global_kv["game_consoles_consume"].value) or 0
    else
        self.costid,self.costone = ui.getIDandNUM(gamedata.config.global_kv["game_consoles_consume"].value)
    end    

    if self.coveritems.costicon1 and self.coveritems.costicon2 then
        setSpriteFrameByName(self.coveritems.costicon1, ui.IDconfig(self.costid) and ui.IDconfig(self.costid).icon or "alpha")
        setSpriteFrameByName(self.coveritems.costicon2, ui.IDconfig(self.costid) and ui.IDconfig(self.costid).icon or "alpha")
        --
        self.coveritems.costiconbtn1:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(self.costid)
        end, CCControlEventTouchUpInside)
        self.coveritems.costiconbtn1:setSwallowsTouch(true)
        self.coveritems.costiconbtn1:setTouchPriority(self.buttontouch)
        --
        self.coveritems.costiconbtn2:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(self.costid)
        end, CCControlEventTouchUpInside)
        self.coveritems.costiconbtn2:setSwallowsTouch(true)
        self.coveritems.costiconbtn2:setTouchPriority(self.buttontouch)
    end    

    --
    return self.coverccb
end


function gambling.reloaddata(self,data)
    if not self.show then return end

    if data and data.gambling then
        self.gambling = data.gambling
    end

    if self.costid == 1021 then
        self.hasnum = self.gambling.pointnum or 0
    else
        self.hasnum = data.hasnum or 0
    end  
    ui.setLabelString(self.coveritems.hasnum, self.hasnum, 111)  

    self.animationManager:runAnimationsForSequenceNamed("free")

    for i = 1,3 do
        for j = 1,12 do
            local propid = self.gambling["propid"..i]-2+j
            if propid < 1 then
                propid = propid+12
            elseif propid > 12 then
                propid = propid-12
            end
            local propcid,propnum = ui.getIDandNUM(gamedata.config.game_consoles_reward[tostring(propid)].reward)
            setSpriteFrameByName(self["showItems"..i]["prop"..j], ui.IDconfig(propcid).icon and ui.IDconfig(propcid).icon or "alpha")
            ui.setLabelString(self["showItems"..i]["propnum"..j], "x"..propnum, 14)
        end
        if self["animationManager"..i] then
            self["animationManager"..i]:runAnimationsForSequenceNamed("begin")
        end
    end

    --
    self.coveritems.tenButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if self.isten then
            self.isten = false
        else
            self.isten = true
        end
        self:setbutton()
    end, CCControlEventTouchUpInside)
    self.coveritems.tenButton:setSwallowsTouch(true)
    self.coveritems.tenButton:setTouchPriority(self.buttontouch)

    --
    self:setbutton()

end

function gambling.setbutton(self)
    if not self.show then return end

    self.coveritems.tensprite:setVisible(self.isten)

    local costall = self.costone*(self.isten and 10 or 1)

    ui.setLabelString(self.coveritems.costnum, costall, 111)

    if costall > (self.hasnum or 0) then
        ui.addGray("CCControlButton",self.coveritems.doButton)
        self.coveritems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if self.costid == 1021 then
                runGamePrompt({msg = "积分不足"})
            else
                runGamePrompt({msg = "道具不足"})
            end    
        end, CCControlEventTouchUpInside)
        self.coveritems.doButton:setSwallowsTouch(true)
        self.coveritems.doButton:setTouchPriority(self.buttontouch)
    else
        ui.removeGray("CCControlButton",self.coveritems.doButton)
        self.coveritems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1.5)
            UIRequest({type = 3861,num = (self.isten and 10 or 1)})
        end, CCControlEventTouchUpInside)
        self.coveritems.doButton:setSwallowsTouch(true)
        self.coveritems.doButton:setTouchPriority(self.buttontouch)
    end
    --

end


function gambling.playReward(self,data)
    if not self.show then return end
    if not (data and data.gambling) then return end

    self.gambling = data.gambling

    gameTouch:clickprofbytime(8)

    self.animationManager:runAnimationsForSequenceNamed("play")
    --
    if self["animationManager"..1] then
        self["animationManager"..1]:setAnimationCompletedCallback(function()
            for j = 1,12 do
                local propid = self.gambling["propid"..1]-11+j
                if propid < 1 then
                    propid = propid+12
                elseif propid > 12 then
                    propid = propid-12
                end
                local propcid,propnum = ui.getIDandNUM(gamedata.config.game_consoles_reward[tostring(propid)].reward)
                setSpriteFrameByName(self["showItems"..1]["prop"..j], ui.IDconfig(propcid).icon and ui.IDconfig(propcid).icon or "alpha")
                ui.setLabelString(self["showItems"..1]["propnum"..j], "x"..propnum, 14)
            end
        end)
        self["animationManager"..1]:runAnimationsForSequenceNamed("start")
    end

    if self["animationManager"..2] then
        self["animationManager"..2]:setAnimationCompletedCallback(function()
            for j = 1,12 do
                local propid = self.gambling["propid"..2]-11+j
                if propid < 1 then
                    propid = propid+12
                elseif propid > 12 then
                    propid = propid-12
                end
                local propcid,propnum = ui.getIDandNUM(gamedata.config.game_consoles_reward[tostring(propid)].reward)
                setSpriteFrameByName(self["showItems"..2]["prop"..j], ui.IDconfig(propcid).icon and ui.IDconfig(propcid).icon or "alpha")
                ui.setLabelString(self["showItems"..2]["propnum"..j], "x"..propnum, 14)
            end
        end)
        self["animationManager"..2]:runAnimationsForSequenceNamed("start")
    end

    if self["animationManager"..3] then
        self["animationManager"..3]:setAnimationCompletedCallback(function()
            for j = 1,12 do
                local propid = self.gambling["propid"..3]-11+j
                if propid < 1 then
                    propid = propid+12
                elseif propid > 12 then
                    propid = propid-12
                end
                local propcid,propnum = ui.getIDandNUM(gamedata.config.game_consoles_reward[tostring(propid)].reward)
                setSpriteFrameByName(self["showItems"..3]["prop"..j], ui.IDconfig(propcid).icon and ui.IDconfig(propcid).icon or "alpha")
                ui.setLabelString(self["showItems"..3]["propnum"..j], "x"..propnum, 14)
            end
        end)
        self["animationManager"..3]:runAnimationsForSequenceNamed("start")
    end

    --
    self.coveritems.effectnode:removeAllChildrenWithCleanup(true)
    for k,v in pairs(data.reward or {}) do
        if v.cid == 1021 then
            self.coveritems.effectnode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(5.5),CCCallFunc:create(function()
                local effectccb,effectItems = CCBReaderLoad("UIEffect/laohuji2/laohuji2effect2", nil, true, "laohuji2effect2")
                effectccb:setPosition(0,0)
                self.coveritems.effectnode:addChild(effectccb)
            end)))
            break
        end
    end

    self.coveritems.topnode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(6.5),CCCallFunc:create(function()

        if data and data.reward then
            showRewardPopupWindow(data.reward,nil)
        end
        self:reloaddata(data)

    end)))

    --

end


function gambling.clear(self)
    self.show = false

    self.isten = false

    self.costid = 1021
    self.hasnum = 0

    self.costone = 0
    self.gambling = {}

    self.animationManager = nil
    self.animationManager1 = nil
    self.animationManager2 = nil
    self.animationManager3 = nil
    self.showNode1 = nil
    self.showNode2 = nil
    self.showNode3 = nil
    self.showItems1 = nil
    self.showItems2 = nil
    self.showItems3 = nil

    self.coverccb = nil
    self.coveritems = nil
end



return gambling