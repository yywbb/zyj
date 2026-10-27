--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

--与海外版有差异，海外版伙伴突破消耗的碎片数量根据资质计算，国内版根据品质计算

local generalup = {

    resource = nil,

    titleCellSize = {x=180,y=180},
    generalListTableView = nil,

    rootNode = nil,
    rootItems = nil,

    pageconfig = {"up","tupo","train","awaken","xiulian","upstar","feisheng"},
    pagename = {"升 级","突 破","培 养","觉 醒","进 修","升 星","飞 升"},

    pagebuild = {1,52,51,174,378,572,449},
    pageScroll = true,
    pagenodes = {up = "upnode",tupo = "tuponode",train = "trainnode",awaken = "juexingnode",xiulian = "xiuliannode",upstar = "upstarnode",feisheng = "feishengnode"},

    selectpage = "up",

    data = {},
    sid = 1,
    generalsdata = nil,
    fragmentsdata = nil,

    nextgenerals = {},

    generalindex = 1,
    generalcid = nil,

    trainSelect = 1,
    trainResuit = false,
    trainiid = 0,
    trainpropnum = 0,

    delaybutton = false,
    awakenCondition = nil,
    xiuLianData = {},
    xiuLianAddData = {},
    xiulianType = 1,

    jinXiuB1 = -104,
    jinXiuB2 = -115,
    jinXiuT = 192,

    tupo_needprops = {},
    scopetype = {
        [1] = "tian",
        [2] = "di",
        [3] = "ren",
    },
    tupo_selectscope = 0,
    newgoldskill = {},
    touchPriority = -103,
    isNotUpChangeType = false,
    feishengEffectItems = {},
    autoXiulian = false,
    autoJuexing = false,

    upstarNodeInfo = nil,
    
}

function generalup.setPageTitleShow( self)
    for i,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            setSpriteFrameByName(self.rootItems["buttonsprite"..i], gameConfig.images.pageButtonON)
        else
            setSpriteFrameByName(self.rootItems["buttonsprite"..i], gameConfig.images.pageButtonOFF)
        end
    end
end

function generalup.setPageTitleOffset(self)

    local index = 1

    for i,v in ipairs(self.pageconfig) do
        if v == self.selectpage then
            index = i
            break
        end
    end
    if index > 5 then
        self.rootItems.generalUpTitle:setPositionX(1080 - index * 196 - 5)
    end
    
end

function generalup.freshUI(self)
    if self.rootItems.jinxiubg then
        self.rootItems.jinxiubg:setVisible(false)
    end

    if self.rootItems.feishengbg then
        self.rootItems.feishengbg:setVisible(false)
    end

    if self.rootItems.btnRule then
        self.rootItems.btnRule:setVisible(false)
    end

    if self.rootItems.generalInfoNode then
        self.rootItems.generalInfoNode:setZOrder(-1)
    end

    if self.rootItems.upstarSKillButton then
        self.rootItems.upstarSKillButton:setVisible(false)
    end

    if self.rootItems.upstarnode_g then
        self.rootItems.upstarnode_g:setVisible(false)
    end

    if self.rootItems.changeskillBtn then
        self.rootItems.changeskillBtn:setVisible(false)
    end

    if self.rootItems.upstarSKillButton then
       self.rootItems.upstarSKillButton:setVisible(false)
    end

    if self.rootItems.btn_jxRebirth then
        self.rootItems.btn_jxRebirth:setVisible(false)
    end

    if self.rootItems.btn_upstarRebirth then
        self.rootItems.btn_upstarRebirth:setVisible(false)
    end

    --改变node位置与隐藏
    for k,v in pairs(self.pagenodes) do
        if k == self.selectpage then
            self.rootItems[v]:setPositionX(0)
            self.rootItems[v]:setVisible(true)
        else
            self.rootItems[v]:setPositionX(9999)
            self.rootItems[v]:setVisible(false)
        end
    end
    self.rootItems.generalnode:setPositionY(30)
    if self.selectpage == "tupo" then
        self:setPage_tupo()
    elseif self.selectpage == "train" then
        self:setPage_train()
    elseif  self.selectpage == "awaken" then
        self:setPage_awaken()

        guide.controller:addComplete(455,function()
            UIRequest({type = 2882,opt=1,sysID=455})
        end)
    elseif self.selectpage == "xiulian" then
        self:setPage_xiulian()
        if self.rootItems.jinxiubg then
            self.rootItems.jinxiubg:setVisible(true)
        end

        guide.controller:addComplete(456,function()
            UIRequest({type = 2882,opt=1,sysID=456})
        end)   
    elseif self.selectpage == "up" then
        self:setPage_up()
    elseif self.selectpage == "feisheng" then
        if self.rootItems.feishengbg then
            self.rootItems.feishengbg:setVisible(true)
        end

        if self.rootItems.generalInfoNode then
            self.rootItems.generalInfoNode:setZOrder(10)
        end

        self.rootItems.generalnode:setPositionY(150)
        self:setPage_feisheng()
        guide.controller:addComplete(457,function()
            UIRequest({type = 2882,opt=1,sysID=457})
        end)
    elseif self.selectpage == "upstar" then
        if not self.upstarNodeInfo then
            local node,items = CCBReaderLoad("general_new/general_upstar", nil, true, "general_upstar")
            self.rootItems.upstarCCB:addChild(node)

            self.upstarNodeInfo = {}
            self.upstarNodeInfo.node = node
            self.upstarNodeInfo.items = items
        end

        self.rootItems.newskillnode:setVisible(false)
        self.rootItems.newskillnode:setPositionX(9999)

        self:setPage_upstar()

    end
end


function generalup.shiftPage(self,type)
    --添加觉醒按钮开启条件，未开启不可见、不响应
    --此处理后觉醒页签必须放在最后，不能修改此页签位置
    if not gameConfig:checkBuildOpen(174)  then
        self.rootItems.buttonnode4:setVisible(false)
        self.rootItems.button4:setTouchEnabled(false)
    else
        self.rootItems.buttonnode4:setVisible(true)
        self.rootItems.button4:setTouchEnabled(true)     
    end
    if not gameConfig:checkBuildOpen(378) then
        self.rootItems.buttonnode5:setVisible(false)
        self.rootItems.button5:setTouchEnabled(false)
    else
        self.rootItems.buttonnode5:setVisible(true)
        self.rootItems.button5:setTouchEnabled(true)
    end
    
    print("shiftPage",self.isContentScroll)
    if self.isContentScroll then
        self:setPageTitleShow()
        return
    end

    
    if type == "tupo" then
        if not GameScene:checkopenlevelbyId(52) then
            self:setPageTitleShow()
            return
        end
    elseif type == "train" then
        if  not GameScene:checkopenlevelbyId(51) then
            self:setPageTitleShow()
            return
        end
    elseif  type == "awaken" then
        if not gameConfig:checkBuildOpen(174) or not GameScene:checkopenlevelbyId(174) then
            self:setPageTitleShow()
            return
        end

    elseif type == "xiulian" then
        if not GameScene:checkopenlevelbyId(378) then
            self:setPageTitleShow()
            return
        end
    elseif type == "feisheng" then
        if not gameConfig:checkBuildOpen(449) or not GameScene:checkopenlevelbyId(449) then
            self:setPageTitleShow()
            return
        end
    elseif type == "upstar" then
        if not gameConfig:checkBuildOpen(449) or not GameScene:checkopenlevelbyId(449) then
            self:setPageTitleShow()
            return
        end
    end

    print("shiftPage",self.selectpage,type)
    self.selectpage = type
    self:setPageTitleOffset()
    self:freshUI()
    self:touchLayerSet()
end

function generalup.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("general_new/general_n_up2", nil, true, "up")
    self.rootNode:setPosition(0,0)
    self:setFixedStrting()
    parent:addChild(self.rootNode)

    self.rootItems.tupoTextScroll = tolua.cast(self.rootItems.tupoTextScroll, "CCScrollView")
    self.rootItems.tupoTextScroll:setTouchPriority(-103)


    self.rootItems.titlescroll = tolua.cast(self.rootItems.titlescroll, "CCScrollView")
    self.rootItems.titlescroll:setTouchPriority(-103)

    self.rootItems.topnode:setPositionY(toppos)

    ----
    self.rootItems.closeButton:addHandleOfControlEvent(function()

        GameScene:shiftLayer(GameScene.priorLayer,"up",{sid = self.sid or 1})

    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(-103)
    ----
    if self.rootItems.showGoldtypeBtn then
        self.rootItems.showGoldtypeBtn:addHandleOfControlEvent(function()
            gameWindows:openWindow("scope_rule",nil,nil)
        end, CCControlEventTouchUpInside)
        self.rootItems.showGoldtypeBtn:setSwallowsTouch(true)
        self.rootItems.showGoldtypeBtn:setTouchPriority(-103)
    end

    if param and param.cid then
        self.generalcid = param.cid
    else
        self.generalcid = self.generalsdata[tostring(self.generalindex)].cid or nil
    end

    if param and param.page then
        self.selectpage = param.page
    end
    self:setPageTitleOffset()

    if param and param.sid then
        self.sid = param.sid
    end
    self.awakenConfig = gamedata.config.general_awaken
    self.fragmentConfig = gamedata.config.general_fragment
    local expSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("spr_42.png"))
    self.rootItems.up_expSprite = CCProgressTimer:create(expSpr);
    self.rootItems.up_expSprite:setAnchorPoint(ccp(0,0.5))
    self.rootItems.up_expSprite:setType(kCCProgressTimerTypeBar)
    self.rootItems.up_expSprite:setMidpoint(ccp(0,0.5))
    self.rootItems.up_expSprite:setBarChangeRate(ccp(1,0))
    self.rootItems.up_expSprite:setPosition(ccp(0,0))
    self.rootItems.up_expSprite:setScaleX(0.887)
    self.rootItems.up_expSprite:setScaleY(0.95)
    self.rootItems.up_expSprite:setPercentage(0)
    self.rootItems.posnode:addChild(self.rootItems.up_expSprite)
    --
    self.rootItems.heartSlider1:setVisible(false)
    expSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("likejindutiao.png"))
    self.rootItems.heartSl1 = CCProgressTimer:create(expSpr);
    self.rootItems.heartSl1:setAnchorPoint(ccp(0.5,0))
    self.rootItems.heartSl1:setType(kCCProgressTimerTypeBar)
    self.rootItems.heartSl1:setMidpoint(ccp(0.5,0))
    self.rootItems.heartSl1:setBarChangeRate(ccp(0,1))
    self.rootItems.heartSl1:setPosition(ccp(0,0))
    self.rootItems.heartSl1:setPercentage(0)
    self.rootItems.sliderNode1:addChild(self.rootItems.heartSl1)

    self.rootItems.heartSlider2:setVisible(false)
    expSpr = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("wenkejindutiao.png"))
    self.rootItems.heartSl2 = CCProgressTimer:create(expSpr);
    self.rootItems.heartSl2:setAnchorPoint(ccp(0.5,0))
    self.rootItems.heartSl2:setType(kCCProgressTimerTypeBar)
    self.rootItems.heartSl2:setMidpoint(ccp(0.5,0))
    self.rootItems.heartSl2:setBarChangeRate(ccp(0,1))
    self.rootItems.heartSl2:setPosition(ccp(0,0))
    self.rootItems.heartSl2:setPercentage(0)
    self.rootItems.sliderNode2:addChild(self.rootItems.heartSl2)

    self.firstReload = true
    self:ReloadData()


    local pageconfig = {}
    local pagename = {}
    local pagebuild = {}

    for i,v in ipairs(self.pagebuild) do
        if gameConfig:checkBuildOpen(v) then
            table.insert(pageconfig,self.pageconfig[i])
            table.insert(pagename,self.pagename[i])
            table.insert(pagebuild,self.pagebuild[i])
        end
    end

    self.pageconfig = pageconfig
    self.pagename = pagename
    self.pagebuild = pagebuild

    self:initTouch()
end


function generalup.initTouch(self)
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.titlescrollnode,x,y) then
            self.isContentScroll = false
            self.touchX = x
            return true
        end
    end

    local function ccTouchMoved(x, y)
        if math.abs(x - self.touchX) > 30 then
            self.isContentScroll = true
        end
    end

    local function ccTouchEnded(x, y)
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end

    self.rootItems.titlescrollnode:registerScriptTouchHandler(onTouch, false,-103, false)
    self.rootItems.titlescrollnode:setTouchPriority(-103)
    self.rootItems.titlescrollnode:setTouchEnabled(true)
end

function generalup.setFixedStrting(self)

    self.rootItems.xiulian_atr4:setString(gameConfig.strings:string_common("general",44))
    self.rootItems.xiulian_atr8:setString(gameConfig.strings:string_common("general",45))
    self.rootItems.xiulian_atr1:setString(gameConfig.strings:string_common("general",47))
    self.rootItems.xiulian_atr2:setString(gameConfig.strings:string_common("generalInfo",36))
    self.rootItems.xiulian_atr3:setString(gameConfig.strings:string_common("fixedString","slotsinfo",7))
    self.rootItems.xiulian_atr5:setString(gameConfig.strings:string_common("general",47))
    self.rootItems.xiulian_atr6:setString(gameConfig.strings:string_common("generalInfo",37))
    self.rootItems.xiulian_atr7:setString(gameConfig.strings:string_common("fixedString","slotsinfo",8))

    ui.setLabelString(self.rootItems.feishengtext,gameConfig.strings:string_common("general",48),19)


end

function generalup.clear(self)
    self.newgoldskill = {}
    self.tupo_selectscope = 0
    self.tupo_needprops = {}
    self.sid = 1
    self.nextgenerals = {}
    self.xiuLianData = {}
    self.xiuLianAddData = {}
    self.xiuLianGeneral = nil
    self.xiulianType = 1
    self.delaybutton = false
    self.trainiid = 0
    self.trainpropnum = 0
    self.trainSelect = 1
    self.trainResuit = false
    self.selectpage = "up"
    self.generalindex = 1
    self.generalcid = nil
    self.generalListTableView = nil
    self.awakenCondition = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.isNotUpChangeType = false
    self.autoXiulian = false
    self.autoJuexing = false
    self.juexingTemp = nil
    self.feishengItems = nil
    self.feishengEffectItems = {}
    self.isRefreshXiulianProps = nil
    self.upstarNodeInfo = nil

end


function generalup.setPage_feisheng(self)
    if self.rootItems.changeskillBtn then
        self.rootItems.changeskillBtn:setVisible(false)
    end
    if self.rootItems.btn_jxRebirth then
        self.rootItems.btn_jxRebirth:setVisible(false)
    end

    self.rootItems.newskillnode:setVisible(false)
    self.rootItems.newskillnode:setPositionX(9999)

    if not (self.generalsdata and self.generalsdata[tostring(self.generalindex)]) then return end
    self.data.general = self.generalsdata[tostring(self.generalindex)]
    printT(self.data.general,"setPage_feisheng")

    if self.rootItems.btnRule then
        self.rootItems.btnRule:setVisible(true)
        self.rootItems["btnRule"]:setTouchPriority(-105)
        self.rootItems["btnRule"]:addHandleOfControlEvent(function()
            gameWindows:openWindow("feisheng_rule")
        end, CCControlEventTouchUpInside)
    end

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local originalBasic = generalConfig.basic
    if generalConfig.init_cid and generalConfig.init_cid > 0 then
        originalBasic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    end

    if self.data.general.level2 > 13 then
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>=7 and 213 or 2*generalConfig.quality-1)
    else    
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)
    end
    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images[generalConfig.actor])
    end
    if generalConfig.awaken == 0 or self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, self.awakenConfig[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)    
    end

    local general_basic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    if tonumber(general_basic) >= 20 then
        if gamedata.config.global_kv["general_awaken"..general_basic] then
            local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
            if self.data.general.skilllevel <= general_awaken then
                if self.rootItems.juexing then
                    self.rootItems.juexing:setVisible(false)
                end
            end
        end
    end

    if self.rootItems.goldtypeNode then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.goldtypeNode:setVisible(true)
            setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope])
        else
            self.rootItems.goldtypeNode:setVisible(false)
        end    
    end
    
    self.rootItems.feishengDetailText:setVisible(false)
    --角色是否能飞升
    if not ui.judgeFeiSheng(self.data.general.cid) then
        --品质不够不能飞升
        self.rootItems.feishengcontrolnode:setVisible(false)
        self.rootItems.notfeishengLabel:setVisible(true)
        
        self.rootItems.feisheng_maxTitle:setVisible(false)
        
        for i,v in ipairs(self.feishengEffectItems) do
            for i2,v2 in ipairs(v) do
                v2.ccb:removeFromParentAndCleanup(true)
            end
        end
        self.feishengEffectItems = {}
        return
    else
        self.rootItems.feishengcontrolnode:setVisible(true)
        self.rootItems.notfeishengLabel:setVisible(false)
    end

    self:setFeishengEffectShow()
    local level = self.data.general.level8
    local curFeishengConfig = gamedata.config.partner_soaring[tostring(level)]
    local nextFeishengConfig = gamedata.config.partner_soaring[tostring(level + 1)]
    
    --飞升最大等级
    if not nextFeishengConfig then
        self.rootItems.feishengattnode:setPositionX(20)
        self.rootItems.feishengnextattnode:setVisible(false)
        self.rootItems.feisheng_maxTitle:setVisible(true)
        self.rootItems.feishengconsumenode:setVisible(false)

        self.rootItems.feisheng_level:setString(curFeishengConfig.name)
        self.rootItems.feisheng_att1:setString(curFeishengConfig[originalBasic.."xianadk"])
        self.rootItems.feisheng_att2:setString(curFeishengConfig[originalBasic.."xiandef"])
        self.rootItems.feisheng_att3:setString(curFeishengConfig[originalBasic.."xianhp"])
        self.rootItems.feisheng_att4:setString(curFeishengConfig[originalBasic.."speed"])

    else
        self.rootItems.feishengattnode:setPositionX(-230)
        self.rootItems.feishengnextattnode:setVisible(true)
        self.rootItems.feisheng_maxTitle:setVisible(false)
        self.rootItems.feishengconsumenode:setVisible(true)

        self.rootItems.feisheng_level:setString(curFeishengConfig.name)
        self.rootItems.feisheng_att1:setString(curFeishengConfig[originalBasic.."xianadk"])
        self.rootItems.feisheng_att2:setString(curFeishengConfig[originalBasic.."xiandef"])
        self.rootItems.feisheng_att3:setString(curFeishengConfig[originalBasic.."xianhp"])
        self.rootItems.feisheng_att4:setString(curFeishengConfig[originalBasic.."speed"])
        self.rootItems.feisheng_next_level:setString(nextFeishengConfig.name)
        self.rootItems.feisheng_next_att1:setString(nextFeishengConfig[originalBasic.."xianadk"])
        self.rootItems.feisheng_next_att2:setString(nextFeishengConfig[originalBasic.."xiandef"])
        self.rootItems.feisheng_next_att3:setString(nextFeishengConfig[originalBasic.."xianhp"])
        self.rootItems.feisheng_next_att4:setString(nextFeishengConfig[originalBasic.."speed"])

        --突破要求
        if nextFeishengConfig.breach and nextFeishengConfig.breach > 0 then

            self.rootItems.feisheng_condition:setString("突破等级："..nextFeishengConfig.breach.."级")
            
            -- if nextFeishengConfig.breach >= 11 and nextFeishengConfig.breach <= 13 then
            --     self.rootItems.feisheng_condition:setString("突破等级：红+"..(nextFeishengConfig.breach - 10))
            -- elseif nextFeishengConfig.breach >= 14 then
            --     self.rootItems.feisheng_condition:setString("突破等级：彩金+"..(nextFeishengConfig.breach - 13))
            -- else
            --     self.rootItems.feisheng_condition:setString("突破等级："..nextFeishengConfig.breach.."级")
            -- end
            
            --判断突破等级
            if self.data.general.level2 < nextFeishengConfig.breach then
                self.rootItems.feisheng_condition:setColor(ccc3(255, 0, 0))
            else
                self.rootItems.feisheng_condition:setColor(ccc3(0, 255, 0))
            end
        else
            self.rootItems.feisheng_condition:setString("")
        end
        
        --进修要求
        if nextFeishengConfig.immortal and nextFeishengConfig.immortal > 0 then
            self.rootItems.feisheng_condition2:setString("文理科同时达到"..nextFeishengConfig.immortal.."级")

            --判断进修
            if self.data.general.level6 < nextFeishengConfig.immortal or self.data.general.level7 < nextFeishengConfig.immortal then
                self.rootItems.feisheng_condition2:setColor(ccc3(255, 0, 0))
            else
                self.rootItems.feisheng_condition2:setColor(ccc3(0, 255, 0))
            end

        else
            self.rootItems.feisheng_condition2:setString("")
        end

        print("originalBasic",originalBasic)
        --消耗
        local cids = {}
        local consume = ui.getIDandNUMs(nextFeishengConfig[originalBasic.."consume"])
        for i,v in ipairs(consume) do
            table.insert(cids,v.cid)
        end
        UIRequest({type = 12001, order = 32004, cids = cids})

        for i=1,4 do
            self.rootItems["feishengMaterial"..i]:setVisible(false)
        end
    end

    local nextSpeedConfig = nil
    for i=level + 1,table.getTableLength(gamedata.config.partner_soaring) do
        local config = gamedata.config.partner_soaring[tostring(i)]
        if config and config[originalBasic.."speed"] > gamedata.config.partner_soaring[tostring(level)][originalBasic.."speed"] then
            nextSpeedConfig = config
            break
        end
    end

    if nextSpeedConfig then
        self.rootItems.feishengDetailText:setVisible(true)
        ui.setLabelString(self.rootItems.feishengDetailText,nextSpeedConfig.name.."：速度+"..nextSpeedConfig[originalBasic.."speed"],48)
    end
end

function generalup.feiShengCallback(self,t)
    --是否升阶 升阶需要重新添加特效Node
    local isUpStage = false
    local level = t.level8

    if level <= 0 then
        return
    end

    if level >= 5 and level % 5 == 0 then
        isUpStage = true
    end

    local index = level%5 ~= 0 and level%5 or 5
    local effect = self.feishengEffectItems[index]

    local function func()
        local aniName = index == 5 and "5-1" or index.."-"..(index+1)
        local animationManager = getAnimationManager(self.feishengItems)
        animationManager:setAnimationCompletedCallback(function()
            -- if gamedata.config.partner_soaring[tostring(level + 1)] then
            --     self.isNoUpStage = true --标识不删除旧莲花
            -- end
            -- self:ReloadData()
        end)

        if isUpStage then
            self:feishengUpStage()
        else
            animationManager:runAnimationsForSequenceNamed(aniName)
            if gamedata.config.partner_soaring[tostring(level + 1)] then
                self.isNoUpStage = true --标识不删除旧莲花
            end
            self:ReloadData()
        end
    end

    local animationManager = getAnimationManager(effect[1].items)
    animationManager:setAnimationCompletedCallback(function()
        func()
    end)
    animationManager:runAnimationsForSequenceNamed("start")

    local animationManager = getAnimationManager(effect[2].items)
    animationManager:runAnimationsForSequenceNamed("start")
end

function generalup.feishengUpStage(self)
    local nodeNames = {"node5_1","node4_1","node3_1","node2_1","node1_1","node5_2","node4_2","node3_2","node2_2","node1_2"}
    for i=1,10 do
        local ccb,items = CCBReaderLoad("UIEffect/feisheng/feisheng_lianhua_change.ccbi", nil, true, "feisheng_lianhua_change")
        self.feishengItems[nodeNames[i]]:addChild(ccb)

        local animationManager = getAnimationManager(items)
        animationManager:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("play")
    end

    local ccb,items = CCBReaderLoad("UIEffect/feisheng/feisheng_lianhua_change2.ccbi", nil, true, "feisheng_lianhua_change")
    ccb:setScale(2)
    self.feishengItems.feishenggeneral:addChild(ccb,3)

    local animationManager = getAnimationManager(items)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
    end)
    animationManager:runAnimationsForSequenceNamed("play")

    gameTouch:clickprofbytime(1)
    self.rootItems.feisheng_effectNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        print("此处执行")
        self:ReloadData()
    end)))
end

function generalup.setFeiShengConsume(self,t)
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local originalBasic = generalConfig.basic
    if generalConfig.init_cid and generalConfig.init_cid > 0 then
        originalBasic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    end
    local level = self.data.general.level8
    local nextFeishengConfig = gamedata.config.partner_soaring[tostring(level + 1)]

    local goldNum = 0
    local consume = ui.getIDandNUMs(nextFeishengConfig[originalBasic.."consume"])
    local showConsume = {}
    for i,v in ipairs(consume) do
        if v.cid ~= 1000 then
            table.insert(showConsume,v)
        else
            goldNum = v.num
        end
    end

    self.rootItems.feisheng_coin:setString(goldNum)
    if GameScene.roleinfo.coin >= goldNum then
        self.rootItems.feisheng_coin:setColor((ccc3(255,255,255)))
    else
        self.rootItems.feisheng_coin:setColor((ccc3(255,8,8)))
    end
    

    for i=1,4 do
        if showConsume[i] then
            self.rootItems["feishengMaterial"..i]:setVisible(true)
            
            local havePropNum = t[tostring(showConsume[i].cid)] or 0
            local needPropNum = showConsume[i].num or 0

            ui.setNewIcon(self.rootItems,{cid =showConsume[i].cid},11 + i)
            ui.setLabelString(self.rootItems["i_num_"..(11+i)],havePropNum.."/"..needPropNum,havePropNum >= needPropNum and 13 or 27)

            self.rootItems["i_button_"..(15+i)]:setTouchPriority(-105)
            self.rootItems["i_button_"..(15+i)]:addHandleOfControlEvent(function()
                print("i_button_",showConsume[i].cid)
                ui.setPopwindowByCid(showConsume[i].cid)
            end, CCControlEventTouchUpInside)

        else
            self.rootItems["feishengMaterial"..i]:setVisible(false)
        end
    end

    
    self.rootItems.feishengbuntton:setSwallowsTouch(true)
    self.rootItems.feishengbuntton:setTouchPriority(-102)
    self.rootItems.feishengbuntton:addHandleOfControlEvent(function()
        printT(self.data.general,"feisheng")
        --判断突破等级
        if self.data.general.level2 < nextFeishengConfig.breach then
            runGamePrompt({msg = gameConfig.strings:string_common("general",34)})
            return
        end
        --判断进修

        if self.data.general.level6 < nextFeishengConfig.immortal or self.data.general.level7 < nextFeishengConfig.immortal then
            runGamePrompt({msg = gameConfig.strings:string_common("general",50)})
            return
        end

        --判断道具
        for i,v in ipairs(consume) do
            if not (t[tostring(v.cid)] and t[tostring(v.cid)] >= v.num) then
                local propconfig = ui.IDconfig(v.cid)
                runGamePrompt({msg = propconfig.name..gameConfig.strings:string_common("general",49)})
                return
            end
        end

        gameTouch:clickprofbytime(2)
        UIRequest({type = 7001,iid = self.data.general.iid})

    end, CCControlEventTouchUpInside)

end

function generalup.setFeishengEffectShow(self)

    -- if self.feishengItems then
    --     return
    -- end
    if self.isNoUpStage then
        self.isNoUpStage = false
        return
    end


    if not self.feishengItems then
        self.rootItems.feisheng_effectNode:removeAllChildrenWithCleanup(true)
        local ccb,items = CCBReaderLoad("general_new/feisheng_zhuan.ccbi", nil, true, "feisheng_zhuan")
        self.rootItems.feisheng_effectNode:addChild(ccb)
        self.feishengItems = items
    else
        --清除所有特效node
        for i,v in ipairs(self.feishengEffectItems) do
            for i2,v2 in ipairs(v) do
                v2.ccb:removeFromParentAndCleanup(true)
            end
        end
    end

    local animationManager = getAnimationManager(self.feishengItems)
    --先播放动画
    local aniName = (self.data.general.level8 + 1)%5 ~= 0 and (self.data.general.level8 + 1)%5 or 5
    animationManager:runAnimationsForSequenceNamed(tostring(aniName))

    self.feishengEffectItems = {}

    local isMax = false
    if not gamedata.config.partner_soaring[tostring(self.data.general.level8+1)] then
        isMax = true
    end

    local stage = math.ceil((self.data.general.level8+1)/5)
    if isMax then
        stage = math.ceil((self.data.general.level8)/5)
    else
        stage = math.ceil((self.data.general.level8+1)/5)
    end

    local index = 1
    index = math.max(stage,1)
    --创建莲花特效
    for i=1,5 do
        self.feishengEffectItems[i] = {}
        for j=1,2 do
            local ccb,items = CCBReaderLoad("UIEffect/feisheng/feisheng_lianhua"..index, nil, true, "feisheng_lianhua")
            self.feishengItems["node"..i.."_"..j]:addChild(ccb)
            self.feishengEffectItems[i][j] = {ccb = ccb,items = items}

            local animationManager = getAnimationManager(items)
            local level = (stage - 1)*5 + i
            animationManager:runAnimationsForSequenceNamed(self.data.general.level8 < level and "free" or "play")
        end
    end
end

function generalup.ReloadGenerals(self,data)
    self.generalsdata = {}
    local generals = {}
    for k,v in pairs(data) do
        if gamedata.config.general[tostring(v.cid)].quality >= 3 then
            v.showorder = tonumber(k)
            table.insert(generals,v)
        end
    end

    local sortByK = function(a,b) return a.showorder < b.showorder end
    table.sort(generals, sortByK)

    for i = 1, table.getTableLength(generals) do
        self.generalsdata[tostring(i)] = generals[i]
    end
    printT(self.generalsdata,"ReloadGenerals")
end

function generalup.ReloadFragments(self,data)
    self.fragmentsdata = data.generalfragments
end


----------------------------------------------------------------------------
function generalup.reloadGeneralList(self,alldata)
    local celldict = {}
    local generalListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.titleCellSize.x, self.titleCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_icon.ccbi", nil, true, "generalIcon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }

                ui.tableviewAnimationH(self.generalListTableView,cellCCB,self.titleCellSize.x, self.titleCellSize.y,a1)
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            cellCCB:setScale(0.9)

            ccbDocumentControler.i_selectEffect:removeAllChildrenWithCleanup(true)
            -- 设置头像
            local generalData = self.generalsdata[tostring(a1+1)]
            if generalData.illusionGeneralCid == nil then
                local configGeneral = gamedata.config.general[tostring(generalData.cid)]
                local gdata = ui.getConfigGeneral(generalData)
                if next(gdata) and configGeneral.fashion_id == 0 then
                    ui.setNewIcon(ccbDocumentControler,generalData,0,nil,gdata)
                else
                    ui.setNewIcon(ccbDocumentControler,generalData)
                end
            else
                ui.setNewIcon(ccbDocumentControler,generalData)
            end
            
            ccbDocumentControler["i_num"]:setVisible(true)
            ui.setLabelString(ccbDocumentControler["i_num"], "等级." .. self.generalsdata[tostring(a1+1)].level1, 13)            
            if self.generalindex == a1+1 then
                local eccb,eitem = CCBReaderLoad("UIEffect/zhenrongxuanzhong/zhenrongxuanzhong", nil, true, "zhenrongxuanzhong")
                eccb:setScale(1.1)
                ccbDocumentControler.i_selectEffect:addChild(eccb)
            end


            if self.generalListTableView then
                cellCCB:setPosition(self.titleCellSize.x/2, self.titleCellSize.y/2)
            end

            if first then
                a2:addChild(cellCCB)
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.generalsdata)
        elseif fn == "cellTouched" then
            gameTouch:clickprofbytime(0.5)
            self.isNotUpChangeType = true
            if a1:getIdx()+1<= table.getTableLength(self.generalsdata) then
                self:setGeneralIndex(a1:getIdx()+1,true)
            else

            end

        elseif fn == "scrollViewDidScroll" then
        end
        return r
    end)

    self.generalListTableView = ui.createLuaTableView({
        handle = generalListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 0
    })
    self.rootItems.listscroll:addChild(self.generalListTableView)
    self.generalListTableView:setTouchPriority(-102)
    --
    if self.generalindex > 5 then
        self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.generalindex-5) ,0),0.2)
    end
end

----------------------------------------------------------------------------



function generalup.setGeneralIndex(self,index)
    self.generalindex = index
    self.generalcid = self.generalsdata[tostring(self.generalindex)].cid or nil
    self:freshUI()
    self.generalListTableView:reloadData()

    -- 滑动层设置
    self:touchLayerSet()
end

--isFirst touchLayerSet
function generalup.ReloadData(self)
    if GameScene:checkUpdate(10023) then
        self.nextgenerals = {}
    else
        local ischangecid = true
        for k,v in pairs(self.generalsdata) do
            if self.generalcid and self.generalcid == v.cid then
                self.generalindex = tonumber(k)
                ischangecid = false
            elseif self.generalcid and gamedata.config.general[tostring(self.generalcid)] and gamedata.config.general[tostring(self.generalcid)].gold_id and gamedata.config.general[tostring(self.generalcid)].gold_id == v.cid then
                self.generalindex = tonumber(k)
            elseif self.generalcid and gamedata.config.general[tostring(self.generalcid)] and gamedata.config.general[tostring(self.generalcid)].break_id and gamedata.config.general[tostring(self.generalcid)].break_id == v.cid then
                self.generalindex = tonumber(k)
            elseif self.generalcid and gamedata.config.general[tostring(self.generalcid)] and gamedata.config.general[tostring(self.generalcid)].break_id and gamedata.config.general[tostring(self.generalcid)].break_id > 0 and gamedata.config.general[tostring(v.cid)] and gamedata.config.general[tostring(v.cid)].partner_id and gamedata.config.general[tostring(v.cid)].partner_id == gamedata.config.general[tostring(self.generalcid)].break_id then
                self.generalindex = tonumber(k)
            end
        end

        self.generalcid = self.generalsdata[tostring(self.generalindex)].cid or nil
        if not self.generalListTableView then
            self:reloadGeneralList()
        else
            self.generalListTableView:reloadData()
        end
        self:freshUI()
        -- 添加touch层 伙伴左右拖动换位

        if self.firstReload or ischangecid then
            self.firstReload = false

            if self.autoXiulian or self.autoJuexing then
                return
            end
            self:touchLayerSet()
        end
        -- self:touchLayerSet()
        self:getXiulianProp()
    end
end

-- 添加touch层 伙伴左右拖动换位
function generalup.touchLayerSet(self)

    self.standdata = {{cid=0,index=0},{cid=0,index=0},{cid=0,index=0}}

    for k,v in pairs(self.generalsdata) do
        
        if tonumber(self.data.general.cid) == tonumber(v.cid) then
            if self.generalsdata[tostring(tonumber(k)-1)] then
                self.standdata[1]["cid"] = self.generalsdata[tostring(tonumber(k)-1)].cid or 0
                self.standdata[1]["index"] = tonumber(k)-1 or 0
            end

            self.standdata[2]["cid"] = v.cid or 0
            self.standdata[2]["index"] = tonumber(k) or 0

            if self.generalsdata[tostring(tonumber(k)+1)] then
                self.standdata[3]["cid"] = self.generalsdata[tostring(tonumber(k)+1)].cid or 0
                self.standdata[3]["index"] = tonumber(k)+1 or 0
            end
        end
    end

    self.rootItems.markLeft:setVisible(true)
    self.rootItems.markRight:setVisible(true)
    
    if self.standdata[1]["cid"] == 0 then
        self.rootItems.markLeft:setVisible(false)
    end

    if self.standdata[3]["cid"] == 0 then
        self.rootItems.markRight:setVisible(false)
    end

    self.rootItems.general:removeAllChildrenWithCleanup(true)


    if self.feishengItems then
       self.feishengItems.feishenggeneral:removeAllChildrenWithCleanup(true)
    end

    self.stepGneral1 = nil
    self.stepGneral2 = nil
    self.stepGneral3 = nil

    --1
    if self.standdata[1]["cid"] ~= 0 then
        -- 设置形象
        local generalConfig = gamedata.config.general[tostring(self.standdata[1]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            if self.generalsdata[tostring(self.standdata[1].index)].illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, self.generalsdata[tostring(self.standdata[1].index)])
            end
        end
        self.stepGneral1 = CCNode:create()
        local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral1:addChild(general)
        self.stepGneral1:setPosition(-820,0)

        if self.selectpage == "feisheng" then
            if self.feishengItems then
                self.feishengItems.feishenggeneral:addChild(self.stepGneral1)
            else
                self.rootItems.general:addChild(self.stepGneral1)
            end
        else
            self.rootItems.general:addChild(self.stepGneral1)
        end

        printT(self.generalsdata[tostring(self.standdata[1].index)], "generalsdata")
        local generalConfig = gamedata.config.general[tostring(self.generalsdata[tostring(self.standdata[1].index)].cid)]
        local general_skilllevel = self.generalsdata[tostring(self.standdata[1].index)].skilllevel
        local general_basic = generalConfig.basic
        
        if general_basic >= 20 then
            if gamedata.config.global_kv["general_awaken"..general_basic] then
                local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
                if general_skilllevel > general_awaken then
                    ui.addAwakeEffect(self.stepGneral1,general_skilllevel,1.7)
                end
            end
        else
            ui.addAwakeEffect(self.stepGneral1,general_skilllevel,1.7)
        end
    end

    --2
    if self.standdata[2]["cid"] ~= 0 then
        local generalConfig = gamedata.config.general[tostring(self.standdata[2]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            if self.generalsdata[tostring(self.standdata[2].index)].illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, self.generalsdata[tostring(self.standdata[2].index)])
            end
        end
        self.stepGneral2 = CCNode:create()
        local general =CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral2:addChild(general)
        self.stepGneral2:setPosition(0,0)
        if self.selectpage == "feisheng" then
            if self.feishengItems then
                self.feishengItems.feishenggeneral:addChild(self.stepGneral2)
            else
                self.rootItems.general:addChild(self.stepGneral2)
            end
        else
            self.rootItems.general:addChild(self.stepGneral2)
        end

        local generalConfig = gamedata.config.general[tostring(self.generalsdata[tostring(self.standdata[2].index)].cid)]
        local general_skilllevel = self.generalsdata[tostring(self.standdata[2].index)].skilllevel
        local general_basic = generalConfig.basic
        
        if general_basic >= 20 then
            if gamedata.config.global_kv["general_awaken"..general_basic] then
                local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
                if general_skilllevel > general_awaken then
                    ui.addAwakeEffect(self.stepGneral2,general_skilllevel,1.7)
                end
            end
        else
            ui.addAwakeEffect(self.stepGneral2,general_skilllevel,1.7)
        end
    end

    --3
    if self.standdata[3]["cid"] ~= 0 then
        local generalConfig = gamedata.config.general[tostring(self.standdata[3]["cid"])]
        local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
        if generalConfig.fashion_id == 0 then --非时装
            if self.generalsdata[tostring(self.standdata[3].index)].illusionGeneralCid == nil then
                generalName = ui.getGeneralAnimationid(generalName, self.generalsdata[tostring(self.standdata[3].index)])
            end
        end
        self.stepGneral3 = CCNode:create()
        local general =CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        general:setAnimation("stand",true,0)
        general:setScale(1.6)
        self.stepGneral3:addChild(general)
        self.stepGneral3:setPosition(820,0)
        if self.selectpage == "feisheng" then
            if self.feishengItems then
                self.feishengItems.feishenggeneral:addChild(self.stepGneral3)
            else
                self.rootItems.general:addChild(self.stepGneral3)
            end
        else
            self.rootItems.general:addChild(self.stepGneral3)
        end

        local generalConfig = gamedata.config.general[tostring(self.generalsdata[tostring(self.standdata[3].index)].cid)]
        local general_skilllevel = self.generalsdata[tostring(self.standdata[3].index)].skilllevel
        local general_basic = generalConfig.basic
        
        if general_basic >= 20 then
            if gamedata.config.global_kv["general_awaken"..general_basic] then
                local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
                if general_skilllevel > general_awaken then
                    ui.addAwakeEffect(self.stepGneral3,general_skilllevel,1.7)
                end
            end
        else
            ui.addAwakeEffect(self.stepGneral3,general_skilllevel,1.7)
        end

    end

    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            self.item1 = nil
            self.item2 = nil
            self.item3 = nil
            self.x1,self.y1 = 0,0
            self.x2,self.y2 = 0,0
            self.x3,self.y3 = 0,0

            if self.stepGneral1 then
                self.item1 = tolua.cast(self.stepGneral1,"CCNode")
                self.x1,self.y1 = self.item1:getPosition()
            end

            if self.stepGneral2 then
                self.item2 = tolua.cast(self.stepGneral2,"CCNode")
                self.x2,self.y2 = self.item2:getPosition()
            end
            
            if self.stepGneral3 then
                self.item3 = tolua.cast(self.stepGneral3,"CCNode")
                self.x3,self.y3 = self.item3:getPosition()
            end
            
            return true
        end
    end

    local function ccTouchMoved(x, y)
        local distanceX = x-self.touchX
        if math.abs(distanceX) >20 then
            if self.item1 then
                self.item1:setPositionX(self.x1+distanceX)
            end

            if self.item2 then
                self.item2:setPositionX(self.x2+distanceX)
            end
            if self.item3 then
                self.item3:setPositionX(self.x3+distanceX)
            end
        end
        
    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(0.5)

            self:setActionRightreload()

        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(0.5)
            self:setActionLeftreload()
        end
    end

    local function onTouch(eventType, x, y)
        if eventType == "began" then
            return ccTouchBegan(x, y)
        elseif eventType == "moved" then
            return ccTouchMoved(x, y)
        elseif eventType == "ended" then
            return ccTouchEnded(x, y)
        end
    end
    if self.rootItems.touchLayer then
        self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -101, false)
        self.rootItems.touchLayer:setTouchPriority(-101)
        self.rootItems.touchLayer:setTouchEnabled(true)
    end
end

function generalup.setActionRightreload(self)
    -- -1080
    -- 560

    if self.item1 then
        local moveTo = CCMoveTo:create(0.8, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)
        self.item1:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
            -- UIRequest({type = 3670,cid = self.standdata[1]})
            self.generalindex = self.standdata[1]["index"]
            self.generalcid = self.generalsdata[tostring(self.generalindex)].cid or nil
            self:freshUI()
            self.generalListTableView:reloadData()

            self:touchLayerSet()

            if self.standdata[2]["index"] == table.getTableLength(self.generalsdata) then 
                if  self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]) < 0  then
                    self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]),0),0.2)
                end
            elseif  self.titleCellSize.x * self.standdata[2]["index"] >  self.rootItems.listscroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * self.standdata[2]["index"],0),0.2)
            elseif self.titleCellSize.x * (self.standdata[2]["index"]-1) < -self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.standdata[2]["index"]-1) ,0),0.2)
            end


            -- if self.generalindex > 4 then
            --     self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.generalindex-4) ,0),0.2)
            -- end
        end)))

        
    else
        -- local moveTo = CCMoveTo:create(0.5, ccp(-1080, 0))
        -- local backOut = CCEaseExponentialOut:create(moveTo)
        -- self.item1:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(820, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)

        return
    end
    if self.item2 then
        local moveTo = CCMoveTo:create(1, ccp(820, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end
end

function generalup.setActionLeftreload(self)

    if self.item3 then
        local moveTo = CCMoveTo:create(0.8, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item3:runAction(backOut)
        self.item3:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5),CCCallFunc:create(function()
            -- UIRequest({type = 3670,cid = self.standdata[3]})
            -- 移动后刷新页面
            self.generalindex = self.standdata[3]["index"]
            self.generalcid = self.generalsdata[tostring(self.generalindex)].cid or nil
            self:freshUI()
            self.generalListTableView:reloadData()

            self:touchLayerSet()

            if self.standdata[2]["index"] == table.getTableLength(self.generalsdata) then 
                if  self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]) < 0  then
                    self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * (self.standdata[2]["index"]),0),0.2)
                end
            elseif  self.titleCellSize.x * self.standdata[2]["index"] >  self.rootItems.listscroll:getContentSize().width - self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(self.rootItems.listscroll:getContentSize().width - self.titleCellSize.x * self.standdata[2]["index"],0),0.2)
            elseif self.titleCellSize.x * (self.standdata[2]["index"]-1) < -self.generalListTableView:getLuaContentOffsetX() then
                self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.standdata[2]["index"]-1) ,0),0.2)
            end

            -- if self.generalindex > 4 then
            --     self.generalListTableView:setContentOffsetInDuration(ccp(-self.titleCellSize.x * (self.generalindex-4) ,0),0.2)
            -- end
        end)))
        
    else
        local moveTo = CCMoveTo:create(0.5, ccp(-820, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item1:runAction(backOut)

        local moveTo = CCMoveTo:create(0.5, ccp(0, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)

        -- local moveTo = CCMoveTo:create(0.5, ccp(560, 0))
        -- local backOut = CCEaseExponentialOut:create(moveTo)
        -- self.item3:runAction(backOut)

        return
    end

    if self.item2 then
        local moveTo = CCMoveTo:create(1, ccp(-820, 0))
        local backOut = CCEaseExponentialOut:create(moveTo)
        self.item2:runAction(backOut)
    end

end
-----------------------------------------------------------------------------



---------------------------------------------------------------------------------

--设置突破丹的数量
function generalup.setTupoProp(self,num)
    -- for k,v in pairs(self.nextgenerals) do
    --     v.prop = {cid = 20017,num = num}
    -- end
    UIRequest({type = 12001,order = 33020, cids = {20017}})

    if not self.nextgenerals[tostring(self.data.general.iid)] then
        UIRequest({type = 1023,general = self.data.general.iid})
    else
        self:setTupoNext(self.nextgenerals[tostring(self.data.general.iid)])
    end
end

function generalup.setgoldskill(self,goldlv)
    for i = 1,2 do
        if self.newgoldskill[i] then
            if self.tupo_selectscope == self.newgoldskill[i].goldtype then
                setSpriteFrameByName(self.rootItems["goldtypeselect"..i],"tujin_"..self.scopetype[self.newgoldskill[i].goldtype].."_h")
                local newskillid = self.newgoldskill[i].breakskillid
                if newskillid and newskillid ~= 0 then
                    self.rootItems.newskillnode:setVisible(true)
                    ui.setLabelString(self.rootItems.newskillname,"突破后解锁: "..gamedata.config.breakskill[tostring(newskillid)].name,48)

                    local scrollHeight = 125
                    self.rootItems.tupoTextScroll:setPositionY(-230)
                    self.rootItems.tupoTextScroll:setViewSize(CCSizeMake(420,scrollHeight))

                    local desc = gamedata.config.breakskill[tostring(newskillid)].desc
                    local labelHeight = 40
                    local textNum = 12
                    local count = ui.getTextLength(desc)

                    local length = math.ceil(count/textNum)
                    if gamedata.device.platform=="android" then
                        length = length + 1
                    end
                    local height = labelHeight * length
                    self.rootItems.containerTupoText:setContentSize(CCSizeMake(self.rootItems.containerTupoText:getContentSize().width,height))
                    self.rootItems.newskilldes:setDimensions(CCSizeMake(self.rootItems.newskilldes:getDimensions().width,height))

                    self.rootItems.containerTupoText:setPositionY(scrollHeight - self.rootItems.containerTupoText:getContentSize().height)
                    ui.removeLabelStroke(self.rootItems.newskilldes)
                    ui.setLabelString(self.rootItems.newskilldes,desc,14)

                    print("newskilldesHeight",count,height,self.rootItems.newskilldes:getContentSize().height)
                end
            else
                setSpriteFrameByName(self.rootItems["goldtypeselect"..i],"tujin_"..self.scopetype[self.newgoldskill[i].goldtype])
            end    
        end
    end
    --
    if goldlv and goldlv > 0 then
        local scopetmp = (self.data.general.g_score1 or 0)*100 + (self.data.general.g_score2 or 0)*10 + (self.data.general.g_score3 or 0)
        if goldlv == 1 then
            scopetmp = scopetmp + self.tupo_selectscope*100
        elseif goldlv == 2 then  
            scopetmp = scopetmp + self.tupo_selectscope*10
        elseif goldlv == 3 then 
            scopetmp = scopetmp + self.tupo_selectscope
        end 
        --
        if gamedata.config.jinjiangkezhiguanxi and gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)] and gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)].camp then
            setSpriteFrameByName(self.rootItems.goldtype_next,"tujin_"..self.scopetype[gamedata.config.jinjiangkezhiguanxi[tostring(scopetmp)].camp])
        end
    end

end    

function generalup.setTupoNext(self,data)

    self.data.nextGeneral = data.nextGeneral
    self.data.generalslove = data.generalslove or {}

    self.nextgenerals[tostring(self.data.general.iid)] = data
    --
    local generalConfig = gamedata.config.general[tostring(self.data.nextGeneral.cid)]
    local general_awake = gamedata.config.general_awake or {}

    ui.setLabelString(self.rootItems.tupo_next_atk,self.data.nextGeneral.atk,23)
    ui.setLabelString(self.rootItems.tupo_next_def,self.data.nextGeneral.defense,23)
    ui.setLabelString(self.rootItems.tupo_next_hp,self.data.nextGeneral.hp,23)
    ui.setLabelString(self.rootItems.tupo_next_speed,self.data.nextGeneral.speed,23)

    ui.setLabelString(self.rootItems.tupo_next_g_atk,self.data.nextGeneral.g_atk or 0,23)
    ui.setLabelString(self.rootItems.tupo_next_g_def,self.data.nextGeneral.g_defense or 0,23)
    ui.setLabelString(self.rootItems.tupo_next_g_hp,self.data.nextGeneral.g_hp or 0,23)

    if (self.data.general.level2+1) > (gamedata.config.global_kv.partner_breakthrough_limit and tonumber(gamedata.config.global_kv.partner_breakthrough_limit.value) or 13) then
        self.rootItems.oldattr:setPositionY(-230)
        self.rootItems.newattr:setVisible(true)
        self.rootItems.next_oldattr:setPositionY(-230)
        self.rootItems.next_newattr:setVisible(true)
    else
        self.rootItems.oldattr:setPositionY(0)
        self.rootItems.newattr:setVisible(false)
        self.rootItems.next_oldattr:setPositionY(0)
        self.rootItems.next_newattr:setVisible(false)
    end        

    --skill
    setSpriteFrameByName(self.rootItems.goldtype_next,"alpha")
    --
    self.newgoldskill = {}
    self.tupo_selectscope = 0
    if (self.data.general.level2+1) > (gamedata.config.global_kv.partner_breakthrough_limit and tonumber(gamedata.config.global_kv.partner_breakthrough_limit.value) or 13) then
        --
        self.rootItems.goldtypeselectNode:setVisible(true)
        --
        local goldlv = (self.data.general.level2+1)-(gamedata.config.global_kv.partner_breakthrough_limit and tonumber(gamedata.config.global_kv.partner_breakthrough_limit.value) or 13)
        for i = 1,3 do
            if generalConfig["gold"..goldlv.."_will_skills_"..i] and generalConfig["gold"..goldlv.."_will_skills_"..i] > 0 then
                table.insert(self.newgoldskill,{goldtype = i, breakskillid = generalConfig["gold"..goldlv.."_will_skills_"..i]})
            end
        end
        --
        self.tupo_selectscope = self.newgoldskill[1].goldtype
        --
        for i = 1,2 do
            self.rootItems["goldtypeselectBtn"..i]:setSwallowsTouch(true)
            self.rootItems["goldtypeselectBtn"..i]:setTouchPriority(-102)
            --
            if self.newgoldskill[i] then
                self.rootItems["goldtypeselectNode"..i]:setVisible(true)
                setSpriteFrameByName(self.rootItems["goldtypeselect"..i],"tujin_"..self.scopetype[self.newgoldskill[i].goldtype])
                self.rootItems["goldtypeselectBtn"..i]:addHandleOfControlEvent(function()
                    self.tupo_selectscope = self.newgoldskill[i].goldtype
                    self:setgoldskill(goldlv)
                end, CCControlEventTouchUpInside)
            else               
                self.rootItems["goldtypeselectNode"..i]:setVisible(false)
                self.rootItems["goldtypeselectBtn"..i]:addHandleOfControlEvent(function()
                    --
                end, CCControlEventTouchUpInside)    
            end
        end 
        -- 
        self:setgoldskill(goldlv)  
    else

        local newskillid = generalConfig["break"..(self.data.general.level2+1)]
        if newskillid and newskillid ~= 0 then
            self.rootItems.newskillnode:setVisible(true)
            ui.setLabelString(self.rootItems.newskillname,"突破后解锁: "..gamedata.config.breakskill[tostring(newskillid)].name,48)
            -- ui.setLabelString(self.rootItems.newskilldes,gamedata.config.breakskill[tostring(newskillid)].desc,14)

            local scrollHeight = 200
            self.rootItems.tupoTextScroll:setPositionY(-305)
            self.rootItems.tupoTextScroll:setViewSize(CCSizeMake(420,scrollHeight))

            local desc = gamedata.config.breakskill[tostring(newskillid)].desc
            local labelHeight = 40
            local textNum = 12
            local count = ui.getTextLength(desc)

            
            local length = math.ceil(count/textNum)
            if gamedata.device.platform=="android" then
                length = length + 1
            end
            local height = labelHeight * length
            self.rootItems.containerTupoText:setContentSize(CCSizeMake(self.rootItems.containerTupoText:getContentSize().width,height))
            self.rootItems.newskilldes:setDimensions(CCSizeMake(self.rootItems.newskilldes:getDimensions().width,height))

            self.rootItems.containerTupoText:setPositionY(scrollHeight - self.rootItems.containerTupoText:getContentSize().height)
            ui.removeLabelStroke(self.rootItems.newskilldes)
            ui.setLabelString(self.rootItems.newskilldes,desc,14)

            print("newskilldesHeight",count,height,self.rootItems.newskilldes:getContentSize().height)

        else
            self.rootItems.newskillnode:setVisible(false)
        end
        --
        self.rootItems.goldtypeselectNode:setVisible(false)
    end

    local needcoin = general_awake[tostring(self.data.general.level2+1)]["coin"..tostring(generalConfig.quality)] or 0
    ui.setLabelString(self.rootItems.tupo_coin, needcoin, GameScene.roleinfo.coin >= needcoin and 14 or 47)

    self.rootItems.tupobuntton:setSwallowsTouch(true)
    self.rootItems.tupobuntton:setTouchPriority(-102)

    --
    local needawaken = general_awake[tostring(self.data.general.level2+1)]["awaken_lv"] or 0
    if needawaken > 0 then
        ui.setLabelString(self.rootItems.tupo_condition2,gameConfig.strings:string_common("generalInfo",30)..(self.awakenConfig[tostring(needawaken)] and self.awakenConfig[tostring(needawaken)].name or ""), (needawaken > self.data.general.skilllevel) and 24 or 22)
    else
        ui.setLabelString(self.rootItems.tupo_condition2,"",48)
    end
    
    --
    local needfavorate = general_awake[tostring(self.data.general.level2+1)]["favorate_lv"] or 0
    local favoratecid = self.data.nextGeneral.cid
    if gamedata.config.general[tostring(self.data.nextGeneral.cid)].init_cid and gamedata.config.general[tostring(self.data.nextGeneral.cid)].init_cid > 0 then
        favoratecid = gamedata.config.general[tostring(self.data.nextGeneral.cid)].init_cid
    elseif gamedata.config.general[tostring(self.data.nextGeneral.cid)].orange_id and gamedata.config.general[tostring(self.data.nextGeneral.cid)].orange_id > 0 then
        favoratecid = gamedata.config.general[tostring(self.data.nextGeneral.cid)].orange_id
    elseif gamedata.config.general[tostring(self.data.nextGeneral.cid)].generalid2 and gamedata.config.general[tostring(self.data.nextGeneral.cid)].generalid2 > 0 then
        favoratecid = gamedata.config.general[tostring(self.data.nextGeneral.cid)].generalid2
    elseif gamedata.config.general[tostring(self.data.nextGeneral.cid)].partner_id and gamedata.config.general[tostring(self.data.nextGeneral.cid)].partner_id > 0 then
        favoratecid = gamedata.config.general[tostring(self.data.nextGeneral.cid)].partner_id
    end
    local favoratelevel = self.data.generalslove[tostring(favoratecid)] and self.data.generalslove[tostring(favoratecid)].level or 0
    --

    local needsoaring = 0
    if general_awake[tostring(self.data.general.level2+1)] and general_awake[tostring(self.data.general.level2+1)].soaring_limit and general_awake[tostring(self.data.general.level2+1)].soaring_limit > 0 then
        needsoaring = general_awake[tostring(self.data.general.level2+1)].soaring_limit
    end  

    --ui.setMobileShopShow(self.rootItems.mobieshop,-102,8,propnum < needprop)
    
    ui.removeGray("CCControlButton",self.rootItems.tupobuntton)
    ui.removeGray("CCLabelTTF",self.rootItems.tupotext)
    self.rootItems.tupobuntton:addHandleOfControlEvent(function()

        if needsoaring > self.data.general.level8 then
            runGamePrompt({msg = "飞升等级不足!"})
            return
        elseif needfavorate > favoratelevel then
            runGamePrompt({msg = gameConfig.strings:need_favorate_lv(needfavorate)})
            return
        elseif needawaken > self.data.general.skilllevel then
            runGamePrompt({msg = gameConfig.strings:string_common("popups","jxlvbz")})
            return
        elseif self.data.general.level1 < general_awake[tostring(self.data.general.level2+1)].level then
            runGamePrompt({msg = gameConfig.strings:string_common("popups","pslvbz")})
            return
        else
            for k,v in ipairs(self.tupo_needprops) do
                if not (v.hasnum and v.hasnum >= v.num) then
                    local propName = ui.IDconfig(v.cid).name
                    if ui.IDconfig(v.cid).staffType == "general_fragment" then
                        propName = propName.."魂魄"
                    elseif ui.IDconfig(v.cid).staffType == "red_fragment" then
                        propName = propName.."精华"
                    end
                    runGamePrompt({msg = gameConfig.strings:notEnough(propName)})
                    return
                end    
            end    
            --
            if GameScene.roleinfo.coin < needcoin then
                shortCoin()
                return
            else
                gameTouch:clickprofbytime(1)
                self.tupodata = table.copy(self.data)
                if self.tupo_selectscope and self.tupo_selectscope > 0 then
                    local cb = function (  )
                        UIRequest({type = 1017, ids = {self.data.general.cid}, scope = self.tupo_selectscope or 0})
                    end
                    gameWindows:openWindow("goldBreakConfirm",self.tupo_selectscope,cb)
                else
                    UIRequest({type = 1017, ids = {self.data.general.cid}, scope = self.tupo_selectscope or 0})
                end
                return
            end
        end 

    end, CCControlEventTouchUpInside)    

end

function generalup.resetPage_tupo(self,data)
    self.rootItems.closeButton:setEnabled(false)
    self.rootItems.tupobuntton:setEnabled(false)
    local effectccb,effectitem = CCBReaderLoad("UIEffect/huobantupo/n_huobantupo", nil, true, "n_huobantupo")

    local animationManager = getAnimationManager(effectitem)
    animationManager:runAnimationsForSequenceNamed("n_huobantupo")

    if effectitem.topnode then
        effectitem.topnode:removeFromParentAndCleanup(false)
        self.rootItems.effectnode_top:addChild(effectitem.topnode)
        --effectitem.topnode:setPosition(0,0)
    end
    if effectitem.bottomnode then
        effectitem.bottomnode:removeFromParentAndCleanup(false)
        self.rootItems.effectnode_bottom:addChild(effectitem.bottomnode)
        --effectitem.bottomnode:setPosition(0,0)
    end

    if data and data.general then
        self.tupodata.nextGeneral = data.general
    end    
    local sequence = CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
        gameWindows:openWindow("generalupfinish",{data = table.copy(self.tupodata)},nil)
        self:ReloadData()
        self.rootItems.closeButton:setEnabled(true)
        self.rootItems.tupobuntton:setEnabled(true)

    end))
    self.rootItems.effectnode_top:runAction(sequence)


end

function generalup.executeXiulian(self)
    print("executeXiulian", self.xiuLianHave)
    self.autoXiulian = false

    if self.data.general and self.xiuLianData[self.data.general.iid] and self.xiuLianHave then
        --local xiuLianData = self.xiuLianData[self.data.general.iid]
        local config
        if self.xiulianType == 1 then
            config = gamedata.config.Immortal_level[tostring(1)][tostring(self.data.general.level6)]
        else
            config = gamedata.config.Immortal_level[tostring(2)][tostring(self.data.general.level7)]
        end
        if config.generalLevel > self.data.general.level1 then
            self.autoXiulian = false
            self:setXiuLianStateShow()
            return runGamePrompt({msg =  gameConfig.strings:string_common("general",32)})
        else
            for k,v in pairs(self.xiuLianProps) do
                if self.xiuLianHave[tostring(v.cid)] < v.num then
                    local name = ui.IDconfig(v.cid).name
                    self.autoXiulian = false
                    self:setXiuLianStateShow()
                    return runGamePrompt({msg = name..gameConfig.strings:string_common("friendcopy",2)})
                end
            end
        end
        local isBreak = 0
        if self.xiuLianData[self.data.general.iid]["heart"..self.xiulianType] >= config.character then
            isBreak = 1
        end
        -- gameTouch:clickprofbytime(1)
        self.autoXiulian = true
        self.isRefreshXiulianProps = 0
        self.xiuLianHave = nil
        UIRequest({type = 5513,iid = self.data.general.iid,xiuLian = self.xiulianType,isBreak = isBreak, useIds = self.xiuLianProps})
    end

    self:setXiuLianStateShow()
end

function generalup.setPage_xiulian(self)
    if self.rootItems.changeskillBtn then
        self.rootItems.changeskillBtn:setVisible(false)
    end 
    if self.rootItems.btn_jxRebirth then
        self.rootItems.btn_jxRebirth:setVisible(false)
    end

    self.rootItems.closeButton:setEnabled(true)
    self.rootItems.tupobuntton:setEnabled(true)
    self.rootItems.trainnode:setVisible(false)
    self.rootItems.upnode:setVisible(false)
    self.rootItems.xiuliannode:setVisible(true)
    self.rootItems.tuponode:setVisible(false)
    self.rootItems.newskillnode:setVisible(false)
    self.rootItems.trainnode:setPositionX(9999)
    self.rootItems.upnode:setPositionX(9999)
    self.rootItems.xiuliannode:setPositionX(0)
    self.rootItems.tuponode:setPositionX(9999)
    self.rootItems.newskillnode:setPositionX(9999)
    self.rootItems.juexingnode:setVisible(false)
    self.rootItems.juexingnode:setPositionX(9999)

    if not (self.generalsdata and self.generalsdata[tostring(self.generalindex)]) then return end
    self.data.general = self.generalsdata[tostring(self.generalindex)]
    
    self.rootItems.xl_select_button1:setSwallowsTouch(true)
    self.rootItems.xl_select_button1:setTouchPriority(-102)
    self.rootItems.xl_select_button1:addHandleOfControlEvent(function()
        if self.data.general and self.xiuLianData[self.data.general.iid] then
            self:setXiuLianStateShow(nil,1)
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.xl_select_button2:setSwallowsTouch(true)
    self.rootItems.xl_select_button2:setTouchPriority(-102)
    self.rootItems.xl_select_button2:addHandleOfControlEvent(function()
        if self.data.general and self.xiuLianData[self.data.general.iid] then
            self:setXiuLianStateShow(nil,2)
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.xiulianbuntton2:setSwallowsTouch(true)
    self.rootItems.xiulianbuntton2:setTouchPriority(-300)
    self.rootItems.xiulianbuntton2:addHandleOfControlEvent(function()
    end, CCControlEventTouchUpInside)

    self.rootItems.xiulianbuntton:setSwallowsTouch(true)
    self.rootItems.xiulianbuntton:setTouchPriority(-301)
    self.rootItems.xiulianbuntton:addHandleOfControlEvent(function()

        if self.autoXiulian then
            self.autoXiulian = false
            self:setXiuLianStateShow()
        else

            self:executeXiulian()
        end
        
    end, CCControlEventTouchUpInside)
    
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    
    if self.data.general.level2 > 13 then
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>=7 and 213 or 2*generalConfig.quality-1)
    else  
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)
    end
    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images[generalConfig.actor])
    end
    if generalConfig.awaken == 0 or self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, self.awakenConfig[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)    
    end

    local general_basic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    if tonumber(general_basic) >= 20 then
        if gamedata.config.global_kv["general_awaken"..general_basic] then
            local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
            if self.data.general.skilllevel <= general_awaken then
                if self.rootItems.juexing then
                    self.rootItems.juexing:setVisible(false)
                end
            end
        end
    end

    if self.rootItems.goldtypeNode then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.goldtypeNode:setVisible(true)
            setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope])
        else
            self.rootItems.goldtypeNode:setVisible(false)
        end    
    end   
    
    if not self.xiuLianData[self.data.general.iid] then
        UIRequest{type = 5512,iid = self.data.general.iid}
    else
        self:setXiuLianData()
    end
end

function generalup.getXiuLianData(self,t)
    self.xiuLianData[t.general.iid] = t.general
    if self.selectpage == "xiulian" and self.data.general.iid == t.general.iid then
        self:setXiuLianData()
    end
end

function generalup.setXiuLianData(self)
    local Immortal_level = gamedata.config.Immortal_level or {}
    local useQuality1 = (math.floor(self.data.general.level6/10) + 1) * 2 - 1
    self.rootItems.xiulian_name1:setString(gameConfig.strings:string_common("general",41)..(self.data.general.level6 > 0 and "+"..self.data.general.level6 or ""))
    local useQuality2 = (math.floor(self.data.general.level7/10) + 1) * 2 - 1
    self.rootItems.xiulian_name2:setString(gameConfig.strings:string_common("general",42)..(self.data.general.level7 > 0 and "+"..self.data.general.level7 or ""))

    local xiuLianData = self.xiuLianData[self.data.general.iid]
    local xiuLianAddData = self.xiuLianAddData[self.data.general.iid]
    for i = 1,3 do
        ui.setLabelString(self.rootItems["xiulian_atrn"..i],""..(xiuLianData["attr"..i] -  (xiuLianAddData and xiuLianAddData[i] or 0)),13)
        ui.setLabelString(self.rootItems["xiulian_atrn"..(i + 4)],""..(xiuLianData["attr"..(i + 4)] - (xiuLianAddData and xiuLianAddData[i + 4] or 0)),13)
    end
    local config1 = gamedata.config.Immortal_level[tostring(1)][tostring(self.data.general.level6)]
    local config2 = gamedata.config.Immortal_level[tostring(2)][tostring(self.data.general.level7)]
    ui.setLabelString(self.rootItems["xiulian_atrn"..4],config1.adddmgpct.."%",13)
    ui.setLabelString(self.rootItems["xiulian_atrn"..8],config2.subdmgpct.."%",13)

    if xiuLianAddData then
        for i = 1,3 do
            if xiuLianAddData[i] and xiuLianAddData[i] > 0 then
                ui.setLabelString(self.rootItems["xiulian_atrnA"..i],"+"..xiuLianAddData[i],22)
            else
                ui.setLabelString(self.rootItems["xiulian_atrnA"..i],"",22)
            end

            if xiuLianAddData[i + 4] and xiuLianAddData[i + 4] > 0 then
                ui.setLabelString(self.rootItems["xiulian_atrnA"..(i + 4)],"+"..xiuLianAddData[i + 4],22)
            else
                ui.setLabelString(self.rootItems["xiulian_atrnA"..(i + 4)],"",22)
            end
        end
    else
        for i = 1,3 do
            ui.setLabelString(self.rootItems["xiulian_atrnA"..i],"",22)
            ui.setLabelString(self.rootItems["xiulian_atrnA"..(i + 4)],"",22)
        end
    end
    
   
    self.rootItems.heartValue1:setString(xiuLianData.heart1)
    local percent = xiuLianData.heart1/config1.character
    self.rootItems.slideNode1:setPositionY(self.jinXiuB1 + percent * self.jinXiuT)
    self.rootItems.heartValue2:setString(xiuLianData.heart2)
    percent = xiuLianData.heart2/config2.character
    self.rootItems.slideNode2:setPositionY(self.jinXiuB2 + percent * self.jinXiuT)

    ui.setLabelString(self.rootItems.wenKeL,""..config2.character,61)
    ui.setLabelString(self.rootItems.liKeL,""..config1.character,61)

    self:setXiuLianStateShow()
end

function generalup.setXiuLianStateShow(self,t,xiuLianType)
    self.xiulianType = xiuLianType or self.xiulianType
    -- self.xiuLianHave = nil
    local xiuLianData = self.xiuLianData[self.data.general.iid]
    local config1 = gamedata.config.Immortal_level[tostring(1)][tostring(self.data.general.level6)]
    local config2 = gamedata.config.Immortal_level[tostring(2)][tostring(self.data.general.level7)]

    local cids
    local isNeedGet = true
    if self.xiulianType == 1 then
        if xiuLianData.heart1 >= config1.character then
            local configNext = gamedata.config.Immortal_level[tostring(1)][tostring(self.data.general.level6 + 1)]
            if not configNext then
                self.rootItems.xiulian_prop:setString(gameConfig.strings:string_common("equipInfo",13))
                isNeedGet = false
                self.rootItems.xiulianpropnode:setVisible(false)
            end
            cids = ui.getIDandNUMs(config1.extraConsume)
        else
            cids = ui.getIDandNUMs(config1.consumeEveryTimes)
        end
    else
        if xiuLianData.heart2 >= config2.character then
            local configNext = gamedata.config.Immortal_level[tostring(2)][tostring(self.data.general.level7 + 1)]
            if not configNext then
                self.rootItems.xiulian_prop:setString(gameConfig.strings:string_common("equipInfo",13))
                self.rootItems.xiulianpropnode:setVisible(false)
                isNeedGet = false
            end
            cids = ui.getIDandNUMs(config2.extraConsume)
        else
            cids = ui.getIDandNUMs(config2.consumeEveryTimes)
        end
    end
    local useConfig = self.xiulianType == 1 and config1 or config2
    ui.setLabelString(self.rootItems.xiuLian_condition,gameConfig.strings:needlv(self.data.general.level1,useConfig.generalLevel),(self.data.general.level1 < useConfig.generalLevel and 47 or 31))
    self.rootItems.likeT:setVisible(self.xiulianType == 1)
    self.rootItems.liKeB:setVisible(self.xiulianType == 2)
    self.rootItems.wenkeT:setVisible(self.xiulianType == 2)
    self.rootItems.WenKeB:setVisible(self.xiulianType == 1)

    if self.rootItems.heartSl1:numberOfRunningActions() > 0 and self.data.general.iid  == self.xiuLianGeneral then

    else
        local percent = xiuLianData.heart1/config1.character * 100
        self.rootItems.heartSl1:setPercentage(percent)
        self.rootItems.heartSl1:stopAllActions()
    end

    if self.rootItems.heartSl2:numberOfRunningActions() > 0 and self.data.general.iid  == self.xiuLianGeneral then
    
        
    else
        self.rootItems.heartSl2:stopAllActions()
        percent = xiuLianData.heart2/config2.character * 100
        self.rootItems.heartSl2:setPercentage(percent)
    end
    self.xiuLianGeneral = self.data.general.iid
    

    if self.autoXiulian then
         ui.setLabelString(self.rootItems.xiuliantext,gameConfig.strings:string_common("popups","quxiao"),19)
         setControlButtonFrame(self.rootItems.xiulianbuntton,"b_s_button1","b_s_button1_h","b_s_button1")


    else
        if self.xiulianType == 1 then
            ui.setLabelString(self.rootItems.xiuliantext,gameConfig.strings:string_common("general",41),19)
        else
            ui.setLabelString(self.rootItems.xiuliantext,gameConfig.strings:string_common("general",42),19)
        end
        setControlButtonFrame(self.rootItems.xiulianbuntton,"b_s_button2","b_s_button2_h","b_s_button2")
    end

    self.rootItems.xiulianbuntton2:setEnabled(self.autoXiulian)

    if isNeedGet then
        self.xiuLianProps = cids
        local getIds = {}
        for k,v in ipairs(self.xiuLianProps) do
            table.insert(getIds,v.cid)
        end
        return UIRequest({type = 12001,order = 33015, cids = getIds})
    end
end

function generalup.getXiulianProp(self, t)
    if self.isRefreshXiulianProps == 0 then
        self.isRefreshXiulianProps = 1
        self:ReloadData()
    elseif self.isRefreshXiulianProps == 1 then
        local xiuLianData = self.xiuLianData[self.data.general.iid]
        local config1 = gamedata.config.Immortal_level[tostring(1)][tostring(self.data.general.level6)]
        local config2 = gamedata.config.Immortal_level[tostring(2)][tostring(self.data.general.level7)]
        local isNeedGet = true
        local cids

        if self.xiulianType == 1 then
            if xiuLianData.heart1 >= config1.character then
                local configNext = gamedata.config.Immortal_level[tostring(1)][tostring(self.data.general.level6 + 1)]
                if not configNext then
                    self.rootItems.xiulian_prop:setString(gameConfig.strings:string_common("equipInfo",13))
                    isNeedGet = false
                    self.rootItems.xiulianpropnode:setVisible(false)
                end
                cids = ui.getIDandNUMs(config1.extraConsume)
            else
                cids = ui.getIDandNUMs(config1.consumeEveryTimes)
            end
        else
            if xiuLianData.heart2 >= config2.character then
                local configNext = gamedata.config.Immortal_level[tostring(2)][tostring(self.data.general.level7 + 1)]
                if not configNext then
                    self.rootItems.xiulian_prop:setString(gameConfig.strings:string_common("equipInfo",13))
                    self.rootItems.xiulianpropnode:setVisible(false)
                    isNeedGet = false
                end
                cids = ui.getIDandNUMs(config2.extraConsume)
            else
                cids = ui.getIDandNUMs(config2.consumeEveryTimes)
            end
        end
        self.isRefreshXiulianProps = nil

        if isNeedGet then
            self.xiuLianProps = cids
            local getIds = {}

            for k,v in ipairs(self.xiuLianProps) do
                table.insert(getIds,v.cid)
            end

            return UIRequest({type = 12001,order = 33015, cids = getIds})
        end
    end
end

function generalup.setXiuLianPropShow(self,t)
    self.rootItems.xiulianpropnode:setVisible(true)
    self.rootItems.xiulian_prop:setString(gameConfig.strings:string_common("general",46))
    self.xiuLianHave = nil

    if t then
        self.xiuLianHave = t
    end

    ui.setLabelString(self.rootItems.xiuLiancoinNum,"0",13)
    local setPropId = 1
    printT(self.xiuLianProps,"lipurposes xiuLianProps")
    for k,v in ipairs(self.xiuLianProps) do
        if v.cid == 1000 then
            ui.setLabelString(self.rootItems.xiuLiancoinNum,v.num,(t[tostring(1000)] >= v.num and 13 or 24))
        else
            self.rootItems["xiuLian_prop"..setPropId]:setVisible(true)
            ui.setNewIcon(self.rootItems,{cid=v.cid,num=((t[tostring(v.cid)] or 0).."/"..v.num)},8 + setPropId)
            local labT = (t[tostring(v.cid)] or 0) >= v.num and 13 or 24
            ui.setLabelString(self.rootItems["i_num".."_"..(8 + setPropId)],nil,labT)
            self.rootItems["i_button".."_"..(12 + setPropId)]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(v.cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button".."_"..(12 + setPropId)]:setTouchPriority(-104)
            setPropId = setPropId + 1
        end
    end
    for i = setPropId,3 do
        self.rootItems["xiuLian_prop"..i]:setVisible(false)
    end

    if self.autoXiulian == true then
        self.rootItems.xiuliannode:stopAllActions()
        self.rootItems.xiuliannode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
            print("AutoXiulian",self.autoXiulian)
            if self.selectpage == "xiulian" and self.autoXiulian and (not self.levelUp) then
                self:executeXiulian()
            else
                self.autoXiulian = false
                self:setXiuLianStateShow()
                
                self.rootItems.xiuliannode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()
                    for i = 1,8 do
                        if i ~= 4 and i ~= 8 then
                           self.xiuLianAddData[self.data.general.iid][i] = nil
                        end
                    end

                    self:setXiuLianData()
                    self:setXiuLianStateShow()
                end)))
            end
        end)))
    end
end

function generalup.xiuLianSuccess(self,t)
    if self.data.general.iid ~= t.general.iid then
        self:ReloadData()
        return
    end
    
    if not self.xiuLianAddData[t.general.iid] then
        self.xiuLianAddData[t.general.iid] = {}
    end
    for i = 1,8 do
        if i ~= 4 and i ~= 8 then
            local minus = t.generalXiuLian["attr"..i] - self.xiuLianData[t.general.iid]["attr"..i]
            if minus > 0 then
                self.xiuLianAddData[t.general.iid][i] = minus
            else
                self.xiuLianAddData[t.general.iid][i] = nil
            end
        end
        
    end
    
    if self.selectpage == "xiulian" then
        --self.rootItems.closeButton:setEnabled(false)
        --self.rootItems.xiulianbuntton:setEnabled(false)
        local effectccb1,effectitem1 = CCBReaderLoad("UIEffect/huobantupo/n_huobantupo", nil, true, "n_huobantupo")

        local animationManager1 = getAnimationManager(effectitem1)
        animationManager1:runAnimationsForSequenceNamed("n_huobantupo")

        if effectitem1.topnode then
            effectitem1.topnode:removeFromParentAndCleanup(false)
            self.rootItems.effectnode_top:addChild(effectitem1.topnode)
            
        end
        if effectitem1.bottomnode then
            effectitem1.bottomnode:removeFromParentAndCleanup(false)
            self.rootItems.effectnode_bottom:addChild(effectitem1.bottomnode)
        
        end
        local xiuLianNode = self.xiulianType == 1 and self.rootItems.heartSl1 or self.rootItems.heartSl2
        xiuLianNode:stopAllActions()
        local primePercent = xiuLianNode:getPercentage()
        local levelAdd = self.xiulianType == 1 and "6" or "7"
        local config
        self.levelUp = false
        if self.data.general["level"..levelAdd] == t.general["level"..levelAdd] then
            local xiuLianData = self.xiuLianData[self.data.general.iid]
            config = gamedata.config.Immortal_level[tostring(self.xiulianType)][tostring(self.data.general["level"..levelAdd])]
            --primePercent =  xiuLianNode:getPercentage()
        else
            config = gamedata.config.Immortal_level[tostring(self.xiulianType)][tostring(t.general["level"..levelAdd])]
            self.levelUp = true
        end
        --print("lipurposes ")
        local currentPercent = t.generalXiuLian["heart"..self.xiulianType]/config.character * 100
        local expTo = CCProgressFromTo:create(1,primePercent,currentPercent)
        xiuLianNode:runAction(expTo)
        
        
        
        self.rootItems.effectnode_bottom:stopAllActions()
        self.rootItems.effectnode_bottom:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.1), CCCallFunc:create(function()
            self.data.general = t.general   
            self.xiuLianData[t.general.iid] = t.generalXiuLian
            self:ReloadData()
        end)))

    end
    self.data.general = t.general   
    self.xiuLianData[t.general.iid] = t.generalXiuLian

    
end


function generalup.setPage_tupo(self)
    if self.rootItems.btn_jxRebirth then
        self.rootItems.btn_jxRebirth:setVisible(false)
    end

    self.rootItems.closeButton:setEnabled(true)
    self.rootItems.tupobuntton:setEnabled(true)
    self.rootItems.trainnode:setVisible(false)
    self.rootItems.upnode:setVisible(false)
    self.rootItems.xiuliannode:setVisible(false)
    self.rootItems.tuponode:setVisible(true)
    self.rootItems.newskillnode:setVisible(false)
    self.rootItems.trainnode:setPositionX(9999)
    self.rootItems.upnode:setPositionX(9999)
    self.rootItems.xiuliannode:setPositionX(9999)
    self.rootItems.tuponode:setPositionX(0)
    self.rootItems.newskillnode:setPositionX(0)
    self.rootItems.juexingnode:setVisible(false)
    self.rootItems.juexingnode:setPositionX(9999)
   

    if not (self.generalsdata and self.generalsdata[tostring(self.generalindex)]) then return end
    self.data.general = self.generalsdata[tostring(self.generalindex)]
    self.data.nextGeneral = nil

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local general_awake = gamedata.config.general_awake or {}

    if self.rootItems.btnRule and GameScene.roleinfo.level >= 100 then
        self.rootItems.btnRule:setVisible(true)
        self.rootItems["btnRule"]:setTouchPriority(-105)
        self.rootItems["btnRule"]:addHandleOfControlEvent(function()
            gameWindows:openWindow("scope_rule")
        end, CCControlEventTouchUpInside)
    end

    if self.rootItems.changeskillBtn then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.changeskillBtn:setVisible(true)
            self.rootItems.changeskillBtn:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)

                if self.data.general.illusionGeneralCid then

                    local cb = function (opt)
                        gameWindows:openWindow("changebreakskill",{general = table.copy(self.data.general),selectIllusion = opt},nil)
                    end

                    gameWindows:openWindow("changeSkillIllusion",self.data.general,cb)
                else
                    gameWindows:openWindow("changebreakskill",{general = table.copy(self.data.general)},nil)
                end

            end, CCControlEventTouchUpInside)
            self.rootItems.changeskillBtn:setSwallowsTouch(true)
            self.rootItems.changeskillBtn:setTouchPriority(-103)
        else
            self.rootItems.changeskillBtn:setVisible(false)
            self.rootItems.changeskillBtn:addHandleOfControlEvent(function()
                gameTouch:clickprofbytime(0.5)
                --
            end, CCControlEventTouchUpInside)
            self.rootItems.changeskillBtn:setSwallowsTouch(true)
            self.rootItems.changeskillBtn:setTouchPriority(-103)
        end
    end 

    local maxlv = table.getTableLength(general_awake) or 10
    if (generalConfig.gold_id and generalConfig.gold_id > 0) or generalConfig.quality >= 7 then
        maxlv = table.getTableLength(general_awake) or 10
    elseif (generalConfig.break_id and generalConfig.break_id > 0) or generalConfig.quality == 6 then
        for i = 1,table.getTableLength(general_awake) do
            if general_awake[tostring(i)].gold_will_labal and general_awake[tostring(i)].gold_will_labal == 1 then
                maxlv = i-1
                break
            end
        end
    else
        for i = 1,table.getTableLength(general_awake) do
            if general_awake[tostring(i)].labal and general_awake[tostring(i)].labal == 1 then
                maxlv = i-1
                break
            end
        end
    end

    print("maxlv:  "..maxlv)

    if self.data.general.level2 > 13 then
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>=7 and 213 or 2*generalConfig.quality-1)
    else  
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)
    end
    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images[generalConfig.actor])
    end

    if generalConfig.awaken == 0 or self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, self.awakenConfig[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)    
    end

    local general_basic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    if tonumber(general_basic) >= 20 then
        if gamedata.config.global_kv["general_awaken"..general_basic] then
            local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
            if self.data.general.skilllevel <= general_awaken then
                if self.rootItems.juexing then
                    self.rootItems.juexing:setVisible(false)
                end
            end
        end
    end

    if self.rootItems.goldtypeNode then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.goldtypeNode:setVisible(true)
            setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope])
            --
            setSpriteFrameByName(self.rootItems.goldtype_now,"tujin_"..self.scopetype[self.data.general.scope])
            --
            self.rootItems.oldattr:setPositionY(-230)
            self.rootItems.newattr:setVisible(true)
        else
            self.rootItems.goldtypeNode:setVisible(false)
            --
            setSpriteFrameByName(self.rootItems.goldtype_now,"alpha")
            --
            self.rootItems.oldattr:setPositionY(0)
            self.rootItems.newattr:setVisible(false)
        end    
    end   

    ui.setLabelString(self.rootItems.tupo_atk,self.data.general.atk,14)
    ui.setLabelString(self.rootItems.tupo_def,self.data.general.defense,14)
    ui.setLabelString(self.rootItems.tupo_hp,self.data.general.hp,14)
    ui.setLabelString(self.rootItems.tupo_speed,self.data.general.speed,14)

    ui.setLabelString(self.rootItems.tupo_g_atk,self.data.general.g_atk or 0,14)
    ui.setLabelString(self.rootItems.tupo_g_def,self.data.general.g_defense or 0,14)
    ui.setLabelString(self.rootItems.tupo_g_hp,self.data.general.g_hp or 0,14)


    self.tupo_needprops = {}
    if self.data.general.level2< maxlv then
        self.rootItems.tupo_title:setString("突破材料")
        self.rootItems.tupocontrolnode:setVisible(true)
        self.rootItems.tuponextattnode:setVisible(true)
        -- ui.setLabelString(self.rootItems.tupo_condition,"需要等级: "..self.data.general.level1.."/"..general_awake[tostring(self.data.general.level2+1)].level,(self.data.general.level1+0<general_awake[tostring(self.data.general.level2+1)].level+0 and 27 or 26))
        ui.setLabelString(self.rootItems.tupo_condition,gameConfig.strings:needlv(self.data.general.level1,general_awake[tostring(self.data.general.level2+1)].level),(self.data.general.level1+0<general_awake[tostring(self.data.general.level2+1)].level+0 and 24 or 22))
        if general_awake[tostring(self.data.general.level2+1)] and general_awake[tostring(self.data.general.level2+1)].soaring_limit and general_awake[tostring(self.data.general.level2+1)].soaring_limit > 0 then
            ui.setLabelString(self.rootItems.tupo_condition,"需要飞升等级: "..gamedata.config.partner_soaring[tostring(general_awake[tostring(self.data.general.level2+1)].soaring_limit)].name,(self.data.general.level8+0<general_awake[tostring(self.data.general.level2+1)].soaring_limit+0 and 24 or 22))
        end    

        local needprops = {}
        local getCIds = {}
        local nextquality = generalConfig.quality
        if self.data.general.level2+1 > 13 then
            nextquality = 7
        elseif self.data.general.level2+1 > 10 then
            nextquality = 6
        end
        if general_awake[tostring(self.data.general.level2+1)][tostring(nextquality).."prop"] and general_awake[tostring(self.data.general.level2+1)][tostring(nextquality).."prop"] > 0 then
            table.insert(needprops,{cid = 20017, num = general_awake[tostring(self.data.general.level2+1)][tostring(nextquality).."prop"]})
            table.insert(getCIds,20017)
        end
        --   
        
        if general_awake[tostring(self.data.general.level2+1)][tostring(nextquality).."piece"] and general_awake[tostring(self.data.general.level2+1)][tostring(nextquality).."piece"] > 0 then
            local fcid = gamedata.getOriginCid(self.data.general.cid)
            local fragmentcid = self.data.general.cid
            for k,v in pairs(gamedata.config.general_fragment) do
                if v.general == fcid then fragmentcid = v.id end
            end
            --
            table.insert(needprops,{cid = fragmentcid, num = general_awake[tostring(self.data.general.level2+1)][tostring(nextquality).."piece"]})
            table.insert(getCIds,fragmentcid)
        end
        --
        if general_awake[tostring(self.data.general.level2+1)]["red_cost"] and general_awake[tostring(self.data.general.level2+1)]["red_cost"] > 0 then
            table.insert(needprops,{cid = 20354, num = general_awake[tostring(self.data.general.level2+1)]["red_cost"]})
            table.insert(getCIds,20354)
        end
        --
        if general_awake[tostring(self.data.general.level2+1)]["red_item"] and general_awake[tostring(self.data.general.level2+1)]["red_item"] > 0 then
            local redcid = self.data.general.cid
            local redfragmentcid = self.data.general.cid
            if generalConfig.red_id and generalConfig.red_id > 0 then
                redcid = generalConfig.red_id
            elseif generalConfig.break_id and generalConfig.break_id > 0 then
                redcid = generalConfig.break_id
            elseif generalConfig.partner_id and generalConfig.partner_id > 0 then
                redcid = generalConfig.partner_id    
            end
            for k,v in pairs(gamedata.config.redl_awake_item) do
                if v.red_id == redcid then
                    redfragmentcid = v.id
                end
            end
            --
            table.insert(needprops,{cid = redfragmentcid, num = general_awake[tostring(self.data.general.level2+1)]["red_item"]})
            table.insert(getCIds,redfragmentcid)
        end
        --
        if general_awake[tostring(self.data.general.level2+1)]["red_cost2"] and general_awake[tostring(self.data.general.level2+1)]["red_cost2"] > 0 then
            table.insert(needprops,{cid = 20551, num = general_awake[tostring(self.data.general.level2+1)]["red_cost2"]})
            table.insert(getCIds,20551)
        end
        --
        if general_awake[tostring(self.data.general.level2+1)]["gold_cost"] and general_awake[tostring(self.data.general.level2+1)]["gold_cost"] ~= "" then
            local needs = ui.getIDandNUMs(general_awake[tostring(self.data.general.level2+1)]["gold_cost"])
            if needs and next(needs) then
                for k,v in pairs(needs) do
                    table.insert(needprops,v)
                    table.insert(getCIds,v.cid)
                end    
            end
        end
        --
        for i = 1,5 do
            if needprops[i] then
                self.rootItems["tupo_propnode"..i]:setVisible(true)
                ui.setNewIcon(self.rootItems,needprops[i],i-1)
                self.rootItems["i_button_"..(i+3)]:addHandleOfControlEvent(function()
                    gameWindows:openWindow("dropTips",{cid = needprops[i].cid},nil)
                end, CCControlEventTouchUpInside)
                self.rootItems["i_button_"..(i+3)]:setSwallowsTouch(true)
                self.rootItems["i_button_"..(i+3)]:setTouchPriority(-103)
            else 
                self.rootItems["tupo_propnode"..i]:setVisible(false)
                --
                self.rootItems["i_button_"..(i+3)]:addHandleOfControlEvent(function()
                    --
                end, CCControlEventTouchUpInside)
                self.rootItems["i_button_"..(i+3)]:setSwallowsTouch(true)
                self.rootItems["i_button_"..(i+3)]:setTouchPriority(-103)
            end
        end    
        --
        self.tupo_needprops = table.copy(needprops)
        if getCIds and next(getCIds) then
            UIRequest({type = 12001,order = 33020, cids = getCIds})
        end    
        --

        if not self.nextgenerals[tostring(self.data.general.iid)] then
            UIRequest({type = 1023,general = self.data.general.iid})
        else
            self:setTupoNext(self.nextgenerals[tostring(self.data.general.iid)])
        end

    else
        ui.setLabelString(self.rootItems.tupo_condition,"",48)       
        self.rootItems.tuponextattnode:setVisible(false)
        self.rootItems.tupocontrolnode:setVisible(false)
        self.rootItems.tupo_title:setString("已到达最高阶")
        ui.setLabelString(self.rootItems.tupo_condition2,"",48)
    end

    ui.setLabelString(self.rootItems.tupotext,nil,19)
end

function generalup.setTupoPropNum(self,data)
    for k,v in ipairs(self.tupo_needprops) do
        if data and data[tostring(v.cid)] then
            v.hasnum = data[tostring(v.cid)]
        end    
    end    
    --
    if self.selectpage == "tupo" then
        for k,v in ipairs(self.tupo_needprops) do
            ui.setLabelString(self.rootItems["i_num"..((k>1) and ("_"..(k-1)) or "")],(v.hasnum or 0).."/"..v.num, (v.hasnum or 0) >= v.num and 13 or 24)
        end    
    end    
end    
    ----------

    -----------------------------------------------------------------

function generalup.setPage_train(self)
        if self.rootItems.changeskillBtn then
            self.rootItems.changeskillBtn:setVisible(false)
        end 
        if self.rootItems.btn_jxRebirth then
            self.rootItems.btn_jxRebirth:setVisible(false)
        end
        self.rootItems.trainnode:setVisible(true)
        self.rootItems.upnode:setVisible(false)
        self.rootItems.tuponode:setVisible(false)
        self.rootItems.newskillnode:setVisible(false)
        self.rootItems.trainnode:setPositionX(0)
        self.rootItems.upnode:setPositionX(9999)
        self.rootItems.tuponode:setPositionX(9999)
        self.rootItems.newskillnode:setPositionX(9999)
        self.rootItems.juexingnode:setVisible(false)
        self.rootItems.juexingnode:setPositionX(9999)
        self.rootItems.xiuliannode:setVisible(false)
        self.rootItems.xiuliannode:setPositionX(9999)

        if not (self.generalsdata and self.generalsdata[tostring(self.generalindex)]) then return end
        self.data.general = self.generalsdata[tostring(self.generalindex)]

        local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]

        if self.data.general.level2 > 13 then
            ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>=7 and 213 or 2*generalConfig.quality-1)
        else  
            ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)
        end
        if not gameConfig.images[generalConfig.actor] then
            setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images.alpha)
        else
            setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images[generalConfig.actor])
        end
        ui.setLabelString(self.rootItems.train_atk,self.data.general.atk,14)
        ui.setLabelString(self.rootItems.train_def,self.data.general.defense,14)
        ui.setLabelString(self.rootItems.train_hp,self.data.general.hp,14)
        ui.setLabelString(self.rootItems.train_speed,self.data.general.speed,14)

        ui.setLabelString(self.rootItems.train_num1,self.data.general.potential,13)

        if generalConfig.awaken == 0 or self.data.general.skilllevel <= 0 then
            self.rootItems.juexing:setVisible(false)
        else
            self.rootItems.juexing:setVisible(true)
            setSpriteFrameByName(self.rootItems.juexing_icon, self.awakenConfig[tostring(self.data.general.skilllevel)].icon )
            ui.setLabelString(self.rootItems.juexing_name, self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)    
        end

        local general_basic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
        if tonumber(general_basic) >= 20 then
            if gamedata.config.global_kv["general_awaken"..general_basic] then
                local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
                if self.data.general.skilllevel <= general_awaken then
                    if self.rootItems.juexing then
                        self.rootItems.juexing:setVisible(false)
                    end
                end
            end
        end

        if self.rootItems.goldtypeNode then
            if self.data.general.scope and self.data.general.scope > 0 then
                self.rootItems.goldtypeNode:setVisible(true)
                setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope])
            else
                self.rootItems.goldtypeNode:setVisible(false)
            end    
        end   

        if self.rootItems.train_lab1 then
            ui.setLabelString(self.rootItems.train_lab1,nil,14)
        end

        for i = 1,5 do
            self.rootItems["train_up_num"..i]:setString("")
            ui.setLabelString(self.rootItems["train_up_num"..i],nil,14)
        end
        ----
        if self.trainSelect == 2 then
            self.rootItems.train_isselect_normal:setVisible(false)
            self.rootItems.train_isselect_special:setVisible(true)
        else
            self.rootItems.train_isselect_normal:setVisible(true)
            self.rootItems.train_isselect_special:setVisible(false)
        end
        --
        self.rootItems.train_selectButton_normal:addHandleOfControlEvent(function()
            self.trainSelect = 1
            self.rootItems.train_isselect_normal:setVisible(true)
            self.rootItems.train_isselect_special:setVisible(false)
        end, CCControlEventTouchUpInside)
        self.rootItems.train_selectButton_normal:setSwallowsTouch(true)
        self.rootItems.train_selectButton_normal:setTouchPriority(-103)

        self.rootItems.train_selectButton_special:addHandleOfControlEvent(function()
            self.trainSelect = 2
            self.rootItems.train_isselect_normal:setVisible(false)
            self.rootItems.train_isselect_special:setVisible(true)
        end, CCControlEventTouchUpInside)
        self.rootItems.train_selectButton_special:setSwallowsTouch(true)
        self.rootItems.train_selectButton_special:setTouchPriority(-103)
        --


    ------
    UIRequest({type = 12001, order = 10101, cids = {20009}})

    self.trainiid = self.data.general.iid
    self.trainResuit = false
    if self.trainResuit then
        -- self.rootItems.trainLab1:setString("取 消")
        self.rootItems.trainLab1:setString(gameConfig.strings:string_common("generalInfo",12))
        ui.setLabelString(self.rootItems.trainLab1,nil,19)
        self.rootItems.trainButton1:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.trainResuit then
                self.trainResuit = false
                UIRequest({type = 1014, opt = 0 })
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton1:setSwallowsTouch(true)
        self.rootItems.trainButton1:setTouchPriority(-103)
        --
        -- self.rootItems.trainLab2:setString("确 定")
        self.rootItems.trainLab2:setString(gameConfig.strings:string_common("generalInfo",13))
        ui.setLabelString(self.rootItems.trainLab2,nil,19)
        self.rootItems.trainButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.trainResuit then
                self.trainResuit = false
                UIRequest({type = 1014, opt = 1 })
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton2:setSwallowsTouch(true)
        self.rootItems.trainButton2:setTouchPriority(-103)

        --todo自动培养
        self.rootItems.trainLab3:setString(gameConfig.strings:string_common("generalInfo",40))
        ui.setLabelString(self.rootItems.trainLab3,nil,19)

        ui.addGray("CCControlButton",self.rootItems.trainButton3)
        ui.addGray("CCLabelTTF",self.rootItems.trainLab3)

        self.rootItems.trainButton3:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            runGamePrompt({msg = "培养状态不保存，无法继续培养"})
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton3:setSwallowsTouch(true)
        self.rootItems.trainButton3:setTouchPriority(-103)
    else
        -- self.rootItems.trainLab1:setString("培养一次")
        self.rootItems.trainLab1:setString(gameConfig.strings:string_common("generalInfo",14))
        ui.setLabelString(self.rootItems.trainLab1,nil,19)
        self.rootItems.trainButton1:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.data.general.level1 > 1 then
                UIRequest({type = 1013, id = self.data.general.iid, method = ((self.trainSelect == 2) and 3 or 1), extGeneralData = self.data.general})
            else
                runGamePrompt({msg = "1级伙伴无法培养"})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton1:setSwallowsTouch(true)
        self.rootItems.trainButton1:setTouchPriority(-103)

        -- self.rootItems.trainLab2:setString("培养十次")
        self.rootItems.trainLab2:setString(gameConfig.strings:string_common("generalInfo",15))
        ui.setLabelString(self.rootItems.trainLab2,nil,19)
        self.rootItems.trainButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.data.general.level1 > 1 then
                UIRequest({type = 1013, id = self.data.general.iid, method = ((self.trainSelect == 2) and 4 or 2), extGeneralData = self.data.general})
            else
                runGamePrompt({msg = "1级伙伴无法培养"})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton2:setSwallowsTouch(true)
        self.rootItems.trainButton2:setTouchPriority(-103)

        --todo自动培养
        self.rootItems.trainLab3:setString(gameConfig.strings:string_common("generalInfo",40))
        ui.setLabelString(self.rootItems.trainLab3,nil,19)

        ui.removeGray("CCControlButton",self.rootItems.trainButton3)
        ui.removeGray("CCLabelTTF",self.rootItems.trainLab3)

        self.rootItems.trainButton3:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.data.general.level1 > 1 then
                --2精心 1粗略
                gameWindows:openWindow("generalcultivate",{iid = self.data.general.iid,method = ((self.trainSelect == 2) and 2 or 1), extGeneralData = self.data.general},nil)
            else
                runGamePrompt({msg = "1级伙伴无法培养"})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton3:setSwallowsTouch(true)
        self.rootItems.trainButton3:setTouchPriority(-103)
    end
end

function generalup.setTrainPropNum(self,pdata)
    self.trainpropnum = pdata["20009"] or 0
    self.rootItems.train_num2:setString(self.trainpropnum)
    ui.setLabelString(self.rootItems.train_num2,nil,13)
end

function generalup.setTrainResuit(self,datas)

    if self.trainiid ~= datas.previewGeneralData.iid then return end
    if self.selectpage ~= "train" then return end

    self.trainResuit = true

    local dataTable = datas.extGeneralData
    local newData =  datas.previewGeneralData

    local up_num1 = newData.atk - dataTable.atk
    local up_num2 = newData.defense - dataTable.defense
    local up_num3 = newData.hp - dataTable.hp
    local up_num4 = newData.potential - dataTable.potential

    if math.abs(up_num1)>1000 then
        UIRequest({type=999988, msg="Train atk change: "..up_num1.." old "..dataTable.atk.." new "..newData.atk, from="ui",noneedfix = true})
    end
    if math.abs(up_num2)>1000 then
        UIRequest({type=999988, msg="Train defense change: "..up_num2.." old "..dataTable.defense.." new "..newData.defense, from="ui",noneedfix = true})
    end
    if math.abs(up_num3)>1000 then
        UIRequest({type=999988, msg="Train hp change: "..up_num3.." old "..dataTable.hp.." new "..newData.hp, from="ui",noneedfix = true})
    end
    if math.abs(up_num4)>1000 then
        UIRequest({type=999988, msg="Train potential change: "..up_num4.." old "..dataTable.potential.." new "..newData.potential, from="ui",noneedfix = true})
    end


    self.rootItems.train_up_num5:setString("-"..datas.prop or 0)
    self.rootItems.train_up_num5:setColor(ccc3(255,8,8))
    ui.setLabelString(self.rootItems.train_up_num5,nil,24)

    if up_num1 < 0 then
        self.rootItems.train_up_num1:setString("- "..0-up_num1)
        self.rootItems.train_up_num1:setColor(ccc3(255,8,8))
        ui.setLabelString(self.rootItems.train_up_num1,nil,24)
    elseif up_num1 > 0 then
        self.rootItems.train_up_num1:setString("+ "..up_num1)
        self.rootItems.train_up_num1:setColor(ccc3(78,162,52))
        ui.setLabelString(self.rootItems.train_up_num1,nil,23)
    else
        self.rootItems.train_up_num1:setString(" ")
        self.rootItems.train_up_num1:setColor(ccc3(78,162,52))
        ui.setLabelString(self.rootItems.train_up_num1,nil,23)
    end

    if up_num2 < 0 then
        self.rootItems.train_up_num2:setString("- "..0-up_num2)
        self.rootItems.train_up_num2:setColor(ccc3(255,8,8))
        ui.setLabelString(self.rootItems.train_up_num2,nil,24)
    elseif up_num2 > 0 then
        self.rootItems.train_up_num2:setString("+ "..up_num2)
        self.rootItems.train_up_num2:setColor(ccc3(78,162,52))
        ui.setLabelString(self.rootItems.train_up_num2,nil,23)
    else
        self.rootItems.train_up_num2:setString(" ")
        self.rootItems.train_up_num2:setColor(ccc3(78,162,52))
        ui.setLabelString(self.rootItems.train_up_num2,nil,23)
    end

    if up_num3 < 0 then
        self.rootItems.train_up_num3:setString("- "..0-up_num3)
        self.rootItems.train_up_num3:setColor(ccc3(255,8,8))
        ui.setLabelString(self.rootItems.train_up_num3,nil,24)
    elseif up_num3 > 0 then
        self.rootItems.train_up_num3:setString("+ "..up_num3)
        self.rootItems.train_up_num3:setColor(ccc3(78,162,52))
        ui.setLabelString(self.rootItems.train_up_num3,nil,23)
    else
        self.rootItems.train_up_num3:setString(" ")
        self.rootItems.train_up_num3:setColor(ccc3(78,162,52))
        ui.setLabelString(self.rootItems.train_up_num3,nil,23)
    end

    if up_num4 < 0 then
        self.rootItems.train_up_num4:setString("-"..0-up_num4)
        self.rootItems.train_up_num4:setColor(ccc3(255,8,8))
        ui.setLabelString(self.rootItems.train_up_num4,nil,24)
    elseif up_num4 > 0 then
        self.rootItems.train_up_num4:setString("+"..up_num4)
        self.rootItems.train_up_num4:setColor(ccc3(78,162,52))
        ui.setLabelString(self.rootItems.train_up_num4,nil,23)
    else
        self.rootItems.train_up_num4:setString(" ")
        self.rootItems.train_up_num4:setColor(ccc3(78,162,52))
        ui.setLabelString(self.rootItems.train_up_num4,nil,23)
    end

    if self.trainResuit then
        -- self.rootItems.trainLab1:setString("取 消")
        self.rootItems.trainLab1:setString(gameConfig.strings:string_common("generalInfo",12))
        ui.setLabelString(self.rootItems.trainLab1,nil,19)
        self.rootItems.trainButton1:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.trainResuit then
                self.trainResuit = false
                UIRequest({type = 1014, opt = 0 })
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton1:setSwallowsTouch(true)
        self.rootItems.trainButton1:setTouchPriority(-103)
        --
        -- self.rootItems.trainLab2:setString("确 定")
        self.rootItems.trainLab2:setString(gameConfig.strings:string_common("generalInfo",13))
        ui.setLabelString(self.rootItems.trainLab2,nil,19)
        self.rootItems.trainButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.trainResuit then
                self.trainResuit = false
                UIRequest({type = 1014, opt = 1 })
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton2:setSwallowsTouch(true)
        self.rootItems.trainButton2:setTouchPriority(-103)


        --todo自动培养
        self.rootItems.trainLab3:setString(gameConfig.strings:string_common("generalInfo",40))
        ui.setLabelString(self.rootItems.trainLab3,nil,19)

        ui.addGray("CCControlButton",self.rootItems.trainButton3)
        ui.addGray("CCLabelTTF",self.rootItems.trainLab3)

        self.rootItems.trainButton3:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            runGamePrompt({msg = "培养状态不保存，无法继续培养"})
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton3:setSwallowsTouch(true)
        self.rootItems.trainButton3:setTouchPriority(-103)

    else
        
        -- self.rootItems.trainLab1:setString("培养一次")
        self.rootItems.trainLab1:setString(gameConfig.strings:string_common("generalInfo",14))
        ui.setLabelString(self.rootItems.trainLab1,nil,19)
        self.rootItems.trainButton1:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.data.general.level1 > 1 then
                UIRequest({type = 1013, id = self.data.general.iid, method = ((self.trainSelect == 2) and 3 or 1), extGeneralData = self.data.general})
            else
                runGamePrompt({msg = "1级伙伴无法培养"})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton1:setSwallowsTouch(true)
        self.rootItems.trainButton1:setTouchPriority(-103)

        -- self.rootItems.trainLab2:setString("培养十次")
        self.rootItems.trainLab2:setString(gameConfig.strings:string_common("generalInfo",15))
        ui.setLabelString(self.rootItems.trainLab2,nil,19)
        self.rootItems.trainButton2:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.data.general.level1 > 1 then
                UIRequest({type = 1013, id = self.data.general.iid, method = ((self.trainSelect == 2) and 4 or 2), extGeneralData = self.data.general})
            else
                runGamePrompt({msg = "1级伙伴无法培养"})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton2:setSwallowsTouch(true)
        self.rootItems.trainButton2:setTouchPriority(-103)

        --todo自动培养
        self.rootItems.trainLab3:setString(gameConfig.strings:string_common("generalInfo",40))
        ui.setLabelString(self.rootItems.trainLab3,nil,19)

        ui.removeGray("CCControlButton",self.rootItems.trainButton3)
        ui.removeGray("CCLabelTTF",self.rootItems.trainLab3)

        self.rootItems.trainButton3:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)
            if self.data.general.level1 > 1 then
                --2精心 1粗略
                gameWindows:openWindow("generalcultivate",{iid = self.data.general.iid,method = ((self.trainSelect == 2) and 2 or 1), extGeneralData = self.data.general},nil)
            else
                runGamePrompt({msg = "1级伙伴无法培养"})
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.trainButton3:setSwallowsTouch(true)
        self.rootItems.trainButton3:setTouchPriority(-103)
    end
    gamedata.music:PlayOptSound("py")
end



function generalup.setPage_up(self)
    if self.rootItems.changeskillBtn then
        self.rootItems.changeskillBtn:setVisible(false)
    end 
    if self.rootItems.btn_jxRebirth then
        self.rootItems.btn_jxRebirth:setVisible(false)
    end
    self.rootItems.trainnode:setVisible(false)
    self.rootItems.upnode:setVisible(true)
    self.rootItems.tuponode:setVisible(false)
    self.rootItems.newskillnode:setVisible(false)
    self.rootItems.trainnode:setPositionX(9999)
    self.rootItems.upnode:setPositionX(0)
    self.rootItems.tuponode:setPositionX(9999)
    self.rootItems.newskillnode:setPositionX(9999)
    self.rootItems.juexingnode:setVisible(false)
    self.rootItems.juexingnode:setPositionX(9999)
    self.rootItems.xiuliannode:setVisible(false)
    self.rootItems.xiuliannode:setPositionX(9999)

    self:initUpChangeBtn()
    if not (self.generalsdata and self.generalsdata[tostring(self.generalindex)]) then return end
    self.data.general = self.generalsdata[tostring(self.generalindex)]

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]

    if self.data.general.level2 > 13 then
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>=7 and 213 or 2*generalConfig.quality-1)
    else  
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)
    end
    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images[generalConfig.actor])
    end
    if generalConfig.awaken == 0 or self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, self.awakenConfig[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)    
    end

    local general_basic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    if tonumber(general_basic) >= 20 then
        if gamedata.config.global_kv["general_awaken"..general_basic] then
            local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
            if self.data.general.skilllevel <= general_awaken then
                if self.rootItems.juexing then
                    self.rootItems.juexing:setVisible(false)
                end
            end
        end
    end

    if self.rootItems.goldtypeNode then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.goldtypeNode:setVisible(true)
            setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope])
        else
            self.rootItems.goldtypeNode:setVisible(false)
        end    
    end   

    ui.setLabelString(self.rootItems.up_atk,(generalConfig["atk"]+generalConfig["atk-grow"]*(self.data.general.level1-1)),14)
    ui.setLabelString(self.rootItems.up_def,(generalConfig["def"]+generalConfig["def-grow"]*(self.data.general.level1-1)),14)
    ui.setLabelString(self.rootItems.up_hp,(generalConfig["hp"]+generalConfig["hp-grow"]*(self.data.general.level1-1)),14)
    ui.setLabelString(self.rootItems.up_speed,(generalConfig["speed"]+generalConfig["speed-grow"]*(self.data.general.level1-1)),14)
    --
    ui.setLabelString(self.rootItems.up_next_atk,(generalConfig["atk"]+generalConfig["atk-grow"]*self.data.general.level1),14)
    ui.setLabelString(self.rootItems.up_next_def,(generalConfig["def"]+generalConfig["def-grow"]*self.data.general.level1),14)
    ui.setLabelString(self.rootItems.up_next_hp,(generalConfig["hp"]+generalConfig["hp-grow"]*self.data.general.level1),14)
    ui.setLabelString(self.rootItems.up_next_speed,(generalConfig["speed"]+generalConfig["speed-grow"]*self.data.general.level1),14)
    --
    ------------------

    self.expup =
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

        maxlv = 1,
        l_exp = 0,
        l_level = 0,
        o_level = 0,
        quality = 2,
        up_exp = 0,
        up_exp1 = 0,

    }

    self.expup.quality = generalConfig.quality or 3

    self.expup.l_exp = self.data.general.exp or 0
    self.expup.l_level = self.data.general.level1 or 1
    self.expup.maxlv = gamedata.config.global_kv and tonumber(gamedata.config.global_kv.general_level.value)*GameScene.roleinfo.level or 1
    if self.expup.maxlv > table.getTableLength(gamedata.config.general_exp) then
        self.expup.maxlv = table.getTableLength(gamedata.config.general_exp)
    end
    --
    if self.data.general.level1 >= self.expup.maxlv then
        self.rootItems.upnextattnode:setVisible(false)
    else
        self.rootItems.upnextattnode:setVisible(true)
    end
    --
    ------
    ui.setNewIconName(self.rootItems,{cid = 20196},0)
    ui.setNewIconName(self.rootItems,{cid = 20197},1)
    ui.setNewIconName(self.rootItems,{cid = 20198},2)
    ui.setNewIconName(self.rootItems,{cid = 20199},3)

    self.rootItems["in_button"]:addHandleOfControlEvent(function()
        if self.upChangeType then
            ui.setPopwindowByCid(20196)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["in_button"]:setSwallowsTouch(true)
    self.rootItems["in_button"]:setTouchPriority(-103)

    self.rootItems["in_button_1"]:addHandleOfControlEvent(function()
        if self.upChangeType then
            ui.setPopwindowByCid(20197)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["in_button_1"]:setSwallowsTouch(true)
    self.rootItems["in_button_1"]:setTouchPriority(-103)

    self.rootItems["in_button_2"]:addHandleOfControlEvent(function()
        if self.upChangeType then
            ui.setPopwindowByCid(20198)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["in_button_2"]:setSwallowsTouch(true)
    self.rootItems["in_button_2"]:setTouchPriority(-103)

    self.rootItems["in_button_3"]:addHandleOfControlEvent(function()
        if self.upChangeType then
            ui.setPopwindowByCid(20199)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems["in_button_3"]:setSwallowsTouch(true)
    self.rootItems["in_button_3"]:setTouchPriority(-103)

    self.expup.upnum1 = gamedata.config.props["20196"].param1 or 0
    self.expup.upnum2 = gamedata.config.props["20197"].param1 or 0
    self.expup.upnum3 = gamedata.config.props["20198"].param1 or 0
    self.expup.upnum4 = gamedata.config.props["20199"].param1 or 0

    self.rootItems.up_explab1:setString("EXP:"..self.expup.upnum1)
    self.rootItems.up_explab2:setString("EXP:"..self.expup.upnum2)
    self.rootItems.up_explab3:setString("EXP:"..self.expup.upnum3)
    self.rootItems.up_explab4:setString("EXP:"..self.expup.upnum4)


    UIRequest({type = 12001, order = 10401, cids = {20196,20197,20198,20199}})
    ----
    local beginFunc = function(index,quick)
        if not self.upChangeType then
            if quick then
                if self.expup["num"..index] == self.expup["l_num"..index] then return end
            else
                if self.expup["l_num"..index] < 1 then return end
            end

            self["effect_begin"..index] = false
            self["effect_end"..index] = false
            --
            self.rootItems["selectEffectNode"..index]:stopAllActions()
            self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
            local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/cailiaoxuanzhong/cailiaoxuanzhong", nil, true, "cailiaoxuanzhong")
            qianghuaNode:setPosition(0,0)
            self.rootItems["selectEffectNode"..index]:addChild(qianghuaNode)
            self.rootItems["selectEffectNode"..index]:setScale(1)
            local animationManager = getAnimationManager(qianghuaItems)
            animationManager:runAnimationsForSequenceNamed("zhenrongxuanzhong")
            --
            self.rootItems["selectEffectNode"..index]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
                self["effect_begin"..index] = true
                if self["effect_end"..index] then
                    self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
                end
            end)))
        end
    end

    local endFunc = function(index)
        if not self.upChangeType then
            self["effect_end"..index] = true
            if self["effect_begin"..index] then
                self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
            end
        end
    end
    --
    local Func1 = function(donum)
        if not self.upChangeType then
            local xdonum = donum or 1

            if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
                --runGamePrompt({msg = "经验值已满"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
                return
            end

            if self.expup.l_num1 < xdonum then
                xdonum = self.expup.l_num1
            end    

            local needmaxexp = 0-self.expup.l_exp
            local needmaxnum = 1
            for i = self.expup.l_level,(self.expup.maxlv-1) do
                needmaxexp = needmaxexp + gamedata.config.general_exp[tostring(i)][tostring(self.expup.quality)..'exp']
            end 
            if needmaxexp > 0 then   
                needmaxnum = math.ceil(needmaxexp/self.expup.upnum1) 
            end
            if xdonum > needmaxnum then
                xdonum = needmaxnum
            end

            if self.expup.l_num1 > 0 then
                self.expup.l_num1 = self.expup.l_num1-xdonum
                self.expup.l_exp = self.expup.l_exp+self.expup.upnum1*xdonum
                --runGamePrompt({msg = "经验+"..self.expup.upnum1})
                runGamePrompt({msg = gameConfig.strings:expNum(self.expup.upnum1*xdonum)})
            else
                --runGamePrompt({msg = "材料已消耗完"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
                endFunc(1)
            end

            while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
                if self.expup.l_level+1 > self.expup.maxlv then break end
                self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
                self.expup.l_level = self.expup.l_level + 1
            end

            self:setData_up(self.expup)
        end
    end

    local Func2 = function(donum)
        if not self.upChangeType then
            local xdonum = donum or 1

            if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
                --runGamePrompt({msg = "经验值已满"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
                return
            end

            if self.expup.l_num2 < xdonum then
                xdonum = self.expup.l_num2
            end    

            local needmaxexp = 0-self.expup.l_exp
            local needmaxnum = 1
            for i = self.expup.l_level,(self.expup.maxlv-1) do
                needmaxexp = needmaxexp + gamedata.config.general_exp[tostring(i)][tostring(self.expup.quality)..'exp']
            end 
            if needmaxexp > 0 then   
                needmaxnum = math.ceil(needmaxexp/self.expup.upnum2) 
            end
            if xdonum > needmaxnum then
                xdonum = needmaxnum
            end

            if self.expup.l_num2 > 0 then
                self.expup.l_num2 = self.expup.l_num2-xdonum
                self.expup.l_exp = self.expup.l_exp+self.expup.upnum2*xdonum
                --runGamePrompt({msg = "经验+"..self.expup.upnum2})
                runGamePrompt({msg = gameConfig.strings:expNum(self.expup.upnum2*xdonum)})
            else
                --runGamePrompt({msg = "材料已消耗完"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
                endFunc(2)
            end

            while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
                if self.expup.l_level+1 > self.expup.maxlv then break end
                self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
                self.expup.l_level = self.expup.l_level + 1
            end

            self:setData_up(self.expup)
        end
    end

    local Func3 = function(donum)
        if not self.upChangeType then
            local xdonum = donum or 1

            if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
                --runGamePrompt({msg = "经验值已满"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
                return
            end

            if self.expup.l_num3 < xdonum then
                xdonum = self.expup.l_num3
            end    

            local needmaxexp = 0-self.expup.l_exp
            local needmaxnum = 1
            for i = self.expup.l_level,(self.expup.maxlv-1) do
                needmaxexp = needmaxexp + gamedata.config.general_exp[tostring(i)][tostring(self.expup.quality)..'exp']
            end 
            if needmaxexp > 0 then   
                needmaxnum = math.ceil(needmaxexp/self.expup.upnum3) 
            end
            if xdonum > needmaxnum then
                xdonum = needmaxnum
            end

            if self.expup.l_num3 > 0 then
                self.expup.l_num3 = self.expup.l_num3-xdonum
                self.expup.l_exp = self.expup.l_exp+self.expup.upnum3*xdonum
                --runGamePrompt({msg = "经验+"..self.expup.upnum3})
                runGamePrompt({msg = gameConfig.strings:expNum(self.expup.upnum3*xdonum)})
            else
                --runGamePrompt({msg = "材料已消耗完"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
                endFunc(3)
            end

            while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
                if self.expup.l_level+1 > self.expup.maxlv then break end
                self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
                self.expup.l_level = self.expup.l_level + 1
            end

            self:setData_up(self.expup)
        end
    end

    local Func4 = function(donum)
        if not self.upChangeType then
            local xdonum = donum or 1

            if (self.expup.l_level+1 > self.expup.maxlv) then --and (self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']) then
                --runGamePrompt({msg = "经验值已满"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
                return
            end

            if self.expup.l_num4 < xdonum then
                xdonum = self.expup.l_num4
            end    

            local needmaxexp = 0-self.expup.l_exp
            local needmaxnum = 1
            for i = self.expup.l_level,(self.expup.maxlv-1) do
                needmaxexp = needmaxexp + gamedata.config.general_exp[tostring(i)][tostring(self.expup.quality)..'exp']
            end 
            if needmaxexp > 0 then   
                needmaxnum = math.ceil(needmaxexp/self.expup.upnum4) 
            end
            if xdonum > needmaxnum then
                xdonum = needmaxnum
            end

            if self.expup.l_num4 > 0 then
                self.expup.l_num4 = self.expup.l_num4-xdonum
                self.expup.l_exp = self.expup.l_exp+self.expup.upnum4*xdonum
                --runGamePrompt({msg = "经验+"..self.expup.upnum4})
                runGamePrompt({msg = gameConfig.strings:expNum(self.expup.upnum4*xdonum)})
            else
                --runGamePrompt({msg = "材料已消耗完"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
                endFunc(4)
            end

            while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
                if self.expup.l_level+1 > self.expup.maxlv then break end
                self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
                self.expup.l_level = self.expup.l_level + 1
            end

            self:setData_up(self.expup)
        end
    end

    local reduce1 = function(donum)
        if not self.upChangeType then
            local xdonum = donum or 1

            if (self.expup.l_num1+xdonum) > self.expup.num1 then
                xdonum = self.expup.num1-self.expup.l_num1 
            end    

            if self.expup.l_num1 < self.expup.num1 then
                self.expup.l_num1 = self.expup.l_num1+xdonum
                self.expup.l_exp = self.expup.l_exp-self.expup.upnum1*xdonum
            end

            while self.expup.l_exp < 0 do
                self.expup.up_exp1 = gamedata.config.general_exp[tostring(self.expup.l_level>1 and (self.expup.l_level-1) or 1)][tostring(self.expup.quality)..'exp']
                self.expup.l_exp = self.expup.l_exp + self.expup.up_exp1
                self.expup.l_level = self.expup.l_level - 1
                if self.expup.l_level < 1 then break end
            end

            self:setData_up(self.expup)
        end
    end

    local reduce2 = function(donum)
        if not self.upChangeType then
            local xdonum = donum or 1

            if (self.expup.l_num2+xdonum) > self.expup.num2 then
                xdonum = self.expup.num2-self.expup.l_num2 
            end    

            if self.expup.l_num2 < self.expup.num2 then
                self.expup.l_num2 = self.expup.l_num2+xdonum
                self.expup.l_exp = self.expup.l_exp-self.expup.upnum2*xdonum
            end

            while self.expup.l_exp < 0 do
                self.expup.up_exp1 = gamedata.config.general_exp[tostring(self.expup.l_level>1 and (self.expup.l_level-1) or 1)][tostring(self.expup.quality)..'exp']
                self.expup.l_exp = self.expup.l_exp + self.expup.up_exp1
                self.expup.l_level = self.expup.l_level - 1
                if self.expup.l_level < 1 then break end
            end

            self:setData_up(self.expup)
        end
    end
    local reduce3 = function(donum)
        if not self.upChangeType then
            local xdonum = donum or 1

            if (self.expup.l_num3+xdonum) > self.expup.num3 then
                xdonum = self.expup.num3-self.expup.l_num3
            end    

            if self.expup.l_num3 < self.expup.num3 then
                self.expup.l_num3 = self.expup.l_num3+xdonum
                self.expup.l_exp = self.expup.l_exp-self.expup.upnum3*xdonum
            end

            while self.expup.l_exp < 0 do
                self.expup.up_exp1 = gamedata.config.general_exp[tostring(self.expup.l_level>1 and (self.expup.l_level-1) or 1)][tostring(self.expup.quality)..'exp']
                self.expup.l_exp = self.expup.l_exp + self.expup.up_exp1
                self.expup.l_level = self.expup.l_level - 1
                if self.expup.l_level < 1 then break end
            end

            self:setData_up(self.expup)
        end
    end
    local reduce4 = function(donum)
        if not self.upChangeType then
            local xdonum = donum or 1

            if (self.expup.l_num4+xdonum) > self.expup.num4 then
                xdonum = self.expup.num4-self.expup.l_num4 
            end    

            if self.expup.l_num4 < self.expup.num4 then
                self.expup.l_num4 = self.expup.l_num4+xdonum
                self.expup.l_exp = self.expup.l_exp-self.expup.upnum4*xdonum
            end

            while self.expup.l_exp < 0 do
                self.expup.up_exp1 = gamedata.config.general_exp[tostring(self.expup.l_level>1 and (self.expup.l_level-1) or 1)][tostring(self.expup.quality)..'exp']
                self.expup.l_exp = self.expup.l_exp + self.expup.up_exp1
                self.expup.l_level = self.expup.l_level - 1
                if self.expup.l_level < 1 then break end
            end

            self:setData_up(self.expup)
        end
    end

    if not self.delaybutton then
        ui.creatDelayButton(self.rootItems["add1"],-103,Func1,beginFunc,endFunc,1)
        ui.creatDelayButton(self.rootItems["add2"],-103,Func2,beginFunc,endFunc,2)
        ui.creatDelayButton(self.rootItems["add3"],-103,Func3,beginFunc,endFunc,3)
        ui.creatDelayButton(self.rootItems["add4"],-103,Func4,beginFunc,endFunc,4)
    
        ui.creatDelayButton(self.rootItems["reduce1"],-103,reduce1)
        ui.creatDelayButton(self.rootItems["reduce2"],-103,reduce2)
        ui.creatDelayButton(self.rootItems["reduce3"],-103,reduce3)
        ui.creatDelayButton(self.rootItems["reduce4"],-103,reduce4)

        self.delaybutton = true
    end
    --
    local quickFunc1 = function()
        if (self.expup.l_level+1 > self.expup.maxlv) then
            return
        end

        if self.expup.l_num1 > 0 then
            self.expup.l_num1 = self.expup.l_num1-1
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum1
        else
            return
        end

        while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
            if self.expup.l_level+1 > self.expup.maxlv then break end
            self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
            self.expup.l_level = self.expup.l_level + 1
            if self.upChangeType then
                self.uplevel = self.uplevel + 1
            end
        end
    end
    local quickFunc2 = function()
        if (self.expup.l_level+1 > self.expup.maxlv) then
            return
        end

        if self.expup.l_num2 > 0 then
            self.expup.l_num2 = self.expup.l_num2-1
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum2
        else
            return
        end

        while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
            if self.expup.l_level+1 > self.expup.maxlv then break end
            self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
            self.expup.l_level = self.expup.l_level + 1
            if self.upChangeType then
                self.uplevel = self.uplevel + 1
            end
        end

    end
    local quickFunc3 = function()
        if (self.expup.l_level+1 > self.expup.maxlv) then
            isend = true
            return
        end

        if self.expup.l_num3 > 0 then
            self.expup.l_num3 = self.expup.l_num3-1
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum3
        else
            return
        end

        while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
            if self.expup.l_level+1 > self.expup.maxlv then break end
            self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
            self.expup.l_level = self.expup.l_level + 1
            if self.upChangeType then
                self.uplevel = self.uplevel + 1
            end
        end

    end
    local quickFunc4 = function()
        if (self.expup.l_level+1 > self.expup.maxlv) then
            return
        end

        if self.expup.l_num4 > 0 then
            self.expup.l_num4 = self.expup.l_num4-1
            self.expup.l_exp = self.expup.l_exp+self.expup.upnum4
        else
            return
        end

        while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
            if self.expup.l_level+1 > self.expup.maxlv then break end
            self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
            self.expup.l_level = self.expup.l_level + 1
            if self.upChangeType then
                self.uplevel = self.uplevel + 1
            end
        end

    end

    local quickFunc = function(num,isend)
        if (self.expup.l_level >= self.expup.maxlv) then
            return true
        end

        local _nextexp = gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] - self.expup.l_exp
        local _num = math.ceil(_nextexp / self.expup["upnum"..num])

        if self.expup["l_num"..num] < _num then
            _num = self.expup["l_num"..num]
        end

        self.expup["l_num"..num] = self.expup["l_num"..num] - _num
        self.expup.l_exp = self.expup.l_exp + self.expup["upnum"..num] * _num

        while self.expup.l_exp >= gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp'] do
            if self.expup.l_level >= self.expup.maxlv then break end
            self.expup.l_exp = self.expup.l_exp - gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
            self.expup.l_level = self.expup.l_level + 1
        end

        return false
    end

    local quickAdd = function(limit)
        if self.upChangeType then
            if (self.expup.l_level+1 > self.expup.maxlv) then
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
                return
            elseif (self.expup.num1+self.expup.num2+self.expup.num3+self.expup.num4)<1 then
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
                return
            end

            self.expup.l_num1 = self.expup.num1
            self.expup.l_num2 = self.expup.num2
            self.expup.l_num3 = self.expup.num3
            self.expup.l_num4 = self.expup.num4

            self.expup.l_exp = self.data.general.exp or 0
            self.expup.l_level = self.data.general.level1 or 1

            self.uplevel = 0
            for i=1,self.expup.l_num1 do
                if (self.expup.l_level < self.expup.maxlv) and (self.uplevel < limit) then
                    quickFunc1()
                else
                    break
                end
            end
            for i=1,self.expup.l_num2 do
                if (self.expup.l_level < self.expup.maxlv) and (self.uplevel < limit) then
                    quickFunc2()
                else
                    break
                end
            end
            for i=1,self.expup.l_num3 do
                if (self.expup.l_level < self.expup.maxlv) and (self.uplevel < limit) then
                    quickFunc3()
                else
                    break
                end
            end
            for i=1,self.expup.l_num4 do
                if (self.expup.l_level < self.expup.maxlv) and (self.uplevel < limit) then
                    quickFunc4()
                else
                    break
                end
            end

            print("quickAdd",self.uplevel,self.expup.l_level,self.expup.maxlv)
            -- self:setData_up(self.expup)
            -- for i = 1,4 do
            --     beginFunc(i,1)
            --     endFunc(i)
            -- end

            if self.expup.l_level <= self.expup.maxlv then
                local function func(  )
                    gameTouch:clickprofbytime(1)
                    local props = {}
                    table.insert(props,{cid = 20196, num = self.expup.num1 - self.expup.l_num1})
                    table.insert(props,{cid = 20197, num = self.expup.num2 - self.expup.l_num2})
                    table.insert(props,{cid = 20198, num = self.expup.num3 - self.expup.l_num3})
                    table.insert(props,{cid = 20199, num = self.expup.num4 - self.expup.l_num4})
                    UIRequest({type = 1038, iid = self.data.general.iid, cid = self.data.general.cid, props = props})
                end

                if (self.uplevel < limit) and (self.expup.l_level < self.expup.maxlv) then
                    gameWindows:openWindow("confirm",{msg = "当前经验丹不满足升级条件，是否全部使用？"}, func)
                else
                    func()
                end
            else
                runGamePrompt({msg = "数据出错！"})
            end
        else
            for i = 1, 4 do
                local isend = false

                while self.expup["l_num"..i] > 0 do
                    if isend then
                        break
                    end

                    isend = quickFunc(i,isend)
                end
            end 

            self:setData_up(self.expup)

            for i = 1,4 do
                beginFunc(i, 1)
                endFunc(i)
            end
        end
    end

    -----
    self.rootItems.upButton2:addHandleOfControlEvent(function()
        if self.upChangeType then
            quickAdd(5)
        else
            if (self.expup.l_level+1 > self.expup.maxlv) then
                --runGamePrompt({msg = "经验值已满"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            elseif (self.expup.num1+self.expup.num2+self.expup.num3+self.expup.num4)<1 then
                --runGamePrompt({msg = "材料已消耗完"})
                runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            else
                quickAdd()
            end

            if guide.controller then
                guide.controller:UIComplete(8047)
            end
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.upButton2:setSwallowsTouch(true)
    self.rootItems.upButton2:setTouchPriority(-103)
    --
    if self.rootItems.upButton1 then
        self.rootItems.upButton1:addHandleOfControlEvent(function()
            if self.upChangeType then
                quickAdd(1)

                if guide.controller then
                    guide.controller:UIComplete(8047)
                end
            else
                gameTouch:clickprofbytime(1)

                local props = {}

                table.insert(props,{cid = 20196, num = self.expup.num1 - self.expup.l_num1})
                table.insert(props,{cid = 20197, num = self.expup.num2 - self.expup.l_num2})
                table.insert(props,{cid = 20198, num = self.expup.num3 - self.expup.l_num3})
                table.insert(props,{cid = 20199, num = self.expup.num4 - self.expup.l_num4})

                if (self.expup.num1+self.expup.num2+self.expup.num3+self.expup.num4-self.expup.l_num1-self.expup.l_num2-self.expup.l_num3-self.expup.l_num4)<1 then
                    runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",19)})
                else
                    UIRequest({type = 1038, iid = self.data.general.iid, cid = self.data.general.cid, props = props})
                    self.isNotUpChangeType = true
                end
            end
        end, CCControlEventTouchUpInside)
        self.rootItems.upButton1:setSwallowsTouch(true)
        self.rootItems.upButton1:setTouchPriority(-103)
    end
    --
    local nextexp = 0
    if self.data.general.level1 <= self.expup.maxlv then
        nextexp = gamedata.config.general_exp[tostring(self.data.general.level1)][tostring(self.expup.quality)..'exp']
    end

    local processNum = 100*((self.data.general.exp>=nextexp) and 1 or (self.data.general.exp / nextexp))
    local expTo = CCProgressFromTo:create(0,0,processNum)
    self.rootItems.up_expSprite:runAction(expTo)
    --ui.setSpriteTextureRect2(self.rootItems["up_expSprite"],0,0,844 * ((self.data.general.exp>=nextexp) and 1 or (self.data.general.exp / nextexp)),self.rootItems["up_expSprite_add"]:getContentSize().height)
    ui.setSpriteTextureRect2(self.rootItems["up_expSprite_add"],0,0,0,self.rootItems["up_expSprite_add"]:getContentSize().height)
    --
    self:setData_up(self.expup)
    --

    self.rootItems.up_gotobutton1:addHandleOfControlEvent(function()
        GameScene:shiftLayer("copy_chapter","up",{datatype = "normal"})
    end, CCControlEventTouchUpInside)
    self.rootItems.up_gotobutton1:setSwallowsTouch(true)
    self.rootItems.up_gotobutton1:setTouchPriority(-103)

    self.rootItems.up_gotobutton2:addHandleOfControlEvent(function()
        GameScene:shiftLayerById(131)
    end, CCControlEventTouchUpInside)
    self.rootItems.up_gotobutton2:setSwallowsTouch(true)
    self.rootItems.up_gotobutton2:setTouchPriority(-103)
end

function generalup.initUpChangeBtn(self)
    if not self.isNotUpChangeType then
        self.upChangeType = true
    else
        self.isNotUpChangeType = false
    end
    self:refreshUpChangeBtn()

    local _cb = function()
        self.upChangeType = not self.upChangeType
        self:refreshUpChangeBtn()

        if self.upChangeType then
            self:ReloadData()
        end
    end

    ui.commonBtn(self, self.rootItems, "upChangeBtn", _cb)
end

function generalup.refreshUpChangeBtn(self)
    if self.upChangeType then
        setControlButtonFrame(self.rootItems["upChangeBtn"], "kuaisushengji", "kuaisushengji", "kuaisushengji")
        ui.setLabelString(self.rootItems["upLab2"], gameConfig.strings:string_common("general", 55), 19)
        ui.setLabelString(self.rootItems["upLab1"], gameConfig.strings:string_common("general", 56), 19)
    else
        setControlButtonFrame(self.rootItems["upChangeBtn"], "jingzhunshengji", "jingzhunshengji", "jingzhunshengji")
        ui.setLabelString(self.rootItems["upLab2"], gameConfig.strings:string_common("general", 57), 19)
        ui.setLabelString(self.rootItems["upLab1"], gameConfig.strings:string_common("general", 58), 19)
    end
end

function generalup.setData_up(self,expup)
    local level1 =  self.expup.l_level or self.data.general.level1

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]

    self.rootItems["up_lv"]:setString(self.data.general.level1)

    if level1 > self.data.general.level1 then
        self.rootItems["up_lv_up"]:setString("+"..(level1-self.data.general.level1))
    else
        self.rootItems["up_lv_up"]:setString("")
    end

    self.rootItems["in_num"]:setString( "x"..self.expup.l_num1  )
    self.rootItems["in_num_1"]:setString( "x"..self.expup.l_num2  )
    self.rootItems["in_num_2"]:setString( "x"..self.expup.l_num3  )
    self.rootItems["in_num_3"]:setString( "x"..self.expup.l_num4  )
    ui.setLabelString(self.rootItems["in_num"],nil,13)
    ui.setLabelString(self.rootItems["in_num_1"],nil,13)
    ui.setLabelString(self.rootItems["in_num_2"],nil,13)
    ui.setLabelString(self.rootItems["in_num_3"],nil,13)

    local nextexp = 0
    if self.expup.l_level+0 <= self.expup.maxlv then
        nextexp = gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
    end
    --self.rootItems["up_exp"]:setString((self.expup.l_exp>=nextexp) and "Max" or (self.expup.l_exp.." / "..nextexp))
    self.rootItems["up_exp"]:setString(self.expup.l_exp.." / "..nextexp)
    ui.setLabelString(self.rootItems.up_exp,nil,13)

    if self.expup.l_level > self.data.general.level1 then
        ui.setSpriteTextureRect2(self.rootItems["up_expSprite_add"],0,0,844 * 1 ,self.rootItems["up_expSprite_add"]:getContentSize().height)
    else
        ui.setSpriteTextureRect2(self.rootItems["up_expSprite_add"],0,0,844 * ((self.expup.l_exp>=nextexp) and 1 or (self.expup.l_exp / nextexp)),self.rootItems["up_expSprite_add"]:getContentSize().height)
    end

    if self.expup.num1-self.expup.l_num1 > 0 then
        self.rootItems.reduceNode1:setVisible(true)
    else
        self.rootItems.reduceNode1:setVisible(false)
    end
    if self.expup.num2-self.expup.l_num2 > 0 then
        self.rootItems.reduceNode2:setVisible(true)
    else
        self.rootItems.reduceNode2:setVisible(false)
    end
    if self.expup.num3-self.expup.l_num3 > 0 then
        self.rootItems.reduceNode3:setVisible(true)
    else
        self.rootItems.reduceNode3:setVisible(false)
    end
    if self.expup.num4-self.expup.l_num4 > 0 then
        self.rootItems.reduceNode4:setVisible(true)
    else
        self.rootItems.reduceNode4:setVisible(false)
    end
end


function generalup.setUpNum(self,data)
    self.expup.num1 = data["20196"] or 0
    self.expup.num2 = data["20197"] or 0
    self.expup.num3 = data["20198"] or 0
    self.expup.num4 = data["20199"] or 0
    self.expup.l_num1 = self.expup.num1
    self.expup.l_num2 = self.expup.num2
    self.expup.l_num3 = self.expup.num3
    self.expup.l_num4 = self.expup.num4

    if self.expup.num1+self.expup.num2+self.expup.num3+self.expup.num4 < 1 then
        self.rootItems.up_haspropnode:setVisible(false)
        self.rootItems.up_haspropnode:setPositionX(9999)
        self.rootItems.up_nopropnode:setVisible(true)
        self.rootItems.up_nodetitle:setString("获取经验丹")
    else
        self.rootItems.up_haspropnode:setVisible(true)
        self.rootItems.up_haspropnode:setPositionX(0)
        self.rootItems.up_nopropnode:setVisible(false)
        self.rootItems.up_nodetitle:setString("升级")
    end

    self:setData_up(self.expup)
end

function generalup.ReloadData_up(self)

   --
   local nextexp = 0
   if self.data.general.level1 <= self.expup.maxlv then
        nextexp = gamedata.config.general_exp[tostring(self.data.general.level1)][tostring(self.expup.quality)..'exp']
   end
   local processNum = 100*((self.data.general.exp>=nextexp) and 1 or (self.data.general.exp / nextexp))
   --
   local nextexp1 = 0
   if self.expup.l_level <= self.expup.maxlv then
       nextexp1 = gamedata.config.general_exp[tostring(self.expup.l_level)][tostring(self.expup.quality)..'exp']
   end
   local processNum1 = 100*((self.expup.l_exp>=nextexp1) and 1 or (self.expup.l_exp / nextexp1))
   --


    if self.expup.l_level > self.data.general.level1 then
        gameTouch:clickprofbytime(1)
        local expTo = CCProgressFromTo:create(0.5,processNum,100)
        self.rootItems.up_expSprite:runAction(expTo)

        self.rootItems.up_expSprite:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()

            ui.setSpriteTextureRect2(self.rootItems["up_expSprite_add"],0,0,0,self.rootItems["up_expSprite_add"]:getContentSize().height)

            local effectccb,effectitem = CCBReaderLoad("UIEffect/renwushengji/renwushengji", nil, true, "renwushengji")
            self.rootItems.effectnode_top:removeAllChildrenWithCleanup(true)
            self.rootItems.effectnode_top:addChild(effectccb)

            local expTo1 = CCProgressFromTo:create(0.5,0,processNum1)
            self.rootItems.up_expSprite:runAction(expTo1)

            self.rootItems.up_expSprite:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
                self:ReloadData()
            end)))

        end)))

    else
        gameTouch:clickprofbytime(0.5)
        local expTo2 = CCProgressFromTo:create(0.5,processNum,processNum1)
        self.rootItems.up_expSprite:runAction(expTo2)

        self.rootItems.up_expSprite:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
            self:ReloadData()
        end)))
    end

end

function generalup.setPage_awaken( self )
    print("调用了超神  setPage_awaken ")
    if self.rootItems.changeskillBtn then
        self.rootItems.changeskillBtn:setVisible(false)
    end 
    self.rootItems.juexingnode:setVisible(true)
    self.rootItems.juexingnode:setPositionX(0) 
    self.rootItems.trainnode:setVisible(false)
    self.rootItems.upnode:setVisible(false)
    self.rootItems.tuponode:setVisible(false)
    self.rootItems.newskillnode:setVisible(false)
    self.rootItems.trainnode:setPositionX(9999)
    self.rootItems.upnode:setPositionX(9999)
    self.rootItems.tuponode:setPositionX(9999)
    self.rootItems.newskillnode:setPositionX(9999)
    self.rootItems.xiuliannode:setVisible(false)
    self.rootItems.xiuliannode:setPositionX(9999)

    if not (self.generalsdata and self.generalsdata[tostring(self.generalindex)]) then return end
    self.data.general = self.generalsdata[tostring(self.generalindex)]
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    -- 武将觉醒重生
    if self.rootItems.btn_jxRebirth then
        if tonumber(self.data.general.skilllevel) > 90 and generalConfig.exchange_id ~= nil and generalConfig.exchange_id ~= "" then
            self.rootItems.btn_jxRebirth:setVisible(true)
        else
            self.rootItems.btn_jxRebirth:setVisible(false)
        end
        self.rootItems.btn_jxRebirth:addHandleOfControlEvent(function()
            gameWindows:openWindow("generalJXRebirth",self.data.general,nil)
        end, CCControlEventTouchUpInside)
        self.rootItems.btn_jxRebirth:setSwallowsTouch(true)
        self.rootItems.btn_jxRebirth:setTouchPriority(-103)
    end

    
    self.awakenCondition = nil --为空说明不是从skilllevel是有效值，否自使用global_kv的值
    if generalConfig.basic == 20 and generalConfig.basic > self.awakenConfig[tostring(self.data.general.skilllevel)].basic then
        self.awakenCondition = tonumber(gamedata.config.global_kv.general_awaken20.value)
    elseif generalConfig.basic == 23 and generalConfig.basic > self.awakenConfig[tostring(self.data.general.skilllevel)].basic then
        self.awakenCondition = tonumber(gamedata.config.global_kv.general_awaken23.value)
    --初始红将
    elseif generalConfig.basic == 44 and ui.judgeBasicRed(self.data.general.cid) and generalConfig.basic > self.awakenConfig[tostring(self.data.general.skilllevel)].red_basic then
        self.awakenCondition = tonumber(gamedata.config.global_kv.general_awaken44.value)
    end
    local awakenConfig = self.awakenCondition and self.awakenConfig[tostring(self.awakenCondition + 1)] or self.awakenConfig[tostring(self.data.general.skilllevel + 1)]
    if self.data.general.level2 > 13 then
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>=7 and 213 or 2*generalConfig.quality-1)
    else  
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)
    end
    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images[generalConfig.actor])
    end

    if self.rootItems.goldtypeNode then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.goldtypeNode:setVisible(true)
            setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope])
        else
            self.rootItems.goldtypeNode:setVisible(false)
        end    
    end   

    if generalConfig.awaken == 0 then
        self.rootItems.juexingcontrolnode:setPositionX(9999)
        self.rootItems.juexing_title:setVisible(false)
        self.rootItems.notAwakenLabel:setVisible(true) 
        ui.setLabelString(self.rootItems.notAwakenLabel,nil ,49)
    elseif awakenConfig ~= nil then
        self.rootItems.juexingcontrolnode:setPositionX(0)
        ui.setLabelString(self.rootItems.juexingtext,gameConfig.strings:string_common("generalInfo",27),19) 
        self.rootItems.juexing_title:setString(gameConfig.strings:string_common("general",36)) 
        self.rootItems.juexing_title:setVisible(true)
        self.rootItems.notAwakenLabel:setVisible(false) 
        ui.setLabelString(self.rootItems.notAwakenLabel,nil,49)  
    else
        self.rootItems.juexingcontrolnode:setPositionX(9999)
        self.rootItems.juexing_title:setString(gameConfig.strings:string_common("general",35))
        self.rootItems.juexing_title:setVisible(true)
        self.rootItems.notAwakenLabel:setVisible(false)  
    end
    self:setAwakenNext()
 end 

function generalup.setAwakenNext( self ,data )

    local currentConfig = {}
    local nextConfig = {}

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local awakenConfig =  (self.awakenCondition and self.awakenConfig[tostring(self.awakenCondition + 1)] or self.awakenConfig[tostring(self.data.general.skilllevel + 1)]) or {}

    if generalConfig.awaken > 0 and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)] and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel)] and not self.awakenCondition then
        table.insert(currentConfig ,{"atk",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel)].awaken_atk})

        table.insert(currentConfig ,{"def",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel)].awaken_def})

        table.insert(currentConfig ,{"hp",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel)].awaken_hp})

        table.insert(currentConfig ,{"hit",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel)].awaken_hit})
    end

    print("setAwakenNext",generalConfig.awaken,self.data.general.skilllevel,self.awakenCondition)
    if self.awakenCondition and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)] and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.awakenCondition + 1)] then
        table.insert(nextConfig ,{"atk",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.awakenCondition + 1)].awaken_atk})
        table.insert(nextConfig ,{"def",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.awakenCondition + 1)].awaken_def})
        table.insert(nextConfig ,{"hp",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.awakenCondition + 1)].awaken_hp})
        table.insert(nextConfig ,{"hit",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.awakenCondition + 1)].awaken_hit})
    elseif generalConfig.awaken > 0 and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)] and gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel + 1)] then
        table.insert(nextConfig ,{"atk",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel+1)].awaken_atk})

        table.insert(nextConfig ,{"def",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel+1)].awaken_def})

        table.insert(nextConfig ,{"hp",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel+1)].awaken_hp})

        table.insert(nextConfig ,{"hit",gamedata.config.general_awakenattr[tostring(generalConfig.awaken)][tostring(self.data.general.skilllevel+1)].awaken_hit})
    end

    local materialData =  ui.getSTRandNUMs(awakenConfig.consume1 or ""  )  --需要的材料
    local  t  = {}
    self.awakenData = {}
    for i  = 2,table.getTableLength(materialData) do
        table.insert(t,tonumber(materialData[i].str))
        table.insert(self.awakenData,{id = materialData[i].str,num = materialData[i].num})      
    end

    if next(awakenConfig)  and  awakenConfig.number > 0 then --快速尝试查找碎片
        local ocid = self.data.general.cid
        if generalConfig.init_cid and generalConfig.init_cid > 0 then
            ocid = generalConfig.init_cid
        end   

        table.insert(self.awakenData,{id = ocid + 1000,num =  awakenConfig.number})
        table.insert(t,ocid + 1000)

    end

    local _cid = ui.getOriginCid(self.data.general.cid)
    local originConfig = gamedata.config.general[tostring(_cid)]

    if awakenConfig["consume_"..originConfig.basic] and awakenConfig["consume_"..originConfig.basic] ~= "" then
        local otherConsume =  ui.getSTRandNUMs(awakenConfig["consume_"..originConfig.basic])  --需要的材料
        for i,v in pairs(otherConsume) do
            table.insert(t,tonumber(v.str))
            table.insert(self.awakenData,{id = v.str,num = v.num})   
        end
    end

    UIRequest({type = 12001, order = 10103, cids = t})
    if generalConfig.awaken == 0 or  self.awakenCondition or self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, self.awakenConfig[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)    
    end

    printT(currentConfig,"currentConfig")

    if not  next(currentConfig)  or generalConfig.awaken == 0  then  
        self.rootItems.juexingattnode:setVisible(false) 
        self.rootItems.juexingDetailText:setVisible(false)     
    else
        self.rootItems.juexingattnode:setVisible(true)
        self.rootItems.juexing_level:setString(self.awakenConfig[tostring(self.data.general.skilllevel)].name)
        local fixbasic = "basic"
        if generalConfig.quality >= 6 then
            fixbasic = "red_basic"
        end
        if not awakenConfig[fixbasic] or ( awakenConfig[fixbasic] == 0 or awakenConfig[fixbasic] <  self.data.general.basic or awakenConfig[fixbasic] <=  self.awakenConfig[tostring(self.data.general.skilllevel)][fixbasic]) then
            self.rootItems.juexingDetailText:setVisible(false)
        else
            ui.setLabelString(self.rootItems.juexingDetailText,gameConfig.strings:awakenUp(awakenConfig[fixbasic]),13)
            self.rootItems.juexingDetailText:setVisible(true)            
        end
        for k,v in ipairs(currentConfig) do
            ui.setLabelString( self.rootItems["juexing_attname"..k],gameConfig.strings:string_common("attr_type",v[1])..":",122)
            ui.setLabelString( self.rootItems["juexing_att"..k],v[2],14)            
        end
    end

    local general_basic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    if tonumber(general_basic) >= 20 then
        if gamedata.config.global_kv["general_awaken"..general_basic] then
            local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
            if self.data.general.skilllevel <= general_awaken then
                if self.rootItems.juexing then
                    self.rootItems.juexing:setVisible(false)
                end
                self.rootItems.juexingattnode:setVisible(false)
                self.rootItems.juexingDetailText:setVisible(false) 
            end
        end
    end

    if  not  next(nextConfig) or not next(awakenConfig) or generalConfig.awaken == 0  then
        self.rootItems.juexingnextattnode:setVisible(false)    
    else
        self.rootItems.juexingnextattnode:setVisible(true)   
        self.rootItems.juexing_next_level:setString(awakenConfig.name)   
        for k,v in ipairs(nextConfig) do
            ui.setLabelString( self.rootItems["juexing_next_attname"..k],gameConfig.strings:string_common("attr_type",v[1])..":",122)
            ui.setLabelString( self.rootItems["juexing_next_att"..k],v[2],23)            
        end       
    end
    ui.setLabelString(self.rootItems.juexingtiptext,nil,21)


    
    -- if generalConfig.awaken == 0 or not next(awakenConfig)  or awakenConfig.lv > self.data.general.level1 or self.awankenIsMaterialEnough == false or awakenConfig.breach > self.data.general.level2 then
    --     ui.addGray("CCControlButton",self.rootItems.juexingbuntton)
    --     ui.addGray("CCLabelTTF",self.rootItems.juexingtext)
    -- else
    --     ui.removeGray("CCControlButton",self.rootItems.juexingbuntton)
    --     ui.removeGray("CCLabelTTF",self.rootItems.juexingtext)        
    -- end
end

function generalup.resetPage_Awaken(self,data)

    self.rootItems.closeButton:setEnabled(false)
    self.rootItems.juexingbuntton:setEnabled(false)
    self.rootItems.autojuexingbuntton:setEnabled(false)
    local effectccb1,effectitem1 = CCBReaderLoad("UIEffect/huobantupo/n_huobantupo", nil, true, "n_huobantupo")

    local animationManager1 = getAnimationManager(effectitem1)
    animationManager1:runAnimationsForSequenceNamed("n_huobantupo")

    if effectitem1.topnode then
        effectitem1.topnode:removeFromParentAndCleanup(false)
        self.rootItems.effectnode_top:addChild(effectitem1.topnode)
        --effectitem.topnode:setPosition(0,0)
    end
    if effectitem1.bottomnode then
        effectitem1.bottomnode:removeFromParentAndCleanup(false)
        self.rootItems.effectnode_bottom:addChild(effectitem1.bottomnode)
        --effectitem.bottomnode:setPosition(0,0)
    end

    
    local sequence3 = CCSequence:createWithTwoActions(CCDelayTime:create(0.1), CCCallFunc:create(function()
        self.data.general = data.general
        self:ReloadData()

        if self.autoJuexing then
            self.rootItems.autojuexingbuntton:setEnabled(true)
        end

        self.rootItems.juexingnode:stopAllActions()
        self.rootItems.juexingnode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.3), CCCallFunc:create(function()

            self.rootItems.closeButton:setEnabled(true)
            self.rootItems.juexingbuntton:setEnabled(true)
            self.rootItems.autojuexingbuntton:setEnabled(true)

            if self.autoJuexing then
                print("autoJuexing",data.general.skilllevel)
                --进阶停止
                if data.general.skilllevel%10 == 0 then
                    print("stop")
                    self.autoJuexing = false
                     gameWindows:openWindow("generalawakenfinish",{b = self.juexingGeneralData,e = data},nil)
                else
                    self:executeJuexing(data)
                end
            else
                gameWindows:openWindow("generalawakenfinish",{b = self.juexingGeneralData,e = data},nil)
            end
            self:setAwankenButtonStatus()
        end)))
    end))

    self.rootItems.effectnode_top:stopAllActions()
    self.rootItems.effectnode_top:runAction(sequence3)
    

end


function generalup.executeJuexing(self,t)
    
    print("executeJuexing")
    local autoJuexing = false
    if not self.juexingPropsData then
        self.autoJuexing = autoJuexing
        self:setAwankenButtonStatus()
        return
    end

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local awakenConfig = self.awakenCondition and self.awakenConfig[tostring(self.awakenCondition + 1)] or self.awakenConfig[tostring( self.data.general.skilllevel + 1  )] 

    printT(awakenConfig,"awakenConfig")
    if not(awakenConfig and awakenConfig.consume1) then return end

    local moneynum = {}
    for k,v in pairs(ui.getSTRandNUMs(awakenConfig.consume1)) do
        table.insert(moneynum,v)
    end

    local _cid = ui.getOriginCid(self.data.general.cid)
    local originConfig = gamedata.config.general[tostring(_cid)]

    if awakenConfig["consume_"..originConfig.basic] and awakenConfig["consume_"..originConfig.basic] ~= "" then
        local otherConsume =  ui.getSTRandNUMs(awakenConfig["consume_"..originConfig.basic])  --需要的材料
        for i,v in pairs(otherConsume) do
            table.insert(moneynum,v)   
        end
    end
    
    for k,v in ipairs(self.awakenData) do
        if self.juexingPropsData[tostring(v.id)] == nil then
            self.juexingTemp = t
            return
        end
    end
    local isMaterialEnough = true
    for k,v in ipairs(self.awakenData) do
        if v.num <= self.juexingPropsData[tostring(v.id)] then
        else
            isMaterialEnough = false
        end
    end


    if not gameConfig:checkBuildOpen(174)  then
        
    elseif not GameScene:checkopenlevelbyId(174,true) then
    elseif  generalConfig.awaken == 0 then
    elseif awakenConfig and  awakenConfig.lv > self.data.general.level1  then
    elseif awakenConfig and awakenConfig.breach > self.data.general.level2  then     
    elseif moneynum and moneynum[1].str == "1000" and GameScene.roleinfo.coin < moneynum[1].num then
    elseif moneynum and moneynum[1].str == "1001" and GameScene.roleinfo.gold < moneynum[1].num then
    elseif isMaterialEnough == false then
    else
        autoJuexing = true
    end

    local executeFunc = function (  )
        local generalfragments = {}
        if next(awakenConfig)  and  awakenConfig.number > 0 then --快速尝试查找碎片
            local ocid = ui.getOriginCid(self.data.general.cid)
            generalfragments.id = ocid + 1000
            generalfragments.num = awakenConfig.number

        end
        autoJuexing = true
        UIRequest({type = 1025 , iid = self.data.general.iid ,  materials = moneynum,generalfragments = generalfragments})
    end


    print("autoJuexing",self.autoJuexing,autoJuexing)

    if self.autoJuexing then
        if not autoJuexing then
            --无法继续执行
            gameWindows:openWindow("generalawakenfinish",{b = self.juexingGeneralData,e = t},nil)
        else
            executeFunc()
        end
    else
        if not gameConfig:checkBuildOpen(174)  then
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")}) 
        elseif not GameScene:checkopenlevelbyId(174,true) then
            runGamePrompt({msg = gameConfig.strings:GenralsListLev(gamedata.config.build[tostring(174)].level)}) 
        elseif  generalConfig.awaken == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("general",31)})
        elseif awakenConfig and  awakenConfig.lv > self.data.general.level1  then
            runGamePrompt({msg = gameConfig.strings:generallevel(awakenConfig.lv)})
        elseif awakenConfig and awakenConfig.breach > self.data.general.level2  then
            runGamePrompt({msg = gameConfig.strings:tupolevel(awakenConfig.breach)})       
        elseif moneynum and moneynum[1].str == "1000" and GameScene.roleinfo.coin < moneynum[1].num then
            shortCoin()
        elseif moneynum and moneynum[1].str == "1001" and GameScene.roleinfo.gold < moneynum[1].num then
            shortGold()
        elseif isMaterialEnough == false then
            runGamePrompt({msg = gameConfig.strings:string_common("general",33)})
        else
            executeFunc()
        end
    end

    self.autoJuexing = autoJuexing
    self:setAwankenButtonStatus()
end

function generalup.setAwankenButtonStatus(self)
    if self.autoJuexing then
         ui.setLabelString(self.rootItems.autojuexingtext,gameConfig.strings:string_common("popups","quxiao"),19)
         setControlButtonFrame(self.rootItems.autojuexingbuntton,"b_n_button1","b_n_button1_h","b_n_button1")
    else
        ui.setLabelString(self.rootItems.autojuexingtext,"一键觉醒",19)
        setControlButtonFrame(self.rootItems.autojuexingbuntton,"b_n_button2","b_n_button2_h","b_n_button2")
    end
    self.rootItems.juexingbuntton2:setEnabled(self.autoJuexing)
end

function generalup.setAwankenPropNum(self,pdata )
    printT(self.awakenData,"self.awakenData")
    printT(pdata,"pdata")

    self.juexingPropsData = pdata

    local count = 0
    local isMaterialEnough = true 
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local awakenConfig = self.awakenCondition and self.awakenConfig[tostring(self.awakenCondition + 1)] or self.awakenConfig[tostring( self.data.general.skilllevel + 1  )] 

    if not(awakenConfig and awakenConfig.consume1) then return end

    local moneynum = {}
    for k,v in pairs(ui.getSTRandNUMs(awakenConfig.consume1)) do
        table.insert(moneynum,v)
    end

    local _cid = ui.getOriginCid(self.data.general.cid)
    local originConfig = gamedata.config.general[tostring(_cid)]

    if awakenConfig["consume_"..originConfig.basic] and awakenConfig["consume_"..originConfig.basic] ~= "" then
        local otherConsume =  ui.getSTRandNUMs(awakenConfig["consume_"..originConfig.basic])  --需要的材料
        for i,v in pairs(otherConsume) do
            table.insert(moneynum,v)   
        end
    end

    local juexingdanEnough = true

    for k,v in ipairs(self.awakenData) do
        if k > 4 then
            break
        end
        count = count + 1
        ui.setNewIcon(self.rootItems,{cid =v.id },4 + count)

        if v.num <= pdata[tostring(v.id)] then
            ui.setLabelString(self.rootItems["i_num_"..(4+count)],pdata[tostring(v.id)] .."/"..v.num , 13)
        else
            ui.setLabelString(self.rootItems["i_num_"..(4+count)],pdata[tostring(v.id)] .."/"..v.num , 27)
            isMaterialEnough = false

            if v.id == "20017" then
                --突破丹不足
                juexingdanEnough = false
                
            end

        end

        --ui.setMobileShopShow(self.rootItems["mobieshop_1"],-102,9,not juexingdanEnough)

        self.rootItems["i_button_"..(8+count)]:addHandleOfControlEvent(function()
            if ui.IDconfig(tonumber(v.id)).staffType == "general_fragment" then
                gameWindows:openWindow("dropTips",{cid = v.id},nil)
            else
                ui.setPopwindowByCid(tostring(v.id))
            end
        end,CCControlEventTouchUpInside)
        self.rootItems["i_button_"..(8+count)]:setSwallowsTouch(true)
        self.rootItems["i_button_"..(8+count)]:setTouchPriority(-104)
        self.rootItems["juexingMaterial"..count]:setVisible(true)
    end

    for i = 1+ count ,4 do
        self.rootItems["juexingMaterial"..i]:setVisible(false)
    end
    if moneynum[1].str == "1000" then
        ui.setLabelString(self.rootItems.juexing_coin,moneynum[1].num,GameScene.roleinfo.coin>=moneynum[1].num and 14 or 47)
        setSpriteFrameByName(self.rootItems.awankencoin,"obj_s_coin")
    elseif moneynum[1].str == "1001" then
        ui.setLabelString(self.rootItems.juexing_coin,moneynum[1].num,GameScene.roleinfo.gold>=moneynum[1].num and 14 or 47)
        setSpriteFrameByName(self.rootItems.awankencoin,"obj_s_gold")
    end

    if  generalConfig.awaken == 0 then
        ui.addGray("CCControlButton",self.rootItems.juexingbuntton)
        ui.addGray("CCControlButton",self.rootItems.autojuexingbuntton)
    else
        ui.removeGray("CCControlButton",self.rootItems.juexingbuntton)
        ui.removeGray("CCControlButton",self.rootItems.autojuexingbuntton)
    end   

    self.rootItems.juexingbuntton:setSwallowsTouch(true)
    self.rootItems.juexingbuntton:setTouchPriority(-104)
    self.rootItems.juexingbuntton:addHandleOfControlEvent(function()
        self.juexingGeneralData = table.copy(self.data.general)
        self:executeJuexing()
        self.autoJuexing = false
        self:setAwankenButtonStatus()
        self.rootItems.autojuexingbuntton:setEnabled(false)
    end, CCControlEventTouchUpInside)

    self.rootItems.autojuexingbuntton:setSwallowsTouch(true)
    self.rootItems.autojuexingbuntton:setTouchPriority(-301)
    self.rootItems.autojuexingbuntton:addHandleOfControlEvent(function()

        if self.autoJuexing then
            self.autoJuexing = false
            self:setAwankenButtonStatus()
        else
            self.juexingGeneralData = table.copy(self.data.general)
            self:executeJuexing()
        end

    end, CCControlEventTouchUpInside)


    self.rootItems.juexingbuntton2:setSwallowsTouch(true)
    self.rootItems.juexingbuntton2:setTouchPriority(-300)
    self.rootItems.juexingbuntton2:addHandleOfControlEvent(function()
    end, CCControlEventTouchUpInside)

    self:setAwankenButtonStatus()

    if self.juexingTemp and next(self.juexingTemp) then
        self:executeJuexing(self.juexingTemp)
        self.juexingTemp = nil
    end
end 


function generalup.setPage_upstar(self)
    print("setPage_upstar")

    self.rootItems.upstarnode_g:setVisible(false)
    self.upstarNodeInfo.items.upstar_condition:setString("")


    if self.rootItems.btnRule then
        self.rootItems.btnRule:setVisible(true)
        self.rootItems["btnRule"]:setTouchPriority(-105)
        self.rootItems["btnRule"]:addHandleOfControlEvent(function()
            ui.popCommonRule(572)
        end, CCControlEventTouchUpInside)
    end


    ui.setLabelString(self.upstarNodeInfo.items.fixed1,nil,18)
    ui.setLabelString(self.upstarNodeInfo.items.fixed2,nil,18)

    ui.setLabelString(self.upstarNodeInfo.items.lab1,nil,1010,34)
    ui.setLabelString(self.upstarNodeInfo.items.lab2,nil,1010,34)
    ui.setLabelString(self.upstarNodeInfo.items.lab3,nil,1010,34)
    ui.setLabelString(self.upstarNodeInfo.items.lab4,nil,1010,34)
    ui.setLabelString(self.upstarNodeInfo.items.lab5,nil,1010,34)
    ui.setLabelString(self.upstarNodeInfo.items.lab6,nil,1010,34)

    if not (self.generalsdata and self.generalsdata[tostring(self.generalindex)]) then return end
    self.data.general = self.generalsdata[tostring(self.generalindex)]
    print("level5",self.data.general.level5)
    
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local originalBasic = generalConfig.basic
    if generalConfig.init_cid and generalConfig.init_cid > 0 then
        originalBasic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    end

    if self.data.general.level2 > 13 then
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>=7 and 213 or 2*generalConfig.quality-1)
    else    
        ui.setLabelString(self.rootItems.generalname,generalConfig.name..(self.data.general.level2>0 and " +"..self.data.general.level2 or ""), generalConfig.quality>0 and 2*generalConfig.quality-1 or 1)
    end

    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.rootItems["generaltype"], gameConfig.images[generalConfig.actor])
    end

    if generalConfig.awaken == 0 or self.data.general.skilllevel <= 0 then
        self.rootItems.juexing:setVisible(false)
    else
        self.rootItems.juexing:setVisible(true)
        setSpriteFrameByName(self.rootItems.juexing_icon, self.awakenConfig[tostring(self.data.general.skilllevel)].icon )
        ui.setLabelString(self.rootItems.juexing_name, self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)    
    end

    local general_basic = gamedata.config.general[tostring(generalConfig.init_cid)].basic
    if tonumber(general_basic) >= 20 then
        if gamedata.config.global_kv["general_awaken"..general_basic] then
            local general_awaken = tonumber(gamedata.config.global_kv["general_awaken"..general_basic].value) --觉醒初始值
            if self.data.general.skilllevel <= general_awaken then
                if self.rootItems.juexing then
                    self.rootItems.juexing:setVisible(false)
                end
            end
        end
    end

    if self.rootItems.goldtypeNode then
        if self.data.general.scope and self.data.general.scope > 0 then
            self.rootItems.goldtypeNode:setVisible(true)
            setSpriteFrameByName(self.rootItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope])
        else
            self.rootItems.goldtypeNode:setVisible(false)
        end    
    end

    --角色是否能飞升
    if not (generalConfig.rising_star and generalConfig.rising_star > 0) then
        --品质不够不能飞升
        self.upstarNodeInfo.items.upstarcontrolnode:setVisible(false)
        self.upstarNodeInfo.items.cantNode:setVisible(true)
        return
    else
        self.upstarNodeInfo.items.upstarcontrolnode:setVisible(true)
        self.upstarNodeInfo.items.cantNode:setVisible(false)
    end

    local upstarConfig = gamedata.config.general_star
    local level5 = self.data.general.level5 or 0

    local curConfig  = upstarConfig[tostring(level5)]
    local nextConfig = upstarConfig[tostring(level5 + 1)]

    --当前星数
    local curStar = 0
    if curConfig then
        if curConfig.star_class ~= 0 then
            curStar = curConfig.star_class
        elseif level5 > 1 then
            curStar = upstarConfig[tostring(level5 - 1)].star_class
        end
    end

    --武将升星重生
    if self.rootItems.btn_upstarRebirth then
        if level5 > 0 then
            self.rootItems.btn_upstarRebirth:setVisible(true)
        else
            self.rootItems.btn_upstarRebirth:setVisible(false)
        end
        self.rootItems.btn_upstarRebirth:addHandleOfControlEvent(function()
            gameWindows:openWindow("generalUpStarRebirth",self.data.general,nil)
        end, CCControlEventTouchUpInside)
        self.rootItems.btn_upstarRebirth:setTouchPriority(-104)
    end

    --当前阶段
    local stages = {"C","B","A","S","SS","SSS"}
    local curStage = ""
    if curConfig then
        self.rootItems.upstarnode_g:setVisible(true)
        curStage = curConfig.stage
        --设置星星展示
        setSpriteFrameByName(self.rootItems.upstarlab_Lv, "generalstar_"..curStage)
    end

    local s1 = curStar%25
    if curStar == 0 then
        s1 = 0
    elseif s1 == 0 and (curConfig and curConfig.star_class ~= 0) then
        s1 = 25
    end

    --阶段进阶之后显示  进阶后的等级 0星
    local starnum = s1%5
    if starnum == 0 then
        starnum = 5
    end

    local quality = math.ceil(s1/5)
    print("s1",s1,starnum,quality)

    for i=1,5 do
        if i > starnum then
            setSpriteFrameByName(self.rootItems["star"..i], "shengxing_"..(quality - 1))
        else
            setSpriteFrameByName(self.rootItems["star"..i], "shengxing_"..(quality))
        end
    end

    -- printT(upstarConfig,"upstarConfig")
    local skills = {}
    for i=1,table.getTableLength(upstarConfig) do
        local v = upstarConfig[tostring(i)]
        if v.star_class == 0 then
            if not skills[v.stage] then
               skills[v.stage] = v.activated
            end
        end
    end
    printT(skills,"skills")
    print("curStar",curStar,stages[curStage])

    --当前技能等级
    local curSkillLevel = {0,0,0,0,0,0}
    if curConfig then
        self.upstarNodeInfo.items.upattnode:setVisible(true)
        ui.setLabelString(self.upstarNodeInfo.items.g_atk,curConfig.g_atk,14)
        ui.setLabelString(self.upstarNodeInfo.items.g_def,curConfig.g_def,14)
        ui.setLabelString(self.upstarNodeInfo.items.g_hp,curConfig.g_hp,14)

        for i=1,6 do
            local breakskill = gamedata.config.breakskill[tostring(skills[stages[i]])]
            ui.removeLabelStroke(self.upstarNodeInfo.items["skillName"..i])
            self.upstarNodeInfo.items["skillName"..i]:setString(breakskill.name)
            ui.setLabelString(self.upstarNodeInfo.items["skilllevelMax"..i],nil,24,34)
            
            local level = 0
            for j=0,4 do
                local needlevel = 25*(i-1) + j*5
                if curStar > needlevel then
                    level = level + 1
                elseif curStar == needlevel and curConfig.star_class == 0 then
                    level = level + 1
                end
            end
            --未开启
            if level == 0 then
                ui.setLabelString(self.upstarNodeInfo.items["skilllevel"..i],stages[i].."级开启",14)
                self.upstarNodeInfo.items["skillName"..i]:setColor(ui.grayColor)
            else
                ui.setLabelString(self.upstarNodeInfo.items["skilllevel"..i],"等级."..level,1008,34)
                ui.setLabelString(self.upstarNodeInfo.items["skillName"..i],nil,14)
            end

            self.upstarNodeInfo.items["skilllevelMax"..i]:setVisible(level == 5)

            curSkillLevel[i] = level
        end

    else
        self.upstarNodeInfo.items.upattnode:setVisible(false)
    end

    if self.rootItems.upstarSKillButton then
       self.rootItems.upstarSKillButton:setVisible(true)
        self.rootItems["upstarSKillButton"]:setTouchPriority(-105)
        self.rootItems["upstarSKillButton"]:addHandleOfControlEvent(function()
            gameWindows:openWindow("upStarSkill",{curSkillLevel = curSkillLevel},nil)
        end, CCControlEventTouchUpInside)
    end


    local nextSkillLevel = {0,0,0,0,0,0}
    local nextStar = curStar + 1
    if nextConfig then
        self.upstarNodeInfo.items.upnextattnode:setVisible(true)
        self.upstarNodeInfo.items.maxNode:setVisible(false)
        self.upstarNodeInfo.items.upstarpropnode:setVisible(true)

        ui.setLabelString(self.upstarNodeInfo.items.next_g_atk,nextConfig.g_atk,23)
        ui.setLabelString(self.upstarNodeInfo.items.next_g_def,nextConfig.g_def,23)
        ui.setLabelString(self.upstarNodeInfo.items.next_g_hp,nextConfig.g_hp,23)


        for i=1,6 do
            local breakskill = gamedata.config.breakskill[tostring(skills[stages[i]])]
            ui.removeLabelStroke(self.upstarNodeInfo.items["next_skillName"..i])
            self.upstarNodeInfo.items["next_skillName"..i]:setString(breakskill.name)
            ui.setLabelString(self.upstarNodeInfo.items["next_skilllevelMax"..i],nil,24,34)
            
            local level = 0
            for j=0,4 do
                local needlevel = 25*(i-1) + j*5
                if nextStar > needlevel then
                    level = level + 1
                elseif nextStar == needlevel and nextConfig.star_class == 0 then
                    level = level + 1
                end
            end
            nextSkillLevel[i] = level

            --未开启
            if level == 0 then
                ui.setLabelString(self.upstarNodeInfo.items["next_skilllevel"..i],stages[i].."级开启",14)
                self.upstarNodeInfo.items["next_skillName"..i]:setColor(ui.grayColor)
            else
                self.upstarNodeInfo.items["next_skilllevel"..i]:setString("等级."..level)
                
                if (nextSkillLevel[i] or 0) > (curSkillLevel[i] or 0) then
                    ui.setLabelString(self.upstarNodeInfo.items["next_skillName"..i],nil,14)
                    ui.setLabelString(self.upstarNodeInfo.items["next_skilllevel"..i],nil,23)
                else
                    ui.setLabelString(self.upstarNodeInfo.items["next_skillName"..i],nil,14)
                    ui.setLabelString(self.upstarNodeInfo.items["next_skilllevel"..i],nil,1008,34)
                end

            end

            self.upstarNodeInfo.items["next_skilllevelMax"..i]:setVisible(level == 5)
        end

    else
        self.upstarNodeInfo.items.upnextattnode:setVisible(false)
        self.upstarNodeInfo.items.maxNode:setVisible(true)
        self.upstarNodeInfo.items.upstarpropnode:setVisible(false)
        return
    end


    if gamedata.config.partner_soaring[tostring(nextConfig.limitlv)] then
        self.upstarNodeInfo.items.upstar_condition:setString("飞升等级:"..gamedata.config.partner_soaring[tostring(nextConfig.limitlv)].name)
    else
        self.upstarNodeInfo.items.upstar_condition:setString("")
    end
    
    --判断飞升
    if self.data.general.level8 >= nextConfig.limitlv then
        self.upstarNodeInfo.items.upstar_condition:setColor(ccc3(0, 255, 0))
    else
        self.upstarNodeInfo.items.upstar_condition:setColor(ccc3(255, 0, 0))
    end
    
    local cids = {}
    local consume = ui.getIDandNUMs(nextConfig.consume)
    for i,v in ipairs(consume) do
        table.insert(cids,v.cid)
    end

    self.upstarNeedProp = consume
    UIRequest({type = 12001, order = 33019, cids = cids})

    for i=1,4 do
        self.upstarNodeInfo.items["upstar_prop"..i]:setVisible(false)
    end

    if level5 == 0 then
        ui.setLabelString(self.upstarNodeInfo.items["upstartext"],"激 活",19)
        setControlButtonFrame(self.upstarNodeInfo.items["upstarbuntton"],"b_s_button2","b_s_button2_h","b_s_button2")
    elseif nextConfig and nextConfig.star_class == 0 then
        ui.setLabelString(self.upstarNodeInfo.items["upstartext"],"进 阶",19)
        setControlButtonFrame(self.upstarNodeInfo.items["upstarbuntton"],"b_s_button2","b_s_button2_h","b_s_button2")
    else
        ui.setLabelString(self.upstarNodeInfo.items["upstartext"],"升 星",19)
        setControlButtonFrame(self.upstarNodeInfo.items["upstarbuntton"],"b_s_button1","b_s_button1_h","b_s_button1")
    end

    self.upstarNodeInfo.items["upstarbuntton"]:addHandleOfControlEvent(function()

    end, CCControlEventTouchUpInside)
    self.upstarNodeInfo.items["upstarbuntton"]:setTouchPriority(-104)

end

function generalup.setUpStarPropNum(self,t)
    
    if not self.upstarNeedProp then
        return
    end

    local level5 = self.data.general.level5 or 0
    local nextConfig = gamedata.config.general_star[tostring(level5 + 1)]


    local prop = {}
    local money = nil
    for i,v in ipairs(self.upstarNeedProp) do
        if v.cid == 1000 or v.cid == 1001 then
            money = v
        else
            table.insert(prop,v)
        end
    end

    for i=1,4 do
        if prop[i] then
            self.upstarNodeInfo.items["upstar_prop"..i]:setVisible(true)
            ui.setNewIcon(self.upstarNodeInfo.items,{cid=prop[i].cid,num=((t[tostring(prop[i].cid)] or 0).."/"..prop[i].num)},i - 1)
            local labT = (t[tostring(prop[i].cid)] or 0) >= prop[i].num and 13 or 24
            ui.setLabelString(self.upstarNodeInfo.items[ui.ccbNameEx("i_num",i)],nil,labT)
            self.upstarNodeInfo.items[ui.ccbNameEx("i_button",i)]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(prop[i].cid)
            end, CCControlEventTouchUpInside)
            self.upstarNodeInfo.items[ui.ccbNameEx("i_button",i)]:setTouchPriority(-104)
        else
            self.upstarNodeInfo.items["upstar_prop"..i]:setVisible(false)
        end
    end

    if money then
        self.upstarNodeInfo.items.coinNode:setVisible(true)
        setSpriteFrameByName(self.upstarNodeInfo.items.upstarCoinIcon, gameConfig.images[
            "s_icon_"..money.cid])
        local labT = (t[tostring(money.cid)] or 0) >= money.num and 14 or 47
        ui.setLabelString(self.upstarNodeInfo.items.upstarCoinNum,money.num,labT)
        
    else
        self.upstarNodeInfo.items.coinNode:setVisible(false)
    end
    
    self.upstarNodeInfo.items["upstarbuntton"]:addHandleOfControlEvent(function()

        --判断飞升等级
        if self.data.general.level8 < nextConfig.limitlv then
            runGamePrompt({msg = gameConfig.strings:string_common("general",74)})
            return
        end
        
        --判断道具
        for i,v in ipairs(self.upstarNeedProp) do
            if not (t[tostring(v.cid)] and t[tostring(v.cid)] >= v.num) then
                local propconfig = ui.IDconfig(v.cid)
                runGamePrompt({msg = propconfig.name..gameConfig.strings:string_common("general",49)})
                return
            end
        end

        gameTouch:clickprofbytime(2)
        UIRequest({type = 1029,iid = self.data.general.iid,cost = self.upstarNeedProp})

    end, CCControlEventTouchUpInside)
    self.upstarNodeInfo.items["upstarbuntton"]:setTouchPriority(-104)
    
end

function generalup.upStarCallback(self,t)
    if self.data.general.iid ~= t.general.iid then
        self:ReloadData()
        return
    end
    
    if self.selectpage == "upstar" then
        local effectccb1,effectitem1 = CCBReaderLoad("UIEffect/huobantupo/n_huobantupo", nil, true, "n_huobantupo")

        local animationManager1 = getAnimationManager(effectitem1)
        animationManager1:runAnimationsForSequenceNamed("n_huobantupo")

        if effectitem1.topnode then
            effectitem1.topnode:removeFromParentAndCleanup(false)
            self.rootItems.effectnode_top:addChild(effectitem1.topnode)
            
        end
        if effectitem1.bottomnode then
            effectitem1.bottomnode:removeFromParentAndCleanup(false)
            self.rootItems.effectnode_bottom:addChild(effectitem1.bottomnode)
        end

        self.rootItems.effectnode_bottom:stopAllActions()
        self.rootItems.effectnode_bottom:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1), CCCallFunc:create(function()
            self.data.general = t.general   
            self:ReloadData()
        end)))

    end

end

return generalup
�2 