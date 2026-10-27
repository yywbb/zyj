--
-- Author: jkp
-- Date: 2023-01
--

local minigame = {

    rootNode = nil,
    rootItems = nil,
    touchPriority = -103,

    oldgrid = {},
    actions = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},

    gameState = 0, -- 0：未开始，1：开始游戏，2：游戏结束

    maindata = {},

    nowpoint = 0, --本局积分
    now2048 = 0, --本局2048个数

    battleNum = 0, --挑战次数
    
    updataTime = 0,

}

function minigame.init(self,parent,toppos,param)

    self.rootNode, self.rootItems = CCBReaderLoad("minigame/2048", nil, true, "2048")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY(toppos/2 + 180*GameScene.scaleNum)

    -- 说明
    self.rootItems["infobutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["infobutton"]:addHandleOfControlEvent(function()
        ui.popCommonRule(661)
    end, CCControlEventTouchUpInside)
   
    -- 兑换商店
    self.rootItems["exchangebutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["exchangebutton"]:addHandleOfControlEvent(function()
        gameWindows:openWindow("game2048shop")
    end, CCControlEventTouchUpInside)

    -- 成就
    self.rootItems["achievementbutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["achievementbutton"]:addHandleOfControlEvent(function()
        gameWindows:openWindow("game2048achievement", nil, function()
            if GameScene.hintdata["661"] and GameScene.hintdata["661"] ~= 0 then
                ui.sethint(self.rootItems["hint_minigame"],true)
            else
                ui.sethint(self.rootItems["hint_minigame"],false)
            end
        end)
    end, CCControlEventTouchUpInside)

    -- 排行榜
    self.rootItems["ranklistbutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["ranklistbutton"]:addHandleOfControlEvent(function()
        gameWindows:openWindow("game2048rank",{point = self.maindata.maxpoint})
    end, CCControlEventTouchUpInside)

    -- 次数购买
    self.rootItems["addbutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["addbutton"]:addHandleOfControlEvent(function()
        minigame2048BuyTimes()
    end, CCControlEventTouchUpInside)

    -- 开始/重新开始游戏
    self.rootItems["startbutton"]:setTouchPriority(self.touchPriority)
    self.rootItems["startbutton"]:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.gameState == 0 then
            if self.battleNum > 0 then
                self:initGame()
            else
                runGamePrompt({msg = "游戏挑战次数不足"})
            end
        elseif self.gameState == 1 then
            gameWindows:openWindow("confirm",{msg = "是否结束本局游戏挑战？"}, function()
                self:gameOver()
            end)
        elseif self.gameState == 2 then
            if self.battleNum > 0 then
                self:initGame()
            else
                runGamePrompt({msg = "游戏挑战次数不足"})
            end
        end

    end, CCControlEventTouchUpInside)

    -- 触摸操作
    local function ccTouchBegan(x, y)
        self.istouchmove = false
        self.touchpos = {x=x, y=y}

        if self.gameState == 1 then
            for i=1, #self.grid do
                for j=1, #self.grid[1] do
                    self.oldgrid[i][j] = self.grid[i][j]
                end
            end
        end

        return true
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchpos.x) > 20 or math.abs(y - self.touchpos.y) > 20 then
            self.istouchmove = true
        end
    end

    local function ccTouchEnded(x, y)
        if self.istouchmove then
            if self.gameState == 1 then
                local heng,shu = false, false
                if math.abs(x - self.touchpos.x) > math.abs(y - self.touchpos.y) then
                    heng = true
                    shu = false
                elseif math.abs(x - self.touchpos.x) < math.abs(y - self.touchpos.y) then
                    heng = false
                    shu = true
                else
                    heng = false
                    shu = false
                end

                if heng then
                    if x - self.touchpos.x > 0 then
                        self:moveRight(self.grid)
                    else
                        self:moveLeft(self.grid)
                    end
                end

                if shu then
                    if y - self.touchpos.y > 0 then
                        self:moveUp(self.grid)
                    else
                        self:moveDown(self.grid)
                    end
                end

                if self:canMove(self.grid) then
                    if self:equaldata(self.grid, self.oldgrid) == false then
                        self:randomNum(self.grid)
                        self:printGrid(self.grid)
                        self:setGirdMap(self.rootItems, self.grid)
                    end
                else
                    print("无法移动")
                    self:gameOver()
                end
            elseif self.gameState == 2 then
                runGamePrompt({msg = "本局游戏以结束，请重新挑战！"})
            elseif self.gameState == 0 then
                runGamePrompt({msg = "请点击开始挑战按钮，开启本次挑战！"})
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
    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -12, false)
    self.rootItems.touchLayer:setTouchPriority(-12)
    self.rootItems.touchLayer:setTouchEnabled(true)

    self.grid = self:initGrid(4,4)
    self.oldgrid = self:initGrid(4,4)
    self:makeConfig()

    UIRequest({type = 1600})

end

function minigame.makeConfig(self)
    self.gameCount = gamedata.config.global_kv["2048_times"].value

    gameTimer:rigistTime("activityChristmasTime",86400)
    if gameTimer.times["activityChristmasTime"] and gameTimer.times["activityChristmasTime"] > 0 then
        self.updataTime = 0
        gameTimer:rigistTimeFunc("activityChristmasTime", function()
            if gameTimer.times["activityChristmasTime"] <= 0 then
                gameTimer:rigistTime("activityChristmasTime",86400)
            else
                local speednum = CCDirector:sharedDirector():getScheduler():getTimeScale()
                if self.gameState == 1 then
                    self.updataTime = self.updataTime + 1 
                    if self.updataTime >= (15*speednum) then
                        self.updataTime = 0
                        local maps = {}
                        local m = #self.grid
                        local n = #self.grid[1]
                        for i=1,m do
                            for j=1,n do
                                maps[(i-1)*m+j] = self.grid[i][j]
                            end
                        end
                        UIRequest({type = 1601, nowpoint = self.nowpoint, now2048 = self.now2048, grid = maps})
                    end
                end 
            end
        end)
    end
end

-- 数据加载
function minigame.reloadData(self,data)
    if not data then
        return
    end

    self.maindata = data
    self.nowpoint = self.maindata.nowpoint
    self.rootItems.maxnum:setString(self.maindata.allpoint)
    self.rootItems.nownum:setString(self.nowpoint)

    if self.gameState == 0 then
        for i=1,4 do
            for j=1,4 do
                self.grid[i][j] = self.maindata.grid[tostring((i-1)*4+j)]
                if self.maindata.grid[tostring((i-1)*4+j)] ~= 0 then
                    self.gameState = 1
                end
            end
        end
        if self.gameState == 1 then
            self:setGirdMap(self.rootItems, self.grid)
        end
    end
    self.gameState = self.maindata.gamestate
    if self.gameState == 0 then
        self.rootItems.overLayer:setVisible(false)
        ui.setLabelString(self.rootItems.startlab,"开始挑战",19)
    elseif self.gameState == 1 then
        self.rootItems.overLayer:setVisible(false)
        ui.setLabelString(self.rootItems.startlab,"结束挑战",19)
    elseif self.gameState == 2 then
        self.rootItems.overLayer:setVisible(true)
        ui.setLabelString(self.rootItems.startlab,"重新挑战",19)

    end

    --设置挑战次数
    self.battleNum = (self.gameCount + GameScene.vipstatus.game_2048_times) - self.maindata.count
    if self.battleNum > 0 then
        ui.setLabelString(self.rootItems.battlenum, self.battleNum, 18, 38)
        ui.removeGray("CCControlButton",self.rootItems.startbutton)
        -- ui.removeGray("CCLabelTTF",self.rootItems.startlab)
    else
        self.battleNum = 0
        ui.setLabelString(self.rootItems.battlenum, self.battleNum, 11, 38)
        ui.addGray("CCControlButton",self.rootItems.startbutton)
        -- ui.addGray("CCLabelTTF",self.rootItems.startlab)
    end

    if GameScene.hintdata["661"] and GameScene.hintdata["661"] ~= 0 then
        ui.sethint(self.rootItems["hint_minigame"],true)
    else
        ui.sethint(self.rootItems["hint_minigame"],false)
    end

    --设置时间
    -- local atime = gamedata.config:getConfigByName("peak_time")[tostring(18)]
    -- local beginString = ""
    -- local endString = ""
    -- if atime["begin"] ~= "" then
    --     local year1,month1,day1,hour1,min1,sec1 = ui.getDate(atime["begin"])
    --     local begint = os.time({year=tonumber(year1),month=tonumber(month1),day=tonumber(day1),hour=tonumber(hour1),min=tonumber(min1),sec=tonumber(sec1),isdst=false}) - 2
    --     print("begint = ", begint)
    --     local begintab = os.date("*t",begint)
    --     beginString = begintab.year.."年"..begintab.month.."月"..begintab.day.."日24时"
    -- end
    -- if atime["end"] ~= "" then
    --     local year2,month2,day2,hour2,minute2,second2,min2,sec2 = ui.getDate(atime["end"])
    --     local endt = os.time({year=tonumber(year2),month=tonumber(month2),day=tonumber(day2),hour=tonumber(hour2),min=tonumber(min2),sec=tonumber(sec2),isdst=false}) - 2
    --     local endtab = os.date("*t",endt)
    --     endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
    -- end

    local endtime = os.date("*t",self.maindata.endtime-86400)
    local endString = endtime.year.."年"..endtime.month.."月"..(endtime.day).."日24时"
    self.rootItems.time:setString("活动结束时间: "..endString)

end

-- 游戏结束
function minigame.gameOver(self)
    gameTouch:clickprofbytime(1.2)
    self.gameState = 2
    self.updataTime = 0
    self.rootItems.overLayer:setVisible(true)
    ui.setLabelString(self.rootItems.startlab,"重新挑战",19)

    local node, items = CCBReaderLoad("minigame/2048_gameover", nil, true, "2048_gameover")
    self.rootItems.shibainode:addChild(node)

    items.jifen:setString(self.nowpoint)

    items.closebutton:setSwallowsTouch(true)
    items.closebutton:setTouchPriority(self.touchPriority-1)
    items.closebutton:addHandleOfControlEvent(function()
        node:removeAllChildrenWithCleanup(true)
        node:removeFromParentAndCleanup(true)

        if GameScene.hintdata["661"] and GameScene.hintdata["661"] ~= 0 then
            ui.sethint(self.rootItems["hint_minigame"],true)
        else
            ui.sethint(self.rootItems["hint_minigame"],false)
        end
    end, CCControlEventTouchUpInside)

    local maps = {}
    local m = #self.grid
    local n = #self.grid[1]
    for i=1,m do
        for j=1,n do
            maps[(i-1)*m+j] = self.grid[i][j]
        end
    end
    UIRequest({type = 1602, nowpoint = self.nowpoint, now2048 = self.now2048, grid = maps})

end

--初始化格子
function minigame.initGrid(self, m, n)
    local grid = {}
    for i=1,m do
        if not grid[i] then
            grid[i] = {}
        end
        for j=1,n do
            grid[i][j] = 0
        end
    end
    return grid
end

function minigame.setGirdMap(self, items, grid)
    for i,row in ipairs(grid) do
        for j,num in ipairs(row) do
            local index = (i-1)*(#row)+j
            if num == 0 then
                setSpriteFrameByName(items["grid"..index.."_img"],"alpha")
            else
                setSpriteFrameByName(items["grid"..index.."_img"],"2048_"..num)
            end
        end
    end

    for i=1, #self.actions do
        if self.actions[i] == 1 then --随机
            items["grid"..i.."_img"]:setScale(0.2)
            items["grid"..i.."_img"]:runAction(CCSequence:createWithTwoActions(CCScaleTo:create(0.3, 1, 1), 
            CCCallFunc:create(function()
                if self:canMove(grid) == false and self.gameState ~= 2 then
                    self:gameOver()
                end
            end)))
        elseif self.actions[i] == 2 then --合成
            print("合成")
            items["grid"..i.."_img"]:setScale(0.5)
            items["grid"..i.."_img"]:runAction(CCScaleTo:create(0.2, 1, 1))
        end
        self.actions[i] = 0
    end

    -- 设置积分
    items.nownum:setString(self.nowpoint)

end

--打印格子
function minigame.printGrid(self, grid)
    local celllen = 8
    local gridStrLines = {}
    table.insert(gridStrLines,"-------------------------------------")
    for i,row in ipairs(grid) do
        local line = {}
        for _,num in ipairs(row) do
            if num==0 then
                local pres = ""
                for tmp=1,celllen do
                    pres = pres .. " "
                end
                local s = string.format("%s",pres)
                table.insert(line,s)
            else
                local s = tostring(num)
                local l = string.len(s)
                local l = (celllen-l)/2
                local prel = math.floor(l)
                local sufl = math.ceil(l)
                local pres = ""
                for tmp=1,prel do
                    pres = pres .. " "
                end
                local sufs = pres
                if sufl>prel then
                    sufs = pres.. " "
                end
                local s = string.format("%s%s%s",pres,s,sufs)
                table.insert(line,s)
            end
        end
        local line = table.concat(line,"|")
        line = "|" .. line .. "|"
        table.insert(gridStrLines,line)
        table.insert(gridStrLines,"-------------------------------------")
    end
    local gridStr = table.concat(gridStrLines,"\n")
    print(gridStr)
end

function minigame.randomGrid(self, grid)
    local m = #grid
    local n = #grid[1]
    for i=1,m do
        for j=1,n do
            local r = math.random(1,5)
            local num = 2^r
            grid[i][j] = num
        end
    end
end

function minigame.getRandomZeroPos(self, grid)
    local m = #grid
    local n = #grid[1]
    local zeros = {}
    for i=1,m do
        for j=1,n do
            if grid[i][j]==0 then
                table.insert(zeros,{i=i,j=j})
            end
        end
    end
    if #zeros>0 then
        local r = math.random(1,#zeros)
        return zeros[r].i,zeros[r].j
    end
end

function minigame.randomNum(self, grid)
    local i,j = self:getRandomZeroPos(grid)
    if i and j then
        local r = math.random()
        if r < 0.9 then
            grid[i][j] = 2
        else
            grid[i][j] = 4
        end
        self.actions[(i-1)*(#grid)+j] = 1
        return i,j
    end
end

function minigame.moveLeft(self, grid)
    print("==============moveLeft===============")
    local m = #grid
    local n = #grid[1]
    for i=1,m do
        local line = {}
        for j=1,n do
            if grid[i][j]~=0 then
                table.insert(line,grid[i][j])
            end
        end
        local k=#line
        for j=1,n do
            if j<=k then
                grid[i][j] = line[j]
            else
                grid[i][j] = 0
            end
        end
        for j=1,k-1 do
            if grid[i][j]==grid[i][j+1] then
                grid[i][j+1] = grid[i][j] + grid[i][j+1]
                self.nowpoint = self.nowpoint + grid[i][j+1]
                if grid[i][j+1] == 2048 then
                    self.now2048 = self.now2048 + 1
                end
                local index = 0
                for x=j,n-1 do
                    grid[i][x] = grid[i][x+1]
                    if index == 0 then
                        index = (i-1)*m+x
                    end
                end
                if index ~= 0 then
                    self.actions[index] = 2
                end
                grid[i][n] = 0
            end
        end
    end
end

function minigame.moveRight(self, grid)
    print("==============moveRight==============")
    local m = #grid
    local n = #grid[1]
    for i=1,m do
        local line = {}
        for j=n,1,-1 do
            if grid[i][j]~=0 then
                table.insert(line,grid[i][j])
            end
        end
        local k = #line
        for j=n,1,-1 do
            if n-j+1<=k then
                grid[i][j] = line[n-j+1]
            else
                grid[i][j] = 0
            end
        end
        for j=n,n-k+2,-1 do
            if grid[i][j]==grid[i][j-1] then
                grid[i][j-1] = grid[i][j] + grid[i][j-1]
                self.nowpoint = self.nowpoint + grid[i][j-1]
                if grid[i][j-1] == 2048 then
                    self.now2048 = self.now2048 + 1
                end
                local index = 0
                for x=j,2,-1 do
                    grid[i][x] = grid[i][x-1]
                    if index == 0 then
                        index = (i-1)*m+x
                    end
                end
                if index ~= 0 then
                    self.actions[index] = 2
                end
                grid[i][1] = 0
            end
        end
    end
    -- self.grid = grid
end

function minigame.moveUp(self, grid)
    print("===============moveUp================")
    local m = #grid
    local n = #grid[1]
    for j=1,n do
        local line = {}
        for i=1,m do
            if grid[i][j]~=0 then
                table.insert(line,grid[i][j])
            end
        end
        local k = #line
        for i=1,m do
            if i<=k then
                grid[i][j] = line[i]
            else
                grid[i][j] = 0
            end
        end
        for i=1,k-1 do
            if grid[i][j]==grid[i+1][j] then
                grid[i+1][j] = grid[i][j] + grid[i+1][j]
                self.nowpoint = self.nowpoint + grid[i+1][j]
                if grid[i+1][j] == 2048 then
                    self.now2048 = self.now2048 + 1
                end
                local index = 0
                for x=i,m-1 do
                    grid[x][j] = grid[x+1][j]
                    if index == 0 then
                        index = (x-1)*m+j
                    end
                end
                if index ~= 0 then
                    self.actions[index] = 2
                end
                grid[m][j] = 0
            end
        end
    end
end

function minigame.moveDown(self, grid)
    print("==============moveDown===============")
    local m = #grid
    local n = #grid[1]
    for j=1,n do
        local line = {}
        for i=m,1,-1 do
            if grid[i][j]~=0 then
                table.insert(line,grid[i][j])
            end
        end
        local k = #line
        for i=m,1,-1 do
            if m-i+1<=k then
                grid[i][j] = line[m-i+1]
            else
                grid[i][j] = 0
            end
        end
        for i=m,m-k+2,-1 do
            if grid[i][j]==grid[i-1][j] then
                grid[i-1][j] = grid[i][j] + grid[i-1][j]
                self.nowpoint = self.nowpoint + grid[i-1][j]
                if grid[i-1][j] == 2048 then
                    self.now2048 = self.now2048 + 1
                end
                local index = 0
                for x=i,2,-1 do
                    grid[x][j] = grid[x-1][j]
                    if index == 0 then
                        index = (x-1)*m+j
                    end
                end
                if index ~= 0 then
                    self.actions[index] = 2
                end
                grid[1][j] = 0
            end
        end
    end
end

function minigame.canMove(self, grid)
    local m = #grid
    local n = #grid[1]
    for i=1,m do
        for j=1,n do
            if grid[i][j]==0 then
                return true
            end
            if (i < m and j < n) then
                if grid[i][j] == grid[i][j+1] then
                    return true
                end
                if grid[i][j] == grid[i+1][j] then
                    return true
                end
            elseif (i == m and j < n)then
                if grid[i][j] == grid[i][j+1] then
                    return true
                end
            elseif (i < m and j == n) then
                if grid[i][j] == grid[i+1][j] then
                    return true
                end
            end
        end
    end
    return false
end

function minigame.equaldata(self, a, b)
    if #a ~= #b then
        return false
    end
    local num = 0
    for i=1, #a do
        for j=1, #a[1] do
            if a[i][j] ~= b[i][j] then
                return false
            end
            if a[i][j] == 0 then
                num = num + 1
            end
        end
    end
    if num == 0 then
        return false
    end
    
    return true
end

function minigame.initGame(self)
    self.gameState = 1
    self.updataTime = 0
    self.rootItems.overLayer:setVisible(false)
    ui.setLabelString(self.rootItems.startlab,"结束挑战",19)

    self.actions = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    self.grid = self:initGrid(4,4)
    self.oldgrid = self:initGrid(4,4)
    self:randomNum(self.grid)
    self:printGrid(self.grid)
    self:setGirdMap(self.rootItems, self.grid)

    UIRequest({type = 1603})

end

--排行榜
function minigame.createRankList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.rankCellSize.x, self.rankCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("moneyboss/cell_moneyboss", nil, true, "cell_moneyboss")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCellRankList(ccbDocumentControler,a1+1)

            cellCCB:setPosition(self.rankCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
                r = table.getTableLength(self.rankdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.rankListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.rankscroll:getContentSize().width,
        viewheight = self.rootItems.rankscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.rankscroll:addChild(self.rankListTableView)
    self.rankListTableView:setTouchPriority(self.touchPriority)
end

function minigame.setCellRankList(self,item,index)

end

--
function minigame.clear(self)

    local maps = {}
    local m = #self.grid
    local n = #self.grid[1]
    for i=1,m do
        for j=1,n do
            maps[(i-1)*m+j] = self.grid[i][j]
        end
    end
    UIRequest({type = 1601, nowpoint = self.nowpoint, now2048 = self.now2048, grid = maps})

    if gameTimer.times["activityChristmasTime"] then
        gameTimer:UnrigistTimeFunc("activityChristmasTime")
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.grid = {}
    self.gameState = 0
    self.updataTime = 0
    
end

return minigame k`  