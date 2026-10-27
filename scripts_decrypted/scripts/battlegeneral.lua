--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-7-23
-- Time: 下午5:49
-- To change this template use File | Settings | File Templates.
--

local general = {

    rootNode = nil,

    generalNode = nil,
    generalNodeItem = nil,

    ccb = nil,
    ccbDocumentControler = {},

    node = nil,

    ccbold = 0,
    ccbnew = 0,
    -- damageConfig = {
    --     loseblood_normal = "",
    --     loseblood_critical = "暴击",
    --     dot = "中毒",
    --     dot2 = "持续中毒"
    --     dodge = "",
    --     parry = "格挡",
    --     defense = "招架",
    --     addblood_normal = "",
    --     addblood_critical = "暴击",
    --     manxue = "满血"
    -- },

    damageConfig = gameConfig.strings.damageConfig,

    damageTrunCconfig = {
        dodge = "atk",
        parry = "atk",
    },

    --前后层buff
    constbufferS = {
        atk_promote = true,
    },

    damageeffectnum = {
        addblood_critical = 3,
        addblood_normal = 3,
        dodge = 1,
        dot = 1,
        dot2 = 1,
        firing = 1,
        loseblood_critical = 3,
        loseblood_normal = 3,
        manxue = 1,
        parry = 1,
        loseblood_cut = 3,
        loseblood_sacrifice = 1,
        loseblood_fight = 3,
        loseblood_proof = 3,

        loseblood_normal_beike = 3,
        loseblood_normal_kezhi = 3,
        loseblood_critical_beike = 3,
        loseblood_critical_kezhi = 3,
        loseblood_cut_beike = 3,
        loseblood_cut_kezhi = 3,
        loseblood_fight_beike = 3,
        loseblood_fight_kezhi = 3,
    },

    apcolors = {
        [0] = ccc3(0,0,0),
        [1] = ccc3(255,224,39),
        [2] = ccc3(0,250,256),
        [3] = ccc3(255,64,255),
        [4] = ccc3(255,64,255),
        [5] = ccc3(255,64,255),
        [6] = ccc3(255,64,255),
        [7] = ccc3(255,64,255),
    },

    aprgbs = {
        [0] = {0,0,0},
        [1] = {255,224,39},
        [2] = {0,250,256},
        [3] = {255,64,255},
        [4] = {255,64,255},
        [5] = {255,64,255},
        [6] = {255,64,255},
        [7] = {255,64,255},

    },

    deadStatus = {
        mifengjishu = true,
    }


}

general.__index = general

function general.skeletonTintTo(self,TintTo)
    if self.skeleton.g1 then
        self.skeleton.g1:runAction(TintTo)
    else
        self.skeleton:runAction(TintTo)
    end
end

function general.hideAllBuffer(self,visible)
    self.bufferfrontNode:setVisible(visible)
    self.bufferbackNode:setVisible(visible)
end

function general.setTempZ(self)
    self.rootNode:setZOrder(self.pos.z+2)
end

function general.setskillZ(self)
    self.rootNode:setZOrder(2000)
    self:rootScale(1.2)
end

function general.setOriginZ(self)
    self.rootNode:setZOrder(self.pos.z)
    self:rootScale(1)
end

function general.addTarget(self)
    if not self.effectccbs.target then
        self.effectccbs.target = {}
        self.effectccbs.target.ccb, self.effectccbs.target.item = CCBReaderLoad("target/target", nil, true, "target")
        self.effectccbs.target.animationManager = getAnimationManager(self.effectccbs.target.item)
        self.effectccbs.target.ccb:setPosition(ccp(0,0))
        self.targetNode:addChild(self.effectccbs.target.ccb)
    end
    self.effectccbs.target.ccb:setVisible(true)
    self.effectccbs.target.animationManager:runAnimationsForSequenceNamed("target")
end

function general.removeTarget(self)
    --self.targetNode:removeAllChildrenWithCleanup(true)
end

function general.removeAllbuffer(self)
    self.bufferfrontNode:removeAllChildrenWithCleanup(true)
    self.bufferbackNode:removeAllChildrenWithCleanup(true)
    self.bufferccbs = {}
end

function general.reborn(self,data)
    self.SkeletonNode:stopAllActions()
    self.deathNode:stopAllActions()
    self.deathNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
        self.deathNode:removeAllChildrenWithCleanup(true)
        self.SkeletonNode:setVisible(true)
        self.ccb:setVisible(true)
        self.skeleton:setAnimation("stand",true,0)
        self:setBlood(data,true)
    end)))
    self.isdead = false
end

function general.death(self,delay,data)
    self.isdead = true

    if delay then gamedata.music:PlaySound(self.data.animation.deadaudio) end
    self:removeTarget()
    self:removeAllStatus()
    self:removeAllbuffer()
    self.SkeletonNode:stopAllActions()
    self.deathNode:stopAllActions()
    self.skeleton:setAnimation(data and data.action or "death",false,0)
    self.deathNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(delay or 0), CCCallFunc:create(function()
        local ccb, ccbDocumentControler = CCBReaderLoad("death/death", nil, true, "death")
        ccb:setPosition(ccp(0,0))
        if self.direct == "def" then
            ccb:setScaleX(-1)
        end
        if self.coverccb then self.coverccb:setVisible(false) end
        self.deathNode:addChild(ccb)
        self.SkeletonNode:setVisible(false)
        self.ccb:setVisible(false)
    end)))
end

function general.injureEffect(self)
    --print("injureEffect")
    if not self.effectccbs.injuerd then
        self.effectccbs.injuerd = {}
        self.effectccbs.injuerd.ccb, self.effectccbs.injuerd.item = CCBReaderLoad("Effect/injured", nil, true, "injured")
        self.effectccbs.injuerd.animationManager = getAnimationManager(self.effectccbs.injuerd.item)
        self.effectccbs.injuerd.ccb:setPosition(0,0)
        self.rootNode:addChild(self.effectccbs.injuerd.ccb)
        if self.direct == "atk" then
            self.effectccbs.injuerd.ccb:setScaleX(-1)
        end
    end
    self.effectccbs.injuerd.ccb:setVisible(true)
    self.effectccbs.injuerd.animationManager:runAnimationsForSequenceNamed("injured")
end

function general.coverInjureEffect(self,data)
    printT(data,"coverinjureEffect")
    if not self.data.cover_l or self.data.cover_l<=0 then return end
    if not data.damage2 then return end
    -- if not data.damage2 or data.damage2<=0 then return end
    if self.coverccb then

        if data.damage2 >= 0 then
            self.coveritem.damage:setString(0-data.damage2)
        else
            self.coveritem.damage:setString("+"..(0-data.damage2))
        end
        self.coveranimationManager:runAnimationsForSequenceNamed("moqi")
    end


end

function general.redBlink(self)
    --print("general redBlink")
    local red = CCTintTo:create(0.2,255,0,0)
    local back = CCCallFunc:create(function() 
            self:setColorStatus()
        end)
    local sq = CCSequence:createWithTwoActions(red,back)
    self:skeletonTintTo(sq)
end

function general.injureAction(self,data)
    --print("general injureAction")
    if data.isneedaudio then
        gamedata.music:PlaySound(self.data.animation.injureaudio)
    end

    if self.data.cid ~= 30001 and self.data.cid ~= 30002 then
        self.skeleton:setAnimation("injured",false,0)
        self.SkeletonNode:stopAllActions()
        self.skeleton:addAnimation(self:findStandStatus(),true,0,0)
    end
end

function general.dodgeAction(self,data)
    self.SkeletonNode:stopAllActions()
    self.skeleton:setAnimation("dodge",false,0)
    self.SkeletonNode2 = CCNode:create()
    self.SkeletonNode:addChild(self.SkeletonNode2)
    self.skeleton2 = CCSkeletonAnimation:create(self.data.animation.name.."/"..self.data.animation.name..".json",self.data.animation.name.."/"..self.data.animation.name..".atlas",1)
    --.skeleton2:setAnimation("dodge",false,0)
    self.skeleton2:setPosition(0,0)
    self.skeleton2:setScale(1)
    local fade = CCFadeTo:create(0,125)
    local dack = CCTintTo:create(0,100,100,100)
    local spw = CCSpawn:createWithTwoActions(fade,dack)
    self.skeleton2:runAction(spw)
    if self.direct == "def" then
        self.skeleton2:setScaleX(-1)
    end
    self.SkeletonNode2:addChild(self.skeleton2)
    self.SkeletonNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.15), CCCallFunc:create(function()
        self.skeleton2:setAnimation("dodge",false,0)
        local fade2 = CCFadeTo:create(0.2,0)
        self.skeleton2:runAction(CCSequence:createWithTwoActions(fade2,CCCallFunc:create(function()
            self.SkeletonNode2:removeFromParentAndCleanup(true)
            self.SkeletonNode2 = nil
        end)))
    end)))
    self.SkeletonNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(data.actiondelay), CCCallFunc:create(function()
        self.skeleton:setAnimation(self:findStandStatus(),true,0)
    end)))
end

function general.addOneDamageEffect(self,idx,data)
    local ccb, ccbDocumentControler = CCBReaderLoad("Effect/damage_"..data.ccb, nil, true, data.ccb)
    local animationManager = getAnimationManager(ccbDocumentControler)
    self.effectccbs["damage_"..data.ccb][idx] = {ccb=ccb,item=ccbDocumentControler,animationManager = animationManager}
    self.effectccbs["damage_"..data.ccb][idx].ccb:setPosition(0,0)
    self.damageNode:addChild(self.effectccbs["damage_"..data.ccb][idx].ccb)
    self["damage_"..data.ccb.."index"] = idx

    if self.damageTrunCconfig[data.ccb] and self.direct ~= self.damageTrunCconfig[data.ccb] then
        ccb:setScaleX(-1)
        local index = 1
        while ccbDocumentControler["00"..index] do
            if not self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]]["00"..index.."ScaleX"] then
                self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]]["00"..index.."ScaleX"] = ccbDocumentControler["00"..index]:getScaleX()
            end
            ccbDocumentControler["00"..index]:setScaleX(-1*self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]]["00"..index.."ScaleX"])
            index = index+1
        end
    end
    ccb:setVisible(false)
    return ccb, ccbDocumentControler,animationManager
end

function general.damageEffect(self,data)
    --print("damageEffect",data.ccb)

    if not self.effectccbs["damage_"..data.ccb] then
        self.effectccbs["damage_"..data.ccb]={}
    end

    local ccb,ccbDocumentControler,animationManager
    local total = #self.effectccbs["damage_"..data.ccb]
    if total < self.damageeffectnum[data.ccb] then
        ccb,ccbDocumentControler,animationManager = self:addOneDamageEffect(total+1,data)

    else
        self["damage_"..data.ccb.."index"] = self["damage_"..data.ccb.."index"] +1
        if self["damage_"..data.ccb.."index"] > self.damageeffectnum[data.ccb] then self["damage_"..data.ccb.."index"] = 1 end
        ccb,ccbDocumentControler = self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]].ccb,self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]].item
        animationManager = self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]].animationManager
    end

    ccb:setVisible(true)

    for i=1,2 do
        if ccbDocumentControler["damagelabel"..i] then
            ccbDocumentControler["damagelabel"..i]:setString(math.abs(data.damage))
        end
    end

    local Sequence_ext = ""
    if string.find(data.ccb,"blood") then
        if string.find(data.ccb,"normal") then
            Sequence_ext = math.random(1,3)
        else
            Sequence_ext = ""
        end
    end

    animationManager:runAnimationsForSequenceNamed(data.ccb..Sequence_ext)
end

function general.loseBloodOnce(self,data)
    print("damageEffect")
    if self.hp <= 0 and data.damage > 0 then return end
    if self.hp >= self.hptotal and data.damage < 0 then return end
--    if data.damage == 0 and data.ccb ~= "dodge" then return end

--    if data.status then
--        self:updateStatus(data.status)
--    end

    if data.damage >0 then
        if data.shake then
            self.battleScene:shake(data.shake)
        end

        if self.hp - data.damage > 0 then
            if data.ccb == "dot" or data.ccb == "dot2" or data.ccb == "loseblood_proof" then
            else
                self:injureAction(data)
                self:injureEffect()
                self:redBlink()
            end
        else
            self:death(1.5,data)
            self:injureEffect()
            self:redBlink()
        end
        self:setBlood(data)
        self:damageEffect(data)
    elseif data.damage == 0 then
        if data.ccb == "dodge" then
            self:dodgeAction(data)
            self:damageEffect(data)
        end
    else
        self:setBlood(data)
        self:damageEffect(data)
    end

    if data.damage2>0 then
        self:coverInjureEffect(data)
        self:setCover(data)
    elseif data.damage2 ~= 0 then
        self:setCover(data)
        self:coverInjureEffect(data)
    end

    if data.damage3 and data.damage3 > 0 then
        self:sethudun(data)
    end
end

function general.buffer(self,buffer)
    if self.hp <= 0 then return end

    printT(buffer)
    print(self.direct,self.pos)
    printT(self.bufferccbs)
    if buffer.type == "zhujue" then

        self:ccbeffect({
            dir = "zhujuebeidong",
            name = "jiagong",
        },"atk",0.5)

        self.bufferfrontNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
            if not  self.bufferccbs.jigong_dou then
                self.bufferccbs.jigong_dou = {}
                self.bufferccbs.jigong_dou.ccb, self.bufferccbs.jigong_dou.item = CCBReaderLoad("zhujuebeidong/jigong_dou", nil, true, "jigong_dou")
                self.bufferccbs.jigong_dou.ccb:setPosition(0,0)
                self.bufferfrontNode:addChild(self.bufferccbs.jigong_dou.ccb)
            end

            for i=1, 6 do
                self.bufferccbs.jigong_dou.item[""..i]:setVisible(i<= buffer.num)
            end
        end)))
    elseif buffer.type == "const" then
        if buffer.switch then
            if self.bufferccbs[buffer.name] then
                if self.bufferccbs[buffer.name].animationManager then
                    self.bufferccbs[buffer.name].animationManager:runAnimationsForSequenceNamed(buffer.name)
                end
                if self.bufferccbs[buffer.name].animationManager2 then
                    self.bufferccbs[buffer.name].animationManager2:runAnimationsForSequenceNamed(buffer.name)
                end
            else
                self.bufferccbs[buffer.name] = {}
                if self.constbufferS[buffer.name] then
                    local frontccb, frontitem = CCBReaderLoad("Effect/bufffer_"..buffer.name.."_front", nil, true, buffer.name)
                    self.bufferccbs[buffer.name].topnode = frontccb
                    frontccb:setPosition(0,0)
                    self.bufferfrontNode:addChild(frontccb)
                    self.bufferccbs[buffer.name].animationManager = getAnimationManager(frontitem)
                    self.bufferccbs[buffer.name].animationManager:runAnimationsForSequenceNamed(buffer.name)

                    local backccb, backitem = CCBReaderLoad("Effect/bufffer_"..buffer.name.."_back", nil, true, buffer.name)
                    self.bufferccbs[buffer.name].bottomnode = backccb
                    backccb:setPosition(0,0)
                    self.bufferbackNode:addChild(backccb)
                    self.bufferccbs[buffer.name].animationManager2 = getAnimationManager(backitem)
                    self.bufferccbs[buffer.name].animationManager2:runAnimationsForSequenceNamed(buffer.name)
                else
                    local sourceccb, sourceccbitem = CCBReaderLoad("Effect/bufffer_"..buffer.name, nil, true, buffer.name)
                    self.bufferccbs[buffer.name].animationManager = getAnimationManager(sourceccbitem)
                    self.bufferccbs[buffer.name].animationManager:runAnimationsForSequenceNamed(buffer.name)
                    sourceccb:setPosition(ccp(0,0))
                    self.bufferfrontNode:addChild(sourceccb)
                    self.bufferccbs[buffer.name].topnode = sourceccb
                end
            end
        elseif buffer.switch == false and self.bufferccbs[buffer.name] then
            if self.bufferccbs[buffer.name].topnode then
                self.bufferccbs[buffer.name].topnode:removeFromParentAndCleanup(true)
            end
            if self.bufferccbs[buffer.name].bottomnode then
                self.bufferccbs[buffer.name].bottomnode:removeFromParentAndCleanup(true)
            end
            self.bufferccbs[buffer.name] = nil
        end

    elseif (buffer.type == "normal") and (buffer.switch == true) then
        local ccb, ccbDocumentControler = CCBReaderLoad("Effect/bufffer_"..buffer.name, nil, true, buffer.name)

        ccb:setPosition(0,0)
        self.rootNode:addChild(ccb)

        local animationManager1 = getAnimationManager(ccbDocumentControler)
        animationManager1:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)
        animationManager1:runAnimationsForSequenceNamed(buffer.name)
    end
    print("buffer end")
end

function general.getnewposition(self,parent,child,needturn)
    local oldpos = {x = child:getPositionX(),y = child:getPositionY() }
    local anchor = parent:getAnchorPoint()
    local size =  parent:getContentSize()

    return ccp(needturn and size.width*anchor.x - oldpos.x or oldpos.x-size.width*anchor.x, oldpos.y-size.height*anchor.y)
end

function general.clearccbeffect(self,delay)
    self.frontNode:stopAllActions()
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(delay), CCCallFunc:create(function()
        self.frontNode:removeAllChildrenWithCleanup(true)
        self.backNode:removeAllChildrenWithCleanup(true)
        self.frontccbs = {}
        self.backccbs = {}
        self:setOriginZ()
    end))
    self.frontNode:runAction(sequence)
end

function general.clearccbeffectbyname(self,delay,name)

    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(delay), CCCallFunc:create(function()
        self.frontccbs[name.."count"] = (self.frontccbs[name.."count"] or 0) - 1
        if self.frontccbs[name.."count"] <=0 and self.frontccbs[name] then
            self.frontccbs[name]:removeFromParentAndCleanup(true)
            self.frontccbs[name] = nil
            self.frontccbs[name.."count"] = 0
        end

        self.backccbs[name.."count"] = (self.backccbs[name.."count"] or 0) - 1
        if self.backccbs[name.."count"] <=0 and self.backccbs[name] then
            self.backccbs[name]:removeFromParentAndCleanup(true)
            self.backccbs[name] = nil
            self.backccbs[name.."count"] = 0
        end

        if table.getTableLength(self.frontccbs) ==0 and table.getTableLength(self.backccbs) ==0 then
            self:setOriginZ()
        end
    end))
    self.frontNode:runAction(sequence)
end

function general.skillpreEffect(self,common)
    local ccb,item = CCBReaderLoad("UIEffect/guang/guang", nil, true, "guang")
    self.frontNode:addChild(ccb)

    item.qualitynode:setVisible(self.data.quality >=3)
    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("guang")

end

function general.scopeEffect(self,common)
    local scopetype = {
            [1] = "tian",
            [2] = "di",
            [3] = "ren",
        }   

    if not self.data.scope or not scopetype[self.data.scope] then return false end

    local scopekey = scopetype[self.data.scope]
    local ccb,item = CCBReaderLoad("shuxingzhanshi/shuxingzhanshi_"..scopekey, nil, true, "scopekey")
    ccb:setPosition(0,0)
    self.frontNode:addChild(ccb)

    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("shuxingzhanshi_"..scopekey)
    return true
end

function general.ccbeffectwithoutddelay(self,data,type,ccbdelay)
    if not data.dir or not data.name then return end

    if self.tempSkillanimation == nil then
        self.tempSkillanimation = {}
        for k,v in pairs(gamedata.config.skillanimation) do
            self.tempSkillanimation[v.name] = k
        end
    end

    local _skillname = data.name
    local _dir = data.dir

    if battleScene.isUseEffect3 then
        if _dir == "mowangchongji1" then
            _dir = "mowangchongji"
        end

        if _dir == "mowangyiji1" then
            _dir = "mowangyiji"
        end

        local _animationId1 = self.tempSkillanimation[_dir]
        
        if _animationId1 ~= nil then
            local _animationId2 = gamedata.config.skillanimation[tostring(_animationId1)].name2

            if _animationId2 > 0 then
                _dir = gamedata.config.skillanimation[tostring(_animationId2)].name
                _skillname = _dir.."02"
            end
        end
    end

    local sourceccb, sourceccbitem = CCBReaderLoad(_dir.."/".._skillname, nil, true, _skillname)
    local animationManager = getAnimationManager(sourceccbitem)
    print("runAnimationsForSequenceNamed",_skillname)
    animationManager:runAnimationsForSequenceNamed(_skillname)

    self:clearccbeffectbyname(ccbdelay-(data.delay or 0),_skillname)

    local needturn = false
    print("generalneedturn======",self.direct,type)
    if type and self.direct ~= type then
        needturn = true
        local i = 1
        while sourceccbitem["00"..i] do
            sourceccbitem["00"..i]:setFlipX(true)
            i=i+1
        end
        i = 1
        while sourceccbitem["000"..i] do
            sourceccbitem["000"..i]:setScaleX(-1)
            i=i+1
        end
    end

    if sourceccbitem.topnode or sourceccbitem.bottomnode then
        if sourceccbitem.topnode then
            sourceccbitem.topnode:removeFromParentAndCleanup(false)
            self.frontNode:addChild(sourceccbitem.topnode)
            sourceccbitem.topnode:setPosition(self:getnewposition(sourceccb,sourceccbitem.topnode,needturn))
            if needturn then sourceccbitem.topnode:setScaleX(-1) end
            self.frontccbs[data.name] = sourceccbitem.topnode
            self.frontccbs[data.name.."count"] = (self.frontccbs[data.name.."count"] or 0) + 1
        end
        if sourceccbitem.bottomnode then
            sourceccbitem.bottomnode:removeFromParentAndCleanup(false)
            self.backNode:addChild(sourceccbitem.bottomnode)
            sourceccbitem.bottomnode:setPosition(self:getnewposition(sourceccb,sourceccbitem.bottomnode,needturn))
            if needturn then sourceccbitem.bottomnode:setScaleX(-1) end
            self.backccbs[data.name] = sourceccbitem.bottomnode
            self.backccbs[data.name.."count"] = (self.backccbs[data.name.."count"] or 0) + 1
        end
    else
        sourceccb:setPosition(ccp(0,0))
        self.frontNode:addChild(sourceccb)
        if needturn then sourceccb:setScaleX(-1) end
        self.frontccbs[data.name] = sourceccb
        self.frontccbs[data.name.."count"] = (self.frontccbs[data.name.."count"] or 0) + 1
    end

    return  sourceccb, sourceccbitem
end

function general.ccbeffect(self,data,type,ccbdelay)
    self:setTempZ()
    local delayfunction = function()
--        self.frontNode:removeAllChildrenWithCleanup(true)
--        self.backNode:removeAllChildrenWithCleanup(true)
        print("ccbeffect  CCBReaderLoad",data.name)
        self:ccbeffectwithoutddelay(data,type,ccbdelay)

    end

    if data.delay and data.delay ~= 0 then
        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(data.delay), CCCallFunc:create(delayfunction))
        self.frontNode:runAction(sequence)
    else
        delayfunction()
    end
end

function general.attack(self,data)
    gamedata.music:PlaySound(self.data.animation.normalaudio)
    self:setTempZ()
    self.skeleton:setAnimation(data.action,false,0)
    self.SkeletonNode:stopAllActions()
    self.SkeletonNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(data.actiondelay), CCCallFunc:create(function()
        self.skeleton:setAnimation(self:findStandStatus(),true,0)
        self:setOriginZ()
    end)))
end

function general.skillattack(self,data,ccbeffectdelay)
    self:combskillattack(data,ccbeffectdelay)
    local sourceccb, sourceccbitem = CCBReaderLoad("skillrelease/skill_name", nil, true, "skill_name")
    sourceccb:setPosition(ccp(0,0))
    self.frontNode:addChild(sourceccb)
    self.frontccbs["skill_name"] = sourceccb

    local skillname = data.ccb.skillname
    local issmall = string.find(skillname,"_")
    if issmall then
        skillname = string.sub(skillname,1,issmall-1)
    end

    setSpriteFrameByName(sourceccbitem.skillname, skillname, "public/skillname_new")
    self:clearccbeffectbyname(1.6,"skill_name")
end

function general.combskillattack(self,data,ccbeffectdelay)
    if data.action and data.action ~= "" then
        self:setskillZ()
        self.skeleton:setAnimation(data.action,false,0)
        self.SkeletonNode:stopAllActions()

        self.skeleton:addAnimation(self:findStandStatus(),true,0,0)

        if self.a_skeleton then
            self.a_skeleton:setAnimation("attack",false,0)
            self.a_skeleton:addAnimation("battle",true,0,0)
        end

        self.SkeletonNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.6), CCCallFunc:create(function()
            self:setOriginZ()
            self:hideAllBuffer(true)
        end)))
    end

    local skill01data = {
        dir = "skillrelease",
        name = "skillrelease"..(self.data.quality >=5 and 5 or self.data.quality)
    }

    self:ccbeffectwithoutddelay(skill01data,nil,ccbeffectdelay-0.3)

    if data.hideeffect then self:hideAllBuffer(false) end
end

function general.breakskillattack(self,data,ccbeffectdelay)
    if data.action and data.action ~= "" then
        self:setTempZ()
        self.skeleton:setAnimation(data.action,false,0)
        self.SkeletonNode:stopAllActions()

        self.skeleton:addAnimation(self:findStandStatus(),true,0,0)

        if self.a_skeleton then
            self.a_skeleton:setAnimation("attack",false,0)
            self.a_skeleton:addAnimation("battle",true,0,0)
        end

        self.SkeletonNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.6), CCCallFunc:create(function()
            self:setOriginZ()
            self:hideAllBuffer(true)
        end)))
    end

    if data.ccb then
        self:ccbeffect(data.ccb,"atk",ccbeffectdelay)
    end

    if data.hideeffect then self:hideAllBuffer(false) end
end

function general.injured(self,data,ccbeffectdelay)
    for k, v in ipairs(data.damage) do
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(v.damagedelay),CCCallFunc:create(function()
            
            self:loseBloodOnce(v)
        end)))
    end
end

function general.sethudun(self,data)

    if data.damage and data.damage > 0 then
    else    
        self:injureAction(data)
    end    

    if not self.effectccbs["damage_"..data.ccb] then
        self.effectccbs["damage_"..data.ccb]={}
    end

    local ccb,ccbDocumentControler,animationManager
    local total = #self.effectccbs["damage_"..data.ccb]
    if total < self.damageeffectnum[data.ccb] then
        ccb,ccbDocumentControler,animationManager = self:addOneDamageEffect(total+1,data)

    else
        self["damage_"..data.ccb.."index"] = self["damage_"..data.ccb.."index"] +1
        if self["damage_"..data.ccb.."index"] > self.damageeffectnum[data.ccb] then self["damage_"..data.ccb.."index"] = 1 end
        ccb,ccbDocumentControler = self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]].ccb,self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]].item
        animationManager = self.effectccbs["damage_"..data.ccb][self["damage_"..data.ccb.."index"]].animationManager
    end

    ccb:setVisible(true)

    for i=1,2 do
        if ccbDocumentControler["damagelabel"..i] then
            ccbDocumentControler["damagelabel"..i]:setString(math.abs(data.damage3))
        end
    end

    local Sequence_ext = ""
    if string.find(data.ccb,"blood") then
        if string.find(data.ccb,"normal") then
            Sequence_ext = math.random(1,3)
        else
            Sequence_ext = ""
        end
    end

    animationManager:runAnimationsForSequenceNamed(data.ccb..Sequence_ext)


    if not self.effectccbs["damage_loseblood_hudun"] then
        self.effectccbs["damage_loseblood_hudun"]={}
    end

    if not self.effectccbs["damage_loseblood_hudun"][1] then
        self:addOneDamageEffect(1,{ccb="loseblood_hudun"})
    end    

    local ccb,ccbDocumentControler,animationManager
    ccb,ccbDocumentControler = self.effectccbs["damage_loseblood_hudun"][1].ccb,self.effectccbs["damage_loseblood_hudun"][1].item
    animationManager = self.effectccbs["damage_loseblood_hudun"][1].animationManager

    ccb:setVisible(true)

    for i=1,2 do
        if ccbDocumentControler["damagelabel"..i] then
            ccbDocumentControler["damagelabel"..i]:setString(math.abs(data.damage3))
        end
    end

    animationManager:runAnimationsForSequenceNamed("loseblood_hudun")
    
end    
function general.updateStatus(self,status,delay)

    local delayfunction = function()
        if  status.switch and not self[status.status.."status"] then
            self[status.status.."status"] = true
            if status.status == "sleep" then
                self.skeleton:setAnimation("sleep",true,0)
                return
            end

            self[status.status.."Node"]:removeAllChildrenWithCleanup(true)
            local ccb, item = CCBReaderLoad("Effect/status_"..status.status, nil, true, status.status)
            ccb:setPosition(0,0)
            self[status.status.."Node"]:addChild(ccb)
            local animationManager1 = getAnimationManager(item)
            animationManager1:runAnimationsForSequenceNamed("status_"..status.status)

            if status.status == "damageproof" then
                self[status.status.."status"] = false
            end
            
            if status.status == "dot" then
                self.isdot = true
                self:setColorStatus()
            end

            if status.status == "dot2" then
                self.isdot2 = true
                self:setColorStatus()
            end

            if status.status == "hide" then
                local fadeto = CCFadeTo:create(0,100)
                self:skeletonTintTo(fadeto)
            end

            if status.status == "dizzy" then
                self.skeleton:setAnimation("dizzy",true,0)
            end

            if status.status == "skillproof" then
                local big = 1.1 --1.5
                self.skeleton:setScale(big)
                if self.direct == "def" then
                    self.skeleton:setScaleX(-1*big)
                end
            end
        elseif not status.switch and self[status.status.."status"] then
            self[status.status.."status"] = false            
            if status.status == "sleep" then
                self.skeleton:setAnimation(self:findStandStatus(),true,0)
                return
            end

            self[status.status.."Node"]:removeAllChildrenWithCleanup(true)
            if status.status == "dot" then
                self.isdot = false
                self:setColorStatus()
            end

            if status.status == "dot2" then
                self.isdot2 = false
                self:setColorStatus()
            end

            if status.status == "skillproof" then
                local normal = 1
                self.skeleton:setScale(normal)
                if self.direct == "def" then
                    self.skeleton:setScaleX(-1*normal)
                end
            end

            if status.status == "dizzy" then
                self.skeleton:setAnimation(self:findStandStatus(),true,0)
            end

            if status.status == "hide" then
                local fadeto = CCFadeTo:create(0,255)
                self:skeletonTintTo(fadeto)
            end
        end
    end

    if delay and self[status.status.."Node"] then
        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(delay), CCCallFunc:create(delayfunction))
        self[status.status.."Node"]:runAction(sequence)
    else
        delayfunction()
    end
end

function general.removeAllStatus(self)
    self:updateStatus({status = "defup",switch = false})
    self:updateStatus({status = "dizzy",switch = false})
    self:updateStatus({status = "dot",switch = false})
    self:updateStatus({status = "dot2",switch = false})
    self:updateStatus({status = "frozen",switch = false})
    self:updateStatus({status = "invincible",switch = false})
    self:updateStatus({status = "invincible2",switch = false})
    self:updateStatus({status = "firing",switch = false})
    self:updateStatus({status = "skillproof",switch = false})
    self:updateStatus({status = "atkproof",switch = false})
    self:updateStatus({status = "absorb",switch = false})
    self:updateStatus({status = "sneered",switch = false})
    self:updateStatus({status = "locked",switch = false})
    self:updateStatus({status = "rage",switch = false})
    self:updateStatus({status = "sleep",switch = false})
    self:updateStatus({status = "hide",switch = false})
    self:updateStatus({status = "close",switch = false})
    self:updateStatus({status = "skilllock",switch = false})
    self:updateStatus({status = "feed",switch = false})
    self:updateStatus({status = "shield",switch = false})
    self:updateStatus({status = "mask",switch = false})
    self:updateStatus({status = "aim",switch = false})
    self:updateStatus({status = "primitive",switch = false})
    self:updateStatus({status = "statusproof",switch = false})
    self:updateStatus({status = "damageproof",switch = false})
    self:updateStatus({status = "foyin",switch = false})
    self:updateStatus({status = "cibei",switch = false})
    self:updateStatus({status = "fangdanbeixin",switch = false})
    self:updateStatus({status = "zhanshenxuetong",switch = false})
    self:updateStatus({status = "yonghengmengyan",switch = false})
    self:updateStatus({status = "leizhulongjia",switch = false})
    self:updateStatus({status = "shouhuzhilin",switch = false})
    self:updateStatus({status = "zhanyaochumo",switch = false})
    self:updateStatus({status = "jianzhenyin",switch = false})

    self:updateStatus({status = "shouhuyinji",switch = false})
    self:updateStatus({status = "zuzhou",switch = false})
    self:updateStatus({status = "diwanghudun",switch = false})
    self:updateStatus({status = "wangzhibaohu",switch = false})
    self:updateStatus({status = "yihuajiemu",switch = false})
    self:updateStatus({status = "shuhanbihu",switch = false})
    self:updateStatus({status = "jueqi",switch = false})
    self:updateStatus({status = "qianlong",switch = false})

    self:updateStatus({status = "qinglongyinji",switch = false})

end

function general.celebrate(self)
--    self.dizzyNode:setVisible(false)
--    self.dotNode:setVisible(false)
--    self.frozenNode:setVisible(false)
    general.removeAllStatus(self)
    if self.hp >0 then
        self.SkeletonNode:stopAllActions()
        self:clearccbeffect(0)
        self.iscelebrate = true
        self.skeleton:setAnimation("celebrate",true,0)
    end
end

function general.clear(self)

end

function general.stopAllEffect(self)
    self.rootNode:stopAllActions()
    self.SkeletonNode:stopAllActions()
    self.frontNode:stopAllActions()
    self.bufferfrontNode:stopAllActions()

    self.targetNode:removeAllChildrenWithCleanup(true)
    self.backNode:removeAllChildrenWithCleanup(true)
    self.bufferbackNode:removeAllChildrenWithCleanup(true)
    self.frontNode:removeAllChildrenWithCleanup(true)
    self.bufferfrontNode:removeAllChildrenWithCleanup(true)
    if  self.SkeletonNode2 then
        self.SkeletonNode2:stopAllActions()
        self.SkeletonNode2:removeFromParentAndCleanup(true)
    end

    self.standinNode:removeAllChildrenWithCleanup(true)
end

function general.setBlood(self,data,notdamagetotal)
    --print("general setBlood")

    if data.damage == 0 then return end
    local lastHP = self.hp
    self.hp =  self.hp - data.damage
    local realdamage = data.damage
    if self.hp <0 then
        realdamage = data.damage + self.hp
        self.hp = 0
    elseif self.hp > self.hptotal then
        realdamage = data.damage + self.hp - self.hptotal
        self.hp = self.hptotal
    end
    --print(self.hptotal,self.hp,self.direct,self.pos.o,"general hp ============================================",data.damage,data.damagedelay,data.action)

    local newhp = self.hp/self.hptotal
    local oldhp = lastHP/self.hptotal
    local scaleto = CCScaleTo:create(0.4,newhp,1)
    self.ccbDocumentControler.bloodfront:setScaleX(newhp)
    self.ccbDocumentControler.bloodback:setScaleX(oldhp)
    self.ccbDocumentControler.bloodback:runAction(scaleto)

    self.battleScene:setBlood(self.direct,realdamage)

    if  notdamagetotal then
    else
        self.battleScene:setDamageTotal(data.damage,self.direct)
    end

end

function general.setCover(self,data)
    if not data.damage2 or data.damage2 == 0 then return end
    local lastHP = self.cover_d
    self.cover_d =  self.cover_d - data.damage2
    local realdamage = data.damage2
    if self.cover_d <0 then
        realdamage = data.damage2 + self.cover_d
        self.cover_d = 0
    elseif self.cover_d > self.cover_d2 then
        realdamage = data.damage2 + self.cover_d - self.cover_d2
        self.cover_d = self.cover_d2
    end

    local newhp = self.cover_d/self.cover_d2

    if self.coveritem.blood then
        ui.setSpriteTextureRect2(self.coveritem.blood,0,0,15,163*newhp)
    end

    if self.cover_d<=0 then
        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.7), CCCallFunc:create(function()
            self.coverccb:setVisible(false)
        end))
        self.coverccb:runAction(sequence)
    else
        self.coverccb:setVisible(true)
    end
end

function general.InitBlood(self)
    local bloodtype  = self.data.boss and "bloodboss" or "blood"
    if bloodtype == "blood" then
        bloodtype = bloodtype..(self.data.quality >=5 and "nb" or "")
    end

    self.ccb, self.ccbDocumentControler = CCBReaderLoad("blood/"..bloodtype, nil, true, self.direct)
    self.ccb:setPosition(0,-10)
    self.ccb:setScaleX(0.8)
    self.ccb:setScaleY(0.9)

    --self.ccbDocumentControler.bloodback:setColor(self.direct == "atk" and ccc3(255,38,0) or ccc3(255,255,255))
    self.ccbDocumentControler.bloodfront:setColor(self.direct == "atk" and ccc3(101,185,43) or ccc3(255,38,0))

    self.ccbDocumentControler.bloodfront:setScaleX(self.hp/self.hptotal)
    self.ccbDocumentControler.bloodback:setScaleX(self.hp/self.hptotal)

    setSpriteFrameByName(self.ccbDocumentControler.cover1,self.direct == "atk" and "blood_07" or "blood_05")
    setSpriteFrameByName(self.ccbDocumentControler.cover2,self.direct == "atk" and "blood_06" or "blood_04")


    self:setAp()

    self.rootNode:addChild(self.ccb,100)
    self.ccb:setVisible(false)

    if self.data.cover_l and self.data.cover_l >0 and self.cover_d2 and self.cover_d2 >0 and self.cover_d and self.cover_d >0 then
        local quality = gamedata.config.mozhao_break[tostring(self.data.cover_l)].quality-1
        self.coverccb, self.coveritem = CCBReaderLoad("moqi/moqi_0"..quality, nil, true, "moqi_0")
        self.coveranimationManager = getAnimationManager(self.coveritem)
        ui.setSpriteTextureRect2(self.coveritem.blood,0,0,15,163*self.cover_d/self.cover_d2)
        print("moqi_blood init")
        self.coverccb:setPosition(0,0)
        if self.direct == "def" then
            self.coverccb:setScaleX(-1)
            self.coveritem.damagenode:setScaleX(-1)
        end

        self.rootNode:addChild(self.coverccb,101)
        self.coverccb:setVisible(false)

        local _shieldEffect = self.coveritem.shieldNode
        _shieldEffect:setVisible(not battleScene.isUseEffect2)
    end
end

function general.setAp(self,data)
    if data and self.ap == data.ap then return end

    local old = data and self.ap or 0
    self.ap = data and data.ap or self.ap

    if data and self.ap>old then

--        if self.ap>old then
            local index = 0
            for i=old+1,self.ap do
                local nuidx = math.mod(i,4)
                nuidx = nuidx==0 and 4 or nuidx
                local level = math.ceil(i/4)


                print(index,i,nuidx,level,"setApsetApsetApsetApsetApsetAp")
                local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(index*0.2), CCTintTo:create(0.3,self.aprgbs[level][1],self.aprgbs[level][2],self.aprgbs[level][3]))
                self.ccbDocumentControler["nu"..nuidx]:runAction(sequence)
                index = index+1
            end
--        elseif self.ap<old then
--            for i=self.ap+1,old do
--                local nuidx = math.mod(i,4)
--                nuidx = nuidx==0 and 4 or nuidx
--                local level = math.ceil(i/4)-1
--                level = level>=0 and level or level+1
--                self.ccbDocumentControler["nu"..nuidx]:setColor(ccc3(self.aprgbs[level][1],self.aprgbs[level][2],self.aprgbs[level][3]))
--            end
--        end

    else

        local level = math.ceil(self.ap/4)
        if level >= 4 then level = 4 end
        local num = math.mod(self.ap,4)
        if num==0 and self.ap > 0 then
            num = level*4
        end
        if level == 0 then level = 1 end


        for i=1,4 do
            self.ccbDocumentControler["nu"..i]:stopAllActions()
            self.ccbDocumentControler["nu"..i]:setColor(self.apcolors[i<=num and level or level-1])
        end
    end

    local  animationManager = getAnimationManager(self.ccbDocumentControler)
    animationManager:runAnimationsForSequenceNamed(self.ap>=4 and "full" or "notfull")


    if data and data.effect then
        local apEffect = self.ap > old and "once_nuqi_up" or "once_nuqi_down"
        local ccb, ccbDocumentControler = CCBReaderLoad("Effect/"..apEffect, nil, true, apEffect)
        ccb:setPosition(0,0)
        self.rootNode:addChild(ccb)
        local animationManager1 = getAnimationManager(ccbDocumentControler)
        animationManager1:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)
        animationManager1:runAnimationsForSequenceNamed(apEffect)
    end
end

function general.mobaoshaxuli(self,data,battlescene)
    local sourceccb, sourceccbitem = CCBReaderLoad(data.dir.."/"..data.name, nil, true, data.name)
    local animationManager = getAnimationManager(sourceccbitem)
    animationManager:runAnimationsForSequenceNamed(data.name)
    sourceccb:setPosition(0,0)
    self.frontNode:addChild(sourceccb)

    self.frontNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        battlescene:palyNextAction()
    end)))

end

function general.findStandStatus( self)
    if self.iscelebrate then
        return "celebrate"
    elseif self.dizzystatus then
        return "dizzy"
    elseif self.sleepstatus then
        return "sleep"
    else
        return "stand"
    end
end

function general.setColorStatus( self )
    if self.isdot then
        local green = CCTintTo:create(0,104,191,79)
        self:skeletonTintTo(green)
    elseif self.isdot2 then
        local green = CCTintTo:create(0,104,191,79)
        self:skeletonTintTo(green)
    elseif self.iscopyhades then
        -- local color1 = CCTintTo:create(1,129,56,56)
        -- local color2 = CCTintTo:create(1,98,57,129)
        local color1 = CCTintTo:create(1,205,120,209)
        local color2 = CCTintTo:create(1,209,120,120)
        local sq = CCRepeatForever:create(CCSequence:createWithTwoActions(color1,color2))
        self:skeletonTintTo(sq)
    else
        local back = CCTintTo:create(0.3,255,255,255)
        self:skeletonTintTo(back)  
    end
end

function general.roundbegin( self,round )
--    if self.data.cid == 10813 then
--        if round == 5 then
--            self:updateStatus({status = "sleep",switch = false})
--        end
--    end
end

function general.setVisible(self,bool)
    self.rootNode:setVisible(bool)
end

function general.freezeSkeleton(self)
    self.SkeletonNode:onExit()
end

function general.unfreezeSkeleton(self)
    self.SkeletonNode:onEnter()
end

function general.rootScale( self , tempscale)
    self.rootNode:setScale((tempscale or 1)*self.effectscale*self.selfscale*self.pos.s)
end

function general.reset( self,data )
    if not data then return end 

    self.ap = data.ap
    self:setAp()

    self.hp = data.hp
    self.hptotal = data.hp2
    if data.hp <=0 then
        self:death()
    else
        self.ccbDocumentControler.bloodback:stopAllActions()
        self.ccbDocumentControler.bloodfront:setScaleX(data.hp/data.hp2)
        self.ccbDocumentControler.bloodback:setScaleX(data.hp/data.hp2)        
    end

    self.cover_d = data.cover_d
    self.cover_d2 = data.cover_d2
    if data.cover_d<=0 and self.coverccb then
        self.coverccb:setVisible(false)
    end

end

function general:init(rootNode,data,direct,pos,battleScene)

    local self = {___xxx = 222 }
    setmetatable(self, general)

    self.bufferccbs = {}
    self.effectccbs = {}

    self.frontccbs = {}
    self.backccbs = {}

    self.color = {r=255, g=255, b=255 }

    self.iscelebrate = false

    self.pos = pos
    self.data = data
    self.hp = data.hp
    self.hptotal = data.hp2

    self.cover_d = data.cover_d
    self.cover_d2 = data.cover_d2

    self.ap = data.ap
    self.direct = direct
    self.battleScene = battleScene

    self.rootNode = CCNode:create()
    self.rootNode:setPosition(pos.x,pos.y+50)
    self.rootNode:setZOrder(pos.z)

    self.targetNode = CCNode:create()
    self.targetNode:setPosition(0,0)
    self.rootNode:addChild(self.targetNode)

    self.deathNode = CCNode:create()
    self.deathNode:setPosition(0,0)
    self.rootNode:addChild(self.deathNode)

    self.backNode = CCNode:create()
    self.backNode:setPosition(0,0)
    self.rootNode:addChild(self.backNode)
    
    self.bufferbackNode = CCNode:create()
    self.bufferbackNode:setPosition(0,0)
    self.rootNode:addChild(self.bufferbackNode)

    self.SkeletonNode = CCNode:create()
    self.SkeletonNode:setPosition(0,0)
    self.rootNode:addChild(self.SkeletonNode)

    if battleScene.show then
        self.skeleton = ui.itemcache:attachskeletonwithCheck(data.animation.name,self.SkeletonNode,{level=data.w_l,color = data.w_c})
    end
    self.skeleton:setPosition(0,0)
    self.skeleton:setScale(0.8)

    if self.data.a_cid and self.data.a_cid > 0 and gamedata.config.trump then
        local a_config = gamedata.config.trump[tostring(self.data.a_cid)]
        if a_config.show and a_config.show == 1 then
            local shenqiSkeletonMeta = require"SkeletonShenqi"
            self.a_skeleton = shenqiSkeletonMeta:init(a_config,self.data.a_level)
            self.a_skeleton:setPosition(0,50)
            self.a_skeleton:setScale(0.4)
            self.SkeletonNode:addChild(self.a_skeleton.root or self.a_skeleton)

            local _effect = self.a_skeleton.root or self.a_skeleton
            _effect:setVisible(not battleScene.isUseEffect)
        end
    end    

    if direct == "def" then
        self.skeleton:setScaleX(-0.8)
        if self.a_skeleton then
            self.a_skeleton:setPosition(0,50)
            self.a_skeleton:setScaleX(-1*self.a_skeleton:getScaleX())
        end
    end

    if gamedata.config.general[tostring(data.cid)].name == "主角" then
        local growconfig = gamedata.config.protagonist_grow or {}
        local protagonist = GameScene.protagonist
        local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(protagonist.level2+1)] and (math.mod(protagonist.level2,5)+1) or 5), nil, true, "jie")
        Node11:setScale(0.5)
        self.SkeletonNode:addChild(Node11)
    else
        ui.addAwakeEffect(self.SkeletonNode,data.level3,1)
    end

    self.iscopyhades = battleScene.resultType == "copyhades" and direct == "def" 
    self:setColorStatus()
    if self.iscopyhades then
        local ccb,item = CCBReaderLoad("UIEffect/diyueffect/diyueffect2", nil, true, "jie")
        ccb:setScale(0.5)
        ccb:setPosition(0,0)
        self.SkeletonNode:addChild(ccb)
    end

    self.defupNode = CCNode:create()
    self.defupNode:setPosition(0,0)
    self.rootNode:addChild(self.defupNode)

    self.closeNode = CCNode:create()
    self.closeNode:setPosition(0,0)
    self.rootNode:addChild(self.closeNode)

    self.hideNode = CCNode:create()
    self.hideNode:setPosition(0,0)
    self.rootNode:addChild(self.hideNode)

    self.dizzyNode = CCNode:create()
    self.dizzyNode:setPosition(0,0)
    self.rootNode:addChild(self.dizzyNode)

    self.dotNode = CCNode:create()
    self.dotNode:setPosition(0,0)
    self.rootNode:addChild(self.dotNode)

    self.dot2Node = CCNode:create()
    self.dot2Node:setPosition(0,0)
    self.rootNode:addChild(self.dot2Node)

    self.frozenNode = CCNode:create()
    self.frozenNode:setPosition(0,0)
    self.rootNode:addChild(self.frozenNode)

    self.invincibleNode = CCNode:create()
    self.invincibleNode:setPosition(0,0)
    self.rootNode:addChild(self.invincibleNode)

    self.invincible2Node = CCNode:create()
    self.invincible2Node:setPosition(0,0)
    self.rootNode:addChild(self.invincible2Node)

    self.firingNode = CCNode:create()
    self.firingNode:setPosition(0,0)
    self.rootNode:addChild(self.firingNode)

    self.skillproofNode = CCNode:create()
    self.skillproofNode:setPosition(0,0)
    self.rootNode:addChild(self.skillproofNode)

    self.atkproofNode = CCNode:create()
    self.atkproofNode:setPosition(0,0)
    self.rootNode:addChild(self.atkproofNode)

    self.absorbNode = CCNode:create()
    self.absorbNode:setPosition(0,0)
    self.rootNode:addChild(self.absorbNode)

    self.sneeredNode = CCNode:create()
    self.sneeredNode:setPosition(0,0)
    self.rootNode:addChild(self.sneeredNode)

    self.lockedNode = CCNode:create()
    self.lockedNode:setPosition(0,0)
    self.rootNode:addChild(self.lockedNode)

    self.rageNode = CCNode:create()
    self.rageNode:setPosition(0,0)
    self.rootNode:addChild(self.rageNode)

    self.foyinNode = CCNode:create()
    self.foyinNode:setPosition(0,0)
    self.rootNode:addChild(self.foyinNode)

    self.cibeiNode = CCNode:create()
    self.cibeiNode:setPosition(0,0)
    self.rootNode:addChild(self.cibeiNode)

    self.fangdanbeixinNode = CCNode:create()
    self.fangdanbeixinNode:setPosition(0,0)
    self.rootNode:addChild(self.fangdanbeixinNode)

    self.zhanshenxuetongNode = CCNode:create()
    self.zhanshenxuetongNode:setPosition(0,0)
    self.rootNode:addChild(self.zhanshenxuetongNode)

    self.yonghengmengyanNode = CCNode:create()
    self.yonghengmengyanNode:setPosition(0,0)
    self.rootNode:addChild(self.yonghengmengyanNode)

    self.leizhulongjiaNode = CCNode:create()
    self.leizhulongjiaNode:setPosition(0,0)
    self.rootNode:addChild(self.leizhulongjiaNode)

    self.shouhuzhilinNode = CCNode:create()
    self.shouhuzhilinNode:setPosition(0,0)
    self.rootNode:addChild(self.shouhuzhilinNode)
    
    self.mifengjishuNode = CCNode:create()
    self.mifengjishuNode:setPosition(0,0)
    self.rootNode:addChild(self.mifengjishuNode)

    self.zhanyaochumoNode = CCNode:create()
    self.zhanyaochumoNode:setPosition(0,0)
    self.rootNode:addChild(self.zhanyaochumoNode)

    self.jianzhenyinNode = CCNode:create()
    self.jianzhenyinNode:setPosition(0,0)
    self.rootNode:addChild(self.jianzhenyinNode)

    self.shouhuyinjiNode = CCNode:create()
    self.shouhuyinjiNode:setPosition(0,0)
    self.rootNode:addChild(self.shouhuyinjiNode)

    self.zuzhouNode = CCNode:create()
    self.zuzhouNode:setPosition(0,0)
    self.rootNode:addChild(self.zuzhouNode)

    self.diwanghudunNode = CCNode:create()
    self.diwanghudunNode:setPosition(0,0)
    self.rootNode:addChild(self.diwanghudunNode)

    self.wangzhibaohuNode = CCNode:create()
    self.wangzhibaohuNode:setPosition(0,0)
    self.rootNode:addChild(self.wangzhibaohuNode)

    self.yihuajiemuNode = CCNode:create()
    self.yihuajiemuNode:setPosition(0,0)
    self.rootNode:addChild(self.yihuajiemuNode)

    self.shuhanbihuNode = CCNode:create()
    self.shuhanbihuNode:setPosition(0,0)
    self.rootNode:addChild(self.shuhanbihuNode)

    self.jueqiNode = CCNode:create()
    self.jueqiNode:setPosition(0,0)
    self.rootNode:addChild(self.jueqiNode)

    self.qianlongNode = CCNode:create()
    self.qianlongNode:setPosition(0,0)
    self.rootNode:addChild(self.qianlongNode)

    self.qinglongyinjiNode = CCNode:create()
    self.qinglongyinjiNode:setPosition(0,0)
    self.rootNode:addChild(self.qinglongyinjiNode)

    self.skilllockNode = CCNode:create()
    self.skilllockNode:setPosition(0,0)
    self.rootNode:addChild(self.skilllockNode)

    self.feedNode = CCNode:create()
    self.feedNode:setPosition(0,0)
    self.rootNode:addChild(self.feedNode)

    self.shieldNode = CCNode:create()
    self.shieldNode:setPosition(0,0)
    self.rootNode:addChild(self.shieldNode)

    self.maskNode = CCNode:create()
    self.maskNode:setPosition(0,0)
    self.rootNode:addChild(self.maskNode)

    self.aimNode = CCNode:create()
    self.aimNode:setPosition(0,0)
    self.rootNode:addChild(self.aimNode)

    self.primitiveNode = CCNode:create()
    self.primitiveNode:setPosition(0,0)
    self.rootNode:addChild(self.primitiveNode)

    self.statusproofNode = CCNode:create()
    self.statusproofNode:setPosition(0,0)
    self.rootNode:addChild(self.statusproofNode)

    self.damageproofNode = CCNode:create()
    self.damageproofNode:setPosition(0,0)
    self.rootNode:addChild(self.damageproofNode)

    self.frontNode = CCNode:create()
    self.frontNode:setPosition(0,0)
    self.rootNode:addChild(self.frontNode)

    self.bufferfrontNode = CCNode:create()
    self.bufferfrontNode:setPosition(0,0)
    self.rootNode:addChild(self.bufferfrontNode)

    self.damageNode = CCNode:create()
    self.damageNode:setPosition(0,0)
    self.rootNode:addChild(self.damageNode)

    self.standinNode = CCNode:create() --替身
    self.standinNode:setPosition(0,0)
    self.rootNode:addChild(self.standinNode)

    self.effectccbs["damage_loseblood_critical"]={}
    for i=1, self.damageeffectnum.loseblood_critical do
        self:addOneDamageEffect(i,{ccb="loseblood_critical"})
    end
    self.effectccbs["damage_loseblood_normal"]={}
    for i=1, self.damageeffectnum.loseblood_normal do
        self:addOneDamageEffect(i,{ccb="loseblood_normal"})
    end
    self.effectccbs["damage_loseblood_cut"]={}
    for i=1, self.damageeffectnum.loseblood_cut do
        self:addOneDamageEffect(i,{ccb="loseblood_cut"})
    end
    self.effectccbs["damage_loseblood_sacrifice"]={}
    for i=1, self.damageeffectnum.loseblood_sacrifice do
        self:addOneDamageEffect(i,{ccb="loseblood_sacrifice"})
    end

    --
    self.effectccbs["damage_loseblood_critical_beike"]={}
    for i=1, self.damageeffectnum.loseblood_critical_beike do
        self:addOneDamageEffect(i,{ccb="loseblood_critical_beike"})
    end
    self.effectccbs["damage_loseblood_normal_beike"]={}
    for i=1, self.damageeffectnum.loseblood_normal_beike do
        self:addOneDamageEffect(i,{ccb="loseblood_normal_beike"})
    end
    self.effectccbs["damage_loseblood_cut_beike"]={}
    for i=1, self.damageeffectnum.loseblood_cut_beike do
        self:addOneDamageEffect(i,{ccb="loseblood_cut_beike"})
    end
        self.effectccbs["damage_loseblood_critical_kezhi"]={}
    for i=1, self.damageeffectnum.loseblood_critical_kezhi do
        self:addOneDamageEffect(i,{ccb="loseblood_critical_kezhi"})
    end
    self.effectccbs["damage_loseblood_normal_kezhi"]={}
    for i=1, self.damageeffectnum.loseblood_normal_kezhi do
        self:addOneDamageEffect(i,{ccb="loseblood_normal_kezhi"})
    end
    self.effectccbs["damage_loseblood_cut_kezhi"]={}
    for i=1, self.damageeffectnum.loseblood_cut_kezhi do
        self:addOneDamageEffect(i,{ccb="loseblood_cut_kezhi"})
    end
    --

    self.effectccbs.injuerd = {}
    self.effectccbs.injuerd.ccb, self.effectccbs.injuerd.item = CCBReaderLoad("Effect/injured", nil, true, "injured")
    self.effectccbs.injuerd.animationManager = getAnimationManager(self.effectccbs.injuerd.item)
    self.effectccbs.injuerd.ccb:setPosition(0,0)
    self.rootNode:addChild(self.effectccbs.injuerd.ccb)
    if self.direct == "atk" then
        self.effectccbs.injuerd.ccb:setScaleX(-1)
    end
    self.effectccbs.injuerd.ccb:setVisible(false)

    self.effectccbs.target = {}
    self.effectccbs.target.ccb, self.effectccbs.target.item = CCBReaderLoad("target/target", nil, true, "target")
    self.effectccbs.target.animationManager = getAnimationManager(self.effectccbs.target.item)
    self.effectccbs.target.ccb:setPosition(ccp(0,0))
    self.targetNode:addChild(self.effectccbs.target.ccb)
    self.effectccbs.target.ccb:setVisible(false)


    self:InitBlood()

    if self.hp <= 0  then
        self:death()
        --self.skeleton:setAnimation("death",false,0)
    else
        self.skeleton:setAnimation("stand",true,0)

        if self.a_skeleton then
            self.a_skeleton:setAnimation("chuxian",false,0)
            self.a_skeleton:addAnimation("battle",true,0,0)
        end

--        if data.cid == 10813 then
--            self:updateStatus({status = "sleep",switch = true})
--        end
    end

    --printT(self.data,"self.rootNode:setScale(1)")
    if data.cid > 30000 and data.cid < 33000 then
        if (data.animation.name == "jinyankongquelongwang") or (data.animation.name == "jinyankongquelongwang1") or (data.animation.name == "jinyankongquelongwanghong") or (data.animation.name == "jinyankongquelongwangjin") then
            self.skeleton:setScaleX(1)
        end
        self.selfscale = 1.8
    elseif data.cid > 33000 and data.cid < 100000 then
        self.selfscale = 1.6

    elseif self.data.boss then
        self.selfscale = 0.9
        local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/copyboss", nil, true, "jie")
        Node11:setScale(0.45)
        self.SkeletonNode:addChild(Node11)
    elseif self.battleScene.resultType and self.battleScene.resultType == "heroboss" and direct == "def" then
        self.selfscale = 1.5
    else
        self.selfscale = 0.76
    end

    if data.animation.name == "jingang" then
        self.rootNode:setVisible(false)
        if not battleScene.needenterMonster then
            battleScene.needenterMonster = {}
        end
        table.insert(battleScene.needenterMonster,self)
        self.selfscale = 1.2
    end

    self.effectscale = 1
    self.rootNode:setScale(self.effectscale*self.selfscale*pos.s)

    if data.cid > 30000 and data.cid < 33000 then
        self.backNode:setScale(0.76/self.selfscale)
        self.frontNode:setScale(0.76/self.selfscale)
        self.standinNode:setScale(0.76/self.selfscale)

    elseif data.cid > 33000 and data.cid < 100000 then
        self.backNode:setScale(0.76/self.selfscale)
        self.frontNode:setScale(0.76/self.selfscale)
        self.standinNode:setScale(0.76/self.selfscale)

        if data.animation.name == "rulai" then
            self.rootNode:setPosition(pos.x,pos.y+50-100)
        elseif data.animation.name == "jingang" then
            self.rootNode:setPosition(pos.x-100,pos.y+150)
        end
    end

    rootNode:addChild(self.rootNode)

    return self
end

return general ��  