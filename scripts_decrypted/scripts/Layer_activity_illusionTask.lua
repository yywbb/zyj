local illusionTask = {
    buttontouch = -103,

    normalCellSize = {x=1080,y=220+14},
    
    taskListTableView = nil,
    activityid = 177,
    data = {
    }
}

function illusionTask.init(self,size)
    self.contentsize = size
    self.show = true
    self.onceHint = true
    GameScene:hintDataExt()
    UIRequest({type = 10322, param = {}})

    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/huanhuaguan",nil, true, "huanhuaguan")
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)
    self.rootItems.taskscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y - 180 - 680))
    local activitydata = GameScene.layers["activity"].module:getDailyCPActivityDataById(tonumber(self.activityid))
    self.config = gamedata.config["illusion_task_"..activitydata.cpnum]

    self.rootItems["swallow_btn"]:setSwallowsTouch(true)
    self.rootItems["swallow_btn"]:setTouchPriority(-200)
    self.rootItems["swallow_btn"]:addHandleOfControlEvent(function()
    end, CCControlEventTouchUpInside)

    self:initFixedString()
    self:setRefreshTime()
    return self.rootNode
end

function illusionTask.setRefreshTime(self)
	local timediff = GameScene.layers["activity"].module:getActivityRemainingTime(tonumber(self.activityid))
    if timediff > 0 then
        gameTimer:rigistTime("illusionTaskRefreshTime",timediff)
        gameTimer:rigistTimeFunc("illusionTaskRefreshTime", function()
            if gameTimer.times["illusionTaskRefreshTime"] <= 0 then
                gameTimer:UnrigistTimeFunc("illusionTaskRefreshTime")
                self:setRefreshTime()
            else
                ui.setLabelString(self.rootItems.time,ui.makeTimeDayText(gameTimer.times["illusionTaskRefreshTime"],"day"),22,34)   
            end
        end)
    else
        self:setRefreshTime()       
    end
end

function illusionTask.creareListtask(self)
	local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_huanhuaguan", nil, true, "cell_huanhuaguan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local data = self.data[a1+1]
            self:setCell(ccbDocumentControler,data)
            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.taskListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.taskscroll:getContentSize().width,
        viewheight = self.rootItems.taskscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.taskscroll:addChild(self.taskListTableView)
    self.taskListTableView:setTouchPriority(-101)
end

function illusionTask.setCell(self,items,data)
    items.node1:setVisible(false)
    items.node2:setVisible(false)
    items.getNode:setVisible(false)
    items.rechargeNode:setVisible(false)
    items.hasnode:setVisible(false)
    items.nonenode:setVisible(false)
    items.timeslab:setString("")
    items.progresslab:setString("")

    --icon显示 描述信息
	local config = self.config[tostring(data.id)]
    items.name:setString(config.name)
    if config.type ~= 1 and config.type ~= 4 then
        items.progresslab:setString(string.format("（%d/%d）", math.min(data.now,config.param1),config.param1))
        items.progresslab:setPositionX(items.name:getPositionX() + items.name:getContentSize().width + 3)
    end
    items.desc:setString(config.desc)

    local props1 = gamedata.getIDandNUMs(config.param2)[1]
    local props2 = gamedata.getIDandNUMs(config.reward)[1]
    if config.type ~= 4 then
        ui.setNewIcon(items,props2)
        items["i_button"]:setTouchPriority(-103)
        items["i_button"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(props2["cid"])
        end, CCControlEventTouchUpInside)
    else
        ui.setNewIcon(items,props1)
        ui.setNewIcon(items,props2,1)
        if props1 and props1.cid == 1001 and GameScene.roleinfo.gold < props1.num then
            ui.setLabelString(items["i_num"], nil, 24)
        else
            ui.setLabelString(items["i_num"], nil, 13)
        end

        items["i_button"]:setTouchPriority(-103)
        items["i_button"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(props1["cid"])
        end, CCControlEventTouchUpInside)

        items["i_button_1"]:setTouchPriority(-103)
        items["i_button_1"]:addHandleOfControlEvent(function()
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(props2["cid"])
        end, CCControlEventTouchUpInside)
    end

    ui.setLabelString(items.getlab,gameConfig.strings:string_common("buttontext",config.type == 4 and "goumai" or "lingqu"),18)
    --领取 购买按钮
    if config.type == 1 and data.now >= config.param1 then
        ui.addGray("CCControlButton",items.getbtn)
        ui.addGray("CCLabelTTF",items.getlab)
    elseif config.type == 4 and data.now >= config.param1 then
        ui.addGray("CCControlButton",items.getbtn)
        ui.addGray("CCLabelTTF",items.getlab)
    else
        ui.removeGray("CCControlButton",items.getbtn)
        ui.removeGray("CCLabelTTF",items.getlab)
    end

    items["getbtn"]:setTouchPriority(-103)
    items["getbtn"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if config.type == 1 and data.now >= config.param1 then
            runGamePrompt({msg = gameConfig.strings:string_common("huanhua",18)})
        elseif config.type == 4 then
            if data.now >= config.param1 then
                runGamePrompt({msg = gameConfig.strings:string_common("huanhua",19)})
            elseif props1 and props1.cid == 1001 and GameScene.roleinfo.gold < props1.num then
                shortGold()
            else
                local cb = function ()
                    UIRequest({type = 8118,id = data.id,cost = props1})
                end
                if props1 and next(props1) then
                    local rich = {
                        {fontID = 1,content = "是否消耗",},
                        {fontID = 11,content = props1.num..ui.IDconfig(props1.cid).name,},
                        {fontID = 1,content = "购买",},
                        {fontID = 11,content = ui.IDconfig(props2.cid).name,},
                        {fontID = 1,content = "？",},
                    }
                    gameWindows:openWindow("confirm",{rich = rich}, cb)
                else
                    cb()
                end
            end
        else
            UIRequest({type = 8118,id = data.id})
        end

    end, CCControlEventTouchUpInside)

    
    ui.setLabelString(items.rechargelab,gameConfig.strings:string_common("buttontext","chongzhi"),18)
    items["rechargebtn"]:setTouchPriority(-103)
    items["rechargebtn"]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)


	if config.type == 1 then
        items.node2:setVisible(true)
        items.getNode:setVisible(true)
        items.timeslab:setString(gameConfig.strings:string_common("huanhua",16)..math.max(0,(config.param1 - data.now)))
    elseif config.type == 3 then
        items.node2:setVisible(true)
        if data.status == 0 then
            items.rechargeNode:setVisible(true)
        elseif data.status == 1 then
            items.getNode:setVisible(true)
        elseif data.status == 2 then
            items.hasnode:setVisible(true)
        end
    elseif config.type == 4 then
        items.node1:setVisible(true)
        items.getNode:setVisible(true)
        items.timeslab:setString(gameConfig.strings:string_common("huanhua",17)..math.max(0,(config.param1 - data.now)))
    else
        items.node2:setVisible(true)
        if data.status == 0 then
            items.nonenode:setVisible(true)
        elseif data.status == 1 then
            items.getNode:setVisible(true)
        elseif data.status == 2 then
            items.hasnode:setVisible(true)
        end
    end

end

function illusionTask.reloaddata(self,data)
    if not self.show then return end

    if data and data.task then
        local task = {}
        for k,v in pairs(data.task) do
            local config = self.config[tostring(v.id)]
            local sort = 0
            if (v.status == 1 and config.type ~= 1 and config.type ~= 4) then
                sort = sort + 10000000
            elseif config.type == 1 and v.now < config.param1 then
                sort = sort + 1000000
            elseif config.type == 4 and v.now < config.param1 then
                sort = sort + 100000
            elseif config.type == 3 and v.now < config.param1 then
                sort = sort + 10000
            elseif (v.status == 0 and config.type ~= 1 and config.type ~= 4) then
                sort = sort + 1000
            end
            sort = sort + (500 - config.order)
            v.sort = sort
            table.insert(task,v)
        end

        table.sort(task,function ( a,b)
            return a.sort > b.sort
        end)
        self.data = task
    end

    printT(self.data)
    self:setTipShow()
    if self.taskListTableView then
    	self.taskListTableView:reloadData()
    else
    	self:creareListtask()
    end
end

function illusionTask.setTipShow(self)
    self.rootItems.desc:setVisible(false)
    for k,v in pairs(self.data) do
        local config = self.config[tostring(v.id)]
        if config.type == 2 then
            self.rootItems.desc:setVisible(true)
            break
        end
    end
end

function illusionTask.initFixedString(self)
    ui.setLabelString(self.rootItems.timeLab,nil,1027)
end

function illusionTask.clear(self)
    gameTimer:UnrigistTimeFunc("illusionTaskRefreshTime")
    self.taskListTableView = nil
    self.data = {
    }
    self.show = false
    self.rootNode = nil
    self.rootItems = nil  
end

return illusionTask�*  