-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/24
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.


local onceAddStrengthen = {

    rootNode = nil,
    rootItems = nil,
    cellNorSize = {x=980,y=220},
    cellDelSSize = {x = 980,y = 860},
    cellDelSTwoSize = {x = 980,y = 950},
    cellDelSize = {x = 980,y = 860},

    unrecycleCell = {},
    
    artifactSelect = nil,
    isSelectState = false,
    isSelectState1 = false,
    ListTableView = nil,
    selectList ={},
    data = {},
    callBack = nil,
    artifactNum = 0,
    isstreng = nil,
}

function onceAddStrengthen.open(self,touchPriority,data,callback)

    printT(data,"onceAddStrengthen")
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_yijianup", nil, true, "tc_yijiandazao")
    self.touchPriority = touchPriority
    self.callBack = callback;
    self.rootItems.autosprite1:setVisible(self.isSelectState1);

    self.rootItems.autobutton1:addHandleOfControlEvent(function()
        self.isSelectState1 = not self.isSelectState1
        self.rootItems.autosprite1:setVisible(self.isSelectState1);
        if self.isSelectState1 == true then
            -- for i,v in ipairs(self.artifacts) do
            --     self:addSelectList(v,true)
            -- end
            for i=1,self.artifactNum do
                if self.artifacts[i] and self.artifacts[i].consumeStatus == 0 then
                    self:addSelectList(self.artifacts[i],true)
                end
            end
            self.ListTableView:reloadData()
        else
            self.selectList ={}
            self.ListTableView:reloadData()
        end
        self.rootItems.itemCount:setString(table.getTableLength(self.selectList)..'/'..self.artifactNum)
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton1:setSwallowsTouch(true)
    self.rootItems.autobutton1:setTouchPriority(self.touchPriority-11)

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("onceAddStrengthen")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.noLab,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("onceAddStrengthen")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority-2)

    ui.setLabelString(self.rootItems.yesLab,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.callBack then
            self.callBack(self.selectList);
            gameWindows:closeWindow("onceAddStrengthen")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority-2)
    self:reloadData(table.copy(data));
    self.rootItems.title:setString(gameConfig.strings:string_common("artifact",19));

    return self.rootNode;
end

function onceAddStrengthen.lockCallback(self,t)
    --神器加锁数据 无需重新排序
    for i,v in ipairs(self.artifacts) do
        if v.iid == t.artifactSid then
            v.isLockState = t.isLock
            break
        end
    end
    self.ListTableView:reloadData()
end

function onceAddStrengthen.reloadData( self,data)
    print(" onceAddStrengthen.reloadListData ");
    printT(data)
    self.artifacts = data.data or {}

    self.selectList = data.selectList or {}
    self.isstreng = data.isstreng or nil
    printT(self.artifacts)
    local len = table.getTableLength(data.selectList)
    self.artifactNum = data.num
    self.rootItems.itemCount:setString(len.."/"..tostring(self.artifactNum))

     if not self.ListTableView then
        self:createArtifactList()
    else
        local addLength = self.cellNorSize.y
        if self.artifactSelect then
            local artifact = self.artifacts
            local curHeight = self.cellDelSize.y
            if artifact.skill1 > 0 then
                curHeight = self.cellDelSize.y
            end
            if artifact.skill2 > 0 then
                curHeight = self.cellDelSTwoSize.y
            end
            if artifact.skill3 > 0 then
                curHeight = self.cellDelSSize.y
            end
            addLength = curHeight
        end
        self.ListTableView:setLuaContentOffset(0, self.rootItems.listArtifact:getContentSize().height - (#self.artifacts - 1) *self.cellNorSize.y - addLength)
        self.ListTableView:reloadData()
    end

end

function onceAddStrengthen.createArtifactList(self)
    print("createRankList")

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then
                local artifact = self.artifacts[a1 + 1]
                local curHeight = self.cellDelSize.y
                if artifact.skill1 > 0 then
                    curHeight = self.cellDelSize.y
                end
                if artifact.skill2 > 0 then
                    curHeight = self.cellDelSTwoSize.y
                end
                if artifact.skill3 > 0 then
                    curHeight = self.cellDelSSize.y
                end
                r = CCSizeMake(self.cellNorSize.x, curHeight)
            else
                r = CCSizeMake(self.cellNorSize.x, self.cellNorSize.y)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    print("unrecycleCELL ")
                    return false
                end
            end
            return true
        elseif fn == "cellAtIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then

                local ccb, items,ccb1, items1
                local artifact = self.artifacts[a1 + 1]
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("shenqi_new/cell_shenqichongzhu", nil, true, "cell_shenqichongzhu")
                    ccb1, items1 =  CCBReaderLoad("shenqi_new/cell_shenqiselect_content", nil, true, "cell_shenqiselect_content")
                    items1.touchBtn:addHandleOfControlEvent(function()
                        
                    end, CCControlEventTouchUpInside)
                    items1.touchBtn:setSwallowsTouch(true)
                    items1.touchBtn:setTouchPriority(self.touchPriority - 2)

                    local scrollnode = tolua.cast(items1.scrollnode, "CCScrollView")
                    scrollnode:setTouchPriority(self.touchPriority - 3)

                    
                    gameWindows.windows["artifactSelect"].module:initCellDetalFixedString(items1)
                    
                    local curHeight = self.cellDelSize.y
                    if artifact.skill1 > 0 then
                        curHeight = self.cellDelSize.y
                    end
                    if artifact.skill2 > 0 then
                        curHeight = self.cellDelSTwoSize.y
                    end
                    if artifact.skill3 > 0 then
                        curHeight = self.cellDelSSize.y
                    end
                    ccb1:setPosition(self.cellNorSize.x/2, -curHeight)

                    -- ccb1:setScale(1.1)
                    a2:addChild(ccb1)
                    ccb:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                    -- ccb:setScale(1.1)
                    a2:addChild(ccb)

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1

                    local curHeight = self.cellDelSize.y
                    if artifact.skill1 > 0 then
                        curHeight = self.cellDelSize.y
                    end
                    if artifact.skill2 > 0 then
                        curHeight = self.cellDelSTwoSize.y
                    end
                    if artifact.skill3 > 0 then
                        curHeight = self.cellDelSSize.y
                    end
                    ccb1:setPosition(self.cellNorSize.x/2, -curHeight)

                    items1 = self.unrecycleCell.detailCell.items1
                end
                local state = self:setIsSelected(artifact)
                items.autosprite:setVisible(state)
                -- print("state 1111   ",state)
                items.selectBtn:addHandleOfControlEvent(function()
                    
                    if artifact.isLockState == 1 then
                        runGamePrompt({msg = "当前神器已锁定"})
                        return
                    end
                    
                    local curState = self:addSelectList(artifact,false)
                    items.autosprite:setVisible(not curState)
                    local len = table.getTableLength(self.selectList)
                    self.rootItems.itemCount:setString(len..'/'..self.artifactNum)

                    -- local len = table.getTableLength(self.selectList)
                    -- if len < self.artifactNum then
                    --     state = not state
                    --     items.autosprite:setVisible(state)
                    -- end
                    -- self:addSelectList(artifact,false)
                    -- self.rootItems.itemCount:setString(len..'/'..self.artifactNum)
                end, CCControlEventTouchUpInside)
                items.selectBtn:setSwallowsTouch(true)
                items.selectBtn:setTouchPriority(self.touchPriority - 1)

                gameWindows.windows["artifactSelect"].module.setNormal(self,items,self.artifacts[a1 + 1],function(data)
                    if data.isChecked > 0 then
                        GameScene:shiftLayer("artifactMount","up",{artifact = data})
                    else
                        GameScene:shiftLayer("artifactCheck","up",data)
                    end
                end,true,a1 + 1,#self.artifacts,self.rootItems.listArtifact,true,true,self.isstreng)


                gameWindows.windows["artifactSelect"].module.setDetail(self,items1,self.artifacts[a1+1],true,false)

            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shenqichongzhu", nil, true, "cell_shenqichongzhu")
                    -- cellCCB:setScale(1.1)
                    gameWindows.windows["artifactSelect"].module:initCellFixedString(ccbDocumentControler)
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    ui.tableviewAnimation(self.ListTableView,cellCCB,self.cellNorSize.x/2,-self.cellNorSize.y,a1)

                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end

                 gameWindows.windows["artifactSelect"].module.setNormal(self,ccbDocumentControler,self.artifacts[a1+1],function(data)
                    -- if data.isChecked > 0 then
                    --     GameScene:shiftLayer("artifactMount","up",{artifact = data,})
                    -- else
                    --     GameScene:shiftLayer("artifactCheck","up",data)
                    -- end
                end,false,a1 + 1,#self.artifacts,self.rootItems.listArtifact,true,true,self.isstreng)
                
                if first then
                    a2:addChild(cellCCB)
                else
                    cellCCB:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                end
                local artifact = self.artifacts[a1 + 1]
                local state = self:setIsSelected(artifact)
                ccbDocumentControler.autosprite:setVisible(state)
                ccbDocumentControler.selectBtn:addHandleOfControlEvent(function()
                    
                    if artifact.isLockState == 1 then
                        runGamePrompt({msg = "当前神器已锁定"})
                        return
                    end

                    local curState = self:addSelectList(artifact,false)
                    print('  curState  ',curState)
                    ccbDocumentControler.autosprite:setVisible(not curState)
                    local len = table.getTableLength(self.selectList)
                    self.rootItems.itemCount:setString(len..'/'..self.artifactNum)

                end, CCControlEventTouchUpInside)
                ccbDocumentControler.selectBtn:setSwallowsTouch(true)
                ccbDocumentControler.selectBtn:setTouchPriority(self.touchPriority - 1)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.artifacts)
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listArtifact:getContentSize().width,
        viewheight = self.rootItems.listArtifact:getContentSize().height,
        dire = 1
    })
    self.rootItems.listArtifact:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)

end

function onceAddStrengthen.setIsSelected(self,artifactsData)
    local len = table.getTableLength(self.selectList)
    -- print(' -----11-1-1-1-1',len)
    if len == 0 then
        return false
    end
    for i,v in ipairs(self.selectList) do
        if artifactsData.iid == v.iid then
            return true
        end
    end
    return false
end

-- 添加选择数据
function onceAddStrengthen.addSelectList(self,artifactsData,isAll)
    -- body
    local len = table.getTableLength(self.selectList)
    if len == 0 then
        table.insert(self.selectList,artifactsData)
        return false
    end
    print("len   ",len," self.artifactNum ",self.artifactNum)
    for i,v in ipairs(self.selectList) do
        if artifactsData.iid == v.iid then
            if isAll == false then
                table.remove(self.selectList,i)
            end
            return true
        end
    end

    if len + 1 > self.artifactNum then
        runGamePrompt({msg = "当前添加神器已达上限"})
        return true
    end

    table.insert(self.selectList,artifactsData)
    return false
end


function onceAddStrengthen.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.selectList = {}
    self.ListTableView = nil
    self.callBack = nil
    self.artifacts = nil
    self.isSelectState1 = false

    self.artifactSelect = nil
    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}
    self.isSelectState1 = false
    self.isstreng  = nil
end

return onceAddStrengthen   Q?  