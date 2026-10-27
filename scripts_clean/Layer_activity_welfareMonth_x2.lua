--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/18
-- Time: 上午11:10
-- To change this template use File | Settings | File Templates.
--

local welfareMonth = {
	buttontouch = -103,
	receiveStatus = {},
	deadline = nil,
}

function welfareMonth.init(self, size)
	self.contentsize = size
    self.show = true
    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/yuechengzhang",nil, true, "yuechengzhang")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)

    local year, month, day, hour, min, sec = 0,0,0,0,0,0
    if gamedata.config.activity_time["118"]["open_type"] and gamedata.config.activity_time["118"]["open_type"] == 1 then
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        local timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["118"]["continued_time"] + (gamedata.config.activity_time["118"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        local temp1 = os.date("*t", timediff)
        year, month, day, hour, min, sec = temp1.year,temp1.month,temp1.day,temp1.hour,temp1.min,temp1.sec

    elseif gamedata.config.activity_time["118"]["end"] and gamedata.config.activity_time["118"]["end"] ~= "" then
        year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["118"]["end"])

    else
        self.deadline = ""
    end

    --local tab = {year = year, month = month, day = day, hour = hour, min = min, sec = sec, isdst = false}

    -- print("时间", tab.year, tab.month, tab.day, tab.hour, tab.min, tab.sec)
    --local addTime = gamedata.config.global_kv.monthfund_time.value * 24 * 60 * 60
    --local time = os.time(tab)
    --local time1 = time + addTime
    --local temp = os.date("*t", time1)-- task
    self.deadline = year .. "年" .. month .. "月" .. day .. "日" .. hour .. "时" --.. temp.min .. "分"

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(22)].generalanimation)].name
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local hero = CCSkeletonAnimation:create("nanzhujuewujie/nanzhujuewujie.json","nanzhujuewujie/nanzhujuewujie.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)  
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)

    
    self:onReceive()
    return self.coverccb
end

function welfareMonth.reloaddata(self, data)
	self.receiveStatus = {}
	self.receiveStatus = data

	for i=1,2 do
		self.coveritems["cell_" .. i]:setVisible(true)
		self.coveritems["doNode" .. i]:setVisible(true)
		self.coveritems["hasnode" .. i]:setVisible(false)	
		self.coveritems["doButton"..i]:setSwallowsTouch(true)	

		
		if self.receiveStatus.data["btnStatus" .. i] == 0 then
			-- 去充值
			self.coveritems["lavenum" .. i]:setString("剩余次数：1/1")
			ui.setLabelString(self.coveritems["doLab" .. i], "去充值", 18)
		elseif self.receiveStatus.data["btnStatus" .. i] == 1 then
			-- 未领取
			self.coveritems["lavenum" .. i]:setString("剩余次数：1/1")
			ui.setLabelString(self.coveritems["doLab" .. i], "领 取", 18)
		elseif self.receiveStatus.data["btnStatus" .. i] == 2 then
			-- 已领取
			self.coveritems["lavenum" .. i]:setString("剩余次数：0/1")
			self.coveritems["doNode" .. i]:setVisible(false)
			self.coveritems["hasnode" .. i]:setVisible(true)
			self.coveritems["doButton"..i]:setSwallowsTouch(false)
		end
	end
end

function welfareMonth.onReceive(self)
	--item["in_root"..key_Ex]:setVisible(false)
	local config = gamedata.config.month_welfare_x2
	-- print("月福利")
	-- printT(config)
	ui.setLabelString(self.coveritems.desc1, nil, 1)

	ui.setLabelString(self.coveritems.time1, self.deadline, 26)
	ui.setLabelString(self.coveritems.time2, self.deadline, 26)

	local key_Ex = 0
	for i=1,2 do
		local cid, num = ui.getIDandNUM(config[tostring(i)].reward)
		ui.setLabelString(self.coveritems["desc" .. (i + 1)], nil, 111)
		ui.setNewIcon(self.coveritems, {cid = cid, num = num}, i-1)
		-- 增加弹出窗口
		if i == 1 then
			key_Ex = ""
		else
			key_Ex = "_"..(i-1)
		end
        self.coveritems["i_button" .. key_Ex]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(cid) 
        end, CCControlEventTouchUpInside)
        self.coveritems["i_button" .. key_Ex]:setSwallowsTouch(true)
        self.coveritems["i_button" .. key_Ex]:setTouchPriority(self.buttontouch)	
        	
        self.coveritems["title"..i]:setString(config[tostring(i)].desc)
        self.coveritems["doButton"..i]:addHandleOfControlEvent(function()
        	-- print("领取奖励", self.receiveStatus.data["btnStatus" .. i])
			if self.receiveStatus.data["btnStatus" .. i] == 0 then
				-- 去充值
				gameWindows:openWindow("recharge",{pagetype = "info"})
			elseif self.receiveStatus.data["btnStatus" .. i] == 1 then
				-- 未领取
				UIRequest({type = 5534, receiveId = i})
			elseif self.receiveStatus.data["btnStatus" .. i] == 2 then
				-- 已领取
				
			end        	
        end, CCControlEventTouchUpInside)
        self.coveritems["doButton"..i]:setTouchPriority(self.buttontouch)
        self.coveritems["doButton"..i]:setSwallowsTouch(true)	
	end

	-- ui.setNewIconName(self.coveritems,{cid = 1001, num = num2}, 2)
end

function welfareMonth.clear(self)
    if self.coverccb then   
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end
    self.show = false
end


return welfareMonth