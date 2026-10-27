--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local activityachievements = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    status = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=240},
}


function activityachievements.init(self,size)
    self.contentsize = size
    self.show = true

    if gamedata.config.build[tostring(438)] and gamedata.config.build[tostring(438)].switch and gamedata.config.build[tostring(438)].switch == 1 then
        self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/xianshichengjiu_shengdan",nil, true, "activityshengdan")
    else
        self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/xianshichengjiu",nil, true, "reward")
    end

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-490))

    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    if activityConfig[tostring(56)].generalanimation and activityConfig[tostring(56)].generalanimation > 0 then
        local name = generalConfig[tostring(activityConfig[tostring(56)].generalanimation)].name
        local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(2)
        Gneral1:setPosition(0,0)
        self.coveritems["generalNode"]:addChild(Gneral1)
    end


    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","activityachievements",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","activityachievements",touchend)
    --

    return self.coverccb
end

function activityachievements.reloaddata(self,data)
    if not self.show then return end
    --
    if not data then return end
    self.status = data.status or {}


    -- 活动时间
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["56"]["open_type"] and gamedata.config.activity_time["56"]["open_type"] == 2 then
        self.coveritems.time:setString("")
        self.coveritems.desc1:setString("")
    elseif self.coveritems.time and gamedata.config.activity_time["56"]["open_type"] and gamedata.config.activity_time["56"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["56"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["56"]["open_type"] and gamedata.config.activity_time["56"]["open_type"] == 7 then
        timediff = GameScene.layers["activity"].module:getDailyCpActivityTime(56)
        
    elseif self.coveritems.time and gamedata.config.activity_time["56"]["end"] and gamedata.config.activity_time["56"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["56"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        self.coveritems.time:setString("")
        self.coveritems.desc1:setString("")
    end


    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("ActivityAchievements",timediff)

        if gameTimer.times["ActivityAchievements"] and gameTimer.times["ActivityAchievements"] > 0 then
            gameTimer:rigistTimeFunc("ActivityAchievements", function()
                if gameTimer.times["ActivityAchievements"] <= 0 then
                    if gameTimer.times["ActivityAchievements"] then
                        gameTimer:UnrigistTimeFunc("ActivityAchievements")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["ActivityAchievements"],"day"))
                end
            end)
        end
    end


    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else                                                                                                                     -- self.data                         
            if self.ListTableView:getLuaContentOffsetY() < self.coveritems.listnode:getContentSize().height - table.getTableLength(self.status)*self.normalCellSize.y then
                self.ListTableView:setLuaContentOffset(0, self.coveritems.listnode:getContentSize().height - table.getTableLength(self.status)*self.normalCellSize.y)
            end
            self.ListTableView:reloadData()
        end
    end

end

function activityachievements.clear(self)
    gameTouch:UnrigistFunc("begin","activityachievements")
    gameTouch:UnrigistFunc("end","activityachievements")

    if gameTimer.times["ActivityAchievements"] then
        gameTimer:UnrigistTimeFunc("ActivityAchievements")
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.coverccb = nil
    self.coveritems = nil
end

function activityachievements.createList(self)
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
                -- cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward1", nil, true, "cell_reward1")
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_xianshichengjiu_shengdan", nil, true, "cell_xianshichengjiu_shengdan")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            -- self:setCell(ccbDocumentControler,self.data[a1+1],a1+1)
            self:setCell(ccbDocumentControler, self.status[tostring(a1+1)], a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            -- r = table.getTableLength(self.data)
            r = table.getTableLength(self.status)
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


function activityachievements.setCell(self,item,data,index)
    print("setCell")

    item.doButton:setTouchPriority(-102)
    if data.status and data.status == 1 then
        item.rechargeNode:setVisible(false) -- 增加去充值
        item.nonenode:setVisible(false)
        item.doNode:setVisible(true)
        item.hasnode:setVisible(false)
        ui.removeGray("CCControlButton",item.doButton)
        ui.removeGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("buttontext","lingqu"))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            gameTouch:clickprofbytime(1)
            print("getbutton clicked")
            UIRequest({type = 3761, id = data.config.id or 1})
        end, CCControlEventTouchUpInside)
    elseif data.status and data.status == 2 then
        item.rechargeNode:setVisible(false) -- 增加去充值
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(true)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("buttontext","yilingqu"))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)
    else
        item.nonenode:setVisible(true) -- true
        item.rechargeNode:setVisible(false) -- 去充值
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.doLab:setString(gameConfig.strings:string_common("buttontext","lingqu"))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","weiwancheng")})
        end, CCControlEventTouchUpInside)

    end

    item.title:setString(data.config.desc)
    local props = ui.getIDandNUMs(data.config.reward) or {}

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
            item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                print("i_button")
            end, CCControlEventTouchUpInside)
            item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
            --
        end
    end

    item.typenode:setVisible(false)
    item.reward4:setVisible(false)

    local lavenum = data.num or 0
    local maxlavenum = data.config.param or 0
    item.lavenum:setVisible(true)
    item.lavenum:setString(gameConfig.strings:string_common("fixedString","reward",1)..((lavenum > maxlavenum) and maxlavenum or lavenum).."/"..maxlavenum)

end


return activityachievements