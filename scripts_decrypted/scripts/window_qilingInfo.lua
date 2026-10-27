--
-- Author: songyibo
-- Date: 2021-03-18 15:09:06
--
local qilingInfo = {
    rootNode = nil,
    rootItems = nil,
    data = {},

}

function qilingInfo.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_qilinginfo", nil, true, "tc_qiilinginfo")
    self.touchPriority = touchPriority

    self.opt = data.opt
    self.iid = data.iid
    self.cid = data.cid
    self:checkQilingNew()
	self:reload()
    return self.rootNode
end

function qilingInfo.checkQilingNew(self)
    local newQiling = getNewQilingFromSqlite()
    if self.iid and newQiling[self.iid] then
        saveNewQilingToSqlite({{iid = self.iid,opt = 0}})
    end
end

function qilingInfo.initNode(self)
    self.rootItems.intensifyNode:setVisible(false)
    self.rootItems.changeNode:setVisible(false)
    self.rootItems.unloadNode:setVisible(false)
    self.rootItems.lockBtnNode:setVisible(false)
    self.rootItems.unlockBtnNode:setVisible(false)
    self.rootItems.inlayNode:setVisible(false)
    
    local lockBtnNodeName = self.data.lock == 1 and "unlockBtnNode" or "lockBtnNode"
    local showButtons = {}
    --1 器灵背包界面
    if self.opt == 1 then
        if self.data.ison == 1 then
            showButtons = {"intensifyNode","unloadNode",lockBtnNodeName}
        else
            showButtons = {"intensifyNode","inlayNode",lockBtnNodeName}
        end
    --2 专属神器镶嵌界面
    elseif self.opt == 2 then
        showButtons = {"intensifyNode","changeNode","unloadNode",lockBtnNodeName}
    --3 镶嵌弹窗界面
    elseif self.opt == 3 then
        showButtons = {}
    --4 熔炼选择界面
    elseif self.opt == 4 then
        showButtons = {}
    --5 器灵副本掉落展示界面
    elseif self.opt == 5 then
        showButtons = {}
        self.rootItems.lockNode:setVisible(false)
    end

    self.showHight = 650
    if #showButtons == 0 then
        self.rootItems.buttonNode:setVisible(false)
        self.showHight = 760
        self.rootItems.bg = tolua.cast(self.rootItems.bg, "CCScale9Sprite")
        self.rootItems.bg:setPreferredSize(CCSizeMake(800,self.showHight))
    else

        local pos = {0}
        if #showButtons == 1 then
            pos = {0}
        elseif #showButtons == 2 then
            pos = {-150,150}
        elseif #showButtons == 3 then
            pos = {-230,0,230}
        elseif #showButtons == 4 then
            pos = {-310,-110,110,310}
        end

        for i,v in ipairs(showButtons) do
            self.rootItems[v]:setPositionX(pos[i])
            self.rootItems[v]:setVisible(true)
        end
    end

	self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("qilingInfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

	self.rootItems.ruleButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("exclusiveTipPop",{string = gameConfig.strings:string_common("exclusiveArtifactNew",17),method = "left"})
    end, CCControlEventTouchUpInside)
    self.rootItems.ruleButton:setSwallowsTouch(true)
    self.rootItems.ruleButton:setTouchPriority(self.touchPriority)

    self.rootItems.intensifyBtn:addHandleOfControlEvent(function()
    	print("强化")
        gameWindows:openWindow("qilingIntensify",{data = self.data})
        gameWindows:closeWindowDirect("qilingInfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.intensifyBtn:setSwallowsTouch(true)
    self.rootItems.intensifyBtn:setTouchPriority(self.touchPriority)

    self.rootItems.changeBtn:addHandleOfControlEvent(function()
        
    	print("更换")
        local generalIid = self.data.generalIid
        local location = self.data.location
        --打开器灵选择
        local cb = function (qiLingData)
            UIRequest({type=8104,generalIid = generalIid,pos = location,qiLingIid = qiLingData.iid})
        end
        gameWindows:openWindow("qilingSelect",{type = self.data.location,filterList = {self.data}},cb)
        gameWindows:closeWindowDirect("qilingInfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.changeBtn:setSwallowsTouch(true)
    self.rootItems.changeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.unloadBtn:addHandleOfControlEvent(function()
    	print("卸下")
        UIRequest({type=8104,generalIid = self.data.generalIid,pos = self.data.location,qiLingIid = 0})
        gameWindows:closeWindowDirect("qilingInfo")
    end, CCControlEventTouchUpInside)
    self.rootItems.unloadBtn:setSwallowsTouch(true)
    self.rootItems.unloadBtn:setTouchPriority(self.touchPriority)

    local exclusives = GameScene.layers["exclusiveArtifact"].module:makeData()
    local isCanInlay = (table.getTableLength(exclusives) > 0)
    if not isCanInlay then
        ui.addGray("CCControlButton",self.rootItems.inlayBtn)
    else
        ui.removeGray("CCControlButton",self.rootItems.inlayBtn)
    end

    self.rootItems.inlayBtn:addHandleOfControlEvent(function()
        print("镶嵌")
        if isCanInlay then
            GameScene:shiftLayerById(617)
        else
            runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",27)})
        end
        
    end, CCControlEventTouchUpInside)
    self.rootItems.inlayBtn:setSwallowsTouch(true)
    self.rootItems.inlayBtn:setTouchPriority(self.touchPriority)

    self.rootItems.lockBtn:addHandleOfControlEvent(function()
    	print("锁定")
        UIRequest({type=8107,qiLingIid = self.data.iid,lock = 1})
    end, CCControlEventTouchUpInside)
    self.rootItems.lockBtn:setSwallowsTouch(true)
    self.rootItems.lockBtn:setTouchPriority(self.touchPriority)

    self.rootItems.unlockBtn:addHandleOfControlEvent(function()
        print("解锁")
        UIRequest({type=8107,qiLingIid = self.data.iid,lock = 0})
    end, CCControlEventTouchUpInside)
    self.rootItems.unlockBtn:setSwallowsTouch(true)
    self.rootItems.unlockBtn:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.intensifyLab,nil,19)
    ui.setLabelString(self.rootItems.changeLab,nil,19)
    ui.setLabelString(self.rootItems.unloadLab,nil,19)
    ui.setLabelString(self.rootItems.lockLab,nil,19)
    ui.setLabelString(self.rootItems.unlockLab,nil,19)
    ui.setLabelString(self.rootItems.inlayLab,nil,19)

    self.rootItems.container:removeAllChildrenWithCleanup(true)
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.rootItems.scrollnode:setViewSize(CCSizeMake(800,self.showHight))
    self.scrollNode, self.scrollItems = CCBReaderLoad("zhuanshushenqi/cell_qilinginfo", nil, true, "cell_qilinginfo")
    self.rootItems.container:addChild(self.scrollNode)

end

function qilingInfo.reload(self)

    --器灵展示详情
    if self.opt == 5 then
        self.data = {
            iid                 = 0,
            cid                 = self.cid,
            level               = 0,
            successRate         = 0,
            lock                = 0,
            qiLingAttrKey1      = 0,
            qiLingAttrLevel1    = 0,
            qiLingAttrValue1    = 0,
            qiLingAttrKey2      = 0,
            qiLingAttrLevel2    = 0,
            qiLingAttrValue2    = 0,
            qiLingAttrKey3      = 0,
            qiLingAttrLevel3    = 0,
            qiLingAttrValue3    = 0,
            qiLingAttrKey4      = 0,
            qiLingAttrLevel4    = 0,
            qiLingAttrValue4    = 0,
            generalIid          = nil,
            ison                = nil,
            exclusiveCid        = nil,
        }
    else
        local qilingData = GameScene.layers["qiLingBag"].module.data[self.iid]
        self.data = qilingData
    end

    printT(self.data,"qilingInfo")

    self:initNode()
    local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(self.data.cid)]
    local intensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(self.data.level)]

   	self.rootItems.name:setString(qilingConfig.name)
    if qilingConfig.quality and qilingConfig.quality >= 7 then
        ui.setLabelString(self.rootItems.name,nil, 213)
    else
        ui.setLabelString(self.rootItems.name,nil,((qilingConfig.quality and qilingConfig.quality ~= 0) and qilingConfig.quality or 1)*2-1)
    end

   	ui.setNewIcon(self.rootItems, {cid = self.data.cid, num = self.data.level > 0 and "+"..self.data.level or ""})
    self.rootItems["i_button"]:addHandleOfControlEvent(function()
        gameWindows:openWindow("dropTips",{cid = self.data.cid},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button"]:setSwallowsTouch(true)
    self.rootItems["i_button"]:setTouchPriority(self.touchPriority)


   	self.rootItems.lockSp:setVisible(self.data.lock == 1)
   	self.rootItems.unlockSp:setVisible(self.data.lock == 0)

    local attrValue = qilingConfig.method == "percent" and qilingConfig.value * 100 or qilingConfig.value
   	self.scrollItems.normalAttr:setString(gameConfig.strings:attributeValue2(qilingConfig.attribute,qilingConfig.method,attrValue))
    
    if self.data.level > 0 then
        local intensifyValue = qilingConfig.method == "percent" and intensifyConfig.value * 100 or intensifyConfig.value
        self.scrollItems.intensifyAttr:setString(string.format(gameConfig.strings:string_common("exclusiveArtifactNew",1), intensifyValue..(qilingConfig.method == "percent" and "%" or "")))
    else
        self.scrollItems.intensifyAttr:setString("")
    end

    if self.opt == 5 then
        ui.setLabelString(self.rootItems.inlaydesc,"",1031)
    else
        if self.data.exclusiveCid then
            ui.setLabelString(self.rootItems.inlaydesc,gameConfig.strings:string_common("exclusiveArtifactNew",26)..gamedata.config.exclusive[tostring(self.data.exclusiveCid)].name, 1031,36)
        else
            ui.setLabelString(self.rootItems.inlaydesc,gameConfig.strings:string_common("exclusiveArtifactNew",26).."无",1031,36)
        end
    end

   	--随机属性
   	local randomAttrInfo = self.getRandomAttrInfo(self.data)
   	local fixedH_randomAttr = 0
   	local lineH  = 40
   	for i=1,4 do
        if self.opt == 5 then
            self.scrollItems["r_attr_tipnode"..i]:setVisible(false)
            if qilingConfig.random_attribute_number >= i then
                self.scrollItems["r_attr_name"..i]:setString("？？？？？？？？？？？？？？？？？")
                randomAttrInfo.lineNum = qilingConfig.random_attribute_number * 2
            else
                self.scrollItems["r_attr_name"..i]:setString("")
            end
        else
            if randomAttrInfo[i] then
                self.scrollItems["r_attr_node"..i]:setVisible(true)
                self.scrollItems["r_attr_name"..i]:setString(randomAttrInfo[i].name)
                ui.createRichLabel({
                    {fontID = 1031,content = randomAttrInfo[i].desc[1]},
                    {fontID = 1032,content = randomAttrInfo[i].desc[2]},
                },self.scrollItems["r_attr_desc"..i],false,{min_line_dis = 2})
                self.scrollItems["r_attr_node"..i]:setPositionY(-50-fixedH_randomAttr)
                fixedH_randomAttr = fixedH_randomAttr + randomAttrInfo[i].lineNum * lineH

                self.scrollItems["r_attr_tipnode"..i]:setVisible(randomAttrInfo[i].interval_describe ~= "")
                self.scrollItems["r_attr_button"..i]:addHandleOfControlEvent(function()
                    print("r_attr_button"..i)
                    gameWindows:openWindow("exclusiveTipPop",{string = randomAttrInfo[i].interval_describe,method = "right"})
                end, CCControlEventTouchUpInside)
                self.scrollItems["r_attr_button"..i]:setSwallowsTouch(true)
                self.scrollItems["r_attr_button"..i]:setTouchPriority(self.touchPriority)

            else
                self.scrollItems["r_attr_node"..i]:setVisible(false)
            end
        end
   		
   	end
   	printT(randomAttrInfo,"randomAttrInfo")

    --套装属性
    local suitInfos = self.getSuitAttrInfo(self.data)

    local fixedH_suit = 0
    for i=1,3 do
        ui.setLabelString(self.scrollItems["suit_des"..i],suitInfos[i].desc,suitInfos[i].active == 1 and 1031 or 1033)
        ui.setLabelString(self.scrollItems["suit_name"..i],nil,suitInfos[i].active == 1 and 1031 or 1033)
    	self.scrollItems["suit_node"..i]:setPositionY(-70 - fixedH_suit)
    	fixedH_suit = fixedH_suit + suitInfos[i].lineNum * lineH
    end

   	local offy_AttrInfo = (8 - randomAttrInfo.lineNum)*lineH
   	local offy_Suit = (6 - suitInfos.lineNum)*lineH

   	self.scrollItems.suitNode:setPositionY(self.scrollItems.suitNode:getPositionY() + offy_AttrInfo)
   	local containerH = 900 - offy_AttrInfo - offy_Suit
    self.rootItems.container:setContentSize(CCSizeMake(800, containerH))
    self.scrollNode:setPosition(400,containerH)
    self.rootItems.container:setPositionY(self.showHight - containerH)
end

function qilingInfo.getRandomAttrInfo(data)
	local lineNum = 0
	local info = {}
	for i=1,4 do
		local config = gamedata.config.exclusive_device_spirit_random_properties[tostring(data["qiLingAttrKey"..i])]
		if config then
			info[i] = table.copy(config)
            local randomAttrLevel = math.min(data["qiLingAttrLevel"..i],info[i].interval_limit)
            info[i].randomAttrLevel = randomAttrLevel
			if config.type == 1 then
				info[i].lineNum = 1
				lineNum = lineNum + 1
                if not gameConfig.strings.attr_type[config.attribute] then
                    printT(config,"属性不存在")
                end
				info[i].name = gameConfig.strings.attr_type[config.attribute].."："
				info[i].desc = {}

                if randomAttrLevel > 0 then
                    local intensifyValue = 0
                    local index = 1
                    while index <= randomAttrLevel do
                        intensifyValue = intensifyValue + (config["intensify"..index] or 0)
                        index = index + 1
                    end
                    info[i].desc[1] = "+"..(data["qiLingAttrValue"..i] - intensifyValue)..(config.method == "percent" and "%" or "")
                    info[i].desc[2] = "  "..config["instructions"..randomAttrLevel]
                else
                    info[i].desc[1] = "+"..data["qiLingAttrValue"..i]..(config.method == "percent" and "%" or "")
                    info[i].desc[2] = ""
                end
			elseif config.type == 2 then
				local breakskillConfig = gamedata.config.breakskill[tostring(config.breakskill)]
				info[i].lineNum = breakskillConfig.desc_param
				lineNum = lineNum + breakskillConfig.desc_param

				info[i].name = breakskillConfig.name.."："
				info[i].desc = {}
				info[i].desc[1] = breakskillConfig.desc
				if randomAttrLevel > 0 then
					info[i].desc[2] = "  "..config["instructions"..randomAttrLevel]
                else
                    info[i].desc[2] = ""
				end
			end
		end
	end
	info.lineNum = lineNum
	return info
end

function qilingInfo.getSuitAttrInfo(data)
	--套装属性
    local lineNum = 0
    local suitInfos = {}
    local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(data.cid)]
    for i=1,table.getTableLength(gamedata.config.exclusive_device_spirit_suit) do
    	local suitConfig = gamedata.config.exclusive_device_spirit_suit[tostring(i)]
    	if suitConfig.suit == qilingConfig.suit then
    		local breakskillConfig = gamedata.config.breakskill[tostring(suitConfig.suit_skill)]
    		lineNum = lineNum + breakskillConfig.desc_param
            --判断是否激活套装
            local suitActiviteStatus = 0
            for k,v in pairs(GameScene.layers["slotsInfo"].module.exclusiveArtifactData or {}) do
                if data.generalIid and data.generalIid == v.generalIid then
                    for m=1,3 do
                        if v["suitId"..m] == suitConfig.id then
                            suitActiviteStatus = 1
                            break
                        end
                    end
                end
            end
            table.insert(suitInfos,
                {
                    suitNum = suitConfig.activate_suit,
                    active = suitActiviteStatus,
                    name = suitConfig.suit_describe,
                    desc = breakskillConfig.desc,
                    lineNum = breakskillConfig.desc_param
                })
    	end
    end

    table.sort(suitInfos,function ( a,b )
    	return a.suitNum < b.suitNum
    end)

    suitInfos.lineNum = lineNum
    return suitInfos
end

function qilingInfo.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.data = {}
end

return qilingInfo  �C  