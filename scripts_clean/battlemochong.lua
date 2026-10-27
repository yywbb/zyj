--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/9/15
-- Time: 上午11:19
-- To change this template use File | Settings | File Templates.
--

local mochong = {


}

mochong.__index = mochong

function mochong.skillattack(self)
end
function mochong.combskillattack(self)
end
function mochong.breakskillattack(self)
end
function mochong.scopeEffect(self)
end

function mochong.skillattack2(self,cb)
    local ccb,item = CCBReaderLoad("UIEffect/mochong/mochong", nil, true, "mochong")
    self.item.skillnode:addChild(ccb)
    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
        if cb then cb() end
    end)
    animationManager:runAnimationsForSequenceNamed("mochong")
end

function mochong.skillattack3(self)
    if self.skeleton then
        self.skeleton:setAnimation("skill",false,0)
        self.skeleton:addAnimation("stand",true,0,0)
    end
end

function mochong.celebrate(self)
    if self.skeleton then
        self.skeleton:setAnimation("celebrate",true,0)
    end
end
function mochong.removeAllStatus(self)
end
function mochong.stopAllEffect(self)
end
function mochong.setVisible(self)
end
function mochong.freezeSkeleton(self)
end
function mochong.unfreezeSkeleton(self)
end
function mochong.roundbegin(self)
end

function mochong.setAp(self,data)
--    --print(data.ap,"mochongap")
--    if data and self.ap == data.ap then return end
--
--    local old = self.ap
--    self.ap = data and data.ap or self.ap
--
--    if data then
--        local effect = old<self.ap and "nu_up" or "nu_down"
--        local ccb, ccbDocumentControler = CCBReaderLoad("UIEffect/mochong_nu/"..effect, nil, true, effect)
--        ccb:setPosition(self.direct == "def" and 150 or 0,0)
--        self.root:addChild(ccb)
--        ccbDocumentControler.num:setString(math.abs(old-self.ap))
--        local animationManager1 = getAnimationManager(ccbDocumentControler)
--        animationManager1:setAnimationCompletedCallback(function()
--            ccb:removeFromParentAndCleanup(true)
--        end)
--        animationManager1:runAnimationsForSequenceNamed(effect)
--    end
--
--    ui.setSpriteTextureRect2(self.item.bar,0,0,164*(self.ap/100),30)
--    --ui.setSpriteTextureRect2(self.item.bar,0,0,192*(self.ap/100),36)
end

function mochong.change(self,data,isfirst)
    self.data = data
    --self.ap = data.ap
    setSpriteFrameByName(self.icon,self.data.icon)
    --self:setAp()

    setSpriteFrameByName(self.item.name,self.data.image)
    local qualityconfig = {
        [2] = "08",
        [3] = "06",
        [4] = "07",
        [5] = "09",
        [6] = "10",
    }

    local qualirysp = self.data.quality and "i_mochong_"..(qualityconfig[self.data.quality] or "08") or "alpha"
    setSpriteFrameByName(self.item.quality,qualirysp)

    self.item.none:setVisible(self.data.image == "alpha")

    if self.skeleton then 
        self.skeleton:removeFromParentAndCleanup(true)
        self.skeleton = nil
    end

    if not isfirst then
        self:enter()
    end
end

function mochong.enter( self,callback )
    printT(self.data,"mochong.enter")
    if self.data.cid == 90008 then
        local name = self.data.animation.name
        self.skeleton = CCSkeletonAnimation:create(name.."/"..name..".json",name.."/"..name..".atlas",1)

        self.skeleton:setPosition(0,9999)
        self.skeleton:setAnimation("stand",true,0)
        self.battleScene.rootNode:addChild(self.skeleton)
        local scale = 0.6
        self.skeleton:setScale(scale)
        if self.direct == "def" then
            self.skeleton:setScaleX(-1*scale)
        end

        local timeCB ={}
        timeCB["show"] = function()
            print("timeCB show")
            self.skeleton:setPosition(self.direct == "def" and 720 or 360,1168+(battleScene.topposY-1620)*0.66)
        end
        local ccb, ccbDocumentControler = CCBReaderLoad("common/mochogjinchang_"..name, nil, true, "mochogjinchang",timeCB)
        if self.direct == "def" then
            ccb:setScaleX(-1)
        end

        ccb:setAnchorPoint(ccp(0.5,0))
        ccb:setPosition(ccp(0,(battleScene.topposY-1620)*0.66-200))
        self.battleScene.bgitem.commonnode:addChild(ccb,1999)

        local animationManager = getAnimationManager(ccbDocumentControler)
        animationManager:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
            if callback then callback() end
        end)
        animationManager:runAnimationsForSequenceNamed("jinchang")   
    else
        if callback then callback() end
    end
end

function mochong:init(root,data,direct,battleScene)

    local self = {___xxx = 222 }
    setmetatable(self, mochong)

    self.root = root
    self.data = data or {
        icon = "alpha",
        image = "alpha",
        ap = 0,
    }
    self.ap = data and data.ap or 0
    self.direct = direct
    self.battleScene = battleScene

    self.node, self.item = CCBReaderLoad("backGround/b_mochong", nil, true, "b_mochong")

    local cliper = CCClippingNode:create()
    local stencil = CCSprite:createWithSpriteFrameName("copymap_iconmask.png")
    stencil:setAnchorPoint(ccp(0,0))
    cliper:setStencil(stencil)
    cliper:setAlphaThreshold(0)
    self.icon = CCSprite:create()
    setSpriteFrameByName(self.icon,self.data.icon)
    self.icon:setAnchorPoint(ccp(0,0))
    self.icon:setScale(0.87)
    cliper:addChild(self.icon)
    cliper:setScale(1.13)
    self.item.iconnode:addChild(cliper)

    self.root:addChild(self.node)

    self:change(self.data,true)

    if direct == "def" then
        self.node:setScaleX(-1)
        self.item.name:setFlipX(true)
        --self.item.nu:setScaleX(-1)
    end

    --self.item.bar:setScaleX(-1)

    --self:setAp()

    return self
end



return mochong