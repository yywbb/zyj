--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/22
-- Time: 上午9:49
-- To change this template use File | Settings | File Templates.
--

local card = {

    buttontouch = -103,
    -- statusconfig = {
    --     [0] = "未购买",
    --     [1] = "领取",
    --     [2] = "已领取",
    --}
    statusconfig = {
        [0] = gameConfig.strings:string_common("buttontext","weigoumai"),
        [1] = gameConfig.strings:string_common("buttontext","lingqu"),
        [2] = gameConfig.strings:string_common("buttontext","yilingqu"),
    },
    png = { 
        [1] = "yueka_8.png",--购买
        [2] = "yueka_10.png",--续充
    },
}

function card.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/chaozhiyueka",nil, true, "activity_card")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.midnode:setPositionY((self.contentsize.y-180)/2)

    if gameConfig:checkBuildOpen(165) then
        if self.coveritems["restday98text"] then
            self.coveritems["restday98text"]:setVisible(false)
        end
    else
        if self.coveritems["98yueka"] then
            setSpriteFrameByName(self.coveritems["98yueka"], "98yueka_n_zhongshenka")
        end
    end



    -- self.coveritems.buylabel1:setString("购 买")
    -- self.coveritems.buylabel1:setString(gameConfig.strings:string_common("moreCommon","guomai"))
    -- ui.setLabelString(self.coveritems.buylabel1,nil,19)

    self.coveritems.buyButton_30:setTouchPriority(self.buttontouch)
    self.coveritems.buyButton_30:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end,CCControlEventTouchUpInside)

    self.coveritems.buyButton_98:setTouchPriority(self.buttontouch)
    self.coveritems.buyButton_98:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("recharge",{pagetype = "info"})
    end,CCControlEventTouchUpInside)

    ui.setLabelString(self.coveritems.des,self.coveritems.des:getString(),13)
    -- ui.setLabelString(self.coveritems.des,nil,14)
    -- ui.setLabelString(self.coveritems.des1,nil,13)
    -- ui.setLabelString(self.coveritems.des2,nil,21)
    -- ui.setLabelString(self.coveritems.des3,nil,26)
    -- ui.setLabelString(self.coveritems.des4,nil,13)
    -- ui.setLabelString(self.coveritems.des5,nil,21)
    -- ui.setLabelString(self.coveritems.des6,nil,26)


    return self.coverccb
end

function card.reloaddata(self,data)
    if not self.show then return end
    self.data = data
    -- self.coveritems.restday30:setString(self.data["1"].restday > 0 and ("月卡剩余: "..self.data["1"].restday.."天") or "")
    -- self.coveritems.restday98:setString(self.data["2"].restday > 0 and ("月卡剩余: "..self.data["2"].restday.."天") or "")
    -- if self.data["1"].restday > 0 then
    --     self.coveritems.restday30:setString(self.data["1"].restday)
    --     self.coveritems.restday30:setVisible(true)
    --     self.coveritems.restday30text:setVisible(true)
    -- else
    --     self.coveritems.restday30:setVisible(false)
    --     self.coveritems.restday30text:setVisible(false)
    -- end
    -- if self.data["2"].restday > 0 then
    --     self.coveritems.restday98:setString(self.data["2"].restday)
    --     self.coveritems.restday98:setVisible(true)
    --     self.coveritems.restday98text:setVisible(true)
    -- else
    --     self.coveritems.restday98:setVisible(false)
    --     self.coveritems.restday98text:setVisible(false)
    -- end
    -- ui.setLabelString(self.coveritems.restday30 ,self.data["1"].restday > 0 and (gameConfig.strings:laveDay(self.data["1"].restday)) or "", 14)
    -- ui.setLabelString(self.coveritems.restday98, self.data["2"].restday > 0 and (gameConfig.strings:laveDay(self.data["2"].restday)) or "", 14)

    -- ui.setLabelString(self.coveritems.desc1Text,nil,21)
    -- ui.setLabelString(self.coveritems.desc2Text,nil,21)

    self.coveritems.doButton1_30:setTouchPriority(self.buttontouch)
    self.coveritems.doButton1_98:setTouchPriority(self.buttontouch)

    self.coveritems.doButton1_30:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        UIRequest({type = 2091, cid = 1})
    end, CCControlEventTouchUpInside)

    self.coveritems.doButton1_98:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        UIRequest({type = 2091, cid = 2})
    end, CCControlEventTouchUpInside)

    if self.coveritems.doButton2_30 and self.coveritems.doButton2_98 then
        self.coveritems.doButton2_30:setTouchPriority(self.buttontouch)
        self.coveritems.doButton2_98:setTouchPriority(self.buttontouch)
        --
        self.coveritems.doButton2_30:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = "今日已领取"})
        end, CCControlEventTouchUpInside)
        --
        self.coveritems.doButton2_98:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = "今日已领取"})
        end, CCControlEventTouchUpInside)
    end

    self:setShowBuyButtonType(30,self.data["1"].status,self.data["1"].restday)    
    self:setShowBuyButtonType(98,self.data["2"].status,self.data["2"].restday)      
    -- if self.data["1"].status ==0 then
    --     -- self.coveritems.hasbuy30:setVisible(false)
    --     -- self.coveritems.doLab30:setVisible(false)
    --     -- self.coveritems.doButton30:setVisible(false)
    --     -- self.coveritems.monthlqNode:setVisible(false)
    --     -- self.coveritems.monthwgNode:setVisible(true)

    --     -- 以上为原来代码
    --     -- 未购买
    --     self.coveritems.buyButton1:setVisible(true)
    --     self.coveritems.alreadybuyNode:setVisible(false)

    --     --self.coveritems.doLab30:setString("购买")
    --     -- self.coveritems.doLab30:setString(gameConfig.strings:string_common("buttontext","goumai"))
    --     -- ui.setLabelString(self.coveritems.doLab30,nil,19)
    --     -- ui.removeGray("CCControlButton",self.coveritems.doButton30)
    --     -- ui.removeGray("CCLabelTTF",self.coveritems.doLab30)
    --     -- self.coveritems.doButton30:addHandleOfControlEvent(function()
    --     --     if GameScene.layers["activity"].module.isContentScroll then  return end
    --     --     --GameScene:shiftLayer("recharge","up")
    --     --     gameWindows:openWindow("recharge",{pagetype = "info"})
    --     -- end, CCControlEventTouchUpInside)
    -- elseif self.data["1"].status ==1 then
    --     -- self.coveritems.hasbuy30:setVisible(true)
    --     --self.coveritems.doLab30:setString("领取")
    --     -- self.coveritems.doLab30:setString(gameConfig.strings:string_common("buttontext","lingqu"))
    --     -- self.coveritems.monthlqNode:setVisible(false)
    --     -- self.coveritems.monthwgNode:setVisible(false)


    --     -- 以上为原来代码
    --     -- 购买领取
    --     self.coveritems.buyButton1:setVisible(false)
    --     self.coveritems.alreadybuyNode:setVisible(true)
    --     self.coveritems.getNode:setVisible(true)
    --     self.coveritems.gettedNode:setVisible(false)
        



    --     -- ui.removeGray("CCControlButton",self.coveritems.doButton30)
    --     -- ui.removeGray("CCLabelTTF",self.coveritems.doLab30)
    --     -- ui.setLabelString(self.coveritems.doLab30,nil,19)
    --     self.coveritems.doButton30:addHandleOfControlEvent(function()
    --         if GameScene.layers["activity"].module.isContentScroll then  return end
    --         UIRequest({type = 2091, cid = 1})
    --     end, CCControlEventTouchUpInside)
    -- elseif self.data["1"].status ==2 then
    --     -- self.coveritems.hasbuy30:setVisible(true)
    --     -- self.coveritems.doLab30:setVisible(false)
    --     -- self.coveritems.doButton30:setVisible(false)
    --     -- self.coveritems.monthlqNode:setVisible(true)
    --     -- self.coveritems.monthwgNode:setVisible(false)


    --     -- 以上为原来代码
    --     -- 购买已领取
    --     self.coveritems.buyButton1:setVisible(false)
    --     self.coveritems.alreadybuyNode:setVisible(true)
    --     self.coveritems.getNode:setVisible(false)
    --     self.coveritems.gettedNode:setVisible(true)

    --     --self.coveritems.doLab30:setString("领取")
    --     -- self.coveritems.doLab30:setString(gameConfig.strings:string_common("buttontext","lingqu"))
    --     -- ui.setLabelString(self.coveritems.doLab30,nil,19)
    --     -- ui.addGray("CCControlButton",self.coveritems.doButton30)
    --     -- ui.addGray("CCLabelTTF",self.coveritems.doLab30)

    --     -- self.coveritems.doButton30:addHandleOfControlEvent(function()
    --     --     if GameScene.layers["activity"].module.isContentScroll then  return end
    --     --     --runGamePrompt({msg = "今日已领取"})
    --     --     runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",2)})
    --     -- end, CCControlEventTouchUpInside)
    -- end

    -- if self.data["2"].status ==0 then
    --     -- self.coveritems.hasbuy98:setVisible(false)
    --     -- self.coveritems.doLab98:setVisible(false)
    --     -- self.coveritems.doButton98:setVisible(false)
    --     -- self.coveritems.cmonthlqNode:setVisible(false)
    --     -- self.coveritems.cmonthwgNode:setVisible(true)


    --     -- 以上为原来代码
    --     -- 未购买
    --     self.coveritems.buyButton2:setVisible(true)
    --     self.coveritems.alreadybuyNode2:setVisible(false)
    --     --self.coveritems.doLab98:setString("购买")
    --     -- self.coveritems.doLab98:setString(gameConfig.strings:string_common("buttontext","goumai"))
    --     -- ui.setLabelString(self.coveritems.doLab98,nil,19)
    --     -- ui.removeGray("CCControlButton",self.coveritems.doButton98)
    --     -- ui.removeGray("CCLabelTTF",self.coveritems.doLab98)
    --     -- self.coveritems.doButton98:addHandleOfControlEvent(function()
    --     --     if GameScene.layers["activity"].module.isContentScroll then  return end
    --     --     --GameScene:shiftLayer("recharge","up")
    --     --     gameWindows:openWindow("recharge",{pagetype = "info"})
    --     -- end, CCControlEventTouchUpInside)
    -- elseif self.data["2"].status ==1 then
    --     -- self.coveritems.hasbuy98:setVisible(true)
    --     -- --self.coveritems.doLab98:setString("领取")
    --     -- self.coveritems.doLab98:setString(gameConfig.strings:string_common("buttontext","lingqu"))
    --     -- self.coveritems.cmonthlqNode:setVisible(false)
    --     -- self.coveritems.cmonthwgNode:setVisible(false)
    --     -- ui.setLabelString(self.coveritems.doLab98,nil,19)


    --     -- 以上为原来代码
    --     -- 购买领取
    --     self.coveritems.buyButton2:setVisible(false)
    --     self.coveritems.alreadybuyNode2:setVisible(true)
    --     self.coveritems.getNode2:setVisible(true)
    --     self.coveritems.gettedNode2:setVisible(false)
    --     -- ui.removeGray("CCControlButton",self.coveritems.doButton98)
    --     -- ui.removeGray("CCLabelTTF",self.coveritems.doLab98)
    --     self.coveritems.doButton98:addHandleOfControlEvent(function()
    --         if GameScene.layers["activity"].module.isContentScroll then  return end
    --         UIRequest({type = 2091, cid = 2})
    --     end, CCControlEventTouchUpInside)
    -- elseif self.data["2"].status ==2 then
    --     -- self.coveritems.hasbuy98:setVisible(true)
    --     -- self.coveritems.doLab98:setVisible(false)
    --     -- self.coveritems.doButton98:setVisible(false)
    --     -- self.coveritems.cmonthlqNode:setVisible(true)
    --     -- self.coveritems.cmonthwgNode:setVisible(false)

    --     -- 以上为原来代码
    --     -- 购买已领取
    --     self.coveritems.buyButton2:setVisible(false)
    --     self.coveritems.alreadybuyNode2:setVisible(true)
    --     self.coveritems.getNode2:setVisible(false)
    --     self.coveritems.gettedNode2:setVisible(true)
    --     --self.coveritems.doLab98:setString("领取")
    --     -- self.coveritems.doLab98:setString(gameConfig.strings:string_common("buttontext","lingqu"))
    --     -- ui.setLabelString(self.coveritems.doLab98,nil,19)
    --     -- ui.addGray("CCControlButton",self.coveritems.doButton98)
    --     -- ui.addGray("CCLabelTTF",self.coveritems.doLab98)
    --     -- self.coveritems.doButton98:addHandleOfControlEvent(function()
    --     --     if GameScene.layers["activity"].module.isContentScroll then  return end
    --     --     --runGamePrompt({msg = "今日已领取"})
    --     --     runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",2)})
    --     -- end, CCControlEventTouchUpInside)
    -- end

    if self.coveritems.giftButton_30 and self.coveritems.giftButton_98 then
        self.coveritems.giftButton_30:setTouchPriority(self.buttontouch)
        self.coveritems.giftButton_98:setTouchPriority(self.buttontouch)
        --
        local gift30,gift98 = {},{}
        if gamedata.config.recharge["1"] and gamedata.config.recharge["1"].daygift then
            gift30 = ui.getIDandNUMs(gamedata.config.recharge["1"].daygift) or {}
            if gamedata.config.recharge["1"].daygold and gamedata.config.recharge["1"].daygold > 0 then
                table.insert(gift30,{cid = 1001,num = gamedata.config.recharge["1"].daygold})
            end
        end    
        if gamedata.config.recharge["2"] and gamedata.config.recharge["2"].daygift then
            gift98 = ui.getIDandNUMs(gamedata.config.recharge["2"].daygift) or {}
            if gamedata.config.recharge["2"].daygold and gamedata.config.recharge["2"].daygold > 0 then
                table.insert(gift98,{cid = 1001,num = gamedata.config.recharge["2"].daygold})
            end
        end   
        self.coveritems.giftButton_30:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("getStaff",{data = gift30,type = "超值礼包"},nil)
        end, CCControlEventTouchUpInside)
        --
        self.coveritems.giftButton_98:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("getStaff",{data = gift98,type = "豪华礼包"},nil)
        end, CCControlEventTouchUpInside)
    end

end

function card.clear(self)
    self.show = false
    self.data = nil
    self.coverccb = nil
    self.coveritems = nil
end

-- function card.setPage(self)
--     -- UIRequest({type = 2000,page = GameScene.layers["activity"].module.type})
--     UIRequest({type = 2090})
-- end

-- function card.UIUpdateData(self, isreset)
--     if isreset then
--         self.data = nil
--         self:setPage()
--     end
-- end

--设置构面按钮显示
    --aiButton 是30：30卡 98：98卡 
    --aiType
function card.setShowBuyButtonType(self,aiButton,aiType,aiDays)
    if aiType == 0 then --未购买
        self.coveritems["textspr"..aiButton]:setVisible(true)
        setSpriteFrameByName(self.coveritems["textspr"..aiButton],self.png[1])
        self.coveritems["buyButton_"..aiButton]:setVisible(true)
        self.coveritems["buyButton_"..aiButton]:setTouchEnabled(true)
        self.coveritems["alreadybuyNode_"..aiButton]:setVisible(false)
        self.coveritems["doButton1_"..aiButton]:setTouchEnabled(false)
        if self.coveritems["doButton2_"..aiButton] then
            self.coveritems["doButton2_"..aiButton]:setTouchEnabled(false)
        end    
    elseif aiType == 1 then --可以领取
        self.coveritems["textspr"..aiButton]:setVisible(false)
        self.coveritems["buyButton_"..aiButton]:setVisible(false)
        self.coveritems["buyButton_"..aiButton]:setTouchEnabled(false)
        self.coveritems["alreadybuyNode_"..aiButton]:setVisible(true)
        self.coveritems["doButton1_"..aiButton]:setTouchEnabled(true) 
        self.coveritems["restday"..aiButton]:setString(aiDays or 0) 
        self.coveritems["getNode1_"..aiButton]:setVisible(true)
        self.coveritems["getNode2_"..aiButton]:setVisible(false)
        if self.coveritems["doButton2_"..aiButton] then
            self.coveritems["doButton2_"..aiButton]:setTouchEnabled(false)
        end    
    elseif aiType == 2 then --and aiDays and aiDays > 7 then --已经领取
        self.coveritems["textspr"..aiButton]:setVisible(false)
        self.coveritems["buyButton_"..aiButton]:setVisible(false)
        self.coveritems["buyButton_"..aiButton]:setTouchEnabled(false)
        self.coveritems["alreadybuyNode_"..aiButton]:setVisible(true)
        self.coveritems["doButton1_"..aiButton]:setTouchEnabled(false) 
        self.coveritems["restday"..aiButton]:setString(aiDays or 0)   
        self.coveritems["getNode1_"..aiButton]:setVisible(false)
        self.coveritems["getNode2_"..aiButton]:setVisible(true)
        if self.coveritems["doButton2_"..aiButton] then
            self.coveritems["doButton2_"..aiButton]:setTouchEnabled(true)
        end         
    -- elseif aiType == 2 and aiDays and aiDays <= 7 then --已经领取
    --     self.coveritems["textspr"..aiButton]:setVisible(true)
    --     setSpriteFrameByName(self.coveritems["textspr"..aiButton],self.png[2])
    --     self.coveritems["buyButton_"..aiButton]:setVisible(true)
    --     self.coveritems["buyButton_"..aiButton]:setTouchEnabled(true)
    --     self.coveritems["alreadybuyNode_"..aiButton]:setVisible(true)
    --     self.coveritems["restday"..aiButton]:setString(aiDays or 0) 
    --     self.coveritems["doButton1_"..aiButton]:setTouchEnabled(false) 
    --     self.coveritems["getNode1_"..aiButton]:setVisible(false)
    --     self.coveritems["getNode2_"..aiButton]:setVisible(false)          
    end
end

return card