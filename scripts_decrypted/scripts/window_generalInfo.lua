--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/5/30
-- Time: 14:45
-- To change this template use File | Settings | File Templates.
--
--skill,leadskill,combskill

local generalInfo = {
    rootNode = nil,
    rootItems = nil,

    pageconfig = {"info","inherit","train","up","skillinfo","skillup"},
    pagetype = "info",
    skilltype = "skill",
    inheritSelect = 1,
    fdata = nil,
    trainSelect = 1,
    trainResuit = false,
    hasup = 0,

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
    region = gameConfig.strings:string_common("popups","region0")
}

function generalInfo.open(self,touchPriority,data,callback)

    self.root = ui.createNode()

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.root
end

function generalInfo.reload(self,data,callback)
    self.callback = callback
    self.data = data.data or {}
    self.islead = data.islead or 0
    self.opt = data.opt or 0
    self.sid = data.sid or 1

    if self.data.general and self.data.general.iid and self.data.general.iid == GameScene.protagonist.iid then
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
        self.data.general.skilllevel = 1
        self.data.general.skill = {}
        self.data.general.skill.cid = configdata.skillid or 0
        if configdata.combskillid and configdata.combskillid > 0 then
            self.data.general.combskill = {}
            self.data.general.combskill.cid = configdata.combskillid
        end
    end

    if not (self.data.relation and next(self.data.relation)) then
        self.data.relation = {}
        for i = 1,6 do
            if configdata["cond"..i.."ids"] and configdata["cond"..i.."ids"]~="" then
                self.data.relation[tostring(i)] = { activate = 0 }
            end
        end
    end
    self.pagetype = data.pagetype or self.pagetype
    self.skilltype = data.skilltype or "skill"

    self:showPage(self.pagetype)

end

function generalInfo.reloaddata(self,data)
    self.hasup = 1
    local olddata = self.data.general and table.copy(self.data.general) or nil
    self.data.general = data.general or {}
    self.pagetype = data.pagetype or self.pagetype

    self:showPage(self.pagetype,olddata)

end

function generalInfo.close(self)
    self.data = nil
    self.hasup = 0
    self.fdata = nil
    self.trainResuit = false
    self.skilltype = "skill"
    self.pagetype = "info"
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil

    self.infoItems = nil
    self.inheritItems = nil
    self.trainItems = nil
    self.generalUpItems = nil
    self.skillInfoItems = nil
    self.skillUpItems = nil

    if self.callback then
        self.callback()
    end
end

function generalInfo.showPage(self,type,olddata)
    self.pagetype = type
    print("type==",type)

    if self.pagetype == "info" then
        self.rootNode, self.infoItems = CCBReaderLoad("general_new/general_info2", nil, true, "info")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_info()
    elseif self.pagetype == "inherit" then
        self.rootNode, self.inheritItems = CCBReaderLoad("general_new/general_inherit", nil, true, "inherit")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_inherit()
    elseif self.pagetype == "train" then
        self.rootNode, self.trainItems = CCBReaderLoad("general_new/general_train", nil, true, "train")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_train(olddata)
    elseif self.pagetype == "up" then
        self.rootNode, self.generalUpItems = CCBReaderLoad("general_new/general_up", nil, true, "up")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_up()
    elseif self.pagetype == "skillinfo" then
        self.rootNode, self.skillInfoItems = CCBReaderLoad(self.skilltype == "combskill" and "general_new/skill_info_h" or "general_new/skill_info", nil, true, "skillinfo")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_skillinfo()
    elseif self.pagetype == "skillup" then
        self.rootNode, self.skillUpItems = CCBReaderLoad("general_new/general_up", nil, true, "up")
        self.root:removeAllChildrenWithCleanup(true)
        self.root:addChild(self.rootNode)
        self:setPage_skillup()
    end

end


function generalInfo.setPage_info(self)

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]

    -- 去获取 按钮
    ui.setLabelString(self.infoItems.getText,nil,18)
    self.infoItems.getBtn:addHandleOfControlEvent(function()
        self.callback = nil
        print("getBtn..is")
        gameWindows:openWindow("dropTips",{cid = self.data.general.cid},nil)
    end, CCControlEventTouchUpInside)
    self.infoItems.getBtn:setSwallowsTouch(true)
    self.infoItems.getBtn:setTouchPriority(self.touchPriority)

    self.infoItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.5)
    Gneral:setScaleX(-1.5)
    Gneral:setPosition(0,0)
    self.infoItems["generalNode"]:addChild(Gneral)

    self.infoItems.generalbutton:addHandleOfControlEvent(function()
        Gneral:setAnimation("attack",false,0)
        Gneral:addAnimation("celebrate",false,0,0)
        Gneral:addAnimation("celebrate",false,0,0)
        Gneral:addAnimation("stand",true,0,0)
    end, CCControlEventTouchUpInside)
    self.infoItems.generalbutton:setSwallowsTouch(true)
    self.infoItems.generalbutton:setTouchPriority(self.touchPriority)

    -- self.infoItems.title:setString("角色详情")
    self.infoItems.title:setString(gameConfig.strings:string_common("generalInfo",0))
    self.infoItems.atk:setString(self.data.general.atk)
    self.infoItems.hp:setString(self.data.general.hp)
    self.infoItems.defense:setString(self.data.general.defense)
    self.infoItems.speed:setString(self.data.general.speed)
    self.infoItems.name:setString(generalConfig.name..(self.data.general.level2+0 > 0 and " +"..self.data.general.level2 or ""))
    self.infoItems.lv1:setString(self.data.general.level1)
    self.infoItems.desc:setString(generalConfig.desc)
    --
    self.infoItems.critical:setString(self.data.general.critical)
    self.infoItems.dodge:setString(self.data.general.dodge)
    self.infoItems.parry:setString(self.data.general.parry)
    self.infoItems.hit:setString(self.data.general.hit)
    self.infoItems.resilience:setString(self.data.general.resilience)
    self.infoItems.arp:setString(self.data.general.arp)
    self.infoItems.criticaldmg:setString(self.data.general.criticaldmg)
    self.infoItems.potential:setString(self.data.general.potential)
    --
    self.infoItems.basic:setString((generalConfig.basic and generalConfig.basic or 0 ) + (generalConfig.grow and generalConfig.grow or 0))
    self.infoItems.region:setString(self.region[tostring(generalConfig.region or 6)])
    --
    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.infoItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.infoItems["generaltype"], gameConfig.images[generalConfig.actor])
    end

    if self.islead and self.islead == 1 then
        self.infoItems.name:setString(ui.leadName(GameScene.protagonist.level2))
        self.infoItems.getNode:setVisible(false)
    else
        self.infoItems.getNode:setVisible(true)
    end

    ui.setLabelString(self.infoItems.name,nil,(generalConfig.quality or 1)*2-1)
    ui.setLabelString(self.infoItems.lv1,nil,14)
    --ui.setLabelString(self.infoItems.atk,nil,13)
    --ui.setLabelString(self.infoItems.hp,nil,13)
    --ui.setLabelString(self.infoItems.defense,nil,13)
    --ui.setLabelString(self.infoItems.speed,nil,13)
    --
    --ui.setLabelString(self.infoItems.critical,nil,13)
    --ui.setLabelString(self.infoItems.dodge,nil,13)
    --ui.setLabelString(self.infoItems.parry,nil,13)
    --ui.setLabelString(self.infoItems.hit,nil,13)
    --ui.setLabelString(self.infoItems.resilience,nil,13)
    --ui.setLabelString(self.infoItems.arp,nil,13)
    --ui.setLabelString(self.infoItems.criticaldmg,nil,13)
    --ui.setLabelString(self.infoItems.potential,nil,13)
    --
    --scroll
    local breakconfig = gamedata.config.breakskill or {}
    local breakH = 100
    local breaknum = 0
    local breaklist = {}
    for i = 1,10 do
        if generalConfig["break"..i] and generalConfig["break"..i] > 0 then
            breaknum = breaknum + 1
            local param = 1
            if breakconfig[tostring(generalConfig["break"..i])] and breakconfig[tostring(generalConfig["break"..i])].desc_param and breakconfig[tostring(generalConfig["break"..i])].desc_param>0 then
                param = breakconfig[tostring(generalConfig["break"..i])].desc_param
            else
                param = 1
            end
            breakH = breakH + (50*param)
            table.insert(breaklist,{lv = i, id = generalConfig["break"..i], param = param})
        end
    end
    --
    local fixH = 480+80
    if self.islead and self.islead == 1 then
        if generalConfig.combskillid and generalConfig.combskillid > 0 then
            fixH = 780+80
        else
            fixH = 580+80
        end
    elseif self.data.general.combskill and self.data.general.combskill.cid then
        fixH = 480+80+(breaknum>0 and breakH or 0)
    else
        fixH = 280+80+(breaknum>0 and breakH or 0)
    end

    local relation = self.data.relation or {}
    --local maxnum = table.getTableLength(relation)
    local maxnum = 0
    for i = 1,18 do
        if generalConfig["cond"..i.."ids"] and generalConfig["cond"..i.."ids"]~="" then
            maxnum = i
        end
    end
    if maxnum > 18 then maxnum = 18 end
    self.infoItems.container:setContentSize(CCSize(923,200*maxnum+fixH))
    self.infoItems.scrollnode = tolua.cast(self.infoItems.scrollnode, "CCScrollView")
    self.infoItems.scrollnode:setTouchPriority(self.touchPriority)
    -- self.infoItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    self.yuanNode, self.yuanItems = CCBReaderLoad("general_new/g_general_info", nil, true, "g_general_info")
    -- self.yuanNode:setPosition(0,450)
    self.yuanNode:setPosition(0,200*maxnum+fixH)


    self.infoItems.container:addChild(self.yuanNode)
    self.infoItems.scrollnode:setContentOffsetInDuration(ccp(0,480-200*maxnum-fixH),0)
    -- self.infoItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)
    for i = 1,18 do
        self.yuanItems["yuanNode"..i]:setVisible(i<=maxnum)
    end

    --fixH
    if self.islead and self.islead == 1 then
        self.yuanItems.g_leadNode:setVisible(true)
        if generalConfig.combskillid and generalConfig.combskillid > 0 then
            self.yuanItems.g_leadNode:setPositionY(-480)
            self.yuanItems.g_yuanNode:setPositionY(-780)
        else
            self.yuanItems.g_leadNode:setPositionY(-280)
            self.yuanItems.g_yuanNode:setPositionY(-580)
        end
    elseif self.data.general.combskill and self.data.general.combskill.cid then
        self.yuanItems.g_leadNode:setVisible(false)
        self.yuanItems.g_breakNode:setPositionY(-480)
        self.yuanItems.g_yuanNode:setPositionY(-480-(breaknum > 0 and breakH or 0))
    else
        self.yuanItems.g_leadNode:setVisible(false)
        self.yuanItems.g_breakNode:setPositionY(-280)
        self.yuanItems.g_yuanNode:setPositionY(-280-(breaknum > 0 and breakH or 0))
    end

    --lead
    if self.islead and self.islead == 1 then
        local passive_skill = {}
        for k,v in pairs(gamedata.config.protagonist_grow) do
            if v.skill_ext and v.skill_ext > 0 then
                table.insert(passive_skill,{level = v.level, skill_ext = v.skill_ext})
            end
        end
        local sortfunc = function (a,b)
            return a["level"] < b["level"]
        end
        table.sort(passive_skill,sortfunc)
        local passiveconfig = gamedata.config.passive_skill
        for i = 1,4 do
            if passive_skill[i] then
                --self.yuanItems["g_leadskill"..i]:setString("进阶"..i.."次: "..passiveconfig[tostring(gamedata.config.protagonist_grow[tostring(i+1)].skill_ext)].desc)
                -- self.yuanItems["g_leadskill"..i]:setString("进阶"..passive_skill[i].level.."次: "..passiveconfig[tostring(passive_skill[i].skill_ext)].desc)
                self.yuanItems["g_leadskill"..i]:setString(gameConfig.strings:upnum(passive_skill[i].level,passiveconfig[tostring(passive_skill[i].skill_ext)].desc))
                if passive_skill[i].level <= GameScene.protagonist.level2 then
                    self.yuanItems["g_leadskill"..i]:setColor(ccc3(135,81,25))
                    self.yuanItems["y_leadskill_yes_"..i]:setVisible(true)
                    self.yuanItems["y_leadskill_no_"..i]:setVisible(false)
                else
                    self.yuanItems["g_leadskill"..i]:setColor(ccc3(169, 169, 169))
                    self.yuanItems["y_leadskill_yes_"..i]:setVisible(false)
                    self.yuanItems["y_leadskill_no_"..i]:setVisible(true)
                end
            else
                self.yuanItems["g_leadskill"..i]:setString("")
                self.yuanItems["y_leadskill_yes_"..i]:setVisible(false)
                self.yuanItems["y_leadskill_no_"..i]:setVisible(true)
            end
        end
    end

    --break
    if self.islead and self.islead == 1 then
        self.yuanItems.g_breakNode:setVisible(false)
    elseif breaknum > 0 then
        self.yuanItems.g_breakNode:setVisible(true)
        local nextnum = 1
        local nextindex = 1
        for i = 1,10 do
            if i < nextnum then
                self.yuanItems["g_breakskill"..i]:setString("")
                self.yuanItems["y_breakskill_yes_"..i]:setVisible(false)
                self.yuanItems["y_breakskill_no_"..i]:setVisible(false)
            elseif breaklist[nextindex] and breaklist[nextindex].id then
                --self.yuanItems["g_breakskill"..i]:setString(breakconfig[tostring(breaklist[nextindex].id)].name..": (+"..breaklist[nextindex].lv.."激活)"..(breakconfig[tostring(breaklist[nextindex].id)] and breakconfig[tostring(breaklist[nextindex].id)].desc or ""))
                self.yuanItems["g_breakskill"..i]:setString(gameConfig.strings:brealname(breakconfig[tostring(breaklist[nextindex].id)].name,breaklist[nextindex].lv,(breakconfig[tostring(breaklist[nextindex].id)]) and breakconfig[tostring(breaklist[nextindex].id)].desc or ""))
                self.yuanItems["g_breakskill"..i]:setColor((breaklist[nextindex].lv+0 <= self.data.general.level2+0) and ccc3(135,81,25) or ccc3(169, 169, 169))
                self.yuanItems["y_breakskill_yes_"..i]:setVisible(breaklist[nextindex].lv+0 <= self.data.general.level2+0)
                self.yuanItems["y_breakskill_no_"..i]:setVisible(breaklist[nextindex].lv+0 > self.data.general.level2+0)
                nextnum = nextnum + breaklist[nextindex].param
                nextindex = nextindex + 1
            else
                self.yuanItems["g_breakskill"..i]:setString("")
                self.yuanItems["y_breakskill_yes_"..i]:setVisible(false)
                self.yuanItems["y_breakskill_no_"..i]:setVisible(false)
            end
        end
    else
        self.yuanItems.g_breakNode:setVisible(false)
    end



    --skill
    if (self.islead and self.islead == 1) or generalConfig.quality > 1 then
        self.yuanItems.skillshowButton:setVisible(true)
        self.yuanItems.skillshowButton_1:setVisible(true)
    else
        self.yuanItems.skillshowButton:setVisible(false)
        self.yuanItems.skillshowButton_1:setVisible(false)
    end

    local skillconfig = gamedata.config.skill[tostring(self.data.general.skill.cid)]
    self.yuanItems.s_iscombskill:setVisible(false)
    if self.islead and self.islead == 1 then
        self.yuanItems.s_iscombskill_1:setVisible(false)
        self.yuanItems.s_skill_lv:setVisible(false)
        self.yuanItems.s_skill_lv_1:setVisible(false)
    else
        self.yuanItems.s_iscombskill_1:setVisible(true)
        self.yuanItems.s_skill_lv:setVisible(true)
        self.yuanItems.s_skill_lv_1:setVisible(true)
    end
    ui.setNewIcon(self.yuanItems,self.data.general.skill)
    self.yuanItems.s_skill_name:setString(skillconfig.name)
    self.yuanItems.s_skill_lv:setString("")--"LV:"..(self.data.general.skilllevel or 1))
    self.yuanItems.s_skill_desc:setString(skillconfig["skill-desc"] or "")
    ui.setLabelString(self.yuanItems.s_skill_lv,nil,14)

    if generalConfig.combskillid and generalConfig.combskillid > 0 then
        self.yuanItems.skillNode2:setVisible(true)
        ui.setNewIcon(self.yuanItems,self.data.general.combskill,1)
        local combskillconfig = gamedata.config.combskill[tostring(self.data.general.combskill.cid)]
        self.yuanItems.s_skill_name_1:setString(combskillconfig.name)
        self.yuanItems.s_skill_lv_1:setString("")--"LV:"..(self.data.general.combskilllevel or 0))
        self.yuanItems.s_skill_desc_1:setString(combskillconfig["skill-desc"] or "")
        ui.setLabelString(self.yuanItems.s_skill_lv_1,nil,14)
    else
        self.yuanItems.skillNode2:setVisible(false)
    end

    self.yuanItems.skilliconButton:addHandleOfControlEvent(function()
        self.skilltype = "skill"
        self:showPage("skillinfo")
    end, CCControlEventTouchUpInside)
    self.yuanItems.skilliconButton:setSwallowsTouch(true)
    self.yuanItems.skilliconButton:setTouchPriority(self.touchPriority)

    self.yuanItems.skilliconButton_1:addHandleOfControlEvent(function()
        if self.islead and self.islead == 1 then
            self.skilltype = "leadskill"
        else
            self.skilltype = "combskill"
        end
        self:showPage("skillinfo")
    end, CCControlEventTouchUpInside)
    self.yuanItems.skilliconButton_1:setSwallowsTouch(true)
    self.yuanItems.skilliconButton_1:setTouchPriority(self.touchPriority)

    self.yuanItems.skillshowButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        ui.skillView(self.data.general.skill.cid)
    end, CCControlEventTouchUpInside)
    self.yuanItems.skillshowButton:setSwallowsTouch(true)
    self.yuanItems.skillshowButton:setTouchPriority(self.touchPriority)

    self.yuanItems.skillshowButton_1:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.data.general.combskill and self.data.general.combskill.cid then
            ui.skillView(self.data.general.combskill.cid)
        end
    end, CCControlEventTouchUpInside)
    self.yuanItems.skillshowButton_1:setSwallowsTouch(true)
    self.yuanItems.skillshowButton_1:setTouchPriority(self.touchPriority)

    -- yuan
    for i = 1,maxnum do
        local key_Ex
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..i-1
        end

        self.yuanItems["y_name"..key_Ex]:setString(generalConfig["cond"..i.."name"]..":"..generalConfig["cond"..i.."desc"])

        local ids = ui.Split(generalConfig["cond"..i.."ids"],";") or {}
        for ii = 1,3 do
            if ids[ii] and ids[ii]~="" then
                self.yuanItems["y_node"..ii..key_Ex]:setVisible(true)
                ui.setNewIcon(self.yuanItems,{cid = ids[ii]},i*3+ii-2)
                --
                if self.yuanItems["y_iconbutton"..ii..(i>1 and ("_"..i-1) or "")] then
                    self.yuanItems["y_iconbutton"..ii..(i>1 and ("_"..i-1) or "")]:addHandleOfControlEvent(function()
                        ui.setPopwindowByCid(ids[ii])
                    end, CCControlEventTouchUpInside)
                    self.yuanItems["y_iconbutton"..ii..(i>1 and ("_"..i-1) or "")]:setSwallowsTouch(true)
                    self.yuanItems["y_iconbutton"..ii..(i>1 and ("_"..i-1) or "")]:setTouchPriority(self.touchPriority)
                end
                --
            else
                self.yuanItems["y_node"..ii..key_Ex]:setVisible(false)
            end
        end

        if relation[tostring(i)] and relation[tostring(i)].activate and relation[tostring(i)].activate >= 2 then
            self.yuanItems["y_activate_yes"..key_Ex]:setVisible(true)
            self.yuanItems["y_activate_no"..key_Ex]:setVisible(false)
        else
            self.yuanItems["y_activate_yes"..key_Ex]:setVisible(false)
            self.yuanItems["y_activate_no"..key_Ex]:setVisible(true)
        end

    end


    --
    if self.islead and self.islead == 1 then
        self.infoItems.doNode1:setVisible(false)
        self.infoItems.doNode3:setVisible(false)
    else
        self.infoItems.doNode1:setVisible(true)
        self.infoItems.doNode3:setVisible(true)
    end

    --
    if self.opt == 2 then
        self.infoItems.doNode1:setVisible(false)
        self.infoItems.doNode2:setVisible(false)
        self.infoItems.doNode3:setVisible(false)
    end
    --
    -- self.infoItems.doLab1:setString("升 级")
    -- self.infoItems.doLab2:setString("培 养")
    -- self.infoItems.doLab3:setString("突 破")
    self.infoItems.doLab1:setString(gameConfig.strings:string_common("generalInfo",1))
    self.infoItems.doLab2:setString(gameConfig.strings:string_common("generalInfo",2))
    self.infoItems.doLab3:setString(gameConfig.strings:string_common("generalInfo",3))
    ui.setLabelString(self.infoItems.doLab1,nil,19)
    ui.setLabelString(self.infoItems.doLab2,nil,19)
    ui.setLabelString(self.infoItems.doLab3,nil,19)

    self.infoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalInfo")
    end, CCControlEventTouchUpInside)
    self.infoItems.closeButton:setSwallowsTouch(true)
    self.infoItems.closeButton:setTouchPriority(self.touchPriority)

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
    self.infoItems.doButton1:addHandleOfControlEvent(function()
        if self.opt and self.opt == 3 then
            local cid = self.data.general.cid
            gameWindows:closeWindowDirect("generalInfo")
            local cheersid = self.sid or 1
            local callback = function(selectedData)
                for k,v in pairs(selectedData) do
                    UIRequest({type = 1004, pos1 = cheersid, iid = v.iid})
                    self.callback = nil
                    break
                end
            end
            gameWindows:openWindow("selectlist",{type = "changegeneral", param = cid},callback)
        elseif generalConfig.quality < 3 then
            runGamePrompt({msg = "绿色伙伴无法通过经验丹升级"})
        else
            if not GameScene:checkopenlevelbyId(135) then return end
            --self:showPage("inherit")
            GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "up",})
        end
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton1:setSwallowsTouch(true)
    self.infoItems.doButton1:setTouchPriority(self.touchPriority-1)

    if self.islead and self.islead == 1 then
        self.infoItems.doNode2:setPositionX(544)
        ui.removeGray("CCControlButton",self.infoItems.doButton2)
        ui.removeGray("CCLabelTTF",self.infoItems.doLab2)
        self.infoItems.doButton2:addHandleOfControlEvent(function()
            self.callback = nil
            gameWindows:closeWindow("generalInfo")
            GameScene:shiftLayer("lead","up")
        end, CCControlEventTouchUpInside)
    else
        self.infoItems.doNode2:setPositionX(244)
        if generalConfig.quality < 3 then
            ui.addGray("CCControlButton",self.infoItems.doButton2)
            ui.addGray("CCLabelTTF",self.infoItems.doLab2)
        else
            ui.removeGray("CCControlButton",self.infoItems.doButton2)
            ui.removeGray("CCLabelTTF",self.infoItems.doLab2)
        end
        self.infoItems.doButton2:addHandleOfControlEvent(function()
            --runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","gongneng2")})
            if not GameScene:checkopenlevelbyId(51) then return end
            if generalConfig.quality < 3 then
                runGamePrompt({msg = "绿色伙伴无法培养"})
            elseif self.data.general.level1<=1 then
                runGamePrompt({msg = "1级伙伴无法培养"})
            else
                --self:showPage("train")
                GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "train",})
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
            --local general = self.data.general
            --gameWindows:closeWindowDirect("generalInfo")
            --gameWindows:openWindow("generalUp",{general = general,selectpage = "tupo"})
            GameScene:shiftLayer("generalup","up",{cid = self.data.general.cid, page = "tupo",})
        end

        --self:showPage("up")
    end, CCControlEventTouchUpInside)
    self.infoItems.doButton3:setSwallowsTouch(true)
    self.infoItems.doButton3:setTouchPriority(self.touchPriority-1)


end

function generalInfo.setPage_up(self)
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local general_awake = gamedata.config.general_awake or {}

    self.generalUpItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalInfo")
    end, CCControlEventTouchUpInside)
    self.generalUpItems.closeButton:setSwallowsTouch(true)
    self.generalUpItems.closeButton:setTouchPriority(self.touchPriority)

    --
    -- self.generalUpItems.title:setString("伙伴突破")
    self.generalUpItems.title:setString(gameConfig.strings:string_common("generalInfo",5))

    local maxlv = table.getTableLength(general_awake) or 10

    self.generalUpItems["name"]:setString(generalConfig.name..(self.data.general.level2+0 > 0 and " +"..self.data.general.level2 or ""))
    self.generalUpItems["lv1"]:setString("LV:"..self.data.general.level1)
    ui.setLabelString(self.generalUpItems.lv1,nil,13)

    ui.setLabelString(self.generalUpItems["name"],nil,(generalConfig.quality or 1)*2-1)

    -- self.generalUpItems["type1"]:setString("属性")
    self.generalUpItems["type1"]:setString(gameConfig.strings:string_common("generalInfo",6))
    self.generalUpItems["node_type2"]:setVisible(false)

    if self.data.general.level2 == "0" or self.data.general.level2 == 0 then
        self.generalUpItems["num1"]:setString("x100%")
    else
        self.generalUpItems["num1"]:setString("x"..general_awake[tostring(self.data.general.level2)].promote+100.0 .. "%")
    end
    ui.setLabelString(self.generalUpItems.num1,nil,13)

    if self.data.general.level2+1 > maxlv then
        self.generalUpItems["next_num1"]:setString("x"..general_awake[tostring(maxlv)].promote+100.0 .. "%")
    else
        self.generalUpItems["next_num1"]:setString("x"..general_awake[tostring(self.data.general.level2+1)].promote+100.0 .. "%")
    end
    ui.setLabelString(self.generalUpItems.next_num1,nil,23)

    local xnum = 0
    if self.data.general.level2+1 > maxlv then
        xnum = 0
    else
        xnum = general_awake[tostring(self.data.general.level2+1)][tostring(generalConfig.quality).."piece"]
    end

    ui.setNewIcon(self.generalUpItems,{cid = self.data.general.cid},0)
    ui.setNewIconName(self.generalUpItems,{cid = self.data.general.cid, numdesc = "0".."/"..xnum},0)
    UIRequest({type = 10121, generalCid = self.data.general.cid, order =2})

    -- self.generalUpItems.doLab:setString("突 破")
    self.generalUpItems.doLab:setString(gameConfig.strings:string_common("generalInfo",3))
    ui.setLabelString(self.generalUpItems.doLab,nil,19)
    self.generalUpItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.data.general.level2+1 <= table.getTableLength(gamedata.config.general_awake) then
            local neednum = general_awake[tostring(self.data.general.level2+1)][tostring(generalConfig.quality).."piece"] or 0
            local num = self.fragment and self.fragment.num or 0
            if num+0 < neednum+0 then
                -- runGamePrompt({msg = "魂魄数量不够"})
                 runGamePrompt({msg = gameConfig.strings:string_common("generalInfo",7)})
            else
                UIRequest({type = 1017, ids = {self.data.general.cid}})
            end
        else
            -- runGamePrompt({msg = "已突破到最高次数"})
            runGamePrompt({msg = gameConfig.strings:string_common("generalInfo",8)})
        end
    end, CCControlEventTouchUpInside)
    self.generalUpItems.doButton:setSwallowsTouch(true)
    self.generalUpItems.doButton:setTouchPriority(self.touchPriority)

    --
    self.generalUpItems.in_button:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(self.data.general.cid)
    end, CCControlEventTouchUpInside)
    self.generalUpItems.in_button:setSwallowsTouch(true)
    self.generalUpItems.in_button:setTouchPriority(self.touchPriority)
    --
    --effect
    if self.hasup and self.hasup == 1 then
        self.hasup = 0
        --
        self.generalUpItems.bgEffectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode1,qianghuaItems1 = CCBReaderLoad("UIEffect/qianghua/luzi_effect", nil, true, "luzieffect")
        qianghuaNode1:setPosition(0,0)
        self.generalUpItems.bgEffectNode:addChild(qianghuaNode1)
        self.generalUpItems.bgEffectNode:setScale(1)
        local animationManager1 = getAnimationManager(qianghuaItems1)
        animationManager1:setAnimationCompletedCallback(function()
            self.generalUpItems.bgEffectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager1:runAnimationsForSequenceNamed("luzieffect")
        --
        self.generalUpItems.effectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/tunshitupo/huobantupo", nil, true, "huobantupo")
        qianghuaNode:setPosition(0,0)
        self.generalUpItems.effectNode:addChild(qianghuaNode)
        self.generalUpItems.effectNode:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:setAnimationCompletedCallback(function()
            self.generalUpItems.effectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("huobantupo")
        gamedata.music:PlayOptSound("xlshjhtp")
    end
end

function generalInfo.setFragmentData(self,data)

    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]
    local general_awake = gamedata.config.general_awake or {}
    local fragmentcid = self.data.general.cid
    for k,v in pairs(gamedata.config.general_fragment) do
       if v.general == self.data.general.cid then fragmentcid = v.id end
    end
    self.fragment = data or {}
    ui.setNewIconName(self.generalUpItems,{cid = fragmentcid, numdesc = (self.fragment.num or "0").."/"..(general_awake[tostring(self.data.general.level2+1)] and general_awake[tostring(self.data.general.level2+1)][tostring(generalConfig.quality).."piece"] or 0)},0)
end


function generalInfo.setPage_inherit(self)
    self.fdata = nil
    if not self.fdata then
        ui.addGray("CCControlButton",self.inheritItems.doButton)
        ui.addGray("CCLabelTTF",self.inheritItems.doLab)
    else
        ui.removeGray("CCControlButton",self.inheritItems.doButton)
        ui.removeGray("CCLabelTTF",self.inheritItems.doLab)
    end
    self.inheritItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalInfo")
    end, CCControlEventTouchUpInside)
    self.inheritItems.closeButton:setSwallowsTouch(true)
    self.inheritItems.closeButton:setTouchPriority(self.touchPriority)

    --
    -- self.inheritItems.title:setString("伙伴传功")
    -- self.inheritItems.doLab:setString("传 功")
    self.inheritItems.title:setString(gameConfig.strings:string_common("generalInfo",9))
    self.inheritItems.doLab:setString(gameConfig.strings:string_common("generalInfo",1))
    ui.setLabelString(self.inheritItems.doLab,nil,19)
    --
    ui.setNewIcon(self.inheritItems,{cid = 20011},0)
    ui.setNewIcon(self.inheritItems,{cid = 20012},1)
    --
    self.inheritItems.i_button:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(20011)
    end, CCControlEventTouchUpInside)
    self.inheritItems.i_button:setSwallowsTouch(true)
    self.inheritItems.i_button:setTouchPriority(self.touchPriority)

    self.inheritItems.i_button_1:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(20012)
    end, CCControlEventTouchUpInside)
    self.inheritItems.i_button_1:setSwallowsTouch(true)
    self.inheritItems.i_button_1:setTouchPriority(self.touchPriority)
    --
    if self.inheritSelect == 2 then
        self.inheritItems.isselect_normal:setVisible(false)
        self.inheritItems.isselect_special:setVisible(true)
    else
        self.inheritItems.isselect_normal:setVisible(true)
        self.inheritItems.isselect_special:setVisible(false)
    end

    self.inheritItems.selectButton_normal:addHandleOfControlEvent(function()
        self.inheritSelect = 1
        self.inheritItems.isselect_normal:setVisible(true)
        self.inheritItems.isselect_special:setVisible(false)
    end, CCControlEventTouchUpInside)
    self.inheritItems.selectButton_normal:setSwallowsTouch(true)
    self.inheritItems.selectButton_normal:setTouchPriority(self.touchPriority)

    self.inheritItems.selectButton_special:addHandleOfControlEvent(function()
        self.inheritSelect = 2
        self.inheritItems.isselect_normal:setVisible(false)
        self.inheritItems.isselect_special:setVisible(true)
    end, CCControlEventTouchUpInside)
    self.inheritItems.selectButton_special:setSwallowsTouch(true)
    self.inheritItems.selectButton_special:setTouchPriority(self.touchPriority)

    --
    self.inheritItems.noSelected:setVisible(true)
    self.inheritItems.isSelected:setVisible(false)
    self:setInheritGeneralNode(self.data.general,"")
    self:setInheritSelectNode()
    self:setInheritOriginGeneral(self.data.general)
    --

    self.inheritItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)

        if not self.fdata then
            -- runGamePrompt({msg = "请选择伙伴"})
            runGamePrompt({msg = gameConfig.strings:string_common("generalInfo",10)})
        elseif self.inheritpropnum[self.inheritSelect == 2 and "20012" or "20011"] < 1 then
            shortPropById(self.inheritSelect == 2 and 20012 or 20011,1,{type = 12001,cids = {20011,20012}, order = 10102})
            --runGamePrompt({msg = ui.IDconfig(self.inheritSelect == 2 and 20012 or 20011).name.."不足"})
        else
            --
            self.inheritItems.effectNode:removeAllChildrenWithCleanup(true)
            local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/chuangong/chuangong", nil, true, "chuangong")
            qianghuaNode:setPosition(0,0)
            self.inheritItems.effectNode:addChild(qianghuaNode)
            self.inheritItems.effectNode:setScale(1)
            local animationManager = getAnimationManager(qianghuaItems)
            animationManager:setAnimationCompletedCallback(function()
                self.inheritItems.effectNode:removeAllChildrenWithCleanup(true)
                UIRequest({type = 1011, tid = self.inheritSelect, opt=1, generaliid = self.data.general.iid})
            end)
            animationManager:runAnimationsForSequenceNamed("chuangong")
            gamedata.music:PlayOptSound("cg")
        end

    end, CCControlEventTouchUpInside)
    self.inheritItems.doButton:setSwallowsTouch(true)
    self.inheritItems.doButton:setTouchPriority(self.touchPriority)

    UIRequest({type = 12001,cids = {20011,20012}, order = 10102})

    --
    --effect
    if self.hasup and self.hasup == 1 then
        self.hasup = 0
    end
end

function generalInfo.setInheritGeneralNode(self,data,type)
    local configdata = gamedata.config.general[tostring(data.cid)] or {}
    self.inheritItems["name"..type]:setString(configdata.name..(data.level2+0 > 0 and " +"..data.level2 or ""))
    self.inheritItems["lv1"..type]:setString(data.level1 or " ")
    ui.setLabelString(self.inheritItems["name"..type],nil,(configdata.quality or 1)*2-1)
    ui.setLabelString(self.inheritItems["lv1"..type],nil,13)

    self.inheritItems["generalNode"..type]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(data.cid)].animationid)].name
    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.5)
    Gneral:setPosition(self.inheritItems["generalNode"..type]:getContentSize().width/2,20)
    self.inheritItems["generalNode"..type]:addChild(Gneral)
end


function generalInfo.setInheritPropNum(self,pdata)
    self.inheritpropnum = pdata or {}
    self.inheritItems.numdesc_normal:setString((self.inheritpropnum["20011"] or 0).."/1")
    self.inheritItems.numdesc_special:setString((self.inheritpropnum["20012"] or 0).."/1")
    ui.setLabelString(self.inheritItems.numdesc_normal,nil,13)
    ui.setLabelString(self.inheritItems.numdesc_special,nil,13)

end

function generalInfo.setInheritSelectNode(self,datatable)
    if datatable then
        self.inheritItems["isSelected"]:setVisible(true)
        self.inheritItems["noSelected"]:setVisible(false)

        self:setInheritGeneralNode(datatable,"_selected")
    else
        self.inheritItems["isSelected"]:setVisible(false)
        self.inheritItems["noSelected"]:setVisible(true)
    end
    self.inheritItems.selectButton:addHandleOfControlEvent(function()
        local callback = function(selectedData)
            for k,v in pairs(selectedData) do
                self.fdata = v
                self:setInheritSelectNode(self.fdata)
                UIRequest({type = 1010, fid = v.iid, tid = self.data.general.iid,method = 1 })
                break
            end
            if not self.fdata then
                ui.addGray("CCControlButton",self.inheritItems.doButton)
                ui.addGray("CCLabelTTF",self.inheritItems.doLab)
            else
                ui.removeGray("CCControlButton",self.inheritItems.doButton)
                ui.removeGray("CCLabelTTF",self.inheritItems.doLab)
            end
        end
        gameWindows:openWindow("selectlist",{type = "inherit_selectgeneral", param = self.data.general.iid},callback)
    end, CCControlEventTouchUpInside)
    self.inheritItems.selectButton:setSwallowsTouch(true)
    self.inheritItems.selectButton:setTouchPriority(self.touchPriority)
end

function generalInfo.setInheritOriginGeneral(self,data)
    local OriginData = {
        exp = 0,
        level = data.level1,
        skilllevel = data.skilllevel,
        num = 0,
    }
    self:setInheritPreview(OriginData,"normal")
    self:setInheritPreview(OriginData,"special")

end

function generalInfo.setInheritPreview(self,data,type)
    self.inheritItems[type.."Exp"]:setString(data.exp)
    self.inheritItems[type.."Level"]:setString(data.level)
    self.inheritItems[type.."SkillLevel"]:setString(data.skilllevel)
    self.inheritItems[type.."PropNum"]:setString(data.num)
    ui.setLabelString(self.inheritItems[type.."Exp"],nil,22)
    ui.setLabelString(self.inheritItems[type.."Level"],nil,22)
    ui.setLabelString(self.inheritItems[type.."SkillLevel"],nil,22)
    ui.setLabelString(self.inheritItems[type.."PropNum"],nil,22)
end

--
function generalInfo.setPage_train(self,olddata)

    self.trainItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalInfo")
    end, CCControlEventTouchUpInside)
    self.trainItems.closeButton:setSwallowsTouch(true)
    self.trainItems.closeButton:setTouchPriority(self.touchPriority)

    --
    -- self.trainItems.title:setString("伙伴培养")
    self.trainItems.title:setString(gameConfig.strings:string_common("generalInfo",11))
    local generalConfig = gamedata.config.general[tostring(self.data.general.cid)]

    self.trainItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(generalConfig.animationid)].name
    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(1.5)
    Gneral:setScaleX(-1.5)
    Gneral:setPosition(0,0)
    self.trainItems["generalNode"]:addChild(Gneral)

    for k,v in ipairs({"atk","defense","hp"}) do
        local oldnum = olddata and olddata[v] or 0
        if oldnum ~=0 and self.data.general[v] ~= oldnum then
            local eccb,eitem = CCBReaderLoad("UIEffect/up_down/"..(self.data.general[v] > oldnum and "up" or "down"), nil, true, "up_down")
            self.trainItems[v.."effect"]:addChild(eccb)
            local animationManager = getAnimationManager(eitem)
            animationManager:setAnimationCompletedCallback(function()
                self.trainItems[v.."effect"]:removeAllChildrenWithCleanup(true)
            end)
            animationManager:runAnimationsForSequenceNamed(self.data.general[v] > oldnum and "up" or "down")
        end
    end


    self.trainItems.atk:setString(self.data.general.atk)
    self.trainItems.hp:setString(self.data.general.hp)
    self.trainItems.defense:setString(self.data.general.defense)
    self.trainItems.speed:setString(self.data.general.speed)
    self.trainItems.name:setString(generalConfig.name..(self.data.general.level2+0 > 0 and " +"..self.data.general.level2 or ""))
    self.trainItems.lv1:setString(self.data.general.level1)
    self.trainItems.num1:setString(self.data.general.potential or 0)

    if not gameConfig.images[generalConfig.actor] then
        setSpriteFrameByName(self.trainItems["generaltype"], gameConfig.images.alpha)
    else
        setSpriteFrameByName(self.trainItems["generaltype"], gameConfig.images[generalConfig.actor])
    end

    if self.islead and self.islead == 1 then
        self.trainItems.name:setString(GameScene.roleinfo.name or "")
    end

    ui.setLabelString(self.trainItems.name,nil,(generalConfig.quality or 1)*2-1)
    ui.setLabelString(self.trainItems.lv1,nil,14)
    ui.setLabelString(self.trainItems.atk,nil,14)
    ui.setLabelString(self.trainItems.hp,nil,14)
    ui.setLabelString(self.trainItems.defense,nil,14)
    ui.setLabelString(self.trainItems.speed,nil,14)
    ui.setLabelString(self.trainItems.num1,nil,13)
    --
    for i = 1,5 do
        self.trainItems["up_num"..i]:setString("")
        ui.setLabelString(self.trainItems["up_num"..i],nil,14)
    end
    --
    ui.setNewIconName(self.trainItems,{cid = 20009, num = 1},0)
    ui.setNewIconName(self.trainItems,{cid = 20009, num = 1},1)
    --
    self.trainItems.in_button:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(20009)
    end, CCControlEventTouchUpInside)
    self.trainItems.in_button:setSwallowsTouch(true)
    self.trainItems.in_button:setTouchPriority(self.touchPriority)

    self.trainItems.in_button_1:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(20009)
    end, CCControlEventTouchUpInside)
    self.trainItems.in_button_1:setSwallowsTouch(true)
    self.trainItems.in_button_1:setTouchPriority(self.touchPriority)
    --
    if self.trainSelect == 2 then
        self.trainItems.isselect_normal:setVisible(false)
        self.trainItems.isselect_special:setVisible(true)
    else
        self.trainItems.isselect_normal:setVisible(true)
        self.trainItems.isselect_special:setVisible(false)
    end

    self.trainItems.selectButton_normal:addHandleOfControlEvent(function()
        self.trainSelect = 1
        self.trainItems.isselect_normal:setVisible(true)
        self.trainItems.isselect_special:setVisible(false)
    end, CCControlEventTouchUpInside)
    self.trainItems.selectButton_normal:setSwallowsTouch(true)
    self.trainItems.selectButton_normal:setTouchPriority(self.touchPriority)

    self.trainItems.selectButton_special:addHandleOfControlEvent(function()
        self.trainSelect = 2
        self.trainItems.isselect_normal:setVisible(false)
        self.trainItems.isselect_special:setVisible(true)
    end, CCControlEventTouchUpInside)
    self.trainItems.selectButton_special:setSwallowsTouch(true)
    self.trainItems.selectButton_special:setTouchPriority(self.touchPriority)
    --
    UIRequest({type = 12001, order = 10101, cids = {20009}})

    self.trainResuit = false
    if self.trainResuit then
        -- self.trainItems.doLab1:setString("取 消")
        self.trainItems.doLab1:setString(gameConfig.strings:string_common("generalInfo",12))
        ui.setLabelString(self.trainItems.doLab1,nil,19)
        self.trainItems.doButton1:addHandleOfControlEvent(function()
            UIRequest({type = 1014, opt = 0 })
        end, CCControlEventTouchUpInside)
        self.trainItems.doButton1:setSwallowsTouch(true)
        self.trainItems.doButton1:setTouchPriority(self.touchPriority)
        --
        -- self.trainItems.doLab2:setString("确 定")
        self.trainItems.doLab2:setString(gameConfig.strings:string_common("generalInfo",13))
        ui.setLabelString(self.trainItems.doLab2,nil,19)
        self.trainItems.doButton2:addHandleOfControlEvent(function()
            UIRequest({type = 1014, opt = 1 })
        end, CCControlEventTouchUpInside)
        self.trainItems.doButton2:setSwallowsTouch(true)
        self.trainItems.doButton2:setTouchPriority(self.touchPriority)
    else
        -- self.trainItems.doLab1:setString("培养一次")
        self.trainItems.doLab1:setString(gameConfig.strings:string_common("generalInfo",14))
        ui.setLabelString(self.trainItems.doLab1,nil,19)
        self.trainItems.doButton1:addHandleOfControlEvent(function()
            UIRequest({type = 1013, id = self.data.general.iid, method = ((self.trainSelect == 2) and 3 or 1), extGeneralData = self.data.general})
        end, CCControlEventTouchUpInside)
        self.trainItems.doButton1:setSwallowsTouch(true)
        self.trainItems.doButton1:setTouchPriority(self.touchPriority)

        -- self.trainItems.doLab2:setString("培养十次")
        self.trainItems.doLab2:setString(gameConfig.strings:string_common("generalInfo",15))
        ui.setLabelString(self.trainItems.doLab2,nil,19)
        self.trainItems.doButton2:addHandleOfControlEvent(function()
            UIRequest({type = 1013, id = self.data.general.iid, method = ((self.trainSelect == 2) and 4 or 2), extGeneralData = self.data.general})
        end, CCControlEventTouchUpInside)
        self.trainItems.doButton2:setSwallowsTouch(true)
        self.trainItems.doButton2:setTouchPriority(self.touchPriority)
    end
end


function generalInfo.setTrainPropNum(self,pdata)
    self.trainpropnum = pdata["20009"] or 0
    self.trainItems.num2:setString(self.trainpropnum)
    ui.setLabelString(self.trainItems.num2,nil,13)
end

function generalInfo.setTrainResuit(self,datas)
    self.trainResuit = true

    local dataTable = datas.extGeneralData
    local newData =  datas.previewGeneralData

    local up_num1 = newData.atk - dataTable.atk
    local up_num2 = newData.defense - dataTable.defense
    local up_num3 = newData.hp - dataTable.hp
    local up_num4 = newData.potential - dataTable.potential

    self.trainItems.up_num5:setString("-"..datas.prop or 0)
    self.trainItems.up_num5:setColor(ccc3(255,8,8))
    ui.setLabelString(self.trainItems.up_num5,nil,24)

    if up_num1 < 0 then
        self.trainItems.up_num1:setString("- "..0-up_num1)
        self.trainItems.up_num1:setColor(ccc3(255,8,8))
        ui.setLabelString(self.trainItems.up_num1,nil,24)
    elseif up_num1 > 0 then
        self.trainItems.up_num1:setString("+ "..up_num1)
        self.trainItems.up_num1:setColor(ccc3(78,162,52))
        ui.setLabelString(self.trainItems.up_num1,nil,23)
    else
        self.trainItems.up_num1:setString(" ")
        self.trainItems.up_num1:setColor(ccc3(78,162,52))
        ui.setLabelString(self.trainItems.up_num1,nil,23)
    end

    if up_num2 < 0 then
        self.trainItems.up_num2:setString("- "..0-up_num2)
        self.trainItems.up_num2:setColor(ccc3(255,8,8))
        ui.setLabelString(self.trainItems.up_num2,nil,24)
    elseif up_num2 > 0 then
        self.trainItems.up_num2:setString("+ "..up_num2)
        self.trainItems.up_num2:setColor(ccc3(78,162,52))
        ui.setLabelString(self.trainItems.up_num2,nil,23)
    else
        self.trainItems.up_num2:setString(" ")
        self.trainItems.up_num2:setColor(ccc3(78,162,52))
        ui.setLabelString(self.trainItems.up_num2,nil,23)
    end

    if up_num3 < 0 then
        self.trainItems.up_num3:setString("- "..0-up_num3)
        self.trainItems.up_num3:setColor(ccc3(255,8,8))
        ui.setLabelString(self.trainItems.up_num3,nil,24)
    elseif up_num3 > 0 then
        self.trainItems.up_num3:setString("+ "..up_num3)
        self.trainItems.up_num3:setColor(ccc3(78,162,52))
        ui.setLabelString(self.trainItems.up_num3,nil,23)
    else
        self.trainItems.up_num3:setString(" ")
        self.trainItems.up_num3:setColor(ccc3(78,162,52))
        ui.setLabelString(self.trainItems.up_num3,nil,23)
    end

    if up_num4 < 0 then
        self.trainItems.up_num4:setString("-"..0-up_num4)
        self.trainItems.up_num4:setColor(ccc3(255,8,8))
        ui.setLabelString(self.trainItems.up_num4,nil,24)
    elseif up_num4 > 0 then
        self.trainItems.up_num4:setString("+"..up_num4)
        self.trainItems.up_num4:setColor(ccc3(78,162,52))
        ui.setLabelString(self.trainItems.up_num4,nil,23)
    else
        self.trainItems.up_num4:setString(" ")
        self.trainItems.up_num4:setColor(ccc3(78,162,52))
        ui.setLabelString(self.trainItems.up_num4,nil,23)
    end

    if self.trainResuit then
        -- self.trainItems.doLab1:setString("取 消")
        self.trainItems.doLab1:setString(gameConfig.strings:string_common("generalInfo",12))
        ui.setLabelString(self.trainItems.doLab1,nil,19)
        self.trainItems.doButton1:addHandleOfControlEvent(function()
            UIRequest({type = 1014, opt = 0 })
        end, CCControlEventTouchUpInside)
        self.trainItems.doButton1:setSwallowsTouch(true)
        self.trainItems.doButton1:setTouchPriority(self.touchPriority)
        --
        -- self.trainItems.doLab2:setString("确 定")
         self.trainItems.doLab2:setString(gameConfig.strings:string_common("generalInfo",13))
        ui.setLabelString(self.trainItems.doLab2,nil,19)
        self.trainItems.doButton2:addHandleOfControlEvent(function()
            UIRequest({type = 1014, opt = 1 })
        end, CCControlEventTouchUpInside)
        self.trainItems.doButton2:setSwallowsTouch(true)
        self.trainItems.doButton2:setTouchPriority(self.touchPriority)
    else
        -- self.trainItems.doLab1:setString("培养一次")
        self.trainItems.doLab1:setString(gameConfig.strings:string_common("generalInfo",14))
        ui.setLabelString(self.trainItems.doLab1,nil,19)
        self.trainItems.doButton1:addHandleOfControlEvent(function()
            UIRequest({type = 1013, id = self.data.general.iid, method = ((self.trainSelect == 2) and 3 or 1), extGeneralData = self.data.general})
        end, CCControlEventTouchUpInside)
        self.trainItems.doButton1:setSwallowsTouch(true)
        self.trainItems.doButton1:setTouchPriority(self.touchPriority)

        -- self.trainItems.doLab2:setString("培养十次")
        self.trainItems.doLab2:setString(gameConfig.strings:string_common("generalInfo",15))
        ui.setLabelString(self.trainItems.doLab2,nil,19)
        self.trainItems.doButton2:addHandleOfControlEvent(function()
            UIRequest({type = 1013, id = self.data.general.iid, method = ((self.trainSelect == 2) and 4 or 2), extGeneralData = self.data.general})
        end, CCControlEventTouchUpInside)
        self.trainItems.doButton2:setSwallowsTouch(true)
        self.trainItems.doButton2:setTouchPriority(self.touchPriority)
    end
    gamedata.music:PlayOptSound("py")
end

function generalInfo.setPage_skillinfo(self)
    self.fragmentConfig = gamedata.config.general_fragment
    self.skillInfoItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalInfo")
    end, CCControlEventTouchUpInside)
    self.skillInfoItems.closeButton:setSwallowsTouch(true)
    self.skillInfoItems.closeButton:setTouchPriority(self.touchPriority)
    --
    self.skillInfoItems.doButton:addHandleOfControlEvent(function()
        --self:showPage("skillup")
        self.callback = nil
        gameWindows:closeWindow("generalInfo")
    end, CCControlEventTouchUpInside)
    self.skillInfoItems.doButton:setSwallowsTouch(true)
    self.skillInfoItems.doButton:setTouchPriority(self.touchPriority)
    --
    self.skillInfoItems.title:setString("技能详情")
    self.skillInfoItems.doLab:setString("确 定")
    ui.setLabelString(self.skillInfoItems.doLab,nil,19)
    --
    if self.skilltype == "combskill" then
        self.skillInfoItems.s_iscombskill:setVisible(true)
    else
        self.skillInfoItems.s_iscombskill:setVisible(false)
    end

    if self.islead and self.islead == 1 then
        --self.skillInfoItems.doNode:setVisible(false)
        self.skillInfoItems.s_skill_lv:setVisible(false)
    elseif self.skilltype == "skill" then
        --self.skillInfoItems.doNode:setVisible(true)
    else
        --self.skillInfoItems.doNode:setVisible(false)
    end
    --
    if self.opt == 2 then
        --self.skillInfoItems.doNode:setVisible(false)
    end
    --
    local skill_str = "skill"
    if self.skilltype == "combskill" or self.skilltype == "leadskill" then
        skill_str = "combskill"
    end

    local skillconfig = gamedata.config[skill_str][tostring(self.data.general[skill_str].cid)]

    ui.setNewIcon(self.skillInfoItems,self.data.general[skill_str])
    self.skillInfoItems.s_skill_name:setString(skillconfig.name)
    self.skillInfoItems.s_skill_lv:setString("")--"LV:"..(self.data.general[skill_str.."level"] or 1))
    self.skillInfoItems.s_skill_desc:setString(skillconfig.desc)
    ui.setLabelString(self.skillInfoItems.s_skill_lv,nil,14)
    --
    self.skillInfoItems["xiaoguo"]:setString(skillconfig["effect-desc"] or "")
    --[[
    if skillconfig.trigger <= 0.15  then
        -- self.skillInfoItems["jilv"]:setString("低")
         self.skillInfoItems["jilv"]:setString(gameConfig.strings:string_common("generalInfo",18))
    elseif  skillconfig.trigger >= 0.25  then
        -- self.skillInfoItems["jilv"]:setString("高")
        self.skillInfoItems["jilv"]:setString(gameConfig.strings:string_common("generalInfo",19))
    else
        -- self.skillInfoItems["jilv"]:setString("中")
        self.skillInfoItems["jilv"]:setString(gameConfig.strings:string_common("generalInfo",20))
    end

    --攻击力
    local slv = 1
    if self.skilltype == "combskill" then
        slv = self.data.general["combskilllevel"] or 0
    else
        slv = self.data.general["skilllevel"] or 1
        slv = slv-1
    end
    local atk = " "
    local atkparam = skillconfig["atk-param"]

    local i_atk = string.find(atkparam, ";",1)
    if i_atk then
        local atk1 =  string.sub(atkparam,1,i_atk-1)
        local atkup =  string.sub(atkparam,i_atk+1,string.len(atkparam))
        if self.islead and self.islead == 1 then
            -- atk = tostring(atk1*100) .. "%攻击力"
            atk = gameConfig.strings:addAtk(tostring(atk1*100))
        else
            -- atk = tostring((atk1*100)+(slv)*(atkup*100)) .. "%攻击力"
            atk = gameConfig.strings:addAtk(tostring((atk1*100)+(slv)*(atkup*100)))
        end
    end

    self.skillInfoItems["shanghai"]:setString(atk)
    self.skillInfoItems["xiaoguo"]:setString(skillconfig["effect-desc"] or "")
    self.skillInfoItems["fanwei"]:setString(gameConfig.strings.skill_Range[skillconfig.range])
    if skillconfig.range == "random" then
        self.skillInfoItems["fanwei"]:setString(gameConfig.strings.skill_Range[skillconfig.range]..skillconfig["randnum"].."个")
    end
    ]]
    --
    if self.skilltype == "combskill" then
        local config1 = gamedata.config.general[tostring(skillconfig.cid1)]
        local config2 = gamedata.config.general[tostring(skillconfig.cid2)]

    -- self.infoItems.getBtn:addHandleOfControlEvent(function()
    --     self.callback = nil
    --     print("getBtn..is")
    --     gameWindows:openWindow("dropTips",{cid = self.data.general.cid},nil)
    -- end, CCControlEventTouchUpInside)
    -- self.infoItems.getBtn:setSwallowsTouch(true)
    -- self.infoItems.getBtn:setTouchPriority(self.touchPriority)

        ui.setNewIconName(self.skillInfoItems,{cid = config1.generalid})
        ui.setNewIconName(self.skillInfoItems,{cid = config2.generalid},1)

        self.skillInfoItems.i_button_1:addHandleOfControlEvent(function()
            print("skillInfoItems.i_button_1..is")
            gameWindows:openWindow("dropTips",{cid = self:getFragmentID(self.fragmentConfig,config1.generalid)},nil)
        end, CCControlEventTouchUpInside)
        self.skillInfoItems.i_button_1:setSwallowsTouch(true)
        self.skillInfoItems.i_button_1:setTouchPriority(self.touchPriority)
        self.skillInfoItems.i_button_2:addHandleOfControlEvent(function()
            print("getBtn.i_button_2..is")
            gameWindows:openWindow("dropTips",{cid = self:getFragmentID(self.fragmentConfig,config2.generalid)},nil)
        end, CCControlEventTouchUpInside)
        self.skillInfoItems.i_button_2:setSwallowsTouch(true)
        self.skillInfoItems.i_button_2:setTouchPriority(self.touchPriority)


        if skillconfig.cid3 and skillconfig.cid3>0 then
            self.skillInfoItems.combNode3:setVisible(true)
            local config3 = gamedata.config.general[tostring(skillconfig.cid3)]
            ui.setNewIconName(self.skillInfoItems,{cid = config3.generalid},2)
            self.skillInfoItems.i_button_3:addHandleOfControlEvent(function()
                print("getBtn.i_button_3..is")
                gameWindows:openWindow("dropTips",{cid = self:getFragmentID(self.fragmentConfig,config3.generalid)},nil)
            end, CCControlEventTouchUpInside)
            self.skillInfoItems.i_button_3:setSwallowsTouch(true)
            self.skillInfoItems.i_button_3:setTouchPriority(self.touchPriority)
        else
            self.skillInfoItems.combNode3:setVisible(false)
        end
    end

    if (self.islead and self.islead == 1) or gamedata.config.general[tostring(self.data.general.cid)].quality > 1 then
        self.skillInfoItems.skillshowButton:setVisible(true)
    else
        self.skillInfoItems.skillshowButton:setVisible(false)
    end
    self.skillInfoItems.skillshowButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if self.skilltype == "combskill" or self.skilltype == "leadskill" then
            ui.skillView(self.data.general.combskill.cid)
        else
            ui.skillView(self.data.general.skill.cid)
        end
    end, CCControlEventTouchUpInside)
    self.skillInfoItems.skillshowButton:setSwallowsTouch(true)
    self.skillInfoItems.skillshowButton:setTouchPriority(self.touchPriority)
end
--通过英雄id 获得 碎片id
function generalInfo.getFragmentID( self,aiFragmenCongfig,aiHeroID )
    local id = aiFragmenCongfig[tostring(aiHeroID + 1000)] and aiFragmenCongfig[tostring(aiHeroID + 1000)].general or 0
    if id ==   aiHeroID then
        return aiFragmenCongfig[tostring(aiHeroID + 1000)].id
    end
    for k,v in paris( aiFragmenCongfig) do
        if v.general == aiHeroID then
            return v.id
        end
    end
end

function generalInfo.setPage_skillup(self)
    printT(self.data)
    local skillconfig = gamedata.config["skill"][tostring(self.data.general["skill"].cid)]

    self.skillUpItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("generalInfo")
    end, CCControlEventTouchUpInside)
    self.skillUpItems.closeButton:setSwallowsTouch(true)
    self.skillUpItems.closeButton:setTouchPriority(self.touchPriority)

    --
    -- self.skillUpItems.title:setString("技能修炼")
    self.skillUpItems.title:setString(gameConfig.strings:string_common("generalInfo",21))

    local maxlv = table.getTableLength(gamedata.config.skill_level) or 10

    self.skillUpItems["name"]:setString(skillconfig.name)
    self.skillUpItems["lv1"]:setString("LV:"..self.data.general.skilllevel)
    ui.setLabelString(self.skillUpItems.lv1,nil,13)

    ui.setLabelString(self.skillUpItems["name"],nil,(skillconfig.quality or 1)*2-1)

    -- self.skillUpItems["type1"]:setString("伤害")
    self.skillUpItems["type1"]:setString(gameConfig.strings:string_common("generalInfo",22))
    self.skillUpItems["node_type2"]:setVisible(false)

    local atk = " "
    local nextatk = " "
    local atkparam = skillconfig["atk-param"]
    local i_atk = string.find(atkparam, ";",1)
    if i_atk then
        local atk1 =  string.sub(atkparam,1,i_atk-1)
        local atkup =  string.sub(atkparam,i_atk+1,string.len(atkparam))
        atk = tostring((atk1*100)+(self.data.general.skilllevel-1)*(atkup*100)) .. "%"
        nextatk = tostring((atk1*100)+(self.data.general.skilllevel)*(atkup*100)) .. "%"
    end

    self.skillUpItems["num1"]:setString(atk)
    ui.setLabelString(self.skillUpItems.num1,nil,13)

    if self.data.general.skilllevel+1 > maxlv then
        self.skillUpItems["next_num1"]:setString(atk)
    else
        self.skillUpItems["next_num1"]:setString(nextatk)
    end
    ui.setLabelString(self.skillUpItems.next_num1,nil,23)

    self.skillxnum = 0
    if self.data.general.skilllevel+1 > maxlv then
        self.skillxnum = 0
    else
        self.skillxnum = gamedata.config.skill_level[tostring(self.data.general.skilllevel)][skillconfig.quality.."coin"] or 0
    end

    ui.setNewIcon(self.skillUpItems,{cid = self.data.general["skill"].cid},0)
    ui.setNewIconName(self.skillUpItems,{cid = 20046, numdesc = "0".."/"..self.skillxnum},0)
    UIRequest({type = 12001, order = 10001, cids = {20046}})

    --
    self.skillUpItems.in_button:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(20046)
    end, CCControlEventTouchUpInside)
    self.skillUpItems.in_button:setSwallowsTouch(true)
    self.skillUpItems.in_button:setTouchPriority(self.touchPriority)
    --

    -- self.skillUpItems.doLab:setString("修 炼")
    self.skillUpItems.doLab:setString(gameConfig.strings:string_common("generalInfo",17))
    ui.setLabelString(self.skillUpItems.doLab,nil,19)
    self.skillUpItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)

        if self.data.general.skilllevel+0 >= maxlv then
            -- runGamePrompt({msg = "已达到等级上限"})
            runGamePrompt({msg = gameConfig.strings:string_common("generalInfo",23)})
        elseif self.skillpropnum < self.skillxnum then
            shortPropById(20046,self.skillxnum,{type = 12001, order = 10001, cids = {20046}})
            --runGamePrompt({msg = "道具不够"})
        else
            UIRequest({type = 1008, ids = {self.data.general.iid}, generaliid = self.data.general.iid, xnum = self.skillxnum})
        end
    end, CCControlEventTouchUpInside)
    self.skillUpItems.doButton:setSwallowsTouch(true)
    self.skillUpItems.doButton:setTouchPriority(self.touchPriority)

    --effect
    if self.hasup and self.hasup == 1 then
        self.hasup = 0
        --
        self.skillUpItems.bgEffectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode1,qianghuaItems1 = CCBReaderLoad("UIEffect/qianghua/luzi_effect", nil, true, "luzieffect")
        qianghuaNode1:setPosition(0,0)
        self.skillUpItems.bgEffectNode:addChild(qianghuaNode1)
        self.skillUpItems.bgEffectNode:setScale(1)
        local animationManager1 = getAnimationManager(qianghuaItems1)
        animationManager1:setAnimationCompletedCallback(function()
            self.skillUpItems.bgEffectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager1:runAnimationsForSequenceNamed("luzieffect")
        --
        self.skillUpItems.effectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/tunshitupo/huobantupo", nil, true, "huobantupo")
        qianghuaNode:setPosition(0,0)
        self.skillUpItems.effectNode:addChild(qianghuaNode)
        self.skillUpItems.effectNode:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:setAnimationCompletedCallback(function()
            self.skillUpItems.effectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("huobantupo")
        gamedata.music:PlayOptSound("xlshjhtp")
    end
end

function generalInfo.setSkillPropNum(self,pdata)
    self.skillpropnum = pdata["20046"] or 0
    ui.setNewIconName(self.skillUpItems,{cid = 20046, numdesc = self.skillpropnum.."/"..self.skillxnum},0)
end

return generalInfo  � 