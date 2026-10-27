--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local cumulative = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    status = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=282+14},
    --显示的列表项
    showTable = {},
}


function cumulative.init(self,size)
    self.contentsize = size
    self.show = true

    if gamedata.config.build[tostring(440)] and gamedata.config.build[tostring(440)].switch and gamedata.config.build[tostring(440)].switch == 1 then
        self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/lianxudenglu_yuandan",nil, true, "lianxudenglu_yuandan")
        self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-490))
        ui.setLabelString(self.coveritems.desc1,nil,14)
    else
        self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/leijidenglu2",nil, true, "reward")
        self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-440))
        ui.setLabelString(self.coveritems.desc1,nil,1)
    end

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    --self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-440))

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(12)].generalanimation)].name
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create("zhaoyun/zhaoyun.json","zhaoyun/zhaoyun.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1) 
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)

    --self.coveritems.desc:setString("累计登录奖励")
    -- self.coveritems.desc1:setString("")
    -- self.coveritems.time:setString("")
    --ui.setLabelString(self.coveritems.desc1,nil,1)
    ui.setLabelString(self.coveritems.desc2,nil,1)

    -- ui.setStringWithStrokeAndShadow(self.coveritems.nameLab,nil,1)

    --
    local generalname = ""
    for k,v in pairs(gamedata.config.general) do
        if tostring(v.animationid) == tostring(activityConfig[tostring(12)].generalanimation) then
            generalname = v.name
        end
    end
    --
    if self.coveritems.generalname then
        ui.setLabelString(self.coveritems.generalname,generalname,9)
    end


    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","cumulative",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","cumulative",touchend)
    --

    return self.coverccb
end

function cumulative.reloaddata(self,data)
     if not self.show then return end
    --todo
    self.status = data.status or {}
    --printT(self.status,"data===========")

    self.data = gamedata.config.startgift or {}

    local oldshowtable =  table.getTableLength(self.showTable)
    self.showTable = data.showTable or {}

     if self.coveritems.daynum then
         self.coveritems.daynum:setString(table.getTableLength(self.showTable))
     end

    --printT(self.showTable,"showTable===========")

    -- if not self.show then return end
    -- --todo
    -- self.status = data or {}
    -- printT(self.status,"data===========")

    -- self.data = gamedata.config.startgift or {}

    -- local oldshowtable =  table.getTableLength(self.showTable)
    -- self.showTable = {}
    -- for k,v in pairs(data) do
    --     if v ~= 1 then
    --         if k ~= "1" then
    --          table.insert(self.showTable,self.data[tostring(k-1)])
    --         end
    --     end
    -- end
    -- local sortfunc = function(a,b)
    --     if a["day"] < b["day"] then
    --         return true
    --     else
    --         return false
    --     end
    -- end
    -- table.sort(self.showTable,sortfunc)

    
    local newshowtable = table.getTableLength(self.showTable)
    if not self.ListTableView then
        self:createList()
    else
        self.ListTableView:reloadData()
        self.ListTableView:setLuaContentOffset(0, self.ListTableView:getLuaContentOffsetY() - (newshowtable - oldshowtable)*296 )
    end

end

function cumulative.clear(self)
    gameTouch:UnrigistFunc("begin","cumulative")
    gameTouch:UnrigistFunc("end","cumulative")
    --列表项
    self.showTable = {}
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.coverccb = nil
    self.coveritems = nil
end

function cumulative.createList(self)
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

            --self:setCell(ccbDocumentControler,self.data[tostring(a1+1)])
            self:setCell(ccbDocumentControler,self.showTable[a1+1] or self.showTable[tostring(a1+1)])

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            --r = table.getTableLength(self.data)
            r = table.getTableLength(self.showTable)
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


function cumulative.setCell(self,item,data)
    print("setCell")

    item.doNode:setVisible(true)
    item.typenode:setVisible(false)
    item.reward4:setVisible(false)

    item.title:setString(gameConfig.strings:addDay(data.day))

    local function getIDandNUM(str)
        local i = string.find(str,";")
        return tonumber(string.sub(str,1,i-1)),tonumber(string.sub(str,i+1))
    end

    for i=1, 3 do
        if data["reward"..i] and data["reward"..i] ~= "" then
            item["reward"..i]:setVisible(true)
            local rewardid,rewardnum = getIDandNUM(data["reward"..i])

            local config = ui.IDconfig(rewardid)
            if config then
                ui.setNewIcon(item,{cid = rewardid, num = rewardnum},i-1)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    ui.setPopwindowByCid(rewardid)
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            item["reward"..i]:setVisible(false)
        end
    end

    item.doButton:setSwallowsTouch(true)
    item.doButton:setTouchPriority(-102)



    if self.status["1"] and self.status["1"] >= data.day then
        if self.status[tostring(data.day+1)] and self.status[tostring(data.day+1)] == 0 then
            ui.removeGray("CCControlButton",item.doButton)
            ui.removeGray("CCLabelTTF",item.doLab)
            item.nonenode:setVisible(false)
            item.doNode:setVisible(true)
            item.hasnode:setVisible(false)
            item.doLab:setString(gameConfig.strings:string_common("buttontext","lingqu"))
            ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
            item.doButton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                gameTouch:clickprofbytime(1)
                print("doButton clicked")
                UIRequest({type = 2036, id = data.day})
            end, CCControlEventTouchUpInside)
        else
            ui.addGray("CCControlButton",item.doButton)
            ui.addGray("CCLabelTTF",item.doLab)
            item.nonenode:setVisible(false)
            item.doNode:setVisible(false)
            item.hasnode:setVisible(true)
            item.doLab:setString(gameConfig.strings:string_common("buttontext","yilingqu"))
            ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
            item.doButton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                if gameTouch.isScrollling then return end
                runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
            end, CCControlEventTouchUpInside)
        end
    else
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.nonenode:setVisible(true)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        item.doLab:setString(gameConfig.strings:string_common("buttontext","lingqu"))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",4)})
        end, CCControlEventTouchUpInside)
    end




end

-- function cumulative.setPage(self)
--     -- UIRequest({type = 2000,page = GameScene.layers["activity"].module.type})
--     UIRequest({type = 2035}) 
-- end

-- function cumulative.UIUpdateData(self, isreset)
--     if isreset then
--         self.showTable = {}
--         self.data = {}
--         self.status = {}
--         self:setPage()
--     end
-- end

return cumulative