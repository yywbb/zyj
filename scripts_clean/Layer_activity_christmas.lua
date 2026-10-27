--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-9
-- Time: 下午6:52
-- To change this template use File | Settings | File Templates.
--

local activity_christmas = {

    rootNode = nil,
    rootItems = nil,

    data = {},

    rewardconfig = {},
    max_integral = 0,
    max_index = 0,

}



function activity_christmas.init(self,size)
    self.contentsize = size
    self.show = true
    -- self.rootNode,self.rootItems = CCBReaderLoad("activityjieri/activityshengdanqifu", nil, true, "activityshengdanqifu")
    self.rootNode,self.rootItems = CCBReaderLoad("activityjieri/activityyuanxiaodengmi", nil, true, "activityyuanxiaodengmi")

    self.rootItems.topnode:setPositionY(self.contentsize.y-180)

    --
    if self.rootItems.guessNode then
        self.rootItems.guessNode:setVisible(false)
    end    
    --
    local showreward = {}
    for i = 5,1,-1 do
        if gamedata.config.Christmas_reward and gamedata.config.Christmas_reward[tostring(i)] then
            local reward = ui.getTableFromStr(gamedata.config.Christmas_reward[tostring(i)].reward) or {}
            for k,v in pairs(reward) do
                if v.cid and v.cid > 0 then
                    table.insert(showreward,v)
                end
            end    
        end
    end    

    self.rootItems["btnPreShow"]:setSwallowsTouch(true)
    self.rootItems["btnPreShow"]:setTouchPriority(-102)
    self.rootItems["btnPreShow"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("getStaff",{data = showreward,type = "奖励预览"},nil)
    end,CCControlEventTouchUpInside)  

    --
    self.rootItems["btnRule"]:setSwallowsTouch(true)
    self.rootItems["btnRule"]:setTouchPriority(-102)
    self.rootItems["btnRule"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameWindows:openWindow("newJieriRule",{systemid = 435})
        --
    end,CCControlEventTouchUpInside)  

    --pos
    self.rewardconfig = {}
    self.max_integral = 0
    self.max_index = 0
    for i = 1,4 do
        if gamedata.config.Christmas_awards and gamedata.config.Christmas_awards[tostring(i)] then
            self.rewardconfig[i] = gamedata.config.Christmas_awards[tostring(i)]
            self.max_integral = math.floor(gamedata.config.Christmas_awards[tostring(i)].integral*1.2)
            self.max_index = i
        end
    end

    for i = 1,4 do
        if self.rewardconfig[i] then
            self.rootItems["rewardNode"..i]:setVisible(true)
            self.rootItems["rewardNode"..i]:setPositionX(920*self.rewardconfig[i].integral/self.max_integral)
            ui.setLabelString(self.rootItems["rewardnum"..i],self.rewardconfig[i].integral,1)
            --
            self.rootItems["rewardbutton"..i]:setSwallowsTouch(true)
            self.rootItems["rewardbutton"..i]:setTouchPriority(-102)
            self.rootItems["rewardbutton"..i]:addHandleOfControlEvent(function()
                if GameScene.layers["activity"].module.isContentScroll then  return end
                gameTouch:clickprofbytime(0.5)
                local tempdata = ui.getIDandNUMs(self.rewardconfig[i].props) or {}
                if self.data["status"..i] and self.data["status"..i] >= 2 then
                    gameWindows:openWindow("getStaff",{data = tempdata,type = "已领取"},nil)
                elseif self.data.donum and self.data.donum >= self.rewardconfig[i].integral then
                    UIRequest({type = 6603, id = i})
                else
                    gameWindows:openWindow("getStaff",{data = tempdata,type = "奖励预览"},nil)
                end    
            end,CCControlEventTouchUpInside)  
        else
            self.rootItems["rewardNode"..i]:setVisible(false)
            self.rootItems["rewardNode"..i]:setPositionX(9999)
        end    
    end

    ui.setSpriteTextureRect2(self.rootItems.process,0,0,0,31)
    --ui.setSpriteTextureRect2(self.rootItems.process,0,0,920 * (now > self.max_integral and self.max_integral or now) / self.max_integral,22)

    --
    local timediff = 0
    if self.rootItems.activitytime1 and gamedata.config.activity_time["134"]["open_type"] and gamedata.config.activity_time["134"]["open_type"] == 2 then
        
    elseif self.rootItems.activitytime1 and gamedata.config.activity_time["134"]["open_type"] and gamedata.config.activity_time["134"]["open_type"] == 1 then
        local nowtime = gamedata:time()
        local temp = os.date("*t", GameScene.roleinfo.servertime)
        timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["134"]["continued_time"]+(gamedata.config.activity_time["134"]["days_later"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        if timediff < nowtime then
            timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["134"]["continued_time"]+(gamedata.config.activity_time["134"]["days_later2"] or 0)) - temp.hour*3600 - temp.min*60 - temp.sec
        end
        --
    elseif self.rootItems.activitytime1 and gamedata.config.activity_time["134"]["end"] and gamedata.config.activity_time["134"]["end"] ~= "" then
        local year1,month1,day1,hour1,minute1,second1 = ui.getDate(gamedata.config.activity_time["134"]["end"])
        local time1 = os.time({year=year1, month=month1, day=day1, hour=hour1, min = minute1, sec =  second1})
        local nowtime = gamedata:time()
        timediff = time1-nowtime      
    end

    if self.rootItems.activitytime1 and timediff and timediff > 0 then
        gameTimer:rigistTime("activityChristmasTime",timediff)        
        if gameTimer.times["activityChristmasTime"] and gameTimer.times["activityChristmasTime"] > 0 then
            gameTimer:rigistTimeFunc("activityChristmasTime", function()
                if gameTimer.times["activityChristmasTime"] <= 0 then
                    if gameTimer.times["activityChristmasTime"] then
                        ui.setLabelString(self.rootItems.activitytime1,"",14)
                        gameTimer:UnrigistTimeFunc("activityChristmasTime")
                    end
                else
                    ui.setLabelString(self.rootItems.activitytime1,"活动结束倒计时："..ui.makeTimeDayText(gameTimer.times["activityChristmasTime"],"day"),14)
                end
            end)
        end
    else
        ui.setLabelString(self.rootItems.activitytime1,"",14)
    end


    if self.rootItems["showButton"] then
        ui.setLabelString(self.rootItems.showLab,nil,19)
        self.rootItems["showButton"]:setSwallowsTouch(true)
        self.rootItems["showButton"]:setTouchPriority(-102)
        self.rootItems["showButton"]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameTouch:clickprofbytime(1)
            UIRequest({type = 6604})
        end,CCControlEventTouchUpInside)  
    end    


    return self.rootNode

end



function activity_christmas.reloaddata(self,data)

    if not self.show then return end

    if data then
        self.data = data
    end

    ui.setLabelString(self.rootItems.donumdesc2,nil,14)
    ui.setLabelString(self.rootItems.doLab,nil,19)
    ui.setLabelString(self.rootItems.desc,nil,11)
    ui.setLabelString(self.rootItems.propnum,self.data.propnum or 0,21)
    ui.setLabelString(self.rootItems.donumdesc,"当前全服逛花灯次数："..(self.data.donum or 0),14)
    -- ui.setLabelString(self.rootItems.donumdesc,"当前全服祈福次数: "..(self.data.donum or 0),14)

    ui.setSpriteTextureRect2(self.rootItems.process,0,0,920 * (self.data.donum > self.max_integral and self.max_integral or self.data.donum) / self.max_integral,22)

    local hasindex = 0
    for i = 1,4 do
        if self.rewardconfig[i] then
            if self.data["status"..i] and self.data["status"..i] >= 2 then
                --setSpriteFrameByName(self.rootItems["rewardsprite"..i], "box4_2")
                hasindex = i
                --
                self.rootItems["rewardsprite"..i.."_0"]:setVisible(false)
                self.rootItems["rewardsprite"..i.."_1"]:setVisible(false)
                self.rootItems["rewardsprite"..i.."_2"]:setVisible(true)
            elseif self.data.donum and self.data.donum >= self.rewardconfig[i].integral then
                --setSpriteFrameByName(self.rootItems["rewardsprite"..i], "box4_1")
                hasindex = i
                --
                self.rootItems["rewardsprite"..i.."_0"]:setVisible(false)
                self.rootItems["rewardsprite"..i.."_1"]:setVisible(true)
                self.rootItems["rewardsprite"..i.."_2"]:setVisible(false)
            else
                --setSpriteFrameByName(self.rootItems["rewardsprite"..i], "box4_0")
                --
                self.rootItems["rewardsprite"..i.."_0"]:setVisible(true)
                self.rootItems["rewardsprite"..i.."_1"]:setVisible(false)
                self.rootItems["rewardsprite"..i.."_2"]:setVisible(false)
            end 
        end   
    end    

    self.rootItems["doButton"]:setSwallowsTouch(true)
    self.rootItems["doButton"]:setTouchPriority(-102)
    self.rootItems["doButton"]:addHandleOfControlEvent(function()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(1)
        if self.data.propnum and self.data.propnum > 0 then
            UIRequest({type = 6602})
        else
            runGamePrompt({msg = "道具不足"})
        end    
    end,CCControlEventTouchUpInside)  

    if self.data.propnum and self.data.propnum > 0 then
        ui.removeGray("CCControlButton",self.rootItems["doButton"])
    else
        ui.addGray("CCControlButton",self.rootItems["doButton"])
    end

    -- self.max_index , hasindex
    for i = 1,5 do
        if self.rootItems["effect"..i] then
            if i <= 5-self.max_index+hasindex then
                self.rootItems["effect"..i]:setVisible(true)
            else 
                self.rootItems["effect"..i]:setVisible(false)
            end
        end
    end    



end

function activity_christmas.showquestion(self)
    if not self.rootItems.guessNode then return end
    if GameScene.guessing_riddles_question and next(GameScene.guessing_riddles_question) then
        --
    else
        GameScene.guessing_riddles_question = {}
        for k,v in pairs(gamedata.config.guessing_riddles) do
            table.insert(GameScene.guessing_riddles_question,v.id)
        end    
    end    
    --
    local showindex = math.random(1,#GameScene.guessing_riddles_question)
    local showquestionid = GameScene.guessing_riddles_question[showindex]
    local riddles = gamedata.config.guessing_riddles[tostring(showquestionid)] or {}
    table.remove(GameScene.guessing_riddles_question,showindex)
    --
    self.rootItems.guessNode:setVisible(true)
    self.rootItems.showNode:setVisible(true)
    self.rootItems.answer:setVisible(false)
    self.rootItems.answerstate:setVisible(false)
    ui.setLabelString(self.rootItems.question,riddles.question,18)
    ui.setLabelString(self.rootItems.answer,riddles.answer,18)
    ui.setLabelString(self.rootItems.answerstate,riddles.state,13)
    if self.rootItems.showstate then
        ui.setLabelString(self.rootItems.showstate,nil,13)
    end

end   

function activity_christmas.showanswer(self)
    if not self.rootItems.guessNode then return end

    self.rootItems.showNode:setVisible(false)
    self.rootItems.answer:setVisible(true)
    self.rootItems.answerstate:setVisible(true)

end    


function activity_christmas.clear(self)

    self.show = false

    self.data = {}

    if gameTimer.times["activityChristmasTime"] then
        gameTimer:UnrigistTimeFunc("activityChristmasTime")
    end

    if self.rootNode then
        self.rootNode:removeAllChildrenWithCleanup(true)
        self.rootNode:removeFromParentAndCleanup(true)
        self.rootNode = nil
        self.rootItems = nil
    end
end


return activity_christmas
