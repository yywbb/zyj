--
-- Author: songyibo
-- Date: 2021-03-22 11:35:25
--

local exclusiveArtifact = {
    rootNode = nil,
    rootItems = nil,
    data = {},

}

function exclusiveArtifact.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_zhuanshushenqiinfo", nil, true, "tc_zhuanshushenqiinfo")
    self.touchPriority = touchPriority
    printT(data,"exclusiveArtifact")
    self.opt = data.opt --opt 1 正常 opt 2 图鉴 3 其他人
    self.sid = data.sid
    self.general = data.general
	self:initNode()
	self:reload()
    return self.rootNode
end

function exclusiveArtifact.initNode(self)
	self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("exclusiveArtifact")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.scrollNode, self.scrollItems = CCBReaderLoad("zhuanshushenqi/cell_zhuanshushenqiinfo", nil, true, "cell_zhuanshushenqiinfo")
    self.rootItems.container:addChild(self.scrollNode)
    
end

function exclusiveArtifact.reload(self)
    print("exclusiveArtifact_reload")

    local exclusiveArtifactData = nil
    local qinglingDatas = {}
    self.active = false
    if self.opt == 1 or self.opt == 11 then
        exclusiveArtifactData = GameScene.layers["slotsInfo"].module.exclusiveArtifactData[self.general.iid]
        qinglingDatas = GameScene.layers["qiLingBag"].module.data
    elseif self.opt == 3 then
        exclusiveArtifactData = GameScene.templayers["other_slotinfo"].exclusiveArtifactData[self.general.iid]
        qinglingDatas = GameScene.templayers["other_slotinfo"].exclusiveArtifactQilingData
    end

    if exclusiveArtifactData then
        self.active = true
    end

    print("self.active",self.active)
    if self.active then
        self.data = table.copy(exclusiveArtifactData)
        self.data.general = self.general
    else
        --未激活
        self.data = {
            generalIid      = 0,
            level           = 0,
            inlayId1        = 0,
            inlayId2        = 0,
            inlayId3        = 0,
            inlayId4        = 0,
            inlayId5        = 0,
            inlayId6        = 0,
            suitId1         = 0,
            suitId2         = 0,
            suitId3         = 0,
            intensify_level = 0,
            baptism_level   = 0,
            general         = self.general,
            cid             = gamedata.config.general[tostring(self.general.cid)].exclusive,
        }
    end
    
    printT(self.data.general)
    if (not self.active) and (self.opt == 1) then
        --请求挑战次数
        UIRequest({type = 8109, generalIid = self.data.general.iid})
        self:reloadHint()
    end

    --显示样式
    self:initShowType()

    local generalConfig = gamedata.config.general[tostring(self.data.general.illusionGeneralCid or self.data.general.cid)]
  	local exclusiveConfig = gamedata.config.exclusive[tostring(generalConfig.exclusive)]
  	
  	--名
    self.rootItems.title:setString(generalConfig.name..gameConfig.strings:string_common("exclusiveArtifactNew",10))
    self.rootItems.name:setString(exclusiveConfig.name..(self.data.intensify_level > 0 and "+"..self.data.intensify_level or ""))

    --spine
    self.rootItems.skeleton:removeAllChildrenWithCleanup(true)
    local skeleton = ui.createExclusiveSkeleton(exclusiveConfig.animation,self.opt == 2 and 1.5 or 1)
    if skeleton then
        skeleton:setAnimation("stand",true,0)
        self.rootItems.skeleton:addChild(skeleton)
        if self.opt ~= 2 then
            if not self.active then
                ui.addGray("CCNode",skeleton)
            elseif generalConfig.quality < 7 then
                ui.addGray("CCNode",skeleton)
            end
        end
    end

    --器灵
    if self.opt == 2 then
    	self.rootItems.qilingNode:setVisible(false)
    else
    	self.rootItems.qilingNode:setVisible(true)
    	for i=1,6 do
    		if self.data["inlayId"..i] and self.data["inlayId"..i] > 0 and qinglingDatas[self.data["inlayId"..i]] then
   				local qilingData = qinglingDatas[self.data["inlayId"..i]]
   				local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(qilingData.cid)]
   				setSpriteFrameByName(self.rootItems["qiling"..i],qilingConfig.icon)
   			else
   				setSpriteFrameByName(self.rootItems["qiling"..i],gameConfig.images.alpha)
   			end
    	end
    end

    if self.opt == 2 then
        self.scrollItems.levelNode:setVisible(true)
        self.scrollItems.attrNode:setPositionY(-180)
        self.scrollItems.normalAttr:setAnchorPoint(ccp(0.5,0.5))
        self.scrollItems.normalAttr:setPositionX(0)
    else
        self.scrollItems.levelNode:setVisible(false)
        self.scrollItems.attrNode:setPositionY(-40)
    end

    --详情
    local basic_attr = ui.getSTRandNUMs(exclusiveConfig.attribute)[1]
    self.scrollItems.normalAttr:setString(gameConfig.strings.attr_type[basic_attr.str].." +"..basic_attr.num)

    if self.data.level > 0 then
    	local exclusiveIntensifyConfig = gamedata.config.exclusive_intensify[tostring(exclusiveConfig.intensify_type)][tostring(self.data.level)]
    	self.scrollItems.intensifyAttr:setString(string.format(gameConfig.strings:string_common("exclusiveArtifactNew",1), exclusiveIntensifyConfig.value))
    else
    	self.scrollItems.intensifyAttr:setString("")
    end

    --技能
    self.scrollItems.skillNode:setPositionY(self.scrollItems.attrNode:getPositionY() - 140)
    local lineH = 40
    local lineNum_skill = 0

   	for i=1,5 do
   		self.scrollItems["skillDescNode"..i]:setPositionY(-70 - lineNum_skill*40)
   		local skillId = exclusiveConfig["skill"..i]
   		local breakskill = gamedata.config.breakskill[tostring(skillId)]
   		self.scrollItems["skillName"..i]:setString(string.format(gameConfig.strings:string_common("exclusiveArtifactNew",8), i))
   		self.scrollItems["skillDesc"..i]:setString(breakskill.desc)

        local fontId = self.data.baptism_level >= i and 1031 or 1033
        if self.opt == 2 then
            fontId = 1031
        end
   		ui.setLabelString(self.scrollItems["skillName"..i],nil,fontId)
   		ui.setLabelString(self.scrollItems["skillDesc"..i],nil,fontId)
   		self.scrollItems["skillDesc"..i]:setDimensions(CCSizeMake(500,breakskill.desc_param * lineH))
   		lineNum_skill = lineNum_skill + breakskill.desc_param
   	end

   	print("lineNum_skill",lineNum_skill)

   	--器灵
    self.scrollItems.qilingNode:setPositionY(self.scrollItems.skillNode:getPositionY() - lineH * lineNum_skill - 90)
   	local fixedH_qiling = 0
   	for i=1,6 do
   		if self.data["inlayId"..i] and self.data["inlayId"..i] > 0 and qinglingDatas[self.data["inlayId"..i]] then

   			local qilingData = qinglingDatas[self.data["inlayId"..i]]
   			local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(qilingData.cid)]
   			--器灵名称
   			local node, items = CCBReaderLoad("zhuanshushenqi/cell_suijishuxing", nil, true, "cell_suijishuxing")
   			items.r_attr_tipnode:setVisible(false)
	        node:setPositionY(-fixedH_qiling)
	        self.scrollItems.qilingInfoNode:addChild(node)
	        items.r_attr_name:setString(gameConfig.strings.bigNum[i].."号位：")

	        local fontId = 1
	        if qilingConfig.quality and qilingConfig.quality >= 7 then
		        fontId = 213
		    else
		    	fontId = ((qilingConfig.quality and qilingConfig.quality ~= 0) and qilingConfig.quality or 1)*2-1
		    end
	        ui.createRichLabel({
	            {fontID = fontId,content = qilingConfig.name,fontSize = 32}
	        },items["r_attr_desc"],false,{min_line_dis = 2})
	        fixedH_qiling = fixedH_qiling + lineH

	        --基础属性
	        local node, items = CCBReaderLoad("zhuanshushenqi/cell_suijishuxing", nil, true, "cell_suijishuxing")
   			items.r_attr_tipnode:setVisible(false)
	        node:setPositionY(-fixedH_qiling)
	        self.scrollItems.qilingInfoNode:addChild(node)
	        items.r_attr_name:setString(gameConfig.strings:string_common("exclusiveArtifactNew",12))
	        local contents = {}

            local attrValue = qilingConfig.method == "percent" and qilingConfig.value * 100 or qilingConfig.value
	        contents[1] = {fontID = 1031,content = gameConfig.strings:attributeValue(qilingConfig.attribute,qilingConfig.method,attrValue)}
	        if qilingData.level > 0 then
	        	local intensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(qilingData.level)]
	        	contents[1].content = contents[1].content.."	"

                local intensifyValue = qilingConfig.method == "percent" and intensifyConfig.value * 100 or intensifyConfig.value
	        	contents[2] = {fontID = 1032,content = string.format(gameConfig.strings:string_common("exclusiveArtifactNew",1), intensifyValue..(qilingConfig.method == "percent" and "%" or ""))}
	        end
	        ui.createRichLabel(contents,items["r_attr_desc"],false,{min_line_dis = 2})
	        fixedH_qiling = fixedH_qiling + lineH

	        --随机属性
            local randomAttrInfo = gameWindows.windows["qilingInfo"].module.getRandomAttrInfo(qilingData)
            for j=1,4 do
            	if randomAttrInfo[j] then
            		local node, items = CCBReaderLoad("zhuanshushenqi/cell_suijishuxing", nil, true, "cell_suijishuxing")
		   			items.r_attr_tipnode:setVisible(false)
			        node:setPositionY(-fixedH_qiling)
			        self.scrollItems.qilingInfoNode:addChild(node)

			        items["r_attr_name"]:setString(randomAttrInfo[j].name)
		   			ui.createRichLabel({
			            {fontID = 1031,content = randomAttrInfo[j].desc[1]},
			            {fontID = 1032,content = randomAttrInfo[j].desc[2]},
			        },items["r_attr_desc"],false,{min_line_dis = 2})
			        fixedH_qiling = fixedH_qiling + lineH * randomAttrInfo[j].lineNum
            	end
            end
   		else
   			local node, items = CCBReaderLoad("zhuanshushenqi/cell_suijishuxing", nil, true, "cell_suijishuxing")
   			items.r_attr_tipnode:setVisible(false)
	        node:setPositionY(-fixedH_qiling)
	        self.scrollItems.qilingInfoNode:addChild(node)

	        items.r_attr_name:setString(gameConfig.strings.bigNum[i].."号位：")
	        ui.createRichLabel({
	            {fontID = 1031,content = gameConfig.strings:string_common("exclusiveArtifactNew",11)}
	        },items["r_attr_desc"],false,{min_line_dis = 2})
	        fixedH_qiling = fixedH_qiling + lineH
   		end
   	end

   	--套装
   	self.scrollItems.suitNode:setPositionY(self.scrollItems.qilingNode:getPositionY() - fixedH_qiling - 120)
   	local suitInfos = GameScene.layers["exclusiveArtifact"].module.getExclusiveArtifactSuitInfos(self.data)
    for i=1,3 do
        if suitInfos[i] then
            self.scrollItems["suit_desc"..i]:setString(suitInfos[i].suit_desc.."："..suitInfos[i].breakskill_desc)
            self.scrollItems["suit_no"..i]:setVisible(false)
        else
            self.scrollItems["suit_desc"..i]:setString("")
            self.scrollItems["suit_no"..i]:setVisible(true)
        end
    end

    --描述
    self.scrollItems.desc:setString(exclusiveConfig.describe)
    if self.opt == 2 then
        self.scrollItems.qilingNode:setVisible(false)
        self.scrollItems.suitNode:setVisible(false)
        self.scrollItems.descNode:setPositionY(self.scrollItems.qilingNode:getPositionY())
    else
        self.scrollItems.descNode:setPositionY(self.scrollItems.suitNode:getPositionY() - 330)
    end

    local containerH = -(self.scrollItems.descNode:getPositionY() - 200)
    self.rootItems.container:setContentSize(CCSizeMake(800, containerH))
    self.scrollNode:setPosition(400,containerH)
    self.rootItems.container:setPositionY(self.showHight - containerH)
end

function exclusiveArtifact.reloadHint(self)
    if not self.active then
        return
    end

    ui.sethint(self.rootItems.hint_up,self.data.general.hashint_exclusiveIntensify)
    local hint_xiangqian = false
    for k,v in pairs(self.data.general.hashint_exclusiveQiling or {}) do
        if v > 0 then
            hint_xiangqian = true
            break
        end
    end
    ui.sethint(self.rootItems.hint_xiangqian,hint_xiangqian)
end

function exclusiveArtifact.initShowType(self)

	self.showHight = 650
	if self.opt == 1 then
		self.rootItems.buttonNode:setVisible(true)

		self.showHight = self.active and 510 or 440
		self.rootItems.bg = tolua.cast(self.rootItems.bg, "CCScale9Sprite")
        self.rootItems.bg:setPreferredSize(CCSizeMake(800,self.showHight))
		self.rootItems.scrollnode:setViewSize(CCSizeMake(800,self.showHight))
        -- self.rootItems.scrollnode:setPositionY(self.rootItems.scrollnode:getPositionY() - 10)

		self.rootItems.activeNode:setVisible(not self.active)
		self.rootItems.timesNode:setVisible(not self.active)

        self.rootItems.sureNode:setVisible(false)
    	self.rootItems.upNode:setVisible(self.active)
    	self.rootItems.xiangqianNode:setVisible(self.active)

    	ui.setLabelString(self.rootItems.activeLab,nil,19)
    	ui.setLabelString(self.rootItems.upLab,nil,19)
    	ui.setLabelString(self.rootItems.xiangqianLab,nil,19)

        local generalConfig = gamedata.config.general[tostring(self.general.cid)]
        if generalConfig.quality < 7 then
            ui.addGray("CCControlButton",self.rootItems.upButton)
            ui.addGray("CCLabelTTF",self.rootItems.upLab)

            ui.addGray("CCControlButton",self.rootItems.xiangqianButton)
            ui.addGray("CCLabelTTF",self.rootItems.xiangqianLab)
        else
            ui.removeGray("CCControlButton",self.rootItems.upButton)
            ui.removeGray("CCLabelTTF",self.rootItems.upLab)

            ui.removeGray("CCControlButton",self.rootItems.xiangqianButton)
            ui.removeGray("CCLabelTTF",self.rootItems.xiangqianLab)
        end

	    self.rootItems.upButton:addHandleOfControlEvent(function()
            if generalConfig.quality < 7 then
                runGamePrompt({msg=gameConfig.strings:string_common("exclusiveArtifactNew",16)})
                return
            end
	        GameScene:shiftLayerById(616,{cid = self.data.general.cid,sid = self.sid})
	    end, CCControlEventTouchUpInside)
	    self.rootItems.upButton:setSwallowsTouch(true)
	    self.rootItems.upButton:setTouchPriority(self.touchPriority)

	    self.rootItems.xiangqianButton:addHandleOfControlEvent(function()
            if generalConfig.quality < 7 then
                runGamePrompt({msg=gameConfig.strings:string_common("exclusiveArtifactNew",16)})
                return
            end
	        GameScene:shiftLayerById(617,{cid = self.data.general.cid,sid = self.sid})
	    end, CCControlEventTouchUpInside)
	    self.rootItems.xiangqianButton:setSwallowsTouch(true)
	    self.rootItems.xiangqianButton:setTouchPriority(self.touchPriority)
    elseif self.opt == 2 then
    	self.rootItems.buttonNode:setVisible(false)
        self.rootItems.timesNode:setVisible(false)

    	self.showHight = 650
		self.rootItems.bg = tolua.cast(self.rootItems.bg, "CCScale9Sprite")
        self.rootItems.bg:setPreferredSize(CCSizeMake(800,self.showHight))
		self.rootItems.scrollnode:setViewSize(CCSizeMake(800,self.showHight))
    elseif self.opt == 3 or self.opt == 11 then
        self.showHight = 510
        self.rootItems.bg = tolua.cast(self.rootItems.bg, "CCScale9Sprite")
        self.rootItems.bg:setPreferredSize(CCSizeMake(800,self.showHight))
        self.rootItems.scrollnode:setViewSize(CCSizeMake(800,self.showHight))
        
        self.rootItems.buttonNode:setVisible(true)
        self.rootItems.timesNode:setVisible(false)

        self.rootItems.upNode:setVisible(false)
        self.rootItems.xiangqianNode:setVisible(false)
        self.rootItems.activeNode:setVisible(false)
        self.rootItems.sureNode:setVisible(true)

        ui.setLabelString(self.rootItems.sureLab,nil,19)

        self.rootItems.sureButton:addHandleOfControlEvent(function()
            gameWindows:closeWindow("exclusiveArtifact")
        end, CCControlEventTouchUpInside)
        self.rootItems.sureButton:setSwallowsTouch(true)
        self.rootItems.sureButton:setTouchPriority(self.touchPriority)
    end
end

function exclusiveArtifact.reloadChallengeTimes(self,data)

    local ison = false
    local slotData = GameScene.layers["slotsInfo"].module.slotdata
    for i=1,7 do
        if slotData[tostring(i)] and slotData[tostring(i)].general then
            if slotData[tostring(i)].general.iid == self.data.general.iid then
                ison = true
                break
            end
        end
    end
            
    local generalConfig = gamedata.config.general[tostring(self.general.cid)]
    local maxTimes = gamedata.config.vip[tostring(GameScene.vip.vip)].exclusive_copy or 0
    local endChallengeTimes = maxTimes - (data[tostring(self.data.general.iid)] or 0)
    ui.setLabelString(self.rootItems.times,endChallengeTimes,endChallengeTimes > 0 and 26 or 27,32)

    if generalConfig.quality < 7 then
        ui.addGray("CCControlButton",self.rootItems.activeButton)
        ui.addGray("CCLabelTTF",self.rootItems.activeLab)
    elseif endChallengeTimes <= 0 then
        ui.addGray("CCControlButton",self.rootItems.activeButton)
        ui.addGray("CCLabelTTF",self.rootItems.activeLab)
    elseif not ison then
        ui.addGray("CCControlButton",self.rootItems.activeButton)
        ui.addGray("CCLabelTTF",self.rootItems.activeLab)
    else
        ui.removeGray("CCControlButton",self.rootItems.activeButton)
        ui.removeGray("CCLabelTTF",self.rootItems.activeLab)
    end

    self.rootItems.activeButton:addHandleOfControlEvent(function()
        if generalConfig.quality < 7 then
            runGamePrompt({msg=string.format(gameConfig.strings:string_common("exclusiveArtifactNew",15), generalConfig.name)})
        elseif not ison then
            runGamePrompt({msg=string.format(gameConfig.strings:string_common("exclusiveArtifactNew",19), generalConfig.name)})
        elseif endChallengeTimes <= 0 then
            runGamePrompt({msg=gameConfig.strings:string_common("exclusiveArtifactNew",14)})
        else
            UIRequest({type = 8103, generalIid = self.data.general.iid})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.activeButton:setSwallowsTouch(true)
    self.rootItems.activeButton:setTouchPriority(self.touchPriority)
end

function exclusiveArtifact.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.data = {}
end

return exclusiveArtifact
