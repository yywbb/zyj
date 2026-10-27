--
-- 
--

local setgmspeed = {
    rootNode = nil,
    rootItems = nil,

    speed = 1,
    stopOff = 0,
}

function setgmspeed.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("GM/GMTool_Speed", nil, true, "GMTool_Speed")
    self.touchPriority = touchPriority

    self.speed = CCUserDefault:sharedUserDefault():getFloatForKey("gmspeednum"..GameScene.roleinfo.id, 1)
    self.stopOff = CCUserDefault:sharedUserDefault():getIntegerForKey("gmspeedstate"..GameScene.roleinfo.id, 0)

    self.rootItems.speedPointer:setPositionX(-158+((self.speed-1)*2)*62)
    self.rootItems.speedStr:setString(((self.speed-0.5)*2).."倍")
    if self.stopOff == 1 then
        self.rootItems.stopLab:setString("开启")
    end

    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("setgmspeed")
    end, CCControlEventTouchUpInside)

    --加速
    self.rootItems.addBtn:setTouchPriority(self.touchPriority)
    self.rootItems.addBtn:addHandleOfControlEvent(function()
        local nowSpeed = (self.speed-0.5)*2
        
        local config = gamedata.config.speed_limit or {}
        local index = 0
        for i=1,table.getTableLength(config) do
            if tonumber(GameScene.roleinfo.level) >= tonumber(config[tostring(i)].level) then
                index = tonumber(config[tostring(i)].id)
            end
        end
        
        local cSpeed = 1
        if index > 0 then
            cSpeed = tonumber(config[tostring(index)].times)
        end
        if nowSpeed < cSpeed then
            self:setSpeed(0.5)
        else
            if nowSpeed ~= tonumber(config[tostring(table.getTableLength(config))].times) then
                runGamePrompt({msg = "开启"..config[tostring(index+1)].times.."倍加速需要队伍等级达到"..config[tostring(index+1)].level.."级"})
            end
        end
    end, CCControlEventTouchUpInside)
    
    --减速
    self.rootItems.redBtn:setTouchPriority(self.touchPriority)
    self.rootItems.redBtn:addHandleOfControlEvent(function()
        self:setSpeed(-0.5)
    end, CCControlEventTouchUpInside)
    
    --暂停
    self.rootItems.stopBtn:setTouchPriority(self.touchPriority)
    self.rootItems.stopBtn:addHandleOfControlEvent(function()
        local str = "暂停"
        if self.stopOff == 0 then
            self.stopOff = 1
            str = "开启"
            CCDirector:sharedDirector():getScheduler():setTimeScale(1)
        else
            self.stopOff = 0
            str = "暂停"
            self.speed = CCUserDefault:sharedUserDefault():getFloatForKey("gmspeednum"..GameScene.roleinfo.id, 1)
            CCDirector:sharedDirector():getScheduler():setTimeScale(self.speed)
        end
        self.rootItems.stopLab:setString(str)
        CCUserDefault:sharedUserDefault():setIntegerForKey("gmspeedstate"..GameScene.roleinfo.id, self.stopOff)
    end, CCControlEventTouchUpInside)

    return self.rootNode
end

function setgmspeed.setSpeed(self,num)
    self.speed = self.speed + num
    if self.speed >= 5.5 then
        self.speed = 5.5
    end
    if self.speed <= 1 then
        self.speed = 1
    end

    self.rootItems.speedPointer:setPositionX(-158+((self.speed-1)*2)*62)
    self.rootItems.speedStr:setString(((self.speed-0.5)*2).."倍")
    if self.stopOff == 0 then
        CCDirector:sharedDirector():getScheduler():setTimeScale(self.speed)
    end
    CCUserDefault:sharedUserDefault():setFloatForKey("gmspeednum"..GameScene.roleinfo.id, self.speed)
end

function setgmspeed.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return setgmspeed

