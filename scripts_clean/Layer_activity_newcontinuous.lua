--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/25
-- Time: 15:30
-- To change this template use File | Settings | File Templates.
--

local newcontinuous = {
    isscrolltouched = false,
    buttontouch = -103,

    data = {},
    status = {},
    index = 1,
    ListTableView = nil,
    normalCellSize = {x=1080,y=282+14},
}


function newcontinuous.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/lianxudenglu3",nil, true, "reward")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-160-450-20))

    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    local Gneral1 = CCSkeletonAnimation:create("hexiangu/hexiangu.json","hexiangu/hexiangu.atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)
    --self.coveritems.desc:setString("连续登录奖励")

    --self.coveritems.desc1:setString("")
    --self.coveritems.time:setString("")

    if self.coveritems.desc1 and self.coveritems.desc2 then
        ui.setLabelString(self.coveritems.desc1,nil,1)
        ui.setLabelString(self.coveritems.desc2,nil,1)
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","newcontinuous",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","newcontinuous",touchend)
    --
    if self.coveritems.desc_muyou then
        self.coveritems.desc_muyou:setVisible(true)
        --ui.setLabelString(self.coveritems.desc_muyou,nil,24)
    end    
    --

    return self.coverccb
end

function newcontinuous.reloaddata(self,data)
    if not self.show then return end
    --todo
    self.status = data or {}
    self.index = self.status["1"] or 1

    self.data = gamedata.config.continue7_X1 or {}

    --
    if self.index > table.getTableLength(self.data) then self.index = table.getTableLength(self.data) end
    local len = table.getTableLength(self.data) - self.index + 1
    if len < 3 then len = 3 end
    --

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else
            self.ListTableView:reloadData()
        end
        self.ListTableView:setLuaContentOffset(0, self.coveritems.listnode:getContentSize().height - len*self.normalCellSize.y)
    end


end

function newcontinuous.clear(self)
    gameTouch:UnrigistFunc("begin","newcontinuous")
    gameTouch:UnrigistFunc("end","newcontinuous")
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.status = {}
    self.index = 1
    self.coverccb = nil
    self.coveritems = nil
end

function newcontinuous.createList(self)
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

            self:setCell(ccbDocumentControler,self.data[tostring(a1+1)])

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
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


function newcontinuous.setCell(self,item,data)
    print("setCell")

    item.doNode:setVisible(true)
    item.typenode:setVisible(false)
    item.reward4:setVisible(false)

    -- item.title:setString("连续登录第"..data.day.."天")
    item.title:setString(gameConfig.strings:sign_day(data.day))

    local reward = {}
    reward = ui.getIDandNUMs(data.reward)

    for i=1, 3 do
        if reward[i] and reward[i].cid > 0 then
            item["reward"..i]:setVisible(true)

            local config = ui.IDconfig(reward[i].cid)
            if config then
                ui.setNewIcon(item,{cid = reward[i].cid, num = reward[i].num},i-1)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    ui.setPopwindowByCid(reward[i].cid)
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        else
            item["reward"..i]:setVisible(false)
        end
    end

    item.doButton:setTouchPriority(-102)

    if self.index == data.day then
        if self.status[tostring(self.index+1)] and self.status[tostring(self.index+1)] == 0 then
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
                UIRequest({type = 215})
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
                runGamePrompt({msg = gameConfig.strings:string_common("buttontext","yilingqu")})
            end, CCControlEventTouchUpInside)
        end
    elseif  self.index+0 > data.day+0 then
        ui.addGray("CCControlButton",item.doButton)
        ui.addGray("CCLabelTTF",item.doLab)
        item.nonenode:setVisible(false)
        item.doNode:setVisible(false)
        item.hasnode:setVisible(false)
        item.doLab:setString(gameConfig.strings:string_common("buttontext","lingqu"))
        ui.setStringWithStrokeAndShadow(item.doLab,nil,1)
        item.doButton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",3)})
        end, CCControlEventTouchUpInside)
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



return newcontinuous