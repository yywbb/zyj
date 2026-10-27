--

--

local generalcultivate = {
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

    costnum1 = 0,
    costcid = 0,
    peiyangnum = 0,
    stonecid = 20009,
    stonenum = 0,
    needbig = 0,
    hasstonenum = 0,
    potentialNum = 0,
    delayButtonStatus = true,
    isShowContent = true,
    oldPotential = 0,
    typeconfig = {"atk","hp","def",},
}

function generalcultivate.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("general_new/zidong_train", nil, true, "zidong_train")
    self:initFixedString()
    self.touchPriority = touchPriority
    self.callback = callback

    self.extGeneralData = data.extGeneralData

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.donum,self.touchPriority,function (num)
        self.donum = 0
        self:numchange(num)
    end)   

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalcultivate")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        gameWindows:openWindow("zidong_rule",{doType= 3},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
         --self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)


    self.rootItems.sub10:addHandleOfControlEvent(function()
         --self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab,gameConfig.strings:string_common("general", 68), 19)
    
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        local zeroNum = 0
        for i =1,3 do
            if self["status"..i] == 0 then
                zeroNum = zeroNum + 1
            end
        end
        if zeroNum == 3 then
            runGamePrompt({msg = gameConfig.strings:string_common("general",69)})
            return
        end    

        if self.donum > 0 then
            if self.extGeneralData.potential >= self.needbig then
                gameTouch:clickprofbytime(2)
                UIRequest({type = 1126,iid = self.iid,method = self.method,xlnum = self.donum,status1 = self.status1,status2 = self.status2,status3 = self.status3})
            else
                local needtype = {}
                for k,v in ipairs(self.typeconfig) do
                    if self["status"..k] ~= 1 then
                        local num = 0
                        if v == "def" then
                            num = self.extGeneralData["defense"]
                        else
                            num = self.extGeneralData[tostring(v)]
                        end
                        if num <= 0 then
                            table.insert(needtype,gameConfig.strings:string_common("attr_type", v))
                        end
                    end
                end
                
                if #needtype > 0 then
                    local msg = ""
                    for k,v in ipairs(needtype) do
                        msg = msg..v.."属性"
                    end
                    --runGamePrompt({msg = "潜力点为0时需要"..msg.."培养值大于0"})
                    runGamePrompt({msg = "未勾选属性可培养值为0"})   
                else
                    gameTouch:clickprofbytime(2)
                    UIRequest({type = 1126,iid = self.iid,method = self.method,xlnum = self.donum,status1 = self.status1,status2 = self.status2,status3 = self.status3})
                end
            end
        else
            runGamePrompt({msg = gameConfig.strings:string_common("general", 70)})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    --self.cid = data.cid or 0
    self.iid = data.iid or 0
    self.method = data.method or 2

    local config = gamedata.config.global_kv.general_foster_bad.value
    if self.method == 2 then
        self.rootItems.xilianCostNode:setVisible(true)
        self.rootItems.xilianCostNode2:setPositionX(0)
        self.stonenum = 1 or 0
        config = gamedata.config.global_kv.general_foster_good.value
    else
        self.rootItems.xilianCostNode:setVisible(false)
        self.rootItems.xilianCostNode2:setPositionX(-210)
        self.stonenum = 1 or 0
    end

    local props = ui.getIDandNUMs(config)
    
    for k,v in pairs(props) do
        if v.cid * 10 > self.needbig then
            self.needbig = v.cid * 10
        end
    end

    self.costcid = 1001
    self.costnum1 = 5
    self.stonecid = 20009
    self.peiyangnum = 1

    for i = 1,3 do
        ui.setLabelString(self.rootItems["attr"..i], gameConfig.strings:string_common("attr_type",self.typeconfig[i]), 14)
        self.rootItems["attrstatus"..i]:setVisible(false)
        self["status"..i] = 0
        -- if self.extGeneralData.potential >= self.needbig then
        --     self.potentialNum = 3
        --     self.rootItems["attrstatus"..i]:setVisible(true)
        --     self["status"..i] = 1
        -- end
        self.rootItems["attrButton"..i]:addHandleOfControlEvent(function()
            print("touch show status"..self["status"..i])
            if self["status"..i] == 1 then
                self["status"..i] = 0
                self.potentialNum = self.potentialNum - 1
                self.rootItems["attrstatus"..i]:setVisible(false)
            else
                if self.extGeneralData.potential < self.needbig then
                    if self.potentialNum >= 2 then
                        runGamePrompt({msg = gameConfig.strings:string_common("general", 71)})
                        return
                    end
                end
                self["status"..i] = 1
                self.potentialNum = self.potentialNum + 1
                self.rootItems["attrstatus"..i]:setVisible(true)
            end
        end, CCControlEventTouchUpInside)
        self.rootItems["attrButton"..i]:setSwallowsTouch(true)
        self.rootItems["attrButton"..i]:setTouchPriority(self.touchPriority)
    end
    self.oldPotential = self.extGeneralData.potential
    self:initnum(0)
    UIRequest({type = 12001, order = 10101, cids = {20009}})
 
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
                cellCCB, ccbDocumentControler = CCBReaderLoad("general_new/cell_zidongpeiyang", nil, true, "cell_zidongpeiyang")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            data =  self.status[tostring(a1+1)] or {}

            if self.stop == 1 and (a1 + 1 == self.total) then
                ccbDocumentControler["stop"]:setVisible(true)

                if data["potential"] and data["potential"] > 0 then
                    ccbDocumentControler["stop"]:setString("潜力点不足，自动培养停止")
                else

                    local needtype = {}
                    for k,v in ipairs(self.typeconfig) do
                        if self["status"..k] ~= 1 then
                            table.insert(needtype,gameConfig.strings:string_common("attr_type", v))
                        end
                    end
                    local msg = "自动培养停止"
                    if #needtype == 1 then
                        msg = string.format("可培养\"%s\"为0，自动培养停止。", needtype[1])
                    elseif #needtype == 2 then
                        msg = string.format("可培养\"%s、%s\"为0，自动培养停止。", needtype[1],needtype[2])
                    end

                    ccbDocumentControler["stop"]:setString(msg)
                end
            else
                ccbDocumentControler["stop"]:setVisible(false)
            end

           

            if data.status and data.status == 1 then
                ccbDocumentControler["x_status"]:setColor(ccc3(84,255,8))
                ui.setLabelString(ccbDocumentControler["x_status"], "已保存！", 3)
            else
                ui.setLabelString(ccbDocumentControler["x_status"], "未保存！", 11)
                ccbDocumentControler["x_status"]:setColor(ccc3(255,8,8))
            end
            ui.setLabelString(ccbDocumentControler["x_title"],gameConfig.strings:generalPeiyang(a1+1),14)

            local attribute1,num1,attribute2,num2 = 0,0,0,0
            if data["attribute1"] > 0 then
                attribute1 = data["attribute1"]
                num1 =  data["num1"]
            end

            if data["attribute2"] > 0 then
                attribute2 = data["attribute2"]
                num2 =  data["num2"]
            end

            for i = 1,4 do
                if i == 2 then
                    ui.setLabelString(ccbDocumentControler["x_attr"..i], gameConfig.strings:string_common("zhuxiantai",0), 13)
                elseif i == 3 then
                    ui.setLabelString(ccbDocumentControler["x_attr"..i], gameConfig.strings:string_common("zhuxiantai",2), 13)
                elseif i == 4 then
                    ui.setLabelString(ccbDocumentControler["x_attr"..i], gameConfig.strings:string_common("fixedString","general",19), 13)
                else
                    ui.setLabelString(ccbDocumentControler["x_attr"..i], gameConfig.strings:string_common("zhuxiantai",i), 13)
                end

                if i == attribute1 or i == attribute2 then
                    if i == attribute1 then
                        if num1 > 0 then
                            ui.setLabelString(ccbDocumentControler["num"..i], "+" .. num1, 26)
                        elseif num1 < 0 then
                            ui.setLabelString(ccbDocumentControler["num"..i], num1, 27)
                        else
                            ui.setLabelString(ccbDocumentControler["num"..i], "+0", 13)
                        end
                    else
                        if num2 > 0 then
                            ui.setLabelString(ccbDocumentControler["num"..i], "+" ..num2, 26)
                        elseif num2 < 0 then
                            ui.setLabelString(ccbDocumentControler["num"..i], num2, 27)
                        else
                            ui.setLabelString(ccbDocumentControler["num"..i], "+0", 13)
                        end
                    end
                else
                    ui.setLabelString(ccbDocumentControler["num"..i], "+0", 13)
                end
            end
            ui.setLabelString(ccbDocumentControler["num4"], "-"..data["potential"], 27)

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

    self:setAddandReduceBtn()
    return self.rootNode
end


function generalcultivate.initnum(self,num)
    self:initEmpteyLabelString(true)
    self.donum = num
    ui.setLabelString(self.rootItems.donum,self.donum,14)


    local gold = self.costnum1*self.donum

    ui.setLabelString(self.rootItems.costnum1, gold, GameScene.roleinfo.gold >= gold and 14 or 1001)


    local costAndHasNum = string.format("%d",self.peiyangnum*self.donum)
    ui.setLabelString(self.rootItems.costnum2, costAndHasNum, 14)

    ui.setLabelString(self.rootItems.costnum5, self.extGeneralData.potential, 14)  
end

function generalcultivate.initEmpteyLabelString( self ,isVisible)
    if isVisible then
        if self.rootItems.contentNode then
            ui.createRichLabel({
                {fontID = 138,content = gamedata.config.system_intro["8"].intro},
                },self.rootItems.contentNode,true,{min_line_dis = 10})
        end
    else
        if self.rootItems.contentNode then
            self.rootItems.contentNode:removeFromParentAndCleanup(true)
            self.rootItems.contentNode = nil
        end
    end
end


-- 增加 减少按钮
function generalcultivate.setAddandReduceBtn( self)
    
    local beginFunc = function(index)
        print("beginFunc"..index)
       
    end
    local endFunc = function(index)
        print("endFunc"..index)
       
    end
  
    local Func10 = function()
        self:numchange(10)
    end
   
    local reduce10 = function()
        self:numchange(-10)
    end
    -- printT(self.rootItems)
    if self.delayButtonStatus then
        ui.creatDelayButton(self.rootItems.add10,self.touchPriority,Func10,beginFunc,endFunc,1)
        ui.creatDelayButton(self.rootItems.sub10,self.touchPriority,reduce10)
    end
    self.delayButtonStatus = false

end

function generalcultivate.numchange(self,num)

    local donum = self.donum + num

    if donum < 0 then return end
    if donum > 200 then return end

    local needcostnum = self.costnum1*donum or 0
    local needstonenum = self.peiyangnum*donum or 0

    if needstonenum > self.hasstonenum then
        runGamePrompt({msg = gameConfig.strings:nameBuzu(ui.IDconfig(self.stonecid).name)})
    elseif (self.costcid == 1001) and (needcostnum > GameScene.roleinfo.gold) and self.method == 2 then
        runGamePrompt({msg = "元宝不足"})
    else
        self.donum = donum
    end

    ui.setLabelString(self.rootItems.donum,self.donum,14)

    local gold = self.costnum1*self.donum
    ui.setLabelString(self.rootItems.costnum1, self.costnum1*self.donum, GameScene.roleinfo.gold >= gold and 14 or 1001)

    local costAndHasNum = string.format("%d",self.peiyangnum*self.donum)
    ui.setLabelString(self.rootItems.costnum2, costAndHasNum, self.hasstonenum >= tonumber(costAndHasNum) and 14 or 1001)
    ui.setLabelString(self.rootItems.costnum4, self.hasstonenum, 14)

    if self.extGeneralData.potential <= 0 then
        self.extGeneralData.potential = 0
    end
end

function generalcultivate.setpropNum(self,data)
    self.hasstonenum = data and data[tostring(self.stonecid)] or self.hasstonenum
    ui.setLabelString(self.rootItems.costnum4, self.hasstonenum, 14)
    local costAndHasNum = string.format("%d",self.peiyangnum*self.donum)
    ui.setLabelString(self.rootItems.costnum2, costAndHasNum, self.hasstonenum >= tonumber(costAndHasNum) and 14 or 1001)
    local needcostnum = self.costnum1*self.donum or 0
    local needstonenum = self.peiyangnum*self.donum or 0
    if needstonenum > self.hasstonenum then
        self:initnum(0)
    elseif (self.costcid == 1001) and (needcostnum > GameScene.roleinfo.gold) then
        self:initnum(0)
    end
end


function generalcultivate.reloadData(self,data)
    UIRequest({type = 12001, order = 10101, cids = {20009}})

    self.extGeneralData = data.general
    self.stop = data.stop
    self:initEmpteyLabelString(false)
    
    -- self:initnum(0)

    if data.general.potential < self.needbig and self.oldPotential >= self.needbig then
        self:initnum(0)
    end

    ui.setLabelString(self.rootItems.costnum5, self.extGeneralData.potential, 14)
    local needcostnum = self.costnum1*self.donum or 0
    local needstonenum = self.peiyangnum*self.donum or 0

    if needstonenum > self.hasstonenum then
        self:initnum(0)
    elseif (self.costcid == 1001) and (needcostnum > GameScene.roleinfo.gold) then
        self:initnum(0)
    end
 
    if self.extGeneralData.potential <= 0 then
        self.extGeneralData.potential = 0
    end

    local status = data.status or {}
    self.total = table.getTableLength(status) 
    self.status = {}
    --
    for i=1,3 do
        if data.general.potential < self.needbig and self.oldPotential >= self.needbig then
            self.rootItems["attrstatus"..i]:setVisible(false)
            self.potentialNum = 0
            self["status"..i] = 0
        end
    end
    self.oldPotential = data.general.potential
    local rnum = table.getTableLength(status) or 0
    --
    local speednum = CCDirector:sharedDirector():getScheduler():getTimeScale()
    gameTouch:clickprofbytime((0.5*rnum+1)/speednum)
    print("rnum---------", rnum)
    for i = 1,rnum do
        self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5*i),CCCallFunc:create(function()
            self.status[tostring(i)] = status[tostring(i)]
            if i == rnum then
                print("khfjashifkjhdshfk-------")
                runGamePrompt({msg = gameConfig.strings:string_common("general", 72)})
            end
            if self.ListTableView then
                self.ListTableView:reloadData()
                self.ListTableView:setLuaContentOffset(0,(self.rootItems.listnode:getContentSize().height > table.getTableLength(self.status)*220) and (self.rootItems.listnode:getContentSize().height - table.getTableLength(self.status)*220) or 0)
            end
        end)))
    end
end

function generalcultivate.close(self)

    self.ListTableView = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end

    self.iid = 0
    self.donum = 0
    self.method = 0
    self.status1 = 0
    self.status2 = 0
    self.status3 = 0
    self.status4 = 0
    self.costcid = 0
    self.costnum1 = 0
    self.stonecid = 20009
    self.peiyangnum = 0
    self.hasstonenum = 0
    self.status = {}
    self.potentialNum = 0
    self.delayButtonStatus = true
    self.needbig = 0
end

function generalcultivate.initFixedString(self)
    ui.setLabelString(self.rootItems.fixstr1, gameConfig.strings:string_common("general", 63), 14)
    ui.setLabelString(self.rootItems.fixstr2, gameConfig.strings:string_common("general", 64), 14) 
    ui.setLabelString(self.rootItems.fixstr3, gameConfig.strings:string_common("general", 65), 14)  
    ui.setLabelString(self.rootItems.fixstr4, gameConfig.strings:string_common("general", 66), 14)
    ui.setLabelString(self.rootItems.fixstr5, gameConfig.strings:string_common("general", 67), 14)
    ui.setLabelString(self.rootItems.fixstr6, gameConfig.strings:string_common("general", 73), 14) 
end

return generalcultivate  M  