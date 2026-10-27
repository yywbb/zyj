--
-- Created by IntelliJ IDEA.
-- User: boomDone
-- Date: 14/11/26
-- Time: 下午6:47
-- To change this template use File | Settings | File Templates.
--
QRIL_DEBUG_ANIMATION = false
local dumpling = {
    buttontouch = -102,
    m_iDLNums = nil, -- 粽子个数
    m_iBoomData = nil, --爆炸类型
}

function dumpling.init(self,size)
    self.contentsize = size
    self.show = true
    self.m_tReward = {}
    for i,v in pairs(gamedata.config.zongzi_reward) do
        local id, num = ui.getIDandNUM(v["reward"])
        self.m_tReward[i] = {cid = id, num = num}
    end

    local tmpCallBack = {
        boomDone = function()
            self:deadDone()
        end,
        deadDone = function()
            if not self.m_bIsStop then
                self:giveThing()
            end
        end
    }

    -- 根节点
    self.coverccb, self.coveritems = CCBReaderLoad("activityduanwu/activityduanwu_rengzongzi",nil, true, "dumpling",tmpCallBack)
    self.animationManager = getAnimationManager(self.coveritems)
    self.animationManager:runAnimationsForSequenceNamed("free")

    self.coveritems.topnode:setPositionY(self.contentsize.y-180)

    -- 盘子
    self.dlnodeccb, self.dlnodeitems = CCBReaderLoad("activityduanwu/activityduanwu_zongzi",nil, true, "zongzi")
    self.dlnodanimationManager = getAnimationManager(self.dlnodeitems)
    self.coveritems.dlroot:addChild(self.dlnodeccb)

    -- 屈原 manroot
    self.mannodeccb, self.mannodeitems = CCBReaderLoad("UIEffect/rengzongzi/rengzongzi",nil, true, "rengzongzi",tmpCallBack)
    self.mannodanimationManager = getAnimationManager(self.mannodeitems)
    self.coveritems.manroot:addChild(self.mannodeccb)



    self.coveritems.helpButton:setTouchPriority(self.buttontouch)
    self.coveritems.helpButton:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        gameTouch:clickprofbytime(0.5)
        gameWindows:openWindow("getStaff",{data = self.m_tReward,type = gameConfig.strings:string_common("popups","jiangli")},nil)
    end, CCControlEventTouchUpInside)
    self.m_iDLNums = 0

    ui.setLabelString(self.coveritems.times_name,nil,14)
    ui.setLabelString(self.coveritems.time,nil,26)

    self:updatetimeFunc()
    self.m_bIsStop = true


    return self.coverccb
end

function dumpling.deadDone(self)
    if QRIL_DEBUG_ANIMATION or self.m_iBoomData._type == 0 then
        self.mannodanimationManager:runAnimationsForSequenceNamed("yu")
    else
        self.mannodanimationManager:runAnimationsForSequenceNamed("quyuan")
    end
end

function dumpling.reloaddata(self,data)
    self.m_iDLNums = data.num
    self.m_bIsStop = false
    self.coveritems.hasNum:setString(tostring(self.m_iDLNums))
    self.coveritems.button:setSwallowsTouch(true)
    self.coveritems.button:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then return end
            if self.m_iDLNums > 0 then
                gameTouch:clickprofbytime(0.5)
                if QRIL_DEBUG_ANIMATION then
                    self:play()
                else
                    UIRequest({type = 3307})
                end
            else
                gameWindows:openWindow("dropTips",{cid = 1012},nil)
                -- runGamePrompt({msg = gameConfig.strings:string_common("dumpling",1)})
            end
    end, CCControlEventTouchUpInside)

    local tmpPlayNum = (self.m_iDLNums > 6 and 7 ) or self.m_iDLNums
    self.dlnodanimationManager:runAnimationsForSequenceNamed(tostring(tmpPlayNum))
end

function dumpling.play(self,data)
    if self.animationManager ~= nil then
        self.coveritems.button:setEnabled(false)
        local tmpPlayNum = ((self.m_iDLNums - 1 > 6 and 7 ) or self.m_iDLNums - 1)
        self.dlnodanimationManager:runAnimationsForSequenceNamed(tostring(tmpPlayNum))

        self.m_iBoomData = data

        self.animationManager:runAnimationsForSequenceNamed("play")
        self.coveritems.hasNum:setString(tostring(self.m_iDLNums - 1))
    end
end

function dumpling.finishNow(self)
    if self.m_iBoomData ~= nil then
        self.m_bIsStop = true
        self.animationManager:runAnimationsForSequenceNamed("free")
        self.mannodanimationManager:runAnimationsForSequenceNamed("free")
        self:giveThing()
    end
end

function dumpling.giveThing(self)
    self.coveritems.button:setEnabled(true)
    if QRIL_DEBUG_ANIMATION then
        self:reloaddata({num = self.m_iDLNums - 1})
    else
        if self.m_iBoomData ~= nil then
            local function tmpActionDone()
                self.m_iBoomData = nil
                UIRequest({type = 3306})
            end
            showRewardPopupWindow(self.m_iBoomData._reward,nil,tmpActionDone)
        end
    end
end

function dumpling.updatetimeFunc( self )
    local nowtime = os.date("*t", gamedata:time())
    local remaintime = 0

    local isnow,remaintime = ui.checkDateActive(gamedata.config.activity_time["39"]["begin"],gamedata.config.activity_time["39"]["end"])
    -- local year,month,day,hour,minute,second = ui.getDate(gamedata.config.activity_time["38"]["end"])
    print("isnow,remaintime===",isnow,remaintime)
    if not isnow then
        return
    end

    gameTimer:rigistTime("dumpling_rewardtime", remaintime)
    gameTimer:rigistTimeFunc("dumpling_rewardtime",function()
    
        if gameTimer.times["dumpling_rewardtime"] >= 0 then
            if nowtime.wday == 1 then
                ui.setLabelString(self.coveritems.time,ui.makeTimeText(gameTimer.times["dumpling_rewardtime"],"hour"),26)
            else
                ui.setLabelString(self.coveritems.time,ui.makeTimeDayText(gameTimer.times["dumpling_rewardtime"],"day"),26)
            end
        end
        if gameTimer.times["dumpling_rewardtime"] == 0 then
            -- print("lunpan_rewardtime===",0)
            -- UIRequest({type=3820})
            gameTimer:UnrigistTimeFunc("dumpling_rewardtime")
        end
    end)
end

function dumpling.clear(self)
    self.show = false
    gameTimer:UnrigistTimeFunc("dumpling_rewardtime")
    self.animationManager = nil
    self.dlnodanimationManager = nil
    self.mannodanimationManager = nil
    self.mannodeccb  = nil
    self.mannodeitems = nil
    self.dlnodeccb  = nil
    self.dlnodeitems = nil
    self.coverccb = nil
    self.coveritems = nil
    self.m_iBoomData = nil
end


return dumpling