--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/13
-- Time: 下午4:46
-- To change this template use File | Settings | File Templates.
--

local function other(postype)
    return postype == "atk" and "def" or "atk"
end

local function getnewposition(self,parent,child,needturn)
    local oldpos = {x = child:getPositionX(),y = child:getPositionY() }
    local anchor = parent:getAnchorPoint()
    local size =  parent:getContentSize()

    return ccp(needturn and size.width*anchor.x - oldpos.x or oldpos.x-size.width*anchor.x, oldpos.y-size.height*anchor.y)
end

function petskill(battlescene,action)

    local source = action.sourceAnimation[1]
    local pet = battlescene[source.postype].general[source.pos]

    if pet.skeleton then
        pet:skillattack3()
        return
    end

    pet:skillattack2()

    local ccb, ccbDocumentControler = CCBReaderLoad("common/commonmochong", nil, true, "commonmochong")

    local config = gamedata.config.pet3_attr[tostring(pet.data.cid)]
    local mowang = gamedata.config.generalanimation[tostring(config[tostring(pet.data.level2)].animationid)].name

    local Gneral1 = CCSkeletonAnimation:create(mowang.."/"..mowang..".json",mowang.."/"..mowang..".atlas",1)
    Gneral1:setScale(1.0*(config[tostring(pet.data.level2)].scale or 1))
    ccbDocumentControler.pet:addChild(Gneral1)
    Gneral1:setAnimation("stand",true,0)

    if (mowang == "jinyankongquelongwang") or (mowang == "jinyankongquelongwang1") or (mowang == "jinyankongquelongwanghong") then
        ccbDocumentControler.pet:setScaleX(-1*ccbDocumentControler.pet:getScaleX())
    end

    local needturn = false
    if action.sourceAnimation[1].postype == "def" then
        ccb:setScaleX(-1)
        needturn = true
    end

    ccbDocumentControler.shandian:setRotation((battlescene.topposY - 1920)*13/300)
    ccb:setAnchorPoint(ccp(0.5,0))
    ccb:setPosition(ccp(0,0))
    battlescene.bgitem.commonnode:addChild(ccb,1999)

    Gneral1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.0), CCCallFunc:create(function()
        print("mochong skill ",action.sourceccbmodule.name)

        local path = CCFileUtils:sharedFileUtils():fullPathForFilename(action.sourceccbmodule.name.."/"..action.sourceccbmodule.name..".json")
        local skilljson = LoadJsonFileToTable(path)

        printT(skilljson)
        if skilljson.has01 then
            local sourceccb, sourceccbitem = CCBReaderLoad(action.sourceccbmodule.name.."/"..action.sourceccbmodule.name.."01", nil, true, action.sourceccbmodule.name)
            local animationManager = getAnimationManager(sourceccbitem)
            animationManager:runAnimationsForSequenceNamed(action.sourceccbmodule.name.."01")
            if sourceccbitem.topnode or sourceccbitem.bottomnode then
                if sourceccbitem.topnode then
                    sourceccbitem.topnode:removeFromParentAndCleanup(false)
                    ccbDocumentControler.petfront:addChild(sourceccbitem.topnode)
                    sourceccbitem.topnode:setPosition(getnewposition(sourceccb,sourceccbitem.topnode,needturn))
                end
                if sourceccbitem.bottomnode then
                    sourceccbitem.bottomnode:removeFromParentAndCleanup(false)
                    ccbDocumentControler.petback:addChild(sourceccbitem.bottomnode)
                    sourceccbitem.bottomnode:setPosition(getnewposition(sourceccb,sourceccbitem.bottomnode,needturn))
                end
            else
                sourceccb:setPosition(ccp(0,0))
                ccbDocumentControler.petfront:addChild(sourceccb)
            end
        end

        Gneral1:setAnimation("skill",true,0)
        Gneral1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2.0), CCCallFunc:create(function()
            Gneral1:setAnimation("stand",true,0)
        end)))
    end)))

    local animationManager = getAnimationManager(ccbDocumentControler)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("commonmochong")

    battlescene:shake("shake_mochong")
end

local function getThreeInonePosY( battlescene,action )
    local postotal = 0
    local destnum = 0

    for k,v in ipairs(action.destAnimation) do
        if v.animation.damage and next(v.animation.damage) then
            postotal=postotal + battlescene[v.postype].general[v.pos].pos.y
            destnum = destnum + 1
        end
    end
    if destnum == 0 then
        local source = action.sourceAnimation[1]
        return battlescene[source.postype].general[source.pos].pos.y
    else
        return postotal/destnum
    end
end

function threeInone(battlescene,action)
    local source = action.sourceAnimation[1]
    local posY = getThreeInonePosY(battlescene,action)

    local ccb, item = CCBReaderLoad(action.destccbmodule.name.."/"..action.destccbmodule.name.."02", nil, true, action.destccbmodule.name.."02")

    local needturn = (battlescene[source.postype].general[source.pos].direct == "def")

    if item.topnode or item.bottomnode then
        if item.topnode then
            item.topnode:removeFromParentAndCleanup(false)
            battlescene.bgitem.fronteffect:addChild(item.topnode)
            item.topnode:setPosition(ccp(needturn and -540 or 540,posY))
            if needturn then item.topnode:setScaleX(-1) end
        end
        if item.bottomnode then
            item.bottomnode:removeFromParentAndCleanup(false)
            battlescene.bgitem.backeffect:addChild(item.bottomnode)
            item.bottomnode:setPosition(ccp(needturn and -540 or 540,posY))
            if needturn then item.bottomnode:setScaleX(-1) end
        end
    else
        ccb:setPosition(ccp(needturn and -540 or 540,posY))
        battlescene.bgitem.fronteffect:addChild(ccb)
        if needturn then ccb:setScaleX(-1) end
    end

    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        if item.topnode then item.topnode:removeFromParentAndCleanup(true) end
        if item.bottomnode then item.bottomnode:removeFromParentAndCleanup(true) end
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed(action.destccbmodule.name.."02")
end

function threeInoneByindex(battlescene,action)
    local source = action.sourceAnimation[1]
    local posY = getThreeInonePosY(battlescene,action)

    local ccb, item = CCBReaderLoad(action.destccbmodule.name.."/"..action.destccbmodule.name.."02_"..action.destccbmodule.index, nil, true, action.destccbmodule.name.."02")

    local needturn = (battlescene[source.postype].general[source.pos].direct == "def")

    if item.topnode or item.bottomnode then
        if item.topnode then
            item.topnode:removeFromParentAndCleanup(false)
            battlescene.bgitem.fronteffect:addChild(item.topnode)
            item.topnode:setPosition(ccp(needturn and -540 or 540,posY))
            if needturn then item.topnode:setScaleX(-1) end
        end
        if item.bottomnode then
            item.bottomnode:removeFromParentAndCleanup(false)
            battlescene.bgitem.backeffect:addChild(item.bottomnode)
            item.bottomnode:setPosition(ccp(needturn and -540 or 540,posY))
            if needturn then item.bottomnode:setScaleX(-1) end
        end
    else
        ccb:setPosition(ccp(needturn and -540 or 540,posY))
        battlescene.bgitem.fronteffect:addChild(ccb)
        if needturn then ccb:setScaleX(-1) end
    end

    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        if item.topnode then item.topnode:removeFromParentAndCleanup(true) end
        if item.bottomnode then item.bottomnode:removeFromParentAndCleanup(true) end
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed(action.destccbmodule.name.."02_"..action.destccbmodule.index)
end

function yuhuangjuntuan(battlescene,action)
    local source = action.sourceAnimation[1]
    for i=1,8 do
        local ccb, item = CCBReaderLoad(action.destccbmodule.name.."/"..action.destccbmodule.name.."02_"..i, nil, true, action.destccbmodule.name.."02_"..i)
        ccb:setPosition(ccp(540,0))
        battlescene.rootNode:addChild(ccb,100*(i-0.5))
        if battlescene[source.postype].general[source.pos].direct == "def" then
            ccb:setScaleX(-1)
        end
        local animationManager = getAnimationManager(item)
        animationManager:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed(action.destccbmodule.name.."02_"..i)
    end
end


function jiuyanhantianwu(battlescene,action)

    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos].skeleton:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.destdelay), CCCallFunc:create(function()
            local fadeout = CCFadeOut:create(0)
            battlescene[v.postype].general[v.pos].skeleton:runAction(fadeout)
        end)))
        battlescene[v.postype].general[v.pos].skeleton:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.actiontime), CCCallFunc:create(function()
            local fadein = CCFadeIn:create(0.3)
            battlescene[v.postype].general[v.pos].skeleton:runAction(fadein)
            battlescene[v.postype].general[v.pos]:hideAllBuffer(true)
            battlescene[v.postype].general[v.pos].skeleton:setAnimation(battlescene[v.postype].general[v.pos].iscelebrate and "celebrate" or "stand",true,0)
        end)))
    end
end

function threeInoneBytype(battlescene,action)
--    local source = action.sourceAnimation[1]
--    local zorder = battlescene[source.postype].general[source.pos].pos.z+2
--    local frontGeneral = {}
--
--    for k,v in ipairs(action.destAnimation) do
--        if battlescene[v.postype].general[v.pos].pos.z > zorder then
--            frontGeneral = v
--            battlescene[v.postype].general[v.pos].rootNode:setZOrder(zorder-1)
--        end
--    end
--
--    if next(frontGeneral) then
--        battlescene[frontGeneral.postype].general[frontGeneral.pos].skeleton:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.actiontime), CCCallFunc:create(function()
--            battlescene[frontGeneral.postype].general[frontGeneral.pos]:setOriginZ()
--        end)))
--    end
    local source = action.sourceAnimation[1]
    local posY = battlescene[source.postype].general[source.pos].pos.y

    local index = tonumber(source.pos) <= 7 and "02_1" or "02_2"
    local ccb, item = CCBReaderLoad(action.destccbmodule.name.."/"..action.destccbmodule.name..index, nil, true, action.destccbmodule.name..index)

    local needturn = (battlescene[source.postype].general[source.pos].direct == "def")

    if item.topnode or item.bottomnode then
        if item.topnode then
            item.topnode:removeFromParentAndCleanup(false)
            battlescene.bgitem.fronteffect:addChild(item.topnode)
            item.topnode:setPosition(ccp(needturn and -540 or 540,posY))
            if needturn then item.topnode:setScaleX(-1) end
        end
        if item.bottomnode then
            item.bottomnode:removeFromParentAndCleanup(false)
            battlescene.bgitem.backeffect:addChild(item.bottomnode)
            item.bottomnode:setPosition(ccp(needturn and -540 or 540,posY))
            if needturn then item.bottomnode:setScaleX(-1) end
        end
    else
        ccb:setPosition(ccp(needturn and -540 or 540,posY))
        battlescene.bgitem.fronteffect:addChild(ccb)
        if needturn then ccb:setScaleX(-1) end
    end

    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        if item.topnode then item.topnode:removeFromParentAndCleanup(true) end
        if item.bottomnode then item.bottomnode:removeFromParentAndCleanup(true) end
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed(action.destccbmodule.name..index)
end

function zhujue(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos].skeleton:setAnimation("skill01_01",false,0)
        if  action.screenAnimation.actiontime> v.animation.actiondelay1 + v.animation.actiondelay2 then
            battlescene[v.postype].general[v.pos].skeleton:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(v.animation.actiondelay1), CCCallFunc:create(function()
                battlescene[v.postype].general[v.pos].skeleton:setAnimation("skill01_02",true,0)
            end)))
        end
        battlescene[v.postype].general[v.pos].skeleton:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.actiontime-v.animation.actiondelay2), CCCallFunc:create(function()
            battlescene[v.postype].general[v.pos].skeleton:setAnimation("skill01_03",false,0)
        end)))
        battlescene[v.postype].general[v.pos].skeleton:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.actiontime), CCCallFunc:create(function()
            battlescene[v.postype].general[v.pos].skeleton:setAnimation(battlescene[v.postype].general[v.pos].iscelebrate and "celebrate" or "stand",true,0)
        end)))
    end
end

function dariwuzhishan(battlescene,action)
    local index = math.random(1,5)
    local ccb, ccbDocumentControler = CCBReaderLoad(action.destccbmodule.name.."/"..action.destccbmodule.name.."_screen"..index, nil, true, action.destccbmodule.name.."_screen"..index)
    ccb:setPosition(0,0)
    battlescene.bgitem.fronteffect:addChild(ccb)
    local animationManager = getAnimationManager(ccbDocumentControler)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed(action.destccbmodule.name.."_screen"..index)

    local shakeconfig = {1,2,2,2,1}
    battlescene:shake("shake_"..action.destccbmodule.name..shakeconfig[index])

end

function frontOrback(battlescene,action)

    local index = "2"
    for k,v in ipairs(action.destAnimation) do
        if tonumber(v.pos) < 8 then
            index = ""
        end
    end

    local ccb, ccbDocumentControler = CCBReaderLoad(action.destccbmodule.name.."/"..action.destccbmodule.name.."_screen"..index, nil, true, action.destccbmodule.name.."_screen"..index)
    ccb:setPosition(0,0)
    if action.sourceAnimation[1].postype == "def" then
        ccb:setScaleX(-1)
    end
    battlescene.bgitem.fronteffect:addChild(ccb)
    local animationManager = getAnimationManager(ccbDocumentControler)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed(action.destccbmodule.name.."_screen"..index)

end

function nothing(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:hideAllBuffer(true)
    end
end

function sourcewithblood(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        local ccb, item = battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        item.damagelabel1:setString(v.animation.damage and math.abs(v.animation.damage) or "")
        item.damagelabel2:setString(v.animation.damage and math.abs(v.animation.damage) or "")
        battlescene[v.postype].general[v.pos]:setBlood({damage = (v.animation.damage or 0)},true)
    end

end

function zibao(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        local ccb, item = battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        
        battlescene[v.postype].general[v.pos]:death(1.7,{action="zibao"})

        --item.damagelabel1:setString(v.animation.damage and math.abs(v.animation.damage) or "")
        
        --battlescene[v.postype].general[v.pos]:setBlood({damage = (v.animation.damage or 0)},true)
    end

end

function has01skill(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(
            {
                dir = action.sourceccbmodule.name,
                name = action.sourceccbmodule.name.."01",
            },
            v.postype,
            action.screenAnimation.actiontime)
    end
end

function yuhuochongsheng(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        battlescene[v.postype].general[v.pos]:reborn({
            damage = v.animation.damage,
        })
    end
end

function xiandaochongsheng(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        battlescene[v.postype].general[v.pos]:reborn({
            damage = v.animation.damage,
        })
    end
end

function jianzairenzai(battlescene,action)
    for k,v in ipairs(action.destAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay({dir=jianzairenzai,name=jianzairenzai01},v.postype,action.screenAnimation.actiontime)
        battlescene[v.postype].general[v.pos]:reborn({
            damage = 0,
        })
    end
end

function bumiemingwang(battlescene,action)
    for k,v in ipairs(action.destAnimation) do
        battlescene[v.postype].general[v.pos]:reborn({
            damage = 0,
        })
    end
end

function zhuzhenyi(battlescene,action)
    for k,v in ipairs(action.destAnimation) do
        battlescene[v.postype].general[v.pos]:reborn({
            damage = v.animation.damage,
        })
    end
end

function huanhua(battlescene,action)
    for k,v in ipairs(action.destAnimation) do
        if v.animation and v.animation.damage and next(v.animation.damage) then
            battlescene[v.postype].general[v.pos]:reborn({
                damage = v.animation.damage,
            })
        end
    end
end

function feilongzaisheng(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        battlescene[v.postype].general[v.pos]:reborn({
            damage = v.animation.damage,
        })
    end
end

function wangtuijiangqi(battlescene,action)
    for k,v in ipairs(action.destAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay({dir=action.destccbmodule.name,name=action.destccbmodule.name.."02"},v.postype,action.screenAnimation.actiontime)
        battlescene[v.postype].general[v.pos]:reborn({
            damage = 0,
        })
    end
end

function fuchoudaji(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        battlescene[v.postype].general[v.pos]:reborn({
            damage = v.animation.damage,
        })
    end
end

function qixingdenghuo(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        if v.animation.damage and math.abs(v.animation.damage) > 0 then
            battlescene[v.postype].general[v.pos]:reborn({
                damage = v.animation.damage,
            })
        end
    end
end

function bujishenming(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        if v.animation.damage and math.abs(v.animation.damage) > 0 then
            battlescene[v.postype].general[v.pos]:reborn({
                damage = v.animation.damage,
            })
        end
    end
end

function xiandaochongsheng(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:ccbeffectwithoutddelay(v.animation.specialccb,v.postype,action.screenAnimation.actiontime)
        battlescene[v.postype].general[v.pos]:reborn({
            damage = v.animation.damage,
        })
    end
end

function shenyou(battlescene,action)
    for k,v in ipairs(action.destAnimation) do
        battlescene[v.postype].general[v.pos]:reborn({
            damage = 0,
        })
    end
end

function tuantuzaoren(battlescene,action)
    for k,v in ipairs(action.destAnimation) do
        battlescene[v.postype].general[v.pos]:reborn({
            damage = 0,
        })
    end
end

function baguashengsi(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        battlescene[v.postype].general[v.pos]:reborn({
            damage = 0,
        })
    end
end

function frontWith02(battlescene,action)

    for k,v in ipairs(action.destAnimation) do
        if v.animation.damage and next(v.animation.damage) then
            local pos=battlescene[v.postype].general[v.pos].pos

            local sourceccb, sourceccbitem = CCBReaderLoad(action.destccbmodule.name.."/"..action.destccbmodule.name.."02", nil, true, action.destccbmodule.name)
            local animationManager = getAnimationManager(sourceccbitem)
            animationManager:runAnimationsForSequenceNamed(action.destccbmodule.name.."02")

            local needturn = false
            if battlescene[v.postype].general[v.pos].direct ~= "def" then
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
            sourceccb:setPosition(pos.x-540,pos.y+50)
            battlescene.bgitem.fronteffect:addChild(sourceccb)
        end
    end

end

function frontWith02Order(battlescene,action)


    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(action.destccbmodule.name.."/" .. action.destccbmodule.name .. ".json")
    local skilljson = LoadJsonFileToTable(path)

    local index = 1
    for k,v in ipairs(action.destAnimation) do
        if v.animation.damage and next(v.animation.damage) then
            print("frontWith02Order",index)

            local delay = skilljson.dest.damage[tostring(index)].ccbdelay
            local index_ = index
            local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(delay), CCCallFunc:create(function()
                -- body
                local pos=battlescene[v.postype].general[v.pos].pos

                local sourceccb, sourceccbitem = CCBReaderLoad(action.destccbmodule.name.."/"..action.destccbmodule.name.."02_"..index_, nil, true, action.destccbmodule.name)
                local animationManager = getAnimationManager(sourceccbitem)
                animationManager:runAnimationsForSequenceNamed(action.destccbmodule.name.."02_"..index_)

                local needturn = false
                if battlescene[v.postype].general[v.pos].direct ~= "def" then
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
                sourceccb:setPosition(pos.x-540,pos.y+50)
                battlescene.bgitem.fronteffect:addChild(sourceccb)

            end))
            battlescene[v.postype].general[v.pos].frontNode:runAction(sequence)
            index = index + 1
        end
    end
end

function menghuajianshu(battlescene,action)
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(action.destccbmodule.name.."/"..action.destccbmodule.name..".json")
    local skilljson = LoadJsonFileToTable(path)

    local idx = 0 
    for k,v in ipairs(action.destAnimation) do

        if v.animation.damage and next(v.animation.damage) then
            idx = idx +1
            if idx==1 then
                battlescene[v.postype].general[v.pos]:ccbeffect({
                    delay = 0,
                    name = action.destccbmodule.name.."01",
                    dir = action.destccbmodule.name,
                },"def",skilljson.dest.damage["1"].ccbdelay)
            end
            battlescene[v.postype].general[v.pos]:ccbeffect({
                    delay = skilljson.dest.damage[tostring(idx)].ccbdelay,
                    name = action.destccbmodule.name.."02_"..(tonumber(v.pos)<=7 and 1 or 2),
                    dir = action.destccbmodule.name,
                },"def",action.screenAnimation.actiontime-action.screenAnimation.destdelay)
        end

    end
end

function hideSelf(battlescene,action)
    local index = action.sourceAnimation[1].postype 
    for k,v in pairs(battlescene[index].general) do 
        v:setVisible(false)
    end
end

function hideEnemy(battlescene,action)
    local index = other(action.sourceAnimation[1].postype) 
    for k,v in pairs(battlescene[index].general) do 
        v:setVisible(false)
    end
end

function hideEnemyKeepEffect(battlescene, action)
    local index = other(action.sourceAnimation[1].postype) 
    for k,v in pairs(battlescene[index].general) do 
        -- Todo ????
        v.SkeletonNode:setVisible(false)
    end
end

function showSelf(battlescene,action)
    local index = action.sourceAnimation[1].postype
    for k,v in pairs(battlescene[index].general) do
        v:setVisible(true)
    end
end

function showEnemy(battlescene,action)
    local index = other(action.sourceAnimation[1].postype)
    for k,v in pairs(battlescene[index].general) do 
        v:setVisible(true)
    end
end

function showEnemyKeepEffect(battlescene,action)
    local index = other(action.sourceAnimation[1].postype)
    for k,v in pairs(battlescene[index].general) do 
        -- Todo ????
        print("hp = ",v.hp)
        if v.hp <= 0 then
            v:death()
        else
            v.SkeletonNode:setVisible(true)
        end
    end
end

function freezeEnemy( battlescene,action )
    local index = other(action.sourceAnimation[1].postype) 
    for k,v in pairs(battlescene[index].general) do 
        v:freezeSkeleton()
    end
end

function unfreezeEnemy( battlescene,action )
    local index = other(action.sourceAnimation[1].postype) 
    for k,v in pairs(battlescene[index].general) do 
        v:unfreezeSkeleton()
    end
end

function laoshuronghedest(battlescene,action)
    for k,v in ipairs(action.destAnimation) do
        if v.animation.damage and next(v.animation.damage) and battlescene[v.postype].general[v.pos] then
            local general = battlescene[v.postype].general[v.pos]
            general:ccbeffect({
                delay = 0,
                name = action.destccbmodule.name.."02",
                dir = action.destccbmodule.name,
            },"def",action.screenAnimation.actiontime-action.screenAnimation.destdelay)


            local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
                general.effectscale=general.effectscale*1.2
                general:rootScale(1)
            end))
            general.rootNode:runAction(sequence)
        end
    end
end

function laoshuronghesource(battlescene,action)
    for k,v in ipairs(action.sourceAnimation) do
        local general = battlescene[v.postype].general[v.pos]
        if not general then return end

        local position = general.pos
        local effectccb, effectitem = CCBReaderLoad("buouronghe/buouronghe01", nil, true, "buouronghe01")
        effectccb:setPosition(position.x,position.y)
        battlescene.rootNode:addChild(effectccb,position.z+5)

        local animationManager = getAnimationManager(effectitem)
        animationManager:setAnimationCompletedCallback(function()
            effectccb:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("buouronghe01")

        battlescene[v.postype.."hp"] = battlescene[v.postype.."hp"] - general.hp
        battlescene[v.postype.."hptotal"] = battlescene[v.postype.."hptotal"] - general.hptotal
        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
            ui.itemcache:detachskeleton(general.data.animation.name,general.skeleton)
            general.rootNode:removeFromParentAndCleanup(true)
            battlescene[v.postype].general[tostring(v.pos)] = nil
            if battlescene[v.postype.."hptotal"] <=0 then
                battlescene[v.postype.."bloodbar"]:setPercentage(0)
            else
                battlescene[v.postype.."bloodbar"]:setPercentage(100*battlescene[v.postype.."hp"]/battlescene[v.postype.."hptotal"])
            end
            battlescene:setBloodstar(v.postype)
        end))
        general.rootNode:stopAllActions()
        general.rootNode:runAction(sequence)
    end
end

function baibai( battlescene,action )
    for k,v in ipairs(action.sourceAnimation) do
        local general = battlescene[v.postype].general[v.pos]
        if not general then return end

        general.skeleton:setAnimation("stand",true,0)

        local position = general.pos
        local effectccb, effectitem = CCBReaderLoad("baibai/baibai01", nil, true, "baibai01")
        effectccb:setPosition(position.x,position.y)
        battlescene.rootNode:addChild(effectccb,position.z+5)

        local animationManager = getAnimationManager(effectitem)
        animationManager:setAnimationCompletedCallback(function()
            effectccb:removeFromParentAndCleanup(true)
            general.skeleton:setAnimation("taopao",false,0)
            general.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
                general:setVisible(false)
            end)))            
        end)
        animationManager:runAnimationsForSequenceNamed("baibai01")
    end
end

function numberOfPeople(battlescene, action) 
    local destnum = 0

    for k,v in ipairs(action.destAnimation) do
        local general = battlescene[v.postype].general[tostring(v.pos)]
        if general and general.battleScene.isend == false then
            destnum = destnum + 1
            local effectccb, effectitem = CCBReaderLoad("zhuxianjianzhen/zhuxianjianzhen02_"..destnum, nil, true, "zhuxianjianzhen02_" .. destnum)
            local animationManager = getAnimationManager(effectitem)
            animationManager:setAnimationCompletedCallback(function()
                general.standinNode:removeAllChildrenWithCleanup(true)
                effectccb:removeFromParentAndCleanup(true)
            end)
            effectccb:setPosition(0,0)
            general.standinNode:addChild(effectccb)
            animationManager:runAnimationsForSequenceNamed("zhuxianjianzhen02_"..destnum)         
        end
    end
    
    battlescene.bgitem.commonnode:removeAllChildrenWithCleanup(true)
    local texie = action.screenAnimation.skill2.spine
    battlescene.texie_skeleton = CCSkeletonAnimation:create(texie.."/"..texie..".json",texie.."/"..texie..".atlas",1)
    battlescene.texie_skeleton:setScale(1)
    battlescene.texie_skeleton:setScaleX(action.screenAnimation.common.direct and 1 or -1)
    battlescene.bgitem.commonnode:addChild(battlescene.texie_skeleton)

    battlescene.texie_skeleton:setAnimation("skill2_"..destnum,false,0)

end

