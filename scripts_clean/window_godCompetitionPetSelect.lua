--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--

local godCompetitionPetList = {

    rootNode = nil,
    rootItems = nil,

    mochongTableview = nil,
    petdata = nil, --未上线魔宠
    onlinePet = {}, --上线魔宠
    team_id = 0,

}


function godCompetitionPetList.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    -- print("godCompetitionPetList..init",toppos)
    -- printT(data)
    self.onlinePet = data.onlinePet
    self.team_id = data.team_id_now
    self.rootNode, self.rootItems = CCBReaderLoad("windows/select_list", nil, true, "mochongList")
    self.rootNode:setPosition(0,0)
    UIRequest({type = 1040})

    return self.rootNode
end


function godCompetitionPetList.reload(self,allPetData)
    self.rootItems.title:setString("魔宠")
    self.rootItems.doNode2:setVisible(false)

    self.rootItems.listscroll:setPosition(540,610)
    self.rootItems.listscroll:setContentSize(CCSizeMake(960,1100))


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("godCompetitionPetList")

    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)
    self.allPetData = allPetData
    -- printT(allPetData,"allPetData")

    self.petdata = {} --所有魔宠

    local petextdata = {}
    if self.allPetData and self.allPetData.pets then
        for k,v in pairs(self.allPetData.pets) do
            v.quality = gamedata.config.pet3_attr[tostring(v.cid)][tostring(v.level)].quality
            local isadd = true
            for kk,vv in pairs (self.onlinePet) do
                if vv.petid == v.iid and vv.team_id == tonumber(self.team_id) then
                    -- print(kk,vv,"self.onlinePet")
                    isadd = false
                end   
            end    
            if isadd then
                table.insert(petextdata,v)
            end    
        end
    end    
 

    local sortFunc = function( a, b )
        if a["quality"] > b["quality"] then
            return true
        elseif a["quality"] < b["quality"] then
            return false
        else
            if a["cid"]  < b["cid"] then
                return true
            else
                return false
            end
        end    

    end
    table.sort(petextdata,sortFunc)
    self.petdata = petextdata

    -- printT(self.data)
    -- print("devourList,reload")
    -- printT(self.petdata)

    self:mochongRelaod()
    -- self:shiftPage(self.selectpage)
end


function godCompetitionPetList.mochongRelaod(self)

    if not self.mochongTableview then
        self:createMochongList()
    else
        self.mochongTableview:reloadData()
    end

    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.petdata) == 0,"devil")
end


function godCompetitionPetList.createMochongList(self)
    local celldict = {}
    local taskListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1080, 228)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("mochong3/cell_mochong.ccbi", nil, true, "cell_mochong")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local celldata = self.petdata[tonumber(a1+1)]
            local config = gamedata.config.pet3_attr[tostring(celldata.cid)][tostring(celldata.level)]
            
            -- print("config=====")
            -- printT(config)

            -- ccbDocumentControler.nameLabel:setString(config.name)
            if config.quality >= 7 then
                ui.setLabelString(ccbDocumentControler.nameLabel,config.name,213)
                ui.setLabelString(ccbDocumentControler.qualityLabel,gameConfig.strings:string_common("quality",tonumber(config.quality)),213)
            else
                ui.setLabelString(ccbDocumentControler.nameLabel,config.name,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
                ui.setLabelString(ccbDocumentControler.qualityLabel,gameConfig.strings:string_common("quality",tonumber(config.quality)),((config.quality and config.quality ~= 0) and config.quality or 1)*2)
            end

            -- ccbDocumentControler.qualityLabel:setString(gameConfig.strings:string_common("quality",tonumber(config.quality)) )
            

            ui.setNewIcon(ccbDocumentControler,{cid=self.petdata.cid})
            setSpriteFrameByName(ccbDocumentControler["i_k_quality"], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
            setSpriteFrameByName(ccbDocumentControler["i_quality"], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
            setSpriteFrameByName(ccbDocumentControler.i_icon,config.icon)
            ui.setSpriteTextureRect(ccbDocumentControler.i_icon,0,0,150,150)


            local isgray  = false
            local battleString = "上阵"
            ccbDocumentControler.spr_zhenrong:setVisible(false)
            -- setControlButtonFrameByName(ccbDocumentControler.battleBtn, "b_s_button1.png", CCControlStateNormal)
            ccbDocumentControler.battleBtn:setSwallowsTouch(true)
            
            ui.removeGray("CCControlButton", ccbDocumentControler.battleBtn)
            for kk,vv in pairs (self.onlinePet) do
                print(kk,vv,"self.onlinePet")
                if vv.petid == celldata.iid then
                    -- battleString = "已上阵"..( vv.team_id).."阵容"
                    ccbDocumentControler.spr_zhenrong:setVisible(true)
                    setSpriteFrameByName(ccbDocumentControler.spr_zhenrong, "godcompetition_" .. vv.team_id)
                    -- setControlButtonFrameByName(ccbDocumentControler.battleBtn, "b_s_button2.png", CCControlStateNormal)
                    if vv.team_id == tonumber(self.team_id) then
                        ui.addGray("CCControlButton", ccbDocumentControler.battleBtn)
                        ccbDocumentControler.battleBtn:setSwallowsTouch(false)
                        battleString = "当前阵容"
                        isgray = true
                    end    
                    break
                end   
            end    

            ccbDocumentControler.battleLabel:setVisible(false)
            ui.setLabelString(ccbDocumentControler.battleText,battleString,18)
            ccbDocumentControler.battleBtn:setTouchPriority(self.touchPriority)
            ccbDocumentControler.battleBtn:addHandleOfControlEvent(function()
                gameWindows:closeWindow("godCompetitionPetList")
                UIRequest({type = 8254, iid = celldata.iid, team_id = self.team_id})
            end, CCControlEventTouchUpInside)
            
            cellCCB:setScale(0.9)
            cellCCB:setPosition(960/2, 0)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.petdata)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.mochongTableview = ui.createLuaTableView({
        handle = taskListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.mochongTableview:setTouchPriority(self.touchPriority)
    self.rootItems.listscroll:addChild(self.mochongTableview)
end


function godCompetitionPetList.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.mochongTableview = nil

    self.petdata = nil
end


return godCompetitionPetList