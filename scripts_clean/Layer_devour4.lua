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

    TableView = nil,

    data = {},
    fragment = {},
    selectData = {},
    showData = {},
    generalData = {},
    fragmentData = {},

    index = 0,

}

function devour.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("mochong2/mochong2", nil, true, "devour")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    if self.rootItems.topnode then
        self.rootItems.topnode:setPositionY(toppos)
    end


    UIRequest({type = 1040})

end

function devour.clear(self)

    self.index = 0
    self.data = {}
    self.fragment = {}
    self.selectData = {}
    self.showData = {}

    self.generalData = {}
    self.fragmentData = {}

    self.TableView = nil
    self.rootItems = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

end


function devour.reload(self,data)

    if self.index > 0 and self.data.pets and self.data.pets[self.index] then
        for k,v in pairs(data.petsdata.pets) do
            if v.cid == self.data.pets[self.index].cid then
                if self.data.pets[self.index].level2 < v.level2 then
                    self:checkuplv2()
                end
            end
        end
    end
    --
    self.data =  {
        iid = 0,
        pets = {},
    }
    for k,v in pairs(gamedata.config.pet2_attr) do
        local pet = { iid = 0, cid = v["0"].id, exp = 0, level1 = 1, level2 = 0,}
        for k,v in pairs(data.petsdata.pets) do
            if v.cid == pet.cid then
                pet.iid = v.iid or 0
                pet.exp = v.exp or 0
                pet.level1 = v.level1 or 0
                pet.level2 = v.level2 or 0
            end
        end
        table.insert(self.data.pets, pet)
    end
    self.data.iid = data.petsdata.iid or 0
    local sortById = function(a,b) return a.cid < b.cid end
    table.sort(self.data.pets, sortById)


    --

    if self.index == 0 then
        self.index = 1
        for k,v in pairs(self.data.pets) do
            if v.iid == self.data.iid then
                self.index = tonumber(k)
            end
        end
    end

    self:setPet()

    self.rootItems.leftButton:setTouchPriority(-103)
    self.rootItems.leftButton:addHandleOfControlEvent(function()
        if self.index > 1 then
            self.index = self.index-1
            self:setPet()
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.rightButton:setTouchPriority(-103)
    self.rootItems.rightButton:addHandleOfControlEvent(function()
        if self.index < table.getTableLength(self.data.pets) then
            self.index = self.index+1
            self:setPet()
        end
    end, CCControlEventTouchUpInside)
    --

    --
    local function ccTouchBegan(x, y)
        if ui.isTouched(self.rootItems.touchLayer,x,y) then
            self.touchX = x
            self.touchY = y
            return true
        end
    end

    local function ccTouchMoved(x, y)

    end

    local function ccTouchEnded(x, y)
        if x-self.touchX > 20 then
            gameTouch:clickprofbytime(0.5)
            if self.index < table.getTableLength(self.data.pets) then
                self.index = self.index+1
                self:setPet()
            end
        elseif self.touchX-x > 20 then
            gameTouch:clickprofbytime(0.5)
            if self.index > 1 then
                self.index = self.index-1
                self:setPet()
            end
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

    self.rootItems.touchLayer:registerScriptTouchHandler(onTouch, false, -102, false)
    self.rootItems.touchLayer:setTouchPriority(-102)
    self.rootItems.touchLayer:setTouchEnabled(true)

    --

end

function devour.setPet(self,index)

    if self.index >= table.getTableLength(self.data.pets) then
        self.rootItems.rightsprite:setVisible(false)
    else
        self.rootItems.rightsprite:setVisible(true)
    end
    if self.index <= 1 then
        self.rootItems.leftsprite:setVisible(false)
    else
        self.rootItems.leftsprite:setVisible(true)
    end

    local config = gamedata.config.pet2_attr[tostring(self.data.pets[self.index].cid)] or {}
    local skillconfig = gamedata.config.skill or {}
    local breakskillconfig = gamedata.config.breakskill or {}
    local fragmentconfig =  gamedata.config.pet2_fragment or {}

    self.rootItems.battleButton:setTouchPriority(-103)
    self.rootItems.battleButton:addHandleOfControlEvent(function()
        print("battle")
        if self.data.pets[self.index].iid ~= self.data.iid then
            UIRequest({type = 1043, iid = self.data.pets[self.index].iid })
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.viewButton:setTouchPriority(-103)
    self.rootItems.viewButton:addHandleOfControlEvent(function()
        print("view")
        gameWindows:openWindow("devourpreview",self.data.pets[self.index])
    end, CCControlEventTouchUpInside)

    self.rootItems.generalButton:setTouchPriority(-103)
    self.rootItems.generalButton:addHandleOfControlEvent(function()
        print("generalButton")
        gameWindows:openWindow("devourinfo",self.data.pets[self.index])
    end, CCControlEventTouchUpInside)

    local lv2str = {
        ["0"] = "零",
        ["1"] = "一",
        ["2"] = "二",
        ["3"] = "三",
        ["4"] = "四",
        ["5"] = "五",
        ["6"] = "六",
        ["7"] = "七",
        ["8"] = "八",
        ["9"] = "九",
        ["10"] = "十",
    }
    self.rootItems.name:setString((config[tostring(self.data.pets[self.index].level2)].name.." ("..lv2str[tostring(self.data.pets[self.index].level2)].."阶)") or "")
    ui.setLabelString(self.rootItems.name,nil, config[tostring(self.data.pets[self.index].level2)].quality and 2*config[tostring(self.data.pets[self.index].level2)].quality-1 or 1)


    if self.rootItems.generalNode then
        local mowang = gamedata.config.generalanimation[tostring(config[tostring(self.data.pets[self.index].level2)].animationid)].name or "mowang_1"
        self.rootItems.generalNode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = CCSkeletonAnimation:create(mowang.."/"..mowang..".json",mowang.."/"..mowang..".atlas",1)
        if self.Gneral1 then
            self.Gneral1:setAnimation("stand",true,0)
            self.Gneral1:setScale(1.8*(config[tostring(self.data.pets[self.index].level2)].scale or 1))
            self.Gneral1:setPosition(0,0)
            self.rootItems.generalNode:addChild(self.Gneral1)

        end
    end


    --
    for i = 0,self.data.pets[self.index].level2 do
        if config[tostring(i)].skillid and config[tostring(i)].skillid > 0 then
            self.rootItems.zdskill_name:setString(skillconfig[tostring(config[tostring(i)].skillid)]["name"]..": ")
            self.rootItems.zdskill_desc:setString(skillconfig[tostring(config[tostring(i)].skillid)]["effect-desc"])
        end

    end
    --

    if self.data.pets[self.index].iid <= 0 then
        self.rootItems.getpetNode:setVisible(true)
        self.rootItems.level2upNode:setVisible(false)
    else
        self.rootItems.getpetNode:setVisible(false)
        self.rootItems.level2upNode:setVisible(true)
    end
    --
    if self.data.pets[self.index].iid <= 0 then
        self.rootItems.battleNode:setVisible(false)
    elseif self.data.pets[self.index].iid == self.data.iid then
        self.rootItems.battleNode:setVisible(true)
        -- self.rootItems.battleLab:setString("出战中")
        self.rootItems.battleLab:setString(gameConfig.strings:string_common("layer_devour",5))
        ui.setLabelString(self.rootItems.battleLab,nil,18)
        ui.addGray("CCControlButton",self.rootItems.battleButton)
        ui.addGray("CCLabelTTF",self.rootItems.battleLab)
    else
        self.rootItems.battleNode:setVisible(true)
        -- self.rootItems.battleLab:setString("出 战")
        self.rootItems.battleLab:setString(gameConfig.strings:string_common("layer_devour",6))
        ui.setLabelString(self.rootItems.battleLab,nil,18)
        ui.removeGray("CCControlButton",self.rootItems.battleButton)
        ui.removeGray("CCLabelTTF",self.rootItems.battleLab)
    end
    --
    --level2upNode

    local xids = {}
    local xindex = 1

    --if config[tostring(self.data.pets[self.index].level2)].consume and config[tostring(self.data.pets[self.index].level2)].consume ~= "" and config[tostring(self.data.pets[self.index].level2)].consume ~= "0" and config[tostring(self.data.pets[self.index].level2)].consume ~= 0 then
    if config[tostring(self.data.pets[self.index].level2+1)] then
        xids = ui.getIDandNUMs(config[tostring(self.data.pets[self.index].level2)].consume)
        if self.rootItems.level2upXNode then
            self.rootItems.level2upXNode:setVisible(true)
        end
        self.rootItems.needlevel:setString("需要等级:"..GameScene.roleinfo.level.."/"..config[tostring(self.data.pets[self.index].level2)].level)
        ui.setLabelString(self.rootItems.needlevel,nil,GameScene.roleinfo.level<config[tostring(self.data.pets[self.index].level2)].level and 24 or 22)
    else
        self.rootItems.xcoin:setString("")
        ui.setLabelString(self.rootItems.xcoin,nil,14)
        if self.rootItems.level2upXNode then
            self.rootItems.level2upXNode:setVisible(false)
        end
    end
    self.xupprops = {}
    local xpropcids = {}
    ui.removeGray("CCControlButton",self.rootItems.upButton)
    ui.removeGray("CCLabelTTF",self.rootItems.upLab)
    for k,v in pairs(xids) do
        if v.cid == 1000 then
            self.rootItems.xcoin:setString(v.num)
            if GameScene.roleinfo.coin < v.num then
                ui.setLabelString(self.rootItems.xcoin,nil,47)
                ui.addGray("CCControlButton",self.rootItems.upButton)
                ui.addGray("CCLabelTTF",self.rootItems.upLab)
            else
                ui.setLabelString(self.rootItems.xcoin,nil,14)
            end
        else
            self.rootItems["upxnode"..xindex]:setVisible(true)
            ui.setNewIcon(self.rootItems,{cid = v.cid, num = v.num}, xindex)
            table.insert(self.xupprops,{index = xindex,cid = v.cid,num = v.num})
            table.insert(xpropcids,v.cid)
            self.rootItems["i_button_"..xindex]:setTouchPriority(-103)
            self.rootItems["i_button_"..xindex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(v.cid)
            end,CCControlEventTouchUpInside)
            xindex = 2
        end
    end
    UIRequest({type = 12001, order = 18001, cids = xpropcids})

    ui.setLabelString(self.rootItems.upLab,nil,19)
    self.rootItems.upButton:setTouchPriority(-103)
    self.rootItems.upButton:addHandleOfControlEvent(function()
        print("up")
        if GameScene.roleinfo.level+0 < config[tostring(self.data.pets[self.index].level2)].level+0 then
            runGamePrompt({msg = "等级不足"})
        else
            UIRequest({type = 1042, iid = self.data.pets[self.index].iid, xids = xids or {}})
        end
    end, CCControlEventTouchUpInside)

    --
    if GameScene.roleinfo.level+0 < config[tostring(self.data.pets[self.index].level2)].level+0 then
        ui.addGray("CCControlButton",self.rootItems.upButton)
        ui.addGray("CCLabelTTF",self.rootItems.upLab)
    end
    --
    UIRequest({type = 1044})

end

function devour.setGetPetNode(self,data)
    --getpetNode

    self.fragment = data.fragment or {}
    --

    local config = gamedata.config.pet2_attr[tostring(self.data.pets[self.index].cid)] or {}
    local fragmentconfig =  gamedata.config.pet2_fragment or {}

    ui.setNewIcon(self.rootItems,{cid = config["0"].debris, num = (self.fragment[tostring(config["0"].debris)] and self.fragment[tostring(config["0"].debris)].num or 0).."/"..fragmentconfig[tostring(config["0"].debris)].number},0)

    self.rootItems.gotoButton:setTouchPriority(-103)
    self.rootItems.gotoButton:addHandleOfControlEvent(function()
        print("goto")
        gameWindows:openWindow("dropTips",{cid = config["0"].debris, num = self.fragment[tostring(config["0"].debris)] and self.fragment[tostring(config["0"].debris)].num or 0 },nil)
    --if fragmentconfig[tostring(config["0"].debris)].systemid and fragmentconfig[tostring(config["0"].debris)].systemid > 0 then
    --    GameScene:shiftLayerById(fragmentconfig[tostring(config["0"].debris)].systemid,fragmentconfig[tostring(config["0"].debris)].param)
    --end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.getLab,nil,18)
    self.rootItems.getButton:setTouchPriority(-103)
    self.rootItems.getButton:addHandleOfControlEvent(function()
        print("get")
        UIRequest({type = 1045, cid = self.data.pets[self.index].cid })
    end, CCControlEventTouchUpInside)

    if self.fragment[tostring(config["0"].debris)] and self.fragment[tostring(config["0"].debris)].num >= fragmentconfig[tostring(config["0"].debris)].number then
        self.rootItems.gotoNode:setVisible(false)
        self.rootItems.getNode:setVisible(true)
    else
        self.rootItems.gotoNode:setVisible(true)
        self.rootItems.getNode:setVisible(false)
    end
    --
end



function devour.checkuplv2(self,data)

    self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
    local qianghuaNode1,qianghuaItems1 = CCBReaderLoad("UIEffect/mochong/mochongjinjie", nil, true, "mochongjinjie")
    qianghuaNode1:setPosition(0,0)
    self.rootItems.effectNode:addChild(qianghuaNode1)
    self.rootItems.effectNode:setScale(1)
    local animationManager1 = getAnimationManager(qianghuaItems1)
    animationManager1:setAnimationCompletedCallback(function()
        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        gameWindows:openWindow("devourup",self.data.pets[self.index])
    end)
    animationManager1:runAnimationsForSequenceNamed("mochongjinjie")
    gamedata.music:PlayOptSound("xlshjhtp")

end


function devour.setPropNum(self,props)
    for k,v in pairs(self.xupprops) do
        ui.setNewIcon(self.rootItems,{cid = v.cid, num = (props[tostring(v.cid)] or 0).."/"..v.num}, v.index)
        if (props[tostring(v.cid)] or 0) < v.num then
            ui.setLabelString(self.rootItems["i_num"..(v.index==0 and "" or "_"..(v.index))],nil,24)
            ui.addGray("CCControlButton",self.rootItems.upButton)
            ui.addGray("CCLabelTTF",self.rootItems.upLab)
        else
            ui.setLabelString(self.rootItems["i_num"..(v.index==0 and "" or "_"..(v.index))],nil,22)
        end
    end
end

return devour