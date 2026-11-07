-- 总次数只受资源限制；1126仍每批最多200次，收到本批结果后才发送下一批。
local pending, owner, serial = nil, nil, 0

local function controls(self, running)
    if not self.rootItems then return end
    local locked = running or pending ~= nil
    for _,name in ipairs({"add10","sub10","attrButton1","attrButton2","attrButton3","rulebutton"}) do
        self.rootItems[name]:setEnabled(not locked)
    end
    self.localFosterInput:setEnabled(not locked)
    ui.setLabelString(self.rootItems.doLab, running and "停止培养" or (pending and "等待结算" or gameConfig.strings:string_common("general",68)),19)
end

function generalcultivate.localFosterStop(self, message)
    if self.localFosterRun then self.localFosterRun.active = false end
    self.localFosterRun = nil
    if owner == self then owner = nil end
    if self.localFosterTimer then self.localFosterTimer:stopAllActions() end
    controls(self,false)
    if message then runGamePrompt({msg=message}) end
end

local function ready(self, run)
    local window = gameWindows.windows.generalcultivate
    if self.localFosterRun ~= run or not run.active or not self.rootNode or self.localFosterView ~= run.view
        or not window or not window.show or window.module ~= self or self.iid ~= run.iid or self.method ~= run.method
        or GameScene.presentLayer ~= run.layer or (guide and guide.controller and guide.controller.isOnGuide)
        or (getbattlecallbackactive and getbattlecallbackactive()) then return false end
    for i=1,3 do if self["status"..i] ~= run.flags[i] then return false end end
    return true
end

local function send(self, run)
    if not ready(self,run) then self:localFosterStop("自动培养已停止：窗口、伙伴或筛选已变化") return end
    if pending then return end
    serial = serial+1
    local left = run.total-run.done
    local request = {id=serial,window=self,run=run,deadline=os.time()+21}
    pending = request
    local function check()
        if pending ~= request or self.localFosterRun ~= run then return end
        if not ready(self,run) then self:localFosterStop("自动培养已停止：已离开当前伙伴") return end
        if os.time() >= request.deadline then
            self:localFosterStop("本批培养结果未知，已停止且不会重试；请等待回复或重进游戏")
            return
        end
        self.localFosterTimer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(check)))
    end
    self.localFosterTimer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(1),CCCallFunc:create(check)))
    UIRequest({type=1126,iid=run.iid,method=run.method,xlnum=math.min(200,left),
        status1=run.flags[1],status2=run.flags[2],status3=run.flags[3],localFosterBatch=serial,localFosterTotal=left})
end

function generalcultivate.localFosterStart(self)
    if pending then runGamePrompt({msg="上一批培养尚未结束；结果未知时请重进游戏"}) return end
    if self.localFosterRun then return end
    if not self.donum or self.donum < 1 or self.donum >= 2147483648 or self.donum % 1 ~= 0 then
        runGamePrompt({msg="请输入现有培养丹、元宝可支付的正整数次数"}) return
    end
    local run = {active=true,view=self.localFosterView,iid=self.iid,method=self.method,total=self.donum,done=0,
        flags={self.status1,self.status2,self.status3},layer=GameScene.presentLayer}
    self.localFosterRun, owner = run, self
    controls(self,true)
    runGamePrompt({msg="自动培养已开始：次数栏显示剩余次数，可点击停止培养"})
    send(self,run)
end

function generalcultivate.reloadData(self, data)
    self.extGeneralData, self.oldPotential = data.general, data.general.potential
    self.hasstonenum = data.remaining
    self.stop, self.status = data.stop, data.status or {}
    self.total = table.getTableLength(self.status)
    self:initnum(self.donum)
    self:initEmpteyLabelString(false)
    ui.setLabelString(self.rootItems.costnum4,self.hasstonenum,14)
    self.ListTableView:reloadData()
    self.ListTableView:setLuaContentOffset(0,0)
end

function LocalFosterAutoReply(t)
    local request = pending
    if not request or request.id ~= t.localFosterBatch then return false end
    pending = nil
    local self, run = request.window, request.run
    local active = ready(self,run)
    run.done = run.done+t.actual
    if self.localFosterView == run.view and self.rootNode and self.iid == run.iid then
        self.localFosterTimer:stopAllActions()
        self.donum = run.total-run.done
        self:reloadData(t)
    end
    if not active or t.stop == 1 or run.done >= run.total then
        self:localFosterStop(active and string.format("自动培养已结束，实际执行%d次",run.done) or nil)
        return true
    end
    -- 下一帧继续，让绝对库存/角色校准和用户的停止操作先处理；不累计无限结果行或动画。
    self.localFosterTimer:runAction(CCSequence:createWithTwoActions(CCDelayTime:create(0.1),CCCallFunc:create(function()
        if self.localFosterRun == run then send(self,run) end
    end)))
    return false
end

function LocalFosterAutoError(t)
    if pending and t.localFosterBatch == pending.id and (not t.request_opcode or t.request_opcode == 1126) then
        local self = pending.window
        pending = nil
        self:localFosterStop()
    end
end

function LocalFosterAutoStop(message)
    if owner then owner:localFosterStop(message) end
end

local originalOpen, originalClose, originalNumchange = generalcultivate.open, generalcultivate.close, generalcultivate.numchange
function generalcultivate.open(self,...)
    self.localFosterView = (self.localFosterView or 0)+1
    local result = originalOpen(self,...)
    self.localFosterTimer = CCNode:create()
    self.rootNode:addChild(self.localFosterTimer)
    controls(self,false)
    return result
end

function generalcultivate.close(self,...)
    self:localFosterStop()
    self.localFosterView = (self.localFosterView or 0)+1
    self.localFosterTimer, self.localFosterInput = nil,nil
    return originalClose(self,...)
end

function generalcultivate.numchange(self,num)
    if self.localFosterRun or pending then return end
    return originalNumchange(self,num)
end
