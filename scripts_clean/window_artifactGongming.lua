--
-- Author: songyibo
-- Date: 2019-03-05 10:44:01
--

local artifactGongming = {
    rootNode = nil,
    rootItems = nil,
}

function artifactGongming.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_shenjigongming", nil, true, "tc_shenjigongming")
    self:initFixedString()
    self.touchPriority = touchPriority
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("artifactGongming")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
   
    local scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    scrollnode:setTouchPriority(self.touchPriority - 1)

    printT(data,"artifactGongming")
   	self.data = data


    self["activate1"],self["activate2"],self["unActivate1"],self["unActivate2"] = self:dealData(self.data)

	local sortfun = function (a,b)
		return a.data.sorting > b.data.sorting
	end

	table.sort(self["activate1"],sortfun)
	table.sort(self["unActivate1"],sortfun)

    table.sort(self["activate2"],sortfun)
	table.sort(self["unActivate2"],sortfun)

    self:createCells()

    return self.rootNode
end

function artifactGongming.compare(self,data,config)
	local result = {}
	for i=1,2 do
		local skillId = config["skills"..i]
		for j=1,3 do
			if skillId == data["skill"..j] then
				result["skill"..i] = true
				break
			end
		end
	end
	return result
end

--处理缘分数据
function artifactGongming.dealData(self,artifact)
	local config = gamedata.config.resonance_attribute

	--激活
	local activate1 = {}
	--未激活
	local unActivate1 = {}

	for k,v in pairs(config["1"]) do
		local result = self:compare(artifact,v)
		printT(result,"result")
		if result.skill1 and result.skill2 then
			table.insert(activate1,{data = v,status = result,active = true})
		elseif result.skill1 or result.skill2 then
			table.insert(unActivate1,{data = v,status = result,active = false})
		end
	end

	--激活
	local activate2 = {}
	--未激活
	local unActivate2 = {}

	local skillNum = 0
	for i=1,3 do
		if artifact["skill"..i] > 0 then
			local skillConfig = gamedata.config.breakskill[tostring(artifact["skill"..i])]
			if skillConfig.quality >= 6 then
				skillNum = skillNum + 1
			end
		end
	end

	for k,v in pairs(config["2"]) do
		if skillNum >= v.id then
			table.insert(activate2,{data = v,active = true})
		else
			table.insert(unActivate2,{data = v,active = false})
		end
	end

	return activate1,activate2,unActivate1,unActivate2
end

function artifactGongming.addCell(self,v)

	local data = v.data
	local status = v.status

	printT(data,"addCell")
	local ccb, items = CCBReaderLoad("shenqi_new/cell_shenjigongming", nil, true, "cell_shenjigongming")
	ccb:setPosition(440,self.fixH + 22)
	self.rootItems.container:addChild(ccb)
	self.fixH = self.fixH + 60

	items.active:setVisible(v.active)
	items.unactive:setVisible(not v.active)

	ui.setLabelString(items.attr,"速度+"..data.attribute.."：",v.active and 132 or 133)

	if data.type == 1 then
	    local args = {}

	    table.insert(args,{fontID = 131,content = "拥有"})

	    local skillConfig = gamedata.config.breakskill[tostring(data.skills1)]
	    table.insert(args,{fontID = status.skill1 and 132 or 133,content = skillConfig.name or ""})
	    table.insert(args,{fontID = 131,content = "和"})

	    local skillConfig = gamedata.config.breakskill[tostring(data.skills2)]
	    table.insert(args,{fontID = status.skill2 and 132 or 133,content = skillConfig.name or ""})
	    table.insert(args,{fontID = 131,content = "激活"})

	    ui.createRichLabel(args,items.richnode)


	elseif data.type == 2 then
		local args = {}

	    table.insert(args,{fontID = 131,content = "拥有"})
	    table.insert(args,{fontID = v.active and 132 or 133,content = data.id})
	    table.insert(args,{fontID = 131,content = "个红色技能激活"})

	    ui.createRichLabel(args,items.richnode)

	end
	return ccb
end

--获取创建技能cell一些进本数据
function artifactGongming.createCells(self)
    local breakconfig = gamedata.config.breakskill or {}

    self.fixH = 0

    for i,v in ipairs(self["unActivate1"]) do
    	self:addCell(v)
    end

    for i,v in ipairs(self["unActivate2"]) do
    	self:addCell(v)
    end


    for i,v in ipairs(self["activate1"]) do
    	self:addCell(v)
    end

    for i,v in ipairs(self["activate2"]) do
    	self:addCell(v)
    end
    

    

    self.rootItems.container:setContentSize(CCSize(880,self.fixH))
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,560 - self.fixH),0)
end

function artifactGongming.initFixedString(self)
	
end

function artifactGongming.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return artifactGongming