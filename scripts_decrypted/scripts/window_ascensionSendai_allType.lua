
local sendai_allType = {
    rootNode = nil,
    rootItems = nil,

    typeId = 1,
    selectId = 0, 
    dieOn = 0,    --复活标识

    data = {},

    selectData = {},
    showgenerals = {}, --伙伴镜像

    price = {0,0,0,0} --仙术价格
}

function sendai_allType.open(self,touchPriority,data,callback)

    self.data = data or {}
    self.typeId = data and data.id or 1

    if self.typeId == 1 then      --购买事件 buy
        self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/tc_sxt_selectyiwu", nil, true, "tc_sxt_selectyiwu")
    elseif self.typeId == 2 then  --选择仙术 buff
        self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/tc_sxt_selectxianshu", nil, true, "tc_sxt_selectxianshu")
    elseif self.typeId == 3 then  --助战伙伴 cheer
        self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/tc_sxt_selectzhuzhan", nil, true, "tc_sxt_selectzhuzhan")
    elseif self.typeId == 4 then  --仙遇事件 encounter
        self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/tc_sxt_xianyu", nil, true, "tc_sxt_xianyu")
    elseif self.typeId == 5 then  --恢复事件 recover
        self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/tc_sxt_huifu", nil, true, "tc_sxt_huifu")
        UIRequest({type = 8859})
    elseif self.typeId == 6 then  --复活事件 revive
        self.rootNode, self.rootItems = CCBReaderLoad("shengxiantai/tc_sxt_fuhuo", nil, true, "tc_sxt_fuhuo")
        UIRequest({type = 8859})
    end
    self.touchPriority = touchPriority
    self.callback = callback
    
    --
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        if self.typeId == 4 and self.selectId > 0 then
        else
            self.callback = nil
        end
        gameWindows:closeWindowDirect("sendai_allType")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
    --
    if self.typeId == 4 then
        --喝
        ui.setLabelString(self.rootItems.doLab1,nil,19)
        self.rootItems.doButton1:addHandleOfControlEvent(function()
            self:changeEncounterInfo(1)
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton1:setSwallowsTouch(true)
        self.rootItems.doButton1:setTouchPriority(self.touchPriority)
        --不喝
        ui.setLabelString(self.rootItems.doLab2,nil,19)
        self.rootItems.doButton2:addHandleOfControlEvent(function()
            self:changeEncounterInfo(2)
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton2:setSwallowsTouch(true)
        self.rootItems.doButton2:setTouchPriority(self.touchPriority)
        --确定
        ui.setLabelString(self.rootItems.doLab,nil,19)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            gameWindows:closeWindowDirect("sendai_allType")
            if self.callback then
                self.callback(self.selectId)
                self.selectId = 0
                self.callback = nil
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    else
        ui.setLabelString(self.rootItems.doLab,nil,19)
        self.rootItems.doButton:addHandleOfControlEvent(function()
            if self.typeId == 1 then
                if self.selectId > 0 then
                    if self.data.eventdata.sxynum < self.price[self.selectId] then
                        runGamePrompt({msg = "升仙玉不足"})
                        return
                    else
                        gameWindows:closeWindowDirect("sendai_allType")
                    end
                else
                    runGamePrompt({msg = "请任意选择一项"})
                    return
                end
            elseif self.typeId == 2 or self.typeId == 3 then
                if self.selectId > 0 then
                    gameWindows:closeWindowDirect("sendai_allType")
                else
                    runGamePrompt({msg = "请任意选择一项"})
                    return
                end
            else
                gameWindows:closeWindowDirect("sendai_allType")
            end
            if self.callback then
                if self.typeId == 5 or self.typeId == 6 then
                    self.callback(self.selectData, self.dieOn)
                    self.selectData = {}
                    self.dieOn = 0
                else
                    self.callback(self.selectId)
                    self.selectId = 0
                end
                self.callback = nil
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.doButton:setSwallowsTouch(true)
        self.rootItems.doButton:setTouchPriority(self.touchPriority)
    end

    self:reloadConfig(data)

    return self.rootNode
end

function sendai_allType.reloadData(self, data)
    self.showgenerals = data
    if self.typeId == 5 then
        self:showRecoverInfo(self.data.config)
    elseif self.typeId == 6 then
        self:showReviveInfo(self.data.config)
    end
end

function sendai_allType.reloadConfig(self, data)
    if data.id == 1 then
        self:showBuyInfo(data.config)
    elseif data.id == 2 then
        self:showBuffInfo(data.config)
    elseif data.id == 3 then
        self:showCheerInfo(data.config)
    elseif data.id == 4 then
        self:showEncounterInfo(data.config)
    elseif data.id == 5 then
        self:showRecoverInfo(data.config)
    elseif data.id == 6 then
        self:showReviveInfo(data.config)
    end
end

function sendai_allType.showBuyInfo(self, config)
    for i=1,4 do
        local bConfig = gamedata.config.breakskill[tostring(self.data.eventdata["buyBuffId"..i])]
        printT(bConfig,"jkp-bConfig")
        ui.setNewIcon(self.rootItems, {icon = bConfig.icon, quality = bConfig.quality}, i-1)

        local key_Ex
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        local quality = ((tonumber(bConfig.quality) >= 3) and bConfig.quality or 3)
        if quality > 5 then
            quality = 5
        end
        setSpriteFrameByName(self.rootItems["xianshu_bg"..key_Ex], "sxt_xianshu_"..quality)
        ui.setLabelString(self.rootItems["xianshu_name"..key_Ex], bConfig.name, ((bConfig.quality and bConfig.quality ~= 0) and bConfig.quality or 1)*2-1, 28)
        ui.setLabelString(self.rootItems["xianshu_des"..key_Ex], bConfig.desc, 18, 21)

        local buffData = ui.getIDRandNums(config.buffid)
        for j=1,#buffData do
            if tonumber(self.data.eventdata["buyBuffId"..i]) == buffData[j][1] then
                self.price[i] = buffData[j][3]
            end
        end
        self.rootItems["num"..i]:setString(self.price[i])
        --
        self.rootItems["selectBtn"..i]:addHandleOfControlEvent(function()
            for j=1,4 do
                self.rootItems["select"..j]:setVisible(false)
            end
            self.rootItems["select"..i]:setVisible(true)
            self.selectId = i
        end, CCControlEventTouchUpInside)
        self.rootItems["selectBtn"..i]:setSwallowsTouch(true)
        self.rootItems["selectBtn"..i]:setTouchPriority(self.touchPriority-5)
    end

    self.rootItems.sxb_num:setString(tostring(self.data.eventdata.sxynum))
end

function sendai_allType.showBuffInfo(self, config)
    for i=1,3 do
        local bConfig = gamedata.config.breakskill[tostring(self.data.eventdata["buffId"..i])]
        printT(bConfig,"jkp-bConfig")
        ui.setNewIcon(self.rootItems, {icon = bConfig.icon, quality = bConfig.quality}, i-1)

        local key_Ex
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        local quality = ((tonumber(bConfig.quality) >= 3) and bConfig.quality or 3)
        if quality > 5 then
            quality = 5
        end
        setSpriteFrameByName(self.rootItems["xianshu_bg"..key_Ex], "sxt_xianshu_"..quality)
        ui.setLabelString(self.rootItems["xianshu_name"..key_Ex], bConfig.name, ((bConfig.quality and bConfig.quality ~= 0) and bConfig.quality or 1)*2-1, 28)
        ui.setLabelString(self.rootItems["xianshu_des"..key_Ex], bConfig.desc, 18, 21)
        --
        self.rootItems["selectBtn"..i]:addHandleOfControlEvent(function()
            for j=1,3 do
                self.rootItems["select"..j]:setVisible(false)
            end
            self.rootItems["select"..i]:setVisible(true)
            self.selectId = i
        end, CCControlEventTouchUpInside)
        self.rootItems["selectBtn"..i]:setSwallowsTouch(true)
        self.rootItems["selectBtn"..i]:setTouchPriority(self.touchPriority-5)
    end
end

function sendai_allType.showCheerInfo(self, config)
    for i=1,4 do
        ui.setNewIconName(self.rootItems, { cid = self.data.eventdata["cheerId"..i] }, i-1)

        local key_Ex
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        self.rootItems["in_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
        self.rootItems["in_button"..key_Ex]:addHandleOfControlEvent(function()
            print("i = ", i) 
            for j=1,4 do
                local key_Jx
                if j == 1 then
                    key_Jx = ""
                else
                    key_Jx = "_"..(j-1)
                end
                self.rootItems["in_suitNode"..key_Jx]:removeAllChildrenWithCleanup(true)
            end
            local select_img = CCSprite:create("public/publicsprite/obj_select.png")
            self.rootItems["in_suitNode"..key_Ex]:addChild(select_img)
            self.selectId = i
        end, CCControlEventTouchUpInside)
        self.rootItems["in_button"..key_Ex]:setTouchPriority(self.touchPriority-5)
    end
end

function sendai_allType.showEncounterInfo(self, config)
    self.rootItems["desc"]:setString(config.desc)
    ui.setLabelString(self.rootItems.doLab1,config.button1,19)
    ui.setLabelString(self.rootItems.doLab2,config.button2,19)
end

function sendai_allType.changeEncounterInfo(self, index)
    self.selectId = index
    if index == 1 then --喝
        self.rootItems["desc"]:setString(self.data.config.talk1)
    elseif index == 2 then --不喝
        self.rootItems["desc"]:setString(self.data.config.talk2)
    end
    self.rootItems.doNode:setVisible(true)
    self.rootItems.doNode1:setVisible(false)
    self.rootItems.doNode2:setVisible(false)
end

function sendai_allType.showRecoverInfo(self, config)
    if self.showgenerals and next(self.showgenerals) then
        local aliveGenerals = {}
        for k,v in pairs(self.showgenerals) do
            if v.newhp > 0 then
                table.insert(aliveGenerals, v)
            end
        end
        local sortBy = function(a,b)
            return a.hp_ratio < b.hp_ratio
        end
        table.sort(aliveGenerals, sortBy)
        printT(aliveGenerals,"jkp-aliveGenerals")
        local tn = tonumber(table.getTableLength(aliveGenerals))
        local dn = tonumber(config.num)
        local num = ((tn < dn) and tn or dn)
        print("num = ", num)
        self.selectData = {}
        for i=1,num do
            table.insert(self.selectData, aliveGenerals[i].iid)
        end
        printT(self.selectData,"jkp-selectData")
    end
    self.rootItems.desc2:setString("生命最低伙伴恢复"..(config.percent*100).."%生命")
end

function sendai_allType.showReviveInfo(self, config)
    if self.showgenerals and next(self.showgenerals) then
        local dieGeneral = {}
        local sortBy = function(a,b)
            return a.hp_ratio < b.hp_ratio
        end
        table.sort(self.showgenerals, sortBy)
        printT(self.showgenerals,"jkp-showReviveInfo")
        self.selectData = {}

        for i=1,table.getTableLength(self.showgenerals) do
            if self.showgenerals[tostring(i)].newhp <= 0 then
                table.insert(dieGeneral, self.showgenerals[tostring(i)])
            end
        end

        if next(dieGeneral) then
            local tn = tonumber(table.getTableLength(dieGeneral))
            local dn = tonumber(config.num)
            local num = ((tn < dn) and tn or dn)
            if num == 1 then
                local prob = math.random(1, tonumber(table.getTableLength(dieGeneral)))
                table.insert(self.selectData, dieGeneral[prob].iid)
            else
                for i=1,num do
                    table.insert(self.selectData, dieGeneral[i].iid)
                end
            end
            self.dieOn = 1
        else
            local tn = tonumber(table.getTableLength(self.showgenerals))
            local dn = tonumber(config.num)
            local num = ((tn < dn) and tn or dn)
            print("num = ", num)
            for i=1,num do
                table.insert(self.selectData, self.showgenerals[tostring(i)].iid)
            end
            self.dieOn = 0
        end
        printT(self.selectData,"jkp-selectData")
        print("self.dieOn = ", self.dieOn)
    end

    self.rootItems.desc2:setString("随机复活一个伙伴；无伙伴可复活时，生命最低伙伴恢复"..(config.percent*100).."%生命")
end

function sendai_allType.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end

return sendai_allType

   �4  