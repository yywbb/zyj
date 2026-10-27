--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/26
-- Time: 下午6:47
-- To change this template use File | Settings | File Templates.
--

local cornucopia = {

    buttontouch = -103,
    data = {},
}

function cornucopia.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitymoney/money",nil, true, "money")
    self.animationManager = getAnimationManager(self.coveritems)
    self.animationManager:runAnimationsForSequenceNamed("first")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.midnode:setPositionY((self.contentsize.y-160)/2+60)

    ui.setLabelString(self.coveritems.lab1,nil,18)
    ui.setLabelString(self.coveritems.lab2,nil,18)
    ui.setLabelString(self.coveritems.lab4,nil,18)
    if self.coveritems.lab3 then
        ui.setLabelString(self.coveritems.lab3,nil,18)
    end

    self.coveritems.helpButton:setTouchPriority(self.buttontouch)
    self.coveritems.helpButton:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("cornucopiaRule",nil,nil)
    end, CCControlEventTouchUpInside)
    self.coveritems.helpButton:setVisible(gameConfig:checkBuildOpen(154))
    return self.coverccb
end

function cornucopia.reloaddata(self,data)
    if not self.show then return end

    ui.setLabelString(self.coveritems.doLab,"聚宝1次",19)
    ui.setLabelString(self.coveritems.doLab2,"聚宝5次",19)

    self.data = data.cornucopia or {}
    --
    local totalcount = gamedata.config.vip[tostring(GameScene.vip.vip)]["shake_times"] or 0
    local costcount = (self.data.count or 0)-(self.data.ad or 0)
    if costcount < 0 then costcount = 0 end
    local countnum = (totalcount) - (costcount)
    ui.setLabelString(self.coveritems.countnum,countnum.." / "..(gamedata.config.vip[tostring(GameScene.vip.vip)]["shake_times"] or 0),21)
    

    local goldnum,goldnum5 = 0,0
    local priceconfig = gamedata.config.buycount_price
    local configlen = table.getTableLength(gamedata.config.buycount_price)
    if countnum > 0 then
        local oneidx = tostring(costcount+1)
        goldnum = priceconfig[oneidx] and priceconfig[oneidx].shake_cost or priceconfig[tostring(configlen)].shake_cost
        
        local max = math.min(costcount+5,totalcount)
        for i=costcount+1,max do
            goldnum5 = goldnum5 + (priceconfig[tostring(i)] and priceconfig[tostring(i)].shake_cost or priceconfig[tostring(configlen)].shake_cost)
        end

        ui.setLabelString(self.coveritems.doLab2,"聚宝"..(max-costcount).."次",19)

        -- if gamedata.config.buycount_price[tostring(self.data.count+1)] and gamedata.config.buycount_price[tostring(self.data.count+1)].shake_cost then
        --     goldnum = gamedata.config.buycount_price[tostring(self.data.count+1)].shake_cost+0
        -- elseif gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))] and gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].shake_cost then
        --     goldnum = gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].shake_cost+0
        -- end

        if goldnum > 0 then
            self.coveritems.goldnode:setVisible(true)
            ui.setLabelString(self.coveritems.goldnum,goldnum,21)
        else
            self.coveritems.goldnode:setVisible(false)
            ui.setLabelString(self.coveritems.goldnum,"免费",21)
        end

        if goldnum5 > 0 then
            self.coveritems.goldnode2:setVisible(true)
            ui.setLabelString(self.coveritems.goldnum2,goldnum5,21)
        else
            self.coveritems.goldnode2:setVisible(false)
            ui.setLabelString(self.coveritems.goldnum2,"免费",21)
        end
    
        ui.removeGray("CCControlButton",self.coveritems["doButton"])
        ui.removeGray("CCControlButton",self.coveritems["doButton2"])
    else
        ui.addGray("CCControlButton",self.coveritems["doButton"])
        ui.addGray("CCControlButton",self.coveritems["doButton2"])
        self.coveritems.goldnode:setVisible(false)
        self.coveritems.goldnode2:setVisible(false)
        ui.setLabelString(self.coveritems.goldnum,"",21)
        ui.setLabelString(self.coveritems.goldnum2,"",21)
    end

    self.coveritems.doButton:setTouchPriority(self.buttontouch)
    self.coveritems.doButton:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)
        if countnum > 0 then
            UIRequest({type = 2032, xgold = goldnum,num=1,payType=0})
        else
            runGamePrompt({msg = "今日聚宝次数已用完"})
        end
        if guide.controller then
            guide.controller:UIComplete(10081)
        end
    end, CCControlEventTouchUpInside)

    self.coveritems.doButton2:setTouchPriority(self.buttontouch)
    self.coveritems.doButton2:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)
        if countnum > 0 then
            UIRequest({type = 2032, xgold = goldnum5,num=5,payType=0})
        else
            runGamePrompt({msg = "今日聚宝次数已用完"})
        end
    end, CCControlEventTouchUpInside)

    --免费聚宝
    local ad = require"adChannel"
    if ad:showOrNot() then
        local adNum = gamedata.config.global_kv.cornucopia_ad_limit.value - self.data.ad
        if self.coveritems.hint_adButton then
            ui.sethint(self.coveritems.hint_adButton,false)
            if adNum > 0 then
                ui.sethint(self.coveritems.hint_adButton,true)
            end
        end

        local callback = function(num)
            gamedata.sdk:showAd(1,{type = 2032, xgold = 0,num=1,payType=1})
        end
        self.coveritems.watchad:setVisible(true)
        self.coveritems.adButton:setTouchPriority(self.buttontouch)
        self.coveritems.adButton:addHandleOfControlEvent(function ()
            if adNum > 0 then
                gameWindows:openWindow("adCueboard",{msg = string.format(gameConfig.strings:string_common("fixedString","adCueboard",3),adNum)},callback)
            else
                runGamePrompt({msg = "今日免费聚宝次数已用完"})
            end

        end, CCControlEventTouchUpInside)
    else
        self.coveritems.watchad:setVisible(false)
    end

    --
    local shakeconfig = gamedata.config.shake_param[tostring(GameScene.roleinfo.level)] or gamedata.config.shake_param[tostring(table.getTableLength(gamedata.config.shake_param))]

    if self.coveritems.coinnum then
        ui.setLabelString(self.coveritems.coinnum,shakeconfig.shake_money or "",18)
    end    

    if self.data.count and (self.data.count < shakeconfig.shake_max_award) then
        ui.setSpriteTextureRect2(self.coveritems["exp"],0,0,741 * (self.data.count / shakeconfig.shake_max_award),31)
    else
        ui.setSpriteTextureRect2(self.coveritems["exp"],0,0,741,31)
    end

    for i = 1,3 do
        ui.setLabelString(self.coveritems["box_lab"..i],"聚宝"..shakeconfig["shake_award"..i].."次",14)
        if self.data["box"..i] and self.data["box"..i] == 2 then
            setSpriteFrameByName(self.coveritems["box_sprite"..i],"box4_2")
        elseif self.data["box"..i] and self.data["box"..i] == 1 then
            setSpriteFrameByName(self.coveritems["box_sprite"..i],"box4_1")
        else
            setSpriteFrameByName(self.coveritems["box_sprite"..i],"box4_0")
        end

        self.coveritems["box_button"..i]:setTouchPriority(self.buttontouch)
        self.coveritems["box_button"..i]:addHandleOfControlEvent(function ()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            if self.data["box"..i] and self.data["box"..i] == 2 then
                gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(shakeconfig["shake"..(i*10)]),type = "已领取"},nil)
            elseif self.data["box"..i] and self.data["box"..i] == 1 then
                UIRequest({type = 2033, index = i})
            else
                gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(shakeconfig["shake"..(i*10)]),type = "奖励预览"},nil)
            end
        end, CCControlEventTouchUpInside)

    end

end

function cornucopia.play(self,data)
    if not self.show then return end
    if not data then return end
    gameTouch:clickprofbytime(4)
    self.coveritems.doButton:setEnabled(false)
    self.coveritems.doButton2:setEnabled(false)

    gameTimer:rigistTime("cornucopia_play", 4)
    gameTimer:rigistTimeFunc("cornucopia_play",function()
        if gameTimer.times["cornucopia_play"] > 0 then
            ui.setLabelString(self.coveritems.doLab,"聚宝中"..gameTimer.times["cornucopia_play"].."秒",21)
            ui.setLabelString(self.coveritems.doLab2,"聚宝中"..gameTimer.times["cornucopia_play"].."秒",21)
        end
        if gameTimer.times["cornucopia_play"] <= 0 then
            self:reloaddata(data)
            gameTimer:UnrigistTimeFunc("cornucopia_play")
        end
    end)


    if self.coveritems.effectnode then
        self.coveritems.effectnode:removeAllChildrenWithCleanup(true)
    end

    self.animationManager:setAnimationCompletedCallback(function()
        self:playMoneyEffect(data,1)
        
    end)
    self.animationManager:runAnimationsForSequenceNamed("play")

end

function cornucopia.playMoneyEffect(self,data,num)
    if data.ext[tostring(num)] and data.ext[tostring(num)] > 1 and data.ext[tostring(num)] <= 10 then
        local ccb,items = CCBReaderLoad("UIEffect/jubaopen/jubaopen",nil, true, "money")
        if ccb and items and self.coveritems.effectnode then
            gameTouch:clickprofbytime(2.2)
            local animationManager = getAnimationManager(items)
            animationManager:setAnimationCompletedCallback(function()
                self.coveritems.effectnode:removeAllChildrenWithCleanup(true)
                if data.ext[tostring(num+1)] then
                    self:playMoneyEffect(data,num+1)
                else
                    self.coveritems.doButton:setEnabled(true)
                    self.coveritems.doButton2:setEnabled(true)
                    showRewardPopupWindow(data.reward,nil,nil)
                end
            end)
            self.coveritems.effectnode:addChild(ccb)
            --
            setSpriteFrameByName(items.num1,"money_baoji_"..data.ext[tostring(num)])
            setSpriteFrameByName(items.num2,"money_baoji_"..data.ext[tostring(num)])
            setSpriteFrameByName(items.num3,"money_baoji_"..data.ext[tostring(num)])
            --
            --gameTouch:clickprofbytime(2)
            if data.ext[tostring(num)] > 9 then
                animationManager:runAnimationsForSequenceNamed("9-10")
            elseif data.ext[tostring(num)] < 6 then
                animationManager:runAnimationsForSequenceNamed("2-5")
            else
                animationManager:runAnimationsForSequenceNamed("6-8")
            end
        else
            if data.ext[tostring(num+1)] then
                    self:playMoneyEffect(data,num+1)
            else
                runGamePrompt({msg = data.ext.."倍暴击"})
                showRewardPopupWindow(data.reward,nil,nil)
                self.coveritems.doButton:setEnabled(true)
                self.coveritems.doButton2:setEnabled(true)
            end
        end
    else
        if data.ext[tostring(num+1)] then
            self:playMoneyEffect(data,num+1)
        else
            showRewardPopupWindow(data.reward,nil,nil)
            self.coveritems.doButton:setEnabled(true)
            self.coveritems.doButton2:setEnabled(true)
        end
    end

end

function cornucopia.clear(self)
    self.show = false

    self.coverccb = nil
    self.coveritems = nil
    if gameTimer.times["cornucopia_play"] == 0 then
        gameTimer:UnrigistTimeFunc("cornucopia_play")
    end
end


return cornucopia�0  