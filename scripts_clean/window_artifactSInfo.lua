--
-- Created by IntelliJ IDEA.
-- User: lipurpose
-- Date: 17/8/1
-- Time: 下午4:31
-- To change this template use File | Settings | File Templates.
--

local artifactSInfo = {
    rootNode = nil,
    rootItems = nil,
    needcallback = true,
}

function artifactSInfo.setFixedString(self)
    ui.setLabelString(self.rootItems.doLab, gameConfig.strings:string_common("nightclub",31),19)
    ui.setLabelString(self.rootItems.fixed1, gameConfig.strings:string_common("artifact",34),71)
    ui.setLabelString(self.rootItems.fixed2, gameConfig.strings:string_common("artifact",74),71)
    ui.setLabelString(self.rootItems.fixed3, gameConfig.strings:string_common("artifact",143),71)
    ui.setLabelString(self.rootItems.goToText, gameConfig.strings:string_common("artifact",90),19)
end

function artifactSInfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_dazao", nil, true, "tc_dazao")
    self.touchPriority = touchPriority
    --
    self:setFixedString()
    --
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("artifactSInfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    --
    self.rootItems.goToCheck:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactCheck","up",data.artifact)
    end, CCControlEventTouchUpInside)
    self.rootItems.goToCheck:setSwallowsTouch(true)
    self.rootItems.goToCheck:setTouchPriority(self.touchPriority)

    self:reload(data,callback)
    return self.rootNode
end

function artifactSInfo.reload(self,data,callback)
    self.callback = callback
    print("lipurposes artifact id ",data.artifact.cid)
    local trumpConfig = gamedata.config.trump[tostring(data.artifact.cid)]
    ui.setLabelString(self.rootItems.title,data.title,58)
    local nameStr = trumpConfig.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..trumpConfig.name or trumpConfig.name
    local rich = {
        {fontID = 9,content = nameStr,},
    }
    ui.createRichLabel(rich,self.rootItems.name,false)
    local playerStr1 = data.artifact.name
    local playerStr2 = (trumpConfig.goldTrump > 0 and gameConfig.strings:string_common("artifact",154) or "")
    local playerStr3 = (trumpConfig.goldTrump > 0 and gameConfig.strings:string_common("artifact",144) or gameConfig.strings:string_common("artifact",36))
    rich = {
        {fontID = 122,content = playerStr1,},
        {fontID = 78,content = playerStr2,},
        {fontID = 122,content = playerStr3,},
    }
    ui.createRichLabel(rich,self.rootItems.playerName,false)
    self.rootItems.desc:setString(trumpConfig.desc)

    rich = {
        {fontID = (trumpConfig.type == 1 and 78 or 82),content = gameConfig.strings:string_common("artifact",77).."/",},
        {fontID = (trumpConfig.type == 2 and 78 or 82),content = gameConfig.strings:string_common("artifact",78).."/",},
        {fontID = (trumpConfig.type == 3 and 78 or 82),content = gameConfig.strings:string_common("artifact",79),},
    }
    ui.createRichLabel(rich,self.rootItems.artifactType,false)
    local shenqiSkeletonMeta = require"SkeletonShenqi"
    local skeleton = shenqiSkeletonMeta:init(trumpConfig,0)
    skeleton:setScale(0.7)
    skeleton:setAnimation("stand",true,0)
    self.rootItems.spine:addChild(skeleton.root or skeleton)
end

function artifactSInfo.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    
    if self.callback then
        self.callback(self.selectPos)
    end
end

return artifactSInfo