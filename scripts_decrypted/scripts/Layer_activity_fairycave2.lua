--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/1/4
-- Time: 10:45
-- To change this template use File | Settings | File Templates.
--


local fairycave = {

    buttontouch = -103,

    data = {},
    olddata = {},
    hasforecast = false,
    isplayeffect = false,
    gnum = 0,
    xnum = 0,
    rightnum = 0,
    lastright = 0,
    starsprite = {
        [8] = "g_beiji",
        [3] = "g_lianzhen",
        [5] = "g_lucun",
        [1] = "g_pojun",
        [7] = "g_tanlang",
        [4] = "g_wenqu",
        [2] = "g_wuqu",
        [6] = "g_jumen",
    },

    starstring = {
        [8] = "g_zi_beiji",
        [3] = "g_zi_lianzhen",
        [5] = "g_zi_lucun",
        [1] = "g_zi_pojun",
        [7] = "g_zi_tanlang",
        [4] = "g_zi_wenqu",
        [2] = "g_zi_wuqi",
        [6] = "g_zi_jumen",
    },

    oldstarsprite = {
        [8] = "g_beiji",
        [3] = "g_lianzhen",
        [5] = "g_lucun",
        [1] = "g_pojun",
        [7] = "g_tanlang",
        [4] = "g_wenqu",
        [2] = "g_wuqu",
        [6] = "g_jumen",
    },

    oldstarstring = {
        [8] = "g_zi_beiji",
        [3] = "g_zi_lianzhen",
        [5] = "g_zi_lucun",
        [1] = "g_zi_pojun",
        [7] = "g_zi_tanlang",
        [4] = "g_zi_wenqu",
        [2] = "g_zi_wuqi",
        [6] = "g_zi_jumen",
    },
    firstdata = 0,


}

function fairycave.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitystar/guanxingtai2.ccbi",nil, true, "guanxingtai")
    self.coveritems.topnode:setPositionY(self.contentsize.y-240)
    self.coveritems.midnode:setPositionY(self.contentsize.y/2+200)
    self.coveritems.midnode2:setPositionY(300)

    self.coveritems["show_rule"]:setTouchPriority(self.buttontouch)
    self.coveritems["show_rule"]:addHandleOfControlEvent(function()
        print("show_rule")
        gameWindows:openWindow("starRule",nil)
    end,CCControlEventTouchUpInside)

    self.coveritems["show_reward"]:setTouchPriority(self.buttontouch)
    self.coveritems["show_reward"]:addHandleOfControlEvent(function()
        print("show_reward")
        gameWindows:openWindow("starGetReward",self.data)
    end,CCControlEventTouchUpInside)

    --
    ui.setLabelString(self.coveritems["forecasttext"],nil,19)
    self.coveritems["forecastButton"]:setTouchPriority(self.buttontouch)
    self.coveritems["forecastButton"]:addHandleOfControlEvent(function()
        print("forecastButton")
        gameTouch:clickprofbytime(1)
        if self.gnum and self.gnum > 0 then
            UIRequest({type = 2063})
        else
            -- runGamePrompt({msg = "今日观星次数已用完"})
            runGamePrompt({msg = gameConfig.strings:string_common("fairycave",8)})
        end
    end,CCControlEventTouchUpInside)

    ui.setLabelString(self.coveritems["reversiontext"],nil,19)
    self.coveritems["reversionButton"]:setTouchPriority(self.buttontouch)
    self.coveritems["reversionButton"]:addHandleOfControlEvent(function()
        print("reversionButton")
        gameTouch:clickprofbytime(1)
        if self.isplayeffect then return end
        if self.rightnum < 8 then
            UIRequest({type = 2064, xnum = self.xnum})
        else
            -- runGamePrompt({msg = "本次观星已全部点亮"})
            runGamePrompt({msg = gameConfig.strings:string_common("fairycave",7)})
        end
    end,CCControlEventTouchUpInside)

    ui.setLabelString(self.coveritems["gettext"],nil,19)
    self.coveritems["getButton"]:setTouchPriority(self.buttontouch)
    self.coveritems["getButton"]:addHandleOfControlEvent(function()
        print("getButton")
        gameTouch:clickprofbytime(1)
        if self.isplayeffect then return end

        UIRequest({type = 2065})

        local Node,Items = CCBReaderLoad("UIEffect/lizi/tuowei", nil, true, "tuowei")
        Node:setPosition(0,0)
        self.coveritems.geteffectNode:addChild(Node)
        local moveto2 = CCMoveTo:create(1.5, ccp(0,-600))
        Node:runAction(CCSequence:createWithTwoActions(moveto2,CCCallFunc:create(function()
            Node:removeFromParentAndCleanup(true)
        end)))

    end,CCControlEventTouchUpInside)
    --

    local day = 1
    local dayconfig = gamedata.config.watchstar_position or {}
    day = os.date("%w",gamedata:time())+0
    if day < 1 or day > 7 then day = 7 end
    for k,v in pairs(dayconfig) do
        if v.day == day then
            for i = 1,8 do
                self.starsprite[i] = self.oldstarsprite[v["position"..i]]
                self.starstring[i] = self.oldstarstring[v["position"..i]]
            end
        end
    end
    --

    --self.coveritems["pos"]:setScaleX(0)
    self.coveritems["partical"]:setPosition(-470,-50)
    --




    local luckSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("obj_15.png"))
    self.coveritems.posSp = CCProgressTimer:create(luckSpr);
    self.coveritems.posSp:setAnchorPoint(ccp(0.5,0.5))
    self.coveritems.posSp:setType(kCCProgressTimerTypeBar)
    self.coveritems.posSp:setMidpoint(ccp(0,0.5))
    self.coveritems.posSp:setBarChangeRate(ccp(1,0))
    self.coveritems.posSp:setPosition(ccp(0,0))
    self.coveritems.posSp:setScaleX(1.18)
    self.coveritems.posSp:setPercentage(0)
    self.coveritems.posnode:addChild(self.coveritems.posSp)

    return self.coverccb
end


function fairycave.reloaddata(self,data)
    if not self.show then return end
    self.data = data or {}
    self.olddata = {}
    self:cleaneffect()
    self:setstarnum()
    if self.hasforecast then
        self.coveritems.startNode:setVisible(false)
        self.coveritems.changeNode:setVisible(true)
        --self:playeffect()
        for i = 1,8 do
            self.coveritems["starccb"..i]:removeAllChildrenWithCleanup(true)
            local starNode,starItems = CCBReaderLoad("activitystar/star_star", nil, true, "star")
            starNode:setPosition(0,0)
            self.coveritems["starccb"..i]:addChild(starNode)

            setSpriteFrameByName(starItems.star_base,self.starsprite[i])
            setSpriteFrameByName(starItems.star_a,self.starsprite[self.data.starstatus[tostring(i)] > 0 and self.data.starstatus[tostring(i)] or i])
            setSpriteFrameByName(starItems.star_b,self.starsprite[self.data.starstatus[tostring(i)] > 0 and self.data.starstatus[tostring(i)] or i])

            starItems["playstarnode"]:setVisible(false)

            if self.data.starstatus[tostring(i)] == i then
                starItems.effectnode:removeAllChildrenWithCleanup(true)
                local effectNode,effectItems = CCBReaderLoad("UIEffect/guanxing/guanxing", nil, true, "star")
                effectNode:setPosition(0,0)
                starItems.effectnode:addChild(effectNode)
            end
        end
        --
        self.isplayeffect = false
        local startconfig = gamedata.config.watchstar_starextra or {}
        self.coveritems["right_num"]:setString(self.rightnum)
        self.coveritems["reward_num"]:setString(startconfig[tostring(self.rightnum)] and startconfig[tostring(self.rightnum)].extra or 0)
        self.lastright = self.rightnum
        --
    else
        self.coveritems.startNode:setVisible(true)
        self.coveritems.changeNode:setVisible(false)
        local startconfig = gamedata.config.watchstar_starextra or {}
        self.coveritems["right_num"]:setString(self.rightnum)
        self.coveritems["reward_num"]:setString(startconfig[tostring(self.rightnum)] and startconfig[tostring(self.rightnum)].extra or 0)
        self.lastright = self.rightnum
    end

end


function fairycave.playdata(self,data)
    if not self.show then return end
    self.olddata = table.copy(self.data) or {}
    self.data = data or {}

    self:setstarnum()
    if self.hasforecast then
        self.coveritems.startNode:setVisible(false)
        self.coveritems.changeNode:setVisible(true)
        self:playeffect()
    else
        self.coveritems.startNode:setVisible(true)
        self.coveritems.changeNode:setVisible(false)
    end

end


function fairycave.setstarnum(self)
    self.hasforecast = false
    self.rightnum = 0
    local startconfig = gamedata.config.watchstar_starextra or {}
    self.coveritems["star_num"]:setString(self.data.starnum or 0)

    if  self.data.starstatus and self.data.starstatus["1"] and self.data.starstatus["1"] > 0 then
        self.hasforecast = true
        for i = 1,8 do
            if  self.data.starstatus[tostring(i)] and self.data.starstatus[tostring(i)] == i then
                self.rightnum = self.rightnum + 1
            end
        end
    end

    self.coveritems["getnum"]:setString("")
    self.coveritems["getnum_bg"]:setVisible(false)
    if self.data.rewardstatus then
        local getnum = 0
        for k,v in pairs(self.data.rewardstatus) do
            getnum = getnum + (v == 1 and 1 or 0)
        end
        if getnum >= 1 then
            self.coveritems["getnum"]:setString(getnum)
            self.coveritems["getnum_bg"]:setVisible(true)
        end
    end

    --self.coveritems["right_num"]:setString(self.rightnum)
    --self.coveritems["reward_num"]:setString(startconfig[tostring(self.rightnum)] and startconfig[tostring(self.rightnum)].extra or 0)
    --
    self.gnum = 0
    if self.data.forecastnum and gamedata.config.vip[tostring(GameScene.vip.vip)].c_watchstar_watch then
        self.gnum = gamedata.config.vip[tostring(GameScene.vip.vip)].c_watchstar_watch - self.data.forecastnum
    end
    -- self.coveritems["des"]:setString("今日还可观星"..self.gnum.."次")
    self.coveritems["des"]:setString(gameConfig.strings:swtchStarNum(self.gnum))

    if self.gnum < 1 then
        ui.addGray("CCControlButton",self.coveritems.forecastButton)
        ui.addGray("CCLabelTTF",self.coveritems.forecasttext)
    else
        ui.removeGray("CCControlButton",self.coveritems.forecastButton)
        ui.removeGray("CCLabelTTF",self.coveritems.forecasttext)
    end
    --
    local allnum = gamedata.config.watchstar_reward["10"] and gamedata.config.watchstar_reward["10"].star or 1
    --self.coveritems["pos"]:setScaleX(self.data.starnum < allnum and self.data.starnum / allnum or 1)
    --self.coveritems["partical"]:setPosition((self.data.starnum < allnum and 940*self.data.starnum/allnum-470 or 470),-50)

    -- local ScaleTo = CCScaleTo:create(1,self.data.starnum < allnum and self.data.starnum / allnum or 1,1)
    -- self.coveritems["pos"]:runAction(ScaleTo)
    local processNum = 100*(self.data.starnum < allnum and self.data.starnum / allnum or 1)
    local luckTo = CCProgressFromTo:create(1,self.firstdata,processNum)
    self.coveritems.posSp:runAction(luckTo)
    self.firstdata = processNum


    local Moveto = CCMoveTo:create(1, ccp((self.data.starnum < allnum and 940*self.data.starnum/allnum-470 or 470),-50))
    self.coveritems["partical"]:runAction(Moveto)
    --
    self.cnum = 0
    self.xnum = 0
    local xgoldconfig = {}
    if gamedata.config.watchstar_change then
        for k,v in pairs(gamedata.config.watchstar_change) do
            table.insert(xgoldconfig,v)
        end
        local sortfunc = function (a,b)
             return a["count"] < b["count"]
        end
        table.sort(xgoldconfig,sortfunc)
    end
    if self.data.changenum and gamedata.config.vip[tostring(GameScene.vip.vip)].c_watchstar_change then
        self.cnum = self.data.changenum - gamedata.config.vip[tostring(GameScene.vip.vip)].c_watchstar_change
    end
    if self.cnum < 0 then
        self.coveritems.goldnode:setVisible(false)
        self.coveritems.freeRevers:setVisible(true)
        self.coveritems.hint:setVisible(true)
        -- self.coveritems.freeRevers:setString("可免费换星"..0-self.cnum.."次")
        self.coveritems.freeRevers:setString(gameConfig.strings:swtchStarfreeNum((0-self.cnum)))
    else
        self.coveritems.goldnode:setVisible(true)
        self.coveritems.freeRevers:setVisible(false)
        self.coveritems.hint:setVisible(false)
        for k,v in ipairs(xgoldconfig) do
            if self.cnum+1 >= v.count then
                self.xnum = v.watchstar_change or 0
            end
        end
        self.coveritems.revisiongold:setString(self.xnum)
    end

end

function fairycave.cleaneffect(self)
    self.isplayeffect = false
    for i = 1,8 do
        self.coveritems["starccb"..i]:removeAllChildrenWithCleanup(true)
        local starNode,starItems = CCBReaderLoad("activitystar/star_star", nil, true, "star")
        starNode:setPosition(0,0)
        self.coveritems["starccb"..i]:addChild(starNode)
        starItems["playstarnode"]:setVisible(false)
        setSpriteFrameByName(starItems.star_base,self.starsprite[i])
        setSpriteFrameByName(self.coveritems["star_name"..i],self.starstring[i])
    end
end

function fairycave.playeffect(self,index)

    local s_index = index or 1
    if s_index > 8 then
        self.isplayeffect = false
        local startconfig = gamedata.config.watchstar_starextra or {}
        self.coveritems["right_num"]:setString(self.rightnum)
        self.coveritems["reward_num"]:setString(startconfig[tostring(self.rightnum)] and startconfig[tostring(self.rightnum)].extra or 0)
        if self.coveritems.upNode and self.rightnum > self.lastright then
            self.coveritems.upNode:removeAllChildrenWithCleanup(true)
            local Node,Items = CCBReaderLoad("UIEffect/up_down/up", nil, true, "do")
            Node:setPosition(0,0)
            self.coveritems.upNode:addChild(Node)
            local animationManager = getAnimationManager(Items)
            animationManager:setAnimationCompletedCallback(function()
                self.coveritems.upNode:removeAllChildrenWithCleanup(true)
            end)
            animationManager:runAnimationsForSequenceNamed("up")
        end
        self.lastright = self.rightnum
        return
    end
    self.isplayeffect = true

    if  self.olddata.starstatus and self.olddata.starstatus[tostring(s_index)] and self.olddata.starstatus[tostring(s_index)] == s_index then
        self:playeffect(s_index+1)
    else
        self.coveritems["starccb"..s_index]:removeAllChildrenWithCleanup(true)
        local starNode,starItems = CCBReaderLoad("activitystar/star_star", nil, true, "star")
        starNode:setPosition(0,0)
        self.coveritems["starccb"..s_index]:addChild(starNode)

        setSpriteFrameByName(starItems.star_base,self.starsprite[s_index])
        setSpriteFrameByName(starItems.star_a,self.starsprite[self.data.starstatus[tostring(s_index)] > 0 and self.data.starstatus[tostring(s_index)] or s_index])
        setSpriteFrameByName(starItems.star_b,self.starsprite[self.data.starstatus[tostring(s_index)] > 0 and self.data.starstatus[tostring(s_index)] or s_index])

        starItems["playstarnode"]:setVisible(true)

        local animationManager = getAnimationManager(starItems)
        animationManager:setAnimationCompletedCallback(function()
            starItems["playstarnode"]:setVisible(false)
            --
            if self.data.starstatus[tostring(s_index)] == s_index then
                starItems.effectnode:removeAllChildrenWithCleanup(true)
                local effectNode,effectItems = CCBReaderLoad("UIEffect/guanxing/guanxing", nil, true, "star")
                effectNode:setPosition(0,0)
                starItems.effectnode:addChild(effectNode)
            end
            --
            --self:playeffect(s_index+1)
        end)
        animationManager:runAnimationsForSequenceNamed(self.data.starstatus[tostring(s_index)] == s_index and "playstar" or "playstar_lose")

        self.coverccb:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
            self:playeffect(s_index+1)
        end)))

    end
end


function fairycave.clear(self)
    self.show = false
    self.firstdata = 0
    self.data = {}
    self.olddata = {}
    self.hasforecast = false
    self.isplayeffect = false
    self.gnum = 0
    self.xnum = 0
    self.rightnum = 0
    self.lastright = 0
    self.coverccb = nil
    self.coveritems = nil
    self.rewardccb,self.rewarditem = nil,nil
end



return fairycave ?  