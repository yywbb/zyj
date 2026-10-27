--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/9/8
-- Time: 下午4:20
-- To change this template use File | Settings | File Templates.
--


local generalInfo = {
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"tupo"},--,"train"},
    -- pagename = {"突破","培养"},
    pagename = {gameConfig.strings:string_common("popups","tupo")},--,gameConfig.strings:string_common("popups","peiyang")},
    selectpage = "tupo",

    data = {}

}

function generalInfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/general_tupo", nil, true, "general_tupo")

    self.touchPriority = touchPriority
    self.selectpage = data.selectpage or self.selectpage
    GameScene:setLayerpageshift(self,self,self.touchPriority)
    GameScene:shiftlayerpage(self,self,self.selectpage)

--    ui.addGray("CCSprite",self.rootItems.buttonsprite2)
--    ui.addGray("CCLabelBMFont",self.rootItems.buttontext2)
--    self.rootItems.button2:addHandleOfControlEvent(function()
--        runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng2")})
--    end, CCControlEventTouchUpInside)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("generalUp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)

    self.rootItems.topnode:setPositionY((GameScene.topposY-1920)*0.5+1920-80)
    self.rootItems.bottomnode:setPositionY((1920-GameScene.topposY)*0.5)
    self.rootItems.tupomid:setPositionY(-(1920-GameScene.topposY)*0.5+840)
    --self.rootItems.bg:setPositionY((1920-GameScene.topposY)*0.5-70)

    self:reload(data,callback)

    return self.rootNode, true
end

function generalInfo.close(self)

    self.selectpage = "up"
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.General = nil
    self.Generalnext = nil
    self.data = {}

    if self.callback then
        self.callback()
    end
end

function generalInfo.reload(self,data,callback)
    self.callback = callback
    self.data.general = data.general or {}
    self.selectpage = data.selectpage or self.selectpage

    ui.setLabelString(self.rootItems.des,nil,48 )
    ui.setLabelString(self.rootItems.desnext,nil,48 )
    ui.setLabelString(self.rootItems.desneed,nil,49 )
    ui.setLabelString(self.rootItems.tupotext,nil,18 )

    self:shiftPage(self.selectpage)
end

function generalInfo.shiftPage(self,type,olddata)
    self.selectpage = type

    for k,v in ipairs(self.pageconfig) do
        if v == type then
            self.rootItems[v.."Node"]:setVisible(true)
            self.rootItems[v.."Node"]:setPositionX(0)
        else
            self.rootItems[v.."Node"]:setVisible(false)
            self.rootItems[v.."Node"]:setPositionX(9999)
        end
    end

    if self.selectpage == "tupo" then
         self:setPage_tupo()
    else
        --self:setPage_tupo()
    end
end

function generalInfo.setTupoNext(self,data)
    self.data.fragment = data.fragment
    self.data.nextGeneral = data.nextGeneral
    self.data.prop = data.prop

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local general_awake = gamedata.config.general_awake or {}
    if not self.Generalnext then
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        self.Generalnext = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.Generalnext:setAnimation("stand",true,0)
        self.Generalnext:setScale(1.6)
        self.rootItems.generalnext:addChild(self.Generalnext)
    end
    ui.setLabelString(self.rootItems.generalnamenext,generalConfig.name..(self.data.general.level2+1>0 and " +"..(self.data.general.level2+1) or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)

    ui.setLabelString(self.rootItems.atknext,self.data.nextGeneral.atk,23)
    ui.setLabelString(self.rootItems.defnext,self.data.nextGeneral.defense,23)
    ui.setLabelString(self.rootItems.hpnext,self.data.nextGeneral.hp,23)
    ui.setLabelString(self.rootItems.speednext,self.data.nextGeneral.speed,23)

    local newskillid = generalConfig["break"..(self.data.general.level2+1)]
    if newskillid and newskillid ~= 0 then
        self.rootItems.newskillnode:setVisible(true)
        ui.setLabelString(self.rootItems.newskillname,"解锁技能: "..gamedata.config.breakskill[tostring(newskillid)].name,48)
        ui.setLabelString(self.rootItems.newskilldes,gamedata.config.breakskill[tostring(newskillid)].desc,14)
    else
        self.rootItems.newskillnode:setVisible(false)
    end

    local fragmentnum = self.data.fragment and self.data.fragment.num or 0
    local propnum = self.data.prop and self.data.prop.num or 0
    local needfragment = general_awake[tostring(self.data.general.level2+1)][tostring(generalConfig.quality).."piece"]
    local needprop =  general_awake[tostring(self.data.general.level2+1)][tostring(generalConfig.quality).."prop"]
    local needcoin = general_awake[tostring(self.data.general.level2+1)]["coin"..tostring(generalConfig.quality)]

    self.rootItems.propnode:setVisible(needprop~=0)
    self.rootItems.soulnode:setVisible(needfragment~=0)

    ui.setLabelString(self.rootItems.neednum1,fragmentnum.."/"..needfragment, fragmentnum>=needfragment and 14 or 47)
    ui.setLabelString(self.rootItems.neednum2,propnum.."/"..needprop, propnum>=needprop and 14 or 47)
    ui.setLabelString(self.rootItems.coin,needcoin, GameScene.roleinfo.coin>=needcoin and 14 or 47)

    self.rootItems.tupobuntton:setSwallowsTouch(true)
    self.rootItems.tupobuntton:setTouchPriority(self.touchPriority)

    if self.data.general.level1 < general_awake[tostring(self.data.general.level2+1)].level then
        ui.addGray("CCControlButton",self.rootItems.tupobuntton)
        ui.addGray("CCLabelTTF",self.rootItems.tupotext)
        self.rootItems.tupobuntton:addHandleOfControlEvent(function()
            -- runGamePrompt({msg = "伙伴等级不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","pslvbz")})
        end, CCControlEventTouchUpInside)
    elseif fragmentnum < needfragment then
        ui.addGray("CCControlButton",self.rootItems.tupobuntton)
        ui.addGray("CCLabelTTF",self.rootItems.tupotext)
        self.rootItems.tupobuntton:addHandleOfControlEvent(function()
            -- runGamePrompt({msg = "伙伴魂魄不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","hplvbz")})
        end, CCControlEventTouchUpInside)
    elseif propnum < needprop then
        ui.addGray("CCControlButton",self.rootItems.tupobuntton)
        ui.addGray("CCLabelTTF",self.rootItems.tupotext)
        self.rootItems.tupobuntton:addHandleOfControlEvent(function()
            -- runGamePrompt({msg = "突破丹不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","tpdbz")})
        end, CCControlEventTouchUpInside)
    elseif GameScene.roleinfo.coin < needcoin then
        ui.addGray("CCControlButton",self.rootItems.tupobuntton)
        ui.addGray("CCLabelTTF",self.rootItems.tupotext)
        self.rootItems.tupobuntton:addHandleOfControlEvent(function()
            -- runGamePrompt({msg = "银币不足"})
            --runGamePrompt({msg = gameConfig.strings:string_common("popups","coinbz")})
            shortCoin()
        end, CCControlEventTouchUpInside)
    else --if propnum < needprop then
        ui.removeGray("CCControlButton",self.rootItems.tupobuntton)
        ui.removeGray("CCLabelTTF",self.rootItems.tupotext)
        self.rootItems.tupobuntton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 1017, ids = {self.data.general.cid}})
        end, CCControlEventTouchUpInside)
    end
end

function generalInfo.resetPage_tupo(self,data)
    self.rootItems.closeButton:setEnabled(false)
    self.rootItems.tupobuntton:setEnabled(false)
    local effectccb,effectitem = CCBReaderLoad("UIEffect/huobantupo/n_huobantupo", nil, true, "n_huobantupo")

    local animationManager = getAnimationManager(effectitem)
    animationManager:runAnimationsForSequenceNamed("n_huobantupo")

    if effectitem.topnode then
        effectitem.topnode:removeFromParentAndCleanup(false)
        self.rootItems.effectnode_top:addChild(effectitem.topnode)
        effectitem.topnode:setPosition(0,0)
    end
    if effectitem.bottomnode then
        effectitem.bottomnode:removeFromParentAndCleanup(false)
        self.rootItems.effectnode_bottom:addChild(effectitem.bottomnode)
        effectitem.bottomnode:setPosition(0,0)
    end

    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(2.2), CCCallFunc:create(function()

        gameWindows:openWindow("generalupfinish",{data = table.copy(self.data)},nil)
        self.data = {}
        self.data.general = data.general
        self:setPage_tupo()
        self.rootItems.closeButton:setEnabled(true)
        self.rootItems.tupobuntton:setEnabled(true)
        print("generalupfinish,openWindow")

    end))
    self.rootItems.effectnode_top:runAction(sequence)


end


function generalInfo.setPage_tupo(self,data)
    if data then self.data.general = data end
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local general_awake = gamedata.config.general_awake or {}


    local maxlv = table.getTableLength(general_awake) or 10

    if not self.General then
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        self.General = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.General:setAnimation("stand",true,0)
        self.General:setScale(1.6)
        self.rootItems.general:addChild(self.General)
    end
    ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)

    ui.setLabelString(self.rootItems.atk,self.data.general.atk,14)
    ui.setLabelString(self.rootItems.def,self.data.general.defense,14)
    ui.setLabelString(self.rootItems.hp,self.data.general.hp,14)
    ui.setLabelString(self.rootItems.speed,self.data.general.speed,14)

    if self.data.general.level2< maxlv then
        self.rootItems.tupocontrolnode:setVisible(true)
        -- ui.setLabelString(self.rootItems.condition,"需要等级: "..self.data.general.level1.."/"..general_awake[tostring(self.data.general.level2+1)].level,(self.data.general.level1+0<general_awake[tostring(self.data.general.level2+1)].level+0 and 27 or 26))
        ui.setLabelString(self.rootItems.condition,gameConfig.strings:needlv(self.data.general.level1,general_awake[tostring(self.data.general.level2+1)].level),(self.data.general.level1+0<general_awake[tostring(self.data.general.level2+1)].level+0 and 47 or 31))

        local fragmentcid = self.data.general.cid
        for k,v in pairs(gamedata.config.general_fragment) do
            if v.general == self.data.general.cid then fragmentcid = v.id end
        end
        ui.setNewIcon(self.rootItems,{cid = fragmentcid})
        -- ui.setLabelString(self.rootItems.needname1,generalConfig.name.."魂魄", generalConfig.quality and 2*generalConfig.quality-1 or 1)
        ui.setLabelString(self.rootItems.needname1,gameConfig.strings:hunpo(generalConfig.name), generalConfig.quality and 2*generalConfig.quality-1 or 1)

        ui.setNewIcon(self.rootItems,{cid = 20017},1)
        local prop = ui.IDconfig(20017)
        ui.setLabelString(self.rootItems.needname2, prop.name, prop.quality>0 and 2*prop.quality-1 or 1)

        if not self.data.nextGeneral then
             UIRequest({type = 1023,general = self.data.general.iid})
        end
    else
        -- ui.setLabelString(self.rootItems.condition,"已达最高阶",48)
        ui.setLabelString(self.rootItems.condition,gameConfig.strings:string_common("popups","dddj"),48)
        self.rootItems.tupocontrolnode:setVisible(false)
        self.rootItems.nextdatanode:setVisible(false)
        self.rootItems.nextGeneralnode:setVisible(false)
    end
end


return generalInfo �0  