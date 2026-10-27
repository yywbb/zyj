--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local weekreward = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    typeid = 1,
    status = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=282+14},
}


function weekreward.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/zhouzhouyouli",nil, true, "reward")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-640))

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(116)].generalanimation)].name
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create("hexiangu/hexiangu.json","hexiangu/hexiangu.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1) 
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)


    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","weekreward",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","weekreward",touchend)
    --

    self:setRefreshTime()
    --

    return self.coverccb
end


function weekreward.setRefreshTime(self)
    local nowtime = os.date("*t", gamedata:time())

    local fixtimenum = 0
    if nowtime.wday >= 2 then
        fixtimenum = (9-nowtime.wday)*24*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec+1
    else 
        fixtimenum = (2-nowtime.wday)*24*3600-nowtime.hour*3600-nowtime.min*60-nowtime.sec+1
    end

    if fixtimenum and fixtimenum > 0 then
        gameTimer:rigistTime("weekrewardRefreshTime",fixtimenum)
        if gameTimer.times["weekrewardRefreshTime"] and gameTimer.times["weekrewardRefreshTime"] > 0 then
            gameTimer:rigistTimeFunc("weekrewardRefreshTime", function()
                if gameTimer.times["weekrewardRefreshTime"] <= 0 then
                    gameTimer:UnrigistTimeFunc("weekrewardRefreshTime")
                    self:setRefreshTime()
                else
                    ui.setLabelString(self.coveritems.time,ui.makeTimeDayText(gameTimer.times["weekrewardRefreshTime"],"day"),22)   
                end
            end)
        end
    else
        self:setRefreshTime()       
    end
    --
end


function weekreward.reloaddata(self,data)
    if not self.show then return end
    --
    if not data then return end

    self.typeid = data.typeid or 1
    self.status = data.status or {}

    self.data = {}

    for k,v in pairs(gamedata.config.week_gift and gamedata.config.week_gift[tostring(self.typeid)] or {}) do
        v.sortnum = 100+v.align
        if self.status[tostring(2*v.align)] and self.status[tostring(2*v.align)] == 1 then
            v.sortnum = v.align
        elseif self.status[tostring(2*v.align)] and self.status[tostring(2*v.align)] == 2 then
            v.sortnum = 200+v.align       
        end    
        table.insert(self.data,v)
    end

    table.sort(self.data, function(a,b) return a.sortnum < b.sortnum end)

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            if self.ListTableView:getLuaContentOffsetY() < self.coveritems.listnode:getContentSize().height - table.getTableLength(self.data)*self.normalCellSize.y then
                self.ListTableView:setLuaContentOffset(0, self.coveritems.listnode:getContentSize().height - table.getTableLength(self.data)*self.normalCellSize.y)
            end
            self.ListTableView:reloadData()
        end
    end

end

function weekreward.clear(self)
    gameTouch:UnrigistFunc("begin","weekreward")
    gameTouch:UnrigistFunc("end","weekreward")

    if gameTimer.times["weekrewardRefreshTime"] then
        gameTimer:UnrigistTimeFunc("weekrewardRefreshTime")
    end

    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.typeid = 1
    self.coverccb = nil
    self.coveritems = nil
end

function weekreward.createList(self)
    print("createList")

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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward1", nil, true, "cell_reward1")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.data[a1+1],a1+1)

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


function weekreward.setCell(self,item,data,index)
    print("setCell")

    item.doButton:setTouchPriority(-102)
    if self.status[tostring(2*data.align)] and self.status[tostring(2*data.align)] == 1 then
        item.nonenode:setVisible(false)
        item.doNode:setVisible(true)
        item.hasnode:setVisible(false)
        ui.removeGray("CCControlButton",item.doButton)
        ui.removeGray("CCLabelTTF",item.doLab)
        -- item.doLab:setString("领取")
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setLabelString(item.doLab,nil,18)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            print("getbutton clicked")
            UIRequest({type = 5526, id = data.align or 1})
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(2*data.align)] and self.status[tostring(2*data.align)] == 2 then
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(true)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",5))
        ui.setLabelString(item.doLab,nil,18)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
    else
        item.nonenode:setVisible(true)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setLabelString(item.doLab,nil,18)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",7)})
        end, CCControlEventTouchUpInside)
    end

    if data.desc and tonumber(data.desc) == 1 then
        item.lavenum:setVisible(true)
        if self.status[tostring(2*data.align)] and self.status[tostring(2*data.align)] > 0 then
            item.lavenum:setString("进度：( "..data.target.." / "..data.target.." )")
        else 
            item.lavenum:setString("进度：( "..self.status[tostring(2*data.align-1)].." / "..data.target.." )")
        end
    else
        item.lavenum:setVisible(false)
    end    

    item.title:setString(data.name)

    local props = ui.getIDandNUMs(data.rewards) or {}

    for i=1, 4 do
        if props[i] and props[i].cid then
            item["reward"..i]:setVisible(true)
            local config = ui.IDconfig(props[i].cid)
            if config then
                ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(props[i].cid)
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            item["reward"..i]:setVisible(false)
        end
    end

    item.typenode:setVisible(props[4] and true or false)

end


return weekreward   �)  