--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--

local wing_main = {


    resource = nil,

    rootNode = nil,
    rootItems = nil,

    wingdata = {},
    spendPropsData = {},

    firstnum = 0,
    starupNum = 0,--是否升级

    stagefirstnum = 0,--进阶进度条初始位置

    oldexp = 0, --上一级经验

    poptimes = 0, --升星经验滚动次数
    labnum = 0, --升星消耗次数记录（滚动一次＋1

    isselect = false,


    pages = {"first","starup","stageup","max"},
    choosepage = "first",
    update = false,

    isUseEffect = false,
}

function wing_main.init(self,parent,toppos,param)

    self.rootNode,self.rootItems = CCBReaderLoad("wing/wing", nil, true, "wing")
    self.rootNode:setPosition(-540,0)
    parent:addChild(self.rootNode)

    if self.rootItems.mainTopNode then
        self.rootItems.mainTopNode:setPositionY(toppos)
    end

    local phoName = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("cb_3.png"))

    self.rootItems.expbarprogress = CCProgressTimer:create(phoName)
    self.rootItems.expbarprogress:setAnchorPoint(ccp(0.0, 0.5))
    self.rootItems.expbarprogress:setType(kCCProgressTimerTypeBar)
    self.rootItems.expbarprogress:setMidpoint(ccp(0, 0.5))
    self.rootItems.expbarprogress:setBarChangeRate(ccp(1, 0))
    self.rootItems.expbarprogress:setPosition(ccp(-431.0, 0))
    self.rootItems.expbarprogress:setPercentage(0)
    -- self.rootItems.expbarprogress:setScaleX(1)
    self.rootItems.expNode:addChild(self.rootItems.expbarprogress)

    -- 进阶成功率进度
    local phoName = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("cb_2.png"))

    self.rootItems.stageExpbarprogress = CCProgressTimer:create(phoName)
    self.rootItems.stageExpbarprogress:setAnchorPoint(ccp(0.0, 0.5))
    self.rootItems.stageExpbarprogress:setType(kCCProgressTimerTypeBar)
    self.rootItems.stageExpbarprogress:setMidpoint(ccp(0, 0.5))
    self.rootItems.stageExpbarprogress:setBarChangeRate(ccp(1, 0))
    self.rootItems.stageExpbarprogress:setPosition(ccp(-431.0, 0))
    self.rootItems.stageExpbarprogress:setPercentage(0)
    -- self.rootItems.stageExpbarprogress:setScaleX(1)
    self.rootItems.stageExpNode:addChild(self.rootItems.stageExpbarprogress)


    -- ui.setLabelString(self.rootItems.expDescText,"翅膀满10级后即可进阶操作",14)
    ui.setLabelString(self.rootItems.expDescText,gameConfig.strings:string_common("fixedString","wing",7),14)

    ui.setLabelString(self.rootItems.generalnameLabel,"",1)

    -- 隐藏翅膀
    if (gameConfig:checkBuildOpen(580) and GameScene:checkopenlevelbyId(580,true)) then
        self.rootItems["useSelectNode"]:setVisible(true)
    else
        self.rootItems["useSelectNode"]:setVisible(false)
    end
    self:initWingEffectShow()
    self.rootItems["isUseEffectSelect"]:setVisible(self.isUseEffect)
    ui.setLabelString(self.rootItems["useEffectTxt"], nil, 19)
    self.rootItems.useSelectBtn:addHandleOfControlEvent(function()
        self.isUseEffect = not self.isUseEffect
        local _str1 = "0"
        if self.isUseEffect then
            _str1 = "1"
        end
        self.rootItems["isUseEffectSelect"]:setVisible(self.isUseEffect)
        local data = {}
        if self.isUseEffect then
            data = {num = 1}
        end

        if GameScene.roleinfo and GameScene.roleinfo.id then
            CCUserDefault:sharedUserDefault():setStringForKey("useWingEffect"..GameScene.roleinfo.id, _str1)
        end
        ui.itemcache:removeskeleton(gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.generaldata.general.cid)].animationid)].name)

        self.hasdata = true
        self.haschange = true
        self:setGeneral(data)
    end, CCControlEventTouchUpInside)
    self.rootItems.useSelectBtn:setSwallowsTouch(true)
    self.rootItems.useSelectBtn:setTouchPriority(-103)

    UIRequest({type = 3740})

    guide.controller:addComplete(213,function()
        UIRequest({type = 2882,opt=1,sysID=213})
    end)
end

function wing_main.initWingEffectShow(self)
    if GameScene.roleinfo and GameScene.roleinfo.id then 
        local _str = CCUserDefault:sharedUserDefault():getStringForKey("useWingEffect"..GameScene.roleinfo.id)
        self.isUseEffect = false
        
        if _str == "" or _str == "0" then
            self.isUseEffect = false
        else
            self.isUseEffect = true
        end
    else
        self.isUseEffect = false
    end
end

function wing_main.refreshFunc(self)
    print("refreshFunc")
    UIRequest({type = 3740})
end

function wing_main.reloadData(self,data)
    -- self:setPet()
    print("reloadData=")
    if not data then
        return
    end


    self.hasdata = false
    self.haschange = false
    if self.generaldata and self.generaldata.level2 > 0 then
        self.hasdata = true

        if data.protagonist.train ~= self.generaldata.train then
            self.haschange = true
        end

        if data.protagonist.general and data.protagonist.general.cid and ( data.protagonist.general.cid ~= self.generaldata.general.cid ) then
            self.haschange = true
        end

        if data.protagonist.w_l ~= self.generaldata.w_l or data.protagonist.w_c ~= self.generaldata.w_c then
            self.haschange = true
        end
    end

    self.wingdata = data.wing
    self.generaldata = data.protagonist

    if self.rootItems.bgbutton then
        self.rootItems.bgbutton:setVisible(false)
        self.rootItems.bgbutton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            print("bgbutton")     --todo
            self.rootItems.starupBtn:stopAllActions()
            self.poptimes = 0
            self:showNumAction()
        end, CCControlEventTouchUpInside)
        self.rootItems.bgbutton:setSwallowsTouch(true)
        self.rootItems.bgbutton:setTouchPriority(-103)
    end

    -- 进阶预览
    self.rootItems.stagewatchBtn:setTouchPriority(-103)
    self.rootItems.stagewatchBtn:addHandleOfControlEvent(function()
        print("进阶预览")
        gameTouch:clickprofbytime(1)
        gameWindows:openWindow("wingPreview",{wing = self.wingdata, protagonist = self.generaldata})
    end, CCControlEventTouchUpInside)

    -- 染色
    self.rootItems.setColorBtn:setTouchPriority(-103)
    self.rootItems.setColorBtn:addHandleOfControlEvent(function()
        print("ranse")
        gameTouch:clickprofbytime(1)
        if self.wingdata.stagenum < 1 then
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","wing",4)})
        elseif gamedata.config.wing_stage[tostring(self.wingdata.stagenum)] and gamedata.config.wing_stage[tostring(self.wingdata.stagenum)].coler and gamedata.config.wing_stage[tostring(self.wingdata.stagenum)].coler > 0 then
            gameWindows:openWindow("wingcolorset")
        else
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","wing",5)})
        end

    end, CCControlEventTouchUpInside)

    local uplvconfig = gamedata.config.wing_uplv[tostring(self.wingdata.stagenum)]
    
    if self.wingdata.stagenum == 0 then
        self.choosepage = "first"
    elseif ((table.getTableLength(gamedata.config.wing_uplv)) == self.wingdata.stagenum) and ((table.getTableLength(uplvconfig)) == self.wingdata.starnum) then
        print("max=====")
        self.choosepage = "max"
    elseif (table.getTableLength(uplvconfig)) == self.wingdata.starnum then
        self.choosepage = "stageup"
    else
        print("starup=====")
        self.choosepage = "starup"
    end

    print("pagenum-===",table.getTableLength(gamedata.config.wing_uplv),(table.getTableLength(uplvconfig)),self.wingdata.stagenum,self.wingdata.starnum,self.choosepage)
    if self.choosepage == "max" then
        self:setMaxProperty()
    else
        self:setProperty()
    end

    self:shiftNode(self.choosepage)

    
    self:setGeneral()
    setTriggerGiftEnable(true)
end

-- 属性角色形象
function wing_main.setGeneral(self,data)
    local nowstageconfig = gamedata.config.wing_stage[tostring((self.wingdata.stagenum == 0) and 1 or self.wingdata.stagenum)]
    ui.setLabelString(self.rootItems.generalnameLabel,nowstageconfig.name,1)

    if (not self.hasdata) or self.haschange then
        self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.generaldata.general.cid)].animationid)].name
        -- local wing = {level = self.generaldata.w_l, color = self.generaldata.w_c}
        local wing = {level = self.wingdata.stagenum, color = self.wingdata.colortype}
        if data and data.num == 1 then
            wing = {}
        end
        --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(1.6)
        Gneral1:setPosition(0,0)
        self.rootItems["generalNode"]:addChild(Gneral1.root or Gneral1)
    end

    -- if (not hasdata) or fashionchange then
        -- self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
        -- local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.generaldata.general.cid)].animationid)].name
        -- -- local wing = {level = self.generaldata.w_l, color = self.generaldata.w_c}
        -- local wing = {level = self.wingdata.stagenum, color = self.wingdata.colortype}
        -- --local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        -- local Gneral1 = ui.itemcache:loadSkeleton(generalName,wing)
        -- Gneral1:setAnimation("stand",true,0)
        -- Gneral1:setScale(1.6)
        -- Gneral1:setPosition(0,0)
        -- self.rootItems["generalNode"]:addChild(Gneral1.root or Gneral1)

        -- self.rootItems["levelEffectNode"]:removeAllChildrenWithCleanup(true)
        -- local Node11,Item11 = CCBReaderLoad("UIEffect/renwushengjie/renwushengjie_"..(growconfig[tostring(self.generaldata.level2+1)] and (math.mod(self.generaldata.level2,5)+1) or 5), nil, true, "jie")
        -- self.rootItems.levelEffectNode:addChild(Node11)

        -- if self.rootItems.name then
        --     self.rootItems.name:setString(ui.leadName(self.generaldata.level2))
        --     ui.setLabelString(self.rootItems.name,nil, gamedata.config.general[tostring(self.generaldata.general.cid)].quality~=0 and 2*gamedata.config.general[tostring(self.generaldata.general.cid)].quality-1 or 1)
        -- end
    -- end
end
    
    
-- 属性设置
function wing_main.setMaxProperty(self)
    -- self.rootItems.propertyText:setString("属性加成")
    self.rootItems.propertyText:setString(gameConfig.strings:string_common("fixedString","wing",8))

    local nowstagenum = self.wingdata.stagenum
    local nowstarnum = self.wingdata.starnum
    if nowstagenum == 0 then
        nowstagenum = 1
        nowstarnum = 0
    end
    -- 当前属性
    local uplvconfig = gamedata.config.wing_uplv[tostring(nowstagenum)] or {}
    local nowlvconfig = uplvconfig[tostring(nowstarnum)] or {}
    if nowstarnum == 0 then
        nowlvconfig = gamedata.config.wing_stage[tostring(nowstagenum)]
    end

    -- printT(nowlvconfig,"nowlvconfig==")
    -- 前4属性设置
    for i=1,4 do
        print("effect===",nowlvconfig["effect"..i])
        local attr1,num1 = ui.getATTRandNUM2(nowlvconfig["effect"..i])

        ui.setLabelString(self.rootItems["attrText"..i],gameConfig.strings.attr_type[attr1] or "",48)
        ui.setLabelString(self.rootItems["attrLab"..i],num1,14)

        self.rootItems["addnode"..i]:setVisible(false)
    end

    -- 资质设置
    local num3 = nowlvconfig["effect"..5]
    -- ui.setLabelString(self.rootItems["attrText"..5],"资质",48)
    ui.setLabelString(self.rootItems["attrText"..5],gameConfig.strings:string_common("fixedString","wing",9),48)

    ui.setLabelString(self.rootItems["attrLab"..5],num3,14)

    self.rootItems["addnode"..5]:setVisible(false)

end

-- 属性设置
function wing_main.setProperty(self)
    print("setProperty===")
    -- self.rootItems.propertyText:setString("属性加成")
    self.rootItems.propertyText:setString(gameConfig.strings:string_common("fixedString","wing",8))

    local nowstagenum = self.wingdata.stagenum
    local nowstarnum = self.wingdata.starnum
    if nowstagenum == 0 then
        nowstagenum = 1
        nowstarnum = 0
    end
    -- 当前属性
    local uplvconfig = gamedata.config.wing_uplv[tostring(nowstagenum)] or {}
    local nowlvconfig = uplvconfig[tostring(nowstarnum)] or {}
    if nowstarnum == 0 then
        nowlvconfig = gamedata.config.wing_stage[tostring(nowstagenum)]
    end

    -- 下一级属性
    local nextstagenum = nowstagenum
    local nextstarnum = nowstarnum + 1

    if (table.getTableLength(uplvconfig)) == self.wingdata.starnum then
        if nextstagenum >= table.getTableLength(gamedata.config.wing_stage) then
            nextstagenum = table.getTableLength(gamedata.config.wing_stage)
            nextstarnum = self.wingdata.starnum
        else
            nextstagenum = nextstagenum + 1
            nextstarnum = 0
        end
    end
    local nextuplvconfig = gamedata.config.wing_uplv[tostring(nextstagenum)]
    local nextlvconfig = nextuplvconfig[tostring(nextstarnum)]
    if nextstarnum == 0 then
        nextlvconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
    end

    printT(nowlvconfig,"nowlvconfig==")
    printT(nextlvconfig,"nextlvconfig==")
    -- 前4属性设置
    for i=1,4 do
        print("effect===",nowlvconfig["effect"..i],nextlvconfig["effect"..i])
        local attr1,num1 = ui.getATTRandNUM2(nowlvconfig["effect"..i])
        local attr2,num2 = ui.getATTRandNUM2(nextlvconfig["effect"..i])
        local addnum = num2-num1

        ui.setLabelString(self.rootItems["attrText"..i],gameConfig.strings.attr_type[attr1] or "",48)
        ui.setLabelString(self.rootItems["attrLab"..i],num1,14)

        if addnum == 0 or self.wingdata.stagenum == 0 then
            self.rootItems["addnode"..i]:setVisible(false)
        else
            self.rootItems["addnode"..i]:setVisible(true)
            ui.setLabelString(self.rootItems["addnum"..i],addnum,23)
        end
    end

    -- 资质设置
    local num3 = nowlvconfig["effect"..5]
    local num4 = nextlvconfig["effect"..5]
    local addnum2 = num4-num3
    ui.setLabelString(self.rootItems["attrText"..5],gameConfig.strings:string_common("fixedString","wing",9),48)
    ui.setLabelString(self.rootItems["attrLab"..5],num3,14)

    if addnum2 == 0  or self.wingdata.stagenum == 0 then
        self.rootItems["addnode"..5]:setVisible(false)
    else
        self.rootItems["addnode"..5]:setVisible(true)
        ui.setLabelString(self.rootItems["addnum"..5],addnum2,23)
    end

end

function wing_main.shiftNode(self,type)
    print("i...am..shiftNode",type)

    self.choosepage = type
    
    for k,v in ipairs(self.pages) do
        if v == self.choosepage then
            self.rootItems[v.."Node"]:setPositionX(540)
            self.rootItems[v.."Node"]:setVisible(true)
        else
            self.rootItems[v.."Node"]:setPositionX(9999)
            self.rootItems[v.."Node"]:setVisible(false)
        end
    end

    if type == "first" then
        -- print("firstNode...is....")
        self:firstReload()
    elseif type == "starup" then
        self:starupReload()
    elseif type == "stageup" then
        self:stageupReload()
    else
        print("max===")
    end

end

function wing_main.firstReload(self)
    print("firstReload===")

    -- 激活页面
    local needglod = gamedata.config.global_kv.wing_activation.value
    ui.setLabelString(self.rootItems.firstdoLabel,needglod,19)

    -- ui.setLabelString(self.rootItems.firstdoText,"激 活",19)
    ui.setLabelString(self.rootItems.firstdoText,gameConfig.strings:string_common("fixedString","wing",10),19)

    self.rootItems.firstdoBtn:setSwallowsTouch(true)
    self.rootItems.firstdoBtn:setTouchPriority(-103)
    self.rootItems.firstdoBtn:addHandleOfControlEvent(function()
        print("激活")
        -- self:shiftNode("starup")
        -- gameWindows:openWindow("devilSkill","explain")
        -- 激活 和 进阶 共享同一接口

        UIRequest({type = 3742,marknum = 0,spend = {},first = 1})
    end, CCControlEventTouchUpInside)


end

-- 升级页面设置
function wing_main.starupReload(self)
    print("starupReload===")
    -- ui.setLabelString(self.rootItems.starupLab,"自动升星",14)
    ui.setLabelString(self.rootItems.starupLab,gameConfig.strings:string_common("fixedString","wing",11),14)

    self.rootItems.starupBtn:setTouchPriority(-103)
    self.rootItems.starupBtn:addHandleOfControlEvent(function()
        print("自动升星",self.poptimes)
        if self.poptimes ~= 0 then
            return
        end
        local cidnum = 0
        local num = 0
        for k,v in pairs(self.spendPropsData) do
            cidnum = tonumber(k)
            num = v
        end
        if num <= 0 then
            -- runGamePrompt({msg = "材料不足，无法升星"}) 
            runGamePrompt({msg = gameConfig.strings:string_common("fixedString","wing",12)}) 

            return
        end

        -- self:shiftNode("stageup")
        -- gameWindows:openWindow("devilSkill","explain")
         UIRequest({type = 3741,id = cidnum})
    end, CCControlEventTouchUpInside)

    -- self.rootItems.starup_title:setString("所需材料")
    self.rootItems.starup_title:setString(gameConfig.strings:string_common("fixedString","wing",13))


    local nowstagenum = self.wingdata.stagenum
    local nowstarnum = self.wingdata.starnum
    if nowstagenum == 0 then
        nowstagenum = 1
        nowstarnum = 0
    end
    -- 当前星级属性
    local uplvconfig = gamedata.config.wing_uplv[tostring(nowstagenum)]

    -- 下一级属性
    local nextstagenum = nowstagenum
    local nextstarnum = nowstarnum + 1

    if (table.getTableLength(uplvconfig)) == self.wingdata.starnum then
        nextstagenum = nextstagenum + 1
        nextstarnum = 0
    end
    local nextuplvconfig = gamedata.config.wing_uplv[tostring(nextstagenum)]
    local nextlvconfig = nextuplvconfig[tostring(nextstarnum)]
    if nextstarnum == 0 then
        nextlvconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
    end

    self:setStarupShow()
    -- 获取消耗数据
    local spendtemp = {}
    -- local spenddata = ui.getSTRandNUMs(nextlvconfig.cost)
    -- for k,v in pairs(spenddata) do
        table.insert(spendtemp,nextlvconfig.cost)
    -- end
    printT(spendtemp,"spendtemp===000")
    UIRequest({type = 12001, order = 14005, cids = spendtemp})
end


-- 设置星级经验
function wing_main.setStarupShow(self)
    local nowstagenum = self.wingdata.stagenum
    local nowstarnum = self.wingdata.starnum
    if nowstagenum == 0 then
        nowstagenum = 1
        nowstarnum = 0
    end
    -- 上一级属性
    local uplvconfig = gamedata.config.wing_uplv[tostring(nowstagenum)]
    printT(uplvconfig,"setStarupShow===")
    print("uplvconfig-num==",table.getTableLength(uplvconfig),nowstarnum)
    -- 设置星级
    for i=1,table.getTableLength(uplvconfig) do
        if i <= nowstarnum then
            self.rootItems["starup"..i]:setVisible(true)
        else
            self.rootItems["starup"..i]:setVisible(false)
        end
    end


    -- 下一级属性
    local nextstagenum = nowstagenum
    local nextstarnum = nowstarnum + 1

    if (table.getTableLength(uplvconfig)) == self.wingdata.starnum then
        nextstagenum = nextstagenum + 1
        nextstarnum = 0
    end
    local nextuplvconfig = gamedata.config.wing_uplv[tostring(nextstagenum)]
    if not nextuplvconfig then return end
    local nextlvconfig = nextuplvconfig[tostring(nextstarnum)]
    if nextstarnum == 0 then
        nextlvconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
    end
    local nextexp = nextlvconfig["lv_exp"] or 1
    local processNum = 0
    -- -- 设置经验
    -- if self.starupNum ~= 0 then
    --     printT(self.wingdata.expnumtable)
    --     local temptimes = (table.getTableLength(self.wingdata.expnumtable)-1)*0.2
    --     print("nextnxtt==",table.getTableLength(self.wingdata.expnumtable),temptimes,self.firstnum)
    --     local greento = CCProgressFromTo:create(temptimes,self.firstnum,100)
    --     -- local greento = CCProgressFromTo:create(0.6,0,100)
    --     self.rootItems.expbarprogress:runAction(greento)

    --     self.firstnum = 0

    --     local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(temptimes), CCCallFunc:create(function() 
    --             print("poptimes===",self.poptimes)
    --             local processNum = 100*(self.wingdata.exp < nextexp and self.wingdata.exp/nextexp or 1)
    --             local greento = CCProgressFromTo:create(0.2,self.firstnum,processNum)
    --             self.rootItems.expbarprogress:runAction(greento)
    --             self.firstnum = processNum
    --                 end))

    --     self.rootItems.starupBtn:runAction(sequence)
    -- else
        processNum = 100*(self.wingdata.exp < nextexp and self.wingdata.exp/nextexp or 1)
        local greento = CCProgressFromTo:create(0.2,self.firstnum,processNum)
        self.rootItems.expbarprogress:runAction(greento)
    -- end
    

    self.firstnum = processNum

    local expnum = self.wingdata.exp.."/"..nextexp
    ui.setLabelString(self.rootItems.expnumsLab,expnum,14)
    
end

-- 升星动画特效
function wing_main.effect_shengxing(self,data)
    -- 判断是否升级
    self.olddata = table.copy(self.wingdata)
    self.oldexp = self.olddata.exp
    self.starupNum = data.wing.starnum - self.wingdata.starnum


    -- self.wingdata = data

    self.wingdata = data.wing
    self.generaldata = data.protagonist
    printT(self.olddata,"effect.olddata==")
    printT(self.wingdata,"effect.wingdata==")

    -- 经验滚动多少次
    self.poptimes = table.getTableLength(data.wing.expnumtable) or 0


    -- if self.starupNum ~= 0 then
    --     printT(self.wingdata.expnumtable)
    --     local temptimes = ((self.poptimes or 1)+1)*0.1
    --     -- ((table.getTableLength(self.wingdata.expnumtable)-2) > 0 and (table.getTableLength(self.wingdata.expnumtable)-2) or 1)*0.2
    --     print("nextnxtt==",self.poptimes,temptimes,self.firstnum)
    --     local greento = CCProgressFromTo:create(temptimes,self.firstnum,100)
    --     -- local greento = CCProgressFromTo:create(0.6,0,100)
    --     self.rootItems.expbarprogress:runAction(greento)

    --     self.firstnum = 0

    --     -- local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(temptimes), CCCallFunc:create(function() 
    --     --         print("poptimes===",self.poptimes)
    --     --         local processNum = 100*(self.wingdata.exp < nextexp and self.wingdata.exp/nextexp or 1)
    --     --         local greento = CCProgressFromTo:create(0.2,self.firstnum,processNum)
    --     --         self.rootItems.expbarprogress:runAction(greento)
    --     --         self.firstnum = processNum
    --     --             end))

    --     -- self.rootItems.starupBtn:runAction(sequence)
    -- end

    if self.rootItems.bgbutton then
        self.rootItems.bgbutton:setVisible(true)
    end

    self:showNumAction()
end

-- 经验滚动播放
function wing_main.showNumAction(self)
    print("showNumAction..poptimes==",self.poptimes)
    if self.poptimes <= 0 then
        if self.starupNum ~= 0 then
            self.firstnum = 0
        end
        
        local nowstagenum = self.wingdata.stagenum
        local nowstarnum = self.wingdata.starnum
        if nowstagenum == 0 then
            nowstagenum = 1
            nowstarnum = 0
        end

        -- 上一级属性
        local uplvconfig = gamedata.config.wing_uplv[tostring(nowstagenum)]
        printT(uplvconfig,"showNumAction.uplvconfig==")

        for i=1,table.getTableLength(uplvconfig) do
            if self.rootItems["starupnode"..i] then
                self.rootItems["starupnode"..i]:removeAllChildrenWithCleanup(true)
            end
        end
        if self.starupNum ~= 0 then
            local ccbnode,ccbitem = 0,0
            ccbnode,ccbitem = CCBReaderLoad("wing/wing_xingxing", nil, true, "wing_xingxing")
            if not self.rootItems["starupnode"..nowstarnum] then
                return
            end
            self.rootItems["starupnode"..nowstarnum]:addChild(ccbnode)

            -- setSpriteFrameByName(ccbitem.starpicture1, starconfig[tostring(self.data.level3)]["icon"])
            -- setSpriteFrameByName(ccbitem.starpicture2, starconfig[tostring(self.data.level3)]["icon"])

            local animationManager = getAnimationManager(ccbitem)
            animationManager:setAnimationCompletedCallback(function()
                print("effect..back..")
                self.rootItems["starupnode"..nowstarnum]:removeAllChildrenWithCleanup(true)
            end)
            animationManager:runAnimationsForSequenceNamed("play")
        end

        
        print("reloadData===")
        if (table.getTableLength(uplvconfig)) == self.wingdata.starnum then
            self:setStarupShow()
        end
        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.1), CCCallFunc:create(function() 
            self:reloadData({wing = self.wingdata,protagonist = self.generaldata})
        end))
        
        self.rootItems.starupBtn:runAction(sequence)
        return
    else
        local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(0.1), CCCallFunc:create(function() 
                print("poptimes===",self.poptimes)
                printT(self.wingdata.expnumtable)

                -- printT(self.olddata,"expfjlkj==")
                local nowstagenum = self.wingdata.stagenum
                local nowstarnum = self.wingdata.starnum
                if nowstagenum == 0 then
                    nowstagenum = 1
                    nowstarnum = 0
                end
                -- 不升级的情况
                if self.starupNum == 0 then
                    nowstarnum = nowstarnum + 1
                end
                
                -- 上一级属性
                local uplvconfig = gamedata.config.wing_uplv[tostring(nowstagenum)][tostring(nowstarnum)]

                local weightsdata = ui.getIDandNUMs(uplvconfig.weights)
                printT(weightsdata,"weightsdata===")
                local basicnum = tonumber(weightsdata[1]["cid"])
                local numtemp = tonumber(self.wingdata.expnumtable[tostring(self.poptimes)]/basicnum)
      
                print("numtemp===",numtemp)

                local tempstring = {}
                if numtemp == 1 then
                    tempstring = "获得经验："..self.wingdata.expnumtable[tostring(self.poptimes)]
                    runGamePrompt({msg = tempstring}) 
                elseif numtemp > 1 and numtemp < 3 then
                    tempstring.color = ccc3(93,227,90)
                    -- tempstring.str = "爆击"..numtemp.."倍，".."获得经验："..self.wingdata.expnumtable[tostring(self.poptimes)]
                    tempstring.str = gameConfig.strings:string_common("fixedString","wing",16)..self.wingdata.expnumtable[tostring(self.poptimes)]..gameConfig.strings:string_common("fixedString","wing",14)..numtemp..gameConfig.strings:string_common("fixedString","wing",15)
                    
                    runGamePrompt({msg = tempstring}) 
                else
                    tempstring.color = ccc3(121,203,255)
                    -- tempstring.str = "爆击"..numtemp.."倍，".."获得经验："..self.wingdata.expnumtable[tostring(self.poptimes)]
                    tempstring.str = gameConfig.strings:string_common("fixedString","wing",16)..self.wingdata.expnumtable[tostring(self.poptimes)]..gameConfig.strings:string_common("fixedString","wing",14)..numtemp..gameConfig.strings:string_common("fixedString","wing",15)
                    runGamePrompt({msg = tempstring}) 
                end


                -- 下一级属性
                -- local nextstagenum = nowstagenum
                -- local nextstarnum = nowstarnum + 1

                -- if (table.getTableLength(uplvconfig)) == self.olddata.starnum then
                --     nextstagenum = nextstagenum + 1
                --     nextstarnum = 0
                -- end
                -- local nextuplvconfig = gamedata.config.wing_uplv[tostring(nextstagenum)]
                -- local nextlvconfig = nextuplvconfig[tostring(nextstarnum)]
                -- if nextstarnum == 0 then
                --     nextlvconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
                -- end
                local nextexp = uplvconfig["lv_exp"] or 100



                self.oldexp = self.oldexp + self.wingdata.expnumtable[tostring(self.poptimes)]
                if self.oldexp > nextexp then
                    self.oldexp = nextexp
                end
                -- printT(nextuplvconfig,"nextuplvconfig==")
                print("num===num--",self.oldexp,nextexp)
                -- printT(nextlvconfig,"nextlvconfig==")

                local expnum = self.oldexp.."/"..nextexp
                ui.setLabelString(self.rootItems.expnumsLab,expnum,14)

                local temptimes = 0.1
                local toscroll = 100*(self.oldexp/nextexp)
                print("toscroll===",self.firstnum,toscroll,temptimes)
                local greento = CCProgressFromTo:create(temptimes,self.firstnum,toscroll)
                -- local greento = CCProgressFromTo:create(0.6,0,100)
                self.rootItems.expbarprogress:runAction(greento)

                

                self.firstnum = toscroll

                self.poptimes = self.poptimes - 1

                self:showNumAction()
        end))

        self.rootItems.starupBtn:runAction(sequence)

        -- 升星中消耗数递减
        -- ui.setLabelString(self.rootItems.starupLab,"升星中",14)
        ui.setLabelString(self.rootItems.starupLab,gameConfig.strings:string_common("fixedString","wing",17),14)


        self.labnum = self.labnum - 1
        if self.labnum >= 1 then
            ui.setLabelString(self.rootItems.spendnumsLab,self.labnum.."/1",13)
        else
            ui.setLabelString(self.rootItems.spendnumsLab,self.labnum.."/1",27)
        end
        

    end

    

end

-- 设置消耗物品
function wing_main.setSpendPropsData(self,data)
    printT(data,"setSpendPropsData===")
    if not data then
        return
    end

    self.spendPropsData = data


    local nowstagenum = self.wingdata.stagenum
    local nowstarnum = self.wingdata.starnum
    if nowstagenum == 0 then
        nowstagenum = 1
        nowstarnum = 0
    end

    local uplvconfig = gamedata.config.wing_uplv[tostring(nowstagenum)]

    -- 下一级属性
    local nextstagenum = nowstagenum
    local nextstarnum = nowstarnum + 1

    if (table.getTableLength(uplvconfig)) == self.wingdata.starnum then
        nextstagenum = nextstagenum + 1
        nextstarnum = 0
    end
    local nextuplvconfig = gamedata.config.wing_uplv[tostring(nextstagenum)]
    local nextlvconfig = nextuplvconfig[tostring(nextstarnum)]
    if nextstarnum == 0 then
        nextlvconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
    end
    print("numnum====",nextstagenum,nextstarnum)
    printT(self.wingdata,"wingdata===")
    printT(nextlvconfig,"starupnext===")
    -- 获取消耗数据
    local spendcid = nextlvconfig.cost
    print("spendcid===111",spendcid)
    -- ui.getSTRandNUMs(nextlvconfig.cost)

    ui.setNewIcon(self.rootItems,{cid=spendcid})
    local temconfig = ui.IDconfig(spendcid)
    ui.setLabelString(self.rootItems.spendnameLab,temconfig.name,(temconfig.quality and temconfig.quality or 1)*2-1)
    if self.spendPropsData[tostring(spendcid)] >= 1 then
        ui.setLabelString(self.rootItems.spendnumsLab,self.spendPropsData[tostring(spendcid)].."/1",13)
    else
        ui.setLabelString(self.rootItems.spendnumsLab,self.spendPropsData[tostring(spendcid)].."/1",27)
    end
    


    -- 设置消耗数
    self.labnum = self.spendPropsData[tostring(spendcid)] or 0

    self.rootItems.i_button:setTouchPriority(-103)
    self.rootItems.i_button:addHandleOfControlEvent(function()
        print("进阶材料详情")

        ui.setPopwindowByCid(spendcid)
    end, CCControlEventTouchUpInside)
end


function wing_main.stageupReload(self)
    if self.wingdata.stagenum == table.getTableLength(gamedata.config.wing_stage) then
        return
    end
    print("stageupReload===")
    -- local successLabstring = "成功率："..self.wingdata.successpercent.."%"
    local successLabstring = gameConfig.strings:string_common("fixedString","wing",18)..self.wingdata.successpercent..gameConfig.strings:string_common("fixedString","wing",19)


    local stageconfig = gamedata.config.wing_stage[tostring(self.wingdata.stagenum+1)] or {}
    ui.setLabelString(self.rootItems.successLab,successLabstring,14)
    ui.setLabelString(self.rootItems.successDesText,gameConfig.strings:wing_up_persent(stageconfig.add),14)
    self.rootItems.stageup_title:setString(gameConfig.strings:string_common("fixedString","wing",13))

    if stageconfig.down_lv and stageconfig.down_lv ==1 then
        ui.setLabelString(self.rootItems.stagepointText,gameConfig.strings:string_common("fixedString","wing",21),27)
    else
        ui.setLabelString(self.rootItems.stagepointText,"",27)
    end
    
    ui.setLabelString(self.rootItems.stageupLab,gameConfig.strings:string_common("fixedString","wing",22),18)
    self.rootItems.stageUpButton:setTouchPriority(-103)
    self.rootItems.stageUpButton:addHandleOfControlEvent(function()
        print("进阶按钮")
        gameTouch:clickprofbytime(1)
        
        local nowstagenum = self.wingdata.stagenum
        local nextstagenum = nowstagenum+1
        local nextstageconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
        local spenddata1 = ui.getIDandNUMs(nextstageconfig.cost)
        local spenddata2 = ui.getIDandNUMs(nextstageconfig.special_cost)

        local spenddata = {}
        for i,v in ipairs(spenddata1) do
            table.insert(spenddata,v)
        end

        if self.isselect then
            table.insert(spenddata,spenddata2[1])
        end

        local stagenum = 0
        if self.isselect then
            stagenum = 1
        end

        if GameScene.roleinfo.level < nextstageconfig["battle_lv"] then
            local temstring = gameConfig.strings:DevilTeamLev(nextstageconfig["battle_lv"])
            -- runGamePrompt({msg = "队伍等级达到"..nextstageconfig["battle_lv"].."才能进阶"})
            runGamePrompt({msg = temstring})
            
            return
        end
        print("isselect===222",self.isselect)

        for i=1,2 do
            if spenddata1[i] and self.stageSpendPropsData[tostring(spenddata1[i]["cid"])] < spenddata1[i]["num"] then
                runGamePrompt({msg = gameConfig.strings:string_common("fixedString","wing",23)})
                return
            end
        end
        
        printT(nextstageconfig,"nextstageconfig===1")
        printT(spenddata2,"spenddata2===1")
        if nextstageconfig.down_lv ~= 0 and self.isselect == false then
            -- runGamePrompt({msg = "材料不足，无法进阶"})
            local function tishicallback()
                print("tishicallback")
                UIRequest({type = 3742,marknum = stagenum,spend = spenddata})
            end
            gameWindows:openWindow("wingstagesuccess",{index = "tishi"},tishicallback)
            return
        end


        UIRequest({type = 3742,marknum = stagenum,spend = spenddata})
    end, CCControlEventTouchUpInside)


    -- 进度条设置
    local processNum = (self.wingdata.successpercent and self.wingdata.successpercent or 100)
    local greento = CCProgressFromTo:create(0.2,self.stagefirstnum,processNum)
    self.rootItems.stageExpbarprogress:runAction(greento)
    print("stageprocessnum===",processNum,self.stagefirstnum)
    self.stagefirstnum = processNum
    print("stageprocessnum===111",processNum,self.stagefirstnum)

    
    -- 消耗
    local nowstagenum = self.wingdata.stagenum
    local nextstagenum = nowstagenum+1
    local nextstageconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
    print("nextstagenum---",nextstagenum)
    printT(nextstageconfig,"nextstageconfig===")
    local spendcid = {}
    -- 是否消耗保护药（显示与否）
    if nextstageconfig.down_lv == 0 then
        self.rootItems.specialnode:setVisible(false)
        self.rootItems.stagepointText:setVisible(false)
        local spenddata1 = ui.getIDandNUMs(nextstageconfig.cost)
        
        for i,v in ipairs(spenddata1) do
            table.insert(spendcid,v.cid)
        end

    else
        self.rootItems.specialnode:setVisible(true)
        self.rootItems.stagepointText:setVisible(true)
        local spenddata1 = ui.getIDandNUMs(nextstageconfig.cost)
        local spenddata2 = ui.getIDandNUMs(nextstageconfig.special_cost)
        for i,v in ipairs(spenddata1) do
            table.insert(spendcid,v.cid)
        end
        table.insert(spendcid,spenddata2[1]["cid"])
    end

    -- for k,v in pairs(spenddata) do
        -- table.insert(spendcid,spenddata1[1]["cid"])
        -- table.insert(spendcid,spenddata2[1]["cid"])
    -- end
    printT(spendcid,"spendcido===")
    UIRequest({type = 12001, order = 14006, cids = spendcid})
end


function wing_main.setStageSpendPropsData(self,data)
    self.stageSpendPropsData = data
     -- 消耗
    local nowstagenum = self.wingdata.stagenum
    local nextstagenum = nowstagenum+1
    local nextstageconfig = gamedata.config.wing_stage[tostring(nextstagenum)]

    -- local spenddata = ui.getIDandNUMs(nextstageconfig.cost)

    local spenddata = {}
    local spenddata2 = {}

    -- 是否消耗保护药（显示与否）
    if nextstageconfig.down_lv == 0 then
        local spenddata1 = ui.getIDandNUMs(nextstageconfig.cost)
        for i,v in ipairs(spenddata1) do
            table.insert(spenddata,v)
        end

    else
        self.rootItems.specialnode:setVisible(true)
        self.rootItems.stagepointText:setVisible(true)
        local spenddata1 = ui.getIDandNUMs(nextstageconfig.cost)

        for i,v in ipairs(spenddata1) do
            table.insert(spenddata,v)
        end

        local spenddata1 = ui.getIDandNUMs(nextstageconfig.special_cost)
        for i,v in ipairs(spenddata1) do
            table.insert(spenddata2,v)
        end
    end

    -- printT(spenddata,"spenddata====")

    
    for i=1,2 do
        if spenddata[i] then
            self.rootItems["jinjie_costIcon"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,{cid=spenddata[i].cid},tonumber(i))

            if self.rootItems["i_button_"..i] then
                self.rootItems["i_button_"..i]:setTouchPriority(-103)
                self.rootItems["i_button_"..i]:addHandleOfControlEvent(function()
                    print("进阶材料详情")
                    ui.setPopwindowByCid(spenddata[i].cid)
                end, CCControlEventTouchUpInside)
            end

            if self.stageSpendPropsData[tostring(spenddata[i].cid)] < spenddata[i].num then
                ui.setLabelString(self.rootItems["i_num_"..i],(self.stageSpendPropsData[tostring(spenddata[i].cid)].."/"..spenddata[i].num),24)
            else
                ui.setLabelString(self.rootItems["i_num_"..i],(self.stageSpendPropsData[tostring(spenddata[i].cid)].."/"..spenddata[i].num),13)
            end
        else
            self.rootItems["jinjie_costIcon"..i]:setVisible(false)
        end

    end


    self.isselect = false
    if next(spenddata2) then
        local v = spenddata2[1]
        local k = 3

        ui.setNewIcon(self.rootItems,{cid=v.cid},tonumber(k))
        
        if self.rootItems["i_button_"..k] then
            self.rootItems["i_button_"..k]:setTouchPriority(-103)
            self.rootItems["i_button_"..k]:addHandleOfControlEvent(function()
                print("进阶材料详情")
                ui.setPopwindowByCid(v.cid)
            end, CCControlEventTouchUpInside)
        end

        local temconfig = ui.IDconfig(v.cid)
        ui.setLabelString(self.rootItems["stagespendname"..k],temconfig.name,(temconfig.quality and temconfig.quality or 1)*2-1)
        if self.stageSpendPropsData[tostring(v.cid)] < v.num then
            ui.setLabelString(self.rootItems["stagespendnum"..k],(self.stageSpendPropsData[tostring(v.cid)].."/"..v.num),24)
        else
            self.isselect = true
            ui.setLabelString(self.rootItems["stagespendnum"..k],(self.stageSpendPropsData[tostring(v.cid)].."/"..v.num),13)
        end

    end

    -- for k,v in pairs(spenddata2) do
    --     ui.setNewIcon(self.rootItems,{cid=v.cid},tonumber(k))
        
    --     if self.rootItems["i_button_"..k] then
    --         self.rootItems["i_button_"..k]:setTouchPriority(-103)
    --         self.rootItems["i_button_"..k]:addHandleOfControlEvent(function()
    --             print("进阶材料详情")
                
    --             ui.setPopwindowByCid(v.cid)
    --         end, CCControlEventTouchUpInside)
    --     end
        
    --     local temconfig = ui.IDconfig(v.cid)
    --     ui.setLabelString(self.rootItems["stagespendname"..k],temconfig.name,(temconfig.quality and temconfig.quality or 1)*2-1)
    --     -- ui.setLabelString(self.rootItems["stagespendnum"..k],(self.stageSpendPropsData[tostring(v.cid)].."/"..v.num),14)
    --     if self.stageSpendPropsData[tostring(v.cid)] < v.num then
    --         ui.setLabelString(self.rootItems["stagespendnum"..k],(self.stageSpendPropsData[tostring(v.cid)].."/"..v.num),24)
    --     else
    --         if tonumber(k) == 2 then
    --             -- 是否 能选择
    --             self.isselect = true
    --         end
    --         ui.setLabelString(self.rootItems["stagespendnum"..k],(self.stageSpendPropsData[tostring(v.cid)].."/"..v.num),13)
    --     end
    -- end
    print("isselect==",self.isselect)

    self.rootItems.selectmarkBtn:setTouchPriority(-103)
    self.rootItems.selectmarkBtn:addHandleOfControlEvent(function()
        print("选择保护药")
        -- self:shiftNode("stageup")
        -- gameWindows:openWindow("devilSkill","explain")
        -- GameScene:shiftLayer("devilcollect",nil,{petsData = self.petdata, petFragmentData = self.petFragmentData})
        local nowstagenum = self.wingdata.stagenum
        local nextstagenum = nowstagenum+1
        local nextstageconfig = gamedata.config.wing_stage[tostring(nextstagenum)]
        -- local spenddata1 = ui.getIDandNUMs(nextstageconfig.cost)
        local spenddata2 = ui.getIDandNUMs(nextstageconfig.special_cost)
        printT(nextstageconfig,"nextstageconfig===")
        printT(spenddata2,"spenddata2===")
        printT(self.stageSpendPropsData,"stageSpendPropsData===")

        if nextstageconfig.down_lv ~= 0 and self.stageSpendPropsData[tostring(spenddata2[1]["cid"])] < spenddata2[1]["num"] then
            -- runGamePrompt({msg = "材料不足，无法进阶"})
            ui.setPopwindowByCid(spenddata2[1]["cid"])
            self:setselect(false)
            return
        end


        self:setselect(not self.isselect)
        print("isselect===111",self.isselect)

    end, CCControlEventTouchUpInside)
    
    self:setselect(self.isselect)
end

function wing_main.setselect(self,isselect)
    self.isselect = isselect
    self.rootItems.selectmark:setVisible(self.isselect)
end

function wing_main.stageEndSet(self,data)
    if data.wing and data.wing.issuccess and data.wing.issuccess == 1 then
        gameWindows:openWindow("wingstagesuccess",{wing = self.wingdata, protagonist = self.generaldata, index = "stagesuccess"},function() self:reloadData(data) end)
    else  
        -- runGamePrompt({msg = "进阶失败！"})
        runGamePrompt({msg = gameConfig.strings:string_common("fixedString","wing",24)})


        local stationnum = table.getTableLength(gamedata.config.wing_uplv[tostring(data.wing.stagenum)])
        local ccbnode,ccbitem = 0,0
        ccbnode,ccbitem = CCBReaderLoad("UIEffect/chibang/xingxingposui", nil, true, "xingxingposui")
        if not self.rootItems["starupnode"..stationnum] then
            return
        end
        self.rootItems["starupnode"..stationnum]:addChild(ccbnode)

        -- setSpriteFrameByName(ccbitem.starpicture1, starconfig[tostring(self.data.level3)]["icon"])
        -- setSpriteFrameByName(ccbitem.starpicture2, starconfig[tostring(self.data.level3)]["icon"])

        local animationManager = getAnimationManager(ccbitem)
        animationManager:setAnimationCompletedCallback(function()
            print("effect..back..")
            self.rootItems["starupnode"..stationnum]:removeAllChildrenWithCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("Default Timeline")
        print("reloadData===")
        local uplvconfig = gamedata.config.wing_uplv[tostring(data.wing.stagenum)]
        if (table.getTableLength(uplvconfig)) == data.wing.starnum then
            self:setStarupShow()
        end
        self:reloadData(data)
    end


    -- self.wingdata = data

end


function wing_main.clear(self)
    
    self.rootItems.starupBtn:stopAllActions()

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootItems = nil
    self.rootNode = nil

    -- self.poptimes = 0
    -- self.starupNum = 0
    self.generaldata = nil
    self.isselect = false
    self.firstnum = 0
    self.starupNum = 0
    self.stagefirstnum = 0
    self.oldexp = 0
    self.poptimes = 0
    self.labnum = 0
end


return wing_main �  