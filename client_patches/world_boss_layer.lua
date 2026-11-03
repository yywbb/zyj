function worldboss.localWorldBossRequest(self,req)
    req.view,req.page=self.localWorldBossView,self.selectpage
    if req.type==3401 or req.type==3411 then
        if self.localWorldBossBusy or self.localWorldBossPlaying then return end
        local data=self.data[self.selectpage].statusdata
        if data.status~=1 then self:setauto(false);return end
        if req.method==10 and not req.confirmed then
            self:setauto(false)
            local view,page=self.localWorldBossView,self.selectpage
            local cooling=(self.localWorldBossReady or 0)>gamedata:time()
            local price=tonumber(gamedata.config.global_kv.worldboss_gold.value)
            gameWindows:openWindow("confirm",{localWorldBossPick=cooling,localWorldBossPrice=price,
                msg=cooling and "选择本次复活：5元宝普通再战，或"..price.."元宝本场攻击翻倍。关闭不扣款。"
                    or "花费"..price.."元宝挑战一次？仅本场攻击翻倍。"},function(method)
                if self.rootNode and self.localWorldBossView==view and self.selectpage==page then
                    self:localWorldBossRequest({type=req.type,method=method or 10,isauto=false,confirmed=true})
                end
            end)
            return
        end
        if (req.method or 0)==0 and (self.localWorldBossReady or 0)>gamedata:time() then return end
        self.localWorldBossBusy=req.type
        self:setAttackstatus(false)
    end
    UIRequest(req)
end
local nativeAttackStatus=worldboss.setAttackstatus
function worldboss.setAttackstatus(self,live)
    nativeAttackStatus(self,live and (self.localWorldBossReady or 0)<=gamedata:time())
    for _,name in ipairs({"attackbutton","goldrelivebutton"}) do
        self.rootItems[name]:setEnabled(not self.localWorldBossBusy and not self.localWorldBossPlaying)
    end
end
function worldboss.setattackCD(self,cd)
    self.localWorldBossReady=gamedata:time()+(cd or 0)
    gameTimer.times[self.data[self.selectpage].worldbossattack]=cd or 0
    self:setAttackstatus((cd or 0)<=0)
    ui.setLabelString(self.rootItems.reliveCD,tostring(cd or 0).."s",3)
end
local nativeRealRank=worldboss.setrealrank
function worldboss.setrealrank(self,data)
    self.data[self.selectpage].realrank=data or {}
    ui.setLabelString(self.rootItems.myrankLabel,"未进榜",14)
    if not next(data or {}) then
        if self.ListTableView then self.ListTableView:reloadData() end
        return
    end
    return nativeRealRank(self,data)
end
function worldboss.reloadstatus(self,data)
    self.data[self.selectpage].statusdata=data
    self:setauto(self.isauto and data.status==1)
    if data.status==1 then
        self:setBattle(data)
        self:shiftNode(self.hasjoin and "battle" or "start")
    else
        self:shiftNode("normal")
        self:setbosshp(data.bosshp)
    end
    self:startnotify()
end
function worldboss.reloadnotify(self,data)
    local queued=self.data[self.selectpage].notifys
    for _,info in ipairs(data or {}) do table.insert(queued,info) end
    while #queued>100 do table.remove(queued,1) end
end
function worldboss.setstarttimer(self) self:startnotify() end
function worldboss.setendtimer(self) end
function worldboss.startnotify(self)
    if self.localWorldBossPlaying then return end
    gameTimer:rigistTime("localworldboss",99999)
    gameTimer:rigistTimeFunc("localworldboss",function()
        local layer=GameScene.layers.worldboss
        if not layer.show or not self.rootNode then
            self.isauto=false
            gameTimer:UnrigistTimeFunc("localworldboss")
            return
        end
        local now=gamedata:time()
        if self.localWorldBossTick==now then return end
        self.localWorldBossTick=now
        local cd=math.max(0,(self.localWorldBossReady or 0)-now)
        gameTimer.times[self.data[self.selectpage].worldbossattack]=cd
        ui.setLabelString(self.rootItems.reliveCD,tostring(cd).."s",3)
        self:setAttackstatus(cd==0)
        local seconds=(now+28800)%86400
        local hour=self.selectpage=="onepage" and 12 or 21
        local begin=hour*3600
        ui.setLabelString(self.rootItems.starttime,ui.makeTimeText((begin-seconds)%86400),26)
        ui.setLabelString(self.rootItems.endCD,ui.makeTimeText(math.max(0,begin+1800-seconds),"minute"),29)
        if self.localWorldBossBusy or self.localWorldBossPlaying or (battleScene and battleScene.show) then return end
        if not self.localWorldBossPoll or now>=self.localWorldBossPoll then
            self.localWorldBossPoll=now+5
            self:localWorldBossRequest({type=self.data[self.selectpage].request0})
            self:localWorldBossRequest({type=self.data[self.selectpage].request3})
        end
        self:showOneNotify()
        for _,window in pairs(gameWindows.windows) do if window.show then return end end
        if self.isauto and self.hasjoin and self.choosepage=="battle" and cd==0 and self.data[self.selectpage].statusdata.status==1 then
            self:localWorldBossRequest({type=self.data[self.selectpage].request1,method=0,isauto=true})
        end
    end)
end
function worldboss.stoptnotify(self) gameTimer:UnrigistTimeFunc("localworldboss") end
local nativeStop=worldboss.stopNextAllEvent
function worldboss.stopNextAllEvent(self)
    self:stoptnotify()
    gameTimer:UnrigistTimeFunc("worldbossattack1")
    gameTimer:UnrigistTimeFunc("worldbossattack2")
    return nativeStop(self)
end
local nativeInit=worldboss.init
function worldboss.init(self,parent,toppos,param)
    nativeInit(self,parent,toppos,param)
    ui.setLabelString(self.rootItems.rewarddecLable,"本地规则：挑战冷却60秒\n排名与击杀奖励由系统邮件领取",7)
end
