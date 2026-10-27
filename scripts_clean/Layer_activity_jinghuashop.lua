--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local jinghuashop = {
    CellSize = {x=1080, y=280},
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"one","two","three","four",} ,

    pagename = {"","","",""},

    selectpage = "one",

    oneListTableView = nil,
    twoListTableView = nil,
    threeListTableView = nil,
    fourListTableView = nil,

    oneRewardData = {},
    twoRewardData = {},
    threeRewardData = {},
    fourRewardData = {},

    propnum = 0,
    propnum2 = 0,
    notlimit = 0,

    rewardconfig = {},

    isscrolltouched = false,

}


--按钮高亮状态的显示
function  jinghuashop.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.rootItems["btnspr"..km], "b_n_shangdianzibiaoqian2")
            --self.rootItems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(self.rootItems["btnspr"..km], "b_n_shangdianzibiaoqian1")
            --self.rootItems["buttonnode"..km]:setZOrder(0)
        end
    end
end

function jinghuashop.shiftPage(self,type)
    if type and self.selectpage == type then
        return
    end
    
    if type then
        self.selectpage = type
    end

    self:shiftlayerpage(self.selectpage)

    for k,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            self.rootItems[v.."Node"]:setPositionX(0)
            self.rootItems[v.."Node"]:setVisible(true)
        else
            self.rootItems[v.."Node"]:setPositionX(9999)
            self.rootItems[v.."Node"]:setVisible(false)
        end
    end

    self.rootItems["show20"]:setVisible(self.selectpage == "one")
    self.rootItems["show23"]:setVisible(self.selectpage ~= "one")
    self.rootItems["limitdesc"]:setVisible(self.selectpage == "one" and self.notlimit and tonumber(self.notlimit) == 0)
    self.rootItems["activitytimeText"]:setVisible(self.selectpage == "one" and self.notlimit and tonumber(self.notlimit) == 0)

    if self.selectpage ~= "one" then
        for k,v in pairs(gamedata.config.essence_shop) do
            if v.page > 1 and v.times > 0 then
                self.rootItems["activitytimeText"]:setVisible(true)
                break
            end    
        end  
    end 

    if self.selectpage == "one" then 
        print("onelayer===")
        -- printT(self.oneRewardData)
        self:reloadOneData()
    elseif self.selectpage == "two" then
        print("twolayer===")
        -- printT(self.twoRewardData)
        self:reloadTwoData()
    elseif self.selectpage == "three" then
        print("threelayer===")
        -- printT(self.threeRewardData)
        self:reloadThreedData()
    elseif self.selectpage == "four" then
        print("fourlayer===")
        -- printT(self.fourRewardData)
        self:reloadFourData()
    end

end


function jinghuashop.init(self,size)
    self.contentsize = size
    self.show = true
    self.rootNode,self.rootItems = CCBReaderLoad("activityreward_new/jinghua_shop", nil, true, "jinghua_shop")
    -- self.rootNode:setPosition(0,0)
    -- parent:addChild(self.rootNode)
    self.rootItems.topnode:setPositionY(self.contentsize.y-180)


    -- self.rootItems.scoreListNode:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-380))
    -- ui.setLabelString(self.rootItems.desc1, nil, 150)
    self.rootItems.oneNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    self.rootItems.twoNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    self.rootItems.threeNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    self.rootItems.fourNode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))
    
    self.rootItems.scrollnode_touch:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-520-462))

    for k,v in pairs(gamedata.config.essence_shop) do
        for i = 1,4 do
            if v.page and v.page == i then
                self.pagename[i] = v.name or ""
            end    
        end    
    end

    --显示页签得按钮
    for k=1,4 do
        self.rootItems["plantitle"..k]:setString(self.pagename[k])

        self.rootItems["planbutton"..k]:setSwallowsTouch(true)
        self.rootItems["planbutton"..k]:setTouchPriority(-102)
        self.rootItems["planbutton"..k]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            self:shiftPage(self.pageconfig[k])
        end,CCControlEventTouchUpInside)  
    end
  
    -- self.rootItems.titlenameLabel:setString(gamedata.config.activity_time[tostring(133)].name)


    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","jinghuashop",touchbegin)

    local function touchend(pos)
        if self.rootItems.scrollnode_touch and ui.isTouched(self.rootItems.scrollnode_touch,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","jinghuashop",touchend)
    --
    if self.rootItems.propbutton then
        self.rootItems["propbutton"]:setSwallowsTouch(true)
        self.rootItems["propbutton"]:setTouchPriority(-102)
        self.rootItems["propbutton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(20778)
        end,CCControlEventTouchUpInside)  
    end    

    if self.rootItems.propbutton2 then
        self.rootItems["propbutton2"]:setSwallowsTouch(true)
        self.rootItems["propbutton2"]:setTouchPriority(-102)
        self.rootItems["propbutton2"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            ui.setPopwindowByCid(20790)
        end,CCControlEventTouchUpInside)  
    end    

    if self.rootItems.limitdesc and gamedata.config.essence_shop_config then
        ui.setLabelString(self.rootItems.limitdesc,"开服天数达到"..gamedata.config.essence_shop_config.server_open.value.."天或角色创建天数达到"..gamedata.config.essence_shop_config.role_creation.value.."天将取消购买次数限制",24)
    end    

    if self.rootItems.gotoBtn then
        ui.setLabelString(self.rootItems.gotoText,nil,18)
        self.rootItems["gotoBtn"]:setSwallowsTouch(true)
        self.rootItems["gotoBtn"]:setTouchPriority(-102)
        self.rootItems["gotoBtn"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            GameScene:shiftLayerById(441)
        end,CCControlEventTouchUpInside)  
    end    

    return self.rootNode
    -- self:updatetimeFunc()
end



function jinghuashop.reloadData(self, t)
    local data = t.data
    local propnum = t.propnum
    local propnum2 = t.propnum2
    local notlimit = t.notlimit

    if not self.show then return end

    if propnum then
        self.propnum = propnum
    end

    if propnum2 then
        self.propnum2 = propnum2
    end

    if notlimit then
        self.notlimit = notlimit
    end

    -- ui.setLabelString(self.rootItems.propnum,self.propnum,14)
    -- ui.setLabelString(self.rootItems.propnum2,self.propnum2,14)
    self.rootItems.propnum:setString(self.propnum)
    self.rootItems.propnum2:setString(self.propnum2)

    local haspage = 0
    local hasname = "one"
    if data.onerankdata then
        self.oneRewardData = data.onerankdata or {}
        if self.oneRewardData and next(self.oneRewardData) then
            self.rootItems.btnnode1:setVisible(true)
            haspage = haspage+1
            hasname = "one"
        else
            self.rootItems.btnnode1:setVisible(false)
        end   
    else
         self.rootItems.btnnode1:setVisible(false)
    end
    if data.tworankdata then
        self.twoRewardData = data.tworankdata or {}
        if self.twoRewardData and next(self.twoRewardData) then
            self.rootItems.btnnode2:setVisible(true)
            haspage = haspage+1
            hasname = "two"
        else
            self.rootItems.btnnode2:setVisible(false)
        end  
    else 
         self.rootItems.btnnode2:setVisible(false)
    end
    if data.threerankdata then
        self.threeRewardData = data.threerankdata or {}

        if self.threeRewardData and next(self.threeRewardData) then
            self.rootItems.btnnode3:setVisible(true)
            haspage = haspage+1
            hasname = "three"
        else
            self.rootItems.btnnode3:setVisible(false)
        end  
    else
          self.rootItems.btnnode3:setVisible(false)
    end
    if data.fourrankdata then
        self.fourRewardData = data.fourrankdata or {}
        if self.fourRewardData and next(self.fourRewardData) then
            self.rootItems.btnnode4:setVisible(true)
            haspage = haspage+1
            hasname = "four"
        else
            self.rootItems.btnnode4:setVisible(false)
        end   
    else    
        self.rootItems.btnnode4:setVisible(false)
    end

    if haspage < 2 then
        self.rootItems.btnnode1:setVisible(false) 
        self.rootItems.btnnode2:setVisible(false)
        self.rootItems.btnnode3:setVisible(false)
        self.rootItems.btnnode4:setVisible(false)
        self.selectpage = hasname
    end    

    --
    self:shiftPage()
end


function jinghuashop.reloadOneData(self)

    --local fixh = self.contentsize.y-180-520-160
    --self.rootItems.ismore:setVisible(math.ceil(table.getTableLength(self.oneRewardData)/2)*320 > fixh)

    if self.oneListTableView == nil then
        self:createOneList()
    else
        -- if self.RankListTableView:getLuaContentOffsetY() < self.rootItems.scoreListNode:getContentSize().height - table.getTableLength(self.rankdata)*205 then
            -- self.RankListTableView:setLuaContentOffset(0, self.rootItems.scoreListNode:getContentSize().height - table.getTableLength(self.rankdata)*100)
        -- end
        self.oneListTableView:reloadData()
    end
end
function jinghuashop.reloadTwoData(self)

    --local fixh = self.contentsize.y-180-520-160
    --self.rootItems.ismore:setVisible(math.ceil(table.getTableLength(self.twoRewardData)/2)*320 > fixh)

    if self.twoListTableView == nil then
        self:createTwoList()
    else
        self.twoListTableView:reloadData()
    end
end
function jinghuashop.reloadThreedData(self)

    --local fixh = self.contentsize.y-180-520-160
    --self.rootItems.ismore:setVisible(math.ceil(table.getTableLength(self.threeRewardData)/2)*320 > fixh)

    if self.threeListTableView == nil then
        self:createThreeList()
    else
        self.threeListTableView:reloadData()
    end
end
function jinghuashop.reloadFourData(self)

    --local fixh = self.contentsize.y-180-520-160
    --self.rootItems.ismore:setVisible(math.ceil(table.getTableLength(self.fourRewardData)/2)*320 > fixh)

    if self.fourListTableView == nil then
        self:createFourList()
    else
        self.fourListTableView:reloadData()
    end
end


function jinghuashop.setone(self,data,items,index)
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
        -- print("notid===",data.id)
        return
    end

    local config = table.copy(gamedata.config.essence_shop[tostring(data.id)])

    if not config  then
        print("notid===",data.id)
        return
    end

    local timesstring = "今日可兑换"..(config.times-data.num).."次"

    if config.times and config.times <= 0 then
        config.times = 99999
        timesstring = ""
    elseif self.selectpage == "one" and self.notlimit and tonumber(self.notlimit) == 1 then 
        config.times = 99999
        timesstring = ""
    end    

    items["desc"..key_Ex]:setString(timesstring)
    -- if config.times-data.num == 0 then
    --     ui.setLabelString(items["desc"..key_Ex],nil,27)
    -- else
    --     ui.setLabelString(items["desc"..key_Ex],nil,14)
    -- end
    
    local spenddata = ui.getIDandNUMs(config.num)
    local propnum = 0
    if spenddata[1].cid == 20790 then
        propnum = self.propnum2 or 0
        items["usesprite1"..key_Ex]:setVisible(false)
        items["usesprite2"..key_Ex]:setVisible(true)
    else
        propnum = self.propnum or 0
        items["usesprite1"..key_Ex]:setVisible(true)
        items["usesprite2"..key_Ex]:setVisible(false)
    end 
       
    if propnum >= math.floor(spenddata[1].num) then
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata[1].num),14)
    else
        ui.setLabelString(items["gold"..key_Ex],math.floor(spenddata[1].num),27)
    end


    local id,num = ui.getIDandNUM(config.reward)

    ui.setNewIconName(items,{cid = id, num = num},index-1)
    --
    items["in_button"..icon_key]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        ui.setPopwindowByCid(id)
    end, CCControlEventTouchUpInside)
    items["in_button"..icon_key]:setTouchPriority(-102)
    --

    ui.setLabelString(items["exchangeText"..key_Ex],nil,18)

    items["exchange"..key_Ex]:setTouchPriority(-102)
    items["exchange"..key_Ex]:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end

        gameTouch:clickprofbytime(0.5)
        if config.times-data.num <= 0 then
            runGamePrompt({msg = "已经没有兑换次数"})
        elseif propnum < math.floor(spenddata[1].num) then
            runGamePrompt({msg = "道具不足"})
        else

            function shopExchangeRequest(num)
                if propnum < math.floor(spenddata[1].num)*num then
                    runGamePrompt({msg = "道具不足"})
                else
                    UIRequest({type = 6452, id = data.id,usecid = spenddata[1].cid,usenum = math.floor(spenddata[1].num*num),num = num})
                end
            end
            local exchangeNum = config.times-data.num
            local spenddata2 = ui.getIDandNUMs(config.num)
            spenddata2[1].num = math.floor(spenddata2[1].num)

            if exchangeNum > math.floor(propnum / math.floor(spenddata[1].num)) then
                exchangeNum = math.floor(propnum / math.floor(spenddata[1].num))
            end    

            if exchangeNum > 5 then
                gameWindows:openWindow("shopExchange",{cid = id,num = num,cost = spenddata2,exchangeNum = exchangeNum},shopExchangeRequest)
            else
                UIRequest({type = 6452, id = data.id,usecid = spenddata[1].cid,usenum = math.floor(spenddata[1].num),num = 1})
            end    
        end

    end, CCControlEventTouchUpInside)

    if config.times-data.num <= 0 then
        ui.addGray("CCControlButton",items["exchange"..key_Ex])
        ui.addGray("CCLabelTTF",items["exchangeText"..key_Ex])
        items["soldoutNode"..key_Ex]:setVisible(true)
    else
        ui.removeGray("CCControlButton",items["exchange"..key_Ex])
        ui.removeGray("CCLabelTTF",items["exchangeText"..key_Ex])
        items["soldoutNode"..key_Ex]:setVisible(false)
    end

end

-- createOneList createTwoList createThreeList createFourList
function jinghuashop.createOneList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_jinghuashop2.ccbi", nil, true, "cell_jinghuashop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.oneRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.oneRewardData[tostring((a1+1)*2)] then
                self:setone(self.oneRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

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

function jinghuashop.createTwoList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_jinghuashop2.ccbi", nil, true, "cell_jinghuashop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.twoRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.twoRewardData[tostring((a1+1)*2)] then
                self:setone(self.twoRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.twoRewardData)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.twoListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.twoNode:getContentSize().width,
        viewheight = self.rootItems.twoNode:getContentSize().height,
        dire = 1
    })
    self.twoListTableView:setTouchPriority(-101)
    self.rootItems.twoNode:addChild(self.twoListTableView)
end

function jinghuashop.createThreeList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_jinghuashop2.ccbi", nil, true, "cell_jinghuashop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.threeRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.threeRewardData[tostring((a1+1)*2)] then
                self:setone(self.threeRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.threeRewardData)/2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.threeListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.threeNode:getContentSize().width,
        viewheight = self.rootItems.threeNode:getContentSize().height,
        dire = 1
    })
    self.threeListTableView:setTouchPriority(-101)
    self.rootItems.threeNode:addChild(self.threeListTableView)
end

function jinghuashop.createFourList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_jinghuashop2.ccbi", nil, true, "cell_jinghuashop")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                --ui.tableviewAnimation(self.rewardListTableView,cellCCB,self.rewardCellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setone(self.fourRewardData[tostring((a1+1)*2-1)],ccbDocumentControler,1)

            if self.fourRewardData[tostring((a1+1)*2)] then
                self:setone(self.fourRewardData[tostring((a1+1)*2)],ccbDocumentControler,2)
                ccbDocumentControler.RightRewardNode:setVisible(true)
            else
                ccbDocumentControler.RightRewardNode:setVisible(false)
            end
            

            --if self.rewardListTableView then
                cellCCB:setPosition(self.CellSize.x/2, -8)
            --end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.fourRewardData)/2) 
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.fourListTableView = ui.createLuaTableView({
        handle = rankListHandle,
        viewwidth = self.rootItems.fourNode:getContentSize().width,
        viewheight = self.rootItems.fourNode:getContentSize().height,
        dire = 1
    })
    self.fourListTableView:setTouchPriority(-101)
    self.rootItems.fourNode:addChild(self.fourListTableView)
end


function jinghuashop.clear(self)

    gameTouch:UnrigistFunc("begin","jinghuashop")
    gameTouch:UnrigistFunc("end","jinghuashop")
    self.show = false

    self.oneListTableView = nil
    self.twoListTableView = nil
    self.threeListTableView = nil
    self.fourListTableView = nil

    self.oneRewardData = {}
    self.twoRewardData = {}
    self.threeRewardData = {}
    self.fourRewardData = {}

    self.propnum = 0
    self.propnum2 = 0
    self.notlimit = 0

    self.rewardconfig = {}

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
end


return jinghuashop
