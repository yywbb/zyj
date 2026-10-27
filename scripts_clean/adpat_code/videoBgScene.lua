
-- zjh

local videoBgSceneCtrl = {
      videoLayer = nil,
}
local guangSchedule = nil
local bgSprTwo = nil
local bgSpr = nil
local guangCount = 1
local guangTable = {}

function videoBgSceneCtrl.clear(self)
    guangCount = 1
    if bgSprTwo then
        bgSprTwo:removeAllChildrenWithCleanup(true)
    end
    if bgSpr then
        bgSpr:removeAllChildrenWithCleanup(true)
    end
    bgSpr = nil
    bgSprTwo = nil
    guangTable = {}

    
    if guangSchedule then
        -- CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.guangSchedule)
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(guangSchedule)
        guangSchedule = nil
    end

    -- local curScene = CCDirector:sharedDirector():getRunningScene()
    local curScene = cc.Director:getInstance():getRunningScene()

    -- curScene:removeAllChildren(true)
    -- self.videoLayer:removeChildByTag(100000)
    -- self.videoLayer:removeChildByTag(100001)
    curScene:removeChildByTag(100002)

    curScene:removeFromParent(true)
end


function videoBgSceneCtrl.init(self,videoscene)
    guangTable = {}
    guangCount = 1
    bgSprTwo = nil
    bgSpr = nil
    table.insert(guangTable,127);
    table.insert(guangTable,153);
    table.insert(guangTable,127);
    table.insert(guangTable,102);
    table.insert(guangTable,127);
    table.insert(guangTable,153);
    -- print(videoscene)

    bRunWithScene = false 
    -- local curScene = CCDirector:sharedDirector():getRunningScene()
    local curScene = cc.Director:getInstance():getRunningScene()
    print("::videoBgSceneCtrl.init:::",curScene)

    -- local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local openGLView = cc.Director:getInstance():getOpenGLView()
    local frameSize = openGLView:getFrameSize()


    self.videoLayer = cc.Layer:create()
    -- self.videoLayer:setContentSize(cc.Size(1080, 1920))
    local s = cc.Director:getInstance():getWinSize()
    print("videobg size width:",s.width," height:",s.height)
    self.videoLayer:setContentSize(s.width, s.height)
    self.videoLayer:setAnchorPoint(0,0)
    self.videoLayer:setPosition(0,0)
    self.videoLayer:setTag(100002)
    curScene:addChild(self.videoLayer)


    bgSpr = cc.Sprite:create("vidiobg.jpg")
    bgSpr:setPosition(frameSize.width/2,frameSize.height)
    bgSpr:setAnchorPoint(0.5,1)
    bgSpr:setScale(frameSize.height/2160)
    bgSpr:setTag(100000)
    self.videoLayer:addChild(bgSpr,1)



    bgSprTwo = cc.Sprite:create("guang.png")
    bgSprTwo:setPosition(frameSize.width/2,frameSize.height)
    bgSprTwo:setAnchorPoint(0.5,1)
    bgSprTwo:setScale(frameSize.height/2160)
    bgSprTwo:setTag(100001)
    self.videoLayer:addChild(bgSprTwo,2)



    bgSprTwo:setOpacity(127)
    local gangTimw = 0.07
    if not guangSchedule then
        guangSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(guangUIUpdate, gangTimw, false)
        -- guangSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        --     guangCount = guangCount + 1
        --     local opacity = tonumber(guangTable[guangCount])
        --     bgSprTwo:setOpacity(opacity)
        --     if guangCount >= 6 then
        --         guangCount = 1
        --     end
        --         end,gangTimw, false)
    end
    -- print("videoBgSceneCtrl")
end

function guangUIUpdate(self)
    guangCount = guangCount + 1
    local opacity = tonumber(guangTable[guangCount])
    bgSprTwo:setOpacity(opacity)
    if guangCount >= 6 then
        guangCount = 1
    end
end



return videoBgSceneCtrl