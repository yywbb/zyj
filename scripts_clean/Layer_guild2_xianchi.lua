--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/31
-- Time: 上午10:58
-- To change this template use File | Settings | File Templates.
--

local guildxianchi = {

    rootNode = nil,
    rootItems = nil,
    buttontouch = -1,

    gang = nil,
    xianchidata = nil,
    delayButtonStatus = true,
    firstnum = 0,
    -- chifirstnum = 0,
    -- beforeNum = 0,
}



function guildxianchi.init(self,parent,toppos,param)

    self.optlimt = tonumber(gamedata.config.global_kv.gang2_fishpoind_limit.value) or 10

    self.rootNode,self.rootItems = CCBReaderLoad("gonghui2/gonghui_xianchi", nil, true, "gonghui_xianchi")
    parent:addChild(self.rootNode)

    self.taibairootNode, self.taibairootItems = CCBReaderLoad("UIEffect/zaotang/zaotang_taibai.ccbi", nil, true, "zaotang_taibai")
    self.rootItems.taibaiNode:addChild(self.taibairootNode)
    
    self.rootItems.topnode:setPositionY(toppos)

    if self.rootItems.animationnode and toppos >1920 then
        self.rootItems.animationnode:setPositionY((toppos-1920)/2+1920)
    end

    -- self.rootItems.shakeNode:setVisible(false)

    local timeCB = {}
    timeCB["levelup"] = function()
        print("levelup")
        local picName = {}


        local fishpondTemp = gamedata.config.gang2_fishpond

        local dayprogress = self.xianchidata.xc_dayprogress
        local allmilestone = fishpondTemp[tostring(self.gang.level)]
        if dayprogress <  allmilestone.milestone_award1 then
            picName = "zaotang_06"
        elseif dayprogress <  allmilestone.milestone_award2  then
            picName = "zaotang_05"
        elseif dayprogress <  allmilestone.milestone_award3  then
            picName = "zaotang_04"
        else
            picName = "zaotang_03"
        end
        setSpriteFrameByName(self.zaopenrootItems.zoapenpic, picName)
        
    end
    self.zaopenrootNode, self.zaopenrootItems = CCBReaderLoad("UIEffect/zaotang/zaotang_zaopen.ccbi", nil, true, "zaotang_zaopen",timeCB)
    self.rootItems.zaopenNode:addChild(self.zaopenrootNode)



    local phoName = CCSprite:create("public/publicsprite/spr_42.png")

    self.rootItems.starbarProcess = CCProgressTimer:create(phoName)
    self.rootItems.starbarProcess:setAnchorPoint(ccp(0.0, 0.5))
    self.rootItems.starbarProcess:setType(kCCProgressTimerTypeBar)
    self.rootItems.starbarProcess:setMidpoint(ccp(0, 0.5))
    self.rootItems.starbarProcess:setBarChangeRate(ccp(1, 0))
    self.rootItems.starbarProcess:setPosition(ccp(-484, 0.2))
    self.rootItems.starbarProcess:setPercentage(0)
    self.rootItems.starbarProcess:setScaleX(1.145)
    self.rootItems.starbarNode:addChild(self.rootItems.starbarProcess)


    -- self.rootItems.expposProcess = CCProgressTimer:create(phoName)
    -- self.rootItems.expposProcess:setAnchorPoint(ccp(0.0, 0.5))
    -- self.rootItems.expposProcess:setType(kCCProgressTimerTypeBar)
    -- self.rootItems.expposProcess:setMidpoint(ccp(0, 0.5))
    -- self.rootItems.expposProcess:setBarChangeRate(ccp(1, 0))
    -- self.rootItems.expposProcess:setPosition(ccp(-329.0, -129.8))
    -- self.rootItems.expposProcess:setPercentage(0)
    -- self.rootItems.expposProcess:setScaleX(0.99)
    -- self.rootItems.expposNode:addChild(self.rootItems.expposProcess)



    print("guildxianchi.init")
    -- printT(param)
    self.gang = table.copy(param.gang) 


    self.rootItems.backbutton:setTouchPriority(self.buttontouch)
    self.rootItems.backbutton:setSwallowsTouch(true)
    self.rootItems.backbutton:addHandleOfControlEvent(function()
        print("backbutton=")    

        UIRequest({type = 2230,param = "main"})

        

    end, CCControlEventTouchUpInside)
    
    -- ui.setLabelString(self.rootItems.confirmText, nil, 19) 
    -- self.rootItems.confirmBtn:setTouchPriority(self.buttontouch)
    -- self.rootItems.confirmBtn:setSwallowsTouch(true)
    -- self.rootItems.confirmBtn:addHandleOfControlEvent(function()
    --     print("confirmBtn=")
    --     local changedata = {}
    --     local countnum = 0
    --     for i=1,4 do
    --         if self.refine["num"..i] ~= 0 then
    --             table.insert(changedata,{cid = tonumber(self.soapsdata[tonumber(i)].cid), num = self.refine["num"..i]})
    --             countnum = countnum + 1
    --         end
            
    --     end
    --     if  countnum == 0 then
    --         -- runGamePrompt({msg = "未放肥皂"})
    --         runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",1)})
    --         return
    --     end
    --     -- printT(changedata)

    --     UIRequest({type = 2257,changedata = changedata})

    -- end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.confirmText, "一键肥皂", 19) 
    self.rootItems.confirmBtn:setTouchPriority(self.buttontouch)
    self.rootItems.confirmBtn:setSwallowsTouch(true)
    self.rootItems.confirmBtn:addHandleOfControlEvent(function()
        print("confirmBtn=")

        -- self.xianchidata.eattimesnum.."/"..(self.optlimt)

        -- local soapsTemp = {cid = self.soapsdata[tonumber(i)].cid, num = self.soapsdata[tonumber(i)].num}

        if (self.xianchidata.eattimesnum) >= (self.optlimt) then
            runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",4)})
            return
        end

        local changedata = {}
        local countnum = 0
        for i=1,4 do
            if self.soapsdata[tonumber(5-i)].num ~= 0 then
                local tempNum = 0
                if (tonumber(self.xianchidata.eattimesnum) + tonumber(self.soapsdata[tonumber(5-i)].num) + countnum) <= tonumber(self.optlimt) then
                    tempNum = tonumber(self.soapsdata[tonumber(5-i)].num)
                    countnum = countnum + tonumber(self.soapsdata[tonumber(5-i)].num)
                    -- print("add==",tempNum)
                    table.insert(changedata,{cid = tonumber(self.soapsdata[tonumber(5-i)].cid), num = (tempNum or 0)})
                    if countnum + tonumber(self.xianchidata.eattimesnum) == tonumber(self.optlimt) then
                        break
                    end
                    
                else
                    tempNum = tonumber(self.optlimt) - tonumber(self.xianchidata.eattimesnum) - countnum
                    countnum = countnum + tempNum
                    -- print("add==max",tempNum)

                    table.insert(changedata,{cid = tonumber(self.soapsdata[tonumber(5-i)].cid), num = (tempNum or 0)})
                    break
                end
                
            end
        end
        -- print("max===num==",countnum)
        -- printT(changedata)
        if  countnum == 0 then
            -- runGamePrompt({msg = "未放肥皂"})
            -- runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",3)})
            return
        end
        local data = {}
        for i,v in ipairs(changedata) do
            if v.num ~= 0 then
                table.insert(data,v)
            end
        end
        -- printT(data,"data====")

        -- printT(changedata)

        UIRequest({type = 2257,changedata = data})

    end, CCControlEventTouchUpInside)



    self.rootItems.rulebutton:setTouchPriority(self.buttontouch)
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        print("rulebutton=")    

        gameWindows:openWindow("guildxianchirank",{index= "rule"},nil) 

    end, CCControlEventTouchUpInside)

    self.rootItems.ranklistbutton:setTouchPriority(self.buttontouch)
    self.rootItems.ranklistbutton:setSwallowsTouch(true)
    self.rootItems.ranklistbutton:addHandleOfControlEvent(function()
        print("ranklistbutton=")   
         
        gameWindows:openWindow("guildxianchirank",{index= "rank"},nil) 
    end, CCControlEventTouchUpInside)

    ui.setLabelString(self.rootItems.desctext1, nil, 21)

    ui.setLabelString(self.rootItems.desctext2, nil, 14)

    UIRequest({type = 2256})

end



-- function guildxianchi.showGetPoint(self,data)


--     runGamePrompt({msg = "获得公会经验:"..data.gang_exp..",获得公会贡献值:"..data.contribution})
-- end

function guildxianchi.reloaddata(self,data, changedata)
    -- self.beforeNum = data.xc_dayprogress
    if not data then return end
    -- print("changedata===00")
    -- printT(changedata,"changedata===Z")
    if changedata and next(changedata) then
        runGamePrompt({msg = "获得公会经验:"..(changedata.gang_exp or 0)..",获得个人贡献值:"..(changedata.contribution or 0)..",进度增加："..((data.xc_dayprogress or 0)-(self.xianchidata and self.xianchidata.xc_dayprogress or 0))})
    end

    self.xianchidata = data


    local fishpondTemp = gamedata.config.gang2_fishpond
    local fishpondexp = gamedata.config.gang2_fishpondexp
    local fishbait = gamedata.config.gang2_bait

    -- 设置澡盆内肥皂个数 状态
    local dayprogress = self.xianchidata.xc_dayprogress
    local allmilestone = fishpondTemp[tostring(self.gang.level)]
    if dayprogress <  allmilestone.milestone_award1 then
        picName = "zaotang_06"
    elseif dayprogress <  allmilestone.milestone_award2  then
        picName = "zaotang_05"
    elseif dayprogress <  allmilestone.milestone_award3  then
        picName = "zaotang_04"
    else
        picName = "zaotang_03"
    end
    setSpriteFrameByName(self.zaopenrootItems.zoapenpic, picName)


    print("reloaddata===ganglevel==",self.gang.level)
    -- 工会等级，经验进度条
    -- ui.setLabelString(self.rootItems.ganglevel_Label,self.gang.level.."级工会",21)
    ui.setLabelString(self.rootItems.ganglevel_Label,gameConfig.strings:guildLv((self.gang.level or 1)),21)
    -- ui.setLabelString(self.rootItems.exp_Label,self.gang.exp.."/"..gamedata.config.gang2_level[tostring(self.gang.level)].gang_exp,13)
    -- ui.setSpriteTextureRect2(self.rootItems.exppos,0,0,280*(self.gang.exp < gamedata.config.gang2_level[tostring(self.gang.level)].gang_exp and self.gang.exp/gamedata.config.gang2_level[tostring(self.gang.level)].gang_exp or 1),36)


    -- 宝箱领取进度条
    ui.setLabelString(self.rootItems.dayprogressText,nil,14)
    ui.setLabelString(self.rootItems.dayprogress_Label,self.xianchidata.xc_dayprogress,23)
    
    
    local allmilestone = fishpondTemp[tostring(self.gang.level)].milestone
    -- ui.setSpriteTextureRect2(self.rootItems.starbar,0,0,966*(self.xianchidata.xc_dayprogress < allmilestone and self.xianchidata.xc_dayprogress/allmilestone or 1),31)

    -- 设置今日进度条进度
    local processNum = 100*(self.xianchidata.xc_dayprogress < allmilestone and self.xianchidata.xc_dayprogress/allmilestone or 1)
    local greento = CCProgressFromTo:create(0.2,self.firstnum,processNum)
    self.rootItems.starbarProcess:runAction(greento)
    self.firstnum = processNum

    -- printT(fishpondTemp)
    -- printT(fishpondexp)
    -- printT(fishbait)
    -- 仙池等级进度条
    local xianchipro = self.gang.level
    local ganglevelTemp = gamedata.config.gang2_level[tostring(xianchipro)]

    -- 当前鱼塘等级下 在 多少品级时 升级所需经验
    
    -- ui.setLabelString(self.rootItems.xianchiLevel_Label,self.xianchidata.xc_level.."级",18) 
    -- ui.setLabelString(self.rootItems.xianchiLevel_Label,gameConfig.strings:levelGt(self.xianchidata.xc_level),18) 
    -- ui.setLabelString(self.rootItems.xianchiLevelText,nil,18) 

    ui.setLabelString(self.rootItems.eattimesText,nil,14) 
    ui.setLabelString(self.rootItems.eattimes_Label,self.xianchidata.eattimesnum.."/"..(self.optlimt),14)
    -- local needexpNum = fishpondexp[tostring(self.xianchidata.xc_level)]["exp"..(self.xianchidata.xc_quality)]
    -- print("xc_quality==",(self.xianchidata.xc_quality+1))
    -- print("needexpNum==",needexpNum)
    -- ui.setLabelString(self.rootItems.xianchi_exp_Label,self.xianchidata.xc_exp.."/"..needexpNum,14)
    -- self.rootItems.xianchi_exppos:setScaleX(self.xianchidata.xc_exp/needexpNum) 
    -- 设置汤池等级进度条
    -- local xianchiprocessNum = 100*(self.xianchidata.xc_exp < needexpNum and self.xianchidata.xc_exp/needexpNum or 1)
    -- local xianchito = CCProgressFromTo:create(1,90,10)
    -- local xianchito = CCProgressFromTo:create(0.1,self.chifirstnum,xianchiprocessNum)
    -- self.rootItems.expposProcess:runAction(xianchito)
    -- self.chifirstnum = xianchiprocessNum
    


    -- 设置进度特效
    -- local contentsize = self.rootItems.xianchi_exppos:getContentSize().width*(self.xianchidata.xc_exp/needexpNum)
    -- print("contentsize==",contentsize)
    -- print(self.rootItems.xianchi_exppos:getPositionX())
    -- self.rootItems.partical:setPosition(self.rootItems.xianchi_exppos:getPositionX()+contentsize,self.rootItems.xianchi_exppos:getPositionY()) 
    
    -- printT(self.xianchidata)
    
    -- 设置领取宝箱 能领取多少个宝箱（鱼塘等级决定
    for i =1, 4 do
        self:setrewardbox(i)
    end

    -- self:setPropNum()
    -- 肥皂设置
    UIRequest({type = 12001, order = 40001, cids = {20162,20163,20164,20165}})

    
    if (self.xianchidata.eattimesnum) >= (self.optlimt) then
        ui.addGray("CCControlButton",self.rootItems.confirmBtn)
    else
        ui.removeGray("CCControlButton",self.rootItems.confirmBtn)
    end
end

function guildxianchi.setrewardbox(self,itemNum)
    

    local fishpondTemp = gamedata.config.gang2_fishpond
    local fishpondexp = gamedata.config.gang2_fishpondexp
    local fishbait = gamedata.config.gang2_bait


    local nowboxcoreNum = fishpondTemp[tostring(self.gang.level)]["milestone_award"..itemNum]
    local max = fishpondTemp[tostring(self.gang.level)]["milestone_award"..4]
    local distanceNum = 966*(nowboxcoreNum/max)
    print("boxnodedata=",nowboxcoreNum,max,distanceNum)

    self.rootItems["boxNode"..itemNum]:setPosition(-484.0+distanceNum,0)


    setSpriteFrameByName(self.rootItems["box"..itemNum], "box"..self.xianchidata.xc_quality.."_"..self.xianchidata["rewardstatus"..itemNum])
    ui.setLabelString(self.rootItems["boxscore"..itemNum],fishpondTemp[tostring(self.gang.level)]["milestone_award"..itemNum],22)
    print("setrewardboxitem",self.xianchidata["rewardstatus"..itemNum])

    self.rootItems["boxeffect"..itemNum]:removeAllChildrenWithCleanup(true)
    if  self.xianchidata["rewardstatus"..itemNum] == 1 then
        self.rootItems["boxeffect"..itemNum]:removeAllChildrenWithCleanup(true)

        local ccb, item = CCBReaderLoad("UIEffect/baoxiangkelingqu/baoxiangkelingqu.ccbi", nil, true, "baoxiangkelingqu")
        self.rootItems["boxeffect"..itemNum]:addChild(ccb)
        local ccb2, item2 = CCBReaderLoad("UIEffect/lizi/baoxiang.ccbi", nil, true, "baoxiang")
        self.rootItems["boxeffect"..itemNum]:addChild(ccb2)
    end
    self.rootItems["r_button"..itemNum]:setSwallowsTouch(true)
    self.rootItems["r_button"..itemNum]:setTouchPriority(-102)
    self.rootItems["r_button"..itemNum]:addHandleOfControlEvent(function()
        print("itemNum",itemNum)
        print("level",self.xianchidata.xc_level)

        local fishdstring = fishpondTemp[tostring(self.gang.level)]["award"..itemNum]
        fishdata = ui.getIDandNUMs(fishpondTemp[tostring(self.gang.level)]["award"..itemNum])
        print("fishdstring==",fishdstring)
        -- printT(fishdata)
        
        if self.xianchidata["rewardstatus"..itemNum] == 0 then
            gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(fishpondTemp[tostring(self.gang.level)]["award"..itemNum]),type = gameConfig.strings:string_common("task",6)},nil)
        elseif self.xianchidata["rewardstatus"..itemNum] == 1 then
            print("请求服务器id=",itemNum)
            -- if itemNum > self.xianchidata.xc_level then
            --     -- runGamePrompt({msg = "仙池等级不足，无法领取"})
            --     runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",2)})
            --     return
            -- end

            UIRequest({type = 2258, id =itemNum})
        elseif self.xianchidata["rewardstatus"..itemNum] == 2 then
            gameWindows:openWindow("getStaff",{data = ui.getIDandNUMs(fishpondTemp[tostring(self.gang.level)]["award"..itemNum]),type = gameConfig.strings:string_common("moreCommon",5)},nil)
        end
    end, CCControlEventTouchUpInside)

end

function guildxianchi.setPropNum(self,data)
    print("setPropNum====")
    self.data = data
    -- printT(data)
    self.soapsdata = {}
    for k,v in pairs(data) do
        table.insert(self.soapsdata,{cid=k,num=v}) 
    end
    local sortfunction = function( a, b )
        return a.cid < b.cid
    end

    table.sort( self.soapsdata, sortfunction )

    -- printT(self.soapsdata)

    -- for i=1,4 do
    --     ui.setNewIcon(self.rootItems,self.soapsdata[tonumber(i)],i-1)

    --     local key_Ex
    --     if i == 1 then
    --         key_Ex = ""
    --     else
    --         key_Ex = "_"..(i-1)
    --     end
    --     print("key_Ex==",key_Ex)
    --     if self.soapsdata[tonumber(i)].num == 0 then
    --         self.rootItems["i_quality"..key_Ex]:setColor(ccc3(150,150,150))
    --         self.rootItems["i_icon"..key_Ex]:setColor(ccc3(150,150,150))
    --     else
    --         print("this way...")
            
    --         self.rootItems["i_quality"..key_Ex]:setColor(ccc3(255,255,255))
    --         self.rootItems["i_icon"..key_Ex]:setColor(ccc3(255,255,255))
    --     end
    -- end



    self:setNewSoapData()

    -- self:setAddandReduceBtn()
    

end

-- 增加 减少按钮
function guildxianchi.setAddandReduceBtn( self)
    self.refine = nil

    self.refine =
    {
        num1 = 0,
        num2 = 0,
        num3 = 0,
        num4 = 0,

        l_num1 = 0,
        l_num2 = 0,
        l_num3 = 0,
        l_num4 = 0,

        maxNum = 0,
    }
    print("refine.num1=",self.refine.num1)
    -- printT(self.refine)

    for i,v in ipairs(self.soapsdata) do
        self.refine["l_num"..i] = self.soapsdata[tonumber(i)].num
    end


    local beginFunc = function(index)
        print("beginFunc"..index)
        if self.refine["l_num"..index] < 1 then return end

        self["effect_begin"..index] = false
        self["effect_end"..index] = false
        --
        self.rootItems["selectEffectNode"..index]:stopAllActions()
        self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        local qianghuaNode,qianghuaItems = CCBReaderLoad("UIEffect/cailiaoxuanzhong/cailiaoxuanzhong", nil, true, "cailiaoxuanzhong")
        qianghuaNode:setPosition(0,0)
        self.rootItems["selectEffectNode"..index]:addChild(qianghuaNode)
        self.rootItems["selectEffectNode"..index]:setScale(1)
        local animationManager = getAnimationManager(qianghuaItems)
        animationManager:runAnimationsForSequenceNamed("zhenrongxuanzhong")
        --
        self.rootItems["selectEffectNode"..index]:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(function()
            self["effect_begin"..index] = true
            if self["effect_end"..index] then
                self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
            end
        end)))
    end

    local endFunc = function(index)
        print("endFunc"..index)
        self["effect_end"..index] = true
        if self["effect_begin"..index] then
            self.rootItems["selectEffectNode"..index]:removeAllChildrenWithCleanup(true)
        end
    end
    --
    local Func1 = function()
        if self.refine.l_num1 == 0 then
            -- runGamePrompt({msg = "肥皂不足"})
            -- runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",3)})
            gameWindows:openWindow("dropTips",{cid = self.soapsdata[tonumber(1)].cid},nil)
        end
        if self.xianchidata.eattimesnum+self.refine.maxNum+1 > self.optlimt then
            -- runGamePrompt({msg = "今日可用肥皂数，已到最大"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",4)})
            -- runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.refine.l_num1 > 0 then
            print("l_num1==",self.refine.l_num1)
            print("num1==",self.refine.num1)
            print("maxNum==",self.refine.maxNum)
            self.refine.l_num1 = self.refine.l_num1 - 1
            self.refine.num1 = self.refine.num1 + 1
            self.refine.maxNum= self.refine.maxNum + 1
            print("l_num1==",self.refine.l_num1)
            print("num1==",self.refine.num1)
            print("maxNum==",self.refine.maxNum)

        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(1)
        end

        self:setSoapData()
    end

    local Func2 = function()
        if self.refine.l_num2 == 0 then
            -- runGamePrompt({msg = "肥皂不足"})
            -- runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",3)})
            gameWindows:openWindow("dropTips",{cid = self.soapsdata[tonumber(2)].cid},nil)
        end
        if self.xianchidata.eattimesnum+self.refine.maxNum+1 > self.optlimt then
            -- runGamePrompt({msg = "今日可用肥皂数，已到最大"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",4)})
            -- runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.refine.l_num2 > 0 then
            self.refine.l_num2 = self.refine.l_num2-1
            self.refine.num2 = self.refine.num2 + 1
            self.refine.maxNum= self.refine.maxNum + 1
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(2)
        end

        self:setSoapData()
    end

    local Func3 = function()
        if self.refine.l_num3 == 0 then
            -- runGamePrompt({msg = "肥皂不足"})
            -- runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",3)})
            gameWindows:openWindow("dropTips",{cid = self.soapsdata[tonumber(3)].cid},nil)
        end
        if self.xianchidata.eattimesnum+self.refine.maxNum+1 > self.optlimt then
            -- runGamePrompt({msg = "今日可用肥皂数，已到最大"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",4)})
            -- runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.refine.l_num3 > 0 then
            self.refine.l_num3 = self.refine.l_num3-1
            self.refine.num3 = self.refine.num3 + 1
            self.refine.maxNum= self.refine.maxNum + 1
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(3)
        end

        self:setSoapData()
    end

    local Func4 = function()
        if self.refine.l_num4 == 0 then
            -- runGamePrompt({msg = "肥皂不足"})
            -- runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",3)})
            gameWindows:openWindow("dropTips",{cid = self.soapsdata[tonumber(4)].cid},nil)
        end
        if self.xianchidata.eattimesnum+self.refine.maxNum+1 > self.optlimt then
            -- runGamePrompt({msg = "今日可用肥皂数，已到最大"})
            runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",4)})
            -- runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",17)})
            return
        end

        if self.refine.l_num4 > 0 then
            self.refine.l_num4 = self.refine.l_num4-1
            self.refine.num4 = self.refine.num4 + 1
            self.refine.maxNum= self.refine.maxNum + 1
        else
            --runGamePrompt({msg = "材料已消耗完"})
            runGamePrompt({msg = gameConfig.strings:string_common("equipInfo",18)})
            endFunc(4)
        end

        self:setSoapData()
    end

    local reduce1 = function()
        if self.refine.num1 == 0 then
            return
        end
        print("reduce1===")
        if self.refine.num1 > 0 then
            print("enter1...")
            self.refine.l_num1 = self.refine.l_num1+1
            self.refine.num1 = self.refine.num1 - 1
            self.refine.maxNum= self.refine.maxNum - 1
        end
        print("l_num1==",self.refine.l_num1)
        print("num1==",self.refine.num1)

        self:setSoapData()
    end

    local reduce2 = function()
        if self.refine.num2 == 0 then
            return
        end

        if self.refine.num2 > 0 then
            self.refine.l_num2 = self.refine.l_num2+1
            self.refine.num2 = self.refine.num2 - 1
            self.refine.maxNum= self.refine.maxNum - 1
        end
        self:setSoapData()
    end
    local reduce3 = function()
        if self.refine.num3 == 0 then
            return
        end

        if self.refine.num3 > 0 then
            self.refine.l_num3 = self.refine.l_num3+1
            self.refine.num3 = self.refine.num3 - 1
            self.refine.maxNum= self.refine.maxNum - 1
        end

        self:setSoapData()
    end
    local reduce4 = function()
        if self.refine.num4 == 0 then
            return
        end
        if self.refine.num4 > 0 then
            self.refine.l_num4 = self.refine.l_num4+1
            self.refine.num4 = self.refine.num4 - 1
            self.refine.maxNum= self.refine.maxNum - 1
        end

        self:setSoapData()
    end
    print("aaaaaa====")
    -- printT(self.rootItems)
    if self.delayButtonStatus then
        ui.creatDelayButton(self.rootItems.add1,-102,Func1,beginFunc,endFunc,1)
        ui.creatDelayButton(self.rootItems.add2,-102,Func2,beginFunc,endFunc,2)
        ui.creatDelayButton(self.rootItems.add3,-102,Func3,beginFunc,endFunc,3)
        ui.creatDelayButton(self.rootItems.add4,-102,Func4,beginFunc,endFunc,4)

        ui.creatDelayButton(self.rootItems.reduce1,-102,reduce1)
        ui.creatDelayButton(self.rootItems.reduce2,-102,reduce2)
        ui.creatDelayButton(self.rootItems.reduce3,-102,reduce3)
        ui.creatDelayButton(self.rootItems.reduce4,-102,reduce4)
    end
    self.delayButtonStatus = false

    self:setSoapData()
end

function guildxianchi.setSoapData( self )
    print("setSoapData===")

    print("maxNum==",self.refine.maxNum)
    for i=1,4 do
        local soapsTemp = {cid = self.soapsdata[tonumber(i)].cid, num = self.refine["l_num"..i]}
        ui.setNewIcon(self.rootItems,soapsTemp,i-1)

        ui.setLabelString(self.rootItems["numlabel"..i],self.refine["num"..i],13)

        local key_Ex
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        print("key_Ex==",key_Ex)
        if self.soapsdata[tonumber(i)].num == 0 then
            self.rootItems["i_quality"..key_Ex]:setColor(ccc3(150,150,150))
            self.rootItems["i_icon"..key_Ex]:setColor(ccc3(150,150,150))
        else
            print("this way...")
            
            self.rootItems["i_quality"..key_Ex]:setColor(ccc3(255,255,255))
            self.rootItems["i_icon"..key_Ex]:setColor(ccc3(255,255,255))
        end
        
    end
    -- 预算今日使用肥皂个数。
    ui.setLabelString(self.rootItems.eattimes_Label,(self.xianchidata.eattimesnum+self.refine.maxNum).."/"..(self.optlimt),14)
    


    if self.refine.num1> 0 then
        self.rootItems.reduceNode1:setVisible(true)
    else
        self.rootItems.reduceNode1:setVisible(false)
    end
    if self.refine.num2 > 0 then
        self.rootItems.reduceNode2:setVisible(true)
    else
        self.rootItems.reduceNode2:setVisible(false)
    end
    if self.refine.num3 > 0 then
        self.rootItems.reduceNode3:setVisible(true)
    else
        self.rootItems.reduceNode3:setVisible(false)
    end
    if self.refine.num4 > 0 then
        self.rootItems.reduceNode4:setVisible(true)
    else
        self.rootItems.reduceNode4:setVisible(false)
    end
end

function guildxianchi.setNewSoapData( self )
    print("setSoapData===")
    printT(self.soapsdata)

    -- print("maxNum==",self.refine.maxNum)
    for i=1,4 do
        local soapsTemp = {cid = self.soapsdata[tonumber(i)].cid}
        ui.setNewIcon(self.rootItems,soapsTemp,i-1)

        ui.setLabelString(self.rootItems["numlabel"..i],self.soapsdata[tonumber(i)].num,13)

        local key_Ex
        if i == 1 then
            key_Ex = ""
        else
            key_Ex = "_"..(i-1)
        end
        print("key_Ex==",key_Ex)
        if self.soapsdata[tonumber(i)].num == 0 then
            self.rootItems["i_quality"..key_Ex]:setColor(ccc3(150,150,150))
            self.rootItems["i_icon"..key_Ex]:setColor(ccc3(150,150,150))
        else
            print("this way...")
            
            self.rootItems["i_quality"..key_Ex]:setColor(ccc3(255,255,255))
            self.rootItems["i_icon"..key_Ex]:setColor(ccc3(255,255,255))
        end

        
        self.rootItems["i_button"..key_Ex]:setSwallowsTouch(true)
        self.rootItems["i_button"..key_Ex]:setTouchPriority(self.buttontouch)
        self.rootItems["i_button"..key_Ex]:addHandleOfControlEvent(function()
            print("扔肥皂")
            if self.soapsdata[tonumber(i)].num == 0 then
                gameWindows:openWindow("dropTips",{cid = self.soapsdata[tonumber(i)].cid},nil)
            elseif (self.xianchidata.eattimesnum) >= (self.optlimt) then
                runGamePrompt({msg = gameConfig.strings:string_common("guild_xianchi",4)})
            else
                local changedata = {}
                table.insert(changedata,{cid = self.soapsdata[tonumber(i)].cid, num = 1})
                    
                UIRequest({type = 2257,changedata = changedata})
            end
            
            
        end, CCControlEventTouchUpInside)

        
    end
    -- 预算今日使用肥皂个数。
    ui.setLabelString(self.rootItems.eattimes_Label,(self.xianchidata.eattimesnum).."/"..(self.optlimt),14)
    


    -- if self.refine.num1> 0 then
    --     self.rootItems.reduceNode1:setVisible(true)
    -- else
    --     self.rootItems.reduceNode1:setVisible(false)
    -- end
    -- if self.refine.num2 > 0 then
    --     self.rootItems.reduceNode2:setVisible(true)
    -- else
    --     self.rootItems.reduceNode2:setVisible(false)
    -- end
    -- if self.refine.num3 > 0 then
    --     self.rootItems.reduceNode3:setVisible(true)
    -- else
    --     self.rootItems.reduceNode3:setVisible(false)
    -- end
    -- if self.refine.num4 > 0 then
    --     self.rootItems.reduceNode4:setVisible(true)
    -- else
    --     self.rootItems.reduceNode4:setVisible(false)
    -- end
end

function guildxianchi.ganglevelup(self, data)
    print("工会升级特效播放")
    -- printT(data)
    -- ui.setLabelString(self.rootItems.ganglevel_Label,data.gang_level.."级工会",21)
    self.gang.level = data.gang_level
    ui.setLabelString(self.rootItems.ganglevel_Label,gameConfig.strings:guildLv(data.gang_level),21)
end

function guildxianchi.xianchilevelup(self, data)
    print("仙池等级升级特效播放")
    -- 设置仙池进度条初始数字
    -- self.chifirstnum = 0

    paizirootNode, paizirootItems = CCBReaderLoad("UIEffect/huanpaizi/huanpaizi.ccbi", nil, true, "huanpaizi")
    self.rootItems.paiziNode:addChild(paizirootNode)
    local xianchilevestring = {}
    if data.xc_level == 1 then
        xianchilevestring = "gonghui_pai3"
    elseif data.xc_level == 2 then
        xianchilevestring = "gonghui_pai2"
    elseif data.xc_level == 3 then
        xianchilevestring = "gonghui_pai1"
    elseif data.xc_level == 4 then
        xianchilevestring = "gonghui_pai0"
    end
    setSpriteFrameByName(self.rootItems.paiziPic, xianchilevestring)
    
end

function guildxianchi.xianchiqualityup(self, data)
    print("仙池品级升级特效播放")

end



function guildxianchi.delayfunction(self)
    self.rootNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1.0), CCCallFunc:create(function()
        print("call...back====")
        self:actionSoap()
    end)))
end


function guildxianchi.actionSoap(self,data, rewards)
    print("播放掉肥皂动画")
    -- printT(data)
    local rollnum = {0,1,1,1,1}
    math.randomseed(gamedata:time())
    local delayNum = math.random(1,#rollnum)
    delayNum = math.random(1,#rollnum)
    delayNum = math.random(1,#rollnum)

    local num = rollnum[delayNum]
    print("actionSoapnum===",num,delayNum)

    
    -- self.rootItems.taibaiNode:removeAllChildrenWithCleanup(true)
    self.rootItems.taibaiNode:setVisible(true)
    if self.rootItems.taimeiNode then
        self.rootItems.taimeiNode:removeAllChildrenWithCleanup(true)
    end
    

    if num == 0 then
        self.taimeirootNode, self.taimeirootItems = CCBReaderLoad("UIEffect/zaotang/zaotang_baimei.ccbi", nil, true, "zaotang_baimei")
        self.rootItems.taimeiNode:addChild(self.taimeirootNode) 

        self.rootItems.taibaiNode:setVisible(false)

        self.animationManager = getAnimationManager(self.rootItems)
        self.animationManager:runAnimationsForSequenceNamed("shake")


        self.animationTaimeiManager = getAnimationManager(self.taimeirootItems)
        self.animationTaimeiManager:setAnimationCompletedCallback(function()
            print("complete11")
            self.rootItems.taimeiNode:removeAllChildrenWithCleanup(true)
            self.rootItems.taibaiNode:setVisible(true)
            -- if next(data) then
            --     runGamePrompt({msg = "获得公会经验:"..data.gang_exp..",获得公会贡献值:"..data.contribution})
            -- end
            -- if next(rewards) then
            --     showRewardPopupWindow(rewards,nil,nil)
            -- end

            self.animationManager = getAnimationManager(self.taibairootItems)
            self.animationManager:runAnimationsForSequenceNamed("zaotang_taibai")

            self.animationManager = getAnimationManager(self.zaopenrootItems)
            self.animationManager:setAnimationCompletedCallback(function()
                print("complete22")

                
            end)
            self.animationManager:runAnimationsForSequenceNamed("zaotang_zaopen")

            

        end)
        self.animationTaimeiManager:runAnimationsForSequenceNamed("zaotang_baimei2")
    else

        self.animationManager = getAnimationManager(self.taibairootItems)
        self.animationManager:setAnimationCompletedCallback(function()
            print("complete1")
            -- if next(data) then
            --     runGamePrompt({msg = "获得公会经验:"..data.gang_exp..",获得公会贡献值:"..data.contribution})
            -- end
            -- if next(rewards) then
            --     showRewardPopupWindow(rewards,nil,nil)
            -- end
            self.animationManager = getAnimationManager(self.taibairootItems)
            self.animationManager:runAnimationsForSequenceNamed("zaotang_taibai")
            self.animationManager = getAnimationManager(self.zaopenrootItems)
            self.animationManager:setAnimationCompletedCallback(function()
                print("complete2")

                
            end)
            self.animationManager:runAnimationsForSequenceNamed("zaotang_zaopen")

            

        end)
        self.animationManager:runAnimationsForSequenceNamed("zaotang_taibai2")
    end

    

end



function guildxianchi.clear(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.taibairootItems = nil
    self.zaopenrootItems = nil
    self.delayButtonStatus = true
    -- self.beforeNum = 0
end


function guildxianchi.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 2256})
    end
end


return guildxianchi