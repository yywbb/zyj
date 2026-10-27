--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/5
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--

local recruit = {
    root = nil,

    recruitCCB = nil,
    recruitItems = nil,

    oneCCB = nil,
    oneItems = nil,

    tenCCB = nil,
    tenItems = nil,

    yulanCCB = nil,
    yulanItems = nil,

    recruitdata = nil,
    tendata = nil,
    onedata = nil,
    yulandata = nil,

    yulandata_1 = {},
    yulandata_2 = {},
    yulandata_3 = {},
    yulandata_4 = {},

    typeconfig = {
        recruit = "shop/recruit_ten",
        ten = "shop/recruit_zhaomu_ten",
        one = "shop/recruit_zhaomu_one",
        yulan = "shop/recruit_yulan",
    },
    type=nil,

    yulanindex = 0,
    loadindex = 0,
    isscrolltouched = false,
    RecruitTempData = {},

    hundanNum = 0,
}

function recruit.makeYulandata(self)
    if not next(self.yulandata_1) then
        for k,v in pairs(gamedata.config.recruit) do
            local onedata = ui.IDconfig(v.id) --table.copy(gamedata.config:getConfigByName("general")[tostring(v.id)])
            onedata.cid = v.id
            onedata.showorder = v.order or 0
            if v.tenfree >0 or v.tengold >0 then
                table.insert(self.yulandata_1,onedata)
            end

            if v.hundredfree >0 or v.hundredgold >0 or v.hundredfirst >0  then
                table.insert(self.yulandata_2,onedata)
            end

            if v.millionfree >0 or v.milliongold >0 or v.millionfirst >0 or v.millionmust >0 then
                table.insert(self.yulandata_3,onedata)
            end

            if v.enlist and v.enlist > 0 then
                table.insert(self.yulandata_4,onedata)
            end
        end

        local sortfunc = function (a,b)
            return a["showorder"] > b["showorder"]
        end

        table.sort(self.yulandata_1,sortfunc)
        table.sort(self.yulandata_2,sortfunc)
        table.sort(self.yulandata_3,sortfunc)
        table.sort(self.yulandata_4,sortfunc)
    end
end

function recruit.shiftType(self,data)
    self.firstreload = true
    self.type = data.type
    self.root:removeAllChildrenWithCleanup(true)
    self[self.type.."CCB"], self[self.type.."Items"] = CCBReaderLoad(self.typeconfig[data.type], nil, true, "recruit")
    self[self.type.."data"] = data.data
    self[self.type.."CCB"]:setAnchorPoint(ccp(0.5,0.5))

    self.root:addChild(self[self.type.."CCB"])
    self.rootNode = self[self.type.."CCB"]
    --
    -- 防止在listnode外还可点击
    local function touchbegin(pos)
        self.isscrolltouched = false
    end
    gameTouch:rigistFunc("begin","recruit",touchbegin)
    local function touchend(pos)
        if self.type == "yulan" then
            
        else
            self.yulanItems = nil
        end
        if self.yulanItems and self.yulanItems.listnode and ui.isTouched(self.yulanItems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end
    gameTouch:rigistFunc("end","recruit",touchend)
    -- 

    local needanimation = true

    if self.type == "recruit" then
        self:requestPropNum()
        self.recruitItems.hint_change:setVisible(false)
        self.recruitItems.changeButton:setVisible(false)
        self.recruitItems.fengshen_tip1:setVisible(false)
        self.recruitItems.fengshen_tip2:setVisible(false)

        if data.data.index == 4 then
            self.recruitItems.fengshen_tip1:setVisible(true)
            self.recruitItems.fengshen_tip2:setVisible(true)

            -- ui.setLabelString(self.recruitItems.fengshen_tip1,nil, 14)
            -- ui.setLabelString(self.recruitItems.fengshen_tip2,nil, 14)
            self.recruitItems.changeButton:setVisible(true)
            UIRequest({type = 7110})
        end
    elseif self.type == "ten" then
        self:reloadten()
        needanimation = false
    elseif self.type == "one" then
        self:reloadone()
        needanimation =false
    elseif self.type == "yulan" then
        self:reloadyulan()
    end

    return needanimation
end

function recruit.requestPropNum( self )
    if self.type == "recruit" then
        UIRequest({type = 12001, order = 32010, cids = {20100, 20619, 20618}})
    end
end

function recruit.setPropNum(self, data)
    self.zhaomuling = data["20100"]
    self.gaojizhaomuling = data["20619"]
    self.fengshenzhaomuling = data["20618"]

    self:reloadrecruit()
end

function recruit.setFengshenRefresh(self, data)
    
    self.RecruitTempData = data

    if self.type == "recruit" and self.recruitdata.index == 4 then

        if self.RecruitTempData.status ~= 1 then
            self.recruitItems.hint_change:setVisible(true)
        end

        -- self.recruitItems.changeButton:setVisible(true)

        if self.RecruitTempData.status == 1 then
            setControlButtonFrame(self.recruitItems.changeButton,"fengshenshuomingbt","fengshenshuomingbt","fengshenshuomingbt")
        else
            setControlButtonFrame(self.recruitItems.changeButton,"genghuanjianglibt","genghuanjianglibt","genghuanjianglibt")
        end

        self.recruitItems.changeButton:addHandleOfControlEvent(function()

            if self.RecruitTempData.status == 1 then
                gameWindows:openWindow("fengshenRule")
            else
                local _data = {
                    method = 2,
                    pos = 4,
                    gets = self.RecruitTempData.gets,
                }
                gameWindows:openWindow("recruit",{type = "ten", data = _data },nil)
            end
            

        end, CCControlEventTouchUpInside)
        self.recruitItems.changeButton:setSwallowsTouch(true)
        self.recruitItems.changeButton:setTouchPriority(self.touchPriority)
    end
end

function recruit.open(self,touchPriority,data,callback)
    self.root = CCNode:create()

    self.touchPriority = touchPriority

    printT(data,"recruit_open")
    self.callback = callback
    self:makeYulandata()
    local needanimation = self:shiftType(data)
    return self.root, not needanimation
end

function recruit.reload(self,data,callback)
    self.callback = callback
    self:shiftType(data)
end

function recruit.setOneyulan(self,ccb,item,pos)
    self.yulanindex = self.yulanindex +1
    if self.yulanindex> #self["yulandata_"..self.recruitdata.index] then
        self.yulanindex = 1
    end

    item.general:removeAllChildrenWithCleanup(true)
    local configdata =  self["yulandata_"..self.recruitdata.index][self.yulanindex]
    local generalName = gamedata.config:getConfigByName("generalanimation")[tostring(configdata.animationid)].name
    local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral:setAnimation("stand",true,0)
    Gneral:setScale(2.3)

    ui.setLabelString(item.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)
    item.general:addChild(Gneral)
    ccb:setPosition(pos)
end

function recruit.repeataction(self,ccb,item)
    self:setOneyulan(ccb,item,ccp(-446,100))
    local first = CCMoveTo:create(10, ccp(1338, 100))
    ccb:runAction(CCSequence:createWithTwoActions(first, CCCallFunc:create(function()
        self:repeataction(ccb,item)
    end)))
end


function recruit.setyulan(self)
    local general1ccb,general1item = CCBReaderLoad("shop/yulan_one", nil, true, "yulan_one")
    self.recruitItems.container:addChild(general1ccb)
    self:setOneyulan(general1ccb,general1item,ccp(446,100))
    local general2ccb,general2item = CCBReaderLoad("shop/yulan_one", nil, true, "yulan_one")
    self.recruitItems.container:addChild(general2ccb)

    local first = CCMoveTo:create(5, ccp(1338, 100))
    general1ccb:runAction(CCSequence:createWithTwoActions(first, CCCallFunc:create(function()
         self:repeataction(general1ccb,general1item)
    end)))

    self:repeataction(general2ccb,general2item)
end

function recruit.reloadrecruit(self)

    self.recruitItems.generalscroll:setTouchEnabled(false)
    self.recruitItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("recruit")
    end, CCControlEventTouchUpInside)
    self.recruitItems.closeButton:setSwallowsTouch(true)
    self.recruitItems.closeButton:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.recruitItems.yulantext,"招募预览",18)
    ui.setLabelString(self.recruitItems.yulantext,gameConfig.strings:string_common("recruit",0),18)
    self.recruitItems.yulanbutton:addHandleOfControlEvent(function()
        self.callback = nil
        self:shiftType({type = "yulan",data = self.recruitdata.index})
    end, CCControlEventTouchUpInside)
    self.recruitItems.yulanbutton:setSwallowsTouch(true)
    self.recruitItems.yulanbutton:setTouchPriority(self.touchPriority)

    if self.recruitItems.getHundredNode then
       if self.recruitdata.index == 1 then
           self.recruitItems.getHundredNode:setVisible(true)
           self.recruitItems.getTenNode:setPositionX(0)
           self.recruitItems.getOneNode:setPositionX(-280)
           self.recruitItems.hundredgold:setVisible(false)
           self.recruitItems.hundredprop:setVisible(true)
       else
           self.recruitItems.getHundredNode:setVisible(false)
           self.recruitItems.getTenNode:setPositionX(200)
           self.recruitItems.getOneNode:setPositionX(-200)
           self.recruitItems.hundredgold:setVisible(true)
           self.recruitItems.hundredprop:setVisible(false)
       end
       --
       ui.setLabelString(self.recruitItems.hundredgoldnum,"100",14)
       ui.setLabelString(self.recruitItems.getHundredtext,"招百次",18)
       self.recruitItems.getHundred:addHandleOfControlEvent(function()
           gameTouch:clickprofbytime(0.5)
           UIRequest({type = 1403, pos = self.recruitdata.index, method = 3})
       end, CCControlEventTouchUpInside)
       self.recruitItems.getHundred:setSwallowsTouch(true)
       self.recruitItems.getHundred:setTouchPriority(self.touchPriority)
    end

    self.recruitItems.propnode:setVisible(self.recruitdata.index == 1)
    self.recruitItems.gambling1:setVisible(self.recruitdata.index == 1)
    -- self.recruitItems.onegold:setVisible(self.recruitdata.index ~= 1)
    self.recruitItems.oneprop:setVisible(self.recruitdata.index == 1)
    -- self.recruitItems.tengold:setVisible(self.recruitdata.index ~= 1)
    self.recruitItems.tenprop:setVisible(self.recruitdata.index == 1)
    self.recruitItems.gaojizhaomulingNode:setVisible(self.recruitdata.index == 3 or self.recruitdata.index == 4)

    --self.recruitItems.singledes1:setVisible(false)
    --self.recruitItems.singledes2:setVisible(false)
    local config = gamedata.config:getConfigByName("recruit_basic")[tostring(self.recruitdata.index)]
    local _maxGold = self.recruitdata.data.propnum

    -- if self.recruitdata.index ~= 1 then
    --     _maxGold = GameScene.roleinfo.gold
    -- else
    --     _maxGold = self.zhaomuling
    -- end

    if self.recruitdata.index == 3 then
        setSpriteFrameByName(self.recruitItems.gaojizhaomulingSprite, "gaojizhaomuling")
        self.recruitItems.goldnum2:setString(self.gaojizhaomuling)

        if self.gaojizhaomuling > 0 then
            self.recruitItems.goldnum2:setColor(ccc3(255,245,219))
        else
            self.recruitItems.goldnum2:setColor(ccc3(255,0,0))
        end
    elseif self.recruitdata.index == 4 then
        setSpriteFrameByName(self.recruitItems.gaojizhaomulingSprite, "fengshenzhaomuling")
        self.recruitItems.goldnum2:setString(self.fengshenzhaomuling)

        if self.fengshenzhaomuling > 0 then
            self.recruitItems.goldnum2:setColor(ccc3(255,245,219))
        else
            self.recruitItems.goldnum2:setColor(ccc3(255,0,0))
        end
    else
        _maxGold = self.zhaomuling
        self.recruitItems.goldnum:setString(_maxGold)
        if _maxGold > 0 then
            self.recruitItems.goldnum:setColor(ccc3(255,245,219))
        else
            self.recruitItems.goldnum:setColor(ccc3(255,0,0))
        end
    end

    local _l = self.recruitItems.getOneNode:getChildByTag(1011)
    if _l then
        _l:removeFromParentAndCleanup(true)
    end

    self.recruitItems.ongoldnum:setVisible(true)
        
    if self.recruitdata.index == 3 then
        -- if self.gaojizhaomuling >= config.count then
        --     self.typeOne = "gaojizhaomuling"
        --     if config.costid == 1001 then
        --         self.recruitItems.onegold:setVisible(true)
        --         self.recruitItems.onegaojizhaomuling:setVisible(false)
        --     else
        --         self.recruitItems.onegold:setVisible(false)
        --         self.recruitItems.onegaojizhaomuling:setVisible(true)
        --     end
        --     self.recruitItems.ongoldnum:setString(config.count)
        --     local _icon = ui.IDconfig(config.costid).icon
        --     setSpriteFrameByName(self.recruitItems.onegaojizhaomuling, _icon)
        -- else
        --     self.typeOne = "gold"
        --     if config.costid_god == 1001 then
        --         self.recruitItems.onegold:setVisible(true)
        --         self.recruitItems.onegaojizhaomuling:setVisible(false)
        --     else
        --         self.recruitItems.onegold:setVisible(false)
        --         self.recruitItems.onegaojizhaomuling:setVisible(true)
        --     end
        --     self.recruitItems.ongoldnum:setString(config.count_god)
        --     local _icon = ui.IDconfig(config.costid_god).icon
        --     setSpriteFrameByName(self.recruitItems.onegaojizhaomuling, _icon)
        -- end
        self.typeOne = "gaojizhaomuling"
        if config.costid == 1001 then
            self.recruitItems.onegold:setVisible(true)
            self.recruitItems.onegaojizhaomuling:setVisible(false)
        else
            self.recruitItems.onegold:setVisible(false)
            self.recruitItems.onegaojizhaomuling:setVisible(true)
        end
        self.recruitItems.ongoldnum:setString(config.count)
        local _icon = ui.IDconfig(config.costid).icon
        setSpriteFrameByName(self.recruitItems.onegaojizhaomuling, _icon)

    elseif self.recruitdata.index == 4 then

        self.typeOne = "gaojizhaomuling"
        if config.costid == 1001 then
            self.recruitItems.onegold:setVisible(true)
            self.recruitItems.onegaojizhaomuling:setVisible(false)
        else
            self.recruitItems.onegold:setVisible(false)
            self.recruitItems.onegaojizhaomuling:setVisible(true)
        end
        self.recruitItems.ongoldnum:setString(config.count)
        local _icon = ui.IDconfig(config.costid).icon
        setSpriteFrameByName(self.recruitItems.onegaojizhaomuling, _icon)

        -- if self.fengshenzhaomuling >= config.count then
        --     self.typeOne = "gaojizhaomuling"
        --     if config.costid == 1001 then
        --         self.recruitItems.onegold:setVisible(true)
        --         self.recruitItems.onegaojizhaomuling:setVisible(false)
        --     else
        --         self.recruitItems.onegold:setVisible(false)
        --         self.recruitItems.onegaojizhaomuling:setVisible(true)
        --     end
        --     self.recruitItems.ongoldnum:setString(config.count)
        --     local _icon = ui.IDconfig(config.costid).icon
        --     setSpriteFrameByName(self.recruitItems.onegaojizhaomuling, _icon)
        -- else
        --     self.typeOne = "gold"
        --     if config.costid_god == 1001 then
        --         self.recruitItems.onegold:setVisible(true)
        --         self.recruitItems.onegaojizhaomuling:setVisible(false)
        --     else
        --         self.recruitItems.onegold:setVisible(false)
        --         self.recruitItems.onegaojizhaomuling:setVisible(true)
        --     end
        --     self.recruitItems.ongoldnum:setString(config.count_god)
        --     local _icon = ui.IDconfig(config.costid_god).icon
        --     setSpriteFrameByName(self.recruitItems.onegaojizhaomuling, _icon)
        -- end
    else
        self.recruitItems.onegold:setVisible(false)
        self.recruitItems.onegaojizhaomuling:setVisible(false)
        self.typeOne = "gold"
        self.recruitItems.ongoldnum:setString(config.count)
    end

    if self.recruitdata.index == 3 then

        local discount = self.recruitdata.discount or 10

        -- if self.gaojizhaomuling >= config.tentaverncount*discount/10 then
        --     self.typeTen = "gaojizhaomuling"
        --     if config.costid == 1001 then
        --         self.recruitItems.tengold:setVisible(true)
        --         self.recruitItems.tengaojizhaomuling:setVisible(false)
        --     else
        --         self.recruitItems.tengold:setVisible(false)
        --         self.recruitItems.tengaojizhaomuling:setVisible(true)
        --     end
        --     self.recruitItems.tengoldnum:setString(config.tentaverncount*discount/10)
        --     local _icon = ui.IDconfig(config.costid).icon
        --     setSpriteFrameByName(self.recruitItems.tengaojizhaomuling, _icon)
        -- else
        --     self.typeTen = "gold"
        --     if config.costid_god == 1001 then
        --         self.recruitItems.tengold:setVisible(true)
        --         self.recruitItems.tengaojizhaomuling:setVisible(false)
        --     else
        --         self.recruitItems.tengold:setVisible(false)
        --         self.recruitItems.tengaojizhaomuling:setVisible(true)
        --     end
        --     self.recruitItems.tengoldnum:setString(config.tentaverncount_god)
        --     local _icon = ui.IDconfig(config.costid_god).icon
        --     setSpriteFrameByName(self.recruitItems.tengaojizhaomuling, _icon)
        -- end
        self.typeTen = "gaojizhaomuling"
        if config.costid == 1001 then
            self.recruitItems.tengold:setVisible(true)
            self.recruitItems.tengaojizhaomuling:setVisible(false)
        else
            self.recruitItems.tengold:setVisible(false)
            self.recruitItems.tengaojizhaomuling:setVisible(true)
        end
        self.recruitItems.tengoldnum:setString(config.tentaverncount*discount/10)
        local _icon = ui.IDconfig(config.costid).icon
        setSpriteFrameByName(self.recruitItems.tengaojizhaomuling, _icon)

    elseif self.recruitdata.index == 4 then
        self.typeTen = "gaojizhaomuling"
        if config.costid == 1001 then
            self.recruitItems.tengold:setVisible(true)
            self.recruitItems.tengaojizhaomuling:setVisible(false)
        else
            self.recruitItems.tengold:setVisible(false)
            self.recruitItems.tengaojizhaomuling:setVisible(true)
        end
        self.recruitItems.tengoldnum:setString(config.tentaverncount)
        local _icon = ui.IDconfig(config.costid).icon
        setSpriteFrameByName(self.recruitItems.tengaojizhaomuling, _icon)

        -- if self.fengshenzhaomuling >= config.tentaverncount then
        --     self.typeTen = "gaojizhaomuling"
        --     if config.costid == 1001 then
        --         self.recruitItems.tengold:setVisible(true)
        --         self.recruitItems.tengaojizhaomuling:setVisible(false)
        --     else
        --         self.recruitItems.tengold:setVisible(false)
        --         self.recruitItems.tengaojizhaomuling:setVisible(true)
        --     end
        --     self.recruitItems.tengoldnum:setString(config.tentaverncount)
        --     local _icon = ui.IDconfig(config.costid).icon
        --     setSpriteFrameByName(self.recruitItems.tengaojizhaomuling, _icon)
        -- else
        --     self.typeTen = "gold"
        --     if config.costid_god == 1001 then
        --         self.recruitItems.tengold:setVisible(true)
        --         self.recruitItems.tengaojizhaomuling:setVisible(false)
        --     else
        --         self.recruitItems.tengold:setVisible(false)
        --         self.recruitItems.tengaojizhaomuling:setVisible(true)
        --     end
        --     self.recruitItems.tengoldnum:setString(config.tentaverncount_god)
        --     local _icon = ui.IDconfig(config.costid_god).icon
        --     setSpriteFrameByName(self.recruitItems.tengaojizhaomuling, _icon)
        -- end
    else
        self.recruitItems.tengold:setVisible(false)
        self.recruitItems.tengaojizhaomuling:setVisible(false)
        self.typeTen = "gold"
        self.recruitItems.tengoldnum:setString(config.tentaverncount_god)
    end

    if config.openfreerecruit ==0 and self.recruitdata.timer == 0 then
        self.recruitItems.ongoldnum:setString(0)
        self.recruitItems.onegold:setVisible(false)
        self.recruitItems.oneprop:setVisible(false)
        self.recruitItems.ongoldnum:setVisible(false)
        self.recruitItems.onegaojizhaomuling:setVisible(false)
                       
        local argsName = {
            text = "本次免费",
            color =ccc3(37,197,1),
            fontsize = 34,
        }
        local label = ui.createLabel(argsName)
        label:setPosition(0,-80)
        self.recruitItems.getOneNode:addChild(label)
        label:setTag(1011)
        ui.setLabelString(label,nil,123)
    end
    
    if self.recruitdata.discount then
        if self.recruitItems.hundredgoldnum then
            -- if self.gaojizhaomuling >= 10 then
            --     ui.setLabelString(self.recruitItems.hundredgoldnum,config.hundred*self.recruitdata.discount/10,14)
            -- else
            --     ui.setLabelString(self.recruitItems.hundredgoldnum,config.hundred_god*self.recruitdata.discount/10,14)
            -- end
            ui.setLabelString(self.recruitItems.hundredgoldnum,config.hundred*self.recruitdata.discount/10,14)
        end

        -- if self.gaojizhaomuling >= 10*self.recruitdata.discount/10 then
        --     self.recruitItems.tengoldnum:setString(config.tentaverncount*self.recruitdata.discount/10)
        -- else
        --     self.recruitItems.tengoldnum:setString(config.tentaverncount_god*self.recruitdata.discount/10)
        -- end
        self.recruitItems.tengoldnum:setString(config.tentaverncount*self.recruitdata.discount/10)

        --ui.setLabelString(self.recruitItems.discountnum,"("..gameConfig.strings:cutOff(self.recruitdata.discount)..")",14)
        self.recruitItems.discountsprite:setVisible(true)
        self.recruitItems.discountsprite2:setVisible(true)
        setSpriteFrameByName(self.recruitItems.discountsprite, self.recruitdata.discount.."zhe")
        setSpriteFrameByName(self.recruitItems.discountsprite2, self.recruitdata.discount.."zhe")
    else
        if self.typeTen == "gaojizhaomuling" then
            self.recruitItems.tengoldnum:setString(config.tentaverncount)
        else
            self.recruitItems.tengoldnum:setString(config.tentaverncount_god)
        end
        self.recruitItems.discountsprite:setVisible(false)
        self.recruitItems.discountsprite2:setVisible(false)
        if self.recruitItems.hundredgoldnum then
            ui.setLabelString(self.recruitItems.hundredgoldnum,config.hundred_god,14)
        end
    end

    if self.recruitdata.index == 3 and self.recruitdata.data.consumtimes<=0 then
        --self.recruitItems.singledes1:setVisible(true)
        --self.recruitItems.singledes2:setVisible(true)
        --ui.setLabelString(self.recruitItems.singledes1,nil,21)
        --ui.setLabelString(self.recruitItems.singledes2,nil,7)
    end

    ui.setLabelString(self.recruitItems.ongoldnum,nil,14)
    ui.setLabelString(self.recruitItems.tengoldnum,nil,14)

    if self.recruitdata.index == 3 then
        ui.setLabelString(self.recruitItems.ongoldnum,nil,self.gaojizhaomuling >= 1 and 14 or 47,34)
        ui.setLabelString(self.recruitItems.tengoldnum,nil,self.gaojizhaomuling >= 10 and 14 or 47,34)
    end

    if self.recruitdata.index == 4 then
        ui.setLabelString(self.recruitItems.ongoldnum,nil,self.fengshenzhaomuling >= 1 and 14 or 47,34)
        ui.setLabelString(self.recruitItems.tengoldnum,nil,self.fengshenzhaomuling >= 10 and 14 or 47,34)
    end

    if self.recruitdata.pointactive and (self.recruitdata.index == 3 or self.recruitdata.index == 4) then
        local point = ""
        if self.recruitdata.index == 3 then
            point = gamedata.config:getConfigByName("global_kv").enlist_wanzhongzhumu.value
        elseif self.recruitdata.index == 4 then
            point = gamedata.config:getConfigByName("global_kv").enlist_fengshenzhaomu.value
        end
        ui.setLabelString(self.recruitItems.tenpoint,"积分+"..(point*10),23)
        ui.setLabelString(self.recruitItems.onepoint,"积分+"..point,23)
    end

    -- ui.setLabelString(self.recruitItems.getOnetext,"招一次",18)
    ui.setLabelString(self.recruitItems.getOnetext,gameConfig.strings:string_common("recruit",1),18)
    self.recruitItems.getOne:addHandleOfControlEvent(function()

        gameTouch:clickprofbytime(0.5)
        if self.recruitdata.index == 4 and self.RecruitTempData.status and self.RecruitTempData.status == 0 then
            runGamePrompt({msg = gameConfig.strings:string_common("recruit",13)})
        else
            UIRequest({type = 1403, pos = self.recruitdata.index, method = 1, goldType = self.typeOne})
        end

        
    end, CCControlEventTouchUpInside)
    self.recruitItems.getOne:setSwallowsTouch(true)
    self.recruitItems.getOne:setTouchPriority(self.touchPriority)

    -- ui.setLabelString(self.recruitItems.getTentext,"招十次",18)
    ui.setLabelString(self.recruitItems.getTentext,gameConfig.strings:string_common("recruit",3),18)
    self.recruitItems.getTen:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        
        if self.recruitdata.index == 4 then

            if self.RecruitTempData.status and self.RecruitTempData.status == 0 then
                runGamePrompt({msg = gameConfig.strings:string_common("recruit",13)})
            else
                UIRequest({type = 7111, goldType = self.typeTen})
            end
        else
            UIRequest({type = 1403, pos = self.recruitdata.index, method = 2, goldType = self.typeTen})
        end

    end, CCControlEventTouchUpInside)
    self.recruitItems.getTen:setSwallowsTouch(true)
    self.recruitItems.getTen:setTouchPriority(self.touchPriority)



    if self.firstreload then
        self:setyulan()
        self.firstreload = false
    end
    


    --
    if gamedata.config:getConfigByName("build")[tostring(354)] and gamedata.config:getConfigByName("build")[tostring(354)].switch == 1 then
        if self.recruitItems.gambling1 and self.recruitdata.index > 1 then
            -- self.recruitItems.gambling1:setVisible(false)
            -- ui.setLabelString(self.recruitItems.title,"赠送伙伴",18)
            -- ui.setLabelString(self.recruitItems.yulantext,"赠送预览",18)
            -- ui.setLabelString(self.recruitItems.getOnetext,"购买一次",18)
            -- ui.setLabelString(self.recruitItems.getTentext,"购买十次",18)
            -- local icon = "alpha"
            -- if gamedata.config:getConfigByName("gambling") and gamedata.config:getConfigByName("gambling")[tostring(self.recruitdata.index-1)] then
            --     local reward = ui.getIDandNUMs(gamedata.config:getConfigByName("gambling")[tostring(self.recruitdata.index-1)].reward1)
            --     icon = ui.IDconfig(reward[1].cid).icon
            -- end
            -- self.recruitItems.gambling2:setVisible(false)
            -- self.recruitItems.gambling3:setVisible(false)
            -- self.recruitItems.gambling4:setVisible(false)
            -- ui.setLabelString(self.recruitItems.gambling2,nil,18)
            -- ui.setLabelString(self.recruitItems.gambling3,nil,18)
            -- setSpriteFrameByName(self.recruitItems.gambling4, icon)
        end
    end

    -- 购买令牌
    if self.recruitdata.index == 3 then
        self.recruitItems.buyItemNode:setVisible(true)
        ui.setLabelString(self.recruitItems.itemLab,gameConfig.strings:string_common("fixedString","shop",28),18)

        self.recruitItems.buyItem:setTouchPriority(self.touchPriority)
        self.recruitItems.buyItem:setSwallowsTouch(true)
        self.recruitItems.buyItem:addHandleOfControlEvent(function()

            gameTouch:clickprofbytime(0.5)
            gameWindows:openWindow("buyItem",{id = config.costid},function (data)
                if data.id == config.costid then
                    UIRequest({type = 1402})
                    self.gaojizhaomuling = data.num
                    self:reloadrecruit()
                end
            end)
    
        end, CCControlEventTouchUpInside)
    else
        self.recruitItems.buyItemNode:setVisible(false)
    end

end

function recruit.showExtReward(self,ext,type)
    local extnode,extitem = CCBReaderLoad("shop/cell_zhaomu", nil, true, "cellzhaomu")
    self[type].extnode:addChild(extnode)
    for i=1,2 do
        if ext[tostring(i)] then
            ui.setNewIcon(extitem,ext[tostring(i)],i-1)
        else
            extitem["reward"..i]:setVisible(false)
        end
    end
end

function recruit.loadOneOfTen(self)
    self.loadindex = self.loadindex +1
    if self.loadindex> table.getTableLength(self.tendata.gets) then
        self.loadindex = 0
        self.tenItems.buttonnode:setVisible(true)
        self.tenItems.closeButton:setVisible(true)

        if self.tendata.ext and next(self.tendata.ext) then
            self:showExtReward(self.tendata.ext,"tenItems")
        end

        return
    end
    self.tenCCB:runAction(CCSequence:createWithTwoActions(CCDelayTime:create( 0.2 ), CCCallFunc:create(function()
        local configdata = ui.IDconfig(self.tendata.gets[tostring(self.loadindex)].cid)
        local ccb,item = nil,nil
        if self.tendata.pos == 1 then
            ccb,item = CCBReaderLoad("UIEffect/zhaomu/recruit_ten_ren"..(configdata.quality >=5 and "_5" or ""), nil, true, "recruit_ten_ren")
        else
            ccb,item = CCBReaderLoad("UIEffect/zhaomu/recruit_ten_ren"..(configdata.quality >=5 and "_5" or "").."_yuanbao", nil, true, "recruit_ten_ren")
        end
        local generalName = gamedata.config:getConfigByName("generalanimation")[tostring(gamedata.config:getConfigByName("general")[tostring(configdata.generalid)].animationid)].name
        local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        Gneral:setAnimation("stand",true,0)
        Gneral:setScale(1)
        Gneral:setPosition(0,0)
        item.general:addChild(Gneral)
        ui.setLabelString(item.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)
        self.tenItems["g"..self.loadindex]:addChild(ccb)


        if configdata.staffType == "general" then
            item.fragmentNode:setVisible(false)
        else
            item.fragmentNode:setVisible(true)
            ui.setLabelString(item.fragmentNum,"x"..self.tendata.gets[tostring(self.loadindex)].num,14)
        end


        if configdata.actor and configdata.actor == "tank" then
            setSpriteFrameByName(item.gtype, "obj_qian")
        else
            setSpriteFrameByName(item.gtype, "obj_hou")
        end

--        if configdata.quality >=5 then
--            local positionx = self.tenItems["g"..self.loadindex]:getPositionX()
--            local positiony = self.tenItems["g"..self.loadindex]:getPositionY()
--            self.tenItems["g"..self.loadindex]:setPosition(1080/2,1920/2)
--            self.tenItems["g"..self.loadindex]:setScale(2.3)
--            self.tenItems["g"..self.loadindex]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5), CCCallFunc:create(function()
--                local move = CCMoveTo:create(0.3,ccp(positionx,positiony))
--                local scale = CCScaleTo:create(0.3,1)
--                local sp = CCSpawn:createWithTwoActions(move,scale)
--                self.tenItems["g"..self.loadindex]:runAction(CCSequence:createWithTwoActions(sp, CCCallFunc:create(function()
--                    self:loadOneOfTen()
--                end)))
--            end)))
--        else
--            self:loadOneOfTen()
--        end
        if configdata.quality >=5 and configdata.staffType == "general" then

            local flag = false
            local ccb1,item1 = CCBReaderLoad("UIEffect/zhaomu/recruit_5_tishi", nil, true, "recruit_5_tishi")
            self.tenItems.tishiNode:addChild(ccb1)  
            local animationManager1 = getAnimationManager(item1)
            animationManager1:setAnimationCompletedCallback(function()
                if flag == false then
                    self:loadOneOfTen()
                end                
                ccb1:removeFromParentAndCleanup(true)
            end)
            item1.closeButton:addHandleOfControlEvent(function()
                flag = true
                ccb1:setVisible(false)
                item1.closeButton:setTouchEnabled(false)
                item1.closeButton:setSwallowsTouch(false)
                self:loadOneOfTen()
            end, CCControlEventTouchUpInside)
            item1.closeButton:setSwallowsTouch(true)
            item1.closeButton:setTouchEnabled(true)
            item1.closeButton:setTouchPriority(self.touchPriority-1)  
            local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            Gneral1:setAnimation("stand",true,0)
            Gneral1:setScale(1.5)
            Gneral1:setPosition(0,0)
            item1.general:addChild(Gneral1)
            ui.setLabelString(item1.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1) 
            animationManager1:runAnimationsForSequenceNamed("recruit_5_tishi") 
        else
            self:loadOneOfTen()
        end


    end)))
end

function recruit.reloadten(self)

    self.tenItems.buttonnode:setVisible(false)
    self.tenItems.closeButton:setVisible(false)
    self.tenItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("recruit")
    end, CCControlEventTouchUpInside)
    self.tenItems.closeButton:setSwallowsTouch(true)
    self.tenItems.closeButton:setTouchPriority(self.touchPriority)

    local config = gamedata.config:getConfigByName("recruit_basic")[tostring(self.tendata.pos)]
    local discounttime,discount = GameScene.layers["shopList"].module:checkDiscountActivity()
    discount = discount and discount/10 or 1

    if self.tendata.pos == 4 then
        discount = 1
    end

    if self.tendata.reward and next(self.tendata.reward) then
        for k,v in pairs(self.tendata.reward) do
            -- 显示自动锻造
            if tonumber(v.cid) == 20200 then
                self.tenItems.autoTishi:setVisible(true)
                self.hundanNum = self.hundanNum + v.num
            end
        end
    end

    self.tenItems.doYuanbao:setVisible(self.tendata.pos ~= 1)
    self.tenItems.doZhao:setVisible(self.tendata.pos == 1)
    self.tenItems.Zhaomuling:setVisible(self.tendata.pos == 1)
    self.tenItems.Yuanbao:setVisible(self.tendata.pos ~= 1)
    --..(discount~=1 and "("..gameConfig.strings:cutOff(self.recruitdata.discount)..")" or ""))
    local _propnum = 0

    if self.typeTen == "gaojizhaomuling" then
        self.tenItems.doNum:setString(config.tentaverncount*discount)
        local _icon = ui.IDconfig(config.costid).icon

        setSpriteFrameByName(self.tenItems.doYuanbao, _icon)
        setSpriteFrameByName(self.tenItems.Yuanbao, _icon)

        if self.recruitdata.index == 3 then
            _propnum = self.tendata.generalrecruit[tostring(self.tendata.pos)].propnum
        elseif self.recruitdata.index == 4 then
            _propnum = 0
        else
            _propnum = self.tendata.gold
        end

        self.tenItems.doYuanbao:setScale(0.5)
        self.tenItems.Yuanbao:setScale(0.5)

        if _propnum < config.tentaverncount*discount then
            ui.setLabelString(self.tenItems.doNum,nil,47)
        else
            ui.setLabelString(self.tenItems.doNum,nil,14)
        end
    else
        self.tenItems.doNum:setString(config.tentaverncount_god*discount)
        local _icon = ui.IDconfig(config.costid_god).icon
        
        if self.recruitdata.index == 3 then
            setSpriteFrameByName(self.tenItems.doYuanbao, _icon)
            setSpriteFrameByName(self.tenItems.Yuanbao, _icon)
            _propnum = self.tendata.gold
        elseif self.recruitdata.index == 4 then
            _propnum = 0
        else
            setSpriteFrameByName(self.tenItems.doYuanbao, _icon)
            setSpriteFrameByName(self.tenItems.Yuanbao, _icon)
            _propnum = self.tendata.generalrecruit[tostring(self.tendata.pos)].propnum
        end
        
        self.tenItems.doYuanbao:setScale(0.5)
        self.tenItems.Yuanbao:setScale(0.5)

        if _propnum < config.tentaverncount_god*discount then
            ui.setLabelString(self.tenItems.doNum,nil,47)
        else
            ui.setLabelString(self.tenItems.doNum,nil,14)
        end
    end

    self.tenItems.propNum:setString(_propnum)

    if (discount~=1) and self.recruitdata.discount then
        self.tenItems.discountsprite:setVisible(true)
        -- self.tenItems.discountsprite2:setVisible(true)
        setSpriteFrameByName(self.tenItems.discountsprite, self.recruitdata.discount.."zhe")
    else
        self.tenItems.discountsprite:setVisible(false)
        -- self.tenItems.discountsprite2:setVisible(false)
    end

    if _propnum > 0 then
        self.tenItems.propNum:setColor(ccc3(254,254,237))
    else
        self.tenItems.propNum:setColor(ccc3(255,0,0))
    end

    self.tenItems.shareNode:setVisible(gameConfig:checkBuildOpen(153))

    -- ui.setLabelString(self.tenItems.doLab,"再招十次",18)
    ui.setLabelString(self.tenItems.doLab,gameConfig.strings:string_common("recruit",4),18)
    self.tenItems.doButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        UIRequest({type = 1403, pos = self.tendata.pos, method = 2, goldType = self.typeTen})
    end, CCControlEventTouchUpInside)
    self.tenItems.doButton:setSwallowsTouch(true)
    self.tenItems.doButton:setTouchPriority(self.touchPriority-1)

    -- ui.setLabelString(self.tenItems.generalButtontext,"确 定",18)
    ui.setLabelString(self.tenItems.generalButtontext,gameConfig.strings:string_common("recruit",5),18)
    self.tenItems.generalButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("recruit")
    end, CCControlEventTouchUpInside)
    self.tenItems.generalButton:setSwallowsTouch(true)
    self.tenItems.generalButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.tenItems.sharetext,nil,18)
    self.tenItems.share:addHandleOfControlEvent(function()
        --todo share
    end, CCControlEventTouchUpInside)
    self.tenItems.share:setSwallowsTouch(true)
    self.tenItems.share:setTouchPriority(self.touchPriority-1)

    self.tenItems.checknode:setPositionX(gameConfig:checkBuildOpen(153) and 0 or -230)
    self.tenItems.donode:setPositionX(gameConfig:checkBuildOpen(153) and 330 or 230)


    --封神招募10连
    if self.tendata.pos == 4 then
        self.tenItems.shareNode:setPositionX(9999)
        self.tenItems.checknode:setPositionX(230)
        self.tenItems.donode:setPositionX(-230)
        self.tenItems.propNode:setVisible(false)

        self.tenItems.doZhao:setVisible(false)
        self.tenItems.doYuanbao:setVisible(true)
        setSpriteFrameByName(self.tenItems.doYuanbao, "obj_s_gold")
        self.tenItems.doYuanbao:setScale(1)

        local refreshTime = self.RecruitTempData.refreshTime
        local refresh_price = gamedata.config.buycount_price[tostring(refreshTime + 1)] and gamedata.config.buycount_price[tostring(refreshTime + 1)].modify_price or gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].modify_price

        self.tenItems.doNum:setString(refresh_price)

        if GameScene.roleinfo.gold < refresh_price then
            ui.setLabelString(self.tenItems.doNum,nil,47)
        else
            ui.setLabelString(self.tenItems.doNum,nil,14)
        end

        self.tenItems.doLab4:setVisible(true)

        self.tenItems.doLab4:setString(gameConfig.strings:string_common("recruit",11))

        ui.setLabelString(self.tenItems.doLab,gameConfig.strings:string_common("recruit",8),18)
        self.tenItems.doButton:addHandleOfControlEvent(function()
            gameTouch:clickprofbytime(0.5)

            local refreshTime = self.RecruitTempData.refreshTime
            local refresh_price = gamedata.config.buycount_price[tostring(refreshTime + 1)] and gamedata.config.buycount_price[tostring(refreshTime + 1)].modify_price or gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].modify_price

            if GameScene.roleinfo.gold < refresh_price then
                runGamePrompt({msg = gameConfig.strings:string_common("recruit",14)})
            else
                gameWindows:openWindow("confirm",{msg = "是否花费"..refresh_price.."元宝更换奖励？"},function (  )
                    UIRequest({type = 7112})
                end)
            end
            
        end, CCControlEventTouchUpInside)
        self.tenItems.doButton:setSwallowsTouch(true)
        self.tenItems.doButton:setTouchPriority(self.touchPriority-1)

        ui.setLabelString(self.tenItems.generalButtontext,gameConfig.strings:string_common("recruit",9),18)
        self.tenItems.generalButton:addHandleOfControlEvent(function()
            
            gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("recruit",10)},function (  )
                UIRequest({type = 7113})
            end)

        end, CCControlEventTouchUpInside)
        self.tenItems.generalButton:setSwallowsTouch(true)
        self.tenItems.generalButton:setTouchPriority(self.touchPriority-1)

    end

    local ccb,item = CCBReaderLoad("UIEffect/guanxing/liuxing.ccbi",nil, true, "liuxing")
    self.tenCCB:addChild(ccb)
    self.tenCCB:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
        self.loadindex = 0
        self:loadOneOfTen()

        if self.tendata.pos == 4 then
            local refreshTime = self.RecruitTempData.refreshTime
            local refresh_price = gamedata.config.buycount_price[tostring(refreshTime + 1)] and gamedata.config.buycount_price[tostring(refreshTime + 1)].modify_price or gamedata.config.buycount_price[tostring(table.getTableLength(gamedata.config.buycount_price))].modify_price
            if GameScene.roleinfo.gold < refresh_price then
                ui.setLabelString(self.tenItems.doNum,nil,47)
            else
                ui.setLabelString(self.tenItems.doNum,nil,14)
            end
        end
    end)))
    local animationManager = getAnimationManager(item)
    animationManager:setAnimationCompletedCallback(function()
   
    end)
    animationManager:runAnimationsForSequenceNamed("liuxing")


    --
    if gamedata.config:getConfigByName("build")[tostring(354)] and gamedata.config:getConfigByName("build")[tostring(354)].switch == 1 then
        if self.tenItems.gambling1 and self.tendata.pos > 1 then
            -- self.tenItems.gambling1:setVisible(true)
            -- local gs = ""
            -- if gamedata.config:getConfigByName("gambling") and gamedata.config:getConfigByName("gambling")[tostring(self.tendata.pos-1)] then
            --     local reward = ui.getIDandNUMs(gamedata.config:getConfigByName("gambling")[tostring(self.tendata.pos-1)].reward1)
            --     local name = ui.IDconfig(reward[1].cid).name
            --     gs = "恭喜获得"..name.."x"..(reward[1].num*10)
            -- end
            -- ui.setLabelString(self.tenItems.gambling1,gs,18)
        end
    end

end

function recruit.reloadone(self)
    self.oneItems.buttonnode:setVisible(false)
    gameTouch:clickprofbytime(2)
    gamedata.music:PlayOptSound("zm1")

    local configdata = ui.IDconfig(self.onedata["gets"]["1"].cid)

--    if configdata.staffType == "general" then
--        self.oneItems.has:setString('')
--    elseif configdata.staffType == "general_fragment" then
--        self.oneItems.has:setString(gameConfig.strings:PerNum(tostring(self.onedata["gets"]["1"].num or 0)))
--    end

    if configdata.staffType == "general" then
        self.oneItems.has:setVisible(true)
        self.oneItems.fragmentNode:setVisible(false)
        if self.onedata.reward and next(self.onedata.reward) then
            for k,v in pairs(self.onedata.reward) do
                if v.cid == self.onedata["gets"]["1"].cid then
                    self.oneItems.has:setVisible(false)
                end
                -- 显示自动锻造
                if tonumber(v.cid) == 20200 then
                    self.oneItems.autoTishi:setVisible(true)
                    self.hundanNum = self.hundanNum + v.num
                end
            end
        end
    else
        self.oneItems.has:setVisible(false)
        self.oneItems.fragmentNode:setVisible(true)
        ui.setLabelString(self.oneItems.fragmentNum,"x"..self.onedata["gets"]["1"].num,14)
    end

    self.oneItems["generalNode"]:removeAllChildrenWithCleanup(true)

    ui.setLabelString(self.oneItems.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1)
    local  ccb,item = CCBReaderLoad("UIEffect/zhaomu/zhaomu_"..configdata.quality..".ccbi",nil, true, "zhaomu_")
    ccb:setPosition(0,0)
    self.oneItems.effectnode:addChild(ccb)


    self.oneItems.generalNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.5), CCCallFunc:create(function()
        if configdata.generalid then
            if configdata.quality >=4 then
                local ccb,item = CCBReaderLoad("UIEffect/zhaomu/zhaomu_"..configdata.quality.."_effect.ccbi",nil, true, "zhaomu_effect")
                self.oneItems.generalNode:addChild(ccb)
            end
            local generalName = gamedata.config:getConfigByName("generalanimation")[tostring(gamedata.config:getConfigByName("general")[tostring(configdata.generalid)].animationid)].name
            local Gneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
            Gneral:setAnimation("stand",true,0)
            Gneral:setScale(2)
            Gneral:setPosition(0,0)
            local red = CCTintTo:create(0,0,0,0)
            local back = CCTintTo:create(0.5,255,255,255)
            Gneral:runAction(CCSequence:createWithTwoActions(red,back))
            self.oneItems["generalNode"]:addChild(Gneral)

            gamedata.music:PlayOptSound("zm2")

            self.oneItems.generalNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.5), CCCallFunc:create(function()
                self.oneItems.buttonnode:setVisible(true)
                if guide.controller then
                    guide.controller:setGuideLayerVisible(true)
                end
                if self.onedata.ext and next(self.onedata.ext) then
                    self:showExtReward(self.onedata.ext,"oneItems")
                end

            end)))
            if configdata.quality >=5 and configdata.staffType == "general" then
                local flag = false
                local ccb1,item1 = CCBReaderLoad("UIEffect/zhaomu/recruit_5_tishi", nil, true, "recruit_5_tishi")
                self.oneItems.tishiNode:addChild(ccb1)  
                local animationManager1 = getAnimationManager(item1)
                animationManager1:setAnimationCompletedCallback(function()              
                    ccb1:removeFromParentAndCleanup(true)
                end)
                item1.closeButton:addHandleOfControlEvent(function()
                    flag = true
                    ccb1:setVisible(false)
                    item1.closeButton:setTouchEnabled(false)
                    item1.closeButton:setSwallowsTouch(false)
                end, CCControlEventTouchUpInside)
                item1.closeButton:setSwallowsTouch(true)
                item1.closeButton:setTouchEnabled(true)
                item1.closeButton:setTouchPriority(self.touchPriority-1)  
                local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
                Gneral1:setAnimation("stand",true,0)
                Gneral1:setScale(1.5)
                Gneral1:setPosition(0,0)
                item1.general:addChild(Gneral1)
                ui.setLabelString(item1.name,configdata.name, configdata.quality~=0 and 2*configdata.quality-1 or 1) 
                animationManager1:runAnimationsForSequenceNamed("recruit_5_tishi")                 
            end
        end
    end)))
    --

    if configdata.actor and configdata.actor == "tank" then
        setSpriteFrameByName(self.oneItems.gtype, "obj_qian")
    else
        setSpriteFrameByName(self.oneItems.gtype, "obj_hou")
    end

    self.oneItems.closeButton:addHandleOfControlEvent(function()
        guide:setGuideProlayer(true)
        gameWindows:closeWindowDirect("recruit")
    end, CCControlEventTouchUpInside)
    self.oneItems.closeButton:setSwallowsTouch(true)
    self.oneItems.closeButton:setTouchPriority(self.touchPriority)

    self.oneItems.shareNode:setVisible(gameConfig:checkBuildOpen(153))
    self.oneItems.doNode:setVisible(self.onedata.opt ~= 2)

    if self.onedata.opt == 2 then
        self.oneItems.propNode:setVisible(false)
    else
        local config = gamedata.config:getConfigByName("recruit_basic")[tostring(self.onedata.pos)]

        self.oneItems.doYuanbao:setVisible(self.onedata.pos ~= 1)
        self.oneItems.doZhao:setVisible(self.onedata.pos == 1)
        self.oneItems.Zhaomuling:setVisible(self.onedata.pos == 1)
        self.oneItems.Yuanbao:setVisible(self.onedata.pos ~= 1)
        local _propnum = 0

        if self.typeOne == "gaojizhaomuling" then
            self.oneItems.doNum:setString(config.count)
            local _icon = ui.IDconfig(config.costid).icon

            setSpriteFrameByName(self.oneItems.doYuanbao, _icon)
            setSpriteFrameByName(self.oneItems.Yuanbao, _icon)

            if self.recruitdata.index == 3 then
                _propnum = self.onedata.generalrecruit[tostring(self.onedata.pos)].propnum
            elseif self.recruitdata.index == 4 then
                _propnum = self.onedata.generalrecruit[tostring(self.onedata.pos)].propnum
            else
                _propnum = self.onedata.gold
            end
            self.oneItems.doYuanbao:setScale(0.5)
            self.oneItems.Yuanbao:setScale(0.5)

            if _propnum < config.count then
                ui.setLabelString(self.oneItems.doNum,nil,47)
            else
                ui.setLabelString(self.oneItems.doNum,nil,14)
            end
        else
            self.oneItems.doNum:setString(config.count_god)
            local _icon = ui.IDconfig(config.costid_god).icon

            setSpriteFrameByName(self.oneItems.doYuanbao, _icon)
            setSpriteFrameByName(self.oneItems.Yuanbao, _icon)

            if self.recruitdata.index == 3 or self.recruitdata.index == 4 then
                _propnum = self.onedata.gold
            else
                _propnum = self.onedata.generalrecruit[tostring(self.onedata.pos)].propnum
            end
            
            self.oneItems.doYuanbao:setScale(0.5)
            self.oneItems.Yuanbao:setScale(0.5)

            if _propnum < config.count_god then
                ui.setLabelString(self.oneItems.doNum,nil,47)
            else
                ui.setLabelString(self.oneItems.doNum,nil,14)
            end
        end

        self.oneItems.propNum:setString(_propnum)
        
        if _propnum > 0 then
            self.oneItems.propNum:setColor(ccc3(254,254,237))
        else
            self.oneItems.propNum:setColor(ccc3(255,0,0))
        end
    end

    -- ui.setLabelString(self.oneItems.doLab,"再招一次",18)
    ui.setLabelString(self.oneItems.doLab,gameConfig.strings:string_common("recruit",6),18)
    self.oneItems.doButton:addHandleOfControlEvent(function()
        if self.onedata.opt == 2 then

        else
            gameTouch:clickprofbytime(0.5)
            UIRequest({type = 1403, pos = self.onedata.pos, method = 1, goldType = self.typeOne})
        end
    end, CCControlEventTouchUpInside)
    self.oneItems.doButton:setSwallowsTouch(true)
    self.oneItems.doButton:setTouchPriority(self.touchPriority-1)


    -- ui.setLabelString(self.oneItems.generalButtontext,"查 看",18)
    ui.setLabelString(self.oneItems.generalButtontext,gameConfig.strings:string_common("recruit",7),18)
    self.oneItems.generalButton:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(configdata.generalid)
    end, CCControlEventTouchUpInside)
    self.oneItems.generalButton:setSwallowsTouch(true)
    self.oneItems.generalButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.oneItems.sharetext,nil,18)
    self.oneItems.share:addHandleOfControlEvent(function()
        --todo share
    end, CCControlEventTouchUpInside)
    self.oneItems.share:setSwallowsTouch(true)
    self.oneItems.share:setTouchPriority(self.touchPriority-1)

    self.oneItems.shareNode:setPositionX(self.onedata.opt == 2 and -230 or -330)
    if gameConfig:checkBuildOpen(153) then
        self.oneItems.checknode:setPositionX(self.onedata.opt == 2 and 230 or 0)
    else
        self.oneItems.checknode:setPositionX(self.onedata.opt == 2 and 0 or -230)
    end
    self.oneItems.doNode:setPositionX(gameConfig:checkBuildOpen(153)  and 330 or 230)


    --
    if self.onedata.opt ~= 2 then
        if gamedata.config:getConfigByName("build")[tostring(354)] and gamedata.config:getConfigByName("build")[tostring(354)].switch == 1 then
            -- if self.oneItems.gambling1 and self.onedata.pos > 1 then
            --     self.oneItems.gambling1:setVisible(true)
            --     local gs = ""
            --     if gamedata.config:getConfigByName("gambling") and gamedata.config:getConfigByName("gambling")[tostring(self.onedata.pos-1)] then
            --         local reward = ui.getIDandNUMs(gamedata.config:getConfigByName("gambling")[tostring(self.onedata.pos-1)].reward1)
            --         local name = ui.IDconfig(reward[1].cid).name
            --         gs = "恭喜获得"..name.."x"..(reward[1].num)
            --     end
            --     ui.setLabelString(self.oneItems.gambling1,gs,18)
            -- end
        end
    end


end

function recruit.reloadyulan(self)

    self.yulanItems.closeButton:addHandleOfControlEvent(function()
        self:shiftType({type = "recruit",data = self.recruitdata})
    end, CCControlEventTouchUpInside)
    self.yulanItems.closeButton:setSwallowsTouch(true)
    self.yulanItems.closeButton:setTouchPriority(self.touchPriority)

    local data = self["yulandata_"..self.recruitdata.index]
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(900, 250)
        elseif fn == "cellAtIndex" then

            local CCB,item = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                for i=1,4 do
                    CCB[i],item[i] = CCBReaderLoad("icons/new_iconName2.ccbi", nil, true, "new_iconName2")
                end
                celldict[a2] = {CCB=CCB,item=item }
            else
                first = false

                CCB = celldict[a2].CCB
                item = celldict[a2].item
            end

            for i =1, 4 do
                local data1 = data[tostring(4*(a1) +i)] or data[(4*(a1) +i)]
                if data1 then
                    CCB[i]:setVisible(true)
                    ui.setNewIconName(item[i],{cid = data1.cid or data1.generalid})
                    -- 增加招募预览中角色详情预览
                    item[i].in_button:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        ui.setPopwindowByCid(data1.cid or data1.generalid)
                    end, CCControlEventTouchUpInside)
                    --item[i].in_button:setSwallowsTouch(true)
                    item[i].in_button:setTouchPriority(self.touchPriority)                    
                else
                    CCB[i]:setVisible(false)
                end

                CCB[i]:setPosition(200*(i-0.5)+50, 150)
                if first then
                    a2:addChild(CCB[i])
                end
            end

            r = a2
        elseif fn == "numberOfCells" then
            r = math.ceil(table.getTableLength(data)/4)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    local ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.yulanItems.listnode:getContentSize().width,
        viewheight = self.yulanItems.listnode:getContentSize().height,
        dire = 1
    })
    ListTableView:setTouchPriority(self.touchPriority)
    self.yulanItems.listnode:addChild(ListTableView)


    --
    if gamedata.config:getConfigByName("build")[tostring(354)] and gamedata.config:getConfigByName("build")[tostring(354)].switch == 1 then
        -- if self.recruitdata.index > 1 then
        --     ui.setLabelString(self.yulanItems.title,"赠送预览",18)
        -- end
    end

end



function recruit.close(self)
    if self.hundanNum > 0 then
        showRewardPopupWindow({{cid = 20200, num = self.hundanNum, order = 1}},nil,nil)
    end
    self.hundanNum = 0

    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    setTriggerGiftEnable(true)
    gameTouch:UnrigistFunc("begin","recruit")
    gameTouch:UnrigistFunc("end","recruit")
    if self.callback then
        self.callback()
    end
end

return recruit
