--
-- Author: songyibo
-- Date: 2018-09-26 11:00:59
--

local goddownshop = {
    buttontouch = -100,
    data = {},
    goddowndata = 0,
    normalCellSize = {x = 960, y = 295},
    rootItems = nil,
    rootNode = nil,
    --商品列表
    ListTableView = nil,
    --配置表
    configdata = {},
    isscrolltouched = false,

    cpnum = 0,
    cpday = 0,

}


function goddownshop.makeConfig(self)
    if not next(self.configdata) then
        for k,v in pairs(gamedata.config["goddown_exchange"..(self.cpnum > 0 and ("_"..self.cpnum) or "")]) do
            table.insert(self.configdata,v)
        end
        local function sortbylevel(a,b)
            return a.id < b.id
        end
        table.sort(self.configdata,sortbylevel)
    end
end

--初始化
function goddownshop.open(self,touchPriority,data,callback)
    print("goddownshopinit===")
    self.touchPriority = touchPriority
    self.rootNode, self.rootItems = CCBReaderLoad("activitypigNew/activitypig_shop", nil, true, "activitypig_shop")
    --商品node的初始化
    --返回按钮

    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
   
    	gameWindows:closeWindow("cp_goddownShop")

    end,CCControlEventTouchUpInside)


    self.rootItems.goddowndesc:setString(gameConfig.strings:string_common("goddownshop",1))
    self.rootItems.shoptitlename:setString(gameConfig.strings:string_common("goddownshop",8))


    --
    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","activitygoddownshop",touchbegin)

    local function touchend(pos)
        if self.rootItems.listnode and ui.isTouched(self.rootItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","activitygoddownshop",touchend)
    --
    
    if data then
    	self:reloaddata(data)
    end
    

    return self.rootNode
end



--加载数据
function goddownshop.reloaddata(self,data)
    printT(data,"goddownshop===")
    if not data then
        return
    end

    self.cpnum = data and data.cpnum or 0
    self.cpday = data and data.cpday or 0
    --
    

    -- 数据
    self.data = data.shopdata and data.shopdata.props or {}
    --工会信息
    self.goddowndata = data.shopdata and data.shopdata.goddownnum or 0
    --当前供奉值
    self.rootItems.goddownnum:setString(data.shopdata and data.shopdata.goddownnum or 0)

    self:makeConfig()

    --创建表
    if self.rootItems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end


end

--创建表
function  goddownshop.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activitypigNew/cell_pigshop",nil,true,"cell_a_gonghuishop")
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
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function goddownshop.setCell(self,item,data,id)
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
        item["i_button"..i_key]:setTouchPriority(self.touchPriority)
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
    item["getbutton"..key_Ex]:setTouchPriority(self.touchPriority)
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
                UIRequest({type = 5016, id = data.id,num = num})
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

function goddownshop.close(self)  
    gameTouch:UnrigistFunc("begin","activitygoddownshop")
    gameTouch:UnrigistFunc("end","activitygoddownshop")
    -- body
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

return goddownshop