--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/18
-- Time: 下午2:45
-- To change this template use File | Settings | File Templates.
--

local findDragonReward = {
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    root = nil,
    cellSize = {x = 900},

    title = 60,
    width = 180, 
    hight = 190,
    num = 5,
    data = 1,
}

function findDragonReward.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    
    self.rootNode, self.rootItems = CCBReaderLoad("xunlongjue/tc_xunlongjue", nil, true, "tc_xunlongjue")
    self.callback = callback
    self.data = data or 1

    self.rootItems.tabbutton1:addHandleOfControlEvent(function()
        self:shiftPage(1) 
    end, CCControlEventTouchUpInside)
    self.rootItems.tabbutton1:setSwallowsTouch(true)
    self.rootItems.tabbutton1:setTouchPriority(self.touchPriority)

    self.rootItems.tabbutton2:addHandleOfControlEvent(function()
        self:shiftPage(2)
    end, CCControlEventTouchUpInside)
    self.rootItems.tabbutton2:setSwallowsTouch(true)
    self.rootItems.tabbutton2:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("findDragonReward")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self:reload()
    
    self.root:addChild(self.rootNode)
    return self.root
end

function findDragonReward.shiftPage(self,type)
    if (type == 1) then
        self.rootItems.node1:setPositionX(0)
        self.rootItems.node2:setPositionX(9999)
        setSpriteFrameByName(self.rootItems.tabon1, gameConfig.images.pageButtonON)
        setSpriteFrameByName(self.rootItems.tabon2, gameConfig.images.pageButtonOFF)  
    else
        self.rootItems.node1:setPositionX(9999)
        self.rootItems.node2:setPositionX(0)
        setSpriteFrameByName(self.rootItems.tabon1, gameConfig.images.pageButtonOFF)
        setSpriteFrameByName(self.rootItems.tabon2, gameConfig.images.pageButtonON) 
    end
end

function findDragonReward.reload(self)
    print("findDragonReward.reload(self)-=-=-=-", self.data)
    self:shiftPage(self.data)
    local config = gamedata.config:getConfigByName("xunlong_reward")
    self.reward = {}
    local big = {}
    local small = {}
    for k, v in pairs(config) do
        if (tonumber(v.type) == 2) then
            if v.reward ~= "" then
                table.insert(big, v.reward)
            end
        else
            if v.reward ~= "" then
                table.insert(small, v.reward)
            end
        end
    end
    table.insert(self.reward, big)
    table.insert(self.reward, small)

    if self.ListTableView then
        self.ListTableView:reloadData()
    else
        self:setNode1()
    end
    self:setNode2()
end

function findDragonReward.setNode1(self, cell)
    printT(self.reward, "setNode1=-=-=-=-=-=-=-=")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            r = CCSizeMake(self.cellSize.x, math.ceil(table.getTableLength(self.reward[a1 + 1]) / self.num) * self.hight + self.title)
        elseif fn == "cellAtIndex" then
            local ccb,items = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()

                ccb, items = CCBReaderLoad("xunlongjue/cell_xunlongjue", nil, true, "cell_xunlongjue")
                celldict[a2] = {cell = a2, ccb=ccb,items=items }
            else
                first = false
                ccb = celldict[a2].ccb
                items = celldict[a2].items
            end
            self:setCell(ccb, items, a1 + 1)
            ccb:setPosition(self.cellSize.x/2, -(math.ceil(table.getTableLength(self.reward[a1 + 1]) / self.num) * self.hight + self.title) / 2)
            if first then
                a2:addChild(ccb)
            end
            
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.reward)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.ListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listScroll:addChild(self.ListTableView)
end

function findDragonReward.setNode2(self, cell)
    self.rootItems.probability:setString(gamedata.config:getConfigByName("system_intro")["67"].intro)
end

function findDragonReward.setCell(self, root, cell, index)
    local reward = self.reward[index]
    local hight = math.ceil(table.getTableLength(reward) / self.num) * self.hight + self.title
    root:setContentSize(CCSizeMake(self.cellSize.x, hight))
    local beginx = self.width / 2
    local beginy = hight - self.title - self.hight / 2
    for k, v in pairs(reward) do 
        local item, items = CCBReaderLoad("icons/new_iconName2", nil, true, "new_iconName2")
        local cid, num = ui.getIDandNUM(v)
        item:setScale(0.7)
        root:addChild(item)
        ui.setNewIconName(items, {cid = cid, num = num}, 0)
        item:setPosition(beginx + (tonumber(k) - 1) % self.num * self.width, beginy - (math.ceil(tonumber(k) / self.num) - 1) * self.hight)
    end

    if index == table.getTableLength(self.reward) then
        cell.cell_line:setVisible(false)
    else
        cell.cell_line:setVisible(true)
    end
    cell.cell_line:setPositionY(0)
    cell.res:setPositionY(hight - 18)
    if (index == 1) then
        cell.res:setString("大奖奖励")
        cell.res:setColor(ccc3(96, 248, 243))
    else
        cell.res:setString("普通奖励")
        cell.res:setColor(ccc3(255, 255, 255))
    end
end

function findDragonReward.close(self)
    self.ListTableView = nil
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return findDragonReward