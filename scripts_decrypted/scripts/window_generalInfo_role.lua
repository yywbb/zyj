-- 新武将详情
-- zhangzhixin

local generalInfo = {
    rootNode = nil,
    rootItems = nil,
    breakNum = 0,--主角时突破等级
    cX = 500,--x坐标中心点
    png = {
    	line = "public/publicsprite/spr_74.png",
    	activate = "b_lab1.png"
	},
    d_viewSize = {width=gamedata.device.SCREEN_WIDTH, height =gamedata.device.SCREEN_HEIGHT },
    viewSize = gameConfig.originSize,
    maxRadio_size = gameConfig.maxRadio_size,
    -- region = {
    --     ["0"] = "魔王",
    --     ["1"] = "天庭",
    --     ["2"] = "佛界",
    --     ["3"] = "魔",
    --     ["4"] = "地府",
    --     ["5"] = "妖",
    --     ["6"] = "群雄",
    --     ["7"] = "魏国",
    --     ["8"] = "蜀国",
    --     ["9"] = "吴国",
    -- },

    region = gameConfig.strings:string_common("popups","region0"),

    isscrolltouched = false,
    attrStatus = "fan",

    scopetype = {
        [1] = "tian",
        [2] = "di",
        [3] = "ren",
    },
}

function generalInfo.open(self,touchPriority,data,callback)
    print("generalInfo.open ============")
    printT(data)
    self.root = ui.createNode()
    self.touchPriority = touchPriority
    self:reload(table.copy(data),callback)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","generalinfo",touchbegin)

    local function touchend(pos)
        if self.infoItems.bottombg and ui.isTouched(self.infoItems.bottombg,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","generalinfo",touchend)



    return self.root, true
end

function generalInfo.reload(self,data,callback)
    self.callback = callback
    self.data = data.data or {}
    self.islead = data.islead or 0
    self.opt = data.opt or 0
    self.sid = data.sid or 1
    self.cheersid = data.cheersid or 1

    printT(data,"generalInfo.reload ==========")
    if self.data.general and self.data.general.iid and self.data.general.iid == GameScene.protagonist.iid  then
        self.islead = 1
    end
    local gcid = (self.opt == 2) and data.cid or self.data.general.cid
    local configdata = gamedata.config.general[tostring(gcid)] or {}
    if self.opt == 2 then
        self.data.general = {}
        self.data.relation = {}
        self.data.general.iid = 0
        self.data.general.cid = data.cid
        self.data.general.level1 = 1
        self.data.general.level2 = 0
        self.data.general.combskilllevel = 0
        self.data.general.atk = configdata.atk or 0
        self.data.general.hp = configdata.hp or 0
        self.data.general.defense = configdata.def or 0
        self.data.general.speed = configdata.speed or 0
        self.data.general.critical = configdata.critical or 0
        self.data.general.resilience = configdata.resilience or 0
        self.data.general.hit = configdata.hit or 0
        self.data.general.arp = configdata.arp or 0
        self.data.general.dodge = configdata.dodge or 0
        self.data.general.parry = configdata.parry or 0
        self.data.general.criticaldmg = configdata.criticaldmg or 0
        self.data.general.potential = configdata.potential or 0
        self.data.general.skilllevel = -1
        self.data.general.skill = {}
    end

    local  g_config = configdata
    if self.data.general and self.data.general.illusionGeneralCid then
        g_config = gamedata.config.general[tostring(self.data.general.illusionGeneralCid)]
        for i=1,5 do
            self.data.general["g_score"..i] = self.data.general.illusion["g_score"..i]
        end
    end

    if g_config.skillid and g_config.skillid >0 then
        self.data.general.skill.cid = g_config.skillid or 0
    elseif g_config.special_skill_reveal and g_config.special_skill_reveal >0 then
        self.data.general.skill.cid = g_config.special_skill_reveal or 0
    end
    if g_config.combskillid and g_config.combskillid > 0 then
        self.data.general.combskill = {}
        self.data.general.combskill.cid = g_config.combskillid
    end
    --装备有缘进来的主角判定
    if configdata.actor == "lead" and self.islead == 0 then
        self.islead = 1
    end

    if not (self.data.relation and next(self.data.relation)) then
        self.data.relation = {}
        for i = 1,50 do
            if configdata["cond"..i.."ids"] and configdata["cond"..i.."ids"]~="" then
                self.data.relation[tostring(i)] = { activate = 0 ,ids = {}}
            end
        end
    end
    -- self.pagetype = data.pagetype or self.pagetype
    self.skilltype = data.skilltype or "skill"
    self.passiveconfig = gamedata.config.breakskill
    self.equipConfig = gamedata.config.equip
    self.allGeneralConfig = gamedata.config.general
    self.fragmentConfig =  gamedata.config.general_fragment
    self.awakenConfig = gamedata.config.general_awaken
    self.protagonist_growConfig = gamedata.config.protagonist_grow
    self:showPage()	
end

function generalInfo.close(self)
--    ui.itemcache:detachskeleton(self.generalName)
--    ui.itemcache:resumAttachs()

    gameTouch:UnrigistFunc("begin","generalinfo")
    gameTouch:UnrigistFunc("end","generalinfo")
    self.data = nil
    self.fdata = nil
    self.trainResuit = false
    -- self.skilltype = "skill"
    -- self.pagetype = "info"
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.infoItems = nil
    self.yuanItems = nil
    self.message = nil
    self.generalConfig = nil
	self.passiveconfig = nil

    if self.callback then
        self.callback()
    end	

    self.attrStatus = "fan"
end
--改版后之后角色信息界面
function generalInfo.showPage(self)
    self.rootNode, self.infoItems = CCBReaderLoad("general_new/general_info_new2", nil, true, "info")
    self.root:removeAllChildrenWithCleanup(true)
    self.root:addChild(self.rootNode)
    self.infoItems.scrollnode = tolua.cast(self.infoItems.scrollnode, "CCScrollView")
    self.infoItems.scrollnode:setTouchPriority(self.touchPriority)

    self.attrNode, self.attrItems = CCBReaderLoad("UIEffect/wujianginfo/wujianginfo", nil, true, "wujianginfo")
    self.infoItems.attrNode:addChild(self.attrNode)

    if self.d_viewSize.width/self.d_viewSize.height <= self.maxRadio_size.width/self.maxRadio_size.height then
        local scale = (self.viewSize.width/self.viewSize.height)*(self.d_viewSize.height/self.d_viewSize.width)
        if scale > 1.125 then scale = 1.125 end
        self.changeHight = 960 * (1- scale) * 2
        local sizeBG = self.infoItems.bottombg:getContentSize()        
        self.infoItems.topnode:setPositionY(self.infoItems.topnode:getPositionY() - 960 * (1-scale))
        if gameWindows.existTopWindows ~= 0 then
            self.infoItems.middlenode:setPositionY(self.infoItems.middlenode:getPositionY() - 960 * (1- scale)- 63)
            self.infoItems.bottomnode:setPositionY( self.infoItems.bottomnode:getPositionY()+ 960 - 960 * scale - 125)
        else
            self.infoItems.middlenode:setPositionY(self.infoItems.middlenode:getPositionY() - 960 * (1- scale))
            self.infoItems.bottomnode:setPositionY( self.infoItems.bottomnode:getPositionY()+ 960 - 960 * scale)
        end
        self.infoItems.bottomview:setPositionY(self.infoItems.bottomview:getPositionY() - self.changeHight)
        self.infoItems.scrollnode:setPositionY(self.infoItems.scrollnode:getPositionY()+self.changeHight)        
        self.infoItems.bottombg:setContentSize(CCSize(sizeBG.width,sizeBG.height-self.changeHight ))
        self.infoItems.scrollnode:setViewSize(CCSizeMake(1000,820-self.changeHight ))
    else
        local topY  = GameScene.topposY
        self.changeHight =  (1920 - topY)
        local sizeBG = self.infoItems.bottombg:getContentSize()   
        self.infoItems.topnode:setPositionY(self.infoItems.topnode:getPositionY() -   0.5*self.changeHight ) --960 * (1-scale)    )

        self.infoItems.bottomview:setPositionY(self.infoItems.bottomview:getPositionY() - self.changeHight)
        self.infoItems.scrollnode:setPositionY(self.infoItems.scrollnode:getPositionY()+self.changeHight)        
        self.infoItems.bottombg:setContentSize(CCSize(sizeBG.width,sizeBG.height-self.changeHight ))
        self.infoItems.scrollnode:setViewSize(CCSizeMake(1000,820-self.changeHight ))   
        if  gameWindows.existTopWindows ~= 0 then 
            self.infoItems.middlenode:setPositionY(self.infoItems.middlenode:getPositionY() -  0.5*self.changeHight -63)
            self.infoItems.bottomnode:setPositionY( self.infoItems.bottomnode:getPositionY()+ 0.5*self.changeHight -125)
        else
            self.infoItems.middlenode:setPositionY(self.infoItems.middlenode:getPositionY() -  0.5*self.changeHight)
            self.infoItems.bottomnode:setPositionY( self.infoItems.bottomnode:getPositionY()+ 0.5*self.changeHight)            
        end
    end
    if gameWindows.existTopWindows ~= 0 then
        self.rootNode:setPosition(0,-960)
    else
        self.rootNode:setPosition(0,-960-80)
    end
    self.awakenConfig = gamedata.config.general_awaken
    self:setPage_info()
    self:setExclusiveShow()
end 

function generalInfo.setExclusiveShow(self)
    self.infoItems.hint_zhuanshu:setVisible(false)
    self.infoItems.exclusiveArtifactNode:setVisible(false)

    local generalConfig = gamedata.config.general[tostring(self.data.general.illusionGeneralCid or self.data.general.cid)]
    local exclusiveConfig = ui.IDconfig(generalConfig.exclusive)
    if not exclusiveConfig then
        return
    end

    if self.opt and self.opt == 2 then
        self.infoItems.exclusiveArtifactNode:setVisible(true)
        local skeleton = ui.createExclusiveSkeleton(exclusiveConfig.animation)
        if skeleton then
            skeleton:setAnimation("stand",true,0)
            self.infoItems.zhuanshu:addChild(skeleton)
        end
    else
        if not (gameConfig:checkBuildOpen(611) and GameScene:checkopenlevelbyId(611,true)) then
            return
        end

        if self.data.general.hashint_exclusive then
            self.infoItems.hint_zhuanshu:setVisible(true)
        end

        self.infoItems.exclusiveArtifactNode:setVisible(true)
        local skeleton = ui.createExclusiveSkeleton(exclusiveConfig.animation)
        if skeleton then
            skeleton:setAnimation("stand",true,0)
            self.infoItems.zhuanshu:addChild(skeleton)
            if generalConfig.quality < 7 then
                ui.addGray("CCNode",skeleton)
            elseif not GameScene.layers["slotsInfo"].module.exclusiveArtifactData[self.data.general.iid] then
                ui.addGray("CCNode",skeleton)
            end
        end
    end

    self.infoItems["zhuanshubutton"]:setSwallowsTouch(true)
    self.infoItems["zhuanshubutton"]:setTouchPriority(self.touchPriority)
    self.infoItems["zhuanshubutton"]:addHandleOfControlEvent(function()
        local opt = 1
        if self.opt and self.opt == 2 then
            opt = 2
        end
        gameWindows:openWindow("exclusiveArtifact", {general = self.data.general,opt = opt})
    end,CCControlEventTouchUpInside)

end

--武将培养1014， 接受客户端数据
function generalInfo.reloaddata(self,data)
    local olddata = self.data.general and table.copy(self.data.general) or nil
    self.data.general = data.general or {}

    -- if self.data.general and self.data.general.iid then
    --     self.data.general = gamedata.generalAttrChange(self.data.general)
    -- end

    self:showPage()
end

--设置属性 凡 仙
function generalInfo.setAttr_info(self)
    
    local tag = ""
    if self.attrStatus == "fan" then
        self.infoItems.fan:setVisible(true)
        self.infoItems.xian:setVisible(false)
    elseif self.attrStatus == "xian" then
        self.infoItems.fan:setVisible(false)
        self.infoItems.xian:setVisible(true)
        tag = "g_"
    end

    local generalConfig = gamedata.config.general[tostring(self.data.general.illusionGeneralCid or self.data.general.cid)]

    if self.data and self.data.general then
        general = self.data.general
        self.attrItems.desc:setString(generalConfig.desc)
        ui.setLabelString(self.infoItems.lv1,general.level1 or 0,18)

        local power = self.data.general.power or 0

        if power == 0 then
            self.attrItems.powerTotal:setString("战斗力")
        else
            self.attrItems.powerTotal:setString("战斗力:"..power)
        end
        

        -- ui.setLabelString(self.attrItems.speed,general.speed or 0,18)
        -- ui.setLabelString(self.attrItems.potential,general.potential or 0,18)
        -- ui.setLabelString(self.attrItems.atk,general[tag.."atk"] or 0,18)
        -- ui.setLabelString(self.attrItems.hp,general[tag.."hp"] or 0,18)
        -- ui.setLabelString(self.attrItems.defense,general[tag.."defense"] or 0,18)
        -- ui.setLabelString(self.attrItems.critical,general[tag.."critical"] or 0,18)
        -- ui.setLabelString(self.attrItems.dodge,general[tag.."dodge"] or 0,18)
        -- ui.setLabelString(self.attrItems.parry,general[tag.."parry"] or 0,18)
        -- ui.setLabelString(self.attrItems.hit,general[tag.."hit"] or 0,18)
        -- ui.setLabelString(self.attrItems.resilience,general[tag.."resilience"] or 0,18)
        -- ui.setLabelString(self.attrItems.arp,general[tag.."arp"] or 0,18)
        -- ui.setLabelString(self.attrItems.criticaldmg,general[tag.."criticaldmg"] or 0,18)


        self.attrItems.speed:setString(general.speed or 0)
        self.attrItems.potential:setString(general.potential or 0)
        self.attrItems.atk:setString(general[tag.."atk"] or 0)
        self.attrItems.hp:setString(general[tag.."hp"] or 0)
        self.attrItems.defense:setString(general[tag.."defense"] or 0)
        self.attrItems.critical:setString(general[tag.."critical"] or 0)
        self.attrItems.dodge:setString(general[tag.."dodge"] or 0)
        self.attrItems.parry:setString(general[tag.."parry"] or 0)
        self.attrItems.hit:setString(general[tag.."hit"] or 0)
        self.attrItems.resilience:setString(general[tag.."resilience"] or 0)
        self.attrItems.arp:setString(general[tag.."arp"] or 0)
        self.attrItems.criticaldmg:setString(general[tag.."criticaldmg"] or 0)

        -- self.attrItems.desc:setColor(ccc3(0,0,0))
        -- self.attrItems.speed:setColor(ccc3(0,0,0))
        -- self.attrItems.potential:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.atk:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.hp:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.defense:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.critical:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.dodge:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.parry:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.hit:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.resilience:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.arp:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
        -- self.attrItems.criticaldmg:setColor(self.attrStatus == "fan" and ccc3(255,255,255) or ccc3(125,71,45))
    else
        self.attrItems.powerTotal:setString("战斗力")
    end
    
end

--设置 info 
function generalInfo.setPage_info(self)

    local generalConfig = gamedata.config.general[tostring(self.data.general.illusionGeneralCid or self.data.general.cid)]
    self.generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    -- 去获取 按钮
    ui.setLabelString(self.infoItems.getText,nil,18)

    self.infoItems.getBtn:addHandleOfControlEvent(function()

        gameWindows:openWindow("dropTips",{cid =  self:findFragmentIDByHeroID(self.data.general.cid )},nil)
    end, CCControlEventTouchUpInside)
    self.infoItems.getBtn:setSwallowsTouch(true)
    self.infoItems.getBtn:setTouchPriority(self.touchPriority)

    --
    if self.infoItems.fashionButton then
        if self.infoItems.hint_fashion then
            self.infoItems.hint_fashion:setVisible(false)
        end  
        if gameConfig:checkBuildOpen(444) then
            if self.islead and self.islead == 1 then
                self.infoItems.fashionButton:setVisible(false)
            else
                local gndata = gamedata.config.general[tostring(self.data.general.cid)] or {}
                if gndata.breach_upper_limit > 10 then
                    self.infoItems.fashionButton:setVisible(true)
                end
                if generalConfig.fashion_image and generalConfig.fashion_image ~= "" then
                    self.infoItems.fashionButton:setVisible(true)
                end
                self.infoItems.fashionButton:addHandleOfControlEvent(function()
                    local gcid = self.data.general.illusionGeneralCid or self.data.general.cid
                    if self.opt and self.opt == 2 then
                        gameWindows:openWindow("partner_fashion",{cid = gcid, iid = 0, general = self.data.general, opt = 2},nil)
                    else
                        savePartnerfashionOnceToSqlite(self.data.general.cid,0)
                        gameWindows:openWindow("partner_fashion",{cid = gcid, iid = self.data.general.iid or 0, general = self.data.general},nil)
                        -- 皮肤红点
                        if getPartnerfashionOnceFromSqlite(self.data.general.cid) == 1 then
                            self.infoItems.hint_fashion:setVisible(true)
                        else
                            self.infoItems.hint_fashion:setVisible(false)
                        end 
                        -- 时装红点
                        local o_cid = self.data.general.cid
                        if gamedata.config.general[tostring(o_cid)] and gamedata.config.general[tostring(o_cid)].partner_id and gamedata.config.general[tostring(o_cid)].partner_id > 0 then
                            o_cid = gamedata.config.general[tostring(o_cid)].partner_id
                        end   
                        for k,v in pairs(gamedata.config.partner_fashion) do
                            if (v.orange_partner2 == o_cid) or (v.red_partner2 == o_cid) or (v.gold_partner2 == o_cid) then
                                if getPartnerfashionOnceFromSqlite(v.fashion_id) == 1 then
                                    self.infoItems.hint_fashion:setVisible(true)
                                    break
                                end 
                            end    
                        end 
                    end
                end, CCControlEventTouchUpInside)
                self.infoItems.fashionButton:setSwallowsTouch(true)
                self.infoItems.fashionButton:setTouchPriority(self.touchPriority)
                --
                if self.infoItems.hint_fashion then
                    -- 皮肤红点
                    if getPartnerfashionOnceFromSqlite(self.data.general.cid) == 1 then
                        self.infoItems.hint_fashion:setVisible(true)
                    else
                        self.infoItems.hint_fashion:setVisible(false)
                    end 
                    -- 时装红点
                    local o_cid = self.data.general.cid
                    if gamedata.config.general[tostring(o_cid)] and gamedata.config.general[tostring(o_cid)].partner_id and gamedata.config.general[tostring(o_cid)].partner_id > 0 then
                        o_cid = gamedata.config.general[tostring(o_cid)].partner_id
                    end   
                    for k,v in pairs(gamedata.config.partner_fashion) do
                        if (v.orange_partner2 == o_cid) or (v.red_partner2 == o_cid) or (v.gold_partner2 == o_cid) then
                            if getPartnerfashionOnceFromSqlite(v.fashion_id) == 1 then
                                self.infoItems.hint_fashion:setVisible(true)
                                break
                            end 
                        end    
                    end  
                end
                --
            end
        end
    end
    --

    self.infoItems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- 设置形象
    local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
    if generalConfig.fashion_id == 0 then --非时装
        if self.data.general.illusionGeneralCid then
            generalName = ui.getGeneralAnimationidSion(generalName, self.data.general)
        else
            generalName = ui.getGeneralAnimationid(generalName, self.data.general)
        end
    end
--    self.generalName = generalName
--    ui.itemcache:saveAttachsByname(generalName)
--
--    local Gneral = ui.itemcache:attachskeleton(generalName,self.infoItems["generalNode"])
--    Gneral:setAnimation("stand",true,0)
--    Gneral:setScale(1)
--    self.infoItems["generalNode"]:setScale(1.5)

    local wing = {}
    if self.opt==0 and self.islead and self.islead == 1 then
        wing = {level = GameScene.protagonist.w_l, color = GameScene.protagonist.w_c}
    end
    --local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    local Gneral = ui.itemcache:loadSkeleton(generalName,wing)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.5)
    Gneral:setPosition(0,0)
    self.infoItems["generalNode"]:addChild(Gneral.root or Gneral)


    ui.addAwakeEffect(self.infoItems["generalNode"],self.data.general.skilllevel,1.5)

    self.infoItems.generalbutton:addHandleOfControlEvent(function()
        self.animationtype = not self.animationtype
        if self.animationtype then
            Gneral:setAnimation("attack",false,0)
        else
            Gneral:setAnimation("celebrate",false,0)
        end

        Gneral:addAnimation("stand",true,0,0)
    end, CCControlEventTouchUpInside)
    self.infoItems.generalbutton:setSwallowsTouch(true)
    self.infoItems.generalbutton:setTouchPriority(self.touchPriority )

    
    local animationManager = getAnimationManager(self.attrItems)
    if self.data.general.power and self.data.general.power > 0 and GameScene:checkopenlevelbyId(449,true) then
        if self.data.general.level8 and self.data.general.level8 > 0 then
            self.attrStatus = "xian"
            animationManager:runAnimationsForSequenceNamed("xian_free")
        else
            animationManager:runAnimationsForSequenceNamed("fan_free")
        end
        self:setAttr_info()
        self.infoItems.attrChange:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(1)
            if self.attrStatus == "fan" then
                self.attrStatus = "xian"
                animationManager:runAnimationsForSequenceNamed("xian_play")
            else
                self.attrStatus = "fan"
                animationManager:runAnimationsForSequenceNamed("fan_play")
            end
            self:setAttr_info()
        end, CCControlEventTouchUpInside)
        self.infoItems.attrChange:setSwallowsTouch(true)
        self.infoItems.attrChange:setTouchPriority(self.touchPriority )
    else
        animationManager:runAnimationsForSequenceNamed("fan_free")
        self:setAttr_info()
        self.infoItems.attrChange:setVisible(false)
        self.infoItems.fan:setVisible(false)
        self.infoItems.xian:setVisible(false)

        self.infoItems.attrInfoButton:setVisible(false)
    end

    if self.data.general.scope and self.data.general.scope > 0 then
        self.infoItems.goldtype:setVisible(true)
        setControlButtonFrame(self.infoItems.goldtype,"tujin_"..self.scopetype[self.data.general.scope],"tujin_"..self.scopetype[self.data.general.scope],"tujin_"..self.scopetype[self.data.general.scope])
        
        self.infoItems.goldtype:addHandleOfControlEvent(function()
            gameWindows:openWindow("scope_rule")
        end, CCControlEventTouchUpInside)
        self.infoItems.goldtype:setSwallowsTouch(true)
        self.infoItems.goldtype:setTouchPriority(self.touchPriority)

    else
       self.infoItems.goldtype:setVisible(false)
    end

    -- ui.setLabelString(self.infoItems.basic,(generalConfig.basic  and generalConfig.basic or 0 ) + (generalConfig.grow and generalConfig.grow or 0),3)
    
    if self.islead and self.islead == 1 and self.data.general.skilllevel > 0 then
        self.infoItems.juexing:setVisible(true)
        setSpriteFrameByName(self.infoItems.juexing_icon,gamedata.config.protagonist_awaken[tostring(self.data.general.skilllevel)].icon)
        ui.setLabelString(self.infoItems.juexing_name,gamedata.config.protagonist_awaken[tostring(self.data.general.skilllevel)].stage,18)
    elseif self.data.general.skilllevel > 0 and generalConfig.awaken > 0 then
        self.infoItems.juexing:setVisible(true)
        setSpriteFrameByName(self.infoItems.juexing_icon,self.awakenConfig[tostring(self.data.general.skilllevel)].icon)
        ui.setLabelString(self.infoItems.juexing_name,self.awakenConfig[tostring(self.data.general.skilllevel)].stage,18)
    else
        self.infoItems.juexing:setVisible(false)
    end

    if self.data.general.skilllevel > 0 then
        local fixbasicstr = "basic"
        if generalConfig.quality and generalConfig.quality == 6 then
            fixbasicstr = "red_basic"
        elseif generalConfig.quality and generalConfig.quality >= 7 then
            fixbasicstr = "gold_basic"    
        end
        ui.setLabelString(self.infoItems.basic, 
            generalConfig.basic > self.awakenConfig[tostring(self.data.general.skilllevel)][fixbasicstr]
            and generalConfig.basic or self.awakenConfig[tostring(self.data.general.skilllevel)][fixbasicstr],3)
    else
        ui.setLabelString(self.infoItems.basic, generalConfig.basic,3)
    end
    ui.setLabelString(self.infoItems.region,self.region[tostring(generalConfig.region or 6)],7)

    ui.setLabelString(self.infoItems.basicText,self.infoItems.basicText:getString(),3)
    ui.setLabelString(self.infoItems.regionText,self.infoItems.regionText:getString(),7)
--    ui.setLabelString(self.infoItems.atktext,self.infoItems.atktext:getString(),10)
--    ui.setLabelString(self.infoItems.hptext,self.infoItems.hptext:getString(),10)
--    ui.setLabelString(self.infoItems.defensetext,self.infoItems.defensetext:getString(),10)
--    ui.setLabelString(self.infoItems.speedtext,self.infoItems.speedtext:getString(),10)
--    ui.setLabelString(self.infoItems.desctext,self.infoItems.desctext:getString(),30)
--    ui.setLabelString(self.infoItems.criticaltext,self.infoItems.criticaltext:getString(),30)
--    ui.setLabelString(self.infoItems.dodgetext,self.infoItems.dodgetext:getString(),30)
--    ui.setLabelString(self.infoItems.parrytext,self.infoItems.parrytext:getString(),30)
--    ui.setLabelString(self.infoItems.hittext,self.infoItems.hittext:getString(),30)
--    ui.setLabelString(self.infoItems.resiliencetext,self.infoItems.resiliencetext:getString(),30)
--    ui.setLabelString(self.infoItems.arptext,self.infoItems.arptext:getString(),30)
--    ui.setLabelString(self.infoItems.criticaldmgtext,self.infoItems.criticaldmgtext:getString(),30)
--    ui.setLabelString(self.infoItems.potentialtext,self.infoItems.potentialtext:getString(),30)
--    ui.setLabelString(self.infoItems.arptext,self.infoItems.arptext:getString(),30)
--    ui.setLabelString(self.infoItems.arptext,self.infoItems.arptext:getString(),30)

    if self.attrItems.nothisattr then
        self.attrItems.nothisattr:setVisible(self.islead and self.islead == 1)
    end

    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.infoItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.infoItems["generaltype"], gameConfig.images[generalConfig.actor])
    end

    if self.islead and self.islead == 1 then
        if self.opt and self.opt ~= 2 then
            self.infoItems.name:setString(ui.leadName(GameScene.protagonist.level2))

            local pre = tonumber(self.infoItems.basic:getString())
            local nowlvconfig = gamedata.config.wing_stage[tostring(GameScene.protagonist.w_l)] or {}
            ui.setLabelString(self.infoItems.basic,(pre+(nowlvconfig["effect"..5] or 0)),3)
        end
        self.infoItems.getNode:setVisible(false)
        self.infoItems.region:setPositionX(self.infoItems.region:getPositionX()-100)
        self.infoItems.regionText:setPositionX(self.infoItems.regionText:getPositionX()-100)
        self.infoItems.basic:setPositionX(self.infoItems.basic:getPositionX()-100)
        self.infoItems.basicText:setPositionX(self.infoItems.basicText:getPositionX()-100)
    else
        self.infoItems.getNode:setVisible(true)
        --
        if self.data.general.level2 > 13 then
            self.infoItems.name:setString(generalConfig.name..(self.data.general.level2+0 > 0 and " +"..self.data.general.level2 or "")..(self.data.general.illusionGeneralCid and "(幻化)" or ""))
        else
            self.infoItems.name:setString(generalConfig.name..(self.data.general.level2+0 > 0 and " +"..self.data.general.level2 or "")..(self.data.general.illusionGeneralCid and "(幻化)" or ""))
        end
    end

    if generalConfig.quality and generalConfig.quality >= 7 then
        ui.setLabelString(self.infoItems.name,nil,213)
    else
        ui.setLabelString(self.infoItems.name,nil,(generalConfig.quality or 1)*2-1)
    end
    ui.setLabelString(self.infoItems.lv1,nil,18)

    if self.islead and self.islead == 1 then
        self.infoItems.doNode1:setVisible(false)
        self.infoItems.doNode3:setVisible(false)
        self.infoItems.doNode5:setVisible(false)
        self.infoItems.doNode7:setVisible(false)
    else
        self.infoItems.doNode1:setVisible(true)
        self.infoItems.doNode3:setVisible(true)
        self.infoItems.doNode4:setVisible(true)
        self.infoItems.doNode5:setVisible(true)
        self.infoItems.doNode7:setVisible(true)
    end

    --
    if self.opt == 2 then
        self.infoItems.doNode1:setVisible(false)
        self.infoItems.doNode2:setVisible(false)
        self.infoItems.doNode3:setVisible(false)
        self.infoItems.doNode4:setVisible(false)
        self.infoItems.doNode5:setVisible(false)
        self.infoItems.doNode6:setVisible(false)
        self.infoItems.doNode7:setVisible(false)
    end


    ui.setLabelString(self.infoItems.doLab1,gameConfig.strings:string_common("generalInfo",1),19)
    ui.setLabelString(self.infoItems.doLab2,gameConfig.strings:string_common("generalInfo",2),19)
    ui.setLabelString(self.infoItems.doLab3,gameConfig.strings:string_common("generalInfo",3),19)
    ui.setLabelString(self.infoItems.doLab4,gameConfig.strings:string_common("generalInfo",27),19)
    ui.setLabelString(self.infoItems.doLab5,gameConfig.strings:string_common("general",40),19)
    ui.setLabelString(self.infoItems.doLab6,gameConfig.strings:string_common("general",48),19)
    ui.setLabelString(self.infoItems.doLab7,gameConfig.strings:string_common("general",75),19)

    self.infoItems.button_back:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("generalInfoRole")
    end, CCControlEventTouchUpInside)
    self.infoItems.button_back:setSwallowsTouch(true)
    self.infoItems.button_back:setTouchPriority(self.touchPriority)


    self.infoItems.attrInfoButton:addHandleOfControlEvent(function()
        gameWindows:openWindow("generalAttributeInfo",self.data.general)
    end, CCControlEventTouchUpInside)
    self.infoItems.attrInfoButton:setSwallowsTouch(true)
    self.infoItems.attrInfoButton:setTouchPriority(self.touchPriority)

    
    --
    if self.opt and self.opt == 3 then
        -- self.infoItems.doLab1:setString("更 换")
        self.infoItems.doLab1:setString(gameConfig.strings:string_common("generalInfo",4))
        ui.setLabelString(self.infoItems.doLab1,nil,19)
    else
        -- self.infoItems.doLab1:setString("升 级")
        self.infoItems.doLab1:setString(gameConfig.strings:string_common("generalInfo",1))
        ui.setLabelString(self.infoItems.doLab1,nil,19)
    end

    if self.opt and self.opt == 3 then
        ui.removeGray("CCControlButton",self.infoItems.doButton1)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab1)
    elseif generalConfig.quality < 3 then
        ui.addGray("CCControlButton",self.infoItems.doButton1)
        ui.addGray("CCLabelTTF",self.infoItems.doLab1)
    else
        ui.removeGray("CCControlButton",self.infoItems.doButton1)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab1)
    end

    if not (self.islead and self.islead == 1) then
        if  not gameConfig:checkBuildOpen(174) or not GameScene:checkopenlevelbyId(174,true) or generalConfig.awaken == 0  then
            ui.addGray("CCControlButton",self.infoItems.doButton4)
            ui.addGray("CCLabelTTF",self.infoItems.doLab4)
        else
            ui.removeGray("CCControlButton",self.infoItems.doButton4)
            ui.removeGray("CCLabelTTF",self.infoItems.doLab4)        
        end
    end

    

    if  not gameConfig:checkBuildOpen(449) or not GameScene:checkopenlevelbyId(449,true) then
        ui.addGray("CCControlButton",self.infoItems.doButton6)
        ui.addGray("CCLabelTTF",self.infoItems.doLab6)
    else
        ui.removeGray("CCControlButton",self.infoItems.doButton6)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab6)  
    end

    if not gameConfig:checkBuildOpen(378) or not GameScene:checkopenlevelbyId(378,true) or generalConfig.quality < 3 then
        --todo
    end

    self.infoItems.doButton1:addHandleOfControlEvent(function()
        if self.opt and self.opt == 3 then
            local cid = self.data.general.cid
            local cheersid = self.cheersid or 1
            local callback = function(selectedData)
                
                for k,v in pairs(selectedData) do
                    UIRequest({type = 1004, pos1 = cheersid, iid = v.iid})
                    self.callback = nil
                    gameWindows:closeWindowDirect("generalInfoRole")
                    break
                end
            end
            gameWindows:openWindow("selectlist",{type = "changegeneral", param = cid,param2="cheer"},callback)
        elseif generalConfig.quality < 3 then
            runGamePrompt({msg =  gameConfig.strings:string_common("general",22) })
        else
            if not GameScene:checkopenlevelbyId(135) then return end
            GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "up", sid = self.sid or 1})
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton1:setSwallowsTouch(true)
    self.infoItems.doButton1:setTouchPriority(self.touchPriority-1)

    if self.islead and self.islead == 1 then
        -- self.infoItems.doNode2:setPositionX(0)
        self.infoItems.doNode2:setPositionX(300)
        self.infoItems.doNode4:setPositionX(0)
        self.infoItems.doNode6:setPositionX(-300)
        ui.removeGray("CCControlButton",self.infoItems.doButton2)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab2)
        self.infoItems.doButton2:addHandleOfControlEvent(function()
            self.callback = nil
            gameWindows:closeWindowDirect("generalInfoRole")
            GameScene:shiftLayer("lead","up")
        end, CCControlEventTouchUpInside)
    else
        -- self.infoItems.doNode2:setPositionX(0)
        self.infoItems.doNode2:setPositionX(140)
        self.infoItems.doNode6:setPositionX(-280)
        if generalConfig.quality < 3 or self.data.general.level1<=1 then
            ui.addGray("CCControlButton",self.infoItems.doButton2)
            ui.addGray("CCLabelTTF",self.infoItems.doLab2)
        else
            ui.removeGray("CCControlButton",self.infoItems.doButton2)
            ui.removeGray("CCLabelTTF",self.infoItems.doLab2)
        end
        self.infoItems.doButton2:addHandleOfControlEvent(function()
            if not GameScene:checkopenlevelbyId(51) then return end
            if generalConfig.quality < 3 then
                runGamePrompt({msg = gameConfig.strings:string_common("general",23) })
            elseif self.data.general.level1<=1 then
                runGamePrompt({msg = gameConfig.strings:string_common("general",24)})
            else
                GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "train",sid = self.sid or 1})
            end
        end, CCControlEventTouchUpInside)
    end
    self.infoItems.doButton2:setSwallowsTouch(true)
    self.infoItems.doButton2:setTouchPriority(self.touchPriority-1)

    if generalConfig.quality < 3 then
        ui.addGray("CCControlButton",self.infoItems.doButton3)
        ui.addGray("CCLabelTTF",self.infoItems.doLab3)
    else
        ui.removeGray("CCControlButton",self.infoItems.doButton3)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab3)
    end

    self.infoItems.doButton3:addHandleOfControlEvent(function()
        if not GameScene:checkopenlevelbyId(52) then return end
        if generalConfig.quality < 3 then
            --runGamePrompt({msg = "绿色伙伴无法突破"})
            runGamePrompt({msg = gameConfig.strings:string_common("general",6)})
        else
            GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "tupo",sid = self.sid or 1})
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton3:setSwallowsTouch(true)
    self.infoItems.doButton3:setTouchPriority(self.touchPriority-1)

    self.infoItems.doButton4:addHandleOfControlEvent(function()

        if self.islead and self.islead == 1 then
            if not gameConfig:checkBuildOpen(567)  then
                runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")}) 
            elseif  not GameScene:checkopenlevelbyId(567) then 
                return
            else
                GameScene:shiftLayerById(567)
            end

        else
            if not gameConfig:checkBuildOpen(174)  then
                runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")}) 
            elseif  not GameScene:checkopenlevelbyId(174) then 
                return
            elseif generalConfig.awaken == 0 then
                --runGamePrompt({msg = "绿色伙伴无法突破"})
                runGamePrompt({msg = gameConfig.strings:string_common("general",31)})
            else
                GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "awaken",sid = self.sid or 1})
            end
        end

        
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton4:setSwallowsTouch(true)
    self.infoItems.doButton4:setTouchPriority(self.touchPriority-1)

    if GameScene:checkopenlevelbyId(378,true) and generalConfig.quality >= 3 then
        ui.removeGray("CCControlButton",self.infoItems.doButton5)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab5)
    else
        ui.addGray("CCControlButton",self.infoItems.doButton5)
        ui.addGray("CCLabelTTF",self.infoItems.doLab5)
    end

    self.infoItems.doButton5:addHandleOfControlEvent(function()
        if not gameConfig:checkBuildOpen(378)  then
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")}) 
        elseif  not GameScene:checkopenlevelbyId(378) then 
            return
        elseif generalConfig.quality < 3 then
            runGamePrompt({msg = gameConfig.strings:string_common("general",39)})
        -- elseif  gamedata.config.Immortal_level["1"]["0"].generalLevel > self.data.general.level1 then
        --     runGamePrompt({msg =  gameConfig.strings:string_common("general",32)})
        else
            GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "xiulian",sid = self.sid or 1})
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton5:setSwallowsTouch(true)
    self.infoItems.doButton5:setTouchPriority(self.touchPriority-1)


    if gameConfig:checkBuildOpen(449) and((ui.judgeFeiSheng(self.data.general.cid) or (self.islead and self.islead == 1))) and GameScene:checkopenlevelbyId(449,true) then
        ui.removeGray("CCControlButton",self.infoItems.doButton6)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab6)
    else
        ui.addGray("CCControlButton",self.infoItems.doButton6)
        ui.addGray("CCLabelTTF",self.infoItems.doLab6)
    end

    self.infoItems.doButton6:addHandleOfControlEvent(function()
        if not gameConfig:checkBuildOpen(449)  then
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")}) 
        elseif  not GameScene:checkopenlevelbyId(449) then 
            return
        else

            if self.islead and self.islead == 1 then
                -- gameWindows:openWindow("generalFeiSheng",self.data)
                -- GameScene:shiftLayer("generalFeiSheng","up",self.data)
                GameScene:shiftLayerById(466)
            else
                if ui.judgeFeiSheng(self.data.general.cid) then
                    GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "feisheng",sid = self.sid or 1})
                else
                    runGamePrompt({msg = gameConfig.strings:string_common("general",53)})
                end
                
            end
            
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton6:setSwallowsTouch(true)
    self.infoItems.doButton6:setTouchPriority(self.touchPriority-1)


    if gameConfig:checkBuildOpen(572) and GameScene:checkopenlevelbyId(572,true) and self.data.general.level2 > 13 then
        ui.removeGray("CCControlButton",self.infoItems.doButton7)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab7)
    else
        ui.addGray("CCControlButton",self.infoItems.doButton7)
        ui.addGray("CCLabelTTF",self.infoItems.doLab7)
    end

    self.infoItems.doButton7:addHandleOfControlEvent(function()
        if not gameConfig:checkBuildOpen(572)  then
            runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng")}) 
        elseif  not GameScene:checkopenlevelbyId(572) then 
            return
        else
            if self.data.general.level2 > 13 then
                GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "upstar",sid = self.sid or 1})
            else
                runGamePrompt({msg = "彩金将开启"})
            end
            
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton7:setSwallowsTouch(true)
    self.infoItems.doButton7:setTouchPriority(self.touchPriority-1)

    self:getMessage(generalConfig)

    addDelayUpdateFunc(function()
        if self.root then
            self:createYuanNode( generalConfig )
        end
    end,"windowgeneralinfo",1)

    if self.islead and self.islead == 1 then
    else
        if not GameScene:checkopenlevelbyId(51,true) then
            ui.addGray("CCControlButton",self.infoItems.doButton2)
            ui.addGray("CCLabelTTF",self.infoItems.doLab2)
        end

        if self.opt and self.opt == 3 then
        else
            if not GameScene:checkopenlevelbyId(135,true) then
                ui.addGray("CCControlButton",self.infoItems.doButton1)
                ui.addGray("CCLabelTTF",self.infoItems.doLab1)
            end
        end

        if not GameScene:checkopenlevelbyId(52,true) then
            ui.addGray("CCControlButton",self.infoItems.doButton3)
            ui.addGray("CCLabelTTF",self.infoItems.doLab3)
        end
    end

end
--创建缘分技能node
function generalInfo.createYuanNode(self, generalConfig )


    self.infoItems.scrollnode = tolua.cast(self.infoItems.scrollnode, "CCScrollView")
    self.infoItems.scrollnode:setTouchPriority(self.touchPriority)
	-- self:getMessage(generalConfig)
	self.yuanNode, self.yuanItems = CCBReaderLoad("general_new/g_general_info_new", nil, true, "g_general_info_new")
	self.infoItems.container:addChild(self.yuanNode)
	self.yuanNode:setPosition(0,100*self.message.maxnum+self.message.fixH)
	--设置tilte位置

    local feishengH = 0
    if self.data.general.level8 and self.data.general.level8 > 0 and (ui.judgeFeiSheng(self.data.general.cid) or (self.islead and self.islead == 1)) then
        feishengH = 240
    else
        self.yuanItems.g_feishengNode:setVisible(false)
    end

    if self.islead and self.islead == 1 then
        if generalConfig.combskillid and generalConfig.combskillid > 0 then
            if GameScene.fashiondata and GameScene.fashiondata.fashions and next(GameScene.fashiondata.fashions) then

                self.yuanItems.g_feishengNode:setPositionY(-480)
                self.yuanItems.g_fashionNode:setPositionY(-480 - feishengH)
                self.yuanItems.g_breakNode:setPositionY(-720 - feishengH)
                self.yuanItems.g_yuanNode:setPositionY(-720 - feishengH -(self.message.breaknum > 0 and self.message.breakH or 0))
                self.yuanItems.g_fashionNode:setVisible(true)
                self:setFashionCellAll()
            else

                self.yuanItems.g_feishengNode:setPositionY(-480)
                self.yuanItems.g_breakNode:setPositionY(-480 - feishengH)
                self.yuanItems.g_yuanNode:setPositionY(-480 - feishengH -(self.message.breaknum > 0 and self.message.breakH or 0))
                self.yuanItems.g_fashionNode:setVisible(false)
            end
        else
            if GameScene.fashiondata and GameScene.fashiondata.fashions and next(GameScene.fashiondata.fashions) then

                self.yuanItems.g_feishengNode:setPositionY(-280)
                self.yuanItems.g_fashionNode:setPositionY(-280 - feishengH)
                self.yuanItems.g_breakNode:setPositionY(-520 - feishengH)
                self.yuanItems.g_yuanNode:setPositionY(-520 - feishengH -(self.message.breaknum > 0 and self.message.breakH or 0))
                self.yuanItems.g_fashionNode:setVisible(true)
                self:setFashionCellAll()
            else

                self.yuanItems.g_feishengNode:setPositionY(-280)
                self.yuanItems.g_breakNode:setPositionY(-280  - feishengH)
                self.yuanItems.g_yuanNode:setPositionY(-280 - feishengH -(self.message.breaknum > 0 and self.message.breakH or 0))
                self.yuanItems.g_fashionNode:setVisible(false)
            end
        end
        self.yuanItems.g_partnerfashionNode:setVisible(false)
    else
        if self.data.general.combskill and self.data.general.combskill.cid then
            self.yuanItems.g_partnerfashionNode:setPositionY(-480)
            self.yuanItems.g_feishengNode:setPositionY(-480-self.message.partnerfashion_fixH)
            self.yuanItems.g_breakNode:setPositionY(-480 - feishengH -self.message.partnerfashion_fixH)
            self.yuanItems.g_yuanNode:setPositionY(-480 - feishengH -(self.message.breaknum > 0 and self.message.breakH or 0)-self.message.partnerfashion_fixH)
        else
            self.yuanItems.g_partnerfashionNode:setPositionY(-280)
            self.yuanItems.g_feishengNode:setPositionY(-280-self.message.partnerfashion_fixH)
            self.yuanItems.g_breakNode:setPositionY(-280 - feishengH -self.message.partnerfashion_fixH)
            self.yuanItems.g_yuanNode:setPositionY(-280 - feishengH -(self.message.breaknum > 0 and self.message.breakH or 0)-self.message.partnerfashion_fixH)
        end
        if self.message.partnerfashion and #self.message.partnerfashion > 0 and self.opt  and self.opt ~= 2 then
            self.yuanItems.g_partnerfashionNode:setVisible(true)
            self:createPartnerfashionLink()
        else 
            self.yuanItems.g_partnerfashionNode:setVisible(false)
        end   
    end
	self:createSkill(generalConfig)
    self:setFeiShengAttr()
	self:createAdvanced(generalConfig)
	self:createLink(generalConfig)
end

function generalInfo.setFeiShengAttr(self)

    local g_atk = 0
    local g_def = 0
    local g_hp = 0
    local speed = 0

    if self.data.general.level8 and self.data.general.level8 > 0 then
        if self.islead and self.islead == 1 then
            g_atk = gamedata.config.passive_soaring[tostring(self.data.general.level8)].xianadk
            g_def = gamedata.config.passive_soaring[tostring(self.data.general.level8)].xiandef
            g_hp = gamedata.config.passive_soaring[tostring(self.data.general.level8)].xianhp
            speed = gamedata.config.passive_soaring[tostring(self.data.general.level8)].speed
        else
            local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
            local originalBasic = gamedata.config.general[tostring(gamedata.getOriginCid(self.data.general.cid))].basic

            if gamedata.config.partner_soaring["0"][originalBasic.."consume"] then
                g_atk = gamedata.config.partner_soaring[tostring(self.data.general.level8)][originalBasic.."xianadk"]
                g_def = gamedata.config.partner_soaring[tostring(self.data.general.level8)][originalBasic.."xiandef"]
                g_hp = gamedata.config.partner_soaring[tostring(self.data.general.level8)][originalBasic.."xianhp"]
                speed = gamedata.config.partner_soaring[tostring(self.data.general.level8)][originalBasic.."speed"]
            end
        end
    end

    ui.setLabelString(self.yuanItems.g_feisheng_attr1,gameConfig.strings.attr_type["g_atk"].."："..g_atk,13)
    ui.setLabelString(self.yuanItems.g_feisheng_attr2,gameConfig.strings.attr_type["g_def"].."："..g_def,13)
    ui.setLabelString(self.yuanItems.g_feisheng_attr3,gameConfig.strings.attr_type["g_hp"].."："..g_hp,13)
    ui.setLabelString(self.yuanItems.g_feisheng_attr4,gameConfig.strings.attr_type["speed"].."："..speed,13)
    
end

--获取创建技能cell一些进本数据
function generalInfo.getMessage(self,generalConfig)

    local breakconfig = gamedata.config.breakskill or {}
    local breakH = 100
    local breaknum = 0
    local breaklist = {}
    local partnerfashion = {}
    local partnerfashion_fixH = 0
    local feisheng_fixH = 240

--    if self.islead ~= 1 then
	    for i = 1,50 do
	        if generalConfig["break"..i] and generalConfig["break"..i] > 0 then
	            breaknum = breaknum + 1
	            local param = 1
	            if breakconfig[tostring(generalConfig["break"..i])] and breakconfig[tostring(generalConfig["break"..i])].desc_param and breakconfig[tostring(generalConfig["break"..i])].desc_param>0 then
	                param = breakconfig[tostring(generalConfig["break"..i])].desc_param
	            else
	                param = 1
	            end
	            breakH = breakH + (50*param)
	            table.insert(breaklist,{lv = i, id = generalConfig["break"..i], param = param,data = breakconfig[tostring(generalConfig["break"..i])]})
	        end
	    end
        --todo gold
        for i = 1,3 do
            for j = 1,3 do
                if generalConfig["gold"..i.."_will_skills_"..j] and generalConfig["gold"..i.."_will_skills_"..j] > 0 then
                    breaknum = breaknum + 1
                    local param = 1
                    if breakconfig[tostring(generalConfig["gold"..i.."_will_skills_"..j])] and breakconfig[tostring(generalConfig["gold"..i.."_will_skills_"..j])].desc_param and breakconfig[tostring(generalConfig["gold"..i.."_will_skills_"..j])].desc_param>0 then
                        param = breakconfig[tostring(generalConfig["gold"..i.."_will_skills_"..j])].desc_param
                    else
                        param = 1
                    end
                    breakH = breakH + (50*param)
                    table.insert(breaklist,{goldlv = i, goldscope = j,lv = i + ((self.islead and self.islead == 1) and 23 or 13), id = generalConfig["gold"..i.."_will_skills_"..j], param = param,data = breakconfig[tostring(generalConfig["gold"..i.."_will_skills_"..j])]})
                end
            end    
        end    
--    else
--    	local dataConfig  = gamedata.config.protagonist_grow
--
--        for k,v in pairs(dataConfig) do
--            if v.skill_ext and v.skill_ext > 0 then
--            	local name,desc = "",""
--            	for m,n in pairs(self.passiveconfig) do
--            		if tonumber(v.skill_ext) == tonumber(n.id) then
--            			name = n.skill_name
--            			desc = n.desc
--            		end
--            	end
--                table.insert(breaklist,{lv = v.level, id = v.skill_ext,param = 1,data = {name =name,desc = desc,desc_param = 1 }})
--                breakH = breakH + 50
--            end
--        end
--        local sortfunc = function (a,b)
--            return a["lv"] < b["lv"]
--        end
--        table.sort(breaklist,sortfunc)
--    end
    --
    local fixH = 480+80
    if self.islead and self.islead == 1 then
        local fashion_fixH = 0
        if GameScene.fashiondata and GameScene.fashiondata.fashions and next(GameScene.fashiondata.fashions) then
            fashion_fixH = 240
        end
        if generalConfig.combskillid and generalConfig.combskillid > 0 then
            fixH = 480+80+(breaknum>0 and breakH or 0)+fashion_fixH
        else
            fixH = 280+80+(breaknum>0 and breakH or 0)+fashion_fixH
        end

    else
        partnerfashion_fixH = 0
        partnerfashion = {}
        --
        local o_cid = self.data.general.cid
        if gamedata.config.general[tostring(o_cid)] and gamedata.config.general[tostring(o_cid)].partner_id and gamedata.config.general[tostring(o_cid)].partner_id > 0 then
            o_cid = gamedata.config.general[tostring(o_cid)].partner_id
        end  
        for k,v in pairs(gamedata.config.partner_fashion) do
            if (o_cid == v.orange_partner) or (o_cid == v.orange_partner2) or (o_cid == v.red_partner) or (o_cid == v.red_partner2) or (o_cid == v.gold_partner) or (o_cid == v.gold_partner2) then
                table.insert(partnerfashion,v)
            end
        end
        if #partnerfashion > 0 and self.opt  and self.opt ~= 2 then
            partnerfashion_fixH = 50 + #partnerfashion*100
        end    
        if self.data.general.combskill and self.data.general.combskill.cid then
            fixH = 480+80+(breaknum>0 and breakH or 0)+partnerfashion_fixH
        else
            fixH = 280+80+(breaknum>0 and breakH or 0)+partnerfashion_fixH
        end    
    end

    local relation = self.data.relation or {}
    local maxnum = 0
    for i = 1,50 do
        if generalConfig["cond"..i.."ids"] and generalConfig["cond"..i.."ids"]~="" then
            maxnum = i
        end
    end
    if maxnum > 50 then maxnum = 50 end

-- {
-- 	breaknum, 突破技能数量
-- 	breaklist, 突破技能
-- 	fixH,	技能占的高度
-- 	maxnum  仙缘技能数量
--  breakH 进阶的高度
-- }
    --飞升高度
    if self.data.general.level8 and self.data.general.level8 > 0 and (ui.judgeFeiSheng(self.data.general.cid) or (self.islead and self.islead == 1)) then
        fixH = fixH + feisheng_fixH
    end

    self.message = {breaknum = breaknum,breaklist = breaklist,fixH = fixH,maxnum = maxnum,breakH = breakH,partnerfashion = partnerfashion,partnerfashion_fixH = partnerfashion_fixH}
    self.infoItems.container:setContentSize(CCSize(1000,100*self.message.maxnum+self.message.fixH))
    self.infoItems.scrollnode:setContentOffsetInDuration(ccp(0,820 - self.changeHight -100*maxnum-fixH),0)

end
--创建技能对象
function generalInfo.createSkill(self,generalConfig)
    -- 设置技能
    if self.data.general.illusionGeneralCid then
        local gdata = ui.getConfigGeneralSion(self.data.general)
        if next(gdata) and generalConfig.fashion_id == 0 then
            if gdata.skillid and gdata.skillid > 0 then
                self.data.general.skill.cid = gdata.skillid
            end
            if gdata.special_skill_reveal and gdata.special_skill_reveal > 0 then
                self.data.general.skill.cid = gdata.special_skill_reveal
            end
            self.data.general.skill.quality = self.data.general.quality
        end
    else
        local gdata = ui.getConfigGeneral(self.data.general)
        if next(gdata) and generalConfig.fashion_id == 0 then
            if gdata.skillid and gdata.skillid > 0 then
                self.data.general.skill.cid = gdata.skillid
            end
            if gdata.special_skill_reveal and gdata.special_skill_reveal > 0 then
                self.data.general.skill.cid = gdata.special_skill_reveal
            end
            self.data.general.skill.quality = self.data.general.quality
        end
    end
	local skillconfig = ui.IDconfig(self.data.general.skill.cid)
    self:createSkillCell(skillconfig,false)
    
    if generalConfig.combskillid and generalConfig.combskillid > 0 then
		local combskillconfig = gamedata.config.combskill[tostring(self.data.general.combskill.cid)]
		self:createSkillCell(combskillconfig,true)
    end
end
--skillconfig 数据
--aiBool 是不是合体技
function generalInfo.createSkillCell(self, skillconfig,aiBool )
	local skillNode, skillItems =  CCBReaderLoad("general_new/g_general_skill_info_new", nil, true, "g_general_skill_info_new")
	self.yuanNode:addChild(skillNode) 
	
	skillItems.s_iscombskill:setVisible(aiBool)
    ui.setLabelString(skillItems.s_iscombskill,nil,7)
	skillItems.s_skill_lv:setVisible(false)
	if aiBool == false then
		ui.setNewIcon(skillItems,self.data.general.skill)
		skillNode:setPosition(ccp(self.cX,-160))
	else
		ui.setNewIcon(skillItems,self.data.general.combskill )
		skillNode:setPosition(ccp(self.cX,-360 ))
		local args = {
			frame = self.png.line,
			x = self.cX,
			y = -260,
			ax = 0.5,
			ay = 0.5,
		}
		local tSprite = ui.createSpriteWithImage(args)
		tSprite:setScaleX(2)
		self.yuanItems.g_skillNode:addChild( tSprite ) 		
	end
    ui.setLabelString(skillItems.s_skill_name,skillconfig.name,7)
    ui.setLabelString(skillItems.s_skill_desc,skillconfig["skill-desc"] or "",13)
    skillItems.skillshowButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(1)
        if aiBool == false then
        	ui.skillView(self.data.general.skill.cid)
        else
        	ui.skillView(self.data.general.combskill.cid)
        end
    end, CCControlEventTouchUpInside)
    skillItems.skillshowButton:setSwallowsTouch(true)
    skillItems.skillshowButton:setTouchPriority(self.touchPriority)	
    skillItems.skilliconButton:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        gameTouch:clickprofbytime(1)
    	local skilltype = "skill"
    	if aiBool == true and self.islead == 1  then
    		skilltype = "leadskill"
    	elseif aiBool == true  then
    		skilltype = "combskill"
    	end
        gameWindows:openWindow("generalInfoSkill",{data = self.data ,sid = self.data.sid, pagetype = "skillinfo",skilltype =  skilltype  })
    end, CCControlEventTouchUpInside)
    skillItems.skilliconButton:setSwallowsTouch(true)
    skillItems.skilliconButton:setTouchPriority(self.touchPriority)
end
function generalInfo.createAdvanced( self )
	local hight = 0 --从第几行显示
    if self.islead ~= 1 then
        self.yuanItems.advancelable:setString("突破")
    end
	for i = 1,#self.message.breaklist do
		self:createAdvancedCell(self.message.breaklist[i],hight)
		hight = hight + self.message.breaklist[i].data.desc_param
	end
end
--fashion
function generalInfo.setFashionCellAll(self)

    local allnum = {
        atk = 0,
        def = 0,
        hp = 0,
        speed = 0,
        critical = 0,
        dodge = 0,
        parry = 0,
        subdmg = 0,
        adddmg = 0,
        adddmgpct = 0,
        subdmgpct = 0,
        hit = 0,
        criticaldmg = 0,
        resilience = 0,
        arp = 0,
        ap = 0,
        ap_atk_p = 0,
    }

    if GameScene.fashiondata.fashions then
        for k,v in pairs(GameScene.fashiondata.fashions) do
            --attr
            local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(v.id)] or {}
            local levelnow = v.level or 1
            if not upconfigall[tostring(levelnow)] then break end
            local upconfig = upconfigall[tostring(levelnow)] or {}

            for i = 1,3 do
                if upconfig["intentify_add"..i] and upconfig["intentify_add"..i] ~= "" then
                    local attr,num = ui.getATTRandNUM(upconfig["intentify_add"..i])
                    if allnum[attr] then
                        allnum[attr] = allnum[attr] + num
                    end
                end
            end
            --
            for i = 1,levelnow do
                if upconfigall[tostring(i)] and upconfigall[tostring(i)]["add_attribute"] and upconfigall[tostring(i)]["add_attribute"] ~= "" then
                    local attr,num = ui.getATTRandNUM(upconfigall[tostring(i)]["add_attribute"])
                    if allnum[attr] then
                        allnum[attr] = allnum[attr] + num
                    end
                end
            end
        end
    end

    --ui.setLabelString(self.yuanItems.g_fashion_lab1,"时装总属性：",13)

    for i = 1,4 do
        ui.setLabelString(self.yuanItems["g_fashion_lab"..i],"",13)
    end

    local hasnum = 0
    for k,v in pairs(allnum) do
        if v > 0 then
            hasnum = hasnum+1
            if hasnum <= 3 then
                ui.setLabelString(self.yuanItems["g_fashion_lab"..(hasnum)],gameConfig.strings.attr_type[k].." +"..((v > 0 and v < 1) and ((v*100).."%") or v),13)
            end
        end
    end

end


function generalInfo.setFashionCell( self )

    --attr
    local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(GameScene.fashiondata.fashionid)] or {}
    local levelnow = GameScene.fashiondata.fashions[tostring(GameScene.fashiondata.fashionid)] and GameScene.fashiondata.fashions[tostring(GameScene.fashiondata.fashionid)].level or 1
    if not upconfigall[tostring(levelnow)] then return end
    local upconfig = upconfigall[tostring(levelnow)] or {}
    ui.setLabelString(self.yuanItems.g_fashion_lab1,"基础属性：",13)
    local attrstr = ""
    local attrstr2 = ""
    for i = 1,3 do
        if upconfig["intentify_add"..i] and upconfig["intentify_add"..i] ~= "" then
            local attr,num = ui.getATTRandNUM(upconfig["intentify_add"..i])
            attrstr = attrstr..(gameConfig.strings.attr_type[attr] or "").." +"..num.."    "
        end
    end
    ui.setLabelString(self.yuanItems.g_fashion_lab2,attrstr,13)
    --
    local allnum = {
        atk = 0,
        def = 0,
        hp = 0,
        speed = 0,
        critical = 0,
        dodge = 0,
        parry = 0,
        subdmg = 0,
        adddmg = 0,
        adddmgpct = 0,
        subdmgpct = 0,
        hit = 0,
        criticaldmg = 0,
        resilience = 0,
        arp = 0,
        ap = 0,
        ap_atk_p = 0,
    }

    for i = 1,levelnow do
        if upconfigall[tostring(i)] and upconfigall[tostring(i)]["add_attribute"] and upconfigall[tostring(i)]["add_attribute"] ~= "" then
            local attr,num = ui.getATTRandNUM(upconfigall[tostring(i)]["add_attribute"])
            if allnum[attr] then
                allnum[attr] = allnum[attr] + num
            end
        end
    end

    local hasnum = 0
    for k,v in pairs(allnum) do
        if v > 0 then
            hasnum = hasnum+1
            attrstr2 = attrstr2..(gameConfig.strings.attr_type[k] or "").." +"..((v > 0 and v < 1) and ((v*100).."%") or v).."    "
        end
    end

    if hasnum > 0 then
        ui.setLabelString(self.yuanItems.g_fashion_lab3,"强化属性：",13)
        ui.setLabelString(self.yuanItems.g_fashion_lab4,attrstr2,13)
    else
        ui.setLabelString(self.yuanItems.g_fashion_lab3,"",13)
        ui.setLabelString(self.yuanItems.g_fashion_lab4,"",13)
    end
    --

end

--创建进阶对象Cell
function generalInfo.createAdvancedCell(self,aiData,aiHeight )
	local isActivate = false --是否激活
	if self.data.general.level2 >= aiData.lv then
		isActivate = true
	end
	if self.islead == 1 and GameScene.protagonist.level2 >= aiData.lv then
		isActivate = true
	end
    local argsName = {
        text = aiData.data.name,
        color = isActivate and ccc3(255,255,0) or ccc3(169, 169, 169),
        fontsize = 29,
        font = "Helvetica-Bold",
        x = 30,
        y = -70 - aiHeight * 50 ,
        ax = 0,
        ay = 1,
        dw = 730,
        dh = 50*aiData.data.desc_param,
        hAlignment = kCCTextAlignmentLeft,
        vAlignment = kCCVerticalTextAlignmentTop
    }
    local textName = ui.createLabel(argsName)
    self.yuanItems.g_breakNode:addChild(textName) 
    local node  = ui.createNode({
            w = 610,
            h = 35,
            ax = 0,
            ay = 1,
            x = 158,
            y = -70 - aiHeight * 50,
            scale = 1,        
        })
    self.yuanItems.g_breakNode:addChild(node)

    local args = {}
    table.insert(args,{fontID = 334,content = ":"})
    if self.islead == 0 or  self.islead == false then
        -- if aiData.lv > 13 then
        --     table.insert(args,{fontID = isActivate and 333 or 335,content = (aiData.lv>13 and ("(金色+"..tostring(aiData.lv-13)) or ("(+"..tostring(aiData.lv)))..")"})
        -- else
        --     table.insert(args,{fontID = isActivate and 333 or 335,content = (aiData.lv>10 and ("(红色+"..tostring(aiData.lv-10)) or ("(+"..tostring(aiData.lv))).."激活)"})
        -- end

        table.insert(args,{fontID = isActivate and 333 or 335,content = "+"..aiData.lv.."激活"})
    else
--        local quality = tonumber(self.protagonist_growConfig[tostring(aiData.lv)].skillcolor)
--        if isActivate == true and self.opt and self.opt ~= 2  then --self.opt ~= 2 判定是不是从缘分里面进来的
--            table.insert(args,{fontID = quality*2 -1,content = " "})--"("..gameConfig.strings:string_common("quality",quality)..")"})
--        else
--            table.insert(args,{fontID = 335,content = " "}) --"("..gameConfig.strings:string_common("quality",quality)..")"})
--        end
    end
    table.insert(args,{fontID = 334,content = aiData.data.desc or ""})
    ui.createRichLabel(args,node)

    if aiData.goldscope and aiData.goldscope > 0 then
        --
        local sprite = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("tujin_"..self.scopetype[aiData.goldscope]))
        sprite:setScale(0.5)
        self.yuanItems.g_breakNode:addChild(sprite) 
        sprite:setPosition(ccp(840,-90 - aiHeight * 50))   
        --

        if aiData.goldlv and aiData.goldlv > 0 and self.data.general["g_score"..aiData.goldlv] and self.data.general["g_score"..aiData.goldlv] > 0 and self.data.general["g_score"..aiData.goldlv] == aiData.goldscope then
            local sprite = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("yixuanzezi"))
            self.yuanItems.g_breakNode:addChild(sprite) 
            sprite:setPosition(ccp(930,-90 - aiHeight * 50))   
        else
            local sprite = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame("weixuanzezi"))
            self.yuanItems.g_breakNode:addChild(sprite) 
            sprite:setPosition(ccp(930,-90 - aiHeight * 50))   
        end
    else
    	if isActivate == true and self.opt and self.opt ~= 2  then--self.opt ~= 2 判定是不是从缘分里面进来的
    		-- local otherArgs = {
    		-- 	frame = self.png.activate,
    		-- 	x = 890,
    		-- 	y = -90 - aiHeight * 50,
    		-- 	ax = 0.5,
    		-- 	ay = 0.5,
    		-- }
    		-- self.yuanItems.g_breakNode:addChild( ui.createSprite(otherArgs) ) 
            local sprite = CCSprite:createWithSpriteFrame(ui.itemcache:getSpriteFrame(self.png.activate))
            self.yuanItems.g_breakNode:addChild(sprite) 
            sprite:setPosition(ccp(910,-90 - aiHeight * 50))        
    	else
    		local otherArgs = {
    			text = "未激活",
    			color = ccc3(169, 169, 169),
    			fontsize = 42,
    			font = "Helvetica-Bold",
    			x = 910,
    			y = -90 - aiHeight * 50 ,
    			ax = 0.5,
    			ay = 0.5,
    			dw = 130,
    			dh = 50,
    			hAlignment = kCCTextAlignmentLeft,
    			vAlignment = kCCVerticalTextAlignmentTop
    		}
    		self.yuanItems.g_breakNode:addChild(ui.createLabel(otherArgs)) 		
    	end
    end    
end
--创建仙缘技能
function generalInfo.createLink( self,generalConfig )
	for i = 1,self.message.maxnum do
		self:createLinkCell(i)
	end
end
--创建仙缘技能Cell
function generalInfo.createLinkCell(self,aiIndex)
	local linkNode, linkItems =  CCBReaderLoad("general_new/cell_yuan3", nil, true, "cell_yuan2")
	self.yuanItems.g_yuanNode:addChild(linkNode)
	linkNode:setPosition(self.cX,-100 -100*(aiIndex- 1))
    print("aiIndex ======= "..aiIndex )
    printT(self.data.relation)
    local netData = self.data.relation[tostring(aiIndex)] --单个仙缘信息
    if netData.activate>= 2  and self.opt  and self.opt ~= 2 then--self.opt ~= 2 判定是不是从缘分里面进来的
        linkItems.y_activate_yes:setVisible(true)
        linkItems.y_activate_no:setVisible(false)
        ui.setLabelString(linkItems.y_name,self.generalConfig["cond"..aiIndex.."name"],333)
    else
        linkItems.y_activate_yes:setVisible(false)
        linkItems.y_activate_no:setVisible(true)  
        ui.setLabelString(linkItems.y_name,self.generalConfig["cond"..aiIndex.."name"],335)
    end
    
    local linkType = 0
    if self.generalConfig["cond"..aiIndex.."type"] == "person" then
        linkType = 1
    else
        linkType = 0
    end
    local args = {}
    table.insert(args,{fontID = 334,content = linkType == 1  and ":和" or ":装备"})
    if linkType == 1 then
        local ids = ui.Split(self.generalConfig["cond"..aiIndex.."ids"],";") or {}
        for i = 1,#ids do
            if ids[i] and ids[i] ~= ""    then
                local islight = false
                for k,v in pairs( self.data.relation[tostring(aiIndex)].ids) do
                    if v == tonumber(ids[i]) then
                        islight = true
                        break
                    end
                end
                if islight == true then
                    table.insert(args,{fontID = 333,content = self.allGeneralConfig[ tostring(ids[i]) ].name })
                else
                    table.insert(args,{fontID = 335,content = self.allGeneralConfig[ tostring(ids[i]) ].name })
                end
            end
            if ids[i + 1] and ids[i + 1] ~= "" then
                table.insert(args,{fontID = 334,content = "、" })
            end
        end
        table.insert(args,{fontID = 334,content = "一起上阵" })
    else
        if netData.activate>= 2 then
            table.insert(args,{fontID = 333,content = self.generalConfig["cond"..aiIndex.."name"] })
        else
            table.insert(args,{fontID = 335,content = self.generalConfig["cond"..aiIndex.."name"] })
        end
    end
    table.insert(args,{fontID = 334,content = self.generalConfig[ "cond"..aiIndex.."desc" ] })
    local offsetY =  ui.createRichLabel(args,linkItems.y_namenode)
    if offsetY <= 50 then
        linkItems.y_namenode:setPositionY(linkItems.y_namenode:getPositionY() - 18.4)
        linkItems.y_name:setPositionY(linkItems.y_name:getPositionY() - 18.4)
    end
end
function generalInfo.findFragmentIDByHeroID(self,aiID)

    local aiID = aiID
    if gamedata.config.general[tostring(aiID)].partner_id and gamedata.config.general[tostring(aiID)].partner_id > 0 then
        aiID = gamedata.config.general[tostring(aiID)].partner_id
    end 

    if gamedata.config.general[tostring(aiID)] and gamedata.config.general[tostring(aiID)].quality and gamedata.config.general[tostring(aiID)].quality >= 6 then
        return aiID
    end    

    if self.fragmentConfig[tostring(aiID + 1000)] ~=nil and self.fragmentConfig[tostring(aiID + 1000)].general == aiID  then
        return self.fragmentConfig[tostring(aiID + 1000)].id
    end
    for k,v in pairs(self.fragmentConfig) do
        if v.general == aiID then
            return v.id
        end
    end
    print("无此英雄碎片===========")
end

--
--时装
function generalInfo.createPartnerfashionLink(self)
    for i = 1,#self.message.partnerfashion do
        self:createPartnerfashionLinkCell(i)
    end
end
--时装
function generalInfo.createPartnerfashionLinkCell(self,aiIndex)
    local linkNode, linkItems =  CCBReaderLoad("general_new/cell_fashion", nil, true, "cell_fashion")
    self.yuanItems.g_partnerfashionNode:addChild(linkNode)
    linkNode:setPosition(self.cX,-100 -100*(aiIndex- 1))

    if GameScene.partnerfashion and GameScene.partnerfashion[tostring(self.message.partnerfashion[aiIndex].fashion_id)] and GameScene.partnerfashion[tostring(self.message.partnerfashion[aiIndex].fashion_id)].time ~= 0 then
        ui.setLabelString(linkItems.f_name,self.message.partnerfashion[aiIndex].name.."：",333)
        linkItems.f_activate_yes:setVisible(true)
        linkItems.f_activate_no:setVisible(false)  
    else
        linkItems.f_activate_yes:setVisible(false)
        linkItems.f_activate_no:setVisible(true)  
        ui.setLabelString(linkItems.f_name,self.message.partnerfashion[aiIndex].name.."：",335)
    end
    
    local args = {}
    table.insert(args,{fontID = 334,content = "获得 "})
    if GameScene.partnerfashion and GameScene.partnerfashion[tostring(self.message.partnerfashion[aiIndex].fashion_id)] and GameScene.partnerfashion[tostring(self.message.partnerfashion[aiIndex].fashion_id)].time ~= 0 then
        table.insert(args,{fontID = 333,content = self.message.partnerfashion[aiIndex].name })
    else
        table.insert(args,{fontID = 335,content = self.message.partnerfashion[aiIndex].name })
    end
    
    table.insert(args,{fontID = 334,content = " "..self.message.partnerfashion[aiIndex].instructions })
    local offsetY =  ui.createRichLabel(args,linkItems.f_namenode)
    -- if offsetY <= 50 then
    --     linkItems.f_namenode:setPositionY(linkItems.f_namenode:getPositionY() - 18.4)
    --     linkItems.f_name:setPositionY(linkItems.f_name:getPositionY() - 18.4)
    -- end
end


return generalInfo
   U* 