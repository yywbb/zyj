--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local guildmain = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,

    buttontouch = -1,

    hintconfig = {
        {
            name = "rootItems",
            config = {
                main = {125,163},
                shangxiang = {124},
                xianchi = {122},
                gangboss = {268},
                guard = {350},
                activity = {268,570,571,575,576},
            },
        },
    },

}

function guildmain.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui_zhuye", nil, true, "gonghui")
    parent:addChild(self.rootNode)

    self.topposy = toppos
    self.rootItems.topnode:setPositionY(toppos)
    --self.rootItems.bgnode:setPositionY(toppos)

    self.rootItems.bgscroll = tolua.cast(self.rootItems.bgscroll, "CCScrollView")
    self.rootItems.bgscroll:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
    self.rootItems.bgscroll:setContentOffsetInDuration(ccp(0,toppos-160-1920),0)
    --
    self.rootItems.backbutton:setSwallowsTouch(true)
    self.rootItems.backbutton:setTouchPriority(self.buttontouch-2)
    self.rootItems.backbutton:addHandleOfControlEvent(function()
        --if self.isContentScroll then return end
        print("back")
        GameScene:shiftLayer("main","down")
    end, CCControlEventTouchUpInside)

    --self.rootItems.mainbutton:setSwallowsTouch(true)
    self.rootItems.mainbutton:setTouchPriority(self.buttontouch)
    self.rootItems.mainbutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("main")
        GameScene:shiftLayer("gang_manager","up",{gang = self.gang})
    end, CCControlEventTouchUpInside)

    self.rootItems.noticebutton:setSwallowsTouch(true)
    self.rootItems.noticebutton:setTouchPriority(self.buttontouch-2)
    self.rootItems.noticebutton:addHandleOfControlEvent(function()
        --if self.isContentScroll then return end
        print("notice")

    end, CCControlEventTouchUpInside)

    --商店
    --self.rootItems.shopbutton:setSwallowsTouch(true)
    self.rootItems.shopbutton:setTouchPriority(self.buttontouch)
    self.rootItems.shopbutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("other")
        -- GameScene:shiftLayer("guild_shop","up")
        GameScene:shiftLayerById(166)
    end, CCControlEventTouchUpInside)

    --上香
    --self.rootItems.incensebutton:setSwallowsTouch(true)
    self.rootItems.incensebutton:setTouchPriority(self.buttontouch)
    self.rootItems.incensebutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("gang_shangxiang")
        
        GameScene:shiftLayer("gang_shangxiang","up")
    end, CCControlEventTouchUpInside)

    --洗澡
    --self.rootItems.batheroombutton:setSwallowsTouch(true)
    self.rootItems.batheroombutton:setTouchPriority(self.buttontouch)
    self.rootItems.batheroombutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("gang_xianchi")
        
        GameScene:shiftLayer("gang_xianchi","up",{gang = self.gang})
    end, CCControlEventTouchUpInside)


    --公会战
    --self.rootItems.battlebutton:setSwallowsTouch(true)
    self.rootItems.battlebutton:setTouchPriority(self.buttontouch)
    self.rootItems.battlebutton:addHandleOfControlEvent(function()

        if self.isContentScroll then return end

        if gameConfig:checkBuildOpen(171) then
            local globalconfig = gamedata.config.global_kv
            if tonumber(self.gang.level) >= tonumber(globalconfig.gang2_signup_minlevel.value) then
                --GameScene:shiftLayer("gangwar_main","up")
                UIRequest({type = 2130, param = "main"})
            else
                runGamePrompt({msg = gameConfig.strings:guildOpenLv(globalconfig.gang2_signup_minlevel.value)})
            end
        else
            runGamePrompt({msg = "功能未开启"})
        end
        
    end, CCControlEventTouchUpInside)

    --显示军团信息
    self.rootItems.guilddynamic:setSwallowsTouch(true)
    self.rootItems.guilddynamic:setTouchPriority(self.buttontouch-2)
    self.rootItems.guilddynamic:addHandleOfControlEvent(function()
        --if self.isContentScroll then return end
        UIRequest({type = 2254})
    end, CCControlEventTouchUpInside)

    self.rootItems.otherguild:setSwallowsTouch(true)
    self.rootItems.otherguild:setTouchPriority(self.buttontouch-2)
    self.rootItems.otherguild:addHandleOfControlEvent(function()
        --if self.isContentScroll then return end
        print("other")
        GameScene:shiftLayer("gang_list","up",{opt = 2})
    end, CCControlEventTouchUpInside)

    --self.rootItems.skillbutton:setSwallowsTouch(true)
    self.rootItems.skillbutton:setTouchPriority(self.buttontouch)
    self.rootItems.skillbutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("工会技能")

        if gameConfig:checkBuildOpen(172) then
            GameScene:shiftLayerById(172)
        else
            runGamePrompt({msg = "功能未开启"})
        end

    end, CCControlEventTouchUpInside)

        --self.rootItems.guardbutton:setSwallowsTouch(true)
    self.rootItems.guardbutton:setTouchPriority(self.buttontouch)
    self.rootItems.guardbutton:addHandleOfControlEvent(function()
        print("打地鼠")
        if self.isContentScroll then return end

        if gameConfig:checkBuildOpen(350) then
            if  self.gang.level >= tonumber(gamedata.config.global_kv.guide_open and gamedata.config.global_kv.guide_open.value or 0) then
                
            else
                runGamePrompt({msg = gameConfig.strings:guildOpenLv(gamedata.config.global_kv.guide_open and gamedata.config.global_kv.guide_open.value or 0)})
            end
        else
            runGamePrompt({msg = "功能未开启"})
        end
    end, CCControlEventTouchUpInside)

    --公会活动
    self.rootItems.activitybutton:setTouchPriority(self.buttontouch)
    self.rootItems.activitybutton:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        GameScene:shiftLayer("guildActivity",nil,{gang = self.gang})
    end, CCControlEventTouchUpInside)

    --
    --boss
    if self.rootItems.bossbutton then
        if gameConfig:checkBuildOpen(268) then
            self.rootItems.bossbutton:setVisible(true)
        else
            self.rootItems.bossbutton:setVisible(false)
        end
        self.rootItems.bossbutton:setSwallowsTouch(true)
        self.rootItems.bossbutton:setTouchPriority(self.buttontouch-2)
        self.rootItems.bossbutton:addHandleOfControlEvent(function()
            --if self.isContentScroll then return end
            if tonumber(self.gang.level) >= tonumber(gamedata.config.global_kv.sociaty_boss_class and gamedata.config.global_kv.sociaty_boss_class.value or 0) then
                GameScene:shiftLayer("guildboss","up")
            else
                runGamePrompt({msg = gameConfig.strings:guildOpenLv(gamedata.config.global_kv.sociaty_boss_class and gamedata.config.global_kv.sociaty_boss_class.value or 0)})
            end

        end, CCControlEventTouchUpInside)
    end
    --

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.isContentScroll = false
            self.touchy = y
            --self.contentoffsetx = self.rootItems.bgnode:getPositionY()
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(y - self.touchy) > 10 then
            self.isContentScroll = true
        end
       -- if math.abs(y - self.touchy) > 30 and self.contentoffsetx + (y - self.touchy) <= 160 and self.contentoffsetx + (y - self.touchy) >= GameScene.topposY-1920 then
       --     local offsety = self.contentoffsetx + (y - self.touchy)
       --     self.rootItems.bgnode:setPositionY(offsety)
       -- end
    end

    local function ccTouchEnded(x, y)
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -4, false)
    self.rootItems.touchLayer:setTouchPriority(-4)
    self.rootItems.touchLayer:setTouchEnabled(true)

    self:reloaddata()
end

function guildmain.legiondata(self,data)
    gameWindows:openWindow("guildlegion",nil)
end

function guildmain.reloaddata(self,data)
    if data then
        self.gang = data
    end

    if not self.gang then return end

    ui.setLabelString(self.rootItems.name,self.gang.name,21)
    ui.setLabelString(self.rootItems.level,self.gang.level,14)

    ui.setLabelString(self.rootItems.exp,self.gang.exp.." / "..gamedata.config.gang2_level[tostring(self.gang.level)].gang_exp,13)
    ui.setSpriteTextureRect2(self.rootItems.exppos,0,0,280*(self.gang.exp < gamedata.config.gang2_level[tostring(self.gang.level)].gang_exp and self.gang.exp/gamedata.config.gang2_level[tostring(self.gang.level)].gang_exp or 1),36)

    ui.setLabelString(self.rootItems.des,nil,121)
    ui.setLabelString(self.rootItems.num,self.gang.contribution,121)

    if self.gang.content and self.gang.content ~= "" then
        self.rootItems.content:setString(self.gang.content)
    else
        self.rootItems.content:setString("管理员太懒了，没有编辑公告")
    end
end

function guildmain.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return guildmain