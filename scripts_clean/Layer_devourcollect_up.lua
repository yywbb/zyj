--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/3/10
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
-- pet3_illustrated

local devourcollectup = {
    resource = nil,
    rootNode = nil,
    rootItems = nil,

    petData = {},
    petFragment = {},

    xprop = {},
    beforecid = 0
}

function devourcollectup.init(self,parent,toppos,param)

    self.petData = param.petData
    self.petFragment = param.petFragmentData
    self.allPetsData = param.allPetsData
    self.rootNode,self.rootItems = CCBReaderLoad("mochong3/mochong_tujianup.ccbi", nil, true, "mochong_tujianup")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if self.rootItems.topnode then
        self.rootItems.topnode:setPositionY(toppos)
    end

   

    --
    -- self.rootItems.button_back:setTouchPriority(-103)
    -- self.rootItems.button_back:addHandleOfControlEvent(function()
    --     -- GameScene:shiftLayer("devil","up")
    --     local obj = {}
    --     obj.petsData = self.allPetsData;
    --     obj.petFragmentData = self.petFragment;
    --     GameScene:shiftLayer("devilcollect","up",obj)
    -- end, CCControlEventTouchUpInside)

    --
    self:reload()

end

function devourcollectup.refreshFunc(self,data)
    print("devourcollectup.refreshFunc")
    self:reload(data)
end

function devourcollectup.getMochongFragmentData(self,data)
    print("getMochongFragmentData===")
    printT(data)
    self.petFragment = data
end

function devourcollectup.reload(self,data)
    print("devourcollectup.reload")

    if data then
        self.petData = data
    end

    local nowlevel = self.petData.level
    local config = gamedata.config.pet3_attr[tostring(self.petData.cid)] or {}

    if self.beforecid==0 or self.beforecid ~= self.petData.cid then
        if self.rootItems.mochongNode then
            self.beforecid = self.petData.cid
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

    --
    local petconfig = gamedata.config.pet3_attr and gamedata.config.pet3_attr[tostring(self.petData.cid)] or {}
    local config = gamedata.config.pet3_illustrated and gamedata.config.pet3_illustrated[tostring(self.petData.cid)] or {}
    local maxlv = table.getTableLength(config)
    --
    ui.setLabelString(self.rootItems["propertynameLevel"],"等级:",13)
    ui.setLabelString(self.rootItems["propertyNumLevel"],self.petData.collectlevel,13)
    --
    for i = 1,3 do
        ui.setLabelString(self.rootItems["propertynameLabel"..i],(gameConfig.strings:string_common("attr_type",petconfig["0"]["attr"..i])..":"),13)
        local attrnum = 0
        if petconfig["0"]["method"..i] == "value" then
            attrnum = petconfig["0"]["init"..i] + config[tostring(self.petData.collectlevel)]["attr"..i]
        else
            attrnum = (tonumber(petconfig["0"]["init"..i] + config[tostring(self.petData.collectlevel)]["attr"..i])*100).."%"
        end
        ui.setLabelString(self.rootItems["propertyNumLabel"..i],attrnum,13)
    end
    --
    if self.petData.collectlevel and self.petData.collectlevel >= maxlv then
        self.rootItems.next_attrNode:setVisible(false)
        self.rootItems.attrNode:setPositionX(0)
        self.rootItems.upNode:setVisible(false)
        self.rootItems.maxDescText:setVisible(false)
        self.rootItems.maxDesc:setVisible(true)
    else
        self.rootItems.next_attrNode:setVisible(true)
        self.rootItems.attrNode:setPositionX(-270)
        self.rootItems.upNode:setVisible(true)
        self.rootItems.maxDescText:setVisible(false)
        self.rootItems.maxDesc:setVisible(false)
        --
        ui.setLabelString(self.rootItems["next_propertynameLevel"],"等级:",13)
        ui.setLabelString(self.rootItems["next_propertyNumLevel"],self.petData.collectlevel+1,13)
        --
        for i = 1,3 do
            ui.setLabelString(self.rootItems["next_propertynameLabel"..i],(gameConfig.strings:string_common("attr_type",petconfig["0"]["attr"..i])..":"),13)
            local attrnum = 0
            if petconfig["0"]["method"..i] == "value" then
                attrnum = petconfig["0"]["init"..i] + config[tostring(self.petData.collectlevel+1)]["attr"..i]
            else
                attrnum = (tonumber(petconfig["0"]["init"..i] + config[tostring(self.petData.collectlevel+1)]["attr"..i])*100).."%"
            end
            ui.setLabelString(self.rootItems["next_propertyNumLabel"..i],attrnum,13)
        end
        --
        ui.setLabelString(self.rootItems.xnum,0,13)
        local upneed = ui.getIDandNUMs(config[tostring(self.petData.collectlevel)].cost)
        local suipiancid = 0 
        self.xprop = {}
        self.neednum = 0
        for k,v in pairs(upneed) do
            if v.cid == 1000 then
                ui.setLabelString(self.rootItems.xnum,v.num,v.num > GameScene.roleinfo.coin and 24 or 13)
            else
                suipiancid = v.cid
                self.neednum = v.num
                self.xprop = v
            end
        end
        if next(self.xprop) then
            self.rootItems.xprop:setVisible(true)
            ui.setNewIcon(self.rootItems,{cid=suipiancid,num=(self.petFragment[tostring(suipiancid)] and self.petFragment[tostring(suipiancid)].num or 0).."/"..self.neednum})
            self.rootItems["i_button"]:setTouchPriority(-103)
            self.rootItems["i_button"]:addHandleOfControlEvent(function()
                gameWindows:openWindow("dropTips",{cid = suipiancid, num = (self.petFragment[tostring(suipiancid)] and self.petFragment[tostring(suipiancid)].num or 0)},nil)
            end, CCControlEventTouchUpInside)
            if self.petFragment[tostring(suipiancid)] then
                if self.petFragment[tostring(suipiancid)].num >= self.neednum then
                    ui.setLabelString(self.rootItems.i_num,nil,13)
                else
                    ui.setLabelString(self.rootItems.i_num,nil,24)
                    -- hongse
                end
            end

            UIRequest({type = 12001, order = 10621, cids = {self.xprop.cid}})
        else
            self.rootItems.xprop:setVisible(false)
        end
        --
        local needlv = 0
        local needlv2 = 0
        if config[tostring(self.petData.collectlevel)].cond1 and config[tostring(self.petData.collectlevel)].cond1 > 0 then
            needlv = config[tostring(self.petData.collectlevel)].cond1
        end
        if config[tostring(self.petData.collectlevel)].cond2 and config[tostring(self.petData.collectlevel)].cond2 > 0 then
            needlv2 = config[tostring(self.petData.collectlevel)].cond2
        end

        if needlv > 0 then
            ui.setLabelString(self.rootItems.needlv,"队伍等级："..GameScene.roleinfo.level.."/"..needlv,GameScene.roleinfo.level >= needlv and 22 or 24)
        else
            ui.setLabelString(self.rootItems.needlv,"",13)
        end

        if needlv2 > 0 then
            ui.setLabelString(self.rootItems.needlv2,"魔宠进阶到：",self.petData.level >= needlv2 and 22 or 24)
            ui.setLabelString(self.rootItems.needlv2_name,petconfig[tostring(needlv2)].name,((petconfig[tostring(needlv2)].quality and petconfig[tostring(needlv2)].quality ~= 0) and petconfig[tostring(needlv2)].quality or 1)*2)
        else
            ui.setLabelString(self.rootItems.needlv2,"",13)
            ui.setLabelString(self.rootItems.needlv2_name,"",13)
        end
        --
        ui.setLabelString(self.rootItems.advanceSpendText,nil,13)
        ui.setLabelString(self.rootItems.upText,nil,19)
        self.rootItems.upBtn:setTouchPriority(-103)
        self.rootItems.upBtn:addHandleOfControlEvent(function()
            if needlv > 0 and GameScene.roleinfo.level < needlv then
                runGamePrompt({msg = "队伍等级不足"})
            elseif needlv2 > 0 and self.petData.level < needlv2 then
                runGamePrompt({msg = "魔宠进阶等级不足"})
            else
                UIRequest({type = 1062,iid = self.petData.iid,need = upneed})
            end
        end, CCControlEventTouchUpInside)
        --

    end
end

function devourcollectup.setPropsData(self,pdata)
    print("setPropsData")
    for k,v in pairs(pdata) do
        if next(self.xprop) and tonumber(k) == tonumber(self.xprop.cid) then
           if v >= self.xprop.num then
               print("labe: "..v.."/"..self.xprop.num)
               ui.setLabelString(self.rootItems.i_num,v.."/"..self.xprop.num,13)
           else
               ui.setLabelString(self.rootItems.i_num,v.."/"..self.xprop.num,24)
           end
        end
    end
end

function devourcollectup.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootItems = nil
    self.rootNode = nil

    self.petData = {}
    self.petFragment = {}
    self.xprop = {}
    self.beforecid = 0
    self.allPetsData = {}
end


return devourcollectup