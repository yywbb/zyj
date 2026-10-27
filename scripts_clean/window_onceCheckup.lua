

local onceCheckup = {
    rootNode = nil,
    rootItems = nil,
    cellsize = {x = 960, y= 220},
    listview = nil,
    selectList = {},
    data = {},
    isSelectState1 = false,
    isSelectState3 = false,
    curNum1 = 0,
    curNum2 = 0,
    maxCheckNum = 10,
}

function onceCheckup.checkProp( self )
    if self.isSelectState1 and self.curNum1 <=0 then
        shortPropById(self.afterCheckId)
        return false
    elseif not self.isSelectState1 and self.curNum2 <=0 then
        shortPropById(self.beforeCheckId)
        return false
    end    
    return true
end

function onceCheckup.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_yijianjianding", nil, true, "tc_yijiandazao")
    self.touchPriority = touchPriority

    self.rootItems.autosprite1:setVisible(self.isSelectState1);
    self.rootItems.autosprite2:setVisible(not self.isSelectState2);
    self.rootItems.autosprite3:setVisible(self.isSelectState3);
    ui.addGray("CCControlButton",self.rootItems.yesButton)
    self.rootItems.autobutton1:addHandleOfControlEvent(function()
        if self.isSelectState1 == false then
            self.isSelectState1 = not self.isSelectState1
            self.rootItems.autosprite1:setVisible(self.isSelectState1);
            self.rootItems.autosprite2:setVisible(not self.isSelectState1);
            self.isSelectState3 = false
            self.rootItems.autosprite3:setVisible(self.isSelectState3);
            self.selectList ={}
            self.listview:reloadData()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton1:setSwallowsTouch(true)
    self.rootItems.autobutton1:setTouchPriority(self.touchPriority)

    self.rootItems.autobutton2:addHandleOfControlEvent(function()
        if self.isSelectState1 == true then
            self.rootItems.autosprite2:setVisible(self.isSelectState1);
            self.rootItems.autosprite1:setVisible(not self.isSelectState1);
            self.isSelectState1 = not self.isSelectState1
            self.isSelectState3 = false
            self.rootItems.autosprite3:setVisible(self.isSelectState3);
            self.selectList ={}
            self.listview:reloadData()
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton2:setSwallowsTouch(true)
    self.rootItems.autobutton2:setTouchPriority(self.touchPriority)

    self.rootItems.autobutton3:addHandleOfControlEvent(function()

        if not self:checkProp() then return end 

        self.isSelectState3 = not self.isSelectState3
        self.rootItems.autosprite3:setVisible(self.isSelectState3);
        if self.isSelectState3 == true then
            -- for i,v in ipairs(self.artifacts) do
            --     self:addSelectList(v,true)
            -- end
            for i=1,self.maxCheckNum do
                local v = self.artifacts[i]
                if v then
                   self:addSelectList(v,true) 
                end
            end
            self.listview:reloadData()
        else
            self.selectList ={}
            self.listview:reloadData()
        end
        local len = table.getTableLength(self.selectList)
        if len > 0 then
            ui.removeGray("CCControlButton",self.rootItems.yesButton)
        else
            ui.addGray("CCControlButton",self.rootItems.yesButton)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton3:setSwallowsTouch(true)
    self.rootItems.autobutton3:setTouchPriority(self.touchPriority)

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("onceCheckup")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.noLab,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("onceCheckup")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.yesLab,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        local curID = self.afterCheckId
        if self.isSelectState1 == false then
            curID = self.beforeCheckId
        end
        -- printT(self.selectList,"  self.selectList  ")
        -- for i=1,#self.selectList do
        --     printT(self.selectList[i],"==== ------ - - - -  -")
        -- end
        local len = #self.selectList
        if len > 0 then
            UIRequest({type = 5516,curList = self.selectList,itemID = curID})
            gameWindows:closeWindowDirect("onceCheckup")
        else
            runGamePrompt({msg = "请选择要鉴定的神器"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority)

   if not self.beforeCheckId then
        self:setCheckId()
    end
    self:reloadData(data);
    return self.rootNode;
end



function onceCheckup.reloadData( self,data)
    print(" onceCheckup.reloadListData ");
    self.artifacts = data.artifacts
    -- printT(data)
    UIRequest({type = 12001, order = 33013, cids = {self.beforeCheckId,self.afterCheckId}})
    if not self.listview  then
        self:createList()
    else
        self.listview:reloadData()
    end
end

function onceCheckup.createList(self)
    print("createRankList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellsize.x, self.cellsize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_yijianjianding", nil, true, "cell_yijianjianding")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setSell(ccbDocumentControler,self.artifacts[a1+1])
            cellCCB:setPosition(self.cellsize.x/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.artifacts)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end


function onceCheckup.setSell(self,item,data)
    -- body
    -- printT(data,"onceCheckup.setSell")
    ui.setNewIcon(item,{cid = data.cid},0)
    local artifactConfig = gamedata.config.trump[tostring(data.cid)] 
    -- if data.level1 == 0 then
    --     item.name:setString(artifactConfig.name)
    -- else
    --     item.name:setString(artifactConfig.name.."+"..data.level1)
    -- end

    local nameStr = artifactConfig.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..artifactConfig.name or artifactConfig.name

    if data.level1 > 0 then
        nameStr = nameStr.."+"..data.level1
    end
    ui.setLabelString(item.name,nameStr,9)
    
    -- item.playerName:setString("玩家"..data.name.."强化打造")

    local playerStr = artifactConfig.goldTrump > 0 and data.name..gameConfig.strings:string_common("artifact",35) or data.name..gameConfig.strings:string_common("artifact",36)
    item.playerName:setString(playerStr)
    
    local isState = self:setisSelected(data);
    item.autosprite:setVisible(isState);
    item.autobutton:addHandleOfControlEvent(function()
        if not self:checkProp() then return end 
        printT(self.selectList," 选择列表-===== ")
        local isState = self:addSelectList(data,false);
        item.autosprite:setVisible(not isState);
        printT(self.selectList," 选择列表-===22222== ")
        local len = table.getTableLength(self.selectList)
        if len > 0 then
            ui.removeGray("CCControlButton",self.rootItems.yesButton)
        else
            ui.addGray("CCControlButton",self.rootItems.yesButton)
        end
    end, CCControlEventTouchUpInside)
    item.autobutton:setSwallowsTouch(true)
    item.autobutton:setTouchPriority(self.touchPriority)
end

function onceCheckup.setisSelected(self,artifactsData)
    local len = table.getTableLength(self.selectList)
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
function onceCheckup.addSelectList(self,artifactsData,isAll)
    -- body
    local len = table.getTableLength(self.selectList)
    if len == 0 then
        if self.isSelectState1 == false then
            if self.curNum2 > len and self.curNum2 > 0 then
                table.insert(self.selectList,artifactsData)
                return false
            else
                print("鉴定符数量不足")
                return true
            end
        else
            if self.curNum1 > len and self.curNum1 > 0 then
                table.insert(self.selectList,artifactsData)
                return false
            else
                print("鉴定符数量不足")
                return true
            end
        end
    end


    for i,v in ipairs(self.selectList) do
        if artifactsData.iid == v.iid then
            if isAll == false then
                table.remove(self.selectList,i)
            end
            return true
        end
    end


    if table.getTableLength(self.selectList) >= self.maxCheckNum then
        runGamePrompt({msg = "超过最大可选数量！"})
        return true
    end

    if self.isSelectState1 == false then
        if self.curNum2 > len and self.curNum2 > 0 then
            table.insert(self.selectList,artifactsData)
            return false
        else
            print("鉴定符数量不足")
            return true
        end
    else
        if self.curNum1 > len and self.curNum1 > 0 then
            table.insert(self.selectList,artifactsData)
            return false
        else
            print("鉴定符数量不足")
            return true
        end
    end
    
end


function onceCheckup.setCheckId(self)
    local configs = gamedata.config.trump_autweight
    local ids = {}
    for k,v in pairs(configs) do
        ids[#ids + 1] = v.itemID
    end
    self.beforeCheckId = ids[1] < ids[2] and ids[1] or ids[2]
    self.afterCheckId = ids[1] < ids[2] and ids[2] or ids[1]
end


function onceCheckup.checkPropNums(self,data)
    printT(t," onceCheckup.checkPropNums ")
    self.curNum1 = data[tostring(self.afterCheckId)]
    self.curNum2 = data[tostring(self.beforeCheckId)]
    self.rootItems.itemNum1:setString(self.curNum1)
    self.rootItems.itemNum2:setString(self.curNum2)
end

-- 发送
function onceCheckup.onSendArtifactMessage(self )
    -- body 打造神器的数量
    -- self.usenum
end


function onceCheckup.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.selectList = {}
    self.listview = nil
    self.isSelectState3 = false
    self.isSelectState1 = false
    self.curNum1 = 0
    self.curNum2 = 0
    -- self.callback = nil
end

return onceCheckup