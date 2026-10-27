--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/9/24
-- Time: 上午11:51
-- To change this template use File | Settings | File Templates.
--

local popWindows = {

    maxRadio_size = gameConfig.maxRadio_size,
    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },
    viewSize = gameConfig.originSize,

    existTopWindows = 0,
    existNormalWindows = 0,

    topZorder = gameConfig.Zorder.popwindow,
    topPriority = gameConfig.touchPriority.topwindow,

    normalZorder =  1,
    normalPriority =  gameConfig.touchPriority.popwindow,

    touchPos = {},

    windows = {

        versionUpdate = {type = "top", postype = "center", module = require"window_versionUpdate" },
        downloadUpdate = {type = "top", postype = "center", module = require"window_downloadUpdate" },
        shiming = {type = "top", postype = "center", module = require"window_shiming2" },
        userAgreement = {type= "top", postype = "center", hold = true,module = require"window_userAgreement"},
        userAndPrivacyAgreement = {type= "top", postype = "center", hold = true,module = require"window_userAndPrivacyAgreement"},
    	ageTips = {type = "top", postype = "center", module = require"window_ageTips" },
    },

    profColor = ccc4(0,0,0,100),

    inited = false,
}

function popWindows.init(self)
    if self.inited then return end

    self.scaleNum = gameConfig.scaleNum

    self.inited = true
end

function popWindows.openWindow(self,name,data,callback)
    if not self.windows[name] or not next(self.windows[name]) then runGamePrompt({msg = "功能未开启"}) return end

    if self.windows[name].show then
        if self.windows[name].module.reload then
            self.windows[name].module:reload(data,callback)
        else
            self:closeWindowDirect(name)
        end
        return
    end


    if self.existTopWindows ~= 0 or self.windows[name].type == "top" then
        local index = self.existTopWindows+1
        local touchPriority = self.topPriority - (index-1)*5 -1

        local noAnimation = nil
        self.windows[name].animationNode, noAnimation = self.windows[name].module:open(touchPriority,data,callback)

        self.windows[name].profLayer = ui.addProflayer(loginScene,touchPriority+1, self.topZorder+2*(index-1)-1,self.profColor,nil,nil,nil,nil,"gameWindowsLoginprof")

        self.windows[name].animationNode:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
        self.windows[name].animationNode:setScale(self.scaleNum)
        loginScene:addChild(self.windows[name].animationNode,self.topZorder+2*(index-1))

        self.windows[name].fromX,self.windows[name].fromY,self.windows[name].realtype = self:openWindowAnimation(self.windows[name].animationNode,self.windows[name].postype,"top",true)

        self.existTopWindows = self.existTopWindows+1
    end

    self.windows[name].show = true
end

function popWindows.closeWindow(self,name)
    if self.windows[name].show then
        self:closeWindowAnimation(name, function()
            self:closeWindowDirect(name)
        end)
    end
end

function popWindows.closeAllWindowDirect(self)

    for k,v in pairs(self.windows) do
        if v.show then
            self:closeWindowDirect(k)
        end
    end

    self.existTopWindows = 0
    self.existNormalWindows = 0
end

function popWindows.closeWindowDirect(self,name)
    if self.windows[name].show then

        self.windows[name].profLayer:removeFromParentAndCleanup(true)
        self.windows[name].profLayer = nil
        self.windows[name].animationNode = nil

        if self.windows[name].realtype=="top" then
            self.existTopWindows = self.existTopWindows-1
        else
            self.existNormalWindows = self.existNormalWindows-1
        end
        self.windows[name].show = false
        self.windows[name].module:close()

    end

end

function popWindows.openWindowAnimation(self,node,postype,windowtype,noAnimation)
    local toX
    local toY
    if windowtype == "top" then
        toX = gamedata.device.SCREEN_WIDTH/2
        toY = gamedata.device.SCREEN_HEIGHT/2
    else
        toX = 1080/2
        toY = GameScene.topposY/2 + 80
    end

    if postype ~= nil and postype == "touchPosTo" then
        toX = self.touchPos.x*(gameConfig.originSize.width/gamedata.device.SCREEN_WIDTH)
        toY = self.touchPos.y*(gameConfig.originSize.width/gamedata.device.SCREEN_WIDTH)
    end

    local fromX = toX
    local fromY = toY

    if postype ~= nil and postype == "touchPos" then
        if windowtype == "top" then
            fromX = self.touchPos.x
            fromY = self.touchPos.y
        else
            fromX = self.touchPos.x*(gameConfig.originSize.width/gamedata.device.SCREEN_WIDTH)
            fromY = self.touchPos.y*(gameConfig.originSize.width/gamedata.device.SCREEN_WIDTH)
        end
    end

    if noAnimation then
        node:setPosition(ccp(toX,toY))
    else
        node:setPosition(ccp(fromX,fromY))
        node:setScale(0)
        local moveto = CCMoveTo:create(noAnimation and 0 or 0.3,ccp(toX,toY))
        local backOut1 = CCEaseBackOut:create(moveto)

        local scaleTo = CCScaleTo:create(noAnimation and 0 or 0.3, windowtype == "top" and self.scaleNum or 1)
        local backOut = CCEaseBackOut:create(scaleTo)

        local spw = CCSpawn:createWithTwoActions(backOut1,backOut)
        local sequence = CCSequence:createWithTwoActions(spw, CCCallFunc:create(cb))
        node:runAction(sequence)
    end

    return fromX,fromY,windowtype
end

function popWindows.closeWindowAnimation(self,name,callBack)
    local data = self.windows[name]
    local moveto = CCMoveTo:create(0.3,ccp(data.fromX,data.fromY))
    local backIn1 = CCEaseBackIn:create(moveto)

    data.animationNode:setScale(data.realtype == "top" and self.scaleNum or 1)
    local scaleTo = CCScaleTo:create(0.3, 0)
    local backIn = CCEaseBackIn:create(scaleTo)

    local spw = CCSpawn:createWithTwoActions(backIn1,backIn)
    data.animationNode:runAction(spw)

    --after animation to clear
    local delay = CCDelayTime:create(0.4)
    local sequence = CCSequence:createWithTwoActions(delay, CCCallFunc:create(callBack))
    data.animationNode:runAction(sequence)
end

return popWindows