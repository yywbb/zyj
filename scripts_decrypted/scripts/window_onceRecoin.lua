
--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/10/24
-- Time: 上午10:13
-- To change this template use File | Settings | File Templates.
--

local onceRecoin = {

    rootNode = nil,
    rootItems = nil,

    cellNorSize = {x=980,y=220},
    cellDelSSize = {x = 980,y = 860},
    cellDelSTwoSize = {x = 980,y = 950},
    cellDelSize = {x = 980,y = 860},

    unrecycleCell = {},
    artifactData = nil,
    pageconfig = {"artifact"},
    -- artifactTypeConfig = {"all","checked","unChecked"},
    artifactTypeConfig = {"all","atkArtifact","defArtifact","hpArtifact"},
    
    selectpage = "artifact",
    selectArtifactPage = "all",
    artifactSelect = nil,
    isSelectState = false,
    isSelectState1 = false,
    curSelectPage = "commonlyArtifact",--strengthenArtifact
    ListTableView = nil,
    selectList ={},
    maxNum = 30,
}


function onceRecoin.shiftPage(self,type,isChange)

    print("shiftPage",isChange)
    self.selectpage = type or self.selectpage

    self.rootItems.listArtifact:setVisible(self.selectpage == self.pageconfig[1])
    print("lipurposes self.selectpage ",self.selectpage)
    if not self.artifactData then
        GameScene:addUpdate(10032)
    end
    if GameScene:checkUpdate(10032) then
        return
    end
    -- self.rootItems.listArtifact:setPositionX(0)
    

    --重置全选状态
    self.isSelectState1 = false
    self.rootItems.autosprite1:setVisible(self.isSelectState1)
    self:selectListState()
    self:setArtifactBtnState()

    if not self.ListTableView then
        self:createArtifactList()
    else
        local addLength = self.cellNorSize.y
        if self.artifactSelect then
            local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][self.artifactSelect]
            
            local curHeight = self.cellDelSize.y
            if artifact.skill1 > 0 then
                curHeight = self.cellDelSize.y
            end
            if artifact.skill2 > 0 then
                curHeight = self.cellDelSTwoSize.y
            end
            if artifact.skill3 > 0 then
                curHeight = self.cellDelSSize.y
            end
            addLength = curHeight
        end

        if isChange then
            self.ListTableView:setLuaContentOffset(0, self.rootItems.listArtifact:getContentSize().height - (#self.artifactData[self.curSelectPage][self.selectArtifactPage] - 1) *self.cellNorSize.y - addLength)
        end
        
        self.ListTableView:reloadData()
    end
end


function onceRecoin.setArtifactBtnState(self)
    for k,v in pairs(self.artifactTypeConfig) do
        self.rootItems[v.."Onpoint"]:setVisible(v == self.selectArtifactPage)
    end
    
    local n = math.floor(table.getTableLength(self.selectList)/3)
    self.rootItems.artifactNums:setString("当前可重铸"..n.."件");
end

--[[
    0.无提示 
    1.有橙色或者红色技能的神器弹出二次确认框
    2.有2个或3个技能的神器弹出二次确认框
]]
function onceRecoin.consumeJudge(datas)
    for i,v in ipairs(datas) do
        for k=1,3 do
            if v["skill"..k] > 0 then
                local config = gamedata.config.breakskill[tostring(v["skill"..k])]

                if config.quality > 4 then
                    return 1
                end
            end
        end
    end

    for i,v in ipairs(datas) do
        local skillnum = 0
        for k=1,3 do
            if v["skill"..k] > 0 then
                skillnum = skillnum + 1
            end
        end

        if skillnum >= 2 then
            return 2
        end
    end

    return 0
end

function onceRecoin.selectListState(self)
    self.selectList = {}
    if self.isSelectState1 then
        for i,v in ipairs(self.artifactData[self.curSelectPage][self.selectArtifactPage]) do
            if table.getTableLength(self.selectList) < self.maxNum then
                if v.consumeStatus == 0 then
                    self:addSelectList(v,true)
                end
            else
                break
            end
        end
    end
end

function onceRecoin.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("shenqi_new/tc_yijianchongzhu", nil, true, "tc_yijianchongzhu")
    self.touchPriority = touchPriority
    self.callBack = callback;

    self.selectpage = "artifact"
    self.rootItems.listArtifact:setContentSize(CCSizeMake(1080,800))
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

        self.isSelectState1 = false
        self.rootItems.autosprite1:setVisible(self.isSelectState1)
        self:selectListState()

        if not self.ListTableView then
            self:createArtifactList()
        else
            local addLength = self.cellNorSize.y
            if self.artifactSelect then
                local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][self.artifactSelect]
                local curHeight = self.cellDelSize.y
                if artifact.skill1 > 0 then
                    curHeight = self.cellDelSize.y
                end
                if artifact.skill2 > 0 then
                    curHeight = self.cellDelSTwoSize.y
                end
                if artifact.skill3 > 0 then
                    curHeight = self.cellDelSSize.y
                end
                addLength = curHeight
            end
            self.ListTableView:setLuaContentOffset(0, self.rootItems.listArtifact:getContentSize().height - (#self.artifactData[self.curSelectPage][self.selectArtifactPage] - 1) *self.cellNorSize.y - addLength)
            self.ListTableView:reloadData()
        end



    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton:setSwallowsTouch(true)
    self.rootItems.autobutton:setTouchPriority(self.touchPriority)

    self:setButtonFunc()
    self:shiftPage()
    return self.rootNode
end

function onceRecoin.setButtonFunc(self)
    for k,v in pairs(self.artifactTypeConfig) do
        self.rootItems[v.."Button"]:addHandleOfControlEvent(function()
            if self.selectArtifactPage == v then
                return
            else
                self.artifactSelect = nil
                self.selectArtifactPage = v
                self:shiftPage(nil,true)
           end
        end, CCControlEventTouchUpInside)
        self.rootItems[v.."Button"]:setSwallowsTouch(true)
        self.rootItems[v.."Button"]:setTouchPriority(self.touchPriority)
    end

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("onceRecoin")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.noLab,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.noButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("onceRecoin")
    end, CCControlEventTouchUpInside)
    self.rootItems.noButton:setSwallowsTouch(true)
    self.rootItems.noButton:setTouchPriority(self.touchPriority-2)

    ui.addGray("CCControlButton",self.rootItems.yesButton)
    ui.setLabelString(self.rootItems.yesLab,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.yesButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        local len = table.getTableLength(self.selectList)
        if len >= 3 then

            local executeFunc = function ( )
                local curState = 0
                if self.isSelectState == true then
                    curState = 1
                else
                    curState = 0
                end
                local len = math.floor(table.getTableLength(self.selectList)/3)*3
                UIRequest({type = 5517,curList = self.selectList,curState = curState,curNum = len})
                gameWindows:closeWindowDirect("onceRecoin")
            end
            local result = onceRecoin.consumeJudge(self.selectList)
            if result == 0 then
                executeFunc()
            elseif result == 1 then
                gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("artifact",183)},executeFunc)
            elseif result == 2 then
                gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("artifact",184)},executeFunc)
            end
        else
            runGamePrompt({msg = "数量不满足条件！"})
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.yesButton:setSwallowsTouch(true)
    self.rootItems.yesButton:setTouchPriority(self.touchPriority-2)

    self.rootItems.autosprite1:setVisible(false)
    self.rootItems.autobutton1:addHandleOfControlEvent(function()
        self.isSelectState1 = not self.isSelectState1
        self.rootItems.autosprite1:setVisible(self.isSelectState1);
        
        self:selectListState()
        self.ListTableView:reloadData()
        self:updateBtnState()
    end, CCControlEventTouchUpInside)
    self.rootItems.autobutton1:setSwallowsTouch(true)
    self.rootItems.autobutton1:setTouchPriority(self.touchPriority-2)

end
-- 更新确定按钮状态
function onceRecoin.updateBtnState(self)

    local len = table.getTableLength(self.selectList)
    if len >= 3 then
        ui.removeGray("CCControlButton",self.rootItems.yesButton)
    else
        ui.addGray("CCControlButton",self.rootItems.yesButton)
    end

    local n = math.floor(table.getTableLength(self.selectList)/3)
    self.rootItems.artifactNums:setString("当前可重铸"..n.."件");
end

function onceRecoin.setIsSelected(self,artifactsData)
    local len = table.getTableLength(self.selectList)
    -- print(' -----11-1-1-1-1',len)
    if len == 0 then
        return false
    end
    for i,v in ipairs(self.selectList) do
        if artifactsData.iid == v.iid then
            return true
        end
    end
    return false
end

-- 添加选择数据
function onceRecoin.addSelectList(self,artifactsData,isAll)


    if artifactsData.isLockState == 1 then
        runGamePrompt({msg = gameConfig.strings:string_common("artifact",171)})
        return true
    end

    -- body
    local len = table.getTableLength(self.selectList)
    if len == 0 then
        table.insert(self.selectList,artifactsData)
        return false
    end
    for i,v in ipairs(self.selectList) do
        if artifactsData.iid == v.iid then
            if isAll == false then
                table.remove(self.selectList,i)
            end
            return true
        end
    end

    --超过上限
    print("addSelectList",table.getTableLength(self.selectList),self.maxNum)
    if table.getTableLength(self.selectList) >= self.maxNum then
        runGamePrompt({msg = "数量超过上限！"})
        return true
    end

    table.insert(self.selectList,artifactsData)
    return false
end


function onceRecoin.createArtifactList(self)
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then

        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            if self.artifactSelect and self.artifactSelect == a1+1 then
                local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1]

                local curHeight = self.cellDelSize.y
                if artifact.skill1 > 0 then
                    curHeight = self.cellDelSize.y
                end
                if artifact.skill2 > 0 then
                    curHeight = self.cellDelSTwoSize.y
                end
                if artifact.skill3 > 0 then
                    curHeight = self.cellDelSSize.y
                end
                r = CCSizeMake(self.cellNorSize.x, curHeight)
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
                local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1]
                if self.unrecycleCell.detailCell == nil then
                    a2 = CCTableViewCell:create()
                    ccb, items =  CCBReaderLoad("shenqi_new/cell_shenqichongzhu", nil, true, "cell_shenqichongzhu")
                    -- gameWindows.windows["artifactSelect"].module:initCellFixedString(items)
                    -- ui.setLabelString(items.doLab,gameConfig.strings:string_common("artifact",6),19)
                    ccb1, items1 =  CCBReaderLoad("shenqi_new/cell_shenqiselect_content", nil, true, "cell_shenqiselect_content")
                    items1.touchBtn:addHandleOfControlEvent(function()
                        
                    end, CCControlEventTouchUpInside)
                    items1.touchBtn:setSwallowsTouch(true)
                    items1.touchBtn:setTouchPriority(self.touchPriority - 2)

                    local scrollnode = tolua.cast(items1.scrollnode, "CCScrollView")
                    scrollnode:setTouchPriority(self.touchPriority - 3)

                    gameWindows.windows["artifactSelect"].module:initCellDetalFixedString(items1)

                    local curHeight = self.cellDelSize.y
                    if artifact.skill1 > 0 then
                        curHeight = self.cellDelSize.y
                    end
                    if artifact.skill2 > 0 then
                        curHeight = self.cellDelSTwoSize.y
                    end
                    if artifact.skill3 > 0 then
                        curHeight = self.cellDelSSize.y
                    end
                    ccb1:setPosition(self.cellNorSize.x/2, -curHeight)

                    -- ccb1:setScale(1.1)
                    a2:addChild(ccb1)
                    ccb:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                    -- ccb:setScale(1.1)
                    a2:addChild(ccb)

                    self.unrecycleCell.detailCell={cell = a2, ccb =ccb, items=items,ccb1 =ccb1, items1=items1}
                    self.unrecycleCell.detailCell.cell:retain()
                else
                    a2 = self.unrecycleCell.detailCell.cell
                    ccb = self.unrecycleCell.detailCell.ccb
                    items = self.unrecycleCell.detailCell.items
                    ccb1 = self.unrecycleCell.detailCell.ccb1

                    local curHeight = self.cellDelSize.y
                    if artifact.skill1 > 0 then
                        curHeight = self.cellDelSize.y
                    end
                    if artifact.skill2 > 0 then
                        curHeight = self.cellDelSTwoSize.y
                    end
                    if artifact.skill3 > 0 then
                        curHeight = self.cellDelSSize.y
                    end
                    ccb1:setPosition(self.cellNorSize.x/2, -curHeight)

                    items1 = self.unrecycleCell.detailCell.items1
                end
                self:updateSkillCounAndLock(items,artifact)
                self:addSkillInfo(items1,artifact)
                local state = self:setIsSelected(artifact)
                items.autosprite:setVisible(state)
                print("state 1111   ",state)
                items.selectBtn:addHandleOfControlEvent(function()
                    state = self:addSelectList(artifact,false)
                    items.autosprite:setVisible(not state)
                    -- self:addSelectList(artifact,false)
                    self:updateBtnState();
                end, CCControlEventTouchUpInside)
                items.selectBtn:setSwallowsTouch(true)
                items.selectBtn:setTouchPriority(self.touchPriority - 1)

                -- local setStr = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1].isChecked > 0 and gameConfig.strings:string_common("artifact",6) or gameConfig.strings:string_common("artifact",90)
                -- ui.setLabelString(items.doLab,setStr,19)
                gameWindows.windows["artifactSelect"].module.setNormal(self,items,self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1],function(data)
                    if data.isChecked > 0 then
                        GameScene:shiftLayer("artifactMount","up",{artifact = data})
                    else
                        GameScene:shiftLayer("artifactCheck","up",data)
                    end
                end,true,a1 + 1,#self.artifactData[self.curSelectPage][self.selectArtifactPage],self.rootItems.listArtifact,true,true)

                gameWindows.windows["artifactSelect"].module.setDetail(self,items1,self.artifactData[self.curSelectPage][self.selectArtifactPage][a1+1],true,false)


            else
                local cellCCB,ccbDocumentControler = 0,0
                local first = true
                if not a2 then
                    a2 = CCTableViewCell:create()
                    cellCCB, ccbDocumentControler = CCBReaderLoad("shenqi_new/cell_shenqichongzhu", nil, true, "cell_shenqichongzhu")
                    -- cellCCB:setScale(1.1)
                    gameWindows.windows["artifactSelect"].module:initCellFixedString(ccbDocumentControler)
                    celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
                    ui.tableviewAnimation(self.ListTableView,cellCCB,self.cellNorSize.x/2,-self.cellNorSize.y,a1)

                else
                    first = false
                    cellCCB = celldict[a2].cellCCB
                    ccbDocumentControler = celldict[a2].ccbDocumentControler
                end
                -- local setStr = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1].isChecked > 0 and gameConfig.strings:string_common("artifact",6) or gameConfig.strings:string_common("artifact",90)
                -- ui.setLabelString(ccbDocumentControler.doLab,setStr,19)
                gameWindows.windows["artifactSelect"].module.setNormal(self,ccbDocumentControler,self.artifactData[self.curSelectPage][self.selectArtifactPage][a1+1],function(data)
                    -- if data.isChecked > 0 then
                    --     GameScene:shiftLayer("artifactMount","up",{artifact = data,})
                    -- else
                    --     GameScene:shiftLayer("artifactCheck","up",data)
                    -- end
                end,false,a1 + 1,#self.artifactData[self.curSelectPage][self.selectArtifactPage],self.rootItems.listArtifact,true,true)
                
                if first then
                    a2:addChild(cellCCB)
                else
                    cellCCB:setPosition(self.cellNorSize.x/2, -self.cellNorSize.y)
                end
                local artifact = self.artifactData[self.curSelectPage][self.selectArtifactPage][a1 + 1]
                
                self:updateSkillCounAndLock(ccbDocumentControler,artifact)

                local state = self:setIsSelected(artifact)
                ccbDocumentControler.autosprite:setVisible(state)
                print("state 2222   ",state)
                ccbDocumentControler.selectBtn:addHandleOfControlEvent(function()
                    state = self:addSelectList(artifact,false)
                    ccbDocumentControler.autosprite:setVisible(not state)
                    self:updateBtnState()
                end, CCControlEventTouchUpInside)
                ccbDocumentControler.selectBtn:setSwallowsTouch(true)
                ccbDocumentControler.selectBtn:setTouchPriority(self.touchPriority - 1)
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


function onceRecoin.addSkillInfo(self,items,data)
    -- body
end


function onceRecoin.initCellFixedString(self,cellItems)
    cellItems.fixed1:setString(gameConfig.strings:string_common("general",12))
    --ui.setLabelString(cellItems.buttontext1,gameConfig.strings:string_common("general",3),19)
end


function onceRecoin.lockCallback(self,t)
    --神器加锁数据 无需重新排序
    for i,v in ipairs(self.artifactData.all) do
        if v.iid == t.artifactSid then
            v.isLockState = t.isLock
            break
        end
    end
    --选中状态锁定 取消选中
    for i,v in ipairs(self.selectList) do
        if v.iid == t.artifactSid then
            table.remove(self.selectList,i)
            break
        end
    end

    self:shiftPage()
end

--withoutOrder 无需排序
function onceRecoin.reloadData(self,t)

    self:orderArtifactData(t.data)

    if gameWindows.windows["onceRecoin"].show then
        self:shiftPage()
    end
end


function onceRecoin.orderArtifactData(self,artifactData)
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
        v.consumeStatus = gameWindows.windows["artifactSelect"].module.consumeStatus(v)
        self.artifactData.all[#self.artifactData.all + 1] = v
        local cof = gamedata.config.trump[tostring(v.cid)] 
        -- 是否是金光神器
        if cof.goldTrump == 1 then

            if not v.generalcid then
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
                    self.artifactData.checked[#self.artifactData.checked + 1] = v
                else
                    -- 未解锁
                    self.artifactData.unChecked[#self.artifactData.unChecked + 1] = v
                    self.artifactData.strengthenArtifact.unChecked[#self.artifactData.strengthenArtifact.unChecked + 1] = v
                end
            end
            
        else
            -- if v.isLockState == 0 and not v.generalcid  then
            if not v.generalcid  then
                -- 普通神器数据
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
    end
    local sortFunc = function (a,b)
        if a.consumeStatus ~= b.consumeStatus then
            return a.consumeStatus < b.consumeStatus
        end

        return a.score < b.score
    end

    table.sort(self.artifactData.all,sortFunc)
    table.sort(self.artifactData.checked,sortFunc)
    table.sort(self.artifactData.unChecked,sortFunc)
    -- 金光神器排序
    table.sort(self.artifactData.strengthenArtifact.all,sortFunc)
    table.sort(self.artifactData.strengthenArtifact.atkArtifact,sortFunc)
    table.sort(self.artifactData.strengthenArtifact.defArtifact,sortFunc)
    table.sort(self.artifactData.strengthenArtifact.hpArtifact,sortFunc)
    table.sort(self.artifactData.strengthenArtifact.unChecked,sortFunc)
    -- 普通神器排序
    table.sort(self.artifactData.commonlyArtifact.all,sortFunc)
    table.sort(self.artifactData.commonlyArtifact.atkArtifact,sortFunc)
    table.sort(self.artifactData.commonlyArtifact.defArtifact,sortFunc)
    table.sort(self.artifactData.commonlyArtifact.hpArtifact,sortFunc)
    table.sort(self.artifactData.commonlyArtifact.unChecked,sortFunc)

end

function onceRecoin.updateSkillCounAndLock( self,items,data)

    ui.showArtifactSkillNum(items,data)
    if data.isLockState == 1 then
        items.lockIcon:setVisible(true)
    else
        items.lockIcon:setVisible(false)
    end
end

function onceRecoin.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

    self.rootNode = nil
    self.rootItems = nil

    self.ListTableView = nil

    self.selectpage = "artifact"
    self.selectArtifactPage = "all"
    self.artifactSelect = nil
    self.curSelectPage = "commonlyArtifact"
    if self.unrecycleCell.detailCell then
        self.unrecycleCell.detailCell.cell:release()
    end
    self.unrecycleCell = {}
    self.isSelectState = false
    self.isSelectState1 = false
    self.selectList = {}
    self.artifactData = nil
end


return onceRecoin
 �k  