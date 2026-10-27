--
-- User: zhangzhixin
-- 足迹弹窗(kingfoot 日常->王的男人)
-- 难度选择 (kingselect)

local kingfootmark = {
    rootNode = nil,
    rootItems = nil,
    days = {0,0,0},--日期号
    cellSize= {x = 900,y= 310},
    png = {
    	[1] = "km_4.png",
    	[2] = "km_3.png",
    },
    attBossData = {}, --boss属性
    isscrolltouched = false,
}

-- data
-- {type = kingfoot} 足迹
-- {type = kingselect, data = {服务器数据} }
function kingfootmark.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.attConfigData = gamedata.config.personalboss_att
    -- print("attConfigData ======")
    -- printT(self.attConfigData)   
    print("kingfootmark ===========")  
    printT(data)
    self.root = ui.createNode()
    self:shiftPage(data,callback)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("kingfoot")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority) 
    self.rootItems.closeButton:setSwallowsTouch(true)  



    return self.root
end

function kingfootmark.close(self)
    gameTouch:UnrigistFunc("begin","activityshop")
    gameTouch:UnrigistFunc("end","activityshop")
    self.isscrolltouched = false,   
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.days = {0,0,0}
    self.attBossData = {}
    self.type = nil
end

function kingfootmark.shiftPage(self,data,callback)
    self.type = data.type
    if data.type == "kingfoot" then
	    self.rootNode,self.rootItems = CCBReaderLoad("kingman/kingman_zuji", nil, true, "kingfoot")
	    self.root:addChild(self.rootNode)
	    self.dateConfigData = gamedata.config.personalboss_date
	    -- print("dateConfigData ======")
	    -- printT(self.dateConfigData)  

	    self:getDays()
	    self:createFootList()      
    else
	    self.rootNode,self.rootItems = CCBReaderLoad("kingman/kingman_xuanze", nil, true, "kingselect")
	    self.root:addChild(self.rootNode)
	    self.data = data.data
	    self:setBossLevelTable(data.data.bosstype)
        ui.setLabelString(self.rootItems.battletimes,nil,13)
        -- local tTimes = gamedata.config.global_kv["personalboss_"..self.data.bosstype].value-self.data.battlenum+GameScene.vipstatus.personalboss_times
        local tTimes = gamedata.config.vip[tostring(0)]["personalboss_times"]-self.data.battlenum+GameScene.vipstatus.personalboss_times

        if tTimes <= 0 then
            ui.setLabelString(self.rootItems.times,0,24)
        else
            ui.setLabelString(self.rootItems.times,tTimes,13)
        end 
        self:createLevelList() 


        self.rootItems.addTimes:addHandleOfControlEvent(function()
            -- gameWindows:closeWindow("kingfoot")
            singlebossBuyTimes()

        end, CCControlEventTouchUpInside)
        self.rootItems.addTimes:setTouchPriority(self.touchPriority) 
        self.rootItems.addTimes:setSwallowsTouch(true) 


    end
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","window_kingfoot",touchbegin)
    local function touchend(pos)
        if self.rootItems and self.rootItems.listScroll and ui.isTouched(self.rootItems.listScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","window_kingfoot",touchend)      
end
--获得后3天数日期号
function kingfootmark.getDays(self)
	local newtime = gamedata:time()
	self.days = {os.date("*t", newtime+ 86400),os.date("*t", newtime + 172800),os.date("*t", newtime + 259200)}
end
--获得当前boss数据
function kingfootmark.setBossLevelTable(self,aiType)
    self.attBossData = {}
	for k,v in pairs(self.attConfigData) do
		if v["function"] == aiType then
			table.insert(self.attBossData,v)
		end
	end
    local sortfun = function(a,b)
        return a.id < b.id 
    end
	table.sort( self.attBossData,sortfun)
end
function kingfootmark.createFootList(self)
    local celldict = {}
    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.x, self.cellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kingman/cell_zuji.ccbi", nil, true, "cell_zuji")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
           	self:setFootCell(ccbDocumentControler,a1)
            if first then
            	cellCCB:setPosition(self.cellSize.x/2, self.cellSize.y/2)   
            end      
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = #self.days
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.footListTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.footListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listScroll:addChild(self.footListTableView)

end
function kingfootmark.setFootCell(self,aiCell,aiIndex)
	print("kingfootmark.setCell =====")
	local bossIndex = self.dateConfigData[tostring(self.days[aiIndex + 1].day)].boss
	local bossdata = nil
	for k,v in pairs(self.attConfigData) do
		if tonumber(k)%100 == 1 and v["function"] == bossIndex then
			bossdata = v
			break
		end
	end
	setSpriteFrameByName(aiCell.bg,self.png[bossIndex])
	local s = self.days[aiIndex + 1].month.."月"..self.days[aiIndex + 1].day.."日00点开启"
	ui.setLabelString(aiCell.timeText,s,14)
	ui.setLabelString(aiCell.desc,bossdata.desc,21)
end

function kingfootmark.createLevelList(self)
    local celldict = {}
    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.x, self.cellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("kingman/cell_nandu.ccbi", nil, true, "cell_selectlevel")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
           	self:setLevelCell(ccbDocumentControler,a1)
            if first then
            	cellCCB:setPosition(self.cellSize.x/2, self.cellSize.y/2)   
            end      
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            if self.data.openlevel + 2 >= self.attBossData[#self.attBossData].id then
                r = table.getTableLength(self.attBossData)
            elseif self.data.openlevel == 0 then
                r = 2
            else
                local function a()
                        for i = table.getTableLength(self.attBossData),1,-1 do
                            if self.data.openlevel  == self.attBossData[i].id then
                                return i + 2
                            end
                        end
                    end
                r = a()
            end
            self.showCellNum = r
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.levelListTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.levelListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listScroll:addChild(self.levelListTableView)
    --
end
function kingfootmark.setLevelCell(self,aiCell,aiIndex)
	print("kingfootmark.setLevelCell ==========")
    -- print("openlevel = "..self.data.openlevel .." aiIndex = "..aiIndex)
    -- 双倍掉落判断
    if aiCell.isrewarddouble then
        local datatmp = ui.CheckHuodongByParam(4)
        -- local datatmp = ui.CheckHuodongByParam(1)
        -- local timesnum = ui.GetHuodongModulus(4)
        if datatmp then
            aiCell.isrewarddouble:setVisible(true)
            ui.setLabelString(aiCell.isrewarddouble, gameConfig.strings:string_common("doublereward",1), 24)
        else
            aiCell.isrewarddouble:setVisible(false)
        end
    end
    

    local useddata = 0
    local msg_openLevel = 0 --用户格外给用户显示看的
    useddata = self.attBossData[self.showCellNum - aiIndex]
    if self.data.openlevel + 2 <= self.attBossData[#self.attBossData].id and 0 == aiIndex  then
        msg_openLevel = self.attBossData[self.showCellNum - aiIndex -1].level or self.attBossData[1].level
        ui.addGray("CCSprite",aiCell.clickImage)
    else
        ui.removeGray("CCSprite",aiCell.clickImage)
    end
	--setSpriteFrameByName(aiCell.bg,self.png[useddata["function"]])

    aiCell.bg1:setVisible(useddata["function"] == 1)
    aiCell.bg2:setVisible(useddata["function"] == 2)

	aiCell.levelText:setString(useddata.level.."级开启")
    if GameScene.roleinfo.level < useddata.level then
        
        ui.addGray("CCLabelBMFont",aiCell.levelText)
        
        -- ui.addGray("CCSprite",aiCell.bg)
        -- ui.addGray("CCLabelBMFont",aiCell.clickImage)
        -- ui.addGray("CCLabelBMFont",aiCell.introduceText)
        -- ui.addGray("CCControlButton",aiCell.button)
        -- ui.addGray("CCControlButton",aiCell.introduce)
    else
        ui.removeGray("CCLabelBMFont",aiCell.levelText)
    end
    aiCell.button:setTouchPriority(self.touchPriority)
    aiCell.button:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        -- if self.data.battlenum >= (tonumber(gamedata.config.global_kv["personalboss_"..self.data.bosstype].value)+GameScene.vipstatus.personalboss_times) then
        if self.data.battlenum >= (tonumber(gamedata.config.vip[tostring(0)]["personalboss_times"])+GameScene.vipstatus.personalboss_times) then
            -- gamedata.config.vip[tostring(0)]["personalboss_times"]
            runGamePrompt({msg = "挑战次数不足"})
            singlebossBuyTimes()
        elseif GameScene.roleinfo.level < useddata.level then
        	runGamePrompt({msg = "等级不足"})
        elseif msg_openLevel > 0 then 
            runGamePrompt({msg = "请先挑战过"..msg_openLevel.."级难度"})
        else
        	print("请求攻打boss boss ID = "..useddata.id)
            UIRequest({type = 3701,id = useddata.id})
    	end
    end, CCControlEventTouchUpInside)

    aiCell.introduce:setSwallowsTouch(true)
    aiCell.introduce:setTouchPriority(self.touchPriority-1)
    aiCell.introduce:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        print("boss详情 boss data = ")
        gameWindows:openWindow("bossDetail", {num = useddata.id}, nil)
    end, CCControlEventTouchUpInside)

    aiCell.showitem:setSwallowsTouch(true)
    aiCell.showitem:setTouchPriority(self.touchPriority-1)
    aiCell.showitem:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        -- 双倍掉落判断
        local datatmp = ui.CheckHuodongByParam(4)
        -- local datatmp = ui.CheckHuodongByParam(1)

        print("boss掉落 boss ID = ")
        printT(useddata)
        gameWindows:openWindow("copyacivityitem",{type = "boosfall", data = useddata, isrewarddouble = datatmp})
    end, CCControlEventTouchUpInside)       
end
--请求攻打boss回调处理
function kingfootmark.reloaddata( self ,aiData )
    if self.type == "kingfoot" then  return end
    self.data = aiData.boss
    -- local tTimes = gamedata.config.global_kv["personalboss_"..self.data.bosstype].value-self.data.battlenum+GameScene.vipstatus.personalboss_times
    local tTimes = gamedata.config.vip[tostring(0)]["personalboss_times"]-self.data.battlenum+GameScene.vipstatus.personalboss_times

    if tTimes <= 0 then
        ui.setLabelString(self.rootItems.times,0,24)
    else
        ui.setLabelString(self.rootItems.times,tTimes,13)
    end
    self.levelListTableView:reloadData()
    if aiData.isNextLevelOpen == 1 then
        self.levelListTableView:setLuaContentOffset(0, self.rootItems.listScroll:getContentSize().height - self.showCellNum *self.cellSize.y)
    end
end
return kingfootmark _4  