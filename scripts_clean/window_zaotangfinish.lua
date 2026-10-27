--
-- Created by IntelliJ IDEA.
-- User: dhope
-- Date: 19/11/8
-- Time: 上午10:58
--

local zaotangfinish = {
    rootNode = nil,
    rootItems = nil,
    -- snatch = {},
    needcallback = true,
}

function zaotangfinish.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui3/tc_zaotangjiesuan", nil, true, "tc_zaotangjiesuan")
    self.show = true
    self.touchPriority = touchPriority

    self.callback = callback
        
    local reward = {}
    for k,v in pairs(data.data.reward) do
        if  v.cid ~= 1000 and v.cid ~= 1001 then
            reward[tostring(table.getTableLength(reward) + 1)] = v
        end
    end
    data.data.reward = reward

    if data.jieshutype then
        self:initinfo(data)
    else
        self:reload(data,callback)
    end
    return self.rootNode
end
--补发奖励
function zaotangfinish.initinfo(self,data)
    self.data = data.data
    local idx = 1
    for i = 1, table.getTableLength(self.data.reward) do

        if self.rootItems["rewardIcon"..idx] then
            local v = self.data.reward[tostring(i)]
            if v then
                local icondata = ui.IDconfig(v.cid)
                setSpriteFrameByName(self.rootItems["rewardIcon"..idx],icondata.icon..".png")
                self.rootItems["propName"..idx]:setString(icondata.name)
                self.rootItems["gatheringReward"..idx]:setString(""..v.num)
                idx = idx + 1
            else
                self.rootItems["gatheringReward"..idx]:setVisible(false)
                self.rootItems["rewardIcon"..idx]:setVisible(false)
                self.rootItems["rewardbg"..idx]:setVisible(false)
                self.rootItems["rewardbgnei"..idx]:setVisible(false)
                idx = idx + 1
            end
        end
        
    end
    for i=1,3 do
        self.rootItems["titlelabel"..i]:setVisible(false)
    end
    self.rootItems["titlelabel"]:setVisible(true)
    self.rootItems["extrareward1"]:setVisible(false)
    self.rootItems["extrareward2"]:setVisible(false)
    self.rootItems.extralabel1:setVisible(false)
    self.rootItems.extralabel2:setVisible(false)
    self.rootItems.extranode:setVisible(false)
end

function zaotangfinish.reload(self,data,callback)

    self.data = data.data

    local jiacheng = (self.data.beinum-1)*100
    self.rootItems.jiachengbei:setString(jiacheng.."%")
    self.rootItems.canyuren:setString(self.data.personNum.."人")
    for i=1,3 do
        self.rootItems["titlelabel"..i]:setVisible(false)
    end
    self.rootItems["titlelabel"]:setVisible(false)

    print(self.data.beinum.."=====feastfinish.reload====="..self.data.roomid)
    self.rootItems["titlelabel"..self.data.roomid]:setVisible(true)

    if not next(self.data.reward) then
        for i = 1, 2 do
            self.rootItems["gatheringReward"..i]:setVisible(false)
            self.rootItems["rewardIcon"..i]:setVisible(false)
            self.rootItems["rewardbg"..i]:setVisible(false)
            self.rootItems["rewardbgnei"..i]:setVisible(false)
            self.rootItems["extrareward"..i]:setVisible(false)
        end
        self.rootItems["noRewardLabel"]:setVisible(true)
        return
    end

    
    local idx = 1
    for i = 1, table.getTableLength(self.data.reward) do
        if self.rootItems["rewardIcon"..idx] then
            local v = self.data.reward[tostring(i)]
            if v then
                local icondata = ui.IDconfig(v.cid)
                setSpriteFrameByName(self.rootItems["rewardIcon"..idx],icondata.icon..".png")
                local initval = math.ceil(v.num / self.data.beinum)
                local offval = v.num - initval
                self.rootItems["gatheringReward"..idx]:setString(""..initval)
                self.rootItems["propName"..idx]:setString(icondata.name)
                self.rootItems["extrareward"..idx]:setString(""..offval)
                idx = idx + 1
            else
                self.rootItems["gatheringReward"..idx]:setVisible(false)
                self.rootItems["rewardIcon"..idx]:setVisible(false)
                self.rootItems["rewardbg"..idx]:setVisible(false)
                self.rootItems["rewardbgnei"..idx]:setVisible(false)
                idx = idx + 1
            end
        end
    end
    
end
function zaotangfinish.createExpUpAnim(self, posx, posy, idx, val)
    local ccb, items = CCBReaderLoad("UIEffect/jihuijianglieffect/jihuijianglieffect", nil, true, "jihuijianglieffect")
    ccb:setPosition(posx, posy)
    items.explabel:setString(val)
    self.rootItems.rewardNode:addChild(ccb)
    local animationManager = getAnimationManager(items)
    animationManager:setAnimationCompletedCallback(function()
        ccb:removeFromParentAndCleanup(true)
        self.rootItems["gatheringReward"..idx]:setString(""..self.data.reward[idx].num)
        end)
    animationManager:runAnimationsForSequenceNamed("jihuijianglieffect") 
end

function zaotangfinish.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    self.show = false
    if self.callback then
        self.callback()
    end

    UIRequest({type = 2230,param = "activity"})
end

return zaotangfinish
