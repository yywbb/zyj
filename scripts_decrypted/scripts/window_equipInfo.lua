--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/5/25
-- Time: 17:24
-- To change this template use File | Settings | File Templates.
--


local equipInfo = {
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"info","refine","up","treasureRefine","xilian"},
    pagetype = "info",

    isSuit = false,
    hasup = 0,

    rolecoin = 0,

    yuannum = 0,
    hasxilian = false,

    xlselect = 1,
    xlselectbtn = 1,
    xiliansStoneNum = 0,

    xl_coin = 0,
    xl_gold = 0,
    xl_stone1 = 0,
    xl_stone2 = 0,
    xl_stone3 = 0,

    xl_max1 = false,
    xl_max2 = false,
    xl_max3 = false,
    xl_max4 = false,

    hasXLPreview = false,
    isscrolltouched = false,
}

function equipInfo.open(self,touchPriority,data,callback)
    self.root = ui.createNode()

    self.touchPriority = touchPriority

    self:reload(data,callback)

    return self.root
end

function equipInfo.reload(self,data,callback)
    self.callback = callback
    self.data = data.equip or {}
    self.opt = data.opt or 0  -- 0,1,2:图鉴
    self.sid = data.sid or 1
    self.index = data.index or 1
    print(self.sid,"equipInfo.reload")
    printT(data,"equipInfo.data")

    self.rolecoin = data.coin or GameScene.roleinfo.coin

    if self.opt == 2 then
        self.data.cid = data.cid
        self.data.iid = 0
        self.data.level1 = 1
        self.data.level2 = 0
        self.data.level4 = 0
        self.data.suit = {}
        self.data.suitstage = {}
    end

    --
    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    local relation = {}
    if equipConfig.relation and equipConfig.relation ~= "" then
        if equipConfig.relation ~= 0 and equipConfig.relation ~= "0" then
            relation = ui.Split(equipConfig.relation,";")
        end
    end
    local maxnum = table.getTableLength(relation)
    if maxnum > 0 then
        if relation[maxnum] and relation[maxnum] == "" then
            maxnum = maxnum-1
        end
    end
    self.yuannum = maxnum or 0
    if equipConfig.suit and equipConfig.suit > 0 then
        self.isSuit = true
    else
        self.isSuit = false
    end
    --
    self.hasxilian = false
    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        self.hasxilian = false
    elseif equipConfig.quality > 2 then
        self.hasxilian = true
    end
    --
    self.pagetype = data.pagetype or self.pagetype

    self:showPage(self.pagetype)

end

function equipInfo.reloaddata(self,data)
    if self.data and (data.equip.level2 > self.data.level2 or data.equip.level1 > self.data.level1) then
       self.hasup = 1
    else
       self.hasup = 0
    end
    self.rolecoin = data.coin or GameScene.roleinfo.coin
    self.data = data.equip or {}
    self.pagetype = data.pagetype or self.pagetype
    self:showPage(self.pagetype)

end

function equipInfo.close(self)
    self.hasXLPreview = false
    self.xl_max1 = false
    self.xl_max2 = false
    self.xl_max3 = false
    self.xl_max4 = false
    self.xiliansStoneNum = 0
    self.xlselect = 1
    self.xlselectbtn = 1
    self.yuannum = 0
    self.hasxilian = false
    self.isSuit = false
    self.hasup = 0
    self.pagetype = "info"
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    gameTouch:UnrigistFunc("begin","equipInfo")
    gameTouch:UnrigistFunc("end","equipInfo") 
    if self.callback then
        self.callback()
    end
end

function equipInfo.showPage(self,type)
    self.pagetype = type

    if self.pagetype == "info" then
        self.rootNode, self.infoItems = CCBReaderLoad((self.yuannum >= 1 or self.isSuit or self.hasxilian) and "equip_new/equip_info" or "equip_new/equip_info2", nil, true, "equip_info")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        --
        local function touchbegin(pos)
            self.isscrolltouched = false
        end
        gameTouch:rigistFunc("begin","equipInfo",touchbegin) --scrollnode
        local function touchend(pos)
            -- if self.pagetype == "info" then
                
            -- else
            --     self.infoItems = nil
            -- end
            if self.infoItems.scrollnode and ui.isTouched(self.infoItems.scrollnode,pos.x,pos.y) then
                self.isscrolltouched = true
            end
        end
        gameTouch:rigistFunc("end","equipInfo",touchend)
        --
        self:setPage_info()
    elseif self.pagetype == "refine" then
        self.rootNode, self.refineItems = CCBReaderLoad("equip_new/equip_refine", nil, true, "equip_refine")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_refine()
    elseif self.pagetype == "up" then
        self.rootNode, self.upItems = CCBReaderLoad("equip_new/equip_up", nil, true, "equip_up")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_up()
        if guide.controller then
            guide.controller:UIComplete(8047)
        end
    elseif self.pagetype == "treasureRefine" then
        self.rootNode, self.treasureRefineItems = CCBReaderLoad("equip_new/treasure_refine", nil, true, "treasure_refine")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_treasureRefine()
    elseif self.pagetype == "xilian" then
        self.rootNode, self.xilianItems = CCBReaderLoad("equip_new/equip_xilian", nil, true, "equip_xilian")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_xilian()
    end

end


function equipInfo.setPage_info(self)

    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    -- printT(equipConfig,"equipConfig===")
    -- printT(self.data,"self.data===")
    -- 去获取 按钮
    ui.setLabelString(self.infoItems.getText,nil,18)
    self.infoItems.getBtn:addHandleOfControlEvent(function()
        self.callback = nil
        print("getBtn..is")
        -- UIRequest({type = 12002, id = self.data.cid})
        gameWindows:openWindow("dropTips",{cid = self.data.cid},nil)
    end, CCControlEventTouchUpInside)
    self.infoItems.getBtn:setSwallowsTouch(true)
    self.infoItems.getBtn:setTouchPriority(self.touchPriority)


    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        local maxlv = table.getTableLength(gamedata.config.treasure2_strengthen)
        if equipConfig.maxlevel and (maxlv > (equipConfig.maxlevel+0)) then
            maxlv = equipConfig.maxlevel+0
        end
        if maxlv > GameScene.roleinfo.level then
            maxlv = GameScene.roleinfo.level
        end
        self.infoItems.e_level:setString("强化等级: "..self.data.level1.."/"..maxlv)
    else
        local maxlv = 0
        maxlv = GameScene.roleinfo.level*tonumber(gamedata.config.global_kv.equip_level.value)
        if equipConfig.maxlevel and (maxlv > (equipConfig.maxlevel+0)) then
            maxlv = equipConfig.maxlevel+0
        end
        self.infoItems.e_level:setString("强化等级:  "..self.data.level1.."/"..maxlv)
    end

    -- 添加装备升星按钮
    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        self.infoItems.doNode1:setPositionX(240) --340
        self.infoItems.doNode2:setPositionX(540) --740
        self.infoItems.doNode3:setVisible(false)
        if self.infoItems.doNode4 then
            self.infoItems.doNode4:setVisible(true)
            self.infoItems.doNode4:setPositionX(840)
        end
        if self.infoItems.doNode5 then
            self.infoItems.doNode5:setVisible(false)
        end
        --
        if self.opt and self.opt == 1 then
            self.infoItems.doNode1:setPositionX(240)
            self.infoItems.doNode2:setPositionX(540)
            self.infoItems.doNode3:setVisible(false)
            if self.infoItems.doNode4 then
                self.infoItems.doNode4:setVisible(true)
                self.infoItems.doNode4:setPositionX(840)
            end
            if self.infoItems.doNode0 then
                self.infoItems.doNode0:setVisible(false)
            end 
        end
        --
        ui.setLabelString(self.infoItems.doLab4,nil,19)
        self.infoItems.doButton4:addHandleOfControlEvent(function()
            if not gameConfig:checkBuildOpen(666)  then
                runGamePrompt({msg = "功能未开启"})
            elseif equipConfig.up_star == nil or equipConfig.up_star == 0 then
                runGamePrompt({msg = "橙色品质以下的宝物无法升星"})
            else
                if not GameScene:checkopenlevelbyId(666) then return end
                GameScene:shiftLayer("treasureup", "up", {page = "upstar", data = self.data, sid = self.sid or 1})
            end
        end, CCControlEventTouchUpInside)
        self.infoItems.doButton4:setSwallowsTouch(true)
        self.infoItems.doButton4:setTouchPriority(self.touchPriority)

        local config = gamedata.config.build[tostring(666)] or {}
        if not gameConfig:checkBuildOpen(666)  then
            ui.addGray("CCControlButton",self.infoItems.doButton4)
        elseif config and GameScene.roleinfo.level < config.level then
            ui.addGray("CCControlButton",self.infoItems.doButton4)
        elseif equipConfig.up_star == 0 then
            ui.addGray("CCControlButton",self.infoItems.doButton4)
        else
            ui.removeGray("CCControlButton",self.infoItems.doButton4)
        end

    else
        if equipConfig.up_star == 0  then
            if self.infoItems.doNode4 then
                self.infoItems.doNode4:setVisible(false)
            end
            self.infoItems.doNode1:setPositionX(214)
            self.infoItems.doNode2:setPositionX(434)
            self.infoItems.doNode3:setPositionX(654)
            if self.infoItems.doNode5 then
                self.infoItems.doNode5:setPositionX(874)
            else
                self.infoItems.doNode1:setPositionX(214)
                self.infoItems.doNode2:setPositionX(544)
                self.infoItems.doNode3:setPositionX(874)
            end
        else
            self.infoItems.doNode1:setPositionX(170)
            self.infoItems.doNode2:setPositionX(355)
            self.infoItems.doNode3:setPositionX(540)
            if self.infoItems.doNode5 then
                self.infoItems.doNode5:setPositionX(910)
            end
            if self.infoItems.doNode4 then
                self.infoItems.doNode4:setPositionX(725)
                self.infoItems.doNode4:setVisible(true)
    
                self.infoItems.doLab4:setString("升 星")
                ui.setLabelString(self.infoItems.doLab4,nil,19)
                self.infoItems.doButton4:addHandleOfControlEvent(function()
                    if not gameConfig:checkBuildOpen(199)  then
                        runGamePrompt({msg = "功能未开启"})
                    elseif equipConfig.up_star == nil or equipConfig.up_star == 0 then
                        runGamePrompt({msg = "该品质的装备没有升星资格"})
                    else
                        if not GameScene:checkopenlevelbyId(199) then return end
                        GameScene:shiftLayer("equipsup","up",{page = "shengxing",data = self.data,sid = self.index or 1,arrange_sid = self.sid or 1})
                    end
                end, CCControlEventTouchUpInside)
                self.infoItems.doButton4:setSwallowsTouch(true)
                self.infoItems.doButton4:setTouchPriority(self.touchPriority)
    
                local config = gamedata.config.build[tostring(199)]
                -- print("level===",GameScene.roleinfo.level,config.level)
                if not gameConfig:checkBuildOpen(199)  then
                    ui.addGray("CCControlButton",self.infoItems.doButton4)
                elseif config and GameScene.roleinfo.level < config.level then
                    ui.addGray("CCControlButton",self.infoItems.doButton4)
                elseif equipConfig.up_star == 0 then
                    ui.addGray("CCControlButton",self.infoItems.doButton4)
                else
                    ui.removeGray("CCControlButton",self.infoItems.doButton4)
                end
            end
        end

        if self.infoItems.doNode3 then
            self.infoItems.doNode3:setVisible(true)
            ui.setLabelString(self.infoItems.doLab3,gameConfig.strings:string_common("equips",28),19)
            self.infoItems.doButton3:addHandleOfControlEvent(function()

                if not gameConfig:checkBuildOpen(384)  then
                    runGamePrompt({msg = "功能未开启"})
                elseif equipConfig.quality < 3 then
                    runGamePrompt({msg = gameConfig.strings:string_common("equips",29)})
                elseif not GameScene:checkopenlevelbyId(384) then 
                    return
                else
                    GameScene:shiftLayer("equipsup","up",{page = "cast",data = self.data,sid =  self.index or 1,arrange_sid = self.sid or 1})
                end
            end, CCControlEventTouchUpInside)
            self.infoItems.doButton3:setSwallowsTouch(true)
            self.infoItems.doButton3:setTouchPriority(self.touchPriority)

            local config = gamedata.config.build[tostring(384)]
            -- print("level===",GameScene.roleinfo.level,config.level)
            if not gameConfig:checkBuildOpen(384)  then
                ui.addGray("CCControlButton",self.infoItems.doButton3)
            elseif config and GameScene.roleinfo.level < config.level then
                ui.addGray("CCControlButton",self.infoItems.doButton3)
            elseif equipConfig.quality < 3 then
                ui.addGray("CCControlButton",self.infoItems.doButton3)
            else
                ui.removeGray("CCControlButton",self.infoItems.doButton3)
            end
        end
    end


    --self.infoItems.title:setString("装备详情")
    self.infoItems.title:setString(gameConfig.strings:string_common("equipInfo",0))
    self.infoItems.e_desc:setString(equipConfig.desc)
    self.infoItems.e_equiptype:setString(gameConfig.strings.equipType[equipConfig.type])
    if equipConfig.type ~= "horse" and equipConfig.type ~= "treasure" then
        self.infoItems.e_name:setString(ui.getEquipStageName(self.data) or "")
    else
        self.infoItems.e_name:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or "" ))
    end

    if equipConfig.quality >= 7 then
        ui.setLabelString(self.infoItems.e_name,nil,213)
    else
        ui.setLabelString(self.infoItems.e_name,nil,(equipConfig.quality or 1)*2-1)
    end
    
    --
    -- ui.setIconLv(self.infoItems,self.data)
    -- 装备升星星级展示
    ui.setIconLv(self.infoItems,self.data,nil,self.data)

    -- 装备升星属性提升展示
    ui.setEquipStarPropertyshow(self.infoItems,self.data)


    if equipConfig.suit and equipConfig.suit > 0 then
        self.infoItems.e_equiptypenode1:setVisible(false)
        self.infoItems.e_equiptypenode2:setVisible(true)
        self.isSuit = true
    else
        self.infoItems.e_equiptypenode1:setVisible(true)
        self.infoItems.e_equiptypenode2:setVisible(false)
        self.isSuit = false
    end

    ui.setEquipPromote(self.infoItems["e_type1"],self.infoItems["e_type2"],self.data,self.infoItems["e_type3"])
    --
    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("equipInfo")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

    if self.opt and self.opt == 1 then
        if self.data.generalcid and self.data.generalcid > 0 then
            ui.addGray("CCControlButton",self.infoItems.doButton0)
        else
            ui.removeGray("CCControlButton",self.infoItems.doButton0)
        end
        self.infoItems.doLab0:setString("炼 化")
        ui.setLabelString(self.infoItems.doLab0,nil,19)
        self.infoItems.doButton0:addHandleOfControlEvent(function()
            if self.data.generalcid and self.data.generalcid > 0 then
                runGamePrompt({msg = "已装备的物品无法炼化"})
            else
                --UIRequest({type = 1104, ids = {self.data.iid}})
                gameWindows:closeWindowDirect("equipInfo")
                GameScene:shiftLayer("qiankunlu","up")
            end
        end, CCControlEventTouchUpInside)
        self.infoItems.doButton0:setSwallowsTouch(true)
        self.infoItems.doButton0:setTouchPriority(self.touchPriority)
    else
        --self.infoItems.doLab0:setString("更 换")
        self.infoItems.doLab0:setString(gameConfig.strings:string_common("equipInfo",3))
        ui.setLabelString(self.infoItems.doLab0,nil,19)
        self.infoItems.doButton0:addHandleOfControlEvent(function()
            gameWindows:closeWindowDirect("equipInfo")
            local callback = function(selectedData)
                for k,v in pairs(selectedData) do
                    UIRequest({type=1005,slot = self.sid,equipeid = v.iid})
                    break
                end
            end
            gameWindows:openWindow("selectlist",{type = "change_"..equipConfig.type.."_all", param = {equipiid = self.data.iid,sid = self.sid}},callback)
        end, CCControlEventTouchUpInside)
        self.infoItems.doButton0:setSwallowsTouch(true)
        self.infoItems.doButton0:setTouchPriority(self.touchPriority)
    end

    --
    if self.infoItems.doNode5 then
        self.infoItems.doLab5:setString("进 阶")
        ui.setLabelString(self.infoItems.doLab5,nil,19)
        if equipConfig.evolve and equipConfig.evolve == 1 then
            self.infoItems.doButton5:addHandleOfControlEvent(function()
                if not GameScene:checkopenlevelbyId(150) then return end
                
                local equip = table.copy(self.data)
                
                 GameScene:shiftLayer("equipsup","up",{page = "jinjie",data = self.data,sid = self.index or 1,arrange_sid = self.sid or 1})
                -- GameScene:shiftLayer("equipstage","up",{equip = equip})
            end, CCControlEventTouchUpInside)
            self.infoItems.doButton5:setSwallowsTouch(true)
            self.infoItems.doButton5:setTouchPriority(self.touchPriority)

            local config = gamedata.config.build[tostring(150)]
            -- print("level===",GameScene.roleinfo.level,config.level)
            if not gameConfig:checkBuildOpen(150)  then
                ui.addGray("CCControlButton",self.infoItems.doButton5)
            elseif config and GameScene.roleinfo.level < config.level then
                ui.addGray("CCControlButton",self.infoItems.doButton5)
            else
                ui.removeGray("CCControlButton",self.infoItems.doButton5)
            end
        else
            ui.addGray("CCControlButton",self.infoItems.doButton5)
            self.infoItems.doButton5:addHandleOfControlEvent(function()
                runGamePrompt({msg = "该装备无法进阶"})
            end, CCControlEventTouchUpInside)
            self.infoItems.doButton5:setSwallowsTouch(true)
            self.infoItems.doButton5:setTouchPriority(self.touchPriority)
        end
    end
    --

    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        self.infoItems.doLab2:setString("精 炼")
        if not GameScene:checkopenlevelbyId(137,true) then
            ui.addGray("CCControlButton",self.infoItems.doButton2)
        else
            ui.removeGray("CCControlButton",self.infoItems.doButton2)
        end
    else
        ui.removeGray("CCControlButton",self.infoItems.doButton2)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab2)
        if not GameScene:checkopenlevelbyId(53,true) then
            ui.addGray("CCControlButton",self.infoItems.doButton2)
            ui.addGray("CCLabelTTF",self.infoItems.doLab2)
        end
        self.infoItems.doLab2:setString("洗 炼")
        if equipConfig.quality < 3 then
            ui.addGray("CCControlButton",self.infoItems.doButton2)
            ui.addGray("CCLabelTTF",self.infoItems.doLab2)
        end
    end
    --self.infoItems.doLab2:setString(gameConfig.strings:string_common("equipInfo",4))
    ui.setLabelString(self.infoItems.doLab2,nil,19)
    self.infoItems.doButton2:addHandleOfControlEvent(function()

        if equipConfig.type == "horse" or equipConfig.type == "treasure" then
            if not GameScene:checkopenlevelbyId(137) then return end
            --self:showPage("refine")
            GameScene:shiftLayer("treasureup","up",{page = "refine",data = self.data,sid = self.sid or 1})
        else
            if not GameScene:checkopenlevelbyId(53) then return end
            if equipConfig.quality < 3 then
                runGamePrompt({msg = "该装备无法洗炼"})
            else
                -- self:showPage("xilian")
                GameScene:shiftLayer("equipsup","up",{page = "xilian",data = self.data,sid = self.index or 1,arrange_sid = self.sid or 1})
            end
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton2:setSwallowsTouch(true)
    self.infoItems.doButton2:setTouchPriority(self.touchPriority)

    --self.infoItems.doLab3:setString("强 化")
    self.infoItems.doLab1:setString(gameConfig.strings:string_common("equipInfo",5))
    ui.setLabelString(self.infoItems.doLab1,nil,19)
    self.infoItems.doButton1:addHandleOfControlEvent(function()
        guide:setGuideProlayer(true)
        if equipConfig.type == "horse" or equipConfig.type == "treasure" then
            --self:showPage("treasureRefine")
            --runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng2")})
            GameScene:shiftLayer("treasureup","up",{page = "up",data = self.data,sid = self.sid or 1})
        else
            -- self:showPage("up")
            GameScene:shiftLayer("equipsup","up",{page = "up",data = self.data,sid =  self.index or 1,arrange_sid = self.sid or 1})
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton1:setSwallowsTouch(true)
    self.infoItems.doButton1:setTouchPriority(self.touchPriority)

    --
    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        -- self.infoItems.title:setString("宝物详情")
        -- self.infoItems.doLab3:setString("升 华")
        self.infoItems.title:setString(gameConfig.strings:string_common("equipInfo",6))
        self.infoItems.doLab1:setString(gameConfig.strings:string_common("equipInfo",5))
        ui.setLabelString(self.infoItems.doLab1,nil,19)
        ui.removeGray("CCControlButton",self.infoItems.doButton1)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab1)
        -- self.infoItems.doNode1:setPositionX(244)
        -- self.infoItems.doNode2:setPositionX(544)
        -- self.infoItems.doNode3:setPositionX(844)
    else
        -- self.infoItems.title:setString("装备详情")
        -- self.infoItems.doLab3:setString("强 化")
        self.infoItems.title:setString(gameConfig.strings:string_common("equipInfo",0))
        self.infoItems.doLab1:setString(gameConfig.strings:string_common("equipInfo",5))
        ui.setLabelString(self.infoItems.doLab1,nil,19)
        ui.removeGray("CCControlButton",self.infoItems.doButton1)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab1)
        -- self.infoItems.doNode1:setPositionX(244)
        -- self.infoItems.doNode2:setPositionX(544)
        -- self.infoItems.doNode3:setPositionX(844)
    end

    if self.opt and self.opt == 2 then
        for i = 1,5 do
            if self.infoItems["doNode"..i] then
                self.infoItems["doNode"..i]:setVisible(false)
            end
        end
        if self.infoItems["doNode0"] then
            self.infoItems["doNode0"]:setVisible(false)
        end
    end

    --xilian
    local xl_h = 0
    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        if equipConfig.quality > 3 and equipConfig.quality < 5 then
            xl_h = 320 + 40
        elseif equipConfig.quality >= 5 then
            xl_h = 320 + 40 + 280
        else
            xl_h = 160
        end
    elseif equipConfig.quality > 2 then
        xl_h = 160 + 160
    end

    -- 进阶
    if gameConfig:checkBuildOpen(150) and GameScene:checkopenlevelbyId(150,true) and equipConfig.evolve == 1 and equipConfig.type ~= "horse" and equipConfig.type ~= "treasure" then
        print("jinjie==height=")
        xl_h = xl_h + 280 + 80
    end

    --yuan

    local relation = {}
    if equipConfig.relation and equipConfig.relation ~= "" then
        if equipConfig.relation ~= 0 and equipConfig.relation ~= "0" then
            relation = ui.Split(equipConfig.relation,";")
        end
    end
    local maxnum = table.getTableLength(relation)
    if maxnum > 0 then
        if relation[maxnum] and relation[maxnum] == "" then
            maxnum = maxnum-1
        end
    end

    self.infoItems.container:setContentSize(CCSize(923,200*maxnum+80+40+(self.isSuit and (420+xl_h) or xl_h)))
    self.infoItems.scrollnode = tolua.cast(self.infoItems.scrollnode, "CCScrollView")
    self.infoItems.scrollnode:setTouchPriority(self.touchPriority)
    -- self.infoItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    self.yuanNode, self.yuanItems = CCBReaderLoad(self.isSuit and "equip_new/e_equip_info_t" or "equip_new/e_equip_info_n", nil, true, "equip_info_n")
    self.yuanNode:setPosition(0, 200*maxnum+80+40+(self.isSuit and (420+xl_h) or xl_h))
    self.infoItems.container:addChild(self.yuanNode)
    self.infoItems.scrollnode:setContentOffsetInDuration(ccp(0, 640-200*maxnum-80-40-(self.isSuit and (420+xl_h) or xl_h)), 0)

    --
    print("xl_h==",xl_h)
    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        self.yuanItems.cellcastnode:setVisible(false)
        self.yuanItems.cellxiliannode:setVisible(true)
        self.yuanItems["xl_title"]:setString("精 炼")
        if equipConfig.quality >= 5 then
            self.yuanItems.cellxiliannode:setPositionY(160 - xl_h + 280)
            if self.isSuit then
                self.yuanItems.cellsuitnode:setPositionY(-xl_h)
                self.yuanItems.cellyuannode:setPositionY(-420 - xl_h - 40 + 280)
            else
                self.yuanItems.cellyuannode:setPositionY(-xl_h - 40 - 40 + 280)
            end
        else
            self.yuanItems.cellxiliannode:setPositionY(160-xl_h)
            if self.isSuit then
                self.yuanItems.cellsuitnode:setPositionY(-xl_h)
                self.yuanItems.cellyuannode:setPositionY(-420 - xl_h - 40)
            else
                self.yuanItems.cellyuannode:setPositionY(-xl_h - 40 - 40)
            end
        end

        local jlstring = ""
        if equipConfig.type == "horse" then
            jlstring = "装备相同品质的典籍可激活套装属性"
        else
            jlstring = "装备相同品质的坐骑可激活套装属性"
        end
        
        self.yuanItems["jl_desc"]:setString(jlstring)

        --
        if equipConfig.quality > 3 then
            self.yuanItems.cellbaowunode:setVisible(true)
            local str = gamedata.config.global_kv[(equipConfig.quality-1).."_treasure_suit"].value or ""
            local attrs = ui.getSTRandNUMs(str) or {}
            for i = 1,4 do
                if attrs[i] and attrs[i] ~= "" then
                    local ss = gameConfig.strings.attr_type[attrs[i].str].." +"..( attrs[i].num<1 and ((attrs[i].num*100).."%") or attrs[i].num)
                    self.yuanItems["jl_att"..i]:setString(ss)
                    -- print("quality===",self.data.quality,gamedata.config.equip[tostring(self.data.anotherTreasure.cid)].quality)
                    
                    if self.data.anotherTreasure and self.data.anotherTreasure.cid ~= 0 and self.data.quality == gamedata.config.equip[tostring(self.data.anotherTreasure.cid)].quality then
                        print("激活套装属性")
                        self.yuanItems["jl_att"..i]:setColor(ccc3(135,81,25))
                    else
                        print("没有激活套装属性")
                        self.yuanItems["jl_att"..i]:setColor(ccc3(150,150,150))
                    end
                    -- self.yuanItems["jl_att"..i]:setColor(ccc3(135,81,25))
                else
                    self.yuanItems["jl_att"..i]:setString("")
                    self.yuanItems["jl_att"..i]:setColor(ccc3(150,150,150))
                end
            end
        else
            self.yuanItems.cellbaowunode:setVisible(false)
        end
        --

        -- 宝物精炼属性
        if equipConfig.type and (equipConfig.type == "horse" or equipConfig.type == "treasure") then
            if equipConfig.refine and equipConfig.refine ~= "" then
                local refinenum = 0
                for i = 1,self.data.level2 do
                    if equipConfig["refine-grow"..i] then
                        refinenum = refinenum + equipConfig["refine-grow"..i]
                    end
                end
                self.yuanItems["xl_desc"]:setString(gameConfig.strings.attr_type[equipConfig.refine].."+"..refinenum)
            else
                self.yuanItems["xl_desc"]:setString("")
            end
        else
            self.yuanItems["xl_desc"]:setString("")
        end

        for i = 1,6 do
            if equipConfig["refine-level"..i] and equipConfig["refine-level"..i] ~= "" then
                local str = equipConfig["refine-attr"..i]
                local ii = string.find(str, ";") or string.find(str, "；")
                if ii then
                    local ss = gameConfig.strings.attr_type[string.sub(str, 1, ii-1)].." +"..( tonumber(string.sub(str, ii+1))<=1 and ((tonumber(string.sub(str, ii+1))*100).."%") or tonumber(string.sub(str, ii+1)))
                    if self.data.level2 < equipConfig["refine-level"..i] then
                        self.yuanItems["xl_att"..i]:setString(ss.." (宝物+"..equipConfig["refine-level"..i].."解锁)")
                        self.yuanItems["xl_att"..i]:setColor(ccc3(150,150,150))
                    else
                        self.yuanItems["xl_att"..i]:setString(ss)
                        self.yuanItems["xl_att"..i]:setColor(ccc3(135,81,25))
                    end

                else
                    self.yuanItems["xl_att"..i]:setString("")
                    self.yuanItems["xl_att"..i]:setColor(ccc3(150,150,150))
                end
            else
                self.yuanItems["xl_att"..i]:setString("")
                self.yuanItems["xl_att"..i]:setColor(ccc3(150,150,150))
            end
        end
        --
    elseif equipConfig.quality > 2 then
        self.yuanItems.cellbaowunode:setVisible(false)
        self.yuanItems.cellxiliannode:setVisible(true)
        self.yuanItems.cellcastnode:setVisible(true)
        self.yuanItems["xl_title"]:setString("洗 炼")
        self.yuanItems["zl_title"]:setString(gameConfig.strings:string_common("equips",28))
        for i = 1,4 do
            if equipConfig["baptize_attr"..i] and equipConfig["baptize_attr"..i] ~= "" then
                self.yuanItems["xl_att"..i]:setString(gameConfig.strings.attr_type[equipConfig["baptize_attr"..i]]..": "..(self.data["x"..equipConfig["baptize_attr"..i]] or 0))
            else
                self.yuanItems["xl_att"..i]:setString("")
            end
        end
    else
        self.yuanItems.cellbaowunode:setVisible(false)
        self.yuanItems.cellxiliannode:setVisible(false)
        self.yuanItems.cellcastnode:setVisible(false)
        if self.isSuit then
            self.yuanItems.cellsuitnode:setPositionY(0)
            self.yuanItems.cellyuannode:setPositionY(-420)
        else
            self.yuanItems.cellyuannode:setPositionY(0)
        end
    end

    --宝物升星
    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        if equipConfig.quality >= 5 then
            self.yuanItems.cellupstarnode:setVisible(true)
            local mh = 0
            if equipConfig.quality == 5 then
                mh = 100
                self.yuanItems.us_skillname3:setVisible(false)
                self.yuanItems.us_skillname4:setVisible(false)
                self.yuanItems.us_skillname5:setVisible(false)
                self.yuanItems.us_skillname6:setVisible(false)
            elseif equipConfig.quality == 6 then
                mh = 50
                self.yuanItems.us_skillname5:setVisible(false)
                self.yuanItems.us_skillname6:setVisible(false)
            end
            if self.isSuit then
                self.yuanItems.cellsuitnode:setPositionY(-xl_h)
                self.yuanItems.cellupstarnode:setPositionY(-420 - xl_h - 40 + 280)
                self.yuanItems.cellyuannode:setPositionY(-420 - xl_h - 40 + mh)
            else
                self.yuanItems.cellupstarnode:setPositionY(-xl_h - 40 - 40 + 280)
                self.yuanItems.cellyuannode:setPositionY(-xl_h - 40 - 40 + mh)
            end
            --设置升星属性
            local starSkilllConfig = gamedata.config.treasure2_star
            local skilldata = {}
            for k,v in pairs(starSkilllConfig) do
                if v.show > 0 then
                    table.insert(skilldata,{id = v.id, activated = v[equipConfig.type.."_activated"]})
                end
            end
            table.sort(skilldata,function (a,b)
                return a.id < b.id
            end)
            printT(skilldata,"jkp-skilldata")

            for i=1, #skilldata do
                local breakskill = gamedata.config.breakskill[tostring(skilldata[i].activated)]
                if self.data and self.opt ~= 2 then
                    if self.data.level3 < skilldata[i].id then
                        self.yuanItems["us_skillname"..i]:setString(breakskill.name.." (升星+"..skilldata[i].id.."解锁)")
                        self.yuanItems["us_skillname"..i]:setColor(ccc3(150,150,150))
                    else
                        local newLv = self.data.level3 - skilldata[i].id + 1
                        if newLv > 5 then
                            newLv = 5
                        end
                        self.yuanItems["us_skillname"..i]:setString(breakskill.name.." Lv"..newLv)
                        self.yuanItems["us_skillname"..i]:setColor(ccc3(135,81,25))
                    end
                else
                    self.yuanItems["us_skillname"..i]:setString(breakskill.name.." (升星+"..skilldata[i].id.."解锁)")
                    self.yuanItems["us_skillname"..i]:setColor(ccc3(150,150,150))
                end
            end

            self.yuanItems.us_atk:setString("攻击+"..0)
            self.yuanItems.us_def:setString("防御+"..0)
            self.yuanItems.us_hp:setString("生命+"..0)
            if self.data and self.opt ~= 2 then
                if self.data.level3 > 0 then
                    self.yuanItems.us_atk:setString("攻击+"..starSkilllConfig[tostring(self.data.level3)].atk)
                    self.yuanItems.us_def:setString("防御+"..starSkilllConfig[tostring(self.data.level3)].def)
                    self.yuanItems.us_hp:setString("生命+"..starSkilllConfig[tostring(self.data.level3)].hp)
                end
            end
        else
            self.yuanItems.cellupstarnode:setVisible(false)
        end
    end

    -- 进阶
    if gameConfig:checkBuildOpen(150) and GameScene:checkopenlevelbyId(150,true) and equipConfig.evolve == 1 and equipConfig.type ~= "horse" and equipConfig.type ~= "treasure" then
        print("equipinfo=====000000")
        self.yuanItems.celljinjienode:setVisible(true)
        local level = self.data.level2
        local cid = self.data.cid
        local equip_evolve = gamedata.config.equip_evolve[tostring(cid)]

        local propertyString = gameConfig.strings:string_common("attr_type",equip_evolve["attr"]).."＋"..equip_evolve["init"..level] or {}

        self.yuanItems.jj_att:setString(propertyString)
        

        for i=1,13 do
            if self.yuanItems["jj_att"..i] then
                if equip_evolve["trigger_attr"..i] and equip_evolve["trigger_attr"..i] ~= "" then
                    local attrtemp = equip_evolve["trigger_attr"..i]
                    local attr,num = gamedata.getAttrData(attrtemp)
                    -- print("attr,num==",attr,num)
                    local strings = gameConfig.strings:string_common("attr_type",attr)
                    -- print("string2,desc==",strings,equip_evolve["desc"..i])
                    strings = strings..num.."%("..equip_evolve["desc"..i]..")"


                    self.yuanItems["jj_att"..i]:setString(strings)
                    if level >= tonumber(equip_evolve["trigger"..i]) then
                        -- print("level111,==",level,equip_evolve["trigger"..i])
                        self.yuanItems["jj_att"..i]:setColor(ccc3(135,81,25))
                    else
                        -- print("level222,==",level,equip_evolve["trigger"..i])
                        self.yuanItems["jj_att"..i]:setColor(ccc3(150,150,150))
                    end
                else
                    self.yuanItems["jj_att"..i]:setString("")
                end
            end
        end
    elseif equipConfig.type == "horse" or equipConfig.type == "treasure" then 
        print("equipinfo=====111111")
        self.yuanItems.celljinjienode:setVisible(false)
        if self.yuanItems.cellbaowunode then
            self.yuanItems.cellbaowunode:setPositionY(0)
        end
    elseif not (equipConfig.quality == 2 and equipConfig.suit) then
        self.yuanItems.celljinjienode:setVisible(false)
        if self.yuanItems.cellbaowunode then
            self.yuanItems.cellbaowunode:setPositionY(0)
        end

        if self.yuanItems.cellxiliannode then
            self.yuanItems.cellxiliannode:setPositionY(0)
        end
        if self.yuanItems.cellcastnode then
            local x,y = self.yuanItems.cellcastnode:getPosition()
            self.yuanItems.cellcastnode:setPositionY(y + 320)
        end
        if self.yuanItems.cellsuitnode then
            printT(self.yuanItems.cellsuitnode:getPosition())
            local x,y = self.yuanItems.cellsuitnode:getPosition()
            print("cellsuitnode.y==",x,y)
            self.yuanItems.cellsuitnode:setPositionY(y+320)
        end
        if self.yuanItems.cellyuannode then
            local x,y = self.yuanItems.cellyuannode:getPosition()
            print("cellyuannode.y==",x,y)
            self.yuanItems.cellyuannode:setPositionY(y+320)
        end
    elseif equipConfig.quality == 2 and equipConfig.suit then
        self.yuanItems.celljinjienode:setVisible(false)
    end

    --注灵
    if equipConfig.type ~= "horse" and equipConfig.type ~= "treasure" and equipConfig.quality > 2 then
        local maxLevel = GameScene.roleinfo.level > equipConfig.forging_maxlevel and equipConfig.forging_maxlevel or GameScene.roleinfo.level
        self.yuanItems.zl_level:setString(gameConfig.strings:string_common("equips",30).." "..self.data.level4.."/"..maxLevel)
        local type = gameConfig.strings.attr_type[equipConfig.forging_attr]..":"
        local num = " "..math.floor(equipConfig.forging_grow* self.data.level4 * (equipConfig.method1 == "value" and 1 or 100))..(equipConfig.method1 == "value" and "" or "%")
        self.yuanItems.zl_att1:setString(type..num)
    end

    --
    if self.yuannum < 1 then
        self.yuanItems.cellyuannode:setVisible(false)
    else
        self.yuanItems.cellyuannode:setVisible(true)
    end

    for i = 1,maxnum do

        local cellNode, cellItems = CCBReaderLoad("equip_new/cell_yuan1", nil, true, "cell_yuan")
        cellNode:setPosition(460,-170-200*(i-1))
        self.yuanItems.cellyuannode:addChild(cellNode)

        ui.setNewIcon(cellItems,{cid = relation[i]})
        -- 增加弹出窗口
        cellItems.i_button:addHandleOfControlEvent(function()
            if not self.isscrolltouched then return end
            ui.setPopwindowByCid(relation[i]) 
        end, CCControlEventTouchUpInside)
        cellItems.i_button:setSwallowsTouch(true)
        cellItems.i_button:setTouchPriority(self.touchPriority + 1)

        local Config = gamedata.config.general[tostring(relation[i])]
        cellItems["y_general"]:setString(Config.name)
        for ii = 1,24 do
           if (Config["cond"..ii.."ids"] and Config["cond"..ii.."ids"] ~= "") and ((Config["cond"..ii.."ids"] == tostring(self.data.cid)) or (Config["cond"..ii.."ids"] == tostring(equipConfig.treasure_relation or 0)))then
               cellItems["y_name"]:setString(Config["cond"..ii.."name"])
               local pos = string.find(Config["cond"..ii.."buf"],":") or string.find(Config["cond"..ii.."buf"],"：")
               cellItems["y_num"]:setString(string.sub(Config["cond"..ii.."buf"],pos+1).."%"..gameConfig.strings.attr_type[string.sub(Config["cond"..ii.."buf"],1,pos-1)])
           end
        end
    end

    --suit
    print("isSuit===",self.isSuit)
    printT(self.data,"jkp-isSuit")
    if self.isSuit then

        self.yuanItems.suit_equip1:setVisible(false)
        self.yuanItems.suit_equip2:setVisible(false)
        self.yuanItems.suit_equip3:setVisible(false)
        self.yuanItems.suit_equip4:setVisible(false)
        local suitconfig = gamedata.config.suit[tostring(equipConfig.suit)] --套装id
        -- printT(equipConfig.suit)
        print("suitconfig===",equipConfig.suit)
        printT(self.yuanItems)

        for i = 1,4 do
            if suitconfig["id"..i] and suitconfig["id"..i]>0 then
                local cidnum = suitconfig["id"..i]
                if self.data.suit then
                    if suitconfig["6id"..i] ~= 0 and self.data.suit[tostring(suitconfig["6id"..i])] then
                        cidnum = suitconfig["6id"..i]
                    elseif suitconfig["7id"..i] ~= 0 and self.data.suit[tostring(suitconfig["7id"..i])] then
                        cidnum = suitconfig["7id"..i]
                    end
                end
                print("cidnum = ",cidnum)
                printT(self.data.suit,"suit===")
                self.yuanItems["suit_equip"..i]:setVisible(true)
                ui.setNewIcon(self.yuanItems,{cid = cidnum},i-1)
                self.yuanItems["i_button"..(i ~= 1 and "_"..(i-1) or "")]:addHandleOfControlEvent(function()
                    gameWindows:openWindow("dropTips",{cid = cidnum},nil)
                end,CCControlEventTouchUpInside)
                self.yuanItems["i_button"..(i ~= 1 and "_"..(i-1) or "")]:setSwallowsTouch(true)
                self.yuanItems["i_button"..(i ~= 1 and "_"..(i-1) or "")]:setTouchPriority(self.touchPriority + 1)

                if self.data.suit and self.data.suit[tostring(cidnum)] then
                    -- 判断该套装不见在不在阵上
                    self.yuanItems["suit_equipname"..i]:setString(ui.getEquipStageName(self.data.suitstage[tostring(self.data.suit[tostring(cidnum)])]))
                elseif self.data.suit == nil  then
                    -- 不在阵的装备处于哪一个进阶范围,取当前范围的激活进阶等级
                    local level2num = self.data.level2
                    if self.data.quality == 6 and suitconfig["6id"..i] ~= 0 then
                        cidnum = suitconfig["6id"..i]
                        level2num = level2num + 30
                        ui.setNewIcon(self.yuanItems,{cid = cidnum},i-1)
                    elseif self.data.quality == 7 and suitconfig["7id"..i] ~= 0 then
                        cidnum = suitconfig["7id"..i]
                        if gamedata.config.equip[tostring(cidnum)].init_eid and gamedata.config.equip[tostring(cidnum)].init_eid == 1 then
                            --初始红装
                            level2num = level2num + 50    
                        else
                            level2num = level2num + 80
                        end
                        ui.setNewIcon(self.yuanItems,{cid = cidnum},i-1)
                    end

                    local firtstagelevelnum = 0
                    for ia = 13,1,-1 do
                        if suitconfig["equip_evolve_"..ia] then
                            if tonumber(level2num) >= tonumber(suitconfig["equip_evolve_"..ia]) then
                                if self.data.quality == 6 and suitconfig["6id"..i] ~= 0 then
                                    firtstagelevelnum = suitconfig["equip_evolve_"..ia]-30
                                elseif self.data.quality == 7 and suitconfig["7id"..i] ~= 0 then
                                    if gamedata.config.equip[tostring(cidnum)].init_eid and gamedata.config.equip[tostring(cidnum)].init_eid == 1 then
                                        --初始红装
                                        firtstagelevelnum = suitconfig["equip_evolve_"..ia]-50
                                    else
                                        firtstagelevelnum = suitconfig["equip_evolve_"..ia]-80
                                    end
                                else
                                    firtstagelevelnum = suitconfig["equip_evolve_"..ia]
                                end
                                break
                            end
                        end
                    end
                    local tempdata = {}
                    tempdata.cid = cidnum
                    tempdata.level2 = firtstagelevelnum
                    tempdata.quality = self.data.quality
                    self.yuanItems["suit_equipname"..i]:setString(ui.getEquipStageName(tempdata))
                else
                    self.yuanItems["suit_equipname"..i]:setString(gamedata.config.equip[tostring(cidnum)].name)
                end
            else
                self.yuanItems["suit_equip"..i]:setVisible(false)
                self.yuanItems["suit_equipname"..i]:setString("")
            end
        end

        --
        local hasid = {0, 0, 0, 0}
        --
        printT(suitconfig,"suitconfig===")
        local stagenum = {0, 0, 0, 0}
        if self.data.suit then
            for i = 1,4 do
                if (suitconfig["id"..i] and self.data.suit[tostring(suitconfig["id"..i])]) or (suitconfig["6id"..i] and self.data.suit[tostring(suitconfig["6id"..i])]) or (suitconfig["7id"..i] and self.data.suit[tostring(suitconfig["7id"..i])]) then
                    local tempcid = suitconfig["id"..i]
                    if suitconfig["6id"..i] ~= 0 and self.data.suit[tostring(suitconfig["6id"..i])] then
                        tempcid = suitconfig["6id"..i]
                    elseif suitconfig["7id"..i] ~= 0 and self.data.suit[tostring(suitconfig["7id"..i])] then
                        tempcid = suitconfig["7id"..i]
                    end

                    local level2 = self.data.suitstage[tostring(self.data.suit[tostring(tempcid)])]["level2"]
                    local tempconfig = gamedata.config.equip[tostring(tempcid)]
                    if tempconfig.quality == 6 and suitconfig["6id"..i] ~= 0 then
                        level2 = level2 + 30
                    elseif tempconfig.quality == 7 and suitconfig["7id"..i] ~= 0 then
                        if tempconfig.init_eid and tempconfig.init_eid == 1 then
                            --初始红装
                            level2 = level2 + 50
                        else
                            level2 = level2 + 80
                        end
                    end

                    if suitconfig.equip_evolve_1 ~= 0 then
                        for ai=1,13 do
                            if suitconfig["equip_evolve_"..(14-ai)] and (tonumber(suitconfig["equip_evolve_"..(14-ai)]) > 0) and (tonumber(level2) >= tonumber(suitconfig["equip_evolve_"..(14-ai)])) then
                                stagenum[i] = 14-ai
                                break
                            end
                        end
                    end
                    hasid[i] = 1
                end
            end
        end
        -- print("stagenum===")
        -- printT(stagenum)

        for i = 1,4 do
            if hasid[i] == 0 then
                self.yuanItems["i_k_quality"..(i==1 and "" or ("_"..i-1))]:setColor(ccc3(150,150,150))
                self.yuanItems["i_quality"..(i==1 and "" or ("_"..i-1))]:setColor(ccc3(150,150,150))
                self.yuanItems["i_icon"..(i==1 and "" or ("_"..i-1))]:setColor(ccc3(150,150,150))
            else
                self.yuanItems["suit_equipname"..i]:setColor(ccc3(135,81,25))
            end
        end

        local hasidnum = hasid[1] + hasid[2] + hasid[3] + hasid[4]

        self.yuanItems.suit_name:setString(suitconfig.name.." ("..hasidnum.."/4) ")

        if hasidnum >= 2 then
            self.yuanItems.suit_att1:setColor(ccc3(135,81,25))
            self.yuanItems.suit_att1_1:setColor(ccc3(135,81,25))
            self.yuanItems.suit_att1_2:setColor(ccc3(135,81,25))
        end
        if hasidnum >= 3 then
            self.yuanItems.suit_att2:setColor(ccc3(135,81,25))
            self.yuanItems.suit_att2_1:setColor(ccc3(135,81,25))
            self.yuanItems.suit_att2_2:setColor(ccc3(135,81,25))
        end
        if hasidnum >= 4 then
            self.yuanItems.suit_att3:setColor(ccc3(135,81,25))
            self.yuanItems.suit_att3_1:setColor(ccc3(135,81,25))
            self.yuanItems.suit_att3_2:setColor(ccc3(135,81,25))
            self.yuanItems.suit_att3_3:setColor(ccc3(135,81,25))
            self.yuanItems.suit_att3_4:setColor(ccc3(135,81,25))
        end

        --套装属性
        -- stage判断
        local team2num1 = 0
        local team2num2 = 0
        local team2num3 = 0
        local team2num4 = 0
        local team2num5 = 0
        local team2num6 = 0
        local team2num7 = 0
        local team2num8 = 0
        local team2num9 = 0
        local team2num10 = 0
        local team2num11 = 0
        local team2num12 = 0
        local team2num13 = 0
        for i,v in ipairs(stagenum) do
            if v >= 1 then
                team2num1 = team2num1 + 1
            end
            if v >= 2 then
                team2num2 = team2num2 + 1
            end
            if v >= 3 then
                team2num3 = team2num3 + 1
            end
            if v >= 4 then
                team2num4 = team2num4 + 1
            end
            if v >= 5 then
                team2num5 = team2num5 + 1
            end
            if v >= 6 then
                team2num6 = team2num6 + 1
            end
            if v >= 7 then
                team2num7 = team2num7 + 1
            end
            if v >= 8 then
                team2num8 = team2num8 + 1
            end
            if v >= 9 then
                team2num9 = team2num9 + 1
            end
            if v >= 10 then
                team2num10 = team2num10 + 1
            end
            if v >= 11 then
                team2num11 = team2num11 + 1
            end
            if v >= 12 then
                team2num12 = team2num12 + 1
            end
            if v >= 13 then
                team2num13 = team2num13 + 1
            end
        end

        -- stage判断 俩件套
        local attrString = "2attr"
        if team2num13 >= 2 then
            attrString = "2attr_13"
        elseif team2num12 >= 2 then
            attrString = "2attr_12"
        elseif team2num11 >= 2 then
            attrString = "2attr_11"
        elseif team2num10 >= 2 then
            attrString = "2attr_10"
        elseif team2num9 >= 2 then
            attrString = "2attr_9"
        elseif team2num8 >= 2 then
            attrString = "2attr_8"
        elseif team2num7 >= 2 then
            attrString = "2attr_7"
        elseif team2num6 >= 2 then
            attrString = "2attr_6"
        elseif team2num5 >= 2 then
            attrString = "2attr_5"
        elseif team2num4 >= 2 then
            attrString = "2attr_4"
        elseif team2num3 >= 2 then
            attrString = "2attr_3"
        elseif team2num2 >= 2 then
            attrString = "2attr_2"
        elseif team2num1 >= 2 then
            attrString = "2attr_1"
        end
        printT(stagenum,"stagenum===")
        if suitconfig[attrString] == "" or suitconfig[attrString] == nil then
            attrString = "2attr"
        end
        -- 不在阵的装备处于哪一个进阶范围（套装属性设置
        if self.data.suit == nil  then
            local level2num = self.data.level2
            if self.data.quality == 6 and suitconfig["6id1"] ~= 0 then
                level2num = level2num + 30
            elseif self.data.quality == 7 and suitconfig["7id1"] ~= 0 then
                local init_eid = gamedata.config.equip[tostring(suitconfig["7id1"])].init_eid or 0
                if init_eid == 1 then
                    --初始红装
                    level2num = level2num + 50
                else
                    level2num = level2num + 80
                end
            end

            for ia = 13,1,-1 do
                if suitconfig["equip_evolve_"..ia] and suitconfig["equip_evolve_"..ia] ~= 0 and tonumber(level2num) >= tonumber(suitconfig["equip_evolve_"..ia]) then
                    attrString = "2attr_"..ia
                    break
                end
            end
        end

        if suitconfig[attrString] and suitconfig[attrString] ~= "" then
            local att = ui.Split(suitconfig[attrString],";")
            if att[1] then
                local att1 = ui.Split(att[1],",")
                if att1[2] then
                    if 0+att1[2] < 1 then
                        att1[2] = tostring((0+att1[2])*100).."%"
                    end
                    self.yuanItems["suit_att1_1"]:setString(gameConfig.strings.attr_type[att1[1]]..":+"..att1[2])
                else
                    self.yuanItems.suit_att1_1:setString(" ")
                end
            end
            if att[2] then
                local att2 = ui.Split(att[2],",")
                if att2[2] then
                    if 0+att2[2] < 1 then
                        att2[2] = tostring((0+att2[2])*100).."%"
                    end
                    self.yuanItems["suit_att1_2"]:setString(gameConfig.strings.attr_type[att2[1]]..":+"..att2[2])
                else
                    self.yuanItems.suit_att1_2:setString(" ")
                end
            else
                self.yuanItems.suit_att1_2:setString(" ")
            end
        else
            self.yuanItems.suit_att1_1:setString(" ")
            self.yuanItems.suit_att1_2:setString(" ")
        end


        -- stage判断 三件套
        local attrString = "3attr"
        if team2num13 >= 3 then
            attrString = "3attr_13"
        elseif team2num12 >= 3 then
            attrString = "3attr_12"
        elseif team2num11 >= 3 then
            attrString = "3attr_11"
        elseif team2num10 >= 3 then
            attrString = "3attr_10"
        elseif team2num9 >= 3 then
            attrString = "3attr_9"        
        elseif team2num8 >= 3 then
            attrString = "3attr_8"
        elseif team2num7 >= 3 then
            attrString = "3attr_7"
        elseif team2num6 >= 3 then
            attrString = "3attr_6"
        elseif team2num5 >= 3 then
            attrString = "3attr_5"
        elseif team2num4 >= 3 then
            attrString = "3attr_4"
        elseif team2num3 >= 3 then
            attrString = "3attr_3"
        elseif team2num2 >= 3 then
            attrString = "3attr_2"
        elseif team2num1 >= 3 then
            attrString = "3attr_1"
        end
        if suitconfig[attrString] == "" or suitconfig[attrString] == nil then
            attrString = "3attr"
        end
        -- 不在阵的装备处于哪一个进阶范围（套装属性设置
        if self.data.suit == nil  then
            local level2num = self.data.level2
            if self.data.quality == 6 and suitconfig["6id1"] ~= 0 then
                level2num = level2num + 30
            elseif self.data.quality == 7 and suitconfig["7id1"] ~= 0 then
                local init_eid = gamedata.config.equip[tostring(suitconfig["7id1"])].init_eid or 0
                if init_eid == 1 then
                    --初始红装
                    level2num = level2num + 50
                else
                    level2num = level2num + 80
                end
            end

            for ia = 13,1,-1 do
                if suitconfig["equip_evolve_"..ia] and suitconfig["equip_evolve_"..ia] ~= 0 and tonumber(level2num) >= tonumber(suitconfig["equip_evolve_"..ia]) then
                    attrString = "3attr_"..ia
                    break
                end
            end
        end

        if suitconfig[attrString] and suitconfig[attrString] ~= "" then
            local att = ui.Split(suitconfig[attrString],";")
            if att[1] then
                local att1 = ui.Split(att[1],",")
                if att1[2] then
                    if 0+att1[2] < 1 then
                        att1[2] = tostring((0+att1[2])*100).."%"
                    end
                    self.yuanItems["suit_att2_1"]:setString(gameConfig.strings.attr_type[att1[1]]..":+"..att1[2])
                else
                    self.yuanItems.suit_att2_1:setString(" ")
                end
            end
            if att[2] then
                local att2 = ui.Split(att[2],",")
                if att2[2] then
                    if 0+att2[2] < 1 then
                        att2[2] = tostring((0+att2[2])*100).."%"
                    end
                    self.yuanItems["suit_att2_2"]:setString(gameConfig.strings.attr_type[att2[1]]..":+"..att2[2])
                else
                    self.yuanItems.suit_att2_2:setString(" ")
                end
            else
                self.yuanItems.suit_att2_2:setString(" ")
            end
        else
            self.yuanItems.suit_att2_1:setString(" ")
            self.yuanItems.suit_att2_2:setString(" ")
        end

        -- stage判断 四件套

        local attrString = "4attr"
        if team2num13 >= 4 then
            attrString = "4attr_13"
        elseif team2num12 >= 4 then
            attrString = "4attr_12"
        elseif team2num11 >= 4 then
            attrString = "4attr_11"
        elseif team2num10 >= 4 then
            attrString = "4attr_10"
        elseif team2num9 >= 4 then
            attrString = "4attr_9"
        elseif team2num8 >= 4 then
            attrString = "4attr_8"
        elseif team2num7 >= 4 then
            attrString = "4attr_7"
        elseif team2num6 >= 4 then
            attrString = "4attr_6"
        elseif team2num5 >= 4 then
            attrString = "4attr_5"
        elseif team2num4 >= 4 then
            attrString = "4attr_4"
        elseif team2num3 >= 4 then
            attrString = "4attr_3"
        elseif team2num2 >= 4 then
            attrString = "4attr_2"
        elseif team2num1 >= 4 then
            attrString = "4attr_1"
        end
        if suitconfig[attrString] == "" or suitconfig[attrString] == nil then
            attrString = "4attr"
        end
        -- 不在阵的装备处于哪一个进阶范围（套装属性设置
        if self.data.suit == nil  then
            local level2num = self.data.level2
            if self.data.quality == 6 and suitconfig["6id1"] ~= 0 then
                level2num = level2num + 30
            elseif self.data.quality == 7 and suitconfig["7id1"] ~= 0 then
                local init_eid = gamedata.config.equip[tostring(suitconfig["7id1"])].init_eid or 0
                if init_eid == 1 then
                    --初始红装
                    level2num = level2num + 50
                else
                    level2num = level2num + 80
                end
            end

            for ia = 13,1,-1 do
                if suitconfig["equip_evolve_"..ia] and suitconfig["equip_evolve_"..ia] ~= 0 and tonumber(level2num) >= tonumber(suitconfig["equip_evolve_"..ia]) then
                    attrString = "4attr_"..ia
                    break
                end
            end
        end

        if suitconfig[attrString] and suitconfig[attrString] ~= "" then
            local att = ui.Split(suitconfig[attrString],";")
            if att[1] then
                local att1 = ui.Split(att[1],",")
                if att1[2] then
                    if 0+att1[2] < 1 then
                        att1[2] = tostring((0+att1[2])*100).."%"
                    end
                    self.yuanItems["suit_att3_1"]:setString(gameConfig.strings.attr_type[att1[1]]..":+"..att1[2])
                else
                    self.yuanItems.suit_att3_1:setString(" ")
                end
            end
            if att[2] then
                local att2 = ui.Split(att[2],",")
                if att2[2] then
                    if 0+att2[2] < 1 then
                        att2[2] = tostring((0+att2[2])*100).."%"
                    end
                    self.yuanItems["suit_att3_2"]:setString(gameConfig.strings.attr_type[att2[1]]..":+"..att2[2])
                else
                    self.yuanItems.suit_att3_2:setString(" ")
                end
            else
                self.yuanItems.suit_att3_2:setString(" ")
            end
            if att[3] then
                local att3 = ui.Split(att[3],",")
                if att3[2] then
                    if 0+att3[2] < 1 then
                        att3[2] = tostring((0+att3[2])*100).."%"
                    end
                    self.yuanItems["suit_att3_3"]:setString(gameConfig.strings.attr_type[att3[1]]..":+"..att3[2])
                else
                    self.yuanItems.suit_att3_3:setString(" ")
                end
            else
                self.yuanItems.suit_att3_3:setString(" ")
            end
            if att[4] then
                local att4 = ui.Split(att[4],",")
                if att4[2] then
                    if 0+att4[2] < 1 then
                        att4[2] = tostring((0+att4[2])*100).."%"
                    end
                    self.yuanItems["suit_att3_4"]:setString(gameConfig.strings.attr_type[att4[1]]..":+"..att4[2])
                else
                    self.yuanItems.suit_att3_4:setString(" ")
                end
            else
                self.yuanItems.suit_att3_4:setString(" ")
            end
        else
            self.yuanItems.suit_att3_1:setString(" ")
            self.yuanItems.suit_att3_2:setString(" ")
            self.yuanItems.suit_att3_3:setString(" ")
            self.yuanItems.suit_att3_4:setString(" ")
        end

    end

end


function equipInfo.setPage_up(self)

    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]

    --self.upItems.title:setString("装备强化")
    self.upItems.title:setString(gameConfig.strings:string_common("equipInfo",8))
    self.upItems.e_desc:setString(equipConfig.desc)
    self.upItems.e_equiptype:setString(gameConfig.strings.equipType[equipConfig.type])
    self.upItems.e_name:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or "" ))
    if equipConfig.quality >= 7 then
        ui.setLabelString(self.upItems.e_name,nil,213)
    else
        ui.setLabelString(self.upItems.e_name,nil,(equipConfig.quality or 1)*2-1)
    end
    --
    ui.setIconLv(self.upItems,self.data)
    if equipConfig.suit and equipConfig.suit > 0 then
        self.upItems.e_equiptypenode1:setVisible(false)
        self.upItems.e_equiptypenode2:setVisible(true)
        self.isSuit = true
    else
        self.upItems.e_equiptypenode1:setVisible(true)
        self.upItems.e_equiptypenode2:setVisible(false)
        self.isSuit = false
    end
    --
    local type1,num1,type2,num2 = ui.setEquipPromote(self.upItems["e_type1"],self.upItems["e_type2"],self.data,self.upItems["e_type3"])
    --

    ui.setLabelString(self.upItems["num1"],num1,14)
    self.upItems["type1"]:setString(type1)
    ui.setLabelString(self.upItems["num2"],num2,14)
    self.upItems["type2"]:setString(type2)

    self.upItems["paramNode2"]:setVisible(equipConfig.attr2 and equipConfig.attr2~="")

    local maxlv = 0
    maxlv = GameScene.roleinfo.level*tonumber(gamedata.config.global_kv.equip_level.value)
    if equipConfig.maxlevel and (maxlv > (equipConfig.maxlevel+0)) then
       maxlv = equipConfig.maxlevel+0
    end

    self.upItems.e_level:setString("强化等级:  "..self.data.level1.."/"..maxlv)
    ui.setLabelString(self.upItems["lv1"],self.data.level1.."/"..maxlv,14)

    if self.data.level1 < maxlv then
        ui.setLabelString(self.upItems["next_lv1"],(self.data.level1+1).."/"..maxlv,23)
        local type1_,num1_,type2_,num2_ = ui.setEquipPromote(nil,nil,{cid=self.data.cid, level1=self.data.level1+1, level2=self.data.level2})
        ui.setLabelString(self.upItems["next_num1"],num1_,23)
        ui.setLabelString(self.upItems["next_num2"],num2_,23)
        ui.setLabelString(self.upItems["x_coinNum1"],gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality] ,14)
        ui.setLabelString(self.upItems["x_coinNum2"],gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality] ,14)
    else
        ui.setLabelString(self.upItems["next_lv1"],self.data.level1.."/"..maxlv,23)
        ui.setLabelString(self.upItems["next_num1"],num1,23)
        ui.setLabelString(self.upItems["next_num2"],num2,23)
        ui.setLabelString(self.upItems["x_coinNum1"],0,14)
        ui.setLabelString(self.upItems["x_coinNum2"],0,14)
    end
    --
    self.upItems["coinNum"]:setString(self.rolecoin)
    ui.setLabelString(self.upItems["coinNum"],nil,14)

    --
    self.upItems.closeButton:addHandleOfControlEvent(function()
        guide:setGuideProlayer(true)
        self.callback = nil
        gameWindows:closeWindow("equipInfo")
    end, CCControlEventTouchUpInside)
    self.upItems.closeButton:setSwallowsTouch(true)
    self.upItems.closeButton:setTouchPriority(self.touchPriority)
    --

    ui.setLabelString(self.upItems.doLab1,nil,19)
    self.upItems.doButton1:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.data.level1+0 >= maxlv then
            --runGamePrompt({msg = "已达到强化等级上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",9)})
        elseif self.rolecoin < gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality] then
            --runGamePrompt({msg = "银币不足"})
            --runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",10)})
            shortCoin()
        else
            if equipConfig.type == "horse" or equipConfig.type == "treasure" then
                 --runGamePrompt({msg = "装备类型错误"})
                 runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",11)})
            else
                UIRequest({type = 1101, xcoin = gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality], iid = self.data.iid, method = 1})
            end
        end
    end, CCControlEventTouchUpInside)
    self.upItems.doButton1:setSwallowsTouch(true)
    self.upItems.doButton1:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.upItems.doLab2,nil,19)
    self.upItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.data.level1+0 >= maxlv then
            --runGamePrompt({msg = "已达到强化等级上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",9)})
        elseif self.rolecoin < gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality] then
            --runGamePrompt({msg = "银币不足"})
            --runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",10)})
            shortCoin()
        else
            if equipConfig.type == "horse" or equipConfig.type == "treasure" then
                --runGamePrompt({msg = "装备类型错误"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",11)})
            else
                UIRequest({type = 1101, xcoin = gamedata.config.equip_strengthen[tostring(self.data.level1)]["quality"..equipConfig.quality], iid = self.data.iid, method = 0})
            end
        end
    end, CCControlEventTouchUpInside)
    self.upItems.doButton2:setSwallowsTouch(true)
    self.upItems.doButton2:setTouchPriority(self.touchPriority)

    --
    --effect
    if self.hasup and self.hasup == 1 then
        self.hasup = 0
        self.upItems.effectNode:removeAllChildrenWithCleanup(true)
        self.upItems.effectNode2:removeAllChildrenWithCleanup(true)
        --
        local qianghuaNode2,qianghuaItems2 = CCBReaderLoad("UIEffect/qianghua/qianghua2", nil, true, "qianghua2")
        qianghuaNode2:setPosition(0,0)
        self.upItems.effectNode2:addChild(qianghuaNode2)
        self.upItems.effectNode2:setScale(1)
        local animationManager2 = getAnimationManager(qianghuaItems2)
        animationManager2:setAnimationCompletedCallback(function()
            self.upItems.effectNode2:removeAllChildrenWithCleanup(true)
            local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/qianghua/qianghua", nil, true, "qianghua")
            qianghuaNode:setPosition(0,0)
            self.upItems.effectNode:addChild(qianghuaNode)
            self.upItems.effectNode:setScale(1)
            local animationManager = getAnimationManager(qianghuaItems)
            animationManager:setAnimationCompletedCallback(function()
                self.upItems.effectNode:removeAllChildrenWithCleanup(true)
                if guide.controller then
                    guide.controller:setGuideLayerVisible(true)
                end
            end)
            animationManager:runAnimationsForSequenceNamed("qianghua")

            local animationManager3 = getAnimationManager(self.upItems)
            animationManager3:runAnimationsForSequenceNamed("qianghua")
        end)
        animationManager2:runAnimationsForSequenceNamed("qianghua2")
        --
        gamedata.music:PlayOptSound("qh")
    end
end


function equipInfo.setPage_treasureRefine(self)

    self.treasureRefineItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("equipInfo")
    end, CCControlEventTouchUpInside)
    self.treasureRefineItems.closeButton:setSwallowsTouch(true)
    self.treasureRefineItems.closeButton:setTouchPriority(self.touchPriority)

    --
    --self.treasureRefineItems.title:setString("宝物升华")
    self.treasureRefineItems.title:setString(gameConfig.strings:string_common("equipInfo",12))

    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    local maxlv = table.getTableLength(gamedata.config.treasure_refine) or 10
    if equipConfig.maxlevel2 and (maxlv > (equipConfig.maxlevel2+0)) then
        maxlv = equipConfig.maxlevel2+0
    end

    self.treasureRefineItems["name"]:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or ""))
    self.treasureRefineItems["lv1"]:setString("等级:"..self.data.level1)
    ui.setLabelString(self.treasureRefineItems.lv1,nil,13)

    if equipConfig.quality >= 7 then
        ui.setLabelString(self.treasureRefineItems["name"],nil,213)
    else
        ui.setLabelString(self.treasureRefineItems["name"],nil,(equipConfig.quality or 1)*2-1)
    end

--    local type1,num1,type2,num2 = ui.setEquipPromote(nil,nil,self.data)
--    local type1_,num1_,type2_,num2_ = ui.setEquipPromote(nil,nil,{cid=self.data.cid, level1=self.data.level1, level2=self.data.level2+1 > maxlv and self.data.level2 or self.data.level2+1})
--    self.treasureRefineItems["type1"]:setString(type1)
--    ui.setLabelString(self.treasureRefineItems["num1"],num1,13)
--    ui.setLabelString(self.treasureRefineItems["next_num1"],num1_,23)
--
--    if equipConfig.attr2 and equipConfig.attr2~="" then
--        self.treasureRefineItems["node_type2"]:setVisible(true)
--        self.treasureRefineItems["type2"]:setString(type2)
--        ui.setLabelString(self.treasureRefineItems["num2"],num2,13)
--        ui.setLabelString(self.treasureRefineItems["next_num2"],num2_,23)
--    end


    self.treasureRefineItems["type1"]:setString(gameConfig.strings.attr_type[equipConfig.attr1])
    ui.setLabelString(self.treasureRefineItems["type1"],nil,21)
    if self.data.level2 == "0" or self.data.level2 == 0 then
        ui.setLabelString(self.treasureRefineItems["num1"],"x100%",13)
    else
        ui.setLabelString(self.treasureRefineItems["num1"],"x"..(gamedata.config.treasure_refine[tostring(self.data.level2)]["radio"]*100).."%",13)
    end
    if self.data.level2+1 > maxlv then
        ui.setLabelString(self.treasureRefineItems["next_num1"],"x"..(gamedata.config.treasure_refine[tostring(self.data.level2)]["radio"]*100).."%",23)
    else
        ui.setLabelString(self.treasureRefineItems["next_num1"],"x"..(gamedata.config.treasure_refine[tostring(self.data.level2+1)]["radio"]*100).."%",23)
    end

    if equipConfig.attr2 and equipConfig.attr2~="" then
        self.treasureRefineItems["node_type2"]:setVisible(true)
        self.treasureRefineItems["type2"]:setString(gameConfig.strings.attr_type[equipConfig.attr2])
        ui.setLabelString(self.treasureRefineItems["type2"],nil,21)
        if self.data.level2 == "0" or self.data.level2 == 0 then
            ui.setLabelString(self.treasureRefineItems["num2"],"x100%",13)
        else
            ui.setLabelString(self.treasureRefineItems["num2"],"x"..(gamedata.config.treasure_refine[tostring(self.data.level2)]["radio"]*100).."%",13)
        end
        if self.data.level2+1 > maxlv then
            ui.setLabelString(self.treasureRefineItems["next_num2"],"x"..(gamedata.config.treasure_refine[tostring(self.data.level2)]["radio"]*100).."%",23)
        else
            ui.setLabelString(self.treasureRefineItems["next_num2"],"x"..(gamedata.config.treasure_refine[tostring(self.data.level2+1)]["radio"]*100).."%",23)
        end
    end

    local equips = self.data.allnum or {}
    local xequips = {}
    local xnum = 0
    for k,v in pairs(equips) do
        if v ~= self.data.iid then
            table.insert(xequips,v)
        end
    end
    if self.data.level2+1 > maxlv then
        xnum = 0
    else
        xnum = gamedata.config.treasure_refine[tostring(self.data.level2+1)]["num"] or 1
    end

    ui.setNewIcon(self.treasureRefineItems,{cid = self.data.cid},0)
    ui.setNewIconName(self.treasureRefineItems,{cid = self.data.cid, numdesc = table.getTableLength(xequips).."/"..xnum},0)

    --self.treasureRefineItems.doLab:setString("升 华")
    self.treasureRefineItems.doLab:setString(gameConfig.strings:string_common("equipInfo",7))
    ui.setLabelString(self.treasureRefineItems.doLab,nil,19)
    self.treasureRefineItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.data.level2+1 > maxlv then
            --runGamePrompt({msg = "已达到最高阶"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",13)})
            return
        end

        if table.getTableLength(xequips) >= xnum then
            local ids = {}
            for i = 1, xnum do
                table.insert(ids,xequips[i])
            end
            UIRequest({type = 1106, iid = self.data.iid, ids = ids})
        else
            --runGamePrompt({msg = "材料不够"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",14)})
        end
    end, CCControlEventTouchUpInside)
    self.treasureRefineItems.doButton:setSwallowsTouch(true)
    self.treasureRefineItems.doButton:setTouchPriority(self.touchPriority)

    --
    --effect
    if self.hasup and self.hasup == 1 then
        self.hasup = 0
        --
        self.treasureRefineItems.bgEffectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode1,qianghuaItems1 = CCBReaderLoad("UIEffect/qianghua/luzi_effect", nil, true, "luzieffect")
        qianghuaNode1:setPosition(0,0)
        self.treasureRefineItems.bgEffectNode:addChild(qianghuaNode1)
        self.treasureRefineItems.bgEffectNode:setScale(1)
        local animationManager1 = getAnimationManager(qianghuaItems1)
        animationManager1:setAnimationCompletedCallback(function()
            self.treasureRefineItems.bgEffectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager1:runAnimationsForSequenceNamed("luzieffect")
        --
        self.treasureRefineItems.effectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/jinglian/jinglian", nil, true, "jinglian")
        qianghuaNode:setPosition(0,0)
        self.treasureRefineItems.effectNode:addChild(qianghuaNode)
        self.treasureRefineItems.effectNode:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:setAnimationCompletedCallback(function()
            self.treasureRefineItems.effectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("jinglian")
        gamedata.music:PlayOptSound("xlshjhtp")
    end

end

function equipInfo.setPage_refine(self)
    --
    --effect
    if self.hasup and self.hasup == 1 then
        self.hasup = 0
        --
        self.refineItems.bgEffectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode1,qianghuaItems1 = CCBReaderLoad("UIEffect/qianghua/luzi_effect", nil, true, "luzieffect")
        qianghuaNode1:setPosition(0,0)
        self.refineItems.bgEffectNode:addChild(qianghuaNode1)
        self.refineItems.bgEffectNode:setScale(1)
        local animationManager1 = getAnimationManager(qianghuaItems1)
        animationManager1:setAnimationCompletedCallback(function()
            self.refineItems.bgEffectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager1:runAnimationsForSequenceNamed("luzieffect")
        --
        self.refineItems.effectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/jinglian/jinglian", nil, true, "jinglian")
        qianghuaNode:setPosition(0,0)
        self.refineItems.effectNode:addChild(qianghuaNode)
        self.refineItems.effectNode:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:setAnimationCompletedCallback(function()
            self.refineItems.effectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("jinglian")
        gamedata.music:PlayOptSound("xlshjhtp")

        local animationManager3 = getAnimationManager(self.refineItems)
        animationManager3:runAnimationsForSequenceNamed("jinglian")
    end
    --
    self.refineItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("equipInfo")
    end, CCControlEventTouchUpInside)
    self.refineItems.closeButton:setSwallowsTouch(true)
    self.refineItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.refine =
    {
        upnum1 = 0,
        upnum2 = 0,
        upnum3 = 0,
        upnum4 = 0,

        num1 = 0,
        num2 = 0,
        num3 = 0,
        num4 = 0,

        l_num1 = 0,
        l_num2 = 0,
        l_num3 = 0,
        l_num4 = 0,

        maxlv = 10,
        l_exp = 0,
        l_level = 0,
        o_level = 0,
        quality = 2,
        up_exp = 0,
        up_exp1 = 0,
        isTreasure = false,
    }

    --

    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    self.refine.quality = equipConfig.quality or 2
    if equipConfig.type == "horse" or equipConfig.type == "treasure" then
        self.refine.isTreasure = true
        --self.refineItems.title:setString("宝物精炼")
        self.refineItems.title:setString(gameConfig.strings:string_common("equipInfo",15))
    else
        self.refine.isTreasure = false
        --self.refineItems.title:setString("装备精炼")
        self.refineItems.title:setString(gameConfig.strings:string_common("equipInfo",16))
    end

    self.refine.l_exp = self.data.exp
    self.refine.l_level = self.refine.isTreasure and self.data.level1 or self.data.level2
    self.refine.maxlv = self.refine.isTreasure and table.getTableLength(gamedata.config.treasure_strengthen) or table.getTableLength(gamedata.config.equip_refine)

    if self.refine.isTreasure then
        if equipConfig.maxlevel and (self.refine.maxlv > (equipConfig.maxlevel+0)) then
            self.refine.maxlv = equipConfig.maxlevel+0
        end
    else
        if equipConfig.maxlevel2 and (self.refine.maxlv > (equipConfig.maxlevel2+0)) then
            self.refine.maxlv = equipConfig.maxlevel2+0
        end
    end

    self.refineItems["type1"]:setString(self.refine.isTreasure and "宝物属性" or "装备属性") --(gameConfig.strings.attr_type[equipConfig.attr1])
    ui.setLabelString(self.refineItems["type1"],nil,21)

    self.refineItems["type3"]:setString("精炼等级")
    ui.setLabelString(self.refineItems["type3"],nil,21)

    --if equipConfig.attr2 and equipConfig.attr2~="" then
    --    self.refineItems["node_type2"]:setVisible(true)
    --    self.refineItems["type2"]:setString(gameConfig.strings.attr_type[equipConfig.attr2])
    --    ui.setLabelString(self.refineItems["type2"],nil,21)
    --end

    ui.setNewIcon(self.refineItems,{cid = self.data.cid},0)

    --
    if equipConfig.type == "weapon" then

        ui.setNewIconName(self.refineItems,{cid = 20022},0)
        ui.setNewIconName(self.refineItems,{cid = 20023},1)
        ui.setNewIconName(self.refineItems,{cid = 20024},2)
        ui.setNewIconName(self.refineItems,{cid = 20025},3)

        self.refine.upnum1 = gamedata.config.props["20022"].param1 or 0
        self.refine.upnum2 = gamedata.config.props["20023"].param1 or 0
        self.refine.upnum3 = gamedata.config.props["20024"].param1 or 0
        self.refine.upnum4 = gamedata.config.props["20025"].param1 or 0

        UIRequest({type = 12001, order = 11002, cids = {20022,20023,20024,20025}})

    elseif equipConfig.type == "armor" then

        ui.setNewIconName(self.refineItems,{cid = 20026},0)
        ui.setNewIconName(self.refineItems,{cid = 20027},1)
        ui.setNewIconName(self.refineItems,{cid = 20028},2)
        ui.setNewIconName(self.refineItems,{cid = 20029},3)

        self.refine.upnum1 = gamedata.config.props["20026"].param1 or 0
        self.refine.upnum2 = gamedata.config.props["20027"].param1 or 0
        self.refine.upnum3 = gamedata.config.props["20028"].param1 or 0
        self.refine.upnum4 = gamedata.config.props["20029"].param1 or 0

        UIRequest({type = 12001, order = 11002, cids = {20026,20027,20028,20029}})

    elseif equipConfig.type == "head" then

        ui.setNewIconName(self.refineItems,{cid = 20034},0)
        ui.setNewIconName(self.refineItems,{cid = 20035},1)
        ui.setNewIconName(self.refineItems,{cid = 20036},2)
        ui.setNewIconName(self.refineItems,{cid = 20037},3)

        self.refine.upnum1 = gamedata.config.props["20034"].param1 or 0
        self.refine.upnum2 = gamedata.config.props["20035"].param1 or 0
        self.refine.upnum3 = gamedata.config.props["20036"].param1 or 0
        self.refine.upnum4 = gamedata.config.props["20037"].param1 or 0

        UIRequest({type = 12001, order = 11002, cids = {20034,20035,20036,20037}})

    elseif equipConfig.type == "accessory" then

        ui.setNewIconName(self.refineItems,{cid = 20030},0)
        ui.setNewIconName(self.refineItems,{cid = 20031},1)
        ui.setNewIconName(self.refineItems,{cid = 20032},2)
        ui.setNewIconName(self.refineItems,{cid = 20033},3)

        self.refine.upnum1 = gamedata.config.props["20030"].param1 or 0
        self.refine.upnum2 = gamedata.config.props["20031"].param1 or 0
        self.refine.upnum3 = gamedata.config.props["20032"].param1 or 0
        self.refine.upnum4 = gamedata.config.props["20033"].param1 or 0

        UIRequest({type = 12001, order = 11002, cids = {20030,20031,20032,20033}})

    elseif equipConfig.type == "horse" then

        ui.setNewIconName(self.refineItems,{cid = 20042},0)
        ui.setNewIconName(self.refineItems,{cid = 20043},1)
        ui.setNewIconName(self.refineItems,{cid = 20044},2)
        ui.setNewIconName(self.refineItems,{cid = 20045},3)

        self.refine.upnum1 = gamedata.config.props["20042"].param1 or 0
        self.refine.upnum2 = gamedata.config.props["20043"].param1 or 0
        self.refine.upnum3 = gamedata.config.props["20044"].param1 or 0
        self.refine.upnum4 = gamedata.config.props["20045"].param1 or 0

        UIRequest({type = 12001, order = 11002, cids = {20042,20043,20044,20045}})

    elseif equipConfig.type == "treasure" then

        ui.setNewIconName(self.refineItems,{cid = 20038},0)
        ui.setNewIconName(self.refineItems,{cid = 20039},1)
        ui.setNewIconName(self.refineItems,{cid = 20040},2)
        ui.setNewIconName(self.refineItems,{cid = 20041},3)

        self.refine.upnum1 = gamedata.config.props["20038"].param1 or 0
        self.refine.upnum2 = gamedata.config.props["20039"].param1 or 0
        self.refine.upnum3 = gamedata.config.props["20040"].param1 or 0
        self.refine.upnum4 = gamedata.config.props["20041"].param1 or 0

        UIRequest({type = 12001, order = 11002, cids = {20038,20039,20040,20041}})

    end
    --
    --
    local beginFunc = function(index,quick)
        -- print("beginFunc"..index)
        if quick then
            if self.refine["num"..index] == self.refine["l_num"..index] then return end
        else
            if self.refine["l_num"..index] < 1 then return end
        end

        self["effect_begin"..index] = false
        self["effect_end"..index] = false
        --
        self.refineItems["selectEffectNode"..index]:stopAllActions()
        self.refineItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/cailiaoxuanzhong/cailiaoxuanzhong", nil, true, "cailiaoxuanzhong")
        qianghuaNode:setPosition(0,0)
        self.refineItems["selectEffectNode"..index]:addChild(qianghuaNode)
        self.refineItems["selectEffectNode"..index]:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:runAnimationsForSequenceNamed("zhenrongxuanzhong")
        --
        self.refineItems["selectEffectNode"..index]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
            self["effect_begin"..index] = true
            if self["effect_end"..index] then
                self.refineItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
            end
        end)))
    end

    local endFunc = function(index)
        print("endFunc"..index)
        self["effect_end"..index] = true
        if self["effect_begin"..index] then
            self.refineItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        end
    end
    --
    local Func1 = function()
        if self.refine.l_level+1 > self.refine.maxlv then
            --runGamePrompt({msg = "已到最高级"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.refine.l_num1 > 0 then
            self.refine.l_num1 = self.refine.l_num1-1
            self.refine.l_exp = self.refine.l_exp+self.refine.upnum1
            --runGamePrompt({msg = "经验+"..self.refine.upnum1})
            runGamePrompt({msg = gameConfig.strings:expNum(self.refine.upnum1)})
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(1)
        end

        while self.refine.l_exp >= (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality]) do
            self.refine.l_exp = self.refine.l_exp - (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality])
            self.refine.l_level = self.refine.l_level + 1
            if self.refine.l_level+1 > self.refine.maxlv then break end
        end

        self:setData_refine(self.refine)
    end

    local Func2 = function()
        if self.refine.l_level+1 > self.refine.maxlv then
            --runGamePrompt({msg = "已到最高级"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.refine.l_num2 > 0 then
            self.refine.l_num2 = self.refine.l_num2-1
            self.refine.l_exp = self.refine.l_exp+self.refine.upnum2
            --runGamePrompt({msg = "经验+"..self.refine.upnum2})
            runGamePrompt({msg = gameConfig.strings:expNum(self.refine.upnum2)})
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(2)
        end

        while self.refine.l_exp >= (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality]) do
            self.refine.l_exp = self.refine.l_exp - (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality])
            self.refine.l_level = self.refine.l_level + 1
            if self.refine.l_level+1 > self.refine.maxlv then break end
        end

        self:setData_refine(self.refine)
    end

    local Func3 = function()
        if self.refine.l_level+1 > self.refine.maxlv then
            --runGamePrompt({msg = "已到最高级"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.refine.l_num3 > 0 then
            self.refine.l_num3 = self.refine.l_num3-1
            self.refine.l_exp = self.refine.l_exp+self.refine.upnum3
            --runGamePrompt({msg = "经验+"..self.refine.upnum3})
            runGamePrompt({msg = gameConfig.strings:expNum(self.refine.upnum3)})
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(3)
        end

        while self.refine.l_exp >= (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality]) do
            self.refine.l_exp = self.refine.l_exp - (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality])
            self.refine.l_level = self.refine.l_level + 1
            if self.refine.l_level+1 > self.refine.maxlv then break end
        end

        self:setData_refine(self.refine)
    end

    local Func4 = function()
        if self.refine.l_level+1 > self.refine.maxlv then
            --runGamePrompt({msg = "已到最高级"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.refine.l_num4 > 0 then
            self.refine.l_num4 = self.refine.l_num4-1
            self.refine.l_exp = self.refine.l_exp+self.refine.upnum4
            --runGamePrompt({msg = "经验+"..self.refine.upnum4})
            runGamePrompt({msg = gameConfig.strings:expNum(self.refine.upnum4)})
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(4)
        end

        while self.refine.l_exp >= (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality]) do
            self.refine.l_exp = self.refine.l_exp - (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality])
            self.refine.l_level = self.refine.l_level + 1
            if self.refine.l_level+1 > self.refine.maxlv then break end
        end

        self:setData_refine(self.refine)
    end

    local reduce1 = function()

        if self.refine.l_num1 < self.refine.num1 then
            self.refine.l_num1 = self.refine.l_num1+1
            self.refine.l_exp = self.refine.l_exp-self.refine.upnum1
        end

        while self.refine.l_exp < 0 do
            self.refine.up_exp1 = self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level>1 and (self.refine.l_level-1) or 1)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level)]["quality"..self.refine.quality]
            self.refine.l_exp = self.refine.l_exp + self.refine.up_exp1
            self.refine.l_level = self.refine.l_level - 1
            if self.refine.l_level < 1 then break end
        end

        self:setData_refine(self.refine)
    end

    local reduce2 = function()

        if self.refine.l_num2 < self.refine.num2 then
            self.refine.l_num2 = self.refine.l_num2+1
            self.refine.l_exp = self.refine.l_exp-self.refine.upnum2
        end

        while self.refine.l_exp < 0 do
            self.refine.up_exp1 = self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level>1 and (self.refine.l_level-1) or 1)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level)]["quality"..self.refine.quality]
            self.refine.l_exp = self.refine.l_exp + self.refine.up_exp1
            self.refine.l_level = self.refine.l_level - 1
            if self.refine.l_level < 1 then break end
        end

        self:setData_refine(self.refine)
    end
    local reduce3 = function()

        if self.refine.l_num3 < self.refine.num3 then
            self.refine.l_num3 = self.refine.l_num3+1
            self.refine.l_exp = self.refine.l_exp-self.refine.upnum3
        end

        while self.refine.l_exp < 0 do
            self.refine.up_exp1 = self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level>1 and (self.refine.l_level-1) or 1)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level)]["quality"..self.refine.quality]
            self.refine.l_exp = self.refine.l_exp + self.refine.up_exp1
            self.refine.l_level = self.refine.l_level - 1
            if self.refine.l_level < 1 then break end
        end

        self:setData_refine(self.refine)
    end
    local reduce4 = function()

        if self.refine.l_num4 < self.refine.num4 then
            self.refine.l_num4 = self.refine.l_num4+1
            self.refine.l_exp = self.refine.l_exp-self.refine.upnum4
        end

        while self.refine.l_exp < 0 do
            self.refine.up_exp1 = self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level>1 and (self.refine.l_level-1) or 1)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level)]["quality"..self.refine.quality]
            self.refine.l_exp = self.refine.l_exp + self.refine.up_exp1
            self.refine.l_level = self.refine.l_level - 1
            if self.refine.l_level < 1 then break end
        end

        self:setData_refine(self.refine)
    end


        ui.creatDelayButton(self.refineItems["add1"],self.touchPriority,Func1,beginFunc,endFunc,1)
        ui.creatDelayButton(self.refineItems["add2"],self.touchPriority,Func2,beginFunc,endFunc,2)
        ui.creatDelayButton(self.refineItems["add3"],self.touchPriority,Func3,beginFunc,endFunc,3)
        ui.creatDelayButton(self.refineItems["add4"],self.touchPriority,Func4,beginFunc,endFunc,4)

        ui.creatDelayButton(self.refineItems["reduce1"],self.touchPriority,reduce1)
        ui.creatDelayButton(self.refineItems["reduce2"],self.touchPriority,reduce2)
        ui.creatDelayButton(self.refineItems["reduce3"],self.touchPriority,reduce3)
        ui.creatDelayButton(self.refineItems["reduce4"],self.touchPriority,reduce4)

    --
    local quickFunc1 = function(isend)
        if self.refine.l_level+1 > self.refine.maxlv then
            isend = true
            return
        end

        if self.refine.l_num1 > 0 then
            self.refine.l_num1 = self.refine.l_num1-1
            self.refine.l_exp = self.refine.l_exp+self.refine.upnum1
        else
            return
        end

        while self.refine.l_exp >= (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality]) do
            self.refine.l_exp = self.refine.l_exp - (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality])
            self.refine.l_level = self.refine.l_level + 1
            if self.refine.l_level+1 > self.refine.maxlv then break end
        end

    end
    local quickFunc2 = function(isend)
        if self.refine.l_level+1 > self.refine.maxlv then
            isend = true
            return
        end

        if self.refine.l_num2 > 0 then
            self.refine.l_num2 = self.refine.l_num2-1
            self.refine.l_exp = self.refine.l_exp+self.refine.upnum2
        else
            return
        end

        while self.refine.l_exp >= (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality]) do
            self.refine.l_exp = self.refine.l_exp - (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality])
            self.refine.l_level = self.refine.l_level + 1
            if self.refine.l_level+1 > self.refine.maxlv then break end
        end

    end
    local quickFunc3 = function(isend)
        if self.refine.l_level+1 > self.refine.maxlv then
            isend = true
            return
        end

        if self.refine.l_num3 > 0 then
            self.refine.l_num3 = self.refine.l_num3-1
            self.refine.l_exp = self.refine.l_exp+self.refine.upnum3
        else
            return
        end

        while self.refine.l_exp >= (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality]) do
            self.refine.l_exp = self.refine.l_exp - (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality])
            self.refine.l_level = self.refine.l_level + 1
            if self.refine.l_level+1 > self.refine.maxlv then break end
        end

    end
    local quickFunc4 = function(isend)
        if self.refine.l_level+1 > self.refine.maxlv then
            isend = true
            return
        end

        if self.refine.l_num4 > 0 then
            self.refine.l_num4 = self.refine.l_num4-1
            self.refine.l_exp = self.refine.l_exp+self.refine.upnum4
        else
            return
        end

        while self.refine.l_exp >= (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality]) do
            self.refine.l_exp = self.refine.l_exp - (self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..self.refine.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..self.refine.quality])
            self.refine.l_level = self.refine.l_level + 1
            if self.refine.l_level+1 > self.refine.maxlv then break end
        end

    end

    local quickAdd = function()
        local isend = false
        for i=1,self.refine.l_num1 do
            if isend then
                return
            else
                quickFunc1(isend)
            end
        end
        for i=1,self.refine.l_num2 do
            if isend then
                return
            else
                quickFunc2(isend)
            end
        end
        for i=1,self.refine.l_num3 do
            if isend then
                return
            else
                quickFunc3(isend)
            end
        end
        for i=1,self.refine.l_num4 do
            if isend then
                return
            else
                quickFunc4(isend)
            end
        end
        self:setData_refine(self.refine)
        for i = 1,4 do
            beginFunc(i,1)
            endFunc(i)
        end
    end
    --
    ui.setLabelString(self.refineItems.doLab,nil,19)
    self.refineItems.doButton:addHandleOfControlEvent(function()
        local props = {}
        if equipConfig.type == "weapon" then
            table.insert(props,{cid = 20022, num = self.refine.num1 - self.refine.l_num1})
            table.insert(props,{cid = 20023, num = self.refine.num2 - self.refine.l_num2})
            table.insert(props,{cid = 20024, num = self.refine.num3 - self.refine.l_num3})
            table.insert(props,{cid = 20025, num = self.refine.num4 - self.refine.l_num4})
        elseif equipConfig.type == "armor" then
            table.insert(props,{cid = 20026, num = self.refine.num1 - self.refine.l_num1})
            table.insert(props,{cid = 20027, num = self.refine.num2 - self.refine.l_num2})
            table.insert(props,{cid = 20028, num = self.refine.num3 - self.refine.l_num3})
            table.insert(props,{cid = 20029, num = self.refine.num4 - self.refine.l_num4})
        elseif equipConfig.type == "head" then
            table.insert(props,{cid = 20034, num = self.refine.num1 - self.refine.l_num1})
            table.insert(props,{cid = 20035, num = self.refine.num2 - self.refine.l_num2})
            table.insert(props,{cid = 20036, num = self.refine.num3 - self.refine.l_num3})
            table.insert(props,{cid = 20037, num = self.refine.num4 - self.refine.l_num4})
        elseif equipConfig.type == "accessory" then
            table.insert(props,{cid = 20030, num = self.refine.num1 - self.refine.l_num1})
            table.insert(props,{cid = 20031, num = self.refine.num2 - self.refine.l_num2})
            table.insert(props,{cid = 20032, num = self.refine.num3 - self.refine.l_num3})
            table.insert(props,{cid = 20033, num = self.refine.num4 - self.refine.l_num4})
        elseif equipConfig.type == "horse" then
            table.insert(props,{cid = 20042, num = self.refine.num1 - self.refine.l_num1})
            table.insert(props,{cid = 20043, num = self.refine.num2 - self.refine.l_num2})
            table.insert(props,{cid = 20044, num = self.refine.num3 - self.refine.l_num3})
            table.insert(props,{cid = 20045, num = self.refine.num4 - self.refine.l_num4})
        elseif equipConfig.type == "treasure" then
            table.insert(props,{cid = 20038, num = self.refine.num1 - self.refine.l_num1})
            table.insert(props,{cid = 20039, num = self.refine.num2 - self.refine.l_num2})
            table.insert(props,{cid = 20040, num = self.refine.num3 - self.refine.l_num3})
            table.insert(props,{cid = 20041, num = self.refine.num4 - self.refine.l_num4})
        end

        --if self.refine.l_level+1 > self.refine.maxlv then
            --runGamePrompt({msg = "已到最高级"})
        --    runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
        if (self.refine.num1+self.refine.num2+self.refine.num3+self.refine.num4-self.refine.l_num1-self.refine.l_num2-self.refine.l_num3-self.refine.l_num4)<1 then
            --runGamePrompt({msg = "请选择消耗材料"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",19)})
        elseif self.refine.isTreasure then
            UIRequest({type = 1105, iid = self.data.iid, props = props})
        else
            UIRequest({type = 1102, iid = self.data.iid, props = props})
        end
    end, CCControlEventTouchUpInside)
    self.refineItems.doButton:setSwallowsTouch(true)
    self.refineItems.doButton:setTouchPriority(self.touchPriority)
    --
    if self.refineItems.doButton1 then
        ui.setLabelString(self.refineItems.doLab1,"一键添加",19)
        self.refineItems.doButton1:addHandleOfControlEvent(function()
            if self.refine.l_level+1 > self.refine.maxlv then
                --runGamePrompt({msg = "已到最高级"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            elseif (self.refine.num1+self.refine.num2+self.refine.num3+self.refine.num4)<1 then
                --runGamePrompt({msg = "材料已消耗完"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            --elseif self.refine.isTreasure then
            --    UIRequest({type = 1116, iid = self.data.iid})
            else
                --UIRequest({type = 1115, iid = self.data.iid})
                quickAdd()
            end
        end, CCControlEventTouchUpInside)
        self.refineItems.doButton1:setSwallowsTouch(true)
        self.refineItems.doButton1:setTouchPriority(self.touchPriority)
    end
    --
    self:setData_refine(self.refine)
end

function equipInfo.setData_refine(self,refine)
    local level1 =  self.refine.isTreasure and self.refine.l_level or self.data.level1
    local level2 =  self.refine.isTreasure and self.data.level2 or self.refine.l_level

    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    self.refineItems["name"]:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or ""))
    self.refineItems["lv1"]:setString("等级:"..self.data.level1)

    if equipConfig.quality >= 7 then
        ui.setLabelString(self.refineItems["name"],nil,213)
    else
        ui.setLabelString(self.refineItems["name"],nil,(equipConfig.quality or 1)*2-1)
    end
    
    ui.setLabelString(self.refineItems.lv1,nil,13)
    self.refineItems["lv1_up"]:setString("")
    self.refineItems["lv2_up"]:setString("")
    if self.refine.isTreasure then
        if self.refine.l_level+0 > self.data.level1+0 then
            self.refineItems["lv1_up"]:setString("+"..(self.refine.l_level-self.data.level1))
        end
    else
        if self.refine.l_level+0 > self.data.level2+0 then
            self.refineItems["lv2_up"]:setString("+"..(self.refine.l_level-self.data.level2))
        end
    end

    if self.refine.isTreasure then
        local type1,num1,type2,num2 = ui.setEquipPromote(nil,nil,self.data)
        local type1_,num1_,type2_,num2_ = ui.setEquipPromote(nil,nil,{cid=self.data.cid, level1=level1+1 > self.refine.maxlv and level1 or level1 , level2=level2})

        ui.setLabelString(self.refineItems["num1"],num1,13)
        ui.setLabelString(self.refineItems["next_num1"],num1_,23)

        if equipConfig.attr2 and equipConfig.attr2~="" then
            ui.setLabelString(self.refineItems["num2"],num2,13)
            ui.setLabelString(self.refineItems["next_num2"],num2_,23)
        end

        ui.setLabelString(self.refineItems["num3"],self.data.level1.."/"..self.refine.maxlv,13)
        ui.setLabelString(self.refineItems["next_num3"],(level1+1 > self.refine.maxlv and level1 or level1).."/"..self.refine.maxlv,23)

    else
--        local type1,num1,type2,num2 = ui.setEquipPromote(nil,nil,self.data)
--        local type1_,num1_,type2_,num2_ = ui.setEquipPromote(nil,nil,{cid=self.data.cid, level1=level1, level2=level2+1 > self.refine.maxlv and level2 or level2+1})
--
--        ui.setLabelString(self.refineItems["num1"],num1,13)
--        ui.setLabelString(self.refineItems["next_num1"],num1_,23)
--
--        if equipConfig.attr2 and equipConfig.attr2~="" then
--            ui.setLabelString(self.refineItems["num2"],num2,13)
--            ui.setLabelString(self.refineItems["next_num2"],num2_,23)
--        end
        ui.setLabelString(self.refineItems["num3"],"+"..self.data.level2.."/".."+"..self.refine.maxlv,13)

        if self.data.level2+0 > 0 then
            self.refineItems["num1"]:setString("x"..(gamedata.config.equip_refine[tostring(self.data.level2)]["radio"]*100).."%")
            self.refineItems["num2"]:setString("x"..(gamedata.config.equip_refine[tostring(self.data.level2)]["radio"]*100).."%")
        else
            self.refineItems["num1"]:setString("x100%")
            self.refineItems["num2"]:setString("x100%")
        end

        if level2+1 > self.refine.maxlv then
            ui.setLabelString(self.refineItems["next_num3"],"+"..level2.."/".."+"..self.refine.maxlv,23)
            self.refineItems["next_num1"]:setString("x"..(gamedata.config.equip_refine[tostring(level2)]["radio"]*100).."%")
            self.refineItems["next_num2"]:setString("x"..(gamedata.config.equip_refine[tostring(level2)]["radio"]*100).."%")
        else
            ui.setLabelString(self.refineItems["next_num3"],"+"..(level2).."/".."+"..self.refine.maxlv,23)
            if level2>0 then
                self.refineItems["next_num1"]:setString("x"..(gamedata.config.equip_refine[tostring(level2>0 and level2 or 1)]["radio"]*100).."%")
                self.refineItems["next_num2"]:setString("x"..(gamedata.config.equip_refine[tostring(level2>0 and level2 or 1)]["radio"]*100).."%")
            else
                self.refineItems["next_num1"]:setString("x100%")
                self.refineItems["next_num2"]:setString("x100%")
            end
        end
    end
    ui.setLabelString(self.refineItems.num1,nil,13)
    ui.setLabelString(self.refineItems.next_num1,nil,23)

    self.refineItems["in_num"]:setString( "x"..self.refine.l_num1  )
    self.refineItems["in_num_1"]:setString( "x"..self.refine.l_num2  )
    self.refineItems["in_num_2"]:setString( "x"..self.refine.l_num3  )
    self.refineItems["in_num_3"]:setString( "x"..self.refine.l_num4  )
    ui.setLabelString(self.refineItems["in_num"],nil,13)
    ui.setLabelString(self.refineItems["in_num_1"],nil,13)
    ui.setLabelString(self.refineItems["in_num_2"],nil,13)
    ui.setLabelString(self.refineItems["in_num_3"],nil,13)

    local nextexp = 0
    if self.refine.l_level+0 < self.refine.maxlv then
        nextexp = self.refine.isTreasure and gamedata.config.treasure_strengthen[tostring(self.refine.l_level)]["quality"..equipConfig.quality] or gamedata.config.equip_refine[tostring(self.refine.l_level+1)]["quality"..equipConfig.quality]
    end
    self.refineItems["expLab"]:setString((self.refine.l_exp>=nextexp) and "Max" or (self.refine.l_exp.." / "..nextexp))
    ui.setSpriteTextureRect2(self.refineItems["expSprite"],0,0,793 * ((self.refine.l_exp>=nextexp) and 1 or (self.refine.l_exp / nextexp)),self.refineItems["expSprite"]:getContentSize().height)
    ui.setLabelString(self.refineItems.expLab,nil,13)

    if self.refine.num1-self.refine.l_num1 > 0 then
        self.refineItems.reduceNode1:setVisible(true)
    else
        self.refineItems.reduceNode1:setVisible(false)
    end
    if self.refine.num2-self.refine.l_num2 > 0 then
        self.refineItems.reduceNode2:setVisible(true)
    else
        self.refineItems.reduceNode2:setVisible(false)
    end
    if self.refine.num3-self.refine.l_num3 > 0 then
        self.refineItems.reduceNode3:setVisible(true)
    else
        self.refineItems.reduceNode3:setVisible(false)
    end
    if self.refine.num4-self.refine.l_num4 > 0 then
        self.refineItems.reduceNode4:setVisible(true)
    else
        self.refineItems.reduceNode4:setVisible(false)
    end

end


function equipInfo.setRefineNum(self,data)
    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    if equipConfig.type == "weapon" then
        self.refine.num1 = data["20022"] or 0
        self.refine.num2 = data["20023"] or 0
        self.refine.num3 = data["20024"] or 0
        self.refine.num4 = data["20025"] or 0
    elseif equipConfig.type == "armor" then
        self.refine.num1 = data["20026"] or 0
        self.refine.num2 = data["20027"] or 0
        self.refine.num3 = data["20028"] or 0
        self.refine.num4 = data["20029"] or 0
    elseif equipConfig.type == "head" then
        self.refine.num1 = data["20034"] or 0
        self.refine.num2 = data["20035"] or 0
        self.refine.num3 = data["20036"] or 0
        self.refine.num4 = data["20037"] or 0
    elseif equipConfig.type == "accessory" then
        self.refine.num1 = data["20030"] or 0
        self.refine.num2 = data["20031"] or 0
        self.refine.num3 = data["20032"] or 0
        self.refine.num4 = data["20033"] or 0
    elseif equipConfig.type == "horse" then
        self.refine.num1 = data["20042"] or 0
        self.refine.num2 = data["20043"] or 0
        self.refine.num3 = data["20044"] or 0
        self.refine.num4 = data["20045"] or 0
    elseif equipConfig.type == "treasure" then
        self.refine.num1 = data["20038"] or 0
        self.refine.num2 = data["20039"] or 0
        self.refine.num3 = data["20040"] or 0
        self.refine.num4 = data["20041"] or 0
    end
    self.refine.l_num1 = self.refine.num1
    self.refine.l_num2 = self.refine.num2
    self.refine.l_num3 = self.refine.num3
    self.refine.l_num4 = self.refine.num4

    self:setData_refine(self.refine)
end


function equipInfo.setPage_xilian(self)

    self.hasXLPreview = false

    self.xilianItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("equipInfo")
    end, CCControlEventTouchUpInside)
    self.xilianItems.closeButton:setSwallowsTouch(true)
    self.xilianItems.closeButton:setTouchPriority(self.touchPriority)

    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]

    self.xilianItems.title:setString("装备洗炼")
    ui.setLabelString(self.xilianItems["xilianlab1"],nil,21)
    ui.setLabelString(self.xilianItems["xilianlab2"],nil,18)
    ui.setLabelString(self.xilianItems["xl_Lab1"],nil,19)
    ui.setLabelString(self.xilianItems["xl_Lab2"],nil,19)
    ui.setLabelString(self.xilianItems["xl_Lab3"],nil,19)
    ui.setLabelString(self.xilianItems["xl_Lab_no"],nil,19)
    ui.setLabelString(self.xilianItems["xl_Lab_yes"],nil,19)

    self.xilianItems.e_desc:setString(equipConfig.desc)
    self.xilianItems.e_equiptype:setString(gameConfig.strings.equipType[equipConfig.type])
    if equipConfig.type ~= "horse" and equipConfig.type ~= "treasure" then
        self.xilianItems.e_name:setString(ui.getEquipStageName(self.data) or "")
    else
        self.xilianItems.e_name:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or "" ))
    end
    -- self.xilianItems.e_name:setString(equipConfig.name..(self.data.level2+0 > 0 and " +"..self.data.level2 or "" ))
    if equipConfig.quality >= 7 then
        ui.setLabelString(self.xilianItems.e_name,nil,213)
    else
        ui.setLabelString(self.xilianItems.e_name,nil,(equipConfig.quality or 1)*2-1)
    end
    
    --
    ui.setIconLv(self.xilianItems,self.data)
    if equipConfig.suit and equipConfig.suit > 0 then
        self.xilianItems.e_equiptypenode1:setVisible(false)
        self.xilianItems.e_equiptypenode2:setVisible(true)
        self.isSuit = true
    else
        self.xilianItems.e_equiptypenode1:setVisible(true)
        self.xilianItems.e_equiptypenode2:setVisible(false)
        self.isSuit = false
    end
    --
    local type1,num1,type2,num2 = ui.setEquipPromote(self.xilianItems["e_type1"],self.xilianItems["e_type2"],self.data,self.xilianItems["e_type3"])
    --
    local maxlv = 0
    maxlv = GameScene.roleinfo.level*tonumber(gamedata.config.global_kv.equip_level.value)
    if equipConfig.maxlevel and (maxlv > (equipConfig.maxlevel+0)) then
        maxlv = equipConfig.maxlevel+0
    end
    self.xilianItems.e_level:setString("强化等级:  "..self.data.level1.."/"..maxlv)
    --
    local baseY = 80
    for i = 1,4 do
        self["xl_max"..i] = false
        self.xilianItems["xl_up_max"..i]:setVisible(false)
        self.xilianItems["xl_up_node"..i]:setVisible(false)
        self.xilianItems["xl_down_node"..i]:setVisible(false)
        if equipConfig["baptize_attr"..i] and equipConfig["baptize_attr"..i] ~= "" then
            self.xilianItems["xl_type"..i]:setString(gameConfig.strings.attr_type[equipConfig["baptize_attr"..i]]..":")
            self.xilianItems["xl_num"..i]:setString(self.data["x"..equipConfig["baptize_attr"..i]] or 0)
            self.xilianItems["xl_max"..i]:setString("( 最大"..(equipConfig["attrlimitup_"..i]*(self.data.level1-1)+equipConfig["attrlimit"..i]).." )")
            ui.setLabelString(self.xilianItems["xl_num"..i],nil,22)
            ui.setLabelString(self.xilianItems["xl_max"..i],nil,13)

            if self.data["x"..equipConfig["baptize_attr"..i]] >= (equipConfig["attrlimitup_"..i]*(self.data.level1-1)+equipConfig["attrlimit"..i]) then
                self["xl_max"..i] = true
            end
            --
            self.xilianItems["xl_type_node"..i]:setVisible(true)
            self.xilianItems["xl_type_node"..i]:setPositionY(baseY)
            baseY = baseY-60
        else
            self["xl_max"..i] = true
            self.xilianItems["xl_type_node"..i]:setVisible(false)
        end
    end

    for i = 1,3 do
        self.xilianItems["xl_select"..i]:setVisible(i == self.xlselect)
        self.xilianItems["xl_select_button"..i]:addHandleOfControlEvent(function()
            self.xlselect = i
            for ii = 1,3 do
                self.xilianItems["xl_select"..ii]:setVisible(ii == self.xlselect)
            end
        end, CCControlEventTouchUpInside)
        self.xilianItems["xl_select_button"..i]:setSwallowsTouch(true)
        self.xilianItems["xl_select_button"..i]:setTouchPriority(self.touchPriority)
        --
        local xprop = ui.getIDandNUMs(tostring(gamedata.config.global_kv["baptize_consume_"..i].value))
        for k,v in pairs(xprop) do
            if v.cid == 1000 then
                self.xl_coin = v.num or 0
                self.xilianItems["xl_coin"]:setString(v.num)
                ui.setLabelString(self.xilianItems["xl_coin"],nil,13)
            elseif v.cid == 1001 then
                self.xl_gold = v.num or 0
                self.xilianItems["xl_gold"]:setString(v.num)
                ui.setLabelString(self.xilianItems["xl_gold"],nil,13)
            elseif v.cid == 20222 then
                self["xl_stone"..i] = v.num or 0
                self.xilianItems["xl_stone"..i]:setString(v.num)
                ui.setLabelString(self.xilianItems["xl_stone"..i],nil,13)
            end
        end
    end

    self.xilianItems["xl_stone_has"]:setString(self.xiliansStoneNum or 0)
    ui.setLabelString(self.xilianItems["xl_stone_has"],nil,18)

    UIRequest({type = 12001, order = 11004, cids = {20222}})

    self.xilianItems.xl_Button1:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.xl_max1 and self.xl_max2 and self.xl_max3 and self.xl_max4 then
            runGamePrompt({msg = "属性已达当前上限，强化装备可提高上限"})
            return
        end
        self.xlselectbtn = 1
        UIRequest({type = 1120, iid = self.data.iid, method = self.xlselect, xlnum = 1,})
    end, CCControlEventTouchUpInside)
    self.xilianItems.xl_Button1:setSwallowsTouch(true)
    self.xilianItems.xl_Button1:setTouchPriority(self.touchPriority)

    self.xilianItems.xl_Button2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.xl_max1 and self.xl_max2 and self.xl_max3 and self.xl_max4 then
            runGamePrompt({msg = "属性已达当前上限，强化装备可提高上限"})
            return
        end
        self.xlselectbtn = 2
        UIRequest({type = 1120, iid = self.data.iid, method = self.xlselect, xlnum = 5,})
    end, CCControlEventTouchUpInside)
    self.xilianItems.xl_Button2:setSwallowsTouch(true)
    self.xilianItems.xl_Button2:setTouchPriority(self.touchPriority)

    self.xilianItems.xl_Button3:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.xl_max1 and self.xl_max2 and self.xl_max3 and self.xl_max4 then
            runGamePrompt({msg = "属性已达当前上限，强化装备可提高上限"})
            return
        end
        self.xlselectbtn = 3
        UIRequest({type = 1120, iid = self.data.iid, method = self.xlselect, xlnum = 10,})
    end, CCControlEventTouchUpInside)
    self.xilianItems.xl_Button3:setSwallowsTouch(true)
    self.xilianItems.xl_Button3:setTouchPriority(self.touchPriority)
    --

    self.xilianItems.xl_Button_no:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.hasXLPreview then
            self.hasXLPreview = false
            UIRequest({type = 1121, id = self.data.iid, method = 0,})
        end
    end, CCControlEventTouchUpInside)
    self.xilianItems.xl_Button_no:setSwallowsTouch(true)
    self.xilianItems.xl_Button_no:setTouchPriority(self.touchPriority)

    self.xilianItems.xl_Button_yes:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.hasXLPreview then
            self.hasXLPreview = false
            UIRequest({type = 1121, id = self.data.iid, method = 1,})
        end
    end, CCControlEventTouchUpInside)
    self.xilianItems.xl_Button_yes:setSwallowsTouch(true)
    self.xilianItems.xl_Button_yes:setTouchPriority(self.touchPriority)
    --
    self.xilianItems.xl_Node_no:setVisible(false)
    self.xilianItems.xl_Node_yes:setVisible(false)

    self.xilianItems.xl_Node1:setVisible(true)
    self.xilianItems.xl_Node2:setVisible(true)
    self.xilianItems.xl_Node3:setVisible(true)
    self.xilianItems.xl_Node1:setPositionX(244)
    self.xilianItems.xl_Node2:setPositionX(544)
    self.xilianItems.xl_Node3:setPositionX(844)
    --

    self.xilianItems.xl_Button_yes:setEnabled(true)
    ui.removeGray("CCControlButton",self.xilianItems.xl_Button_yes)
    ui.removeGray("CCLabelTTF",self.xilianItems.xl_Lab_yes)
    self.xilianItems.xl_Button_no:setEnabled(true)
    ui.removeGray("CCControlButton",self.xilianItems.xl_Button_no)
    ui.removeGray("CCLabelTTF",self.xilianItems.xl_Lab_no)
    for i = 1,3 do
        self.xilianItems["xl_Button"..i]:setEnabled(true)
        ui.removeGray("CCControlButton",self.xilianItems["xl_Button"..i])
        ui.removeGray("CCLabelTTF",self.xilianItems["xl_Lab"..i])
    end

    --
    self.xilianItems.xl_addStone:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("dropTips",{cid = 20222,num = self.xiliansStoneNum or 0},nil)
    end, CCControlEventTouchUpInside)
    self.xilianItems.xl_addStone:setSwallowsTouch(true)
    self.xilianItems.xl_addStone:setTouchPriority(self.touchPriority)
end

function equipInfo.setXilianPreview(self,data)
    if not data then return end
    self.hasXLPreview = true
    local hasup = false
    local hasdown = false
    local equipConfig = gamedata.config.equip[tostring(self.data.cid)]
    for i = 1,4 do
        self.xilianItems["xl_up_max"..i]:setVisible(false)
        self.xilianItems["xl_up_node"..i]:setVisible(false)
        self.xilianItems["xl_down_node"..i]:setVisible(false)
        if equipConfig["baptize_attr"..i] and equipConfig["baptize_attr"..i] ~= "" then

            if self.data["x"..equipConfig["baptize_attr"..i]] < data["x"..equipConfig["baptize_attr"..i]] then
                hasup = true
                self.xilianItems["xl_up_node"..i]:setVisible(true)
                self.xilianItems["xl_up_num"..i]:setString("+"..(data["x"..equipConfig["baptize_attr"..i]]-self.data["x"..equipConfig["baptize_attr"..i]]))
                ui.setLabelString(self.xilianItems["xl_up_num"..i],nil,22)
            elseif self.data["x"..equipConfig["baptize_attr"..i]] > data["x"..equipConfig["baptize_attr"..i]] then
                hasdown = true
                self.xilianItems["xl_down_node"..i]:setVisible(true)
                self.xilianItems["xl_down_num"..i]:setString("-"..(self.data["x"..equipConfig["baptize_attr"..i]]-data["x"..equipConfig["baptize_attr"..i]]))
                ui.setLabelString(self.xilianItems["xl_down_num"..i],nil,24)
            elseif self["xl_max"..i] then
                self.xilianItems["xl_up_max"..i]:setVisible(true)
                ui.setLabelString(self.xilianItems["xl_up_max"..i],nil,22)
            end
            --
            self.xilianItems["xl_type_node"..i]:setVisible(true)
        else
            self.xilianItems["xl_type_node"..i]:setVisible(false)
        end
    end

    self.xilianItems.xl_Node_no:setVisible(true)
    self.xilianItems.xl_Node_yes:setVisible(true)
    self.xilianItems.xl_Node1:setVisible(self.xlselectbtn == 1)
    self.xilianItems.xl_Node2:setVisible(self.xlselectbtn == 2)
    self.xilianItems.xl_Node3:setVisible(self.xlselectbtn == 3)
    self.xilianItems["xl_Node"..self.xlselectbtn]:setPositionX(544)

    UIRequest({type = 12001, order = 11004, cids = {20222}})

    --
    if not hasup then
        self.xilianItems.xl_Button_yes:setEnabled(false)
        ui.addGray("CCControlButton",self.xilianItems.xl_Button_yes)
        ui.addGray("CCLabelTTF",self.xilianItems.xl_Lab_yes)
    else
        self.xilianItems.xl_Button_yes:setEnabled(true)
        ui.removeGray("CCControlButton",self.xilianItems.xl_Button_yes)
        ui.removeGray("CCLabelTTF",self.xilianItems.xl_Lab_yes)
    end

    if not hasdown then
        self.xilianItems.xl_Button_no:setEnabled(false)
        self.xilianItems["xl_Button"..self.xlselectbtn]:setEnabled(false)
        ui.addGray("CCControlButton",self.xilianItems.xl_Button_no)
        ui.addGray("CCLabelTTF",self.xilianItems.xl_Lab_no)
        ui.addGray("CCControlButton",self.xilianItems["xl_Button"..self.xlselectbtn])
        ui.addGray("CCLabelTTF",self.xilianItems["xl_Lab"..self.xlselectbtn])
    else
        self.xilianItems.xl_Button_no:setEnabled(true)
        self.xilianItems["xl_Button"..self.xlselectbtn]:setEnabled(true)
        ui.removeGray("CCControlButton",self.xilianItems.xl_Button_no)
        ui.removeGray("CCLabelTTF",self.xilianItems.xl_Lab_no)
        ui.removeGray("CCControlButton",self.xilianItems["xl_Button"..self.xlselectbtn])
        ui.removeGray("CCLabelTTF",self.xilianItems["xl_Lab"..self.xlselectbtn])
    end

    --

end



function equipInfo.setXilianNum(self,data)
    self.xiliansStoneNum = data["20222"] or 0
    self.xilianItems["xl_stone_has"]:setString(self.xiliansStoneNum or 0)
    ui.setLabelString(self.xilianItems["xl_stone_has"],nil,18)
end

return equipInfo

 �  