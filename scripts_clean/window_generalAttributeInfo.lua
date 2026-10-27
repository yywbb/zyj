--
-- Author: songyibo
-- Date: 2019-03-19 15:39:24
--


local attributeInfo = {
    rootNode = nil,
    rootItems = nil,
    attrStatus = "fan",
}

function attributeInfo.open(self,touchPriority,data,callback)
    self.root = CCNode:create()

    self.touchPriority = touchPriority
 
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/tc_shuxinginfo", nil, true, "tc_shuxinginfo")
    self.root:addChild(self.rootNode)
    self.data = data
    self:reload()

    return self.root
end


function attributeInfo.reload(self)
	self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
       gameWindows:closeWindow("generalAttributeInfo")
    end, CCControlEventTouchUpInside)


    self.rootItems.attrChange:addHandleOfControlEvent(function()
        if self.attrStatus == "fan" then
            self.attrStatus = "xian"
            self.rootItems.fan:setVisible(false)
	        self.rootItems.xian:setVisible(true)
        else
            self.attrStatus = "fan"
            self.rootItems.fan:setVisible(true)
	        self.rootItems.xian:setVisible(false)
            setSpriteFrameByName(self.rootItems.attr_bg1,"shuxinginfogbg")
            setSpriteFrameByName(self.rootItems.attr_bg2,"shuxinginfogbg")
        end
        self:setAttr_info()
    end, CCControlEventTouchUpInside)
    self.rootItems.attrChange:setSwallowsTouch(true)
    self.rootItems.attrChange:setTouchPriority(self.touchPriority )

    self:setAttr_info()
end


function attributeInfo.setAttr_info(self)

	-- --凡属性转换仙属性折算比例
 --    local every_fairy_turn = gamedata.config.global_kv.every_fairy_turn.value

 --    --仙属性转换凡属性折算比例
 --    local fairy_turn_every = gamedata.config.global_kv.fairy_turn_every.value


	local general = self.data
    printT(general,"general")
	self.rootItems.powerTotal:setString(general.power)

	local tag = ""

	local changeTag = ""
	local percent = 0
	if self.attrStatus == "fan" then
		tag = ""
		changeTag = "g_"
		self.rootItems.power:setString("战斗力："..general.f_power)
		self.rootItems.changeTitle:setString(gameConfig.strings:string_common("general",51))
		percent = gamedata.config.global_kv.fairy_turn_every.value

        setSpriteFrameByName(self.rootItems.attr_bg1,"shuxinginfogbg")
        setSpriteFrameByName(self.rootItems.attr_bg2,"shuxinginfogbg")
        self.rootItems.criticaldmg:setPositionX(134)
        self.rootItems.g_criticaldmg:setPositionX(134)

	else
		tag = "g_"
		changeTag = ""
		self.rootItems.power:setString("战斗力："..general.g_power)
		self.rootItems.changeTitle:setString(gameConfig.strings:string_common("general",52))
		percent = gamedata.config.global_kv.every_fairy_turn.value

        setSpriteFrameByName(self.rootItems.attr_bg1,"shuxinginfogbg2")
        setSpriteFrameByName(self.rootItems.attr_bg2,"shuxinginfogbg2")

        self.rootItems.criticaldmg:setPositionX(104)
        self.rootItems.g_criticaldmg:setPositionX(104)
	end

	self.rootItems.atk:setString(general.attrWithOutTransform[tag.."atk"])
    self.rootItems.defense:setString(general.attrWithOutTransform[tag.."defense"])
    self.rootItems.hp:setString(general.attrWithOutTransform[tag.."hp"])
    self.rootItems.critical:setString(general.attrWithOutTransform[tag.."critical"])
    self.rootItems.dodge:setString(general.attrWithOutTransform[tag.."dodge"])
    self.rootItems.parry:setString(general.attrWithOutTransform[tag.."parry"])
    self.rootItems.resilience:setString(general.attrWithOutTransform[tag.."resilience"])
    self.rootItems.hit:setString(general.attrWithOutTransform[tag.."hit"])
    self.rootItems.arp:setString(general.attrWithOutTransform[tag.."arp"])
    self.rootItems.criticaldmg:setString(general.attrWithOutTransform[tag.."criticaldmg"])


    self.rootItems.g_atk:setString(math.floor(general.attrWithOutTransform[changeTag.."atk"] * percent))
    self.rootItems.g_defense:setString(math.floor(general.attrWithOutTransform[changeTag.."defense"] * percent))
    self.rootItems.g_hp:setString(math.floor(general.attrWithOutTransform[changeTag.."hp"] * percent))
    self.rootItems.g_critical:setString(math.floor(general.attrWithOutTransform[changeTag.."critical"] * percent))
    self.rootItems.g_dodge:setString(math.floor(general.attrWithOutTransform[changeTag.."dodge"] * percent))
    self.rootItems.g_parry:setString(math.floor(general.attrWithOutTransform[changeTag.."parry"] * percent))
    self.rootItems.g_resilience:setString(math.floor(general.attrWithOutTransform[changeTag.."resilience"] * percent))
    self.rootItems.g_hit:setString(math.floor(general.attrWithOutTransform[changeTag.."hit"] * percent))
    self.rootItems.g_arp:setString(math.floor(general.attrWithOutTransform[changeTag.."arp"] * percent))
    self.rootItems.g_criticaldmg:setString(math.floor(general.attrWithOutTransform[changeTag.."criticaldmg"] * percent))

    self.rootItems.speed:setString(general["speed"] or 0)
    self.rootItems.g_speed:setString(general["speed"] or 0)
    self.rootItems.potential:setString(general["potential"] or 0)
    self.rootItems.g_potential:setString(general["potential"] or 0)

end


function attributeInfo.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.attrStatus = "fan"
    if self.callback then
        self.callback()
    end
end

return attributeInfo