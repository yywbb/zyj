--
-- Author: jkp
-- Date: 2020-07-15 15:15
--

local autorefining = {
    rootNode = nil,
    rootItems = nil,
    data = {},

    selectId = {0,0,0,0,0},
}

function autorefining.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shop/tc_autorefin", nil, true, "tc_autorefin")
    self.touchPriority = touchPriority

    self:init(callback)
    UIRequest({ type = 8060 })

    return self.rootNode
end

function autorefining.init(self,callback)
    self.callback = callback

    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("autorefining")
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.starttext1,nil,19)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        local setData = {}
        for i=1,5 do
            table.insert(setData, self.selectId[i])
        end
        printT(setData,"setData")
        UIRequest({ type = 8061, data = setData})
        gameWindows:closeWindow("autorefining")
    end, CCControlEventTouchUpInside)

    for i=1, 5 do
        if self.selectId[i] == 1 then
            self.rootItems["selectSp"..i]:setVisible(true)
        else
            self.rootItems["selectSp"..i]:setVisible(false)
        end

        self.rootItems["selectUse"..i]:setSwallowsTouch(true)
        self.rootItems["selectUse"..i]:setTouchPriority(self.touchPriority)
        self.rootItems["selectUse"..i]:addHandleOfControlEvent(function()
            if self.selectId[i] == 0 then
                self.selectId[i] = 1
                self.rootItems["selectSp"..i]:setVisible(true)
            else
                self.selectId[i] = 0
                self.rootItems["selectSp"..i]:setVisible(false)
            end
        end, CCControlEventTouchUpInside)
    end


end

function autorefining.reload(self, data)
    for i=1, 5 do
        if data[tostring(i)] then
            self.selectId[i] = data[tostring(i)]
        end
        if self.selectId[i] == 1 then
            self.rootItems["selectSp"..i]:setVisible(true)
        else
            self.rootItems["selectSp"..i]:setVisible(false)
        end
    end
end

function autorefining.close(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.data = {}
    self.selectId = {0,0,0,0,0}

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return autorefining