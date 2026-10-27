--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local wudaohuilunpan = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -101,

    lunpandata = {},

    rotation = {337.5, 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5},


    -- 活动时间
    begintimenum = {week=3,hour=20,min=30,sec=0},
    endtimenum = {week=3,hour=21,min=0,sec=0},
    finaltimenum = {week=3,hour=21,min=10,sec=0},

    isopen = false,
    touchPriority = -101,
}


function wudaohuilunpan.init(self,size)
    self.contentsize = size
    self.show = true

    self.rootNode,self.rootItems = CCBReaderLoad("wudaohui/wudaohui_choujiang", nil, true, "wudaohui_choujiang")
    -- parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)


    self.rootItems.showNode:setPositionY(self.contentsize.y/2-10)

    self.xiandouShopConfig = gamedata.config.xiandou_shop
    -- self.rootItems.showNode:setPositionY((toppos-550-315)/2+315)
    ui.setLabelString(self.rootItems.rewardText,nil,14)

    local global_kvconfig = gamedata.config.global_kv
    local rewarddata = ui.getIDandNUMs(global_kvconfig.wudao_lottery_must.value)

    ui.setLabelString(self.rootItems.rewardLabel,"x"..(rewarddata[1]["num"] or 0),21)
    local tempconfig = ui.IDconfig(rewarddata[1]["cid"])
    
    setSpriteFrameByName(self.rootItems.rewardSprite, tempconfig.icon and tempconfig.icon or "alpha")

    ui.setLabelString(self.rootItems.spendText,nil,14)
    ui.setLabelString(self.rootItems.spendTextMore,nil,14)
    ui.setLabelString(self.rootItems.spendLabel,(global_kvconfig.wudao_lottery_use and global_kvconfig.wudao_lottery_use.value and global_kvconfig.wudao_lottery_use.value or 0),21)
    
    
    ui.setLabelString(self.rootItems.doLab,nil,19)
    ui.setLabelString(self.rootItems.hasxiandaoText,nil,14)
    ui.setLabelString(self.rootItems.hasxiandaoLabel,nil,21)

    ui.setLabelString(self.rootItems.refreshText, gameConfig.strings:string_common("wudaohui", 50), 14)
    local _xiandou = ui.getIDandNUMs(global_kvconfig.wudao_refresh_use.value)
    ui.setLabelString(self.rootItems.refreshLabel, _xiandou[1]["num"], 21)
    ui.setLabelString(self.rootItems.refreshLab, gameConfig.strings:string_common("wudaohui", 52), 19)

    self:initRefreshBtn()
    self:initRefreshPreviewBtn()


    if GameScene.roleinfo and next(GameScene.roleinfo) and GameScene.roleinfo.id then
        local _wudaohuiRewardPreview = CCUserDefault:sharedUserDefault():getBoolForKey("wudaohuiRewardPreview"..GameScene.roleinfo.id)

        if _wudaohuiRewardPreview then
            self.rootItems["new_reward"]:removeAllChildrenWithCleanup(true)
            local ccb,Items = CCBReaderLoad("talk/new", nil, true, "new")
            self.rootItems["new_reward"]:addChild(ccb)
        end
    end
    -- UIRequest({type = 3820})
    -- self:reloaddata()

    return self.rootNode
end

function wudaohuilunpan.initRefreshBtn(self)
    local _cb = function()
        if self.lunpandata.mynowscorenum then
            local _xiandou = ui.getIDandNUMs(gamedata.config.global_kv.wudao_refresh_use.value)

            if self.lunpandata.mynowscorenum >= tonumber(_xiandou[1]["num"]) then
                gameTouch:clickprofbytime(1)
                self.refreshAnimationCount = 0
                self:refreshAnimation()
            else
                runGamePrompt({msg = gameConfig.strings:string_common("wudaohui",1)})
            end
        end
    end

    ui.commonBtn(self, self.rootItems, "refreshBtn", _cb)
end

function wudaohuilunpan.refreshAnimation(self)
    local _time = 0.05
    self.rootItems["animationNode"]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(_time), CCCallFunc:create(function()
        self.refreshAnimationCount = self.refreshAnimationCount + 1
        for i = 1, 8 do
            local _config = self.xiandouShopConfig[tostring(i)]
            local _len = table.getTableLength(_config)
            local _id = math.random(1, _len)
            local _reward = _config[tostring(_id)].reward
            local getdata = ui.getIDandNUMs(_reward)
            if getdata and next(getdata[1]) then
                ui.setNewIcon(self.rootItems,getdata[1], i - 1)
            end
        end

        if self.refreshAnimationCount == 1 / _time then
            UIRequest({type = 4105, id = 2})
        else
            self:refreshAnimation()
        end
    end)))
end

function wudaohuilunpan.initRefreshPreviewBtn(self)
    local _cb = function()
        gameWindows:openWindow("wudaohuiRewardPreview")
        self.rootItems["new_reward"]:removeAllChildrenWithCleanup(true)
        GameScene.layers["activity"].module.NavigationTableView:reloadData()
    end

    ui.commonBtn(self, self.rootItems, "rewardPreviewBtn", _cb)
end

function wudaohuilunpan.actionShowSet(self,data)
    if not data then return end
    gameTouch:clickprofbytime(4.5)

    local rotationnum = 0
    -- for k,v in pairs(gamedata.config.wudao_lottery) do
    --     local getdata = ui.getIDandNUMs(v.reward)
    --     if tonumber(getdata[1].cid) == tonumber(data.reward[tostring(1)].cid) and tonumber(getdata[1].num) == tonumber(data.reward[tostring(1)].num) then
    --         rotationnum = self.rotation[tonumber(k)]
    --         break
    --     end
    -- end
    rotationnum = self.rotation[tonumber(data.rewardid or 1)]

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

        -- local scorestring = gameConfig.strings:string_common("lunpan",1)..(gamedata.config.global_kv.dragonboatfestival_number.value or 0)
        -- runGamePrompt({msg = scorestring})
        
        UIRequest({type = 1001})

        UIRequest({type = 4105})
        -- self:reloaddata(data.maindata)
    end)))

end


function wudaohuilunpan.reloaddata(self,data)
    if not self.show then return end
    if not data then return end

    self.lunpandata = data
    --printT(self.lunpandata,"lunpandata===")



    -- 武道会时间设置与判断
    self:setTimeData()


    ui.setLabelString(self.rootItems.hasxiandaoLabel,self.lunpandata.mynowscorenum,21)

    -- local lotteryNums = self.lunpandata.lotteryNums or 0
    -- if lotteryNums == 60 then
    --     lotteryNums = 60
    -- end
    local global_kvconfig = gamedata.config.global_kv
    local spendscorenum = global_kvconfig.wudao_lottery_use.value or 0

    for i = 1, 8 do
        local _reward = self.xiandouShopConfig[tostring(i)][tostring(self.lunpandata.reward[tostring(i)])].reward
        local getdata = ui.getIDandNUMs(_reward)
        if getdata and next(getdata[1]) then
            ui.setNewIcon(self.rootItems,getdata[1], i - 1)
            local id = (i - 1) or 0
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
            end, CCControlEventTouchUpInside)
        end
    end
    -- print("spendscorenum==",spendscorenum,self.lunpandata.mynowscorenum)
    -- if tonumber(spendscorenum) > tonumber(self.lunpandata.mynowscorenum) then

    --     ui.addGray("CCControlButton",self.rootItems.doButton)
    --     ui.addGray("CCLabelTTF",self.rootItems.doLab)
    -- else

    --     ui.removeGray("CCControlButton",self.rootItems.doButton)
    --     ui.removeGray("CCLabelTTF",self.rootItems.doLab)
    -- end

    
    -- 段位
    self.rootItems.duanweiBtn:setTouchPriority(self.buttontouch)
    self.rootItems.duanweiBtn:setSwallowsTouch(true)
    self.rootItems.duanweiBtn:addHandleOfControlEvent(function()
        print("duanweiBtn=")    
        gameWindows:openWindow("wudaohuiduanwei",{myallscorenum=self.lunpandata.myallscorenum})
    end, CCControlEventTouchUpInside)

    -- 抽奖 按钮
    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:setTouchPriority(self.buttontouch)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        print("doButton=")    
        if GameScene.layers["activity"].module.isContentScroll then  return end

        gameTouch:clickprofbytime(1)
        if tonumber(spendscorenum) > tonumber(self.lunpandata.mynowscorenum) then
            runGamePrompt({msg = gameConfig.strings:string_common("wudaohui",1)})
        else
            UIRequest({type=4106, num = 1})
        end

    end, CCControlEventTouchUpInside)

    --
    local donum = 10
    if math.floor(tonumber(self.lunpandata.mynowscorenum)/tonumber(spendscorenum)) >= 10 then
        donum = 10
    elseif math.floor(tonumber(self.lunpandata.mynowscorenum)/tonumber(spendscorenum)) >= 2 then
        donum = math.floor(tonumber(self.lunpandata.mynowscorenum)/tonumber(spendscorenum))
    end
    --
    ui.setLabelString(self.rootItems.spendLabelMore,(global_kvconfig.wudao_lottery_use and global_kvconfig.wudao_lottery_use.value and global_kvconfig.wudao_lottery_use.value*donum or 0),21)
    ui.setLabelString(self.rootItems.doLabMore,gameConfig.strings:wudaohui_choujiang(donum),19)
    --
    self.rootItems.doButtonMore:setTouchPriority(self.buttontouch)
    self.rootItems.doButtonMore:setSwallowsTouch(true)
    self.rootItems.doButtonMore:addHandleOfControlEvent(function()
        print("doButtonMore=")
        if GameScene.layers["activity"].module.isContentScroll then  return end

        gameTouch:clickprofbytime(1)
        if tonumber(spendscorenum)*donum > tonumber(self.lunpandata.mynowscorenum) then
            runGamePrompt({msg = gameConfig.strings:string_common("wudaohui",1)})
        else
            UIRequest({type=4106, num = donum})
        end

    end, CCControlEventTouchUpInside)
    --
    -- 去武道会按钮
    ui.setLabelString(self.rootItems.gotoWudaohuiText,nil,18)
    self.rootItems.gotoWudaohuiBtn:setTouchPriority(self.buttontouch)
    self.rootItems.gotoWudaohuiBtn:setSwallowsTouch(true)
    self.rootItems.gotoWudaohuiBtn:addHandleOfControlEvent(function()
        print("shopBtn=") 
        if self.isopen == false then
            runGamePrompt({msg = "不在活动时间内"})
            return
        end  
        
        GameScene:shiftLayerById(191)
    end, CCControlEventTouchUpInside)



    -- self:updatetimeFunc()
    self:sethit()
    
end

-- 设置红点提示
function wudaohuilunpan.sethit( self )
    local hitstatus = false
    if tonumber(self.lunpandata.hintstatus) ~= 0 then
        hitstatus = true
    end
    ui.sethint(self.rootItems.hint,hitstatus)
end

-- 判断为哪个活动倒计时
function wudaohuilunpan.setTimeData( self )
    if gamedata.config.wudao_time and gamedata.config.wudao_time["1"] and gamedata.config.wudao_time["1"].open_week and gamedata.config.wudao_time["1"].open_week > 0 then
    else
        return
    end

    local nowtime = os.date("*t", gamedata:time())

    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))

    local updatestatus = false
    -- printT(gamedata.config.wudao_time,"wudao_time====")
    for k,v in pairs(gamedata.config.wudao_time) do
        if tonumber(v.open_week) == daynums then
            local hour1,min1,sec1 = ui.getGangBattleTime(v["open_time"])
            local hour2,min2,sec2 = ui.getGangBattleTime(v["over_time"])
            local hour3,min3,sec3 = ui.getGangBattleTime(v["finaly_time"])
            print("hour1,min1,sec1==",hour1,min1,sec1)
            print("hour2,min2,sec2==",hour2,min2,sec2)

            self.begintimenum = {week=v["open_week"], hour=hour1, min=min1, sec=sec1}
            self.endtimenum = {week=v["open_week"], hour=hour2, min=min2, sec=sec2}
            self.finaltimenum = {week=v["open_week"], hour=hour3, min=min3, sec=sec3}
            updatestatus = true
            break
        end
    end
    if updatestatus == false then
        self.isopen = false
        return
    end


    self:judgeOpenType()
end

function wudaohuilunpan.judgeOpenType( self )
    local nowtime = os.date("*t", gamedata:time())
    print("nowtime===")
    --printT(nowtime)
    local daynums = (nowtime.wday == 1 and 7 or (nowtime.wday-1))
    local alltimes = (daynums - 1)*24*3600 + nowtime.hour*3600 + nowtime.min*60 + nowtime.sec - 1

    if self:gettimenum(self.begintimenum) <= alltimes and alltimes < self:gettimenum(self.endtimenum) then
        print("start====time")
        self.isopen = true
    elseif self:gettimenum(self.endtimenum) <= alltimes and alltimes < self:gettimenum(self.finaltimenum) then
        print("end====time")
        self.isopen = true
    else
        print("out====time")
        self.isopen = false
    end
end



function wudaohuilunpan.updatetimeFunc( self )
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


-- 代入时间计算秒数
function wudaohuilunpan.gettimenum(self,times,minnum)
    -- print("minnum===",minnum)
    local min = 0
    if minnum then
        min = minnum
    end
    local alltimes = 0
    alltimes = (times.week and (times.week-1) or 0)*24*3600 + (times.hour or 0)*3600 + times.min*60 + times.sec + min*60
    return alltimes
end



function wudaohuilunpan.clear(self)
    self.show = false

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
    

    self.lunpandata = {}

    -- gameTimer:UnrigistTimeFunc("lunpan_rewardtime")

end


function wudaohuilunpan.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 4105})
    end
end


return wudaohuilunpanH=  