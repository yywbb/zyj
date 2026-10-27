--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/3/31
-- Time: 上午11:43
-- To change this template use File | Settings | File Templates.
--

local godCompetitionSlotsDetail = {

    rootNode = nil,
    rootItems = nil,

    data = {},
    godCompetionData = {},
    buffdata = {},--阵容buff
    touchpriority  = -103,
}

function godCompetitionSlotsDetail.init(self,parent,toppos,data,index)
    self.rootNode,self.rootItems =  CCBReaderLoad("fengshensai/fengshensai_buzhen", nil, true, "fengshensai_buzhen")
    self.rootNode:setPosition(-GameScene.viewSize.width/2,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.bg:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((toppos)/2)

    --返回
    if self.rootItems.closeButton then
        self.rootItems.closeButton:setTouchPriority(self.touchpriority)
        self.rootItems.closeButton:addHandleOfControlEvent(function()
            GameScene:shiftLayer("godCompetitionMain","up")
        end, CCControlEventTouchUpInside)
    end

    --配置阵容
    ui.setLabelString(self.rootItems.editarrayLab, nil, 18)
    ui.setLabelString(self.rootItems.savearrayLab, nil, 18)
    self.rootItems.editArrayButton:setSwallowsTouch(true)
    self.rootItems.editArrayButton:setTouchPriority(self.touchpriority)
    self.rootItems.editArrayButton:addHandleOfControlEvent(function()
        print("配置阵容")
        GameScene:shiftLayer("godCompetitionSlotsInfo","up",{buzhendata = self.data, buffdata=self.buffdata})
    end, CCControlEventTouchUpInside)

    self.rootItems.saveArrayButton:setSwallowsTouch(true)
    self.rootItems.saveArrayButton:setTouchPriority(self.touchpriority)
    self.rootItems.saveArrayButton:addHandleOfControlEvent(function()
        print("上传阵容")
        local isfull = self:checkSlot()
        if isfull then
            if self.buffdata and self.buffdata.type == "pvp" then
                -- UIRequest({type=8263}) --pvp
                UIRequest({type=8251})
            else
                UIRequest({type=8264})
            end    
        else
           runGamePrompt({ msg= gameConfig.strings:string_common("godCompetition",6) })
        end    
    end, CCControlEventTouchUpInside)


    if data and data.buzhendata then --布阵信息
        print("godCompetitionSlotsDetail init  have data")
        self:reloadSlotsDetail(data.buzhendata)    
    else
        UIRequest({type=8252})
    end
    
    if data and data.bossindex then --boss界面跳转
        self.buffdata = data
    end

    if data and data.buffdata then --布阵界面返回
        self.buffdata = data.buffdata
    end

    if self.buffdata then
        self.rootItems.title:setString( self.buffdata.period)
        local breakskill = gamedata.config.breakskill
        if self.buffdata.bossBuff then
            printT(self.buffdata.bossBuff,"bossBuff")
            for k,v in pairs(self.buffdata.bossBuff) do
                if self.buffdata.type == "boss" then
                    self.rootItems[k]:setString("BUFF:无")
                else
                    if breakskill[tostring(v)] then
                        self.rootItems[k]:setString("BUFF:"..breakskill[tostring(v)].desc)
                    end    
                end    
            end    
        end    

    end    

end

function godCompetitionSlotsDetail.reloadSlotsDetail(self,data)
    
    if data and data.godCompetionData then
        self.data = data
        self.godCompetionData = data.godCompetionData
        -- printT(self.godCompetionData,"self.godCompetionData")
        for i=1,3 do
            local _zhenrongdata  =  self.godCompetionData[tostring(i)].slot_General
            printT(_zhenrongdata,"zhenrongdata")
            local _mach = {}
            for kk,vv in pairs(_zhenrongdata.sid) do
                -- printT(_zhenrongdata.general[tostring(kk)],"kk_zhengrong")
                if _zhenrongdata.general and _zhenrongdata.general[tostring(kk)] and table.getTableLength(_zhenrongdata.general[tostring(kk)]) > 0 then
                   _mach[kk] =  _zhenrongdata.general[tostring(kk)].general.godCompetitionArrayId
                else
                   _mach[kk] = 0
                end
     
                --武将头像
                local cellCCB, ccbDocumentControler = CCBReaderLoad("slotsInfo/generalIcon.ccbi", nil, true, "generalIcon")
                ccbDocumentControler.selectEffect:removeAllChildrenWithCleanup(true)
                cellCCB:setScale(0.96)
                local generalData = _zhenrongdata.general[tostring(kk)]
                if generalData.general then
                    if generalData.general.illusionGeneralCid then
                        local configGeneral = gamedata.config.general[tostring(generalData.general.illusionGeneralCid)]
                        local gdata = ui.getConfigGeneralSion(generalData.general)
                        if next(gdata) and configGeneral.fashion_id == 0 then
                            if configGeneral.passiveskills and configGeneral.passiveskills > 0 then
                                gdata.skillid = configGeneral.passiveskills
                            end
                            ui.setSlotGeneralIcon(generalData,ccbDocumentControler,0,gdata)
                        else
                            ui.setSlotGeneralIcon(generalData,ccbDocumentControler)
                        end
                    else
                        local configGeneral = gamedata.config.general[tostring(generalData.general.cid)]
                        local gdata = ui.getConfigGeneral(generalData.general)
                        if next(gdata) and configGeneral.fashion_id == 0 then
                            if configGeneral.passiveskills and configGeneral.passiveskills > 0 then
                                gdata.skillid = configGeneral.passiveskills
                            end
                            ui.setSlotGeneralIcon(generalData,ccbDocumentControler,0,gdata)
                        else
                            ui.setSlotGeneralIcon(generalData,ccbDocumentControler)
                        end
                    end
                    self.rootItems["general"..i.."_"..kk]:removeAllChildrenWithCleanup(true)
                    cellCCB:setPosition(81,81)
                    self.rootItems["general"..i.."_"..kk]:addChild(cellCCB)
                end
            end  
            -- self.buzhen_mach[tostring(i)] = _mach
            printT(_mach,"jkp-mach")

            --武将头像
            local cellCCB, ccbDocumentControler = CCBReaderLoad("slotsInfo/generalIcon.ccbi", nil, true, "generalIcon")
            ccbDocumentControler.selectEffect:removeAllChildrenWithCleanup(true)
            cellCCB:setScale(0.9)
            --魔宠头像
            local pet =  self.godCompetionData[tostring(i)].pet
            if pet and pet.cid > 0 then
                ui.setSlotPetIcon(ccbDocumentControler,{cid=pet.cid, level=pet.level})
                cellCCB:setPosition(82,83)
                self.rootItems["general"..i.."_pet"]:removeAllChildrenWithCleanup(true)
                self.rootItems["general"..i.."_pet"]:addChild(cellCCB)
            end    

            --战力
            local power =  self.godCompetionData[tostring(i)].god_power or 0
            self.rootItems["power"..i]:setString(power)

            -- -- BUFF
            -- local desc = gamedata.config.apex_boss[i] 
            -- self.rootItems["buffer"..i]:setString("BUFF:"..desc)
            
        end    
        -- printT(self.buzhen_mach,"buzhen_mach")
    end    


end    


function godCompetitionSlotsDetail.checkSlot(self)
    local isFull = true
    for i=1,3 do
        local _zhenrongdata  =  self.godCompetionData[tostring(i)].slot_General
        local havegeneral = 0
        for kk,vv in pairs(_zhenrongdata.sid) do
            if _zhenrongdata.general and _zhenrongdata.general[tostring(kk)] and table.getTableLength(_zhenrongdata.general[tostring(kk)]) > 0 then
                havegeneral = havegeneral+1
            end
        end  
        if havegeneral == 0 then
            isFull = false
        end    
    end 
    return isFull
end

function godCompetitionSlotsDetail.ReloadPVP(self,data)
--1，代表上传成功
    if data and data.status then
        local _status = data.status or 0
        if _status == 1 then 
            runGamePrompt({ msg= gameConfig.strings:string_common("godCompetition",7) })
        end    
    end    
end    

function godCompetitionSlotsDetail.ReloadBoss(self,data)
    if data and data.status then
        local _status = data.status or 1
        if _status == 0  then -- 0表示成功
            runGamePrompt({ msg= gameConfig.strings:string_common("godCompetition",7) })
        else    --非0，代表该阵容为空
            runGamePrompt({ msg= gameConfig.strings:string_common("godCompetition",6) })
        end    
    end    
end  

function godCompetitionSlotsDetail.clear(self)

    self.bossIndex = 0
    self.godCompetionData = {}
    self.data = {}
    self.buffdata = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    
    self.rootNode = nil
    self.rootItems = nil
end

return godCompetitionSlotsDetail  b$  