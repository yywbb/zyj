--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local shizhuangshop = {
    CellSize = {x=1080, y=280},
    rootNode = nil,
    rootItems = nil,

    oneListTableView = nil,
    oneRewardData = {},
    partnerfashion = {},
    isscrolltouched = false,

}



function shizhuangshop.init(self,size)
    self.contentsize = size
    self.show = true
    self.rootNode,self.rootItems = CCBReaderLoad("wujiangshizhuang/shizhuang_shop", nil, true, "shizhuang_shop")

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    self.rootItems.oneNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
     
    -- self.rootItems.titlenameLabel:setString(gamedata.config.activity_time[tostring(136)].name)
    -- ui.setLabelString(self.rootItems.desc1, nil, 150)
    -- ui.setLabelString(self.rootItems.activitytimeText, nil, 13)


    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","shizhuangshop",touchbegin)

    local function touchend(pos)
        if self.rootItems.oneNode and ui.isTouched(self.rootItems.oneNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","shizhuangshop",touchend)
    --
    if self.rootItems.propbutton then
        self.rootItems["propbutton"]:setSwallowsTouch(true)
        self.rootItems["propbutton"]:setTouchPriority(-102)
        self.rootItems["propbutton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(20793)
        end,CCControlEventTouchUpInside)  
    end    


    return self.rootNode
end



function shizhuangshop.reloadData(self,data)

    if not self.show then return end

    self.oneRewardData = {}

    if data and data.partnerfashion then
        self.partnerfashion = data.partnerfashion
    end
    if data and data.propnum then
        self.propnum = data.propnum
    end

    for k,v in pairs(gamedata.config.partner_fashion_shop) do
        local showitem = true
        if v["begin"] and v["begin"] ~= "" then
            local year1,month1,day1,hour1,minute1,second1 = ui.getDate(v["begin"])
            local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
            local nowtime = gamedata:time()
            if time1-nowtime > 0 then
                showitem = false
            end
        end
        if v["end"] and v["end"] ~= "" then
            local year1,month1,day1,hour1,minute1,second1 = ui.getDate(v["end"])
            local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
            local nowtime = gamedata:time()
            if time1-nowtime <= 0 then
                showitem = false
            end
        end
        --
        if showitem then
            print(v.sell_props)
            local fashion = gamedata.getIDandNUMs(v.sell_props)
            if self.partnerfashion[tostring(fashion[1].cid)] and self.partnerfashion[tostring(fashion[1].cid)].time ~= 0 then
                v.has = 1
            else
                v.has = 0
            end  
            table.insert(self.oneRewardData,v)  
        end
    end

    local sortBy = function(a,b) 
        if a.has == b.has then
            return a.sorting < b.sorting 
        else
            return a.has < b.has
        end    
    end
    table.sort(self.oneRewardData, sortBy)

    -- ui.setLabelString(self.propnum,self.propnum,14)
    self.rootItems.propnum:setString(self.propnum)

    if self.oneListTableView == nil then
        self:createOneList()
    else
        self.oneListTableView:reloadData()
    end

end


function shizhuangshop.setone(self,data,items,index)
    print("index==",index)
    -- printT(data)
    local key_Ex
    local icon_key
    if index == nil or index == 1 then
        key_Ex = ""
        icon_key = ""
    else
        key_Ex = "_2"
        icon_key = "_1"
    end

    if not data then
        return
    end

    local timesstring = "剩余次数:"..(1-data.has)

    items["desc"..key_Ex]:setString(timesstring)
    -- if (1-data.has) <= 0 then
    --     ui.setLabelString(items["desc"..key_Ex],nil,27)
    -- else
        -- ui.setLabelString(items["desc"..key_Ex],nil,14)
    -- end
    
    local spenddata = ui.getIDandNUMs(data.purchase_price)
    local propnum = 0
    if spenddata[1].cid == 20793 then
        propnum = self.propnum or 0
    elseif spenddata[1].cid == 1001 then 
        propnum = GameScene.roleinfo.gold or 0
    end 
    
    setSpriteFrameByName(items["usesprite"..key_Ex], ui.IDconfig(spenddata[1].cid) and ui.IDconfig(spenddata[1].cid).icon or "alpha")
 
    if spenddata[1].cid == 1001 then  
        items["usesprite"..key_Ex]:setVisible(false)
        items["usespriteGold"..key_Ex]:setVisible(true)
    else
        items["usesprite"..key_Ex]:setVisible(true)
        items["usespriteGold"..key_Ex]:setVisible(false)
    end    
    print("uiui1")
    if propnum >= math.floor(spenddata[1].num) then
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata[1].num),14)
    else
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata[1].num),27)
    end


    local id,num = ui.getIDandNUM(data.sell_props)

    ui.setNewIconName(items,{cid = id},index-1)
    --
    items["in_button"..icon_key]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        ui.setPopwindowByCid(id)
        -- gameWindows:openWindow("partner_fashion",{cid = gamedata.config.partner_fashion[tostring(id)].orange_partner, iid = 0, opt = 2},nil)
    end, CCControlEventTouchUpInside)
    items["in_button"..icon_key]:setTouchPriority(-102)
    --
    print("uiui2")
    ui.setLabelString(items["exchangeText"..key_Ex],nil,18)

    items["exchange"..key_Ex]:setTouchPriority(-102)
    items["exchange"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(1)
        if (1-data.has) <= 0 then
            runGamePrompt({msg = "已获得该时装"})
        else

            local names = gamedata.config.partner_fashion[tostring(id)].name or ""

            local generalid =  gamedata.config.partner_fashion[tostring(id)].orange_partner or "160001"
            -- print("generalid",generalid)
            local generalname = gamedata.config.general[tostring(generalid)].name or ""
            local nums = items["gold"..key_Ex]:getString() or "100"

            if self.propnum < tonumber(nums) then
                runGamePrompt({ msg = "道具不足"})
                return
            end    

            local cb = function()
                 UIRequest({type = 6910, id = data.id})
            end
            local rich = {
                {fontID = 1,content = "是否消耗 ",},
                {fontID = 0,content = "shizhuangsuipian",scale = 0.4},
                {fontID = 11,content = " "..nums,},
                {fontID = 1,content = "，\n购买"},
                {fontID = 11,content = generalname},
                {fontID = 1,content = "时装"},
                {fontID = 11,content = names},
                {fontID = 1,content = "?"},
            }
            gameWindows:openWindow("confirm",{rich = rich}, cb)



        end

    end, CCControlEventTouchUpInside)
    print("uiui3")
    if (1-data.has) <= 0 then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
        items["soldoutNode"..key_Ex]:setVisible(false)
        ui.setLabelString(items["exchangeText"..key_Ex],"已获得",18)
    else
        ui.removeGray("CCControlButton",items["exchange"..key_Ex])
        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
        items["soldoutNode"..key_Ex]:setVisible(false)
        ui.setLabelString(items["exchangeText"..key_Ex],"购 买",18)
    end

end


function shizhuangshop.createOneList(self)
    local celldict = {}
    local rankListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("wujiangshizhuang/cell_shizhuangshop2.ccbi", nil, true, "cell_shizhuangshop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }

            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.oneRewardData[(a1+1)*2-1] or self.oneRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.oneRewardData[(a1+1)*2] or self.oneRewardData[tostring((a1+1)*2)] then
                self:setone(self.oneRewardData[(a1+1)*2] or self.oneRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end

            cellCCB:setPosition(self.CellSize.x/2, -8)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.oneRewardData)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.oneListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.oneNode:getContentSize().width,
        viewheight = self.rootItems.oneNode:getContentSize().height,
        dire = 1
    })
    self.oneListTableView:setTouchPriority(-101)
    self.rootItems.oneNode:addChild(self.oneListTableView)
end



function shizhuangshop.clear(self)

    gameTouch:UnrigistFunc("begin","shizhuangshop")
    gameTouch:UnrigistFunc("end","shizhuangshop")
    self.show = false

    self.partnerfashion = {}
    self.oneListTableView = nil
    self.oneRewardData = {}

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
end


return shizhuangshop
