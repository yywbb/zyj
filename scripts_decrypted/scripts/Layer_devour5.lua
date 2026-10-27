--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--

local devour = {


    resource = nil,

    rootNode = nil,
    rootItems = nil,

    advanceIid = nil,

    pages = {"firstNode","mainNode","advanceNode"},
    choosepage = "firstNode",
    update = false,
}

function devour.init(self,parent,toppos,param)
    self.advanceIid = param
    -- print("param===",param)

    self.rootNode,self.rootItems = CCBReaderLoad("mochong3/mochong3", nil, true, "mochong3")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if self.rootItems.bgnode then
        self.rootItems.bgnode:setPositionY((toppos-1620)*0.22)
    end

    if self.rootItems.mainTopNode then
        self.rootItems.mainTopNode:setPositionY(toppos)
    end
    if self.rootItems.advanceTopNode then
        self.rootItems.advanceTopNode:setPositionY(toppos-980)
    end

    guide.controller:addComplete(49,function()
        UIRequest({type = 2882,opt=1,sysID=49})
    end)
    
    -- 魔宠碎片查询
    UIRequest({type = 1044})
    -- 魔宠查询
    UIRequest({type = 1040})

end

function devour.initjinjie(self,parent,toppos,param)
   

end


function devour.reload(self,data)
    -- self:setPet()
    self.petdata = data
    GameScene.layers["devil"].module:pageDataSend("mochongdata",{petsData = self.petdata, petFragmentData = self.petFragmentData})
    -- 主界面
    ui.setLabelString(self.rootItems.aboutText,nil,21)
    self.rootItems.aboutBtn:setTouchPriority(-103)
    self.rootItems.aboutBtn:addHandleOfControlEvent(function()
        -- print("说明")
        -- self:shiftNode("firstNode")
        gameWindows:openWindow("devilSkill","explain")
    end, CCControlEventTouchUpInside)

    -- 图鉴
    ui.setLabelString(self.rootItems.tujianText,nil,21)
    self.rootItems.tujianBtn:setTouchPriority(-103)
    self.rootItems.tujianBtn:addHandleOfControlEvent(function()
        print("图鉴")
        -- self:shiftNode("firstNode")
        -- gameWindows:openWindow("devilSkill","explain")
        GameScene:shiftLayer("devilcollect",nil,{petsData = self.petdata, petFragmentData = self.petFragmentData})

    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.bagText,nil,21)
    self.rootItems.bagBtn:setTouchPriority(-103)
    self.rootItems.bagBtn:addHandleOfControlEvent(function()
        -- print("背包")
        -- self:shiftNode("mainNode")
        GameScene:shiftLayer("devilBag",nil,{petsData = self.petdata,petsChipData = self.petFragmentData})
    end, CCControlEventTouchUpInside)

    -- ui.setLabelString(self.rootItems.gotoAdvanceText,nil,19)
    self.rootItems.gotoAdvanceBtn:setTouchPriority(-103)
    self.rootItems.gotoAdvanceBtn:addHandleOfControlEvent(function()
        -- print("去进阶页面")
        -- local iidnum = self.petdata.iid
        -- if self.advanceIid then
        --     -- print("背包跳转过来")
        --     iidnum = self.advanceIid
        -- end

        -- local nowlevel = self.petdata.pets[tostring(iidnum)].level
        -- local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(iidnum)].cid)] or {}
        -- local advanceSpendconfig = config[tostring(nowlevel)].consume
        -- print("gotoAdvanceBtn===nowlevel",nowlevel)
        -- printT(config[tostring(nowlevel)])
        -- if advanceSpendconfig == nil or advanceSpendconfig == "" then
        --     runGamePrompt({msg = "魔宠等级已达到上限，无法再进阶！"}) 
        --     return
        -- end

        self:shiftNode("advanceNode")

    end, CCControlEventTouchUpInside)

    self.rootItems.devour:setVisible(false)

    ui.setLabelString(self.rootItems.skillStudyText,nil,19)
    self.rootItems.skillStudyBtn:setTouchPriority(-103)
    self.rootItems.skillStudyBtn:addHandleOfControlEvent(function()
        -- print("技能学习")
        -- self:shiftNode("advanceNode")
        local maxlevelnum = 0

        local nowlevel = self.petdata.pets[tostring(self.petdata.iid)].level
        local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(self.petdata.iid)].cid)] or {}

        local talentskillconfig = gamedata.config.pet3_talentskill

        local jihuoNum = 0
        for k,v in pairs(self.petdata.pets) do
            -- print("for====,",v.cid)
            -- printT(v)
            local config = gamedata.config.pet3_attr[tostring(v.cid)] or {}
            local numx = talentskillconfig[tostring(config[tostring(v.level)].talentskill)].number
            -- print("numx ===",numx)
            if numx > jihuoNum then
                jihuoNum = numx
            end
        end
        

        -- local jihuoNum =  talentskillconfig[tostring(config[tostring(nowlevel)].talentskill)].number

        local globalconfig = gamedata.config.global_kv
        local limitLevelNum = globalconfig.pet3_passiveskill_limit.value

        -- print("limitNum===231-",jihuoNum,limitLevelNum)

        for k,v in pairs(self.passiveskilldata) do
            if tonumber(v.level) >= tonumber(limitLevelNum) then
                maxlevelnum = maxlevelnum + 1
            end
        end
        -- print("maxlevelnum===",maxlevelnum)

        if maxlevelnum >= jihuoNum then
            runGamePrompt({msg = "所有开启技能已达到最高等级，请重置后再学习"})
        elseif tonumber(self.nowskillpoint) >= tonumber(globalconfig.pet3_passiveskill_spot.value) then
            UIRequest({type = 1048})
        else
            runGamePrompt({msg = "技能点数不足，请提升队伍等级"})
        end


        

    end, CCControlEventTouchUpInside)
    
    ui.setLabelString(self.rootItems.skillResetText,nil,19)
    self.rootItems.skillResetBtn:setTouchPriority(-103)
    self.rootItems.skillResetBtn:addHandleOfControlEvent(function()
        -- print("技能重置")
        local skillnum = 0
        local locknum = 0
        for k,v in pairs(self.passiveskilldata) do
            -- print(k,v)
            if v.cid ~= 0 then
                skillnum = skillnum + 1
            end
            if v.lock ~= 0 then
                locknum = locknum + 1
            end
        end
        -- print("skillnum==lock=",skillnum,locknum)

        if skillnum == 0 then
            runGamePrompt({msg = "没有技能可以重置"})
            return
        elseif locknum >= skillnum  then
            runGamePrompt({msg = "技能全部锁定，无法重置"})
            return
        end
        gameWindows:openWindow("devourDetails",{data = self.passiveskilldata,index = "reset"})
    end, CCControlEventTouchUpInside)

    self.rootItems.skillPreviewBtn:setTouchPriority(-103)
    self.rootItems.skillPreviewBtn:addHandleOfControlEvent(function()
        -- print("技能预览")
        -- printT(self.passiveskilldata)
        gameWindows:openWindow("devilSkill",{petdata = self.petdata,skillpoint = self.passiveskilldata})
    end, CCControlEventTouchUpInside)

    self.rootItems.scoreruleBtn:setTouchPriority(-103)
    self.rootItems.scoreruleBtn:addHandleOfControlEvent(function()
        -- print("技能点获取途径说明")
        -- printT(self.passiveskilldata)
        gameWindows:openWindow("devourDetails",{data = {},index = "score"})
    end, CCControlEventTouchUpInside)

    self.rootItems.scorerule2Btn:setSwallowsTouch(true)
    self.rootItems.scorerule2Btn:setTouchPriority(-103)
    self.rootItems.scorerule2Btn:addHandleOfControlEvent(function()
        -- print("技能点获取途径说明")
        -- printT(self.passiveskilldata)
        gameWindows:openWindow("devourDetails",{data = {},index = "score"})
    end, CCControlEventTouchUpInside)
    
    


    self.rootItems.selectBtn:setTouchPriority(-103)
    self.rootItems.selectBtn:addHandleOfControlEvent(function()
        -- print("点击角色")
        -- self:shiftNode("firstNode")
        if self.choosepage == "mainNode" then
            gameWindows:openWindow("devourDetails",{data = self.petdata,index = "details"})
            -- gameWindows:openWindow("devourDetails",{data = self.petdata.pets[tostring(self.petdata.iid)],index = "info"})

        end
        
    end, CCControlEventTouchUpInside)
    
    

    -- 初始界面
    self.rootItems.addMochongBtn:setSwallowsTouch(true)
    self.rootItems.addMochongBtn:setTouchPriority(-103)
    self.rootItems.addMochongBtn:addHandleOfControlEvent(function()
        -- print("添加魔宠")
        -- self:shiftNode("mainNode")
        -- GameScene:shiftLayer("devourList","up",self.petdata)
        gameWindows:openWindow("devourSelect",{data = self.petdata})
        
    end, CCControlEventTouchUpInside)


    -- 消耗品数量获取
    local iidnum = self.petdata.iid

    if self.advanceIid then
        -- print("背包跳转过来")
        iidnum = self.advanceIid
    end
    if iidnum ~= 0 then
        local nowcid = self.petdata.pets[tostring(iidnum)].cid
        local nowlevel = self.petdata.pets[tostring(iidnum)].level

        local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(iidnum)].cid)] or {}
        local advanceSpendconfig = config[tostring(nowlevel)].consume
        local spenddata = ui.getIDandNUMs(advanceSpendconfig)

        if advanceSpendconfig == nil or advanceSpendconfig == "" then
            -- self:setHashitData()
            ui.sethint(self.rootItems["stage_hint"],false)
        else
            if spenddata[4] and spenddata[4].cid then
                UIRequest({type = 12001, cids = {spenddata[2].cid,spenddata[4].cid}, order = 12341})
            else
                UIRequest({type = 12001, cids = {spenddata[2].cid}, order = 12341})
            end
        end

        
    end
    


    if self.petdata.iid == 0 then
        self.choosepage = "firstNode"
    elseif self.advanceIid then
        self.choosepage = "advanceNode"
    else
        self.choosepage = "mainNode"
    end
    

    self:shiftNode(self.choosepage)

    -- 被动技能查询
    UIRequest({type = 1047})
end

function devour.refreshFunc(self)
    print("devour.refreshFunc")
    -- self.choosepage = "advanceNode"
    -- self:shiftNode(self.choosepage)
    -- self:advanceReload()
    -- GameScene.layers["devil"].module:pageDataCallback("jinjie","shiftNode","advanceNode")
end

function devour.shiftNode(self,type)
    -- print("i...am..shiftNode",type)

    self.choosepage = type
    if type == "firstNode" then
        self.rootItems.nameNode:setVisible(false)
        self.rootItems.mainTopNode:setVisible(true)
        self.rootItems.mainTopNode:setPositionX(540)
    elseif type == "mainNode" then
        self.rootItems.nameNode:setVisible(true)
        self.rootItems.mainTopNode:setVisible(true)
        self.rootItems.mainTopNode:setPositionX(540)
    else
        self.rootItems.nameNode:setVisible(false)
        self.rootItems.mainTopNode:setVisible(false)
        self.rootItems.mainTopNode:setPositionX(9999)
    end

    
    for k,v in ipairs(self.pages) do
        if v == self.choosepage then
            self.rootItems[v]:setPositionX(540)
            self.rootItems[v]:setVisible(true)
        else
            self.rootItems[v]:setPositionX(9999)
            self.rootItems[v]:setVisible(false)
        end
    end
    if type == "firstNode" then
        -- print("firstNode...is....")

    elseif type == "mainNode" then
        self:mainReload()
    elseif type == "advanceNode" then

        self:advanceReload()
    end

end

function devour.getMochongFragmentData(self,data)
    print("getMochongFragmentData===")
    -- printT(data)
    self.petFragmentData = data
    GameScene.layers["devil"].module:pageDataSend("mochongdata",{petsData = self.petdata, petFragmentData = self.petFragmentData})

end

function devour.getSpendPropsData(self,data,status)
    -- print("getSpendPropsData===")
    if status then
        -- print("status====getSpendPropsData,",status)
        self.update = true
    end
    self.spendprops = data

    self:advanceReload()

    self:setHashitData()
end


function devour.mainReload(self,data)
    -- print("iid====",self.petdata.iid)
    -- print("cid====",self.petdata.pets[tostring(self.petdata.iid)].cid)
    -- printT(self.petdata)
    ui.setLabelString(self.rootItems.remindText,nil,21)

    ui.setLabelString(self.rootItems.markDescText,nil,21)


    local iidnum = self.petdata.iid
    local nowcid = self.petdata.pets[tostring(self.petdata.iid)].cid
    local nowlevel = self.petdata.pets[tostring(self.petdata.iid)].level
    local nowdevourlevel = self.petdata.pets[tostring(self.petdata.iid)].devourlevel or 0
    local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(self.petdata.iid)].cid)] or {}

    -- 魔宠显示设置
    local moquality = (config[tostring(nowlevel)].quality and config[tostring(nowlevel)].quality ~= 0) and config[tostring(nowlevel)].quality or 1
    ui.setLabelString(self.rootItems.mochongnameLabel,config[tostring(nowlevel)].name,moquality>=7 and 213 or moquality*2-1)
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

    local skillconfig = gamedata.config.combskill or {}
    if config[tostring(nowlevel)].skillid and config[tostring(nowlevel)].skillid > 0 then
        local nowSkillConfig = skillconfig[tostring(config[tostring(nowlevel)].skillid)]
        if nowSkillConfig.quality >= 7 then
            ui.setLabelString(self.rootItems.activeSkillNameLabel, nowSkillConfig["name"]..": ", 213)
        else
            ui.setLabelString(self.rootItems.activeSkillNameLabel, nowSkillConfig["name"]..": ", ((nowSkillConfig.quality and nowSkillConfig.quality ~= 0) and nowSkillConfig.quality or 1)*2)
        end
        ui.setLabelString(self.rootItems.activeSkillDescLabel, gameConfig.strings:skillEffectDesc(nowSkillConfig), 13)
        self.rootItems.markDescText:setVisible(true)
        self.rootItems.markDescText:setPositionX(self.rootItems.activeSkillNameLabel:getPositionX() + self.rootItems.activeSkillNameLabel:getContentSize().width)
        -- 主页面设置 主动技能icon
        local stringname = nowSkillConfig.icon
        -- print("stringname==",stringname)
        setSpriteFrameByName(self.rootItems.i_icon, stringname)
        self.rootItems.i_soulsprite:setVisible(false)
    end

    local talentskillconfig = gamedata.config.pet3_talentskill
    local globalconfig = gamedata.config.global_kv
    local skillpointconfig = gamedata.config.pet3_skillpoints
    -- printT(skillpointconfig)
    -- print("level====",GameScene.roleinfo.level)


    ui.setLabelString(self.rootItems.jihuoText, nil,30)
    ui.setLabelString(self.rootItems.jihuoNumLabel, talentskillconfig[tostring(config[tostring(nowlevel)].talentskill)].number,6)

    ui.setLabelString(self.rootItems.skillLevelText, nil,30)
    ui.setLabelString(self.rootItems.skillLevelLabel, globalconfig.pet3_passiveskill_limit.value,6)

    ui.setLabelString(self.rootItems.nowSkillPointText, nil,30)
    -- ui.setLabelString(self.rootItems.nowSkillPointLabel, skillpointconfig[tostring(GameScene.roleinfo.level)]["number"],4)


    -- ui.setLabelString(self.rootItems.resetGoldLabel, globalconfig.pet3_passiveskill_cost.value,4)

    --plus num
    ui.setLabelString(self.rootItems.plusLab,nil,1)
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
    if plusattr.num1+plusattr.num2+plusattr.num3 > 0.00001 then      --float   todo
        self.rootItems.PlusNode:setVisible(true)
        ui.setLabelString(self.rootItems.plusAttr1,gameConfig.strings:string_common("attr_type",plusattr.attr1).."：",13)
        ui.setLabelString(self.rootItems.plusNum1,plusattr.num1,13)
        ui.setLabelString(self.rootItems.plusAttr2,gameConfig.strings:string_common("attr_type",plusattr.attr2).."：",13)
        ui.setLabelString(self.rootItems.plusNum2,plusattr.num2,13)
        ui.setLabelString(self.rootItems.plusAttr3,gameConfig.strings:string_common("attr_type",plusattr.attr3).."：",13)
        ui.setLabelString(self.rootItems.plusNum3,plusattr.num3,13)
    else
        self.rootItems.PlusNode:setVisible(false)
    end


end


function devour.setHashitData(self)
    if self.petdata and self.petdata.iid and self.petdata.pets[tostring(self.petdata.iid)] then
    else
        return
    end
    local nowlevel = self.petdata.pets[tostring(self.petdata.iid)].level

    local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(self.petdata.iid)].cid)] or {}
    local advanceSpendconfig = config[tostring(nowlevel)].consume
    local spenddata = ui.getIDandNUMs(advanceSpendconfig)
    printT(spenddata,"spenddata===")

    local hashit = false

    if spenddata[1] and spenddata[2] and spenddata[3] and self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num >= spenddata[1].num and self.spendprops[tostring(spenddata[2].cid)] >= spenddata[2].num and tonumber(GameScene.roleinfo.coin) >= tonumber(spenddata[3].num) then
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


    local globalconfig = gamedata.config.global_kv
    if self.nowskillpoint and tonumber(self.nowskillpoint) >= tonumber(globalconfig.pet3_passiveskill_spot.value) then
        GameScene.layers["devil"].module:setHint("mochong",true)
    else
        GameScene.layers["devil"].module:setHint("mochong",false)
    end
end


function devour.effectAction(self)
    print("effectAction==")
    local effectNode, effectItems = CCBReaderLoad("UIEffect/mochong/mochongjinjie", nil, true, "mofujinjie")
    self.rootItems.effectNode:addChild(effectNode)

    self.animationManager = getAnimationManager(effectItems)
    self.animationManager:setAnimationCompletedCallback(function()
        print("complete")
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        
    end)
    self.animationManager:runAnimationsForSequenceNamed("mochongjinjie")
    
    local iidnum = self.petdata.iid

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


function devour.advanceReload(self,data)
    -- self.spendprops = data
    print("spendprops====")
    printT(self.petdata)

    ui.setLabelString(self.rootItems.moredesc,"",1)

    self.rootItems.closeButton:setTouchPriority(-103)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        -- print("返回")
        if self.advanceIid then
            GameScene:shiftLayer("devilBag","up",{petsData = self.petdata,petsChipData = self.petFragmentData})
        else
            self:shiftNode("mainNode")
        end  
        
        self.advanceIid = nil

    end, CCControlEventTouchUpInside)

    self.rootItems.stageViewButton:setTouchPriority(-103)
    self.rootItems.stageViewButton:addHandleOfControlEvent(function()
        -- print("返回")
        local nowiid = self.petdata.iid
        if self.advanceIid then
            nowiid = self.advanceIid
        end


        local petdata = {}

        for k,v in pairs(self.petdata.pets) do
            if tonumber(v.iid) == tonumber(nowiid) then
                petdata = v
                break
            end
        end


        gameWindows:openWindow("devourDetails",{data = petdata,index = "stageinfo"})

    end, CCControlEventTouchUpInside)


    local iidnum = self.petdata.iid

    if self.advanceIid then
        -- print("背包跳转过来")
        iidnum = self.advanceIid
    end


    local nowcid = self.petdata.pets[tostring(iidnum)].cid
    local nowlevel = self.petdata.pets[tostring(iidnum)].level

    local config = gamedata.config.pet3_attr[tostring(self.petdata.pets[tostring(iidnum)].cid)] or {}
    local configdata = config[tostring(nowlevel)]

    local talentconfig = gamedata.config.pet3_talentskill[tostring(configdata.talentskill)]

    local skillconfig = gamedata.config.combskill or {}

    -- 魔宠显示设置
    local moquality = (config[tostring(nowlevel)].quality and config[tostring(nowlevel)].quality ~= 0) and config[tostring(nowlevel)].quality or 1
    ui.setLabelString(self.rootItems.mochongnameLabel,config[tostring(nowlevel)].name,moquality>=7 and 213 or moquality*2-1)
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


    -- 当前信息
    ui.setLabelString(self.rootItems.qualityText,nil,13)
    ui.setLabelString(self.rootItems.talantskillText,nil,13)
    -- ui.setLabelString(self.rootItems.mochongnameLabel,config[tostring(nowlevel)].name,((config[tostring(nowlevel)].quality and config[tostring(nowlevel)].quality ~= 0) and config[tostring(nowlevel)].quality or 1)*2-1)
          
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

    --local stringname = skillconfig[tostring(configdata.skillid)].icon
    -- print("stringname==",stringname)
    --setSpriteFrameByName(self.rootItems.i_icon_1, stringname)
    --self.rootItems.i_soulsprite_1:setVisible(false)
    -- qualityText1
    -- talantskillText1
    -- qualityLabel1
    -- talantLabel1
    -- ActiveSkillLabel1
    -- print("configdata.end=====")
    -- printT(configdata)
    if configdata.consume == nil or configdata.consume == "" or not config[tostring(nowlevel+1)] then
        -- 当魔宠达到最大阶级
        configdata = config[tostring(nowlevel)]

        --self.rootItems.nowStageNode:setPositionX(0)
        self.rootItems.nextStageNode:setVisible(false)

        self.rootItems.stageSpendNode:setVisible(false)
        self.rootItems.maxDescText:setVisible(true)

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

        configdata = config[tostring(nowlevel+1)]
        ui.removeGray("CCControlButton",self.rootItems.advanceBtn)

    end

    if self.spendprops == nil or next(self.spendprops) == nil or self.spendprops == "" then
        -- print("spendprops==nil")
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

    ui.setNewIcon(self.rootItems,{cid=spenddata[1].cid,num=(self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num or 0).."/"..spenddata[1].num},1)
    ui.setNewIcon(self.rootItems,{cid=spenddata[2].cid,num=(self.spendprops[tostring(spenddata[2].cid)] and self.spendprops[tostring(spenddata[2].cid)] or 0).."/"..spenddata[2].num},2)

    if spenddata[4] and spenddata[4].cid then
        ui.setNewIcon(self.rootItems,{cid=spenddata[4].cid,num=(self.spendprops[tostring(spenddata[4].cid)] and self.spendprops[tostring(spenddata[4].cid)] or 0).."/"..spenddata[4].num},3)
        self.rootItems.stageSpendProp3:setVisible(true)
        self.rootItems.stageSpendProp1:setPositionX(-200)
        self.rootItems.stageSpendProp2:setPositionX(0)
        self.rootItems.stageSpendProp3:setPositionX(200)
    else
        self.rootItems.stageSpendProp3:setVisible(false)
        self.rootItems.stageSpendProp1:setPositionX(-100)
        self.rootItems.stageSpendProp2:setPositionX(100)
        self.rootItems.stageSpendProp3:setPositionX(300)
    end
    -- printT(self.rootItems)
    if self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num >= spenddata[1].num then
        ui.setLabelString(self.rootItems.i_num_1,nil,13)
    else
        ui.setLabelString(self.rootItems.i_num_1,nil,24)
        -- hongse
    end


    self.rootItems["i_button_6"]:setTouchPriority(-103)
    self.rootItems["i_button_6"]:addHandleOfControlEvent(function()

        gameWindows:openWindow("dropTips",{cid = spenddata[1].cid, num = (self.petFragmentData[tostring(spenddata[1].cid)] and self.petFragmentData[tostring(spenddata[1].cid)].num or 0)},nil)

    end, CCControlEventTouchUpInside)

    self.rootItems["i_button_7"]:setTouchPriority(-103)
    self.rootItems["i_button_7"]:addHandleOfControlEvent(function()

        gameWindows:openWindow("dropTips",{cid = spenddata[2].cid, num=(self.spendprops[tostring(spenddata[2].cid)] and self.spendprops[tostring(spenddata[2].cid)] or 0)},nil)
    end, CCControlEventTouchUpInside)

    self.rootItems["i_button_8"]:setTouchPriority(-103)
    self.rootItems["i_button_8"]:addHandleOfControlEvent(function()

        gameWindows:openWindow("dropTips",{cid = spenddata[4].cid, num=(self.spendprops[tostring(spenddata[4].cid)] and self.spendprops[tostring(spenddata[4].cid)] or 0)},nil)
    end, CCControlEventTouchUpInside)

   
    if self.spendprops[tostring(spenddata[2].cid)] >= spenddata[2].num then
        ui.setLabelString(self.rootItems.i_num_2,nil,13)
    else
        ui.setLabelString(self.rootItems.i_num_2,nil,24)
        -- hongse
    end

    if spenddata[4] and spenddata[4].cid then
        if (self.spendprops[tostring(spenddata[4].cid)] or 0) >= spenddata[4].num then
            ui.setLabelString(self.rootItems.i_num_3,nil,13)
        else
            ui.setLabelString(self.rootItems.i_num_3,nil,24)
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
        local iidnum = self.petdata.iid
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


function devour.passiveSkillReload(self,data,status)
    if status then
        -- print("status====,passiveSkillReload",status)
        self.update = true
    end
    -- print("passiveskilldata...enter")
    -- printT(data)
    self.nowskillpoint = data.nowskillpoint or 0
    self.nowskillpoint2 = data.nowskillpoint2 or 0
    self.nowskillpoint3 = data.nowskillpoint3 or 0
    self.passiveskilldata = {}

    ui.setLabelString(self.rootItems.nowSkillPointLabel, self.nowskillpoint or 0,4,29)
    ui.setLabelString(self.rootItems.nowSkillPointLabel2, "( "..(self.nowskillpoint2 or 0).." )",11,29)
    ui.setLabelString(self.rootItems.nowSkillPointLabel3, "( "..(self.nowskillpoint3 or 0).." )",213,29)

    local passiveskillconfig = gamedata.config.pet3_passiveskill

    for k,v in pairs(data.skill) do
        self.passiveskilldata[tonumber(k)]=v
    end
    -- printT(self.passiveskilldata)

    local nowlocknum = 0
    for i,v in ipairs(self.passiveskilldata) do
        local key_Ex
        if (i-1) == nil or (i-1) == 0 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end

        -- if v.cid ~= 0 then
            self.rootItems["in_close"..key_Ex]:setVisible(true)
            self.rootItems["in_lock"..key_Ex]:setVisible(true)

            if v.lock == 0 then
                self.rootItems["in_lock"..key_Ex]:setVisible(false)
            else
                nowlocknum = nowlocknum + 1
                self.rootItems["in_lock"..key_Ex]:setVisible(true)
            end

            if v.status == 0 then
                -- 未开启

                ui.setNewIconName(self.rootItems,{cid = v.cid},(i-1))

                self.rootItems["in_close"..key_Ex]:setVisible(true)
                self.rootItems["in_name"..key_Ex]:setString("未开启")

            elseif v.status == 1 then
                -- 开启未激活
                if v.cid == 0 then
                    ui.setNewIconName(self.rootItems,{cid = v.cid},(i-1))
                    self.rootItems["in_name"..key_Ex]:setString("未学习")
                else
                    local config = passiveskillconfig[tostring(v.cid)]
                    local string = {}
                    if config.attr == "critical" or config.attr == "resilience" or config.attr == "parry" or config.attr == "arp" or config.attr == "dodge" or config.attr == "hit" or config.attr == "criticaldmg" then
                        -- print("is...percent",config.attr)
                        string =  gameConfig.strings:string_common("attr_type",config.attr)..(tonumber(config.init+config.init_grow*(v.level-1))*100).."%" or {}
                    else
                        -- print("is...value",config.attr)
                        string =  gameConfig.strings:string_common("attr_type",config.attr)..(config.init+config.init_grow*(v.level-1)) or {}
                    end
                     
                    -- print("string===",string)
                    ui.setNewIconName(self.rootItems,{cid = v.cid,num = "LV:"..v.level},(i-1))

                    local config = table.merge(ui.IDconfig(v.cid) or {},config)
                    if config.quality >= 7 then
                        ui.setLabelString(self.rootItems["in_name"..key_Ex],string,213)
                    else
                        ui.setLabelString(self.rootItems["in_name"..key_Ex],string,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
                    end
                    -- self.rootItems["in_name"..key_Ex]:setString(string)

                end

                self.rootItems["in_close"..key_Ex]:setVisible(true)
                
            elseif v.status == 2 then
                -- 开启且激活
                print("开启且激活")
                if v.cid == 0 then
                    ui.setNewIconName(self.rootItems,{cid = v.cid},(i-1))
                    self.rootItems["in_name"..key_Ex]:setString("未学习")
                else
                    local config = passiveskillconfig[tostring(v.cid)]
                    local string = {}
                    if config.attr == "critical" or config.attr == "resilience" or config.attr == "parry" or config.attr == "arp" or config.attr == "dodge" or config.attr == "hit" or config.attr == "criticaldmg" then
                        -- print("is...percent",config.attr)
                        string =  gameConfig.strings:string_common("attr_type",config.attr)..(tonumber(config.init+config.init_grow*(v.level-1))*100).."%" or {}
                    else
                        -- print("is...value",config.attr)
                        string =  gameConfig.strings:string_common("attr_type",config.attr)..(config.init+config.init_grow*(v.level-1)) or {}
                        end
                    -- print("string===",string)
                    ui.setNewIconName(self.rootItems,{cid = v.cid,num = "LV:"..v.level},(i-1))

                    local config = table.merge(ui.IDconfig(v.cid) or {},config)
                    ui.setLabelString(self.rootItems["in_name"..key_Ex],string,((config.quality and config.quality ~= 0) and config.quality or 1)*2-1)
                    -- self.rootItems["in_name"..key_Ex]:setString(string)
                end
                

                self.rootItems["in_close"..key_Ex]:setVisible(false)
            end

            self.rootItems["in_button"..key_Ex]:setTouchPriority(-103)
            self.rootItems["in_button"..key_Ex]:addHandleOfControlEvent(function()
                -- print("技能锁定")
                -- self:shiftNode("advanceNode")
--                local locknum = tonumber(gamedata.config.global_kv.pet3_passiveskill_lock.value)
--                -- print("locknum==",locknum,nowlocknum)
                if v.status ~= 0 and v.cid ~= 0  then
--                    if nowlocknum >= locknum and v.lock == 0 then
--                        -- print("锁定达到最大数")
--                        runGamePrompt({msg = "技能锁定达到最大数"})
--                    else
--                        UIRequest({type = 1060,id = i,lock = v.lock})
--                    end
--                    -- 开启 且 有技能
                    --todo
                    gameWindows:openWindow("devilSkillDetail",{skillIndex = i, list = passiveskillconfig[tostring(v.cid)],skill = self.passiveskilldata,opt = 1,nowskillpoint = self.nowskillpoint,nowskillpoint2 = self.nowskillpoint2,nowskillpoint3 = self.nowskillpoint3,level = v.level or 1})
                end

            end, CCControlEventTouchUpInside)
    end


    local locknum = 0
    for k,v in pairs(self.passiveskilldata) do
        if v.lock ~= 0 then
            locknum = locknum + 1
        end
    end
    -- print("locknum===1==",locknum)

    local spendnum = 0
    local globalconfig = gamedata.config.global_kv
    if locknum == 0 then
        spendnum =  tonumber(globalconfig.pet3_passiveskill_cost.value or 0)
    else
        spendnum =  tonumber(globalconfig.pet3_passiveskill_cost.value or 0) + tonumber(globalconfig["pet3_passiveskill_cost"..locknum].value or 0)
    end

    ui.setLabelString(self.rootItems.resetGoldLabel, spendnum,4)
    self:setHashitData()

end

function devour.clear(self)
    print("status====clear,",self.update)
    if self.update then
        --UIRequest({type = 1002, param = "devil"})
    end
    if self.rootItems.mochongNode then
        self.rootItems.mochongNode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = nil
    end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootItems = nil
    self.rootNode = nil

    

    self.advanceIid = nil
end


return devour
   ��  