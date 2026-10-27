--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
-- pet3_illustrated

local devourcollectjinjie = {
    resource = nil,
    rootNode = nil,
    rootItems = nil,

    petData = {},
    petFragment = {},

    xprop = {},
    beforecid = 0
}

function devourcollectjinjie.init(self,parent,toppos,param)

    self.petData = param.petData
    self.petFragment = param.petFragmentData
    self.petdata = param.allPetsData
    self.petFragmentData = param.petFragmentData

    self.rootNode,self.rootItems = CCBReaderLoad("mochong3/mochong_jinjie.ccbi", nil, true, "mochong_jinjie")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if self.rootItems.topnode then
        self.rootItems.topnode:setPositionY(toppos)
    end

    local nowlevel = self.petData.level
    local config = gamedata.config.pet3_attr[tostring(self.petData.cid)] or {}
    self.beforecid = config[tostring(nowlevel)].animationid
    if self.rootItems.mochongNode then
        local mochong = gamedata.config.generalanimation[tostring(config[tostring(nowlevel)].animationid)].name or "mowang_1"
        self.rootItems.mochongNode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = nil
        self.Gneral1 = CCSkeletonAnimation:create(mochong.."/"..mochong..".json",mochong.."/"..mochong..".atlas",1)
        if self.Gneral1 then
            self.Gneral1:setAnimation("stand",true,0)
            self.Gneral1:setScale(1.8*(config[tostring(nowlevel)].scale or 1))
            self.Gneral1:setPosition(0,0)
            self.rootItems.mochongNode:addChild(self.Gneral1)
        end
    end


    local iidnum = self.petdata.iid

    if iidnum ~= 0 then
        local nowcid = self.petdata.pets[tostring(iidnum)].cid
        local nowlevel = self.petdata.pets[tostring(iidnum)].level

        local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(iidnum)].cid)] or {}
        local advanceSpendconfig = config[tostring(nowlevel)].consume
        local spenddata = ui.getIDandNUMs(advanceSpendconfig)

        if advanceSpendconfig == nil or advanceSpendconfig == "" then
            -- self:setHashitData()
            -- ui.sethint(self.rootItems["stage_hint"],false)
        else
            if spenddata[4] and spenddata[4].cid then
                UIRequest({type = 12001, cids = {spenddata[2].cid,spenddata[4].cid}, order = 12341})
            else
                UIRequest({type = 12001, cids = {spenddata[2].cid}, order = 12341})
            end
        end
    end 

    self.rootItems.stageViewButton:setTouchPriority(-103)
    self.rootItems.stageViewButton:addHandleOfControlEvent(function()
        -- print("返回")
        -- local nowiid = self.petdata.iid
        local nowiid = self.petData.iid

        local petdata = {}
        for k,v in pairs(self.petdata.pets) do
            if tonumber(v.iid) == tonumber(nowiid) then
                petdata = v
                break
            end
        end

        gameWindows:openWindow("devourDetails",{data = petdata,index = "stageinfo"})

    end, CCControlEventTouchUpInside)


end

function devourcollectjinjie.refreshFunc(self,data)
    print("devourcollectup.refreshFunc")
    self.petData = data
    self:reload()
    self:setHashitData()
end

function devourcollectjinjie.setPropsData(self,pdata)
    print("setPropsData")
    -- (self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num or 0)
    for k,v in pairs(pdata) do
         print("k,v",k,v)
        if self.spenddata and self.spenddata[1] and self.spenddata[1].cid and tonumber(k) == tonumber(self.spenddata[1].cid) then
            if self.petFragmentData and self.petFragmentData[tostring(self.spenddata[1].cid)] then
                 self.petFragmentData[tostring(self.spenddata[1].cid)].num = v
            end
        end
    end
end


function devourcollectjinjie.reload(self,data)
    if data then
        printT(data,"devourcollectjinjie.reload")
        self.petData = data.petsdata
        self.petdata = data.petsdata
    end
    --
    local iidnum = self.petData.iid

    local nowcid = self.petdata.pets[tostring(iidnum)].cid
    local nowlevel = self.petdata.pets[tostring(iidnum)].level
    local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(iidnum)].cid)] or {}
    local configdata = config[tostring(nowlevel)]

    print("iidnum",iidnum,"nowcid",nowcid,"nowlevel",nowlevel)
    -- printT(config,"config")
    -- printT(configdata,"configdata")

    if self.beforecid ~= config[tostring(nowlevel)].animationid then
        print("刷新魔宠形象")
        if self.rootItems.mochongNode then
            self.beforecid = config[tostring(nowlevel)].animationid
            local mochong = gamedata.config.generalanimation[tostring(config[tostring(nowlevel)].animationid)].name or "mowang_1"
            self.rootItems.mochongNode:removeAllChildrenWithCleanup(true)
            self.Gneral1 = nil
            self.Gneral1 = CCSkeletonAnimation:create(mochong.."/"..mochong..".json",mochong.."/"..mochong..".atlas",1)
            if self.Gneral1 then
                self.Gneral1:setAnimation("stand",true,0)
                self.Gneral1:setScale(1.8*(config[tostring(nowlevel)].scale or 1))
                self.Gneral1:setPosition(0,0)
                self.rootItems.mochongNode:addChild(self.Gneral1)
            end
        end
    end    
   


    local talentconfig = gamedata.config.pet3_talentskill[tostring(configdata.talentskill)]
    local skillconfig = gamedata.config.combskill or {}

  
    ui.setLabelString(self.rootItems.qualityLabel,gameConfig.strings:string_common("quality",tonumber(configdata.quality)),((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2)
    ui.setLabelString(self.rootItems.talantLabel,talentconfig.number,2)
    --ui.setLabelString(self.rootItems.ActiveSkillLabel1,skillconfig[tostring(configdata.skillid)]["name"],((skillconfig.quality and skillconfig.quality ~= 0) and skillconfig.quality or 1)*2)

    --todo
    local moquality = (config[tostring(nowlevel)].quality and config[tostring(nowlevel)].quality ~= 0) and config[tostring(nowlevel)].quality or 1
    ui.setLabelString(self.rootItems.p_name,config[tostring(nowlevel)].name,moquality>=7 and 213 or moquality*2-1)


    --attr plus
    local plusattr = {
        attr1 = "atk",
        num1 = 0,
        attr2 = "def",
        num2 = 0,
        attr3 = "hp",
        num3 = 0,
    }
    for k,v in pairs(config) do
        if (tonumber(k) > 0) and (tonumber(k) <= nowlevel) then
            if v.attr1 and v.attr1 ~= "" then
                plusattr.attr1 = v.attr1
                plusattr.num1 = plusattr.num1+v.init1
            end
            if v.attr2 and v.attr2 ~= "" then
                plusattr.attr2 = v.attr2
                plusattr.num2 = plusattr.num2+v.init2
            end
            if v.attr3 and v.attr3 ~= "" then
                plusattr.attr3 = v.attr3
                plusattr.num3 = plusattr.num3+v.init3
            end
        end
    end
    --
    if plusattr.num1+plusattr.num2+plusattr.num3 > 0.00001 then
        ui.setLabelString(self.rootItems.p_attr1,gameConfig.strings:string_common("attr_type",plusattr.attr1).."：",13)
        ui.setLabelString(self.rootItems.p_num1,plusattr.num1,13)
        ui.setLabelString(self.rootItems.p_attr2,gameConfig.strings:string_common("attr_type",plusattr.attr2).."：",13)
        ui.setLabelString(self.rootItems.p_num2,plusattr.num2,13)
        ui.setLabelString(self.rootItems.p_attr3,gameConfig.strings:string_common("attr_type",plusattr.attr3).."：",13)
        ui.setLabelString(self.rootItems.p_num3,plusattr.num3,13)
    else
        ui.setLabelString(self.rootItems.p_attr1,"",13)
        ui.setLabelString(self.rootItems.p_num1,"",13)
        ui.setLabelString(self.rootItems.p_attr2,"",13)
        ui.setLabelString(self.rootItems.p_num2,"",13)
        ui.setLabelString(self.rootItems.p_attr3,"",13)
        ui.setLabelString(self.rootItems.p_num3,"",13)
    end

    --
    if nowlevel > 0 then
        local configdata1 = nil
        local configdata2 = nil
        local configdata3 = nil
        if configdata.attr1 and configdata.attr1 ~= "" then
            configdata1 = config[tostring(nowlevel)]
            configdata2 = config[tostring(nowlevel+1)]
            configdata3 = config[tostring(nowlevel+2)]
            ui.removeGray("CCSprite",self.rootItems.a_attr_sprite1)
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite2)
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite3)
        elseif configdata.attr2 and configdata.attr2 ~= "" then
            configdata1 = config[tostring(nowlevel-1)]
            configdata2 = config[tostring(nowlevel)]
            configdata3 = config[tostring(nowlevel+1)]
            ui.removeGray("CCSprite",self.rootItems.a_attr_sprite1)
            ui.removeGray("CCSprite",self.rootItems.a_attr_sprite2)
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite3)
        elseif configdata.attr3 and configdata.attr3 ~= "" then
            configdata1 = config[tostring(nowlevel-2)]
            configdata2 = config[tostring(nowlevel-1)]
            configdata3 = config[tostring(nowlevel)]
            ui.removeGray("CCSprite",self.rootItems.a_attr_sprite1)
            ui.removeGray("CCSprite",self.rootItems.a_attr_sprite2)
            ui.removeGray("CCSprite",self.rootItems.a_attr_sprite3)
        elseif config[tostring(nowlevel+1)] and config[tostring(nowlevel+1)].attr1 and config[tostring(nowlevel+1)].attr1 ~= "" then
            configdata1 = config[tostring(nowlevel+1)]
            configdata2 = config[tostring(nowlevel+2)]
            configdata3 = config[tostring(nowlevel+3)]
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite1)
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite2)
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite3)
        end

        if configdata1 and configdata2 and configdata3 then
            self.rootItems.attrNode:setVisible(true)
            ui.setLabelString(self.rootItems.a_attr_num1,gameConfig.strings:string_common("attr_type",configdata1 and configdata1.attr1 or "atk").."+"..(configdata1 and configdata1.init1 or 0),11)
            ui.setLabelString(self.rootItems.a_attr_num2,gameConfig.strings:string_common("attr_type",configdata2 and configdata2.attr2 or "def").."+"..(configdata2 and configdata2.init2 or 0),5)
            ui.setLabelString(self.rootItems.a_attr_num3,gameConfig.strings:string_common("attr_type",configdata3 and configdata3.attr3 or "hp").."+"..(configdata3 and configdata3.init3 or 0),3)
            setSpriteFrameByName(self.rootItems.a_attr_sprite1,"mochong_hong"..(configdata1 and configdata1.attr1 or "atk") )
            setSpriteFrameByName(self.rootItems.a_attr_sprite2,"mochong_hong"..(configdata2 and configdata2.attr2 or "def") )
            setSpriteFrameByName(self.rootItems.a_attr_sprite3,"mochong_hong"..(configdata3 and configdata3.attr3 or "hp") )
        else
            self.rootItems.attrNode:setVisible(false)
        end

    else
        self.rootItems.attrNode:setVisible(false)

        --
        local configdata1 = nil
        local configdata2 = nil
        local configdata3 = nil
        if config[tostring(nowlevel+1)] and config[tostring(nowlevel+1)].attr1 and config[tostring(nowlevel+1)].attr1 ~= "" then
            configdata1 = config[tostring(nowlevel+1)]
            configdata2 = config[tostring(nowlevel+2)]
            configdata3 = config[tostring(nowlevel+3)]
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite1)
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite2)
            ui.addGray("CCSprite",self.rootItems.a_attr_sprite3)
        end
        --
        if configdata1 and configdata2 and configdata3 then
            self.rootItems.attrNode:setVisible(true)
            ui.setLabelString(self.rootItems.a_attr_num1,gameConfig.strings:string_common("attr_type",configdata1 and configdata1.attr1 or "atk").."+"..(configdata1 and configdata1.init1 or 0),11)
            ui.setLabelString(self.rootItems.a_attr_num2,gameConfig.strings:string_common("attr_type",configdata2 and configdata2.attr2 or "def").."+"..(configdata2 and configdata2.init2 or 0),5)
            ui.setLabelString(self.rootItems.a_attr_num3,gameConfig.strings:string_common("attr_type",configdata3 and configdata3.attr3 or "hp").."+"..(configdata3 and configdata3.init3 or 0),3)
            setSpriteFrameByName(self.rootItems.a_attr_sprite1,"mochong_hong"..(configdata1 and configdata1.attr1 or "atk") )
            setSpriteFrameByName(self.rootItems.a_attr_sprite2,"mochong_hong"..(configdata2 and configdata2.attr2 or "def") )
            setSpriteFrameByName(self.rootItems.a_attr_sprite3,"mochong_hong"..(configdata3 and configdata3.attr3 or "hp") )
        else
            self.rootItems.attrNode:setVisible(false)
        end
    end


    if configdata.consume == nil or configdata.consume == "" or not config[tostring(nowlevel+1)] then
        -- 当魔宠达到最大阶级
        configdata = config[tostring(nowlevel)]

        --self.rootItems.nowStageNode:setPositionX(0)
        self.rootItems.nextStageNode:setVisible(false)

        self.rootItems.stageSpendNode:setVisible(false)
        self.rootItems.maxDescText:setVisible(false)
        self.rootItems.maxDesc:setVisible(true)

        ui.addGray("CCControlButton",self.rootItems.advanceBtn)

        ui.setLabelString(self.rootItems.advanceText,nil,19)
        self.rootItems.advanceBtn:setTouchPriority(-103)
        self.rootItems.advanceBtn:addHandleOfControlEvent(function()
            -- print("进阶")
           
            runGamePrompt({msg = "魔宠等级已达到上限，无法再进阶！"}) 

        end, CCControlEventTouchUpInside)
        
        return
    else
        --self.rootItems.nowStageNode:setPositionX(-270)
        self.rootItems.nextStageNode:setVisible(true)

        self.rootItems.stageSpendNode:setVisible(true)
        self.rootItems.maxDescText:setVisible(false)
        self.rootItems.maxDesc:setVisible(false)


        configdata = config[tostring(nowlevel+1)]
        ui.removeGray("CCControlButton",self.rootItems.advanceBtn)

    end


    if self.spendprops == nil or next(self.spendprops) == nil or self.spendprops == "" then
        print("spendprops==nil")
        return
    end
    
    -- print("configdata.end=====")
    -- printT(configdata)

    --todo
    if config["14"] then
        if nowlevel >= 7 and nowlevel < 10 then
            ui.setLabelString(self.rootItems.moredesc,"进至3阶可升红品",1)
        elseif nowlevel >= 10 and nowlevel < 14 then
            ui.setLabelString(self.rootItems.moredesc,"进阶至红品得红色技能点",1)
        else
            ui.setLabelString(self.rootItems.moredesc,"",1)
        end
    else
        ui.setLabelString(self.rootItems.moredesc,"",1)
    end

    -- 进阶之后信息
    ui.setLabelString(self.rootItems.next_qualityText,nil,13)
    ui.setLabelString(self.rootItems.next_talantskillText,nil,13)

    ui.setLabelString(self.rootItems.next_qualityLabel,gameConfig.strings:string_common("quality",tonumber(configdata.quality)),((configdata.quality and configdata.quality ~= 0) and configdata.quality or 1)*2)

    local talentconfig2 = gamedata.config.pet3_talentskill[tostring(configdata.talentskill)]

    ui.setLabelString(self.rootItems.next_talantLabel,talentconfig2.number,2)
    -- ui.setLabelString(self.rootItems.qualityLabel2,gameConfig.strings:string_common("quality",tonumber(configdata.quality)),2)
    
    --ui.setLabelString(self.rootItems.ActiveSkillLabel2,skillconfig[tostring(configdata.skillid)]["name"],((skillconfig.quality and skillconfig.quality ~= 0) and skillconfig.quality or 1)*2)

    local moquality = (configdata.quality and configdata.quality ~= 0) and configdata.quality or 1
    ui.setLabelString(self.rootItems.next_p_name,configdata.name,moquality>=7 and 213 or moquality*2-1)



    --todo
    if plusattr.num1+plusattr.num2+plusattr.num3+configdata.init1+configdata.init2+configdata.init3 > 0.00001 then
        ui.setLabelString(self.rootItems.next_p_attr1,gameConfig.strings:string_common("attr_type",plusattr.attr1).."：",13)
        ui.setLabelString(self.rootItems.next_p_num1,plusattr.num1,22)
        ui.setLabelString(self.rootItems.next_p_attr2,gameConfig.strings:string_common("attr_type",plusattr.attr2).."：",13)
        ui.setLabelString(self.rootItems.next_p_num2,plusattr.num2,22)
        ui.setLabelString(self.rootItems.next_p_attr3,gameConfig.strings:string_common("attr_type",plusattr.attr3).."：",13)
        ui.setLabelString(self.rootItems.next_p_num3,plusattr.num3,22)
        --
        if configdata.attr1 and configdata.attr1 ~= "" then
            ui.setLabelString(self.rootItems.next_p_num1,plusattr.num1.."  +"..configdata.init1,22)
        end
        if configdata.attr2 and configdata.attr2 ~= "" then
            ui.setLabelString(self.rootItems.next_p_num2,plusattr.num2.."  +"..configdata.init2,22)
        end
        if configdata.attr3 and configdata.attr3 ~= "" then
            ui.setLabelString(self.rootItems.next_p_num3,plusattr.num3.."  +"..configdata.init3,22)
        end
    else
        ui.setLabelString(self.rootItems.next_p_attr1,"",13)
        ui.setLabelString(self.rootItems.next_p_num1,"",22)
        ui.setLabelString(self.rootItems.next_p_attr2,"",13)
        ui.setLabelString(self.rootItems.next_p_num2,"",22)
        ui.setLabelString(self.rootItems.next_p_attr3,"",13)
        ui.setLabelString(self.rootItems.next_p_num3,"",22)
    end
    --


    --    local stringname = skillconfig[tostring(configdata.skillid)].icon
--    -- print("stringname==222",stringname)
--    setSpriteFrameByName(self.rootItems.i_icon_2, stringname)
--    self.rootItems.i_soulsprite_2:setVisible(false)


    -- 进化消耗
    local advanceSpendconfig = config[tostring(nowlevel)].consume
    local spenddata = ui.getIDandNUMs(advanceSpendconfig)
    printT(spenddata,"spenddata")
    self.spenddata = spenddata

    printT(self.petFragmentData,"self.petFragmentData")
    ui.setNewIcon(self.rootItems,{cid=spenddata[1].cid,num=(self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num or 0).."/"..spenddata[1].num},0)
    ui.setNewIcon(self.rootItems,{cid=spenddata[2].cid,num=(self.spendprops[tostring(spenddata[2].cid)] and self.spendprops[tostring(spenddata[2].cid)] or 0).."/"..spenddata[2].num},1)
    if spenddata[4] then
        ui.setNewIcon(self.rootItems,{cid=spenddata[4].cid,num=(self.spendprops[tostring(spenddata[4].cid)] and self.spendprops[tostring(spenddata[4].cid)] or 0).."/"..spenddata[4].num},2)
    end

    if self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num >= spenddata[1].num then
        ui.setLabelString(self.rootItems.i_num_1,nil,13)
    else
        ui.setLabelString(self.rootItems.i_num_1,nil,24)
        -- hongse
    end


    self.rootItems["i_button"]:setTouchPriority(-103)
    self.rootItems["i_button"]:addHandleOfControlEvent(function()

        gameWindows:openWindow("dropTips",{cid = spenddata[1].cid, num = (self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num or 0)},nil)

    end, CCControlEventTouchUpInside)

    self.rootItems["i_button_1"]:setTouchPriority(-103)
    self.rootItems["i_button_1"]:addHandleOfControlEvent(function()

        gameWindows:openWindow("dropTips",{cid = spenddata[2].cid, num=(self.spendprops[tostring(spenddata[2].cid)] and self.spendprops[tostring(spenddata[2].cid)] or 0)},nil)
    end, CCControlEventTouchUpInside)

    if spenddata[4] then
        self.rootItems["i_root_2"]:setVisible(true)
        self.rootItems["i_button_2"]:setTouchPriority(-103)
        self.rootItems["i_button_2"]:addHandleOfControlEvent(function()

        gameWindows:openWindow("dropTips",{cid = spenddata[4].cid, num=(self.spendprops[tostring(spenddata[4].cid)] and self.spendprops[tostring(spenddata[4].cid)] or 0)},nil)
        end, CCControlEventTouchUpInside)

        self.rootItems["i_root"]:setPositionX(-200)
        self.rootItems["i_root_1"]:setPositionX(0)
        self.rootItems["i_root_2"]:setPositionX(200)

    else
        self.rootItems["i_root"]:setPositionX(-100)
        self.rootItems["i_root_1"]:setPositionX(100)
        self.rootItems["i_root_2"]:setPositionX(300)
        self.rootItems["i_root_2"]:setVisible(false)
    end

    if self.petFragmentData[tostring(spenddata[1].cid)] then
        if self.petFragmentData[tostring(spenddata[1].cid)].num >= spenddata[1].num then
            ui.setLabelString(self.rootItems.i_num,nil,13)
        else
            ui.setLabelString(self.rootItems.i_num,nil,24)
            -- hongse
        end
    end

    if self.spendprops[tostring(spenddata[2].cid)] >= spenddata[2].num then
        ui.setLabelString(self.rootItems.i_num_1,nil,13)
    else
        ui.setLabelString(self.rootItems.i_num_1,nil,24)
        -- hongse
    end

    if spenddata[4] and spenddata[4].cid then
        if (self.spendprops[tostring(spenddata[4].cid)] or 0) >= spenddata[4].num then
            ui.setLabelString(self.rootItems.i_num_2,nil,13)
        else
            ui.setLabelString(self.rootItems.i_num_2,nil,24)
            -- hongse
        end
    end



    ui.setLabelString(self.rootItems.advanceSpendText,nil,13)

    if tonumber(GameScene.roleinfo.coin) >= tonumber(spenddata[3].num) then
        ui.setLabelString(self.rootItems.advanceSpendLabel,spenddata[3].num,13)
    else
        ui.setLabelString(self.rootItems.advanceSpendLabel,spenddata[3].num,24)
    end


    -- 进阶页面
    ui.setLabelString(self.rootItems.advanceText,nil,19)
    self.rootItems.advanceBtn:setTouchPriority(-103)
    self.rootItems.advanceBtn:addHandleOfControlEvent(function()
        -- print("进阶")
        gameTouch:clickprofbytime(1)
        local iidnum = self.petData.iid
        -- local iidnum = self.petdata.iid
        if self.advanceIid then
            -- print("背包跳转过来")
            iidnum = self.advanceIid
        end

        local nowlevel = self.petdata.pets[tostring(iidnum)].level
        local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(iidnum)].cid)] or {}
        local advanceSpendconfig = config[tostring(nowlevel)].consume
        -- print("advanceBtn===")
        if advanceSpendconfig == nil or advanceSpendconfig == "" then
            runGamePrompt({msg = "魔宠等级已达到上限，无法再进阶！"}) 
            return
        end

        
        if tonumber(GameScene.roleinfo.level) < tonumber(config[tostring(nowlevel)].level) then
           runGamePrompt({msg = "队伍达到"..(config[tostring(nowlevel)].level).."级，才能进阶到下级"}) 
           return
        end


        if self.petFragmentData[tostring(spenddata[1].cid)]== nil or self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num < spenddata[1].num or self.spendprops[tostring(spenddata[2].cid)] < spenddata[2].num then
            runGamePrompt({msg = "进阶材料不足"}) 
            return
        end

        if spenddata[4] and spenddata[4].cid then
            if (self.spendprops[tostring(spenddata[4].cid)] or 0) < spenddata[4].num then
                runGamePrompt({msg = "进阶材料不足"})
                return
            end
        end

        if tonumber(GameScene.roleinfo.coin) < tonumber(spenddata[3].num) then
           --runGamePrompt({msg = "进阶银币不足"})
            shortCoin()
           return
        end

        UIRequest({type = 1046,iid = iidnum,spenddata = spenddata})


    end, CCControlEventTouchUpInside)




end


function devourcollectjinjie.getSpendPropsData(self,data,status)
        print("getSpendPropsData,",status)

    if status then
        -- print("status====getSpendPropsData,",status)
        self.update = true
    end
    self.spendprops = data

    self:reload()

    self:setHashitData()
end


function devourcollectjinjie.getMochongFragmentData(self,data)
    print("getMochongFragmentData===")
    printT(data)
    self.petFragmentData = data

end

function devourcollectjinjie.effectAction(self)
    print("effectAction==")
    local effectNode, effectItems = CCBReaderLoad("UIEffect/mochong/mochongjinjie", nil, true, "mofujinjie")
    self.rootItems.effectNode:addChild(effectNode)

    self.animationManager = getAnimationManager(effectItems)
    self.animationManager:setAnimationCompletedCallback(function()
        print("complete")
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        
    end)
    self.animationManager:runAnimationsForSequenceNamed("mochongjinjie")
    
    -- local iidnum = self.petdata.iid
    local iidnum = self.petData.iid

    if self.advanceIid then
        -- print("背包跳转过来")
        iidnum = self.advanceIid
    end

    local nowlevel = self.petdata.pets[tostring(iidnum)].level
    local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(iidnum)].cid)] or {}

    local skillconfig = gamedata.config.combskill or {}
    local skillid = config[tostring(nowlevel)].skillid
    local beforLevel = nowlevel + 1
    local befSkillId = config[tostring(beforLevel)] and config[tostring(beforLevel)].skillid 
    if befSkillId and (befSkillId ~= skillid) then
        runGamePrompt({msg = ("魔宠技能："..skillconfig[tostring(config[tostring(nowlevel)].skillid)]["name"].."升级")}) 
    end
end




function devourcollectjinjie.setHashitData(self)

    if self.petdata and self.petData and self.petdata.iid and self.petData.iid and self.petdata.pets[tostring(self.petdata.iid)] then
    else
        return
    end

    local iidnum = self.petData.iid

    local nowlevel = self.petdata.pets[tostring(iidnum)].level

    local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(iidnum)].cid)] or {}
    local advanceSpendconfig = config[tostring(nowlevel)].consume
    local spenddata = ui.getIDandNUMs(advanceSpendconfig)
    printT(spenddata,"spenddata===")

    local hashit = false

    if self.spendprops == nil or next(self.spendprops) == nil or self.spendprops == "" then
        print("spendprops==nil")
        hashit = false
        GameScene.layers["devil"].module:setHint("jinjie",hashit)
        return
    end
    
    if spenddata[1] and spenddata[2] and spenddata[3] and self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num >= spenddata[1].num and self.spendprops and self.spendprops[tostring(spenddata[2].cid)] and self.spendprops[tostring(spenddata[2].cid)] >= spenddata[2].num and tonumber(GameScene.roleinfo.coin) >= tonumber(spenddata[3].num) then
        -- ui.setLabelString(self.rootItems.i_num_3,nil,13)
        print("spenddata1=true")
        if spenddata[4] and (self.spendprops[tostring(spenddata[4].cid)] or 0) < spenddata[4].num then
            hashit = false
        else
            hashit = true
        end
    else
        print("spenddata1=false")
        -- ui.setLabelString(self.rootItems.i_num_3,nil,24)
        hashit = false
        -- hongse
    end

    print("hitn===",hashit)
    GameScene.layers["devil"].module:setHint("jinjie",hashit)
    -- ui.sethint(self.rootItems["stage_hint"],hashit)

end


function devourcollectjinjie.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootItems = nil
    self.rootNode = nil

    self.petData = {}
    self.petFragment = {}
    self.xprop = {}
    self.beforecid = 0
    self.petdata = {}
end


return devourcollectjinjie   �l  