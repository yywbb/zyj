--
-- Author: songyibo
-- Date: 2020-03-23 16:54:40
--

local guildActivity = {

    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,

    hintext = {
        [1] = {570,575},    --盛宴
        [2] = {571,576},    --篝火
        [3] = {268},        --公会Boss
    },
    sysids = {570,571,268},
}

function guildActivity.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui3/main", nil, true, "main")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos

    self.rootItems.topnode:setPositionY(self.toppos)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        UIRequest({type = 2230,param = "main"})
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    if param and param.gang then
        self:reload(param.gang)
    else
        UIRequest({type = 2230,param = "activity"})
    end
    
    self:reloadHint()
end


function guildActivity.reloadHint(self)

    for i,v in ipairs(self.hintext) do
        local hint = false
        for i2,v2 in ipairs(v) do
            if GameScene.hintdata[tostring(v2)] and GameScene.hintdata[tostring(v2)] ~= 0 then
                hint = true
                break
            end
        end
        print("sethint",i,hint)
        ui.sethint(self.rootItems[ui.ccbNameEx("hint",i)],hint)
    end
end

function guildActivity.reload(self,data)
    self.gang = data

    local bgNames = {"gonghui_shengyanrukou","gonghui_gouhuorukou","gonghui_bossrukou"}
    for i=1,3 do
        setSpriteFrameByName(self.rootItems[ui.ccbNameEx("bg",i)], bgNames[i] )

        local limit = 0
        if i == 1 then
            limit = tonumber(gamedata.config.global_kv.sociaty_feast_class and gamedata.config.global_kv.sociaty_feast_class.value or 0)
        elseif i == 2 then
            limit = tonumber(gamedata.config.global_kv.sociaty_bonfire_class and gamedata.config.global_kv.sociaty_bonfire_class.value or 0)
        elseif i == 3 then
            limit = tonumber(gamedata.config.global_kv.sociaty_boss_class and gamedata.config.global_kv.sociaty_boss_class.value or 0)
        end

        self.rootItems[ui.ccbNameEx("clickbutton",i)]:setSwallowsTouch(true)
        self.rootItems[ui.ccbNameEx("clickbutton",i)]:setTouchPriority(self.touchPriority)
        self.rootItems[ui.ccbNameEx("clickbutton",i)]:addHandleOfControlEvent(function()

            if not GameScene:checkopenlevelbyId(self.sysids[i]) then
                return
            end

            if tonumber(self.gang.level) < limit then
                runGamePrompt({msg = gameConfig.strings:guildOpenLv(limit)})
                return
            end
            self:skip(i)
        end, CCControlEventTouchUpInside)

        if limit > 1 and tonumber(self.gang.level) < limit then
            self.rootItems[ui.ccbNameEx("opennode",i)]:setVisible(true)
            self.rootItems[ui.ccbNameEx("openlevel",i)]:setString("公会"..limit.."级开放")
        else
            self.rootItems[ui.ccbNameEx("opennode",i)]:setVisible(false)
        end
    end

    
    if self.gang.gangfeastreward and self.gang.gangfeastreward == 1 then
        UIRequest({type = 2273})
    end

    if self.gang.gangbathreward and self.gang.gangbathreward == 1 then
        UIRequest({type = 2283})
    end

end

function guildActivity.skip(self,index)
    print("skip",index)

	if index == 3 then
		GameScene:shiftLayer("guildboss","up")
    elseif index == 2 then
    	local bathdoing = self.gang.gangbathdoing
        print("bathdoing",bathdoing)
        if bathdoing and bathdoing > 0 then
            UIRequest({type = 2282, roomid = bathdoing, controltype = 1})
        else
            gameWindows:openWindow("openzaotanginfo",{gang = self.gang})
        end
    elseif index == 1 then
        local feastdoing = self.gang.gangfeastdoing
        print("feastdoing",feastdoing)
        if feastdoing and feastdoing > 0 then
            UIRequest({type = 2272, roomid = feastdoing, controltype = 1})
        else
            gameWindows:openWindow("openfeastinfo",nil)
        end
	end
end

function guildActivity.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return guildActivity