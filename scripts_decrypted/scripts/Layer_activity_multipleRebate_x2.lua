--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/15
-- Time: 下午14:07
-- To change this template use File | Settings | File Templates.
--
local multipleRebate = {
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
}


function multipleRebate.init(self, size, status)
    self.configWelfare = gamedata.config.month_welfare_x2
    -- self.pagename = {configWelfare.limit[1] .. "基金",  .. "基金"}
    self.pagename = {}
    for k,v in pairs(self.configWelfare) do
        table.insert(self.pagename, v.limit .. "基金")
    end
    self.contentsize = size
    self.show = true
    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/yuefanli",nil, true, "rebate1")

    local year, month, day, hour, min, sec = 0,0,0,0,0,0
    local surplusTime = 0
    if gamedata.config.activity_time["117"]["open_type"] and gamedata.config.activity_time["117"]["open_type"] == 1 then
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["117"]["continued_time"] + (gamedata.config.activity_time["117"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        local temp1 = os.date("*t", timediff)
        year, month, day, hour, min, sec = temp1.year,temp1.month,temp1.day,temp1.hour,temp1.min,temp1.sec
    elseif gamedata.config.activity_time["117"]["end"] and gamedata.config.activity_time["117"]["end"] ~= "" then
        year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["117"]["end"])
    else
        self.status = 1
        self.playerTimeLab = ""
        self.endTimeLab = ""
    end

    local time1 = gamedata:time()
    local tab = {year = year, month = month, day = day, hour = hour, min = min, sec = sec, isdst = false}
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

    local addTime = gamedata.config.global_kv.monthfund_time_x2.value * 24 * 60 * 60
    local time = os.time(tab)
    local time1 = time + addTime
    local temp = os.date("*t", time1)
    self.endTimeLab = temp.year .. "年" .. temp.month .. "月" .. temp.day .. "日" .. temp.hour .. "时" .. temp.min .. "分"

    if self.status == 1 then
     	-- UIRequest({type = 2090, update = true})
     	self.coveritems.multipleRebateNode:setPositionY((GameScene.topposY-1620)*0.5 - 80)   	
     	self.coveritems.statusNode1:setPositionY((GameScene.topposY-1620)*0.5 - 90)
     	-- self.coveritems.topNode:setPositionY((GameScene.topposY-1620)*0.5 - 160) 
     	self.coveritems.topNode:setPositionY(self.contentsize.y-160)
     	self.coveritems.statusNode2:setVisible(false)
     	self.coveritems.statusNode1:setVisible(true)
     	-- self:onStatusNode1()
                            -- ReceiveCountdown
	    gameTimer:rigistTime("multipleRebateTimer",surplusTime) -- 注册时间
	    --活动时间
	    if gameTimer.times["multipleRebateTimer"] and gameTimer.times["multipleRebateTimer"] > 0 then
	        gameTimer:rigistTimeFunc("multipleRebateTimer", function()
	            if gameTimer.times["multipleRebateTimer"] <= 0 then
	            	self.status = 2
	                if gameTimer.times["multipleRebateTimer"] then
	                    gameTimer:UnrigistTimeFunc("multipleRebateTimer")
	                end
	            else
	                self.coveritems.timeLab1:setString(ui.makeTimeDayText(gameTimer.times["multipleRebateTimer"], "day").."后停止购买")
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
    	-- self.coveritems.topNode:setPositionY((GameScene.topposY-1620)*0.5 - 160) 
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
   --  -- 页签相关

   self:pageShow()
    -- 防止点击滚动页外还可以点击
    local function gettouchpos(pos)
        self.touchPos = pos
    end
    gameTouch:rigistFunc("begin","multipleRebate",gettouchpos)
    --

    self:shiftPage(self.selectpage)
    return self.coverccb
end

function multipleRebate.pageShow(self)
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

function multipleRebate.shiftPage(self, type)
	if type then
		self.selectpage = type
	end
    self.rebateTab = {}
    self:shiftlayerpage(self.selectpage)
	if self.selectpage == "rebate1" then
		-- self.rebateTab = {68, 10}
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
function  multipleRebate.shiftlayerpage(self,page)
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

function multipleRebate.reloaddata(self, data)
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
        
        if (data.data.activationBtnStatus1 ~= 0 and data.data.activationBtnStatus2 ~= 0) or data.data.activationBtnStatus1 ~= 0 then
            self.selectpage = "rebate1"
            self.page = 1 -- 标记页签
            self.rebateTab = {self.configWelfare[tostring(self.page)].limit, self.configWelfare[tostring(self.page)].coefficient}

        elseif data.data.activationBtnStatus2 ~= 0 then
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

function multipleRebate.onExplanation(self)
	local multiple1 = self.rebateTab[2]
	local recharge = self.rebateTab[1] .. "元"
	local multiple2 = self.rebateTab[2] .. "倍"
    local explanationText = nil
	self.coveritems.multipleRebateLab:setString(multiple1.."倍返利")

    if self.coveritems.multipleRebateLab1 and self.coveritems.multipleRebateLab2 then
        if multiple1 >= 20 then
            self.coveritems["multipleRebateLab1"]:setVisible(false)
            self.coveritems["multipleRebateLab2"]:setVisible(true)
        else
            self.coveritems["multipleRebateLab1"]:setVisible(true)
            self.coveritems["multipleRebateLab2"]:setVisible(false)
        end
    end    

    if gameConfig:checkBuildOpen(165) then
        explanationText = "同时激活月卡与高级月卡的用户单笔充值"
    end
	ui.setLabelString(self.coveritems.explanationLab, explanationText, 121) -- 描述
	ui.setLabelString(self.coveritems.rechargeLab, recharge, 21)
	ui.setLabelString(self.coveritems.multipleLab, multiple2, 21)

    if self.coveritems.explanationLab_x2 and self.coveritems.explanationLab_x3 then
        ui.setLabelString(self.coveritems.explanationLab_x2, nil, 121)     
        ui.setLabelString(self.coveritems.explanationLab_x3, nil, 121) 
    end 

end

function multipleRebate.onStatusNode1(self, info)
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

    local surplusStatus1 = self.activationTab.monthcard[tostring(1)] and self.activationTab.monthcard[tostring(1)].status or 0
    local surplusStatus2 = self.activationTab.monthcard[tostring(2)] and self.activationTab.monthcard[tostring(2)].status or 0    
    local function onBtnShow(_type)
        if _type then
            self.coveritems.eactivationBtn:setSwallowsTouch(false)
            -- self.coveritems.eactivationLab:setString("已激活")
            self.coveritems.yiJiHuoSpr:setVisible(true)
            self.coveritems.eactivationNode:setVisible(false)
            self.coveritems.eactivationBtn:setTouchEnabled(false)            
        else
            self.coveritems.eactivationBtn:setSwallowsTouch(true)
            -- self.coveritems.eactivationLab:setString("已激活")
            self.coveritems.yiJiHuoSpr:setVisible(false)
            self.coveritems.eactivationNode:setVisible(true)
            self.coveritems.eactivationBtn:setTouchEnabled(true)  
        end
    end    
    if self.page == 1 then
        if self.activationTab.data.activationBtnStatus1 == 1 then -- 已激活
                -- self.coveritems.eactivationBtn:setSwallowsTouch(false)
                -- self.coveritems.eactivationLab:setString("已激活")
                -- self.coveritems.yiJiHuoSpr:setVisible(true)
                -- self.coveritems.eactivationLab:setVisible(false)
                onBtnShow(true)
    	elseif surplusStatus1 == 0 or surplusStatus2 == 0 then
	    	self.coveritems.eactivationBtn:setSwallowsTouch(true)
	    	self.coveritems.eactivationLab:setString("去购买")

            if self.coveritems.eactivationLab1 and self.coveritems.eactivationLab2 then
                self.coveritems.eactivationLab1:setVisible(true)
                self.coveritems.eactivationLab2:setVisible(false)
            end

            onBtnShow(false)
	    else
            local _type = nil
		    if self.activationTab.data.activationBtnStatus1 == 0 then -- 未激活
		    	-- self.coveritems.eactivationBtn:setSwallowsTouch(true)
		    	self.coveritems.eactivationLab:setString("去激活")

                if self.coveritems.eactivationLab1 and self.coveritems.eactivationLab2 then
                    self.coveritems.eactivationLab1:setVisible(false)
                    self.coveritems.eactivationLab2:setVisible(true)
                end    

                _type = false
		    elseif self.activationTab.data.activationBtnStatus1 == 1 then -- 已激活
		    	-- self.coveritems.eactivationBtn:setSwallowsTouch(false)
		    	-- self.coveritems.eactivationLab:setString("已激活")
                -- self.coveritems.yiJiHuoSpr:setVisible(true)
                -- self.coveritems.eactivationLab:setVisible(false)
                _type = true
            else
                _type = true
		    end	 
            onBtnShow(_type)           		
    	end

	elseif self.page == 2 then
        if self.activationTab.data.activationBtnStatus2 == 1 then -- 已激活
                -- self.coveritems.eactivationBtn:setSwallowsTouch(false)
                -- self.coveritems.eactivationLab:setString("已激活")
                onBtnShow(true)
    	elseif surplusStatus1 == 0 or surplusStatus2 == 0 then
	    	self.coveritems.eactivationBtn:setSwallowsTouch(true)
	    	self.coveritems.eactivationLab:setString("去购买")
            if self.coveritems.eactivationLab1 and self.coveritems.eactivationLab2 then
                self.coveritems.eactivationLab1:setVisible(true)
                self.coveritems.eactivationLab2:setVisible(false)
            end  
            onBtnShow(false)  
	    else
            local _type = nil
		    if self.activationTab.data.activationBtnStatus2 == 0 then -- 未激活
		    	-- self.coveritems.eactivationBtn:setSwallowsTouch(true)
		    	self.coveritems.eactivationLab:setString("去激活")

                if self.coveritems.eactivationLab1 and self.coveritems.eactivationLab2 then
                    self.coveritems.eactivationLab1:setVisible(false)
                    self.coveritems.eactivationLab2:setVisible(true)
                end

                _type = false
		    elseif self.activationTab.data.activationBtnStatus2 == 1 then -- 已激活
		    	-- self.coveritems.eactivationBtn:setSwallowsTouch(false)
		    	-- self.coveritems.eactivationLab:setString("已激活")
                _type = true
            else
                _type = true
		    end
            onBtnShow(_type)  
		end
    end

    -- 激活
    self.coveritems.eactivationBtn:setTouchPriority(self.buttontouch)
    self.coveritems.eactivationBtn:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
    	if surplusStatus1 == 0 or surplusStatus2 == 0 then
    		print("去购买月卡")
             GameScene:shiftLayerById(35)
    	else
    		print("去激活基金")
            gameWindows:openWindow("recharge",{pagetype = "info"})
    	end
    	
    end, CCControlEventTouchUpInside)



    local explain = nil
    local otsukiCardText = nil
    local canBePurchasedText = "同时激活月卡及终身卡可购买"..self.rebateTab[1].."基金"
    if gameConfig:checkBuildOpen(165) then -- true  高级月卡 false 终身卡
        explain = self.rebateTab[1] .. "基金激活必须满足3个条件，即必须激活月卡、激活高级月卡和单笔充值" .. self.rebateTab[1] .. "元以上（充值没有顺序限制）才能激活"..self.rebateTab[1].."基金，" .. "三个条件缺一不可。" .. "\n" .. "此活动结束后立即开启资源领取通道，激活月基金的魔大大可在领取截止时间内累计获得20次资源（每天获得1次）。"
        otsukiCardText = "高级月卡："
        canBePurchasedText = "同时激活月卡及高级月卡可购买"..self.rebateTab[1].."基金"
        self.coveritems.otsukiCardLab:setPositionX(101)

    else
        explain = self.rebateTab[1] .. "基金激活必须满足3个条件，即必须激活月卡、激活终身卡和单笔充值" .. self.rebateTab[1] .. "元以上（充值没有顺序限制）才能激活"..self.rebateTab[1].."基金，" .. "三个条件缺一不可。" .. "\n" .. "此活动结束后立即开启资源领取通道，激活月基金的魔大大可在领取截止时间内累计获得20次资源（每天获得1次）。"
        otsukiCardText = "终身卡："
    end

    local explain2 = false
    if self.rebateTab[1] < 198 then
        explain2 = true
    end

    self.coveritems.aboutBtn:setTouchPriority(self.buttontouch)
    self.coveritems.aboutBtn:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        -- 
    	gameWindows:openWindow("multipleRebateHelp",{explain = explain, explain2 = explain2, title = "激活规则"}, nil)
    end, CCControlEventTouchUpInside)		
    local surplusDay1 = self.activationTab.monthcard[tostring(1)] and self.activationTab.monthcard[tostring(1)].restday or 0
    local surplusDay2 = self.activationTab.monthcard[tostring(2)] and self.activationTab.monthcard[tostring(2)].restday or 0
    ui.setLabelString(self.coveritems.satsukiCardLab, nil, 121) -- 小月卡
    ui.setLabelString(self.coveritems.otsukiCardLab, otsukiCardText, 121) -- 高级月卡&终身卡

    if surplusDay1 == 0 then
        ui.setLabelString(self.coveritems.surplusDayLab1, "未激活", 27)
    else
        ui.setLabelString(self.coveritems.surplusDayLab1, "已激活", 26)
    end
    if surplusDay2 > 0 then
        ui.setLabelString(self.coveritems.surplusDayLab2, "已激活", 26)
    else
        ui.setLabelString(self.coveritems.surplusDayLab2, "未激活", 27)
    end

    ui.setLabelString(self.coveritems.canBePurchasedLab, canBePurchasedText, 121)
    -- ui.setLabelString(self.coveritems.timeLab1, "12时12分12秒后停止购买", 26)
    ui.setLabelString(self.coveritems.timeLab2, self.playerTimeLab .. "开启领奖", 121)

    local config = gamedata.config.month_growup_x2
    for i=1,20 do
    	-- printT(config[tostring(i)])
    	local id, num = ui.getIDandNUM(config[tostring(i)]["reward"..self.page])
    	self.props[i] = {cid = id, num = num}
    end
end

function multipleRebate.onStatusNode2(self, info)
    if not self.show then return end
    self.coveritems.scroll = tolua.cast(self.coveritems.scroll, "CCScrollView")
    self.coveritems.scroll:setTouchPriority(-103)
    self.coveritems.scroll:setContentOffset(ccp(0, -320))
    self.coveritems.scroll:setVisible(true)
    if info then
    	self.signInTab = info
    else
    	
    end
    if self.page == 1 then
	    if self.signInTab.data.activationBtnStatus1 == 2 then -- 未领取
	        ui.removeGray("CCControlButton",self.coveritems["getButton"])
	        ui.removeGray("CCLabelTTF",self.coveritems["getLab"])
	        self.coveritems.getButton:setSwallowsTouch(true)	    	
	    elseif self.signInTab.data.activationBtnStatus1 == 3 or self.signInTab.data.receiveDay1 >= 20 then -- 已领取
	        ui.addGray("CCControlButton",self.coveritems["getButton"])
	        ui.addGray("CCLabelTTF",self.coveritems["getLab"])
	        self.coveritems.getButton:setSwallowsTouch(false)
	    end
	    ui.setLabelString(self.coveritems.day, self.signInTab.data.receiveDay1, 22) -- self.data.daynum
	    if math.ceil((self.signInTab.data.receiveDay1+1)/5) > 2 then
            self.coveritems.scroll:setContentOffset(ccp(0, 0))
        end
    elseif self.page == 2 then
	    if self.signInTab.data.activationBtnStatus2 == 2 then -- 未领取
	        ui.removeGray("CCControlButton",self.coveritems["getButton"])
	        ui.removeGray("CCLabelTTF",self.coveritems["getLab"])
	        self.coveritems.getButton:setSwallowsTouch(true)
	    elseif self.signInTab.data.activationBtnStatus2 == 3 or self.signInTab.data.receiveDay2 >= 20 then -- 已领取
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
            if self.signInTab.data.receiveDay1 >= 20 then
                runGamePrompt({msg = "奖励已全部领完"})
                return
            end
            if self.signInTab.data.activationBtnStatus1 == 3 then
                if self.signInTab.data.receiveDay1 >= 20 then
                    runGamePrompt({msg = "奖励已全部领完"})
                else
                    runGamePrompt({msg = "今日已领取"})
                end
            else
                UIRequest({type = 5532, stalls = self.page})
            end
        elseif self.page == 2 then
            if self.signInTab.data.receiveDay2 >= 20 then
                runGamePrompt({msg = "奖励已全部领完"})
                return
            end
            if self.signInTab.data.activationBtnStatus2 == 3 then
                if self.signInTab.data.receiveDay2 >= 20 then
                    runGamePrompt({msg = "奖励已全部领完"})
                else
                    runGamePrompt({msg = "今日已领取"})
                end
            else
                UIRequest({type = 5532, stalls = self.page})
            end
        end
    end, CCControlEventTouchUpInside)	
	self.coveritems.getButton:setTouchPriority(self.buttontouch)
	self.coveritems.getButton:setSwallowsTouch(true)

    ui.setLabelString(self.coveritems.getLab, nil, 18)	
	ui.setLabelString(self.coveritems.receiveLab, nil, 4)
	ui.setLabelString(self.coveritems.timeLab3, self.endTimeLab, 111)	
	
    local config = gamedata.config.month_growup_x2
    local oneData = {}
    local dayNum = nil
    for i=1,20 do
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

function multipleRebate.setOneDay(self, item, data, id, daynum)
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

function multipleRebate.clear(self)
    if self.coverccb then   
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end
    self.selectpage = "rebate1"
    if gameTimer.times["multipleRebateTimer"] then
        gameTimer:UnrigistTimeFunc("multipleRebateTimer")
    end    
    self.touchPos = nil
    gameTouch:UnrigistFunc("begin","multipleRebate")
    self.configWelfare = {}
    self.rebateTab = {}
	self.props = {}
	self.activationTab = {}
	self.signInTab = {}
    self.show = false
end


return multipleRebate
  �c  