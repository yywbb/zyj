--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/30
-- Time: 下午4:37
-- To change this template use File | Settings | File Templates.
--


local equipstage = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    chooseData = nil,--选择的物品数据
    spendPropsData = nil, --消耗物品数据
}



function equipstage.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("equip_new/equip_jinjie2", nil, true, "equip_jinjie")

    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)


    self.rootItems.closeButton:addHandleOfControlEvent(function()
        -- gameWindows:closeWindow("equipstage")
        print("点击主页")
        guide:setGuideProlayer(true)
        gameWindows:closeAllWindowDirect()
        --GameScene:shiftLayer("main","down")
        GameScene:shiftLayer(GameScene.priorLayer,"up",{selectpage = "equip"})
        --print("lua memory",collectgarbage("count"))
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(-101)

    ui.setLabelString(self.rootItems.nowNameLabel,nil,1)
    ui.setLabelString(self.rootItems.nextNameLabel,nil,1)
    
    self.rootItems.nowPropertyNode:setVisible(false)
    self.rootItems.nextPropertyNode:setVisible(false)

    ui.setLabelString(self.rootItems.needcoinText,nil,13)
    ui.setLabelString(self.rootItems.needcoinLabel,nil,13)
  
    if param and param.equip then
        self:reloadData(param.equip)
    else    

    -- if not GameScene:checkUpdate(10025,"equipstage") then
        self:reloadData()
    -- end 
    end

    guide.controller:addComplete(150,function()
        UIRequest({type = 2882,opt=1,sysID=150})
    end)
end

function equipstage.reloadStatus(self,data)
    self.chooseData = {}
    table.insert(self.chooseData,data)

    -- local spengtemp = {}
    -- if self.chooseData and next(self.chooseData)  then
    --     -- print("enter====cid...level2",self.chooseData[1]["cid"],self.chooseData[1]["level2"]+1)
    --     -- printT(gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])])
    --     local spengconfig = gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])]
    --     -- spengtemp = gamedata.getIDandNUMs(spengconfig["consume"]) 
    --     -- printT()
    --     for k,v in pairs(gamedata.getIDandNUMs(spengconfig["consume"..(self.chooseData[1]["level2"]+1)])) do
    --         table.insert(spengtemp,v.cid)
    --     end

    --     if spengconfig["equip"..(self.chooseData[1]["level2"]+1)] then
    --         local temp = spengconfig["equip"..(self.chooseData[1]["level2"]+1)]
    --         for k,v in pairs(gamedata.getIDandNUMs(temp)) do
    --             table.insert(spengtemp,v.cid)
    --         end
    --     end
    -- end
    local spengtemp = self:getSpendPropsNum()
    print("spengtemp=callback")
    -- printT(spengtemp)
    -- 获取消耗物品的数据
    UIRequest({type = 12001, order = 14002, cids = spengtemp})
    
    self:reloadData()
end


function equipstage.reloadData(self,equipdata)
    print("Reloadequipstage")
    ui.setLabelString(self.rootItems.stageUpText,nil,19)
    
    self.rootItems.stageUpBtn:addHandleOfControlEvent(function()
        -- gameWindows:closeWindow("equipstage")
        print("装备进阶")
        local spengtemp = {}
        if self.chooseData and next(self.chooseData)  then
            local limitnum = table.getTableLength(gamedata.config.equip_evolvesuffix)
            

            local stageLevel = self.chooseData[tonumber(1)].level2+1
            local cidnum = self.chooseData[tonumber(1)].cid
            local equipconfig = gamedata.config.equip[tostring(cidnum)]
            local equip_evolve = gamedata.config.equip_evolve[tostring(cidnum)]
            -- print("stageLevel===",limitnum,stageLevel,self.chooseData[tonumber(1)].level2)
            if equipconfig.quality < 6 then
                limitnum = 30
            end
            if self.chooseData[tonumber(1)].level2 == limitnum then
                if (equip_evolve.evolve ~= nil and equip_evolve.evolve ~= 0 and equip_evolve.evolve ~= "") then
                    equipconfig = gamedata.config.equip[tostring(equip_evolve["evolve"])]
                    stageLevel = 1
                    cidnum = tostring(equip_evolve["evolve"])
                else
                    stageLevel = self.chooseData[tonumber(1)].level2
                end
                -- print("changelevel2")
                -- equipconfig = gamedata.config.equip[tostring(equip_evolve["evolve"])]
                -- stageLevel = 1
                -- cidnum = tostring(equip_evolve["evolve"])
            end
            -- 升红的等级限制提示
            if equipconfig.quality == 6 then
                -- self.rootItems.stagePromptLabel:setVisible(true)

                local stagePrompsconfig = gamedata.config.equip_evolvesuffix[tostring(stageLevel)]
                -- -- 装备达到0星，且强化等级不小于0级，才可继续进阶
                -- local stagePrompstring = "装备达到"..(stagePrompsconfig.star_lv or 0).."星，且强化等级不小于"..(stagePrompsconfig.intentify_lv or 0).."级，才可继续进阶"
                -- ui.setLabelString(self.rootItems.stagePromptLabel,stagePrompstring,11)

                if self.chooseData[tonumber(1)].level3 < stagePrompsconfig.star_lv then
                    -- runGamePrompt({msg = gameConfig.strings:string_common("equipstage",3)})
                    -- runGamePrompt({msg = "装备星级等级需要达到"..stagePrompsconfig.star_lv.."级,才可进阶"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",6)..stagePrompsconfig.star_lv..gameConfig.strings:string_common("equipstage",7)})
                    return
                end
                if self.chooseData[tonumber(1)].level1 < stagePrompsconfig.intentify_lv then
                    -- runGamePrompt({msg = gameConfig.strings:string_common("equipstage",3)})
                    -- runGamePrompt({msg = "装备强化等级需要达到"..stagePrompsconfig.intentify_lv.."级,才可进阶"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",8)..stagePrompsconfig.intentify_lv..gameConfig.strings:string_common("equipstage",7)})
                    return
                end
            end  
            -- local spengconfig = gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])]
            -- spengtemp = gamedata.getIDandNUMs(spengconfig["consume"..(self.chooseData[1]["level2"]+1)]) 
            -- if spengconfig["equip"..(self.chooseData[1]["level2"]+1)] then
            --     local temp = spengconfig["equip"..(self.chooseData[1]["level2"]+1)]
            --     for k,v in pairs(gamedata.getIDandNUMs(temp)) do
            --         table.insert(spengtemp,v)
            --     end
            -- end
            local spengtemp = self:getSpendPropsNum(true)

            for i,v in ipairs(spengtemp) do

                if v.cid == 1000 then
                    if (self.spendPropsData[tostring(v.cid)] or 0) < v.num then
                        shortCoin()
                        return
                    end  
                    -- print("i==1,",self.spendPropsData[tostring(v.cid)],v.num)
                    --runGamePrompt({msg = "银币不足"})
                    
                elseif ((self.spendPropsData[tostring(v.cid)] or 0) < v.num) then
                    -- print("i~=1,",(self.spendPropsData[tostring(v.cid)] or 0),v.num)
                    -- runGamePrompt({msg = "进阶材料不足"})
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",3)})
                    return
                end
            end
            if  spengtemp == nil or (not next(spengtemp)) then
                -- runGamePrompt({msg = "装备已达到最高阶"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipstage",4)})
            else
                local limilvconfig = gamedata.config.equip_evolvelv
                local evolveconfig = gamedata.config.equip_evolve[tostring(self.chooseData[1]["cid"])]
                if (evolveconfig.evolve == nil or evolveconfig.evolve == 0) and not limilvconfig[tostring(self.chooseData[1]["level2"]+1)] then
                    runGamePrompt({msg = gameConfig.strings:string_common("equipstage",4)})
                    
                    return
                elseif limilvconfig[tostring(self.chooseData[1]["level2"]+1)] and limilvconfig[tostring(self.chooseData[1]["level2"]+1)]["lv"..self.chooseData[1]["quality"]] > GameScene.roleinfo.level then
                    -- local lvstring = "进化到下一阶级，需要战队等级达到"..GameScene.roleinfo.level.."级"
                    local lvstring = gameConfig.strings:string_common("equipstage",1)..limilvconfig[tostring(self.chooseData[1]["level2"]+1)]["lv"..self.chooseData[1]["quality"]]..gameConfig.strings:string_common("equipstage",2)
                    runGamePrompt({msg = lvstring})
                    
                    return
                end
                UIRequest({type = 1122,iid = self.chooseData[1]["iid"],props = spengtemp})
            end
        else
            -- runGamePrompt({msg = "还没选择装备"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipstage",5)})
            return
        end


    end, CCControlEventTouchUpInside)
    self.rootItems.stageUpBtn:setSwallowsTouch(true)
    self.rootItems.stageUpBtn:setTouchPriority(-101)

    --
    if equipdata then
        self.chooseData = {}
        table.insert( self.chooseData, equipdata )
        local spengtemp = self:getSpendPropsNum()
        UIRequest({type = 12001, order = 14002, cids = spengtemp})
        self:setStageUpItems()
    else
    --
        self:setStageUpItems()
        self:setNeedItems()
    end

end


function equipstage.setEquipstagedData(self,data)
    print("equipstagedData")
    -- printT(data)

    self.equipstagedData = data
end

-- 接收消耗品数据
function equipstage.setSpendPropsData(self,data)
    print("spendPropsData")
    printT(data)
    self.spendPropsData = {}
    self.spendPropsData = data

    local spengtemp = self:getSpendPropsNum(true)

    local spendcoinnum = 0
    for i,v in ipairs(spengtemp) do
        print("cid==",v.cid,v.num)
        if v.cid == 1000 then
            spendcoinnum = v.num
            break
        end
    end

    if (self.spendPropsData[tostring(1000)] or 0) < spendcoinnum then
        ui.setLabelString(self.rootItems.needcoinLabel,spendcoinnum,24)
    else
        ui.setLabelString(self.rootItems.needcoinLabel,spendcoinnum,13)
    end

        
    self:setNeedItems()
end

-- 设置当前装备属性和下一阶属性
function equipstage.setStageUpItems(self)
    print("setStageUpItems...")
    -- printT(self.chooseData)
    self.rootItems.stagePromptLabel:setVisible(false)
    if self.chooseData and next(self.chooseData) then
        self.rootItems.nowPropertyNode:setVisible(true)
        self.rootItems.nextPropertyNode:setVisible(true)

        -- 进阶前设置
        local cidnum = self.chooseData[tonumber(1)]["cid"]
        local equipconfig = gamedata.config.equip[tostring(cidnum)]
        local nowNameString = equipconfig.name
        local stageLevel = self.chooseData[tonumber(1)].level2
        local stageNameConfig = gamedata.config.equip_evolvesuffix
        if stageLevel ~= 0 then
            nowNameString = nowNameString..stageNameConfig[tostring(stageLevel)]["suffix"..self.chooseData[tonumber(1)]["quality"]]
        end
        ui.setLabelString(self.rootItems.nowNameLabel,nowNameString,((equipconfig.quality and equipconfig.quality ~= 0) and equipconfig.quality or 1)*2-1)
        -- 进阶前icon设置
        self:setHasItems(self.chooseData[tonumber(1)],1)
        -- 进阶前属性
        self:setProperty(stageLevel,cidnum,"now")
        
        -- 进阶后的icon设置
        local limitnum = table.getTableLength(gamedata.config.equip_evolvesuffix)
        if equipconfig.quality < 6 then
            limitnum = 30
        end
        local stageLevel = self.chooseData[tonumber(1)].level2+1
        -- print("stageLevel===",limitnum,stageLevel,self.chooseData[tonumber(1)].level2)
        local equip_evolve = gamedata.config.equip_evolve[tostring(cidnum)]
        if self.chooseData[tonumber(1)].level2 == limitnum then
            print("changelevel2===",self.chooseData[tonumber(1)].level2,limitnum,equip_evolve.evolve)
            if (equip_evolve.evolve ~= nil and equip_evolve.evolve ~= 0 and equip_evolve.evolve ~= "") then
                equipconfig = gamedata.config.equip[tostring(equip_evolve["evolve"])]
                stageLevel = 1
                cidnum = tostring(equip_evolve["evolve"])
            else
                stageLevel = self.chooseData[tonumber(1)].level2
            end
            
        end
        printT(equipconfig,"equipconfig===")
        local nextNameString = equipconfig.name
        local stageNameConfig = gamedata.config.equip_evolvesuffix
        -- print("stageNameConfig===",stageLevel,nextNameString)
        -- printT(stageNameConfig)

        -- 升红的等级限制提示
        if equipconfig.quality == 6 then
            self.rootItems.stagePromptLabel:setVisible(true)
            local stagePrompsconfig = stageNameConfig[tostring(stageLevel)]
            -- 装备达到0星，且强化等级不小于0级，才可继续进阶
            -- local stagePrompstring = "装备达到"..(stagePrompsconfig.star_lv or 0).."星，且强化等级不小于"..(stagePrompsconfig.intentify_lv or 0).."级，才可继续进阶"
            local stagePrompstring = gameConfig.strings:string_common("equipstage",9)..(stagePrompsconfig.star_lv or 0)..gameConfig.strings:string_common("equipstage",10)..(stagePrompsconfig.intentify_lv or 0)..gameConfig.strings:string_common("equipstage",11)
            ui.setLabelString(self.rootItems.stagePromptLabel,stagePrompstring,11)
        end  
        

        -------------------------------Max判断设置-------------------------------
        local tempconfig
        if stageLevel ~= 0 then
            tempconfig = stageNameConfig[tostring(stageLevel)]["suffix"..equipconfig["quality"]]
        end
        print("max======",self.chooseData[tonumber(1)].level2,limitnum,tempconfig,equip_evolve.evolve)
        if (stageLevel ~= 0 and self.chooseData[tonumber(1)].level2 ~= limitnum and (tempconfig == nil or tempconfig == "")) or (self.chooseData[tonumber(1)].level2 == limitnum and (equip_evolve.evolve and equip_evolve.evolve == 0 or equip_evolve.evolve == "")) then
            -- ui.setLabelString(self.rootItems.refine_next_attrnum1, configdata["refine-grow"]*self.data.level2, 14)
            -- ui.setLabelString(self.rootItems.refine_next_name,configdata.name..(self.data.level2>0 and "+"..self.data.level2 or ""), configdata.quality and 2*configdata.quality-1 or 1)
            -- self.rootItems.spendsNode:setVisible(true)
            -- self.rootItems.refine_next_attrnode:setVisible(false)

            self.rootItems.refine_next_attrnode:setVisible(false)
            self.rootItems.stage_prop_title:setVisible(false)
            self.rootItems.spendsNode:setVisible(false)
            self.rootItems.coinNode:setVisible(false)
            self.rootItems.maxDescText:setVisible(true)


            self.rootItems.refine_attrnode:setPositionX(0)
            ui.addGray("CCControlButton",self.rootItems.stageUpBtn)
            print("equip===stage===max===")

            self.rootItems.stagePromptLabel:setVisible(false)
            self.rootItems.stageUpBtn:setVisible(false)
            self.rootItems.stageUpText:setVisible(false)

            return
        end

        self.rootItems.refine_next_attrnode:setVisible(true)
        self.rootItems.stage_prop_title:setVisible(true)
        self.rootItems.spendsNode:setVisible(true)
        self.rootItems.coinNode:setVisible(true)
        self.rootItems.maxDescText:setVisible(false)

        self.rootItems.refine_attrnode:setPositionX(-270)
        ui.removeGray("CCControlButton",self.rootItems.stageUpBtn)

        self.rootItems.stageUpBtn:setVisible(true)
        self.rootItems.stageUpText:setVisible(true)
        -------------------------------Max判断设置-------------------------------



        if stageLevel ~= 0 then
            -- print("name====",stageNameConfig[tostring(stageLevel)]["suffix"..self.chooseData[tonumber(1)]["quality"]])
            nextNameString = nextNameString .. stageNameConfig[tostring(stageLevel)]["suffix"..equipconfig["quality"]]
        end
        -- print("text0000")
        ui.setLabelString(self.rootItems.nextNameLabel,nextNameString,((equipconfig.quality and equipconfig.quality ~= 0) and equipconfig.quality or 1)*2-1)
        -- print("text1111")
        -- 进阶后icon设置
        self:setHasItems({cid = cidnum, level1 = self.chooseData[tonumber(1)]["level1"],level3 = self.chooseData[tonumber(1)]["level3"] },2)
        -- 进阶后属性
        -- print("text2222")
        -- print("cidnum====",cidnum)
        self:setProperty(stageLevel,cidnum,"next")
        -- 消耗银币设置

        -- local spengconfig = gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])]
        -- local spengtemp = gamedata.getIDandNUMs(spengconfig["consume"..(self.chooseData[1]["level2"]+1)]) 
         
        local spengtemp = self:getSpendPropsNum(true)

        local spendcoinnum = 0
        for i,v in ipairs(spengtemp) do
            print("cid==",v.cid,v.num)
            if v.cid == 1000 then
                spendcoinnum = v.num
                break
            end
        end
        print("spendcoinnum==",spendcoinnum)

        ui.setLabelString(self.rootItems.needcoinLabel,spendcoinnum,13)
    else
        self.rootItems.nowPropertyNode:setVisible(false)
        self.rootItems.nextPropertyNode:setVisible(false)
        self:setNothingItems(1)
        self:setNothingItems(2)
        -- 消耗银币置空
        ui.setLabelString(self.rootItems.needcoinLabel,"0",13)
        ui.setLabelString(self.rootItems.nowNameLabel,gameConfig.strings:string_common("equipstage",12),1)
        ui.setLabelString(self.rootItems.nextNameLabel,gameConfig.strings:string_common("equipstage",12),1)
        

    end

end

-- 设置属性
function equipstage.setProperty(self,level,cid,type)
    local equip_evolve = gamedata.config.equip_evolve[tostring(cid)]
    -- printT(equip_evolve)
    print("level,cid,type",level,cid,type)

    -- print(gameConfig.strings:string_common("attr_type",equip_evolve["attr"]))
    -- print("gongji==",equip_evolve["init"..level])

    -- local equipconfig = gamedata.config.equip[tostring(cid)]
    -- ui.setLabelString(self.rootItems[type.."propertyText"],nil,14)

    local propertyString = gameConfig.strings:string_common("attr_type",equip_evolve["attr"]).."＋"..equip_evolve["init"..level] or {}

    ui.setLabelString(self.rootItems[type.."propertyLabel"],propertyString,14)
    
    -- nowpropertyText
    -- nowpropertyLabel

    for i=1,13 do
        if self.rootItems[type.."propertyAdd"..i] then
            if equip_evolve["trigger_attr"..i] and equip_evolve["trigger_attr"..i] ~= "" then
                local attrtemp = equip_evolve["trigger_attr"..i]
                local attr,num = gamedata.getAttrData(attrtemp)
                -- print("attr,num==",attr,num)
                local strings = gameConfig.strings:string_common("attr_type",attr)
                -- print("string2,desc==",strings,equip_evolve["desc"..i])
                strings = strings..num.."%("..equip_evolve["desc"..i]..")"

                local labelnum = 29
                if level >= tonumber(equip_evolve["trigger"..i]) then
                    labelnum = 14
                end
                ui.setLabelString(self.rootItems[type.."propertyAdd"..i],strings,labelnum)
            else
                ui.setLabelString(self.rootItems[type.."propertyAdd"..i],"",29)
            end
        end
    end
    -- nowpropertyAdd1
    -- nowpropertyAdd2
    -- nowpropertyAdd3
    -- nowpropertyAdd4

end

-- 设置进阶消耗物品
function equipstage.setNeedItems(self)

    
    -- local spengtemp = {}
    -- if self.chooseData and next(self.chooseData)  then
    --     -- 判断是否橙色升到红色
    --     local limitnum = table.getTableLength(gamedata.config.equip_evolvesuffix)
    
    --     local stageLevel = self.chooseData[tonumber(1)].level2+1
    --     local cidnum = self.chooseData[tonumber(1)].cid
    --     -- print("stageLevel===",limitnum,stageLevel,self.chooseData[tonumber(1)].level2)
    --     if self.chooseData[tonumber(1)].level2 == limitnum then
    --         -- print("changelevel2")
    --         local equip_evolve = gamedata.config.equip_evolve[tostring(cidnum)]
    --         equipconfig = gamedata.config.equip[tostring(equip_evolve["evolve"])]
    --         stageLevel = 1
    --         cidnum = tostring(equip_evolve["evolve"])
    --     end


    --     -- local spengconfig = gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])]
    --     local spengconfig = gamedata.config.equip_evolveconsume[tostring(cidnum)]
    --     -- print("setNeedItems====")
    --     -- printT(spengconfig)
    --     if spengconfig["equip"..stageLevel] then
    --         local temp = spengconfig["equip"..stageLevel]
    --         for k,v in pairs(gamedata.getIDandNUMs(temp)) do
    --             table.insert(spengtemp,v)
    --         end
    --     end

    --     for i,v in ipairs(gamedata.getIDandNUMs(spengconfig["consume"..stageLevel]) ) do
    --         -- if i ~= 1 then
    --         if v.cid ~= 1000 then
    --             table.insert(spengtemp,v)
    --         end
    --     end
    -- end

    local spengtemp = self:getSpendPropsNum(true,true)
    printT(spengtemp,"spengtemp===setNeedItems")

    for i=3,7 do
        if spengtemp and next(spengtemp) and (i-2) <= #spengtemp then
            -- print("setHasItems",i)
            self:setHasItems(spengtemp[tonumber(i-2)],i,true)
            self.rootItems["needprop"..(i-2)]:setVisible(true)
        else
            -- print("setNothingItems",i)
            self.rootItems["needprop"..(i-2)]:setVisible(false)
        end
    end
end

-- 有物品时设置
function equipstage.setHasItems(self,data,num,stutas)
    print("setHasItems===num",num)
    -- printT(data)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end

    self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
        -- ui.setPopwindowByCid(data.cid)
        -- print("setHasItems...button",num)
        if stutas then
            ui.setPopwindowByCid(data.cid)
        end
        if num > 1 then
            return
        end
        local equipiid = 0
        if self.chooseData and next(self.chooseData) then
            equipiid = self.chooseData[1].iid
        end
        -- print("equipiid==",equipiid)

        local callback = function(selectedData)

            self.chooseData = {}
            for k,v in pairs(selectedData) do
                table.insert( self.chooseData, v )
            end

            -- printT(self.chooseData,"self.chooseData==")

            -- local spengtemp = {}
            -- if self.chooseData and next(self.chooseData)  then
            --     -- print("enter====cid...level2",self.chooseData[1]["cid"],self.chooseData[1]["level2"]+1)
            --     -- printT(gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])])
            --     local spengconfig = gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])]
            --     -- spengtemp = gamedata.getIDandNUMs(spengconfig["consume"]) 
            --     -- printT()
            --     for k,v in pairs(gamedata.getIDandNUMs(spengconfig["consume"..(self.chooseData[1]["level2"]+1)])) do
            --         table.insert(spengtemp,v.cid)
            --     end
            --     if spengconfig["equip"..(self.chooseData[1]["level2"]+1)] then
            --         local temp = spengconfig["equip"..(self.chooseData[1]["level2"]+1)]
            --         for k,v in pairs(gamedata.getIDandNUMs(temp)) do
            --             table.insert(spengtemp,v.cid)
            --         end
            --     end
            -- end
            -- -- print("spengtemp=callback")
            -- -- printT(spengtemp)
            -- 获取消耗物品的数据
            local spengtemp = self:getSpendPropsNum()
            UIRequest({type = 12001, order = 14002, cids = spengtemp})
            
            
            self:setStageUpItems()
        end
        gameWindows:openWindow("selectlist",{type = "change_equipstage_one", param = {equipiid = equipiid}},callback)
    end, CCControlEventTouchUpInside)
    

    if stutas then
        -- print(data.cid,"cid====")
        -- printT(data,"data===")
        -- printT(self.spendPropsData,"self.spendPropsData===")
        ui.setNewIcon(self.rootItems,{cid=data.cid,num=((self.spendPropsData[tostring(data.cid)] or 0).."/"..data.num)},num-1)
        if (self.spendPropsData[tostring(data.cid)] or 0) >= data.num then
            ui.setLabelString(self.rootItems["i_num"..key_Ex],nil,13)
        else
            ui.setLabelString(self.rootItems["i_num"..key_Ex],nil,24)
        end
    else
        -- ui.setNewIcon(self.rootItems,{cid=data.cid,num=("LV:"..data.level1)},num-1)
        -- 装备升星星级展示
        ui.setNewIcon(self.rootItems,{cid=data.cid,num=("等级:"..data.level1)},num-1,data)
    end

    -- self.spendPropsData
    -- cid, num

    -- self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
    --     -- ui.setPopwindowByCid(data.cid)
        
    --     print("i..am..1",num)
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems["i_button"..key_Ex]:setTouchPriority(-101)

end

-- 没物品时设置
function equipstage.setNothingItems(self,num)
    local key_Ex
    if num == nil or num == 1 then
        key_Ex = ""
    else
        key_Ex = "_"..(num-1)
    end


    self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
        -- ui.setPopwindowByCid(data.cid)
        if num > 1 then
            return
        end
        local equipiid = 0
        if self.chooseData and next(self.chooseData) then
            equipiid = self.chooseData[1].iid
        end
        -- print("equipiid==",equipiid)

        local callback = function(selectedData)

            print("selectedData=callback")
            -- printT(selectedData)
            self.chooseData = {}
            for k,v in pairs(selectedData) do
                table.insert( self.chooseData, v )
            end

            -- local spengtemp = {}
            -- if self.chooseData and next(self.chooseData)  then
            --     -- print("enter====cid...level2",self.chooseData[1]["cid"],self.chooseData[1]["level2"]+1)
            --     -- printT(gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])])
            --     local spengconfig = gamedata.config.equip_evolveconsume[tostring(self.chooseData[1]["cid"])]
            --     -- spengtemp = gamedata.getIDandNUMs(spengconfig["consume"]) 
            --     -- printT()
            --     for k,v in pairs(gamedata.getIDandNUMs(spengconfig["consume"..(self.chooseData[1]["level2"]+1)])) do
            --         table.insert(spengtemp,v.cid)
            --     end
            --     if spengconfig["equip"..(self.chooseData[1]["level2"]+1)] then
            --         local temp = spengconfig["equip"..(self.chooseData[1]["level2"]+1)]
            --         for k,v in pairs(gamedata.getIDandNUMs(temp)) do
            --             table.insert(spengtemp,v.cid)
            --         end
            --     end
                
            -- end
            -- printT(self.chooseData)
            -- print("spengtemp=callback")
            -- printT(spengtemp)
            -- 获取消耗物品的数据
            local spengtemp = self:getSpendPropsNum()
            UIRequest({type = 12001, order = 14002, cids = spengtemp})
            
            self:setStageUpItems()
        end
        gameWindows:openWindow("selectlist",{type = "change_equipstage_one", param = {equipiid = equipiid}},callback)
    end, CCControlEventTouchUpInside)
    if num == 1 then
        setSpriteFrameByName(self.rootItems["i_icon"..key_Ex], "obj_add2")
    else
        setSpriteFrameByName(self.rootItems["i_icon"..key_Ex], "alpha")
    end
    setSpriteFrameByName(self.rootItems["i_k_quality"..key_Ex], "b_iconk1")
    setSpriteFrameByName(self.rootItems["i_quality"..key_Ex], "b_iconbg1")
    self.rootItems["i_soulsprite"..key_Ex]:setVisible(false)

    self.rootItems["i_soulnode"..key_Ex]:removeAllChildrenWithCleanup(true)
    self.rootItems["i_suitNode"..key_Ex]:removeAllChildrenWithCleanup(true)
    

    ui.setLabelString(self.rootItems["i_num"..key_Ex],"",13)

    self.rootItems["star_starnode"..key_Ex]:setVisible(false)
    
end

-- 获取消耗的cid,status1:有值时获取v，没值时获取cid；status2：有值时获取除开银币的材料v（1000），没值时获取材料v
function equipstage.getSpendPropsNum( self,status1,status2)
    printT(self.chooseData,"chooseData===")
    local spengtemp = {}
    if self.chooseData and next(self.chooseData)  then
        -- 判断是否橙色升到红色
        local limitnum = table.getTableLength(gamedata.config.equip_evolvesuffix)

        local stageLevel = self.chooseData[tonumber(1)].level2+1
        local cidnum = self.chooseData[tonumber(1)].cid
        -- print("stageLevel===",limitnum,stageLevel,self.chooseData[tonumber(1)].level2)
        local equip_evolve = gamedata.config.equip_evolve[tostring(cidnum)]

        if gamedata.config.equip[tostring(cidnum)].quality < 6 then
            limitnum = 30
        end

        if self.chooseData[tonumber(1)].level2 == limitnum then
            if (equip_evolve.evolve ~= nil and equip_evolve.evolve ~= 0 and equip_evolve.evolve ~= "") then
                stageLevel = 1
                cidnum = tostring(equip_evolve["evolve"])
            else
                stageLevel = self.chooseData[tonumber(1)].level2
            end
            -- print("changelevel2")
            -- equipconfig = gamedata.config.equip[tostring(equip_evolve["evolve"])]
            
        end
        print("stageLevel,cidnum===",stageLevel,cidnum)
        local equipconfig = gamedata.config.equip[tostring(cidnum)]
        local spengconfig = gamedata.config.equip_evolveconsume[tostring(cidnum)]
        printT(spengconfig,"spengconfig===")
        print("spendPropsnum===",equipconfig.quality, equip_evolve.evolve, equipconfig.quality, cidnum, spengconfig["consume"..stageLevel])
        if (equipconfig.quality ~=6 and self.chooseData[tonumber(1)].level2 == limitnum and (equip_evolve.evolve == nil or equip_evolve.evolve == 0 or equip_evolve.evolve == "")) or (spengconfig["consume"..stageLevel] == nil or spengconfig["consume"..stageLevel] == "") then

        else
            if spengconfig["equip"..stageLevel] then
                local temp = spengconfig["equip"..stageLevel]
                for k,v in pairs(gamedata.getIDandNUMs(temp)) do
                    if status1 then
                        if status2 == nil then
                            table.insert(spengtemp,v)
                        elseif v.cid ~= 1000 then
                            table.insert(spengtemp,v)
                        end 
                    else
                        table.insert(spengtemp,v.cid)
                    end
                    
                end
            end
            for k,v in pairs(gamedata.getIDandNUMs(spengconfig["consume"..stageLevel])) do
                if status1 then
                    if status2 == nil then
                        table.insert(spengtemp,v)
                    elseif v.cid ~= 1000 then
                        table.insert(spengtemp,v)
                    end  
                else
                    table.insert(spengtemp,v.cid)
                end
            end
        end
        
        printT(spengtemp,"spengtemp===")
    end
    -- print("spengtemp=callback")
    -- printT(spengtemp)
    -- 获取消耗物品的数据
    return spengtemp
end

function equipstage.clear(self)

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    self.chooseData = nil
    spendPropsData = nil
end


return equipstage