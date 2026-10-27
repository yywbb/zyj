--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/27
-- Time: 下午3:00
-- To change this template use File | Settings | File Templates.
--

local mammon = {

    buttontouch = -103,

    serverbroadcast = {},
    broadcastindex = 5,

    defaultbroadcast = {
        [1] = gameConfig.strings:string_common("mammon",1),
        [2] = gameConfig.strings:string_common("mammon",2),
        [3] = gameConfig.strings:string_common("mammon",3),
        [4] = gameConfig.strings:string_common("mammon",4),
        [5] = gameConfig.strings:string_common("mammon",5),
        [6] = gameConfig.strings:string_common("mammon",6),
        [7] = gameConfig.strings:string_common("mammon",7),
        [8] = gameConfig.strings:string_common("mammon",8),
        [9] = gameConfig.strings:string_common("mammon",9),
        [10] = gameConfig.strings:string_common("mammon",10),
    },

    viplimit = 0,

}

function mammon.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitymammon/mammon",nil, true, "mammon")

    self.coveritems.topnode:setPositionY(self.contentsize.y)
    self.coveritems.midnode:setPositionY((self.contentsize.y-gameConfig.maiscenebottomheight)/2+50) -- +gameConfig.maiscenebottomheight)

    for i=1,5 do
        self.coveritems["numscroll"..i]:setTouchEnabled(false)
    end
    self.coveritems.broadcastscroll:setTouchEnabled(false)

    UIRequest({type = 2017})
    return self.coverccb
end

function mammon.palyrandom(self,data)
    -- print("点击迎财神刷新")
    if not self.show then return end

    self.data = data
    self.coveritems.paynode:setVisible(false)
    gameTouch:clickprofbytime(4)
    for i=1, 5 do
        local num = math.mod(math.floor(data.reward["1"].num/(10^(5-i))),10)
        -- print(num)
        if  i== 1 then
            local moveTo = CCMoveTo:create((5-i)*0.5+1, ccp(0, -1700*(6-i)-num*170))
            local backOut = CCEaseExponentialOut:create(moveTo)
            local seq = CCSequence:createWithTwoActions(backOut, CCCallFunc:create(function()
                local seq2 = CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
                    gameWindows:openWindow("mammon_pop",{pay = gamedata.config.mammon[tostring(self.data.status["1"]-1)].gold, get = data.reward["1"].num},function() GameScene:coin_effect(2,540,600,0.5) end);
                    local ccb,item = CCBReaderLoad("UIEffect/tianjiangyuanbao/tianjiangyuanbao",nil, true, "tianjiangyuanbao")
                    ccb:setPosition(ccp(550*GameScene.scaleNum,1130*GameScene.scaleNum+gameConfig.fixH))
                    ccb:setScale(GameScene.scaleNum)
                    mainScene:addChild(ccb,10000)

                    ccb:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(3), CCCallFunc:create(function()
                        ccb:removeFromParentAndCleanup(true)
                    end)))
                    self:resetdata()
                end))
                self.coveritems.topnode:runAction(seq2)
            end))
            self.coveritems["container"..i]:setPosition(ccp(0,math.mod(self.coveritems["container"..i]:getPositionY(),1700)))
            self.coveritems["container"..i]:runAction(seq)
        else
            local moveTo = CCMoveTo:create((5-i)*0.5+1, ccp(0, -1700*(6-i)-num*170))
            local backOut = CCEaseExponentialOut:create(moveTo)
            self.coveritems["container"..i]:setPosition(ccp(0,math.mod(self.coveritems["container"..i]:getPositionY(),1700)))
            self.coveritems["container"..i]:runAction(backOut)
        end
    end
end

function mammon.resetdata(self)
    -- print("resetdata.num==",6-self.data.status["1"])
    self.coveritems.needVip1:setVisible(false)
    self.coveritems.needVip2:setVisible(false)
    if (table.getTableLength(gamedata.config.mammon)-self.data.status["1"] + 1) <=0 then
        --ui.addGray("CCSprite",self.coveritems.optsprite)
        ui.addGray("CCControlButton",self.coveritems.eatButton)
        self.coveritems.eatButton:addHandleOfControlEvent(function ()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",14)})
        end, CCControlEventTouchUpInside)
        self.coveritems.paynode:setVisible(false)
    else
        self.viplimit = gamedata.config:getConfigByName("mammon")[tostring(self.data.status["1"])].limit
        if self.viplimit > 1 then
            self.coveritems.needVip1:setVisible(true)
            self.coveritems.needVip2:setVisible(true)
            ui.setLabelString(self.coveritems.needVip1, nil, 14, 38)
            if GameScene.vip.vip < self.viplimit then
                ui.setLabelString(self.coveritems.needVip2, "贵族"..self.viplimit, 11, 38)
            else
                ui.setLabelString(self.coveritems.needVip2, "贵族"..self.viplimit, 3, 38)
            end
        end
        if GameScene.vip.vip < self.viplimit then
            ui.addGray("CCControlButton",self.coveritems.eatButton)
            self.coveritems.eatButton:addHandleOfControlEvent(function ()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                -- runGamePrompt({msg = "需要VIP"..self.viplimit.."才能迎财神"})
                runGamePrompt({msg = gameConfig.strings:need_mammon2_lv(self.viplimit)})
            end, CCControlEventTouchUpInside)
        end

        self.coveritems.paynode:setVisible(true)
        self.coveritems.pay:setString(gamedata.config.mammon[tostring(self.data.status["1"])].gold)
        self.coveritems.maxpaynum:setString(tostring(math.floor((gamedata.config.mammon[tostring(self.data.status["1"])].gold) * (gamedata.config.mammon[tostring(self.data.status["1"])].min))))
    end

    self.coveritems.goldnow:setString(self.data.gold)
end


function mammon.reloaddata(self,data)
    -- print("迎财神初始化1")
    if not self.show then return end
    self.data = data
    self.coveritems.eatButton:setSwallowsTouch(true)
    self.coveritems.eatButton:setTouchPriority(self.buttontouch)
    self.coveritems.eatButton:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
       
        if GameScene.vip.vip < self.viplimit then
            --runGamePrompt({msg = "需达到VIP"..self.viplimit.."才能迎财神"})
            runGamePrompt({msg = gameConfig.strings:need_mammon2_lv(self.viplimit)})
        else
            UIRequest({type = 2016})
        end
    end, CCControlEventTouchUpInside)

    -- print("reloaddata.num==",6-self.data.status["1"])
    if (table.getTableLength(gamedata.config.mammon)-self.data.status["1"] + 1) <= 0 then
        -- print("reloaddata...addGray")
        ui.addGray("CCControlButton",self.coveritems.eatButton)
    end

    if gameTimer.times["mammon"] and gameTimer.times["mammon"] > 0 then
        gameTimer:rigistTimeFunc("mammon",function()
            if gameTimer.times["mammon"] > 0 then
                local t = ui.makeTimeTable(gameTimer.times["mammon"])
                --self.coveritems.rest:setString(gameConfig.strings:lvtimes((6-self.data.status["1"])))
                self.coveritems.rest:setString(table.getTableLength(gamedata.config.mammon)-self.data.status["1"] + 1)
                self.coveritems.resttime:setString(gameConfig.strings:dayHourSecond(t.day,t.hour,t.minute,t.second))
                --self.coveritems.restsecond:setString(t.second)
                self.coveritems.activenode:setVisible(true)
                self.coveritems.overnode:setVisible(false)
            else
                self.coveritems.rest:setString("")
                self.coveritems.activenode:setVisible(false)
                self.coveritems.overnode:setVisible(true)
                ui.addGray("CCControlButton",self.coveritems.eatButton)
                self.coveritems.eatButton:addHandleOfControlEvent(function ()
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",15)})
                end, CCControlEventTouchUpInside)
            end
        end)
    else
        self.coveritems.rest:setString("")
        self.coveritems.activenode:setVisible(false)
        self.coveritems.overnode:setVisible(true)
        ui.addGray("CCControlButton",self.coveritems.eatButton)
        self.coveritems.eatButton:addHandleOfControlEvent(function ()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",15)})
        end, CCControlEventTouchUpInside)
    end
    self:resetdata()
end

function mammon.palybroadcast(self)
    for i=1,4 do
        if self.coveritems["broadcast"..i]:getPositionY() > 125 then
            self.coveritems["broadcast"..i]:setPositionY(-25)
            self.coveritems["broadcast"..i]:setString(self.serverbroadcast[self.broadcastindex])
            self.broadcastindex = self.broadcastindex +1
            if self.broadcastindex > 10 then
                self.broadcastindex = 1
            end
        end
        local moveTo = CCMoveTo:create(0.5, ccp(500, self.coveritems["broadcast"..i]:getPositionY()+ 50))
        self.coveritems["broadcast"..i]:runAction(moveTo)
    end

    local seq = CCSequence:createWithTwoActions(CCDelayTime:create(3), CCCallFunc:create(function()
         self:palybroadcast()
    end))
    self.coveritems.broadcastscroll:runAction(seq)
end

function mammon.reloadbroadcast(self,data)
    -- print("迎财神初始化2")
    if not self.show then return end
    for i=1,10 do
        if data.data[tostring(i)] then
            self.serverbroadcast[i] = data.data[tostring(i)]
        else
            self.serverbroadcast[i] = self.defaultbroadcast[i]
        end
    end

    for i=1,4 do
        self.coveritems["broadcast"..i]:setString(self.serverbroadcast[i])
    end

    self:palybroadcast()
end

function mammon.clear(self)
    self.broadcastindex = 5
    gameTimer:UnrigistTimeFunc("mammon")
    self.show = false

    self.data = nil
    self.coverccb = nil
    self.coveritems = nil

    self.viplimit = 0
end

return mammon