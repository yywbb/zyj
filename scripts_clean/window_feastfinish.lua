--
-- Created by IntelliJ IDEA.
-- User: dhope
-- Date: 19/11/8
-- Time: 上午10:58
--

local feastfinish = {
    rootNode = nil,
    rootItems = nil,
    -- snatch = {},
    needcallback = true,
}

function feastfinish.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("gonghui3/tc_jiesuan", nil, true, "tc_jiesuan")
    self.show = true
    self.touchPriority = touchPriority

    self.callback = callback
    
    --转换经验丹特殊处理
    local reward = {}
    local ischange = false
    local otherReward = {}

    --升级会有元宝和银币 需要去掉

    for k,v in pairs(data.data.reward) do
        if v.cid == 20199 then
            otherReward[20199] = v.num
            ischange = true
        end
        if v.cid == 1031 then
            otherReward[1031] = v.num
        end

        if v.cid ~= 20199 and v.cid ~= 1031 and v.cid ~= 1000 and v.cid ~= 1001 then
            reward[tostring(table.getTableLength(reward) + 1)] = v
        end
        
    end

    local slotnum = 0
    local slotData = GameScene.layers["slotsInfo"].module.slotdata
    for i=1,7 do
        if slotData[tostring(i)] and slotData[tostring(i)].general and GameScene.protagonist.general.cid ~= slotData[tostring(i)].general.cid then
            slotnum = slotnum + 1
        end
    end
    if ischange and self.rootItems.changLab then
        reward[tostring(table.getTableLength(reward) + 1)] = {cid = 20199,num = otherReward[20199]}
        self.rootItems.changLab:setVisible(true)
        self.rootItems.changLab:setString(string.format("本次总共获得伙伴经验%d X%d，已全部转换为神奇经验丹", otherReward[1031] or 0,slotnum))
        self.rootItems.extNode2:setVisible(false)
    elseif otherReward[1031] then
        reward[tostring(table.getTableLength(reward) + 1)] = {cid = 1031,num = otherReward[1031]}
    end
    data.data.reward = reward

    printT(data)
    if data.jieshutype then
        self:initinfo(data)
    else
        self:reload(data,callback)
    end
    return self.rootNode
end
--补发奖励
function feastfinish.initinfo(self,data)
    self.data = data.data

    -- self.rootItems.closeButton:addHandleOfControlEvent(function()
    --     gameWindows:closeWindow("feastjiesuan")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.closeButton:setSwallowsTouch(true)
    -- self.rootItems.closeButton:setTouchPriority(self.touchPriority)

   
    local idx = 1
    for i = 1, table.getTableLength(self.data.reward) do
        if self.rootItems["rewardIcon"..idx] then
            local v = self.data.reward[tostring(i)]
            if v then
                -- if v.cid == 1017 or v.cid == 20768 then
                    local icondata = ui.IDconfig(v.cid)
                    setSpriteFrameByName(self.rootItems["rewardIcon"..idx],icondata.icon..".png")
                    self.rootItems["propName"..idx]:setString(icondata.name)
                    self.rootItems["gatheringReward"..idx]:setString(""..v.num)
                    idx = idx + 1
                -- end
            else
                self.rootItems["gatheringReward"..idx]:setVisible(false)
                self.rootItems["rewardIcon"..idx]:setVisible(false)
                self.rootItems["rewardbg"..idx]:setVisible(false)
                self.rootItems["rewardbgnei"..idx]:setVisible(false)
                idx = idx + 1
            end
        end
    end
    self.rootItems["titlelabel"]:setVisible(true)
    for i=1,3 do
        self.rootItems["titlelabel"..i]:setVisible(false)
    end
    self.rootItems["extrareward1"]:setVisible(false)
    self.rootItems["extrareward2"]:setVisible(false)
    self.rootItems.extralabel1:setVisible(false)
    self.rootItems.extralabel2:setVisible(false)
    self.rootItems.extranode:setVisible(false)
    -- self.rootItems["titlelabel"..self.data.roomid]:setVisible(true)
    -- self.rootItems["noRewardLabel"]:setVisible(true)
 

    -- self.rootItems.sure_btn:addHandleOfControlEvent(function()
    --     gameWindows:closeWindow("feastjiesuan")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.sure_btn:setSwallowsTouch(true)
    -- self.rootItems.sure_btn:setTouchPriority(self.touchPriority)
end

function feastfinish.reload(self,data,callback)

    self.data = data.data

    -- self.rootItems["noRewardLabel"]:setVisible(false)
    -- self.rootItems.closeButton:addHandleOfControlEvent(function()
    --     self.callback = nil
    --     gameWindows:closeWindow("feastjiesuan")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.closeButton:setSwallowsTouch(true)
    -- self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    -- self.rootItems.sure_btn:addHandleOfControlEvent(function()
    --     gameWindows:closeWindow("feastjiesuan")
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.sure_btn:setSwallowsTouch(true)
    -- self.rootItems.sure_btn:setTouchPriority(self.touchPriority)

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
                if v.cid == 20199 then
                    self.rootItems["gatheringReward"..idx]:setString(v.num)
                end
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
function feastfinish.createExpUpAnim(self, posx, posy, idx, val)
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

function feastfinish.close(self)
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

return feastfinish
