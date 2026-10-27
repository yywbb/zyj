--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/27
-- Time: 上午午10:57
-- To change this template use File | Settings | File Templates.
--

local treasuresDiscount_x2 = {
	buttontouch = -103,

	ListTableView = nil,
	normalCellSize = {x=1080, y=245},
	-- taskTab = {},
	data = {},
	treasuresStatus = {},
	index = nil,
    goldNum = nil,
    isscrolltouched = false,
}

function treasuresDiscount_x2.init(self, size)
	self.contentsize = size
    self.show = true

    if gamedata.config.build[tostring(440)] and gamedata.config.build[tostring(440)].switch and gamedata.config.build[tostring(440)].switch == 1 then
        self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/zhenpinzhekou_yuandan",nil, true, "zhenpinzhekou_yuandan")
        self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-340))-- -160-180
    else
        self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/huobanduihuan",nil, true, "huobanduihuan")
        self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-200))-- -160-180
    end
    
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    

    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","treasuresDiscount_x2",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","treasuresDiscount_x2",touchend)

    self.endTime = ""
    self.endTime2 = ""

    if gamedata.config.activity_time["33"]["open_type"] and gamedata.config.activity_time["33"]["open_type"] == 2 then
        self.coveritems.describe:setVisible(false)
        self.coveritems.time:setVisible(false)
    elseif gamedata.config.activity_time["33"]["open_type"] and gamedata.config.activity_time["33"]["open_type"] == 1 then
        local timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["33"]["continued_time"]-1)
        local temp = os.date("*t", timediff)
        self.endTime = temp.year .. "年" .. temp.month .. "月" .. temp.day .. "日"  .. "24时"

        local timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["33"]["continued_time"]-1) - 86400
        local temp = os.date("*t", timediff)
        self.endTime2 = temp.year .. "." .. temp.month .. "." .. temp.day .. "."  .. "24时"

    elseif gamedata.config.activity_time["33"]["open_type"] and gamedata.config.activity_time["33"]["open_type"] == 3 then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["33"]["end"])
        self.endTime = year .. "年" .. month .. "月" .. day .. "日" .. hour .. "时"
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            self.endTime = endtab.year.."年"..endtab.month.."月"..endtab.day.."日".."24时"
        end

        local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 86400 - 1
        local endtab = os.date("*t",endt)
        self.endTime2 = endtab.year.."年"..endtab.month.."月"..endtab.day.."日".."24时"
    end

    local activityConfig = gamedata.config.activity_time or {}
    local generalConfig = gamedata.config.generalanimation or {}
    -- if activityConfig[tostring(33)].generalanimation ~= 0 then
        -- local name = generalConfig[tostring(activityConfig[tostring(33)].generalanimation)].name
        -- self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
        -- local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1) -- yudi
        -- Gneral1:setAnimation("stand",true,0)
        -- Gneral1:setScale(2)
        -- Gneral1:setPosition(0,0)
        -- self.coveritems["generalNode"]:addChild(Gneral1)
    -- end

    --
    if self.coveritems.title and activityConfig[tostring(33)] then
        self.coveritems.title:setString(activityConfig[tostring(33)].name or "")
    end
    --

    self:onInit()
    -- self:reloadData()
    return self.coverccb
end

function treasuresDiscount_x2.onInit(self)
    if self.coveritems.aboutBtn then
        self.coveritems.aboutBtn:setVisible(false)
        self.coveritems.aboutBtn:setTouchPriority(self.buttontouch)
        self.coveritems.aboutBtn:setSwallowsTouch(true)
        self.coveritems.aboutBtn:addHandleOfControlEvent(function()
            -- 说明
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("multipleRebateHelp", {explain = nil, title = "物品兑换限制"}, nil)
        end, CCControlEventTouchUpInside)
    end

    if gamedata.config.build[tostring(440)] and gamedata.config.build[tostring(440)].switch and gamedata.config.build[tostring(440)].switch == 1 then
        self.coveritems.time:setString(self.endTime)
        self.coveritems.time2:setString(self.endTime2)
    else
        ui.setLabelString(self.coveritems.describe, nil, 14)	
        ui.setLabelString(self.coveritems.time, "活动截止时间:"..self.endTime, 14)
        -- ui.setLabelString(self.coveritems.fiexd1, nil, 14)
    end
       
end

function treasuresDiscount_x2.reloaddata(self, data)
    if not self.show then return end

    self.treasuresStatus = data.activityTreasure
    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData() -- 刷新列表
            print("is ListTableView")
        end
    end

end

function treasuresDiscount_x2.createList(self)
    local celldict = {}
    local unrecycleCell = {}
    local data = gamedata.config.treasure_discount_x2 or {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_zhenpinzhekou2", nil, true, "cell_zhenpinzhekou")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
			self:setCell(ccbDocumentControler, data[tostring(a1+1)], a1+1)
            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
        	-- print("self.treasuresStatus ====="..table.getTableLength(self.treasuresStatus))
            r = table.getTableLength(self.treasuresStatus)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.listnode:getContentSize().width,
        viewheight = self.coveritems.listnode:getContentSize().height,
        dire = 1
    })
    self.coveritems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

function treasuresDiscount_x2.setCell(self, item, cellData, index)

	local data = cellData
    local props = ui.getIDandNUMs(data.generals) or {}
    local consumnum = #props

    local treasuresStatus = self.treasuresStatus[tostring(index)]
	local goldCellTab = ui.getIDandNUMs(data.target) or {}
	for k,v in pairs(goldCellTab) do
		table.insert(props, v)
    end
    
    local canExchangeMax = 99999999
    local remaining_num = (data.count - treasuresStatus.num) or 0
    local notprops = false
	
	self.goldNum = props[1] and props[1].num or 0
	item.surplusNum:setString(((data.count - treasuresStatus.num) < 0 and 0 or (data.count - treasuresStatus.num)) .. "/" .. data.count) -- 剩余次数

	setSpriteFrameByName(item.discountLv, (data.discount .. "zhe") or "alpha")
	ui.setLabelString(item.exchangeLab, nil, 18)

    for i=1, 5 do
        if item["reward"..i] then
            if props[i] and props[i].cid then
                item["reward"..i]:setVisible(true)
                local config = ui.IDconfig(props[i].cid)
                if config then
                    if i<= consumnum then
                        local hasnum = treasuresStatus[tostring(props[i].cid)] or 0
                        if props[i].cid == 1000 or props[i].cid == 1001 then
                            ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                        else
                            ui.setNewIcon(item,{cid = props[i].cid, num = hasnum.."/"..props[i].num,},i-1)
                        end

                        if canExchangeMax > math.floor(hasnum/props[i].num) then
                            canExchangeMax = math.floor(hasnum/props[i].num)
                        end

                        if hasnum< props[i].num then
                            notprops = true
                            ui.setLabelString(item["i_num"..(i-1==0 and "" or "_"..(i-1))], nil, 24)
                        end
                    else
                        ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                    end
                    --
                    item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        ui.setPopwindowByCid(props[i].cid)
                    end, CCControlEventTouchUpInside)
                    item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                    --
                end
                if i<= consumnum then
                    item["reward"..i]:setPositionX(100+(i-1)*120)
                else
                    item["reward"..i]:setPositionX(150+(i-1)*120)
                end
                item.esprite:setPositionX(186+(consumnum-1)*120)
            else
                item["reward"..i]:setVisible(false)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    --
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        end
    end	

    item.exchangeBtn:setTouchPriority(self.buttontouch)
    item.exchangeBtn:addHandleOfControlEvent(function() 
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        local bagCB = function(num)
            gameTouch:clickprofbytime(1)  
            UIRequest({type = 4015, treasures = index, goldNum = props[1].num, num = num})        
        end
        if treasuresStatus.status == 1 then
            if notprops then -- 判断兑换条件是否满足
                bagCB(1)
            else
                if remaining_num > 5 then -- 多次弹窗
                    if props[1].cid == 1001 and consumnum == 1 and item_num == 1 then -- 元宝单对单
                        local cost = {{cid = props[1].cid, num = props[1].num}}
                        gameWindows:openWindow("shopExchange",{cid = goldCellTab[1].cid, num = goldCellTab[1].num, cost = cost, exchangeNum = (canExchangeMax < remaining_num) and canExchangeMax or remaining_num}, bagCB)
                    else
                        ui.exchangeMore(bagCB, canExchangeMax, data.count - treasuresStatus.num, data.count)
                    end
                else -- 单次弹窗
                    if props[1].cid == 1001 and props[1].num > 500 then
                        if consumnum == 1 and item_num == 1 then
                            local cost = {{cid = props[1].cid, num = props[1].num}}
                            gameWindows:openWindow("shopExchange",{cid = goldCellTab[1].cid, num = goldCellTab[1].num, cost = cost, exchangeNum = remaining_num, ccbtype = 2}, bagCB)
                        else
                            gameWindows:openWindow("confirm",{msg = "是否确认兑换/购买"}, bagCB)
                        end
                    else
                        bagCB(1)
                    end
                end
            end
        else 
            bagCB(1)
        end
    end, CCControlEventTouchUpInside)

    if treasuresStatus.status == 1 then
		-- 正常
        ui.removeGray("CCControlButton",item.exchangeBtn)
        ui.removeGray("CCLabelTTF",item.exchangeLab)		
	else
		-- 置灰
        ui.addGray("CCControlButton",item.exchangeBtn)
        ui.addGray("CCLabelTTF",item.exchangeLab)
    end
end

function treasuresDiscount_x2.clear(self)
    if self.coverccb then 
    	self.ListTableView = nil 
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
        self.data = {}
        self.treasuresStatus = {}
        gameTouch:UnrigistFunc("begin","treasuresDiscount_x2")
        gameTouch:UnrigistFunc("end","treasuresDiscount_x2")
    end
	self.show = false
end


return treasuresDiscount_x2
