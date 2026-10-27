--
-- Author: songyibo
-- Date: 2021-03-18 11:09:05
--

local qiLingRefining = {

    rootNode = nil,
    rootItems = nil,
    touchPriority = -102,
    data = {},
    selectdatas = {},
    maxnum_select = 10

}

function qiLingRefining.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("zhuanshushenqi/zhuanshushenqi_ronglian", nil, true, "zhuanshushenqi_ronglian")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)
    self.toppos = toppos
    self.rootItems.topnode:setPositionY(toppos)
   
    self.rootItems.common_back_btn:setSwallowsTouch(true)
    self.rootItems.common_back_btn:setTouchPriority(self.touchPriority)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
        GameScene:shiftLayer("qiLingBag")
    end, CCControlEventTouchUpInside)

    self.rootItems.ruleBtn:setSwallowsTouch(true)
    self.rootItems.ruleBtn:setTouchPriority(self.touchPriority)
    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
    	ui.popCommonRule(618)
    end, CCControlEventTouchUpInside)


    ui.setLabelString(self.rootItems.onekeyText,nil,19)
    self.rootItems.onekeyBtn:setSwallowsTouch(true)
    self.rootItems.onekeyBtn:setTouchPriority(self.touchPriority)
    self.rootItems.onekeyBtn:addHandleOfControlEvent(function()
    	self:onekeyRefining()
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.doText,nil,19)
    self.rootItems.doBtn:setSwallowsTouch(true)
    self.rootItems.doBtn:setTouchPriority(self.touchPriority)
    self.rootItems.doBtn:addHandleOfControlEvent(function()
    	self:refining()
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.propLab,nil,19,36)
    ui.setLabelString(self.rootItems.propNum,nil,19,36)
    ui.setLabelString(self.rootItems.showgetText,nil,14)

    self:reload()
end

function qiLingRefining.onekeyRefining(self)
	self.selectdatas = {}
	for i,v in ipairs(self.data[0]) do
		if #self.selectdatas < 10 then
			table.insert(self.selectdatas,v)
		end
	end

    if #self.selectdatas == 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",20)})
    else
        self:reloadSelect()
    end
end

function qiLingRefining.refining(self)
	local iids = {}
	for k,v in pairs(self.selectdatas) do
		table.insert(iids,v.iid)
	end
    if #iids == 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("exclusiveArtifactNew",21)})
    else
        UIRequest({type = 8108, iids = iids})
    end
end

function qiLingRefining.refiningCallback(self,data)

    gameTouch:clickprofbytime(1)
    self.rootNode:stopAllActions()
    local sq = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        showRewardPopupWindow(data.reward,nil,nil,true)
    end))
    self.rootNode:runAction(sq)

    for i=1,#self.selectdatas do
        self:playEffect(i,self.rootItems)
    end
	self.selectdatas = {}
	self:reloadSelect()
    self:reload()
end

function qiLingRefining.playEffect( self, num ,Ttems)
    local rootNode, rootItems = CCBReaderLoad("UIEffect/qiankunlu/qiankunlu.ccbi", nil, true, "qiankunlu")
   Ttems["effect"..num.."node"]:addChild(rootNode)

    local animationManager = getAnimationManager(rootItems)
    animationManager:setAnimationCompletedCallback(function()
        Ttems["effect"..num.."node"]:removeAllChildrenWithCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("qiankunlu_texiao")
end

function qiLingRefining.requestPropNum(self)
	UIRequest({type = 12001, order = 33021, cids = {192091}})
end

function qiLingRefining.reloadPropNum(self,t)
    setSpriteFrameByName(self.rootItems.propIcon, ui.IDconfig(192091).icon)
	ui.setLabelString(self.rootItems.propNum,t["192091"],19,36)
end

function qiLingRefining.reloadSelect(self)
    printT(self.selectdatas,"reloadSelect")
	for i=1,self.maxnum_select do
		self:setItem(i)
	end
	
	if #self.selectdatas > 0 then
		self.rootItems.showgetNode:setVisible(true)
        local getCid = 192087
		local getnum = 0
		for i,v in ipairs(self.selectdatas) do
			local qilingConfig = gamedata.config.exclusive_device_spirit[tostring(v.cid)]
			local material = gamedata.getIDandNUMs(qilingConfig.smelting_material)
			if material[1] then
                getCid = material[1].cid
				getnum = getnum + material[1].num
			end

            if v.level > 0 then
                local intensifyConfig = gamedata.config.exclusive_device_spirit_intensify[tostring(qilingConfig.intensify_bonus_way)][tostring(v.level)]
                local material = gamedata.getIDandNUMs(intensifyConfig["return"])
                if material[1] then
                    getnum = getnum + material[1].num
                end
            end
		end

        if getnum > 0 then
            setSpriteFrameByName(self.rootItems.geticon1, ui.IDconfig(getCid).icon)
            ui.setLabelString(self.rootItems.getLabel1,("x"..getnum),3)
        end
        
	else
		self.rootItems.showgetNode:setVisible(false)
	end

end

function qiLingRefining.setItem(self,index)
    local key_Ex
    if index == nil or index == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(index-1)
    end
    local data = self.selectdatas[index]
    if data then
    	ui.setNewIcon(self.rootItems,{cid = data.cid, num = data.level > 0 and "+"..data.level or ""},index-1)
    	self.rootItems["i_icon"..key_Ex]:stopAllActions()
        local back = CCFadeTo:create(0,255)
        self.rootItems["i_icon"..key_Ex]:runAction(back)
    else
    	ui.resetNewIcon(self.rootItems,index-1)
    	setSpriteFrameByName(self.rootItems["i_icon"..key_Ex], "obj_add2")
    	ui.blink(self.rootItems["i_icon"..key_Ex],1)
    end

    self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
    	print("qilingselect",index)
        local cb = function(selectdatas)
            self.selectdatas = selectdatas
            self:reloadSelect()
        end
        gameWindows:openWindow("qilingRefiningSelect",{data = self.data,selectdatas = self.selectdatas},cb)
    end, CCControlEventTouchUpInside)
    self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority)
end

function qiLingRefining.reload(self)
	self.data = {}
	for k=0,6 do
		self.data[k] = {}
	end
    for k,v in pairs(table.copy(GameScene.layers["qiLingBag"].module.data)) do
    	if v.ison == 0 and v.lock == 0 then
    		local config = ui.IDconfig(v.cid)
	    	v.quality = config.quality
	    	v.location = config.location
	    	table.insert(self.data[0],v)
	    	
    	end
    end
    gamedata.sortData(self.data[0],"quality","level","cid",nil,nil,nil,true,true,true)
    for i,v in ipairs(self.data[0]) do
        table.insert(self.data[v.location],v)
    end

    self:requestPropNum()
    self:reloadSelect()
end

function qiLingRefining.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.data = {}
    self.selectdatas = {}
end

return qiLingRefining