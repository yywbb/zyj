--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/22
-- Time: 下午8:07
-- To change this template use File | Settings | File Templates.
--

local invent = {
    isscrolltouched = false,
    buttontouch = -103,
    statusconfig = {
        [0] = gameConfig.strings:string_common("moreCommon",11),
        [1] = gameConfig.strings:string_common("moreCommon",6),
        [2] = gameConfig.strings:string_common("moreCommon",5),
    },

    selfconfig = {},
    inventconfig = {},

    normalCellSize = {x=1080,y=228+14},
}

function invent.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/yaoqinghaoyou2",nil, true, "invent")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.scroll:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-180-712))

    self.coveritems.copyNode:setVisible(true)
    ui.setLabelString(self.coveritems.copyLab,"复制",18)
    self.coveritems.copybutton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if ui.setStringToPasteBoard(self.data.code) then
            runGamePrompt({msg = "复制成功"})
        end

    end, CCControlEventTouchUpInside)

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(9)].generalanimation)].name
    self.coveritems["generalNode1"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create("nanzhujueyijie/nanzhujueyijie.json","nanzhujueyijie/nanzhujueyijie.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode1"]:addChild(Gneral1)

    -- self.coveritems["generalNode2"]:removeAllChildrenWithCleanup(true)
    -- local Gneral2 = CCSkeletonAnimation:create("nvzhujueyijie/nvzhujueyijie.json","nvzhujueyijie/nvzhujueyijie.atlas",1)
    -- Gneral2:setAnimation("stand",true,0)
    -- Gneral2:setScale(2)
    -- Gneral2:setPosition(0,0)
    -- self.coveritems["generalNode2"]:addChild(Gneral2)

    -- self.coveritems.inventdes:setString("接受邀请的好友需要领取"..gamedata.config.global_kv.invite_valid_level.value.."级邀请奖励方能计入“成功邀请”。")
    self.coveritems.inventdes:setString("等级" .. gamedata.config.global_kv.invite_valid_level.value)
    for i=1,3 do
        ui.setLabelString(self.coveritems["desc" .. i], nil, 1)
    end

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","invent",touchbegin)

    local function touchend(pos)
        if self.coveritems.scroll and ui.isTouched(self.coveritems.scroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","invent",touchend)
    --

    return self.coverccb
end

function invent.createlist(self)

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

--            if self.inventconfig[a1+1].type == 1 then
--               self:setselfconfig(ccbDocumentControler,a1+1)
--            else
                self:setinventconfig(ccbDocumentControler,a1+1)
--            end

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

function invent.reloaddata(self,data)
    if not self.show then return end

    self.data = data

    local configdata = gamedata.config.invite
    self.selfconfig = {}
    self.inventconfig = {}

--    for i=1, table.getTableLength(configdata) do
--        if configdata[tostring(i)].type == 1 then
--            table.insert(self.selfconfig,configdata[tostring(i)])
--            if #self.inventconfig < 1 then
--               table.insert(self.inventconfig,configdata[tostring(i)])
--            end
--        else
--            table.insert(self.inventconfig,configdata[tostring(i)])
--        end
--    end

    table.insert(self.inventconfig,{id = 0, type = 0, showindex = ((self.data.selfstatus == 0) and 0 or 300)})
    for k,v in pairs(configdata) do
        local showindex = v.sorting or 0
        if self.data.status[tostring(v.id)] and self.data.status[tostring(v.id)] == 1 then
            showindex = showindex + 100
        elseif self.data.status[tostring(v.id)] and self.data.status[tostring(v.id)] == 2 then
            showindex = showindex + 300
        else
            showindex = showindex + 200
        end
        v.showindex = showindex
        table.insert(self.inventconfig,v)
    end
    --
    local sortfunc = function (a,b)
        if a.showindex == b.showindex then
            return a.id < b.id
        else
            return a.showindex < b.showindex
        end
    end
    table.sort(self.inventconfig,sortfunc)
    --


    self.coveritems.hasnum:setString(self.data.inventnum)
    self.coveritems.mykey:setString(self.data.code)

    if not self.listview then
        self:createlist()
    else
        self.listview:reloadData()
    end
end

function invent.setselfconfig(self,item,index)
    item.getbutton:setTouchPriority(-102)

    if self.data.selfstatus == 0 then
        item.getNode:setVisible(true)
        item.nonenode:setVisible(false)

        item.des1:setString(gameConfig.strings:string_common("moreCommon",12))
        item.des2:setString(gameConfig.strings:string_common("moreCommon",12))
        item.gettext:setString(gameConfig.strings:string_common("moreCommon",13))
        ui.setLabelString(item.gettext,nil,18)
        item.getbutton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("invent",{code = self.data.code},nil)
        end, CCControlEventTouchUpInside)

        ui.setNewIcon(item,{cid = 1001,})
    else
        item.gettext:setString(gameConfig.strings:string_common("moreCommon",5))
        ui.setLabelString(item.gettext,nil,18)
        item.getbutton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
        end, CCControlEventTouchUpInside)

        item.getNode:setVisible(false)
        item.nonenode:setVisible(false)
        item.hasnode:setVisible(true)

        for k,v in ipairs(self.selfconfig) do
            local cid, num = ui.getIDandNUM(v.reward)
            item.des1:setString(gameConfig.strings:getLv(v.param))
            item.des2:setString(gameConfig.strings:rewardNameNum(v.name,num))
            ui.setNewIcon(item,{cid = cid, num = num})

            --
            item["i_button"]:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
                ui.setPopwindowByCid(cid)
            end, CCControlEventTouchUpInside)
            item["i_button"]:setTouchPriority(-103)
            --

            if self.data.status[tostring(v.id)] == 2 then
                ui.addGray("CCControlButton",item.getbutton)
                ui.addGray("CCLabelTTF",item.gettext)
            elseif  self.data.status[tostring(v.id)] == 1 then
                item.getNode:setVisible(true)
                item.nonenode:setVisible(false)
                item.hasnode:setVisible(false)
                item.gettext:setString(gameConfig.strings:string_common("moreCommon",6))
                ui.setLabelString(item.gettext,nil,18)
                item.getbutton:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    UIRequest({type = 2082, id = v.id})
                end, CCControlEventTouchUpInside)
                ui.removeGray("CCControlButton",item.getbutton)
                ui.removeGray("CCLabelTTF",item.gettext)
                break
            elseif  self.data.status[tostring(v.id)] == 0 then
                item.getNode:setVisible(false)
                item.nonenode:setVisible(true)
                item.hasnode:setVisible(false)
                item.getbutton:addHandleOfControlEvent(function()
                end, CCControlEventTouchUpInside)
                ui.addGray("CCControlButton",item.getbutton)
                ui.addGray("CCLabelTTF",item.gettext)
                break
            end
        end
    end
end

function invent.setinventconfig(self,item,index)
    local config = self.inventconfig[index]

    if config.type == 0 then
        item.nonenode:setVisible(false)
        item.des1:setString(gameConfig.strings:string_common("moreCommon",12))
        item.des2:setString(gameConfig.strings:string_common("moreCommon",12))
        item.gettext:setString(gameConfig.strings:string_common("moreCommon",13))
        ui.setLabelString(item.gettext,nil,18)
        item.getbutton:setTouchPriority(-102)
        item.getbutton:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("invent",{code = self.data.code},nil)
        end, CCControlEventTouchUpInside)
        ui.setNewIcon(item,{cid = 1001,})
        if self.data.selfstatus == 0 then
            item.getNode:setVisible(true)
            item.hasnode:setVisible(false)
            ui.removeGray("CCControlButton",item.getbutton)
            ui.removeGray("CCLabelTTF",item.gettext)
        else
            item.getNode:setVisible(false)
            item.hasnode:setVisible(true)
        end
    else
        local data = self.data.status[tostring(config.id)] or 0

        local cid, num = ui.getIDandNUM(config.reward)

        if config.type == 1 then
            item.des1:setString(gameConfig.strings:getLv(config.param)..((self.data.selfstatus == 0) and "   (需接受他人邀请)" or ""))
            item.des2:setString(gameConfig.strings:rewardNameNum(config.name,num))
        else
            item.des1:setString(gameConfig.strings:getSuccessPalays(config.param))
            item.des2:setString(gameConfig.strings:rewardNameNum(config.name,num))
        end

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
            item.nonenode:setVisible(true)
            item.getNode:setVisible(false)
            item.hasnode:setVisible(false)
            item.getbutton:addHandleOfControlEvent(function()

            end, CCControlEventTouchUpInside)
            ui.addGray("CCControlButton",item.getbutton)
            ui.addGray("CCLabelTTF",item.gettext)
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
                UIRequest({type = 2082, id = config.id})
            end, CCControlEventTouchUpInside)
            ui.removeGray("CCControlButton",item.getbutton)
            ui.removeGray("CCLabelTTF",item.gettext)
        elseif data == 2 then
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
end

function invent.clear(self)
    gameTouch:UnrigistFunc("begin","invent")
    gameTouch:UnrigistFunc("end","invent")
    self.selfconfig = {}
    self.inventconfig = {}
    self.show = false
    self.listview = nil

    self.data = nil
    self.coverccb = nil
    self.coveritems = nil
end

-- function invent.setPage(self)
--     UIRequest({type = 2000,page = GameScene.layers["activity"].module.type})
--     UIRequest({ type = 2080 })
-- end

-- function invent.UIUpdateData(self, isreset)
--     if isreset then
--         self.data = nil
--         self:setPage()
--     end
-- end


return invent