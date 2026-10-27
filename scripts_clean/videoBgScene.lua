
-- zjh

local videoBgSceneCtrl = {

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
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(guangSchedule)
        guangSchedule = nil
    end

    local curScene = CCDirector:sharedDirector():getRunningScene()
    if curScene then 
        print("222223444 --- ")
 --       curScene:removeAllChildrenWithCleanup(true)
     curScene:removeChildByTag(100003,true)
     curScene:removeChildByTag(100004,true)
     curScene:removeFromParentAndCleanup(true)
    end
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
    local curScene = CCDirector:sharedDirector():getRunningScene()
    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()

    local bgSpr = CCSprite:create("vidiobg.jpg")
    bgSpr:setPosition(frameSize.width/2,frameSize.height)
    bgSpr:setAnchorPoint(ccp(0.5,1))
    bgSpr:setScale(frameSize.width/2160)
    bgSpr:setTag(100003)
    curScene:addChild(bgSpr,1)

    bgSprTwo = CCSprite:create("guang.png")
    bgSprTwo:setPosition(frameSize.width/2,frameSize.height)
    bgSprTwo:setAnchorPoint(ccp(0.5,1))
    bgSprTwo:setScale(frameSize.width/2160)
    bgSprTwo:setTag(100004)
    curScene:addChild(bgSprTwo,2)

    bgSprTwo:setOpacity(127)
    local gangTimw = 0.07
    if not guangSchedule then
        guangSchedule = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(guangUIUpdate, gangTimw, false)
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