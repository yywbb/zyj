--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local doubleoutput = {
    isscrolltouched = false,
    buttontouch = -103,
    data = {},
    ListTableView = nil,
    normalCellSize = {x=920,y=200},
}


function doubleoutput.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/51huodong",nil, true, "51huodong")

    self.coveritems.midnode:setPositionY(self.contentsize.y/2+50)

    local allconfig = gamedata.config.double_output or {}
    self.data = {}
    for k,v in pairs(allconfig) do
        if v.show and v.show == 1 then
            table.insert(self.data,v)
        end
    end
    local sortById = function(a,b) return a.id < b.id end
    table.sort(self.data, sortById)
    --
    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","doubleoutput",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","doubleoutput",touchend)
    --
    local beginString = ""
    local endString = ""
    if gamedata.config.activity_time["30"]["begin"] and gamedata.config.activity_time["30"]["begin"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["30"]["begin"])
        beginString = year.."."..month.."."..day
    end
    if gamedata.config.activity_time["30"]["end"] and gamedata.config.activity_time["30"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["30"]["end"])
        endString = year.."."..month.."."..day
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日24时"
        end
    end
    ui.setLabelString(self.coveritems["activitytime"],"活动结束时间: "..endString,18)
    --
    self:reloaddata()

    return self.coverccb
end

function doubleoutput.reloaddata(self)

    if not self.show then return end


    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
    end

end

function doubleoutput.clear(self)

    gameTouch:UnrigistFunc("begin","doubleoutput")
    gameTouch:UnrigistFunc("end","doubleoutput")

    self.data = {}
    self.show = false
    self.ListTableView = nil

    self.coverccb = nil
    self.coveritems = nil
end

function doubleoutput.createList(self)
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_51huodong", nil, true, "cell_51huodong")
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
            r = table.getTableLength(self.data)
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


function doubleoutput.setCell(self,item,index)
    print("setCell")

    local config = self.data[index] or {}

    item["name"]:setString(config.name or "")

    ui.setLabelString(item["gotoLab"],nil,18)
    --
    item["gotoButton"]:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if GameScene.layers["activity"].module.isContentScroll then  return end

        if config.function_id then
            GameScene:shiftLayerById(config.function_id)
        end

    end, CCControlEventTouchUpInside)
    item["gotoButton"]:setTouchPriority(-103)
    --

end



return doubleoutput