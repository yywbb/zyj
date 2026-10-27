--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local vipwelfare = {
    isscrolltouched = false,
    buttontouch = -103,

    data1 = {},
    data2 = {},
    need = {},
    status = {},
    ListTableView1 = nil,
    ListTableView2 = nil,
    normalCellSize = {x=160,y=160},
}


function vipwelfare.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/vipfuli",nil, true, "vipfuli")

    self.coveritems.midnode:setPositionY((self.contentsize.y-680)/2+620)
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    if activityConfig[tostring(57)].generalanimation and activityConfig[tostring(57)].generalanimation > 0 then
        local name = generalConfig[tostring(activityConfig[tostring(57)].generalanimation)].name
        local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(2)
        Gneral1:setPosition(0,0)
        self.coveritems["generalNode"]:addChild(Gneral1)
    end


    

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","vipwelfare",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode1 and ui.isTouched(self.coveritems.listnode1,pos.x,pos.y) then
            self.isscrolltouched = true
        elseif self.coveritems.listnode2 and ui.isTouched(self.coveritems.listnode2,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","vipwelfare",touchend)
    --
    ui.setLabelString(self.coveritems.getLab,nil,18)
    ui.setLabelString(self.coveritems.buyLab,nil,18)
    ui.setLabelString(self.coveritems.lab1,nil,14)
    ui.setLabelString(self.coveritems.popLab,nil,18)
    ui.setLabelString(self.coveritems.popfuliLab,nil,18)
    ui.setLabelString(self.coveritems.lab2,nil,13)
    ui.setLabelString(self.coveritems.lab3,nil,21)
    ui.setLabelString(self.coveritems.lab4,nil,21)
    ui.setLabelString(self.coveritems.lab7,nil,13)
    ui.setLabelString(self.coveritems.lab8,nil,13)
    --
    return self.coverccb
end

function vipwelfare.reloaddata(self,data)
    if not self.show then return end
    --
    if not data then return end
    self.status = data.vipstatus or {}
    --
    self.coveritems["popButton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        gameTouch:clickprofbytime(1)
        gameWindows:openWindow("recharge",{pagetype = "vip"})
    end, CCControlEventTouchUpInside)
    self.coveritems["popButton"]:setSwallowsTouch(true)
    self.coveritems["popButton"]:setTouchPriority(-104)


    self.coveritems["popfuliButton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        gameTouch:clickprofbytime(1)
        gameWindows:openWindow("vipwelfare")
    end, CCControlEventTouchUpInside)
    self.coveritems["popfuliButton"]:setSwallowsTouch(true)
    self.coveritems["popfuliButton"]:setTouchPriority(-104)


    --
    local datas = {}
    local roleinfo = GameScene.roleinfo or {}
    local config = gamedata.config.vip_welfare and gamedata.config.vip_welfare[tostring(GameScene.vip.vip)] or {}
    for k,v in pairs(config) do
        table.insert(datas,v)
    end
    local sortById = function(a,b) return a.battle_lv < b.battle_lv end
    table.sort(datas, sortById)
    local leveldata = datas[1] or {}
    for k,v in ipairs(datas) do
        if roleinfo.level > v.battle_lv then
            leveldata = datas[k+1] or v
        end
    end
    --
    if next(leveldata) then
        self.data1 = ui.getIDandNUMs(leveldata.free) or {}
        self.data2 = ui.getIDandNUMs(leveldata.pay) or {}
        self.need = ui.getIDandNUMs(leveldata.discount)[1] or {}
    end
    --
    self.coveritems.vip:setString("贵族"..GameScene.vip.vip)
    --
    if next(self.need) then
        ui.setLabelString(self.coveritems.xnum,self.need.num,13)
        if self.need.cid == 1000 then
            self.coveritems.sprite_coin:setVisible(true)
            self.coveritems.sprite_gold:setVisible(false)
        else
            self.coveritems.sprite_coin:setVisible(false)
            self.coveritems.sprite_gold:setVisible(true)
        end
    end
    --
    if self.status.vipexchange_free and self.status.vipexchange_free == 0 then
        ui.removeGray("CCControlButton",self.coveritems["getButton"])
        self.coveritems["getButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 4611, isfree = 1})
        end, CCControlEventTouchUpInside)
        self.coveritems["getButton"]:setSwallowsTouch(true)
        self.coveritems["getButton"]:setTouchPriority(-104)
    else
        --
        UIRequest({type = 10321,notupdate = 1,ids = {245}})
        --
        ui.addGray("CCControlButton",self.coveritems["getButton"])
        self.coveritems["getButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then return end
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
        self.coveritems["getButton"]:setSwallowsTouch(true)
        self.coveritems["getButton"]:setTouchPriority(-104)
    end
    --
    if self.status.vipexchange_buy and self.status.vipexchange_buy == 0 then
        ui.removeGray("CCControlButton",self.coveritems["buyButton"])
        self.coveritems["buyButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then return end
            gameTouch:clickprofbytime(1)
            if gamedata.config.global_kv.welfare_choose_limit and GameScene.roleinfo.level >= tonumber(gamedata.config.global_kv.welfare_choose_limit.value) then
                gameWindows:openWindow("vipExchangeBuy",{status = self.status.vipexchange_buy})
            else
                UIRequest({type = 4611, isfree = 0, need = self.need,battle_lv = leveldata.battle_lv})
            end
            
        end, CCControlEventTouchUpInside)
        self.coveritems["buyButton"]:setSwallowsTouch(true)
        self.coveritems["buyButton"]:setTouchPriority(-104)
    else
        ui.addGray("CCControlButton",self.coveritems["buyButton"])
        self.coveritems["buyButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then return end
            gameTouch:clickprofbytime(1)
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",10)})
        end, CCControlEventTouchUpInside)
        self.coveritems["buyButton"]:setSwallowsTouch(true)
        self.coveritems["buyButton"]:setTouchPriority(-104)
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

end

function vipwelfare.clear(self)
    gameTouch:UnrigistFunc("begin","vipwelfare")
    gameTouch:UnrigistFunc("end","vipwelfare")

    self.show = false
    self.ListTableView1 = nil
    self.ListTableView2 = nil
    self.data1 = {}
    self.data2 = {}
    self.need = {}
    self.status = {}
    self.coverccb = nil
    self.coveritems = nil
end

function vipwelfare.createList1(self)
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


function vipwelfare.createList2(self)
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

return vipwelfare  �1  