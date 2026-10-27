--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/24
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--

local artifactList = {

    resource = nil,
    rootNode = nil,
    rootItems = nil,

    touchPriority = -101,
    cellNorSize = {x=1080,y=242},
    cellDelSSize = {x = 1080,y = 976},
    cellDelSize = {x = 1080,y = 976},

    jewelCellSize = {x=1080,y=242},

    unrecycleCell = {},
    labelHeight = 40,
    labelDemention = 0,
    labelP = -40,

    artifactData = nil,
    jewelData = nil,
    jewelShowData = nil,

    pageconfig = {"artifact","jewel"},
    pagename = {gameConfig.strings:string_common("artifact",27),gameConfig.strings:string_common("artifact",28)},

    -- artifactTypeConfig = {"all","checked","unChecked"},
    artifactTypeConfig = {"all","atkArtifact","defArtifact","hpArtifact","unChecked"},
    jewelConfig = {"whole","attack","defence","life","skill"},
    jewelGoId = {120001,120001,120101,120201,120301},
    layerName = "artifactList",
    
    selectpage = "artifact",
    selectArtifactPage = "all",
    selectJewelPage = "whole",
    artifactSelect = nil,
    isSelectState = false,
    curSelectPage = "commonlyArtifact",--strengthenArtifact
    hintconfig = {
        {
            name = "rootItems",
            type = "self",
            config = {
                title1 = {368},
                title2 = {369},
            },
        },
    },
}


function artifactList.shiftPage(self,type,noResetOffset)
    self.selectpage = type or self.selectpage

    self.rootItems.listArtifact:setVisible(self.selectpage == self.pageconfig[1])
    self.rootItems.listJewel:setVisible(self.selectpage == self.pageconfig[2])
    self.rootItems.jewelTop:setVisible(self.selectpage == self.pageconfig[2])
    self.rootItems.artifactTop:setVisible(self.selectpage == self.pageconfig[1])
    print("lipurposes self.selectpage ",self.selectpage)
    if self.selectpage == self.pageconfig[1] then
        self.rootItems.jewelGo:setVisible(false)
        if not self.artifactData then
            GameScene:addUpdate(10032)
        end

        if not self.lockChange then
            if GameScene:checkUpdate(10032) then
                return
            end
        else
            self.lockChange = false
        end
        
        self.rootItems.listArtifact:setPositionX(0)
        self.rootItems.listJewel:setPositionX(9999)
        self:setArtifactBtnState()

        self.rootItems.artifactGo:setVisible(false)
        if #self.artifactData[self.artifactTypeConfig[1]] <= 0 then
            self.rootItems.artifactGo:setVisible(true)
        end
        
        if not self.ListTableView then
            self:createArtifactList()
        else
            local addLength = self.cellNorSize.y
            if self.artifactSelect then
                local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][self.artifactSelect]
                if artifact.skill1 > 0 or artifact.skill2 > 0 or artifact.skill3 > 0 then
                    addLength = self.cellDelSSize.y
                end
                addLength = self.cellDelSize.y
            end

            if not noResetOffset then
                self.ListTableView:setLuaContentOffset(0, self.rootItems.listArtifact:getContentSize().height - (#self.artifactData[self.curSelectPage][self.selectArtifactPage] - 1) *self.cellNorSize.y - addLength)
            end
            
            self.ListTableView:reloadData()
        end
    else
        self.rootItems.artifactGo:setVisible(false)
        if not self.jewelData then
            GameScene:addUpdate(10031)
        end
        if not self.artifactData then
            GameScene:addUpdate(10032)
        end
        if  GameScene:checkUpdate(10032) or GameScene:checkUpdate(10031) then
            return
        end
       
        self.rootItems.listArtifact:setPositionX(9999)
        self.rootItems.listJewel:setPositionX(0)
        self:setJewelBtnState()
        
        self.rootItems.jewelGo:setVisible(false)
        if #self.jewelShowData[self.selectJewelPage] == 0 then
            self.rootItems.jewelGo:setVisible(true)
        end
        
        if not self.jewelList then
            self:createJewelList()
        else
            local setSize = 0
            setSize = #self.jewelShowData[self.selectJewelPage]
            self.jewelList:setLuaContentOffset(0, self.rootItems.listJewel:getContentSize().height - setSize *self.jewelCellSize.y)
            self.jewelList:reloadData()
        end
    end
end


function artifactList.setArtifactBtnState(self)
    for k,v in pairs(self.artifactTypeConfig) do
        self.rootItems[v.."Onbg"]:setVisible(v == self.selectArtifactPage)
        self.rootItems[v.."Onpoint"]:setVisible(v == self.selectArtifactPage)
    end
    print("  elf.selectArtifactPage==   ",self.selectArtifactPage,curSelectPage," ==== = = = =")
    printT(self.artifactData)
    if self.selectArtifactPage == self.artifactTypeConfig[1] then
        self.rootItems.artifactNums:setString(gameConfig.strings:string_common("artifact",42)..":"..(#self.artifactData[self.curSelectPage][self.selectArtifactPage]))
    elseif self.selectArtifactPage == self.artifactTypeConfig[2] then
        self.rootItems.artifactNums:setString("攻击神器:"..(#self.artifactData[self.curSelectPage][self.selectArtifactPage]))
    elseif self.selectArtifactPage == self.artifactTypeConfig[3] then
        self.rootItems.artifactNums:setString("防御神器:"..(#self.artifactData[self.curSelectPage][self.selectArtifactPage]))
    elseif self.selectArtifactPage == self.artifactTypeConfig[4] then
        self.rootItems.artifactNums:setString("辅助神器:"..(#self.artifactData[self.curSelectPage][self.selectArtifactPage]))
    else
        self.rootItems.artifactNums:setString(gameConfig.strings:string_common("artifact",43)..":"..(#self.artifactData[self.curSelectPage][self.selectArtifactPage]))
    end
end

function artifactList.setJewelBtnState(self)
    for k,v in pairs(self.jewelConfig) do
        self.rootItems[v.."Onbg"]:setVisible(v == self.selectJewelPage)
        self.rootItems[v.."Onpoint"]:setVisible(v == self.selectJewelPage)
    end
    local setStr
    if self.selectJewelPage == self.jewelConfig[1] then
        setStr = gameConfig.strings:string_common("artifact",45)
    elseif self.selectJewelPage == self.jewelConfig[2] then
        setStr = gameConfig.strings:string_common("artifact",46)
    elseif self.selectJewelPage == self.jewelConfig[3] then
        setStr = gameConfig.strings:string_common("artifact",47)
    elseif self.selectJewelPage == self.jewelConfig[4] then
        setStr = gameConfig.strings:string_common("artifact",48)
    else
        setStr = gameConfig.strings:string_common("artifact",49)
    end

    self.rootItems.jewelNums:setString(setStr..":"..(self.jewelShowData.Nums[self.selectJewelPage] or 0))
end



function artifactList.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("shenqi_new/shenqi_list", nil, true, "shenqi_list")
    self:initFixedString()
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.selectpage = param or "artifact"
    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.listArtifact:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-60))
    self.rootItems.listJewel:setContentSize(CCSizeMake(gameConfig.originSize.width,toppos-gameConfig.maiscenebottomheight-gameConfig.labelnodeheight-60))
    self.curSelectPage = "commonlyArtifact"
    -- 默认隐藏状态
    self.rootItems.autosprite:setVisible(self.isSelectState)
    self.rootItems.autobutton:addHandleOfControlEvent(function()
        -- GameScene:shiftLayer("artifact","up")
        self.isSelectState = not self.isSelectState
        self.rootItems.autosprite:setVisible(self.isSelectState)
        if self.isSelectState == true then
            self.curSelectPage = "strengthenArtifact"
        else
            self.curSelectPage = "commonlyArtifact"
        end

        if not self.ListTableView then
            self:createArtifactList()
        else
            local addLength = self.cellNorSize.y
            if self.artifactSelect then
                local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][self.artifactSelect]
                if artifact.skill1 > 0 or artifact.skill2 > 0 or artifact.skill3 > 0 then
                    addLength = self.cellDelSSize.y
                end
                addLength = self.cellDelSize.y
            end
            self.ListTableView:setLuaContentOffset(0, self.rootItems.listArtifact:getContentSize().height - (#self.artifactData[self.curSelectPage][self.selectArtifactPage] - 1) *self.cellNorSize.y - addLength)
            self.ListTableView:reloadData()
        end

        self:setArtifactBtnState()
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton:setSwallowsTouch(true)
    self.rootItems.autobutton:setTouchPriority(self.touchPriority)

    self.rootItems.jewelGo:setVisible(false)
    self.rootItems.artifactGo:setVisible(false)
    self:setButtonFunc()
    self:shiftPage()
end

function artifactList.setButtonFunc(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifact","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    
    for k,v in pairs(self.artifactTypeConfig) do
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            if self.selectArtifactPage == v then
                return
            else
                self.artifactSelect = nil
                self.selectArtifactPage = v
                self:shiftPage()
           end
        end, CCControlEventTouchUpInside)
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(self.touchPriority)
    end

    for k,v in pairs(self.jewelConfig) do
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            if self.selectJewelPage == v then
                return
            else
                self.selectJewelPage = v
                self:shiftPage()
           end
        end, CCControlEventTouchUpInside)
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(self.touchPriority)
    end

    self.rootItems.goToCast:addHandleOfControlEvent(function()
        local cid
        for i = 1,5 do
            if self.jewelConfig[i] == self.selectJewelPage then
                cid = self.jewelGoId[i]
                break
            end
        end
        gameWindows:openWindow("dropTips",{cid = cid},nil)
    end, CCControlEventTouchUpInside)
    self.rootItems.goToCast:setSwallowsTouch(true)
    self.rootItems.goToCast:setTouchPriority(self.touchPriority - 1)

    self.rootItems.goToCast1:addHandleOfControlEvent(function()
        GameScene:shiftLayer("artifactCreate","up")
    end, CCControlEventTouchUpInside)
    self.rootItems.goToCast1:setSwallowsTouch(true)
    self.rootItems.goToCast1:setTouchPriority(self.touchPriority - 1)
end

function artifactList.initFixedString(self)
    self.rootItems.allStr:setString(gameConfig.strings:string_common("artifact",29))
    -- self.rootItems.checkedStr:setString(gameConfig.strings:string_common("artifact",30))
    self.rootItems.unCheckedStr:setString(gameConfig.strings:string_common("artifact",31))

    self.rootItems.allJStr:setString(gameConfig.strings:string_common("artifact",29))
    
    self.rootItems.type1Str:setString(gameConfig.strings:string_common("attr_type","atk"))
    self.rootItems.type2Str:setString(gameConfig.strings:string_common("attr_type","def"))
    self.rootItems.type3Str:setString(gameConfig.strings:string_common("attr_type","hp"))
    self.rootItems.type4Str:setString(gameConfig.strings:string_common("fixedString","general",1))
end

function artifactList.createArtifactList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then
                local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1]
                if artifact.skill1 > 0 or artifact.skill2 > 0 or artifact.skill3 > 0 then
                    r = CCSizeMake(self.cellNorSize.x, self.cellDelSSize.y)
                else
                    r = CCSizeMake(self.cellNorSize.x, self.cellDelSize.y)
                end
            else
                r = CCSizeMake(self.cellNorSize.x, self.cellNorSize.y)
            end
        elseif fn == "isRecycle" then
            for k,v in pairs (self.unrecycleCell) do
                if a2 == v.cell then
                    print("unrecycleCELL ")
                    return false
                end
            end
            return true
        elseif fn == "cellAtIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then
                local ccb, items,ccb1, items1
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("shenqi_new/cell_shenqiselect", nil, true, "cell_shenqiselect")
                    gameWindows.windows["artifactSelect"].module:initCellFixedString(items)
                    ui.setLabelString(items.doLab,gameConfig.strings:string_common("artifact",6),19)
                    ccb1, items1 =  CCBReaderLoad("shenqi_new/cell_shenqiselect_content", nil, true, "cell_shenqiselect_content")

                    items1.touchBtn:addHandleOfControlEvent(function()
                        
                    end, CCControlEventTouchUpInside)
                    items1.touchBtn:setSwallowsTouch(true)
                    items1.touchBtn:setTouchPriority(self.touchPriority - 2)

                    local scrollnode = tolua.cast(items1.scrollnode, "CCScrollView")
                    scrollnode:setTouchPriority(self.touchPriority - 3)
    
                    gameWindows.windows["artifactSelect"].module:initCellDetalFixedString(items1)
                    local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1]
                    if artifact.skill1 > 0 or artifact.skill2 > 0 or artifact.skill3 > 0 then
                        ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSSize.y)
                    else
                        ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSize.y)
                    end
                    ccb1:setScale(1.1)
                    a2:addChild(ccb1)
                    ccb:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                    ccb:setScale(1.1)
                    a2:addChild(ccb)

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1
                    local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1]
                    if artifact.skill1 > 0 or artifact.skill2 > 0 or artifact.skill3 > 0 then
                        ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSSize.y)
                    else
                        ccb1:setPosition(self.cellNorSize.x/2, -self.cellDelSize.y)
                    end
                    items1 = self.unrecycleCell.detailCell.items1
                end
                local setStr = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1].isChecked > 0 and gameConfig.strings:string_common("artifact",6) or gameConfig.strings:string_common("artifact",90)
                ui.setLabelString(items.doLab,setStr,19)
                gameWindows.windows["artifactSelect"].module.setNormal(self,items,self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1],function(data)
                    if data.isChecked > 0 then
                        GameScene:shiftLayer("artifactMount","up",{artifact = data})
                    else
                        GameScene:shiftLayer("artifactCheck","up",data)
                    end
                end,true,a1 + 1,#self.artifactData[self.curSelectPage][self.selectArtifactPage],self.rootItems.listArtifact)
                gameWindows.windows["artifactSelect"].module.setDetail(self,items1,self.artifactData[self.curSelectPage][self.selectArtifactPage][a1+1],true,true)
            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shenqiselect", nil, true, "cell_shenqiselect")
                    cellCCB:setScale(1.1)
                    gameWindows.windows["artifactSelect"].module:initCellFixedString(ccbDocumentControler)
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    ui.tableviewAnimation(self.ListTableView,cellCCB,self.cellNorSize.x/2,-self.cellNorSize.y,a1)
                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
                local setStr = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1].isChecked > 0 and gameConfig.strings:string_common("artifact",6) or gameConfig.strings:string_common("artifact",90)
                ui.setLabelString(ccbDocumentControler.doLab,setStr,19)
                gameWindows.windows["artifactSelect"].module.setNormal(self,ccbDocumentControler,self.artifactData[self.curSelectPage][self.selectArtifactPage][a1+1],function(data)
                    if data.isChecked > 0 then
                        GameScene:shiftLayer("artifactMount","up",{artifact = data,})
                    else
                        GameScene:shiftLayer("artifactCheck","up",data)
                    end
                end,false,a1 + 1,#self.artifactData[self.curSelectPage][self.selectArtifactPage],self.rootItems.listArtifact)
                
                if first then
                    a2:addChild(cellCCB)
                else
                    cellCCB:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                end
            end
            r = a2
        elseif fn == "numberOfCells" then
            r = #self.artifactData[self.curSelectPage][self.selectArtifactPage]
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listArtifact:getContentSize().width,
        viewheight = self.rootItems.listArtifact:getContentSize().height,
        dire = 1
    })
    self.rootItems.listArtifact:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function artifactList.createJewelList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.jewelCellSize.x, self.jewelCellSize.y)
        elseif fn == "cellAtIndex" then
            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shenqibaoshi", nil, true, "cell_shenqibaoshi")
                --cellCCB:setScale(1.1)
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                ui.tableviewAnimation(self.jewelList,cellCCB,self.jewelCellSize.x/2,0,a1)
                self:initCellFixedString(ccbDocumentControler)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setlistCell(ccbDocumentControler,self.jewelShowData[self.selectJewelPage][a1+1])

            if self.jewelList then
                cellCCB:setPosition(self.jewelCellSize.x/2,0)
            end
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = #self.jewelShowData[self.selectJewelPage]
        end
        return r
    end)

    self.jewelList = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listJewel:getContentSize().width,
        viewheight = self.rootItems.listJewel:getContentSize().height,
        dire = 1
    })
    self.rootItems.listJewel:addChild(self.jewelList)
    self.jewelList:setTouchPriority(self.touchPriority)
end

function artifactList.setlistCell(self,items,data)
    ui.setNewIcon(items,{cid = data.cid},0)
    local artifactData = data.artifactId and self.artifactData.primeData[tostring(data.artifactId)] or nil
    items["i_button"]:addHandleOfControlEvent(function()
        if data.artifactId then
            gameWindows:openWindow("jewelInfo",{cid = data.cid,artifact = artifactData,isUp = true,pos = data.pos},nil)
        else
            gameWindows:openWindow("jewelInfo",{cid = data.cid,isUp = false},nil)
        end
    end, CCControlEventTouchUpInside)
    items["i_button"]:setTouchPriority(self.touchPriority - 1)
    local config =  gamedata.config.trump_gem[tostring(data.cid)]
    if config.quality >= 7 then
        ui.setLabelString(items.name,config.name,213)
    else
        ui.setLabelString(items.name,config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2 - 1)
    end
    
    ui.setAttrStr(items["attr"],data)

    items.numNode:setVisible(data.artifactId == nil)
    items.generalNode:setVisible(data.artifactId ~= nil)
    if not data.artifactId  then
        ui.setLabelString(items.num,""..data.num,48)
        ui.setLabelString(items.buttontext1,gameConfig.strings:string_common("buttontext","hecheng"),19)
        ui.setLabelString(items.buttontext2,gameConfig.strings:string_common("artifact",6),19)
    else
        local artifactConfig = gamedata.config.trump[tostring(artifactData.cid)] or gamedata.config.trump_compose_cost[tostring(artifactData.cid)]
        local nameStr = artifactConfig.goldTrump > 0 and gameConfig.strings:string_common("equips",8).."·"..artifactConfig.name or artifactConfig.name
        if artifactData.generalcid then
            local name
            if gamedata.config.general[tostring(artifactData.generalcid)].name == gameConfig.strings:string_common("soul",6) then
                name = GameScene.roleinfo.name
            else
                name = gamedata.config.general[tostring(artifactData.generalcid)].name
            end
            items.generalLabel:setString(gameConfig.strings:string_format({"artifact",134},{name,nameStr}))
        else
            items.generalLabel:setString(gameConfig.strings:string_format({"artifact",135},{nameStr}))
        end

        ui.setLabelString(items.buttontext1,gameConfig.strings:string_common("artifact",106),19)
        ui.setLabelString(items.buttontext2,gameConfig.strings:string_common("artifact",5),19)
    end
    --
    ui.removeGray("CCControlButton",items.button1)
    if config.per_cid == 0 then
        ui.addGray("CCControlButton",items.button1)
    else
        if data.artifactId then
            local configN = gamedata.config.trump_gem[tostring(config.per_cid)]
            if GameScene.roleinfo.level < configN.gem_lvbet then
                ui.addGray("CCControlButton",items.button1)
            end
        end
    end
    items.button1:addHandleOfControlEvent(function()
        if data.artifactId then
            if config.per_cid == 0 then
                runGamePrompt({msg = gameConfig.strings:string_common("devour",13)})
            else
                local configN = gamedata.config.trump_gem[tostring(config.per_cid)]
                if GameScene.roleinfo.level < configN.gem_lvbet then
                    return runGamePrompt({msg = gameConfig.strings:string_format({"artifact",100},{configN.gem_lvbet})})
                end
                gameWindows:openWindow("artifactOpenPos",{artifact = artifactData,pos = data.pos})
            end
        else
            if config.per_cid == 0 then
                runGamePrompt({msg = gameConfig.strings:string_common("devour",13)})
            else
                gameWindows:openWindow("jewelUp",{selectId = data.cid},nil)
            end
        end
    end, CCControlEventTouchUpInside)
    items.button1:setSwallowsTouch(true)
    items.button1:setTouchPriority(self.touchPriority - 1)

    items.button2:addHandleOfControlEvent(function()
        if data.artifactId then
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 5505,iid = artifactData.iid,jewelCid = 0,pos = data.pos})
        else
            GameScene:shiftLayer("artifactMount","up",{isFrom = "artifactList",param = "jewel"})
        end
    end, CCControlEventTouchUpInside)
    items.button2:setSwallowsTouch(true)
    items.button2:setTouchPriority(self.touchPriority - 1)
end

function artifactList.initCellFixedString(self,cellItems)
    cellItems.fixed1:setString(gameConfig.strings:string_common("general",12))
    --ui.setLabelString(cellItems.buttontext1,gameConfig.strings:string_common("general",3),19)
end

function artifactList.lockCallback(self,t)
    --神器加锁数据 无需重新排序
    for i,v in ipairs(self.artifactData.all) do
        if v.iid == t.artifactSid then
            v.isLockState = t.isLock
            break
        end
    end
    if GameScene.layers["artifactList"].show then
        --加锁引起的10032更新不需要请求
        self.lockChange = true
        self:shiftPage(nil,true)
    end
end

function artifactList.reloadData(self,t)
    self:setArtifactData(t.data)
    self:orderJewelData()
    if GameScene.layers["artifactList"].show then
        self:shiftPage()
    end
end

function artifactList.reloadJewelData(self,t)
    self:orderJewelData(t.data)
    if GameScene.layers["artifactList"].show then
        self:shiftPage()
    end
end

function artifactList.orderJewelData(self,jewelData)
    if not self.artifactData and not jewelData then
        return
    end

    if jewelData then
        self.jewelData = {}
        self.jewelData.primeData = jewelData
    
        self.jewelData.whole = {}
        self.jewelData.attack = {}
        self.jewelData.defence = {}
        self.jewelData.life = {}
        self.jewelData.skill = {}
        self.jewelData.Nums = {}
        self.jewelData.Nums.whole = 0
        self.jewelData.Nums.attack = 0
        self.jewelData.Nums.defence = 0
        self.jewelData.Nums.life = 0
        self.jewelData.Nums.skill = 0
        for k,v in pairs(jewelData) do
            if v.num > 0 then
                self.jewelData.whole[#self.jewelData.whole + 1] = v
                self.jewelData.Nums.whole = self.jewelData.Nums.whole + v.num
                local config = gamedata.config.trump_gem[tostring(v.cid)]
                local addTable = self.jewelData[self.jewelConfig[config.type + 1]]
                addTable[#addTable + 1] = v
                self.jewelData.Nums[self.jewelConfig[config.type + 1]] = self.jewelData.Nums[self.jewelConfig[config.type + 1]] + v.num
            end
        end
    end
    
    if self.artifactData and self.jewelData then
        self.jewelShowData = {}
        self.jewelShowData.whole = table.copy(self.jewelData.whole)
        self.jewelShowData.attack = table.copy(self.jewelData.attack)
        self.jewelShowData.defence = table.copy(self.jewelData.defence)
        self.jewelShowData.life = table.copy(self.jewelData.life)
        self.jewelShowData.skill = table.copy(self.jewelData.skill)
        self.jewelShowData.Nums = {}
        self.jewelShowData.Nums.whole = self.jewelData.Nums.whole
        self.jewelShowData.Nums.attack = self.jewelData.Nums.attack
        self.jewelShowData.Nums.defence = self.jewelData.Nums.defence
        self.jewelShowData.Nums.life = self.jewelData.Nums.life
        self.jewelShowData.Nums.skill = self.jewelData.Nums.skill
        for k,v in ipairs(self.artifactData.checked) do
            for i = 1,4 do
                if v["jewel"..i] > 0 then
                    self.jewelShowData.Nums.whole = self.jewelShowData.Nums.whole + 1
                    self.jewelShowData.whole[#self.jewelShowData.whole + 1] = {cid = v["jewel"..i],num = 1,artifactId = v.iid,pos = i}
                    local config = gamedata.config.trump_gem[tostring(v["jewel"..i])]
                    local addTable = self.jewelShowData[self.jewelConfig[config.type + 1]]
                    addTable[#addTable + 1] = {cid = v["jewel"..i],num = 1,artifactId = v.iid,pos = i}
                    self.jewelShowData.Nums[self.jewelConfig[config.type + 1]] = self.jewelShowData.Nums[self.jewelConfig[config.type + 1]] + 1
                end
            end
        end
        local sortFunc = function (a,b)
            if a.artifactId and b.artifactId then
                if a.cid == b.cid then
                    return a.artifactId > b.artifactId
                end
                return a.cid > b.cid
            elseif not a.artifactId and not b.artifactId then
                return a.cid < b.cid
            else
                if a.artifactId then
                    return true
                else
                    return false
                end
            end
        end
        for i = 1,5 do
            table.sort(self.jewelShowData[self.jewelConfig[i]],sortFunc)
        end
    end
end

function artifactList.setArtifactData(self,artifactData)
    self.artifactData = {}
    self.artifactData.primeData = artifactData
    -- 所有
    self.artifactData.all = {}
    -- 金光神器
    self.artifactData.strengthenArtifact = {}
    self.artifactData.strengthenArtifact.all = {}
    -- 攻击
    self.artifactData.strengthenArtifact.atkArtifact = {}
    self.artifactData.strengthenArtifact.defArtifact = {}
    self.artifactData.strengthenArtifact.hpArtifact = {}
    -- 未鉴定
    self.artifactData.strengthenArtifact.unChecked = {}
    -- 普通神器
    self.artifactData.commonlyArtifact = {}
    self.artifactData.commonlyArtifact.all = {}
    -- 攻击
    self.artifactData.commonlyArtifact.atkArtifact = {}
    self.artifactData.commonlyArtifact.defArtifact = {}
    self.artifactData.commonlyArtifact.hpArtifact = {}
    -- 未鉴定
    self.artifactData.commonlyArtifact.unChecked = {}

    -- 解锁
    self.artifactData.checked = {}
    self.artifactData.unChecked = {}
    for k,v in pairs(artifactData) do
        self.artifactData.all[#self.artifactData.all + 1] = v
    end
    printT(self.artifactData.checked,"setArtifactData")
    
    self:orderArtifactData(self.artifactData.all)

    for i,v in ipairs(self.artifactData.all) do
        local cof = gamedata.config.trump[tostring(v.cid)] or gamedata.config.trump_compose_cost[tostring(v.cid)]
        -- printT(v," = = = =")
        -- 是否是金光神器
        if cof.goldTrump == 1 then
            if v.isChecked > 0 then
                self.artifactData.strengthenArtifact.all[#self.artifactData.strengthenArtifact.all + 1] = v            
                if cof.type == 1 then
                    self.artifactData.strengthenArtifact.atkArtifact[#self.artifactData.strengthenArtifact.atkArtifact + 1] = v
                elseif cof.type == 2 then
                    self.artifactData.strengthenArtifact.defArtifact[#self.artifactData.strengthenArtifact.defArtifact + 1] = v
                elseif cof.type == 3 then
                    self.artifactData.strengthenArtifact.hpArtifact[#self.artifactData.strengthenArtifact.hpArtifact + 1] = v
                end
                -- 已解锁神器
                -- self.artifactData.checked[#self.artifactData.checked + 1] = v
            else
                -- 未解锁
                -- self.artifactData.unChecked[#self.artifactData.unChecked + 1] = v
                self.artifactData.strengthenArtifact.unChecked[#self.artifactData.strengthenArtifact.unChecked + 1] = v
            end
        else
            
        end

        -- 普通神器数据 改为显示全部神器
        if v.isChecked > 0 then
            self.artifactData.commonlyArtifact.all[#self.artifactData.commonlyArtifact.all + 1] = v
            if cof.type == 1 then
                self.artifactData.commonlyArtifact.atkArtifact[#self.artifactData.commonlyArtifact.atkArtifact + 1] = v
            elseif cof.type == 2 then
                self.artifactData.commonlyArtifact.defArtifact[#self.artifactData.commonlyArtifact.defArtifact + 1] = v
            elseif cof.type == 3 then
                self.artifactData.commonlyArtifact.hpArtifact[#self.artifactData.commonlyArtifact.hpArtifact + 1] = v
            end
            -- 已解锁神器
            self.artifactData.checked[#self.artifactData.checked + 1] = v
        else
            self.artifactData.unChecked[#self.artifactData.unChecked + 1] = v
            self.artifactData.commonlyArtifact.unChecked[#self.artifactData.commonlyArtifact.unChecked + 1] = v
        end
    end

end

function artifactList.orderArtifactData(self,artifactData)
    
    local sortFunc = function (a,b)
        -- if a.isChecked ~= b.isChecked then
        --     return a.isChecked > b.isChecked
        -- end
        if a.generalcid and not b.generalcid then 
            return true
        end
        if b.generalcid and not a.generalcid then 
            return false
        end
        -- local total1,total2 = 0,0
        -- for i = 1,4 do
        --     total1 = a["jewel"..i] > 0 and a["jewel"..i]%100 + total1 or total1 + 0
        --     total2 = b["jewel"..i] > 0 and b["jewel"..i]%100 + total2 or total2 + 0
        -- end
        -- if total1 ~= total2 then
        --     return total1 > total2
        -- end

        if a.score ~= b.score then
            return a.score > b.score
        end

        local skillS1,skillS2 = 0,0
        for i = 1,3 do
            if a["skill"..i] > 0 then
                local integral = gamedata.config.breakskill[tostring(a["skill"..i])].integral
                skillS1 = skillS1 + integral
            end
            if b["skill"..i] > 0 then
                local integral = gamedata.config.breakskill[tostring(b["skill"..i])].integral
                skillS2 = skillS2 + integral
            end
        end
        if skillS1 ~= skillS2 then
            return skillS1 > skillS2
        end

        local config1 = gamedata.config.trump[tostring(a.cid)] or gamedata.config.trump_compose_cost[tostring(a.cid)]
        local config2 = gamedata.config.trump[tostring(b.cid)] or gamedata.config.trump_compose_cost[tostring(b.cid)]
        if config1.goldTrump ~= config2.goldTrump then
            return config1.goldTrump > config2.goldTrump
        end

        return a.cid < b.cid
    end
    table.sort(artifactData,sortFunc)

    -- table.sort(self.artifactData.all,sortFunc)
    -- table.sort(self.artifactData.checked,sortFunc)
    -- table.sort(self.artifactData.unChecked,sortFunc)
    -- -- 金光神器排序
    -- table.sort(self.artifactData.strengthenArtifact.all,sortFunc)
    -- table.sort(self.artifactData.strengthenArtifact.atkArtifact,sortFunc)
    -- table.sort(self.artifactData.strengthenArtifact.defArtifact,sortFunc)
    -- table.sort(self.artifactData.strengthenArtifact.hpArtifact,sortFunc)
    -- table.sort(self.artifactData.strengthenArtifact.unChecked,sortFunc)
    -- -- 普通神器排序
    -- table.sort(self.artifactData.commonlyArtifact.all,sortFunc)
    -- table.sort(self.artifactData.commonlyArtifact.atkArtifact,sortFunc)
    -- table.sort(self.artifactData.commonlyArtifact.defArtifact,sortFunc)
    -- table.sort(self.artifactData.commonlyArtifact.hpArtifact,sortFunc)
    -- table.sort(self.artifactData.commonlyArtifact.unChecked,sortFunc)
    -- printT(self.artifactData.checked,"orderArtifactData")

end

function artifactList.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil

    self.jewelList = nil
    self.ListTableView = nil

    self.selectpage = "artifact"
    self.selectArtifactPage = "all"
    self.selectJewelPage = "whole"
    self.artifactSelect = nil
    self.curSelectPage = "commonlyArtifact"
    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}
    self.isSelectState = false
end


return artifactList �  