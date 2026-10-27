--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local wingPreview = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
    index = 1,
    maxindex = 1,
    wing = {},
    protagonist = {},
}

function wingPreview.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority

    self.rootNode, self.rootItems = CCBReaderLoad("wing/wing_yulan.ccbi", nil, true, "wing_yulan")
    self.root:addChild(self.rootNode)

    local tempnum = 0
    for k,v in pairs(gamedata.config.wing_stage) do
        if tonumber(v.preview) == 1 then
            tempnum = tempnum + 1
        end
    end
    -- self.maxindex = table.getTableLength(gamedata.config.wing_stage)
    self.maxindex = tempnum
    --
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)

    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(1)
            if self.index > 1 then
                self.index = self.index-1
                self:showstage()
            end
        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(1)
            if self.index < self.maxindex then
                self.index = self.index+1
                self:showstage()
            end
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
    if self.rootItems.touchLayer then
        self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority, false)
        self.rootItems.touchLayer:setTouchPriority(self.touchPriority)
        self.rootItems.touchLayer:setTouchEnabled(true)
    end
    --
    self:reloadData(data)

    return self.root
end


--
function wingPreview.reloadData(self,data)

    if data then
        self.wing = data.wing
        self.protagonist = data.protagonist
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("wingPreview")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority-1)

    self.index = (self.wing.stagenum > 0) and self.wing.stagenum or 1

    self:showstage()

    self.rootItems.left:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.index > 1 then
            self.index = self.index-1
            self:showstage()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.left:setSwallowsTouch(true)
    self.rootItems.left:setTouchPriority(self.touchPriority-1)

    self.rootItems.right:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.index < self.maxindex then
            self.index = self.index+1
            self:showstage()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.right:setSwallowsTouch(true)
    self.rootItems.right:setTouchPriority(self.touchPriority-1)

end

function wingPreview.showstage(self)

    if self.index <= 1 then
        self.rootItems.leftSprite:setVisible(false)
    else
        self.rootItems.leftSprite:setVisible(true)
    end
    if self.index < self.maxindex then
        self.rootItems.rightSprite:setVisible(true)
    else
        self.rootItems.rightSprite:setVisible(false)
    end


    local nowstageconfig = gamedata.config.wing_stage[tostring(self.index)]
    ui.setLabelString(self.rootItems.generalname,nowstageconfig.name,1)

    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.protagonist.general.cid)].animationid)].name
    local wing = {level = self.index, color = 0, show = 1}
    local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.6)
    Gneral1:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral1.root or Gneral1)

    self.rootItems.useButton:setTouchPriority(self.touchPriority-1)
    self.rootItems.useButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("wingPreview")
    end, CCControlEventTouchUpInside)
    self.rootItems.useButton:setSwallowsTouch(true)
    ui.setLabelString(self.rootItems.useLab,gameConfig.strings:string_common("fixedString","wing",6),19)

end


function wingPreview.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.index = 1
    self.wing = {}
    self.protagonist = {}

    if self.callback then
        self.callback()
    end
end

return wingPreview