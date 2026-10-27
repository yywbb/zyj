--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/8/28
-- Time: 下午3:28
-- To change this template use File | Settings | File Templates.
--

local island = {

    rootNode = nil,
    rootItems = nil,
    chuansongNode = nil,
    chuansongItems = nil,

    ccbNodes = {},

    -- roll到的数
    rollNum = 0,
    -- 初始化时获取的数据
    config = nil,
    -- 移动过程中的上一次点集
    prelocationNum = {},

    movetype = false,
    deadtype = false,
    completetype = false,

    zhuanpanData =
    {
        [1] = {start = 0,ended=29-15,numdata={1}},
        [2] = {start = 30-15,ended=89-15,numdata={1,2}},
        [3] = {start = 90-15,ended=119-15,numdata={2}},
        [4] = {start = 120-15,ended=179-15,numdata={2,3}},
        [5] = {start = 180-15,ended=209-15,numdata={3}},
        [6] = {start = 210-15,ended=269-15,numdata={3,4}},
        [7] = {start = 270-15,ended=299-15,numdata={4}},
        [8] = {start = 300-15,ended=359-15,numdata={1,4}},
        [9] = {start = 360-15,ended=359,numdata={1}},
    },
}


function island.init(self,parent,toppos)
   	self.rootNode,self.rootItems = CCBReaderLoad("island2/island2", nil, true, "island2")
   	self.rootNode:setPosition(0,0)
   	parent:addChild(self.rootNode)

    self.rootItems.container:setContentSize(CCSize(1395,3008))
    self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setTouchPriority(-101)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(0,0),0)

    print("island2.init")
    local t = os.date("*t", os.time())
    -- printT(t)
    local wdayNum = 1
    if t.wday == 1 then
        wdayNum = 7
    else
        wdayNum = t.wday - 1
    end

    local ccbName = "island2/"..gamedata.config.penglai2_map0[tostring(wdayNum)].ccb


    self.chuansongNode, self.chuansongItems = CCBReaderLoad(ccbName, nil, true, "map2")
    self.chuansongNode:setPosition(0,0)
    self.rootItems.container:addChild(self.chuansongNode)


    self.rootItems.topnode:setPositionY(toppos)
    -- self.rootItems.scrollnode = tolua.cast(self.rootItems.scrollnode, "CCScrollView")
    self.rootItems.scrollnode:setViewSize(CCSizeMake(gameConfig.originSize.width,toppos-160))
    -- self.rootItems.scrollnode:

    -- 转盘是否出现状态
	self.stuteType = true
    -- 是否可点击开始安装转动
    self.turnType = true

    self.movetype =false

    -- 定时器 纪录num
    self.updateNum = 0

    -- ui.setLabelString(self.rootItems.turntext,nil,19)

    -- self:zhuanpanStateAction("hidewheel")
    -- 规则介绍按钮
    self.rootItems.rulebutton:setSwallowsTouch(true)
    self.rootItems.rulebutton:setTouchPriority(-102)
    self.rootItems.rulebutton:addHandleOfControlEvent(function()
        print("i..am.....rulebutton..end")
        gameWindows:openWindow("penglaiResult",{index= "ruleview",data = {}},nil)
        
    end, CCControlEventTouchUpInside)

    -- 成就系统
    self.rootItems.pointbutton:setSwallowsTouch(true)
    self.rootItems.pointbutton:setTouchPriority(-102)
    self.rootItems.pointbutton:addHandleOfControlEvent(function()
        print("i..am.....pointbutton..end")
         -- runGamePrompt({msg = "暂未开启"})
        gameWindows:openWindow("penglaiReward",{point = self.config.island.PointWeek , movetype = self.movetype},nil)
        self.movetype = false
    end, CCControlEventTouchUpInside)

    -- roll骰子特效
    local ccCCB, item = CCBReaderLoad("UIEffect/shaizi/shaizi.ccbi", nil, true, "shaizi")
    ccCCB:setAnchorPoint(ccp(0.0,0.0))
    ccCCB:setPosition(ccp(0,0))
    self.rootItems.rolleffectNode:addChild(ccCCB)

    -- roll骰子按钮

    self.rollType = false
    self.rootItems.rollBtn:setSwallowsTouch(true)
    self.rootItems.rollBtn:setTouchPriority(-102)
    self.rootItems.rollBtn:addHandleOfControlEvent(function()
        print("i..am.....rollBtn..end")
        
        print("self.deadtype==",self.deadtype)

        if self.deadtype then return end
        if self.completetype then return end
        if self.rollType then return end
        if self.rollNum ~= 0 then return end

        self.rollType = true


        

        self.animationManager = getAnimationManager(item)
        self.animationManager:setAnimationCompletedCallback(function()
            print("complete1")
            local globconfig = gamedata.config.global_kv
            local randomnum = 6

            if self.config.island.Dayfreenum >= tonumber(globconfig.penglaixiandao_dice_free.value) then
                randomnum = 4
            end
            
            math.randomseed(os.time())
            local delayNum = math.random(1,randomnum)
            local frameName = "shaizi"..delayNum
            print("frameName==",frameName)

            setSpriteFrameByName(item.rollFrame, frameName)

            -- self.rootItems.shaiziFrame:setVisible(true)
            self.rollType = false

            self:rollaction(delayNum)

        end)
        self.animationManager:runAnimationsForSequenceNamed("rolleffect")

    end, CCControlEventTouchUpInside)




    -- 显示隐藏转盘按钮
    -- self.rootItems.startGameBtn:setSwallowsTouch(true)
    -- self.rootItems.startGameBtn:setTouchPriority(-102)
    -- self.rootItems.startGameBtn:addHandleOfControlEvent(function()
    --     print("i..am.....startGameBtn..end")
    --     print("self.deadtype==",self.deadtype)
    --     if self.deadtype then return end
    --     if self.completetype then return end


    --     -- self.rootItems.zhuanpanNode:setVisible(true)
    --     self.rootItems.timeNumLabel:setString(10)
    --     gameTimer:UnrigistTimeFunc("islandrollnum")
    --     if self.rollNum ~= 0 then

    --     elseif self.stuteType then  
    --         self.stuteType = false
    --         self:zhuanpanStateAction("showwheel")
    --     else
    --         self.stuteType = true
    --         self:zhuanpanStateAction("hidewheel")
    --     end
    --     -- 每次点击 初始化转盘旋转状态
    --     self.turnType = true
        
    -- end, CCControlEventTouchUpInside)

    -- 加入转盘按钮特效
    -- local ccCCB, item = CCBReaderLoad("UIEffect/zhujiemian/huodong.ccbi", nil, true, "huodong")
    -- ccCCB:setAnchorPoint(ccp(0.0,0.0))
    -- ccCCB:setPosition(ccp(0,0))
    -- self.rootItems.rolleffectNode:addChild(ccCCB)

    -- 转盘开始 暂停按钮
    -- self.rootItems.turnBtn:setSwallowsTouch(true)
    -- self.rootItems.turnBtn:setTouchPriority(-102)
    -- self.rootItems.turnBtn:addHandleOfControlEvent(function()
    --     print("i..am.....turnBtn..end")
    --     if not self.stuteType then  
    --         self:turnAction()
    --     end
    -- end, CCControlEventTouchUpInside)

    

    -- 几个传送门按钮 响应
    self.chuansongItems.chuansongBtn:setSwallowsTouch(true)
    self.chuansongItems.chuansongBtn:setTouchPriority(-102)
    self.chuansongItems.chuansongBtn:addHandleOfControlEvent(function()
        print("i..am.chuansongBtn.上")
        print("rollnum:",self.rollNum)
        print("status:",self.config.island.status)

        if not self.stuteType then return end

        if self.config.island.location == 51 then
            return
        end
        if self.rollNum == 0 and self.config.island.status == 1 then
            local callback = function()
            
                local fromnum = self.config.island.location
                local tonum = 51
                print("fromnum...=",fromnum)
                print("tonum...=",tonum)
                UIRequest({type = 2111 ,from = fromnum, to = tonum})
                self.movetype = true
            end
            -- gameWindows:openWindow("confirm",{msg = "是否10花费元宝传送"},callback)
            gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("island",1)},callback)
        end
        
    end, CCControlEventTouchUpInside)

    self.chuansongItems.chuansongBtn_1:setSwallowsTouch(true)
    self.chuansongItems.chuansongBtn_1:setTouchPriority(-102)
    self.chuansongItems.chuansongBtn_1:addHandleOfControlEvent(function()
        print("i..am.....chuansongBtn_1..下")
        if not self.stuteType then return end
        if self.config.island.location == 52 then
            return
        end
        if self.rollNum == 0 and self.config.island.status == 1 then
            local callback = function()
            
                local fromnum = self.config.island.location
                local tonum = 52
                print("fromnum...=",fromnum)
                print("tonum...=",tonum)
                UIRequest({type = 2111 ,from = fromnum, to = tonum})
                self.movetype = true
            end
            -- gameWindows:openWindow("confirm",{msg = "是否10花费元宝传送"},callback)
            gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("island",1)},callback)
        end
        
    end, CCControlEventTouchUpInside)


    UIRequest({type = 2110})
end


function island.rollaction( self, rollnum )
    print("num====",rollnum)

    self.rollNum = rollnum

    local rollcallback = function( )
        -- 飘字消失后再走动
        print("i..am..callback")
        self:creatdirectionBtn(self.config.island.location)
    end
    -- runGamePrompt({msg = "你掷了"..self.rollNum.."步"},rollcallback)
    runGamePrompt({msg = gameConfig.strings:runNum(self.rollNum)})

    gameTimer:rigistTime("islandrolldirection", 1)
    gameTimer:rigistTimeFunc("islandrolldirection",function()
    
        if gameTimer.times["islandrolldirection"] == 0 then
            print("i..am..islandrolldirection..callback")
            self:creatdirectionBtn(self.config.island.location)
        end
    end)

    -- printT(self.config.island)
    print("prelocation:",self.config.island.prelocation)
    print("location:",self.config.island.location)
    self.prelocationNum = {}
    table.insert(self.prelocationNum,self.config.island.prelocation)
    -- table.insert(self.prelocationNum,41)
    table.insert(self.prelocationNum,self.config.island.location)
    -- printT(self.prelocationNum)
    -- self.rootItems.turnhand:setRotation(x)
end

-- 显示／隐藏转盘
function island.zhuanpanStateAction( self, typekey )
    local animationManager = getAnimationManager(self.rootItems)
    animationManager:setAnimationCompletedCallback(function()
        print("i...am...zhuanpanStateAction.....")
    end)
    animationManager:runAnimationsForSequenceNamed(typekey)
    -- ui.setLabelString(self.rootItems.turntext, "开 始", 19)
    -- ui.setLabelString(self.rootItems.turntext, gameConfig.strings:string_common("island",2), 19)
    -- self.rootItems.turntext:setString(gameConfig.strings:string_common("island",2))
end

-- 转盘转动
function island.turnAction(self)
    print("i...am....turnAction...")
    if self.turnType then
        self.turnType = false
        -- self.rootItems.turntext:setString("停 止")
        -- ui.setLabelString(self.rootItems.turntext, "停 止", 19)
        -- ui.setLabelString(self.rootItems.turntext, gameConfig.strings:string_common("island",3), 19)
        self.rootItems.turntext:setString(gameConfig.strings:string_common("island",3))
        math.randomseed(os.time())
        local delayNum = math.random(2,4)
        local action = CCRotateBy:create(delayNum, 360)
        -- local easeAction = CCEaseCubicActionInOut:create(action)
        local runForeverAction = CCRepeatForever:create(action)

        self.rootItems.turnhand:runAction(runForeverAction)
        -- 开启定时器
        self:updateTimer()
    else
        gameTimer:UnrigistTimeFunc("islandrollnum")
        self.turnType = true
        -- self.rootItems.turntext:setString("开 始")
        -- ui.setLabelString(self.rootItems.turntext, "开 始", 19)
        -- ui.setLabelString(self.rootItems.turntext, gameConfig.strings:string_common("island",2), 19)
        self.rootItems.turntext:setString(gameConfig.strings:string_common("island",2))

        self.rootItems.turnhand:stopAllActions()
        local x = self.rootItems.turnhand:getRotation()
        local y = x%360
        local getNUm = math.floor(y)
        print("getNUm...is...:",getNUm)

        local rollNumdata = {}

        for i,v in ipairs(self.zhuanpanData) do
            if getNUm > v.start or getNUm == v.start then
                if getNUm < v.ended or getNUm == v.ended then
                    -- printT(v.numdata)
                    rollNumdata = v.numdata
                    break
                end
            end
        end
        print("....this...is...roNum...:",getNUm)
        math.randomseed(os.time())
        local delayNum = math.random(1,#rollNumdata)

        self.rollNum = rollNumdata[delayNum]
        -- 设置可走步数显示
        self.rootItems.stepLabel:setString(self.rollNum)

        print("i...am...delayNum...:",delayNum)
        print("i...am...rollNum...:",self.rollNum)


        local rollcallback = function( )
            -- 飘字消失后再走动
            print("i..am..callback")
            self:creatdirectionBtn(self.config.island.location)
        end
        -- runGamePrompt({msg = "你掷了"..self.rollNum.."步"},rollcallback)
        runGamePrompt({msg = gameConfig.strings:runNum(self.rollNum)})


        gameTimer:rigistTime("islandrolldirection", 1)
        gameTimer:rigistTimeFunc("islandrolldirection",function()
        
            if gameTimer.times["islandrolldirection"] == 0 then
                print("i..am..islandrolldirection..callback")
                self:creatdirectionBtn(self.config.island.location)
            end
        end)

        -- 隐藏转盘
        self.stuteType = true
        self:zhuanpanStateAction("hidewheel")
        -- printT(self.config.island)
        print("prelocation:",self.config.island.prelocation)
        print("location:",self.config.island.location)
        self.prelocationNum = {}
        table.insert(self.prelocationNum,self.config.island.prelocation)
        -- table.insert(self.prelocationNum,41)
        table.insert(self.prelocationNum,self.config.island.location)
        -- printT(self.prelocationNum)
        self.rootItems.turnhand:setRotation(x)
    end  
end

function island.updateTimer(self)

    gameTimer:rigistTime("islandrollnum",10)
    if gameTimer.times["islandrollnum"] and gameTimer.times["islandrollnum"] ~= 0 then
        gameTimer:rigistTimeFunc("islandrollnum",function()
            print("i..am..Timer:",gameTimer.times["islandrollnum"])

            self.rootItems.timeNumLabel:setString(gameTimer.times["islandrollnum"])

            if  gameTimer.times["islandrollnum"] == 0 then
                self:turnAction()
                gameTimer:UnrigistTimeFunc("islandrollnum")
            end

                -- for k,v in pairs(self.wipetimes) do
                --     v.node:setVisible(true)
                --     v.label:setString(ui.makeTimeText(gameTimer.times["islandrollnum"],"minute"))
                -- end
        end)
    end
end

function island.reload(self,data)
    print("i...am..reload....")

    self.config = data
    local xxxx = 0
    local mapdata = self.config.island.mapStatus
    local lengthNum = table.getTableLength(mapdata)
    print("lengthNum===",lengthNum)
    -- printT(mapdata)
    for i=1,lengthNum do
        local pointdata = self.config.island.mapStatus[tostring(i)]
        print("fori==",i)
        -- printT(pointdata)
        if pointdata.type == 0 then
            pointdata.status = 999
        elseif pointdata.status ~= 999 then
            if self["itemsCCB"..i] == nil then
                print("forii==",i)
                local goodsName = gamedata.config.penglai2_type[tostring(pointdata.type)]
                -- printT(goodsName)
                local ccbname = "island2/icon_"..goodsName.type
                -- pointCCB , self["itemsCCB"..i] = CCBReaderLoad(ccbname, nil, true, goodsName.type)
                -- self.chuansongItems["p"..i]:addChild(pointCCB)
                self.ccbNodes[i], self["itemsCCB"..i] = CCBReaderLoad(ccbname, nil, true, goodsName.type)
                self.chuansongItems["p"..i]:addChild(self.ccbNodes[i])
                
                self.chuansongItems["p"..i]:setScale(1.5)

                if goodsName.type == "box" then
                    self["itemsCCB"..i].s_icon:setScale(0.6)
                    print("ccbname1===",ccbname)
                    -- 把宝箱图片 换成对应的 物品图片
                    local propsdata = ui.getIDandNUMs(goodsName.param)
                    -- printT(propsdata) 
                    local config = ui.IDconfig(propsdata[1].cid)
                    -- printT(config)

                    setSpriteFrameByName(self["itemsCCB"..i].s_icon, config.icon)
                    
                    self["itemsCCB"..i]["box_button"]:setSwallowsTouch(true)
                    self["itemsCCB"..i]["box_button"]:setTouchPriority(-101)
                    self["itemsCCB"..i]["box_button"]:addHandleOfControlEvent(function()
                        print("prop.type=",goodsName.type)
                        print("self.deadtype==",self.deadtype)
                        if not self.stuteType then return end
                        if self.deadtype then return end
                        if self.completetype then return end



                        if ui.getIDandNUMs(goodsName.param)[1] == "1001" or ui.getIDandNUMs(goodsName.param)[1] == "1000" then
                            return
                        end
                        -- printT(ui.getIDandNUMs(goodsName.param))
                        gameWindows:openWindow("propInfo", {prop = ui.getIDandNUMs(goodsName.param)[1], pagetype = "info"})
                            
                    end, CCControlEventTouchUpInside)

                elseif goodsName.type == "prop" then

                    print("ccbname2===",ccbname)
                    print(goodsName.param)
                    -- printT(ui.getTableFromStr(goodsName.param))

                    self["itemsCCB"..i]["prop_button"]:setSwallowsTouch(true)
                    self["itemsCCB"..i]["prop_button"]:setTouchPriority(-101)
                    self["itemsCCB"..i]["prop_button"]:addHandleOfControlEvent(function()
                        print("itemsCCB.type=",pointdata.type)
                        print("self.deadtype==",self.deadtype)
                        if not self.stuteType then return end
                        if self.deadtype then return end
                        if self.completetype then return end

                        gameWindows:openWindow("getStaff",{data = ui.getTableFromStr(goodsName.param),type = gameConfig.strings:string_common("task",7)},nil)
                    end, CCControlEventTouchUpInside)

                elseif goodsName.type == "monster" or goodsName.type == "brave" or goodsName.type == "boss" then
                    self["itemsCCB"..i][goodsName.type.."_button"]:setSwallowsTouch(true)
                    self["itemsCCB"..i][goodsName.type.."_button"]:setTouchPriority(-101)
                    self["itemsCCB"..i][goodsName.type.."_button"]:addHandleOfControlEvent(function()
                        print("itemsCCB.type=",goodsName.type)
                        print("self.deadtype==",self.deadtype)
                        if not self.stuteType then return end
                        if self.deadtype then return end
                        if self.completetype then return end
                        
                        local positionx = self.chuansongItems["p"..i]:getPositionX()
                        local positiony = self.chuansongItems["p"..i]:getPositionY()

                        print("just one...")
                        local talkstring = {}
                        if goodsName.type == "monster" then
                            -- talkstring = "想要积分吗？快挑战我把！"
                            talkstring = gameConfig.strings:string_common("island",4)
                        elseif goodsName.type == "brave" then
                            -- talkstring = "不要打我，我不爆东西的！"
                            talkstring = gameConfig.strings:string_common("island",5)
                        elseif goodsName.type == "boss" then
                            -- talkstring = "不要挑战我，否则你会死的很难看！"
                            talkstring = gameConfig.strings:string_common("island",6)
                        end


                        if self.ccb then
                            self.item.content:setString(talkstring)
                            self.animationManager = getAnimationManager(self.item )
                            -- self.animationManager:setAnimationCompletedCallback(function()
                            --     print("complete1")

                            -- end)
                            self.animationManager:runAnimationsForSequenceNamed("talk")

                            self.chuansongItems.pipaoNode:setPosition(positionx, positiony)
                            return
                        end


                        self.ccb,self.item = CCBReaderLoad("MainScene/tishi", nil, true, "tishi")
                        self.chuansongItems.pipaoNode:addChild(self.ccb)
                        self.chuansongItems.pipaoNode:setPosition(positionx, positiony)

                    end, CCControlEventTouchUpInside)
                end

            end
            
        elseif pointdata.status == 999 then
            self.chuansongItems["p"..i]:setVisible(false)
        end
        -- 隐藏所有 步数点
        if self["itemsCCB"..i] and self["itemsCCB"..i].step_Label then
            print("i...am...===",i)
            -- printT(self["itemsCCB"..i])
            self["itemsCCB"..i].step_Label:setVisible(false)
        end
        
    end


    -- 设置角色
    local nowLocationX = self.chuansongItems["p"..self.config.island.location]:getPositionX()
    local nowLocationY = self.chuansongItems["p"..self.config.island.location]:getPositionY()
    -- local nowLocation = self.chuansongItems["p"..self.config.island.location]:getPosition()
    print("nowLocationx...num...is..:",nowLocationX)
    print("nowLocationy...num...is..:",nowLocationY)
    print("location...num...is..:",self.config.island.location)
    if self.stepGneral == nil then
        local generalName = gamedata.config.generalanimation[tostring(gamedata.config.general[tostring(GameScene.protagonist.general.cid)].animationid)].name
        self.stepGneral = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
        self.stepGneral:setAnimation("stand",true,0)
        self.stepGneral:setScale(0.65)
        self.chuansongItems.generalNode:addChild(self.stepGneral)
    end
    self.chuansongItems.generalNode:setPosition(nowLocationX,nowLocationY)

    self:setViewPointCenter()
    self.completetype = false
    if self.config.island.status == 999 and self.config.island.rewardStatus == 2 then
        gameWindows:openWindow("penglaiResult",{index= "complete",data = self.config},nil)
        self.completetype = true
    elseif self.config.island.status == 999 and self.config.island.rewardStatus ~= 2 then
        UIRequest({type = 2113})
        self.completetype = true
    end

    self:setOpenWindow()

    self:setStatus()

    self:setStepNums()
end

-- 设置四步以内 标示
function island.setStepNums( self )
    
    -- 当本次事件完成后才触发
    local nowpoint = self.config.island.location
    local pointdata = self.config.island.mapStatus[tostring(nowpoint)]
    local preNum = self.config.island.prelocation
    print("nowpoint==",nowpoint)
    -- printT(self.config.island.mapStatus)
    -- printT(pointdata)

    if nowpoint ==51 or nowpoint == 52 or pointdata.status == 0 or pointdata.status == 999 then
        local t = os.date("*t", os.time())
        -- printT(t)
        local wdayNum = 1
        if t.wday == 1 then
            wdayNum = 7
        else
            wdayNum = t.wday - 1
        end
        print("wdayNum=",wdayNum)

        local linkTemp = gamedata.config[tostring(gamedata.config.penglai2_map0[tostring(wdayNum)].config)]
        local linkdata = linkTemp[tostring(nowpoint)]
        
        -- local preNum = self.config.island.prelocation

        print("preNum...=",preNum)
        -- printT(linkdata)
        local linktableOne = {}
        for i=1,4 do
            local linkkey = "link"..i
            print("linkkey:",linkkey)
            if preNum == 0 then
                if linkdata[linkkey] ~= 0 then
                    print("preNum=0:",linkdata[linkkey])
                    table.insert(linktableOne,linkdata[linkkey])
                end
            else
                if linkdata[linkkey] ~= 0 and linkdata[linkkey] ~= preNum then
                    print("preNum~=0:",linkdata[linkkey])
                    table.insert(linktableOne,linkdata[linkkey])
                end
            end
        end

       -- 如果有分岔口创建方向按钮
       print("i...am...onestep")
       printT(linktableOne)

       for i,v in ipairs(linktableOne) do
            if v ~= 0 and self["itemsCCB"..v] and self["itemsCCB"..v].step_Label then
                self["itemsCCB"..v].step_Label:setVisible(true)
                self["itemsCCB"..v].step_Label:setString(1)
            end
       end

       -- 重置上一点
       local preNum = self.config.island.location

       local linktableTwo = {}
       for i,v in ipairs(linktableOne) do
            local linkdata = linkTemp[tostring(v)]
            for a=1,4 do
                local linkkey = "link"..a
                if preNum == 0 then
                    if linkdata[linkkey] ~= 0 then
                        print("preNum=0:",linkdata[linkkey])
                        table.insert(linktableTwo,linkdata[linkkey])
                    end
                else
                    if linkdata[linkkey] ~= 0 and linkdata[linkkey] ~= preNum then
                        print("preNum~=0:",linkdata[linkkey])
                        table.insert(linktableTwo,linkdata[linkkey])
                    end
                end
            end
       end

       print("i...am...twotep")
       -- printT(linktableTwo)

       for i,v in ipairs(linktableTwo) do
            if v ~= 0 and self["itemsCCB"..v] and self["itemsCCB"..v].step_Label then
                self["itemsCCB"..v].step_Label:setVisible(true)
                self["itemsCCB"..v].step_Label:setString(2)
            end
       end


       local linktableThree = {}
       for i,v in ipairs(linktableTwo) do
            local linkdata = linkTemp[tostring(v)]

            for a=1,4 do
                local linkkey = "link"..a
                if preNum == 0 then
                    if linkdata[linkkey] ~= 0 then
                        print("preNum=0:",linkdata[linkkey])
                        table.insert(linktableThree,linkdata[linkkey])
                    end
                else
                    if linkdata[linkkey] ~= 0 then
                        print("preNum~=0:",linkdata[linkkey])
                        table.insert(linktableThree,linkdata[linkkey])
                    end
                end
            end
       end


       for i,v in ipairs(linktableOne) do
            for ai,av in ipairs(linktableThree) do
                if av == v then
                    -- table.remove(linktableThree,ai)
                    linktableThree[tonumber(ai)] = 0
                end
            end
       end

       print("i...am...threestep")
       -- printT(linktableThree)
       for i,v in ipairs(linktableThree) do
            if v ~= 0 and self["itemsCCB"..v] and self["itemsCCB"..v].step_Label then
                self["itemsCCB"..v].step_Label:setVisible(true)
                self["itemsCCB"..v].step_Label:setString(3)
            end
       end


       local linktableFour = {}
       for i,v in ipairs(linktableThree) do
            local linkdata = linkTemp[tostring(v)]
            if v ~= 0 then
                for a=1,4 do
                    local linkkey = "link"..a
                    if preNum == 0 then
                        if linkdata[linkkey] ~= 0 then
                            print("preNum=0:",linkdata[linkkey])
                            table.insert(linktableFour,linkdata[linkkey])
                        end
                    else
                        if linkdata[linkkey] ~= 0 then
                            print("preNum~=0:",linkdata[linkkey])
                            table.insert(linktableFour,linkdata[linkkey])
                        end
                    end
                end
            end
       end

       for i,v in ipairs(linktableOne) do
            for ai,av in ipairs(linktableFour) do
                if av == v then
                    -- table.remove(linktableFour,ai)
                    linktableFour[tonumber(ai)] = 0
                end
            end
       end

       for i,v in ipairs(linktableTwo) do
            for ai,av in ipairs(linktableFour) do
                if av == v then
                    -- table.remove(linktableFour,ai)
                    linktableFour[tonumber(ai)] = 0
                end
            end
       end

       print("i...am...fourstep")
       -- printT(linktableFour)

       for i,v in ipairs(linktableFour) do
            if v ~= 0 and self["itemsCCB"..v] and self["itemsCCB"..v].step_Label then
                self["itemsCCB"..v].step_Label:setVisible(true)
                self["itemsCCB"..v].step_Label:setString(4)
            end
       end

    end
end





function island.setbufferaction( self )
    print("enter.setbufferaction...")
    local ccCCB1, item1 = CCBReaderLoad("UIEffect/island_effect/buff_add.ccbi", nil, true, "buff_add")
    ccCCB1:setPosition(ccp(0,0))
    self.chuansongItems.generalNode:addChild(ccCCB1)

    self.animationManager = getAnimationManager(item1)
    self.animationManager:setAnimationCompletedCallback(function()
        print("complete1")
        ccCCB1:removeAllChildrenWithCleanup(true)
        ccCCB1:removeFromParentAndCleanup(true)
        ccCCB1 = nil
        item1 = nil

        local ccCCB2, item2 = CCBReaderLoad("UIEffect/island_effect/bufficon_add.ccbi", nil, true, "bufficon_add")
        ccCCB2:setPosition(ccp(0,0))
        self.rootItems.bufferNode:addChild(ccCCB2)
        self.animationManager = getAnimationManager(item2)
        self.animationManager:setAnimationCompletedCallback(function()
            print("complete2")
            ccCCB2:removeAllChildrenWithCleanup(true)
            ccCCB2:removeFromParentAndCleanup(true)
            ccCCB2 = nil
            item2 = nil
        end)
        self.animationManager:runAnimationsForSequenceNamed("bufficon_add")

    end)
    self.animationManager:runAnimationsForSequenceNamed("buff_add")

    
end

-- 顶部状态栏设置
function island.setStatus( self )
    -- self.rootItems.pointtotal:setString(self.config.island.PointDay)
    -- self.rootItems.bufferStateLabel:setString((self.config.island.buffer*100).."%")
    
    ui.setLabelString(self.rootItems.pointtotal,self.config.island.PointDay,14)

    ui.setLabelString(self.rootItems.bufferText,nil,21)
    local bufnum = 0 + (self.config.island.buffer)*tonumber(gamedata.config.penglai2_type[tostring(6)]["param"]) 

    ui.setLabelString(self.rootItems.bufferStateLabel,(bufnum*100).."%",21)

    ui.setLabelString(self.rootItems.pointtotalText,nil,12)
    ui.setLabelString(self.rootItems.timeNumText,nil,12)


    local globconfig = gamedata.config.global_kv
    local freenum = tonumber(globconfig.penglaixiandao_dice_free.value)-self.config.island.Dayfreenum
    local spendgoldnum = tonumber(globconfig.penglaixiandao_dice_gold.value)

    print("freenum，spendgoldnum==",freenum,spendgoldnum)

    if freenum <= 0 then
        print("spend====")
        ui.setLabelString(self.rootItems.spendText,nil,21)
        ui.setLabelString(self.rootItems.spendLabel,spendgoldnum,21)
        self.rootItems.freeNode:setVisible(false)
        self.rootItems.spendNode:setVisible(true)
    else
        print("free====")
        ui.setLabelString(self.rootItems.freenumText,nil,21)
        ui.setLabelString(self.rootItems.freenumLabel,freenum,21)
        self.rootItems.freeNode:setVisible(true)
        self.rootItems.spendNode:setVisible(false)
    end


    
    local t = os.date("*t", os.time())
    

    if t.wday ~= 1 then
        print("i...am...here...")
        -- self.rootItems.restday:setString(gameConfig.strings:Day(9-t.wday))
        ui.setLabelString(self.rootItems.restday,gameConfig.strings:Day(9-t.wday),14)
    else

        local hourNum = 23 - t.hour
        local minNUm = 59 - t.min
        local secNum = 60 - t.sec

        local allsecNum = hourNum*3600 + minNUm*60 + secNum

        local hour = math.floor(allsecNum/3600)
        local minute = math.floor(allsecNum%3600/60)
        local second = math.floor(allsecNum%60)
        local timeString = string.format("%02d:%02d:%02d",hour,minute,second)

        gameTimer:rigistTime("islandtimenum",allsecNum)
        if gameTimer.times["islandtimenum"] and gameTimer.times["islandtimenum"] ~= 0 then
            gameTimer:rigistTimeFunc("islandtimenum",function()
                print("i..am..Timer:",gameTimer.times["islandtimenum"])

                local hour = math.floor(gameTimer.times["islandtimenum"]/3600)
                local minute = math.floor(gameTimer.times["islandtimenum"]%3600/60)
                local second = math.floor(gameTimer.times["islandtimenum"]%60)
                local timeString = string.format("%02d:%02d:%02d",hour,minute,second)

                -- self.rootItems.restday:setString(timeString)
                ui.setLabelString(self.rootItems.restday, timeString, 14)

                if  gameTimer.times["islandtimenum"] == 0 then
                    gameTimer:UnrigistTimeFunc("islandtimenum")
                    -- self.rootItems.restday:setString("活动结束")
                    -- ui.setLabelString(self.rootItems.restday, "活动结束", 14)
                    ui.setLabelString(self.rootItems.restday, gameConfig.strings:string_common("island",7), 14)
                end

                    -- for k,v in pairs(self.wipetimes) do
                    --     v.node:setVisible(true)
                    --     v.label:setString(ui.makeTimeText(gameTimer.times["islandrollnum"],"minute"))
                    -- end
            end)
        end

    end

    


end

-- 设置 弹出哪个 弹出框
function island.setOpenWindow( self )
    print("set11111")
    self.deadtype = false
    self.rootItems.fuhuo_button:setVisible(false)
    self.rootItems.dead_Layer:setVisible(false)
    if self.config.island.status == 1 then

    elseif self.config.island.status == 2 then
        local locationpointdata = self.config.island.mapStatus[tostring(self.config.island.location)]
        local tempdata = gamedata.config.penglai2_type[tostring(locationpointdata.type)]
        -- local typestatus = gamedata.config.penglai2_type[tostring(typedata.status)]

        local typestring = tempdata.type
        local typestatus = locationpointdata.status
        print("typestatus==",typestatus)

        if typestring == "monster" or typestring == "brave" or typestring == "boss" then
            if typestatus == 1 then
                gameWindows:openWindow("penglaiResult",{index= "choose",data = self.config},nil)
            elseif typestatus == 2 then
                gameWindows:openWindow("penglaiResult",{index= "seccess",data = self.config},nil)
            elseif typestatus == 3 then
                if not self.deadtype then
                    gameWindows:openWindow("penglaiResult",{index= "fail",data = self.config},nil)
                end
                print("set12222")
                self.deadtype = true
                self.rootItems.dead_Layer:setVisible(true)
                self.rootItems.fuhuo_button:setVisible(true)

                self.rootItems.fuhuo_button:setSwallowsTouch(true)
                self.rootItems.fuhuo_button:setTouchPriority(-102)
                self.rootItems.fuhuo_button:addHandleOfControlEvent(function()
                    print("i..am.....fuhuo_button..")
                    gameWindows:openWindow("penglaiResult",{index= "fail",data = self.config},nil)
                    
                end, CCControlEventTouchUpInside)
            end
        elseif typestring == "buffer" then
            gameWindows:openWindow("penglaiResult",{index= "buffer",data = self.config},nil)
        elseif typestring == "prop" then
            print("i...am...prop:")
        elseif typestring == "point" then
            print("i...am...point:")
        elseif typestring == "box" then
            print("i...am...box:")
        end
    elseif self.config.island.status == 999 then
        print("self.completetype===",self.completetype)
        if self.completetype == false then
            self.rootItems.dead_Layer:setVisible(false)
            print("i...am..deadfalse")
        else
            self.rootItems.dead_Layer:setVisible(true)
            print("i...am..deadtrue")
        end
    end
     
end

-- 视图区域设置
function island.setViewPointCenter(self)
    
    local nowLocationX = self.chuansongItems.generalNode:getPositionX()
    local nowLocationY = self.chuansongItems.generalNode:getPositionY()
    
    local winSize = gameConfig.originSize
    local x = math.max(nowLocationX, winSize.width/2)
    local y = math.max(nowLocationY, (winSize.height)/2)
    local aaa = self.chuansongItems.gameNode
    local bbb = aaa:getContentSize()
    local ccc = bbb.width

    local disNum = 240
    local trueWinSize = CCDirector:sharedDirector():getWinSize()
    print("trueWinSize===",trueWinSize.width,trueWinSize.height)
    if (trueWinSize.width/trueWinSize.height) >= (2/3) then
        disNum = 240*2
    end
    print("i...am...cccc:",ccc,trueWinSize.width,trueWinSize.height,disNum)
    x = math.min(x, self.chuansongItems.gameNode:getContentSize().width-winSize.width/2)
    y = math.min(y, self.chuansongItems.gameNode:getContentSize().height+disNum-(winSize.height)/2)

    --self.chuansongItems.gameNode:setPosition(ccp(winSize.width/2-x, (winSize.height)/2-y))

    -- local moveTo = CCMoveTo:create(0.8,ccp(winSize.width/2-x, (winSize.height)/2-y))
    -- self.chuansongItems.gameNode:runAction(moveTo)
    local xdis = (winSize.width/2-x)
    local ydis = (winSize.height/2-y)
    self.rootItems.scrollnode:setContentOffsetInDuration(ccp(xdis,ydis),0.5)
end

-- 下一步
function island.stepToNext(self, nextstepNum)

        local nextX = self.chuansongItems["p"..nextstepNum]:getPositionX()
        local nextY = self.chuansongItems["p"..nextstepNum]:getPositionY()

        -- 移动时设置武将状态
        self.stepGneral:setAnimation("run",true,0)
        local plusNum = nextX - self.chuansongItems.generalNode:getPositionX()
        if plusNum > 0 then
            self.stepGneral:setScaleX(0.65)
        else
            self.stepGneral:setScaleX(-0.65)
        end


        local moveTo = CCMoveTo:create(0.8,ccp(nextX,nextY))

        self.chuansongItems.generalNode:runAction(CCSequence:createWithTwoActions(moveTo, CCCallFunc:create(function()
            -- 走的步数
            self.rollNum = self.rollNum - 1
            -- 设置可走步数显示
            -- self.rootItems.stepLabel:setString(self.rollNum)
            
            self.stepGneral:setAnimation("stand",true,0)
            if self.rollNum ~= 0 then
                self:creatdirectionBtn(nextstepNum)
            else
                print("i...am...end:")
                -- self.stepGneral:setAnimation("stand",true,0)
                local fromnum = self.prelocationNum[1]
                self.fromnum = self.prelocationNum[1]
                local tonum = nextstepNum
                print("fromnum...=",fromnum)
                print("tonum...=",tonum)
                UIRequest({type = 2111 ,from = fromnum, to = tonum, rollnum = self.config.island.Dayfreenum})
                self.movetype = true
            end
            

        end)))
    -- end
    
    print("rollnum....=",self.rollNum)
end

-- 创建方向键
function island.creatdirectionBtn(self,linkNum)
    
    self:setViewPointCenter()

    print("i...am...creatdirectionBtn...")
    -- local linkdata = gamedata.config.penglai2_map[tostring(linkNum)]
    local t = os.date("*t", os.time())
    -- printT(t)
    local wdayNum = 1
    if t.wday == 1 then
        wdayNum = 7
    else
        wdayNum = t.wday - 1
    end

    local ccbName = gamedata.config.penglai2_map0[tostring(wdayNum)].config
    print("ccbName==",ccbName)

    local linkdata = gamedata.config[tostring(gamedata.config.penglai2_map0[tostring(wdayNum)].config)][tostring(linkNum)]
    -- printT(self.prelocationNum)
    local preNum = table.remove(self.prelocationNum,1)
    -- local preNum = self.config.island.prelocation

    -- printT(self.prelocationNum)
    print("preNum...=",preNum)
    -- printT(linkdata)
    local linktable = {}
    for i=1,4 do
        local linkkey = "link"..i
        print("linkkey:",linkkey)
        if preNum == 0 then
            if linkdata[linkkey] ~= 0 then
                print("preNum=0:",linkdata[linkkey])
                table.insert(linktable,linkdata[linkkey])
            end
        else
            if linkdata[linkkey] ~= 0 and linkdata[linkkey] ~= preNum then
                print("preNum~=0:",linkdata[linkkey])
                table.insert(linktable,linkdata[linkkey])
            end
        end
    end

   -- 如果有分岔口创建方向按钮
   -- printT(linktable)
    if #linktable > 1 then
        self:setWindowScale()

        for i,v in ipairs(linktable) do
            print(i,v)
            self["jiantou"..i],self["item"..i] = CCBReaderLoad("island2/jiantou.ccbi", nil, true, "jiantou")
            self.chuansongItems.generalNode:addChild(self["jiantou"..i])

            local nowLocationX = self.chuansongItems.generalNode:getPositionX()
            local nowLocationY = self.chuansongItems.generalNode:getPositionY()

            local nextX = self.chuansongItems["p"..v]:getPositionX()
            local nextY = self.chuansongItems["p"..v]:getPositionY()

            local DvalueX = nextX - nowLocationX
            local DvalueY = nextY - nowLocationY
            print("DvalueX...is...:",DvalueX)
            local bbbb = 0
            if DvalueX == 0 and DvalueY > 0 then
                bbbb = -90
            elseif DvalueX == 0 and DvalueY < 0 then
                bbbb = 90
            elseif DvalueY == 0 and DvalueX > 0 then
                bbbb = 0
            elseif DvalueY == 0 and DvalueX < 0 then
                bbbb = 180
            else
                local tanx = math.atan(math.abs(DvalueY/DvalueX))
                print("tanx:",tanx)
                bbbb = math.deg(tanx)
                print("bbbb1:",bbbb)
                if DvalueX > 0 and DvalueY > 0 then
                    bbbb = -bbbb 
                elseif DvalueX > 0 and DvalueY < 0 then
                    bbbb = bbbb
                elseif DvalueX < 0 and DvalueY > 0 then
                    bbbb = 180 + bbbb 
                elseif DvalueX < 0 and DvalueY < 0 then
                    bbbb = 180 -bbbb
                end
            end
            
            print("bbbb2:",bbbb)
            self["item"..i].directionNode:setRotation(bbbb)

            
            self["item"..i].directionBtn:setSwallowsTouch(true)
            self["item"..i].directionBtn:setTouchPriority(-102)
            self["item"..i].directionBtn:addHandleOfControlEvent(function()
                print("i..am...directionBtn..")

                self:setWindowScaleBack()
                for i,v in ipairs(linktable) do
                    self["jiantou"..i]:removeAllChildrenWithCleanup(true)
                    self["jiantou"..i]:removeFromParentAndCleanup(true)
                    self["jiantou"..i] = nil
                    self["item"..i] = nil
                end
                print("vvvvvvv=",v)
                self:stepToNext(v)
                table.insert(self.prelocationNum,v)
                
            end, CCControlEventTouchUpInside)
        end
        return
    else
        print("onestepNum:...",linktable[1])
        self:stepToNext(linktable[1])
        table.insert(self.prelocationNum,linktable[1])
    end
end

-- 分叉路口场景缩放
function island.setWindowScale(self)
    local nowLocationX = self.chuansongItems.generalNode:getPositionX()
    local nowLocationY = self.chuansongItems.generalNode:getPositionY()
    
    local x = self.chuansongItems.gameNode:getContentSize().width
    local y = self.chuansongItems.gameNode:getContentSize().height

    local anchorX = nowLocationX/x
    local anchorY = nowLocationY/y
    print("anchorX==",anchorX)
    print("anchorY==",anchorY)


    self.chuansongItems.gameNode:setAnchorPoint(ccp(anchorX,anchorY))
    self.chuansongItems.gameNode:setPosition(ccp(nowLocationX,nowLocationY))
    -- self.chuansongItems.gameNode:setScaleTo(2)

    local scaleTo = CCScaleTo:create(0.5,2, 2)
    self.chuansongItems.gameNode:runAction(scaleTo)
end

-- 分叉路口场景缩放恢复
function island.setWindowScaleBack(self)

    -- local scaleTo = CCScaleTo:create(0.5,1)
    -- self.chuansongItems.gameNode:runAction(scaleTo)

    self.chuansongItems.gameNode:stopAllActions()
    self.chuansongItems.gameNode:setScale(1)
    self.chuansongItems.gameNode:setAnchorPoint(ccp(0,0))
    self.chuansongItems.gameNode:setPosition(ccp(0,0))
end



function island.clear(self)
    print("island.clear=")
    -- self.rootItems.turnhand:stopAllActions()

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil


    if self.chuansongNode then
        self.chuansongNode = nil
        self.chuansongItems = nil
    end
    

    if self.ccb then
        -- self.ccb:removeAllChildrenWithCleanup(true)
        -- self.ccb:removeFromParentAndCleanup(true)
        self.ccb = nil
        self.item = nil
    end

    self.stepGneral = nil
    self.prelocationNum = nil
    self.rollNum = 0
    if gameTimer.times["islandrollnum"] then
        gameTimer:UnrigistTimeFunc("islandrollnum")
    end

    if gameTimer.times["islandtimenum"] then
        gameTimer:UnrigistTimeFunc("islandtimenum")
    end

    if gameTimer.times["islandrolldirection"] then
        gameTimer:UnrigistTimeFunc("islandrolldirection")
    end
    

    local mapdata = self.config.island.mapStatus
    local lengthNum = table.getTableLength(mapdata)
    for i=1,lengthNum do
        if self.ccbNodes[i] then
            print("clear=",i)
            self.ccbNodes[i] = nil
            self["itemsCCB"..i] = nil
        end
        -- if self["itemsCCB"..i] then
        --     self["itemsCCB"..i] = nil
        -- end
    end
    
end

return island
  �  