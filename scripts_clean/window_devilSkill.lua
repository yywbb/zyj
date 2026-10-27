--
-- 魔宠被动技能列表
-- 魔宠说明
-- User: zhangzhixin
-- Date: 12/1/16
-- To change this template use File | Settings | File Templates.
--
local  gamedata = gamedata

local devilSkill = {
    rootNode = nil,
    rootItems = nil,
    quality = 4,--技能品质等级
    dataNum = 0 ,--数据总个数	
    cellSize = {width = 900,height = 230},
    isscrolltouched = false,
}

function devilSkill.open(self,touchPriority,data,callback)
    print("devilSkills...am...open...")
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    self.data = data.petdata
    self.haveSkill = data.skillpoint
    printT(self.data)
    printT(self.haveSkill)
    --加载魔宠说明
    if data == "explain" then
        self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochong_rule", nil, true, "mochong_rule")
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("devilSkill")
        end, CCControlEventTouchUpInside)
        self.rootItems.closeButton:setSwallowsTouch(true)
        self.rootItems.closeButton:setTouchPriority(self.touchPriority)            
        self.root:addChild(self.rootNode)
        return self.root 
    end
    self.rootNode, self.rootItems = CCBReaderLoad("mochong3/mochongskill_yulan", nil, true, "mochongskill_yulan")
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("devilSkill")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)    
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("devilSkill")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)      
    self:devilSkillInit()  
    ui.setLabelString(self.rootItems.doLab, gameConfig.strings:string_common("moreCommon","queding"),19)
    self.rootItems.title:setString("被动技能预览")
    self.root:addChild(self.rootNode)
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","devilSkill",touchbegin)
    local function touchend(pos)
        if self.rootItems.listScroll and ui.isTouched(self.rootItems.listScroll,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","devilSkill",touchend)    
    return self.root  
end

function devilSkill.close(self)
    gameTouch:UnrigistFunc("begin","devilSkill")
    gameTouch:UnrigistFunc("end","devilSkill")
    self.isscrolltouched = false    
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.GeneralListTableView = nil

    self.devilList = {}
end

function devilSkill.devilSkillInit(self)
	self:devilListReload()
end
--读取配置表
function devilSkill.devilListReload(self)
    print("devilSkill.devilListReload...am...generallistReload...")

    self.devilList = {}
    for k,v in pairs(gamedata.config.pet3_passiveskill) do
    	table.insert(self.devilList,v)
    end
    -- local sortQualityID = function(a,b)
    -- 	if a["quality"] == b["quality"] then
    -- 		if a["id"] > b["id"] then
    -- 			return true
    -- 		else
				-- return false
    -- 		end
    -- 	else
    -- 		if a["quality"] > b["quality"] then
    -- 			return true
    -- 		else
    -- 			return false
    -- 		end
    -- 	end
    -- end
    local sortQualityID = function ( a, b )
        return a.order < b.order
    end
	table.sort(self.devilList,sortQualityID)
	self.dataNum = table.getTableLength(self.devilList)
    self:createDevilSkillList()
end

--创建技能列表
function devilSkill.createDevilSkillList(self)
    local celldict = {}
    local devilListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.cellSize.width, self.cellSize.height)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("mochong3/cell_mochongskill.ccbi", nil, true, "cell_mochongskill")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            cellCCB:setPosition(self.cellSize.width/2, self.cellSize.height/2)         
           	self:itemInit(ccbDocumentControler,a1)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(self.devilList)/self.quality)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.GeneralListTableView = ui.createLuaTableView({
        handle = devilListHandle,
        viewwidth = self.rootItems.listScroll:getContentSize().width,
        viewheight = self.rootItems.listScroll:getContentSize().height,
        dire = 1
    })
    self.GeneralListTableView:setTouchPriority(self.touchPriority)
    self.rootItems.listScroll:addChild(self.GeneralListTableView)
end

function devilSkill:itemInit(aiCell,aiNum)
    print("devilSkill:itemInit")
	printT(self.devilList)
    printT(aiCell)
	for i = 1,self.quality do
		if self.dataNum >= i + aiNum * self.quality then
            aiCell["cellItem"..i]:setVisible(true)
			ui.setNewIconName(aiCell,{cid = self.devilList[aiNum*4 + i]["id"]},i-1)
			if i == 1 then
				aiCell["in_soulsprite"]:setVisible(false)
	            aiCell["i_button"]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end

		            gameWindows:openWindow("devilSkillDetail",{ list = self.devilList[aiNum*4 + i],skill = self.haveSkill})
	            end, CCControlEventTouchUpInside)
			    aiCell["i_button"]:setTouchPriority(self.touchPriority) 
                setSpriteFrameByName(aiCell.in_icon,self.devilList[aiNum*4 + i].icon)	
                aiCell["in_name"]:setString(self.devilList[aiNum*4 + i].name)
			else
				aiCell["in_soulsprite_"..(i-1)]:setVisible(false)
	            aiCell["i_button_"..(i-1)]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
		            gameWindows:openWindow("devilSkillDetail",{ list = self.devilList[aiNum*4 + i],skill = self.haveSkill})
	            end, CCControlEventTouchUpInside)
			    aiCell["i_button_"..(i-1)]:setTouchPriority(self.touchPriority) 	
                setSpriteFrameByName(aiCell["in_icon_"..(i - 1)],self.devilList[aiNum*4 + i].icon)	
                aiCell["in_name_"..(i-1)]:setString(self.devilList[aiNum*4 + i].name)
			end
		else
			print(i)
			aiCell["cellItem"..i]:setVisible(false)
			if i ~= 1 then
				aiCell["i_button_"..(i-1)]:setTouchEnabled(false)
				aiCell["in_button_"..(i-1)]:setTouchEnabled(false)
			else
				aiCell["i_button"]:setTouchEnabled(false)
				aiCell["in_button"]:setTouchEnabled(false)
			end
		end
	end
end
--锁定、解锁技能时 修改数据
function devilSkill.changelockData(self,aiData )
    self.haveSkill = {}
    for k,v in pairs(aiData.skill) do
        self.haveSkill[tonumber(k)]=v
    end
end
return devilSkill