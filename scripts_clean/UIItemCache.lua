--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/9/22
-- Time: 下午2:34
-- To change this template use File | Settings | File Templates.
--

local itemcache = {
    skeletons = {},

    attachedSkeletons = {},
    savedAttaches = {},

    spriteFrames = {},


    skeletonWithWings = require"SkeletonWithWing"
}

function itemcache.loadSkeleton(self,name,wing)
    local show = 0
    if wing and wing.show then
        show = wing.show
    end
    if show == 0 and GameScene.roleinfo and GameScene.roleinfo.id then
        local _str = CCUserDefault:sharedUserDefault():getStringForKey("useWingEffect"..GameScene.roleinfo.id)
        if _str == "1" then
            wing = {}
        end
    end
    
    local wing_ = wing

    local skeleton = CCSkeletonAnimation:create(name.."/"..name..".json",name.."/"..name..".atlas",1)
    if string.find(name,"zhujue") or string.find(name,"shizhuang") then
        if not skeleton.changeBone then
            runGamePrompt({msg = "当前客户端版本过低，翅膀无法显示，请下载最新客户端"})
            return skeleton
        else
            local _spine = self.skeletonWithWings:init(skeleton,name,wing_)
            return _spine
        end
    else
        return skeleton
    end
end

function itemcache.addSkeleton(self,name,wing)
    self.skeletons[name] = {}
    self.skeletons[name].skeleton = self:loadSkeleton(name,wing)
    self.skeletons[name].skeleton:retain()
    return self.skeletons[name].skeleton

--      return  CCSkeletonAnimation:create(name.."/"..name..".json",name.."/"..name..".atlas",1)

end

function itemcache.getSkeleton(self,name,wing)
    if not self.skeletons[name] then
        return self:addSkeleton(name,wing)
    else
        if self.skeletons[name].skeleton.wing and self.skeletons[name].skeleton.checkwing and self.skeletons[name].skeleton:checkwing(wing) then
            if self.skeletons[name].skeleton:getParent() then
                self.skeletons[name].skeleton:removeFromParentAndCleanup(true)
            end
            return self:addSkeleton(name,wing)
        else
            if self.skeletons[name].skeleton:getParent() then
                self.skeletons[name].skeleton:removeFromParentAndCleanup(false)
            end
            return self.skeletons[name].skeleton
        end
    end
end

function itemcache.attachskeleton(self,name,node,wing)
    print("attachskeleton",name)
    local skeleton = self:getSkeleton(name,wing)
    node:addChild(skeleton.root or skeleton)
    self.attachedSkeletons[name] = node
    return skeleton
end

function itemcache.detachskeleton(self,name,skeleton)

    if self.skeletons[name] and self.skeletons[name].skeleton:getParent() and (not skeleton or self.skeletons[name].skeleton == skeleton) then
        self.skeletons[name].skeleton:removeFromParentAndCleanup(false)
        self.attachedSkeletons[name] = false
    end
end

function itemcache.detachAllSkeletons(self)
    for k,v in pairs(self.attachedSkeletons) do
        self:detachskeleton(k)
    end
    self.attachedSkeletons = {}
end

function itemcache.attachskeletonwithCheck(self,name,node,wing)
    if self.skeletons[name] and not self.attachedSkeletons[name] then
        return self:attachskeleton(name,node,wing)
    else
        local skeleton = self:loadSkeleton(name,wing)
        node:addChild(skeleton.root or skeleton)
        return skeleton
    end
end

function itemcache.removeskeleton(self,name)
    if self.skeletons[name] then
        self.skeletons[name].skeleton:release()
        self.skeletons[name] = nil
    end
end

function itemcache.removeAllSkeletons(self)
    for k,v in pairs(self.skeletons) do
        self:removeskeleton(k)
    end

    self.skeletons = {}
    self.attachedSkeletons = {}
    self.savedAttaches = {}
    self.spriteFrames = {}
end

function itemcache.saveAttachs(self)
    self.savedAttaches = table.copy(self.attachedSkeletons)
end

function itemcache.resumAttachs(self)
    for k,v in pairs(self.savedAttaches) do
        if v then
            self:attachskeleton(k,v)
        end
    end
    self.savedAttaches = {}
end

function itemcache.saveAttachsByname(self,name)
    if self.attachedSkeletons[name] then
        self.savedAttaches[name] = self.attachedSkeletons[name]
    end
end

function itemcache.resumAttachByname(self,name)
    if self.savedAttaches and next(self.savedAttaches) and self.savedAttaches[name] then
        self:attachskeleton(name,self.savedAttaches[name])
    end

end

function itemcache.getSpriteFrame(self,frameName,dirname)

    if not string.find(frameName,".jpg") and string.find(frameName,".png") == nil then
        frameName = frameName..".png"
    end

    local frameIncache = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameName)
    if not frameIncache then
        if not self.spriteFrames[frameName] then
            local spritetemp
            if dirname then
                spritetemp = CCSprite:create(dirname.."/"..frameName)
            else
                spritetemp = CCSprite:create("public/icons/"..frameName) or (CCSprite:create("public/publicsprite/"..frameName) or CCSprite:create("public/bg/"..frameName) or CCSprite:create("public/language/"..frameName))
            end
            if spritetemp then
                frameIncache = spritetemp:displayFrame()
--                frameIncache:retain()
--                CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFrame(frameIncache,frameName)
--                self.spriteFrames[frameName] = frameIncache
            else
                cclog("no souch frame in setSpriteFrameByName %s ",frameName);
                frameIncache = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(gameConfig.images.alpha)
            end
        else
            frameIncache = self.spriteFrames[frameName]
        end
    end
    return frameIncache
end

function itemcache.removeSpriteFrame(self,frameName)
    if self.spriteFrames[frameName] then
        self.spriteFrames[frameName]:release()
        self.spriteFrames[frameName] = nil
    end
end

function itemcache.removeAllSpriteFrame(self)
    for k,v in pairs(self.spriteFrames) do
        self:removeSpriteFrame(k)
    end
    self.spriteFrames = {}
end

return itemcache

