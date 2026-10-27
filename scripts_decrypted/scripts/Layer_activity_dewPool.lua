local dewPool = {
    buttontouch = -103,

    normalCellSize = {x=1080,y=220+14},
    
    --标签显示
    pageconfig = {"achievement","task","shop"},
    pagename = {"封神之路","露水收集","露水兑换"},
    selectpage = 1,

    achievementListTableView = nil,
    taskListTableView = nil,
    shopListTableView = nil,

    props = {192004,192005},

    data = {
    }
}

function dewPool.init(self,size)
    self.contentsize = size
    self.show = true
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/lushuichi",nil, true, "lushuichi")
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    local _h = self.contentsize.y-180-160-600
    self.listH = _h
    self.rootItems.achievementscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,_h))
    self.rootItems.taskscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,_h))
    self.rootItems.shopscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,_h))

    --显示页签得按钮
    for k=1,3 do
		self.rootItems["planbutton"..k]:setSwallowsTouch(true)
		self.rootItems["planbutton"..k]:setTouchPriority(self.buttontouch)
		self.rootItems["planbutton"..k]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
			self:shiftPage(k)
		end,CCControlEventTouchUpInside)
	end

    self:shiftPage(self.selectpage)

    

    for i=1,2 do
        self.rootItems["iconBtn"..i]:setSwallowsTouch(true)
        self.rootItems["iconBtn"..i]:setTouchPriority(self.buttontouch)
        self.rootItems["iconBtn"..i]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(self.props[i])
        end,CCControlEventTouchUpInside)

        setSpriteFrameByName(self.rootItems["icon"..i], ui.IDconfig(self.props[i]).icon)
    end

    self.firstReload = true
    self:initFixedString()
    self:setRefreshTime()
    return self.rootNode
end

function dewPool.setRefreshTime(self)
    local nowtime = os.date("*t", gamedata:time())

    local fixtimenum = 0
    if nowtime.wday >= 2 then
        fixtimenum = (9-nowtime.wday)*24*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec+1
    else 
        fixtimenum = (2-nowtime.wday)*24*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec+1
    end

    if fixtimenum and fixtimenum > 0 then
        gameTimer:rigistTime("dewPoolRefreshTime",fixtimenum)
        if gameTimer.times["dewPoolRefreshTime"] and gameTimer.times["dewPoolRefreshTime"] > 0 then
            gameTimer:rigistTimeFunc("dewPoolRefreshTime", function()
                if gameTimer.times["dewPoolRefreshTime"] <= 0 then
                    gameTimer:UnrigistTimeFunc("dewPoolRefreshTime")
                    self:setRefreshTime()
                else
                    ui.setLabelString(self.rootItems.time,ui.makeTimeDayText(gameTimer.times["dewPoolRefreshTime"],"day"),22,34)   
                end
            end)
        end
    else
        self:setRefreshTime()       
    end
    --
end

--按钮高亮状态的显示
function  dewPool.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if page == km then
            setSpriteFrameByName(self.rootItems["btnspr"..km], gameConfig.images.pageButtonON)
        else
            setSpriteFrameByName(self.rootItems["btnspr"..km], gameConfig.images.pageButtonOFF)
        end
    end
end

function dewPool.shiftPage(self,type)
    print("shiftPage",type)
    self.selectpage = type or self.selectpage
	
    self:shiftlayerpage(self.selectpage)

	for k,v in ipairs(self.pageconfig) do
		if k == type then
			self.rootItems[v.."scroll"]:setPosition(ccp(0,160))
            self.rootItems["bg"..k]:setVisible(true)
		else
			self.rootItems[v.."scroll"]:setPosition(ccp(0,99999))
            self.rootItems["bg"..k]:setVisible(false)
		end
	end
    self.rootItems.timeNode:setVisible(self.selectpage ~= 1)

    self:setPage()
end

function dewPool.setPage(self)
    print("setPage")
    ui.setLabelString(self.rootItems.desc1,gameConfig.strings:string_common("dewPool", (self.selectpage - 1)*3 + 1),1027)
    ui.setLabelString(self.rootItems.desc2,gameConfig.strings:string_common("dewPool", (self.selectpage - 1)*3 + 2),1027)
    ui.setLabelString(self.rootItems.desc3,gameConfig.strings:string_common("dewPool", (self.selectpage - 1)*3 + 3),1027)

    if not next(self.data) then
        UIRequest({type = 8055})
        return
    end

    local _tag = self.pageconfig[self.selectpage]
    if self[_tag.."ListTableView"] then
        if _tag == "achievement" and self.achievementsChangeNum then
            if self.data[_tag] and next(self.data[_tag]) then
                local totalH = table.getTableLength(self.data[_tag])*self.normalCellSize.y
                self[_tag.."ListTableView"]:setLuaContentOffset(0, self.listH - totalH)
            end
        end

        self[_tag.."ListTableView"]:reloadData()
    else
        self["creareList".._tag](self)
    end
end

function dewPool.creareListachievement(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_lushuichi", nil, true, "cell_lushuichi")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local data = self.data.achievement[tostring(a1+1)]
            local reward = ui.getIDandNUMs(data.reward)[1]

            if reward then
                ui.setNewIcon(ccbDocumentControler,reward)
            end

            ccbDocumentControler.unlocknode:setVisible(false)
            if data.status == 0 then
                ccbDocumentControler.nonenode:setVisible(true)
                ccbDocumentControler.getNode:setVisible(false)
                ccbDocumentControler.hasnode:setVisible(false)
            elseif data.status == 1 then
                ccbDocumentControler.nonenode:setVisible(false)
                ccbDocumentControler.getNode:setVisible(true)
                ccbDocumentControler.hasnode:setVisible(false)
            elseif data.status == 2 then
                ccbDocumentControler.nonenode:setVisible(false)
                ccbDocumentControler.getNode:setVisible(false)
                ccbDocumentControler.hasnode:setVisible(true)
            end

            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(reward.cid)
            end, CCControlEventTouchUpInside)
            ccbDocumentControler["i_button"]:setTouchPriority(-102)

            ccbDocumentControler.getbutton:setTouchPriority(-102)
            ccbDocumentControler.getbutton:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                if gameTouch.isScrollling then return end

                UIRequest({type = 8056,method = 1,_type = data.type, id = data.id})
            end, CCControlEventTouchUpInside)

            ui.setLabelString(ccbDocumentControler.gettext,nil,18)

            ccbDocumentControler.name:setString(data.name)
            ccbDocumentControler.desc:setString(data.desc)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.achievement)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.achievementListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.achievementscroll:getContentSize().width,
        viewheight = self.rootItems.achievementscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.achievementscroll:addChild(self.achievementListTableView)
    self.achievementListTableView:setTouchPriority(-101)
end

function dewPool.creareListtask(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_lushuichi", nil, true, "cell_lushuichi")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local data = self.data.task[tostring(a1+1)]
            local reward = ui.getIDandNUMs(data.reward)[1]

            if reward then
                ui.setNewIcon(ccbDocumentControler,reward)
            end

            ccbDocumentControler.unlocknode:setVisible(false)
            ccbDocumentControler.getNode:setVisible(false)
            ccbDocumentControler.hasnode:setVisible(false)
            ccbDocumentControler.nonenode:setVisible(false)

            if data.status == 0 then
                ccbDocumentControler.nonenode:setVisible(true)
            elseif data.status == 1 then
                ccbDocumentControler.getNode:setVisible(true)
            elseif data.status == 2 then
                ccbDocumentControler.hasnode:setVisible(true)
            elseif data.status == -1 then
                ccbDocumentControler.unlocknode:setVisible(true)
            end

            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(reward.cid)
            end, CCControlEventTouchUpInside)
            ccbDocumentControler["i_button"]:setTouchPriority(-102)

            ccbDocumentControler.getbutton:setTouchPriority(-102)
            ccbDocumentControler.getbutton:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                if gameTouch.isScrollling then return end

                UIRequest({type = 8056,method = 2,_type = data.type, id = data.id})
            end, CCControlEventTouchUpInside)

            ui.setLabelString(ccbDocumentControler.gettext,nil,18)

            
            if data.status == -1 then
                ccbDocumentControler.desc:setString(data.locked_desc)
                ccbDocumentControler.name:setString(data.name)
            else
                ccbDocumentControler.name:setString(data.name.."("..data.now.."/"..data.param..")")
                ccbDocumentControler.desc:setString(data.desc)
            end
            

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.task)
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

function dewPool.creareListshop(self)
    print("creareListshop")
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 320)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_lushuichishop", nil, true, "cell_lushuichishop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end


            self:setone(self.data.shop[tostring((a1+1)*2-1)],ccbDocumentControler,1)
            if self.data.shop[tostring((a1+1)*2)] then
                self:setone(self.data.shop[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            
            cellCCB:setPosition(1080/2, -8)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.data.shop)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.shopListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.shopscroll:getContentSize().width,
        viewheight = self.rootItems.shopscroll:getContentSize().height,
        dire = 1
    })
    self.shopListTableView:setTouchPriority(-101)
    self.rootItems.shopscroll:addChild(self.shopListTableView)
end

function dewPool.setone(self,data,items,index)
    print("index==",index,data.id)
    local key_Ex
    local icon_key
    if index == nil or index == 1 then
        key_Ex = ""
        icon_key = ""
    else
        key_Ex = "_2"
        icon_key = "_1"
    end

    local config = table.copy(gamedata.config.dew_pool_shop[tostring(data.id)])

    if not config  then
        print("notid===",data.id)
        return
    end

    local timesstring = "剩余:"..(config.limit-data.num)

    if config.limit and config.limit <= 0 then
        config.limit = 99999
        timesstring = ""
    end    

    items["desc"..key_Ex]:setString(timesstring)
    ui.setLabelString(items["desc"..key_Ex],nil,14)
    
    local spenddata = ui.getIDandNUMs(config.cost)[1]
    local propnum = self.data.props[tostring(spenddata.cid)] or 0
    
    local spendConfig = ui.IDconfig(spenddata.cid)
    if propnum >= math.floor(spenddata.num) then
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata.num),14)
    else
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata.num),27)
    end
    setSpriteFrameByName(items["usesprite"..key_Ex], spendConfig.icon)

    local goods = ui.getIDandNUMs(config.goods)[1]
    local goodsConfig = ui.IDconfig(goods.cid)

    items["name"..key_Ex]:setString(goodsConfig.name)
    if goodsConfig.quality and goodsConfig.quality >= 7 then
        ui.setLabelString(items["name"..key_Ex],nil,213)
    else
        ui.setLabelString(items["name"..key_Ex],nil,((goodsConfig.quality and goodsConfig.quality ~= 0) and goodsConfig.quality or 1)*2-1)
    end

    ui.setNewIcon(items,{cid = goods.cid, num = goods.num},index-1)
    --
    items["i_button"..icon_key]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        ui.setPopwindowByCid(goods.cid)
    end, CCControlEventTouchUpInside)
    items["i_button"..icon_key]:setTouchPriority(-102)
    --

    ui.setLabelString(items["exchangeText"..key_Ex],nil,18)

    items["exchange"..key_Ex]:setTouchPriority(-102)
    items["exchange"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end

        gameTouch:clickprofbytime(0.5)
        if config.limit-data.num <= 0 then
            runGamePrompt({msg = "超出兑换次数限制"})
        elseif propnum < math.floor(spenddata.num) then
            runGamePrompt({msg = spendConfig.name.."数量不足"})
        else

            local cb = function (  )
                UIRequest({type = 8057, id = data.id,spenddata = spenddata})
            end

            local rich = {
                {fontID = 1,content = "是否消耗 ",},
                {fontID = 0,content = spendConfig.icon,scale = 0.5},
                {fontID = 11,content = " "..spenddata.num,},
                {fontID = 1,content = "，\n兑换",},
                {fontID = 11,content = goodsConfig.name,},
            }
            gameWindows:openWindow("confirm",{rich = rich}, cb) 
        end

    end, CCControlEventTouchUpInside)

    if config.limit-data.num <= 0 then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
        -- items["soldoutNode"..key_Ex]:setVisible(true)
    else
        ui.removeGray("CCControlButton",items["exchange"..key_Ex])
        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
        -- items["soldoutNode"..key_Ex]:setVisible(false)
    end

end

function dewPool.reloaddata(self,data)
    if not self.show then return end



    --条数量是否有增加
    self.achievementsChangeNum = false

    if self.data.achievement and next(self.data.achievement) and data.achievement and next(data.achievement) then
        if table.getTableLength(data.achievement) > table.getTableLength(self.data.achievement) then
            self.achievementsChangeNum = true
        end
    end
    print("self.achievementsChangeNum",self.achievementsChangeNum)

    self.data = data
    if self.firstReload then
        self.firstReload = false

        local isallreward = true
        for k,v in pairs(self.data.achievement) do
            if v.status ~= 2 then
                isallreward = false
                break
            end
        end

        --全部领取显示第二个
        if isallreward then
            self.selectpage = 2
        end
    end

    self.rootItems.num1:setString(self.data.props["192004"])
    self.rootItems.num2:setString(self.data.props["192005"])
    ui.setLabelString(self.rootItems.num1,nil,1027)
    ui.setLabelString(self.rootItems.num2,nil,1027)

    self:shiftPage(self.selectpage)
    self:reloadHint()
end

function dewPool.reloadHint(self)

    ui.sethint(self.rootItems.hint1,false)
    ui.sethint(self.rootItems.hint2,false)

    for k,v in pairs(self.data.achievement) do
        if v.status == 1 then
            ui.sethint(self.rootItems.hint1,true)
            break
        end
    end

    for k,v in pairs(self.data.task) do
        if v.status == 1 then
            ui.sethint(self.rootItems.hint2,true)
            break
        end
    end

end

function dewPool.initFixedString(self)
    ui.setLabelString(self.rootItems.fixed1,nil,1027)
    ui.setLabelString(self.rootItems.timeLab,nil,1027)
end

function dewPool.clear(self)
    gameTimer:UnrigistTimeFunc("dewPoolRefreshTime")
    
    self.achievementListTableView = nil
    self.taskListTableView = nil
    self.shopListTableView = nil

    self.data = {
    }

    self.show = false
    self.selectpage = 1
    self.rootNode = nil
    self.rootItems = nil  
end

return dewPool   N  