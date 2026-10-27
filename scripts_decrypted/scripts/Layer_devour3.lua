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
    iseat = false,
}

function devour.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("mochong/mochong", nil, true, "devour")
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
    self.iseat = false
    self.generalData = {}
    self.fragmentData = {}

    self.TableView = nil
    self.rootItems = nil

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)

end



function devour.createList(self)
    print("createList")
    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(200, 200)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = {},{}
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_Icon_chong.ccbi", nil, true, "Icon")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
                    --
                    local celldata = self.showData[a1+1] or {}
                    if not celldata.iid then
                        ui.setNewIcon(ccbDocumentControler,{cid = celldata.cid, num = celldata.num, staffType = "general_fragment"})
                    else
                        ui.setNewIcon(ccbDocumentControler,{cid = celldata.cid, num = celldata.num})
                    end
                    ccbDocumentControler["i_select"]:setVisible(false)
                    if self.selectData[celldata.cid..(celldata.iid or "")] then
                        ccbDocumentControler["i_select"]:setVisible(true)
                        ccbDocumentControler["i_k_quality"]:setColor(ccc3(150,150,150))
                        ccbDocumentControler["i_quality"]:setColor(ccc3(150,150,150))
                        ccbDocumentControler["i_icon"]:setColor(ccc3(150,150,150))
                    else
                        ccbDocumentControler["i_k_quality"]:setColor(ccc3(255,255,255))
                        ccbDocumentControler["i_quality"]:setColor(ccc3(255,255,255))
                        ccbDocumentControler["i_icon"]:setColor(ccc3(255,255,255))
                    end

                    if ccbDocumentControler.i_button then
                        ccbDocumentControler.i_button:setTouchPriority(-104)
                        ccbDocumentControler.i_button:addHandleOfControlEvent(function()
                            if gameTouch.isScrollling then return end
                            if not self.selectData[celldata.cid..(celldata.iid or "")] then
                                self.selectData[celldata.cid..(celldata.iid or "")] = celldata
                                ccbDocumentControler["i_select"]:setVisible(true)
                                ccbDocumentControler["i_k_quality"]:setColor(ccc3(150,150,150))
                                ccbDocumentControler["i_quality"]:setColor(ccc3(150,150,150))
                                ccbDocumentControler["i_icon"]:setColor(ccc3(150,150,150))
                            else
                                self.selectData[celldata.cid..(celldata.iid or "")] = nil
                                ccbDocumentControler["i_select"]:setVisible(false)
                                ccbDocumentControler["i_k_quality"]:setColor(ccc3(255,255,255))
                                ccbDocumentControler["i_quality"]:setColor(ccc3(255,255,255))
                                ccbDocumentControler["i_icon"]:setColor(ccc3(255,255,255))
                                --
                                self.selectall = false
                                self.rootItems.allselect:setVisible(false)
                            end
                        end, CCControlEventTouchUpInside)
                    end
                    --

                cellCCB:setPosition(100,100)

                if first then
                    a2:addChild(cellCCB)
                end


            r = a2
        elseif fn == "numberOfCells" then
            r =  table.getTableLength(self.showData)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            --gameTouch.isScrollling = true
        end
        return r
    end)

    self.TableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listnode:getContentSize().width,
        viewheight = self.rootItems.listnode:getContentSize().height,
        dire = 0,
    })
    self.TableView:setTouchPriority(-102)
    self.rootItems.listnode:addChild(self.TableView)
end

function devour.reload(self,data)

    if self.index > 0 and self.data.pets and self.data.pets[self.index] then
        for k,v in pairs(data.petsdata.pets) do
            if v.cid == self.data.pets[self.index].cid then
                if self.data.pets[self.index].level1 < v.level1 then
                    self:checkuplv1()
                elseif self.data.pets[self.index].level2 < v.level2 then
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
    if self.iseat then
        self.iseat = false
        self:eatEffect()
    end
    --
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
    --

    UIRequest({type = 18001})
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

    self.rootItems.power:setString("")

    self.rootItems.atk:setString(config[tostring(self.data.pets[self.index].level2)].atk + config[tostring(self.data.pets[self.index].level2)].atk_grow*(self.data.pets[self.index].level1-(self.data.pets[self.index].level2 > 0 and config[tostring(self.data.pets[self.index].level2-1)].level or 1)))
    self.rootItems.speed:setString(config[tostring(self.data.pets[self.index].level2)].speed )
    self.rootItems.anger:setString(config[tostring(self.data.pets[self.index].level2)].ap + config[tostring(self.data.pets[self.index].level2)].ap_grow*(self.data.pets[self.index].level1-(self.data.pets[self.index].level2 > 0 and config[tostring(self.data.pets[self.index].level2-1)].level or 1)))
    self.rootItems.back:setString(config[tostring(self.data.pets[self.index].level2)].ap_bout + config[tostring(self.data.pets[self.index].level2)].ap_bout_grow*(self.data.pets[self.index].level1-(self.data.pets[self.index].level2 > 0 and config[tostring(self.data.pets[self.index].level2-1)].level or 1)))

    --
    if self.data.pets[self.index].level1 >= config[tostring(self.data.pets[self.index].level2)].level then
        -- self.rootItems.type_atk_up:setString("下一阶")
        -- self.rootItems.type_speed_up:setString("下一阶")
        -- self.rootItems.type_anger_up:setString("下一阶")
        -- self.rootItems.type_back_up:setString("下一阶")
        self.rootItems.type_atk_up:setString(gameConfig.strings:string_common("layer_devour",1))
        self.rootItems.type_speed_up:setString(gameConfig.strings:string_common("layer_devour",1))
        self.rootItems.type_anger_up:setString(gameConfig.strings:string_common("layer_devour",1))
        self.rootItems.type_back_up:setString(gameConfig.strings:string_common("layer_devour",1))
        self.rootItems.atk_up:setString("+"..(config[tostring(self.data.pets[self.index].level2)].atk_up or 0))
        self.rootItems.speed_up:setString("+"..(config[tostring(self.data.pets[self.index].level2)].speed_up or 0))
        self.rootItems.anger_up:setString("+"..(config[tostring(self.data.pets[self.index].level2)].ap_up or 0))
        self.rootItems.back_up:setString("+"..(config[tostring(self.data.pets[self.index].level2)].ap_boutup or 0))
    else
        -- self.rootItems.type_atk_up:setString("下一级")
        -- self.rootItems.type_speed_up:setString("下一级")
        -- self.rootItems.type_anger_up:setString("下一级")
        -- self.rootItems.type_back_up:setString("下一级")
        self.rootItems.type_atk_up:setString(gameConfig.strings:string_common("layer_devour",2))
        self.rootItems.type_speed_up:setString(gameConfig.strings:string_common("layer_devour",2))
        self.rootItems.type_anger_up:setString(gameConfig.strings:string_common("layer_devour",2))
        self.rootItems.type_back_up:setString(gameConfig.strings:string_common("layer_devour",2))
        self.rootItems.atk_up:setString("+"..(config[tostring(self.data.pets[self.index].level2)].atk_grow or 0))
        self.rootItems.speed_up:setString("+"..(config[tostring(self.data.pets[self.index].level2)].speed_grow or 0))
        self.rootItems.anger_up:setString("+"..(config[tostring(self.data.pets[self.index].level2)].ap_grow or 0))
        self.rootItems.back_up:setString("+"..(config[tostring(self.data.pets[self.index].level2)].ap_bout_grow or 0))
    end
    --

    if self.rootItems.generalNode then
        local mowang = gamedata.config.generalanimation[tostring(config[tostring(self.data.pets[self.index].level2)].animationid)].name or "mowang_1"
        self.rootItems.generalNode:removeAllChildrenWithCleanup(true)
        self.Gneral1 = CCSkeletonAnimation:create(mowang.."/"..mowang..".json",mowang.."/"..mowang..".atlas",1)
        if self.Gneral1 then
            self.Gneral1:setAnimation("stand",true,0)
            self.Gneral1:setScale(1.8)
            self.Gneral1:setPosition(0,0)
            self.rootItems.generalNode:addChild(self.Gneral1)

        end
    end

    --skill
    local breakup = {
        q_atk = 0,
        h_atk = 0,
        q_def = 0,
        h_def = 0,
        q_hp = 0,
        h_hp = 0,
    }

    for i = 0,self.data.pets[self.index].level2 do
        if config[tostring(i)].skillid and config[tostring(i)].skillid > 0 then
            self.rootItems.zdskill_desc:setString(skillconfig[tostring(config[tostring(i)].skillid)].desc)
        end

        if config[tostring(i)].breakskillid and config[tostring(i)].breakskillid > 0 then
           if breakskillconfig[tostring(config[tostring(i)].breakskillid)].target == "6" then
              if breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] then
                  breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] = breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] + (breakskillconfig[tostring(config[tostring(i)].breakskillid)].value or 0)
              end
           elseif breakskillconfig[tostring(config[tostring(i)].breakskillid)].target == "7" then
               if breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] then
                   breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] = breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] + (breakskillconfig[tostring(config[tostring(i)].breakskillid)].value or 0)
               end
           elseif breakskillconfig[tostring(config[tostring(i)].breakskillid)].target == "1" then
               if breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] then
                   breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] = breakup["q_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] + (breakskillconfig[tostring(config[tostring(i)].breakskillid)].value or 0)
               end
               if breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] then
                   breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] = breakup["h_"..breakskillconfig[tostring(config[tostring(i)].breakskillid)].attr] + (breakskillconfig[tostring(config[tostring(i)].breakskillid)].value or 0)
               end
           end
        end
    end

    local q_breakstr = ""
    local h_breakstr = ""
    -- if breakup.q_atk > 0 then q_breakstr = q_breakstr.."攻击+"..(breakup.q_atk*100).."%   " end
    -- if breakup.h_atk > 0 then h_breakstr = h_breakstr.."攻击+"..(breakup.h_atk*100).."%   " end
    -- if breakup.q_def > 0 then q_breakstr = q_breakstr.."防御+"..(breakup.q_def*100).."%   " end
    -- if breakup.h_def > 0 then h_breakstr = h_breakstr.."防御+"..(breakup.h_def*100).."%   " end
    -- if breakup.q_hp > 0 then q_breakstr = q_breakstr.."生命+"..(breakup.q_hp*100).."%   " end
    -- if breakup.h_hp > 0 then h_breakstr = h_breakstr.."生命+"..(breakup.h_hp*100).."%   " end
    if breakup.q_atk > 0 then q_breakstr = gameConfig.strings:breakeAtk(q_breakstr,breakup.q_atk) end
    if breakup.h_atk > 0 then h_breakstr = gameConfig.strings:breakeAtk(h_breakstr,breakup.h_atk) end
    if breakup.q_def > 0 then q_breakstr = gameConfig.strings:breakeDef(q_breakstr,breakup.q_def) end
    if breakup.h_def > 0 then h_breakstr = gameConfig.strings:breakeDef(h_breakstr,breakup.h_def) end
    if breakup.q_hp > 0 then q_breakstr = gameConfig.strings:breakeHp(q_breakstr,breakup.q_hp) end
    if breakup.h_hp > 0 then h_breakstr = gameConfig.strings:breakeHp(h_breakstr,breakup.h_hp) end

    if q_breakstr ~= "" then
        -- self.rootItems.bdskill1_type:setString("前排伙伴：")
        self.rootItems.bdskill1_type:setString(gameConfig.strings:string_common("layer_devour",3))
        self.rootItems.bdskill1_desc:setString(q_breakstr)
        if h_breakstr ~= "" then
            -- self.rootItems.bdskill2_type:setString("后排伙伴：")
            self.rootItems.bdskill2_type:setString(gameConfig.strings:string_common("layer_devour",4))
            self.rootItems.bdskill2_desc:setString(h_breakstr)
        else
            self.rootItems.bdskill2_type:setString("")
            self.rootItems.bdskill2_desc:setString("")
        end
    elseif h_breakstr ~= "" then
        -- self.rootItems.bdskill1_type:setString("后排伙伴：")
        self.rootItems.bdskill1_type:setString(gameConfig.strings:string_common("layer_devour",4))
        self.rootItems.bdskill1_desc:setString(h_breakstr)
        self.rootItems.bdskill2_type:setString("")
        self.rootItems.bdskill2_desc:setString("")
    else
        self.rootItems.bdskill1_type:setString("")
        self.rootItems.bdskill1_desc:setString("")
        self.rootItems.bdskill2_type:setString("")
        self.rootItems.bdskill2_desc:setString("")
    end

    --
    --if config[tostring(self.data.pets[self.index].level2+1)] and config[tostring(self.data.pets[self.index].level2+1)].skillid and config[tostring(self.data.pets[self.index].level2+1)].skillid > 0 then
    --    self.rootItems.zdskill_desc_next:setString(skillconfig[tostring(config[tostring(self.data.pets[self.index].level2+1)].skillid)].desc)
    --    self.rootItems.zdskill_next:setVisible(false)
    --else
        self.rootItems.zdskill_next:setVisible(false)
    --end
    --
    if self.data.pets[self.index].iid <= 0 then
        self.rootItems.getpetNode:setVisible(true)
        self.rootItems.level2upNode:setVisible(false)
        self.rootItems.level1upNode:setVisible(false)
    elseif self.data.pets[self.index].level1 >= config[tostring(self.data.pets[self.index].level2)].level then
        self.rootItems.getpetNode:setVisible(false)
        self.rootItems.level1upNode:setVisible(false)
        self.rootItems.level2upNode:setVisible(true)
    else
        self.rootItems.getpetNode:setVisible(false)
        self.rootItems.level2upNode:setVisible(false)
        self.rootItems.level1upNode:setVisible(true)
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
    self.rootItems.up_lv:setString("等级:"..self.data.pets[self.index].level1)
    local xids = {}
    local xindex = 1
    self.rootItems.upxnode1:setVisible(false)
    self.rootItems.upxnode2:setVisible(false)
    if config[tostring(self.data.pets[self.index].level2)].consume and config[tostring(self.data.pets[self.index].level2)].consume ~= "" and config[tostring(self.data.pets[self.index].level2)].consume ~= "0" and config[tostring(self.data.pets[self.index].level2)].consume ~= 0 then
        xids = ui.getIDandNUMs(config[tostring(self.data.pets[self.index].level2)].consume)
        -- self.rootItems.up_lvnext:setString("进阶后等级上限为"..config[tostring(self.data.pets[self.index].level2+1)].level)
        self.rootItems.up_lvnext:setString(gameConfig.strings:lvUp(config[tostring(self.data.pets[self.index].level2+1)].level))
        if self.rootItems.level2upXNode then
            self.rootItems.level2upXNode:setVisible(true)
        end
    else
        self.rootItems.xcoin:setString("")
        ui.setLabelString(self.rootItems.xcoin,nil,14)
        -- self.rootItems.up_lvnext:setString("已到达最高阶")
        self.rootItems.up_lvnext:setString(gameConfig.strings:string_common("layer_devour",7))
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
        UIRequest({type = 1042, iid = self.data.pets[self.index].iid, xids = xids or {}})
    end, CCControlEventTouchUpInside)

    --
    --level1upNode
    local expupconfig = gamedata.config.pet2_expup or {}
    self.rootItems.exp_lv:setString("等级:"..self.data.pets[self.index].level1.."/"..config[tostring(self.data.pets[self.index].level2)].level)

    if self.data.pets[self.index].level1 >= table.getTableLength(expupconfig) then
        -- self.rootItems.exp:setString("满级")
        self.rootItems.exp:setString(gameConfig.strings:string_common("layer_devour",8))
        ui.setSpriteTextureRect2(self.rootItems.exp_pos,0,0,844,31)
    else
        self.rootItems.exp:setString(self.data.pets[self.index].exp.."/"..expupconfig[tostring(self.data.pets[self.index].level1)]["exp"..(config[tostring(self.data.pets[self.index].level2)].quality-1)])
        if self.data.pets[self.index].exp > expupconfig[tostring(self.data.pets[self.index].level1)]["exp"..(config[tostring(self.data.pets[self.index].level2)].quality-1)] then
            ui.setSpriteTextureRect2(self.rootItems.exp_pos,0,0,844,31)
        else
            ui.setSpriteTextureRect2(self.rootItems.exp_pos,0,0,844 * self.data.pets[self.index].exp / expupconfig[tostring(self.data.pets[self.index].level1)]["exp"..(config[tostring(self.data.pets[self.index].level2)].quality-1)],31)
        end
    end

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


function devour.reloadData(self,data)
    print("reloadgeneral")
    --printT(data)
    local expconfig = gamedata.config.pet2_exp or {}

    self.selectall = false
    self.rootItems.allselect:setVisible(false)
    self.selectData = {}
    self.generalData = data.generals or self.generalData
    self.fragmentData = data.generalfragments or self.fragmentData
    self.showData = {}

    for k,v in pairs(expconfig) do
        for k1,v1 in pairs(self.fragmentData) do
            if gamedata.config.general_fragment[tostring(v.id)] and gamedata.config.general_fragment[tostring(v.id)].general == v1.cid then
               table.insert(self.showData,v1)
            end
        end
        for k2,v2 in pairs(self.generalData) do
            if v.id == v2.cid then
                table.insert(self.showData,v2)
            end
        end
    end

    local sortfunc = function (a,b)
        return a["quality"] < b["quality"]
    end
    table.sort(self.showData,sortfunc)

    if self.TableView then
        self.TableView:reloadData()
    else
        self:createList()
    end

    self.rootItems.allselectButton:setTouchPriority(-103)
    self.rootItems.allselectButton:addHandleOfControlEvent(function()
        if self.selectall then
            self.selectall = false
            self.rootItems.allselect:setVisible(false)
            self.selectData = {}
            self.TableView:reloadData()
        else
            for k,v in pairs(self.showData) do
                self.selectData[v.cid..(v.iid or "")] = v
            end
            self.selectall = true
            self.rootItems.allselect:setVisible(true)
            self.TableView:reloadData()
            if guide.controller then
                guide.controller:UIComplete(8046)
            end
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.selectLab,nil,19)
    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:addHandleOfControlEvent(function()

        if next(self.selectData) then
            self.iseat = true
            UIRequest({type = 1041, iid = self.data.pets[self.index].iid, data = self.selectData,})
        else
            -- runGamePrompt({msg = "请选择伙伴或魂魄"})
            runGamePrompt({msg = gameConfig.strings:string_common("layer_devour",9)})
        end

    end, CCControlEventTouchUpInside)

    if table.getTableLength(self.showData) > 0 then
        ui.removeGray("CCControlButton",self.rootItems.doButton)
        ui.removeGray("CCLabelTTF",self.rootItems.doLab)
    else
        ui.addGray("CCControlButton",self.rootItems.doButton)
        ui.addGray("CCLabelTTF",self.rootItems.doLab)
    end
end




function devour.checkuplv1(self,data)

        self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/mochong/mochongshengji", nil, true, "mochongshengji")
        qianghuaNode:setPosition(0,0)
        self.rootItems.effectNode:addChild(qianghuaNode)
        self.rootItems.effectNode:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:setAnimationCompletedCallback(function()
            self.rootItems.effectNode:removeAllChildrenWithCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("mochongshengji")
        gamedata.music:PlayOptSound("xlshjhtp")

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

function devour.eatEffect(self)
    if self.Gneral1 then
        self.Gneral1:setAnimation("eat",false,0)
        self.rootItems.generalNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(4),CCCallFunc:create(function()
            self.Gneral1:setAnimation("stand",true,0)
        end)))

        local Node,Items = CCBReaderLoad("UIEffect/lizi/tuowei", nil, true, "tuowei")
        Node:setPosition(0,0)
        self.rootItems.EatEffectNode:addChild(Node)
        local moveto2 = CCMoveTo:create(1.5, ccp(0,450))
        Node:runAction(CCSequence:createWithTwoActions(moveto2,CCCallFunc:create(function()
            Node:removeFromParentAndCleanup(true)
        end)))
    end
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

return devour   �  