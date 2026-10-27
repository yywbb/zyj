--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local godcompetition_battleRecord = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    ListTableView = nil,
    nowPage = 1, --当前页数
    beforePage = 0, --之前页数
    maxPage = 1, --最大页数
    normalCellSize = {x =940,y=185},
    titleCellSize = {x=180*0.59,y=180*0.59},

}

function godcompetition_battleRecord.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority


    self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_tiaozhanjilu.ccbi", nil, true, "tc_tiaozhanjilu")
    gameTouch:clickprofbytime(0.5)
    UIRequest({type = 8260})
   
    self.rootItems.closeBtn:addHandleOfControlEvent(function()

        gameWindows:closeWindow("godcompetition_battleRecord")

    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority-1)
       

    self.rootItems.beforeBtn:addHandleOfControlEvent(function()
        self:shiftPage(false)
    end, CCControlEventTouchUpInside)
    self.rootItems.beforeBtn:setSwallowsTouch(true)
    self.rootItems.beforeBtn:setTouchPriority(self.touchPriority-1)

    self.rootItems.nextBtn:addHandleOfControlEvent(function()
         self:shiftPage(true)
    end, CCControlEventTouchUpInside)
    self.rootItems.nextBtn:setSwallowsTouch(true)
    self.rootItems.nextBtn:setTouchPriority(self.touchPriority-1)
    
    self.root:addChild(self.rootNode)
    
    return self.root
end


function godcompetition_battleRecord.reloadData(self,data)
    self.data = data.battleInfo or {}
    local length = table.getTableLength(self.data)
    self.maxPage = math.floor( length / 2 )
    if math.modf( length / 2 ) == 1 then
        self.maxPage  =  self.maxPage +1
    end    
    -- local sortFunc = function( a, b )
    --     if a["timetemp"] >= b["timetemp"] then
    --         return true
    --     else 
    --         return false
    --     end    
    -- end    
    -- table.sort(self.data,sortFunc)
    -- printT(self.data,"reloadData")
    self:showPageByIndex(1)
    self.rootItems.nowPageLabel:setString(self.nowPage)
end


function godcompetition_battleRecord.shiftPage(self,isadd)
    print(self.nowPage,self.maxPage,"shiftPage")
   if isadd then --向后翻页
        if self.nowPage < self.maxPage then
            self.nowPage = self.nowPage+1
        else    
            runGamePrompt({msg="当前已经是最后一页了"})
        end  
   else --向前翻页
        if self.nowPage > 1 then
            self.nowPage = self.nowPage-1
        else
            runGamePrompt({msg="当前已经是第一页了"})
        end  
   end 
   
   self:showPageByIndex(self.nowPage)
   self.rootItems.nowPageLabel:setString(self.nowPage)
end    

function godcompetition_battleRecord.showPageByIndex(self,page)
    if self.beforePage == page then return end
    for i=1,2 do
        local _index = i+(page-1)*2
        print(_index,"showPageByIndex")
        if self.data and self.data[tostring(_index)] then
            self.rootItems["pageNode"..i]:setVisible(true)  
            local  _slotdata =  self.data[tostring(_index)]
              -- -- boss
            local boss = gamedata.config.apex_boss[tostring(_slotdata.bossid)] 
            if boss then
                self.rootItems["bossName"..i]:setString(boss.name)
            end    
            local time =  ui.getDateByTime(_slotdata.timetemp or 0)
            self.rootItems["bossTime"..i]:setString(time)
            
            local celldict = {}
            local ListHandle1 = LuaEventHandler:create(function(fn, myTable, a1, a2)
                local r
                if fn == "cellSize" then
                    r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
                elseif fn == "cellAtIndex" then
                    local cellCCB,ccbDocumentControler = 0,0
                    local first = true
                    if not a2 then
                        a2 = CCTableViewCell:create()
                        cellCCB, ccbDocumentControler = CCBReaderLoad("fengshensai/cell_tiaozhanjilu", nil, true, "cell_tiaozhanjilu")
                        celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    else
                        first = false
                        cellCCB = celldict[a2].cellCCB
                        ccbDocumentControler = celldict[a2].ccbDocumentControler
                    end

                    local _celldata = _slotdata.slotinfo[tostring(a1+1)] or {}
                    self:initCellData(ccbDocumentControler,a1+1,_celldata)
                    
                    cellCCB:setPosition(self.normalCellSize.x/2, 5)         
                    if first then
                        a2:addChild(cellCCB)
                    end
                    r = a2
                elseif fn == "numberOfCells" then
                    print("showPageByIndex 2")

                   r = 3
                elseif fn == "cellTouched" then

                elseif fn == "scrollViewDidScroll" then
                end
                return r
            end)

            self.ListTableView1 = ui.createLuaTableView({
                handle = ListHandle1,
                viewwidth = self.rootItems["listnode"..i]:getContentSize().width,
                viewheight = self.rootItems["listnode"..i]:getContentSize().height,
                dire = 1
            })
            self.rootItems["listnode"..i]:removeAllChildrenWithCleanup(true)
            self.rootItems["listnode"..i]:addChild(self.ListTableView1)

        else
            self.rootItems["pageNode"..i]:setVisible(false)  
        end    

    end    

    self.beforePage =  page

end    



function godcompetition_battleRecord.initCellData(self, item,index,data)

    print("initCellData"..index)
    printT(data,"data")

    item.slotsNum:setString("阵容"..data.slotsid)
    item.hurtNum:setString(data.hurtNum or 0)
    item.hurtTitle:setString("伤害")

    local celldict = {}
    local itemListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                -- slotsInfo/generalIcon
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon", nil, true, "new_icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2+5)
            cellCCB:setScale(0.59)

            --幻化
            if ccbDocumentControler["phantomNode"] then
                ccbDocumentControler["phantomNode"]:removeAllChildrenWithCleanup(true)
            end    

            if a1+1 == 8 then --魔宠
                local petid =  data.petid or 0
                ui.setNewIcon(ccbDocumentControler, {cid = petid}, 0)
            else--武将
                local generalid =  data["slot"..(a1+1)] or 0
                local llusionID =  data["llusion"..(a1+1)] or 0
                local isllusion = false
                if llusionID > 0 then
                    isllusion = true
                    generalid = llusionID
                end    
                local configGeneral = gamedata.config.general[tostring(generalid)]
                ui.setNewIcon(ccbDocumentControler, {cid = generalid}, 0)
             
                if isllusion then
                    if ccbDocumentControler["phantomNode"] then
                        ui.createPhantomIcon(ccbDocumentControler["phantomNode"])
                        ccbDocumentControler["phantomNode"]:setVisible(true)
                    end
                end    
            end     
            if first then
                a2:addChild(cellCCB)
            end    
            r = a2

        elseif fn == "numberOfCells" then
            r =  8
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    local itemListTableView = ui.createLuaTableView({
        handle = itemListHandle,
        viewwidth =  item.generalIconList:getContentSize().width,
        viewheight =  item.generalIconList:getContentSize().height,
        dire = 0
    })
    item.generalIconList:removeAllChildrenWithCleanup(true)
    item.generalIconList:addChild(itemListTableView)
    itemListTableView:setTouchPriority(self.touchPriority-3)
end



function godcompetition_battleRecord.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.beforePage = 0
    self.nowPage = 1
    self.maxPage = 0
    self.data = {}
end

return godcompetition_battleRecord�$  