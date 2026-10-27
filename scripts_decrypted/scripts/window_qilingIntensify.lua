--
-- Author: songyibo
-- Date: 2021-03-19 10:28:15
--

local qilingIntensify = {
    rootNode = nil,
    rootItems = nil,
    data = {},
    consumePropCid = 192091,
    allQilingInfos = {},
    selectindex = 0,
}

function qilingIntensify.open(self,touchPriority,data,callback)
    printT(data,"qilingIntensify")
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_qilingup", nil, true, "tc_qilingup")
    self.touchPriority = touchPriority

    self.qilingIid = data.data.iid
    self.data = table.copy(data.data)
    self:initNode()
	self:reload()
    return self.rootNode
end

function qilingIntensify.makeExclusiveArtifactQilingInfos(self)
	local allExclusiveArtifactData = GameScene.layers["slotsInfo"].module.exclusiveArtifactData or {}
	local infos = {}
	if self.data.generalIid and self.data.generalIid > 0 and allExclusiveArtifactData[self.data.generalIid] then
		local exclusiveArtifactData = allExclusiveArtifactData[self.data.generalIid]
		for i=1,6 do
			local qilingIid = exclusiveArtifactData["inlayId"..i]
			if qilingIid > 0 then
				infos[i] = GameScene.layers["qiLingBag"].module:getQilingData(qilingIid)
			end
		end
	end
	self.allQilingInfos = infos
    self.data = GameScene.layers["qiLingBag"].module:getQilingData(self.qilingIid)
end

function qilingIntensify.initNode(self)

	self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("qilingIntensify")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

	self.rootItems.ruleButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("exclusiveTipPop",{string = gameConfig.strings:string_common("exclusiveArtifactNew",17),method = "left"})
    end, CCControlEventTouchUpInside)
    self.rootItems.ruleButton:setSwallowsTouch(true)
    self.rootItems.ruleButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab,nil, 19)
    self.rootItems.doBtn:addHandleOfControlEvent(function()
        print("强化")
    end, CCControlEventTouchUpInside)
    self.rootItems.doBtn:setSwallowsTouch(true)
    self.rootItems.doBtn:setTouchPriority(self.touchPriority)

    self.infoNode, self.infoItems = CCBReaderLoad("zhuanshushenqi/cell_qilinginfo", nil, true, "cell_qilinginfo")
    self.infoItems.suitNode:setVisible(false)
    self.rootItems.infoNode:addChild(self.infoNode)
    ui.setNewIcon(self.rootItems, {cid = self.consumePropCid},1)

    self.rootItems["i_button_1"]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(self.consumePropCid)
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button_1"]:setSwallowsTouch(true)
    self.rootItems["i_button_1"]:setTouchPriority(self.touchPriority)

    if self.data.generalIid and self.data.generalIid > 0 then
    	self.rootItems.changeNode:setVisible(true)
    	local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(self.data.cid)]
	    self.selectindex = qilingConfig.location

	    for i=1,6 do
	    	self.rootItems["changeBtn"..i]:addHandleOfControlEvent(function()
		    	if self.allQilingInfos[i] then
		    		self.selectindex = i
		    		self:reload()
		    	else
		    		runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",3) })
		    	end
		    end, CCControlEventTouchUpInside)
		    self.rootItems["changeBtn"..i]:setSwallowsTouch(true)
		    self.rootItems["changeBtn"..i]:setTouchPriority(self.touchPriority)
	    end
    else
    	self.rootItems.changeNode:setVisible(false)
    end
end

function qilingIntensify.requestPropNum(self)
	UIRequest({type = 12001, order = 33021, cids = {self.consumePropCid}})
end

function qilingIntensify.reloadPropNum(self,t)
	local haveNum = t[tostring(self.consumePropCid)] or 0
	local qinglingData = self.allQilingInfos[self.selectindex] or self.data

	local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(qinglingData.cid)]
	local nextIntensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(qinglingData.level + 1)]

	--满级
	if not nextIntensifyConfig then
		ui.setLabelString(self.rootItems["i_num_1"],haveNum.."/0", 13)
		ui.addGray("CCControlButton",self.rootItems.doBtn)
		self.rootItems.doBtn:addHandleOfControlEvent(function()
	        runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",4) })
	    end, CCControlEventTouchUpInside)
		self.rootItems.doBtn:setSwallowsTouch(true)
	    self.rootItems.doBtn:setTouchPriority(self.touchPriority)
		return
	end

    local consumeProp = gamedata.getIDandNUMs(nextIntensifyConfig.consumption)[1]
    if consumeProp.num > haveNum then
        ui.addGray("CCControlButton",self.rootItems.doBtn)
    else
        ui.removeGray("CCControlButton",self.rootItems.doBtn)
    end
	ui.setLabelString(self.rootItems["i_num_1"],haveNum.."/"..consumeProp.num, consumeProp.num > haveNum and 24 or 13)
	self.rootItems.doBtn:addHandleOfControlEvent(function()
        if consumeProp.num > haveNum then
        	shortPropById(self.consumePropCid)
        else
        	gameTouch:clickprofbytime(1)
        	UIRequest({type = 8106, qiLingIid = qinglingData.iid,spend = consumeProp})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doBtn:setSwallowsTouch(true)
    self.rootItems.doBtn:setTouchPriority(self.touchPriority)
end

function qilingIntensify.intensifyCallback(self,t)
    gameTouch:clickprofbytime(1.5)
    if t.islevelup then
        ui.addEffectAutoRemove(self.rootItems.animationnode,"UIEffect/zhuanshushenqi/qianghuachenggong")
    else
        local node,items = ui.addEffectAutoRemove(self.rootItems.animationnode,"UIEffect/zhuanshushenqi/qianghuashibai")
        ui.setLabelString(items.lab1,nil, 19)
        ui.setLabelString(items.lab2,t.data.successRate.."%", 26,50)
    end
    self:reload()
end

function qilingIntensify.reload(self)

    self:makeExclusiveArtifactQilingInfos()
    local data = self.allQilingInfos[self.selectindex] or self.data
	local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(data.cid)]
	local nextIntensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(data.level + 1)]
	
    local intensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(data.level)]

   	self.rootItems.name:setString(qilingConfig.name)
    if qilingConfig.quality and qilingConfig.quality >= 7 then
        ui.setLabelString(self.rootItems.name,nil, 213)
    else
        ui.setLabelString(self.rootItems.name,nil,((qilingConfig.quality and qilingConfig.quality ~= 0) and qilingConfig.quality or 1)*2-1)
    end

    if data.exclusiveCid then
            ui.setLabelString(self.rootItems.inlaydesc,gameConfig.strings:string_common("exclusiveArtifactNew",26)..gamedata.config.exclusive[tostring(data.exclusiveCid)].name, 1031,36)
        else
            ui.setLabelString(self.rootItems.inlaydesc,gameConfig.strings:string_common("exclusiveArtifactNew",26).."无",1031,36)
        end

   	ui.setNewIcon(self.rootItems, {cid = data.cid, num = data.level > 0 and "+"..data.level or ""})
   	self.rootItems.lockSp:setVisible(data.lock == 1)
   	self.rootItems.unlockSp:setVisible(data.lock == 0)

    local attrValue = qilingConfig.method == "percent" and qilingConfig.value * 100 or qilingConfig.value
    self.infoItems.normalAttr:setString(gameConfig.strings:attributeValue2(qilingConfig.attribute,qilingConfig.method,attrValue))
    
    if data.level > 0 then
        local intensifyValue = qilingConfig.method == "percent" and intensifyConfig.value * 100 or intensifyConfig.value
        self.infoItems.intensifyAttr:setString(string.format(gameConfig.strings:string_common("exclusiveArtifactNew",1), intensifyValue..(qilingConfig.method == "percent" and "%" or "")))
    else
        self.infoItems.intensifyAttr:setString("")
    end
    

   	--随机属性
   	local randomAttrInfo = gameWindows.windows["qilingInfo"].module.getRandomAttrInfo(data)
   	local fixedH_randomAttr = 0
   	local lineH  = 40
   	for i=1,4 do
   		if randomAttrInfo[i] then
            self.infoItems["r_attr_node"..i]:setVisible(true)
   			self.infoItems["r_attr_name"..i]:setString(randomAttrInfo[i].name)
   			ui.createRichLabel({
	            {fontID = 1031,content = randomAttrInfo[i].desc[1]},
	            {fontID = 1032,content = randomAttrInfo[i].desc[2]},
	        },self.infoItems["r_attr_desc"..i],false,{min_line_dis = 2})
   			self.infoItems["r_attr_node"..i]:setPositionY(-50-fixedH_randomAttr)
   			fixedH_randomAttr = fixedH_randomAttr + randomAttrInfo[i].lineNum * lineH

            self.infoItems["r_attr_tipnode"..i]:setVisible(randomAttrInfo[i].interval_describe ~= "")
            self.infoItems["r_attr_button"..i]:addHandleOfControlEvent(function()
                print("r_attr_button"..i)
                gameWindows:openWindow("exclusiveTipPop",{string = randomAttrInfo[i].interval_describe,method = "right"})
            end, CCControlEventTouchUpInside)
            self.infoItems["r_attr_button"..i]:setSwallowsTouch(true)
            self.infoItems["r_attr_button"..i]:setTouchPriority(self.touchPriority)

   		else
   			self.infoItems["r_attr_node"..i]:setVisible(false)
   		end
   	end
   	printT(randomAttrInfo,"randomAttrInfo")
   	--强化按钮
   	self:requestPropNum()
    if not nextIntensifyConfig then
        --成功率
        self.rootItems.successRate:setString("")
    else
        --成功率
        self.rootItems.successRate:setString(string.format(gameConfig.strings:string_common("exclusiveArtifactNew",2), data.successRate))
    end
   	for i=1,6 do
   		setSpriteFrameByName(self.rootItems["changeSpr"..i],i == self.selectindex and "zhuanshushenqi_"..i.."_h" or "zhuanshushenqi_"..i)
   		if self.allQilingInfos[i] then
   			ui.removeGray("CCSprite",self.rootItems["changeSpr"..i])
   		else
   			ui.addGray("CCSprite",self.rootItems["changeSpr"..i])
   		end
   	end
end

function qilingIntensify.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.data = {}
    self.allQilingInfos = {}
    self.selectindex = 0
end

return qilingIntensify {)  