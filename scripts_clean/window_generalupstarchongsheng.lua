--
-- Created by IntelliJ IDEA.
-- User: jkp
-- Date: 21/12/02
-- Time: 下午2:10
-- To change this template use File | Settings | File Templates.
--

local generalUpStarRebirth = {
    rootNode = nil,
    rootItems = nil,

    generalData = {},

    globalConfig = {},

    itemid = 0,
    needNum = 0,
}

function generalUpStarRebirth.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/tc_general_jxr", nil, true, "tc_general_jxr")

	self.rootItems.juexingNode:setVisible(false)
	self.rootItems.upstar_text1:setVisible(true)

    self.globalConfig = gamedata.config.global_kv

    self.generalData = data
	printT(self.generalData,"generalData")

    self:getUseItem()

	ui.setLabelString(self.rootItems.upstar_text1,nil,11,42)
    ui.setLabelString(self.rootItems.my_item_num,nil,18,42)
    ui.setLabelString(self.rootItems.gang,nil,18,42)
    ui.setLabelString(self.rootItems.item_num,self.needNum,18,42)

    ui.setLabelString(self.rootItems.oktext,gameConfig.strings:string_common("popups","queding"),18)

    --心灵宝石
    self.itemid = tonumber(self.globalConfig.exchange_prop.value)
    ui.setNewIcon(self.rootItems,{cid = self.itemid})
    UIRequest({type = 12001, order = 34308, cids = {self.itemid}})

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("generalUpStarRebirth")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(touchPriority)

    
    self.rootItems.btn_ok:addHandleOfControlEvent(function()
		--
		UIRequest({type = 8301, iid = self.generalData.iid, itemid = self.itemid, itemnum = self.needNum})
        gameWindows:closeWindowDirect("generalUpStarRebirth")
    end, CCControlEventTouchUpInside)
    self.rootItems.btn_ok:setSwallowsTouch(true)
    self.rootItems.btn_ok:setTouchPriority(touchPriority)

    return self.rootNode
end

function generalUpStarRebirth.getUseItem(self)
    local upstarConfig = gamedata.config.general_star or {}
	self.needNum = upstarConfig[tostring(self.generalData.level5)].xinling_num
end

function generalUpStarRebirth.getGeneralAwakenBasic(self, general)
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

function generalUpStarRebirth.setPropNum(self, itemNum)
    if itemNum[tostring(self.itemid)] then
        local num = tonumber(itemNum[tostring(self.itemid)])
        if num >= self.needNum then
            ui.setLabelString(self.rootItems.my_item_num,num,22,42)
        else
            ui.setLabelString(self.rootItems.my_item_num,num,24,42)
        end
    end
end

function generalUpStarRebirth.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.generalData = {}
    self.globalConfig = {}

    self.itemid = 0
    self.needNum = 0

    if self.callback then
        self.callback()
        self.callback = nil
    end
end

return generalUpStarRebirth

