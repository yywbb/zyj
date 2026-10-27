--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:09
-- To change this template use File | Settings | File Templates.
--

local activityshop = {
    isscrolltouched = false,
    buttontouch = -103,
    firstdata = 0,
    cpnum = 0,
    cpday = 0,
}

function activityshop.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("tanchuang/xianshishangdian",nil, true, "xianshishangdian")

    local Gneral = CCSkeletonAnimation:create("mengpo/mengpo.json","mengpo/mengpo.atlas",2)
    Gneral:setAnimation("stand",true,0)
    self.coveritems.general:addChild(Gneral)

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    -- self.coveritems.bottomnode:setPositionY((GameScene.topposY-1620)*1+1000 )


    local luckSpr = CCSprite:create("public/publicsprite/spr_42.png")
    self.coveritems.luckbarProcess = CCProgressTimer:create(luckSpr);
    self.coveritems.luckbarProcess:setAnchorPoint(ccp(0.0,0.5))
    self.coveritems.luckbarProcess:setType(kCCProgressTimerTypeBar)
    self.coveritems.luckbarProcess:setMidpoint(ccp(0,0.5))
    self.coveritems.luckbarProcess:setBarChangeRate(ccp(1,0))
    self.coveritems.luckbarProcess:setPosition(ccp(0,0))
    self.coveritems.luckbarProcess:setScaleX(0.975)
    self.coveritems.luckbarProcess:setScaleY(0.95)
    self.coveritems.luckbarProcess:setPercentage(0)
    self.coveritems.lucknode:addChild(self.coveritems.luckbarProcess)

    ui.setLabelString(self.coveritems.timedes,nil,121)

    ui.setLabelString(self.coveritems.luckydes,nil,13)

    -- ui.setLabelString(self.coveritems.resettext,gameConfig.strings:string_common("buttontext","shuaxin"),19)
    self.coveritems.resetbutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if gameTimer.times["cp_activityshop"] and gameTimer.times["cp_activityshop"] < 180 and gameTimer.times["cp_activityshop"] > 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("activity_shop",1)})
        else
            gameTouch:clickprofbytime(1)
            UIRequest({type = 5045})
        end
    end, CCControlEventTouchUpInside)
    self.coveritems.resetbutton:setSwallowsTouch(true)
    self.coveritems.resetbutton:setTouchPriority(self.buttontouch-1)

    ui.setLabelString(self.coveritems.tipdes,gameConfig.strings:string_common("buttontext","xinyunzhi"),111)
    self.coveritems.tip:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("tips",{type = "activityshopTip"},nil)
    end, CCControlEventTouchUpInside)
    self.coveritems.tip:setSwallowsTouch(true)
    self.coveritems.tip:setTouchPriority(self.buttontouch)

    ui.setLabelString(self.coveritems.viewdes,gameConfig.strings:string_common("buttontext","shangpinyulan"),111)
    self.coveritems.view:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("activityshopPreview",{cpnum = self.cpnum},nil)
    end, CCControlEventTouchUpInside)
    self.coveritems.view:setSwallowsTouch(true)
    self.coveritems.view:setTouchPriority(self.buttontouch)


    self.coveritems.scrollnode = tolua.cast(self.coveritems.scrollnode, "CCScrollView")
    self.coveritems.scrollnode:setTouchPriority(self.buttontouch)
    -- self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    self.coveritems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-500-230))

    self.coveritems.container:setContentSize(CCSize(1080,1000))

    self.scrollNode, self.scrollItems = CCBReaderLoad("tanchuang/map2", nil, true, "map2")
    self.scrollNode:setPosition(0,0)
    self.scrollNode:setVisible(false)
    self.coveritems.container:addChild(self.scrollNode)

    self.coveritems.scrollnode:setContentOffsetInDuration(ccp(0,self.contentsize.y-180-500-230 - 1000),0)

    self.coveritems.scrollnode_touch:setContentSize(CCSize(gameConfig.originSize.width,self.contentsize.y-180-500-230))

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","cp_activityshop",touchbegin)

    local function touchend(pos)
        if self.coveritems.scrollnode_touch and ui.isTouched(self.coveritems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","cp_activityshop",touchend)
    --

    return self.coverccb
end

function activityshop.setone(self,item,id)
    local key_Ex
    if id == nil or id == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(id-1)
    end

    local configdata = gamedata.config["limittime_shop_"..self.cpnum][tostring(self.data.status[tostring(id)].id)]
    print("configdata=======")
    printT(configdata)
    if not configdata then
        print("notid===",self.data.status[tostring(id)].id)
        return
    end

    local data = self.data.status[tostring(id)]

    if tonumber(configdata["currency"]) == 1001 then
        item["coinNode"..key_Ex]:setVisible(false)
    else
        item["goldNode"..key_Ex]:setVisible(false)
    end

    ui.setNewIconName(item,{cid = configdata.id, num = configdata.num},id-1)
    item["i_button"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        ui.setPopwindowByCid(configdata.id)
    end, CCControlEventTouchUpInside)
    item["i_button"..key_Ex]:setTouchPriority(self.buttontouch)

    item["hotnode"..key_Ex]:setVisible(configdata.hot and configdata.hot == 1)
    item["price"..key_Ex]:setString(configdata["price"])
    item["gold"..key_Ex]:setString(configdata["discount"])

    ui.setLabelString(item["buttontext"..key_Ex],gameConfig.strings:string_common("buttontext","goumai"),18)

    if data and data.status == 1 then
        ui.removeGray("CCControlButton",item["button"..key_Ex])
        ui.removeGray("CCLabelTTF",item["buttontext"..key_Ex])

        item["button"..key_Ex]:setTouchPriority(self.buttontouch)
        item["button"..key_Ex]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            -- UIRequest({type = 5044,id = data.id})
            if tonumber(configdata["currency"]) == 1001 then
                if configdata["discount"] > 500 then
                    local function bagCB()
                       UIRequest({type = 5044,id = data.id})            
                    end
                    local cost = {{cid = 1001, num = configdata["discount"]}}
                    gameWindows:openWindow("shopExchange",{cid = configdata.id, num = configdata.num, cost = cost, exchangeNum = 1, ccbtype = 2}, bagCB)
                else
                    UIRequest({type = 5044,id = data.id})
                end
            else
                UIRequest({type = 5044,id = data.id})
            end

        end, CCControlEventTouchUpInside)
    else
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

function activityshop.reloaddata(self,data)
    if not self.show then return end
    self.data = data and data.data or {}
    self.scrollNode:setVisible(true)

    local cpnum = data and data.cpnum or 0
    local cpday = data and data.cpday or 0
    self.cpnum = cpnum
    self.cpday = cpday

    -- 活动时间
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["93"]["open_type"] and gamedata.config.activity_time["93"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(gamedata.config.activity_time["93"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["93"]["open_type"] and gamedata.config.activity_time["93"]["open_type"] == 2 then
        self.coveritems.time:setString("")
        self.coveritems.timedes:setString("")
    elseif self.coveritems.time and gamedata.config.activity_time["93"]["open_type"] and gamedata.config.activity_time["93"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["93"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec

    elseif self.coveritems.time and gamedata.config.activity_time["93"]["end"] and gamedata.config.activity_time["93"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["93"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        self.coveritems.time:setString("")
        self.coveritems.timedes:setString("")
    end

    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("cp_Activityshopdata",timediff)

        if gameTimer.times["cp_Activityshopdata"] and gameTimer.times["cp_Activityshopdata"] > 0 then
            gameTimer:rigistTimeFunc("cp_Activityshopdata", function()
                if gameTimer.times["cp_Activityshopdata"] <= 0 then
                    if gameTimer.times["cp_Activityshopdata"] then
                        print("finish")
                        gameTimer:UnrigistTimeFunc("cp_Activityshopdata")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["cp_Activityshopdata"],"day"))
                    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
                end
            end)
        end
    end

    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
    --



    if self.data.reset>=3 then
        self.coveritems.resetgoldnode:setVisible(true)
        self.coveritems.freegoldLabel:setVisible(false)
        -- self.coveritems.freesprite:setVisible(false)
        ui.setLabelString(self.coveritems.resetgold,"5",121)
    else
        self.coveritems.resetgoldnode:setVisible(false)
        -- self.coveritems.freesprite:setVisible(true)
        self.coveritems.freegoldLabel:setVisible(true)
        self.coveritems.freegoldLabel:setString("免费刷新次数:"..(3-self.data.reset).."/".."3")
    end

    if gameTimer.times["cp_activityshop"] and gameTimer.times["cp_activityshop"] > 0 then
        gameTimer:rigistTimeFunc("cp_activityshop",function()
            if gameTimer.times["cp_activityshop"] < 0 then
                self.coveritems.updatenode:setVisible(false)
                gameTouch:clickprofbytime(1)
                UIRequest({type = 5043,update = true})
                gameTimer:UnrigistTimeFunc("cp_activityshop")
            else
                self.coveritems.updatenode:setVisible(true)
                self.coveritems.updatetime:setString(ui.makeTimeText(gameTimer.times["cp_activityshop"],"hour"))
            end
        end)
    else
        self.coveritems.updatenode:setVisible(false)
    end
    --self.coveritems.luckbar:setPercentage(100*self.data.lucky / 100)
    ui.setLabelString(self.coveritems.lucky,self.data.lucky.."/".."100",13)
    -- ui.setSpriteTextureRect2(self.coveritems.luckbar,0,0,793 * self.data.lucky / 100,21)
    print("lucky===",self.data.lucky)
    printT(self.firstdata)
    local luckTo = CCProgressFromTo:create(0.5,self.firstdata,100*self.data.lucky / 100)
    self.coveritems.luckbarProcess:runAction(luckTo)
    self.firstdata = self.data.lucky

    if tonumber(self.data.lucky) == 100 then
        self.coveritems.luckeffectNode:setVisible(true)
    else
        self.coveritems.luckeffectNode:setVisible(false)
    end

    for i=1, 6 do
        self:setone(self.scrollItems,i)
    end
end

function activityshop.clear(self)
    gameTouch:UnrigistFunc("begin","cp_activityshop")
    gameTouch:UnrigistFunc("end","cp_activityshop")
    if gameTimer.times["cp_Activityshopdata"] then
        gameTimer:UnrigistTimeFunc("cp_Activityshopdata")
    end
    gameTimer:UnrigistTimeFunc("cp_activityshop")
    self.firstdata = 0
    self.show = false
    self.data = nil
    self.coverccb = nil
    self.coveritems = nil
end


return activityshop