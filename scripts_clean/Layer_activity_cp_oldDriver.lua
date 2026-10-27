--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local olddriver = {
    isscrolltouched = false,
    buttontouch = -103,
    data = {},
    ListTableView = nil,
    normalCellSize = {x=1040,y=210},
    page = 1,
    fixstr = "olderDriver",

    cpnum = 0,
    cpday = 0,
    laosijiconfig = {},

    initshow = false,
}


function olddriver.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityolddriver/olddriver1",nil, true, "olddriver")

    self.coveritems.topnode1:setPositionY(self.contentsize.y-180)
    self.coveritems.topnode2:setPositionY(self.contentsize.y-180)
    self.coveritems.midnode2:setPositionY(self.contentsize.y/2-200)

    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-600-20))


    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","olddriver",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","olddriver",touchend)
    --

    if self.page and self.page == 2 then
        self.coveritems.page2:setVisible(true)
        self.coveritems.page1:setVisible(false)
        self.coveritems.page2:setPositionX(0)
        self.coveritems.page1:setPositionX(99999)
    else
        self.coveritems.page1:setVisible(true)
        self.coveritems.page2:setVisible(false)
        self.coveritems.page1:setPositionX(0)
        self.coveritems.page2:setPositionX(99999)
    end
    --
    self.coveritems["closeButton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        self.page = 1
        self.coveritems.page1:setVisible(true)
        self.coveritems.page2:setVisible(false)
        self.coveritems.page1:setPositionX(0)
        self.coveritems.page2:setPositionX(99999)
    end, CCControlEventTouchUpInside)
    self.coveritems["closeButton"]:setSwallowsTouch(true)
    self.coveritems["closeButton"]:setTouchPriority(-104)

    self.coveritems["driverButton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then return end
        self.page = 2
        self.coveritems.page2:setVisible(true)
        self.coveritems.page1:setVisible(false)
        self.coveritems.page2:setPositionX(0)
        self.coveritems.page1:setPositionX(99999)
    end, CCControlEventTouchUpInside)
    self.coveritems["driverButton"]:setSwallowsTouch(true)
    self.coveritems["driverButton"]:setTouchPriority(-104)

    return self.coverccb
end

function olddriver.reloaddata(self,data)

    self.data = data and data.data or self.data
    self.cpnum = data and data.cpnum or self.cpnum
    self.cpday = data and data.cpday or self.cpday

    self.laosijiconfig = gamedata.config["laosiji"..(self.cpnum>0 and ("_"..self.cpnum) or "")]

    if not self.show then return end

    local generalshow = 10559
    -- 10559于  10595王  10594雷
    local generalshow,generalnum = ui.getIDandNUM(self.laosijiconfig["0"].rewards)
    --
    local activityConfig = gamedata.config.activity_time
    --fix
    if generalshow == 10595 then
        self.fixstr = "olderDriver3"
        if self.coveritems.activitybg then
            setSpriteFrameByName(self.coveritems.activitybg,"bg_tupo.jpg")
            setSpriteFrameByName(self.coveritems.hasdriver,"yiqingan")
        end
    elseif generalshow == 10594 then
        self.fixstr = "olderDriver2"
        if self.coveritems.activitybg then
            setSpriteFrameByName(self.coveritems.activitybg,"nightclubbg_jiuba.jpg")
            setSpriteFrameByName(self.coveritems.hasdriver,"yisongli")
        end
    else
        self.fixstr = "olderDriver"
        if self.coveritems.activitybg then
            setSpriteFrameByName(self.coveritems.activitybg,"bg_tupo.jpg")
            setSpriteFrameByName(self.coveritems.hasdriver,"olddriver_4")
        end
    end
    self:initFixedString()
    --
    local generalConfig = gamedata.config.generalanimation
    if (not self.initshow) and ui.IDconfig(generalshow).animationid and tonumber(ui.IDconfig(generalshow).animationid) > 0 then
        local name = generalConfig[tostring(ui.IDconfig(generalshow).animationid)].name
        self.coveritems["generalnode1"]:removeAllChildrenWithCleanup(true)
        self.coveritems["generalnode2"]:removeAllChildrenWithCleanup(true)
        local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(2)
        Gneral1:setPosition(0,0)
        local Gneral2 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
        Gneral2:setAnimation("stand",true,0)
        Gneral2:setScale(2)
        Gneral2:setPosition(0,0)
        self.coveritems["generalnode1"]:addChild(Gneral1)
        self.coveritems["generalnode2"]:addChild(Gneral2)

        self.coveritems.g_name:setString(ui.IDconfig(generalshow).name)
        if not gameConfig.images[ui.IDconfig(generalshow).actor] then
            setSpriteFrameByName(self.coveritems["g_type"], gameConfig.images.alpha)
        else
            setSpriteFrameByName(self.coveritems["g_type"], gameConfig.images[ui.IDconfig(generalshow).actor])
        end
        if self.coveritems["generalButton"] then
            self.coveritems["generalButton"]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then return end
                ui.setPopwindowByCid(generalshow)
            end, CCControlEventTouchUpInside)
            self.coveritems["generalButton"]:setSwallowsTouch(true)
            self.coveritems["generalButton"]:setTouchPriority(-104)
        end
        --
        self.initshow = true
    end
    --
    local endString = ""
    if gamedata.config.activity_time["86"]["open_type"] and gamedata.config.activity_time["86"]["open_type"] == 5 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", nowtime)
        local timediff = nowtime + 86400*(gamedata.config.activity_time["86"]["continued_time"..((self.cpnum == 1) and ("_1") or "")]-self.cpday+1) - temp.hour*3600 - temp.min*60 - temp.sec
        local endtab = os.date("*t", timediff-2)
        endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        ui.setLabelString(self.coveritems["lab1_time"],gameConfig.strings:string_common("fixedString",self.fixstr,1)..endString,14)
    elseif gamedata.config.activity_time["86"]["open_type"] and gamedata.config.activity_time["86"]["open_type"] == 1 then
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local endt = GameScene.roleinfo.servertime + 86400*gamedata.config.activity_time["86"]["continued_time"] - temp.hour*3600 - temp.min*60 - temp.sec - 1
        local endtab = os.date("*t",endt)
        endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日".."24时"
        ui.setLabelString(self.coveritems["lab1_time"],gameConfig.strings:string_common("fixedString",self.fixstr,1)..endString,14)
    elseif gamedata.config.activity_time["86"]["open_type"] and gamedata.config.activity_time["86"]["open_type"] == 2 then
        ui.setLabelString(self.coveritems["lab1_time"],"",14)
    elseif gamedata.config.activity_time["86"]["end"] and gamedata.config.activity_time["86"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["86"]["end"])
        endString = year.."."..month.."."..day
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日".."24时"
        end
        ui.setLabelString(self.coveritems["lab1_time"],gameConfig.strings:string_common("fixedString",self.fixstr,1)..endString,14)
    end

    --
    ui.setLabelString(self.coveritems["driverLab"],gameConfig.strings:string_common("fixedString",self.fixstr,2),19)
    ui.setLabelString(self.coveritems["doLab"],gameConfig.strings:string_common("fixedString",self.fixstr,2),19)
    ui.setLabelString(self.coveritems["lab2_2"],nil,14)
    ui.setLabelString(self.coveritems["lab2_1"],nil,18)
    --


    --

    if self.data.buystatus and self.data.buystatus > 1 then
        self.coveritems.hasdriver:setVisible(true)
        self.coveritems.driverNode:setVisible(false)
        self.page = 1
    else
        self.coveritems.hasdriver:setVisible(false)
        self.coveritems.driverNode:setVisible(true)
    end

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end

    self:setDriver()
    self:setPage()

end

function olddriver.setPage(self)
    if self.page and self.page == 2 then
        self.coveritems.page2:setVisible(true)
        self.coveritems.page1:setVisible(false)
        self.coveritems.page2:setPositionX(0)
        self.coveritems.page1:setPositionX(99999)
    else
        self.coveritems.page1:setVisible(true)
        self.coveritems.page2:setVisible(false)
        self.coveritems.page1:setPositionX(0)
        self.coveritems.page2:setPositionX(99999)
    end
end

function olddriver.clear(self)

    gameTouch:UnrigistFunc("begin","olddriver")
    gameTouch:UnrigistFunc("end","olddriver")

    self.initshow = false

    self.page = 1
    self.data = {}
    self.show = false
    self.ListTableView = nil

    self.coverccb = nil
    self.coveritems = nil
end

function olddriver.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityolddriver/cell_olddriver1", nil, true, "cell_olddriver")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,a1+1)

            cellCCB:setPosition(self.normalCellSize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.itemsdata or {})
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


function olddriver.setCell(self,item,index)
    print("setCell")
    local celldata = self.data.itemsdata and self.data.itemsdata[tostring(index)]
    if not celldata then return end

    local configdata = self.laosijiconfig and self.laosijiconfig[tostring(celldata.id)] or {}

    item.des1:setString(configdata.name or "")
    local rewards = ui.getIDandNUMs(configdata.rewards)
    local nameext = ""
    if ui.IDconfig(rewards[1].cid).staffType == "general_fragment" then
        nameext = "魂魄"
    elseif ui.IDconfig(rewards[1].cid).staffType == "equip_fragment" then
        nameext = "碎片"
    end
    item.des2:setString(gameConfig.strings:rewardName(ui.IDconfig(rewards[1].cid).name)..nameext.."x"..rewards[1].num)
    ui.setNewIcon(item,rewards[1])

    --
    item["i_button"]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end
        ui.setPopwindowByCid(rewards[1].cid)
    end, CCControlEventTouchUpInside)
    item["i_button"]:setTouchPriority(-103)
    --
    local need = nil
    --
    if configdata.type and tostring(configdata.type) == "1" then
        item.des2:setString(ui.IDconfig(rewards[1].cid).name..nameext.."x"..rewards[1].num)
        ui.setLabelString(item["getLab"],"购 买",18)
        item["goldnode"]:setVisible(true)
        item["posnode"]:setVisible(false)
        local needs = ui.getIDandNUMs(configdata.need)
        need = needs[1]
        if needs[1] and needs[1].cid == 1000 then
            item["coinsprite"]:setVisible(true)
            item["goldsprite"]:setVisible(false)
        elseif needs[1] and needs[1].cid == 1001 then
            item["goldsprite"]:setVisible(true)
            item["coinsprite"]:setVisible(false)
        end
        ui.setLabelString(item.goldnum,needs[1].num,14)
    else
        item.des2:setString(gameConfig.strings:rewardName(ui.IDconfig(rewards[1].cid).name)..nameext.."x"..rewards[1].num)
        ui.setLabelString(item["getLab"],"领 取",18)
        item["goldnode"]:setVisible(false)
        item["posnode"]:setVisible(true)
        ui.setLabelString(item["pos"],(celldata.num > configdata.target_num and configdata.target_num or celldata.num).."/"..configdata.target_num,14)
    end
    item.getButton:setTouchPriority(-102)
    --
    if self.data.buystatus and self.data.buystatus < 2 then
        item.hasnode:setVisible(false)
        item.getNode:setVisible(true)
        item.getButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString",self.fixstr,3)})
        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",item.getButton)
    elseif celldata.status == 0 then
        item.hasnode:setVisible(false)
        item.getNode:setVisible(true)
        item.getButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","weiwancheng")})
        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",item.getButton)
    elseif celldata.status == 1 then
        item.hasnode:setVisible(false)
        item.getNode:setVisible(true)
        item.getButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            UIRequest({type = 5033, pos = celldata.id, need = need})
        end, CCControlEventTouchUpInside)
        ui.removeGray("CCControlButton",item.getButton)
    elseif celldata.status == 2 then
        item.getNode:setVisible(false)
        item.hasnode:setVisible(true)
        item.getButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("buttontext","yilingqu")})
        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",item.getButton)
    end


end

function olddriver.setDriver(self)
    print("setCell")
    if not self.data.buystatus then return end
    local configdata = self.laosijiconfig and self.laosijiconfig["0"] or {}

    local need = nil
    --
    local needs = ui.getIDandNUMs(configdata.need)
    need = needs[1]

    ui.setLabelString(self.coveritems.drivergold,needs[1].num,14)
    self.coveritems.doButton:setTouchPriority(-103)
    --

    if self.data.buystatus < 2 then
        self.coveritems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            UIRequest({type = 5033, pos = 0, need = need})
        end, CCControlEventTouchUpInside)
        ui.removeGray("CCControlButton",self.coveritems.doButton)
    elseif self.data.buystatus > 1 then
        self.coveritems.doButton:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString",self.fixstr,4)})
        end, CCControlEventTouchUpInside)
        ui.addGray("CCControlButton",self.coveritems.doButton)
    end


end

function olddriver.initFixedString(self)
    self.coveritems.activitytitle1:setString(gameConfig.strings:string_common("fixedString",self.fixstr,7))
    self.coveritems.lab1_1:setString(gameConfig.strings:string_common("fixedString",self.fixstr,6))
    self.coveritems.activitytitle2:setString(gameConfig.strings:string_common("fixedString",self.fixstr,7))
    self.coveritems.lab2_1:setString(gameConfig.strings:string_common("fixedString",self.fixstr,8))
    self.coveritems.lab2_2:setString(gameConfig.strings:string_common("fixedString",self.fixstr,9))
end

return olddriver