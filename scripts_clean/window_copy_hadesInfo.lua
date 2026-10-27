--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/2/25
-- Time: 13:45
-- To change this template use File | Settings | File Templates.
--

local copyhadesInfo = {
    rootNode = nil,
    rootItems = nil,
    data = {},
    generalListTableView = nil,
    generaldata = {},

    showid = 1,
}

function copyhadesInfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("copydiyu/copydiyu_info", nil, true, "copydiyu_info")

    self.touchPriority = touchPriority
    self.callback = callback
    self.data = data

    if  self.rootItems.leftbutton then
        self.rootItems.leftbutton:addHandleOfControlEvent(function()
            if self.generalListTableView then
                if self.generalListTableView:getLuaContentOffsetX()+200 > 0 then
                    self.generalListTableView:setLuaContentOffset(0 , 0)
                else
                    self.generalListTableView:setLuaContentOffset(self.generalListTableView:getLuaContentOffsetX()+200 , 0)   
                end
            end    
        end, CCControlEventTouchUpInside)
        self.rootItems.leftbutton:setSwallowsTouch(true)
        self.rootItems.leftbutton:setTouchPriority(self.touchPriority)
    end

    if  self.rootItems.rightbutton then
        self.rootItems.rightbutton:addHandleOfControlEvent(function()
            if self.generalListTableView then
                if (self.generalListTableView:getLuaContentOffsetX()-200) < (800-table.getTableLength(self.generaldata)*200) then
                    self.generalListTableView:setLuaContentOffset(800-table.getTableLength(self.generaldata)*200  , 0)
                else
                    self.generalListTableView:setLuaContentOffset(self.generalListTableView:getLuaContentOffsetX()-200 , 0)    
                end
            end    
        end, CCControlEventTouchUpInside)
        self.rootItems.rightbutton:setSwallowsTouch(true)
        self.rootItems.rightbutton:setTouchPriority(self.touchPriority)
    end

    if  self.rootItems.closeButton then
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindowDirect("copyhadesInfo")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    end

    --
    self.rootItems.container:setContentSize(CCSize(880,500))
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    -- self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    self.yuanNode, self.yuanItems = CCBReaderLoad("copydiyu/copydiyu_tupoinfo", nil, true, "copydiyu_tupoinfo")
    self.yuanNode:setPosition(440,500)
    self.rootItems.container:addChild(self.yuanNode)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    ui.setLabelString(self.yuanItems.skilltitle,nil,14)

    --self:reload()
    addDelayUpdateFunc(function()
        self:reload()
    end,"copyhadesInforeload")





    return self.rootNode,true
end

function copyhadesInfo.reload(self,data)
    if data then
        self.data = data
    end

    --
    self.config = gamedata.config.hades_copy[tostring(self.data.mapid)][tostring(self.data.pointid)]

    if  self.rootItems.battleButton then
        ui.setLabelString(self.rootItems.battleLab,nil,19)
        self.rootItems.battleButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            -- if self.data.pointstatus >= self.config[tostring(self.data.pointid)].challenge then
            --     runGamePrompt({msg = "本关卡今日次数已用完"})
            -- else
                UIRequest({type = 1371, mapid = self.data.mapid, pointid = self.data.pointid, pointstatus = self.data.pointstatus})
                --gameWindows:closeWindowDirect("copyhadesInfo")
                self:closedelay()
            --end
        end, CCControlEventTouchUpInside)
        self.rootItems.battleButton:setSwallowsTouch(true)
        self.rootItems.battleButton:setTouchPriority(self.touchPriority)
    end
    --
    self.generaldata = {}
    for i = 1,20 do
        if self.config["p"..i] and self.config["p"..i] > 0 and gamedata.config.copy_monster[tostring(self.config["p"..i])] then
            table.insert(self.generaldata,{cid = gamedata.config.copy_monster[tostring(self.config["p"..i])].generalid, breaklevel = self.config["break"..i.."-correct"] })
        end    
    end    

    self:setPage()

    local config = gamedata.config.hades_copy[tostring(self.data.mapid)][tostring(self.data.pointid)]
    local rewards = ui.getIDandNUMs(config.reward)
    self:hadesCopyRewardList(rewards)
end

function copyhadesInfo.closedelay(self)
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        gameWindows:closeWindowDirect("copyhadesInfo")
    end))
    self.rootItems.generalNode:runAction(sequence)
end

function copyhadesInfo.close(self)
    self.generaldata = {}
    self.data = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.generalListTableView = nil
    self.showid = 1

    if self.callback then
        self.callback()
    end
end

function copyhadesInfo.reloadGeneralList(self,alldata)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(200,200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("copydiyu/diyuicon.ccbi", nil, true, "generalIcon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setScale(1)
            ccbDocumentControler.i_selectEffect:removeAllChildrenWithCleanup(true)

            --ui.setNewIcon(ccbDocumentControler,self.generaldata[a1+1])
            setSpriteFrameByName(ccbDocumentControler["i_icon"], ui.IDconfig(self.generaldata[a1+1].cid).icon and ui.IDconfig(self.generaldata[a1+1].cid).icon or "alpha")
            ui.setSpriteTextureRect(ccbDocumentControler["i_icon"],0,0,150,150)

            if self.showid == a1+1 then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                eccb:setScale(1.1)
                ccbDocumentControler.i_selectEffect:addChild(eccb)
            end

            cellCCB:setPosition(100,100)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.generaldata)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            self.showid = a1:getIdx()+1
            self:setPage()

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.generalListScroll:getContentSize().width,
        viewheight = self.rootItems.generalListScroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.generalListScroll:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(self.touchPriority)
end

function copyhadesInfo.setPage(self)

    if not self.generalListTableView then
        self:reloadGeneralList()
    else
        self.generalListTableView:reloadData()
    end

    --
    local breakskill = {}
    local breaklevel = self.generaldata[self.showid] and self.generaldata[self.showid].breaklevel or 0
    local generalcid = self.generaldata[self.showid] and self.generaldata[self.showid].cid or 0
    local generalconfig = gamedata.config.general[tostring(generalcid)] or {} 
    for i = 1,breaklevel do
        if generalconfig["break"..i] and generalconfig["break"..i] > 0 then
            table.insert(breakskill,generalconfig["break"..i])
        end    
    end
    --
    for i = 1,12 do
        if self.yuanItems["skill"..i] and self.yuanItems["skilldesc"..i] then
            if breakskill[i] and breakskill[i] > 0 and gamedata.config.breakskill[tostring(breakskill[i])] then
                ui.setLabelString(self.yuanItems["skill"..i],gamedata.config.breakskill[tostring(breakskill[i])].name.."：",13)
                ui.setLabelString(self.yuanItems["skilldesc"..i],gamedata.config.breakskill[tostring(breakskill[i])].desc,2)
            else
                ui.setLabelString(self.yuanItems["skill"..i],"",13)
                ui.setLabelString(self.yuanItems["skilldesc"..i],"",2)
            end
        end
    end 
    --
    if #breakskill > 4 then
        local fixh = (#breakskill-4)*120+500
        self.rootItems.container:setContentSize(CCSize(880,fixh))
        self.yuanNode:setPosition(440,fixh)
        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,500-fixh),0)
        self.rootItems.ismore:setVisible(true)
    else
        self.rootItems.container:setContentSize(CCSize(880,500))
        self.yuanNode:setPosition(440,500)
        self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
        self.rootItems.ismore:setVisible(false)
    end

end

function copyhadesInfo.hadesCopyRewardList(self,rewards)
    self.rootItems.rewardList:removeAllChildrenWithCleanup(true)

    local celldict = {}

    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(150, 200)
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

            ui.setNewIcon(ccbDocumentControler, rewards[a1+1])
            ccbDocumentControler["i_button"]:setTouchPriority(-103)
            ccbDocumentControler["i_button"]:addHandleOfControlEvent(function()
                if gameTouch.isScrollling then return end
                ui.setPopwindowByCid(rewards[a1+1].cid)
            end, CCControlEventTouchUpInside)

            cellCCB:setScale(0.8)
            cellCCB:setPosition(150/2, 200/2)

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then 
            r = table.getTableLength(rewards)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    local rewardList = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.rewardList:getContentSize().width,
        viewheight = self.rootItems.rewardList:getContentSize().height,
        dire = 0
    })
    self.rootItems.rewardList:addChild(rewardList)
    rewardList:setTouchPriority(self.touchPriority)

end

return copyhadesInfo
