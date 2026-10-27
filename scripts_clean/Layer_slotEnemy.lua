--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/2
-- Time: 下午1:48
-- To change this template use File | Settings | File Templates.
--



local slotenemy = {

    rootNode = nil,
    rootItems = nil,

    data = {},

    buttontouch = -103,
    ListTableView = nil,
    showgenerals = {},

    position = {},
}

function slotenemy.init(self,parent,toppos,param)
    self.rootNode,self.rootItems = CCBReaderLoad("migong/migong_buzhen_difang", nil, true, "migong_buzhen")
    self.rootNode:setPosition(0,0)
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)
    self.rootItems.midnode:setPositionY((toppos-1620)*0.15+780)
    self.rootItems.buttonNode:setPositionY((toppos-1620)*0.15+300)
    self.rootItems.bg:setPositionY(toppos/2)

    -- self.rootItems.midgeneralnode:setContentSize(CCSizeMake(800,(toppos-1620)*0.6+750))

    self.awakenConfig = gamedata.config.general_awaken
    self.rootItems.backBtn:addHandleOfControlEvent(function()
        print("backBtn")
        GameScene:shiftLayer("maze","up")
        -- UIRequest({type = 3700})
    end, CCControlEventTouchUpInside)
    self.rootItems.backBtn:setSwallowsTouch(true)
    self.rootItems.backBtn:setTouchPriority(self.buttontouch-1)


    self:reloadData(param)
end


function slotenemy.reloadData(self,data)
    print("reloadData===")
    printT(data)
    if data then 
        self.data = data 
    else
        return
    end

    self.rootItems.power:setString("战斗力:"..self.data.slots.power)
    -- 设置魔宠icon
    if self.data.slots.petcid ~= 0 then
        self.rootItems.petccb:setVisible(true)
        local config = gamedata.config.pet3_attr[tostring(self.data.slots.petcid)][tostring(self.data.slots.petlevel)]

        ui.setNewIcon(self.rootItems,{cid=self.data.slots.petcid})
        setSpriteFrameByName(self.rootItems["i_k_quality"], "b_iconk"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(self.rootItems["i_quality"], "b_iconbg"..(config.quality and config.quality>1 and config.quality or 1))
        setSpriteFrameByName(self.rootItems.i_icon,config.icon)
        ui.setSpriteTextureRect(self.rootItems.i_icon,0,0,150,150)    
    else
        self.rootItems.petccb:setVisible(false)
    end



    -- 设置刷新次数
    local globle = gamedata.config.global_kv
    -- printT(globle)
    local spendconfig = gamedata.config.buycount_price
    -- local tempNum = tonumber(globle.maze_refresh_times.value)-tonumber(self.data.slots.resetNum)
    -- printT(spendconfig)
    -- print("sjlopdfjksdl;fjk")
    -- printT(self.data.slots)
    -- print("goldnum===",spendconfig[tostring(self.data.slots.resetNum)]["maze_pay_refresh_cost"])
    local resetNum = self.data.slots.resetNum
    if self.data.slots.resetNum >= 60 then
        resetNum = 59
    end
    if tonumber(spendconfig[tostring(resetNum+1)]["maze_pay_refresh_cost"] or 0) > 0 then
        -- print("spend===",spendconfig[tostring(resetNum+1)]["maze_pay_refresh_cost"])
        self.rootItems.freeNode:setVisible(false)
        self.rootItems.spendNode:setVisible(true)
        ui.setLabelString(self.rootItems.spendLabel,spendconfig[tostring(resetNum+1)]["maze_pay_refresh_cost"] or 1,21)
        ui.setLabelString(self.rootItems.spendText,nil,21)
    else
        -- print("else====")
        self.rootItems.freeNode:setVisible(true)
        self.rootItems.spendNode:setVisible(false)
        ui.setLabelString(self.rootItems.freenumLabel,tonumber(globle.maze_refresh_times.value)-tonumber(resetNum),21)
        ui.setLabelString(self.rootItems.freenumText,nil,21)
    end

    ui.setLabelString(self.rootItems.resetText,nil,19)
    self.rootItems.resetBtn:addHandleOfControlEvent(function()
        -- print("resetBtn")
        gameTouch:clickprofbytime(1)
        local spendnum = 0
        -- if resetNum ~= 0 then
        spendnum = spendconfig[tostring(resetNum+1)]["maze_pay_refresh_cost"] or 0
        -- end
        UIRequest({type = 3811,id = 0,spendnum = spendnum})
        -- UIRequest({type = 3700})
    end, CCControlEventTouchUpInside)
    self.rootItems.resetBtn:setSwallowsTouch(true)
    self.rootItems.resetBtn:setTouchPriority(self.buttontouch-1)

    ui.setLabelString(self.rootItems.fightText,nil,19)
    self.rootItems.fightBtn:addHandleOfControlEvent(function()
        -- print("fightBtn")
        gameTouch:clickprofbytime(1)
        UIRequest({type = 3804})
        -- UIRequest({type = 3804,id = 140,param = self.data.bosstype})
        -- UIRequest({type = 3700})
    end, CCControlEventTouchUpInside)
    self.rootItems.fightBtn:setSwallowsTouch(true)
    self.rootItems.fightBtn:setTouchPriority(self.buttontouch-1)

    

    self:setSlot()
end

function slotenemy.setSlot(self)

    for i=1,7 do
        if self.data.slots.slot[tostring(i)] and self.data.slots.slot[tostring(i)].cid ~= 0 then
            local CCBNode, CCBitem = 0,0
            CCBNode,CCBitem = CCBReaderLoad("migong/cell_buzhen_difang", nil, true, "cell_buzhen")
            self.rootItems["general"..i]:addChild(CCBNode)
            local generalconfig = gamedata.config.general[tostring(self.data.slots.slot[tostring(i)].cid)]
            
            -- local namestring = generalconfig.name
            -- if self.data.slots.slot[tostring(i)].stage ~= 0 then
            --     namestring = namestring.." +"..self.data.slots.slot[tostring(i)].stage
            -- end
            -- ui.setLabelString(CCBitem.g_name,namestring,((generalconfig.quality and generalconfig.quality ~= 0) and generalconfig.quality or 1)*2)

            -- CCBitem.g_name:setString(generalconfig.g_name)
            -- CCBitem.g_level:setString("LV."..self.data.slots.slot[tostring(i)].level)

            -- print("hppercent===",self.data.slots.slot[tostring(i)].hppercent)
            -- ui.setSpriteTextureRect2(CCBitem.hpBar,0,0,125*(self.data.slots.slot[tostring(i)].hppercent < 100 and self.data.slots.slot[tostring(i)].hppercent/100 or 1),14)

            -- setSpriteFrameByName(CCBitem.g_icon, generalconfig.icon)
            local namestring = generalconfig.name or ""
            if self.data.slots.slot[tostring(i)].name then
                namestring = self.data.slots.slot[tostring(i)].name or ""
            end

            local g_data = {
                quality = generalconfig.quality,
                icon = generalconfig.icon,
                name = namestring,
                actor = generalconfig.actor,
                level = self.data.slots.slot[tostring(i)].level,
                level2 = self.data.slots.slot[tostring(i)].stage,
                hppercent = self.data.slots.slot[tostring(i)].hppercent,
                --取消后没有添加觉醒icon
                -- awakenicon = self.awakenConfig[tostring(self.data.generals[tostring(self.data.slots.generals[tostring(i)])].skilllevel)].icon,
                -- awakenstage = self.awakenConfig[tostring(self.data.generals[tostring(self.data.slots.generals[tostring(i)])].skilllevel)].stage,                
            }
            ui.setGeneralIconL2(g_data,CCBitem)

        end
    end
    
end

function slotenemy.clear(self)
    self.data = {}
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return slotenemy