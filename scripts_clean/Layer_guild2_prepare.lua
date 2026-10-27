--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local guildprepare = {

    buttontouch = -102,
    resource = nil,

    rootNode = nil,
    rootItems = nil,

    GuildWarInspire = {},
    GuildWarPrepare = {},
    GuildWarMembers = {},

    pointId = 1,
    attacknum = 0,
    keepnum = 0,
}

function guildprepare.init(self,parent,toppos,data)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghuizhan/gonghuizhan_zhunbei", nil, true, "zhunbei")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    --
    if data and data.pointId then
        self.pointId = data.pointId
    end

    -- 鼓舞说明
    self.rootItems.ruleButton:setTouchPriority(self.buttontouch)
    self.rootItems.ruleButton:setSwallowsTouch(true)
    self.rootItems.ruleButton:addHandleOfControlEvent(function()
        print("ruleButton")
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("inspireRule",nil,nil)
    end, CCControlEventTouchUpInside)
    -- 聊天
    self.rootItems.chatButton:setTouchPriority(self.buttontouch)
    self.rootItems.chatButton:setSwallowsTouch(true)
    self.rootItems.chatButton:addHandleOfControlEvent(function()
        print("chatButton")
        gameTouch:clickprofbytime(0.5)
        GameScene:shiftLayer("chat","up",{page = "guild"})
    end, CCControlEventTouchUpInside)
    -- 退出战场
    self.rootItems.exitButton:setTouchPriority(self.buttontouch)
    self.rootItems.exitButton:setSwallowsTouch(true)
    self.rootItems.exitButton:addHandleOfControlEvent(function()
        print("exitButton")
        gameTouch:clickprofbytime(0.5)
        --GameScene:shiftLayer(GameScene.priorLayer,"up")
        --GameScene:shiftLayer("gangwar_main","up")
        UIRequest({type = 2130, param = "main"})
    end, CCControlEventTouchUpInside)
    -- 银币鼓舞
    self.rootItems.inspire_coin_button:setTouchPriority(self.buttontouch)
    self.rootItems.inspire_coin_button:setSwallowsTouch(true)
    self.rootItems.inspire_coin_button:addHandleOfControlEvent(function()
        print("inspire_coin_button")
        gameTouch:clickprofbytime(0.5)
        if self.GuildWarPrepare.status and self.GuildWarPrepare.status ~= 1 then
            runGamePrompt({msg = "战场准备时间已过,不可鼓舞"})
        elseif self.GuildWarInspire.coinInspireTimes and self.GuildWarInspire.coinInspireTimes >= tonumber(gamedata.config.global_kv.silver_inspire_times.value) then
            runGamePrompt({msg = "银币鼓舞已达次数上限"})
        else
            UIRequest({type = 2136, coin = tonumber(gamedata.config.global_kv.silver_inspire_cost.value) or 0})
        end
    end, CCControlEventTouchUpInside)
    -- 元宝鼓舞
    self.rootItems.inspire_gold_button:setTouchPriority(self.buttontouch)
    self.rootItems.inspire_gold_button:setSwallowsTouch(true)
    self.rootItems.inspire_gold_button:addHandleOfControlEvent(function()
        print("inspire_gold_button")
        gameTouch:clickprofbytime(0.5)
        if self.GuildWarPrepare.status and self.GuildWarPrepare.status ~= 1 then
            runGamePrompt({msg = "战场准备时间已过,不可鼓舞"})
        elseif self.GuildWarInspire.goldInspireTimes and self.GuildWarInspire.goldInspireTimes >= tonumber(gamedata.config.global_kv.gold_inspire_times.value) then
            runGamePrompt({msg = "元宝鼓舞已达次数上限"})
        else
            UIRequest({type = 2137, gold = tonumber(gamedata.config.global_kv.gold_inspire_cost.value) or 0})
        end
    end, CCControlEventTouchUpInside)
    -- 参加战斗
    self.rootItems.joinButton:setTouchPriority(self.buttontouch)
    self.rootItems.joinButton:setSwallowsTouch(true)
    self.rootItems.joinButton:addHandleOfControlEvent(function()
        print("joinButton")
        gameTouch:clickprofbytime(0.5)
        --todo 二次确认
        if self.GuildWarPrepare.status and self.GuildWarPrepare.status ~= 1 then
            runGamePrompt({msg = "战场准备时间已过,不可参战或取消"})
        elseif self.GuildWarInspire.status and self.GuildWarInspire.status == self.pointId then
            UIRequest({type = 2135,id = self.pointId, opt = 0})
        else
            UIRequest({type = 2135,id = self.pointId, opt = 1})
        end
    end, CCControlEventTouchUpInside)

    --
    if data then
        self:ReloadData(data)
    else
        UIRequest({type = 2134, id = self.pointId})
    end

end

function guildprepare.clear(self)
    if gameTimer.times["guildprepare"] then
        gameTimer:UnrigistTimeFunc("guildprepare")
    end

    self.GuildWarInspire = {}
    self.GuildWarPrepare = {}
    self.GuildWarMembers = {}

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end




function guildprepare.ReloadData(self,data)

    if data and data.GuildWarInspire then
        self.GuildWarInspire = data.GuildWarInspire
    end
    if data and data.GuildWarPrepare then
        self.GuildWarPrepare = data.GuildWarPrepare
    end
    if data and data.GuildWarMembers then
        self.GuildWarMembers = data.GuildWarMembers
    end

    --
    self:setPrepare()
    self:setInspire()
    self:setMembers()

end

function guildprepare.ReloadInspire(self,data)

    if data and data.GuildWarInspire then
        self.GuildWarInspire = data.GuildWarInspire
    end

    --
    self:setInspire()

end

function guildprepare.ReloadMembers(self,data)

    if data and data.GuildWarMembers then
        self.GuildWarMembers = data.GuildWarMembers
    end

    --
    self:setMembers()

end


function guildprepare.setPrepare(self,data)

    self.rootItems.a_name:setString(self.GuildWarPrepare.attackName or "")
    self.rootItems.d_name:setString(self.GuildWarPrepare.keepName or "")

    ui.setLabelString(self.rootItems.timeLab,"",22)
    ui.setLabelString(self.rootItems.time,"",22)

    if self.GuildWarPrepare.status and self.GuildWarPrepare.status == 1 then
        ui.setLabelString(self.rootItems.timeLab,"战场准备倒计时: ",22)
    elseif self.GuildWarPrepare.status and self.GuildWarPrepare.status == 2 then
        ui.setLabelString(self.rootItems.timeLab,"开战倒计时: ",22)
    else
        --GameScene:shiftLayer("gangwar_main","up")
        UIRequest({type = 2130, param = "main"})
    end
    --
    if gameTimer.times["guildprepare"] and gameTimer.times["guildprepare"] > 0 then
        gameTimer:rigistTimeFunc("guildprepare",function()

            if not self.rootItems then return end

            if  gameTimer.times["guildprepare"] <= 0 then
                gameTimer:UnrigistTimeFunc("guildprepare")
                ui.setLabelString(self.rootItems.timeLab,"",22)
                ui.setLabelString(self.rootItems.time,"",22)
                UIRequest({type = 2134, id = self.pointId})
            else
                ui.setLabelString(self.rootItems.time, ui.makeTimeText(gameTimer.times["guildprepare"],"hour"), 22)
            end
        end)
    end
    --
end

function guildprepare.setInspire(self,data)

    ui.setLabelString(self.rootItems.inspire_coin_num,gamedata.config.global_kv.silver_inspire_cost.value or 0,13)
    ui.setLabelString(self.rootItems.inspire_gold_num,gamedata.config.global_kv.gold_inspire_cost.value or 0,13)
    --
    if self.rootItems.inspire_coin_times and self.rootItems.inspire_gold_times then
        ui.setLabelString(self.rootItems.inspire_coin_times,"次数: "..(self.GuildWarInspire.coinInspireTimes or 0).."/"..(tonumber(gamedata.config.global_kv.silver_inspire_times.value) or 0),13)
        ui.setLabelString(self.rootItems.inspire_gold_times,"次数: "..(self.GuildWarInspire.goldInspireTimes or 0).."/"..(tonumber(gamedata.config.global_kv.gold_inspire_times.value) or 0),13)
    end
    --
    self.rootItems.atk_num:setString("攻击: "..(self.GuildWarInspire.atkBuff or 0).."%")
    self.rootItems.def_num:setString("防御: "..(self.GuildWarInspire.defBuff or 0).."%")
    self.rootItems.win_num:setString("连胜场次: "..(self.GuildWarInspire.winMax or 0))
    --
    local victory1 = tonumber(gamedata.config.global_kv.victory_times1.value) or 0
    local victory2 = tonumber(gamedata.config.global_kv.victory_times2.value) or 0


    if self.GuildWarInspire.goldInspireTimes and self.GuildWarInspire.goldInspireTimes < victory1 then
        ui.setLabelString(self.rootItems.inspireLab,"元宝鼓舞"..(victory1-self.GuildWarInspire.goldInspireTimes).."("..victory1..")".."次可以增加连胜场次1次",22)
    elseif self.GuildWarInspire.goldInspireTimes and self.GuildWarInspire.goldInspireTimes < victory2 then
        ui.setLabelString(self.rootItems.inspireLab,"元宝鼓舞"..(victory2-self.GuildWarInspire.goldInspireTimes).."("..victory2..")".."次可以增加连胜场次1次",22)
    else
        ui.setLabelString(self.rootItems.inspireLab,"",22)
    end
    --
    if self.GuildWarInspire.status and self.GuildWarInspire.status == self.pointId then
        self.rootItems.joinsprite_out:setVisible(true)
        self.rootItems.joinsprite_in:setVisible(false)
    else
        self.rootItems.joinsprite_out:setVisible(false)
        self.rootItems.joinsprite_in:setVisible(true)
    end
    --
end

function guildprepare.setMembers(self,data)

    if self.GuildWarMembers[tostring(self.pointId)] then
        self.attacknum = table.getTableLength(self.GuildWarMembers[tostring(self.pointId)].attackMembers) or 0
        self.keepnum = table.getTableLength(self.GuildWarMembers[tostring(self.pointId)].keepMembers) or 0
        self.rootItems.a_num:setString(self.attacknum)
        self.rootItems.d_num:setString(self.keepnum)

        for i = 1,10 do

           if self.GuildWarMembers[tostring(self.pointId)].keepMembers[tostring(i)] then
               ui.setNewIconName(self.rootItems,{cid = self.GuildWarMembers[tostring(self.pointId)].keepMembers[tostring(i)].profile},i-1)
               ui.setLabelString(self.rootItems["in_name"..( i>1 and ("_"..i-1) or "")],self.GuildWarMembers[tostring(self.pointId)].keepMembers[tostring(i)].name,1)
           else
               ui.setNewIconName(self.rootItems,{cid = 0},i-1)
           end

           if self.GuildWarMembers[tostring(self.pointId)].attackMembers[tostring(i)] then
               ui.setNewIconName(self.rootItems,{cid = self.GuildWarMembers[tostring(self.pointId)].attackMembers[tostring(i)].profile},i+9)
               ui.setLabelString(self.rootItems["in_name_"..(i+9)],self.GuildWarMembers[tostring(self.pointId)].attackMembers[tostring(i)].name,1)
           else
               ui.setNewIconName(self.rootItems,{cid = 0},i+9)
           end

        end
    end

end

return guildprepare


