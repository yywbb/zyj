--神石详情
--zhangzhixin

local godStoneInfo = {
    rootNode = nil,
    rootItems = nil,
}

function godStoneInfo.open( self,touchPriority,data,callback )
	self.touchPriority = touchPriority
	self.godStoneConfig = gamedata.config.godstone
	self.stoneAttrConfig = gamedata.config.godstonestrengthening
	self.maxLevel = table.getTableLength(self.stoneAttrConfig)
	self.root = ui.createNode()
    self.rootNode, self.rootItems = CCBReaderLoad("slotsInfo/shenshi_info", nil, true, "godStoneInfo")
    self.root:addChild(self.rootNode)
    printT(data,"godStoneInfo.open =======")
    self:load(data)	
    return self.root
end

function godStoneInfo.close( self )
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
end

function godStoneInfo.load(self,aiData)
	self.rootItems.titilenameLabel:setString(gameConfig.strings:string_common("godStoneInfo",1))

    ui.setLabelString(self.rootItems.cancleLabel,nil,19)
	self.rootItems.cancleButton:addHandleOfControlEvent(function()
		gameWindows:closeWindow("godStoneInfo")
	end,CCControlEventTouchUpInside)
    self.rootItems.cancleButton:setTouchPriority(self.touchPriority)
    self.rootItems.cancleButton:setSwallowsTouch(true)	
	self.rootItems.closeButton:addHandleOfControlEvent(function()
		gameWindows:closeWindow("godStoneInfo")
	end,CCControlEventTouchUpInside)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:setSwallowsTouch(true)	 
    
    self.rootItems.name:setString(self.godStoneConfig[tostring(aiData.posID)].name)
	ui.setStoneIcon({level=aiData.level},self.rootItems,0,false,false)

    local config = self.godStoneConfig[tostring(aiData.posID)] or {}
    setSpriteFrameByName(self.rootItems.stone_sprite, config.icon or "alpha")

    self.rootItems.stone_name:setVisible(false)
    self.rootItems.stone_lv:setVisible(false)

    self.rootItems.desc1:setString(gameConfig.strings:string_common("godStoneInfo",3)..aiData.level.."/"..self.maxLevel)
    if aiData.level == 0 then --未激活
    	self.rootItems.desc2:setString(
    		gameConfig.strings:string_common("godStoneInfo",6)
    		..gameConfig.strings:string_common("attr_type",self.godStoneConfig[tostring(aiData.posID)].attribute)
    		.."+"..
    		(self.stoneAttrConfig[tostring(aiData.level+1)][self.godStoneConfig[tostring(aiData.posID)].attribute] > 1 and self.stoneAttrConfig[tostring(aiData.level+1)][self.godStoneConfig[tostring(aiData.posID)].attribute] or tonumber(self.stoneAttrConfig[tostring(aiData.level+1)][self.godStoneConfig[tostring(aiData.posID)].attribute])*100 .."%")
    	)
    	self.rootItems.desc3:setString(gameConfig.strings:string_common("godStoneInfo",4))
		self.rootItems.needNum:setString(self.stoneAttrConfig[tostring(aiData.level+1)][self.godStoneConfig[tostring(aiData.posID)].attribute.."_number"])
	else
    	self.rootItems.desc2:setString(
    		gameConfig.strings:string_common("godStoneInfo",2)
    		..gameConfig.strings:string_common("attr_type",self.godStoneConfig[tostring(aiData.posID)].attribute)
    		.."+"..(self.stoneAttrConfig[tostring(aiData.level)][self.godStoneConfig[tostring(aiData.posID)].attribute] > 1 and self.stoneAttrConfig[tostring(aiData.level)][self.godStoneConfig[tostring(aiData.posID)].attribute] or self.stoneAttrConfig[tostring(aiData.level)][self.godStoneConfig[tostring(aiData.posID)].attribute] *100 .."%"))
    	if aiData.level+1 <= self.maxLevel then --激活 但不是满级时
	    	self.rootItems.desc3:setString(
	    		gameConfig.strings:string_common("godStoneInfo",5)
	    		..gameConfig.strings:string_common("attr_type",self.godStoneConfig[tostring(aiData.posID)].attribute)
	    		.."+"..(self.stoneAttrConfig[tostring(aiData.level+1)][self.godStoneConfig[tostring(aiData.posID)].attribute] > 1 and self.stoneAttrConfig[tostring(aiData.level+1)][self.godStoneConfig[tostring(aiData.posID)].attribute] or self.stoneAttrConfig[tostring(aiData.level+1)][self.godStoneConfig[tostring(aiData.posID)].attribute]*100 .."%")
	    		)
			self.rootItems.needNum:setString(self.stoneAttrConfig[tostring(aiData.level+1)][self.godStoneConfig[tostring(aiData.posID)].attribute.."_number"])
    	else
    		self.rootItems.desc3:setString(gameConfig.strings:string_common("godStoneInfo",7))
	    	self.rootItems.desc4:setVisible(false)
	    	self.rootItems.needNum:setVisible(false)
	    	self.rootItems.stoneSpr:setVisible(false)
            self.rootItems.desc5:setPositionY(self.rootItems.desc2:getPositionY() - 39)
    	end
    	
	end
	self.rootItems.desc3:setPositionX(10 + self.rootItems.desc2:getPositionX()+ self.rootItems.desc2:getContentSize().width)
end

return godStoneInfo