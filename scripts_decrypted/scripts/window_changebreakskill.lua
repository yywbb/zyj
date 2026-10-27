--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/5/25
-- Time: 下午3:16
-- To change this template use File | Settings | File Templates.
--

local changebreakskill = {
    rootNode = nil,
    rootItems = nil,

    listview = nil,

    data = {},

    scopenum = 2,

    skills = {},

    islead = false,

    select1 = 0,
    select2 = 0,
    select3 = 0,

    haspropnum = 0,

    scopetype = {
        [1] = "tian",
        [2] = "di",
        [3] = "ren",
    },
}

function changebreakskill.open(self,touchPriority,data,callback)

    self.rootNode, self.rootItems = CCBReaderLoad("general_new/tc_skillselect", nil, true, "tc_skillselect")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    UIRequest({type = 12001, order = 32005, cids = {20822}})
    
    return self.rootNode
end


function changebreakskill.makeCellSize(self)
    local offy = 10
    
    local labelHeight = 45
    local textNum = 18

    self.cellSizeInfo = {}
    for k,v in ipairs(self.skills) do
        local totalH = 50
        self.cellSizeInfo[k] = {}
        self.cellSizeInfo[k].desLabelHights = {}
        self.cellSizeInfo[k].skillNodePosY = {}
        local data = v
        for i=1,self.scopenum do
            if data[i] then
                local desc = gamedata.config.breakskill[tostring(data[i].breakskillid)].desc
                local count = ui.getTextLength(desc)
                local length = math.ceil(count/textNum) + 1
                -- if gamedata.device.platform=="android" then
                --     length = length + 1
                -- end
                
                self.cellSizeInfo[k].desLabelHights[i] = length * labelHeight
                local _h = length * labelHeight + offy * 2
                self.cellSizeInfo[k].skillNodePosY[i] = -totalH - _h/2
                totalH = totalH + _h
            end
        end
        self.cellSizeInfo[k].totalH = totalH
    end

    printT(self.cellSizeInfo,"makeCellSize")
end

function changebreakskill.creatList(self)
    printT(self.skills,"self.skills")
    self:makeCellSize()
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
        elseif fn == "hasFixedCellSize" then
            r = false
        elseif fn == "cellSizeForIndex" then
            r = CCSizeMake(940, self.cellSizeInfo[a1+1].totalH)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("general_new/cell_skillselect", nil, true, "cell_skillselect")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            self:setCell(ccbDocumentControler,self.skills[a1+1] or self.skills[tostring(a1+1)],a1+1)

            cellCCB:setPosition(470, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.skills)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.listview = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listNode:getContentSize().width,
        viewheight = self.rootItems.listNode:getContentSize().height,
        dire = 1
    })
    self.rootItems.listNode:addChild(self.listview)
    self.listview:setTouchPriority(self.touchPriority)
end    

function changebreakskill.reload(self,data,callback)
    self.callback = callback
    self.data = data
    self.selectIllusion = data.selectIllusion

    ui.setLabelString(self.rootItems.scopestring,nil,14)
    ui.setLabelString(self.rootItems.cancelLab,nil,19)
    ui.setLabelString(self.rootItems.doLab,nil,19)
    
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("changebreakskill")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.RefreshBtn:addHandleOfControlEvent(function()
        --
        self:reload(self.data,self.callback)
    end, CCControlEventTouchUpInside)
    self.rootItems.RefreshBtn:setSwallowsTouch(true)
    self.rootItems.RefreshBtn:setTouchPriority(self.touchPriority - 2)

    self.rootItems.cancelBtn:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("changebreakskill")
    end, CCControlEventTouchUpInside)
    self.rootItems.cancelBtn:setSwallowsTouch(true)
    self.rootItems.cancelBtn:setTouchPriority(self.touchPriority)

    if self.data.islead and self.data.islead == 1 then
        self.islead = true
        self.scopenum = 3
    else
        self.islead = false
        self.scopenum = 2
    end    

    if self.data.general.scope and self.data.general.scope > 0 then
        setSpriteFrameByName(self.rootItems.scope,"tujin_"..self.scopetype[self.data.general.scope])
    else 
        setSpriteFrameByName(self.rootItems.scope,"alpha")
    end

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    if self.selectIllusion then
        generalConfig = gamedata.config.general[tostring(self.data.general.illusionGeneralCid)]
        self.data.general.scope = self.data.general.illusion.scope
        for i=1,5 do
            self.data.general["g_score"..i] = self.data.general.illusion["g_score"..i]
        end
    end

    self.skills = {}
    for i = 1,3 do
        if self.data.general["g_score"..i] and self.data.general["g_score"..i] > 0 then
            self["select"..i] = self.data.general["g_score"..i]
            local skillids = {}
            for j = 1,3 do
                if generalConfig["gold"..i.."_will_skills_"..j] and generalConfig["gold"..i.."_will_skills_"..j] > 0 then
                    table.insert(skillids,{ goldtype = j, breakskillid = generalConfig["gold"..i.."_will_skills_"..j]})
                end    
            end        
            table.insert(self.skills,skillids)
        else 
            self["select"..i] = 0
            break   
        end    
    end    

    self:changeskill()

    if not self.listview then
        self:creatList()
    else
        self.listview:reloadData()
    end 

end

function changebreakskill.changeskill(self)
    local scopetmp = self.select1*100 + self.select2*10 + self.select3
    --
    if gamedata.config.jinjiangkezhiguanxi and gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)] and gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)].camp then
        setSpriteFrameByName(self.rootItems.scope,"tujin_"..self.scopetype[gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)].camp])
    end
    --
    local cost = {}
    local xcost = {}
    local xselect = {}
    local selectNum = 0

    for i = 1,3 do
        if self["select"..i] ~= self.data.general["g_score"..i] then
            selectNum = selectNum + 1
            table.insert(xselect,{lv = i, scope = self["select"..i]})
        end
    end

    if selectNum > 0 then
        if gamedata.config.global_kv["gold_will_replace_breakthrough_skill_consumption"..selectNum] then
            local item = ui.getIDandNUMs(gamedata.config.global_kv["gold_will_replace_breakthrough_skill_consumption"..selectNum].value)
            for k,v in pairs(item) do
                if cost[tostring(v.cid)] then
                    cost[tostring(v.cid)] = cost[tostring(v.cid)] + v.num
                else
                    cost[tostring(v.cid)] = v.num
                end    
            end    
        end
    end

    if next(cost) then
        for k,v in pairs(cost) do
            table.insert(xcost,{cid = tonumber(k), num = tonumber(v)})
            setSpriteFrameByName(self.rootItems.xicon,ui.IDconfig(k).icon or "alpha")
            if (tonumber(k) == 20822) and (tonumber(v) > self.haspropnum) then
                ui.setLabelString(self.rootItems.xnum,v,24)
            else 
                ui.setLabelString(self.rootItems.xnum,v,14)
            end
        end
        self.rootItems.costnode:setVisible(not self.selectIllusion)
        --
        self.rootItems.doBtn:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            UIRequest({type = 7021,selectIllusion = self.selectIllusion, cid = self.data.general.cid, xcost = xcost, xselect = xselect})
        end, CCControlEventTouchUpInside)
        self.rootItems.doBtn:setSwallowsTouch(true)
        self.rootItems.doBtn:setTouchPriority(self.touchPriority)
    else
        self.rootItems.costnode:setVisible(false)
        --
        self.rootItems.doBtn:addHandleOfControlEvent(function()
            runGamePrompt({msg = "请选择需要更换的突破技"})
        end, CCControlEventTouchUpInside)
        self.rootItems.doBtn:setSwallowsTouch(true)
        self.rootItems.doBtn:setTouchPriority(self.touchPriority)
    end    

end    

function changebreakskill.setCell( self,items,data,index )

    items.title:setString((self.islead and 23+index or 13+index).."阶技能")
    items.skill3:setVisible(self.islead)

    local setsprite = function()
        for i = 1,self.scopenum do
            if self["select"..index] == data[i].goldtype then 
                items["selectsprite"..i]:setVisible(true)
            else
                items["selectsprite"..i]:setVisible(false)
            end
        end    
    end

    for i = 1,self.scopenum do
         if data[i] then
            setSpriteFrameByName(items["scope"..i],"tujin_"..self.scopetype[data[i].goldtype])
            ui.setLabelString(items["name"..i],gamedata.config.breakskill[tostring(data[i].breakskillid)].name,48)


            items["desc"..i]:setDimensions(CCSizeMake(items["desc"..i]:getDimensions().width,self.cellSizeInfo[index].desLabelHights[i]))
            ui.removeLabelStroke(items["desc"..i])
            ui.setLabelString(items["desc"..i],gamedata.config.breakskill[tostring(data[i].breakskillid)].desc,14)
            items["skill"..i]:setPositionY(self.cellSizeInfo[index].skillNodePosY[i])
            items["line"..i]:setPositionY(- self.cellSizeInfo[index].desLabelHights[i]/2 - 5)

            if self["select"..index] == data[i].goldtype then 
                items["selectsprite"..i]:setVisible(true)
            else
                items["selectsprite"..i]:setVisible(false)
            end
            --
            items["selectbutton"..i]:addHandleOfControlEvent(function()
                if self["select"..index] ~= data[i].goldtype then
                    self["select"..index] = data[i].goldtype
                    setsprite()
                    self:changeskill()
                end  
            end, CCControlEventTouchUpInside)
            items["selectbutton"..i]:setSwallowsTouch(true)
            items["selectbutton"..i]:setTouchPriority(self.touchPriority-1)
         end   
    end    

end

function changebreakskill.setPropNum(self,data)
    self.haspropnum = data["20822"] or 0
end    

function changebreakskill.close(self)
    self.haspropnum = 0
    self.select1 = 0
    self.select2 = 0
    self.select3 = 0
    self.islead = false
    self.scopenum = 2
    self.data = {}
    self.skills = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.listview = nil

    if self.callback then
        self.callback()
    end
end

return changebreakskill

�/  