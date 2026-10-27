--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local cumulativerecharge = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    status = {},
    ListTableView = nil,
    normalCellSize = {x=1080,y=282+14},
}


function cumulativerecharge.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/leijichongzhi2",nil, true, "reward")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-640))

    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.protagonist.general.cid)].animationid)].name
    -- local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(78)].generalanimation)].name
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)

    self.coveritems.rechargebutton:setTouchPriority(self.buttontouch)
    self.coveritems.rechargebutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end, CCControlEventTouchUpInside)
    -- ui.setStringWithStrokeAndShadow(self.coveritems.rechargeLab,nil,1)

    self.coveritems.desc4:setString("（充值268元送             ）")

    ui.setStringWithStrokeAndShadow(self.coveritems.desc,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc3,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc4,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc1,nil,11)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc2,nil,11)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","cumulativerecharge",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","cumulativerecharge",touchend)
    --

    return self.coverccb
end

function cumulativerecharge.reloaddata(self,data)
    if not self.show then return end
    --
    if not data then return end
    self.status = data.status or {}

    if data.rmb then
        self.coveritems.rmb:setString(gameConfig.strings:money(data.rmb))
    end

    -- ui.setStringWithStrokeAndShadow(self.coveritems.desc2,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.rmb,nil,1)
    -- 活动时间
    local cpnum = data and data.cpnum or 0
    local cpday = data and data.cpday or 0
    local timediff = 0
    if self.coveritems.time and gamedata.config.activity_time["78"]["open_type"] and gamedata.config.activity_time["78"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        timediff = 86400*(gamedata.config.activity_time["78"]["continued_time"..((cpnum == 1) and ("_1") or "")]-cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
    elseif self.coveritems.time and gamedata.config.activity_time["78"]["open_type"] and gamedata.config.activity_time["78"]["open_type"] == 2 then
        self.coveritems.time:setString("")
        self.coveritems.desc1:setString("")
    elseif self.coveritems.time and gamedata.config.activity_time["78"]["open_type"] and gamedata.config.activity_time["78"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["78"]["continued_time"] - nowtime - temp.hour*3600 - temp.min*60 - temp.sec

    elseif self.coveritems.time and gamedata.config.activity_time["78"]["end"] and gamedata.config.activity_time["78"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["78"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime;
    elseif self.coveritems.time then
        self.coveritems.time:setString("")
        self.coveritems.desc1:setString("")
    end


    if self.coveritems.time and timediff and timediff > 0 then
        gameTimer:rigistTime("ActivityTotalcharge",timediff)

        if gameTimer.times["ActivityTotalcharge"] and gameTimer.times["ActivityTotalcharge"] > 0 then
            gameTimer:rigistTimeFunc("ActivityTotalcharge", function()
                if gameTimer.times["ActivityTotalcharge"] <= 0 then
                    if gameTimer.times["ActivityTotalcharge"] then
                        gameTimer:UnrigistTimeFunc("ActivityTotalcharge")
                    end
                else
                    self.coveritems.time:setString(ui.makeTimeDayText(gameTimer.times["ActivityTotalcharge"],"day"))
                    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
                end
            end)
        end
    end

    ui.setStringWithStrokeAndShadow(self.coveritems.time,nil,1)
    ui.setStringWithStrokeAndShadow(self.coveritems.desc1,nil,1)
    -- self.data = {}
    -- for k,v in pairs(gamedata.config.recharge_gift) do
    --     table.insert(self.data,v)
    -- end

    -- table.sort(self.data, function(a,b) return a.id < b.id end)

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

function cumulativerecharge.clear(self)
    gameTouch:UnrigistFunc("begin","cumulativerecharge")
    gameTouch:UnrigistFunc("end","cumulativerecharge")

    if gameTimer.times["ActivityTotalcharge"] then
        gameTimer:UnrigistTimeFunc("ActivityTotalcharge")
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.coverccb = nil
    self.coveritems = nil
end

function cumulativerecharge.createList(self)
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

            -- self:setCell(ccbDocumentControler,self.data[a1+1],a1+1)
            self:setCell(ccbDocumentControler, self.status[tostring(a1+1)].recharge, a1+1)

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


function cumulativerecharge.setCell(self,item,data,index)
    print("setCell")

    item.doButton:setTouchPriority(-102)
    if self.status[tostring(index)].status and self.status[tostring(index)].status == 1 then
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
            UIRequest({type = 5001, id = data.id or 1})
        end, CCControlEventTouchUpInside)
    elseif self.status[tostring(index)].status and self.status[tostring(index)].status == 2 then
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
        item.nonenode:setVisible(false) -- true
        item.rechargeNode:setVisible(true) -- 去充值
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

        -- 去充值
        ui.setLabelString(item.rechargeLab, nil, 18)
        item.rechargeButton:addHandleOfControlEvent(function()
        -- 弹出充值窗口
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if gameTouch.isScrollling then return end
            gameWindows:openWindow("recharge",{pagetype = "info"})
        end, CCControlEventTouchUpInside)
        item.rechargeButton:setTouchPriority(self.buttontouch)
    end

    item.title:setString(gameConfig.strings:addRechage2(data.rmb))
    local props = ui.getIDandNUMs(data.reward) or {}

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

    if props[4] and props[4].cid then
        item.typenode:setVisible(true)
        item.reward4:setVisible(true)
    else    
        item.typenode:setVisible(false)
        item.reward4:setVisible(false)
    end

end



return cumulativerecharge �4  