--
local k_goddownshop = {
    buttontouch = -100,
    data = {},
    goddowndata = 0,
    normalCellSize = {x = 1080, y = 320},
    rootItems = nil,
    rootNode = nil,
    --商品列表
    ListTableView = nil,
    --配置表
    configdata = {},
    isscrolltouched = false,
}

function k_goddownshop.makeConfig(self)
    if not next(self.configdata) then
        for k,v in pairs(gamedata.config.span_goddown_exchange) do
            table.insert(self.configdata,v)
        end
        local function sortbylevel(a,b)
            return a.id < b.id
        end
        table.sort(self.configdata,sortbylevel)
    end
end

--初始化
-- function goddownshop.init(self,parent,toppos)
function k_goddownshop.init(self,size)
    print("goddownshopinit===")
    self.contentsize = size
    self.show = true
    self.rootNode, self.rootItems = CCBReaderLoad("activitypig/activitypig_shop", nil, true, "activitypig_shop")
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)
    --商品node的初始化

    self.rootItems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-gameConfig.maiscenebottomheight-520))

    --返回按钮
    ui.setLabelString(self.rootItems.backText,nil,18)
    self.rootItems.backBtn:setTouchPriority(-102)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        GameScene:shiftLayerById(270)

    end,CCControlEventTouchUpInside)

    self:makeConfig()


    -- self.rootItems.goddowndesc:setString("当前拥有好感度：")
    self.rootItems.goddowndesc:setString(gameConfig.strings:string_common("goddownshop",1))
    self.rootItems.shoptitlename:setString(gameConfig.strings:string_common("goddownshop",10))

    ui.setLabelString(self.rootItems.desc2,gameConfig.strings:string_common("goddownshop",9),111)

    --
    local endString = ""
    if gamedata.config.activity_time["71"]["open_type"] and gamedata.config.activity_time["71"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = 0
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["71"]["continued_time"]+(gamedata.config.activity_time["71"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["71"]["continued_time"]+(gamedata.config.activity_time["71"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        local endtab = os.date("*t", timediff-1)
        --endString = endtab.year..gameConfig.strings:string_common("goddownrank",13)..endtab.month..gameConfig.strings:string_common("goddownrank",14)..endtab.day..gameConfig.strings:string_common("goddownrank",15)
        endString = endtab.month.."月"..endtab.day.."日24时"
    elseif gamedata.config.activity_time["71"]["end"] and gamedata.config.activity_time["71"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["71"]["end"])
        endString = year.."."..month.."."..day
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            --endString = endtab.year..gameConfig.strings:string_common("goddownrank",13)..endtab.month..gameConfig.strings:string_common("goddownrank",14)..endtab.day..gameConfig.strings:string_common("goddownrank",15)
            endString = endtab.month.."月"..endtab.day.."日24时"
        end
    end
    ui.setLabelString(self.rootItems.time1,endString,26)
    --

    --self:reloaddata()
    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","k_activitygoddownshop",touchbegin)

    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","k_activitygoddownshop",touchend)
    --

    return self.rootNode
end



--加载数据
function k_goddownshop.reloaddata(self,data)
    printT(data,"goddownshop===")
    if not data then
        return
    end
    if not self.show then return end
    -- 数据
    self.data = data.props or {}
    --工会信息
    self.goddowndata = data.goddownnum or 0
    --当前供奉值
    self.rootItems.goddownnum:setString(data.goddownnum or 0)



    --创建表
    if self.rootItems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end

    -- for i=1, 6 do
    --        self:setone(self.scrollItems,self.configdata[i],i)
    --    end
end

--创建表
function  k_goddownshop.createList(self)
    local  celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activitypig/cell_pigshop",nil,true,"cell_a_gonghuishop")
                celldict[a2] = {cellCCB = cellCCB,ccbDocumentControler = ccbDocumentControler}
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setCell(ccbDocumentControler,self.configdata[(a1+1)*2-1],1)
            self:setCell(ccbDocumentControler,self.configdata[(a1+1)*2],2)

            cellCCB:setPosition(self.normalCellSize.x/2,0)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn=="numberOfCells" then
            r = table.getTableLength(self.configdata)/2
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)
    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })

    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

function k_goddownshop.setCell(self,item,data,id)
    print("index==",id)
    printT(data)
    local key_Ex
    local i_key
    if id == nil or id == 1 then
        key_Ex = ""
        i_key = ""
    else
        key_Ex = "_2"
        i_key = "_1"
    end
    if not data then
        print("notid===",data.id)
        return
    end
    -- 兑换次数
    if data.limit == nil or data.limit == 0 then
        item["exchangeNode"..key_Ex]:setVisible(false)
    else
        item["exchangeNode"..key_Ex]:setVisible(true)
        -- ui.setLabelString(item["exchangeString"..key_Ex],"今日可兑换",13)
        -- ui.setLabelString(item["exchangetext"..key_Ex],"次",13)
        -- ui.setLabelString(item["contributionNumText"..key_Ex],"好感度：",13)
        ui.setLabelString(item["exchangeString"..key_Ex],gameConfig.strings:string_common("goddownshop",2),13)
        ui.setLabelString(item["exchangetext"..key_Ex],gameConfig.strings:string_common("goddownshop",3),13)
        ui.setLabelString(item["contributionNumText"..key_Ex],gameConfig.strings:string_common("goddownshop",4),13)


        --兑换次数得修改
        --以修改
        --item.exchangeNum:setString(data["number"])
        print("num-===",data["limit"],self.data[tostring(data.id)].num)
        item["exchangeNum"..key_Ex]:setString(data["limit"] - self.data[tostring(data.id)].num)
        if (data["limit"] - self.data[tostring(data.id)].num) > 0 then
            ui.setLabelString(item["exchangeNum"..key_Ex],nil,22)
            ui.removeGray("CCControlButton",item["getbutton"..key_Ex])
            print("removeGray===")
        else
            ui.setLabelString(item["exchangeNum"..key_Ex],nil,24)
            ui.addGray("CCControlButton",item["getbutton"..key_Ex])
            print("addGray===")
        end
    end
    print("兑换次数")

    --显示的道具以及数量和名称
    print("i_key===",i_key)
    printT(item,"item====")
    if data["item"] then
        local itemdata = ui.getIDandNUMs(data["item"])
        ui.setNewIcon(item,{num = itemdata[1].num,cid = itemdata[1].cid},id-1)
        item["i_button"..i_key]:setTouchPriority(-102)
        item["i_button"..i_key]:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            ui.setPopwindowByCid(itemdata[1].cid)
        end,CCControlEventTouchUpInside)
        local propName = ui.IDconfig(itemdata[1].cid)
        ui.setLabelString(item["goodsName"..key_Ex],propName.name,propName.quality*2 -1)
    end
    print("显示的道具以及数量和名称")
    --好感度(花费)
    if data["cost"] then
        local cost = ui.getIDandNUMs(data["cost"])
        item["contributionNum"..key_Ex]:setString(tostring(cost[1]["num"]))
        ui.setLabelString(item["contributionNum"..key_Ex],nil,22)
        --判断好感度(要改) 0改为当前的好感度
        if (self.goddowndata or 0) < cost[1]["num"] then
            ui.setLabelString(item["contributionNum"..key_Ex],nil,24)
        end

    end
    print("好感度")

    --兑换字体的描边
    -- ui.setLabelString(item["gettext"..key_Ex],"兑 换",18)
    ui.setLabelString(item["gettext"..key_Ex],gameConfig.strings:string_common("goddownshop",5),18)

    --兑换按钮
    item["getbutton"..key_Ex]:setTouchPriority(-102)
    item["getbutton"..key_Ex]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        gameTouch:clickprofbytime(0.5)
        local cost = ui.getIDandNUMs(data["cost"])
        --工会等级不足(工会等级)
        if (self.goddowndata or 0) < cost[1]["num"] then
            -- runGamePrompt({msg = "好感度不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("goddownshop",6)})
        elseif (data["limit"] ~= 0) and data["limit"] <= self.data[tostring(data.id)].num then
            -- runGamePrompt({msg = "兑换次数已用完"})
            runGamePrompt({msg = gameConfig.strings:string_common("goddownshop",7)})
        else
            local  cb = function( num )
                UIRequest({type = 4876, id = data.id,num = num})
            end
            if data["limit"] == 0 then
                ui.exchangeMore(cb,math.floor(self.goddowndata/cost[1]["num"]))
            else
                ui.exchangeMore(cb,math.floor(self.goddowndata/cost[1]["num"]),data["limit"] - self.data[tostring(data.id)].num,data["limit"])
            end
        end
        gamedata.music:PlayOptSound("wjdh")
    end,CCControlEventTouchUpInside)

end



--清空数据
function k_goddownshop.clear(self)
    gameTouch:UnrigistFunc("begin","k_activitygoddownshop")
    gameTouch:UnrigistFunc("end","k_activitygoddownshop")
    -- body
    self.show = false
    self.goddowndata = 0
    self.configdata = {}
    self.data = {}
    self.ListTableView = nil
    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootItems = nil
        self.rootNode = nil
    end

end



return k_goddownshop

