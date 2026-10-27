--
-- Author: songyibo
-- Date: 2020-03-19 16:29:16
--
local hellAllReward = {
    root = nil,
    rootNode = nil,
    rootItems = nil,
}

-- 打开弹窗
function hellAllReward.open(self, touchPriority, data, callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self:initNode()
    self:reloadData()

    return self.root
end

-- 初始化ccb
function hellAllReward.initNode(self)
    self.rootNode, self.rootItems = CCBReaderLoad("copyhell/tc_jiangli", nil, true, "tc_jiangli")
    self.rootNode:setPosition(0, 0)
    self.root:addChild(self.rootNode)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("hellRewardPreview")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
end

function hellAllReward.reloadData(self)
    self.config = gamedata.config.hell_difficulty[tostring(GameScene.roleinfo.level)]
    for i=1,3 do
        self:createRewardList(i)
    end
end

function hellAllReward.createRewardList(self,i)

    local rewards = {}
    if i < 3 then

        ui.setLabelString(self.rootItems[ui.ccbNameEx("lab1",i)],"缉拿", 14)
        ui.setLabelString(self.rootItems[ui.ccbNameEx("lab2",i)],gameConfig.strings.bigNum[i].."个", 14)

        rewards = ui.getIDandNUMs(self.config["dropShow"..i])
    else

        ui.setLabelString(self.rootItems[ui.ccbNameEx("lab1",i)],"全通", 14)
        ui.setLabelString(self.rootItems[ui.ccbNameEx("lab2",i)],"奖励", 14)

        rewards = ui.getIDandNUMs(self.config["dropShow3"]..self.config["finalDrop"])
    end


    local celldict = {}
    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(180, 180)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            ui.setNewIcon(ccbDocumentControler, rewards[a1+1])
            ccbDocumentControler["i_button"]:setTouchPriority(self.touchPriority - 1)
            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(rewards[a1+1].cid)
            end, CCControlEventTouchUpInside)

            -- cellCCB:setScale(0.8)
            cellCCB:setPosition(180/2, 180/2)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then 
            r = table.getTableLength(rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local rewardList = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems[ui.ccbNameEx("listnode",i)]:getContentSize().width,
        viewheight = self.rootItems[ui.ccbNameEx("listnode",i)]:getContentSize().height,
        dire = 0
    })
    self.rootItems[ui.ccbNameEx("listnode",i)]:addChild(rewardList)
    rewardList:setTouchPriority(self.touchPriority)
end

function hellAllReward.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
end

return hellAllReward