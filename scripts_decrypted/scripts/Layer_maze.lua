--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local maze = {

    resource = nil,

    rootNode = nil,
    rootItems = nil,
    eventNode = nil,
    eventItems = nil,
    goenable = true,
    maze = {},
    resetgold = 0,
    ismove = 0,
}

function maze.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("migong/migong", nil, true, "migong")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    --
    ui.setLabelString(self.rootItems.resetLab,nil,19)
    self.rootItems.resetButton:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        if gamedata.config.vip[tostring(GameScene.vip.vip)].maze_times-self.maze.reset > 0 then
            UIRequest({type = 3812, xgold = self.resetgold or 0})
        else
            runGamePrompt({msg = "今日重置次数已用完" })
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.resetButton:setSwallowsTouch(true)
    self.rootItems.resetButton:setTouchPriority(-105)
    --
    self.rootItems.maze_reward:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        print("maze_reward")
        UIRequest({type = 3808})
    end, CCControlEventTouchUpInside)
    self.rootItems.maze_reward:setSwallowsTouch(true)
    self.rootItems.maze_reward:setTouchPriority(-105)
    --
    self.rootItems.maze_shop:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(1)
        print("maze_shop")
        GameScene:shiftLayerById(160)
    end, CCControlEventTouchUpInside)
    self.rootItems.maze_shop:setSwallowsTouch(true)
    self.rootItems.maze_shop:setTouchPriority(-105)
    --
    --go
    self.rootItems.go_ahead:addHandleOfControlEvent(function()
        print("go_ahead")
        gameTouch:clickprofbytime(1)
        if self.maze.event_type and self.maze.event_type == 0 then
            self:explore("go")
        else
            print("has event")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.go_ahead:setSwallowsTouch(true)
    self.rootItems.go_ahead:setTouchPriority(-105)
    --
    self.rootItems.go_left:addHandleOfControlEvent(function()
        print("go_left")
        gameTouch:clickprofbytime(1)
        if self.maze.event_type and self.maze.event_type == 0 then
            self:explore("left")
        else
            print("has event")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.go_left:setSwallowsTouch(true)
    self.rootItems.go_left:setTouchPriority(-105)
    --
    self.rootItems.go_right:addHandleOfControlEvent(function()
        print("go_right")
        gameTouch:clickprofbytime(1)
        if self.maze.event_type and self.maze.event_type == 0 then
            self:explore("right")
        else
            print("has event")
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.go_right:setSwallowsTouch(true)
    self.rootItems.go_right:setTouchPriority(-105)
    --
    self.goenable = true
    --

    UIRequest({type = 3800})

end

function maze.clear(self)
    self.ismove = 0
    self.resetgold = 0
    self.maze = {}
    self.goenable = true
    self.eventNode = nil
    self.eventItems = nil
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

end


function maze.ReloadData(self,data)
    print("ReloadData")
    self.goenable = true
    self.maze = data.maze or {}
    self.ismove = data.ismove or 0
    --setstatus
    ui.setLabelString(self.rootItems.progress,"当前进度: "..self.maze.position.."/15",14)
    local resetmax = gamedata.config.vip[tostring(GameScene.vip.vip)].maze_times or 0
    ui.setLabelString(self.rootItems.resetnum,"剩余重置次数: "..(resetmax-self.maze.reset).."/"..resetmax,13)
    if resetmax-self.maze.reset > 0 then
        ui.removeGray("CCControlButton",self.rootItems.resetButton)
        ui.removeGray("CCLabelTTF",self.rootItems.resetLab)
    else
        ui.addGray("CCControlButton",self.rootItems.resetButton)
        ui.addGray("CCLabelTTF",self.rootItems.resetLab)
    end
    --
    if gamedata.config.buycount_price[tostring(self.maze.reset+1)] and gamedata.config.buycount_price[tostring(self.maze.reset+1)].maze and gamedata.config.buycount_price[tostring(self.maze.reset+1)].maze > 0 then
        self.rootItems.resetGoldNode:setVisible(true)
        self.resetgold = gamedata.config.buycount_price[tostring(self.maze.reset+1)].maze
        ui.setLabelString(self.rootItems.reset_gold,self.resetgold,21)
    else
        self.resetgold = 0
        self.rootItems.resetGoldNode:setVisible(false)
    end
    --
    if resetmax-self.maze.reset <= 0 then
        self.rootItems.resetGoldNode:setVisible(false)
    end
    --buff
    local typeconfig = gamedata.config.maze_type or {}
    if self.maze.buff_global and self.maze.buff_global > 0 then
        local str,num = ui.getSTRandNUM(typeconfig[tostring(self.maze.buff_global)].param1)
        self.rootItems.buff_global:setString("全体伙伴"..gameConfig.strings.attr_type[str].."+"..(num*100).."%")
    else
        self.rootItems.buff_global:setString("")
    end
    if self.maze.buff_temp and self.maze.buff_temp > 0 then
        local str,num = ui.getSTRandNUM(typeconfig[tostring(self.maze.buff_temp)].param1)
        self.rootItems.buff_temp:setString("全体伙伴"..gameConfig.strings.attr_type[str].."+"..(num*100).."%")
    else
        self.rootItems.buff_temp:setString("")
    end
    --

    self:setEvent()

end

function maze.explore(self,direction)
    --
    if not self.goenable then return end
    --
    self.goenable = false
    --
    local animationManager = getAnimationManager(self.rootItems)
    animationManager:setAnimationCompletedCallback(function()
        UIRequest({type = 3801})
    end)
    animationManager:runAnimationsForSequenceNamed(direction and direction or "go")
    --
end

function maze.setEvent(self)
    if not self.maze.event_type then return end

    if self.maze.event_type == 1000 or self.maze.event_type == 999 then
        self.rootItems.goNode:setVisible(false)
        self.rootItems.eventNode:setVisible(true)
        --
        self.eventNode,self.eventItems = CCBReaderLoad("migong/migong_finish", nil, true, "event")
        self.eventNode:setPosition(0,-900)
        self.rootItems.eventNode:removeAllChildrenWithCleanup(true)
        self.rootItems.eventNode:addChild(self.eventNode)
        --
        local animationManager = getAnimationManager(self.eventItems)
        --            animationManager:setAnimationCompletedCallback(function()
        --               print("callback")
        --            end)
        animationManager:runAnimationsForSequenceNamed("maze_finish")
        --
    elseif self.maze.event_type == 0 then
        if self.maze.position >= 15 then
            self.rootItems.goNode:setVisible(false)
            self.rootItems.eventNode:setVisible(true)
            --
            self.eventNode,self.eventItems = CCBReaderLoad("migong/migong_finish", nil, true, "event")
            self.eventNode:setPosition(0,-900)
            self.rootItems.eventNode:removeAllChildrenWithCleanup(true)
            self.rootItems.eventNode:addChild(self.eventNode)
            --
            local animationManager = getAnimationManager(self.eventItems)
--            animationManager:setAnimationCompletedCallback(function()
--               print("callback")
--            end)
            animationManager:runAnimationsForSequenceNamed("maze_finish")
            --
        else
            self.rootItems.goNode:setVisible(true)
            self.rootItems.eventNode:setVisible(false)
        end
    elseif self.maze.event_type == 4 then
        self.rootItems.goNode:setVisible(false)
        self.rootItems.eventNode:setVisible(true)
        --
        self.eventNode,self.eventItems = CCBReaderLoad("migong/migong_guai", nil, true, "event")
        self.eventNode:setPosition(0,0)
        self.eventItems.p_box:setVisible(false)
        self.eventItems.p_yudi1:setVisible(false)
        self.eventItems.p_yudi2:setVisible(false)
        self.eventItems.p_general:setVisible(false)
        self.rootItems.eventNode:removeAllChildrenWithCleanup(true)
        self.rootItems.eventNode:addChild(self.eventNode)
        --
        self:setEventBattle()
        --
    else
        self.rootItems.goNode:setVisible(false)
        self.rootItems.eventNode:setVisible(true)
        --
        self.eventNode,self.eventItems = CCBReaderLoad("migong/migong_shijian", nil, true, "event")
        self.eventNode:setPosition(0,-500)
        self.eventItems.e_guess:setVisible(false)
        self.eventItems.e_buff:setVisible(false)
        self.eventItems.e_box:setVisible(false)
        self.rootItems.eventNode:removeAllChildrenWithCleanup(true)
        self.rootItems.eventNode:addChild(self.eventNode)
        --
        self:setEventEvent()
        --
    end
end

function maze.setEventBattle(self)
    --
    self.eventItems["p_generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(self.maze.event_param1).animationid)].name
    local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1)
    Gneral1:setPosition(0,0)
    self.eventItems["p_generalNode"]:addChild(Gneral1)
    ui.setLabelString(self.eventItems["p_generalName"],"",1)--ui.IDconfig(self.maze.event_param1).name,1)
    --
    self.eventItems.p_yudi1:setVisible(self.ismove == 1)
    self.eventItems.p_yudi2:setVisible(self.ismove == 1)
    self.eventItems.p_general:setVisible(true)
    --
    if self.ismove and self.ismove == 1 then
        local animationManager = getAnimationManager(self.eventItems)
        animationManager:setAnimationCompletedCallback(function()
            self.eventItems.p_yudi1:setVisible(false)
            self.eventItems.p_yudi2:setVisible(false)
        end)
        animationManager:runAnimationsForSequenceNamed("start")
    end
    --
    self.eventItems.p_generalButton:addHandleOfControlEvent(function()
        print("p_generalButton"..self.maze.event_id)
        gameTouch:clickprofbytime(1)
        UIRequest({type = 3811,id = 1})
    end, CCControlEventTouchUpInside)
    self.eventItems.p_generalButton:setSwallowsTouch(true)
    self.eventItems.p_generalButton:setTouchPriority(-105)
    --

end

function maze.setEventEvent(self)
    local typeconfig = gamedata.config.maze_type or {}
    if self.maze.event_type == 1 then
        --
        self.eventItems.e_boxButton:addHandleOfControlEvent(function()
            print("e_boxButton"..self.maze.event_id)
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3802,eventtype = self.maze.event_type, eventid = self.maze.event_id })
        end, CCControlEventTouchUpInside)
        self.eventItems.e_boxButton:setSwallowsTouch(true)
        self.eventItems.e_boxButton:setTouchPriority(-105)
        --
        self.eventItems.e_box:setVisible(true)
        self.eventItems.e_guess:setVisible(false)
        self.eventItems.e_buff:setVisible(false)
        --
        local animationManager = getAnimationManager(self.eventItems)
        animationManager:runAnimationsForSequenceNamed("playevent")
        --
    elseif self.maze.event_type == 2 then
        --
        local cid_r = ui.getIDFromStr(typeconfig[tostring(self.maze.event_id)].param1)
        local cid_1 = ui.getIDFromStr(typeconfig[tostring(self.maze.event_param1)].param1)
        local cid_2 = ui.getIDFromStr(typeconfig[tostring(self.maze.event_param2)].param1)
        local cid_3 = ui.getIDFromStr(typeconfig[tostring(self.maze.event_param3)].param1)
        local cid_4 = ui.getIDFromStr(typeconfig[tostring(self.maze.event_param4)].param1)
        --
        self.eventItems["e_guessGeneral"]:removeAllChildrenWithCleanup(true)
        local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(cid_r).animationid)].name
        local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(1.6)
        Gneral1:setPosition(0,0)
        --
        local red = CCTintTo:create(0,0,0,0)
        local back = CCTintTo:create(0,0,0,0)
        local sq = CCSequence:createWithTwoActions(red,back)
        Gneral1:runAction(sq)
        --
        self.eventItems["e_guessGeneral"]:addChild(Gneral1)
        --
        ui.setNewIcon(self.eventItems,{cid = cid_1})
        ui.setNewIcon(self.eventItems,{cid = cid_2},1)
        ui.setNewIcon(self.eventItems,{cid = cid_3},2)
        ui.setNewIcon(self.eventItems,{cid = cid_4},3)
        for i = 1,4 do
            self.eventItems["i_button"..((i > 1) and ("_"..(i-1)) or "")]:addHandleOfControlEvent(function()
                print("i_button"..self.maze["event_param"..i])
                gameTouch:clickprofbytime(1)
                UIRequest({type = 3802,eventtype = self.maze.event_type, eventid = self.maze["event_param"..i] })
            end, CCControlEventTouchUpInside)
            self.eventItems["i_button"..((i > 1) and ("_"..(i-1)) or "")]:setSwallowsTouch(true)
            self.eventItems["i_button"..((i > 1) and ("_"..(i-1)) or "")]:setTouchPriority(-105)
        end
        --
        self.eventItems.e_guess:setVisible(true)
        self.eventItems.e_buff:setVisible(false)
        self.eventItems.e_box:setVisible(false)
        --
        local animationManager = getAnimationManager(self.eventItems)
        animationManager:runAnimationsForSequenceNamed("playevent")
        --
    elseif self.maze.event_type == 3 then
        --
        local str,num = ui.getSTRandNUM(typeconfig[tostring(self.maze.event_id)].param1)
        ui.setLabelString(self.eventItems.e_buffDesc,"全体伙伴"..gameConfig.strings.attr_type[str].."+"..(num*100).."%",22)
        --
        ui.setLabelString(self.eventItems.e_buffLab,nil,19)
        self.eventItems.e_buffButton:addHandleOfControlEvent(function()
            print("e_buffButton"..self.maze.event_id)
            gameTouch:clickprofbytime(1)
            UIRequest({type = 3802,eventtype = self.maze.event_type, eventid = self.maze.event_id })
        end, CCControlEventTouchUpInside)
        self.eventItems.e_buffButton:setSwallowsTouch(true)
        self.eventItems.e_buffButton:setTouchPriority(-105)
        --
        self.eventItems.e_buff:setVisible(true)
        self.eventItems.e_guess:setVisible(false)
        self.eventItems.e_box:setVisible(false)
        --
        local animationManager = getAnimationManager(self.eventItems)
        animationManager:runAnimationsForSequenceNamed("playevent")
        --
    end
end

function maze.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 3800})
    end
end

return maze


�:  