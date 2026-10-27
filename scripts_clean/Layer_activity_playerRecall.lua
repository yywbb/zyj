--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/9/28
-- Time: 10:36
-- To change this template use File | Settings | File Templates.
--

local playerrecall = {
    isscrolltouched = false,
    buttontouch = -103,
    listview = nil,
    inventconfig = {},

    normalCellSize = {x=1080,y=228+14},
}

function playerrecall.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityplayerreturn/activityplayerreturn",nil, true, "activityplayerreturn")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.scroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-712))

    self.coveritems.copyNode:setVisible(true)
    ui.setLabelString(self.coveritems.copyLab,"复制",18)
    self.coveritems.copybutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if ui.setStringToPasteBoard(gameConfig.strings:shell_recall_code(self.data.code)) then
            runGamePrompt({msg = "复制成功"})
        end

    end, CCControlEventTouchUpInside)

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(58)].generalanimation)].name
    self.coveritems["generalNode1"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create("nanzhujueyijie/nanzhujueyijie.json","nanzhujueyijie/nanzhujueyijie.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode1"]:addChild(Gneral1)

    ui.setLabelString(self.coveritems["desc1"], nil, 1)
    ui.setLabelString(self.coveritems["desc2"], nil, 1)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","playerrecall",touchbegin)

    local function touchend(pos)
        if self.coveritems.scroll and ui.isTouched(self.coveritems.scroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","playerrecall",touchend)
    --

    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["58"]["open_type"] and gamedata.config.activity_time["58"]["open_type"] == 2 then
        ui.setLabelString(self.coveritems.time,"",26)
        self.coveritems.timedesc:setVisible(false)
        self.coveritems.timebg:setVisible(false)
    elseif self.coveritems.time and gamedata.config.activity_time["58"]["open_type"] and gamedata.config.activity_time["58"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["58"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["58"]["end"] and gamedata.config.activity_time["58"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["58"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        ui.setLabelString(self.coveritems.time,"",26)
        self.coveritems.timedesc:setVisible(false)
        self.coveritems.timebg:setVisible(false)
    end
    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("playerrecalltime",timediff)

        if gameTimer.times["playerrecalltime"] and gameTimer.times["playerrecalltime"] > 0 then
            gameTimer:rigistTimeFunc("playerrecalltime", function()
                if gameTimer.times["playerrecalltime"] <= 0 then
                    if gameTimer.times["playerrecalltime"] then
                        gameTimer:UnrigistTimeFunc("playerrecalltime")
                    end
                else
                    self.coveritems.timebg:setVisible(true)
                    self.coveritems.timedesc:setVisible(true)
                    ui.setLabelString(self.coveritems.time,ui.makeTimeDayText(gameTimer.times["playerrecalltime"],"day"),26)
                end
            end)
        end
    end

    --
    return self.coverccb
end

function playerrecall.createlist(self)

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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward2", nil, true, "cell-invent")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setinventconfig(ccbDocumentControler,a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.inventconfig)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.scroll:getContentSize().width,
        viewheight = self.coveritems.scroll:getContentSize().height,
        dire = 1
    })
    self.coveritems.scroll:addChild(self.listview)
    self.listview:setTouchPriority(-101)

end

function playerrecall.reloaddata(self,data)
    if not self.show then return end

    self.data = data or {}

    ui.setLabelString(self.coveritems.hasnum,self.data.num or 0,21)
    ui.setLabelString(self.coveritems.mykey,self.data.code or "",21)

    local configdata = gamedata.config.player_back_call
    self.inventconfig = {}

    local table1 = {}
    local table2 = {}

    for i=1, table.getTableLength(configdata) do
        if configdata[tostring(i)].type and configdata[tostring(i)].type == 1 then
            configdata[tostring(i)].sortdata = self.data.status and self.data.status[tostring(configdata[tostring(i)].task_id)] or 0
            table.insert(table1,configdata[tostring(i)])
        else
            if self.data.status and self.data.status[tostring(configdata[tostring(i)].task_id)] and self.data.status[tostring(configdata[tostring(i)].task_id)] > 1 then
                configdata[tostring(i)].sortdata = -1
            else
                configdata[tostring(i)].sortdata = self.data.status and self.data.status[tostring(configdata[tostring(i)].task_id)] or 0
            end
            table.insert(table2,configdata[tostring(i)])
        end
    end

    local sortfunc = function(a,b)
        if a["sortdata"] == b["sortdata"] then
            return a.task_id < b.task_id
        else
            return a["sortdata"] > b["sortdata"]
        end
    end
    table.sort(table2,sortfunc)

    for k,v in ipairs(table1) do
        table.insert(self.inventconfig,v)
    end

    for k,v in ipairs(table2) do
        table.insert(self.inventconfig,v)
    end

    if not self.listview then
        self:createlist()
    else
        self.listview:reloadData()
    end
end


function playerrecall.setinventconfig(self,item,index)
    local config = self.inventconfig[index]
    local data = self.data.status and self.data.status[tostring(config.task_id)] or 0

    if config.type and config.type == 1 and data > 1 then
        data = 1
    end

    local cid, num = ui.getIDandNUM(config.reward)
    item.des1:setString(config.name)
    item.des2:setString(config.name)

    ui.setNewIcon(item,{cid = cid, num = num})

    item.getbutton:setTouchPriority(-102)

    --
    item["i_button"]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        ui.setPopwindowByCid(cid)
    end, CCControlEventTouchUpInside)
    item["i_button"]:setTouchPriority(-103)
    --

    if data == 0 then
        if config.type and config.type == 1 then
            item.nonenode:setVisible(false)
            item.getNode:setVisible(true)
        else
            item.nonenode:setVisible(true)
            item.getNode:setVisible(false)
        end
        item.hasnode:setVisible(false)
        item.getbutton:addHandleOfControlEvent(function()
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","playerrecall",1)})
        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",item.getbutton)
        ui.addGray("CCLabelTTF",item.gettext)
        item.gettext:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setLabelString(item.gettext,nil,18)
    elseif data == 1 then
        item.nonenode:setVisible(false)
        item.getNode:setVisible(true)
        item.hasnode:setVisible(false)
        item.gettext:setString(gameConfig.strings:string_common("moreCommon",6))
        ui.setLabelString(item.gettext,nil,18)
        item.getbutton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3771, id = config.task_id})
        end, CCControlEventTouchUpInside)
        ui.removeGray("CCControlButton",item.getbutton)
        ui.removeGray("CCLabelTTF",item.gettext)
    elseif data >= 2 then
        item.nonenode:setVisible(false)
        item.getNode:setVisible(false)
        item.hasnode:setVisible(true)
        item.gettext:setString(gameConfig.strings:string_common("moreCommon",5))
        ui.setLabelString(item.gettext,nil,18)
        item.getbutton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",item.getbutton)
        ui.addGray("CCLabelTTF",item.gettext)
    end
end

function playerrecall.clear(self)
    gameTouch:UnrigistFunc("begin","playerrecall")
    gameTouch:UnrigistFunc("end","playerrecall")

    if gameTimer.times["playerrecalltime"] then
        gameTimer:UnrigistTimeFunc("playerrecalltime")
    end

    self.inventconfig = {}
    self.show = false
    self.listview = nil

    self.data = nil
    self.coverccb = nil
    self.coveritems = nil
end



return playerrecall