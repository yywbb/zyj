
local multipleRebate_magic = {
	coverccb = nil,
	coveritems = nil,
    --标签显示
    pageconfig = {"rebate1", "rebate2",},
    pagename = {"", ""},
    selectpage = "rebate1",
    buttontouch = -103,
    -- status = 1
    rebateTab = {},
    props = {},

    activationTab = {},
    signInTab = {},
    playerTimeLab = nil,
    endTimeLab = nil,
    page = 1,
    configWelfare = {},
    copyPageconfig = {"rebate1", "rebate2",},

    day = 15, --奖励领取天数
}


function multipleRebate_magic.init(self, size, status)
    self.configWelfare = gamedata.config.month_welfare_x3
    self.pagename = {}
    for k,v in pairs(self.configWelfare) do
        table.insert(self.pagename, v.limit .. "基金")
    end
    self.contentsize = size
    self.show = true
    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/shenqijijin",nil, true, "shenqijijin")

    local year, month, day, hour, min, sec = 0,0,0,0,0,0
    local surplusTime = 0
    if gamedata.config.activity_time["193"]["open_type"] and gamedata.config.activity_time["193"]["open_type"] == 1 then
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["193"]["continued_time"] + (gamedata.config.activity_time["193"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        local temp1 = os.date("*t", timediff)
        year, month, day, hour, min, sec = temp1.year,temp1.month,temp1.day,temp1.hour,temp1.min,temp1.sec
    elseif gamedata.config.activity_time["193"]["end"] and gamedata.config.activity_time["193"]["end"] ~= "" then
        year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["193"]["end"])
    else
        self.status = 1
        self.playerTimeLab = ""
        self.endTimeLab = ""
    end

    local time1 = gamedata:time()
    local _temp = os.date("*t", GameScene.roleinfo.servertime)

    local tab = {year = year, month = month, day = day, hour = hour, min = min, sec = sec, isdst = _temp.isdst}
    local time2 = os.time(tab)
    -- print("时间1", time)
    -- print("时间2", os.date())
    -- local temp = os.date("*t", time)
    -- local string = string.format("%02d:%02d:%02d:%02d:%02d:%02d", temp.year, temp.month, temp.day, temp.hour, temp.min, temp.sec);
    -- print("时间2", temp.year, temp.month, temp.day, temp.hour, temp.min, temp.sec)

    surplusTime = time2 - time1
    if surplusTime > 0 then
        self.status = 1
    else
        self.status = 2
    end

    self.playerTimeLab = tab.year .. "年" .. tab.month .. "月" .. tab.day .. "日" .. tab.hour .. "时" .. tab.min .. "分"

    local addTime = gamedata.config.global_kv.monthfund_time_x3.value * 24 * 60 * 60
    local time = os.time(tab)
    local time1 = time + addTime
    local temp = os.date("*t", time1)
    self.endTimeLab = temp.year .. "年" .. temp.month .. "月" .. temp.day .. "日" .. temp.hour .. "时" .. temp.min .. "分"

    if self.status == 1 then
     	self.coveritems.multipleRebateNode:setPositionY((GameScene.topposY-1620)*0.5 - 80)   	
     	self.coveritems.statusNode1:setPositionY((GameScene.topposY-1620)*0.5 - 90)
     	self.coveritems.topNode:setPositionY(self.contentsize.y-160)
     	self.coveritems.statusNode2:setVisible(false)
     	self.coveritems.statusNode1:setVisible(true)
	    gameTimer:rigistTime("multipleRebateTimer_magic",surplusTime) -- 注册时间
	    --活动时间
	    if gameTimer.times["multipleRebateTimer_magic"] and gameTimer.times["multipleRebateTimer_magic"] > 0 then
	        gameTimer:rigistTimeFunc("multipleRebateTimer_magic", function()
	            if gameTimer.times["multipleRebateTimer_magic"] <= 0 then
	            	self.status = 2
	                if gameTimer.times["multipleRebateTimer_magic"] then
	                    gameTimer:UnrigistTimeFunc("multipleRebateTimer_magic")
	                end
	            else
	                self.coveritems.timeLab1:setString(ui.makeTimeDayText(gameTimer.times["multipleRebateTimer_magic"], "day").."后停止购买")
	                ui.setLabelString(self.coveritems.timeLab1, nil, 26)
	            end
	        end)
	    end 
        self.coveritems.timeLab1:setVisible(true)

        if self.coveritems.topbgnode then
            self.coveritems.topbgnode:setVisible(true)
        end 
           
    elseif self.status == 2 then
    	self.show = true
    	print("位置", self.contentsize.y-160, (GameScene.topposY-1620)*0.5 - 160)
    	self.coveritems.topNode:setPositionY(self.contentsize.y-160)
     	self.coveritems.multipleRebateNode:setPositionY((GameScene.topposY-1620)*0.5 + 60)    	
    	self.coveritems.statusNode2:setPositionY((GameScene.topposY-1620)*0.5 - 120)   

    	self.coveritems.statusNode1:setVisible(false)
    	self.coveritems.statusNode2:setVisible(true)

        if self.coveritems.topbgnode then
            self.coveritems.topbgnode:setVisible(false)
        end 
    	
    end
    -- 页签相关
    self:pageShow()
    -- 防止点击滚动页外还可以点击
    local function gettouchpos(pos)
        self.touchPos = pos
    end
    gameTouch:rigistFunc("begin","multipleRebate_magic",gettouchpos)
    --
    self:shiftPage(self.selectpage)
    return self.coverccb
end

function multipleRebate_magic.pageShow(self)
    -- 页签相关
    for k=1,4 do
        if self.pageconfig[k] then
            self.coveritems["buttontext"..k]:setVisible(true)
            self.coveritems["buttonsprite"..k]:setVisible(true)
            self.coveritems["buttontext"..k]:setString(self.pagename[k])

            self.coveritems["button"..k]:setSwallowsTouch(true)
            self.coveritems["button"..k]:setTouchPriority(self.buttontouch - 1)
            self.coveritems["button"..k]:addHandleOfControlEvent(function()
                self:shiftPage(self.pageconfig[k])
            end,CCControlEventTouchUpInside)
        else
            if not self.coveritems["buttontext"..k] then
            else
                self.coveritems["buttontext"..k]:setVisible(false)
                self.coveritems["buttonsprite"..k]:setVisible(false)
                self.coveritems["button"..k]:setTouchEnabled(false)
            end
        end
    end
end

function multipleRebate_magic.shiftPage(self, type)
	if type then
		self.selectpage = type
	end
    self.rebateTab = {}
    self:shiftlayerpage(self.selectpage)
	if self.selectpage == "rebate1" then
        self.page = 1 -- 标记页签
        self.rebateTab = {self.configWelfare[tostring(self.page)].limit, self.configWelfare[tostring(self.page)].coefficient}
		
	elseif self.selectpage == "rebate2" then
        self.page = 2
		self.rebateTab = {self.configWelfare[tostring(self.page)].limit, self.configWelfare[tostring(self.page)].coefficient}
	end
	if next(self.activationTab) ~= nil or next(self.signInTab) ~= nil then
		if self.status == 1 then
			self:onStatusNode1()
		elseif self.status == 2 then
			self:onStatusNode2()
		end		
	end

	self:onExplanation()
end

--按钮高亮状态的显示
function multipleRebate_magic.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if vm == page then
            setSpriteFrameByName(self.coveritems["buttonsprite"..km], gameConfig.images.pageButtonON)
            --self.coveritems["buttonnode"..km]:setZOrder(1)
        else
            setSpriteFrameByName(self.coveritems["buttonsprite"..km], gameConfig.images.pageButtonOFF)
            --self.coveritems["buttonnode"..km]:setZOrder(0)
        end
    end
end

function multipleRebate_magic.reloaddata(self, data)
	if self.status == 1 then -- 标记显示去激活or签到页面
		self:onStatusNode1(data)
	elseif self.status == 2 then
        --
        self.pageconfig = {}
        if data.data.activationBtnStatus1 ~= 0 then
            table.insert(self.pageconfig, self.copyPageconfig[1])
        end
        if data.data.activationBtnStatus2 ~= 0 then
            table.insert(self.pageconfig, self.copyPageconfig[2])
        end
        self.rebateTab = {}
        local pagename = self.selectpage or "rebate1"
        if data.data.activationBtnStatus1 ~= 0 and data.data.activationBtnStatus2 ~= 0 then
            if pagename == "rebate1" then
                self.selectpage = "rebate1"
                self.page = 1 -- 标记页签
                self.rebateTab = {self.configWelfare[tostring(self.page)].limit, self.configWelfare[tostring(self.page)].coefficient}
            else
                self.selectpage = "rebate2"
                self.page = 2
                self.rebateTab = {self.configWelfare[tostring(self.page)].limit, self.configWelfare[tostring(self.page)].coefficient}   
            end
        elseif data.data.activationBtnStatus1 ~= 0 and data.data.activationBtnStatus2 == 0 then
            self.selectpage = "rebate1"
            self.page = 1 -- 标记页签
            self.rebateTab = {self.configWelfare[tostring(self.page)].limit, self.configWelfare[tostring(self.page)].coefficient}
        elseif data.data.activationBtnStatus1 == 0 and data.data.activationBtnStatus2 ~= 0 then 
            self.pagename = {}
            self.selectpage = "rebate2"
            self.page = 2
            table.insert(self.pagename, self.configWelfare[tostring(self.page)].limit .. "基金")
            self.rebateTab = {self.configWelfare[tostring(self.page)].limit, self.configWelfare[tostring(self.page)].coefficient}            
        end
        self:pageShow()
        self:onExplanation()
        --
        self:onStatusNode2(data)
	end
    --
    self:shiftlayerpage(self.selectpage)
end

function multipleRebate_magic.onExplanation(self)
	local multiple1 = self.rebateTab[2]
	local recharge = self.rebateTab[1] .. "元"
	local multiple2 = self.rebateTab[2] .. "倍"
    local explanationText = nil

    if self.coveritems.multipleRebateLab1 and self.coveritems.multipleRebateLab2 then
        if multiple1 >= 20 then
            self.coveritems["multipleRebateLab1"]:setVisible(false)
            self.coveritems["multipleRebateLab2"]:setVisible(true)
        else
            self.coveritems["multipleRebateLab1"]:setVisible(true)
            self.coveritems["multipleRebateLab2"]:setVisible(false)
        end
    end    

	ui.setLabelString(self.coveritems.explanationLab, nil, 121) -- 描述
	ui.setLabelString(self.coveritems.rechargeLab, recharge, 21)
	ui.setLabelString(self.coveritems.multipleLab, multiple2, 21)

    ui.setLabelString(self.coveritems.buyLab, recharge, 19)

end

function multipleRebate_magic.onStatusNode1(self, info)
	if info then
		self.activationTab = info
	else

	end
	self.coveritems.eactivationNode:setVisible(true)
    --奖励预览
    self.coveritems.rewardsPreviewBtn:setTouchPriority(self.buttontouch)
    self.coveritems.rewardsPreviewBtn:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
    	gameWindows:openWindow("getStaff",{data = self.props,type = "奖励预览",desc = "每日可领取一种奖励"},nil)
    end, CCControlEventTouchUpInside)	
 
    local function onBtnShow(_type)
        if _type then
            self.coveritems.buyButton1:setSwallowsTouch(false)
            self.coveritems.yiJiHuoSpr:setVisible(true)
            self.coveritems.eactivationNode:setVisible(false)
            self.coveritems.buyButton1:setTouchEnabled(false)            
        else
            self.coveritems.buyButton1:setSwallowsTouch(true)
            self.coveritems.yiJiHuoSpr:setVisible(false)
            self.coveritems.eactivationNode:setVisible(true)
            self.coveritems.buyButton1:setTouchEnabled(true)  
        end
    end    
    if self.page == 1 then
        if self.activationTab.data.activationBtnStatus1 == 1 then -- 已激活
            onBtnShow(true)
	    else
            local _type = nil
		    if self.activationTab.data.activationBtnStatus1 == 0 then -- 未激活   
                _type = false
		    elseif self.activationTab.data.activationBtnStatus1 == 1 then -- 已激活
                _type = true
            else
                _type = true
		    end	 
            onBtnShow(_type)           		
    	end
	elseif self.page == 2 then
        if self.activationTab.data.activationBtnStatus2 == 1 then -- 已激活
            onBtnShow(true)
	    else
            local _type = nil
		    if self.activationTab.data.activationBtnStatus2 == 0 then -- 未激活
                _type = false
		    elseif self.activationTab.data.activationBtnStatus2 == 1 then -- 已激活
                _type = true
            else
                _type = true
		    end
            onBtnShow(_type)  
		end
    end

    -- 激活
    self.coveritems.buyButton1:setTouchPriority(self.buttontouch)
    self.coveritems.buyButton1:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
    	print("激活基金")
        -- gameWindows:openWindow("recharge",{pagetype = "info"})
        if sdk:isValid() then
            if self.page == 1 then
                UIRequest({type = 115, cid = 4, bagid = 21})
            elseif self.page == 2 then
                UIRequest({type = 115, cid = 6, bagid = 22})
            end
        else
            -- runGamePrompt({msg = "未接入充值渠道"})
            runGamePrompt({msg = gameConfig.strings:string_common("popups","change_qudao")})
        end

    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.coveritems.timeLab2, self.playerTimeLab .. "开启领奖", 121)

    local config = gamedata.config.month_growup_x3
    for i=1,table.getTableLength(config) do
    	local id, num = ui.getIDandNUM(config[tostring(i)]["reward"..self.page])
    	self.props[i] = {cid = id, num = num}
    end
end

function multipleRebate_magic.onStatusNode2(self, info)
    if not self.show then return end
    self.coveritems.scroll = tolua.cast(self.coveritems.scroll, "CCScrollView")
    self.coveritems.scroll:setTouchPriority(-103)
    self.coveritems.scroll:setContentOffset(ccp(0, -130))
    self.coveritems.scroll:setVisible(true)
    if info then
    	self.signInTab = info
    else
    	
    end
    if self.page == 1 then
	    if self.signInTab.data.btnStatus1 == 1 then -- 未领取
	        ui.removeGray("CCControlButton",self.coveritems["getButton"])
	        ui.removeGray("CCLabelTTF",self.coveritems["getLab"])
	        self.coveritems.getButton:setSwallowsTouch(true)	    	
	    elseif self.signInTab.data.btnStatus1 == 2 or self.signInTab.data.receiveDay1 >= self.day then -- 已领取
	        ui.addGray("CCControlButton",self.coveritems["getButton"])
	        ui.addGray("CCLabelTTF",self.coveritems["getLab"])
	        self.coveritems.getButton:setSwallowsTouch(false)
	    end
	    ui.setLabelString(self.coveritems.day, self.signInTab.data.receiveDay1, 22) -- self.data.daynum
	    if math.ceil((self.signInTab.data.receiveDay1+1)/5) > 2 then
            self.coveritems.scroll:setContentOffset(ccp(0, 0))
        end
    elseif self.page == 2 then
	    if self.signInTab.data.btnStatus2 == 1 then -- 未领取
	        ui.removeGray("CCControlButton",self.coveritems["getButton"])
	        ui.removeGray("CCLabelTTF",self.coveritems["getLab"])
	        self.coveritems.getButton:setSwallowsTouch(true)
	    elseif self.signInTab.data.btnStatus2 == 2 or self.signInTab.data.receiveDay2 >= self.day then -- 已领取
	        ui.addGray("CCControlButton",self.coveritems["getButton"])
	        ui.addGray("CCLabelTTF",self.coveritems["getLab"])
	        self.coveritems.getButton:setSwallowsTouch(false)
	    end	 
	    ui.setLabelString(self.coveritems.day, self.signInTab.data.receiveDay2, 22) -- self.data.daynum  
        if math.ceil((self.signInTab.data.receiveDay2+1)/5) > 2 then
            self.coveritems.scroll:setContentOffset(ccp(0, 0))
        end   	
    end	
	self.data = data or {}

    
    self.coveritems.getButton:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)
        if self.page == 1 then
            if self.signInTab.data.receiveDay1 >= self.day then
                runGamePrompt({msg = "奖励已全部领完"})
                return
            end
            if self.signInTab.data.btnStatus1 == 2 then
                if self.signInTab.data.receiveDay1 >= self.day then
                    runGamePrompt({msg = "奖励已全部领完"})
                else
                    runGamePrompt({msg = "今日已领取"})
                end
            else
                UIRequest({type = 3689, stalls = self.page})
            end
        elseif self.page == 2 then
            if self.signInTab.data.receiveDay2 >= self.day then
                runGamePrompt({msg = "奖励已全部领完"})
                return
            end
            if self.signInTab.data.btnStatus2 == 2 then
                if self.signInTab.data.receiveDay2 >= self.day then
                    runGamePrompt({msg = "奖励已全部领完"})
                else
                    runGamePrompt({msg = "今日已领取"})
                end
            else
                UIRequest({type = 3689, stalls = self.page})
            end
        end
    end, CCControlEventTouchUpInside)	
	self.coveritems.getButton:setTouchPriority(self.buttontouch)
	self.coveritems.getButton:setSwallowsTouch(true)

    ui.setLabelString(self.coveritems.getLab, nil, 18)	
	ui.setLabelString(self.coveritems.receiveLab, nil, 4)
	ui.setLabelString(self.coveritems.timeLab3, self.endTimeLab, 111)	
	
    local config = gamedata.config.month_growup_x3
    local oneData = {}
    local dayNum = nil
    for i=1,table.getTableLength(config) do
	    if config[tostring(i)] then	
	    	local id, num = ui.getIDandNUM(config[tostring(i)]["reward"..self.page])
	    	oneData = {
	    		has = true,
	    		cid = id,
	    		num = num,
	    		day = i,
	    	}
			if self.page == 1 then
				dayNum = self.signInTab.data.receiveDay1
			elseif self.page == 2 then
				dayNum = self.signInTab.data.receiveDay2
			end		    	
	    	self:setOneDay(self.coveritems, oneData, i-1, dayNum)
	    else
	    	self:setOneDay(self.coveritems,{has = false},i-1)
	    end
    end
end

function multipleRebate_magic.setOneDay(self, item, data, id, daynum)
	local key_Ex = nil
	if id == 0 or id == nil then
		key_Ex = ""
	else
		key_Ex = "_"..id
	end
	if not data.has then
		item["in_root"..key_Ex]:setVisible(false)
	else
        item["in_root"..key_Ex]:setVisible(true)
        ui.setNewIconName(item,data,id)
        item["in_name"..key_Ex]:setString(ui.IDconfig(data.cid).name or "")
        if data.day <= daynum then -- self.data.daynum
            item["in_usenode"..key_Ex]:setVisible(true)
        else
            item["in_usenode"..key_Ex]:setVisible(false)
        end

        item["in_button"..key_Ex]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if self.touchPos and not ui.isTouched(self.coveritems.scrollnode,self.touchPos.x,self.touchPos.y) then
            else
                ui.setPopwindowByCid(data.cid)
            end
        end, CCControlEventTouchUpInside)
        item["in_button"..key_Ex]:setTouchPriority(-101)

	end
end

function multipleRebate_magic.clear(self)
    if self.coverccb then   
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end
    self.selectpage = "rebate1"
    if gameTimer.times["multipleRebateTimer_magic"] then
        gameTimer:UnrigistTimeFunc("multipleRebateTimer_magic")
    end    
    self.touchPos = nil
    gameTouch:UnrigistFunc("begin","multipleRebate_magic")
    self.configWelfare = {}
    self.rebateTab = {}
	self.props = {}
	self.activationTab = {}
	self.signInTab = {}
    self.show = false
end


return multipleRebate_magic
