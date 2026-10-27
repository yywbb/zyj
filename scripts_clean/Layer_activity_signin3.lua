--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/2
-- Time: 上午10:00
-- To change this template use File | Settings | File Templates.
--

local signin = {

    buttontouch = -103,

    data = {},
    date = {},

    selectpage = 1,

}


function signin.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitysignin_new/signin_new_n",nil, true, "signin_new")

    -- self.coveritems.topnode:setPositionY(self.contentsize.y)
    self.coveritems.adaptnode:setPositionY((GameScene.topposY-1620)*0.5)
    
    self.coveritems.luxuryNode:setPositionY((GameScene.topposY-1620)*0.5+540)
    self.coveritems.topnode:setPositionY((GameScene.topposY-1620)*0.5 + 1175 + 190)

	self.coveritems.everyDaySigninBtn:addHandleOfControlEvent(function()
		print("每日签到")
        if GameScene.layers["activity"].module.isContentScroll then  return end
        self.selectpage = 1
        UIRequest({type =3641})

	end, CCControlEventTouchUpInside)
    self.coveritems.everyDaySigninBtn:setSwallowsTouch(true)
    self.coveritems.everyDaySigninBtn:setTouchPriority(-104)

	self.coveritems.luxurySigninBtn:addHandleOfControlEvent(function()
		print("豪华签到")
        if GameScene.layers["activity"].module.isContentScroll then  return end
        self.selectpage = 2
		UIRequest({type =3643})

	end, CCControlEventTouchUpInside)
    self.coveritems.luxurySigninBtn:setSwallowsTouch(true)
    self.coveritems.luxurySigninBtn:setTouchPriority(-103)

    local function gettouchpos(pos)
        self.touchPos = pos
    end
    gameTouch:rigistFunc("begin","signin",gettouchpos)

    self.coveritems.scroll = tolua.cast(self.coveritems.scroll, "CCScrollView")
    self.coveritems.scroll:setTouchPriority(-103)
    self.coveritems.scroll:setContentOffset(ccp(0, -643))
    -- self.coveritems.scroll:setContentOffsetInDuration(ccp(0, -651),0)
    -- self.coveritems.scroll:setVisible(true)

    self.coveritems.container:setContentSize(CCSize(1080, 1410))
    self.scrollNode, self.scrollItems = CCBReaderLoad("activitysignin_new/signin_31day_n", nil, true, "map1")
    self.scrollNode:setPosition(0,0)
    self.scrollNode:setVisible(false)
    self.coveritems.container:addChild(self.scrollNode)

    self.selectpage = 1

    UIRequest({type =3643})

    return self.coverccb
end

function signin.setSigninStatus1(self, _visible)
    self.coveritems.everyBtnNode:setVisible(_visible)
    self.coveritems.adaptnode:setVisible(_visible)
    self.coveritems.luxurySigninBtn:setTouchEnabled(_visible)
end

function signin.setSigninStatus2(self, _visible)
    self.coveritems.luxuryBtnNode:setVisible(_visible)
    self.coveritems.luxuryNode:setVisible(_visible)
    self.coveritems.everyDaySigninBtn:setTouchEnabled(_visible)    
end

function signin.onLuxurySigninInterface(self, data)

    if data.status and data.status == 1 then
        self.coveritems.hint_sign2:setVisible(true)
    else
        self.coveritems.hint_sign2:setVisible(false)
    end

    if self.selectpage ~= 2 then
        return
    end

    self:setSigninStatus1(false)
    self:setSigninStatus2(true)

    local propnum = 0
    for i = 1,4 do
        if self.coveritems["s_prop"..i] then
            if data["itemId"..i] and data["itemId"..i] > 0 then
                propnum = propnum + 1
                self.coveritems["s_prop"..i]:setVisible(true)
                ui.setNewIcon(self.coveritems,{cid = data["itemId"..i], num = data["itemNum"..i]}, i-1)
                --
                self.coveritems["i_button"..((i>1) and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                    if GameScene.layers["activity"].module.isContentScroll then  return end
                    ui.setPopwindowByCid(data["itemId"..i])
                end, CCControlEventTouchUpInside)
                self.coveritems["i_button"..((i>1) and ("_"..(i-1)) or "")]:setTouchPriority(-101)
            else
                self.coveritems["s_prop"..i]:setVisible(false)
            end
        end
    end

    for i = 1,4 do
        if self.coveritems["s_prop"..i] then
            self.coveritems["s_prop"..i]:setPositionX(200*(i-1)-100*(propnum-1))
        end
    end

	ui.setLabelString(self.coveritems.rmbLab, nil, 47)
	ui.setLabelString(self.coveritems.descriptionLab, nil, 13)
    ui.removeGray("CCControlButton", self.coveritems.receiveBtn)
    self.coveritems.receiveBtn:setTouchEnabled(true)
	if data.status == 0 then
		ui.setLabelString(self.coveritems.receiveLab, "充 值", 19)
	elseif data.status == 1 then
		ui.setLabelString(self.coveritems.receiveLab, "领 取", 19)
	elseif data.status == 2 then
		ui.setLabelString(self.coveritems.receiveLab, "已经领取", 19)
        ui.addGray("CCControlButton", self.coveritems.receiveBtn)
        self.coveritems.receiveBtn:setTouchEnabled(false)
		-- btn变灰
	end
	if data.status ~= 2 then
		self.coveritems.receiveBtn:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
			if data.status == 0 then
				-- 跳充值
				gameWindows:openWindow("recharge",{pagetype = "info"})
			elseif data.status == 1 then
				-- 领取物品
				UIRequest({type = 3644})
			end
		end, CCControlEventTouchUpInside)
	    self.coveritems.receiveBtn:setSwallowsTouch(true)
	    self.coveritems.receiveBtn:setTouchPriority(-103)
	end

end

function signin.setOneDay(self,item,data,id)
    local key_Ex
    if id == nil or id == 0 then
        key_Ex = ""
    else
        key_Ex = "_"..id
    end
    item["in_geteffect"..key_Ex]:removeAllChildrenWithCleanup(true)

    if not data.has then
        item["in_root"..key_Ex]:setVisible(false)
    else
        item["in_root"..key_Ex]:setVisible(true)
        ui.setNewIconName(item,data,id)
        item["in_name"..key_Ex]:setString(ui.IDconfig(data.cid).name or "")
        --ui.setLabelString(item["in_day"..key_Ex], ui.IDconfig(data.cid).name or "", 11)

        item["animationNode" .. key_Ex]:setVisible(false)
        if self.data.status == 1 then

        elseif not self._config[tostring(self.data.daynum+1)] then

        else
            if data.day == self.data.daynum + 1 then
                item["animationNode" .. key_Ex]:setVisible(true)
            end
        end        
        if data.day <= self.data.daynum then
            item["in_usenode"..key_Ex]:setVisible(true)
            -- 
            ui.addGray("CCSprite", item["in_icon" .. key_Ex])
            ui.addGray("CCSprite", item["in_quality" .. key_Ex])
            ui.addGray("CCSprite", item["in_k_quality" .. key_Ex])
            ui.addGray("CCLabelTTF", item["in_name" .. key_Ex])
        else
            item["in_usenode"..key_Ex]:setVisible(false)
            ui.removeGray("CCSprite", item["in_icon" .. key_Ex])
            ui.removeGray("CCSprite", item["in_quality" .. key_Ex])
            ui.removeGray("CCSprite", item["in_k_quality" .. key_Ex])       
            ui.removeGray("CCLabelTTF", item["in_name" .. key_Ex])  
        end
        
        if data.vip > 0 and gameConfig:checkBuildOpen(154) then
            item["in_statusnode"..key_Ex]:setVisible(true)
            item["in_status"..key_Ex]:setString("贵族"..data.vip)
            ui.setLabelString(item["double" .. key_Ex], nil, 13)

        else
            item["in_statusnode"..key_Ex]:setVisible(false)
        end

        item["in_button"..key_Ex]:addHandleOfControlEvent(function()
            -- print("gametouch==",gameTouch.isScrollling)
            -- if gameTouch.isScrollling then return end
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if self.touchPos and not ui.isTouched(self.coveritems.scrollnode,self.touchPos.x,self.touchPos.y) then
            else
                ui.setPopwindowByCid(data.cid)
            end
        end, CCControlEventTouchUpInside)
        item["in_button"..key_Ex]:setTouchPriority(-101)
    end
end

function signin.reloaddata(self,data)

    self.date = os.date("*t", gamedata:time())
    local config = {}
    if self.date.month <10 then
        config = gamedata.config["sign2_"..self.date.year.."0"..self.date.month]
    else
        config = gamedata.config["sign2_"..self.date.year..self.date.month]
    end


    if data.status and data.status == 1 then
        self.coveritems.hint_sign1:setVisible(false)
    elseif not config[tostring(data.daynum+1)] then
        self.coveritems.hint_sign1:setVisible(false)
    else
        self.coveritems.hint_sign1:setVisible(true)
    end

    if self.selectpage ~= 1 then
        return
    end

    self:setSigninStatus1(true)
    self:setSigninStatus2(false)
    if not self.show then return end
    self.coveritems.getNode:setVisible(true)
    self.scrollNode:setVisible(true)
    -- self.coveritems.scroll = tolua.cast(self.coveritems.scroll, "CCScrollView")
    -- self.coveritems.scroll:setTouchPriority(-103)
    -- self.coveritems.scroll:setContentOffset(ccp(0, -651))
    -- -- self.coveritems.scroll:setVisible(true)

    -- self.scrollNode, self.scrollItems = CCBReaderLoad("activitysignin_new/signin_container", nil, true, "map1")
    -- self.scrollNode:setPosition(0,0)
    -- self.scrollNode:setVisible(false)
    -- self.coveritems.container:addChild(self.scrollNode)   
    --
    self.data = data or {}

    self.coveritems.month:setString(self.date.month.."月签到奖励")
    self.coveritems.day:setString(self.data.daynum)
    ui.setLabelString(self.coveritems.day, nil, 23)

    if math.ceil((self.data.daynum+1)/5) > 4 then
       self.coveritems.container:setPositionY(-188*(7-math.ceil((self.data.daynum+1)/5)))
    end

    self._config = config
    for i=1,35 do
        -- print("签到", config[tostring(i)])
        if config[tostring(i)] then
            local soulStatus = 0
            if i <= self.data.daynum then
                soulStatus = 0
            else
                soulStatus = 1
            end
            local id,num = ui.getIDandNUM(config[tostring(i)].award)
            local onedata = {
                has = true,
                cid = id,
                num = num,
                day = i,
                vip = 0,
                soulStatus = soulStatus,
            }
            if config[tostring(i)].double and config[tostring(i)].double == 1 then
                onedata.vip = config[tostring(i)].vip or 0
            end
            self:setOneDay(self.scrollItems, onedata,i-1)
        else
            self:setOneDay(self.scrollItems, {has = false},i-1)
        end
    end

    ui.setLabelString(self.coveritems.getLab, nil, 19)
    self.coveritems["getButton"]:addHandleOfControlEvent(function()
        -- print("signin")
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)
        if self.data.status == 1 then
            runGamePrompt({msg = "今日已签到"})
        elseif not config[tostring(self.data.daynum+1)] then
            runGamePrompt({msg = "本月签到已完成"})
        else
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3642})
        end
    end, CCControlEventTouchUpInside)
    self.coveritems["getButton"]:setSwallowsTouch(true)
    self.coveritems["getButton"]:setTouchPriority(-102)

    self.coveritems.buttoneffect:removeAllChildrenWithCleanup(true)
    if self.data.status == 1 then
        ui.addGray("CCControlButton",self.coveritems["getButton"])
        ui.addGray("CCLabelTTF",self.coveritems["getLab"])
    elseif not config[tostring(self.data.daynum+1)] then
        ui.addGray("CCControlButton",self.coveritems["getButton"])
        ui.addGray("CCLabelTTF",self.coveritems["getLab"])
    else
        ui.removeGray("CCControlButton",self.coveritems["getButton"])
        ui.removeGray("CCLabelTTF",self.coveritems["getLab"])
        local eccb,eitem = CCBReaderLoad("UIEffect/anniu/anniu_big", nil, true, "anniu_big")
        self.coveritems.buttoneffect:addChild(eccb)
    end


end

function signin.clear(self)
    self.selectpage = 1
    self.show = false
    self.touchPos = nil
    gameTouch:UnrigistFunc("begin","signin")
    self.data = {}
    self.coverccb = nil
    self.coveritems = nil
end

-- function signin.setPage(self)
--     -- UIRequest({type = 2000,page = GameScene.layers["activity"].module.type})
    
--     if self.coveritems.adaptnode:isVisible() then -- 0点刷新每日签到
--         self.coveritems.scroll = nil
--         UIRequest({type = 3641})
--     elseif self.coveritems.luxuryNode:isVisible() then -- 0点刷新豪华签到
--         UIRequest({type = 3643})
--     end
-- end

-- function signin.UIUpdateData(self, isreset)
--     print("更新签到")
--     if isreset then
--         self.data = {}
--         self:setPage()
--     end
-- end


return signin