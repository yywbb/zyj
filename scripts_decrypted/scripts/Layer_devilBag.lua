--
-- 魔宠背包
-- User: zhangzhixin
-- Date: 11/1/16
-- Time: 19:24
-- To change this template use File | Settings | File Templates.
--

-- local UIRequest = UIRequest
-- local gamedata = gamedata

local devilBag = {
    rootNode = nil,
    rootItems = nil,
    CellSize = {x=1080,y=228},
    fragment = {},
    petsChipData = {},
    petsData = {},
    pageconfig = {"pets","petsChip"},
    -- titleconfig = {"魔宠","魔宠碎片"},
    pagename = {gameConfig.strings:string_common("devil",1),gameConfig.strings:string_common("devil",2)},
    selectpage = "pets",   
    havePetsData = {} ,
    isscrolltouched = false,
}

function devilBag.shiftPage(self,type)
	print("devilBag...am...shiftpage",type)
    self.selectpage = type

    if type ==  "pets" then
        self.rootItems.mochongscroll:setPositionX(0)
        self.rootItems.fragmentscroll:setPositionX(-9999)
    elseif  type ==  "petsChip" then
        self.rootItems.mochongscroll:setPositionX(-9999)
        self.rootItems.fragmentscroll:setPositionX(0)
    end

end

function devilBag.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("mochong3/mochongList", nil, true, "mochongList")
    print("devilBag.init ==========")
    printT(param )
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topNode:setPositionY(toppos)

    self.rootItems.fragmentscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))
    self.rootItems.mochongscroll:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight))  
    self.petsData = param.petsData
    self.toppos = toppos
    -- print("PRINT petsData")
    -- printT(self.petsData)
    -- self.touchPriority = touchPriority
    self.petsListData = gamedata.config.pet3_attr
    self.petsChipListData = gamedata.config.pet3_fragment
    -- print("self.petsListData =============")
    -- printT(self.petsListData)
    -- print("self.petsChipListData =============")
    -- printT(self.petsChipListData)
    -- print("param.petsChipData ======= ")
    -- printT(param.petsChipData)    
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","devilBag",touchbegin)
    local function touchend(pos)
        --两个滚动层大小一样，不会同时在一起
        if self.rootItems.mochongscroll and ui.isTouched(self.rootItems.mochongscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
        if self.rootItems.fragmentscroll and ui.isTouched(self.rootItems.fragmentscroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end        
    end
    gameTouch:rigistFunc("end","devilBag",touchend)    
    self:devilListInit() 
    self:loadPetsChipList(param.petsChipData)

    return self.root      
end

function devilBag.clear(self)
    gameTouch:UnrigistFunc("begin","devilBag")
    gameTouch:UnrigistFunc("end","devilBag")    
    self.isscrolltouched = false
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.petsChipData  = {}
    self.petsData = {}
    self.havePetsData = {}    
    self.selectpage = "pets"
    self.petsListTableView = nil
    self.petsChipListTableView = nil
end
--初始化界面
function devilBag:devilListInit(  )
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("devil")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(-103) 
    self.rootItems.fragmentscroll:setPositionX(-9999)
    if 0 == table.getTableLength(self.petsData.pets) then
        local gotoNode = CCLayer:create()
        self.rootItems.mochongscroll:addChild(gotoNode)
        gotoNode:setPosition(ccp(540,self.toppos/2))
        ui.setGoto(gotoNode,true,"devil")
    else
        self:createhavePetsTable()
        self:createPetsList()
    end
end 

function devilBag.createhavePetsTable( self )
    

    for k,v in pairs(self.petsData.pets) do
        if self.petsData.iid ~= v.iid then
            table.insert(self.havePetsData,v)
        end
    end 
    
    local qualityA,qualityB = 0,0
    table.sort(self.havePetsData,function(a,b)
        qualityA = self.petsListData[tostring(a["cid"])][tostring(a["level"])].quality
        qualityB = self.petsListData[tostring(b["cid"])][tostring(b["level"])].quality
        if qualityA > qualityB then
            return true
        elseif qualityA < qualityB then
            return false
        else
            if a["cid"]  < b["cid"] then
                return true
            else
                return false
            end
        end     
    end)
    if self.petsData.pets[tostring(self.petsData.iid)] then
        table.insert(self.havePetsData,1,self.petsData.pets[tostring(self.petsData.iid)])
    end
end
function devilBag.createPetsList(self)
    local celldict = {}

    local petsListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("mochong3/cell_mochong", nil, true, "cell_mochong")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.petsListTableView,cellCCB,self.CellSize.x/2, 0,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            self:setPets(ccbDocumentControler,self.havePetsData[a1 + 1])

            if self.petsListTableView then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = #self.havePetsData 
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.petsListTableView = ui.createLuaTableView({
        handle = petsListHandle,
        viewwidth = self.rootItems.mochongscroll:getContentSize().width,
        viewheight = self.rootItems.mochongscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.mochongscroll:addChild(self.petsListTableView)
    self.petsListTableView:setTouchPriority(-101)
end
--初始化宠物cell
function devilBag.setPets(self,aiCell,aiData)
    print("setPets========")
    printT(aiData)
    local data  = self.petsListData[tostring( aiData.cid)][tostring(aiData.level)]
    data.cid = data.id      

    -- printT(self.petsListData)
    local quality  = self.petsListData[tostring(aiData.cid)][tostring( aiData.level)].quality
    if quality >= 7 then
        ui.setLabelString(aiCell.nameLabel,data.name,213)
        ui.setLabelString(aiCell.qualityLabel,gameConfig.strings:string_common("quality", quality),213)
    else
        ui.setLabelString(aiCell.nameLabel,data.name,quality*2 -1)
        ui.setLabelString(aiCell.qualityLabel,gameConfig.strings:string_common("quality", quality),quality*2)
    end

    if self.petsData.iid == aiData.iid then
        aiCell.battleLabel:setVisible(true)
        aiCell.battleBtn:setPositionY(-50)
        aiCell.battleText:setPositionY(-50)
    else
        aiCell.battleLabel:setVisible(false)
        aiCell.battleBtn:setPositionY(-25)
        aiCell.battleText:setPositionY(-25)
    end
    ui.setLabelString(aiCell.battleText,"进阶",18)

    ui.setNewIcon(aiCell,data)
    setSpriteFrameByName(aiCell.i_icon, data.icon)

    ui.setSpriteTextureRect(aiCell.i_icon,0,0,150,150)

    aiCell.battleBtn:setVisible(false)
    aiCell.battleText:setVisible(false)
    aiCell.battleBtn:setSwallowsTouch(true)
    aiCell.battleBtn:setTouchPriority(-102)
    aiCell.battleBtn:addHandleOfControlEvent(
    function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end
        -- GameScene:shiftLayer("devil","up",aiData.iid)
        if GameScene.layers["devil"].show then
            GameScene.layers["devil"].module:toPage({page = "jinjie"})
        end
    end, CCControlEventTouchUpInside)  

    setSpriteFrameByName(aiCell["i_k_quality"], "b_iconk"..quality)
    setSpriteFrameByName(aiCell["i_quality"], "b_iconbg"..quality)
 end 
--修改宠物碎片数据
function devilBag.loadPetsChipList(self,aiData)
    print("loadPetsChipList")
    local tempTable = {}
    for k,v in pairs(aiData) do
        if v.num ~= 0 then  
            v.isCompound = false
            v.isHas = false
            table.insert(tempTable,v)
        end
    end 
    --取出已有宠物碎片
    for k,v in pairs(self.petsData.pets) do
        for m,n in pairs(tempTable) do
            if v.cid == self.petsChipListData[ tostring(n.cid)].petid then
                n.isHas = true
                table.insert(self.petsChipData,n)
                table.remove(tempTable,m)
                break
            end
        end
    end
    --取出不能合成宠物碎片
    for m,n in pairs(tempTable) do
        if n.num < self.petsChipListData[ tostring(n.cid)].number then
            table.insert(self.petsChipData,n)
        end
    end

    for k,v in pairs(self.petsChipData) do
        for m,n in pairs( tempTable) do
            if n.cid == v.cid then
                table.remove(tempTable,m)
                break
            end
        end
    end
    table.sort(self.petsChipData,function(a,b)
        if a.cid < b.cid then
            return true
        else
            return false
        end
    end) 
    --按cid 由大到小排序 ，再头插入时，正好反过来  
    table.sort(tempTable,function(a,b)
        if a.cid > b.cid then
            return true
        else
            return false
        end
    end)         
    for k,v in pairs(tempTable) do
        v.isCompound = true
        table.insert(self.petsChipData,1,v)
    end 

    if  0 == table.getTableLength(self.petsChipData) then
        local gotoNode = CCLayer:create()
        self.rootItems.fragmentscroll:addChild(gotoNode)
        gotoNode:setPosition(ccp(540,self.toppos/2))
        ui.setGoto(gotoNode,true,"devil")
    else 
        self:createPetsChipList()
    end
end

function devilBag.createPetsChipList(self)
    local celldict = {}
    local petsChipListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.CellSize.x, self.CellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("equip_new/cell_fragment", nil, true, "cell_fragment")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }

                if guide.controller and guide.controller.isOnGuide then
                else
                    ui.tableviewAnimation(self.petsChipListTableView,cellCCB,self.CellSize.x/2, 0,a1)
                end
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setPetsChip(ccbDocumentControler,self.petsChipData[a1 + 1])

            if self.petsChipListTableView  or (guide.controller and guide.controller.isOnGuide) then
                cellCCB:setPosition(self.CellSize.x/2, 0)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.petsChipData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.petsChipListTableView = ui.createLuaTableView({
        handle = petsChipListHandle,
        viewwidth = self.rootItems.fragmentscroll:getContentSize().width,
        viewheight = self.rootItems.fragmentscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.fragmentscroll:addChild(self.petsChipListTableView)
    self.petsChipListTableView:setTouchPriority(-101)
end
--初始化魔宠碎片
function devilBag.setPetsChip(self,aiCell,aiData)
    -- print("devilBag:setPetsChip")
    -- print("self.petsChipListData =========")
    -- printT(self.petsChipListData)
    -- print("aiData =========")
    -- printT(aiData)
    -- print("self.petsData =========")
    -- printT(self.petsData)
    local id  = self.petsChipListData[ tostring( aiData.cid )].petid
    ui.setLabelString(aiCell.name,self.petsListData[tostring(id)]["1"].name.."碎片",self.petsListData[tostring(id)]["0"].quality * 2 -1)
    aiCell.desc:setString("集齐"..self.petsChipListData[ tostring(aiData.cid)].number.."个碎片既可合成"..gameConfig.strings:string_common("quality",self.petsListData[tostring(id)]["0"].quality).."魔宠《"..self.petsListData[tostring(id)]["1"].name.."》")

    ui.setIconLv(aiCell,{cid = aiData.cid})

    aiCell["il_button"]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(aiData.cid)
    end, CCControlEventTouchUpInside)
    aiCell["il_button"]:setTouchPriority(-102)


    ui.setLabelString(aiCell.il_lv, aiData.num,13)
    if aiData.isHas == true then
        ui.setLabelString(aiCell.num,aiData.num,13)
    else
        ui.setLabelString(aiCell.num,aiData.num.."/"..self.petsChipListData[ tostring(aiData.cid)].number,13)
    end
    aiCell.button:setSwallowsTouch(true)
    aiCell.button:setTouchPriority(-102)
    if aiData.isCompound == false  then
        setControlButtonFrame(aiCell.button,"b_s_button1","b_s_button1_h","b_s_button1")
        aiCell.button:addHandleOfControlEvent(
        function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            gameWindows:openWindow("dropTips",aiData,nil)
        end
        , CCControlEventTouchUpInside)        
        ui.setLabelString(aiCell.buttontext,gameConfig.strings:string_common("moreCommon",18),18)
    else
        setControlButtonFrame(aiCell.button,"b_s_button2","b_s_button2_h","b_s_button2")
        aiCell.button:addHandleOfControlEvent(
        function()
            if not self.isscrolltouched then return end
            if gameTouch.isScrollling then return end
            print("devilBag request 1049"..aiData.cid)
            UIRequest({type = 1049 ,cid = aiData.cid,petBagCompound = {cid = aiData.cid,petid =self.petsChipListData[tostring(aiData.cid)].petid, num = aiData.num,useNum = self.petsChipListData[tostring(aiData.cid)].number}})  
        end
        , CCControlEventTouchUpInside)        
        ui.setLabelString(aiCell.buttontext,gameConfig.strings:string_common("buttontext","hecheng"),18)          
    end 
end

function devilBag.devilBagCompound(self,aiData)
    print("devilBag.devilBagCompound")
    -- printT(aiData)
    -- print("self.petsData ========")
    -- printT(self.petsData)
    -- print("self.havePetsData =====  ")
    -- printT(self.havePetsData)
    -- print("self.petsChipData ======  ")
    -- printT(self.petsChipData)
    self.petsData.pets[aiData.iid] = aiData
    table.insert(self.havePetsData,aiData)
    table.sort(self.havePetsData,function(a,b)
        if a["cid"]  > b["cid"] then
            return true
        else
            return false
        end     
    end)   
    -- print("change  self.petsData ======== ")
    -- printT(self.petsData)
    -- print("change self.havePetsData =====  ")
    -- printT(self.havePetsData)
    gameWindows:openWindow("devourDetails",{data = aiData,index = "info"})
    local useChipNum = 0
    local petchipid = 0
    for k,v in pairs(self.petsChipListData) do
        if v.petid == aiData.cid then
            useChipNum = v.number
            petchipid = v.debris 
            break
        end
    end

    for i = 1,#self.petsChipData do
        if petchipid == self.petsChipData[i].cid then
            if self.petsChipData[i].num - useChipNum <= 0 then
                table.remove( self.petsChipData,i)
                self.petsChipListTableView:setLuaContentOffset(0, self.rootItems.fragmentscroll:getContentSize().height - table.getTableLength(self.havePetsData)*self.CellSize.y)
            else
                self.petsChipData[i].num = self.petsChipData[i].num - useChipNum
                self.petsChipData[i].isCompound = false
                self.petsChipData[i].isHas = true
                table.sort(self.petsChipData,function(a,b)
                    if (a.isCompound == false and b.isCompound == false ) or (a.isCompound == true and b.isCompound == true)  then
                        if a.cid < b.cid then
                            return true
                        else
                            return false
                        end
                    elseif  a.isCompound == true and b.isCompound  == false then
                        return true
                    elseif  a.isCompound == false and b.isCompound  == true then
                        return false
                    end
                end)
            end
            -- print("change self.petsChipData ========")
            -- printT(self.petsChipData)
            self.petsChipListTableView:reloadData()
            break
        end
    end
    if self.petsListTableView ~= nil then
        self.petsListTableView:setLuaContentOffset(0, self.rootItems.mochongscroll:getContentSize().height - table.getTableLength(self.havePetsData)*self.CellSize.y)
        self.petsListTableView:reloadData()
    else
        self.rootItems.mochongscroll:removeAllChildrenWithCleanup(true)
        self:createPetsList()  

    end
end

return devilBag
�G  