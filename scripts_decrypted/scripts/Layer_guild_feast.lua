--公会盛宴
--dhope

local guildfeast = {
	normalCellSize = {x = 1080, y = 260},
	rootItems = nil,
	rootNode = nil,
 	roomId = 1, 
    startTime = 0,
    curbei = 1,
    dostr = nil,
    data = nil,
    myFeastTime = 0,
    recordsPerson = 1,
    recordsReward1 = 0,
    recordsReward2 = 0,
    isGetReward = false,
    isstart = false,
    jubuCount = 0,--局部计数
}


function guildfeast.init(self,parent,toppos,data)
	self.show = true
	self.rootNode, self.rootItems = CCBReaderLoad("gonghui3/gonghui_shengyan", nil, true, "gonghui_shengyan")
	self.rootNode:setPosition(0,0)
	parent:addChild(self.rootNode)
	self.rootItems.topnode:setPositionY(toppos)

    self.needoutext = true 

	self.rootItems.common_back_btn:setTouchPriority(-101)
    self.rootItems.common_back_btn:addHandleOfControlEvent(function()
    	print("backbutton=")  
        -- if gameTimer.times["feasttime"] <= 4 then
        --     return
        -- end
        if self.needoutext  then
            -- if gameTimer.times["feasttime"] <= 0 then
            --     UIRequest({type = 2273, beinum = self.curbei, roomid = self.roomId, personnum = self.recordsPerson})
            -- else
                gameWindows:openWindow(
                    "confirm",
                    {msg = "不在当前场景收益衰减-50%，是否离开？"},
                    function ()
                        self.needoutext = false
                        UIRequest({type = 2277})
                        -- UIRequest({type = 2269, beinum = self.curbei, roomid = self.roomId, personnum = self.recordsPerson})
                    end)
            -- end
        else
            UIRequest({type = 2230,param = "activity"})
        end
    end, CCControlEventTouchUpInside)

    self.rootItems.ruleBtn:setTouchPriority(-101)
    self.rootItems.ruleBtn:addHandleOfControlEvent(function()
        --gameWindows:openWindow("gangbossRule",nil)
        ui.popCommonRule(570)
    end, CCControlEventTouchUpInside)

    self.rootItems.invite_btn:setTouchPriority(-101)
    self.rootItems.invite_btn:addHandleOfControlEvent(function()
        local callback = function()
            UIRequest({type = 3011, content = "劝君共饮一杯酒，公会盛宴爆起来，今晚全场消费由我买单。【点击参与】 &&&"..self.roomId})
            -- runGamePrompt({msg = "已发出邀请"})
        end
        gameWindows:openWindow("feastzhaoji",{barrageType = 1,params = {self.roomId}},callback)

    end, CCControlEventTouchUpInside)
    ui.setLabelString(self.rootItems.yaoqing_lab, "邀请", 19,36)

    self.rootItems.start_btn:setTouchPriority(-101)
    self.rootItems.start_btn:addHandleOfControlEvent(function()
        UIRequest({type = 2275})
    end, CCControlEventTouchUpInside)
    ui.setLabelString(self.rootItems.start_lab, nil, 19)
    self.rootItems.again_btn:setTouchPriority(-101)
    self.rootItems.again_btn:addHandleOfControlEvent(function()
        if self.data.feastStatus == 1 then
            runGamePrompt({msg = "宴会未开始暂时不能接龙"})
            return
        end
        local alltimes = gamedata.config.global_kv["gang2_feast_times"].value
        local curtimes = alltimes - self.data.openFeastNum
        if curtimes > 0 then
            gameWindows:openWindow("gangProduceAgain",{roomid = self.roomId,produceType = 1,opennum = self.data.openFeastNum})
        else
            runGamePrompt({msg = "发起次数已用完"})
        end
    end, CCControlEventTouchUpInside)
    ui.setLabelString(self.rootItems.again_lab, nil, 19)

    self.totalnum = GameScene.layers["gang_main"].module.gang.num
    

    ui.setLabelString(self.rootItems.personNum, "", 14)
    ui.setLabelString(self.rootItems.label1, "当前", 14)
    ui.setLabelString(self.rootItems.label2, "人，加成", 14)
    
    self.rootItems.doingTime:setString(ui.makeTimeText(0,"minute"))
    local configBeiData = gamedata.config.gang2_feast_gain
    local curbei = configBeiData["20"].up/100
    self.rootItems.rewardNum:setString(""..curbei)
    self.rootItems.upNum:setString("50%")
    
    if data and data.feastRoomid then
        self.roomId = data.feastRoomid
    end
    self.rootItems.shouyiNode:setVisible(false)
    self:addAnim()
    self:createDaojishiAnim()
	self:reloaddata(data,true)
    self:updataDaojishi()

    self:initTouch()
    self.guildchat = require"Layer_guildchat"
    self.guildchat:init(self.rootNode,{},self.topposY,-101,"bath")
end
function guildfeast.initTouch(self)
    local function touchbegin(pos)
        
    end
    gameTouch:rigistFunc("begin","guildshengyan",touchbegin)

    local function touchend(pos)
        if pos.y > 450 and pos.y < 1000 then
            self.guildchat:setChatListShow(false)
        elseif pos.y < 150 then
            self.guildchat:setChatListShow(true)
        end
    end
    gameTouch:rigistFunc("end","guildshengyan",touchend)
end

function guildfeast.updataDaojishi(self)
    gameTimer:rigistTime("updatafeasttime",999)
    gameTimer:rigistTimeFunc("updatafeasttime",function()
        if gameTimer.times["updatafeasttime"] <= 0 then
            gameTimer:rigistTime("updatafeasttime",999)
        end
        if gameTimer.times["updatafeasttime"]%5 == 0 then
            
            if self.isGetReward == false then
                UIRequest({type = 2274})
            end

            if self.myFeastTime > 0 then
                if self.data.feastStatus ~= 1 and self.myFeastTime < 5 and self.isGetReward == false then
                    self:award()
                end
            else
                if self.data.feastStatus ~= 1 and self.isGetReward == false then
                    self:award()
                end
            end

        end
    end)
end
--餐桌加号缩放
function guildfeast.addAnim(self)
    for i = 1, 7 do
        self.rootItems["placebtn"..i]:setVisible(true)
        self.rootItems["placebtn"..i]:stopAllActions()
        local action1 = CCSequence:createWithTwoActions(CCScaleBy:create(0.5,0.8),CCScaleTo:create(0.5,1))
        self.rootItems["placebtn"..i]:runAction(CCRepeatForever:create(action1))
    end
end

--清空数据
function guildfeast.clear(self) 	
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootItems = nil
	self.rootNode = nil
	self.ListTableView = nil
 	self.maxLevel = 0
 	self.cellNum = 0	
 	self.isscrolltouched = false
    self.dostr = nil
    self.recordsPerson = 1
    self.isGetReward = false
    self.myFeastTime = 0
    self.isstart = false
    self.guildchat:close()
 	gameTimer:UnrigistTime("feasttime")
	gameTimer:UnrigistTimeFunc("feasttime")

    gameTimer:UnrigistTime("updatafeasttime")
    gameTimer:UnrigistTimeFunc("updatafeasttime")

    gameTouch:UnrigistFunc("begin","guildshengyan")
    gameTouch:UnrigistFunc("end","guildshengyan")   

end

function guildfeast.reloaddata(self,data,isfirst)
    
    local feastNpcData = gamedata.config.gang2_feast_npc
    local configData = gamedata.config.gang2_feast_award
    local configTypeData = gamedata.config.gang2_feast_type
    local configBeiData = gamedata.config.gang2_feast_gain
    self.config = configData[tostring(GameScene.roleinfo.level)]
    local awardArr = ui.getIDandNUMs(self.config[tostring(self.roomId)].award)

    local icondata = ui.IDconfig(awardArr[1].cid)
    setSpriteFrameByName(self.rootItems.icon1,icondata.icon..".png")

    icondata = ui.IDconfig(awardArr[2].cid)
    setSpriteFrameByName(self.rootItems.icon2,icondata.icon..".png")

    for i = 1, 13 do
        if i < 8 then
            self.rootItems["headicon"..i]:setVisible(false)
            self.rootItems["playername"..i]:setVisible(false)
            self.rootItems["placebtn"..i]:setVisible(true)
            self.rootItems["placebtn"..i]:setTouchPriority(-101)
            self.rootItems["placebtn"..i]:addHandleOfControlEvent(function()
                -- print("placebtn="..i)  
                -- UIRequest({type = 2268,placeid = i})
                local callback = function()
                    UIRequest({type = 3011, content = "劝君共饮一杯酒，公会盛宴爆起来，今晚全场消费由我买单。【点击参与】 &&&"..self.roomId})
                    -- runGamePrompt({msg = "已发出邀请"})
                end
                gameWindows:openWindow("feastzhaoji",{barrageType = 1},callback)
                
            end, CCControlEventTouchUpInside)
            self.rootItems["playerNode"..i]:stopAllActions()
            self.rootItems["playerNode"..i]:removeAllChildrenWithCleanup(true)
        end
    end

    if data then
        self.data = data
        local alltimes = gamedata.config.global_kv["gang2_feast_times"].value
        local curtimes = alltimes - data.openFeastNum
        if curtimes > 0 then
            ui.removeGray("CCControlButton",self.rootItems.again_btn)
            ui.removeGray("CCLabelTTF",self.rootItems.again_lab)
        else
            ui.addGray("CCControlButton",self.rootItems.again_btn)
            ui.addGray("CCLabelTTF",self.rootItems.again_lab)
        end


        self.myFeastTime = data.feastTime
        self:updateFeastPerson(data.feastPersonNum)
        ui.setLabelString(self.rootItems.personNum, ""..self.recordsPerson, 14)
        self.rootItems.personOnlineNum:setString(data.onlineNum.."人")

        local zhunbeiTime = 0
        if data.feastStatus == 1 then 
            zhunbeiTime = data.feastTime
            self.rootItems.againNode:setVisible(false)
        elseif data.feastStatus == 2 then 
            self.rootItems.againNode:setVisible(true)
            if self.isstart == false then
                self:handStartFeast()
            end
        end
        --local zhunbeiTime = data.feastTime - configTypeData[tostring(self.roomId)].time
        
        -- print(data.feastTime.."====reloaddata==1==="..zhunbeiTime)
        if zhunbeiTime > 0 then
            if zhunbeiTime > configTypeData[tostring(self.roomId)].prepare_time - configTypeData[tostring(self.roomId)].start_time then
                self.rootItems.startNode:setVisible(false)
            else
                if data.myStatus == 1 then 
                    self.rootItems.startNode:setVisible(true)
                elseif data.myStatus == 2 then 
                    self.rootItems.startNode:setVisible(false)
                end
            end
            self.isstart = false


            ui.setLabelString(self.rootItems.timeLabel,"开始时间",14)
            self.rootItems.doingTime:setString(ui.makeTimeText(zhunbeiTime,"minute"))
            gameTimer:rigistTime("feasttime",zhunbeiTime)
        else
            self.rootItems.startNode:setVisible(false)
            self.isstart = true
            self.jubuCount= 0
            ui.setLabelString(self.rootItems.timeLabel,"结束时间",14)
            self.rootItems.doingTime:setString(ui.makeTimeText(data.feastTime,"minute"))
            gameTimer:rigistTime("feasttime",data.feastTime)
        end
        if data.myStatus == 1 then 
        elseif data.myStatus == 2 then 
            awardArr = ui.getIDandNUMs(self.config[tostring(self.roomId)].award_2)
            print("========awardArr=========")
            printT(awardArr)
        end


        if gameTimer.times["feasttime"] > 0 then
            local animationManager = getAnimationManager(self.jishiitems)
            animationManager:runAnimationsForSequenceNamed("daojishi") 
        end
        --19 按钮字
        self.curbei = configBeiData[tostring(self.recordsPerson)].up/100
        local jiacheng = (self.curbei-1) * 100
        ui.setLabelString(self.rootItems.jiachengLabel, jiacheng.."%", 14)
         self.rootItems.rewardbei:setString("+"..jiacheng.."%")

        gameTimer:rigistTimeFunc("feasttime",function()

            print("feasttime-----",gameTimer.times["feasttime"],self.isstart)
            if  gameTimer.times["feasttime"] ~= 0 then
                self.rootItems.doingTime:setString(ui.makeTimeText(gameTimer.times["feasttime"],"minute"))
                if self.isstart == true and gameTimer.times["feasttime"] == 3 then
                    --self:createStartAnim("end")
                elseif self.isstart == false and gameTimer.times["feasttime"] == 3 then
                    self:createStartAnim("start")
                end
                --计算收益
                if self.isstart == true then
                    -- self:jisuanFeastShouyi(data, awardArr, gameTimer.times["feasttime"])
                    self:jisuanFeastShouyi2(data,self.jubuCount)
                    self.jubuCount= self.jubuCount+1
                else
                    local extraNum = (self.curbei-1)*100
                    self.recordsReward1 = awardArr[1].num
                    self.recordsReward2 = awardArr[2].num
                    self.rootItems.rewardExp1:setString(awardArr[1].num.."+"..extraNum)

                    self.rootItems.rewardExp2:setString(awardArr[2].num.."+"..extraNum)
                end

                if gameTimer.times["feasttime"]%3 == 0 then
                    local curidx = math.random(1,6)
                    self:createDuihuaAnim(curidx)
                end
            else
                UIRequest({type = 2274})
                self.rootItems.doingTime:setString("00:00")
                self:stopDaojishiAnim()
                -- self:jisuanFeastShouyi(data, awardArr, 0)
            end
        end)

        for i,v in pairs(data.feastPlayers) do
            if v then
                local idx = v.params["1"].i
                self.rootItems["placebtn"..idx]:setVisible(false)
                self.rootItems["playername"..idx]:setVisible(true)
                self.rootItems["headicon"..idx]:setVisible(true)
                local generalinfo = ui.IDconfig(v.profile)
                -- local headstr = "yuan_"..generalinfo.icon..".png"
                -- setSpriteFrameByName(self.rootItems["headicon"..idx],headstr)
                self.rootItems["headicon"..idx]:removeAllChildrenWithCleanup(true)
                local cliper,conent = ui.createCliperNode(self.rootItems["headicon"..idx],generalinfo.icon,"stencil_headIcon")
                conent:setAnchorPoint(ccp(0,0))
                conent:setPosition(-53,-53)
                conent:setScale(0.7)
                cliper:setScale(0.9)
                
                self.rootItems["playername"..idx]:setString(v.name)
                if self.isstart == true then
                    local tempconfig = configData[tostring(v.level)]
                    local tempAwardArr = ui.getIDandNUMs(tempconfig[tostring(self.roomId)].award)
                    if v.params["2"].i == 2 then
                        tempAwardArr = ui.getIDandNUMs(tempconfig[tostring(self.roomId)].award_2)
                    end
                    local shouyi1 = tempAwardArr[1].num * self.curbei
                    self:createExpUpAnim(self.rootItems["playerNode"..idx],shouyi1,v.params["2"].i)
                    
                    if isfirst == true then
                        self.rootItems.shouyiNode:setVisible(true)
                        local animationManager = getAnimationManager(self.rootItems)
                        animationManager:runAnimationsForSequenceNamed("shouyiout") 
                    end
                end
            end
        end
    end
    if isfirst == true then
        for i = 1, 13 do
            if i > 7 then
                local generalid = feastNpcData[tostring(i-7)].generalsid
                local config = gamedata.config.general[tostring(generalid)]
                local generalName = gamedata.config.generalanimation[tostring(config.animationid)].name
                local Gneral = ui.itemcache:loadSkeleton(generalName,{})
                Gneral:setAnimation("stand",true,0)
                Gneral:setScale(0.8)
                if i > 10 then
                    Gneral:setScaleX(-1)
                end
                Gneral:setPosition(0,0)
                self.rootItems["playerNode"..i]:addChild(Gneral.root or Gneral)
                -- if isstart == true then
                --     self:createExpUpAnim(self.rootItems["playerNode"..i],"")
                -- end
            end
        end
    end
end

function guildfeast.award(self)
    self.isGetReward = true
    UIRequest({type = 2273, beinum = self.curbei, roomid = self.roomId, personnum = self.recordsPerson})
end

function guildfeast.awardCallback(self,data)
    printT(data,"awardCallback")
    for k,v in pairs(data.reward) do
        if v.cid == 1017 then
            local initval = math.ceil(v.num / data.beinum)
            local offval = v.num - initval
            self:updateFeastShouyi(initval, self.recordsReward1, self.rootItems.rewardExp1, offval)

        elseif v.cid == 1031 then
            local initval = math.ceil(v.num / data.beinum)
            local offval = v.num - initval
            self:updateFeastShouyi(initval, self.recordsReward2, self.rootItems.rewardExp2, offval)
        end
    end

    self:createStartAnim("end",function (  )
        gameWindows:openWindow("feastjiesuan", {data = data})
    end)
end

--计算收益
function guildfeast.jiesuanFeastShouyi(self, data)
    for i = 1, table.getTableLength(data.reward) do
        local v = data.reward[tostring(i)]
        if v then
            if v.cid == 1017 or v.cid == 1031 then
                local icondata = ui.IDconfig(v.cid)
                local initval = math.ceil(v.num / data.beinum)
                local offval = v.num - initval
                if v.cid == 1017 then
                    self.rootItems.rewardExp1:setString(initval.."+"..offval)
                else
                    self.rootItems.rewardExp2:setString(initval.."+"..offval)
                end
            end
        end
    end
end
function guildfeast.jisuanExtFeast(self,extTime,awardArr,idx,profit)
    -- body
    local shuaijianConfig = gamedata.config.gang2_feast_profit
    if extTime > 0 then
        local tempshouyi = 0
        local val = 0
        for i=1,table.getTableLength(shuaijianConfig) do
            local v = shuaijianConfig[tostring(i)]
            if extTime > v.times then
                tempshouyi = tempshouyi + (v.times - val)*awardArr[idx].num*profit
                val = v.times 
            else
                tempshouyi = tempshouyi + (extTime - val)*awardArr[idx].num*profit
                break
            end
        end

        print(extTime.."======jisuanExtFeast===1======="..tempshouyi.."/"..profit)
        return tempshouyi
    end
    return 0
end

function guildfeast.jisuanFeastShouyi2(self, data, offsets)
    -- body
    printT(data,"计算收益显示")

    if data.myFeastTime <= 0 then
        return
    end

    local configTypeData = gamedata.config.gang2_feast_type
    local configData = gamedata.config.gang2_feast_award
    local shuaijianConfig = gamedata.config.gang2_feast_profit

    local rewardConfig = configData[tostring(GameScene.roleinfo.level)]
    local awardArr1 = ui.getIDandNUMs(rewardConfig[tostring(self.roomId)].award)
    local awardArr2 = ui.getIDandNUMs(rewardConfig[tostring(self.roomId)].award_2)
    

    local shouyi1 = 0
    local shouyi2 = 0
    local jishival = offsets + data.myFeastTime--data.rewardTimeNum
    if data.myStatus == 1 then
        shouyi1 = shouyi1 + jishival*awardArr1[1].num
        shouyi2 = shouyi2 + jishival*awardArr1[2].num


        print(awardArr1[1].num.."======FeastShouyi===1======="..awardArr1[2].num)
        
    else
        jishival = offsets + data.myFeastTime


        
        local curprofit = 1
        local curDayTimeNum = data.curDayTimeNum
        local temp_t = curDayTimeNum
        
        for i=1,table.getTableLength(shuaijianConfig) do
            local v = shuaijianConfig[tostring(i)]
            if curDayTimeNum + jishival < v.times then
                curprofit = (v.profit/100)
                local tempshouyi1 = 0
                local tempshouyi2 = 0

                if curDayTimeNum > temp_t then
                    tempshouyi1 = (jishival)*awardArr2[1].num*curprofit
                    tempshouyi2 = (jishival)*awardArr2[2].num*curprofit
                else
                    tempshouyi1 = (jishival + curDayTimeNum - temp_t)*awardArr2[1].num*curprofit
                    tempshouyi2 = (jishival + curDayTimeNum - temp_t)*awardArr2[2].num*curprofit
                end

                shouyi1 = math.ceil(shouyi1 + tempshouyi1)
                shouyi2 = math.ceil(shouyi2 + tempshouyi2)
                break
            else
                local tempshouyi1 = 0
                local tempshouyi2 = 0
                curprofit = (v.profit/100)
                if curDayTimeNum < v.times then

                    if curDayTimeNum > temp_t then
                        tempshouyi1 = (v.times - curDayTimeNum)*awardArr2[1].num*curprofit
                        tempshouyi2 = (v.times - curDayTimeNum)*awardArr2[2].num*curprofit
                    else
                        tempshouyi1 = (v.times - temp_t)*awardArr2[1].num*curprofit
                        tempshouyi2 = (v.times - temp_t)*awardArr2[2].num*curprofit
                    end
                    shouyi1 = math.ceil(shouyi1 + tempshouyi1)
                    shouyi2 = math.ceil(shouyi2 + tempshouyi2)
                end
            end

            temp_t = v.times
        end
        print("curprofit",curprofit,shouyi1,shouyi2,offsets,jishival)
    end
    print(shouyi1.."======FeastShouyi====3======"..shouyi2.."/"..self.curbei)

    for i = 1, table.getTableLength(data.curReward) do
        local v = data.curReward[tostring(i)]
        local initval = math.ceil(v.num / self.curbei)
        if v.cid == 1017 then
            shouyi1 = shouyi1 + initval
        elseif v.cid == 1031 then
            shouyi2 = shouyi2 + initval
        end
    end


    print("final_shouyi",shouyi1,shouyi2)

    local extraNum = math.ceil(shouyi1*(self.curbei-1))
    self:updateFeastShouyi(shouyi1, self.recordsReward1, self.rootItems.rewardExp1, extraNum)
    self.recordsReward1 = shouyi1

    
    local extraNum2 = math.ceil(shouyi2*(self.curbei-1))
    self:updateFeastShouyi(shouyi2, self.recordsReward2, self.rootItems.rewardExp2, extraNum2)
    self.recordsReward2 = shouyi2

    -- if self.jubuCount < 5 then
    --     self.jubuCount = self.jubuCount + 1
    -- else
    --     self.jubuCount = 0
    -- end
end
function guildfeast.jisuanFeastShouyi(self, data, awardArr, curtime)
    -- body
    local configTypeData = gamedata.config.gang2_feast_type
    local tempval = data.myFeastTime--data.myFeastTime > configTypeData[tostring(self.roomId)].time and configTypeData[tostring(self.roomId)].time or data.myFeastTime
    
    if data.myFeastTime > 99999 then
        tempval = 0
    end

    local useTime = tempval - curtime
    local shouyi1 = awardArr[1].num * useTime

    local extraNum = math.ceil(shouyi1*(self.curbei-1))
    -- local extraNum = (self.curbei-1)*100
    -- self.rootItems.rewardExp1:setString(shouyi1.."+"..extraNum.."%")
    self:updateFeastShouyi(shouyi1, self.recordsReward1, self.rootItems.rewardExp1, extraNum)
    self.recordsReward1 = shouyi1

    local shouyi2 = awardArr[2].num * useTime
    local extraNum2 = math.ceil(shouyi2*(self.curbei-1))
    -- self.rootItems.rewardExp2:setString(shouyi2.."+"..extraNum.."%")
    self:updateFeastShouyi(shouyi2, self.recordsReward2, self.rootItems.rewardExp2, extraNum2)
    self.recordsReward2 = shouyi2
end

function guildfeast.updateFeastShouyi(self, curShouyi, recordsReward, stringNode, extraNum)
    -- body
    local offsetval = curShouyi - recordsReward
    local shownum = {}
    for i = 1,10 do
        if math.ceil(i*offsetval/10) > offsetval then
            shownum[i] = offsetval
        else    
            shownum[i] = math.ceil(i*offsetval/10)
        end    
        stringNode:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.05*i),CCCallFunc:create(function()
            -- print("======updateFeastShouyi=========="..extraNum)
            stringNode:setString((shownum[i]+recordsReward).."+"..extraNum)
        end)))
    end
    if offsetval > 0 then
        local ccb, items = CCBReaderLoad("UIEffect/banghuieffect/banghuiguang", nil, true, "banghuiguang")
        ccb:setPosition(-300, 0)
        self.rootItems.shouyiNode:addChild(ccb,1000)
        local animationManager = getAnimationManager(items)
        animationManager:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)

        local ccb1, items1 = CCBReaderLoad("UIEffect/banghuieffect/banghuiguang", nil, true, "banghuiguang")
        ccb1:setPosition(-300, -90)
        self.rootItems.shouyiNode:addChild(ccb1,1000)
        local animationManager1 = getAnimationManager(items1)
        animationManager1:setAnimationCompletedCallback(function()
            ccb1:removeFromParentAndCleanup(true)
        end)
    end
end

function guildfeast.updateFeastPerson(self,personNum)
    if personNum and personNum <= 0 then
        return
    end

    if personNum > self.recordsPerson then
        local ccb, items = CCBReaderLoad("gonghui3/tips_join", nil, true, "tips_join")
        ccb:setPosition(gameConfig.originSize.width/2, gameConfig.originSize.height/2)
        self.rootNode:addChild(ccb)
        local animationManager = getAnimationManager(items)
        animationManager:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("shouyizengjia") 
    elseif personNum < self.recordsPerson then
        local ccb, items = CCBReaderLoad("gonghui3/tips_exit", nil, true, "tips_exit")
        ccb:setPosition(gameConfig.originSize.width/2, gameConfig.originSize.height/2)
        self.rootNode:addChild(ccb)
        local animationManager = getAnimationManager(items)
        animationManager:setAnimationCompletedCallback(function()
            ccb:removeFromParentAndCleanup(true)
        end)
        animationManager:runAnimationsForSequenceNamed("shouyijianshao") 
    end
    self.recordsPerson = personNum
end


--倒计时扫光特效
function guildfeast.createTimeSaoguangAnim(self)
    local ccb, items = CCBReaderLoad("UIEffect/yanhuisaoguang/yanhuisaoguang", nil, true, "yanhuisaoguang")
    ccb:setPosition(0, 0)
    self.rootItems.timeSaoguangNode:addChild(ccb)
    -- local animationManager = getAnimationManager(items)
    -- animationManager:setAnimationCompletedCallback(function()
    --     ccb:removeFromParentAndCleanup(true)
    -- end)
    -- animationManager:runAnimationsForSequenceNamed("saoguang") 
    local ccb1, items1 = CCBReaderLoad("UIEffect/yanhuisaoguang/jielongchenggong", nil, true, "jielongchenggong")
    ccb1:setPosition(0, -720)
    local animationManager = getAnimationManager(items1)
    animationManager:setAnimationCompletedCallback(function()
        ccb1:removeFromParentAndCleanup(true)
    end)
    -- animationManager:runAnimationsForSequenceNamed("saoguang") 
    self.rootItems.topnode:addChild(ccb1)
end

function guildfeast.stopDaojishiAnim(self)
    if self.jishiitems then
        local animationManager = getAnimationManager(self.jishiitems)
        animationManager:runAnimationsForSequenceNamed("daojishi_00") 
    end
end
function guildfeast.createDaojishiAnim(self)
    self.rootItems.haomiaonode:removeAllChildrenWithCleanup(true)
    local ccb, items = CCBReaderLoad("gonghui3/gonghui_yanhuidaojishi", nil, true, "gonghui_yanhuidaojishi")
    ccb:setPosition(0, 0)
    self.jishiitems = items
    self.rootItems.haomiaonode:addChild(ccb)
    local animationManager = getAnimationManager(self.jishiitems)
    animationManager:runAnimationsForSequenceNamed("daojishi_00")
end

function guildfeast.handStartFeast(self)
    local configData = gamedata.config.gang2_feast_award
    self.rootItems.shouyiNode:setVisible(true)
    local animationManager = getAnimationManager(self.rootItems)
    animationManager:setAnimationCompletedCallback(function()
        self:addAnim()
    end)
    animationManager:runAnimationsForSequenceNamed("shouyiout") 
    for i,v in pairs(self.data.feastPlayers) do
        if v then
            local idx = v.params["1"].i
            local tempconfig = configData[tostring(v.level)]
            local tempAwardArr = ui.getIDandNUMs(tempconfig[tostring(self.roomId)].award)
            if v.params["2"].i == 2 then
                tempAwardArr = ui.getIDandNUMs(tempconfig[tostring(self.roomId)].award_2)
            end
            local shouyi1 = tempAwardArr[1].num * self.curbei
            self:createExpUpAnim(self.rootItems["playerNode"..idx],shouyi1,v.params["2"].i)
        end
    end
end

function guildfeast.createStartAnim(self, animType, cb)
    local configData = gamedata.config.gang2_feast_award
	
    local Gneral = ui.itemcache:loadSkeleton("yanhui",{})
    Gneral:setAnimation(animType,false,0)
    Gneral:setScale(1)
    Gneral:setPosition(gameConfig.originSize.width/2, gameConfig.originSize.height/2)
    self.rootNode:addChild(Gneral.root or Gneral)
    local sq = CCSequence:createWithTwoActions(CCDelayTime:create(5), CCCallFunc:create(function()
        print("=======StartAnim======="..animType)
        if animType == "start" then
            self.rootItems.shouyiNode:setVisible(true)
            local animationManager = getAnimationManager(self.rootItems)
            animationManager:setAnimationCompletedCallback(function()
                self:addAnim()
            end)
            animationManager:runAnimationsForSequenceNamed("shouyiout") 
            for i,v in pairs(self.data.feastPlayers) do
                if v then
                    local idx = v.params["1"].i
                    local tempconfig = configData[tostring(v.level)]
                    local tempAwardArr = ui.getIDandNUMs(tempconfig[tostring(self.roomId)].award)
                    if v.params["2"].i == 2 then
                        tempAwardArr = ui.getIDandNUMs(tempconfig[tostring(self.roomId)].award_2)
                    end
                    local shouyi1 = tempAwardArr[1].num * self.curbei
                    self:createExpUpAnim(self.rootItems["playerNode"..idx],shouyi1,v.params["2"].i)
                end
            end
        elseif animType == "end" then
            print("=======StartAnim=====end===")
            -- self:createDaojishiAnim()
            self:stopDaojishiAnim()
            -- UIRequest({type = 2273, beinum = self.curbei, roomid = self.roomId, personnum = self.recordsPerson})
            
            for i = 1, 13 do
                self.rootItems["playerNode"..i]:stopAllActions()
            end

            if cb then
                cb()
            end
        end
    end))
    self.rootNode:runAction(sq)
end

function guildfeast.createExpUpAnim(self, animPrent, expnum, isdown)
    local shuaijianConfig = gamedata.config.gang2_feast_profit
    local extTime = self.data.myFeastTime--(self.data.myFeastTime - self.data.rewardTimeNum)
    local curprofit = 1
    
    for i=1,table.getTableLength(shuaijianConfig) do
        local v = shuaijianConfig[tostring(i)]
        if self.data.curDayTimeNum+extTime < v.times then
            curprofit = (v.profit/100)
            break
        end
    end

    local sq = CCSequence:createWithTwoActions(CCCallFunc:create(function()
        local tempval = math.ceil(expnum*0.1)
        local randomNum = math.random(expnum - tempval,expnum + tempval)
        local ccb, items = CCBReaderLoad("UIEffect/jihuijianglieffect/jihuijianglieffect3", nil, true, "jihuijianglieffect3")
        ccb:setPosition(0, 0)
        if isdown == 2 then
            items.explabel1:setString(""..math.ceil(randomNum*curprofit))
        else
            items.explabel1:setString(""..math.ceil(randomNum))
        end
        animPrent:addChild(ccb)
        local animationManager = getAnimationManager(items)
        animationManager:runAnimationsForSequenceNamed("jihuijianglieffectexp") 
    end),CCDelayTime:create(0.5))
    animPrent:runAction(CCRepeatForever:create(sq))
end

function guildfeast.createDuihuaAnim(self, idx)
    local duihuaConfigData = gamedata.config.gang2_feast_bubble
    local dir = idx > 3 and 0 or 1
    local ccb, items = CCBReaderLoad("gonghui3/yanhuirenwu_duihua_left", nil, true, "yanhuirenwu_duihua_left")
    if dir == 1 then
        ccb, items = CCBReaderLoad("gonghui3/yanhuirenwu_duihua_right", nil, true, "yanhuirenwu_duihua_right")
    end
    local tempidx = math.random(1,9)
    items.duihualabel:setString(duihuaConfigData[tostring(tempidx)].text)
    ccb:setPosition(0, 0)
    self.rootItems["duihuaNode"..idx]:addChild(ccb)
    local animationManager = getAnimationManager(items)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
        end)
    animationManager:runAnimationsForSequenceNamed("duihua") 
end

function guildfeast.checkoutext(self,layername)
    local notout = false
    if self.needoutext then
        notout = true
        runGamePrompt({msg = "退出公会盛宴后可前往"})
    end
    return notout    
end 
function guildfeast.UIUpdateData(self, isreset)
    if isreset then
        UIRequest({type = 2274})
    end
end

return guildfeast
  2�  