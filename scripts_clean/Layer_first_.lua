--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/4/13
-- Time: 上午11:56
-- To change this template use File | Settings | File Templates.
--

local first = {
    step = 1,

--    dialog = {
--        {direct = true, timeline = "story10_renwu_1", content = "额~~~我这是在哪~~"},
--        {direct = false, timeline = "story10_renwu_16", content = "你终于醒了，魔王"},
--        {direct  = true, timeline = "story10_renwu_2", content = "怎么回事？你是谁？啊？我的身体呢？"},
--        {direct  = false, timeline = "story10_renwu_3", content = "表慌，我是来帮你的。"},
--        {direct  = false, timeline = "story10_renwu_4", content = "魔王军团全军覆没，你已经战死，肉身被毁，我趁乱截走了你的魂魄，不然你早就被他们打的魂飞魄散了。"},
--        {direct  = true, timeline = "story10_renwu_5", content = "什么？可恶，这群卑鄙的神仙，我要复仇！！！复仇！！！！"},
--        {direct  = true, timeline = "story10_renwu_6",  bao = true,content = "~~~~~"},
--        {direct  = false, timeline = "story10_renwu_17", content = "总之我会帮助你东山再起的，按照我的计划去做，一统三界，妥妥的。"},
--        {direct  = true, timeline = "story10_renwu_7", content = "你到底是谁？为什么要帮我？"},
--        {direct  = false, timeline = "story10_renwu_8", content = "我会用法力重塑你的魔身，你挑选一下你想要的形象吧"},
--        {direct  = true, timeline = "story10_renwu_9", content = "喂！有没有好好听我说话呀！"},
--        {direct  = true, timeline = "story10_renwu_10", xuanren = true, content = "哇！屌爆了！"},
--        {direct  = false, timeline = "story10_renwu_11", content = "恩，现在当务之急我们要先去地府复活之前被你收服的武将和魔将。"},
--        {direct  = true, timeline = "story10_renwu_12", content = "唉？有道理啊喂。"},
--        {direct  = false, timeline = "story10_renwu_13", content = "so，准备战斗！"},
--        {direct  = true, timeline = "story10_renwu_14", content = "··什么？这就要战斗了？不过话说我这是在哪啊，咱们这是往哪飞呀？"},
--        {direct  = true, timeline = "story10_renwu_15", isend = true,content = "··什么？这就要战斗了？不过话说我这是在哪啊，咱们这是往哪飞呀？"},
--    },

    dialog = {
        {direct = true, timeline = "story10_renwu_2", contentdelay = 8,content = gameConfig.strings:string_common("layer_first",0)},
        {direct  = false, timeline = "story10_renwu_4", content = gameConfig.strings:string_common("layer_first",1)},
        {direct  = true, timeline = "story10_renwu_4", content = gameConfig.strings:string_common("layer_first",2)},
        {direct  = false, timeline = "story10_renwu_8", content = gameConfig.strings:string_common("layer_first",3)},
        {direct  = true, timeline = "story10_renwu_10", xuanren = true, content = gameConfig.strings:string_common("layer_first",4)},
        {direct  = false, timeline = "story10_renwu_11", content = gameConfig.strings:string_common("layer_first",5)},
        {direct  = true, timeline = "story10_renwu_12", content = gameConfig.strings:string_common("layer_first",6)},
        {direct  = true, timeline = "story10_renwu_15", isend = true,content = ""},
    },

    name = "",
    profile = 0,
}

function first.loadStoryCCB(self,name,parent,needremove,timeCB,order,scale)
    local ccb,item = CCBReaderLoad("story/"..name..".ccbi", nil, true, name, timeCB)
    ccb:setScale(self.scaleNum*(scale or 1))
    ccb:setPosition(ccp(gamedata.device.SCREEN_WIDTH/2,gamedata.device.SCREEN_HEIGHT/2))
    ccb:setZOrder(order or 0)
    parent:addChild(ccb)

    if needremove then
        local animationManager = getAnimationManager(item)
        animationManager:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed(name)
    end
    return ccb,item, name
end

function first.oneStep(self,step)

    self.rootItems.talkbutton:setEnabled(false)
    --self.rootItems.content:setString((self.dialog[step].direct and (self.name == "" and "魔王魂" or self.name ) or "神秘人")..":\n"..self.dialog[step].content)

    if self.dialog[step].contentdelay then
        self.rootItems.talkbutton:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(self.dialog[step].contentdelay),CCCallFunc:create(function()
            if self.dialog[step].xuanren then
                ui.setStringOneByOne(self.rootItems.content,self.dialog[step].content,nil)
            else
                ui.setStringOneByOne(self.rootItems.content,self.dialog[step].content,function() self.rootItems.talkbutton:setEnabled(true) end)
            end
        end)))
    else
        if self.dialog[step].xuanren then
            ui.setStringOneByOne(self.rootItems.content,self.dialog[step].content,nil)
        else
            ui.setStringOneByOne(self.rootItems.content,self.dialog[step].content,function() self.rootItems.talkbutton:setEnabled(true) end)
        end
    end


    self.animationManager:setAnimationCompletedCallback(function()
        if self.dialog[step].xuanren then
            self.rootItems.talkbutton:setEnabled(true)
        end
    end)
    self.animationManager:runAnimationsForSequenceNamed(self.dialog[step].timeline)

    local light = CCTintTo:create(0,255,255,255)
    local dack = CCTintTo:create(0,100,100,100)
    local light1 = CCTintTo:create(0,255,255,255)
    local dack1 = CCTintTo:create(0,100,100,100)
    self.rootItems.someone:runAction(self.dialog[step].direct and dack or light)

    if self.general then
        self.general:runAction(self.dialog[step].direct and light or dack)
    else
        self.rootItems.self:runAction(self.dialog[step].direct and light or dack)
        self.rootItems.selfface:runAction(self.dialog[step].direct and light1 or dack1)
    end
end

function first.clear(self)
    self.general = nil
    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode= nil
    end
    guide:removefirstlayer()
end

function first.init(self,parent,toppos,scale)

    self.scaleNum = scale
    self.toppos = toppos
    self.parent = parent

    self.name = ""
    self.profile = 0
    self.selectedgeneral = 0

    self.yunbg,self.yunbgitem = self:loadStoryCCB("story10_yun1",parent)

    local timeCB = {}
    timeCB["shownew"] = function()
        self.rootItems.selfnew:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.selectedgeneral)].animationid)].name
        self.general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.general:setAnimation("stand",true,0)
        self.general:setScale(1.5)
        self.rootItems.selfnew:addChild(self.general)
    end
    timeCB["gotoMainScene"] = function()
        self.yunbg:removeFromParentAndCleanup(true)
        if guide.controller then
            guide.controller:CompleteStep("animation")
            guide.controller:setGuideLayerVisible(false)
        end

        GameScene:init(mainScene)

    end
    timeCB["mainScenescale"] = function()
        --GameScene:toNormalScale()
    end

    self.rootNode,self.rootItems = self:loadStoryCCB("story10_renwu",parent,false,timeCB,2,0.85)
    self:loadStoryCCB("story10_heimu1",parent,true,nil,3)

    self.animationManager = getAnimationManager(self.rootItems)

    self.step = 1
    self:oneStep(self.step)

    self.rootItems.talkbutton:addHandleOfControlEvent(function()
        self.step = self.step +1
        if self.dialog[self.step].xuanren then
            gameWindows:openWindow("first",{},nil)
        elseif self.dialog[self.step].isend then
            self.rootItems.talkbutton:setEnabled(false)
            self:loadStoryCCB("story10_yun2",parent,true,nil,1)
            self.animationManager:setAnimationCompletedCallback(function()
                 self:clear()
                 if guide.controller then
                     guide.controller:setGuideLayerVisible(true)
                 end
                 gamedata.music:SetMusic(true)
                 gamedata.music:GameStart()
            end)
            self.animationManager:runAnimationsForSequenceNamed("story10_renwu_15")
        else
            self:oneStep(self.step)
        end
    end, CCControlEventTouchUpInside)
end

function first.afterselect(self)
    if gameWindows.windows["first"].show then
        gameWindows:closeWindow("first")
    end
    self:oneStep(self.step)
end

function first.setSelectProfile(data,item,index,callback)
    local select = 3
    local name = ""

    local selectconfig = {
        [1] = {pos = ccp(284,276),id= 10101 },
        [2] = {pos = ccp(284,56),id= 10106 },
        [3] = {pos = ccp(284,-187),id= 10111},
    }

    function setFirstName(name_)
        name = name_
        item.namelabel:setString(name)
    end

    item.confirm:addHandleOfControlEvent(function()
        if select == 0 then
            -- runGamePrompt({msg = "请选择形象"})
            runGamePrompt({msg = gameConfig.strings:string_common("layer_first",7)})
        elseif name == "" then
            -- runGamePrompt({msg = "请输入昵称"})
            runGamePrompt({msg = gameConfig.strings:string_common("layer_first",8)})
        else
            guide.first.name = name
            guide.first.profile = select
            guide.first.selectedgeneral = selectconfig[select].id
            guide.first.selectwindowindex = index

            UIRequest({type = 101,name =name} )
            if callback then callback() end
        end

    end, CCControlEventTouchUpInside)
    item.confirm:setSwallowsTouch(true)
    item.confirm:setTouchPriority(gameConfig.touchPriority.topwindow-2*index)


    item.selectsprite:setPosition(selectconfig[select].pos)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(selectconfig[select].id)].animationid)].name
    local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    general:setAnimation("stand",true,0)
    general:setScale(1)
    item.profile:addChild(general)

--    local co = {
--        "stand",
--        "attack",
--        "skill01_01",
--        "skill01_02",
--        "skill01_03",
--        "skill01_04",
--        "skill01_05",
--        "skill01_06",
--        "skill01_07",
--        "skill02",
--        "death",
--        "celebrate",
--        "dodge",
--        "injured",
--        "run"
--    }
--    local names = {
--        "nvzhujueyijie",
--        "nvzhujueerjie",
--        "nvzhujuesanjie",
--        "nvzhujuesijie",
--        "nvzhujuewujie",
--    }
--
--    local index = 2
--    local index2 = 1
    for i=1, 3 do
        item["select"..i]:addHandleOfControlEvent(function()
--            if i==2 then runGamePrompt({msg = "暂未开放，敬请期待！！"})  end
            if select == i then return end
            select = i

            item.selectsprite:setPosition(selectconfig[select].pos)
            item.profile:removeAllChildrenWithCleanup(true)
            local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(selectconfig[select].id)].animationid)].name
            general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            general:setAnimation("stand",true,0)
            general:setScale(1)
            item.profile:addChild(general)

--            if i==1 then
--                item.selectsprite:setPosition(selectconfig[select].pos)
--                item.profile:removeAllChildrenWithCleanup(true)
--                --local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(selectconfig[select].id)].animationid)].name
--                local generalName = names[index]
--                print(generalName)
--                general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
--                general:setAnimation("attack",true,0)
--                general:setScale(1)
--                item.profile:addChild(general)
--                index = index+1
--                if index >5 then index = 1 end
--            else
--                general:setAnimation(co[index2],true,0)
--                index2 = index2+1
--                if index2 >15 then index2 = 1 end
--            end

        end, CCControlEventTouchUpInside)
        item["select"..i]:setSwallowsTouch(true)
        item["select"..i]:setTouchPriority(gameConfig.touchPriority.topwindow-2*index)
    end

    local beginfunc = function(label)
        setFirstName("")
    end

    local endfunc = function(label,text,box)
        setFirstName(text)
        box:setText("")
    end

    item.nameInputBox = ui.creatInputEditBoxBylable(item.namelabel,kEditBoxInputModeSingleLine,beginfunc,endfunc,
        {
            fontSize = 50,
            fontColor = ccc3(93,56,42),
            length = 12
        })
    item.nameInputBox:setTouchPriority(gameConfig.touchPriority.topwindow-2*index)

    item.randomnameButton:addHandleOfControlEvent(function()
        UIRequest({type = 100})
    end, CCControlEventTouchUpInside)
    item.randomnameButton:setSwallowsTouch(true)
    item.randomnameButton:setTouchPriority(gameConfig.touchPriority.topwindow-2*index)

end

return first