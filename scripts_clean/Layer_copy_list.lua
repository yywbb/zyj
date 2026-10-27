--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/9/10
-- Time: 上午11:22
-- To change this template use File | Settings | File Templates.
--

--与海外版有差异，国内版普通副本重置价格和海外不一样

local copymap = {

    resource = nil,


    rootNode = nil,
    rootItems = nil,
    pointListTableView = nil,

    selectedPoint = nil,
    sectionID = nil,
    mapID = nil,

    normaldata = nil,
    bravedata = nil,

    copydata = nil,
    data = nil,

    detailCellSize = {x=1080,y=400},
    normalCellSize = {x=1080,y=230},

    requests= {
        normal = 1300,
        brave = 1330,
    },

    celldict = {},
    unrecycleCell = {},

    datatype = nil,
}

function copymap.setParam(self,param)
    print("setParam",self.sectionID,self.mapID,self.selectedPoint)
    printT(param)
    if param then
        self.sectionID = param.section
        self.mapID = param.map
        self.datatype = param.datatype or self.datatype
        self.selectedPoint = param.point

        if param.normaldata then
            self.normaldata = param.normaldata
        end
        if param.bravedata then
            self.bravedata = param.bravedata
        end
    end
end

function copymap.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("copy/copy_map", nil, true, "copy_map")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.pointsScroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-250-gameConfig.maiscenebottomheight))

    self.rootItems.backButton:setTouchPriority(-111)
    self.rootItems.backButton:setSwallowsTouch(true)
    self.rootItems.backButton:addHandleOfControlEvent(function()
        if self.datatype == "normal" then
            GameScene:shiftLayer("copy_chapter","down",{
                normaldata = self.copydata,
                datatype= "normal",
                section = self.sectionID,
            })
        elseif self.datatype == "brave" then
            GameScene:shiftLayer("copy_chapter","down",{
                bravedata = self.copydata,
                datatype= "brave",
                section = self.sectionID,
            })
        end
    end, CCControlEventTouchUpInside)

    self:setParam(param)
    self:reloaddata()
end

function copymap.clear(self)
    print("copymap.clear")
    if self.unrecycleCell.firstCell then
        self.unrecycleCell.firstCell.cell:release()
    end
    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end

    for k,v in pairs(self.celldict) do
        v.cell:release()
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.unrecycleCell = {}
    self.celldict = {}

    self.pointListTableView = nil

    self.copydata = nil
    --    self.selectedPoint = nil
    --    self.sectionID = nil
    --    self.mapID = nil

    self.rootNode = nil
    self.rootItems = nil
    self.haseffect = false
end


function copymap.setNormalPoint(self,item,data)
    --printT(data)
    if self.datatype == "normal" then
        data.config = gamedata.config.copy[tostring(self.data.id)][tostring(data.id)]
    else
        data.config = gamedata.config.brave_copy[tostring(self.data.id)][tostring(data.id)]
    end

    for i=1,3 do
        item["type"..i]:setVisible(data.config.type == i)
    end


    item.name:setString(data.id.." "..data.config.name)
    item.power:setString(data.config.power)
    for i=1, 3 do
        if i <= data.star then
            setSpriteFrameByName(item["star"..i], gameConfig.images.starON)
        else
            setSpriteFrameByName(item["star"..i], gameConfig.images.starOFF)
        end
    end

    ui.setLabelString(item.exp,data.config.xp,14)
    ui.setLabelString(item.coin,data.config.coin,14)

    if data.config.drop1 and data.config.drop1 ~= 0 then
        item.dropnode:setVisible(true)
        ui.setNewIcon(item,{cid = data.config.drop1})

        item.i_button:setTouchPriority(-112)
        item.i_button:setSwallowsTouch(true)
        item.i_button:addHandleOfControlEvent(function()
            --if ui.IDconfig(data.config.drop1).staffType == "equip" then
                ui.setPopwindowByCid(data.config.drop1)
            --end
        end, CCControlEventTouchUpInside)

    else
        item.dropnode:setVisible(false)

        item.i_button:setTouchPriority(-112)
        item.i_button:setSwallowsTouch(true)
        item.i_button:addHandleOfControlEvent(function()
            print("no drop")
        end, CCControlEventTouchUpInside)
    end

    for i = 2,3 do
        if item["dropnode"..i] and data.config["drop"..i] and data.config["drop"..i] ~= 0 then
            item["dropnode"..i]:setVisible(true)
            ui.setNewIcon(item,{cid = data.config["drop"..i]},i-1)

            item["i_button_"..(i-1)]:setTouchPriority(-112)
            item["i_button_"..(i-1)]:setSwallowsTouch(true)
            item["i_button_"..(i-1)]:addHandleOfControlEvent(function()
            --if ui.IDconfig(data.config["drop"..i]).staffType == "equip" then
                ui.setPopwindowByCid(data.config["drop"..i])
            --end
            end, CCControlEventTouchUpInside)

        elseif item["dropnode"..i] then
            item["dropnode"..i]:setVisible(false)

            item["i_button_"..(i-1)]:setTouchPriority(-112)
            item["i_button_"..(i-1)]:setSwallowsTouch(true)
            item["i_button_"..(i-1)]:addHandleOfControlEvent(function()
                print("no drop")
            end, CCControlEventTouchUpInside)
        end
    end
end

function copymap.wipeFunc(self,data,method)
    print("wipe clicked")
    if data.star < 3 then
        -- runGamePrompt({msg = "3星通过后可扫荡"})
        runGamePrompt({msg = gameConfig.strings:string_common("layer_copy",1)})
        return
    end
    --与海外版有差异，消耗元宝数量计算方法不一样
    if data.kill >= data.config.challenge then
        local cb = function()
            if self.datatype == "brave" then
                if GameScene.vipstatus.b_elitecopy>= gamedata.config.vip[tostring(GameScene.vip.vip)].b_elitecopy then
                    shortVip()
                    return
                end
            end
            if GameScene.roleinfo.gold >= 5*data.config.challenge then
                if self.datatype == "normal" then
                    UIRequest({type = 1305, map = self.data.id, point = data.id})
                else
                    UIRequest({type = 1335, map = self.data.id, point = data.id})
                end
            else
                shortGold()
            end
        end
        local msgext = ""
        if self.datatype == "brave" then
            -- msgext = "您是VIP"..GameScene.vip.vip..",当前重置次数("..GameScene.vipstatus.b_elitecopy.."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].b_elitecopy..")"
            msgext = gameConfig.strings:vipCopy(GameScene.vip.vip,GameScene.vipstatus.b_elitecopy,gamedata.config.vip[tostring(GameScene.vip.vip)].b_elitecopy)
        end
        -- gameWindows:openWindow("confirm",{msg = "挑战次数不足，是否花费"..(5*data.config.challenge).."元宝重置挑战次数？"..msgext},cb)
        gameWindows:openWindow("confirm",{msg = gameConfig.strings:challengeMsg((5*data.config.challenge),msgext)},cb)
        return
    end
    if self.datatype == "normal" then


        local cb = function()
            local tipStr = CCUserDefault:sharedUserDefault():getStringForKey("normal_copychange")
            if tipStr and tipStr ~= "" then
                   UIRequest({type =1307, map = self.data.id, point = data.id, method = method ,exchange = tonumber(tipStr)})
                   setbattlecallbackactive(true)
            end
        end

       
        if GameScene.roleinfo.level >= tonumber(gamedata.config:getConfigByName("global_kv").exp_change.value) then
             local issetting = CCUserDefault:sharedUserDefault():getStringForKey("normal_copychange")
             print("issetting:"..issetting)
             if issetting and issetting ~= "" then
                    UIRequest({type =1307, map = self.data.id, point = data.id, method = method ,exchange = tonumber(issetting)})
                    setbattlecallbackactive(true)           
            else
                CCUserDefault:sharedUserDefault():setStringForKey("normal_copychange", "0")
                gameWindows:openWindow("copyexchange",nil,cb)
             end
        else
              UIRequest({type =1307, map = self.data.id, point = data.id, method = method ,exchange = 0})
              setbattlecallbackactive(true)
        end    

      
        -- CCUserDefault:sharedUserDefault():setStringForKey("tip_"..type, _str)


        -- UIRequest({type =1307, map = self.data.id, point = data.id, method = method ,exchange = 1})
        -- setbattlecallbackactive(true)


    else
        UIRequest({type =1338, map = self.data.id, point = data.id, method = method})
        setbattlecallbackactive(true)
    end
end

function copymap.setPointDetail(self,item,data)

    if self.datatype == "normal" then
        data.config = gamedata.config.copy[tostring(self.data.id)][tostring(data.id)]
    else
        data.config = gamedata.config.brave_copy[tostring(self.data.id)][tostring(data.id)]
    end

    ui.setLabelString(item.challenge,data.config.challenge - data.kill,14)
    ui.setLabelString(item.challengedes,nil,14)
    ui.setLabelString(item.physical,data.config.physical,14)
    ui.setLabelString(item.physicaldes,nil,14)

    -- ui.setLabelString(item.exploretext,"挑战",18)
    ui.setLabelString(item.exploretext,gameConfig.strings:string_common("layer_copy",2),18)
    item.explore:setSwallowsTouch(true)
    item.explore:setTouchPriority(-102)
    item.explore:addHandleOfControlEvent(function()
        --与海外版有差异，消耗元宝数量计算方法不一样
        gameTouch:clickprofbytime(0.5)
        if data.kill >= data.config.challenge then
            --runGamePrompt({msg = "今日挑战次数已用完"})
            local cb = function()

                if self.datatype == "brave" then
                    if GameScene.vipstatus.b_elitecopy>= gamedata.config.vip[tostring(GameScene.vip.vip)].b_elitecopy then
                        shortVip()
                        return
                    end
                end

                if GameScene.roleinfo.gold >= 5*data.config.challenge then
                    if self.datatype == "normal" then
                        UIRequest({type = 1305, map = self.data.id, point = data.id})
                    else
                        UIRequest({type = 1335, map = self.data.id, point = data.id})
                    end
                else
                    shortGold()
                end
            end
            local msgext = ""
            if self.datatype == "brave" then
                -- msgext = "您是VIP"..GameScene.vip.vip..",当前重置次数("..GameScene.vipstatus.b_elitecopy.."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].b_elitecopy..")"
                msgext = gameConfig.strings:vipCopy(GameScene.vip.vip,GameScene.vipstatus.b_elitecopy,gamedata.config.vip[tostring(GameScene.vip.vip)].b_elitecopy)
            end
            -- gameWindows:openWindow("confirm",{msg = "挑战次数不足，是否花费"..(5*data.config.challenge).."元宝重置挑战次数？"..msgext},cb)
            gameWindows:openWindow("confirm",{msg = gameConfig.strings:challengeMsg((5*data.config.challenge),msgext)},cb)
            return
        end

        if self.datatype == "normal" then
            UIRequest({type = 1306, map = self.data.id, point = data.id})
        else
            UIRequest({type = 1337, map = self.data.id, point = data.id})
        end
        setbattlecallbackactive(true)
    end, CCControlEventTouchUpInside)

    item.wipeone:setSwallowsTouch(true)
    item.wipeone:setTouchPriority(-102)
    item.wipeall:setSwallowsTouch(true)
    item.wipeall:setTouchPriority(-102)

    item.exploreeffect:removeAllChildrenWithCleanup(true)
    if data.star <=0 then
        item.wipeonenode:setVisible(false)
        item.wipeallnode:setVisible(false)
        local eccb,eitem = CCBReaderLoad("UIEffect/anniu/anniu_small", nil, true, "anniu_small")
        item.exploreeffect:addChild(eccb)
    else
        item.wipeonenode:setVisible(true)
        item.wipeallnode:setVisible(true)
        -- ui.setLabelString(item.wipealltext,"扫荡"..(data.config.challenge - data.kill).."次",18)
        ui.setLabelString(item.wipealltext,gameConfig.strings:challgNum(data.config.challenge,data.kill),18)
        if data.config.challenge <= data.kill then
            ui.setLabelString(item.wipeonetext,gameConfig.strings:challgNum(data.config.challenge,data.kill),18)
        else
            ui.setLabelString(item.wipeonetext,"扫荡1次",18)
        end
        


        local vipopen = ui.getVipLevelByStr("b_fbsd")
        if GameScene.roleinfo.level<tonumber(gamedata.config.global_kv.copy_wipe_level.value) and vipopen > GameScene.vip.vip then
            ui.addGray("CCControlButton",item.wipeone)
            item.wipeone:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                runGamePrompt({msg = gamedata.config.global_kv.copy_wipe_level.value.."级或VIP"..vipopen.."开启！"})
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",item.wipeone)
            item.wipeone:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                self:wipeFunc(data,0)
            end, CCControlEventTouchUpInside)
        end

        local vipopen10 = ui.getVipLevelByStr("copy_sweep")
        if GameScene.roleinfo.level<tonumber(gamedata.config.global_kv.copy_wipe_level10.value) and vipopen10 > GameScene.vip.vip then
            ui.addGray("CCControlButton",item.wipeall)
            item.wipeall:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                runGamePrompt({msg = "等级不足，"..gamedata.config.global_kv.copy_wipe_level10.value.."级或VIP"..vipopen10.."开启！"})
            end, CCControlEventTouchUpInside)
        else
            ui.removeGray("CCControlButton",item.wipeall)
            item.wipeall:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                self:wipeFunc(data,1)
            end, CCControlEventTouchUpInside)
        end

    end
end


function copymap.createPointList(self)

    local pointListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.selectedPoint and self.selectedPoint == table.getTableLength(self.data.points)-a1 then
                r = CCSizeMake(self.detailCellSize.x, self.detailCellSize.y)
            else
                r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    print("self.unrecycleCell ")
                    return false
                end
            end
            return true
        elseif fn == "cellAtIndex" then
            if self.selectedPoint and self.selectedPoint == table.getTableLength(self.data.points)-a1 then
                local ccb, items,ccb1, items1
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("copy2/cell_point", nil, true, "cell_point")
                    ccb1, items1 =  CCBReaderLoad("copy2/cell_detail", nil, true, "cell_detail")

                    --ccb1:setPosition(self.detailCellSize.x/2, -400)
                    a2:addChild(ccb1)
                    --ccb:setPosition(self.detailCellSize.x/2, -self.normalCellSize.y)
                    a2:addChild(ccb)

                    if guide.controller and guide.controller.isOnGuide then
                    else
                        ui.tableviewAnimation(self.pointListTableView,ccb1,self.detailCellSize.x/2, -400,a1)
                        ui.tableviewAnimation(self.pointListTableView,ccb,self.detailCellSize.x/2, -self.normalCellSize.y,a1)
                    end

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1
                    items1 = self.unrecycleCell.detailCell.items1
                end

                if self.pointListTableView or (guide.controller and guide.controller.isOnGuide) then
                    ccb1:setPosition(self.detailCellSize.x/2, -400)
                    ccb:setPosition(self.detailCellSize.x/2, -self.normalCellSize.y)
                end

                self:setNormalPoint(items,self.data.points[tostring(table.getTableLength(self.data.points)-a1)])
                self:setPointDetail(items1,self.data.points[tostring(table.getTableLength(self.data.points)-a1)])
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("copy2/cell_point", nil, true, "cell_point")
                    self.celldict[a2] = {cell = a2, cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    self.celldict[a2].cell:retain()
                    if guide.controller and guide.controller.isOnGuide then
                    else
                        ui.tableviewAnimation(self.pointListTableView,cellCCB,self.detailCellSize.x/2, -self.normalCellSize.y,a1)
                    end

                else
                    first = false
                    cellCCB = self.celldict[a2].cellCCB
                    ccbDocumentControler = self.celldict[a2].ccbDocumentControler
                end

                self:setNormalPoint(ccbDocumentControler,self.data.points[tostring(table.getTableLength(self.data.points)-a1)])
                if self.pointListTableView or (guide.controller and guide.controller.isOnGuide) then
                    cellCCB:setPosition(self.normalCellSize.x/2, -self.normalCellSize.y)
                end
                if first then
                    a2:addChild(cellCCB)
                end
            end
            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.data.points)
        elseif fn == "cellTouched" then
            local location = self.pointListTableView:getLuaContentOffsetY()
            print(location)
            --if a1:getIdx() ~= 0 then
            local touchIndex = table.getTableLength(self.data.points)-a1:getIdx()

            if self.selectedPoint and self.selectedPoint == touchIndex then
                self.selectedPoint = nil
                location= location + self.detailCellSize.y-self.normalCellSize.y
            elseif self.selectedPoint and self.selectedPoint ~= touchIndex then
                self.selectedPoint =  touchIndex
            elseif not  self.selectedPoint then
                self.selectedPoint = touchIndex
                location= location - self.detailCellSize.y+self.normalCellSize.y
            end
            self.pointListTableView:reloadData()
            if touchIndex == 1 and self.rootItems.pointsScroll:getContentSize().height < (table.getTableLength(self.data.points)*self.normalCellSize.y + (self.selectedPoint and 170 or 0)) then
                location = 0
            elseif self.selectedPoint and location<0 and location < -self.normalCellSize.y*(touchIndex-1) then
                location = -self.normalCellSize.y*(touchIndex-1)
            end
            self.pointListTableView:setLuaContentOffset(0,location)
            --end

        elseif fn == "scrollViewDidScroll" then
            self.isScroll = true --不可点击
        end
        return r
    end)

    self.pointListTableView = ui.createLuaTableView({
        handle = pointListHandle,
        viewwidth = self.rootItems.pointsScroll:getContentSize().width,
        viewheight = self.rootItems.pointsScroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.pointsScroll:addChild(self.pointListTableView)
    self.pointListTableView:setTouchPriority(-101)
end

function copymap.reloaddata(self,param)


    self:setParam(param)

    if not self[self.datatype.."data"] or not next(self[self.datatype.."data"]) then
        UIRequest({type = self.requests[self.datatype]})
        return
    end

    self.copydata = self[self.datatype.."data"]

    if not self.sectionID then self.sectionID = table.getTableLength(self.copydata) end
    if not self.mapID then self.mapID = table.getTableLength(self.copydata[tostring(self.sectionID)].maps) end
    if not self.selectedPoint then self.selectedPoint = table.getTableLength(self.copydata[tostring(self.sectionID)].maps[tostring(self.mapID)].points) end

    self.data = self.copydata[tostring(self.sectionID)].maps[tostring(self.mapID)]

    if self.datatype == "normal" then
        self.data.config = gamedata.config.map[tostring(self.data.id)]
    else
        self.data.config = gamedata.config.brave_map[tostring(self.data.id)]
    end

    ui.setSpriteTextureRect2(self.rootItems.starbar,0,0,280 * math.min(self.data.totalstar,self.data.config.star3) /  self.data.config.star3,36)


    for i=1,3 do
        self.rootItems["awardnode"..i]:setPositionX(-340+700*self.data.config["star"..i]/self.data.config["star3"])

        setSpriteFrameByName(self.rootItems["reward"..i], "box"..(i+1).."_"..(self.data["pa"..i]-1))
        ui.setLabelString(self.rootItems["star"..i], self.data.config["star"..i], 14)
        self.rootItems["effect"..i]:removeAllChildrenWithCleanup(true)
        if self.data["pa"..i] == 2 then
            local ccb, item = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu.ccbi", nil, true, "baoxiangkelingqu")
            self.rootItems["effect"..i]:addChild(ccb)
            local ccb2, item2 = CCBReaderLoad("UIEffect/lizi/baoxiang.ccbi", nil, true, "baoxiang")
            self.rootItems["effect"..i]:addChild(ccb2)
        end
        self.rootItems["r_button"..i]:setSwallowsTouch(true)
        self.rootItems["r_button"..i]:setTouchPriority(-102)
        self.rootItems["r_button"..i]:addHandleOfControlEvent(function()
            if self.data["pa"..i] == 1 then
                gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(self.data.config["award"..i]),type = gameConfig.strings:string_common("layer_copy",3)},nil)
            elseif self.data["pa"..i] == 2 then
                gameTouch:clickprofbytime(0.2)
                UIRequest({type = self.datatype=="normal" and 1304 or 1334, map = self.data.id, method = 3*(i-1)})
            elseif self.data["pa"..i] == 3 then
                gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(self.data.config["award"..i]),type = gameConfig.strings:string_common("layer_copy",4)},nil)
            end
        end, CCControlEventTouchUpInside)
    end

    ui.setLabelString(self.rootItems.name,gameConfig.strings:lvNum(self.mapID,self.data.config.name),18)
    ui.setLabelString(self.rootItems.chaptername,self.copydata[tostring(self.sectionID)].name,21)

    if not self.pointListTableView then
        self:createPointList()
    else
        self.pointListTableView:reloadData()
    end

    local location =  self.pointListTableView:getLuaContentOffsetY()
    if (self.selectedPoint)*230+170 > self.rootItems.pointsScroll:getContentSize().height then
        self.pointListTableView:setLuaContentOffset(0, self.rootItems.pointsScroll:getContentSize().height-(self.selectedPoint)*230-170)
    elseif (table.getTableLength(self.data.points))*230+170 < self.rootItems.pointsScroll:getContentSize().height then
        self.pointListTableView:setLuaContentOffset(0, self.rootItems.pointsScroll:getContentSize().height-(table.getTableLength(self.data.points))*230-170)
    else
        self.pointListTableView:setLuaContentOffset(0, 0)
    end
    if location ~= self.pointListTableView:getLuaContentOffsetY() then
        self.pointListTableView:reloadData()
    end
end

function copymap.reloadnormalData(self,data,param)
    self.datatype = self.datatype or "normal"
    if data then
        self.normaldata = data
    end
    self:reloaddata(param)
end

function copymap.reloadbraveData(self,data,param)
    self.datatype = self.datatype or "brave"
    if data then
        self.bravedata = data
    end
    self:reloaddata(param)
end

function copymap.UIUpdateData(self,isreset)
    if isreset then
        self:reloaddata()
    end
end

return copymap
