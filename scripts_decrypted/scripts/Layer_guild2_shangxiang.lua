--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local guildshangxiang = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -1,
    status = nil,
}



function guildshangxiang.init(self,parent,toppos)
    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui_shangxiang", nil, true, "gonghui_shangxiang")
    parent:addChild(self.rootNode)

    self.rootItems.topnode:setPositionY(toppos)

    ui.setLabelString(self.rootItems.titledes_Text,nil,18)
    ui.setLabelString(self.rootItems.nameOne_Label,nil,3)
    ui.setLabelString(self.rootItems.nameTwo_Label,nil,7)
    ui.setLabelString(self.rootItems.nameThree_Label,nil,9)

    -- 字体 什么的初始化
    local shangxiangTem = gamedata.config.gang2_incense
    -- printT(shangxiangTem)

    for k,v in pairs(shangxiangTem) do
        print(k,v)
        ui.setLabelString(self.rootItems["gang_exp_Label"..k],v.gang_exp,23)
        ui.setLabelString(self.rootItems["contribution_Label"..k],v.contribution,23)
        local spenddata = gamedata.getIDandNUMs(v.param)
        -- printT(spenddata)
        print("i..am...spenddata")
        ui.setLabelString(self.rootItems["spend_Label"..k],spenddata[1].num,14)

        if spenddata[1].cid == 1000 then
            if GameScene.roleinfo.coin >= spenddata[1].num then
                ui.setLabelString(self.rootItems["spend_Label"..k],spenddata[1].num,14)
            else
                ui.setLabelString(self.rootItems["spend_Label"..k],spenddata[1].num,24)
            end
        elseif spenddata[1].cid == 1001 then
            if GameScene.roleinfo.gold >= spenddata[1].num then
                ui.setLabelString(self.rootItems["spend_Label"..k],spenddata[1].num,14)
            else
                ui.setLabelString(self.rootItems["spend_Label"..k],spenddata[1].num,24)
            end
        end

        ui.setLabelString(self.rootItems["gang_exp_Text"..k],nil,14)
        ui.setLabelString(self.rootItems["contribution_Text"..k],nil,14)
        ui.setLabelString(self.rootItems["spend_Text"..k],nil,14)
        self["spendNum"..k] = spenddata[1].num
    end


    ui.setLabelString(self.rootItems.firstText, nil, 18) 
    self.rootItems.firstBtn:setTouchPriority(self.buttontouch)
    self.rootItems.firstBtn:setSwallowsTouch(true)
    self.rootItems.firstBtn:addHandleOfControlEvent(function()
        if self.isContentScroll then return end

        if self.status ~= 0 then
            -- runGamePrompt({msg = "今日已贡献，请明日再来"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_shangxiang",1)})
        elseif GameScene.roleinfo.coin < self.spendNum1 then
            -- runGamePrompt({msg = "银币不足"})
            --runGamePrompt({msg = gameConfig.strings:string_common("guild_shangxiang",2)})
            shortCoin()
        elseif self.status == 0 then
            print("firstBtn可以点击")
            UIRequest({type = 2251 ,method=1,coin=self.spendNum1})
            self.status = 1
        end

    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.secondText, nil, 18) 
    self.rootItems.secondBtn:setTouchPriority(self.buttontouch)
    self.rootItems.secondBtn:setSwallowsTouch(true)
    self.rootItems.secondBtn:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        print("secondBtn=")
        if self.status ~= 0 then
            -- runGamePrompt({msg = "今日已贡献，请明日再来"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_shangxiang",1)})
        elseif GameScene.roleinfo.gold < self.spendNum2 then
            -- runGamePrompt({msg = "元宝不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_shangxiang",3)})
        elseif self.status == 0 then
            print("secondBtn可以点击")
            UIRequest({type = 2251 ,method=2,gold=self.spendNum2})
            self.status = 2
        end
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.thirdText, nil, 18) 
    self.rootItems.thirdBtn:setTouchPriority(self.buttontouch)
    self.rootItems.thirdBtn:setSwallowsTouch(true)
    self.rootItems.thirdBtn:addHandleOfControlEvent(function()
        if self.isContentScroll then return end
        -- print("thirdBtn=")
        if ui.getVipLevelByStr("for_200") > GameScene.vip.vip then
            runGamePrompt({msg = "贵族"..ui.getVipLevelByStr("for_200").."以上可贡献叫花鸡"})
        elseif self.status ~= 0 then
            -- runGamePrompt({msg = "今日已贡献，请明日再来"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_shangxiang",1)})
        elseif GameScene.roleinfo.gold < self.spendNum3 then
            -- runGamePrompt({msg = "元宝不足"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_shangxiang",3)})
        elseif self.status == 0 then
            print("thirdBtn可以点击")
            UIRequest({type = 2251 ,method=3,gold=self.spendNum3})
            self.status = 3
        end
    end, CCControlEventTouchUpInside)


    self.rootItems.backbutton:setTouchPriority(self.buttontouch)
    self.rootItems.backbutton:setSwallowsTouch(true)
    self.rootItems.backbutton:addHandleOfControlEvent(function()
        print("backbutton=")    

        UIRequest({type = 2230,param = "main"})
    end, CCControlEventTouchUpInside)



    UIRequest({type = 2250})

end

function guildshangxiang.reateEffect(self)
    if tonumber(self.status) == 1 then
        print("播放烧香动画01")
        local effectNode, items = CCBReaderLoad("UIEffect/gonghui/gongxian_1", nil, true, "gongxian_1")
        self.rootItems.gongxianNode:addChild(effectNode)

        self.animationManager = getAnimationManager(items)
        self.animationManager:setAnimationCompletedCallback(function()
            print("complete")
            
            effectNode:removeAllChildrenWithCleanup(true)
            effectNode:removeFromParentAndCleanup(true)
            effectNode = nil
            items = nil

        end)
        self.animationManager:runAnimationsForSequenceNamed("gonghui_1")


    elseif tonumber(self.status) == 2 then
        print("播放烧香动画02")
        local effectNode, items = CCBReaderLoad("UIEffect/gonghui/gongxian_2", nil, true, "gongxian_2")
        self.rootItems.gongxianNode:addChild(effectNode)

        self.animationManager = getAnimationManager(items)
        self.animationManager:setAnimationCompletedCallback(function()
            print("complete")
            
            effectNode:removeAllChildrenWithCleanup(true)
            effectNode:removeFromParentAndCleanup(true)
            effectNode = nil
            items = nil

        end)
        self.animationManager:runAnimationsForSequenceNamed("gonghui_2")

    elseif tonumber(self.status) == 3 then
        print("播放烧香动画03")
        local effectNode, items = CCBReaderLoad("UIEffect/gonghui/gongxian_3", nil, true, "gongxian_3")
        self.rootItems.gongxianNode:addChild(effectNode)

        self.animationManager = getAnimationManager(items)
        self.animationManager:setAnimationCompletedCallback(function()
            print("complete")
            
            effectNode:removeAllChildrenWithCleanup(true)
            effectNode:removeFromParentAndCleanup(true)
            effectNode = nil
            items = nil

        end)
        self.animationManager:runAnimationsForSequenceNamed("gonghui_3")
    end
end


function guildshangxiang.reloaddata(self,data)
    print("reloaddata===",data)
    if  data.status then
        self.status = data.status
    elseif data.result then
        self.result = data.result
    end
    

    if tonumber(self.status) ~= 0 then  
        print("not==0")
        
        ui.addGray("CCControlButton",self.rootItems.firstBtn)
        ui.addGray("CCControlButton",self.rootItems.secondBtn)
        ui.addGray("CCControlButton",self.rootItems.thirdBtn)
    end


    if tonumber(self.status) == 1 then
        -- ui.setLabelString(self.rootItems.firstText, "已贡献", 18) 
        ui.setLabelString(self.rootItems.firstText, gameConfig.strings:string_common("guild_shangxiang",4), 18) 
    elseif tonumber(self.status) == 2 then
        -- ui.setLabelString(self.rootItems.secondText, "已贡献", 18) 
        ui.setLabelString(self.rootItems.secondText, gameConfig.strings:string_common("guild_shangxiang",4), 18) 
    elseif tonumber(self.status) == 3 then
        -- ui.setLabelString(self.rootItems.thirdText, "已贡献", 18) 
        ui.setLabelString(self.rootItems.thirdText, gameConfig.strings:string_common("guild_shangxiang",4), 18)
    end
end

function guildshangxiang.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end


function guildshangxiang.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 2250})
    end
end

return guildshangxiang  �$  