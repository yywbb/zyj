--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/18
-- Time: 下午5:17
-- To change this template use File | Settings | File Templates.
--

local GameTouch= {
    beginFuncs = {},
    moveFuncs = {},
    endFuncs = {},

    layer = nil,
    isswallow = false,

    ismove = false,
    touchx = 0,

    isScrollling = false,

    endpos = {},

    isactive = false,
    socket = require("socket"),
}

function GameTouch.showpos(self,x,y)
--    if not self.proflayer or CCDirector:sharedDirector():getRunningScene() ~= mainScene then  return end
--    local posccb, positem = CCBReaderLoad("UIEffect/dianji/dianji", nil, true, "dianji")
--    posccb:setPosition(ccp(x or self.endpos.x, y or self.endpos.y))
--    self.layer:addChild(posccb)
--
--    local animationManager = getAnimationManager(positem)
--    animationManager:setAnimationCompletedCallback(function()
--        posccb:removeFromParentAndCleanup(true)
--    end)
--    animationManager:runAnimationsForSequenceNamed("dianji")
end


function GameTouch.clickprofbytime(self,time,iscover)
    if not self.proflayer then return end
    if CCDirector:sharedDirector():getRunningScene() ~= mainScene then return end

    local now = self.socket:gettime()
    self.profend = self.profend or now
    local newtime = time
    if self.isactive == true and time < self.profend-now and (not iscover) then
        return
    end
    self.profend = now+time

    self.proflayer:setTouchEnabled(true)
    self.isactive = true
    -- self.proflayer:stopAllActions()
    -- self.proflayer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(newtime), CCCallFunc:create(function()
    --     self.proflayer:setTouchEnabled(false)
    --     self.isactive = false
    -- end)))
end

function GameTouch.clickprofbytimeCheck( self )
    if self.isactive == true then
        local now = self.socket:gettime()
        if now>self.profend then
            self.proflayer:setTouchEnabled(false)
            self.isactive = false
        end
    end
end

function GameTouch.setClickProf(self,bool)
    if not self.proflayer then return end
    self.proflayer:setTouchEnabled(bool)
    self.isactive = bool
end

function GameTouch.init(self)
    self.layer = CCLayer:create()
    self.layer:setContentSize(CCSizeMake(gamedata.device.SCREEN_WIDTH, gamedata.device.SCREEN_HEIGHT))
    self.layer:setAnchorPoint(ccp(0,0))
    self.layer:setPosition(ccp(0,0))

    self.proflayer = ui.addProflayer(mainScene,gameConfig.touchPriority.touchPosLyer-1,gameConfig.Zorder.touchPosLyer+1,ccc4(0,0,0,0),nil,nil,nil,nil,"gameTouchprof")
    self.proflayer:setTouchEnabled(false)

    mainScene:addChild(self.layer,gameConfig.Zorder.touchPosLyer)

    local function ccTouchBegan(x, y)
        print("TouchPosLayer clicked")
        print("TouchPosLayer isactive = ", self.isactive)
        self:clickprofbytime(0.2)
        for k,v in pairs(self.beginFuncs) do
            v({x=x,y=y})
        end
        if gameWindows then gameWindows.touchPos = {x=x,y=y} end
        self.ismove = false
        self.touchx = x
        return true
    end

    local function ccTouchMoved(x, y)
        for k,v in pairs(self.moveFuncs) do
            v({x=x,y=y})
        end

        if math.abs(self.touchx-x) >1 then
            self.ismove = true
        end
        --print("self.ismove",self.ismove,self.touchx-x)
    end

    local function ccTouchEnded(x, y)
        for k,v in pairs(self.endFuncs) do
            v({x=x,y=y})
        end
        self.endpos = {x=x,y=y}
--        if not self.ismove then
--            print(self.ismove)
--            self:showpos(x,y)
--        end
--        self:clickprofbytime(0.2)

--        if gamedata.device.platform == "android" then
--            self:setAndroidNavigation()
--        end

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

    self.layer:registerScriptTouchHandler(onTouch, false, gameConfig.touchPriority.touchPosLyer , false)
    --self.layer:setTouchPriority(gameConfig.touchPriority.touchPosLyer)
    self.layer:setTouchEnabled(true)

    self.schedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        self:clickprofbytimeCheck()
    end, 0, false)
end

function GameTouch.rigistFunc(self,type,name,func)
    self[type.."Funcs"][name] = func
end

function GameTouch.UnrigistFunc(self,type,name)
    self[type.."Funcs"][name] = nil
end

function GameTouch.clear(self)
    self.beginFuncs = {}
    self.moveFuncs = {}
    self.endFuncs = {} 
    
    self:setClickProf(false)
end

function GameTouch.clearDirect(self)
    if not self.layer or self.proflayer then return end
    self.beginFuncs = {}
    self.moveFuncs = {}
    self.endFuncs = {}

    if self.schedule then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.schedule)
        self.schedule = nil
    end

    self.layer:removeFromParentAndCleanup(true)
    self.layer = nil
    self.proflayer:removeFromParentAndCleanup(true)
    self.proflayer = nil
end

function GameTouch.setAndroidNavigation(self)
    local luaj = require"luaj"

    local javaClassName = "org/cocos2dx/lib/Cocos2dxActivity"
    local javaMethodName = "setSystemUI"
    local javaMethodSig = "()Z"

    local result, packgename = luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
end

return GameTouch