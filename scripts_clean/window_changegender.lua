--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/9/20
-- Time: 17:56
-- To change this template use File | Settings | File Templates.
-- changegender


local changegender = {
    rootNode = nil,
    rootItems = nil,

    isselect = 1,
    goldnum = 0,

    gender = 1,
}

function changegender.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("devil/rename", nil, true, "rename")
    self.touchPriority = touchPriority
    self.callback = callback

    UIRequest({type = 204})

    return self.rootNode
end

function changegender.reload(self,data)

    self.gender = data and data.gender or 1
    self.isselect = self.gender

    ui.setLabelString(self.rootItems.changeText,nil,19)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("changegender")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    --
    for i = 1,3 do
        self.rootItems["selectButton"..i]:addHandleOfControlEvent(function()
            self.isselect = i
            self:showselect()
        end, CCControlEventTouchUpInside)
        self.rootItems["selectButton"..i]:setSwallowsTouch(true)
        self.rootItems["selectButton"..i]:setTouchPriority(self.touchPriority)
    end
    --
    self:showselect()
end

function changegender.showselect(self)
    for i = 1,3 do
        if i == self.isselect then
            self.rootItems["xl_select"..i]:setVisible(true)
        else
            self.rootItems["xl_select"..i]:setVisible(false)
        end
    end

    if self.gender == self.isselect then
        ui.setLabelString(self.rootItems.goldnum,"0",21)
        --
        self.rootItems.change:addHandleOfControlEvent(function()
            gameWindows:closeWindow("changegender")
        end, CCControlEventTouchUpInside)
        self.rootItems.change:setSwallowsTouch(true)
        self.rootItems.change:setTouchPriority(self.touchPriority)
    else
        local goldnum = 0
        if gamedata.config.global_kv.changegender and gamedata.config.global_kv.changegender.value then
            goldnum = tonumber(gamedata.config.global_kv.changegender.value)
        end
        --
        ui.setLabelString(self.rootItems.goldnum,goldnum,21)
        --
        self.rootItems.change:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 203, gender = self.isselect, goldnum = goldnum})
            gameWindows:closeWindow("changegender")
        end, CCControlEventTouchUpInside)
        self.rootItems.change:setSwallowsTouch(true)
        self.rootItems.change:setTouchPriority(self.touchPriority)
    end
end

function changegender.close(self)
    self.gender = 1
    self.goldnum = 0
    self.isselect = 1
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end


return changegender
