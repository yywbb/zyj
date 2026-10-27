--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 21/4/4
-- Time: 下午08:20
-- To change this template use File | Settings | File Templates.
--

local exclusiveArtifactQiLingCopy = {
    rootNode = nil,
    rootItems = nil,
    cellSize = {width = 900,height = 230},

    data = {},
    configData = {},
    cellNum = 0,

    isscrolltouched = false,
    listTableView = nil,
}

function exclusiveArtifactQiLingCopy.open(self,touchPriority,data,callback)

    printT(data,"jkp-data")
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_qilingcopyselect", nil, true, "tc_qilingcopyselect")
    self.touchPriority = touchPriority
    self.data = data

    local qilingConfig = gamedata.config.exclusive_device_spirit_copy[tostring(data.index)]
    self.configData = {}
    for k,v in pairs(qilingConfig) do
        table.insert(self.configData, v)
    end

    local sortfunc = function (a,b)
        return  a.difficulty < b.difficulty 
    end
    table.sort(self.configData,sortfunc)

    printT(self.configData,"jkp-configData")
    
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority) 
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
    	gameWindows:closeWindow("exclusiveArtifactQiLingCopy")
    end, CCControlEventTouchUpInside)  


    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","exclusiveArtifactQiLingCopy",touchbegin)
    local function touchend(pos)
        if self.rootItems.listNode and ui.isTouched(self.rootItems.listNode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","exclusiveArtifactQiLingCopy",touchend)

    self:setCopyInfo(self.rootItems.num, data.num)
    
    self.listTableView = nil
    self:createActivityList()

    -- self.listTableView:reloadData()
    -- self.listTableView:setLuaContentOffset(0, self.rootItems.listNode:getContentSize().height - self.cellNum *self.cellSize.height)
    
    return self.rootNode	
end

function exclusiveArtifactQiLingCopy.close(self)
    gameTouch:UnrigistFunc("begin","exclusiveArtifactQiLingCopy")
    gameTouch:UnrigistFunc("end","exclusiveArtifactQiLingCopy")
    self.isscrolltouched = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.data = nil
    self.configData = nil
    self.cellNum = 0
    self.listTableView = nil 
end

function exclusiveArtifactQiLingCopy.createActivityList( self )

    local celldict = {}
    local listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuanshushenqi/cell_qilingcopyselect", nil, true, "cell_qilingcopyselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler, a1)
            cellCCB:setPosition(self.cellSize.width/2, self.cellSize.height/2)         
           	
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = self.data.difficulty < table.getTableLength( self.configData ) and  self.data.difficulty + 1 or table.getTableLength( self.configData ) 
            self.cellNum = r 
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listTableView = ui.createLuaTableView({
        handle = listHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.listTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listNode:addChild(self.listTableView)	
end


function exclusiveArtifactQiLingCopy.setCell(self,items,aiIndex)
	local tData = nil
    local lowGradeName = nil

    if self.configData[tonumber(self.data.difficulty - aiIndex )] ~= nil then
        lowGradeName = self.configData[tonumber(self.data.difficulty - aiIndex)].name2
    else
        lowGradeName = self.configData[1].name2
    end     

    if self.data.difficulty >= table.getTableLength( self.configData ) then
        tData = self.configData[tonumber(self.data.difficulty - aiIndex)]
    else
	    tData = self.configData[tonumber(self.data.difficulty + 1 - aiIndex)]    
    end
    -- 难度
    for i=1,6 do
        items["nandu"..i]:setVisible(false)
    end
    items["nandu"..tData.difficulty]:setVisible(true)

    items.lookitem:setSwallowsTouch(true)
    items.lookitem:setTouchPriority(self.touchPriority)
    items.lookitem:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        --掉落预览
        gameWindows:openWindow("exclusiveArtifact_rewardlist",{id = tonumber(tData.id), difficulty = tonumber(tData.difficulty)},nil)
    end, CCControlEventTouchUpInside)

    items.zhandouli:setString(tData.power)
    items.xiaohao:setString("消耗体力："..tData.physical)

    ui.setLabelString(items.doLab,gameConfig.strings:string_common("friendcopy",0),19)
    items.doButton:setSwallowsTouch(true)
    items.doButton:setTouchPriority(self.touchPriority)
    items.doButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        --挑战
        printT(tData,"jkp-")
        if self.data.difficulty < tData.difficulty then
            runGamePrompt({msg = "请先挑战过"..lowGradeName.."副本"})
        elseif self.data.num <= 0 then
            runGamePrompt({msg = "挑战次数不足"})
        elseif GameScene.roleinfo.stamina < tData.physical then
            runGamePrompt({msg = "体力不足"})
        else
            UIRequest({type = 8202, state = 2, id = tonumber(tData.id), difficulty = tonumber(tData.difficulty)})
        end
    end, CCControlEventTouchUpInside)

    if self.data.difficulty < tData.difficulty then
        ui.addGray("CCControlButton",items.doButton)
    else
        ui.removeGray("CCControlButton",items.doButton)
    end
end

function exclusiveArtifactQiLingCopy.setCopyInfo(self,items,times)
    if tonumber(times) >0 then
        items:setColor(ccc3(84,255,8))
       else
        items:setColor(ccc3(255,8,8))
    end    
    items:setString(tostring(times))
end

function exclusiveArtifactQiLingCopy.qiLingReload(self,aiData,pass)
    self.data = aiData

    local delay = 0
    if self.rootItems.passeffect then
        self.rootItems.passeffect:removeAllChildrenWithCleanup(true)
        if pass and pass == 1 then
            gameTouch:clickprofbytime(2)
            delay = 1
            local ccbnode,ccbitem = CCBReaderLoad("copy2/copyfinish", nil, true, "copyfinish")
            self.rootItems.passeffect:addChild(ccbnode)
        end
    end

    local dofunc = function()
        self:setCopyInfo(self.rootItems.num, self.data.num)

        self.listTableView:reloadData()
        self.listTableView:setLuaContentOffset(0, self.rootItems.listNode:getContentSize().height - self.cellNum * self.cellSize.height)
    end

    if delay > 0 then
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5),CCCallFunc:create(function()
            dofunc()
        end)))
    else
        dofunc()
    end
end

return exclusiveArtifactQiLingCopy$   