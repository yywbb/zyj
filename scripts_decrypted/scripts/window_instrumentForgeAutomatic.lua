--

--

local instrumentForgeAutomatic = {
    rootNode = nil,
    rootItems = nil,

    ListTableView = nil,

    cid = 0,
    iid = 0,
    donum = 0,

    method = 0,

    status = {},
    status1 = 0,
    status2 = 0,
    status3 = 0,
    status4 = 0,
    status5 = 0,

    costcid = 0,
    costnum = 0,
    stonecid = 20270,
    stonenum = 0,

    hasstonenum = 0,

    isfull = false,
    doButtonNum = 0,
}

function instrumentForgeAutomatic.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("magic/zidongduanzao", nil, true, "zidongduanzao")

    self.touchPriority = touchPriority
    self.callback = callback

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.donum,self.touchPriority,function (num)
        self.donum = 0
        self:numchange(num)
    end)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("instrumentForgeAutomatic")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("zidong_rule",{doType= 2},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:setTouchPriority(self.touchPriority)


    -- self.rootItems.add10:addHandleOfControlEvent(function()
    --     self:numchange(10)
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.add10:setSwallowsTouch(true)
    -- self.rootItems.add10:setTouchPriority(self.touchPriority)


    -- self.rootItems.sub10:addHandleOfControlEvent(function()
    --     self:numchange(-10)
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.sub10:setSwallowsTouch(true)
    -- self.rootItems.sub10:setTouchPriority(self.touchPriority)

    local add10 = function()
        self:numchange(10)
    end
    local sub10 = function()
        self:numchange(-10)
    end

    ui.creatDelayButton(self.rootItems["add10"],self.touchPriority,add10)
    ui.creatDelayButton(self.rootItems["sub10"],self.touchPriority,sub10)


    ui.setLabelString(self.rootItems.doLab,"开始锻造",18)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.donum > 0 then
            gameTouch:clickprofbytime(2)
            self.doButtonNum = self.donum/10 
            UIRequest({type = 1364,iid = self.iid,method = self.method,xlnum = self.donum,status1 = self.status1,status2 = self.status2,status3 = self.status3,status4 = self.status4,status5 = self.status5, tuPoStatus = self.tuPoStatus})
        else
            runGamePrompt({msg = "请选择次数"})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    self.cid = data.cid or 0
    self.iid = data.iid or 0
    self.method = data.method or 2
    self.tuPoStatus =data.tuPoStatus or 0
    self.g_gold =  data.g_gold or 0

    local xprop 
    if self.tuPoStatus > 0 then
        xprop = ui.getIDandNUMs(gamedata.config.artifact_xian_config[tostring(self.iid)][tostring(self.tuPoStatus)]["forging_consume"..self.method])
    else
        xprop = ui.getIDandNUMs(tostring(gamedata.config.global_kv["artifact_consume_"..self.method].value))
    end    

    printT(xprop,"xprop")
    for k,v in pairs(xprop) do
        if v.cid == 1000 then
            self.costcid = 1000
            self.costnum = v.num or 0
            setSpriteFrameByName(self.rootItems["cost1"], "obj_s_coin")
        elseif v.cid == 1001 then
            self.costcid = 1001
            self.costnum = v.num or 0
            setSpriteFrameByName(self.rootItems["cost1"], "obj_s_gold")
        elseif v.cid == 20270 then
            self.stonecid = 20270
            self.stonenum = v.num or 0
        elseif v.cid == 1025 then
            self.costcid = 1025
            self.costnum = v.num
            self.rootItems["g_gold"]:setVisible(true)
            self.rootItems["cost1"]:setVisible(false)
        end
    end

    -- todo
    self.equipConfig = gamedata.config.artifact[tostring(self.iid)]
    local attr = "attr"
    local init = "init"
    if self.tuPoStatus >0 then
        self.equipConfig = gamedata.config.artifact_xian_config[tostring(self.iid)][tostring(self.tuPoStatus)]
    end    
 
    for i = 1,5 do
        if self.rootItems["attr"..i] then
            if self.rootItems["attrnode"..i] then
                self.rootItems["attrnode"..i]:setVisible(true)
            end    
            ui.setLabelString(self.rootItems["attr"..i], nil, 14)
            if self.equipConfig[attr..i] and self.equipConfig[attr..i] ~= "" then
                ui.setLabelString(self.rootItems["attr"..i], gameConfig.strings.attr_type[self.equipConfig[attr..i]], 14)
            elseif i < 5 then
                if self.rootItems["attrnode"..i] then
                    self.rootItems["attrnode"..i]:setVisible(false)
                end
            end
            self.rootItems["attrstatus"..i]:setVisible(self["status"..i] == 1)
            self.rootItems["attrButton"..i]:addHandleOfControlEvent(function()
                if self["status"..i] == 1 then
                    self["status"..i] = 0
                else
                    self["status"..i] = 1
                end
                self.rootItems["attrstatus"..i]:setVisible(self["status"..i] == 1)
            end, CCControlEventTouchUpInside)
            self.rootItems["attrButton"..i]:setSwallowsTouch(true)
            self.rootItems["attrButton"..i]:setTouchPriority(self.touchPriority)
        end    
    end
    --
    ui.setLabelString(self.rootItems.fixstr1, nil, 21)
    ui.setLabelString(self.rootItems.fixstr2, nil, 21)
    ui.setLabelString(self.rootItems.fixstr4, nil, 14)
    ui.setLabelString(self.rootItems.fixstr5, nil, 14)

    --
    self:initnum(10)
    --
    UIRequest({type = 12001, order = 11004, cids = {20270}})
    --

    --list
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(900, 220)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("magic/cell_zidongduanzao", nil, true, "cell_zidongduanzao")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            data =  self.status[tostring(a1+1)] or {}


 
      

            if data.method and data.method == 1 then

                if  self.rnum == a1+1 and  self.rnum < self.doButtonNum then
                    self.isfull = true
                else
                    self.isfull = false      
                end 
                if self.isfull then
                     ui.setLabelString(ccbDocumentControler["x_status"], "已满！", 3)
                     ccbDocumentControler["x_status"]:setColor(ccc3(255,153,45))

                else    
                     ccbDocumentControler["x_status"]:setColor(ccc3(84,255,8))
                     ui.setLabelString(ccbDocumentControler["x_status"], "已保存！", 3)
                end    
            else
                ui.setLabelString(ccbDocumentControler["x_status"], "未保存！", 11)
                ccbDocumentControler["x_status"]:setColor(ccc3(255,8,8))

            end
            self.isfull = false
            ui.setLabelString(ccbDocumentControler["x_title"],"第"..(a1+1).."次".." (锻造x10)",14)

            --todo
            local equipConfig = gamedata.config.artifact[tostring(self.iid)]
            local attr = "attr"
            local init = "init"
            if self.tuPoStatus > 0 then
                equipConfig =  gamedata.config.artifact_xian_config[tostring(self.iid)][tostring(self.tuPoStatus)]
            end

            for i = 1,4 do
                if data["num"..i] > 0 then
                    ui.setLabelString(ccbDocumentControler["num"..i], "+"..data["num"..i], 4)
                elseif data["num"..i] < 0 then
                    ui.setLabelString(ccbDocumentControler["num"..i], data["num"..i], 12)
                else
                    ui.setLabelString(ccbDocumentControler["num"..i], "+0", 13)
                end
                if equipConfig[attr..i] and equipConfig[attr..i] ~= "" then
                    ui.setLabelString(ccbDocumentControler["x_attr"..i], gameConfig.strings.attr_type[equipConfig[attr..i]], 13)
                else
                   ui.setLabelString(ccbDocumentControler["x_attr"..i], "", 13)
                   ui.setLabelString(ccbDocumentControler["num"..i], "", 13)
                end
            end

            cellCCB:setPosition(900/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.status)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
    --


    return self.rootNode
end


function instrumentForgeAutomatic.initnum(self,num)
    self.donum = num
    --
    self.rootItems.donum:setString(self.donum)
    ui.setLabelString(self.rootItems.costnum1, self.costnum*self.donum, 14)
    ui.setLabelString(self.rootItems.costnum2, self.stonenum*self.donum, 14)
end

function instrumentForgeAutomatic.numchange(self,num)

    local donum = self.donum + num

    local maxnum = 200
    if gamedata.config.global_kv["artifact_leve_limit"] and tonumber(gamedata.config.global_kv["artifact_leve_limit"].value) <= GameScene.roleinfo.level then
        if gamedata.config.global_kv["automatic_artifact_number"] and tonumber(gamedata.config.global_kv["automatic_artifact_number"].value) > 0 then
            maxnum = tonumber(gamedata.config.global_kv["automatic_artifact_number"].value)
        end
    end     

    if donum < 0 then return end
    if donum > maxnum then return end

    local needcostnum = self.costnum*donum or 0
    local needstonenum = self.stonenum*donum or 0

    if needstonenum > self.hasstonenum then
        runGamePrompt({msg = ui.IDconfig(self.stonecid).name.."不足"})
    elseif (self.costcid == 1000) and (needcostnum > GameScene.roleinfo.coin) then
        runGamePrompt({msg = "银币不足"})
    elseif (self.costcid == 1001) and (needcostnum > GameScene.roleinfo.gold) then
        runGamePrompt({msg = "元宝不足"})
    elseif (self.costcid == 1025) and (needcostnum > GameScene.roleinfo.g_gold) then  
        runGamePrompt({msg = "仙元不足"})
    else
        self.donum = donum
    end

    --
    self.rootItems.donum:setString(self.donum)
    ui.setLabelString(self.rootItems.costnum1, self.costnum*self.donum, 14)
    ui.setLabelString(self.rootItems.costnum2, self.stonenum*self.donum, 14)

end


function instrumentForgeAutomatic.setpropNum(self,data)
    self.hasstonenum = data and data[tostring(self.stonecid)] or self.hasstonenum
    if self.tuPoStatus > 0 and self.method == 3 then
        self.rootItems.stonenode2:setVisible(true)
        self.rootItems.stonenode:setVisible(false)
        ui.setLabelString(self.rootItems.hasnum2, self.hasstonenum, 14)
        ui.setLabelString(self.rootItems.xianyuannum, self.g_gold, 14)
    else    
        self.rootItems.stonenode2:setVisible(false)
        self.rootItems.stonenode:setVisible(true)
        ui.setLabelString(self.rootItems.hasnum, self.hasstonenum, 14)
    end    
    --
    local needcostnum = self.costnum*self.donum or 0
    local needstonenum = self.stonenum*self.donum or 0
    if needstonenum > self.hasstonenum then
        self:initnum(0)
    elseif (self.costcid == 1000) and (needcostnum > GameScene.roleinfo.coin) then
        self:initnum(0)
    elseif (self.costcid == 1001) and (needcostnum > GameScene.roleinfo.gold) then
        self:initnum(0)
    elseif (self.costcid == 1025) and (needcostnum > GameScene.roleinfo.g_gold) then  
        self:initnum(0)
    else

    end
end


function instrumentForgeAutomatic.reloadData(self,data)

    --self:initnum(0)
    --
    UIRequest({type = 12001, order = 11004, cids = {20270}})
    --
    local status = data.status or {}
    local autotimes = data.autotimes or 0
    self.g_gold = data.g_gold or 0
    if self.tuPoStatus >0 and self.method == 3 then
        ui.setLabelString(self.rootItems.xianyuannum, self.g_gold, 14)
    end    
    --
    self.status = {}
    --
    local rnum = table.getTableLength(status) or 0

    if rnum == 0 then
        runGamePrompt({msg = "锻造属性已满，无法自动锻造"})
    end    

    self.rnum = rnum

    print("instrumentForgeAutomatic reloadData times1:"..rnum.." doButtonNum:"..self.doButtonNum)
    gameTouch:clickprofbytime(0.05*rnum+0.5)
    self.isfull = false    
    --
    for i = 1,rnum do
        -- if i == rnum then
        --     runGamePrompt({msg = "自动锻造完成"})
        --     -- gameTouch:setClickProf(false)
        -- end
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.05*i),CCCallFunc:create(function()
            if i == rnum then
                runGamePrompt({msg = "自动锻造完成"})
            end
            self.status[tostring(i)] = status[tostring(i)]
            if self.ListTableView then
                self.ListTableView:reloadData()
                self.ListTableView:setLuaContentOffset(0,(self.rootItems.listnode:getContentSize().height > table.getTableLength(self.status)*220) and (self.rootItems.listnode:getContentSize().height - table.getTableLength(self.status)*220) or 0)
            end
        end)))
    end
end

function instrumentForgeAutomatic.close(self)

    self.ListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end

    self.cid = 0
    self.iid = 0
    self.donum = 0
    self.method = 0
    self.status1 = 0
    self.status2 = 0
    self.status3 = 0
    self.status4 = 0
    self.status5 = 0
    self.costcid = 0
    self.costnum = 0
    self.stonecid = 20270
    self.stonenum = 0
    self.hasstonenum = 0
    self.status = {}
    self.isfull = nil
end

return instrumentForgeAutomatic  J;  