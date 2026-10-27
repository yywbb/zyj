--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-7-23
-- Time: 上午11:44
-- To change this template use File | Settings | File Templates.
--

local generaMeta = require"battlegeneral"
local petMeta = require"battlemochong"
require"battleReportConvert"
require"battleCallback"
require"battleSkillModules"
require"BattleReportAbbToKey"

local battleScene = {
    maxRadio_size = gameConfig.maxRadio_size,
    slotNum = 7,
    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },
    viewSize = gameConfig.originSize,
    cellSize = {width=200, height =100 },
    firstpos = {x= 400, y=1050},

    battlePos = gameConfig.battlePos,

    slotpos = {"2","8","10","4","12","6","14",},
    scenescale = {1.4,1.15,1.1,1.1,1,1,1},
    autoscale = 1,

    atk = {
        general = {},
        posTable = {},
        SlotInfo = {},
        initSlotInfo = {},
    },
    def = {
        general = {},
        posTable = {},
        SlotInfo = {},
        initSlotInfo = {},
    },

    vs = {},

    isend = false,

    bufferDelay = 1,
    destOnlyDealy = 1,

    destskillmodules = {
        kuangfengjianjue = threeInone,
        mowangjianglin = threeInone,
        yifangfuren = threeInone,
        judanzhanche = threeInone,
        yaoniheyong = threeInone,
        mowangjianglin = threeInone,
        yuhuangjuntuan = yuhuangjuntuan,
        shenwangjuntuan = yuhuangjuntuan,
        molongtuxi = threeInoneBytype,
        dariwuzhishan = dariwuzhishan,
        mingyan = frontOrback,
        kuangmozhan = frontOrback,
        yanrenpaoxiao = threeInone,
        minixiaogangpao = threeInone,

        wanmingjianjiao = threeInone,

        buouronghe = laoshuronghedest,

        jianzairenzai = jianzairenzai,
        jiusi = jianzairenzai,

        zhangdaleyemeiyong = threeInone,
        baoyanluanwu = threeInone,

        wangzhedajun = threeInone,
        yemanpaoxiao = threeInone,
        wangtuijiangqi = wangtuijiangqi,
        longyemeiyouyong = threeInone,

        bumiemingwang = bumiemingwang,
        manshouchongzhuang = threeInone,
        mieshipaoji = threeInone,
        machegehongjineng = threeInone,
	    zhuzhenyi = zhuzhenyi,
        huanhua = huanhua,

        shenyou = shenyou,
        tuantuzaoren = tuantuzaoren,
        zhuxianjianzhen = numberOfPeople,
    },

    destbeginemodule = {
        hideSelf = hideSelf,
        hideEnemy = hideEnemy,
        hideEnemyKeepEffect = hideEnemyKeepEffect,
        freezeEnemy = freezeEnemy,
    },

    destendmodule = {
        showSelf = showSelf,
        showEnemy = showEnemy,
        showEnemyKeepEffect = showEnemyKeepEffect,
        unfreezeEnemy = unfreezeEnemy,
    },

    sourceskillmodules = {
        shenglonghuiyuezhan = jiuyanhantianwu,
        jiuyanhantianwu = jiuyanhantianwu,
        zhujue = zhujue,
        chiyanmingguang = petskill,
        jiuxiaofengming = petskill,
        qianmoshihun = petskill,
        qingguangleidian = petskill,
        ziranshouhu = petskill,
        menghupaoxiao = petskill,
        tunshi = petskill,
        nenglianghongji2 = petskill,
        lvbubeidong = nothing,
        mingyan = sourcewithblood,

        daribeizhou = has01skill,
        darijinzhongzhao = has01skill,
        darirulaishenzhang = has01skill,
        dariwuzhishan = has01skill,
        yuhuochongsheng = yuhuochongsheng,
        shoushenjianmeicao = jiuyanhantianwu,

        xuyuanfuhuo = feilongzaisheng,
        buouronghe = laoshuronghesource,
        tongguiyujin = zibao,
        baibai = baibai,
        qixingdenghuo = qixingdenghuo,
        fuchoudaji = fuchoudaji,
        xiandaochongsheng = xiandaochongsheng,
        bujishenming = bujishenming,

        baguashengsi = baguashengsi,
    },

    show = false,

    speedconfig = {1.5,2,2.5 },

    --speedconfig = {0.6,1.7,2 },
    speedstep = 1,

    texie_skeleton = nil,

    isGMSpeedMove = false,
    touchButton = nil,
    gmSpeedccb = nil,
    gmSpeeditem = nil,
}

function battleScene.makePos(self)

    if next(self.atk.posTable) and next(self.def.posTable) then return end

    for pos =1, self.slotNum*2 do
        self.atk.posTable[pos]={
--            x = pos<=self.slotNum and self.firstpos.x*0.95^(pos-1) or (self.firstpos.x - self.cellSize.width)*0.90^(pos-8),
--            y = self.firstpos.y-self.cellSize.height*(pos-(pos<=self.slotNum and 1 or self.slotNum+1))*1.06^(pos-(pos<=self.slotNum and 1 or self.slotNum+1)),
--            s = 1.1^(pos-(pos<=self.slotNum and 1 or self.slotNum+1)),

            x = self.battlePos[pos].x,
            y = self.battlePos[pos].y,
            s = self.battlePos[pos].s,


            z = (pos<=self.slotNum and pos or pos-self.slotNum)*100,
            o = pos,

        }
        self.def.posTable[pos]={
            x = self.viewSize.width - self.atk.posTable[pos].x,
            y = self.atk.posTable[pos].y,
            z = self.atk.posTable[pos].z,
            s = self.atk.posTable[pos].s,
            o = pos,
        }
    end
end

function battleScene.skillScale(self,postype,pos,scale)
    if self.speedstep ~= 3 then
        local location = self[postype].posTable[tonumber(pos)]

        self.autoscale = self.autoscale or 1

        self.bgitem.autoscalenode:setAnchorPoint(ccp(location.x/1080,location.y/1920))
        self.bgitem.autoscalenode:setPosition(ccp(540+(location.x-540)*self.autoscale,960+(location.y-960)*self.autoscale))

        local scaleTo = CCScaleTo:create(0.3, scale*self.autoscale)
        local backOut = CCEaseOut:create(scaleTo,2)
        self.bgitem.autoscalenode:runAction(backOut)

        self.skillScaleActive = true
    end

end

function battleScene.skillScaleBack(self)

    if self.skillScaleActive or self.speedstep ~= 3 then
        local scaleTo = CCScaleTo:create(0.3, self.autoscale or 1)
        local backOut = CCEaseOut:create(scaleTo,2)

        self.bgitem.autoscalenode:runAction(CCSequence:createWithTwoActions(backOut,CCCallFunc:create(function()
    --        self.bgitem.autoscalenode:setAnchorPoint(ccp(0.5,0))
    --        self.bgitem.autoscalenode:setPosition(ccp(540,0))
        end)))
        self.skillScaleActive = false
    end

end

function battleScene.addSource(self,pos)
    if not self.source then
        self.source = {}
        self.source.ccb, self.source.item = CCBReaderLoad("target/jiaoxia", nil, true, "jiaoxia")
        self.source.animationManager = getAnimationManager(self.source.item)
        self.source.ccb:setPosition(ccp(0,0))
        self.rootNode:addChild(self.source.ccb)
    end
    self.source.ccb:setVisible(true)
    self.source.ccb:setPosition(pos.x,pos.y)
    self.source.animationManager:runAnimationsForSequenceNamed("jiaoxia")
end

function battleScene.hideSource(self)
    if self.source then
        self.source.ccb:setVisible(false)
    end
end

function battleScene.palybattleAction(self)
    if self.tempSkillanimation == nil then
        self.tempSkillanimation = {}
        for k,v in pairs(gamedata.config.skillanimation) do
            self.tempSkillanimation[v.name] = k
        end
    end

    local action = self.animation[self.actionStep]

    local haspre = false
    for k,v in ipairs(action.sourceAnimation) do
        if (action.type2 == "skill" or action.type2 == "comb") and v.pos ~= "0" and self[v.postype].general[v.pos].data.cid <30000 then
            self[v.postype].general[v.pos]:skillpreEffect(action.screenAnimation.common)
            haspre = true
        end
    end

    local prefunction = function()
        local xianshuName = {"leishenzhiwei", "huimieshenfu", "zhuxiejianzhen", "leishenzhichui", "zhiyuhaojiao", "fusujiezhi", "qiangzhezhili", "zonghengzhishu", "dandandashi", "chongyinghaojiao"}
        for k,v in ipairs(action.sourceAnimation) do
            if action.type2 == "normal" then
                self[v.postype].general[v.pos]:attack(v.animation,action.screenAnimation.actiontime)
                self:addSource(self[v.postype].posTable[tonumber(v.pos)])
            elseif action.type2 == "skill" then
                self[v.postype].general[v.pos]:skillattack(v.animation,action.screenAnimation.actiontime)
            elseif action.type2 == "comb" then
                self[v.postype].general[v.pos]:combskillattack(v.animation,action.screenAnimation.actiontime)
            elseif action.type2 == "break" then
                local index = 0
                for i=1, #xianshuName do
                    if v.animation and v.animation.ccb and v.animation.ccb.skillname == xianshuName[i] then
                        index = i
                        break
                    end
                end
                if index > 0 then
                    local ccb, ccbDocumentControler = CCBReaderLoad("skillrelease/skill_xianshu", nil, true, "skill_xianshu")
                    local _skillName = xianshuName[index]
    
                    setSpriteFrameByName(ccbDocumentControler.skillname1, _skillName,"public/skillname_new")
                    setSpriteFrameByName(ccbDocumentControler.skillname2, _skillName,"public/skillname_new")
                    
                    ccb:setAnchorPoint(ccp(0.5,0))
                    ccb:setPosition(ccp(0,(self.topposY-1920)/2))
                    self.bgitem.commonnode:addChild(ccb,1999)
    
                    local animationManager = getAnimationManager(ccbDocumentControler)
                    animationManager:setAnimationCompletedCallback(function()
                        ccb:removeFromParentAndCleanup(true)
                    end)
                    animationManager:runAnimationsForSequenceNamed("skill_xianshu")
                else
                    self[v.postype].general[v.pos]:breakskillattack(v.animation,action.screenAnimation.actiontime)
                end
            end
        end

        if action.type2 == "skill" or action.type2 == "comb" or action.type2 == "break" then
            gamedata.music:PlaySound(action.screenAnimation.audio)

            for k,v in ipairs(action.destAnimation) do
                if v.animation.damage and next(v.animation.damage) and self[v.postype].general[v.pos] then
                    self[v.postype].general[v.pos]:addTarget()
                end
            end
        end

        if next(action.sourceccbmodule) then
            if self.sourceskillmodules[action.sourceccbmodule.name] then
                self.sourceskillmodules[action.sourceccbmodule.name](self,action)
            end
        end


        if action.screenAnimation.common then
            local common =  action.screenAnimation.common
            if not self.skillblack then
                self.skillblack = CCLayerColor:create(ccc4(0,0,0,130))
                self.skillblack:setContentSize(CCSizeMake(1080,2160))
                self.skillblack:setAnchorPoint(ccp(0,0))
                self.skillblack:setPosition(ccp(0,0))
                self.rootNode:addChild(self.skillblack)
                self.skillblack:setZOrder(1999)
            else
                self.skillblack:setVisible(true)
            end

            if common.skilltype == "normal" then
                self:skillScale(common.direct and "atk" or "def", common.pos[1], 1.3)
            else
                self:skillScale(common.direct and "atk" or "def", 11,1.15)
            end

            if common.skilltype == "comb" then
                local ccb, ccbDocumentControler = CCBReaderLoad("skillrelease/skill_combskill", nil, true, "skill_combskill")
                local _skillName = common.skillname

                if self.isUseEffect3 then
                    local _animationId1 = self.tempSkillanimation[_skillName]
                    
                    if _animationId1 ~= nil then
                        local _animationId2 = gamedata.config.skillanimation[tostring(_animationId1)].name2

                        if _animationId2 > 0 then
                            _skillName = gamedata.config.skillanimation[tostring(_animationId2)].name
                        end
                    end
                end

                setSpriteFrameByName(ccbDocumentControler.skillname1, _skillName,"public/skillname_new")
                setSpriteFrameByName(ccbDocumentControler.skillname2, _skillName,"public/skillname_new")
                if not common.direct then
                    ccb:setScaleX(-1)
                    ccbDocumentControler.skillname1:setFlipX(true)
                    ccbDocumentControler.skillname2:setFlipX(true)
                end
                ccb:setAnchorPoint(ccp(0.5,0))
                ccb:setPosition(ccp(0,(self.topposY-1920)/2))
                self.bgitem.commonnode:addChild(ccb,1999)

                local animationManager = getAnimationManager(ccbDocumentControler)
                animationManager:setAnimationCompletedCallback(function()
                    ccb:removeFromParentAndCleanup(true)
                end)
                animationManager:runAnimationsForSequenceNamed("common_combskill")
            end

        end

        local delayfunction = function()
            if self.skillblack then
                self.skillblack:setVisible(false)
            end
            self:skillScaleBack()

            if self.rootNode then
                if (action.screenAnimation and action.screenAnimation.skill2 and action.screenAnimation.skill2.spine) then
                    local tmpScale = action.screenAnimation.skill2.fixscale or 1
                    self.rootNode:setScale(tmpScale)
                    if action.screenAnimation.skill2.fixpos then
                        local tx = 1080*(0.5-tmpScale*(action.screenAnimation.common.direct and 0.75 or 0.25))
                        local ty = 1920*(1-tmpScale)*0.5
                        self.rootNode:setPosition(tx,ty)
                    else
                        local tx = 1080*(1-tmpScale)*0.5
                        local ty = 1920*(1-tmpScale)*0.5
                        self.rootNode:setPosition(tx,ty)   
                    end
                    --
                    local texie = action.screenAnimation.skill2.spine
                    self.texie_skeleton = CCSkeletonAnimation:create(texie.."/"..texie..".json",texie.."/"..texie..".atlas",1)
                    self.texie_skeleton:setScale(1)
                    self.texie_skeleton:setScaleX(action.screenAnimation.common.direct and 1 or -1)
                    self.bgitem.commonnode:addChild(self.texie_skeleton)
                    self.texie_skeleton:setAnimation("skill2",false,0)
                    --
                    if action.screenAnimation.skill2.fixtime and action.screenAnimation.skill2.fixtime > 0 then
                        self.bgitem.commonnode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.skill2.fixtime),CCCallFunc:create(function()
                            if self.rootNode then
                                self.rootNode:setScale(1)
                                self.rootNode:setPosition(0,0)
                            end
                        end)))
                    end
                end
            end

            for k,v in ipairs(action.destAnimation) do

                --            if v.animation.status and next(v.animation.status) then
                --                self[v.postype].general[v.pos]:updateStatus(v.animation.status,v.animation.status.switch and (v.animation.damage[#v.animation.damage].damagedelay or 0) or action.screenAnimation.actiontime-action.screenAnimation.destdelay)
                --            end
                if v.animation.ccb and self[v.postype].general[v.pos] then
                    self[v.postype].general[v.pos]:ccbeffect(v.animation.ccb,"def",action.screenAnimation.actiontime-action.screenAnimation.destdelay)
                end

                if v.animation.damage and next(v.animation.damage) and self[v.postype].general[v.pos] then
                    self[v.postype].general[v.pos]:injured(v.animation,action.screenAnimation.actiontime-action.screenAnimation.destdelay)
                end
            end
            if action.screenAnimation.effect then
                local effect = action.screenAnimation.effect
                local _skillName = effect.skillname
                
                local _animationId2 = 0

                if self.isUseEffect3 then
                    local _animationId1 = self.tempSkillanimation[_skillName]

                    if _animationId1 ~= nil then
                        _animationId2 = gamedata.config.skillanimation[tostring(_animationId1)].name2

                        if _animationId2 > 0 then
                            _skillName = "tongyongjineng_screen"
                        end
                    end
                end

                local ccb, ccbDocumentControler

                if self.isUseEffect3 then
                    if _animationId2 > 0 then
                        ccb, ccbDocumentControler = CCBReaderLoad(_skillName.."/".._skillName.."02", nil, true, _skillName.."02")
                    else
                        ccb, ccbDocumentControler = CCBReaderLoad(_skillName.."/".._skillName.."_screen", nil, true, _skillName.."02")
                    end
                else
                    ccb, ccbDocumentControler = CCBReaderLoad(_skillName.."/".._skillName.."_screen", nil, true, _skillName.."02")
                end

                local animationManager1 = getAnimationManager(ccbDocumentControler)
                animationManager1:setAnimationCompletedCallback(function()
                    ccb:removeFromParentAndCleanup(true)
                    self.bgitem.fronteffect:removeAllChildrenWithCleanup(true)
                    self.bgitem.backeffect:removeAllChildrenWithCleanup(true)
                end)
                print("runAnimationsForSequenceNamed",_skillName.."_screen")
                if self.isUseEffect3 then
                    if _animationId2 > 0 then
                        animationManager1:runAnimationsForSequenceNamed(_skillName.."02")
                    else
                        animationManager1:runAnimationsForSequenceNamed(_skillName.."_screen")
                    end
                else
                    animationManager1:runAnimationsForSequenceNamed(_skillName.."_screen")
                end

                if not effect.direct then
                    local i = 1
                    while ccbDocumentControler["00"..i] do
                        ccbDocumentControler["00"..i]:setFlipX(true)
                        i=i+1
                    end
                    i = 1
                    while ccbDocumentControler["000"..i] do
                        ccbDocumentControler["000"..i]:setScaleX(ccbDocumentControler["000"..i]:getScaleX()*(-1))
                        i=i+1
                    end
                end

                if ccbDocumentControler.topnode or ccbDocumentControler.bottomnode then
                    if ccbDocumentControler.topnode then
                        ccbDocumentControler.topnode:removeFromParentAndCleanup(false)
                        self.bgitem.fronteffect:addChild(ccbDocumentControler.topnode)
                        ccbDocumentControler.topnode:setPosition(ccp(0,0))
                        if ccbDocumentControler.topadapt then
                            ccbDocumentControler.topadapt:setPositionY(ccbDocumentControler.topadapt:getPositionY()-1920+GameScene.topposY)
                        end
                        if not effect.direct then ccbDocumentControler.topnode:setScaleX(-1) end
                    end
                    if ccbDocumentControler.bottomnode then
                        ccbDocumentControler.bottomnode:removeFromParentAndCleanup(false)
                        self.bgitem.backeffect:addChild(ccbDocumentControler.bottomnode)
                        ccbDocumentControler.bottomnode:setPosition(ccp(0,0))
                        if ccbDocumentControler.bottomadapt then
                            ccbDocumentControler.bottomadapt:setPositionY(ccbDocumentControler.topadapt:getPositionY()-1920+GameScene.topposY)
                        end
                        if not effect.direct then ccbDocumentControler.bottomnode:setScaleX(-1) end
                    end
                    self.bgitem.fronteffect:addChild(ccb) --处理音乐无效
                else
                    ccb:setPosition(ccp(0,0))
                    self.bgitem.fronteffect:addChild(ccb)
                    if not effect.direct then ccb:setScaleX(-1) end
                end
            end

            --        if action.type2== "skill" or action.type2== "comb" or action.type2== "break" then
            --            if action.destAnimation[1].animation.damage[1].damage>0 then
            --                self:addDamageTotal(action.destAnimation[1].postype)
            --            end
            --        end

            if next(action.destccbmodule) then
                print("skill-name",action.destccbmodule.name)
                self.destskillmodules[action.destccbmodule.name](self,action)
            end
            
            if action.destbeginemodule then
                if self.destbeginemodule[action.destbeginemodule.name] then
                    if action.destbeginemodule.params and action.destbeginemodule.params[2] then
                        if action.destbeginemodule.name == "hideEnemy" or action.destbeginemodule.name == "hideEnemyKeepEffect" then
                            local _sequence = CCSequence:createWithTwoActions(CCDelayTime:create(tonumber(action.destbeginemodule.params[2])), CCCallFunc:create(function() 
                                 self.destbeginemodule[action.destbeginemodule.name](self, action)
                            end))
                            self.animationNode:runAction(_sequence)
                        end
                    else
                        self.destbeginemodule[action.destbeginemodule.name](self, action)
                    end
                end
            end

            if action.screenAnimation.shake then
                for k,v in ipairs(action.screenAnimation.shake) do
                    self.shakeanimationNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(v.delay),CCCallFunc:create(function()
                        self:shake(v.name)
                    end)))
                end
            end

        end

        local delayfunction3 = function()
--            if next(action.aps_effect) then
--                for k,v in ipairs(action.aps_effect) do
--                    self[v.postype].general[v.pos]:setAp(v)
--                end
--
--                local sequence4 = CCSequence:createWithTwoActions(CCDelayTime:create(self.bufferDelay), CCCallFunc:create(function() self:palyNextAction() end))
--                self.animationNode:runAction(sequence4)
--            else
--                self:palyNextAction()
--            end

            local hasapeffect = false
            for k,v in ipairs(action.aps) do
                self[v.postype].general[v.pos]:setAp(v)
                if v.effect then
                    hasapeffect = true
                end
            end

            if hasapeffect then
                local sequence4 = CCSequence:createWithTwoActions(CCDelayTime:create(self.bufferDelay), CCCallFunc:create(function() self:palyNextAction() end))
                self.animationNode:runAction(sequence4)
            else
                self:palyNextAction()
            end


        --        for k,v in ipairs(action.destAnimation) do
        --            if self[v.postype].general[v.pos] then
        --                self[v.postype].general[v.pos]:removeTarget()
        --            end
        --        end
        end

        local delayfunction2 = function()
            if next(action.buffers) then
                local step = 1
                local function bufferstep()
                    
                    if action.buffers[step] then
                        local bufferstatus = false
                        for k,v in ipairs(action.buffers[step]) do
                            self[v.postype].general[v.pos]:buffer(v.buffer)
                            if v.buffer.switch == true then
                                bufferstatus = true
                            end
                        end

                        local sequence3 = CCSequence:createWithTwoActions(CCDelayTime:create(bufferstatus and self.bufferDelay or 0), CCCallFunc:create(function() bufferstep() end))
                        self.animationNode:runAction(sequence3)                        
                    else
                        delayfunction3()
                    end
                    step = step + 1
                end
                bufferstep()
            else
                delayfunction3()
            end
        end

        if action.destendmodule then
            if self.destendmodule[action.destendmodule.name] then
                if action.destendmodule.params and action.destendmodule.params[2] then
                    if action.destendmodule.name == "showEnemy" or action.destendmodule.name == "showEnemyKeepEffect" then
                        local _sequence = CCSequence:createWithTwoActions(CCDelayTime:create(tonumber(action.destendmodule.params[2])), CCCallFunc:create(function() 
                            self.destendmodule[action.destendmodule.name](self,action)
                        end))
                        self.animationNode:runAction(_sequence)
                    end
                else
                    self.destendmodule[action.destendmodule.name](self,action)
                end
            end
        end

        local delayfunction1 = function()
            if self.bgitem.commonnode then
                self.bgitem.commonnode:stopAllActions()
            end
            if self.rootNode then
                self.rootNode:setScale(1)
                self.rootNode:setPosition(0,0)
            end
            if self.texie_skeleton then
                self.texie_skeleton:removeFromParentAndCleanup(true)
                self.texie_skeleton = nil
            end

            if action.destendmodule then
                print(action.destendmodule.name)
                if self.destendmodule[action.destendmodule.name] then
                    if not (action.destendmodule.params and action.destendmodule.params[2]) then
                        self.destendmodule[action.destendmodule.name](self,action)
                    end
                end
            end

            local hasstatus = false
            for k,v in ipairs(action.destAnimation) do

                if v.animation.status and next(v.animation.status) and self[v.postype].general[v.pos] and (not self[v.postype].general[v.pos].isdead or generaMeta.deadStatus[v.animation.status.status]) then
                    self[v.postype].general[v.pos]:updateStatus(v.animation.status)
                    hasstatus = true
                end
            end
            if hasstatus then
                local sequence2 = CCSequence:createWithTwoActions(CCDelayTime:create(self.bufferDelay), CCCallFunc:create(function() delayfunction2() end))
                self.animationNode:runAction(sequence2)
            else
                delayfunction2()
            end

            self.bgitem.fronteffect:removeAllChildrenWithCleanup(true)
            self.bgitem.backeffect:removeAllChildrenWithCleanup(true)
        end

        --printT(screenAnimation)
        local sequence1 = CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.destdelay), CCCallFunc:create(delayfunction))
        local sequence2 = CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.actiontime), CCCallFunc:create(delayfunction1))
        local spawn = CCSpawn:createWithTwoActions(sequence1,sequence2)
        self.animationNode:runAction(spawn)

    end

    if haspre then
        local sequencepre = CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function() prefunction() end))
        self.animationNode:runAction(sequencepre)
    else
        prefunction()
    end

end

function battleScene.palyTalkAction(self)
    local action = self.animation[self.actionStep]
    guide:playTalk(action,function()
        self:palyNextAction()
    end,
        (not self.animation[self.actionStep+1] or self.animation[self.actionStep+1].type ~= "talk") )
end

function battleScene.palyPosAction(self)
    local action = self.animation[self.actionStep]

    local needpetenter = nil

    for k,v in ipairs(action.changes) do
        if v.opt == "disappear" then
            if tostring(v.pos) == "0" then
                self.bgcontrolitem["pet"..v.direct]:removeAllChildrenWithCleanup(true)
                self[v.direct].general[tostring(v.pos)] = nil
            else
                local position = self[v.direct].posTable[tonumber(v.pos)]
                local effectccb, effectitem = CCBReaderLoad("appear/disappear", nil, true, "disappear")
                effectccb:setPosition(position.x,position.y+50)
                self.rootNode:addChild(effectccb,position.z+1)

                local animationManager = getAnimationManager(effectitem)
                animationManager:setAnimationCompletedCallback(function()
                    effectccb:removeFromParentAndCleanup(true)
                end)
                animationManager:runAnimationsForSequenceNamed("disappear")

                if not self[v.direct].general[tostring(v.pos)] then
                    print("no general here:",v.direct,v.pos)
                else
                    self[v.direct.."hp"] = self[v.direct.."hp"] - self[v.direct].general[tostring(v.pos)].hp
                    self[v.direct.."hptotal"] = self[v.direct.."hptotal"] - self[v.direct].general[tostring(v.pos)].hptotal
                    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.4), CCCallFunc:create(function()
                        ui.itemcache:detachskeleton(self[v.direct].general[tostring(v.pos)].data.animation.name,self[v.direct].general[tostring(v.pos)].skeleton)
                        self[v.direct].general[tostring(v.pos)].rootNode:removeFromParentAndCleanup(true)
                        self[v.direct].general[tostring(v.pos)] = nil
                        if self[v.direct.."hptotal"] <=0 then
                            self[v.direct.."bloodbar"]:setPercentage(0)
                        else
                            self[v.direct.."bloodbar"]:setPercentage(100*self[v.direct.."hp"]/self[v.direct.."hptotal"])
                        end
                        self:setBloodstar(v.direct)
                    end))
                    self[v.direct].general[tostring(v.pos)].rootNode:stopAllActions()
                    self[v.direct].general[tostring(v.pos)].rootNode:runAction(sequence)
                end
            end
        elseif v.opt == "appear" then
            if tostring(v.pos) == "0" then
                if self[v.direct].general[tostring(v.pos)] then
                    self[v.direct].general[tostring(v.pos)]:change(v.general)
                else
                    self[v.direct].general[tostring(v.pos)] = petMeta:init(self.bgcontrolitem["pet"..v.direct],v.general,v.direct,self)
                    needpetenter = self[v.direct].general[tostring(v.pos)]
                end
            else
                local position = self[v.direct].posTable[tonumber(v.pos)]
                local effectccb, effectitem = CCBReaderLoad("appear/appear", nil, true, "appear")
                effectccb:setPosition(position.x,position.y+50)
                self.rootNode:addChild(effectccb,position.z+1)

                local animationManager = getAnimationManager(effectitem)
                animationManager:setAnimationCompletedCallback(function()
                    effectccb:removeFromParentAndCleanup(true)
                end)
                animationManager:runAnimationsForSequenceNamed("appear")

                if self[v.direct].general[tostring(v.pos)] then
                    print("already general here:",v.direct,v.pos)
                    self[v.direct.."hp"] = self[v.direct.."hp"] - self[v.direct].general[tostring(v.pos)].hp
                    self[v.direct.."hptotal"] = self[v.direct.."hptotal"] - self[v.direct].general[tostring(v.pos)].hptotal

                    ui.itemcache:detachskeleton(self[v.direct].general[tostring(v.pos)].data.animation.name)
                    self[v.direct].general[tostring(v.pos)].rootNode:removeFromParentAndCleanup(true)
                    self[v.direct].general[tostring(v.pos)] = nil
                    self[v.direct.."bloodbar"]:setPercentage(100*self[v.direct.."hp"]/self[v.direct.."hptotal"])
                    self:setBloodstar(v.direct)
                end
                local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
                    self[v.direct].general[tostring(v.pos)]=  generaMeta.init(self,self.rootNode,v.general,v.direct,position,self)
                    self[v.direct].general[tostring(v.pos)].ccb:setVisible(true)
                    if self[v.direct].general[tostring(v.pos)].coverccb then
                        self[v.direct].general[tostring(v.pos)].coverccb:setVisible(true)
                    end
                    self[v.direct.."hp"] = self[v.direct.."hp"] + self[v.direct].general[tostring(v.pos)].hp
                    self[v.direct.."hptotal"] = self[v.direct.."hptotal"] + self[v.direct].general[tostring(v.pos)].hptotal

                    self[v.direct.."bloodbar"]:setPercentage(100*self[v.direct.."hp"]/self[v.direct.."hptotal"])
                    self:setBloodstar(v.direct)
                end))
                --self.rootNode:stopAllActions()
                self.rootNode:runAction(sequence)
            end
        end
    end

    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5), CCCallFunc:create(function()
        if needpetenter then
            needpetenter:enter(function()
                self:palyNextAction()
            end)
        else
            self:palyNextAction()
        end
    end)))

    self:autoScale()
end

function battleScene.shake(self,shakename)
    print("battleScene shake",shakename)
   -- if not self.shaking then
   -- self.bganimationManager = getAnimationManager(self.bgitem)
   --     self.bganimationManager:setAnimationCompletedCallback(function()
    --        self.shaking = false
   --     end)
    self.bganimationManager:runAnimationsForSequenceNamed(shakename)
   -- end

end

function battleScene.celebrate(self)
    if self.result then
        gamedata.music:BattleSuccess(self.star)
        for k,v in pairs(self["atk"].general) do
            v:celebrate()
        end
    else
        gamedata.music:BattleFail()
        for k,v in pairs(self["def"].general) do
            v:celebrate()
        end
    end
end

function battleScene.initresultnode(self)
    if self.resultproflayer then
    else
        self.resultproflayer = self:createResultprofLayer(self.rootLayer, gameConfig.touchPriority.battleScene - 10)
        -- self.resultproflayer = ui.addProflayer(self.rootLayer, gameConfig.touchPriority.battleScene - 10, 1, ccc4(0,0,0,100), nil, nil, nil, nil, "battleresult prof")
    end

    if self.resultNode then
        self.resultNode:removeFromParentAndCleanup(true)
        self.resultNode = nil
    end
end

function battleScene.createResultprofLayer(self, parent, touchPriority)
    local Proflayer = CCLayerColor:create(ccc4(0,0,0,100))
    Proflayer:setContentSize(CCSizeMake(self.d_viewSize.width, self.d_viewSize.height))
    Proflayer:setAnchorPoint(ccp(0,0))
    Proflayer:setPosition(ccp(0,0))
    parent:addChild(Proflayer, 1)

    local function ccTouchBegan(x, y) 
        self.isGMSpeedMove = false
        if self.gmSpeeditem and ui.isTouched(self.gmSpeeditem.gmspnode,x,y) then
            self.touchButton = {touchX = x, touchY = y, bX = self.gmSpeeditem.gmspnode:getPositionX(), bY = self.gmSpeeditem.gmspnode:getPositionY()}
            printT(self.touchButton,"jkp-touchButton")
        end
        return true 
    end

    local function ccTouchMoved(x, y)
        if self.touchButton then
            if x <= 0 then
                x = 0
            elseif x >= self.d_viewSize.width then
                x = self.d_viewSize.width
            end

            if y <= 0 then
                y = 0
            elseif y >= self.d_viewSize.height then
                y = self.d_viewSize.height
            end

            if math.abs(x-self.touchButton.touchX) > 10 or math.abs(y-self.touchButton.touchY) > 10 then
                self.isGMSpeedMove = true
            end
            
            local btnRadius = (self.gmSpeeditem.gmspnode:getContentSize().width/2)*self.scaleNum
            local btnX = self.gmSpeeditem.gmspnode:getPositionX()*self.scaleNum
            local btnY = self.gmSpeeditem.gmspnode:getPositionY()*self.scaleNum
            print("btnRadius = ",btnRadius)
            print("btnX = ",btnX)
            print("width = ",self.d_viewSize.width-btnRadius)
            print("btnY = ",btnY)
            print("height = ",self.d_viewSize.height-btnRadius)
            self.gmSpeeditem.gmspnode:setPosition(ccp(self.touchButton.bX + (x/self.scaleNum - self.touchButton.bX), self.touchButton.bY + (y/self.scaleNum - self.touchButton.bY)))
        end
    end

    local function ccTouchEnded(x, y)
        if self.touchButton then
            local btnRadius = (self.gmSpeeditem.gmspnode:getContentSize().width/2)*self.scaleNum
            local btnX = self.gmSpeeditem.gmspnode:getPositionX()*self.scaleNum
            local btnY = self.gmSpeeditem.gmspnode:getPositionY()*self.scaleNum
            
            if btnX >= btnRadius and btnX <= (self.d_viewSize.width-btnRadius) then
                self.gmSpeeditem.gmspnode:setPositionX(self.touchButton.bX + (x/self.scaleNum - self.touchButton.bX))
            elseif btnX < btnRadius then
                self.gmSpeeditem.gmspnode:setPositionX(btnRadius/self.scaleNum)
            else
                self.gmSpeeditem.gmspnode:setPositionX((self.d_viewSize.width/self.scaleNum - btnRadius/self.scaleNum))
            end

            if btnY >= btnRadius and btnY <= (self.d_viewSize.height-btnRadius) then
                self.gmSpeeditem.gmspnode:setPositionY(self.touchButton.bY + (y/self.scaleNum - self.touchButton.bY))
            elseif btnY < btnRadius then
                self.gmSpeeditem.gmspnode:setPositionY(btnRadius/self.scaleNum)
            else
                self.gmSpeeditem.gmspnode:setPositionY((self.d_viewSize.height/self.scaleNum - btnRadius/self.scaleNum))
            end
            
            self.touchButton = nil
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

    Proflayer:registerScriptTouchHandler(onTouch, false, touchPriority , true)
    Proflayer:setTouchPriority(touchPriority)
    Proflayer:setTouchEnabled(true)
    return Proflayer
end

function battleScene.showbattleResult(self, isShow)
    
    self:initresultnode()
    print("战斗结果 = ", self.result)
    if self.result then
        if self.resultType and self.resultType == "kingBattle" then
            self.resultNode,self.resultItem = CCBReaderLoad("wangzhezhizhan/battle_win", nil, true, "battle_win")
            if self.resultItem.scoreLab then
                self.resultItem.scoreLab:setString("+"..self.kingScore)
            end
            if self.resultItem.pointscoreLab then
                self.resultItem.pointscoreLab:setString(self.kingPointScore)
            end
            if self.resultItem.currentScoreLab then
                self.resultItem.currentScoreLab:setString(self.kingcurrentScore)
            end
            if self.resultItem.segmentLab then
                self.resultItem.segmentLab:setString(self.nextKingSegment)
            end
        elseif self.resultType and self.resultType == "babelTower" then
            
            self.resultNode,self.resultItem = CCBReaderLoad("tongtianta/tongtianta_shengli", nil, true, "tongtianta_shengli")
            self:setBabelTowerWin(self.resultItem,self.babelTowerLevelInfo)
        else
            self.resultNode,self.resultItem = CCBReaderLoad("backGround/shengli", nil, true, "shengli")
            for i=1, 3 do
                if i <= self.star then
                    self.resultItem["star"..i]:setVisible(true)
                else
                    self.resultItem["star"..i]:setVisible(false)
                end
            end
            local animationManager = getAnimationManager(self.resultItem)
            animationManager:runAnimationsForSequenceNamed("shengli_success_"..(self.star or 0))
        end

    else
        if self.resultType and self.resultType == "kingBattle" then
            self.resultNode,self.resultItem = CCBReaderLoad("wangzhezhizhan/battle_lose", nil, true, "battle_lose")

            if self.resultItem.scoreLab then
                self.resultItem.scoreLab:setString(self.kingScore)
            end
            if self.resultItem.pointscoreLab then
                self.resultItem.pointscoreLab:setString(self.kingPointScore)
            end
            if self.resultItem.currentScoreLab then
                self.resultItem.currentScoreLab:setString(self.kingcurrentScore)
            end
            if self.resultItem.segmentLab then
                self.resultItem.segmentLab:setString(self.nextKingSegment)
            end
        -- elseif self.resultType and self.resultType == "babelTower" then
        --     self.resultNode,self.resultItem = CCBReaderLoad("backGround/shibai", nil, true, "shibai")
        --     -- local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(3), CCCallFunc:create(function() self:clear() end))
        --     -- self.animationNode:runAction(sequence)
        else
            self.resultNode,self.resultItem = CCBReaderLoad("backGround/shibai", nil, true, "shibai")
        end
    end
    self.resultNode:setScale(self.d_viewSize.width/self.viewSize.width)
    self.resultNode:setAnchorPoint(ccp(0.5,0.5))
    self.resultNode:setPosition(ccp(self.d_viewSize.width/2, self.d_viewSize.height/2))
    self.rootLayer:addChild(self.resultNode,1)

    ui.setLabelString(self.resultItem.replaytext,gameConfig.strings:string_common("battleScene",2),18)
    ui.setLabelString(self.resultItem.quittext,gameConfig.strings:string_common("battleScene",3),18)

    if self.resultType == "friendcopy" or self.resultType == "wudaohui" or self.resultType == "godCompetitionBattle" then
        self.resultItem.battleRoleInjuryBtn:setVisible(false)
    else
        self.resultItem.battleRoleInjuryBtn:setVisible(true)
    end

    if self.resultType == "penglai" then
        self.resultItem.battleReportNode:setVisible(false)
    end

    if self.resultType == "penglai" or self.resultType == "wudaohui" then
        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(5), CCCallFunc:create(function() self:clear() end))
        self.animationNode:runAction(sequence)
    end    
    
    self.resultItem.battleRoleInjuryBtn:addHandleOfControlEvent(function()
        self:battleRoleInjury()
    end,CCControlEventTouchUpInside)
    self.resultItem.battleRoleInjuryBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultItem.replay:addHandleOfControlEvent(function()
        self:replay()
    end,CCControlEventTouchUpInside)
    self.resultItem.replay:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultItem.quit:addHandleOfControlEvent(function()
        self:clear()
    end,CCControlEventTouchUpInside)
    self.resultItem.quit:setTouchPriority(gameConfig.touchPriority.battleScene - 11)
end

function battleScene.setBabelTowerWin(self,items,data)

    local conditionConfig = gamedata.config.tongtianta_tongguantiaojian
    local levelConfig = gamedata.config.tongtianta_guaiwu[tostring(data.mapId)][tostring(data.level)]


    local passData = {}
    local passNum = 0
    for i=1,3 do
        if data["passStatus"..i] and data["passStatus"..i] == 1 then
            passNum = passNum + 1
        end
        table.insert(passData,{index = i,passStatus = data["passStatus"..i] or 0})
    end
    passNum = math.max(passNum,0)
    passNum = math.min(passNum,3)

    table.sort(passData,function (a,b)
        return a.passStatus > b.passStatus
    end)

    for i=1,3 do
        items["star"..i]:setVisible(i<=passNum)
        items["star1_"..i]:setVisible(i<=passNum)
        items["star2_"..i]:setVisible(i<=passNum)

        local index = passData[i].index
        local des = gameConfig.strings:babelTowerPassCondition(levelConfig["through_conditions"..index],levelConfig["attribute"..index],levelConfig["attribute"..index.."_"..index])
        items["des"..i]:setString(des)
    end

    ui.setLabelString(items.replaytext,gameConfig.strings:string_common("battleScene",2),18)
    ui.setLabelString(items.quittext,gameConfig.strings:string_common("battleScene",3),18)

    items.replay:addHandleOfControlEvent(function()
        self:replay()
    end,CCControlEventTouchUpInside)
    items.replay:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    items.quit:addHandleOfControlEvent(function()
        self:clear()
    end,CCControlEventTouchUpInside)
    items.quit:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    local animationManager = getAnimationManager(items)
    animationManager:runAnimationsForSequenceNamed(tostring(passNum))
end

function battleScene.showExp(self)


    if not self.result and self.exp.newlevel ~= self.exp.oldlevel then
        self:showResultWithOutExp()
        return
    end


    self:initresultnode()
    
    local counttimers = {}
    if self.result  then
        self.resultNode,self.resultItem = CCBReaderLoad("backGround/get-shengli", nil, true, "get-shengli")
        
        --
        local generalsdata = {}
        if GameScene.layers["generals"].module and GameScene.layers["generals"].module.generalsdata then
            generalsdata = table.copy(GameScene.layers["generals"].module.generalsdata)
        end
        --
        for k,v in ipairs(self.slotpos) do
            if self.generalexp[tostring(k)] then
                local config = gamedata.config.general[tostring(self.generalexp[tostring(k)].cid)]
                local expdata = self.generalexp[tostring(k)]
                local awakenConfig = self.awakenConfig
                if config.actor == "lead" then
                    awakenConfig = gamedata.config.protagonist_awaken
                end
                --
                local data = {
                    quality = config.quality,
                    icon = config.icon,
                    name = config.name,
                    exp = expdata.exp,
                    level = expdata.level,
                    level2 = expdata.level2,
                    levelup = expdata.levelup,
                    awakenicon = ((config.awaken > 0 or config.actor == "lead") and expdata.skilllevel > 0) and   awakenConfig[tostring(expdata.skilllevel)].icon or nil,
                    awakenstage = ((config.awaken > 0 or config.actor == "lead") and expdata.skilllevel > 0) and  awakenConfig[tostring(expdata.skilllevel)].stage or nil,
                }
                -- 设置头像
                local selsecData = {}
                for k,v in pairs(generalsdata) do
                    local cid = v.illusionGeneralCid or v.cid
                    if expdata.cid == cid then
                        selsecData = v
                        break
                    end
                end
                if next(selsecData) then
                    if selsecData.illusionGeneralCid then
                        local gdata = ui.getConfigGeneralSion(selsecData)
                        if next(gdata) and config.fashion_id == 0 then
                            data.icon = gdata.icon
                        end
                    else
                        local gdata = ui.getConfigGeneral(selsecData)
                        if next(gdata) and config.fashion_id == 0 then
                            data.icon = gdata.icon
                        end
                    end
                end
                ui.setGeneralIconL(data,self.resultItem,k-1,true)
            else
                self.resultItem["general"..k]:setVisible(false)
            end
        end

        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(3), CCCallFunc:create(function()
            runPowerChange()
            for k,v in ipairs(self.slotpos) do
                if self.generalexp[tostring(k)] then
                    local config = gamedata.config.general[tostring(self.generalexp[tostring(k)].cid)]
                    local expdata = self.generalexp[tostring(k)]

                    local awakenConfig = self.awakenConfig
                    if config.actor == "lead" then
                        awakenConfig = gamedata.config.protagonist_awaken
                    end
                    if expdata.exp >0 then
                        local data = {
                            quality = config.quality,
                            icon = config.icon,
                            name = config.name,
                            exp = expdata.exp,
                            level = expdata.level,
                            level2 = expdata.level2,
                            levelup = expdata.levelup,
                            awakenicon = ((config.awaken > 0 or config.actor == "lead") and expdata.skilllevel > 0) and   self.awakenConfig[tostring(expdata.skilllevel)].icon or nil,
                            awakenstage =((config.awaken > 0 or config.actor == "lead") and expdata.skilllevel > 0) and  self.awakenConfig[tostring(expdata.skilllevel)].stage or nil,                         
                        }
                        counttimers[k] = ui.generalExpCount(data,self.resultItem,k-1)
                    end
                else
                    self.resultItem["general"..k]:setVisible(false)
                end
            end
        end))
        self.resultNode:runAction(sequence)

        local ccb,item = CCBReaderLoad("backGround/shengli2", nil, true, "shengli2")

        if item.battleReportNode then
            item.battleReportNode:setVisible(false)
        end
        self.resultItem.effectnode:addChild(ccb)
        for i=1, 3 do
            if i <= self.star then
                item["star"..i]:setVisible(true)
            else
                item["star"..i]:setVisible(false)
            end
        end
        local animationManager = getAnimationManager(item)
        animationManager:runAnimationsForSequenceNamed("shengli_success_"..(self.star or 0))
    else
        self.resultNode,self.resultItem = CCBReaderLoad("backGround/get-shibai2", nil, true, "get-shibai")

        local breakconfig = gamedata.config.battle_result or {}

        local failconfig = {}
        for k,v in pairs(breakconfig) do
            if GameScene.roleinfo.level >= v.level1 and GameScene.roleinfo.level <= v.level2 then
                failconfig = v
                break
            end
        end
        --printT(self.resultItem)

        for i=1,4 do
            local kext = ""
            if i>1 then kext = "_"..(i-1) end
            setSpriteFrameByName(self.resultItem["icon"..kext],failconfig["icon"..i])
            self.resultItem["title"..kext]:setString(failconfig["title"..i])
            ui.setLabelString(self.resultItem["des"..kext],failconfig["desc"..i],13)
            local open = GameScene:checkopenlevelbyId(failconfig["systemid"..i],true)
            self.resultItem["gotonode"..kext]:setVisible(open)
            self.resultItem["locknode"..kext]:setVisible(not open)
            if open then
                self.resultItem["gotobutton"..kext]:setTouchPriority(gameConfig.touchPriority.battleScene - 11)
                self.resultItem["gotobutton"..kext]:addHandleOfControlEvent(function()
                    self:clear()
                    GameScene:shiftLayerById(failconfig["systemid"..i])
                end,CCControlEventTouchUpInside)
            else
                ui.setLabelString(self.resultItem["openlevel"..kext],gamedata.config.build[tostring(failconfig["systemid"..i])].level.."级开启",13)
            end
        end
    end

    -- if GameScene.roleinfo.level < tonumber(gamedata.config.global_kv.damage_open_level.value) then
    --     ui.addGray("CCControlButton",self.resultItem.InjuryTotalBtn)
    -- else
    --     ui.removeGray("CCControlButton",self.resultItem.InjuryTotalBtn)
    -- end
    --伤害统计
    -- self.resultItem.InjuryTotalBtn:addHandleOfControlEvent(function()
    --     -- if GameScene.roleinfo.level < tonumber(gamedata.config.global_kv.damage_open_level.value) then
    --         --runGamePrompt({msg = gamedata.config.global_kv.damage_open_level.value.."级后可查看伤害统计"})
    --         -- runGamePrompt({msg = gamedata.config.global_kv.damage_open_level.value..gameConfig.strings:string_common("battleScene",36)})
    --     -- else
    --         self:battleRoleInjury(counttimers)
    --     -- end
    -- end,CCControlEventTouchUpInside)
    -- self.resultItem.InjuryTotalBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 11)
    -- ui.setLabelString(self.resultItem.replaytext,"重 播",18)
    -- ui.setLabelString(self.resultItem.quittext,"确 定",18)

    ui.setLabelString(self.resultItem.replaytext,gameConfig.strings:string_common("battleScene",2),18)
    ui.setLabelString(self.resultItem.quittext,gameConfig.strings:string_common("battleScene",3),18)

    self.resultItem.battleRoleInjuryBtn:addHandleOfControlEvent(function()
        self:battleRoleInjury(counttimers)
    end,CCControlEventTouchUpInside)
    self.resultItem.battleRoleInjuryBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultItem.replay:addHandleOfControlEvent(function()
        for k,v in pairs(counttimers) do
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(v)
        end
        self:replay()
    end,CCControlEventTouchUpInside)
    self.resultItem.replay:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultItem.quit:addHandleOfControlEvent(function()
        for k,v in pairs(counttimers) do
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(v)
        end
        self:clear()
        GameScene:coin_effect(1,540,600,0.5)
    end,CCControlEventTouchUpInside)
    self.resultItem.quit:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultItem.exp:setString(self.exp.rolegetexp)
    self.resultItem.coin:setString(self.coin)
    self.resultItem.barsprite:removeFromParentAndCleanup(false)
    self.resultItem.userexpbar = CCProgressTimer:create(self.resultItem.barsprite)
    self.resultItem.userexpbar:setAnchorPoint(ccp(0, 0.5))
    self.resultItem.userexpbar:setType(kCCProgressTimerTypeBar)
    self.resultItem.userexpbar:setMidpoint(ccp(0, 0.5))
    self.resultItem.userexpbar:setBarChangeRate(ccp(1, 0))
    self.resultItem.userexpbar:setPosition(ccp(-346, 0.5))

    self.resultItem["userexpnode"]:addChild(self.resultItem.userexpbar)

    self.resultItem.userexpbar:setPercentage(100*self.exp.oldexp/gamedata.config.role_exp[tostring(self.exp.oldlevel)].nextexp)
    ui.setLabelString(self.resultItem.userlv,"等级: "..self.exp.oldlevel,46)

    self.resultItem.replay:setEnabled(false)
    self.resultItem.quit:setEnabled(false)
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(self.result and 4 or 1), CCCallFunc:create(function()
        self.resultItem.replay:setEnabled(true)
        self.resultItem.quit:setEnabled(true)

        if self.exp.newlevel == self.exp.oldlevel then
            local ProgressFromTo = CCProgressFromTo:create(0.4,
                100*self.exp.oldexp/gamedata.config.role_exp[tostring(self.exp.oldlevel)].nextexp,
                100*self.exp.newexp/gamedata.config.role_exp[tostring(self.exp.newlevel)].nextexp)
            self.resultItem.userexpbar:runAction(ProgressFromTo)
        else
            local ProgressFromTo1 = CCProgressFromTo:create(0.4,
                100*self.exp.oldexp/gamedata.config.role_exp[tostring(self.exp.oldlevel)].nextexp,
                100)
            local cb = function()
                ui.setLabelString(self.resultItem.userlv,"等级: "..self.exp.newlevel,46)
                local ProgressFromTo2 = CCProgressFromTo:create(0.4,
                    0,
                    100*self.exp.newexp/gamedata.config.role_exp[tostring(self.exp.newlevel)].nextexp)
                self.resultItem.userexpbar:runAction(ProgressFromTo2)
            end
            self.resultItem.userexpbar:runAction(CCSequence:createWithTwoActions(ProgressFromTo1,CCCallFunc:create(cb)))
        end

        if guide.controller then
            guide.controller:setGuideLayerVisible(true)
        end
    end))
    self.animationNode:runAction(sequence)


    self.resultNode:setScale(guide.scaleNum)
    self.resultNode:setAnchorPoint(ccp(0.5,0.5))
    self.resultNode:setPosition(ccp(self.d_viewSize.width/2, self.d_viewSize.height/2))
    self.rootLayer:addChild(self.resultNode,1)
end

function battleScene.battleRoleInjury(self,counttimers)
    if self.battleRoleInjuryNode then
        return
    end

    self.battleRoleInjuryNode,self.battleRoleInjuryItem = CCBReaderLoad("backGround/shanghaitongji", nil, true, "shanghaitongji")
    self.battleRoleInjuryItem.fixedTitle:setString(gameConfig.strings:string_common("battleScene",22))
    self.battleRoleInjuryItem.damageFixed1:setString(gameConfig.strings:string_common("battleScene",23))
    self.battleRoleInjuryItem.damageFixed2:setString(gameConfig.strings:string_common("battleScene",24))
    local atkMaxDamage = 0
    local defMaxDamage = 0

    if self.atk.SlotInfo then
        for k,v in pairs(self.atk.SlotInfo) do
            if v.blowDamage and atkMaxDamage < v.blowDamage then
                atkMaxDamage = v.blowDamage
            end
        end
    end

    if self.def.SlotInfo then
        for k,v in pairs(self.def.SlotInfo) do
            if v.blowDamage and defMaxDamage < v.blowDamage then
                defMaxDamage = v.blowDamage
            end
        end
    end

    --魔宠的伤害
    if self.atk.SlotInfo and self.atk.SlotInfo["0"] then
        self.battleRoleInjuryItem.atkPetNode:setVisible(true)
        setSpriteFrameByName(self.battleRoleInjuryItem["selfIcon"],self.atk.SlotInfo["0"]["icon"] or "alpha")
        if self.atk.SlotInfo["0"].blowDamage then
            ui.setLabelString(self.battleRoleInjuryItem["selfDamage"], gameConfig.strings:checkBattleDamage(self.atk.SlotInfo["0"].blowDamage),19)
        else
            ui.setLabelString(self.battleRoleInjuryItem["selfDamage"],"0",19)
        end
    else
        self.battleRoleInjuryItem.atkPetNode:setVisible(false)
    end

    if self.def.SlotInfo and self.def.SlotInfo["0"] then
        self.battleRoleInjuryItem.defPetNode:setVisible(true)
        setSpriteFrameByName(self.battleRoleInjuryItem["enemyIcon"],self.def.SlotInfo["0"]["icon"] or "alpha")
        if self.def.SlotInfo["0"].blowDamage and self.def.SlotInfo["0"].blowDamage > 0 then
            ui.setLabelString(self.battleRoleInjuryItem["enemyDamage"], gameConfig.strings:checkBattleDamage(self.def.SlotInfo["0"].blowDamage),19)
        else
            ui.setLabelString(self.battleRoleInjuryItem["enemyDamage"],"0",19)
        end
    else
        self.battleRoleInjuryItem.defPetNode:setVisible(false)
    end

    --武将的伤害统计
    local generalTab = gamedata.config.general
    local _hurtIconConfig = gamedata.config.hurt_icon
    local _atkCount1 = 0
    local _atkCount2 = 0
    local _defCount1 = 0
    local _defCount2 = 0

    for i=1,7 do
        if self.atk.SlotInfo[tostring(i*2)] then
            _atkCount1 = _atkCount1 + 1
            local _key = ui.getKey(_atkCount1 + 1)

            self.battleRoleInjuryItem["selfDamageNode".._key]:setVisible(true)
            local generalConfigTab = generalTab[tostring(self.atk.SlotInfo[tostring(i*2)].cid)]
            
            if generalConfigTab == nil then
                generalConfigTab = _hurtIconConfig[tostring(self.atk.SlotInfo[tostring(i*2)].cid)]
            elseif next(generalConfigTab) and generalConfigTab.icon == nil then
                generalConfigTab = _hurtIconConfig[tostring(self.atk.SlotInfo[tostring(i*2)].cid)]
            end

            setSpriteFrameByName(self.battleRoleInjuryItem["selfIcon".._key],generalConfigTab.icon or "alpha")
            
            if self.atk.SlotInfo[tostring(i*2)].blowDamage and self.atk.SlotInfo[tostring(i*2)].blowDamage > 0 then
                ui.setLabelString(self.battleRoleInjuryItem["selfDamage".._key], gameConfig.strings:checkBattleDamage(self.atk.SlotInfo[tostring(i*2)].blowDamage),19)
                ui.setSpriteTextureRect2(self.battleRoleInjuryItem["selfDamageSpr".._key],0,0,271*(tonumber(self.atk.SlotInfo[tostring(i*2)].blowDamage) < tonumber(atkMaxDamage) and (tonumber(self.atk.SlotInfo[tostring(i*2)].blowDamage) < 0 and 0 or tonumber(self.atk.SlotInfo[tostring(i*2)].blowDamage) ) /tonumber(atkMaxDamage) or 1),33)
            else
                ui.setLabelString(self.battleRoleInjuryItem["selfDamage".._key], "0",19)
                ui.setSpriteTextureRect2(self.battleRoleInjuryItem["selfDamageSpr".._key],0,0,0,33)
            end
        else
            _atkCount2 = _atkCount2 + 1
            local _key = ui.getKey(8 - _atkCount2 + 1)
            self.battleRoleInjuryItem["selfDamageNode".._key]:setVisible(false)
        end
        if self.def.SlotInfo[tostring(i*2)] then
            _defCount1 = _defCount1 + 1
            local _key = ui.getKey(_defCount1 + 1)

            self.battleRoleInjuryItem["enemyDamageNode".._key]:setVisible(true)
            local generalConfigTab2 = generalTab[tostring(self.def.SlotInfo[tostring(i*2)].cid)]
            
            if generalConfigTab2 == nil then
                generalConfigTab2 = _hurtIconConfig[tostring(self.def.SlotInfo[tostring(i*2)].cid)]
            elseif next(generalConfigTab2) and generalConfigTab2.icon == nil then
                generalConfigTab2 = _hurtIconConfig[tostring(self.def.SlotInfo[tostring(i*2)].cid)]
            end
            
            if generalConfigTab2 then
                setSpriteFrameByName(self.battleRoleInjuryItem["enemyIcon".._key],generalConfigTab2["icon"] or "alpha")
            end
            if self.def.SlotInfo[tostring(i*2)].blowDamage and self.def.SlotInfo[tostring(i*2)].blowDamage > 0 then
                ui.setLabelString(self.battleRoleInjuryItem["enemyDamage".._key], gameConfig.strings:checkBattleDamage(self.def.SlotInfo[tostring(i*2)].blowDamage),19)
                ui.setSpriteTextureRect2(self.battleRoleInjuryItem["enemyDamageSpr".._key],0,0,271*(tonumber(self.def.SlotInfo[tostring(i*2)].blowDamage) < tonumber(defMaxDamage) and (tonumber(self.def.SlotInfo[tostring(i*2)].blowDamage) < 0 and 0 or tonumber(self.def.SlotInfo[tostring(i*2)].blowDamage) ) /tonumber(defMaxDamage) or 1),33)
            else
                ui.setLabelString(self.battleRoleInjuryItem["enemyDamage".._key], "0",19)
                ui.setSpriteTextureRect2(self.battleRoleInjuryItem["enemyDamageSpr".._key],0,0,0,33)
            end
        else
            _defCount2 = _defCount2 + 1
            local _key = ui.getKey(8 - _defCount2 + 1)
            self.battleRoleInjuryItem["enemyDamageNode".._key]:setVisible(false)
        end
    end
    ui.setLabelString(self.battleRoleInjuryItem.backLab,gameConfig.strings:string_common("battleScene",25), 18)
    ui.setLabelString(self.battleRoleInjuryItem.sureLab,gameConfig.strings:string_common("battleScene",3), 18)
    self.battleRoleInjuryItem.backButton:addHandleOfControlEvent(function()
        self.battleRoleInjuryNode:removeAllChildrenWithCleanup(true)
        self.battleRoleInjuryNode:removeFromParentAndCleanup(true)
        self.battleRoleInjuryNode = nil
        self.battleRoleInjuryItem = nil
    end,CCControlEventTouchUpInside)
    self.battleRoleInjuryItem.backButton:setSwallowsTouch(true)
    self.battleRoleInjuryItem.backButton:setTouchPriority(gameConfig.touchPriority.battleScene - 12)
    self.battleRoleInjuryItem.sureBtn:addHandleOfControlEvent(function()
        if counttimers then
            for k,v in pairs(counttimers) do
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(v)
            end
        end
        self:clear()
        if self.resultType == "copy" then
            GameScene:coin_effect(1,540,600,0.5)
        end
    end,CCControlEventTouchUpInside)
    self.battleRoleInjuryItem.sureBtn:setSwallowsTouch(true)
    self.battleRoleInjuryItem.sureBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 12)
    self.battleRoleInjuryNode:setScale(guide.scaleNum)
    self.battleRoleInjuryNode:setAnchorPoint(ccp(0.5,0.5))
    self.battleRoleInjuryNode:setPosition(ccp(self.d_viewSize.width/2, self.d_viewSize.height/2))
    self.rootLayer:addChild(self.battleRoleInjuryNode,2)
end

function battleScene.showResultWithOutExp(self)
    self:showbattleResult()
    -- local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(3), CCCallFunc:create(function() self:clear() end))
    -- self.animationNode:runAction(sequence)
end

function battleScene.showResultWithExp(self)
    self:showbattleResult()
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(3), CCCallFunc:create(function() self:showExp() end))
    self.animationNode:runAction(sequence)
end

function battleScene.showWinner(self)
    self:initresultnode()
    self.resultNode,self.resultItem = CCBReaderLoad("backGround/get-gxse", nil, true, "get-gxse")

    self.resultItem.name:setString(self.winner.name)
    self.resultItem.level:setString(self.winner.level)
    local winnerdes = ""
    -- if self.round<=8 then
    --     winnerdes = "距离冠军还剩"..(12-8).."场比赛！！"
    -- elseif self.round ==9 then
    --     winnerdes = "晋级8强！！"
    -- elseif self.round ==10 then
    --     winnerdes = "晋级4强！！"
    -- elseif self.round ==11 then
    --     winnerdes = "晋级决赛！！"
    -- elseif self.round ==12 then
    --     winnerdes = "赢得冠军！！"
    -- end
     if self.round<=8 then
        winnerdes = gameConfig.strings:disbattleNo((12-self.round))
    elseif self.round ==9 then
        winnerdes = gameConfig.strings:string_common("battleScene",4)
    elseif self.round ==10 then
        winnerdes = gameConfig.strings:string_common("battleScene",5)
    elseif self.round ==11 then
        winnerdes = gameConfig.strings:string_common("battleScene",6)
    elseif self.round ==12 then
        winnerdes = gameConfig.strings:string_common("battleScene",7)
    end

    self.resultItem.winnerdes:setString(winnerdes)

--    local generalname = ""
--    if self.result then
--        generalname = self["atk"].initSlotInfo["2"].animation.name
--    else
--        generalname = self["def"].initSlotInfo["2"].animation.name
--    end
--    local skeleton = CCSkeletonAnimation:create(generalname.."/"..generalname..".json",generalname.."/"..generalname..".atlas",2)

    local generalinfo = self[self.result and "atk" or "def"].initSlotInfo["2"]
    local skeleton = ui.itemcache:loadSkeleton(generalinfo.animation.name,{level=generalinfo.w_l,color = generalinfo.w_c})
    skeleton:setPosition(0,0)
    skeleton:setScaleX(self.result and 1 or -1)
    skeleton:setAnimation("stand",true,0)
    self.resultItem.generalnode:addChild(skeleton.root or skeleton)
    self.resultItem.quit:addHandleOfControlEvent(function()
        self:clear()
    end,CCControlEventTouchUpInside)
    self.resultItem.quit:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultNode:setScale(self.d_viewSize.width/self.viewSize.width)
    self.resultNode:setAnchorPoint(ccp(0.5,0.5))
    self.resultNode:setPosition(ccp(self.d_viewSize.width/2, self.d_viewSize.height/2))
    self.rootLayer:addChild(self.resultNode,1)


    self.resultItem.battleRoleInjuryBtn:addHandleOfControlEvent(function()
        self:battleRoleInjury(counttimers)
    end,CCControlEventTouchUpInside)
    self.resultItem.battleRoleInjuryBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 11)
end

function battleScene.showWinnerOfHonorBattle( self )
    self:initresultnode()
    self.resultNode,self.resultItem = CCBReaderLoad("rongyaozhizhan/rongyaozhizhan_shengli", nil, true, "rongyaozhizhan_shengli")

    local winnername = self.result and self.atkname[1] or self.defname[1]
    self.resultItem.winner:setString(winnername)

    -- self.resultItem.quit:addHandleOfControlEvent(function()
    --     self:clear()
    -- end,CCControlEventTouchUpInside)
    -- self.resultItem.quit:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultItem.battleRoleInjuryBtn:addHandleOfControlEvent(function()
        self:battleRoleInjury()
    end,CCControlEventTouchUpInside)
    self.resultItem.battleRoleInjuryBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultItem.replay:addHandleOfControlEvent(function()
        self:replay()
    end,CCControlEventTouchUpInside)
    self.resultItem.replay:setTouchPriority(gameConfig.touchPriority.battleScene - 11)

    self.resultItem.quit:addHandleOfControlEvent(function()
        self:clear()
    end,CCControlEventTouchUpInside)
    self.resultItem.quit:setTouchPriority(gameConfig.touchPriority.battleScene - 11)
    
    self.resultNode:setScale(self.d_viewSize.width/self.viewSize.width)
    self.resultNode:setAnchorPoint(ccp(0.5,0.5))
    self.resultNode:setPosition(ccp(self.d_viewSize.width/2, self.d_viewSize.height/2))
    self.rootLayer:addChild(self.resultNode,1)


    for i=1, 3 do
        if i <= self.star then
            self.resultItem["star"..i]:setVisible(true)
        else
            self.resultItem["star"..i]:setVisible(false)
        end
    end
    local animationManager = getAnimationManager(self.resultItem)
    animationManager:runAnimationsForSequenceNamed(tostring(self.star) or "repeat")
end

function battleScene.delayclear(self)
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(2), CCCallFunc:create(function()
        self:clear()
    end))
    self.animationNode:runAction(sequence)
end

function battleScene.showResultWithDamege(self,postype)
    self:initresultnode()

    self.resultNode,self.resultItem = CCBReaderLoad("backGround/battleover", nil, true, "battleover")
    local totaldamge = math.floor((self.reportEXT.damagetotal[postype])*100/self["defhptotal"])
    if totaldamge>100 then
        totaldamge =100
    elseif totaldamge<0 then
        totaldamge = 0
    end

    ui.setLabelString( self.resultItem.damage,gameConfig.strings:string_common("battleScene",15)..totaldamge.."%",19)
    ui.setLabelString( self.resultItem.des,gameConfig.strings:string_common("battleScene",17),19)

    self.resultItem.quit:addHandleOfControlEvent(function()
        self:clear()
    end,CCControlEventTouchUpInside)
    self.resultItem.quit:setTouchPriority(gameConfig.touchPriority.battleScene - 11)


    --    local animationManager = getAnimationManager(self.resultItem)
    --    animationManager:runAnimationsForSequenceNamed("shengli_success_"..(self.star or 0))

    self.resultNode:setScale(self.d_viewSize.width/self.viewSize.width)
    self.resultNode:setAnchorPoint(ccp(0.5,0.5))
    self.resultNode:setPosition(ccp(self.d_viewSize.width/2, self.d_viewSize.height/2))
    self.rootLayer:addChild(self.resultNode,1)

end


function battleScene.showResult(self)
    print("battle end")
    self:removeDamageTotal()
    if self.resultType == "story" then self:clear() return end
    self:celebrate()


    local delayfunc = function()
        if self.resultType == "copy" then
            self:showExp()
        elseif self.resultType == "sports" then
            self:showResultWithOutExp()
        elseif self.resultType == "servicewar" then
            self:showResultWithOutExp()
        elseif self.resultType == "honorwar" then
            self:showWinnerOfHonorBattle()
        elseif self.resultType == "blood" then
            self:showResultWithOutExp()
        elseif self.resultType == "rob" then
            self:showResultWithOutExp()
        elseif self.resultType == "encounter" then
            self:showResultWithOutExp()
        elseif self.resultType == "friendcopy" then
            self:showResultWithOutExp()
        elseif self.resultType == "story" then
            self:clear()
        elseif self.resultType == "fort" then
            self:clear()
        elseif self.resultType == "cup" then
            self:showWinner()
        elseif self.resultType == "battleother" then
            self:showResultWithOutExp()
        elseif self.resultType == "penglai" then
            self:showResultWithOutExp()
        elseif self.resultType == "worldboss" then
            self:showResultWithOutExp()
        elseif self.resultType == "test" then
            self:delayclear()
        elseif self.resultType == "skillview" then
            self:clear()
        elseif self.resultType == "guildwar" then
            self:clear()
        elseif self.resultType == "activitycopy" then
            self:showResultWithOutExp()
        elseif self.resultType == "singleboss" then
            self:showResultWithOutExp()
        elseif self.resultType == "copystar" then
            self:showResultWithOutExp()
        elseif self.resultType == "copyhades" then
            self:showResultWithOutExp()
        elseif self.resultType == "maze" then
            self:showResultWithOutExp()
        elseif self.resultType == "champion" then
            self:showResultWithOutExp()
        elseif self.resultType == "overpass" then
            self:showResultWithOutExp()
        elseif self.resultType == "wudaohui" then
            self:showResultWithOutExp()
        elseif self.resultType == "activitycopyboss" then
            self:showResultWithDamege("def")
        elseif self.resultType == "nightclub1" or self.resultType == "nightclub2" then
            self:showResultWithOutExp()
        elseif self.resultType == "heroboss" then
            self:showResultWithOutExp()
        elseif self.resultType == "kingBattle" then
            self:showResultWithOutExp()
        elseif self.resultType == "kingBattle2" then
            self:showResultWithOutExp()
        elseif self.resultType == "copyhell" then
            self:showResultWithOutExp()
        elseif self.resultType == "babelTower" then
            self:showbattleResult()
        elseif self.resultType == "blessingCave" then
            self:showResultWithOutExp()
        elseif self.resultType == "robbery" then
            self:showResultWithOutExp()
        elseif self.resultType == "ancientRuins" then
            self:showResultWithOutExp()
        elseif self.resultType == "normal" then
            self:showResultWithOutExp()
        elseif self.resultType == "exclusiveArtifactCopy" then
            self:showResultWithOutExp()
        elseif self.resultType == "exclusiveActive" then
            self:showResultWithOutExp()
        elseif self.resultType == "godCompetitionBattle" then
            self:showResultWithOutExp()
        elseif  self.resultType == "godCompetition" then
            self:showWinnerOfHonorBattle()
        elseif  self.resultType == "sendaiBattle" then
            self:showResultWithOutExp()
        end

    end

    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(2), CCCallFunc:create(delayfunc))
    self.animationNode:runAction(sequence)
end

function battleScene.setonebloodstar(self,pos,index,switch)
    if switch ~= self[pos.."stardisappear"][index] then

        if self.bgcontrolitem[pos.."star"..index] then
            local scaleTo = CCScaleTo:create(0.3, switch and 1 or 0)
            local backOut = switch and CCEaseBackOut:create(scaleTo) or CCEaseBackIn:create(scaleTo)

            self.bgcontrolitem[pos.."star"..index]:runAction(backOut)
        end
        
        self[pos.."stardisappear"][index] =  switch
    end
end

function battleScene.setBloodstar(self,pos)
    if self[pos.."hp"]/self[pos.."hptotal"] > 2/3  then
         self:setonebloodstar(pos,3,true)
         self:setonebloodstar(pos,2,true)
         self:setonebloodstar(pos,1,true)
    elseif self[pos.."hp"]/self[pos.."hptotal"] > 1/3 and self[pos.."hp"]/self[pos.."hptotal"] < 2/3 then
        self:setonebloodstar(pos,3,false)
        self:setonebloodstar(pos,2,true)
        self:setonebloodstar(pos,1,true)
    elseif self[pos.."hp"]/self[pos.."hptotal"] < 1/3 and self[pos.."hp"]/self[pos.."hptotal"] >0 then
        self:setonebloodstar(pos,3,false)
        self:setonebloodstar(pos,2,false)
        self:setonebloodstar(pos,1,true)
    elseif self[pos.."hp"]/self[pos.."hptotal"] <=0 then
        self:setonebloodstar(pos,3,false)
        self:setonebloodstar(pos,2,false)
        self:setonebloodstar(pos,1,false)
    end
end


function battleScene.setBlood(self,pos,damage)

    local lastHP = self[pos.."hp"]
    self[pos.."hp"] =  self[pos.."hp"] - damage
    if self[pos.."hp"] <0 then
        self[pos.."hp"] = 0
    elseif self[pos.."hp"] > self[pos.."hptotal"] then
        self[pos.."hp"] = self[pos.."hptotal"]
    end
    local to = CCProgressFromTo:create(0.2,lastHP*100/self[pos.."hptotal"],self[pos.."hp"]*100/self[pos.."hptotal"])
    self[pos.."bloodbar"]:stopAllActions()
    self[pos.."bloodbar"]:runAction(to)

    self:setBloodstar(pos)

    if pos == "def" then
        self:setBattleInfo({
            damage = math.floor((self[pos.."hptotal"]-self[pos.."hp"])*100/self[pos.."hptotal"]).."%"
        })
    end

end

function battleScene.addDamageTotal(self,pos)
    print("addDamageTotal",pos)
    if self.DamageTotalccb then return end
    self.DamageTotalccb, self.DamageTotalitem = CCBReaderLoad("Effect/loseblood_all", nil, true, "loseblood_all")
    self.bgcontrolitem.damagetotal:addChild(self.DamageTotalccb)
    print("addDamageTotal",pos)
    self.DamageTotalccb:setPosition(0,0)
    print("addDamageTotal",pos)
    if pos == "atk" then
        self.DamageTotalccb:setScaleX(-1)
        self.DamageTotalitem["001"]:setFlipX(true)
        self.DamageTotalitem.damagenode:setScaleX(-1)
        self.DamageTotalitem.damage:setAnchorPoint(ccp(0,0.5))
    end
    print("addDamageTotal",pos)
    self.DamageTotal = 0
    self.DamageTotalitem.damage:setString(self.DamageTotal)
    self.DamageTotalanimationManager = getAnimationManager(self.DamageTotalitem)
    self.DamageTotalanimationManager:runAnimationsForSequenceNamed("loseblood_all")
end
function battleScene.removeDamageTotal(self)
    if not self.DamageTotalccb then return end
    self.DamageTotalanimationManager:setAnimationCompletedCallback(function()
        self.DamageTotalccb:removeFromParentAndCleanup(true)
        self.DamageTotalccb = nil
        self.DamageTotalitem = nil
        self.DamageTotalanimationManager = nil
        self.DamageTotal = 0
    end)
    self.DamageTotalanimationManager:runAnimationsForSequenceNamed("loseblood_all03")
end

function battleScene.setDamageTotal(self,damage,pos)
    local action = self.animation[self.actionStep]
    if action and (action.type2 == "normal" or action.type2 == "destonly" or damage <= 0) then return end

    if not self.DamageTotalccb then
        self:addDamageTotal(pos)
    end
    self.DamageTotal = self.DamageTotal + damage
    self.DamageTotalitem.damage:setString(math.abs(self.DamageTotal))
    self.DamageTotalanimationManager:runAnimationsForSequenceNamed("loseblood_all02")
end

function battleScene.initGeneral(self,pos,SlotInfo)

    self[pos.."hp"] =0
    self[pos.."hptotal"] =0
    self[pos.."stardisappear"] = {true,true,true}

    for k,v in pairs(SlotInfo or self[pos].initSlotInfo) do
        if k==0 or k=="0" then
            self[pos].general[k] = petMeta:init(self.bgcontrolitem["pet"..pos],v,pos,self)
        else
            self[pos].general[k] =  generaMeta:init(self.rootNode,v,pos,self[pos].posTable[tonumber(k)],self)
            self[pos.."hp"] = self[pos.."hp"] + self[pos].general[k].hp
            self[pos.."hptotal"] = self[pos.."hptotal"] + self[pos].general[k].hptotal
        end
    end

--    if not self["atk"].general["0"] then
--        self["atk"].general["0"] = petMeta:init(self.bgcontrolitem["petatk"],nil,"atk",self)
--    end
--    if not self["def"].general["0"] then
--        self["def"].general["0"] = petMeta:init(self.bgcontrolitem["petdef"],nil,"def",self)
--    end

    local bloodbar = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame(pos == "atk" and "battleUI_05.png" or "battleUI_06.png"))

    self[pos.."bloodbar"] = CCProgressTimer:create(bloodbar)
    self[pos.."bloodbar"]:setAnchorPoint(ccp(0.5, 0.5))
    self[pos.."bloodbar"]:setType(kCCProgressTimerTypeBar)
    self[pos.."bloodbar"]:setMidpoint(ccp(pos == "atk" and 0 or 1, 0.5))
    self[pos.."bloodbar"]:setBarChangeRate(ccp(1, 0))
    self[pos.."bloodbar"]:setPosition(ccp(0, 0))

    self.bgcontrolitem[pos.."totalbloodnode"]:addChild(self[pos.."bloodbar"])

    self[pos.."bloodbar"]:setPercentage(100*self[pos.."hp"]/self[pos.."hptotal"])
    self:setBloodstar(pos)
    self.bgcontrolitem[pos.."_name"]:setString(self[pos.."name"][1])
end

function battleScene.autoScale(self)
    self.bgitem.autoscalenode:setAnchorPoint(ccp(0.5, 0.5))
    self.bgitem.autoscalenode:setPosition(ccp(540, 960))
    local atkscale = 1.4
    local defscale = 1.4
    for k,v in ipairs(self.slotpos) do
        if self.atk.general[v] and self.scenescale[k] < atkscale then
            atkscale = self.scenescale[k]
        end
        if self.def.general[v] and self.scenescale[k] < defscale then
            defscale = self.scenescale[k]
        end
    end

    if self.autoscale ~= math.min(atkscale,defscale) then
        self.autoscale =  math.min(atkscale,defscale)
--        local moveto = CCMoveTo:create(0.4,ccp(540,-960*(self.autoscale-1)))
--        local backOut1 = CCEaseOut:create(moveto,2)

        local scaleTo = CCScaleTo:create(0.4, self.autoscale)
        local backOut = CCEaseOut:create(scaleTo,2)

        --local spw = CCSpawn:createWithTwoActions(backOut1,backOut)
        self.bgitem.autoscalenode:runAction(backOut)
    end
end

function battleScene.setSpeed(self,step,isresave,isinit)
    if step == 3 then
        local openvip = ui.getVipLevelByStr("speed3")

        if GameScene.roleinfo and GameScene.roleinfo.level < tonumber(gamedata.config.global_kv.battle_speed_limit.value) then --and GameScene.vip.vip < openvip then
            if self.hasshow or isinit then
                step = 1
                self.hasshow = false             
            else
                --runGamePrompt({msg = gamedata.config.global_kv.battle_speed_limit.value.."级或VIP"..openvip.."可开启战斗3倍加速"})
                runGamePrompt({msg = gamedata.config.global_kv.battle_speed_limit.value.."级可开启战斗3倍加速"})
                self.hasshow = true
                return
            end

        end

    end

    self.speedstep = step
    if self.speedstep > 3 then self.speedstep = 1 end
    if isresave then  self.savedSpeed = self.speedstep end
    print("self.savedSpeed2",isresave,self.savedSpeed,self.speedstep)

    self:saveBattleSpeedToSqlite(self.speedstep)

    local speednum = 1
    local stopOff = 0
    if GameScene.roleinfo and GameScene.roleinfo.id then
        if  guide.controller and guide.controller.isOnGuide and guide.controller.excute.section == 1 then
        else
            local numstr = CCUserDefault:sharedUserDefault():getStringForKey("gmspeednum"..GameScene.roleinfo.id)
            if numstr and numstr ~= "" then
                speednum = tonumber(numstr)
            end
            stopOff = CCUserDefault:sharedUserDefault():getIntegerForKey("gmspeedstate"..GameScene.roleinfo.id)
        end
    end
    if stopOff == 0 then
        CCDirector:sharedDirector():getScheduler():setTimeScale(self.speedconfig[self.speedstep] + (speednum-1))
    else
        CCDirector:sharedDirector():getScheduler():setTimeScale(self.speedconfig[self.speedstep])
    end

    local animationManager = getAnimationManager(self.speeditem)
    animationManager:runAnimationsForSequenceNamed("speedbutton_"..self.speedstep)
end

function battleScene.setBattleInfo(self,data)
    if not self.battleinfoitem then return end
    if data.round then
        ui.setLabelString(self.battleinfoitem.round,gameConfig.strings:string_common("battleScene",14)..data.round,13)
    end
    if data.damage then
        ui.setLabelString(self.battleinfoitem.damage,gameConfig.strings:string_common("battleScene",15)..data.damage,13)
    end
    if data.des then
        ui.setLabelString(self.battleinfoitem.des,data.des,13)
    end

end

function battleScene.makeReport(self,report)
    if type(report) == "string" then
        return LoadJsonStringToTable(ReplaceAbbToKey(report))
    elseif type(report) == "table" then
        return report
    else
        cclog("wrong battlereport type")
        return
    end
end

function battleScene.init(self,mainscene,gstate,result,callback)
    if self.show then return end

    if loading.netproflayer then
        loading.netopencallback= function() self:init(mainscene,gstate,result,callback) end
        return
    end

    clearPrompt()

    self.show = true
    self.scaleNum = gameConfig.scaleNum
    self.rootLayer = CCLayerColor:create(ccc4(0,0,0,255))
    self.rootLayer:setColor(ccc3(0, 0, 0))
    self.rootLayer:setContentSize(CCSizeMake(self.d_viewSize.width, self.d_viewSize.height))
    self.rootLayer:setAnchorPoint(ccp(0,0))
    self.rootLayer:setPosition(ccp(0,0))
    bScene:addChild(self.rootLayer)
    self.awakenConfig = gamedata.config.general_awaken
    self:initAtifactEffectShow()
    self:initShieldEffectShow()
    self:initSkillAndCombSkillShow()

    local function ccTouchBegan(x, y) 
        self.isGMSpeedMove = false
        if self.gmSpeeditem and ui.isTouched(self.gmSpeeditem.gmspnode,x,y) then
            self.touchButton = {touchX = x, touchY = y, bX = self.gmSpeeditem.gmspnode:getPositionX(), bY = self.gmSpeeditem.gmspnode:getPositionY()}
            printT(self.touchButton,"jkp-touchButton")
        end
        return true 
    end

    local function ccTouchMoved(x, y)
        if self.touchButton then
            if x <= 0 then
                x = 0
            elseif x >= self.d_viewSize.width then
                x = self.d_viewSize.width
            end

            if y <= 0 then
                y = 0
            elseif y >= self.d_viewSize.height then
                y = self.d_viewSize.height
            end

            if math.abs(x-self.touchButton.touchX) > 10 or math.abs(y-self.touchButton.touchY) > 10 then
                self.isGMSpeedMove = true
            end
            
            local btnRadius = (self.gmSpeeditem.gmspnode:getContentSize().width/2)*self.scaleNum
            local btnX = self.gmSpeeditem.gmspnode:getPositionX()*self.scaleNum
            local btnY = self.gmSpeeditem.gmspnode:getPositionY()*self.scaleNum
            print("btnRadius = ",btnRadius)
            print("btnX = ",btnX)
            print("width = ",self.d_viewSize.width-btnRadius)
            print("btnY = ",btnY)
            print("height = ",self.d_viewSize.height-btnRadius)
            self.gmSpeeditem.gmspnode:setPosition(ccp(self.touchButton.bX + (x/self.scaleNum - self.touchButton.bX), self.touchButton.bY + (y/self.scaleNum - self.touchButton.bY)))
        end
    end

    local function ccTouchEnded(x, y)
        if self.touchButton then
            local btnRadius = (self.gmSpeeditem.gmspnode:getContentSize().width/2)*self.scaleNum
            local btnX = self.gmSpeeditem.gmspnode:getPositionX()*self.scaleNum
            local btnY = self.gmSpeeditem.gmspnode:getPositionY()*self.scaleNum
            
            if btnX >= btnRadius and btnX <= (self.d_viewSize.width-btnRadius) then
                self.gmSpeeditem.gmspnode:setPositionX(self.touchButton.bX + (x/self.scaleNum - self.touchButton.bX))
            elseif btnX < btnRadius then
                self.gmSpeeditem.gmspnode:setPositionX(btnRadius/self.scaleNum)
            else
                self.gmSpeeditem.gmspnode:setPositionX((self.d_viewSize.width/self.scaleNum - btnRadius/self.scaleNum))
            end

            if btnY >= btnRadius and btnY <= (self.d_viewSize.height-btnRadius) then
                self.gmSpeeditem.gmspnode:setPositionY(self.touchButton.bY + (y/self.scaleNum - self.touchButton.bY))
            elseif btnY < btnRadius then
                self.gmSpeeditem.gmspnode:setPositionY(btnRadius/self.scaleNum)
            else
                self.gmSpeeditem.gmspnode:setPositionY((self.d_viewSize.height/self.scaleNum - btnRadius/self.scaleNum))
            end
            
            self.touchButton = nil
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

    self.rootLayer:registerScriptTouchHandler(onTouch, false, gameConfig.touchPriority.battleScene , true)
    self.rootLayer:setTouchPriority(gameConfig.touchPriority.battleScene)
    self.rootLayer:setTouchEnabled(true)

    self.animationNode= CCNode:create()
    self.rootLayer:addChild(self.animationNode)
    self.shakeanimationNode= CCNode:create()
    self.rootLayer:addChild(self.shakeanimationNode)

    self.bgccb, self.bgitem = CCBReaderLoad("backGround/bg", nil, true, "backGround")
    self.bgcontrolccb, self.bgcontrolitem = CCBReaderLoad("backGround/bgcontrol", nil, true, "bgcontrol")
    self.speedccb,self.speeditem = CCBReaderLoad("backGround/speedbutton", nil, true, "speedbutton")
    self.bgcontrolitem.speednode:addChild(self.speedccb)


    self.bganimationManager = getAnimationManager(self.bgitem)
    self.bgcontrolanimationManager = getAnimationManager(self.bgcontrolitem)

    self.rootNode= self.bgitem.rootNode

    self.scaleNum = gameConfig.scaleNum
    self.topposY =  gameConfig.topposY
    self.bgcontrolitem.topnode:setPositionY(self.topposY)

    self.bgccb:setScale(self.scaleNum)
    self.bgcontrolccb:setScale(self.scaleNum)

    self.bgccb:setAnchorPoint(ccp(0.5,0))
    self.bgccb:setPosition(ccp(self.d_viewSize.width/2, gameConfig.fixH or 0))
    self.rootLayer:addChild(self.bgccb)
    self.bgcontrolccb:setAnchorPoint(ccp(0.5,0))
    self.bgcontrolccb:setPosition(ccp(self.d_viewSize.width/2, gameConfig.fixH or 0))
    self.rootLayer:addChild(self.bgcontrolccb)
    self.isSpeedEnabled = true
    self.speedstep = self:getBattleSpeedFromSqlite()
    self:setSpeed(self.speedstep,nil,true)

    self.bgcontrolitem.speedButton:setTouchPriority(gameConfig.touchPriority.battleScene - 1)
    self.bgcontrolitem.speedButton:addHandleOfControlEvent(function()
        print("setSpeed------")
        self:setSpeed(self.speedstep+1,true)
    end,CCControlEventTouchUpInside)

    self.bgcontrolitem.endButton:setTouchPriority(gameConfig.touchPriority.battleScene - 1)
    self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
        self:endfunction()
    end,CCControlEventTouchUpInside)

    if guide.controller and guide.controller.isOnGuide and guide.controller.excute.section == 1 then
    else
        self:initGMSpeedFunction()
    end

    self.auto = true

    self.callback = callback

    if result.vs_a and result.vs_b then
        self.vs.vs_a = result.vs_a
        self.vs.vs_b = result.vs_b
    end

    self.resultType = gstate
    self.totalround = result.totalround or 0

    local bgs = nil
    if self.resultType == "copy" then
        self.generalexp = result.generalexp
        self.exp = result.exp
        self.coin = result.coin

        if guide.controller.isOnGuide and guide.controller.excute.section == 1 then

        elseif not result.passbattle then
            ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
            self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
                 -- runGamePrompt({msg = "本关三星通过后可跳过战斗"})
                if gamedata.config.global_kv.skip_the_battle_chapter then
                    local name = "" --gamedata.config.map[gamedata.config.global_kv.skip_the_battle_chapter.value].name
                    runGamePrompt({msg = gameConfig.strings:string_common("battleScene",20)..(name or "")})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("battleScene",8)})
                end
            end,CCControlEventTouchUpInside)
        end
        if result.map and result.map <= 42105 then
            bgs =  {"difu1","difu2","difu3"}
        end
    elseif self.resultType == "copyhades" then

        if gamedata.config.global_kv.hades_copy_skip and gamedata.config.global_kv.hades_copy_skip.value and tonumber(gamedata.config.global_kv.hades_copy_skip.value) == 1 then

        else
            ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
            self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
                runGamePrompt({msg = gameConfig.strings:string_common("battleScene",18)})
            end,CCControlEventTouchUpInside)
        end

        bgs =  {"difu1","difu2","difu3"}
    elseif self.resultType == "sports" then

    elseif self.resultType == "servicewar" then
        bgs =  {"bg_kuafuzhan"}
    elseif self.resultType == "honorwar" then
        bgs =  {"bg_kuafuzhan"}
    elseif self.resultType == "godCompetition" then
        bgs =  {"bg_kuafuzhan"}
    elseif self.resultType == "blood" then

    elseif self.resultType == "rob" then

    elseif self.resultType == "encounter" then

    elseif self.resultType == "friendcopy" then
    elseif self.resultType == "godCompetitionBattle" then
    elseif self.resultType == "battleother" then
    elseif self.resultType == "cup" then
        self.round = result.round
        self.winner = result.winner
    elseif self.resultType == "penglai" then
    elseif self.resultType == "worldboss" then
    elseif self.resultType == "test" then
    elseif self.resultType == "story" then
        bgs =  {"renzu1"}
        -- self.bgcontrolitem.endButton:setEnabled(false)
        -- ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
        -- self:setSpeedEnabled(false,"guide")
    elseif self.resultType == "fort" then
    elseif self.resultType == "skillview" then
        bgs =  {"renzu1"}
    elseif self.resultType == "wudaohui" then
        if gamedata.config.global_kv.skip_the_battle and (GameScene.roleinfo.level >= tonumber(gamedata.config.global_kv.skip_the_battle.value)) then

        else
            ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
            self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
                 runGamePrompt({msg = gameConfig.strings:string_common("sports",20)..tonumber(gamedata.config.global_kv.skip_the_battle.value)})
            end,CCControlEventTouchUpInside)
        end

    elseif self.resultType == "activitycopyboss" then
        if gamedata.config.global_kv.skip_the_battle and (GameScene.roleinfo.level >= tonumber(gamedata.config.global_kv.skip_the_battle.value)) then

        elseif result.isfirst and result.isfirst == 1 then
            ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
            self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
                runGamePrompt({msg = gameConfig.strings:string_common("battleScene",19)})
            end,CCControlEventTouchUpInside)
        end
    elseif self.resultType == "nightclub1" then
        ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
        self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
             runGamePrompt({msg = gameConfig.strings:string_common("battleScene",18)})
        end,CCControlEventTouchUpInside)
    elseif self.resultType == "kingBattle" then

        if result.score and result.currentScore then
            self.kingScore = result.score or 0
            self.kingcurrentScore = result.currentScore and result.currentScore > 0 and result.currentScore or 0
            local kingConfig = gamedata.config.king_config
            
            if self.kingScore > 0 then
                self.kingPointScore = kingConfig.king_challenge_reward_win.value
            else
                self.kingPointScore = kingConfig.king_challenge_reward_lose.value
            end

            local kingScoreConfig = gamedata.config.king_paragraph
            local currentIndex = 0
            local nextIndex = 0
            local tabLength = table.getTableLength(kingScoreConfig)
            if self.kingcurrentScore >= kingScoreConfig[tostring(tabLength)].num then
                currentIndex = tabLength
                nextIndex = tabLength
            else
                for i=1,tabLength do
                    if kingScoreConfig[tostring(i)] and kingScoreConfig[tostring(i + 1)] then
                        if self.kingcurrentScore >= kingScoreConfig[tostring(i)].num and self.kingcurrentScore < kingScoreConfig[tostring(i+1)].num then
                            currentIndex = i
                            nextIndex = i+1
                        end
                    end
                end
            end


            if nextIndex ~= 0 and nextIndex == currentIndex then
                self.nextKingSegment = "当前段位为最高段位"
            else
                if kingScoreConfig[tostring(nextIndex)] and kingScoreConfig[tostring(nextIndex)].name then
                    self.nextKingSegment = kingScoreConfig[tostring(nextIndex)].name
                else
                    self.nextKingSegment = ""
                end
            end
        end
    elseif self.resultType == "babelTower" then
        self.babelTowerLevelInfo = result.levelData or {}

        self.bgcontrolitem["atkstar1"]:removeFromParentAndCleanup(true)
        self.bgcontrolitem["atkstar1"] = nil
        self.bgcontrolitem["atkstar2"]:removeFromParentAndCleanup(true)
        self.bgcontrolitem["atkstar2"] = nil
        self.bgcontrolitem["atkstar3"]:removeFromParentAndCleanup(true)
        self.bgcontrolitem["atkstar3"] = nil
        self.bgcontrolitem["defstar1"]:removeFromParentAndCleanup(true)
        self.bgcontrolitem["defstar1"] = nil
        self.bgcontrolitem["defstar2"]:removeFromParentAndCleanup(true)
        self.bgcontrolitem["defstar2"] = nil
        self.bgcontrolitem["defstar3"]:removeFromParentAndCleanup(true)
        self.bgcontrolitem["defstar3"] = nil
        
    elseif self.resultType == "exclusiveActive" then
        ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
        self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("battleScene",18)})
        end,CCControlEventTouchUpInside)
    elseif self.resultType == "sendaiBattle" then --升仙台
        ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
        self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = "第4回合可跳过战斗"})
        end,CCControlEventTouchUpInside)
    end

    if result.speedfalse or (guide.controller and guide.controller.isOnGuide) then
        if self.resultType == "story" then
        elseif guide.controller.isOnGuide and guide.controller.excute.section ==1 then
        else
            self:setSpeedEnabled(false,"guide")
            self.bgcontrolitem.endButton:setEnabled(false)
            ui.addGray("CCControlButton",self.bgcontrolitem.endButton)            
        end
    end
    self.speedresumestep = result.speedresumestep

    bgs = bgs or {"difu1","difu2","difu3","renzu1","renzu2","renzu3","renzu4","xianzu1","xianzu2","xianzu3","xianzu4","yidu1","yidu2"}

    --self.bgName = result.fightbg  or "xianzu1"
    self.bgName = bgs[math.random(1,#bgs)]

    local bgsprite = CCSprite:create("backGround/"..self.bgName..".jpg")
    bgsprite:setPosition(ccp(0,0))
    bgsprite:setAnchorPoint(ccp(0.5, 0))
    bgsprite:setScale(2)
    self.bgitem.bg:addChild(bgsprite)

    self.star = result.star or 0

    local reportT = self:makeReport(result.battlereport)

    self.atkname,self.defname,self.slots = getBattleName(reportT)
    if self.resultType == "wudaohui" then
        self.result = result.result == 1
    elseif self.resultType == "babelTower" then
        self.result = result.result == 1
    else
        self.result = getBattleResult(reportT)    
    end


    local bcall

    --self.atk.initSlotInfo,self.def.initSlotInfo = getBattleInitSlotInfo(reportT)
    bcall, self.atk.initSlotInfo,self.def.initSlotInfo = xpcall(function() return getBattleInitSlotInfo(reportT) end,__G_TRACKBACK__)

    self.atk.SlotInfo,self.def.SlotInfo = table.copy(self.atk.initSlotInfo),table.copy(self.def.initSlotInfo)

    --统计伤害
    if self.resultType == "story" or self.resultType == "story2" or self.resultType == "skillview" or self.resultType == "friendcopy" or self.resultType == "penglai" or self.resultType == "godCompetitionBattle" then

    else
        if self.atk.SlotInfo and self.def.SlotInfo and next(self.atk.SlotInfo) and next(self.def.SlotInfo) then
            if reportT and next(reportT) and reportT.type and reportT.type == "story"  then
                
            else
                self:battleStatisticsDamage(reportT)
            end
        end
    end

    --self.animation = convertBattleReportToAnimationSub(reportT,self.atk.SlotInfo,self.def.SlotInfo,nil,self.resultType)
    bcall, self.animation,self.reportEXT = xpcall(function() return convertBattleReportToAnimationSub(reportT,self.atk.SlotInfo,self.def.SlotInfo,nil,self.resultType) end,__G_TRACKBACK__)
    self.animation = self.animation or {}
    self:makePos()

    ui.itemcache:saveAttachs()

    self.actionStep = 0

    battleScene:initGeneral("atk")
    battleScene:initGeneral("def")

    if self.topposY < 1720 then
        self.bgcontrolitem["petatk"]:setScale(0.7)
        self.bgcontrolitem["petdef"]:setScale(0.7)

        self.bgcontrolitem["petatk"]:setPositionY(self.bgcontrolitem["petatk"]:getPositionY() + 50)
        self.bgcontrolitem["petdef"]:setPositionY(self.bgcontrolitem["petdef"]:getPositionY() + 50)
    end
    

    local effectccb, effectitem = CCBReaderLoad("fight_bg/"..self.bgName.."_bg", nil, true, "fight_bg")
    effectccb:setPosition(ccp(540,960))
    self.rootNode:addChild(effectccb,9000)

    if self.resultType == "copyhades" then
        local effectccb2, effectitem2 = CCBReaderLoad("UIEffect/diyueffect/diyueffectbg", nil, true, "diyueffectbg")
        effectccb2:setPosition(ccp(0,0))
        self.rootNode:addChild(effectccb2,0)
    end    

    loading:battlePreLoading(bScene,"heimu2",function() self:startPlay() end)
    --self:startPlay()

    CCDirector:sharedDirector():pushScene(bScene)

    gamedata.music:BattleStart()
end

--游戏加速
function battleScene.initGMSpeedFunction(self)
    self.gmSpeedccb, self.gmSpeeditem = CCBReaderLoad("backGround/gmspeed_button", nil, true, "gmspeed_button")
    self.gmSpeedccb:setPosition(ccp(0,0))
    self.gmSpeedccb:setScale(self.scaleNum)
    bScene:addChild(self.gmSpeedccb)

    self.gmSpeeditem.gmsp_spr:setOpacity(150)
    self.gmSpeeditem.gmspnode:setPosition(ccp((self.d_viewSize.width/self.scaleNum) - (self.gmSpeeditem.gmspnode:getContentSize().width/2), (self.d_viewSize.height/self.scaleNum)/3-170))

    self.gmSpeeditem.gmsp_btn:setTouchPriority(gameConfig.touchPriority.battleScene - 20)
    -- self.gmSpeeditem.gmsp_btn:setSwallowsTouch(true)
    self.gmSpeeditem.gmsp_btn:addHandleOfControlEvent(function()
        print("加速弹窗")
        if self.isGMSpeedMove then return end
        self.gmSpeedwidnowccb:setPositionX(self.d_viewSize.width/2)
        self.gmSpeeditem.gmspnode:setVisible(false)
    end,CCControlEventTouchUpInside)

    --设置速度弹窗
    self.gmSpeedwidnowccb, self.gmSpeedwidnowitem = CCBReaderLoad("GM/GMTool_Speed", nil, true, "GMTool_Speed")
    self.gmSpeedwidnowccb:setScale(self.scaleNum)
    self.gmSpeedwidnowccb:setPosition(ccp(self.d_viewSize.width*2,self.d_viewSize.height/2))
    bScene:addChild(self.gmSpeedwidnowccb)

    local numstr = CCUserDefault:sharedUserDefault():getStringForKey("gmspeednum"..GameScene.roleinfo.id)
    local speed = 1
    if numstr and numstr ~= "" then
        speed = tonumber(numstr)
    end
    local stopOff = CCUserDefault:sharedUserDefault():getIntegerForKey("gmspeedstate"..GameScene.roleinfo.id)
    self.gmSpeedwidnowitem.speedPointer:setPositionX(-158+((speed-1)*2)*62)
    self.gmSpeedwidnowitem.speedStr:setString(((speed-0.5)*2).."倍")
    if stopOff == 1 then
        self.gmSpeedwidnowitem.stopLab:setString("开启")
    end

    self.gmSpeedwidnowitem.closeBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 20)
    self.gmSpeedwidnowitem.closeBtn:addHandleOfControlEvent(function()
        self.gmSpeedwidnowccb:setPositionX(self.d_viewSize.width*2)
        self.gmSpeeditem.gmspnode:setVisible(true)
    end,CCControlEventTouchUpInside)

    --加速
    self.gmSpeedwidnowitem.addBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 20)
    self.gmSpeedwidnowitem.addBtn:addHandleOfControlEvent(function()
        local numstr = CCUserDefault:sharedUserDefault():getStringForKey("gmspeednum"..GameScene.roleinfo.id)
        local speed = 1
        if numstr and numstr ~= "" then
            speed = tonumber(numstr)
        end
        local nowSpeed = (speed-0.5)*2
        
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
            self:setGMSpeed(0.5)
        else
            if nowSpeed ~= tonumber(config[tostring(table.getTableLength(config))].times) then
                runGamePrompt({msg = "开启"..config[tostring(index+1)].times.."倍加速需要队伍等级达到"..config[tostring(index+1)].level.."级"})
            end
        end
    end, CCControlEventTouchUpInside)
    
    --减速
    self.gmSpeedwidnowitem.redBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 20)
    self.gmSpeedwidnowitem.redBtn:addHandleOfControlEvent(function()
        self:setGMSpeed(-0.5)
    end, CCControlEventTouchUpInside)
    
    --暂停
    self.gmSpeedwidnowitem.stopBtn:setTouchPriority(gameConfig.touchPriority.battleScene - 20)
    self.gmSpeedwidnowitem.stopBtn:addHandleOfControlEvent(function()
        local stopOff = CCUserDefault:sharedUserDefault():getIntegerForKey("gmspeedstate"..GameScene.roleinfo.id)
        local str = "暂停"
        if stopOff == 0 then
            stopOff = 1
            str = "开启"
            CCDirector:sharedDirector():getScheduler():setTimeScale(self.speedconfig[self.speedstep])
        else
            stopOff = 0
            str = "暂停"
            local numstr = CCUserDefault:sharedUserDefault():getStringForKey("gmspeednum"..GameScene.roleinfo.id)
            local speed = 1
            if numstr and numstr ~= "" then
                speed = tonumber(numstr)
            end
            CCDirector:sharedDirector():getScheduler():setTimeScale(self.speedconfig[self.speedstep]+(speed-1))
        end
        self.gmSpeedwidnowitem.stopLab:setString(str)
        CCUserDefault:sharedUserDefault():setIntegerForKey("gmspeedstate"..GameScene.roleinfo.id, stopOff)
    end, CCControlEventTouchUpInside)

end

function battleScene.setGMSpeed(self,num)
    local numstr = CCUserDefault:sharedUserDefault():getStringForKey("gmspeednum"..GameScene.roleinfo.id)
    local speed = 1
    if numstr and numstr ~= "" then
        speed = tonumber(numstr)
    end
    local stopOff = CCUserDefault:sharedUserDefault():getIntegerForKey("gmspeedstate"..GameScene.roleinfo.id)

    speed = speed + num
    if speed >= 5.5 then
        speed = 5.5
    end
    if speed <= 1 then
        speed = 1
    end

    self.gmSpeedwidnowitem.speedPointer:setPositionX(-158+((speed-1)*2)*62)
    self.gmSpeedwidnowitem.speedStr:setString(((speed-0.5)*2).."倍")
    if stopOff == 0 then
        CCDirector:sharedDirector():getScheduler():setTimeScale(self.speedconfig[self.speedstep]+(speed-1))
    end
    CCUserDefault:sharedUserDefault():setStringForKey("gmspeednum"..GameScene.roleinfo.id, tostring(speed))
end

function battleScene.initAtifactEffectShow(self)
    if GameScene.roleinfo and GameScene.roleinfo.id then 
        local _str = CCUserDefault:sharedUserDefault():getStringForKey("useBattleEffect"..GameScene.roleinfo.id)
        self.isUseEffect = false
        
        if _str == "" or _str == "0" then
            self.isUseEffect = false
        else
            self.isUseEffect = true
        end
    else
        self.isUseEffect = false
    end
end

function battleScene.initShieldEffectShow(self)
    if GameScene.roleinfo and GameScene.roleinfo.id then 
        local _str = CCUserDefault:sharedUserDefault():getStringForKey("useBattleEffect2"..GameScene.roleinfo.id)
        self.isUseEffect2 = false
        
        if _str == "" or _str == "0" then
            self.isUseEffect2 = false
        else
            self.isUseEffect2 = true
        end
    else
        self.isUseEffect2 = false
    end
end

function battleScene.initSkillAndCombSkillShow(self)
    if GameScene.roleinfo and GameScene.roleinfo.id then 
        local _str = CCUserDefault:sharedUserDefault():getStringForKey("useBattleEffect3"..GameScene.roleinfo.id)
        self.isUseEffect3 = false
        
        if _str == "" or _str == "0" then
            self.isUseEffect3 = false
        else
            self.isUseEffect3 = true
        end
    else
        self.isUseEffect3 = false
    end
end

function battleScene.initUseSelectBtn(self)
    if (gameConfig:checkBuildOpen(366) and GameScene:checkopenlevelbyId(366,true)) then
        self.rounditem["useSelectNode"]:setVisible(true)
    else
        self.rounditem["useSelectNode"]:setVisible(false)
        return
    end
        
    ui.setLabelString(self.rounditem["useEffectTxt"], gameConfig.strings:string_common("battleScene", 21), 19)
    
    self.rounditem["isUseEffectSelect"]:setVisible(self.isUseEffect)

    local _cb = function()
        self.isUseEffect = not self.isUseEffect
        
        local _str1 = "0"

        if self.isUseEffect then
            _str1 = "1"
        end

        self.rounditem["isUseEffectSelect"]:setVisible(self.isUseEffect)

        for k,v in pairs(self.atk.general) do
            if v.a_skeleton then
                local _effect = v.a_skeleton.root or v.a_skeleton
                _effect:setVisible(not self.isUseEffect)
            end

            if v.coveritem and v.coveritem.shieldNode then
                local _shieldEffect = v.coveritem.shieldNode
                _shieldEffect:setVisible(not self.isUseEffect)
            end
        end

        for k,v in pairs(self.def.general) do
            if v.a_skeleton then
                local _effect = v.a_skeleton.root or v.a_skeleton
                _effect:setVisible(not self.isUseEffect)
            end

            if v.coveritem and v.coveritem.shieldNode then
                local _shieldEffect = v.coveritem.shieldNode
                _shieldEffect:setVisible(not self.isUseEffect)
            end
        end

        if GameScene.roleinfo and GameScene.roleinfo.id then
            CCUserDefault:sharedUserDefault():setStringForKey("useBattleEffect"..GameScene.roleinfo.id, _str1)
        end
    end

    ui.commonBtn(self, self.rounditem, "useSelectBtn", _cb, -500)
end

function battleScene.initUseSelectBtn2(self)
    if (gameConfig:checkBuildOpen(366) and GameScene:checkopenlevelbyId(366,true)) then
        self.rounditem["useSelectNode2"]:setVisible(true)
    else
        self.rounditem["useSelectNode2"]:setVisible(false)
        return
    end
        
    ui.setLabelString(self.rounditem["useEffectTxt2"], gameConfig.strings:string_common("battleScene", 27), 19)
    
    self.rounditem["isUseEffectSelect2"]:setVisible(self.isUseEffect2)

    local _cb = function()
        self.isUseEffect2 = not self.isUseEffect2
        
        local _str1 = "0"

        if self.isUseEffect2 then
            _str1 = "1"
        end

        self.rounditem["isUseEffectSelect2"]:setVisible(self.isUseEffect2)

        for k,v in pairs(self.atk.general) do
            if v.coveritem and v.coveritem.shieldNode then
                local _shieldEffect = v.coveritem.shieldNode
                _shieldEffect:setVisible(not self.isUseEffect2)
            end
        end

        for k,v in pairs(self.def.general) do
            if v.coveritem and v.coveritem.shieldNode then
                local _shieldEffect = v.coveritem.shieldNode
                _shieldEffect:setVisible(not self.isUseEffect2)
            end
        end

        if GameScene.roleinfo and GameScene.roleinfo.id then
            CCUserDefault:sharedUserDefault():setStringForKey("useBattleEffect2"..GameScene.roleinfo.id, _str1)
        end
    end

    ui.commonBtn(self, self.rounditem, "useSelectBtn2", _cb, -500)
end

function battleScene.initUseSelectBtn3(self)
    if (gameConfig:checkBuildOpen(366) and GameScene:checkopenlevelbyId(366,true)) then
        self.rounditem["useSelectNode3"]:setVisible(true)
    else
        self.rounditem["useSelectNode3"]:setVisible(false)
        return
    end
        
    ui.setLabelString(self.rounditem["useEffectTxt3"], gameConfig.strings:string_common("battleScene", 28), 19)
    
    self.rounditem["isUseEffectSelect3"]:setVisible(self.isUseEffect3)

    local _cb = function()
        self.isUseEffect3 = not self.isUseEffect3
        
        local _str1 = "0"

        if self.isUseEffect3 then
            _str1 = "1"
        end

        self.rounditem["isUseEffectSelect3"]:setVisible(self.isUseEffect3)

        if GameScene.roleinfo and GameScene.roleinfo.id then
            CCUserDefault:sharedUserDefault():setStringForKey("useBattleEffect3"..GameScene.roleinfo.id, _str1)
        end
    end

    ui.commonBtn(self, self.rounditem, "useSelectBtn3", _cb, -500)
end

function battleScene.battleStatisticsDamage(self,report)
    
    if report and next(report) then
        if report.battle and next(report.battle) then
            if report.battle.action and next(report.battle.action) then
                local battleReport = report.battle.action
                local actionNum = table.getTableLength(report.battle.action)
                for i=1,actionNum do   
                    if battleReport[i] and battleReport[i].source and next(battleReport[i].source) then
                        local soureceTab = battleReport[i].source
                        local damagePoint = 0
                        if soureceTab.pos[1] then
                            damagePoint = soureceTab.pos[1]
                        end
                        if soureceTab.type == "comb" then
                            if battleReport[i].dest and next(battleReport[i].dest) then
                                for pp,qq in pairs(battleReport[i].dest) do
                                    if qq.direct == soureceTab.direct and qq.ap == 0 then
                                        for pp2,qq2 in pairs(soureceTab.pos) do
                                            if qq.pos == qq2 then
                                                damagePoint = qq.pos
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        if not soureceTab.direct then
                            if self.def.SlotInfo[tostring(damagePoint)] then

                                if not self.def.SlotInfo[tostring(damagePoint)].blowDamage then
                                    self.def.SlotInfo[tostring(damagePoint)].blowDamage = 0
                                end
                                if battleReport[i].dest and next(battleReport[i].dest) then
                                    for kk,vv in pairs(battleReport[i].dest) do
                                        if not not vv.direct then
                                            if vv.damage and vv.damage.damage and vv.damage.damage > 0 then
                                                if vv.damage.status and string.find(vv.damage.status,"dead") then
                                                    if self.atk.SlotInfo[tostring(vv.pos)] and next(self.atk.SlotInfo[tostring(vv.pos)]) then
                                                        if self.atk.SlotInfo[tostring(vv.pos)].laveHp then
                                                        
                                                        else
                                                            if self.atk.SlotInfo[tostring(vv.pos)].hp and self.atk.SlotInfo[tostring(vv.pos)].hp > 0 then
                                                                self.atk.SlotInfo[tostring(vv.pos)].laveHp = self.atk.SlotInfo[tostring(vv.pos)].hp 
                                                            else
                                                                self.atk.SlotInfo[tostring(vv.pos)].laveHp = 0
                                                            end
                                                        end

                                                        if vv.damage.damage > (self.atk.SlotInfo[tostring(vv.pos)].laveHp) then
                                                            self.def.SlotInfo[tostring(damagePoint)].blowDamage = self.def.SlotInfo[tostring(damagePoint)].blowDamage + self.atk.SlotInfo[tostring(vv.pos)].laveHp
                                                        else
                                                            self.def.SlotInfo[tostring(damagePoint)].blowDamage = self.def.SlotInfo[tostring(damagePoint)].blowDamage + vv.damage.damage
                                                        end
                                                    end
                                                else
                                                    self.def.SlotInfo[tostring(damagePoint)].blowDamage = self.def.SlotInfo[tostring(damagePoint)].blowDamage + vv.damage.damage
                                                end
                                            end
                                            if vv.damage and vv.damage.damage2 and vv.damage.damage2 > 0 then
                                                self.def.SlotInfo[tostring(damagePoint)].blowDamage = self.def.SlotInfo[tostring(damagePoint)].blowDamage + vv.damage.damage2
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            if self.atk.SlotInfo[tostring(damagePoint)] then
                                if not self.atk.SlotInfo[tostring(damagePoint)].blowDamage then
                                    self.atk.SlotInfo[tostring(damagePoint)].blowDamage = 0
                                end
                                if battleReport[i].dest and next(battleReport[i].dest) then
                                    for kk,vv in pairs(battleReport[i].dest) do
                                        if not vv.direct then
                                            if vv.damage and vv.damage.damage and vv.damage.damage > 0 then
                                                if vv.damage.status and string.find(vv.damage.status,"dead") then
                                                    if self.def.SlotInfo[tostring(vv.pos)] and next(self.def.SlotInfo[tostring(vv.pos)]) then
                                                        if self.def.SlotInfo[tostring(vv.pos)].laveHp then
                                                        
                                                        else
                                                            if self.def.SlotInfo[tostring(vv.pos)].hp and self.def.SlotInfo[tostring(vv.pos)].hp > 0 then
                                                                self.def.SlotInfo[tostring(vv.pos)].laveHp = self.def.SlotInfo[tostring(vv.pos)].hp 
                                                            else
                                                                self.def.SlotInfo[tostring(vv.pos)].laveHp = 0
                                                            end
                                                        end

                                                        if vv.damage.damage > self.def.SlotInfo[tostring(vv.pos)].laveHp then
                                                            self.atk.SlotInfo[tostring(damagePoint)].blowDamage = self.atk.SlotInfo[tostring(damagePoint)].blowDamage + self.def.SlotInfo[tostring(vv.pos)].laveHp
                                                        else
                                                            self.atk.SlotInfo[tostring(damagePoint)].blowDamage = self.atk.SlotInfo[tostring(damagePoint)].blowDamage + vv.damage.damage
                                                        end
                                                    end
                                                else
                                                    self.atk.SlotInfo[tostring(damagePoint)].blowDamage = self.atk.SlotInfo[tostring(damagePoint)].blowDamage + vv.damage.damage
                                                end
                                            end
                                            if vv.damage and vv.damage.damage2 and vv.damage.damage2 > 0 then
                                                self.atk.SlotInfo[tostring(damagePoint)].blowDamage = self.atk.SlotInfo[tostring(damagePoint)].blowDamage + vv.damage.damage2
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if battleReport[i] and battleReport[i].dest and next(battleReport[i].dest) then
                        for kk,vv in pairs(battleReport[i].dest) do
                            if not vv.direct then
                                if self.def.SlotInfo[tostring(vv.pos)] and next(self.def.SlotInfo[tostring(vv.pos)]) then
                                    if self.def.SlotInfo[tostring(vv.pos)] and self.def.SlotInfo[tostring(vv.pos)].laveHp then
                                        
                                    else
                                        if self.def.SlotInfo[tostring(vv.pos)].hp and self.def.SlotInfo[tostring(vv.pos)].hp > 0 then
                                            self.def.SlotInfo[tostring(vv.pos)].laveHp = self.def.SlotInfo[tostring(vv.pos)].hp 
                                        else
                                            self.def.SlotInfo[tostring(vv.pos)].laveHp = 0
                                        end
                                    end
                                    if vv.damage and vv.damage.damage then
                                        if vv.damage.damage > 0 then
                                            self.def.SlotInfo[tostring(vv.pos)].laveHp = self.def.SlotInfo[tostring(vv.pos)].laveHp - vv.damage.damage
                                        else
                                            if self.def.SlotInfo[tostring(vv.pos)].cureHp then
                                
                                            else
                                                self.def.SlotInfo[tostring(vv.pos)].cureHp = 0
                                            end 
                                            self.def.SlotInfo[tostring(vv.pos)].cureHp = self.def.SlotInfo[tostring(vv.pos)].cureHp + math.abs(vv.damage.damage)

                                            self.def.SlotInfo[tostring(vv.pos)].laveHp = self.def.SlotInfo[tostring(vv.pos)].laveHp + math.abs(vv.damage.damage)
                                        end
                                    end

                                    if self.def.SlotInfo[tostring(vv.pos)].laveHp < 0 then
                                        self.def.SlotInfo[tostring(vv.pos)].laveHp = 0
                                    end
                                end
                            else
                                if self.atk.SlotInfo[tostring(vv.pos)] and next(self.atk.SlotInfo[tostring(vv.pos)]) then
                                    if self.atk.SlotInfo[tostring(vv.pos)] and self.atk.SlotInfo[tostring(vv.pos)].laveHp then
                                        
                                    else
                                        if self.atk.SlotInfo[tostring(vv.pos)].hp and self.atk.SlotInfo[tostring(vv.pos)].hp > 0 then
                                            self.atk.SlotInfo[tostring(vv.pos)].laveHp = self.atk.SlotInfo[tostring(vv.pos)].hp 
                                        else
                                            self.atk.SlotInfo[tostring(vv.pos)].laveHp = 0
                                        end
                                    end

                                    if vv.damage and vv.damage.damage then
                                        if vv.damage.damage > 0 then
                                            self.atk.SlotInfo[tostring(vv.pos)].laveHp = self.atk.SlotInfo[tostring(vv.pos)].laveHp - vv.damage.damage
                                        else
                                            if self.atk.SlotInfo[tostring(vv.pos)].cureHp then
                                
                                            else
                                                self.atk.SlotInfo[tostring(vv.pos)].cureHp = 0
                                            end 
                                            self.atk.SlotInfo[tostring(vv.pos)].cureHp = self.atk.SlotInfo[tostring(vv.pos)].cureHp + math.abs(vv.damage.damage)

                                            self.atk.SlotInfo[tostring(vv.pos)].laveHp = self.atk.SlotInfo[tostring(vv.pos)].laveHp + math.abs(vv.damage.damage)
                                        end
                                    end

                                    if self.atk.SlotInfo[tostring(vv.pos)].laveHp < 0 then
                                        self.atk.SlotInfo[tostring(vv.pos)].laveHp = 0
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        return
    end
end

function battleScene.setSpeedEnabled(self,bool,type)
    if self.isSpeedEnabled  == bool then return end

    self.isSpeedEnabled = bool

    if type and type == "guide" then
     --   self.bgcontrolitem.speedButton:setTouchPriority(gameConfig.touchPriority.guide-10)
        self.bgcontrolitem.speedButton:setEnabled(true)
        self.bgcontrolitem.speedButton:addHandleOfControlEvent(function()
            runGamePrompt({msg = "引导过程中无法加速或跳过"})
            --runGamePrompt({msg = gameConfig.strings:string_common("battleScene",9)})
        end,CCControlEventTouchUpInside)
    else
        self.bgcontrolitem.speedButton:setEnabled(bool)
        self.bgcontrolitem.speedButton:addHandleOfControlEvent(function()
            self:setSpeed(self.speedstep+1,true)
        end,CCControlEventTouchUpInside)
    end

    if not bool then
        self.savedSpeed = self.speedstep
        self:setSpeed(1)
    else
        self:setSpeed(self.savedSpeed or 1)
    end

    if bool then
        ui.removeGray("CCSprite",self.speeditem.speedSprite)
        ui.removeGray("CCSprite",self.speeditem.speedsp1)
        ui.removeGray("CCSprite",self.speeditem.speedsp2)
    else
        ui.addGray("CCSprite",self.speeditem.speedSprite)
        ui.addGray("CCSprite",self.speeditem.speedsp1)
        ui.addGray("CCSprite",self.speeditem.speedsp2)
    end

end

function battleScene.startPlay(self,isreplay)

    if isreplay then
        battleScene:initGeneral("atk")
        battleScene:initGeneral("def")
        local effectccb, effectitem = CCBReaderLoad("fight_bg/"..self.bgName.."_bg", nil, true, "fight_bg")
        effectccb:setPosition(ccp(540,960))
        self.rootNode:addChild(effectccb,9000)
    end


    local callback = function() self:playstart() end
    local callback1 = function() self:monsterEnter(callback) end

    if next(self.vs) then
        gameWindows:openWindow("battleVs",self.vs,function() self:petEnter(callback1) end)
    else
        self:petEnter(callback1)
    end
end

function battleScene.petEnter( self,callback)
    local defcb = function()
        if self.def.general["0"] then
            self.def.general["0"]:enter(callback)
        else
            callback()
        end
    end
    
    if self.atk.general["0"] then
        self.atk.general["0"]:enter(defcb)
    else
        defcb()
    end
end

function battleScene.monsterEnter(self,callback)

    if self.needenterMonster and next(self.needenterMonster) then
         for k,v in ipairs(self.needenterMonster) do
             v.rootNode:setVisible(true)
             v.skeleton:setAnimation("move",false,0)
             v.skeleton:addAnimation("stand",true,0,0)
         end

         self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2), CCCallFunc:create(function()
             callback()
         end)))

         self.battleinfoccb, self.battleinfoitem = CCBReaderLoad("backGround/battleinfo", nil, true, "battleinfo")
         self.battleinfoccb:setScale(self.scaleNum)
         self.battleinfoccb:setPosition(ccp(gamedata.device.SCREEN_WIDTH/2-540*self.scaleNum, 800*self.scaleNum+(gameConfig.fixH or 0)))
         self.rootLayer:addChild(self.battleinfoccb)
         self:setBattleInfo({
             round = "1/"..self.totalround,
             damage = "0%",
             des = gameConfig.strings:string_common("battleScene",16),
         })

    else
        callback()
    end

end

function battleScene.playSoulSlot(self,index,callback)
    if not gameConfig:checkBuildOpen(198) or not GameScene:checkopenlevelbyId(198,true) or not self.slots[index] then callback() return end

    if self.slots[index].slotnameatk ~= "" or self.slots[index].slotnamedef ~= "" then
        gameWindows:openWindow("battleSlot",self.slots[index],callback)
    else
        callback()
    end
end

function battleScene.playstart(self)
    local isendactivity =  self.bgcontrolitem.endButton:isEnabled()
    self.bgcontrolitem.endButton:setEnabled(false)

    self.bgcontrolanimationManager:setAnimationCompletedCallback(function()

        for k,v in pairs(self["atk"].general) do
            if v.ccb and not v.isdead then
                v.ccb:setVisible(true)
                if v.coverccb then
                    v.coverccb:setVisible(true)
                end
            end
        end
        for k,v in pairs(self["def"].general) do
            if v.ccb and not v.isdead then
                v.ccb:setVisible(true)
                if v.coverccb then
                    v.coverccb:setVisible(true)
                end
            end
        end

        self:playSoulSlot(1,function()
            self:playScope()
        end)

        self.bgcontrolitem.endButton:setEnabled(isendactivity)
    end)
    self.bgcontrolanimationManager:runAnimationsForSequenceNamed("start")
    self.bganimationManager:runAnimationsForSequenceNamed("shakecontrol")
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.7), CCCallFunc:create(function() self:autoScale() end))
    self.bgitem.autoscalenode:runAction(sequence)
end

function battleScene.playScope( self )
    local hasScope = false

    for k,v in pairs(self["atk"].general) do
        hasScope = v:scopeEffect() or hasScope
    end
    for k,v in pairs(self["def"].general) do
        hasScope = v:scopeEffect() or hasScope
    end

    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(hasScope and 1.2 or 0), 
        CCCallFunc:create(function() 
            self.actionStep = 0
            self:palyNextAction() 
        end))
    self.animationNode:runAction(sequence)
end

function battleScene.continuePlay(self,report)
    local reportT = self:makeReport(report)
    self.animation = convertBattleReportToAnimationSub(reportT,self.atk.SlotInfo,self.def.SlotInfo,self.animation)
    self:palyNextAction()
end

function battleScene.palyNameChangeAction(self)
    local action = self.animation[self.actionStep]
    local dir = action.direct and "atk" or "def"
    self.bgcontrolitem[dir.."_name"]:setString(self[dir.."name"][action.index])
    self:palyNextAction()
end

function battleScene.palystarAnimationAction(self,action)
    local action = self.animation[self.actionStep]
    self.bgcontrolanimationManager:setAnimationCompletedCallback(function()
        self:playSoulSlot(action.index or 2,function()
            self:palyNextAction()
        end)
    end)
    self.bgcontrolanimationManager:runAnimationsForSequenceNamed("start")
    self.bganimationManager:runAnimationsForSequenceNamed("shakecontrol")
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.7), CCCallFunc:create(function() self:autoScale() end))
    self.bgitem.autoscalenode:runAction(sequence)
end

function battleScene.playRoundAction(self)
    local action = self.animation[self.actionStep]
    if not self.roundccb then
        local timeCB ={}
        timeCB["change"] = function()
            print("round change = ",self.animation[self.actionStep].round)
            setSpriteFrameByName(self.rounditem.round,"huihe_"..self.animation[self.actionStep].round)
            --
            print("回合 = ",self.animation[self.actionStep].round)
            if self.animation[self.actionStep].round >= 4 then
                ui.removeGray("CCControlButton",self.bgcontrolitem.endButton)
                self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
                    self:endfunction()
                end,CCControlEventTouchUpInside)
            end
        end
        self.roundccb,self.rounditem = CCBReaderLoad("UIEffect/huihe/huihe", nil, true, "huihe", timeCB)
        self.bgcontrolitem.roundnode:addChild(self.roundccb)

        if self.resultType ~= "sendaiBattle" then
            self:initUseSelectBtn()
            self:initUseSelectBtn2()
            -- self:initUseSelectBtn3()
        end

        if self.topposY < 1720 then
            self.roundccb:setScale(0.6)
        end

    end

    local animationManager = getAnimationManager(self.rounditem)
    animationManager:setAnimationCompletedCallback(function()
        for k,v in pairs(self["atk"].general) do
            v:roundbegin(action.round)
        end
        for k,v in pairs(self["def"].general) do
            v:roundbegin(action.round)
        end        
        self:palyNextAction()
    end)
    if action.round == 1 then
        setSpriteFrameByName(self.rounditem.round,"huihe_1")
    end
    animationManager:runAnimationsForSequenceNamed(action.round == 1 and "huihe_kaichang" or "huihe_qiehuan")

    self:setBattleInfo({
        round = self.animation[self.actionStep].round.."/"..self.totalround
    })

    self:playRoundOpt(self.animation[self.actionStep].round)
end
function battleScene.playRoundOpt(self, round)
    if self.resultType == "encounter" then
        local skip = tonumber(gamedata.config.global_kv.encounter_skip_round.value) 
        if round < skip or skip == -1 then
            ui.addGray("CCControlButton",self.bgcontrolitem.endButton)
            self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
                if (skip == -1) then
                    runGamePrompt({msg = gameConfig.strings:string_common("battleScene", 18)})
                else
                    runGamePrompt({msg = string.format(gameConfig.strings:string_common("battleScene", 26), skip)})
                end
            end,CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",self.bgcontrolitem.endButton)
            self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
                self:endfunction()
            end,CCControlEventTouchUpInside)
        end
    end
end

function battleScene.mobaosha(self,action)
    self[action.postype].general[action.pos].frontNode:removeAllChildrenWithCleanup(true)
    self[action.postype].general[action.pos].SkeletonNode:setVisible(false)
    local ccb, ccbDocumentControler = CCBReaderLoad(action.dir.."/"..action.name, nil, true, action.name)
    local animationManager = getAnimationManager(ccbDocumentControler)
    animationManager:runAnimationsForSequenceNamed(action.name)
    ccb:setPosition(0,0)
    self.bgitem.fronteffect:addChild(ccb)

    self.hunanimationManager = animationManager

    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(2.7), CCCallFunc:create(function() self:palyNextAction() end))
    self.bgitem.fronteffect:runAction(sequence)

end

function battleScene.resetGeneral(self,action)
    local postype = action.direct and "atk" or "def"
    local s_general = self[postype].general[action.pos]
    s_general:reset(action.general)

    self:palyNextAction()
end

function battleScene.hundisappear(self,action)
    if self.hunanimationManager then
        self.hunanimationManager:runAnimationsForSequenceNamed(action.name)
    end
    self:palyNextAction()
end

function battleScene.palyNextAction(self,step)
    self:removeDamageTotal()
    self:hideSource()
    if self.isend then return end

    if self.auto then
        self.actionStep = self.actionStep +1
    elseif step then
    else
        return
    end

    local action =  self.animation[self.actionStep]

    if self.speedresumestep and self.actionStep > self.speedresumestep then
        self:setSpeedEnabled(true)
    end


    if not action then
        self.isend = true
        self:showResult()
        return
    end
    print("play battle action  ", self.actionStep)

    if action.type == "battle" then
        self:palybattleAction()
    elseif action.type == "talk" then
        self:palyTalkAction()
    elseif action.type == "pos" then
        self:palyPosAction()
    elseif action.type == "namechange" then
        self:palyNameChangeAction()
    elseif action.type == "starAnimation" then
        self:palystarAnimationAction(action)
    elseif action.type == "roundbegin" then
        self:playRoundAction()
    elseif action.type == "mobaoshaxuli" then
        self[action.postype].general[action.pos]:mobaoshaxuli(action,self)
    elseif action.type == "mobaosha" then
        self:mobaosha(action)
    elseif action.type == "hundisappear" then
        self:hundisappear(action)
    elseif action.type == "resetGeneral" then
        self:resetGeneral(action)
    end
end


function battleScene.replay(self)
    self.isend = false

    for k,v in pairs(self["atk"].general) do
        v:removeAllStatus()
    end
    for k,v in pairs(self["def"].general) do
        v:removeAllStatus()
    end
    ui.itemcache:detachAllSkeletons()

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.resultproflayer:removeFromParentAndCleanup(true)
    self.resultproflayer = nil
    self.resultNode:removeFromParentAndCleanup(true)
    self.resultNode= nil

    if self.atkbloodbar then 
        self.atkbloodbar:removeFromParentAndCleanup(true)
        self.atkbloodbar = nil
    end
    if self.defbloodbar then
        self.defbloodbar:removeFromParentAndCleanup(true)
        self.defbloodbar = nil
    end
    
    self.skillblack = nil
    self.source = nil

    if self.roundccb then
        self.roundccb:removeFromParentAndCleanup(true)
        self.roundccb = nil
        self.rounditem = nil
    end

    self.atk.general = {}
    self.def.general = {}

    self.bgcontrolitem.endButton:setEnabled(true)

    self:startPlay(true)

    ui.removeGray("CCControlButton",self.bgcontrolitem.endButton)
    self.bgcontrolitem.endButton:addHandleOfControlEvent(function()
        self:endfunction()
    end,CCControlEventTouchUpInside)
end

function battleScene.endfunction(self)
    if self.isend then return end

    if self.bgitem.commonnode then
        self.bgitem.commonnode:stopAllActions()
    end
    self.shakeanimationNode:stopAllActions()
    self.animationNode:stopAllActions()
    self.rootNode:stopAllActions()
    self.rootNode:setScale(1)
    self.rootNode:setPosition(0,0)
    if self.texie_skeleton then
        self.texie_skeleton:removeFromParentAndCleanup(true)
        self.texie_skeleton = nil
    end

    self.bgitem.backeffect:removeAllChildrenWithCleanup(true)
    self.bgitem.fronteffect:removeAllChildrenWithCleanup(true)
    self.bgitem.commonnode:removeAllChildrenWithCleanup(true)

    for k,v in pairs(self["atk"].general) do
        v:stopAllEffect()
    end
    for k,v in pairs(self["def"].general) do
        v:stopAllEffect()
    end

    local ccb, item = CCBReaderLoad("backGround/tiaoguo", nil, true, "tiaoguo")
    ccb:setPosition(0,0)
    self.bgcontrolitem.tiaoguonode:addChild(ccb,1999)
    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("tiaoguo")
    self:shake("shake_tiaoguo")

    self.isend = true
    self:infotoend()
    self:showResult()
    self.bgcontrolitem.endButton:setEnabled(false)
end

function battleScene.infotoendOne( self,postype,pos )
    local s_info = self[postype].initSlotInfo[pos]
    local e_info = self.reportEXT.endinfo[postype][pos]
    local s_general = self[postype].general[pos]
    if pos==0 or pos=="0" then
    else
        if s_general then
            if s_info and e_info then
                if s_info.id == e_info.id then
                    s_general:reset(e_info)
                else
                    ui.itemcache:detachskeleton(s_info.animation.name,s_general.skeleton)
                    s_general.rootNode:removeFromParentAndCleanup(true)
                    self[postype].general[pos] = nil
    
                    local position = self[postype].posTable[tonumber(pos)]
                    self[postype].general[pos] = generaMeta.init(self,self.rootNode,e_info,postype,position,self)
                    self[postype].general[pos].ccb:setVisible(true)
                    if self[postype].general[pos].coverccb then
                        self[postype].general[pos].coverccb:setVisible(true)
                    end  
                end
            elseif s_info then
                ui.itemcache:detachskeleton(s_info.animation.name,s_general.skeleton)
                s_general.rootNode:removeFromParentAndCleanup(true)
                self[postype].general[pos] = nil
            elseif e_info then
                local position = self[postype].posTable[tonumber(pos)]
                self[postype].general[pos] = generaMeta.init(self,self.rootNode,e_info,postype,position,self)
                self[postype].general[pos].ccb:setVisible(true)
                if self[postype].general[pos].coverccb then
                    self[postype].general[pos].coverccb:setVisible(true)
                end            
            end
        end
    end
end

function battleScene.resetBloodTotal(self, pos,SlotInfo )
    self[pos.."hp"] =0
    self[pos.."hptotal"] =0
    self[pos.."stardisappear"] = {true,true,true}

    for k,v in pairs(SlotInfo) do
        if k==0 or k=="0" then
        else
            self[pos.."hp"] = self[pos.."hp"] + v.hp
            self[pos.."hptotal"] = self[pos.."hptotal"] + v.hp2
        end
    end
    
    self[pos.."bloodbar"]:stopAllActions()
    self[pos.."bloodbar"]:setPercentage(100*self[pos.."hp"]/self[pos.."hptotal"])
    self:setBloodstar(pos)
end

function battleScene.infotoend( self )
    if self.reportEXT.endinfo and self.resultType~="story" and self.resultType~="skillview" then

        for k, v in pairs(self.slotpos) do
            print("jkp-v = ",v)
            if v and tonumber(v) > 0 then
                self:infotoendOne("atk",v)
                self:infotoendOne("def",v)
            end
        end

        self:resetBloodTotal("atk",self.reportEXT.endinfo["atk"])
        self:resetBloodTotal("def",self.reportEXT.endinfo["def"])

        if self.roundccb and self.reportEXT.endinfo.round then
            setSpriteFrameByName(self.rounditem.round,"huihe_"..self.reportEXT.endinfo.round)
        end
    end
end

function battleScene.clear(self)
    --设置速度
    local speednum = 1
    local stopOff = 0
    if GameScene.roleinfo and GameScene.roleinfo.id then
        local numstr = CCUserDefault:sharedUserDefault():getStringForKey("gmspeednum"..GameScene.roleinfo.id)
        if numstr and numstr ~= "" then
            speednum = tonumber(numstr)
        end
        stopOff = CCUserDefault:sharedUserDefault():getIntegerForKey("gmspeedstate"..GameScene.roleinfo.id)
    end
    if stopOff == 0 then
        CCDirector:sharedDirector():getScheduler():setTimeScale(speednum)
    else
        CCDirector:sharedDirector():getScheduler():setTimeScale(1)
    end
    -- CCDirector:sharedDirector():getScheduler():setTimeScale(1)

    if loading.netproflayer then
        loading.netopencallback= function() self:clear() end
        return
    end

    if guide.controller then
        guide.controller:UIComplete(8017)
        --guide:removeGuideLayer()
    end

    for k,v in pairs(self["atk"].general) do
        v:removeAllStatus()
    end
    for k,v in pairs(self["def"].general) do
        v:removeAllStatus()
    end
    ui.itemcache:detachAllSkeletons()
    ui.itemcache:resumAttachs()


    self.speedstep = self.savedSpeed or self.speedstep
    print("self.savedSpeed",self.savedSpeed,self.speedstep)

    clearPrompt()

    self.isend = false
    self.rootLayer:removeAllChildrenWithCleanup(true)
    self.rootLayer:removeFromParentAndCleanup(true)
    self.rootLayer = nil

    if self.gmSpeedccb then
        self.gmSpeedccb:removeAllChildrenWithCleanup(true)
        self.gmSpeedccb:removeFromParentAndCleanup(true)
        self.gmSpeedccb = nil
        self.gmSpeeditem = nil
    end

    if self.gmSpeedwidnowccb then
        self.gmSpeedwidnowccb:removeAllChildrenWithCleanup(true)
        self.gmSpeedwidnowccb:removeFromParentAndCleanup(true)
        self.gmSpeedwidnowccb = nil
        self.gmSpeedwidnowitem = nil
    end

    self.resultproflayer = nil
    self.resultNode= nil
    self.battleRoleInjuryNode = nil
    self.DamageTotalccb = nil
    self.DamageTotalitem = nil
    self.DamageTotalanimationManager = nil

    self.skillblack = nil
    self.source = nil

    self.roundccb = nil
    self.rounditem = nil
    self.battleinfoccb = nil
    self.battleinfoitem = nil

    self.atk.general = {}
    self.def.general = {}
    self.atk.SlotInfo = {}
    self.def.SlotInfo = {}
    self.atk.initSlotInfo = {}
    self.def.initSlotInfo = {}
    self.vs = {}
    self.battlereport = nil

    self.animation = nil
    self.speedresumestep = nil

    self.needenterMonster = nil

    self.touchButton = nil

    UPDATECACHE = 1
--    CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
--    CCTextureCache:sharedTextureCache():removeUnusedTextures()

    gamedata.music:BattleEnd()


    self.show = false

    CCDirector:sharedDirector():popScene()

    --bScene:removeAllChildrenWithCleanup(true)

    if self.callback then
        self.callback()
        self.callback = nil
    end

    if self.cacheresetCallBack then
        self.cacheresetCallBack()
        self.cacheresetCallBack = nil
    end
end

function battleScene.saveBattleSpeedToSqlite( self,speed )
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id

    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "UPDATE battlespeed SET speed=" .. speed .. " WHERE serverid ="..serverid
    mydb:exec(SQL)
    if mydb:changes() == 0 then
        SQL = string.format("INSERT INTO battlespeed (serverid,speed) VALUES (%d,%d)",serverid,speed)
        mydb:exec(SQL)
    end
    mydb:close()
end

function battleScene.getBattleSpeedFromSqlite( self )
    local speed = 1
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id

    local mydb = SQLite3Open()
    if nil == mydb then
        return 1
    end

    local SQL = "select count(*) as texist from sqlite_master where type='table' and name='battlespeed'"
    local ret = 0
    for row in mydb:nrows(SQL) do
        ret = row["texist"]
    end
    if ret == 0 then
        local SQL = "CREATE TABLE IF NOT EXISTS battlespeed (serverid INTEGER, speed INTEGER)";
        mydb:exec(SQL)

        return speed
    end


    local SQL = "SELECT * FROM battlespeed WHERE serverid="..serverid
    for row in mydb:rows(SQL) do
        speed = tonumber(row[2]) or speed
        break
    end
    mydb:close()

    return speed
end

return battleScene

�Y 