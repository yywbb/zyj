--
-- Author: songyibo
-- Date: 2019-07-10 17:26:08
--
local godSoulTempleCuishen = {
	rootNode = nil,
	rootItems = nil,
	ListTableView = nil,
	fragments = {},

	befroePresent = 0,
	isclickOkBtn = false,

	iscanUp = false,--是否能升级
	isConsumeEnough = false,--是否有道具可用于升级
	iscancel = false,--是否能取消和确定
	soulLevel = 1,	--当前xx石等级

	beforestar = 0,
	beforestatus = -1,
	beforestarnum = -1,
}

function godSoulTempleCuishen.clear(self)
	gameTouch:UnrigistFunc("begin", "godSoulTempleCuishen")
	gameTouch:UnrigistFunc("end", "godSoulTempleCuishen")

	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.ListTableView = nil
    self.fragments = {}
    self.iscanUp = false
	self.isConsumeEnough = false
	self.iscancel = false
	self.soulLevel = 1
	self.beforestar = 0
	self.beforestatus = -1
	self.beforestarnum = -1

end

function godSoulTempleCuishen.init(self, parent, toppos, param)
	self:initNode(parent, toppos, param)
	self:initConfig()
	self:initProgressBar()
	self:initFixedString()
	self:initTouch()

	self.isFistLoad = true
	UIRequest({type = 7034, id = tonumber(self.soulType)})
    
    local now = os.date("*t", gamedata:time())
    local _str = now.year.."_"..now.month.."_"..now.day
    CCUserDefault:sharedUserDefault():setStringForKey("cuishen_FirstString"..GameScene.roleinfo.id.."_"..self.soulType, _str)

	self:requestConsumeData()
end

function godSoulTempleCuishen.initNode(self, parent, toppos, param)
	self.rootNode, self.rootItems = CCBReaderLoad("shenhundian/shenhundian_cuishen", nil, true, "shenhundian_lianhun")
    self.rootNode:setPosition(-540,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
    self.soulType = param.soulType
    self.soulLevel = param.soulLevel

    local pageConfig = {
    	["18"] = "gold",
    	["20"] = "tortoise",
    	["23"] = "none",
        ["44"] = "huolingshi",
	}

    self.rootItems.backButton:setTouchPriority(-103)
    self.rootItems.backButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("godSoulTemple","up", {page = pageConfig[self.soulType]})
    end,CCControlEventTouchUpInside)


    self.rootItems.rulebutton:setTouchPriority(-103)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("godSoulTempleRule",{ ruleid =  "64" })
    end,CCControlEventTouchUpInside)


    self.rootItems.attrPreviewBtn:setTouchPriority(-103)
    self.rootItems.attrPreviewBtn:addHandleOfControlEvent(function()
        gameWindows:openWindow("statusOverview", {
			soulType = self.soulType,
			godStatus = self.soulStatus,
			godStar = self.soulStar,
			type = 3
		})
    end,CCControlEventTouchUpInside)
    

    self.rootItems.tianjiaButton:setTouchPriority(-103)
    self.rootItems.tianjiaButton:addHandleOfControlEvent(function()
    	if self.isMax then
			runGamePrompt({msg = "已达到最高级"})
			return
		end

    	if self.iscanUp  then
    		self:autoAdd()
    	elseif not self.isConsumeEnough then	
    		runGamePrompt({msg = "道具不足"})
    	else
    		runGamePrompt({msg = gameConfig.strings:godSoulTempleLevelUp(self.soulType,0)})
        end		
    end,CCControlEventTouchUpInside)

    self.rootItems.quxiaoButton:setTouchPriority(-103)
    self.rootItems.quxiaoButton:addHandleOfControlEvent(function()
      
        if not self.iscancel then
			runGamePrompt({msg = "未选择消耗道具"})
        	return 
        end 	

    	if self.ListTableView then
    		for i,v in ipairs(self.fragments) do
    			v.l_useNum = 0
    		end
    		self.ListTableView:reloadData()
    	end

		self.soulExp = self.soulOriginExp
		self.iscancel = false
		self:refreshExpNode(2)
		print("quxiao------")

    end,CCControlEventTouchUpInside)

    self.rootItems.okBtn:setTouchPriority(-103)
    self.rootItems.okBtn:addHandleOfControlEvent(function()
        
    	local consume = {}
    	for i,v in ipairs(self.fragments) do
    		if v.l_useNum > 0 then
    			consume[v.cid] = v.l_useNum
    		end
    	end

    	if table.getTableLength(consume) > 0 then
    		gameTouch:clickprofbytime(1.5)
    		 self.iscancel = false
    		UIRequest({type = 7035, id = tonumber(self.soulType),consume = consume})
    		self.isclickOkBtn = true
    	else
    		runGamePrompt({msg = "未选择消耗道具"})
    	end
        
    end,CCControlEventTouchUpInside)

    self.iscancel = false

end

function godSoulTempleCuishen.initProgressBar(self)
	local _sprite2 = CCSprite:create("public/publicsprite/obj_15_3.png")
    self.rootItems.progress2 = CCProgressTimer:create(_sprite2)
    self.rootItems.progress2:setAnchorPoint(ccp(0.0, 0.5))
    self.rootItems.progress2:setType(kCCProgressTimerTypeBar)
    self.rootItems.progress2:setMidpoint(ccp(0, 0.5))
    self.rootItems.progress2:setBarChangeRate(ccp(1, 0))
    self.rootItems.progress2:setPosition(ccp(0, 0))
    self.rootItems.progress2:setPercentage(0)
    self.rootItems.progress2:setScaleX(1.25)
    self.rootItems.progress2:setScaleY(1.25)
    self.rootItems.progress2:setOpacity(125)
    self.rootItems.progressNode:addChild(self.rootItems.progress2)



	local _sprite = CCSprite:create("public/publicsprite/obj_15.png")
    self.rootItems.progress = CCProgressTimer:create(_sprite)
    self.rootItems.progress:setAnchorPoint(ccp(0.0, 0.5))
    self.rootItems.progress:setType(kCCProgressTimerTypeBar)
    self.rootItems.progress:setMidpoint(ccp(0, 0.5))
    self.rootItems.progress:setBarChangeRate(ccp(1, 0))
    self.rootItems.progress:setPosition(ccp(0, 0))
    self.rootItems.progress:setPercentage(0)
    self.rootItems.progress:setScaleX(1.25)
    self.rootItems.progress:setScaleY(1.25)
    self.rootItems.progressNode:addChild(self.rootItems.progress)

    self.befroePresent = 0
end

function godSoulTempleCuishen.initConfig(self)
	self.soulExpendConfig = gamedata.config.shenhundian_cuishenxiaohao[self.soulType]
end

function godSoulTempleCuishen.initFixedString(self)
	ui.setLabelString(self.rootItems["title2Txt"], gameConfig.strings:string_common("godSoulTemple", "refineSoule", 11), 14)
	ui.setLabelString(self.rootItems["oneAddTxt"], gameConfig.strings:string_common("godSoulTemple", "refineSoule", 5), 19)
	ui.setLabelString(self.rootItems["cancelTxt"], gameConfig.strings:string_common("godSoulTemple", "refineSoule", 6), 19)
	ui.setLabelString(self.rootItems["okTxt"], gameConfig.strings:string_common("godSoulTemple", "refineSoule", 7), 19)
end

function godSoulTempleCuishen.initTouch(self)
    local _touchBegin = function(pos)
        self.isscrolltouched = false
    end
    
    local _touchEnd = function(pos)
        if self.rootItems.itemNode and ui.isTouched(self.rootItems.itemNode, pos.x, pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("begin", "godSoulTempleCuishen", _touchBegin)
    gameTouch:rigistFunc("end", "godSoulTempleCuishen", _touchEnd)
end

function godSoulTempleCuishen.requestConsumeData(self)
	printT(self.soulExpendConfig,"self.soulExpendConfig")
	print(self.soulType)
	local cids = {}
	for k,v in pairs(self.soulExpendConfig) do
		table.insert(cids,v.consume)
	end
	UIRequest({type = 12001, order = 32009, cids = cids})
end

function godSoulTempleCuishen.setPropNum(self, data)
	printT(data,"self.setPropNum")
	self.fragments = {}

	for k,v in pairs(data) do
		if v > 0 then
			table.insert(self.fragments,{
				num = v,
				cid = tonumber(k),
				l_useNum = 0,
			})
		end
	end


	if #self.fragments > 0 then
		if not self.ListTableView then
	        self:createList()
	    else
	        self.ListTableView:reloadData()
	    end
	    self.rootItems.no:setVisible(false)
	    self.isConsumeEnough = true
    else
    	if self.ListTableView then
	        self.ListTableView:reloadData()
	    end
    	self.rootItems.no:setVisible(true)
    	self.isConsumeEnough = false
	end
	self:btnStatusChangeByLevel()
end



function godSoulTempleCuishen.btnStatusChangeByLevel(self)

    --升级达到最高级了
    if self.isMax then
	    ui.addGray("CCControlButton", self.rootItems["tianjiaButton"])
		ui.addGray("CCControlButton", self.rootItems["okBtn"])
   		ui.addGray("CCControlButton", self.rootItems["quxiaoButton"])
   		return
    end 	

    --一键添加按钮
    if self.soulConfig then
	 	if self.soulConfig.limit <= self.soulLevel then
	       self.iscanUp = true
	       ui.removeGray("CCControlButton", self.rootItems["tianjiaButton"])
	       ui.setLabelString(self.rootItems["hasTxtValue"], nil, 26)

	    else
	       ui.addGray("CCControlButton", self.rootItems["tianjiaButton"])
           ui.setLabelString(self.rootItems["hasTxtValue"], nil, 24)
	       self.iscanUp = false
	       print("level no enough")
	    end 	
    end 	

    if self.isConsumeEnough and self.iscanUp then
        ui.removeGray("CCControlButton", self.rootItems["tianjiaButton"])
    else 	
    	ui.addGray("CCControlButton", self.rootItems["tianjiaButton"])
    end 	

    --确认和取消按钮
    if self.iscancel then
    	ui.removeGray("CCControlButton", self.rootItems["okBtn"])
    	ui.removeGray("CCControlButton", self.rootItems["quxiaoButton"])
    else
    	ui.addGray("CCControlButton", self.rootItems["okBtn"])
   		ui.addGray("CCControlButton", self.rootItems["quxiaoButton"])
    end 	    
end


function godSoulTempleCuishen.reloadData(self, data)
	self:setData(data)

	self:refreshTitle()
	self:refreshExpNode(1)
	self:btnStatusChangeByLevel()

 	if self.beforestatus < self.soulStatus then
		self:refreshStar(self.beforestarnum,self.beforestar+1)
		return
    end		

	self:refreshStarNode()
	self:refreshStar()
	self:refreshDesc()
	
	self.isFistLoad = false
	print("reloaddata------")
end

function godSoulTempleCuishen.setData(self, data)
    self.levelUp = false
	local soulConfig = gamedata.config.shenhundian_cuishen[self.soulType]
	self.soulStatus = data.godSoulTemple.soulStatus
	self.soulConfig = soulConfig[tostring(self.soulStatus)]
	self.soulStar = data.godSoulTemple.soulStar
	self.soulOriginExp = data.godSoulTemple.soulExp
	self.soulExp = self.soulOriginExp

    if self.beforestar == 0 and self.isFistLoad then
       self.beforestar = self.soulStar
    else
        if self.beforestar ~= self.soulStar then
            self.levelUp = true
        end
    end

    if self.beforestatus == -1 then
    	self.beforestatus = self.soulStatus
    end	

    if self.beforestarnum == -1 then
    	self.beforestarnum = self.soulConfig.number
    end	
	
	if self.soulStar >= self.soulConfig.number then
		self.isMax = true
		self.soulMaxExp = 0
	else
		self.isMax = false
		self.soulMaxExp = self.soulConfig["experience"..(self.soulStar + 1)]
	end

end

function godSoulTempleCuishen.autoAdd(self)
	print("autoAdd")

	if self.isMax then
		runGamePrompt({msg = "已达到最高级"})
		return
	end

	if self.soulExp >= self.soulMaxExp then
		runGamePrompt({msg = "经验值已满"})
		return
	end

	for i,v in ipairs(self.fragments) do
		local itemConfig = self.soulExpendConfig[tostring(v.cid)]
		if not itemConfig then
			runGamePrompt({msg = "配置表异常 "..v.cid})
			return
		end

		for k=1,v.num - v.l_useNum do
			self.soulExp = self.soulExp + itemConfig.experience
			v.l_useNum = v.l_useNum + 1
			if self.soulExp >= self.soulMaxExp then
				break
			end
		end

		if self.soulExp >= self.soulMaxExp then
			break
		end

	end

    if not self.isConsumeEnough or  #self.fragments < 0  then	
    	runGamePrompt({msg = "道具不足"})
    	return
    end		
    
	self.iscancel = true
	if self.ListTableView then
		self.ListTableView:reloadData()
	else
		runGamePrompt({msg = "没有消耗道具"})
	    return 	
    end
	self:refreshExpNode(2)
	print("autoadd------")

end

function godSoulTempleCuishen.setCell( self,items,index,refresh)

	local data = self.fragments[index]

	printT(data,"setCell")
	if not refresh then
		ui.setNewIcon(items, {cid = data.cid})
		-- if not items.delaybutton then
		-- 	items.delaybutton = true
		-- 	ui.creatDelayButton(items["add"], -103, function() self:addExp(index, items) end, function(index) self:beginFunc(index, items) end, function(index) self:endFunc(index, items) end, index)
		--     ui.creatDelayButton(items["reduce"], -103, function() self:reduce(index,items) end)
		-- end

        if items.addDelaybutton then
            items.addDelaybutton:removeFromParentAndCleanup(true)
        end

        if items.reduceDelaybutton then
            items.reduceDelaybutton:removeFromParentAndCleanup(true)
        end

        items.addDelaybutton = ui.creatDelayButton(items["add"], -103, function() self:addExp(index, items) end, function(index) self:beginFunc(index, items) end, function(index) self:endFunc(index, items) end, index)
        items.reduceDelaybutton = ui.creatDelayButton(items["reduce"], -103, function() self:reduce(index,items) end)
	end

    

	items.i_num:setString(data.l_useNum.."/"..(data.num - data.l_useNum))
	ui.setLabelString(items.i_num, nil, 13)

	if data.l_useNum > 0 then
        items.reduceNode:setVisible(true)
    else
        items.reduceNode:setVisible(false)
    end

end

function godSoulTempleCuishen.addExp(self, index, items)

    local data = self.fragments[index]

    if self.isMax then
        self:endFunc(index, items)
        runGamePrompt({msg = "已达到最高级"})
        return
    end

     if not self.iscanUp then
    	runGamePrompt({msg = gameConfig.strings:godSoulTempleLevelUp(self.soulType,0)})
        return
     end 	

	if data.num <= 0 then
		self:endFunc(index, items)
		runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
		return
	end

	if self.soulExp >= self.soulMaxExp then
		self:endFunc(index, items)
		runGamePrompt({msg = "经验值已满"})
		return
	end

	local itemConfig = self.soulExpendConfig[tostring(data.cid)]
	if not itemConfig then
		self:endFunc(index, items)
		runGamePrompt({msg = "配置表异常 "..data.cid})
		return
	end

	if data.l_useNum >= data.num then
		self:endFunc(index, items)
		return
	end

	self.soulExp = self.soulExp + itemConfig.experience
	data.l_useNum = data.l_useNum + 1

	self.iscancel = true
	self:setCell(items,index,true)
	self:refreshExpNode(2)
	print("addexp------")
end

function godSoulTempleCuishen.reduce(self, index, items)
	 if not self.iscanUp then
    	runGamePrompt({msg = gameConfig.strings:godSoulTempleLevel(self.soulType,0)})
        return
     end 	
    local data = self.fragments[index]
    if data.l_useNum > 0 then
    	local itemConfig = self.soulExpendConfig[tostring(data.cid)]
    	data.l_useNum = data.l_useNum - 1
    	
    	self:setCell(items,index,true)
	    self.soulExp = self.soulExp - itemConfig.experience
    	self:refreshExpNode(2)
    	print("reduce------")
    end
end

function godSoulTempleCuishen.beginFunc(self, index, items, quick)
    items["selectEffectNode"]:removeAllChildrenWithCleanup(true)
    local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/cailiaoxuanzhong/cailiaoxuanzhong", nil, true, "cailiaoxuanzhong")
    qianghuaNode:setPosition(0,0)
    items["selectEffectNode"]:addChild(qianghuaNode)
    items["selectEffectNode"]:setScale(1)
    local animationManager = getAnimationManager(qianghuaItems)
    animationManager:runAnimationsForSequenceNamed("zhenrongxuanzhong")
end

function godSoulTempleCuishen.endFunc(self, index, items)
    items["selectEffectNode"]:removeAllChildrenWithCleanup(true)
end


function godSoulTempleCuishen.createList(self)
	local _celldict = {}
    local _listHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local _r

        if fn == "cellSize" then
            _r = CCSizeMake(150, 150)
        elseif fn == "cellAtIndex" then
            local _cellCCB, _ccbDocumentControler = 0,0
            local _first = true

            if not a2 then
                a2 = CCTableViewCell:create()
                _cellCCB, _ccbDocumentControler = CCBReaderLoad("icons/new_iconGodSoul", nil, true, "new_iconGodSoul")
                _celldict[a2] = {cellCCB = _cellCCB, ccbDocumentControler = _ccbDocumentControler }
            else
                _first = false
                _cellCCB = _celldict[a2].cellCCB
                _ccbDocumentControler = _celldict[a2].ccbDocumentControler
            end

            self:setCell(_ccbDocumentControler, a1 + 1)

            _cellCCB:setPosition(150 / 2, 150 / 2)
            _cellCCB:setScale(0.8)
            if _first then
                a2:addChild(_cellCCB)
            end

            _r = a2
        elseif fn == "numberOfCells" then
            _r = table.getTableLength(self.fragments)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end

        return _r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = _listHandle,
        viewwidth = self.rootItems.itemNode:getContentSize().width,
        viewheight = self.rootItems.itemNode:getContentSize().height,
        dire = 0
    })
    self.ListTableView:setTouchPriority(-103)
    self.rootItems.itemNode:addChild(self.ListTableView)
end


function godSoulTempleCuishen.refreshTitle(self)
	local _str1 = gameConfig.strings:string_common("godSoulTemple", "refineSoule", 10)
	local _str2 = gameConfig.strings:string_common("godSoulTemple", "refineSoule", 2)
	local _str3 = gameConfig.strings:string_common("godSoulTemple", "refineSoule", 3)

	self.rootItems["title1Txt"]:setString(_str1..self.soulStatus.._str2..self.soulStar.._str3)
    
    ui.setLabelString( self.rootItems["hasTxt"], gameConfig.strings:godSoulTempleLevel(self.soulType,self.soulConfig.limit), 13)
    self.rootItems["hasTxtValue"]:setString(self.soulConfig.limit)

end

function godSoulTempleCuishen.refreshStarNode(self)
	self.rootItems["midnode"]:removeAllChildrenWithCleanup(true)
	self.bgNode, self.bgItems = CCBReaderLoad("shenhundian/"..self.soulConfig.picture_ccb, nil, true, self.soulConfig.picture_ccb)
	self.rootItems["midnode"]:addChild(self.bgNode)
end


function godSoulTempleCuishen.runStarAction(self, node,actionType)
	
   if node then
   	    print("runStarAction----")
        local name = "UIEffect/lianhun/lianhun_xunhuan"
        if actionType == "xunhuan" then
            name = "UIEffect/lianhun/lianhun_xunhuan"
        elseif actionType == "dianliang" then
			name = "UIEffect/lianhun/lianhun_dianliang"
		elseif actionType == "change" then
			name = "UIEffect/lianhun/lianhun_qiehuan"
        end 	

		local ccb,items = CCBReaderLoad(name, nil, true, actionType)
        node:addChild(ccb)
        
        if actionType == "dianliang" or name == "change" then
        	local animationManager2 = getAnimationManager(items)
    		animationManager2:setAnimationCompletedCallback(function()
	        	ccb:removeAllChildrenWithCleanup(true)
	        	self:runStarAction(node,"xunhuan")
	        end)
    	end
   end	
end


function godSoulTempleCuishen.changeNext(self)
    gameTouch:clickprofbytime(2)
	 --加星
	for i = 1, self.soulConfig.number do
		self:runStarAction(self.bgItems["starNode"..i],"change")
	end

	self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5),CCCallFunc:create(function()
			self.beforestatus = self.soulStatus
			self.beforestar = self.soulStar
			self.beforestarnum = self.soulConfig.number

			self:refreshStarNode()
			self:refreshStar()
			self:refreshDesc()
        end)))
end


function godSoulTempleCuishen.refreshStar(self,number,soulStar)
    --最后一颗星点亮
    if number and soulStar then
        for i=1,number do
        	if i == soulStar then
			    self.bgItems["starNode"..i]:removeAllChildrenWithCleanup(true)
				local _starNode, _starItems = CCBReaderLoad("shenhundian/shenhundian_star", nil, true, "shenhundian_star")
				self.bgItems["starNode"..i]:addChild(_starNode)
				print("refreshStar",i,refreshStar)
				setSpriteFrameByName(_starItems["starSprite"], "xingxing_cuishen")
				setSpriteFrameByName(_starItems["star_a"], "xingxing_cuishen")
				setSpriteFrameByName(_starItems["star_b"], "xingxing_cuishen")

				local soulConfig =  gamedata.config.shenhundian_cuishen[self.soulType][tostring(self.soulStatus - 1)]
                _starItems["nameTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status2", soulConfig["attr"..i]).."+")
                if soulConfig["method"..i] == "value" then
                    _starItems["statusTxt"]:setString(soulConfig["value"..i])
                elseif soulConfig["method"..i] == "percent" then
                    _starItems["statusTxt"]:setString((soulConfig["value"..i] * 100).."%")
                end

		    	self:runStarAction(self.bgItems["starNode"..i],"dianliang")

		  		self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5),CCCallFunc:create(function()
		  			self:changeNext()
		        end)))

		    	
        	end	
        end
    	return
    end	

    --加星
	for i = 1, self.soulConfig.number do
		self.bgItems["starNode"..i]:removeAllChildrenWithCleanup(true)
		local _starNode, _starItems = CCBReaderLoad("shenhundian/shenhundian_star", nil, true, "shenhundian_star")
		self.bgItems["starNode"..i]:addChild(_starNode)

		print("refreshStar",i,self.soulStar,self.beforestar)
		if i <= self.soulStar then
			setSpriteFrameByName(_starItems["starSprite"], "xingxing_cuishen")
			setSpriteFrameByName(_starItems["star_a"], "xingxing_cuishen")
			setSpriteFrameByName(_starItems["star_b"], "xingxing_cuishen")

 			if (i == self.soulStar and self.levelUp) then
 				print("runStarAction_dianliang",i)
            	self:runStarAction(self.bgItems["starNode"..i],"dianliang")
            	self.beforestar = self.soulStar
            else
            	print("runStarAction_xunhuan",i)
            	self:runStarAction(self.bgItems["starNode"..i],"xunhuan")
			end	
			
		else
			setSpriteFrameByName(_starItems["starSprite"], "xingxing_hui")
			setSpriteFrameByName(_starItems["star_a"], "xingxing_hui")
			setSpriteFrameByName(_starItems["star_b"], "xingxing_hui")
		end

		_starItems["nameTxt"]:setString(gameConfig.strings:string_common("godSoulTemple", "status2", self.soulConfig["attr"..i]).."+")

		if self.soulConfig["method"..i] == "value" then
			_starItems["statusTxt"]:setString(self.soulConfig["value"..i])
		elseif self.soulConfig["method"..i] == "percent" then
			_starItems["statusTxt"]:setString((self.soulConfig["value"..i] * 100).."%")
		end
	end
end

function godSoulTempleCuishen.refreshDesc(self)
	local _str1 = gameConfig.strings:string_common("godSoulTemple", "refineSoule", 8)
	local _str2 = gameConfig.strings:string_common("godSoulTemple", "refineSoule", 14)

    if self.soulType == "44" then
        ui.setLabelString(self.rootItems["descTxt"], _str1.."23".._str2, 14)
    else
        ui.setLabelString(self.rootItems["descTxt"], _str1..self.soulType.._str2, 14)
    end
end

function godSoulTempleCuishen.refreshExpNode(self,expType)
	local _percent = 0

	if self.soulStar < self.soulConfig.number then
		if self.soulExp < self.soulConfig["experience"..(self.soulStar + 1)] then
			ui.setLabelString(self.rootItems["expTxt"], self.soulExp.."/"..self.soulConfig["experience"..(self.soulStar + 1)], 14)
			_percent = math.ceil(self.soulExp / self.soulConfig["experience"..(self.soulStar + 1)] * 100)
		else
			ui.setLabelString(self.rootItems["expTxt"], "max", 14)
			_percent = 100
		end
	else
		ui.setLabelString(self.rootItems["expTxt"], "max", 14)
		_percent = 100
	end

	 print("expType:"..expType)
    if expType ==1 then
        local pronum = _percent - self.befroePresent
        print("before:"..self.befroePresent.." current:".._percent)
        if pronum > 0 and self.isclickOkBtn then
        	self.isclickOkBtn = false
    	    local expTo = CCProgressFromTo:create(0.5,self.befroePresent,_percent)
    	    self.rootItems.progress:runAction(expTo)
    	    self.rootItems.progress2:setPercentage(_percent)

    	elseif _percent == 0 and self.isclickOkBtn  then  
    	    self.isclickOkBtn = false
    	    local expTo = CCProgressFromTo:create(0.5,self.befroePresent,100)
    	    self.rootItems.progress2:setPercentage(100)

    	    self.rootItems.progress:runAction(expTo)
 			self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.6),CCCallFunc:create(function()
                 self.rootItems.progress:setPercentage(_percent)
                 self.rootItems.progress2:setPercentage(_percent)

            end)))
        else
        	self.rootItems.progress:setPercentage(_percent)
        	self.rootItems.progress2:setPercentage(_percent)
        end	
		self.befroePresent = _percent
    else
		self.rootItems.progress2:setPercentage(_percent)
		self:btnStatusChangeByLevel()
		print("refreshExpNode :exp change")
    end	

end



return godSoulTempleCuishen