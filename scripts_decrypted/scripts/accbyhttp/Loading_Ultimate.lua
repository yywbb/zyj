--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/2/5
-- Time: 上午11:27
-- To change this template use File | Settings | File Templates.
--

local loading = {
    generals = {"change","ganning","guanyu","hamajing","huangzhong","jinyankongquelongwang","kulou","machao","mengpo","qitiandasheng"},

    waittime = 0.5,

    maxRadio_size = gameConfig.maxRadio_size,

    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },
    viewSize = gameConfig.originSize,

    proflayer = nil,
    rechageLayer = nil,

    gameloadingIdx = {},
    netproflayer = nil,

    isexit = false,

    loadincount = 0,
}

function loading.init(self)

    self.scaleNum = gameConfig.scaleNum
    self.topposY =  gameConfig.topposY
end



function loading.startLoginloading(self)
    if self.proflayer then return end

    self.proflayer = ui.addProflayer(CCDirector:sharedDirector():getRunningScene(),gameConfig.touchPriority.loading,gameConfig.Zorder.loading,ccc4(0,0,0,100),nil,nil,nil,"loginLoadingprof")

    local loadingLayer,loadingLayerItem = CCBReaderLoad("loading/loading1.ccbi", nil, true, "loading")

    local skeleton = CCSkeletonAnimation:create("loading/mamian.json","loading/mamian.atlas",1)
    skeleton:setPosition(0,0)
    skeleton:setAnimation("loading",true,0)
    loadingLayerItem.skeletonNode:addChild(skeleton)
    local skeleton2 = CCSkeletonAnimation:create("loading/niutou.json","loading/niutou.atlas",1)
    skeleton2:setPosition(0,0)
    skeleton2:setAnimation("loading",true,0)
    loadingLayerItem.skeletonNode:addChild(skeleton2)
    loadingLayerItem.skeletonNode:setScale(1.5)

    loadingLayer:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
    loadingLayer:setScale(self.scaleNum)

    self.proflayer:addChild(loadingLayer)
end

function loading.stopLoginloading(self)
    if self.isexit then return end
    if self.proflayer then
        self.proflayer:removeFromParentAndCleanup(true)
        self.proflayer = nil
    end
end

function loading.battlePreLoading(self,parent,type,callback)
    local proflayer = ui.addProflayer(parent,gameConfig.touchPriority.loading,gameConfig.Zorder.loading,ccc4(0,0,0,0),nil,nil,nil,nil,"battlePreLoadingprof")
    local ccb,item = CCBReaderLoad("loading/heimu"..math.random(1,10)..".ccbi", nil, true, "heimu")
    ccb:setPosition(gamedata.device.SCREEN_WIDTH/2,gameConfig.fixH)
    ccb:setScale(self.scaleNum)
    ccb:setAnchorPoint(ccp(0.5, 0))
    proflayer:addChild(ccb,1000)
    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        proflayer:removeFromParentAndCleanup(true)
        if callback then callback() end
    end)
    animationManager:runAnimationsForSequenceNamed(type)

    item.maonode:setPositionY(self.topposY/2)

    local index = math.random(1,table.getTableLength(gamedata.config.loading))
    if not gamedata.config.loading[tostring(index)] then index = 1 end

    item.tips:setString(gamedata.config.loading[tostring(index)].desc)
end


function loading.startsceneshiftloading()

end

function loading.stopsceneshiftloading()

end

function loading.startGameloading(self,index)
    print("loading-2")
    if self.isexit then return end
    if index == 2275 or index == 999 or index == 999989 or index == 999901 or index == 999904 then return end
    if not CCDirector:sharedDirector():getRunningScene() or  CCDirector:sharedDirector():getRunningScene() ~= mainScene then return end
    self.gameloadingIdx[index] = 1

    if self.proflayer then 

        return 
    end

    self.proflayer = ui.addProflayer(CCDirector:sharedDirector():getRunningScene(),gameConfig.touchPriority.loading,gameConfig.Zorder.loading,ccc4(0,0,0,0),nil,nil,nil,nil,"gameLoginprof")

    local callback = function()
        if not self.proflayer then return end

        self.loadincount = self.loadincount + 1
        self.proflayer:setOpacity(150)
        local ccb,item = CCBReaderLoad("loading/loading_0"..math.random(1,6)..".ccbi", nil, true, "loading_0")
        ccb:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
        ccb:setScale(self.scaleNum)
        ccb:setAnchorPoint(ccp(0.5, 0.5))
        self.proflayer:addChild(ccb)

--        local general = self.generals[math.random(1,#self.generals)]
--        local skeleton = CCSkeletonAnimation:create(general.."/"..general..".json",general.."/"..general..".atlas",1)
--        skeleton:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
--        skeleton:setAnimation("skill",true,0)
--        skeleton:setScale(2*self.scaleNum)
--        self.proflayer:addChild(skeleton)

--        local sequence1 = CCSequence:createWithTwoActions(CCDelayTime:create(10), CCCallFunc:create(function()
--             if self.proflayer then
--                  UIRequest({type =995})
--             end
--        end))
--        self.proflayer:runAction(sequence1)
    end

    local delaytime = 1+self.loadincount*0.5
    if delaytime>3 then delaytime=3 end

    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(delaytime), CCCallFunc:create(callback))
    self.proflayer:runAction(sequence)
end



function loading.startGameloadingRechage(self)

    if not CCDirector:sharedDirector():getRunningScene() or  CCDirector:sharedDirector():getRunningScene() ~= mainScene then return end
    if self.rechageLayer then 

        return 
    end

    self.rechageLayer = ui.addProflayer(CCDirector:sharedDirector():getRunningScene(),gameConfig.touchPriority.loading,gameConfig.Zorder.loading,ccc4(0,0,0,0),nil,nil,nil,nil,"gameLoginprof")

    local callback = function()
        if not self.rechageLayer then return end
        self.rechageLayer:setOpacity(150)
        local ccb,item = CCBReaderLoad("loading/loading_0"..math.random(1,6)..".ccbi", nil, true, "loading_0")
        ccb:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
        ccb:setScale(self.scaleNum)
        ccb:setAnchorPoint(ccp(0.5, 0.5))
        self.rechageLayer:addChild(ccb)
    end

    callback();
end

function loading.stopGameloadingRechage(self)
    if self.rechageLayer then
        self.rechageLayer:removeFromParentAndCleanup(true)
        self.rechageLayer = nil
    end    
end



local b1000Firest = true
function loading.stopGameloading(self,index)
    if self.isexit then return end
    if index == 9999 or index == 999903 then
        self.gameloadingIdx = {}
        if self.proflayer then
            self.proflayer:removeFromParentAndCleanup(true)
            self.proflayer = nil
        end
    end

    if self.proflayer or self.netproflayer then
        if index == 1000 then
            if not LoginScene.status then
                for msgtype,xxx in pairs(self.gameloadingIdx) do
                    UIRequest({type=999989,msgtype=msgtype})
                end
            end
            self.gameloadingIdx = {}

            if self.proflayer then
                self.proflayer:removeFromParentAndCleanup(true)
                self.proflayer = nil
            end
        end
    end


    if self.gameloadingIdx[index] then
        self.gameloadingIdx[index] = nil
        if not next(self.gameloadingIdx) and self.proflayer then
            self.proflayer:removeFromParentAndCleanup(true)
            self.proflayer = nil
        end
    end
end

function loading.restart(self,uionly)
    print("loading restart ........")

--    local device = require"device"
--    if device.platform == "android" then
--        local luaj = require"luaj"
--        local javaClassName = gameConfig.AD_packageName.."/AndroidUtils"
--        local javaMethodName = "RestartGame"
--        local javaMethodSig = "()V"
--        return luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
--    else

        if not uionly then
            UIResponseClear()
        end

        local remainlist = {
            _G = true,
            uiqueue = true,
            cjson = true,
            myfile = true,
            pb = true,
            struct = true,
            sqlite3 = true,
            md5 = true,
        }

        for k,v in pairs(package.loaded) do
            --print(k)
            if remainlist[k] then

            else
                package.loaded[k] =  nil
            end
        end

        if pauseUIUpdate then
            pauseUIUpdate()
        end

        if pauseaccUIUpdate then
            pauseaccUIUpdate()
        end

        if guide then guide:clear() end

        if battleScene and battleScene.show then
            battleScene.callback = nil
            battleScene:clear()
        end
        if GameScene then GameScene:clear() end
        if ui then ui.itemcache:removeAllSkeletons() end

        if gameTimer then gameTimer:clear() end
        if gameTouch then gameTouch:clearDirect() end

        bRunWithScene = false
        if loginScene then loginScene:removeAllChildrenWithCleanup(true) end
        if mainScene then mainScene:removeAllChildrenWithCleanup(true) end
        if bScene then bScene:removeAllChildrenWithCleanup(true) end

        CCLabelBMFont:purgeCachedData()
        CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
        CCTextureCache:sharedTextureCache():removeUnusedTextures()


        local timer = nil
        timer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
            if timer then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(timer)
                timer = nil
            end

            if not uionly then
                UIResponseClear()
            end
            
            require"accbyhttp/main_ui"
            if not uionly then
                UIRequest({type = 777777})
            end

        end, 0, false)


 --   end

end

function loading.exit(self)
    local device = require"device"
    if device.platform == "android" then
        cclog("android system exit")
        local luaj = require"luaj"
        --local javaClassName = "com/ldfs/sanguo/AndroidUtils"
        --local javaClassName = "com/ldfs/sanguo2/AndroidUtils"
        local javaClassName = gameConfig.AD_packageName.."/AndroidUtils"
        local javaMethodName = "SystemExit"
        local javaMethodSig = "()V"
        luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
    else
        cclog("ios system exit")
        local myfile = require"myfile"
        myfile.osexit()
    end
end

function loading.exitGame(self,des,needrestar)
    if self.isexit then return end
    self.isexit = true
    if self.proflayer then
        self.proflayer:removeFromParentAndCleanup(true)
        self.proflayer = nil
    end

    self.proflayer = ui.addProflayer(CCDirector:sharedDirector():getRunningScene(),gameConfig.touchPriority.loading,gameConfig.Zorder.loading,ccc4(0,0,0,100),nil,nil,nil,nil,"gameExitprof")
    local loadingLayer,loadingLayerItem = CCBReaderLoad("loading/confirm.ccbi", nil, true, "confirm")
    loadingLayer:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
    loadingLayer:setScale(self.scaleNum)

    loadingLayerItem.closeButton:setVisible(false)

    ui.setLabelString(loadingLayerItem.des,des,47)

    ui.setLabelString(loadingLayerItem.confirmtext,"确 定",18)
    loadingLayerItem.confirm:addHandleOfControlEvent(function()
        if needrestar then
            print("exitGame")
            sdk:loginOutStatusRest()
            self:restart()
        else
            self:exit()
        end
    end, CCControlEventTouchUpInside)
    loadingLayerItem.confirm:setSwallowsTouch(true)
    loadingLayerItem.confirm:setTouchPriority(gameConfig.touchPriority.loading-1)

    self.proflayer:addChild(loadingLayer)
end

function loading.netClosed(self)
    if self.isexit then return end
    if self.proflayer then
        self.proflayer:removeFromParentAndCleanup(true)
        self.proflayer = nil
    end

    if self.netproflayer then return end

    self.netproflayer = ui.addProflayer(CCDirector:sharedDirector():getRunningScene(),gameConfig.touchPriority.loading,gameConfig.Zorder.loading,ccc4(0,0,0,100),nil,nil,nil,nil,"gameExitprof")
    local loadingLayer,loadingLayerItem = CCBReaderLoad("tanchuang/tc_duanxianchonglian.ccbi", nil, true, "tc_duanxianchonglian")
    loadingLayer:setPosition(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2)
    loadingLayer:setScale(self.scaleNum)

    --ui.setLabelString(loadingLayerItem.des,"网络连接中断，重连中......\n长时间无响应请检查网络连接。",47)

--    ui.setLabelString(loadingLayerItem.confirmtext,"确 定",18)
--    loadingLayerItem.confirm:addHandleOfControlEvent(function()
--
--    end, CCControlEventTouchUpInside)
--    loadingLayerItem.confirm:setSwallowsTouch(true)
--    loadingLayerItem.confirm:setTouchPriority(gameConfig.touchPriority.loading-1)

    loadingLayerItem.general:removeAllChildrenWithCleanup(true)
    local ma = CCSkeletonAnimation:create("change/change.json","change/change.atlas",2)
    ma:setAnimation("stand",true,0)
    loadingLayerItem.general:addChild(ma)

    self.netproflayer:addChild(loadingLayer)
end

function loading.netOpen(self)
    if self.netproflayer then
        self.netproflayer:removeFromParentAndCleanup(true)
        self.netproflayer = nil
        if  gameTimer then
            gameTimer.reconnect = true
        end
    end

    if self.netopencallback then
        self.netopencallback()
        self.netopencallback = nil
    end
end

return loading

  5  