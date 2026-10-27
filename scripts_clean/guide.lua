--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/16
-- Time: 下午1:47
-- To change this template use File | Settings | File Templates.
--

local guide = {
    controller = require"guideControl",
    first = require"Layer_first",

    scaleNum = gameConfig.scaleNum,
    topposY = gameConfig.topposY,

    rootNode = nil,
    guideLayer = nil,


    buttontypeconfig = {
        [1] = {x = 300, y =300},
        [2] = {x = 180, y =180},
    },

    talkProflayerActive = true,

    leftGeneral = {},
    rightGeneral = {},
    addedTalks = {},

    errorClick = 0
}

function guide.clear(self)
    self.controller:reset()
    self:removeGuideLayer()
    self:removeproflayer()
end

------------------------------------------------------------------------------------------------------

function guide.init(self)
    if self.rootNode then return end

    self.rootNode = CCNode:create()
    self.rootNode:setScale(self.scaleNum)
    self.rootNode:setPosition(gamedata.device.SCREEN_WIDTH/2-540*self.scaleNum,gameConfig.fixH)
    mainScene:addChild(self.rootNode,gameConfig.Zorder.guide)
end

function guide.removeGuideLayer(self)
    print("guide.removeGuideLayer")
    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.npcanimationManager = nil
        self.handanimationManager = nil
        self.tishianimationManager = nil
        self.rootNode = nil
        self.guideLayer = nil
        self.npcNode = nil
        self.handNode = nil
        self.errorClick = 0
    end
end

function guide.setGuideProlayer()

end

function guide.makeGuideRect(self,Px,Py,locationrate)

    Py = Py-(1920-self.topposY)*locationrate
    self.Opx = Px
    self.Opy = Py
    self.midX = Px*self.scaleNum+gamedata.device.SCREEN_WIDTH/2-540*self.scaleNum
    self.midY = Py*self.scaleNum+gameConfig.fixH

    local guideRectSize = {
        x=self.buttontypeconfig[self.posType].x*self.scaleNum,
        y=self.buttontypeconfig[self.posType].y*self.scaleNum
    }

    self.guideRect = CCRectMake(self.midX-guideRectSize.x/2, self.midY-guideRectSize.y/2, guideRectSize.x, guideRectSize.y)
end


function guide.addGuideLayer(self)
    if self.guideLayer then return end
    self.guideLayer = CCLayer:create()
    self.rootNode:addChild(self.guideLayer)

    local touchId
    local tempX,tempY

    local function ccTouchBegan(x, y, pTouch)
        print("guidelayer touched")
        touchId = pTouch:getID()
        if self.guideType == "click" or self.guideType == "click2" or self.guideType == "display" then
            if self.guideRect:containsPoint(pTouch:getLocation()) then
                if self.posType == 2 then
                    local point = pTouch:getLocationInView()
                    tempX = point.x
                    tempY = point.y
                else
                    tempX = self.midX
                    tempY = gamedata.device.SCREEN_HEIGHT - self.midY
                    pTouch:setTouchInfo(touchId,tempX,tempY)
                end
                self.guideused = true
                self.guideRect = CCRectMake(10000, 10000, 1, 1)
            else
                tempX = -10000
                tempY = -10000
                pTouch:setTouchInfo(touchId,tempX,tempY)
                if self.guideType == "click" or self.guideType == "click2" then
                    if self.handNode then
                        if not self.tishianimationManager then
                            self.tishiNode,self.tishiitem = CCBReaderLoad("UIEffect/xinshouyindao/xinshouyindao_tishi.ccbi", nil, true, "xinshouyindao_tishi")
                            self.handItem.tishi:addChild(self.tishiNode)
                            self.tishianimationManager = getAnimationManager(self.tishiitem)
                        end
                        self.tishianimationManager:runAnimationsForSequenceNamed("focus")
                    end
                end
            end
        elseif self.guideType == "talk" then
            tempX = -10000
            tempY = -10000
            pTouch:setTouchInfo(touchId,tempX,tempY)
            self.guideused = true
        end

        if self.guideused then
            self.errorClick =self.errorClick +1
            if self.errorClick > 7 and self.errorClick < 10 then
                runGamePrompt({msg = "再点击"..(10-self.errorClick).."次跳过引导"})
            elseif self.errorClick >= 10 then
                self.controller:CompleteSection()
            end
        end

        return true
    end

    local function ccTouchMoved(x, y, pTouch)
        pTouch:setTouchInfo(touchId,tempX,tempY)
    end

    local function ccTouchEnded(x, y, pTouch)
        pTouch:setTouchInfo(touchId,tempX,tempY)
        if self.guideCallBack then self.guideCallBack() end
    end

    local function onTouch(eventType, x, y, pTouch)
        if eventType == "began" then
            return ccTouchBegan(x, y, pTouch)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y, pTouch)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y, pTouch)
        end
    end

    self.guideLayer:registerScriptTouchHandler(onTouch, false, gameConfig.touchPriority.guide, false)
    self.guideLayer:setTouchPriority(gameConfig.touchPriority.guide)
    self.guideLayer:setTouchEnabled(true)
end

function guide.addNpc(self,config)
    if not config.talkcontent or config.talkcontent == "" then
        if self.npcNode then
            self.npcNode:setVisible(false)
        end
    else
        if not self.npcNode then
            self.npcNode, self.npcItem = CCBReaderLoad("talk/guide", nil, true,"guide")
            self.rootNode:addChild(self.npcNode,2)
            self.npcanimationManager = getAnimationManager(self.npcItem)

--            local skeleton = CCSkeletonAnimation:create("shenmiren/shenmiren.json","shenmiren/shenmiren.atlas",1)
--            skeleton:setAnimation("stand",true,0)
--            skeleton:setScale(2.5)
--            self.npcItem.general:addChild(skeleton)
        end
        self.npcNode:setVisible(true)
        self.npcItem.content:setString(config.talkcontent)
        self.npcItem.continuelabel:setVisible(self.guideType == "talk")

        local Py = self.Opy
        if self.guideType == "talk" then
            self.npcItem.npcNode:setPosition(ccp(0,700))
        elseif Py<self.topposY/6 then
            self.npcItem.npcNode:setPosition(ccp(0,self.topposY/3))
        elseif Py<self.topposY/3 then
            self.npcItem.npcNode:setPosition(ccp(0,self.topposY/2))
        elseif Py<self.topposY/2 then
            self.npcItem.npcNode:setPosition(ccp(0,self.topposY/6))
        elseif Py<self.topposY*2/3 then
            self.npcItem.npcNode:setPosition(ccp(0,self.topposY/6))
        elseif Py<self.topposY*5/6 then
            self.npcItem.npcNode:setPosition(ccp(0,self.topposY/3))
        elseif Py<self.topposY/6 then
            self.npcItem.npcNode:setPosition(ccp(0,self.topposY/3))
        end
    end
end

function guide.addHand(self,config)


    if not self.handNode then
        local timeCB = {}
        timeCB["move"] = function()
            if self.handNode then
                local moveTo = CCMoveTo:create(0.75, ccp(self.posT[2].x,self.posT[2].y))
                self.handNode:runAction(moveTo)
            end
        end
        self.handNode, self.handItem = CCBReaderLoad("UIEffect/xinshouyindao/xinshouyindao.ccbi", nil, true,"xinshouyindao",timeCB)
        self.rootNode:addChild(self.handNode,1)
        self.handanimationManager = getAnimationManager(self.handItem)
    end
    if self.Opx and self.Opx>700 then
        self.handNode:setScaleX(-1)
    else
        self.handNode:setScaleX(1)
    end


    self.handNode:stopAllActions()
    self.handNode:setVisible(true)
    if self.guideType == "talk" then
        self.handNode:setVisible(false)
--        self.handNode:setPosition(973,794)
--        self.handNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
--            self.handNode:setVisible(true)
--            self.handanimationManager:runAnimationsForSequenceNamed("xinshouyindao_click")
--        end)))
    elseif self.guideType == "move" then
        self.handNode:setPosition(self.moveposT[1].x,self.moveposT[1].y)
        self.handanimationManager:runAnimationsForSequenceNamed("xinshouyindao_"..self.guideType)
        self.handNode:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(CCDelayTime:create(1.5), CCCallFunc:create(function()
            self.handNode:setPosition(self.moveposT[1].x,self.moveposT[1].y)
            self.handanimationManager:runAnimationsForSequenceNamed("xinshouyindao_"..self.guideType)
        end))))
    else

        local moveTo = CCMoveTo:create(0.3, ccp(self.Opx, self.Opy))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.handNode:runAction(CCSequence:createWithTwoActions(backOut, CCCallFunc:create(function()
            self.handanimationManager:runAnimationsForSequenceNamed("xinshouyindao_"..self.guideType)
        end)))
    end
end

function guide.setGuideLayerVisible(self,isvisible)
    print("setGuideLayerVisible",isvisible)
    if self.rootNode then
        self.rootNode:setVisible(isvisible)
        --self.isGuideLayerVisible = isvisible
        if self.npcanimationManager and isvisible then
            self.npcanimationManager:runAnimationsForSequenceNamed("guide")
        end
    end
end

function guide.setGuideLayerVisibleOnly(self,isvisible)
    if self.rootNode then
        self.rootNode:setVisible(isvisible)
    end
end

function guide.excuteGuide(self,config,callback)
    self:init()
    self:setGuideLayerVisible(true)
    self:addGuideLayer()
    self.guideType = config.steptype
    self.guideCallBack = callback

    self.guideused = false
    self.errorClick = 0


    if self.guideType == "click" or self.guideType == "click2" or self.guideType == "display" then

        self.posType = tonumber(config.clickrect) or 1
        local x,y = ui.getIDandNUM(config.clickxy1)
        self:makeGuideRect(x,1920-y,config.locRate or 0)
    elseif self.guideType == "talk" then
    elseif self.guideType == "move" then
        local posT = ui.getIDandNUMs(t.clickxy1)
        self.moveposT[1] = {x = posT[1].cid,y = 1920-posT[1].num }
        self.moveposT[2] = {x = posT[2].cid,y = 1920-posT[2].num }
    end

    self:addNpc(config)
    self:addHand(config)
end

----------------------------------------------------------------------------------------------------------------------

function guide.addproflayer(self,callback,keepprof)

    self:setGuideLayerVisibleOnly(false)

    self.talkProflayer = CCLayerColor:create(ccc4(0,0,0,100))
    self.talkProflayer:setContentSize(CCSizeMake(1080,2160))
    self.talkProflayer:setAnchorPoint(ccp(0,0))
    self.talkProflayer:setScale(self.scaleNum)
    self.talkProflayer:setPosition(ccp(gamedata.device.SCREEN_WIDTH/2-540*self.scaleNum,gameConfig.fixH))

    local runingScene = battleScene.show and bScene or mainScene
    runingScene:addChild(self.talkProflayer,gameConfig.Zorder.guide_story)

    self.proflayercallback = callback

    local function ccTouchBegan(x, y)
        print("talkProflayer clicked")
        if self.talkProflayerActive then
            gameTouch:clickprofbytime(0.2)
            if not keepprof then
                self.talkProflayer:removeFromParentAndCleanup(true)
                self.talkProflayer = nil
            end
            if self.proflayercallback then
                self.proflayercallback()
            end
        end
        return true
    end

    local function ccTouchMoved(x, y) end
    local function ccTouchEnded(x, y) end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.talkProflayer:registerScriptTouchHandler(onTouch, false, gameConfig.touchPriority.guide_story, true)
    self.talkProflayer:setTouchPriority(gameConfig.touchPriority.guide_story)
    self.talkProflayer:setTouchEnabled(true)
end

function guide.removeproflayer(self)
    if self.talkProflayer then
        self.talkProflayer:removeFromParentAndCleanup(true)
        self.talkProflayer = nil
        self.proflayercallback = nil
        self.storyccb = nil
        self.storyitem = nil
        self.leftGeneral = {}
        self.rightGeneral = {}
        self.addedTalks = {}
    end
    self:setGuideLayerVisibleOnly(true)
end

-------------------------------------------------------------------------------------------------------------------

function guide.hightlightGeneral(self,general,color)
    local light = CCTintTo:create(0,color,color,color)
    general:runAction(light)
end

function guide.newGeneral(self,data)
    local talkprofile = {
        --[0] = "profile"..GameScene.roleinfo.profile..".png",
        [10602]  = "taibai.png",
        --[10601]  = "shenmiren.png",
        --[10603]  = "mowang.png",
        [10605]  = "mowanghun.png",

        [10619]  = "tongtianjiaozhuhei",
    }


    self[data.direct.."General"] = {}
    self[data.direct.."General"].id = data.general == 0 and GameScene.roleinfo.profile or data.general
    if talkprofile[data.general] then
        local ccb,item = CCBReaderLoad("talk/other", nil, true,"other")

        setSpriteFrameByName(item.general,talkprofile[data.general]) --CCSprite:createWithSpriteFrameName(talkprofile[data.general])
        item.general:removeFromParentAndCleanup(false)
        self[data.direct.."General"].node = item.general
        self[data.direct.."General"].node:setPosition(ccp(0,50))
        self[data.direct.."General"].node:setAnchorPoint(ccp(0.5, 0))

        if data.general == 10601 then
            self[data.direct.."General"].node:setScale(1.1)
        elseif data.general == 10619 then
            self[data.direct.."General"].node:setScale(0.5)
        else
            self[data.direct.."General"].node:setScale(1.5)
        end
    else

        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(data.general == 0 and GameScene.protagonist.general.cid or data.general)].animationid)].name
        self[data.direct.."General"].node = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self[data.direct.."General"].node:setAnimation("stand",true,0)
        self[data.direct.."General"].node:setScale(2)
    end

    self.storyitem[data.direct]:setPosition(data.direct == "left" and -260 or 1340, 850)
    self.storyitem[data.direct]:addChild(self[data.direct.."General"].node)

    local moveto = CCMoveTo:create(0.3,ccp(data.direct == "left" and 160 or 920, 850))
    local backIn1 = CCEaseBackOut:create(moveto)
    self.storyitem[data.direct]:runAction(backIn1)
end

function guide.getLabelSize(self,MAX_w,str)
    local label = ui.createLabel({
        fontsize = 36,
        font = "Helvetica-Bold",
    })

    local size = {}

    label:setString(str)
    local height = label:getContentSize().height
    local width = label:getContentSize().width

    if width > MAX_w then
        size = {w = MAX_w+10, h = math.ceil(width/MAX_w)*height+20}
    else
        size = {w = width+10, h = height+20}
    end
    return size

end

function guide.addOneTalk(self,data)

    if self[data.direct.."General"].node then
        if self[data.direct.."General"].id == data.general then
            self:hightlightGeneral(self[data.direct.."General"].node,255)
        else
            self.storyitem[data.direct]:removeAllChildrenWithCleanup(true)
            --self[data.direct.."General"].node:removeFromParentAndCleanup(true)
            self[data.direct.."General"] = {}
            self:newGeneral(data)
        end
    else
        self:newGeneral(data)
    end

    if self[(data.direct == "left" and "right" or "left").."General"].node then
        self:hightlightGeneral(self[(data.direct == "left" and "right" or "left").."General"].node,100)
    end

    local size = self:getLabelSize(810,data.content)

    self.addedTalks[#self.addedTalks +1] = {}
    local theTalk = self.addedTalks[#self.addedTalks]
    theTalk.ccb, theTalk.item = CCBReaderLoad("talk/talk_story_cell_"..data.direct, nil, true,"talk_story_cell_")

    theTalk.item.textbg = tolua.cast(theTalk.item.textbg, "CCScale9Sprite")
    if theTalk.item.text.setDimensionsWithString ~= nil then
        theTalk.item.text:setDimensionsWithString(CCSizeMake(size.w,size.h),data.content)
    else
        theTalk.item.text:setString(data.content)
        theTalk.item.text:setDimensions(CCSizeMake(size.w,size.h))
    end
    theTalk.item.textbg:setPreferredSize(CCSizeMake(970,size.h+150))

    if data.general > 0 then
        theTalk.item.name:setString(ui.IDconfig(data.general).name)
    else
        theTalk.item.name:setString(GameScene.roleinfo.name)
    end

    self.storyitem.textnode:setPosition(540,self.storyitem.textnode:getPositionY()-size.h-200)

    theTalk.ccb:setPosition(data.direct == "left" and 108 or 972, 900-self.storyitem.textnode:getPositionY())
    theTalk.ccb:setScale(0)

    self.storyitem.textnode:addChild(theTalk.ccb)

    local scaleto = CCScaleTo:create(0.5,1)
    local backIn1 = CCEaseBackOut:create(scaleto)
    local sq = CCSequence:createWithTwoActions(backIn1, CCCallFunc:create(function()
        self.talkProflayerActive = true
    end))
    theTalk.ccb:runAction(sq)

end

function guide.playTalk(self,data,callback,islast)

    if not data then return end
    self.talkProflayerActive = false
    if not self.talkProflayer then
        self:addproflayer(callback,true)
        self.storyccb, self.storyitem = CCBReaderLoad("talk/talk_story", nil, true,"talk_story")
        self.storyccb:setPosition(ccp(540,0))
        self.talkProflayer:addChild(self.storyccb)

        self.storyitem.black:setZOrder(1)

        local animationManager = getAnimationManager(self.storyitem)
        animationManager:setAnimationCompletedCallback(function()
            self:addOneTalk(data)
        end)
        animationManager:runAnimationsForSequenceNamed("begin")
    else
        self:addOneTalk(data)
    end

    if islast then
        self.proflayercallback = function()
            self.proflayercallback = nil
            local animationManager = getAnimationManager(self.storyitem)
            animationManager:setAnimationCompletedCallback(function()
                self:removeproflayer()
                if callback then callback() end
            end)
            animationManager:runAnimationsForSequenceNamed("end")
        end
    end

end

function guide.palyCopyStory(self,data,callback)

    local talkstep = 0
    local function paly()
        talkstep = talkstep + 1
        if  data["direct"..talkstep] and data["direct"..talkstep] ~= "" then
            self:playTalk({
                direct = data["direct"..talkstep],
                general = data["id"..talkstep],-- == 0 and GameScene.firstgeneral or data["id"..talkstep],
                content = data["dialog"..talkstep],
            },paly,not (data["direct"..(talkstep +1)] and data["direct"..(talkstep +1)] ~= ""))
        else
            if callback then callback() end
        end
    end

    paly()
end


----------------------------------------------------------------------------------------------------------------------

function guide.findScaleNum(self,bignum,smallnum)
    local scale = (self.topposY-1620)/300
    --print(tonumber(smallnum) + (tonumber(bignum)-tonumber(smallnum))*scale)
    return tonumber(smallnum) + (tonumber(bignum)-tonumber(smallnum))*scale

end

function guide.loadStoryCCB(self,name,Parent,timeCB)
    local parent = Parent or self.talkProflayer

    local ccb,item = CCBReaderLoad("story/"..name..".ccbi", nil, true, name, timeCB)
    parent:addChild(ccb)
    local ccblab,itemlab = CCBReaderLoad("story/container.ccbi", nil, true, "container")
    ccblab:setPosition(ccp(1080/2,0))
    parent:addChild(ccblab)

    print("loadStoryCCB")
    --printT(gamedata.config.storyconfig)
    local config = gamedata.config.storyconfig[name]
    --printT(config)
    if config then
        for i=1, table.getTableLength(config) do

            if item[tostring(i)] then
      
            local x_b,y_b = string.match(config[tostring(i)].big_p,"x:%s*([+-]?%d+%.*%d*)/y:%s*([+-]?%d+%.*%d*)")
            local x_s,y_s = string.match(config[tostring(i)].small_p,"x:%s*([+-]?%d+%.*%d*)/y:%s*([+-]?%d+%.*%d*)")
            --print(i,x_b,y_b,x_s,y_s)

            item[tostring(i)]:setPosition(ccp(self:findScaleNum(x_b,x_s),self:findScaleNum(y_b,y_s)))
            item[tostring(i)]:setScale(self:findScaleNum(config[tostring(i)].big_s,config[tostring(i)].small_s))
            end

        end
    end

    if name == "story01" then
        gamedata.music:story("story1")
    elseif name == "story02" then
        gamedata.music:story("story2")
    elseif name == "story06" then
        gamedata.music:story("story3")
    elseif name == "story08" then
        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.83), CCCallFunc:create(function()
            gamedata.music:SetMusic(true)
            gamedata.music:story("story3_2")
        end))
        self.talkProflayer:runAction(sequence)
        local sequence2 = CCSequence:createWithTwoActions(CCDelayTime:create(15.5), CCCallFunc:create(function()
            gamedata.music:SetMusic(false)
        end))
        self.talkProflayer:runAction(sequence2)
        gamedata.music:SetMusic(false)
    elseif name == "story09" then
        gamedata.music:story("story3")
    end

    return ccb,item, name, ccblab, itemlab
end

function guide.palyOpenStory(self,beginIdx,endIdx,callback)
    print("palyOpenStory")
    self:init()

    local index = beginIdx - 1
    local function palyone()
        index = index +1
        if index <= endIdx then
            self:addproflayer(nil,true)

            local name = index<10 and "story0"..index or "story"..index
            local ccb,item,name,ccblab, itemlab = self:loadStoryCCB(name)

            itemlab.button:setSwallowsTouch(true)
            itemlab.button:setTouchPriority(gameConfig.touchPriority.guide-100)
            itemlab.button:addHandleOfControlEvent(function()
                self:removeproflayer()
                palyone()
            end, CCControlEventTouchUpInside)

            local animationManager = getAnimationManager(item)
            animationManager:setAnimationCompletedCallback(function()
                self.proflayercallback = function()
                    self:removeproflayer()
                    palyone()
                end
            end)
            animationManager:runAnimationsForSequenceNamed(name)

            self.proflayercallback = function()

                local channel = deviceApi.channel or ""
                if channel == "iqiyiAYYJ" or channel == "iqiyiIOSXYMJ" then
                    self:removeproflayer()
                    palyone()
                else
                    animationManager:runAnimationsForSequenceNamed(name.."_2")
                    self.proflayercallback = function()
                        self:removeproflayer()
                        palyone()
                    end
                end
            end
        else
            if callback then callback() end
        end
    end

    palyone()
end

function guide.palyFirstBattle(self,callback)
    --if callback then callback() return end
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename("story/battle_1.json")
    local t = {
        fightbg = "renzu1",
        battlereport = LoadJsonFileToTable(path),
    }
    gamedata.music:SetMusic(true)
    battleScene:init(mainScene,"story",t,callback)
end

function guide.palyFirst(self,callback)
    self:init()

    self.first:init(self.rootNode,self.topposY)
end

return guide