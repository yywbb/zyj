--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 17/6/14
-- Time: 14:33
-- To change this template use File | Settings | File Templates.
--


local checkTimeList = {
    rootNode = nil,
    rootItems = nil,
    timeSp = {"zi","chou","yin","mao","chen","si","wu","wei","shen","you","xu","hai"},
    cellSize = {x = 180,y = 210},
}

function checkTimeList.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/shenqi_shichen", nil, true, "shenqi_shichen")
    
    self:initFixedString()
    --
    self.touchPriority = touchPriority
    --
    self:initBtnFuncs()
    --
    self.listCenter = self.rootItems.jewelList:getContentSize().width/2 - self.cellSize.x/2
    self:setTime(data)
    return self.rootNode
end


function checkTimeList.setTime(self,t)
    if not t then
        return
    end
    local time = t.time
    if time < 1 or time > 12 then
        time = 1
    end
    local sec = t.sec
    self.data = {time = time,sec = sec}
    gameTimer:rigistTime("checkTimeList",sec)
    gameTimer:rigistTimeFunc("checkTimeList", function()
        if gameTimer.times["checkTimeList"] <= 0 then
            ui.setLabelString(self.rootItems.attribute2,gameConfig.strings:string_format({"artifact",139},{ui.makeTimeDayText(0,"minute")}),26)
        else
            ui.setLabelString(self.rootItems.attribute2,gameConfig.strings:string_format({"artifact",139},{ui.makeTimeDayText(gameTimer.times["checkTimeList"],"minute")}),26)
        end
    end)

    self.rootItems.jewelList:stopAllActions()
    local offSet = -(self.cellSize.x * (self.data.time - 1)) + self.listCenter
    if offSet < -self.cellSize.x * 12 + self.rootItems.jewelList:getContentSize().width then
        offSet = -self.cellSize.x * 12 + self.rootItems.jewelList:getContentSize().width
    end
    if offSet > 0 then
        offSet = 0
    end
    if not self.listTableView then
        self:createList()
        self.listTableView:setLuaContentOffset(offSet,0)
    else
        self.listTableView:setLuaContentOffsetInDuration(offSet,0,0.2)
        self.rootItems.jewelList:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.2), CCCallFunc:create(function()
            self.listTableView:reloadData()
        end)))
    end
end


function checkTimeList.initBtnFuncs(self)
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("checkTimeList")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

end


function checkTimeList.initFixedString(self)
    ui.setLabelString(self.rootItems.title,gameConfig.strings:string_common("artifact",142),65)
    self.rootItems.attribute1:setString(gameConfig.strings:string_common("artifact",138))
end

function checkTimeList.createList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.x, self.cellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shichen", nil, true, "cell_shichen")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,a1 + 1)

            if first then
                a2:addChild(cellCCB)
                cellCCB:setPosition(self.cellSize.x/2,self.cellSize.y/2)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = 12
        elseif fn == "cellTouched" then

        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.jewelList:getContentSize().width,
        viewheight = self.rootItems.jewelList:getContentSize().height,
        dire = 0
    })
    self.rootItems.jewelList:addChild(self.listTableView)
    self.listTableView:setTouchPriority(self.touchPriority)
end

function checkTimeList.setCell(self,items,num)
    printT(items,"lipurposes are are")
    setSpriteFrameByName(items.timeSp,"shenqitime_"..self.timeSp[num])
    setSpriteFrameByName(items.timeL,"shichen_"..self.timeSp[num])
    items.selectNode:setVisible(self.data.time == num)
    if self.data.time == num then
        local animationManager = getAnimationManager(items)
        animationManager:runAnimationsForSequenceNamed("play")
    end
end


function checkTimeList.close(self)
    if gameTimer.times["checkTimeList"] then
        gameTimer:UnrigistTime("checkTimeList")
        gameTimer:UnrigistTimeFunc("checkTimeList")
    end
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.listTableView = nil
    

end

return checkTimeList