--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local activity_timebuy = {

    rootNode = nil,
    rootItems = nil,

    data = {},
    listdata = {},

    showindex = 1,

    ListTableView = nil,
}



function activity_timebuy.init(self,size)
    self.contentsize = size
    self.show = true
    self.rootNode,self.rootItems = CCBReaderLoad("activityjieri/activityxianshituangu", nil, true, "timebuy")

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    --
    self.rootItems["listbutton"]:setSwallowsTouch(true)
    self.rootItems["listbutton"]:setTouchPriority(-102)
    self.rootItems["listbutton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(0.5)
        --
        gameWindows:openWindow("timebuy_list",nil,nil)
    end,CCControlEventTouchUpInside)  
    

    ui.setSpriteTextureRect2(self.rootItems.process,0,0,0,22)
    --ui.setSpriteTextureRect2(self.rootItems.process,0,0,920 * (now > self.max_integral and self.max_integral or now) / self.max_integral,22)
    --
    local timediff = 0
    if self.rootItems.activitytime1 and gamedata.config.activity_time["135"]["open_type"] and gamedata.config.activity_time["135"]["open_type"] == 2 then
        
    elseif self.rootItems.activitytime1 and gamedata.config.activity_time["135"]["open_type"] and gamedata.config.activity_time["135"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["135"]["continued_time"]+(gamedata.config.activity_time["135"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["135"]["continued_time"]+(gamedata.config.activity_time["135"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        --
    elseif self.rootItems.activitytime1 and gamedata.config.activity_time["135"]["end"] and gamedata.config.activity_time["135"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["135"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime      
    end

    if self.rootItems.activitytime1 and timediff and timediff > 0 then
        gameTimer:rigistTime("activityTimeBuy",timediff)        
        if gameTimer.times["activityTimeBuy"] and gameTimer.times["activityTimeBuy"] > 0 then
            gameTimer:rigistTimeFunc("activityTimeBuy", function()
                if gameTimer.times["activityTimeBuy"] <= 0 then
                    if gameTimer.times["activityTimeBuy"] then
                        ui.setLabelString(self.rootItems.activitytime1,"",23)
                        gameTimer:UnrigistTimeFunc("activityTimeBuy")
                    end
                else
                    ui.setLabelString(self.rootItems.activitytime1,"活动结束倒计时："..ui.makeTimeDayText(gameTimer.times["activityTimeBuy"],"day"),23)
                end
            end)
        end
    else
        ui.setLabelString(self.rootItems.activitytime1,"",23)
    end

    --
    ui.setLabelString(self.rootItems.desc,nil,14)
    ui.setLabelString(self.rootItems.doLab,nil,19)
    --
    self.listdata = {}
    for k,v in pairs(gamedata.config.time_buy) do
        if GameScene.roleinfo.level and GameScene.roleinfo.level >= (v.level_limit or 0) then
            table.insert(self.listdata,v)
        end
    end
    --
    local sortById = function(a,b) return a.id < b.id end
    table.sort(self.listdata, sortById)

    --
    if  self.rootItems.leftbutton then
        self.rootItems.leftbutton:addHandleOfControlEvent(function()
            if self.ListTableView then
                if self.ListTableView:getLuaContentOffsetX()+200 > 0 then
                    self.ListTableView:setLuaContentOffset(0 , 0)
                else
                    self.ListTableView:setLuaContentOffset(self.ListTableView:getLuaContentOffsetX()+200 , 0)   
                end
            end    
        end, CCControlEventTouchUpInside)
        self.rootItems.leftbutton:setSwallowsTouch(true)
        self.rootItems.leftbutton:setTouchPriority(-102)
    end

    if  self.rootItems.rightbutton then
        self.rootItems.rightbutton:addHandleOfControlEvent(function()
            if self.ListTableView then
                if (self.ListTableView:getLuaContentOffsetX()-200) < (880-table.getTableLength(self.listdata)*200) then
                    self.ListTableView:setLuaContentOffset(880-table.getTableLength(self.listdata)*200  , 0)
                else
                    self.ListTableView:setLuaContentOffset(self.ListTableView:getLuaContentOffsetX()-200 , 0)    
                end
            end    
        end, CCControlEventTouchUpInside)
        self.rootItems.rightbutton:setSwallowsTouch(true)
        self.rootItems.rightbutton:setTouchPriority(-102)
    end

    --
    return self.rootNode

end



function activity_timebuy.reloaddata(self,data)

    if not self.show then return end

    if data then
        self.data = data
    end

    ui.setLabelString(self.rootItems.gold,self.data.re_gold or 0,14)

    --
    self:setPage()

    --
    UIRequest({type = 10321,notupdate = 1,ids = {439}})
end


function activity_timebuy.setPage(self)

    local configdata = self.listdata[self.showindex] or {}
    local data = self.data.status[tostring(configdata.id)] or {}
    local itemcid,itemnum = ui.getIDandNUM(configdata.item) 
    --
    ui.setLabelString(self.rootItems.allnum,"当前全服已购买数量："..data.allnum or 0,14)
    ui.setNewIcon(self.rootItems,{cid = itemcid, num = itemnum})
    --
    self.rootItems["i_button"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        ui.setPopwindowByCid(itemcid)
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button"]:setTouchPriority(-102)
    --
    ui.setLabelString(self.rootItems.propname,ui.IDconfig(itemcid).name..((ui.IDconfig(itemcid).staffType == "general_fragment") and "魂魄" or "" ),((ui.IDconfig(itemcid).quality and ui.IDconfig(itemcid).quality ~= 0) and ui.IDconfig(itemcid).quality or 1)*2-1)
    self.rootItems.oldgold:setString(configdata.price)
    --
    local nowgold = configdata.price
    self.rootItems.d_zhenode:setVisible(false)
    local maxpoint = 0
    for i = 1,9 do
        if configdata["dis_"..i] and configdata["dis_"..i] > 0 then
            maxpoint = math.floor(configdata["amount_"..i]*1.1)
            self.rootItems["zheNode"..i]:setVisible(true)  
            local zhe = math.floor(configdata["dis_"..i]*10)
            setSpriteFrameByName(self.rootItems["zhe"..i], zhe.."zhe")
            self.rootItems["neednum"..i]:setString(configdata["amount_"..i])
            if data.allnum >= configdata["amount_"..i] then
                nowgold = math.floor(configdata.price*configdata["dis_"..i])
                self.rootItems.d_zhenode:setVisible(true)
                self.rootItems.d_zhe:setString(zhe.."折")
            end    
        else
            self.rootItems["zheNode"..i]:setVisible(false)  
        end
    end 
    --
    for i = 1,9 do
        if configdata["dis_"..i] and configdata["dis_"..i] > 0 then 
            self.rootItems["zheNode"..i]:setPositionX(920*configdata["amount_"..i]/maxpoint)
        end    
    end 
    --
    ui.setSpriteTextureRect2(self.rootItems.process,0,0,920 * (data.allnum > maxpoint and maxpoint or data.allnum) / maxpoint,22)
    --
    self.rootItems.newgold:setString(nowgold)
    --
    if data.num >= configdata.limit then
        self.rootItems.lavenum:setString(((configdata.refresh == 1) and "今日可购买" or "可购买").."0".."次")
        self.rootItems["doButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = "购买次数已用完"})
        end, CCControlEventTouchUpInside)
        self.rootItems["doButton"]:setTouchPriority(-102)
        --
        ui.addGray("CCControlButton",self.rootItems["doButton"])
    else 
        self.rootItems.lavenum:setString(((configdata.refresh == 1) and "今日可购买" or "可购买")..(configdata.limit-data.num).."次")
        self.rootItems["doButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            UIRequest({type=6803,id = configdata.id,gold = nowgold})
        end, CCControlEventTouchUpInside)
        self.rootItems["doButton"]:setTouchPriority(-102)
        --
        ui.removeGray("CCControlButton",self.rootItems["doButton"])
    end
    --
    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
    end
    --

end


function activity_timebuy.createList(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(200,200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            local itemcid,itemnum = ui.getIDandNUM(self.listdata[a1+1].item)
            ui.setNewIcon(ccbDocumentControler,{cid = itemcid})
            ccbDocumentControler.i_selectEffect:removeAllChildrenWithCleanup(true)
            if self.showindex == (a1+1) then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                ccbDocumentControler.i_selectEffect:addChild(eccb)
            end

            cellCCB:setPosition(100, 100)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.listdata)
        elseif fn == "cellTouched" then
            self.showindex = a1:getIdx()+1
            self:setPage()
        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 0
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-107)
end


function activity_timebuy.clear(self)

    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.showindex = 1
    self.listdata = {}

    if gameTimer.times["activityTimeBuy"] then
        gameTimer:UnrigistTimeFunc("activityTimeBuy")
    end

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
end


return activity_timebuy
�.  