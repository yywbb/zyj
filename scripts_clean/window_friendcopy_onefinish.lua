--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/11/3
-- Time: 下午2:17
-- To change this template use File | Settings | File Templates.
--

local friendcopy_onefinish = {
    rootNode = nil,
    rootItems = nil,

    donum = 0,
    doid = 0,

    data = {},

}

function friendcopy_onefinish.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("copyFriend/tc_yijianwancheng", nil, true, "tc_yijianwancheng")

    self.touchPriority = touchPriority

    -- 添加输入数字功能 
    ui.creatInputEditBoxForNum(self.rootItems.inputNumNode,self.rootItems.donum,self.touchPriority,function (num)
        self.donum = 0
        self:numchange(num)
    end)    

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("friendcopy_onefinish")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.add1:addHandleOfControlEvent(function()
        self:numchange(1)
    end, CCControlEventTouchUpInside)
    self.rootItems.add1:setSwallowsTouch(true)
    self.rootItems.add1:setTouchPriority(self.touchPriority)

    self.rootItems.add10:addHandleOfControlEvent(function()
        self:numchange(10)
    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)


    self.rootItems.sub1:addHandleOfControlEvent(function()
        self:numchange(-1)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub1:setSwallowsTouch(true)
    self.rootItems.sub1:setTouchPriority(self.touchPriority)

    self.rootItems.sub10:addHandleOfControlEvent(function()
        self:numchange(-10)
    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)


    --ui.setLabelString(self.rootItems.doLab1,"取 消",18)
    ui.setLabelString(self.rootItems.doLab1,gameConfig.strings:string_common("popups","quxiao"),18)
    self.rootItems.doButton1:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("friendcopy_onefinish")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)

    --ui.setLabelString(self.rootItems.doLab2,"确 定",18)
    ui.setLabelString(self.rootItems.doLab2,gameConfig.strings:string_common("popups","queding"),18)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        gameTouch:clickprofbytime(0.5)
        if self.donum >0 then
            --todo
            UIRequest({type = 1325,id = self.doid, num = self.donum})
            gameWindows:closeWindowDirect("friendcopy_onefinish")
        else
            runGamePrompt({msg = "请选择次数"})
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)

    self:reload(data,callback)


    return self.rootNode
end



function friendcopy_onefinish.numchange(self,num)
    self.donum = self.donum+num
    --
    local restcount = self.data.kill or 0

    if self.donum > restcount then
        runGamePrompt({msg = "达到次数上限"})
        self.donum = restcount
    elseif self.donum <0 then
        self.donum = 0
    end
    --
    self.rootItems.donum:setString(self.donum)
end

function friendcopy_onefinish.reload(self,data,callback)
    self.data = data and data.data or {}
    self.callback = callback

    self:numchange(0)

    self.doid = 0
    for k,v in pairs(self.data.maps or {}) do
        if v.kill and (v.kill > -1) and (v.id > self.doid) then
            self.doid = v.id
        end    
    end

    local mapconfig = gamedata.config.expedition_map[tostring(self.doid)] or {}
    local config = gamedata.config.expedition2[tostring(self.doid)] or {}

    self.rootItems.name:setString(gameConfig.strings:lvNum(self.doid-43000,mapconfig.name))
    self.rootItems.power:setString(gameConfig.strings:tjZdl(config.power))

    --
    local i=1
    local rewards = {}
    while  mapconfig["drop"..i] and mapconfig["drop"..i] > 0 do
        table.insert(rewards,{cid = mapconfig["drop"..i],num = mapconfig["number"..i] or 1 })
        i = i+1
    end

    local rewardnum = #rewards
    local maxw = 760*(0.3+rewardnum*0.15)
    local statx = 120+760*(1-(0.3+rewardnum*0.15))/2
    for i=1,6 do
        local reward = rewards[i]
        if reward then

            if mapconfig["drop"..i.."prob"] and mapconfig["drop"..i.."prob"] ~= 100 then
                local spritetemp = CCSprite:create("public/language/suijidiaoluozi.png")
                if spritetemp then
                    spritetemp:setPosition(110,110)
                    self.rootItems["prop"..i]:addChild(spritetemp)
                end
            end
            
            self.rootItems["prop"..i]:setVisible(true)
            ui.setNewIcon(self.rootItems,reward,i-1)
            self.rootItems["prop"..i]:setPositionX(statx+(maxw/rewardnum)*(i-0.5))
            local key_Ex = i-1>0 and "_"..(i-1) or ""
            self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
                ui.setPopwindowByCid(reward.cid)
            end, CCControlEventTouchUpInside)
            self.rootItems["i_button"..key_Ex]:setTouchPriority(self.touchPriority-1)
        else
            self.rootItems["prop"..i]:setVisible(false)
        end
    end


end



function friendcopy_onefinish.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    -- if self.callback then
    --     self.callback()
    -- end

    self.donum = 0
    self.doid = 0

end

return friendcopy_onefinish