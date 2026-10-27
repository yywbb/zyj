--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local timegift = {
    isscrolltouched = false,
    buttontouch = -103,

    data1 = {},
    data2 = {},
    status = {},
    ListTableView1 = nil,
    ListTableView2 = nil,
    normalCellSize = {x=160,y=160},
}


function timegift.init(self,size)
    self.contentsize = size  
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/libaofuli",nil, true, "libaofuli")

    self.coveritems.midnode:setPositionY((self.contentsize.y-680)/2+620)

    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    if activityConfig[tostring(59)].generalanimation and activityConfig[tostring(59)].generalanimation > 0 then
        local name = generalConfig[tostring(activityConfig[tostring(59)].generalanimation)].name
        local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(2)
        Gneral1:setPosition(0,0)
        self.coveritems["generalNode"]:addChild(Gneral1)
    end


    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","timegift",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode1 and ui.isTouched(self.coveritems.listnode1,pos.x,pos.y) then
            self.isscrolltouched = true
        elseif self.coveritems.listnode2 and ui.isTouched(self.coveritems.listnode2,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","timegift",touchend)
    --
    ui.setLabelString(self.coveritems.buyLab1,nil,18)
    ui.setLabelString(self.coveritems.buyLab2,nil,18)
    --
    return self.coverccb
end

function timegift.reloaddata(self,data)
    if not self.show then return end
    --
    if not data then return end
    self.status = data or {}
    --

    local config = gamedata.config.week_month_gift or {}
    local config1 = config[tostring(self.status.reward1 or 1)] or {}
    local config2 = config[tostring(self.status.reward2 or 1)] or {}
    --
    self.data1 = ui.getIDandNUMs(config1.gift1 or "") or {}
    self.data2 = ui.getIDandNUMs(config2.gift2 or "") or {}
    --
    local xgold1 = ui.getIDandNUMs(config1.price1 or "") or {}
    local xgold2 = ui.getIDandNUMs(config2.price2 or "") or {}
    --
    local xnum1 = xgold1[1] and xgold1[1].num or 0
    local xnum2 = xgold2[1] and xgold2[1].num or 0
    --
    local ygold1 = ui.getIDandNUMs(config1.first_price1 or "") or {}
    local ygold2 = ui.getIDandNUMs(config2.first_price2 or "") or {}
    --
    local ynum1 = ygold1[1] and ygold1[1].num or 0
    local ynum2 = ygold2[1] and ygold2[1].num or 0
    --
    ui.setLabelString(self.coveritems.zhelab1,(config1.discount or "").."折",13)
    ui.setLabelString(self.coveritems.zhelab2,(config2.discount2 or "").."折",13)
    --
    ui.setLabelString(self.coveritems.xnum1,xnum1,13)
    ui.setLabelString(self.coveritems.xnum2,xnum2,13)
    ui.setLabelString(self.coveritems.ynum1,ynum1,13)
    ui.setLabelString(self.coveritems.ynum2,ynum2,13)
    --
    --
    if self.status.status1 and self.status.status1 == 0 then
        ui.removeGray("CCControlButton",self.coveritems["buyButton1"])
        self.coveritems["buyButton1"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then return end
            gameTouch:clickprofbytime(1)
            -- UIRequest({type = 4616, opt = 1, xnum = xnum1})
            local function bagCB()
                UIRequest({type = 4616, opt = 1, xnum = xnum1})    
            end
            gameWindows:openWindow("confirm",{msg = "是否确认兑换/购买"}, bagCB)
        end, CCControlEventTouchUpInside)
        self.coveritems["buyButton1"]:setSwallowsTouch(true)
        self.coveritems["buyButton1"]:setTouchPriority(-104)
    else
        ui.addGray("CCControlButton",self.coveritems["buyButton1"])
        self.coveritems["buyButton1"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then return end
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = "本周已购买"})
        end, CCControlEventTouchUpInside)
        self.coveritems["buyButton1"]:setSwallowsTouch(true)
        self.coveritems["buyButton1"]:setTouchPriority(-104)
    end
    --
    if self.status.status2 and self.status.status2 == 0 then
        ui.removeGray("CCControlButton",self.coveritems["buyButton2"])
        self.coveritems["buyButton2"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then return end
            gameTouch:clickprofbytime(1)
            -- UIRequest({type = 4616, opt = 2, xnum = xnum2})
            local function bagCB()
                UIRequest({type = 4616, opt = 2, xnum = xnum2})     
            end
            gameWindows:openWindow("confirm",{msg = "是否确认兑换/购买"}, bagCB)
        end, CCControlEventTouchUpInside)
        self.coveritems["buyButton2"]:setSwallowsTouch(true)
        self.coveritems["buyButton2"]:setTouchPriority(-104)
    else
        ui.addGray("CCControlButton",self.coveritems["buyButton2"])
        self.coveritems["buyButton2"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then return end
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = "本月已购买"})
        end, CCControlEventTouchUpInside)
        self.coveritems["buyButton2"]:setSwallowsTouch(true)
        self.coveritems["buyButton2"]:setTouchPriority(-104)
    end
    --
    if self.coveritems then
        if not self.ListTableView1 then
            self:createList1()
        else
            self.ListTableView1:reloadData()
        end
        --
        if not self.ListTableView2 then
            self:createList2()
        else
            self.ListTableView2:reloadData()
        end
    end

    --
    UIRequest({type = 10321,notupdate = 1,ids = {252}})
    --
end

function timegift.clear(self)
    gameTouch:UnrigistFunc("begin","timegift")
    gameTouch:UnrigistFunc("end","timegift")

    self.show = false
    self.ListTableView1 = nil
    self.ListTableView2 = nil
    self.data1 = {}
    self.data2 = {}
    self.status = {}
    self.coverccb = nil
    self.coveritems = nil
end

function timegift.createList1(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle1 = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
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

            --
            ui.setNewIcon(ccbDocumentControler,{cid = self.data1[a1+1].cid, num = self.data1[a1+1].num,},0)
            --
            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                --print(self.data1[a1+1].cid)
                ui.setPopwindowByCid(self.data1[a1+1].cid)
            end, CCControlEventTouchUpInside)
            ccbDocumentControler["i_button"]:setTouchPriority(-108)
            --

            cellCCB:setScale(0.9)
            cellCCB:setPosition(self.normalCellSize.x/2, self.normalCellSize.y/2)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data1)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView1 = ui.createLuaTableView({
        handle = ListHandle1,
        viewwidth = self.coveritems.listnode1:getContentSize().width,
        viewheight = self.coveritems.listnode1:getContentSize().height,
        dire = 0
    })
    self.coveritems.listnode1:addChild(self.ListTableView1)
    self.ListTableView1:setTouchPriority(-107)
end


function timegift.createList2(self)
    print("createList")

    local celldict = {}
    local unrecycleCell = {}
    local ListHandle2 = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
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

            --
            ui.setNewIcon(ccbDocumentControler,{cid = self.data2[a1+1].cid, num = self.data2[a1+1].num,},0)
            --
            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                --print(self.data1[a1+1].cid)
                ui.setPopwindowByCid(self.data2[a1+1].cid)
            end, CCControlEventTouchUpInside)
            ccbDocumentControler["i_button"]:setTouchPriority(-108)
            --

            cellCCB:setScale(0.9)
            cellCCB:setPosition(self.normalCellSize.x/2, self.normalCellSize.y/2)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data2)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView2 = ui.createLuaTableView({
        handle = ListHandle2,
        viewwidth = self.coveritems.listnode2:getContentSize().width,
        viewheight = self.coveritems.listnode2:getContentSize().height,
        dire = 0
    })
    self.coveritems.listnode2:addChild(self.ListTableView2)
    self.ListTableView2:setTouchPriority(-107)
end

return timegift  "+  