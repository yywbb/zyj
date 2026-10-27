--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/11/26
-- Time: 下午6:47
-- To change this template use File | Settings | File Templates.
--

local peace = {

    buttontouch = -103,

    drinkConfig = {
        [0] = gameConfig.strings:string_common("activity_peace",0),
        [1] = gameConfig.strings:string_common("activity_peace",1),
        [2] = gameConfig.strings:string_common("activity_peace",2),
        [3] = gameConfig.strings:string_common("activity_peace",3)
    },
    requestTime = {12,14,18,20,21,24},--在对应时间内 请求蟠桃状态，来刷新界面显示
}

function peace.init(self,size)
    self.contentsize = size
    self.show = true

    self.coverccb, self.coveritems = CCBReaderLoad("activitypeace/peace",nil, true, "peace")

    local Gneral = CCSkeletonAnimation:create("qitiandasheng/qitiandasheng.json","qitiandasheng/qitiandasheng.atlas",2.8)
    Gneral:setAnimation("celebrate",true,0)
    self.coveritems.generalnode:addChild(Gneral)
    printT(gamedata.config.global_kv)

    local isdouble = ui.CheckHuodongByParam(5)

    self.eatGoldNum =  gamedata.config.global_kv.eat_peaches.value --吃桃送元宝
    ui.setLabelString(self.coveritems.text1,gameConfig.strings:string_common("activity_peace",7)..self.eatGoldNum..gameConfig.strings:string_common("activity_peace",8)..(isdouble and " ("..gameConfig.strings:string_common("ui",13)..")" or ""),21)
    self.coveritems.topnode:setPositionY(self.contentsize.y)
    self.coveritems.midnode:setPositionY((self.contentsize.y-gameConfig.maiscenebottomheight)/2+gameConfig.maiscenebottomheight)
    self:updatetime()
    return self.coverccb
end

function peace.reloaddata(self,data)
    if not self.show then return end
    local oldstatus = nil
    local hasWine = false
    for i=1,3 do
        if data.status[tostring(i)] == 0 then
            hasWine = true
            self.oldhas = true
        end
        if data.status[tostring(i)] == 1 or data.status[tostring(i)]== 3 then
            self.coveritems["status"..i]:setFntFile("font/fangzheng_lan.fnt");
        end

        -- if data.status[tostring(i)]==1 then
        --     if not oldstatus then
        --         oldstatus =  data.status[tostring(i-1)] or 3
        --     end
        -- end
        --print("data----------------",data.status[tostring(i-1)])
        self.coveritems["status"..i]:setString(gameConfig.strings:string_common("activity_peace",data.status[tostring(i)]))
        self.coveritems["status"..i]:setVisible(true) -- 增加时辰未到初始隐藏
    end
    self.coveritems.peace1:setVisible(hasWine)
    self.coveritems.peace2:setVisible(hasWine)
    if data.nowstatus and data.nowstatus == 0 then
        self.coveritems.statusdes:setString(gameConfig.strings:string_common("activity_peace",4))
    elseif data.nowstatus and data.nowstatus == 2 then
        self.coveritems.statusdes:setString(gameConfig.strings:string_common("activity_peace",6))
    else
        self.coveritems.statusdes:setString(gameConfig.strings:string_common("activity_peace",5))
    end
    --self.coveritems.statusdes:setString(gameConfig.strings:string_common("activity_peace",hasWine and 4 or 5))

    self.coveritems.hunode:removeAllChildrenWithCleanup(true)

    if data.isEatPeaceAni and data.isEatPeaceAni  == 1   then
        local ccb,  item = CCBReaderLoad("UIEffect/chitao/chitao",nil, true, "chitao")
        self.coveritems.hunode:addChild(ccb)
        local animationManager = getAnimationManager(item)
        animationManager:setAnimationCompletedCallback(function()

        end)
        animationManager:runAnimationsForSequenceNamed(self.oldhas and "eat" or "aftereat")
        if data.isEatPeaceAni == 1 then --只有吃桃请求才有吃桃动画
            local ccb1,  item1 = CCBReaderLoad("UIEffect/peace/addpeace",nil, true, "addpeace")
            self.coveritems.hunode:addChild(ccb1)
            -- item1.eatGoldLable:setString("+"..self.eatGoldNum)
            local animationManager1 = getAnimationManager(item1)
            animationManager1:setAnimationCompletedCallback(function()
                ccb1:removeFromParentAndCleanup(true)
            end)
            animationManager1:runAnimationsForSequenceNamed("addpeace")    
        end    
    end



    self.coveritems.eatButton:setTouchPriority(self.buttontouch)
    self.coveritems.eatButton:addHandleOfControlEvent(function ()
        if GameScene.layers["activity"].module.isContentScroll then  return end
        if hasWine then
            gameTouch:clickprofbytime(0.3)
            UIRequest({type = 2011,gold = self.eatGoldNum})
            gamedata.music:PlayOptSound("ct")
        else
            --runGamePrompt({msg = "现在没酒喝啊，主公！"})
        end
    end, CCControlEventTouchUpInside)
end

function peace.clear(self)
    self.show = false
    gameTimer:UnrigistTimeFunc("peace")
    self.oldstatus = false
    self.coverccb = nil
    self.coveritems = nil
end

-- function peace.setPage(self)
--     -- UIRequest({type = 2000,page = GameScene.layers["activity"].module.type})
--     UIRequest({type = 2010}) 
-- end

-- function peace.UIUpdateData(self, isreset)
--     if isreset then
        
--         self:setPage()
--     end
-- end
function peace.updatetime(self)

    local nowtime = os.date("*t", gamedata:time())
    local addtime = 0
    for i,v in ipairs(self.requestTime) do
        print(i,v)
        if nowtime.hour < v then
            addtime = v
            break
        end
    end
    local remaintime = addtime*3600 + 1 -nowtime.hour*3600-nowtime.min*60-nowtime.sec --延迟一秒
    gameTimer:rigistTime("peace", remaintime)
    gameTimer:rigistTimeFunc("peace",function()

        if gameTimer.times["peace"] == 0 then
            UIRequest({type=2010})
            gameTimer:UnrigistTimeFunc("peace")
        end
    end)
end
return peace