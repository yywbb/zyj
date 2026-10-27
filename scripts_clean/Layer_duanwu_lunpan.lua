--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local lunpan = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    lunpandata = {},
    systemId = 186,
    itemNum = 0,
    rotation = {337.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5}
}

function lunpan.setFixedString(self)
    ui.setLabelString(self.rootItems.itemLab,gameConfig.strings:string_common("fixedString","shop",19),18)
    --ui.setLabelString(self.rootItems.haveFixedText,gameConfig.strings:string_common("fixedString","encounter",11),18)
    self.rootItems.haveFixedText:setString(gameConfig.strings:string_common("fixedString","shop",8))

    local useItemConfig = gamedata.config.gambling_items[tostring(self.systemId)]["1"]
    if not useItemConfig then
        cclog("error,no activity %d config",self.systemId)
        return
    end
    local itemConfigs = {}
    local id,num = ui.getIDandNUM(useItemConfig.once2)
    itemConfigs[1] = num
    id,num = ui.getIDandNUM(useItemConfig.tenfold2)
    itemConfigs[2] = num
    self.itemConfigs = itemConfigs
end


function lunpan.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("activityduanwu/activityduanwu_lunpan", nil, true, "lunpan")
    -- parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)


    self.rootItems.showNode:setPositionY(self.contentsize.y/2-390+360)
    self:initgambling()
    self:setFixedString()

    
    
    -- self.rootItems.showNode:setPositionY((toppos-550-315)/2+315)

    ui.setLabelString(self.rootItems.timerText,nil,14)
    ui.setLabelString(self.rootItems.timerLabel,nil,21)

    ui.setLabelString(self.rootItems.scoreText,nil,14)
    ui.setLabelString(self.rootItems.scoreLabel,nil,21)
    
    
    
   
    -- 说明 规则
    self.rootItems.rulebutton:setTouchPriority(self.buttontouch)
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        print("rulebutton=")    
        gameWindows:openWindow("lunpanchange",{index= "rule",data={}},nil) 
        -- gameWindows:openWindow("lunpanselect",{index= "rule"},nil) 

    end, CCControlEventTouchUpInside)

    if self.rootItems.listLab and self.rootItems.listButton then
        ui.setLabelString(self.rootItems.listLab,nil,18)
        self.rootItems.listButton:setTouchPriority(self.buttontouch)
        self.rootItems.listButton:setSwallowsTouch(true)
        self.rootItems.listButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(0.5)
            gameWindows:openWindow("turntablerecord",{systemId = self.systemId},nil)
        end, CCControlEventTouchUpInside)
    end

    self.rootItems.buyItem:setTouchPriority(self.buttontouch)
    self.rootItems.buyItem:setSwallowsTouch(true)
    self.rootItems.buyItem:addHandleOfControlEvent(function()

        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
            if data.id == self.itemId then
                self:setItemNum({[tostring(data.id)] = data.num})
            end
        end)

    end, CCControlEventTouchUpInside)

    -- UIRequest({type = 3820})
    -- self:reloaddata()
    self:requestItemNum()
    return self.rootNode
end

function lunpan.requestItemNum(self)
    if not self.itemId then
        local config = gamedata.config.gambling_items[tostring(self.systemId)]["1"]
        if config then
            local id,_ = ui.getIDandNUM(config.once2)
            self.itemId = id
        end
    end
    if self.itemId then
        UIRequest({type = 12001, order = 33003, cids = {self.itemId}})
    end
end

function lunpan.setItemNum(self,itemNum)
    if itemNum[tostring(self.itemId)] then
        self.itemNum = itemNum[tostring(self.itemId)] or 0
        if self.rootItems then
            self.rootItems.haveFixedNum:setString(""..self.itemNum)
        end
    end
end


function lunpan.actionShowSet(self,data)
    self:requestItemNum()
    if not data then return end
    gameTouch:clickprofbytime(4.5)

    local rotationnum = 0
    for k,v in pairs(gamedata.config.dragonBoatCarnival_lottery) do
        local getdata = ui.getIDandNUMs(v.reward)
        for kk,vv in pairs(data.reward) do
            if tonumber(getdata[1].cid) == tonumber(vv.cid) and tonumber(getdata[1].num) == tonumber(vv.num) then
                rotationnum = self.rotation[tonumber(k)]
                break
            end
        end
    end

    local nowrotationnum = math.mod(self.rootItems.rotateNode:getRotation(),360) 
    print("nowrotationnum==",nowrotationnum)

    local rotationbynum = 4*360 - nowrotationnum + rotationnum

    print("rotationnum===",rotationbynum)

    local rotationby = CCRotateBy:create(4, rotationbynum)
    local rotationOut = CCEaseSineOut:create(rotationby)
    -- self.rootItems.rotateNode:runAction(rotationOut)

    self.rootItems.rotateNode:runAction(CCSequence:createWithTwoActions(rotationOut,CCCallFunc:create(function()
        if data.reward then
            showRewardPopupWindow(data.reward, nil, nil)
        end 

        local scorestring = gameConfig.strings:string_common("lunpan",1)..(gamedata.config.global_kv.dragonboatfestival_number.value or 0)
        runGamePrompt({msg = scorestring})
        
        UIRequest({type = 1001})
        self:reloaddata(data.maindata)
    end)))

end


function lunpan.reloaddata(self,data)
    if not self.show then return end
    if not data then return end

    self.lunpandata = data
    printT(self.lunpandata,"lunpandata===")


    ui.setLabelString(self.rootItems.scoreLabel,self.lunpandata.pointScore,21)

    local lotteryNums = self.lunpandata.lotteryNums or 0
    if lotteryNums >= 59 then
        lotteryNums = 59
    end


    ui.removeGray("CCControlButton",self.rootItems.doButton)
    ui.removeGray("CCLabelTTF",self.rootItems.doLab)


    local freetimes = gamedata.config.global_kv.dragonboatfestival_lottery.value - self.lunpandata.lotteryFreeUsed
    if freetimes > 0 then
        self.rootItems.freenode:setVisible(true)
        self.rootItems.spendnode:setVisible(false)
        ui.setLabelString(self.rootItems.freeText,nil,18)
        ui.setLabelString(self.rootItems.freeLabel,freetimes,21)
    elseif self.lunpandata.lotteryNums >= tonumber(gamedata.config.global_kv.dragonboatfestival_times.value) then
        self.rootItems.freenode:setVisible(false)
        self.rootItems.spendnode:setVisible(false)

        ui.addGray("CCControlButton",self.rootItems.doButton)
        ui.addGray("CCLabelTTF",self.rootItems.doLab)
    else
        self.rootItems.freenode:setVisible(false)
        self.rootItems.spendnode:setVisible(true)
        ui.setLabelString(self.rootItems.spendText,nil,18)
        ui.setLabelString(self.rootItems.spendLabel,self.itemConfigs[1],21)
    end



    -- 抽奖 按钮
    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:setTouchPriority(self.buttontouch)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        print("doButton=")    
        if GameScene.layers["activity"].module.isContentScroll then  return end

        
        if self.lunpandata.lotteryNums >= tonumber(gamedata.config.global_kv.dragonboatfestival_times.value) then
            runGamePrompt({msg = gameConfig.strings:string_common("lunpan",3)})
        else
            if freetimes < 1 and self.itemConfigs[1] > self.itemNum then
                gameWindows:openWindow("buyItem",{id = self.itemId or 20612,num = self.itemNum},function (data)
                    if data.id == self.itemId then
                        self:setItemNum({[tostring(data.id)] = data.num})
                    end
                end)
            else
                gameTouch:clickprofbytime(1)
                UIRequest({type = 3301,useId = self.itemId,useNum = freetimes < 1 and self.itemConfigs[1] or 0})
            end
        end
        
       

    end, CCControlEventTouchUpInside)

    

    -- 去商店按钮
    self.rootItems.shopBtn:setTouchPriority(self.buttontouch)
    self.rootItems.shopBtn:setSwallowsTouch(true)
    self.rootItems.shopBtn:addHandleOfControlEvent(function()
        print("shopBtn=")   
        
        -- GameScene:shiftLayerById(185)
        gameWindows:openWindow("lunpanchange",{index= "change",data=self.lunpandata.pointScore},nil) 
    end, CCControlEventTouchUpInside)



    local goodsconfig = gamedata.config.dragonBoatCarnival_lottery

    for k,v in pairs(goodsconfig) do
        local getdata = ui.getIDandNUMs(v.reward)
        printT(getdata,"getdata===")

        if getdata and next(getdata[1]) then
            ui.setNewIcon(self.rootItems,getdata[1],tonumber(k)-1)

            local id = (tonumber(k)-1) or 0
            local key_Ex
            if id == nil or id == 0 then
                key_Ex = ""
            else
                key_Ex = "_"..id
            end

            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.buttontouch)
            self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                print("i_button=")   
                ui.setPopwindowByCid(getdata[1].cid)
                -- GameScene:shiftLayerById(185)
            end, CCControlEventTouchUpInside)
        end

        

        -- local temp = ui.IDconfig(getdata)
    end



    self:updatetimeFunc()
    
end


function lunpan.updatetimeFunc( self )
    local nowtime = os.date("*t", gamedata:time())
    local remaintime = 0

    local isnow,remaintime = ui.checkDateActive(gamedata.config.activity_time["38"]["begin"],gamedata.config.activity_time["38"]["end"])
    -- local year,month,day,hour,minute,second = ui.getDate(gamedata.config.activity_time["38"]["end"])
    print("isnow,remaintime===",isnow,remaintime)
    if not isnow then
        return
    end
    -- remaintime = day*24*3600+hour*3600+minute*60+second - nowtime.day*24*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec
  

    gameTimer:rigistTime("lunpan_rewardtime", remaintime)
    gameTimer:rigistTimeFunc("lunpan_rewardtime",function()
    
        if gameTimer.times["lunpan_rewardtime"] >= 0 then
            if nowtime.wday == 1 then
                ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeText(gameTimer.times["lunpan_rewardtime"],"hour"),26)
            else
                ui.setLabelString(self.rootItems.timerLabel,ui.makeTimeDayText(gameTimer.times["lunpan_rewardtime"],"day"),26)
            end
        end
        if gameTimer.times["lunpan_rewardtime"] == 0 then
            -- print("lunpan_rewardtime===",0)
            -- UIRequest({type=3820})
            gameTimer:UnrigistTimeFunc("lunpan_rewardtime")
        end
    end)
end



function lunpan.clear(self)
    self.show = false

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
    
    self.itemNum = 0
    self.lunpandata = {}

    gameTimer:UnrigistTimeFunc("lunpan_rewardtime")

end


function lunpan.initgambling(self)

    if gamedata.config.build[tostring(354)] and gamedata.config.build[tostring(354)].switch == 1 then
        ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("fixedString","shop",21),19)
        self.rootItems["gamblingNode"]:setVisible(false)
        if false and self.rootItems["gamblingNode"] then
            self.rootItems["gamblingNode"]:setVisible(true)
            ui.setLabelString(self.rootItems.doLab,"购 买",19)
            local gamblingconfig = gamedata.config.gambling
            local rewardPropCid,rewardPropNum = ui.getIDandNUM(gamblingconfig["6"]["reward1"])
            local richdata = ui.IDconfig(rewardPropCid)
            richdata.num = rewardPropNum
            richdata.cid = rewardPropCid
            ui.setNewIcon(self.rootItems,richdata,8)
            self.rootItems["i_num_8"]:setScale(1.2)
            ui.setLabelString(self.rootItems.fixedcostLab1,"购买",18)
            ui.setLabelString(self.rootItems.fixedcostLab2,"送领奖",18)
        end
    end

end


function lunpan.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 3300})
        self:requestItemNum()
    end
end


return lunpan