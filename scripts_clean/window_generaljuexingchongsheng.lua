--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 21/12/02
-- Time: 下午2:10
-- To change this template use File | Settings | File Templates.
--

local generalJXRebirth = {
    rootNode = nil,
    rootItems = nil,

    generalData = {},
    rebirthData = {},

    globalConfig = {},

    itemid = 0,
    needNum = 0,
}

function generalJXRebirth.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/tc_general_jxr", nil, true, "tc_general_jxr")

    self.globalConfig = gamedata.config.global_kv

    self.generalData = data
	printT(self.generalData,"generalData")
    local copydata = table.copy(data)
    copydata.skilllevel = 90
    self.rebirthData = copydata

    self:getUseItem()
    local jxname = gamedata.config.general_awaken[tostring(self.generalData.skilllevel)].name
    ui.setLabelString(self.rootItems.cs_text1,nil,18)
    ui.setLabelString(self.rootItems.cs_text2,nil,18)
    ui.setLabelString(self.rootItems.cs_text3,jxname,22,44)
    ui.setLabelString(self.rootItems.cs_text4,nil,22,44)

    ui.setLabelString(self.rootItems.my_item_num,nil,18,42)
    ui.setLabelString(self.rootItems.gang,nil,18,42)
    ui.setLabelString(self.rootItems.item_num,self.needNum,18,42)

    ui.setLabelString(self.rootItems.oktext,gameConfig.strings:string_common("popups","queding"),18)

    --心灵宝石
    self.itemid = tonumber(self.globalConfig.exchange_prop.value)
    ui.setNewIcon(self.rootItems,{cid = self.itemid})
    UIRequest({type = 12001, order = 34308, cids = {self.itemid}})

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("generalJXRebirth")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(touchPriority)

    
    self.rootItems.btn_ok:addHandleOfControlEvent(function()
		--
		UIRequest({type = 8096, iid = self.generalData.iid, itemid = self.itemid, itemnum = self.needNum})
        gameWindows:closeWindowDirect("generalJXRebirth")
    end, CCControlEventTouchUpInside)
    self.rootItems.btn_ok:setSwallowsTouch(true)
    self.rootItems.btn_ok:setTouchPriority(touchPriority)

    return self.rootNode
end

function generalJXRebirth.getUseItem(self)
    
    local generalConfig = gamedata.config.general
	local exchange_break = gamedata.config.exchange_break_value --互换突破参数
	local exchange_awaken = gamedata.config.exchange_awaken_param --互换觉醒参数
	local exchange_soaring = gamedata.config.exchange_soaring_param --互换飞升参数

	local xa = 1
	local ya = 1
	local za = 1
	local xb = 1
	local yb = 1
	local zb = 1
	local xa2 = 1
	local ya2 = 1
	local za2 = 1
	local xb2 = 1
	local yb2 = 1
	local zb2 = 1
	local s_a = 0
	local s_b = 0
	if self.generalData then
		local exchange1_id = generalConfig[tostring(self.generalData.cid)].exchange_id
		local nums1 = ui.Split(exchange1_id,";")
		local exchange1 = {}
		for k,v in pairs(nums1) do
            if v ~= nil and v ~= "" then
                table.insert(exchange1, tonumber(v))
            end
		end
		printT(exchange1, "exchange1")
		xa = exchange_break[tostring(exchange1[1])][tostring(self.generalData.level2)]["value"]
		if self.generalData.skilllevel > 0 then
			ya = exchange_awaken[tostring(exchange1[2])][tostring(self.generalData.skilllevel)]["value"]
		else
			ya = exchange_awaken[tostring(exchange1[2])][tostring(self:getGeneralAwakenBasic(self.generalData))]["value"]
		end
		za = exchange_soaring[tostring(exchange1[3])][tostring(self.generalData.level8)]["value"]

		xa2 = exchange_break[tostring(exchange1[1])][tostring(self.rebirthData.level2)]["value"]
		if self.rebirthData.skilllevel > 0 then
			ya2 = exchange_awaken[tostring(exchange1[2])][tostring(self.rebirthData.skilllevel)]["value"]
		else
			ya2 = exchange_awaken[tostring(exchange1[2])][tostring(self:getGeneralAwakenBasic(self.rebirthData))]["value"]
		end
		za2 = exchange_soaring[tostring(exchange1[3])][tostring(self.rebirthData.level8)]["value"]
		s_a = xa + ya - xa2 - ya2
	end

	if self.rebirthData then
		local exchange2_id = generalConfig[tostring(self.rebirthData.cid)].exchange_id
		local nums2 = ui.Split(exchange2_id,";")
		local exchange2 = {}
		for k,v in pairs(nums2) do
			if v ~= nil and v ~= "" then
				table.insert(exchange2, tonumber(v))
			end
		end
		printT(exchange2, "exchange2")
		xb = exchange_break[tostring(exchange2[1])][tostring(self.rebirthData.level2)]["value"]
		if self.rebirthData.skilllevel > 0 then
			yb = exchange_awaken[tostring(exchange2[2])][tostring(self.rebirthData.skilllevel)]["value"]
		else
			yb = exchange_awaken[tostring(exchange2[2])][tostring(self:getGeneralAwakenBasic(self.rebirthData))]["value"]
		end
		zb = exchange_soaring[tostring(exchange2[3])][tostring(self.rebirthData.level8)]["value"]

		xb2 = exchange_break[tostring(exchange2[1])][tostring(self.generalData.level2)]["value"]
		if self.generalData.skilllevel > 0 then
			yb2 = exchange_awaken[tostring(exchange2[2])][tostring(self.generalData.skilllevel)]["value"]
		else
			yb2 = exchange_awaken[tostring(exchange2[2])][tostring(self:getGeneralAwakenBasic(self.generalData))]["value"]
		end
		zb2 = exchange_soaring[tostring(exchange2[3])][tostring(self.generalData.level8)]["value"]
		s_b = xb + yb - xb2 - yb2
	end

	print("s_a == ", s_a)
	print("s_b == ", s_b)
	local x1 = xa
	local y1 = ya
	local z1 = za
	local x1_2 = xa2
	local y1_2 = ya2
	local z1_2 = za2

	local x2 = xb
	local y2 = yb
	local z2 = zb
	local x2_2 = xb2
	local y2_2 = yb2
	local z2_2 = zb2

	if s_a < s_b then
		x1 = xb
		y1 = yb
		z1 = zb
		x1_2 = xb2
		y1_2 = yb2
		z1_2 = zb2

		x2 = xa
		y2 = ya
		z2 = za
		x2_2 = xa2
		y2_2 = ya2
		z2_2 = za2
	end

	local U = (x2_2+y2_2) - (x2+y2)
	local V = (z2_2+z1_2) - (z2+z1)
	local W = (x1+y1) - (x1_2+y1_2)
	local pNum = ((U+V)*tonumber(self.globalConfig.exchange_param_1.value) - W*tonumber(self.globalConfig.exchange_param_2.value))*0.2
	print("pNum == ", pNum)
	if pNum < tonumber(self.globalConfig.exchange_param_3.value)  then
		pNum = tonumber(self.globalConfig.exchange_param_3.value)
	end

	self.needNum = math.ceil(pNum)
	print("needNum == ", self.needNum)

end

function generalJXRebirth.getGeneralAwakenBasic(self, general)
	local awaken = 0
	if general.basic == 18 then
		awaken = 0
	elseif general.basic == 20 then
		awaken = self.globalConfig.general_awaken20.value
	elseif general.basic == 23 then
		awaken = self.globalConfig.general_awaken23.value
	elseif general.basic == 44 then
		awaken = self.globalConfig.general_awaken44.value
	end
	return awaken
end

function generalJXRebirth.setPropNum(self, itemNum)
    if itemNum[tostring(self.itemid)] then
        local num = tonumber(itemNum[tostring(self.itemid)])
        if num >= self.needNum then
            ui.setLabelString(self.rootItems.my_item_num,num,22,42)
        else
            ui.setLabelString(self.rootItems.my_item_num,num,24,42)
        end
    end
end

function generalJXRebirth.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.generalData = {}
    self.rebirthData = {}
    self.globalConfig = {}

    self.itemid = 0
    self.needNum = 0

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return generalJXRebirth

