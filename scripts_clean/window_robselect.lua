--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午1:58
-- To change this template use File | Settings | File Templates.
--

local robselect = {
    rootNode = nil,
    rootItems = nil,
    -- snatch = {},
    mygangid = 0,
}

function robselect.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("rub/qiangduo_tc", nil, true, "qiangduo_tc")
    self.show = true
    self.touchPriority = touchPriority
    -- self:reload(data,callback)

    self:onReload(data, callback)
    return self.rootNode
end

function robselect.onReload(self, data, callback)

    self.mygangid = data.mygangid or 0
    self.data = data
    self.snatch = {}
    local config = ui.IDconfig(data.cid)
    for i=1,3 do
        local celldata = data.players[tostring(i)]
        self:setRate(celldata,config,self.rootItems["rate"..(i==1 and "" or "_"..(i-1))], i)
    end

    table.sort(self.snatch, function(a, b)
        return a.rate > b.rate
    end)

    self:reload(self.snatch, callback)
end

function robselect.setRate(self,enemydata,fragment,label, id)

    local rate = 0
    local config = gamedata.config.loot[tostring(fragment.quality)]
    local selflevel = GameScene.roleinfo.level
    local type = enemydata.rid > gameConfig.npcRidlimit and "npc" or "player"


    rate = config[type.."_basic"] + config["npc_"..(selflevel>=enemydata.level and "more" or "less")]*(enemydata.level-selflevel)
    if rate<  config[type.."_min"] then
        rate = config[type.."_min"]
    elseif rate<  config[type.."_max"] then
        rate = config[type.."_max"]
    end

    rate = rate*100

    local des = ""
    local labeltyep = 32
    if rate >=80 then
        -- des = "非常高"
        des = gameConfig.strings:string_common("robselect",0)
        labeltyep = 11
    elseif rate >=70 then
        -- des = "高概率"
        des = gameConfig.strings:string_common("robselect",1)
        labeltyep = 9
    elseif rate >=50 then
        -- des = "一般概率"
        des = gameConfig.strings:string_common("robselect",2)
        labeltyep = 7
    elseif rate >=30 then
        -- des = "低概率"
        des = gameConfig.strings:string_common("robselect",3)
        labeltyep = 5
    else
        -- des = "非常低"
        des = gameConfig.strings:string_common("robselect",4)
        labeltyep = 3
    end
    enemydata.rate = rate
    enemydata.des = des
    enemydata.labeltyep = labeltyep
    -- ui.setLabelString(label,des,labeltyep)
    table.insert(self.snatch, enemydata)
end

function robselect.changeEnemy(self)
    if self.config and self.config.staffType and self.data and self.data.cid then
        if self.config.staffType == "general" then
            UIRequest({type = 1018, cid = self.data.cid})
        else
            UIRequest({type = 1110, cid = self.data.cid})
        end
    end
end


function robselect.reload(self,data,callback)
    self.callback = callback

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("robselect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- local config = ui.IDconfig(data.cid)
    local config = ui.IDconfig(self.data.cid)

    self.config = config
    -- self.data = data

    -- ui.setLabelString(self.rootItems.changetext,"换对手",19)
    ui.setLabelString(self.rootItems.changetext,gameConfig.strings:string_common("robselect",5),19)
    self.rootItems.changebutton:addHandleOfControlEvent(function()
        if config.staffType == "general" then
            UIRequest({type = 1018, cid = self.data.cid})
        else
            UIRequest({type = 1110, cid = self.data.cid})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.changebutton:setSwallowsTouch(true)
    self.rootItems.changebutton:setTouchPriority(self.touchPriority)



    ui.setIconLv(self.rootItems,{cid = self.data.cid})
    ui.setLabelString(self.rootItems.name,config.name, config.quality and 2*config.quality-1 or 1)
    if config.staffType == "general" then
        setSpriteFrameByName(self.rootItems["i_soulsprite"], "b_soulsprite")
    else
        setSpriteFrameByName(self.rootItems["i_soulsprite"], "b_sprite1")
    end

    --
    self.rootItems["il_button"]:addHandleOfControlEvent(function()
        ui.setPopwindowByCid(self.data.cid)
    end, CCControlEventTouchUpInside)
    self.rootItems["il_button"]:setTouchPriority(self.touchPriority)
    --
    for i= 1,3 do
        local celldata = data[i]
        if celldata and  next(celldata) and celldata.profile and celldata.profile>0 then
            self.rootItems["playernode"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,{cid = celldata.profile},i-1)

            -- self.rootItems["level"..(i==1 and "" or "_"..(i-1))]:setString(celldata.level.."级")
            self.rootItems["level"..(i==1 and "" or "_"..(i-1))]:setString(gameConfig.strings:getlvnum(celldata.level))
            self.rootItems["cellname"..(i==1 and "" or "_"..(i-1))]:setString(celldata.name)
            -- ui.setLabelString(label,des,labeltyep)
            ui.setLabelString(self.rootItems["rate"..(i==1 and "" or "_"..(i-1))], celldata.des, celldata.labeltyep)
            -- ui.setLabelString(self.rootItems["buttontext"..(i==1 and "" or "_"..(i-1))],"抢 夺",19)
            ui.setLabelString(self.rootItems["buttontext"..(i==1 and "" or "_"..(i-1))],gameConfig.strings:string_common("robselect",6),19)
            self.rootItems["button"..(i==1 and "" or "_"..(i-1))]:setTouchPriority(self.touchPriority)
            self.rootItems["button"..(i==1 and "" or "_"..(i-1))]:addHandleOfControlEvent(function()
                print("icon clicked")
                gameTouch:clickprofbytime(0.5)
--                if config.staffType == "general" then
--                    UIRequest({type = 1019, enemy = celldata})
--                else
                    UIRequest({type = 1111, enemy = celldata,cid=self.data.cid, method = (guide.controller and guide.controller.isOnGuide)})
--                end
                gameWindows:closeWindowDirect("robselect")

            end, CCControlEventTouchUpInside)

            if celldata.rid>=gameConfig.npcRidlimit then
                self.rootItems["buttonnode10"..(i==1 and "" or "_"..(i-1))]:setVisible(true)
                ui.setLabelString(self.rootItems["buttontext10"..(i==1 and "" or "_"..(i-1))],gameConfig.strings:string_common("robselect",7),19)
                self.rootItems["button10"..(i==1 and "" or "_"..(i-1))]:setTouchPriority(self.touchPriority)
                self.rootItems["button10"..(i==1 and "" or "_"..(i-1))]:addHandleOfControlEvent(function()
                    gameTouch:clickprofbytime(0.5)
--                    if config.staffType == "general" then
--                        UIRequest({type = 1019, enemy = celldata})
--                    else
                        UIRequest({type = 1114, enemy = celldata,cid=self.data.cid})
                        if gameTimer.times["robprofCD"] ~= 0 then
                            UIRequest({type = 1112}) -- 当倒计时不为0请求新的时间
                        end
--                    end
                    -- gameWindows:closeWindowDirect("robselect")

                end, CCControlEventTouchUpInside)
            else
                self.rootItems["buttonnode10"..(i==1 and "" or "_"..(i-1))]:setVisible(false)
            end


            -- self:setRate(celldata,config,self.rootItems["rate"..(i==1 and "" or "_"..(i-1))])

            --
            if self.rootItems["isgang"..(i==1 and "" or "_"..(i-1))] then
                self.rootItems["isgang"..(i==1 and "" or "_"..(i-1))]:setVisible(false)
                --    
                if self.mygangid > 0 then
                    if celldata.params and celldata.params["1"] and celldata.params["1"].i and celldata.params["1"].i == self.mygangid then
                        self.rootItems["isgang"..(i==1 and "" or "_"..(i-1))]:setVisible(true)
                    end
                end
                --
            end
        else
            self.rootItems["playernode"..i]:setVisible(false)
        end
    end

    -- self.rootItems.sha:setString("当前杀气: "..GameScene.roleinfo.energy)
    -- self.rootItems.sha:setString(GameScene.roleinfo.energy)　
    
    if GameScene.roleinfo.energy <= 0 then
        ui.setLabelString(self.rootItems.sha,GameScene.roleinfo.energy,47)
    else
        ui.setLabelString(self.rootItems.sha,GameScene.roleinfo.energy,18)
    end
    ui.setLabelString(self.rootItems.spendsha_text,nil,18)

end
--挑战后重新设置杀气值
function robselect.reloadEnergy(self)
    print("??????? = "..GameScene.roleinfo.energy)
    if GameScene.roleinfo.energy <= 0 then
        ui.setLabelString(self.rootItems.sha,GameScene.roleinfo.energy,47)
    else
        ui.setLabelString(self.rootItems.sha,GameScene.roleinfo.energy,18)
    end
end

function robselect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.show = false
    if self.callback then
        self.callback()
    end
end

return robselect
