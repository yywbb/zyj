--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/1/25
-- Time: 下午4:52
-- To change this template use File | Settings | File Templates.
--

local first = {
    name = "",
    select = 2,

    selectconfig = {
        [1] = {pos = ccp(-298,83),id= 10101, realid = 1 },
        [2] = {pos = ccp(11,120),id= 10111, realid = 3 },
        [3] = {pos = ccp(312,104),id= 10106, realid = 2},
    }
}

function first.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("story/xuanren.ccbi", nil, true, "xuanren")
    self.rootNode:setPosition(ccp(540,(toppos-1920)*0.3))
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos-(toppos-1920)*0.4)


    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.pagemoved = false
            self.contentoffsetx = self.rootItems.generalnode:getPositionX()
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 30  then
            self.rootItems.generalnode:setPositionX(self.contentoffsetx + (x - self.touchX))
            self.pagemoved = true
        end
    end

    local function ccTouchEnded(x, y)
        local moveX = self.touchX -x
        print(moveX)

        if moveX > 20 and self.pagemoved then
            if self.select+1 <=3 then
                self:setSelectGeneral(self.select+1)
            else
                self:setSelectGeneral(self.select)
            end
        elseif moveX < -20 and self.pagemoved then
            if self.select-1 >0 then
                self:setSelectGeneral(self.select-1)
            else
                self:setSelectGeneral(self.select)
            end
        else
            --self:setPage(self.presentPage)
        end
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -105, false)
    self.rootItems.touchLayer:setTouchPriority(-105)
    self.rootItems.touchLayer:setTouchEnabled(true)

    ui.setLabelString(self.rootItems.confirmtext,gameConfig.strings:string_common("buttontext","queding"),18)
    self.rootItems.confirm:addHandleOfControlEvent(function()
        if self.select == 0 then
            -- runGamePrompt({msg = "请选择形象"})
            runGamePrompt({msg = gameConfig.strings:string_common("layer_first",7)})
        elseif self.name == "" then
            -- runGamePrompt({msg = "请输入昵称"})
            runGamePrompt({msg = gameConfig.strings:string_common("layer_first",8)})
        else
            UIRequest({type = 101,name = self.name} )
        end

    end, CCControlEventTouchUpInside)

    for i=1, 3 do
        self.rootItems["select"..i]:addHandleOfControlEvent(function()
            if self.select == i then return end
            self:setSelectGeneral(i)
            UIRequest({type = 100,sex = self.selectconfig[self.select].realid})
        end, CCControlEventTouchUpInside)

        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.selectconfig[i].id)].animationid)].name
        local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(2.5)
        general:setPosition((i-0.5)*1080,0)
        self.rootItems.generalnode:addChild(general)
    end

    local beginfunc = function(label)
        self:setFirstName("")
    end

    local endfunc = function(label,text,box)
        self:setFirstName(text)
        box:setText("")
    end

    self.nameInputBox = ui.creatInputEditBoxBylable(self.rootItems.namelabel,kEditBoxInputModeSingleLine,beginfunc,endfunc,
        {
            fontSize = 50,
            fontColor = ccc3(93,56,42),
            length = 12,
            extSensitiveWord = gameConfig.strings.sensitiveWordForSetName,
        })
    self.nameInputBox:setTouchPriority(-1)

    self.rootItems.random:addHandleOfControlEvent(function()
        UIRequest({type = 100,sex = self.selectconfig[self.select].realid})
    end, CCControlEventTouchUpInside)

    self:setSelectGeneral(self.select,true)

    gamedata.music:GameStart()

    UIRequest({type = 100,sex = self.selectconfig[self.select].realid})
end

function first.setSelectGeneral(self,index,isfirst)
    self.select = index
    if self.select > 3 then self.select = 3 end
    if self.select < 1 then self.select = 1 end

    if isfirst then
        self.rootItems.generalnode:setPositionX(-(self.select-1) * 1080)
        self:setSelectStatus()
    else
        local moveto = CCMoveTo:create(0.2, ccp(-1080*(self.select-1), 1037))
        self.rootItems.generalnode:runAction(CCSequence:createWithTwoActions(moveto,CCCallFunc:create(function()
            self:setSelectStatus()
        end)))
    end
end

function first.setSelectStatus(self)
    self.rootItems.rightnode:setVisible(self.select ~= 3)
    self.rootItems.leftnode:setVisible(self.select ~= 1)

    for i=1,3 do
        self.rootItems["selectsprite"..i]:setVisible(i==self.select)
    end
end

function first.setFirstName(self,name_)
    self.rootItems.inputdes:setVisible(false)
    self.name = name_
    self.rootItems.namelabel:setString(self.name)
end

function first.afterselect(self)
    self:clear()

    if guide.controller then
        guide.controller:CompleteStep("animation")
        guide.controller:setGuideLayerVisible(false)
    end

    GameScene:init(mainScene)

    if guide.controller then
        guide.controller:setGuideLayerVisible(true)
    end
    gamedata.music:SetMusic(true)
    gamedata.music:GameStart()
end

function first.clear(self)
    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode= nil
        self.name = ""
        self.select = 2
    end
end

return  first
