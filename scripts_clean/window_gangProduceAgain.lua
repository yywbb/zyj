-- 公会盛宴 澡堂继续
-- Created by IntelliJ IDEA.
-- User: admin
-- To change this template use File | Settings | File Templates.
--
local gangProduceAgain = {
	rootNode = nil,
	rootItems = nil,
	produceAgainTab = {},
	propCid = 0,
	needProp = {}
}

function gangProduceAgain.open(self, touchPriority, data, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("gonghui3/tc_xuanzecailiao", nil, true, "tc_xuanzecailiao")
	self.produceAgainTab = data
	self.touchPriority = touchPriority
	self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("gangProduceAgain")
	end, CCControlEventTouchUpInside)
	self.rootItems.closeButton:setSwallowsTouch(true)
	self.rootItems.closeButton:setTouchPriority(self.touchPriority)

	self.rootItems.again_btn:addHandleOfControlEvent(function()
        self.callback = nil
        
        self:againFeastControl()
	end, CCControlEventTouchUpInside)
	self.rootItems.again_btn:setSwallowsTouch(true)	
	self.rootItems.again_btn:setTouchPriority(self.touchPriority)	
	
	ui.setLabelString(self.rootItems.again_lab, nil, 19)
	self.rootItems.title:setString("选择材料")
	
	self:onProduceInfoShow()
	return self.rootNode	
end

function gangProduceAgain.againFeastControl(self)
    local configTypeData = gamedata.config.gang2_feast_type
    local alltimes = gamedata.config.global_kv["gang2_feast_times"].value
    if self.produceAgainTab.produceType == 2 then
		configTypeData = gamedata.config.gang2_bath_type
		alltimes = gamedata.config.global_kv["gang2_bath_partake"].value
	end
    --消耗物品
    local awardArr = ui.getIDandNUMs(configTypeData[tostring(self.produceAgainTab.roomid)].props)
                
    local curtimes = alltimes - self.produceAgainTab.opennum
    if curtimes == 0 then
        runGamePrompt({msg = "次数不足"})
        return
    end
    if self.needProp[tostring(self.propCid)] and self.needProp[tostring(self.propCid)] >= awardArr[1].num then
    	if self.produceAgainTab.produceType == 2 then
    		UIRequest({type = 2286, useProp = awardArr[1]})
    	else
	        UIRequest({type = 2276, useProp = awardArr[1]})
	    end
    elseif  self.needProp[tostring(self.propCid)] then

    	local useProp = table.copy(awardArr[1])
        useProp.num = self.needProp[tostring(self.propCid)]

        local callback = function(gold)
        	if self.produceAgainTab.produceType == 2 then
        		UIRequest({type = 2286, useProp = useProp, gold = gold})
        	else
	            UIRequest({type = 2276, useProp = useProp, gold = gold})
	        end
        end
        local data = {}
        data.prop = {{cid = self.propCid, num = awardArr[1].num - self.needProp[tostring(self.propCid)]}}
        if self.produceAgainTab.produceType == 2 then
        	data.msg = "举办公会篝火"
        else
	        data.msg = "举办公会盛宴"
	    end
        gameWindows:openWindow("price_props",data,callback)   
    else
        runGamePrompt({msg = "道具不足"})
    end 
end

function gangProduceAgain.onProduceInfoShow(self)
	local configTypeData = gamedata.config.gang2_feast_type
	if self.produceAgainTab.produceType == 2 then
		configTypeData = gamedata.config.gang2_bath_type
	end
	local alltimes = gamedata.config.global_kv["gang2_feast_times"].value
    local curtimes = alltimes - self.produceAgainTab.opennum
	self.rootItems.opentimes:setString(curtimes.."/"..alltimes)
	local curconfigdata = configTypeData[tostring(self.produceAgainTab.roomid)]
	self.rootItems.produce_type:setString(curconfigdata.name)
	local awardArr = ui.getIDandNUMs(curconfigdata.props)
	local useProp = awardArr[1]
	self.propCid = useProp.cid
	UIRequest({type = 12001, order = 50001, cids = {useProp.cid}})

	self.rootItems.has_prop:setString("（现有x100）")
	self.rootItems.xiaohao_prop:setString(""..useProp.num)
	local config = ui.IDconfig(useProp.cid) 
	setSpriteFrameByName(self.rootItems.xiaohaoIconNormal,config.icon)


	local time = curconfigdata.time
	self.rootItems.againdesc:setString("消耗1次举办次数接龙，延长全体"..time.."秒盛宴时间")
	self.rootItems.normalLocationDes:setString("盛宴模式")

	if self.produceAgainTab.produceType == 2 then
		configTypeData = gamedata.config.gang2_bath_type
		self.rootItems.againdesc:setString("消耗1次举办次数接龙，延长全体"..time.."秒篝火时间")
		self.rootItems.normalLocationDes:setString("篝火模式")
	end
end

function gangProduceAgain.setpropNum(self,data)
	self.needProp = data
    self.rootItems.has_prop:setString("（现有x"..data[tostring(self.propCid)].."）")
end

function gangProduceAgain.close(self, _type) -- 退出
	self.produceAgainTab = {}
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootNode = nil
	self.rootItems = nil
	self.propCid = 0
	self.needProp = {}

end

return gangProduceAgain