--
-- Author: songyibo
-- Date: 2020-02-10 17:01:13
--
local logerr = require("logError")
local gameHelperLog = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {x = 980,y = 200},
    ListTableView = nil,
    showtimer = nil,
    data = {},
    copyData = nil,
}

--[[
    错误码

    60 该活动副本未开启
    61 没有可扫荡的关卡
    62 重置次数不足
    63 灭神殿扫荡中，请勾选立即完成与重置
    64 未到扫荡极限，请勾选立即完成
    65 重置次数大于1，请勾选立即完成
    66 挑战次数不足
    67 观星次数不足
    68 免费扔骰子次数已达上限
    69 骰子数不足
    70 请选择挑战次数
    71 任务类型不存在
    72 最高层小于5层不可扫荡
    73 冠军试炼开箱次数不能为0

    269 已拜神
    270 请选择拜神类型
    271 拜神类型不存在
    272 公会福利已领取

    207 协助次数不足
    208 好友小妖数不足


    209 没有好友
    210 没有可送礼好友
    213 没有可收好友礼物
    214 没有可收好友礼物且没有可送礼好友
    215 送礼完成，没有可收好礼礼物
    216 收礼完成，没有可送礼好友
    217 建筑大厅至少为1级
    975 上阵位已存在武将
    976 请设置挑战阵容
    1013  无可领奖位置
    979 上阵位未通关

    981 武将已上阵
    982 没有上阵武将
    983 时间配置错误
    984 没有可操作关卡

    1013 无可领奖位置（天庭银座执行 一键上阵、一键收获 无可收获）
]]

function gameHelperLog.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.callback = callback
    self.rootNode,self.rootItems = CCBReaderLoad("youxizhushou/tc_zhushourizhi", nil, true, "tc_zhushourizhi")

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("gameHelperLog")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    

    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("gameHelperLog")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority - 10)
  	 
    if data.data then
        self.data = data.data
    elseif self.copyData then
        self.data = self.copyData
    end
  	
  	self.method = data.method

    self:initTouch()
    self:reload(self.data)
    self:initFixedString()
    return self.rootNode
end

function gameHelperLog.initTouch(self)
    local function ccTouchBegan(x, y)
        self.isContentScroll = false
        self.touchX = x
        return true
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 10 then
            self.isContentScroll = true
        end
    end

    local function ccTouchEnded(x, y)
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, self.touchPriority, false)
    self.rootItems.touchLayer:setTouchPriority(self.touchPriority - 2)
    self.rootItems.touchLayer:setTouchEnabled(true)
end

function gameHelperLog.reload(self,data)
	printT(data,"gameHelperLog")

    local rewards = {}
    if data then
        for i=1,table.getTableLength(data.rewards) do
        	rewards[i] = data.rewards[tostring(i)] or data.rewards[i]
        end
    end
	self.rewards = rewards
    self.copyData = table.copy(self.data)

    if self.method == "log" then
        self:createList()
    else
        -- self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(2),CCCallFunc:create(function()
            
            
        -- end)))

        print("createScrollView_b",os.clock())
        self:createScrollView()
        print("createScrollView_e",os.clock())
    end

end

function gameHelperLog.createList(self)
    print("createList")
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.x, self.cellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("youxizhushou/cell_zhushourizhi", nil, true, "cell_zhushourizhi")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler,self.rewards[a1+1], a1+1)

            cellCCB:setPosition(self.cellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.ListNode:getContentSize().width,
        viewheight = self.rootItems.ListNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.ListNode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)

    -- self.ListTableView:setLuaContentOffset(0, 0)
end

function gameHelperLog.createScrollView(self)
    print("createScrollView")

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    print(self.rootItems.scrollnode)
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)

    self.rootItems.touchButton:addHandleOfControlEvent(function()
    end, CCControlEventTouchUpInside)
    self.rootItems.touchButton:setSwallowsTouch(true)
    self.rootItems.touchButton:setTouchPriority(self.touchPriority - 10)

    self.celldict = {}
    self.rootItems.touchButton:setTouchEnabled(true)

    ui.addGray("CCControlButton",self.rootItems.doButton)
    ui.addGray("CCLabelTTF",self.rootItems.doLab)

    self.firsttimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        print("firsttimer")
        self:createCell()
        self:startTimer()
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.firsttimer)
        self.firsttimer = nil
    end, 0.3, false)

end

function gameHelperLog.startTimer(self)
    self.showtimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        print("showtimer")
        self:createCell()
    end, 1, false)
end


function gameHelperLog.createCell(self)
	if not next(self.rewards) then
        self.rootItems.touchButton:setTouchEnabled(false)
		self:stopTimer()

        ui.removeGray("CCControlButton",self.rootItems.doButton)
        ui.removeGray("CCLabelTTF",self.rootItems.doLab)

		return
	end
	local reward = table.remove(self.rewards,1)
	if not reward then
		self:stopTimer()
		return
	end
	local ccb,items = CCBReaderLoad("youxizhushou/cell_zhushourizhi", nil, true, "cell_zhushourizhi")
	table.insert(self.celldict,{ccb = ccb,items = items})
	ccb:setPosition(self.cellSize.x/2,(#self.celldict - 1)*self.cellSize.y)
	self.rootItems.container:addChild(ccb)
	self:setCell(items,reward,#self.celldict)
	self.rootItems.container:setContentSize(CCSizeMake(self.cellSize.x,#self.celldict * self.cellSize.y))

	for i=#self.celldict,1,-1 do
		local ccb = self.celldict[i].ccb
		ccb:setPosition(self.cellSize.x/2,(#self.celldict - i)*self.cellSize.y)
	end

    local contentH = 880
	if #self.celldict > 5 then
		self.rootItems.container:setPositionY(-self.cellSize.y)
		self.rootItems.container:runAction(CCMoveBy:create(0.3,ccp(0,self.cellSize.y)))
    elseif #self.celldict == 5 then
        local offy = contentH - self.cellSize.y * #self.celldict
        self.rootItems.container:setPositionY(offy)
        self.rootItems.container:runAction(CCMoveBy:create(0.3,ccp(0,-offy)))
    else
        self.rootItems.container:setPositionY(contentH - self.cellSize.y * #self.celldict)
	end

end

function gameHelperLog.setCell(self,items,data,index)
    local reward = data.reward
    items.des1:setString("")
    items.des2:setString("")
	if next(reward) then
	elseif data.errorcode and data.errorcode > 0 then

        if logerr.errorMessage[data.errorcode] then
            if data.errorcode == 1013 then
                items.des1:setString(gameConfig.strings:string_common("gameHelper",35))
            else
                items.des1:setString(gameConfig.strings:string_common("gameHelper",32))
            end
            items.des2:setString("("..logerr.errorMessage[data.errorcode]..")")
        else
            items.des1:setString(gameConfig.strings:string_common("gameHelper",32)..data.errorcode)
        end
    else
        
        --好友送礼
        if data.type == 3 and data.id == 7 and data.index == 2 then
            items.des1:setString(string.format("好友送礼完成，赠送%d个礼物", self.data.friendgift))
        elseif data.type == 3 and data.id == 8 and data.index == 2 then
            items.des1:setString(string.format("一键添加完成，添加了%d个伙伴", self.data.ttyzGeneralNum))
        elseif data.type == 3 and data.id == 1 and data.index == 2 then
            items.des1:setString(string.format("重置成功%d次", self.data.mieshendianResetNum))
        elseif data.type == 3 and data.id == 1 and data.index == 3 then
            items.des1:setString(string.format("立即完成%d次成功", self.data.mieshendianInstantlyComplete))
        else
            items.des1:setString(gameConfig.strings:string_common("gameHelper",35))
        end
	end

    if data.params and data.params.type == 1 then
        items.des1:setString(gameConfig.strings:string_common("gameHelper",36))
    end


    local cw1 = items.des1:getContentSize().width
    local cw2 = items.des2:getContentSize().width
    local originx = -(cw1+cw2)/2
    items.des1:setPositionX(originx)
    items.des2:setPositionX(originx + cw1)


    items.scrollnode = tolua.cast(items.scrollNode, "CCScrollView")
    items.scrollnode:setTouchPriority(self.touchPriority - 1)
    items.container:removeAllChildrenWithCleanup(true)

    local w_ = 0
    local diff = 30
    for i=1,table.getTableLength(reward) do
        local ccb,item = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
        ccb:setPosition(50 + (diff + 90) * (i-1),50)
        ccb:setScale(0.55)
        w_ = ccb:getPositionX() + 50
        items.container:addChild(ccb)

        ui.setNewIcon(item,reward[tostring(i)])
        item["i_button"]:setTouchPriority(self.touchPriority-1)
        item["i_button"]:addHandleOfControlEvent(function()
            if not self.isContentScroll then
                ui.setPopwindowByCid(reward[tostring(i)].cid)
            end
        end, CCControlEventTouchUpInside)
    end

    items.container:setContentSize(CCSize(w_,100))
    -- items.scrollnode:setViewSize(CCSizeMake(w_ < 850 and w_ or 850,100))
    items.scrollnode:setViewSize(CCSizeMake(850,100))
    --标题
    local config = gamedata.config.game_helper[tostring(data.type or 1)][tostring(data.id or 1)]
	items.des:setString(config.log)

    local config = gamedata.config.game_helper[tostring(data.type or 1)][tostring(data.id or 1)]
    items.name:setString(config.activity)


    if data.type == 2 then
        if data.id == 7 then
            items.des:setString(string.format(config.log, self.data.mingjiangChallengeNum))
        else
            items.des:setString(string.format(config.log, data.params.param1))
        end
    end

    if data.type == 3 and data.id == 7 and data.index == 1 then
        items.des:setString("好友一键收礼")
    elseif data.type == 3 and data.id == 7 and data.index == 2 then
        items.des:setString("好友一键送礼")
    elseif data.type == 3 and data.id == 8 and data.index == 1 then
        items.des:setString("天庭银座一键收获")
    elseif data.type == 3 and data.id == 8 and data.index == 2 then
        items.des:setString("天庭银座一键上阵")
    elseif data.type == 3 and data.id == 6 and data.index == 1 then
        items.des:setString("藏经阁一键收获")
    elseif data.type == 3 and data.id == 6 and data.index == 2 then
        items.des:setString("藏经阁一键协助")
    elseif data.type == 4 and data.id == 2 and data.index == 1 then
        items.des:setString("公会温泉一键肥皂")
    elseif data.type == 4 and data.id == 2 and data.index == 2 then
        items.des:setString("公会温泉进度领取")
    elseif data.type == 3 and data.id == 1 and data.index == 1 then
        local level = GameScene.layers["gameHelper"].module.data["activity"]["1"].maxlevel
        items.des:setString("灭神殿一键扫荡到"..level.."层")
    elseif data.type == 3 and data.id == 1 and data.index == 2 then
        items.des:setString("灭神殿重置")
    elseif data.type == 3 and data.id == 1 and data.index == 3 then 
        items.des:setString("灭神殿立即完成")
    elseif data.type == 3 and data.id == 2 and data.index == 1 then
        items.des:setString("观星台一键观星")
    elseif data.type == 3 and data.id == 2 and data.index == 2 then
        items.des:setString("观星台领取星辰奖励")
    elseif data.type == 3 and data.id == 10 then
        items.des:setString(string.format(config.log, data.params.param1))
    elseif data.type == 3 and data.id == 11 then
        items.des:setString(string.format(config.log, data.params.param1))
    elseif data.type == 3 and data.id == 12 then
        items.des:setString(string.format(config.log, data.params.param1))
    elseif data.type == 3 and data.id == 14 then
        items.des:setString(string.format(config.log, data.params.param3))
    elseif data.type == 3 and data.id == 15 then
        items.des:setString(string.format(config.log, self.data.tongtiantaChallengeNum))
    end

    items.costNode1:setVisible(false)
    items.costNode2:setVisible(false)

    local cost = {}

    if data.used and next(data.used) then
        for k,v in pairs(data.used) do
            if (v.cid == 1000 or v.cid == 1001 or v.cid == 1003 or v.cid == 1025) and (v.num > 0) then
                table.insert(cost,v)
            end
        end
    end

    for i=1,2 do
        if cost[i] then
            items["costNode"..i]:setVisible(true)
            local iconName = gameConfig.images["s_icon_"..cost[i].cid] or "obj_s_coin"
            setSpriteFrameByName(items["costIcon"..i], iconName)
            items["cost"..i]:setString(cost[i].num)

            if cost[i].cid == 1025 then
                items["costIcon"..i]:setScale(0.35)
            else
                items["costIcon"..i]:setScale(0.8)
            end
        end
    end

end

function gameHelperLog.stopTimer(self)
	if self.showtimer then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.showtimer)
	    self.showtimer = nil
	end
end

function gameHelperLog.initFixedString(self)
	ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("buttontext","queding"),19,42)
end

function gameHelperLog.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.ListTableView = nil

    if self.firsttimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.firsttimer)
        self.firsttimer = nil
    end

    self:stopTimer()

    if self.callback then
        self.callback()
    end
end
return gameHelperLog A  