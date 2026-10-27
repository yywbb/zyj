--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/22
-- Time: 下午8:07
-- To change this template use File | Settings | File Templates.
--

local fashionshop = {

    buttontouch = -103,
    roleid = 10101,
    coatconfig = {},
    status = 0,
    xgold = 0,
}

function fashionshop.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("shizhuang/shizhuang_activity",nil, true, "shop")

    local activityConfig = gamedata.config.activity_time and gamedata.config.activity_time["43"] or {}
    local fashionconfig = gamedata.config.fashioncoat or {}
    --
    if activityConfig.param and activityConfig.param ~= "" and activityConfig.param ~= 0 then

        if GameScene.protagonist and GameScene.protagonist.general and GameScene.protagonist.general.cid and GameScene.protagonist.general.cid > 0 then
            if (GameScene.protagonist.general.cid >= 10101 and GameScene.protagonist.general.cid <= 10115) or (GameScene.protagonist.general.cid >= 10997 and GameScene.protagonist.general.cid <= 10999) or (GameScene.protagonist.general.cid >= 162001 and GameScene.protagonist.general.cid <= 162003) then
                self.roleid = GameScene.protagonist.general.cid
            else
                for k,v in pairs(fashionconfig) do
                    for k1,v1 in pairs(v) do
                        if v1.coat_id == GameScene.protagonist.general.cid then
                            self.roleid = v1.role_id
                        end
                    end
                end
            end
        end
        for k,v in pairs(fashionconfig) do
            if (tonumber(k) == tonumber(activityConfig.param)) and v[tostring(self.roleid)] then
                self.coatconfig = v[tostring(self.roleid)] or {}
            end
        end
        --
        ui.setLabelString(self.coveritems.generalname,self.coatconfig.name or "",1)
        --
        if self.coatconfig.coat_id and self.coatconfig.coat_id > 0 then
            local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(self.coatconfig.coat_id)].animationid)].name
            local general = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            general:setAnimation("stand",true,0)
            general:setScale(1.6)
            general:setPosition(0,0)
            self.coveritems.general:removeAllChildrenWithCleanup(true)
            self.coveritems.general:addChild(general)
        end
        --
        local generalconfig = gamedata.config.general[tostring(self.coatconfig.coat_id)] or {}
        ui.setSkillIcon({status = 2, cid = generalconfig.skillid },self.coveritems)
        ui.setSkillIcon({status = 2, cid = generalconfig.combskillid > 0 and generalconfig.combskillid or generalconfig.combskillid2 },self.coveritems,1)

        local generaldata = {}
        generaldata.general = {}
        generaldata.general.cid = self.coatconfig.coat_id
        generaldata.general.skill = {}
        generaldata.general.skill.cid = generalconfig.skillid
        generaldata.general.combskill = {}
        generaldata.general.combskill.cid = generalconfig.combskillid > 0 and generalconfig.combskillid or generalconfig.combskillid2
        if generaldata.general.skill.cid and  generaldata.general.skill.cid > 0 then
            self.coveritems.skill1:setVisible(true)
        else
            self.coveritems.skill1:setVisible(false)
        end

        if generaldata.general.combskill.cid and  generaldata.general.combskill.cid > 0 then
            self.coveritems.skill2:setVisible(true)
        else
            self.coveritems.skill2:setVisible(false)
        end
        --
        self.coveritems.skillButton1:addHandleOfControlEvent(function()
            if generaldata.general.skill.cid and  generaldata.general.skill.cid > 0 then
                gameWindows:openWindow("generalInfoSkill",{data = generaldata, sid = 1, islead = 1, pagetype = "skillinfo", skilltype = "skill"})
            end
        end, CCControlEventTouchUpInside)
        self.coveritems.skillButton1:setSwallowsTouch(true)
        self.coveritems.skillButton1:setTouchPriority(-103)
        --
        self.coveritems.skillButton2:addHandleOfControlEvent(function()
            if generaldata.general.combskill.cid and  generaldata.general.combskill.cid > 0 then
                gameWindows:openWindow("generalInfoSkill",{data = generaldata, sid = 1, islead = 1, pagetype = "skillinfo", skilltype = "leadskill"})
            end
        end, CCControlEventTouchUpInside)
        self.coveritems.skillButton2:setSwallowsTouch(true)
        self.coveritems.skillButton2:setTouchPriority(-103)
        --
        --attr
        local upconfigall = gamedata.config.fashionintentify and gamedata.config.fashionintentify[tostring(self.coatconfig.cover_id)] or {}
        local levelnow = 1
        if not upconfigall[tostring(levelnow)] then return end
        local upconfig = upconfigall[tostring(levelnow)] or {}
        ui.setLabelString(self.coveritems.att_basic,nil,14)
        ui.setLabelString(self.coveritems.att_up,nil,14)
        for i = 1,3 do
            if upconfig["intentify_add"..i] and upconfig["intentify_add"..i] ~= "" then
                local attr,num = ui.getATTRandNUM(upconfig["intentify_add"..i])
                ui.setLabelString(self.coveritems["basic_att"..i],gameConfig.strings.attr_type[attr] or "",13)
                ui.setLabelString(self.coveritems["basic_num"..i],"+"..num,21)
            else
                ui.setLabelString(self.coveritems["basic_att"..i],"",13)
                ui.setLabelString(self.coveritems["basic_num"..i],"",21)
            end
        end
        --

        ui.setLabelString(self.coveritems.fashion_name,self.coatconfig.name or "",1)
        ui.setLabelString(self.coveritems.lab1,nil,14)
        ui.setLabelString(self.coveritems.lab2,nil,14)

        ui.setNewIcon(self.coveritems,{cid = self.coatconfig.coat_id})

        local shopconfig = gamedata.config.fashion_gift_bag and gamedata.config.fashion_gift_bag[tostring(self.coatconfig.cover_id)] or {}
        if shopconfig and shopconfig.gold then
            ui.setLabelString(self.coveritems.num1,shopconfig.gold,14)
        end

        if shopconfig and shopconfig.price then
            self.xgold = shopconfig.price
            ui.setLabelString(self.coveritems.num2,shopconfig.price,14)
        end

        ui.setLabelString(self.coveritems.buyLab,nil,18)

        if shopconfig and shopconfig.rebate and shopconfig.rebate > 0 and shopconfig.rebate < 10 then
            self.coveritems.zhe:setString(gameConfig.strings.bigNum[shopconfig.rebate].."折")
        else
            self.coveritems.zhe:setString("")
        end

        if shopconfig and shopconfig.desc and shopconfig.desc ~= "" then
            ui.setLabelString(self.coveritems.fashion_name,(self.coatconfig.name or "").." ("..shopconfig.desc..") ",1)
        end

    end
    --
    local endString = ""
    if gamedata.config.activity_time["43"]["end"] and gamedata.config.activity_time["43"]["end"] ~= "" then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["43"]["end"])
        endString = year.."年"..month.."月"..day.."日"
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            endString = endtab.year.."年"..endtab.month.."月"..endtab.day.."日"
        end
    end
    ui.setLabelString(self.coveritems["activitytime"],"结束时间: "..endString,18)

    --
    return self.coverccb
end


function fashionshop.reloaddata(self,data)
    if not self.show then return end
    if not data then return end

    self.status = data.status or 0

    if self.status == 1 then
        ui.removeGray("CCControlButton",self.coveritems["buyButton"])
        self.coveritems["buyButton"]:setTouchPriority(self.buttontouch)
        self.coveritems["buyButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 1074,id = self.coatconfig.cover_id, xgold = self.xgold})
        end, CCControlEventTouchUpInside)
    else
        ui.addGray("CCControlButton",self.coveritems["buyButton"])
        self.coveritems["buyButton"]:setTouchPriority(self.buttontouch)
        self.coveritems["buyButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            runGamePrompt({msg = "已拥有该时装"})
        end, CCControlEventTouchUpInside)
    end
end


function fashionshop.clear(self)

    self.show = false

    self.roleid = 10101
    self.coatconfig = {}
    self.status = 0
    self.xgold = 0

    self.data = nil
    self.coverccb = nil
    self.coveritems = nil
end



return fashionshop�#  