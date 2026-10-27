--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

--兑换页面

local  exchange = {
    isscrolltouched = false,
    buttontouch = -103,  --button的触摸优先级
    data = {},      --后台数据
    exchange_data = {},    --兑换数据
    refreshSton = 0,  --刷新石
    ListTableView = nil,    --表格
    normalCellSize = {x = 1080, y = 282+14},  --但个title 的大小
    --缓存的英雄表和道具表
    generals = {},
    props = {},
}

--初始化
function exchange.init(self,size)
    self.contentsize = size
    self.show = true
    self.coverccb, self.coveritems = CCBReaderLoad("activityexchange/activityexchange",nil,true,"exchange")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-702))
    --ui.setLabelString(self.coveritems.desc3,"使用刷新石头或者20元宝",48)
    -- ui.setLabelString(self.coveritems.refreshtime,"下次刷新时间:",12)
    ui.setLabelString(self.coveritems.refreshtime,gameConfig.strings:string_common("exchange",0),121)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","exchange",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","exchange",touchend)
    --

    return self.coverccb
end

--创建表
function exchange.createList(self)
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1,a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityexchange/cell_a_exchange",nil,true,"cell_a_exchange")
                celldict[a2] = {cellCCB = cellCCB,ccbDocumentControler = ccbDocumentControler}
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler,self.data[tostring(a1+1)],a1+1)
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
    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.listnode:getContentSize().width,
        viewheight = self.coveritems.listnode:getContentSize().height,
        dire = 1
    })
    self.coveritems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

--设置单元格的内容
function exchange.setCell(self,item,data,index)

    local config = gamedata.config.exchange_sys[tostring(data.id)]
    item.extimes:setString(gameConfig.strings:exchange_num(config.count - data.num))
    for i =1,3 do
        local v= data.pay[tostring(i)]
        if v then
            ui.setNewIcon(item,{num = v.nownum.."/"..v.num,cid = v.cid},i-1)
            if v.nownum>=v.num then
                ui.setLabelString(item["i_num"..(i==1 and "" or "_"..(i-1))],nil,22)
            else
                ui.setLabelString(item["i_num"..(i==1 and "" or "_"..(i-1))],nil,24)
            end
            --点击按钮出现的介绍
            item["i_button"..(i==1 and "" or "_" ..(i-1))]:setTouchPriority(-102)
            item["i_button"..(i==1 and "" or "_" ..(i-1))]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(v.cid)
            end,CCControlEventTouchUpInside)
        else
            item["g"..i]:setVisible(false)
            item["i_button"..(i==1 and "" or "_"..(i-1))]:addHandleOfControlEvent(function()
            end,CCControlEventTouchUpInside)
        end
    end


--    local generals = ui.getIDandNUMs(data.generals)
--    local has = {false,false,false}
--    for i =1,3 do
--        item["i_button"..(i==1 and "" or "_"..(i-1))]:setTouchPriority(-102)
--        if generals[i] then
--            item["g"..i]:setVisible(true)
--            for k, v in pairs( self.generals ) do
--                if 0+v.cid == 0+generals[i].cid then
--                    has[i] = true
--                end
--            end
--            for k, v in pairs( self.props ) do
--                if 0+v.cid == 0+generals[i].cid then
--                    if v.num >= generals[i].num then
--                        has[i] = true
--                    end
--                end
--            end
--            ui.setNewIcon(item,{num = generals[i].num,cid = generals[i].cid},i-1)
--            --设置数量的颜色
--            if has[i] then
--                ui.setLabelString(item["i_num"..(i==1 and "" or "_"..(i-1))],nil,22)
--            else
--                ui.setLabelString(item["i_num"..(i==1 and "" or "_"..(i-1))],nil,24)
--            end
--            --点击按钮出现的介绍
--            item["i_button"..(i==1 and "" or "_" ..(i-1))]:addHandleOfControlEvent(function()
--                if gameTouch.isScrollling then return end
--                ui.setPopwindowByCid(generals[i].cid)
--            end,CCControlEventTouchUpInside)
--        else
--            item["g"..i]:setVisible(false)
--            has[i]=true
--            item["i_button"..(i==1 and "" or "_"..(i-1))]:addHandleOfControlEvent(function()
--            end,CCControlEventTouchUpInside)
--        end
--    end

    --兑换物品
    if config.target then
        local target = ui.getIDandNUMs(config.target)
        ui.setNewIcon(item,{num = target[1].num,cid = target[1].cid},3)
        item.i_button_3:setTouchPriority(-102)
        item.i_button_3:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(target[1].cid)
        end,CCControlEventTouchUpInside) 
    end
    --判断是否兑换
    if config.count - data.num > 0 then
        if data.status == 1 then
            ui.removeGray("CCControlButton",item.buyButton)
            ui.removeGray("CCLabelTTF",item.buyLab)
            item.buyButton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrolling then return end
                gameTouch:clickprofbytime(0.5)

                UIRequest({type = 2056, id = index or 1})
                gamedata.music:PlayOptSound("wjdh")
            end,CCControlEventTouchUpInside)
        else
            ui.addGray("CCControlButton",item.buyButton)
            ui.addGray("CCLabelTTF",item.buyLab)
            item.buyButton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrolling then return end
                -- runGamePrompt({msg = "兑换所需材料不足"});
                runGamePrompt({msg = gameConfig.strings:string_common("exchange",1)});
            end,CCControlEventTouchUpInside)
        end
    else
        ui.addGray("CCControlButton",item.buyButton)
        ui.addGray("CCLabelTTF",item.buyLab)
        item.buyButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            -- runGamePrompt({msg ="当前没有兑换次数！"})
            runGamePrompt({msg =gameConfig.strings:string_common("exchange",2)})
        end,CCControlEventTouchUpInside)
    end
    item.buyButton:setTouchPriority(-102)
    -- ui.setLabelString(item.buyLab,"兑 换",18)
    ui.setLabelString(item.buyLab,gameConfig.strings:string_common("exchange",3),18)
end

--刷新表
function exchange.reloadData(self,data)
    print("reloadData")
end

--刷新数据
function exchange.reloaddata(self, data)
    if not self.show then return end
    self.data = data.data
    self.refreshSton = data.refreshSton or self.refreshSton


--    self.generals = data.generals
--    self.props = data.props
--    --把需要的数据放在兑换表中
--    self.exchange_data ={}
--    local sortTable ={}
--    for k, v in pairs(self.data.items) do
--        table.insert(sortTable,v)
--    end
--    local sortfunc = function (a,b)
--        if  a.index < b.index  then
--            return true
--        else
--            return false
--        end
--    end
--    table.sort(sortTable,sortfunc)
--    for k, v in pairs(sortTable) do
--        table.insert(self.exchange_data,gamedata.config.exchange_sys[tostring(v.id)])
--    end
    --刷新按钮
    if self.refreshSton >= 1 then
        self.coveritems.exgold:setVisible(false);
        self.coveritems.shuaxinshi:setVisible(true);
        self.coveritems.resetgold:setVisible(true);
        self.coveritems.resetgold:setString(tostring(self.refreshSton));
        ui.setLabelString(self.coveritems.resetgold,nil,18)
        -- self.coveritems.resettext:setString("免费刷新")
        self.coveritems.resettext:setString(gameConfig.strings:string_common("exchange",4))
        ui.setLabelString(self.coveritems.resettext,nil,19)
    else
        self.coveritems.exgold:setVisible(true);
        self.coveritems.resetgold:setVisible(true);
        self.coveritems.shuaxinshi:setVisible(false);
        --self.coveritems.resetgold:setString("20");
        ui.setLabelString(self.coveritems.resetgold,"20",18)
        -- self.coveritems.resettext:setString("刷 新")
        self.coveritems.resettext:setString(gameConfig.strings:string_common("exchange",5))
        ui.setLabelString(self.coveritems.resettext,nil,19)
    end

    self.coveritems.resetbutton:setSwallowsTouch(true)
    self.coveritems.resetbutton:setTouchPriority(self.buttontouch)

    --刷新按钮调用的事件
    self.coveritems.resetbutton:addHandleOfControlEvent(function()
        -- if GameScene.layers["activity"].module.isContentScroll then 
        --     print("bbbbbbbbb")
        --     return 
        -- end
        gameTouch:clickprofbytime(0.5)
        if data.refreshSton >= 1 then
            UIRequest({type = 2057})
        else 
            if GameScene.roleinfo.gold < 20 then
                shortGold()
            else
                UIRequest({type = 2057})
            end

        end
    end,CCControlEventTouchUpInside)

    --活动时间
    if gameTimer.times["ActivityExchangeTimer"] and gameTimer.times["ActivityExchangeTimer"] > 0 then
        gameTimer:rigistTimeFunc("ActivityExchangeTimer", function()
            if gameTimer.times["ActivityExchangeTimer"] <= 0.5 then
                if gameTimer.times["ActivityExchangeTimer"] then
                    gameTimer:UnrigistTimeFunc("ActivityExchangeTimer")
                end

                self.coverccb:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
                    UIRequest({type = 2055})
                end)))
            else
                ui.setLabelString(self.coveritems.updatetime,ui.makeTimeText(gameTimer.times["ActivityExchangeTimer"],"hour"),26)
                --self.coveritems.updatetime:setString(ui.makeTimeText(gameTimer.times["ActivityExchangeTimer"],"hour"))
            end
        end)
    end

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end

    end
end


--清理数据
function exchange.clear(self)
    gameTouch:UnrigistFunc("begin","exchange")
    gameTouch:UnrigistFunc("end","exchange")

    if gameTimer.times["ActivityExchangeTimer"] then
        gameTimer:UnrigistTimeFunc("ActivityExchangeTimer")
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.generals = {}
    self.props = {}
    self.exchange_data = {}
    self.refreshSton = 0
    self.coverccb = nil
    self.coveritems = nil
end


return exchange
