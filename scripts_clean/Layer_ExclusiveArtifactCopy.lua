--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 21/3/26
-- Time: 17:40
-- To change this template use File | Settings | File Templates.
--
--专属神器副本

local exclusiveArtifactCopy = {
    rootNode = nil,
    rootItems = nil,
    touchPriority = -103,

    pageconfig = {"qihunCopy","qilingCopy",},
    pagename = {"器魂副本","器灵副本",},
    selectpage = "qihunCopy",

    pagebuild = {614,615,},

    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {614},
                title2 = {615},
            },
        },
    },

    qihunCellSize = {x=1015,y=218+10},
    qilingCellSize = {x=1015,y=218+10},

    qihunNum = 0,
    qihunData = {},
    qihunConfigData = {},

    qilingData = {},
    qilingConfigData = {},
    qilingCopyConfigData = {},

    rolelv = 0,
    isNewOpen = 0,

    ListTableView_QH,
    ListTableView_QL,

    isscrolltouched = false,
}


function exclusiveArtifactCopy.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("zhuanshushenqi/zhuanshushenqi_copy", nil, true, "zhuanshushenqi_copy")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)

    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("daily")
    end, CCControlEventTouchUpInside)

    self.rootItems.add_qhnum:setSwallowsTouch(true)
    self.rootItems.add_qhnum:setTouchPriority(self.touchPriority)
    self.rootItems.add_qhnum:addHandleOfControlEvent(function()
        gameWindows:openWindow("exclusiveArtifactBuyNum",{id = 1})
    end, CCControlEventTouchUpInside)

    self.rootItems.qihunList:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-310))
    self.rootItems.qilingList:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-310))

    self.qihunConfigData = gamedata.config.exclusive_device_soul_copy
    -- 整理器灵数据
    self.qilingConfigData = gamedata.config.exclusive_device_spirit_copy

    self.rootItems.ruleButton1:setSwallowsTouch(true)
    self.rootItems.ruleButton1:setTouchPriority(self.touchPriority)
    self.rootItems.ruleButton1:addHandleOfControlEvent(function()
        if self.selectpage == "qihunCopy" then
            ui.popCommonRule(self.pagebuild[1])
        else
            ui.popCommonRule(self.pagebuild[2])
        end
    end, CCControlEventTouchUpInside)

    -- 触摸设置
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","zhuanshushenqi_copy",touchbegin)
    local function touchend(pos)
        if self.selectpage == "qihunCopy" then
            if self.rootItems.qihunList and ui.isTouched(self.rootItems.qihunList,pos.x,pos.y) then
                self.isscrolltouched = true
            end
        else
            if self.rootItems.qilingList and ui.isTouched(self.rootItems.qilingList,pos.x,pos.y) then
                self.isscrolltouched = true
            end
        end
    end
    gameTouch:rigistFunc("end","zhuanshushenqi_copy",touchend)

    -- self:shiftPage(self.selectpage)
    UIRequest({type = 8201})
end

function exclusiveArtifactCopy.reload(self,data)
    self.qihunNum = data.qhNum
    self.qihunData = data.qhData
    self.qilingData = data.qlData
    self.rolelv = data.rolelv

    self:shiftPage(self.selectpage)
end

function exclusiveArtifactCopy.shiftPage(self,type)
    self.selectpage = type
    if type == "qihunCopy" then
        self.rootItems.qihunNode:setVisible(true)
        self.rootItems.qilingNode:setVisible(false)
        self.rootItems.qihunNode:setPositionX(0)
        self.rootItems.qilingNode:setPositionX(-9999)
        self.rootItems.qihunList:setPositionX(0)
        self.rootItems.qilingList:setPositionX(-9999)

        self:setCopyInfo(self.rootItems.qihun_num,self.qihunNum)
        if self.ListTableView_QH == nil then
            self:qinhunCopyInfo(self.rootItems)
        else
            self.ListTableView_QH:reloadData()
            self.ListTableView_QH:setLuaContentOffset(0,  self.rootItems.qihunList:getContentSize().height - self.qihunCellSize.y*table.getTableLength(self.qihunData))
        end
        
    else
        self.rootItems.qihunNode:setVisible(false)
        self.rootItems.qilingNode:setVisible(true)
        self.rootItems.qihunNode:setPositionX(-9999)
        self.rootItems.qilingNode:setPositionX(0)
        self.rootItems.qihunList:setPositionX(-9999)
        self.rootItems.qilingList:setPositionX(0)

        if self.ListTableView_QL == nil then
            self:qilingCopyInfo(self.rootItems)
        else
            self.ListTableView_QL:reloadData()
        end

    end
end

function exclusiveArtifactCopy.qinhunCopyInfo(self, items)
    
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.qihunCellSize.x, self.qihunCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuanshushenqi/cell_qihuncopy", nil, true, "cell_qihuncopy")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.ListTableView_QH,cellCCB,gameConfig.originSize.width/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local totalnum = table.getTableLength(self.qihunData)
            local config = self.qihunConfigData[tostring(totalnum - a1)]
            self:setCellQiHun(config,ccbDocumentControler)

            if self.ListTableView_QH then
                cellCCB:setPosition(gameConfig.originSize.width/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.qihunData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView_QH = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = items.qihunList:getContentSize().width,
        viewheight = items.qihunList:getContentSize().height,
        dire = 1
    })
    items.qihunList:addChild(self.ListTableView_QH)
    self.ListTableView_QH:setTouchPriority(-101)

end

function exclusiveArtifactCopy.setCellQiHun(self,data,items)

    items.lookitem:setSwallowsTouch(true)
    items.lookitem:setTouchPriority(-102)
    items.lookitem:addHandleOfControlEvent(function()
        --掉落预览
        local reward = {}
        local _str = ""
        for i=1,4 do
            _str = _str..data["reward"..i]
        end
         local _reward = ui.getIDNUMChances(_str)
         
         for i = 1, #_reward do
            if _reward[i].num ~= _reward[i].chance then
                _reward[i].num = _reward[i].num.."~".._reward[i].chance
            else
                _reward[i].num = _reward[i].num
            end
            _reward[i].probability = data["probability"..i]
         end
         gameWindows:openWindow("getStaff",{data = _reward,type = "掉落预览"},nil)
    end, CCControlEventTouchUpInside)

    items.leveltext:setString(data.open_level.."级")

    items.doButton:setSwallowsTouch(true)
    items.doButton:setTouchPriority(self.touchPriority)
    items.doButton:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        --挑战
        if self.rolelv < data.open_level then
            runGamePrompt({msg = data.open_level.."级开启副本"})
        elseif self.qihunData[tostring(data.id)] == 0 then
            local copyConfig = self.qihunConfigData[tostring(data.id - 1)]
            runGamePrompt({msg = "请先挑战过"..copyConfig.open_level.."级器魂副本"})
        elseif self.qihunNum <= 0 then
            runGamePrompt({msg = "挑战次数不足"})
            gameWindows:openWindow("exclusiveArtifactBuyNum",{id = 1})
        else
            UIRequest({type = 8202, state = 1, id = data.id})
        end
    end, CCControlEventTouchUpInside)

    items.doButton1:setSwallowsTouch(true)
    items.doButton1:setTouchPriority(self.touchPriority)
    items.doButton1:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        --扫荡
        if self.qihunNum <= 0 then
            runGamePrompt({msg = "挑战次数不足"})
            gameWindows:openWindow("exclusiveArtifactBuyNum",{id = 1})
        else
            UIRequest({type = 8203, id = data.id})
        end
    end, CCControlEventTouchUpInside)

    items.doNode:setVisible(false)
    items.doNode1:setVisible(false)
    if self.qihunData[tostring(data.id)] == 1 then
        ui.removeGray("CCControlButton",items.doButton)
        ui.setLabelString(items.doLab,gameConfig.strings:string_common("friendcopy",0),19)
        items.doNode:setVisible(true)
    elseif self.qihunData[tostring(data.id)] == 2 then
        ui.setLabelString(items.doLab1,gameConfig.strings:string_common("copymap",1),19)
        items.doNode1:setVisible(true)
    else
        ui.addGray("CCControlButton",items.doButton)
        ui.setLabelString(items.doLab,gameConfig.strings:string_common("friendcopy",0),19)
        items.doNode:setVisible(true)
    end

    items.zhandouli:setString(data.power)
end

function exclusiveArtifactCopy.qilingCopyInfo(self, items)

    -- local sortfunc = function (a,b)
    --     return  a.difficulty > b.difficulty 
    -- end
    -- table.sort(self.currentCopyInfo,sortfunc)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.qilingCellSize.x, self.qilingCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("zhuanshushenqi/cell_qilingcopy", nil, true, "cell_qilingcopy")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.ListTableView_QL,cellCCB,gameConfig.originSize.width/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCellQiLing(self.qilingData[a1+1] or self.qilingData[tostring(a1+1)],ccbDocumentControler, a1+1)

            if self.ListTableView_QL then
                cellCCB:setPosition(gameConfig.originSize.width/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.qilingData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView_QL = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = items.qilingList:getContentSize().width,
        viewheight = items.qilingList:getContentSize().height,
        dire = 1
    })
    items.qilingList:addChild(self.ListTableView_QL)
    self.ListTableView_QL:setTouchPriority(-102)
end

function exclusiveArtifactCopy.setCellQiLing(self,data,items,index)
    
    for i=1,6 do
        items["cell_"..i]:setVisible(false)
    end
    items["cell_"..index]:setVisible(true)
    data.index = index
    self:setCopyInfo(items.num,data.num)

    local names = "简单"
    if data.difficulty == 1 then
        names = "简单"
    elseif data.difficulty == 2 then
        names = "普通"
    elseif data.difficulty == 3 then 
        names = "冒险"
    elseif data.difficulty == 4 then 
        names = "困难"
    elseif data.difficulty == 5 then 
        names = "噩梦"
    elseif data.difficulty == 6 then 
        names = "地狱"
    end
    items.jindu:setString("当前进度："..names)

    items.button:setTouchPriority(self.touchPriority)
    items.button:addHandleOfControlEvent(function()
        if gameTouch.isScrollling then return end
        if not self.isscrolltouched then return end
        print("挑战神器副本")
        gameWindows:openWindow("exclusiveArtifactQiLingCopy",data)
    end, CCControlEventTouchUpInside)   
end

--所有剩余次数
function exclusiveArtifactCopy.setCopyInfo(self,items,times)
    if tonumber(times) >0 then
        items:setColor(ccc3(84,255,8))
       else
        items:setColor(ccc3(255,8,8))
    end    
    items:setString(tostring(times))
end

function exclusiveArtifactCopy.reloadTimes(self,data)
    printT(data,"qihunNum")
    local datatimes = data.buyTime or 0
    self.qihunNum = self.qihunNum + datatimes
    self:setCopyInfo(self.rootItems.qihun_num, self.qihunNum)
end

function exclusiveArtifactCopy.clear(self)
    print("exclusiveArtifactCopy clear")

    gameTouch:UnrigistFunc("begin","zhuanshushenqi_copy")
    gameTouch:UnrigistFunc("end","zhuanshushenqi_copy")    
    self.qihunData = nil
    self.qilingData = nil
    self.qihunConfigData = nil
    self.qilingConfigData = nil
    self.qilingCopyConfigData = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.ListTableView_QH = nil
    self.ListTableView_QL = nil

    self.selectpage = "qihunCopy"

    self.isscrolltouched = false
end

return exclusiveArtifactCopy