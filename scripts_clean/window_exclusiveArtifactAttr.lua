--
-- Author: songyibo
-- Date: 2021-03-20 16:18:41
--

local exclusiveArtifactAttr = {
    rootNode = nil,
    rootItems = nil,
    data = {},

}

function exclusiveArtifactAttr.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("zhuanshushenqi/tc_shuxingzonglan", nil, true, "tc_shuxingzonglan")
    self.touchPriority = touchPriority
    
    printT(data,"exclusiveArtifactAttr")
 --    self.data = {
	-- 	generalIid 		= 0,
	-- 	level 			= 0,
	-- 	inlayId1        = 1,
	-- 	inlayId2        = 2,
	-- 	inlayId3        = 3,
	-- 	inlayId4        = 4,
	-- 	inlayId5        = 5,
	-- 	inlayId6        = 6,
	-- 	suitId1			= 1,
	-- 	suitId2			= 2,
	-- 	suitId3			= 0,
	-- 	intensify_level = 0,
	-- 	baptism_level 	= 0,
	-- 	general 		= {
	-- 		iid = 55005,
	-- 		cid = 162003,
	-- 	},
 --        cid             = 201501,

	-- }
    self.data = data

	self:initNode()
	self:reload()
    return self.rootNode
end

function exclusiveArtifactAttr.initNode(self)

	self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("exclusiveArtifactAttr")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)

    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(self.touchPriority)
    self.scrollNode, self.scrollItems = CCBReaderLoad("zhuanshushenqi/cell_shuxingzonglan", nil, true, "cell_shuxingzonglan")
    self.rootItems.container:addChild(self.scrollNode)
    self.scrollNode:setPosition(400,1000)
end

function exclusiveArtifactAttr.reload(self)
	local qinglingDatas = GameScene.layers["qiLingBag"].module.data

    --基础属性有百分比
    local basic_attr_infos = {}
    local basic_attr_keys = {}

    --随机属性没有百分比

    local random_attrs_infos = {}
    local random_attrs_keys = {}

    for i=1,6 do
    	local qilingIid = self.data["inlayId"..i]
    	if qilingIid and qinglingDatas[qilingIid] then

    		local qilingData = qinglingDatas[qilingIid]
    		local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(qilingData.cid)]
    		--基础属性
    		if not basic_attr_infos[qilingConfig.attribute] then
    			basic_attr_infos[qilingConfig.attribute] = {}
    		end
    		if basic_attr_infos[qilingConfig.attribute][qilingConfig.method] then
    			basic_attr_infos[qilingConfig.attribute][qilingConfig.method].value = basic_attr_infos[qilingConfig.attribute][qilingConfig.method].value + qilingConfig.value
    		else
    			basic_attr_infos[qilingConfig.attribute][qilingConfig.method] = {attribute = qilingConfig.attribute,method = qilingConfig.method,value = qilingConfig.value}
    			table.insert(basic_attr_keys,{attribute = qilingConfig.attribute,method = qilingConfig.method})
    		end

            if qilingData.level > 0 then
                local intensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(qilingData.level)]
                basic_attr_infos[qilingConfig.attribute][qilingConfig.method].value = basic_attr_infos[qilingConfig.attribute][qilingConfig.method].value + intensifyConfig.value
            end

            --随机属性
            local randomAttrInfo = gameWindows.windows["qilingInfo"].module.getRandomAttrInfo(qilingData)

            for j=1,4 do
                local info = randomAttrInfo[j]
                if info then
                    if info.type == 1 then
                        if not random_attrs_keys[info.attribute] then
                            random_attrs_keys[info.attribute] = {id = info.id,name = info.name,type = info.type,attribute = info.attribute,attrValue = qilingData["qiLingAttrValue"..j],method = info.method,sorting = info.sorting}
                            table.insert(random_attrs_infos,random_attrs_keys[info.attribute])
                        else
                            random_attrs_keys[info.attribute].attrValue = random_attrs_keys[info.attribute].attrValue + qilingData["qiLingAttrValue"..j]
                        end
                    else
                        table.insert(random_attrs_infos,info)
                    end
                end
            end

    	end
    end
    printT(random_attrs_infos,"random_attrs_infos")
    
    table.sort(random_attrs_infos,function ( a,b)
        return a.sorting < b.sorting
    end)

    for i=1,6 do
    	if basic_attr_keys[i] then
    		local attrInfo = basic_attr_infos[basic_attr_keys[i].attribute][basic_attr_keys[i].method]
            local attrValue = attrInfo.method == "percent" and attrInfo.value * 100 or attrInfo.value
    		self.scrollItems["attr"..i]:setString(gameConfig.strings:attributeValue2(attrInfo.attribute,attrInfo.method,attrValue))
    	else
    		self.scrollItems["attr"..i]:setString("")
    	end
    end

    local fixedH = 0
    local lineH = 40
    for i,v in ipairs(random_attrs_infos) do
        local lineNum = 0
        local node, items = CCBReaderLoad("zhuanshushenqi/cell_suijishuxing", nil, true, "cell_suijishuxing")
        node:setPositionY(-fixedH)
        self.scrollItems.randomAttrNode:addChild(node)
        local contents = {}
        if v.type == 1 then
            contents[1] = {fontID = 1031,content = "+"..v.attrValue..(v.method == "percent" and "%" or "")}
            lineNum = 1
        else
            local breakskill = v.breakskill
            if v.randomAttrLevel > 0 and v["intensify"..v.randomAttrLevel] then
                breakskill = v["intensify"..v.randomAttrLevel]
            end
            local breakskill = gamedata.config.breakskill[tostring(breakskill)]
            contents[1] = {fontID = 1031,content = breakskill.desc}
            lineNum = breakskill.desc_param
        end
        items["r_attr_name"]:setString(v.name)
        ui.createRichLabel(contents,items["r_attr_desc"],false,{min_line_dis = 2})
        items["r_attr_tipnode"]:setVisible(false)
        fixedH = fixedH + lineNum * lineH
    end

    local containerH = 320 + fixedH
    self.rootItems.container:setContentSize(CCSizeMake(800, containerH))
    self.scrollNode:setPosition(400,containerH)
    self.rootItems.container:setPositionY(1080 - containerH)

end

function exclusiveArtifactAttr.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.data = {}
end

return exclusiveArtifactAttr