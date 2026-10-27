--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/21
-- Time: 下午5:25
-- To change this template use File | Settings | File Templates.
--

--支付的loading时间
local rechage_time = nil 
local retry_time = nil

local tencentOrderId = nil 
local tencentOrderId2 = nil 
function UITencentRecharge(t)
    print("tencent UITencentRecharge上报订单号")
    tencentOrderId = t.orderid
    --UIRequest({type = 10001, orderid = t.orderid})

end

function UITencentRecharge2(t)
    print("tencent UITencentRecharge上报订单号")
    tencentOrderId2 = t.orderid
    --UIRequest({type = 10001, orderid = t.orderid})

end

local hasApplepayData = nil


function UIUserBuy(t)
    print("玩家购买301，接受客户端数据")
    if t.order == 1 then
        UIRequest({type = 1610}) 
    elseif t.order == 4 then
        UIRequest({type = 1323})
    elseif t.order == 5 then
        UIRequest({type = 3620})
    elseif t.order == 6 then
        UIRequest({type = 300 })
        UIRequest({type = 3700})
    elseif t.order == 7 then
        UIRequest({type = 300 })
        UIRequest({type = 1340,temp = "coin"})
    elseif t.order == 8 then
        UIRequest({type = 300 })
        UIRequest({type = 1340,temp = "exp"})
    elseif t.order == 9 then
        UIRequest({type = 300 })
        UIRequest({type = 1340,temp = "stone"})   
    elseif t.order == 10 then
        UIRequest({type = 300 })
        UIRequest({type = 3820})
    elseif t.order == 11 then
        UIRequest({type = 300 })
        UIRequest({type = 1340,temp = "equipstar"})
    elseif t.order == 12 then
        UIRequest({type = 300 })
        UIRequest({type = 1340,temp = "zhenfu"})
    elseif t.order == 13 then
        UIRequest({type = 300 })
        UIRequest({type = 4821,show = 1})
    elseif t.order == 14 then
        UIRequest({type = 300 })
        UIRequest({type = 4840})
    elseif t.order == 15 then
        UIRequest({type = 300 })

        if GameScene.layers["daoGuanMain"].show then
            UIRequest({type = 5301})
        elseif GameScene.layers["daoGuanList"].show then
            GameScene.layers["daoGuanList"].module:refreshData()
        end
    elseif t.order == 16 then
        UIRequest({type = 300 })
        UIRequest({type = 5201})
    elseif t.order == 17 then
        UIRequest({type = 300 })
        UIRequest({type = 1340,temp = "forging"})
    -- elseif t.order == 18 then
    --     UIRequest({type = 300 })
    --     UIRequest({type = 6520})
    elseif t.order == 20 then
        UIRequest({type = 300})
        UIRequest({type = 1600})
    end
    UIRequest({type = 1001})
    UIRequest({type = 300 })
    UIRequest({type = 1032 })
end
local recharge_tmp = nil
local nowtime = 1
local retry = 1
function UIRechargePre(t)
    print("充值准备115，接受客户端数据")
    printT(t)


    if sdk:isValid() then
        local config = gamedata.config.recharge[tostring(t.cid)]
        local serverInfo = gameWindows.windows["roleinfo"].module.SelectedServer  --获取服务器的基本数据
        local rechargeTb = {};
        rechargeTb.rechargeData = t.rechargeData   --后台传的充值数据
        rechargeTb.configData = config  --配置表
        rechargeTb.serverData = serverInfo  --服务器的基本数据
        rechargeTb.level = GameScene.roleinfo.level  --角色等级
        if GameScene.guid then
            rechargeTb.paltformGuid = GameScene.guid --平台id
        end

        local device = require"device"


        if device.platform == "ios" and device.channel == "x7sy" then

            print("t.rechargeData[1].i=====",t.rechargeData["1"].i)
            nowtime = 1;
            rechage_time = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                print("nowtime ======     ", nowtime)
                nowtime = nowtime + 1
                if nowtime == 2 then
                    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
                    rechage_time = nil
                    nowtime = 1
                end
            end, 1, false)
        
        else

            loading:startGameloadingRechage()
            --UIRequest({type = 11501})
            print("t.rechargeData[1].i=====",t.rechargeData["1"].i)
            nowtime = 1;
            rechage_time = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                print("nowtime ======     ", nowtime)
            if(tencentOrderId ~= nil )then
                UIRequest({type = 10001, orderid = tencentOrderId})
                tencentOrderId = nil
            elseif(tencentOrderId2 ~= nil )then
                UIRequest({type = 10003, orderid = tencentOrderId2})
                tencentOrderId2 = nil    
            end    
                nowtime = nowtime + 1
                if nowtime == 60 then
                    runGamePrompt({msg = "充值失败或响应超时，请重新登录"})
                    loading:stopGameloadingRechage()
                    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
                    rechage_time = nil
                    nowtime = 1
                end
                if nowtime%2==0 then
                    UIRequest({type =116,order = t.rechargeData["1"].i})
                end
                if  nowtime%20 == 0 then
                    runGamePrompt({msg = "充值可能存在延迟，请稍等"})
                end 
            end, 1, false)
    
        end

        sdk:Recharge(rechargeTb)
        recharge_tmp = config
       
        if gamedata.device.channel == "qq" or gamedata.device.channel == "weixin" or gamedata.device.channel == "qq1" or gamedata.device.channel == "weixin1" then
            retry = 1
            if retry_time  then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(retry_time)
                retry_time = nil
            end    
    
            retry_time =  CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function() 
                retry = retry +1;
                if retry >= 60 then
                    if retry_time then
                        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(retry_time)
                    end    
                    retry_time = nil
                    retry = 1
                else
                    if retry%2==0 then --每10秒 请求一次
                        if retry<30 then
                            print(" 115======     ",retry)
                            local t = {}
                            sdk:loginSuccess(t)   
                        else   
                            if retry%10==0 then 
                                print(" 115======     ",retry)
                                local t = {}
                                sdk:loginSuccess(t)   
                            end    
                        end
                    end
                end
            end, 1, false)
        end

    else
        runGamePrompt({msg = "未接入第三方渠道"})
    end
end

function UIRechargeSucPre(t)
    printT(t)

    if rechage_time then
        nowtime = 2
        print("nowtime333333333 ======     ", nowtime)
    else
        if nowtime == 1 then
            loading:startGameloadingRechage()
            rechage_time = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                print("nowtime222222 ======     ", nowtime)
                nowtime = nowtime + 1
                if nowtime == 60 then
                    runGamePrompt({msg = "充值失败或响应超时，请重新登录"})
                    loading:stopGameloadingRechage()
                    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
                    rechage_time = nil
                    nowtime = 1
                end
                if nowtime%2==0 then
                    UIRequest({type =116,order = tonumber(t.orderid) })
                end
                if  nowtime%20 == 0 then
                    runGamePrompt({msg = "充值可能存在延迟，请稍等"})
                end 
            end, 1, false)
        end
    end

end

--无充值成功与失败的回调方法
function UIRechargeRsNotFd(t)
    printT(t)

    if rechage_time then
        print("nowtime1 ======     ", nowtime)
        loading:stopGameloadingRechage()
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
        rechage_time = nil
        nowtime = 1
        print("nowtime2 ======     ", nowtime)
    end
    
    if nowtime == 1 then
        loading:startGameloadingRechage()
        rechage_time = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
            print("nowtime3 ======     ", nowtime)
            nowtime = nowtime + 1
            if nowtime == 10 then
                runGamePrompt({msg = "充值取消或响应超时"})
                loading:stopGameloadingRechage()
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
                rechage_time = nil
                nowtime = 1
                -- print("uirecharge--------------")
                -- local s=os.time() - 1
                -- print("s =  ",s)
                -- print("os.time = ",os.time())
                -- while 10 > os.time()-s do
                --     print("uirecharge--------------2222222222")
                --     UIRequest({type =116,order = tonumber(t.orderid) })
                -- end

            end
            if nowtime%2==0 then
                UIRequest({type =116,order = tonumber(t.orderid) })
            end
        end, 1, false)
    end

end


function UIRechargeResult(t)
    print("充值结果116，接受客户端数据")

    printT(t)

    if not GameScene or not GameScene.rootItems then return end

    --是否取消支付
    if t.cancel then 
        if t.cancel == 10 then
            nowtime = 60-t.cancel

        elseif t.cancel == 5 then
            loading:stopGameloadingRechage()
            runGamePrompt({msg = "充值失败"})
            UIRequest({type = 11601})
            if rechage_time then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
                rechage_time = nil
            end

        else
            loading:stopGameloadingRechage()
            UIRequest({type = 11601})
            if rechage_time then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
                rechage_time = nil
            end
        end

        return
        
    end

   

    --取消loading
    loading:stopGameloadingRechage()

    UIRequest({type = 11601})

    if rechage_time then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(rechage_time)
        rechage_time = nil
    end

    -- if MobClickCpp and recharge_tmp then
    --     local gold = 0
    --     for k,v in pairs(t.reward) do
    --         if v.cid == 1001 then
    --             gold = v.num
    --             break
    --         end
    --     end
    --     cclog("umeng pay test rmb:%f gold:%d",recharge_tmp.rmb,gold)
    --     local rmb = recharge_tmp.rmb
    --     if rmb < 1 then
    --         rmb = 1
    --     end
    --     MobClickCpp:pay(rmb, 2, gold)
    -- end
    

    UIRechargefresh()
    if not next(t.reward) then

        return
    end

    showRewardPopupWindow(t.reward)
end

function UIRechargefresh(t)
    print("充值刷新11602，接受客户端数据")

    UIRequest({type = 3765, ids = nil,})
    UIRequest({type = 2090, update = true})
    UIRequest({type = 2092, update = true})
    UIRequest({type = 2097, update = true})
    UIRequest({type = 300, update = true})
    UIRequest({type = 117, update = true})
    UIRequest({type = 2099})

    -- 117 返回后刷新
    --UIRequest({type = 1001})
    --
    --UIRequest({type = 117})
    if GameScene.layers["activity"].module.openPageTable then
        for k,v in pairs(GameScene.layers["activity"].module.openPageTable) do
            if v.id == 22 then
                UIRequest({type = 3682, update = true})
            elseif v.id == 19 then
                UIRequest({type = 3643, update = true})
            elseif v.id == 16 and GameScene.layers["activity"].module.pageTable[16] and GameScene.layers["activity"].module.pageTable[16].module.show then
                UIRequest({type = 2024, update = true})
            elseif v.id == 14 and GameScene.layers["activity"].module.pageTable[14] and GameScene.layers["activity"].module.pageTable[14].module.show then
                UIRequest({type = 2022, update = true})
            elseif v.id == 35 and GameScene.layers["activity"].module.pageTable[35] and GameScene.layers["activity"].module.pageTable[35].module.show then
                UIRequest({type = 3310, update = true})
            elseif v.id == 55 and GameScene.layers["activity"].module.pageTable[55] and GameScene.layers["activity"].module.pageTable[55].module.show then
                UIRequest({type = 3750, update = true})
            elseif v.id == 68 and GameScene.layers["activity"].module.pageTable[68] and GameScene.layers["activity"].module.pageTable[68].module.show then
                UIRequest({type = 4860, update = true})
            elseif v.id == 69 and GameScene.layers["activity"].module.pageTable[69] and GameScene.layers["activity"].module.pageTable[69].module.show then
                UIRequest({type = 4850, update = true})
            elseif v.id == 76 and GameScene.layers["activity"].module.pageTable[76] and GameScene.layers["activity"].module.pageTable[76].module.show then
                UIRequest({type = 4006, update = true})
            elseif v.id == 77 and GameScene.layers["activity"].module.pageTable[77] and GameScene.layers["activity"].module.pageTable[77].module.show then
                UIRequest({type = 5002, update = true})
            elseif v.id == 78 and GameScene.layers["activity"].module.pageTable[78] and GameScene.layers["activity"].module.pageTable[78].module.show then
                UIRequest({type = 5000, update = true})
            elseif v.id == 92 and GameScene.layers["activity"].module.pageTable[92] and GameScene.layers["activity"].module.pageTable[92].module.show then
                UIRequest({type = 5041, update = true})
            elseif v.id == 94 and GameScene.layers["activity"].module.pageTable[94] and GameScene.layers["activity"].module.pageTable[94].module.show then
                UIRequest({type = 5050, update = true})
            elseif v.id == 96 and GameScene.layers["activity"].module.pageTable[96] and GameScene.layers["activity"].module.pageTable[96].module.show then
                UIRequest({type = 5055, update = true})
            elseif v.id == 66 and GameScene.layers["activity"].module.pageTable[66] and GameScene.layers["activity"].module.pageTable[66].module.show then
                UIRequest({type = 4660, update = true})
            elseif v.id == 97 and GameScene.layers["activity"].module.pageTable[97] and GameScene.layers["activity"].module.pageTable[97].module.show then
                UIRequest({type = 5057, update = true})
            elseif v.id == 87 and GameScene.layers["activity"].module.pageTable[87] and GameScene.layers["activity"].module.pageTable[87].module.show then
                UIRequest({type = 5034, update = true})
            elseif v.id == 108 and GameScene.layers["activity"].module.pageTable[108] and GameScene.layers["activity"].module.pageTable[108].module.show then
                UIRequest({type = 5701, update = true})
            elseif v.id == 113 then
                UIRequest({type = 3686, update = true})
            elseif v.id == 118 then
                UIRequest({type = 5533, update = true})
            elseif v.id == 116 and GameScene.layers["activity"].module.pageTable[116] and GameScene.layers["activity"].module.pageTable[116].module.show then
                UIRequest({type = 5525, update = true})
            elseif v.id == 130 and GameScene.layers["activity"].module.pageTable[130] and GameScene.layers["activity"].module.pageTable[130].module.show then
                UIRequest({type = 3755, update = true})
            elseif v.id == 131 and GameScene.layers["activity"].module.pageTable[131] and GameScene.layers["activity"].module.pageTable[131].module.show then
                UIRequest({type = 5060, update = true})
            elseif v.id == 141 and GameScene.layers["activity"].module.pageTable[141] and GameScene.layers["activity"].module.pageTable[141].module.show then
                UIRequest({type = 3758, update = true})
            elseif v.id == 148 and GameScene.layers["activity"].module.pageTable[148] and GameScene.layers["activity"].module.pageTable[148].module.show then
                UIRequest({type = 5081, update = true})
            elseif v.id == 149 and GameScene.layers["activity"].module.pageTable[149] and GameScene.layers["activity"].module.pageTable[149].module.show then
                UIRequest({type = 7091, update = true})
                UIRequest({type = 7094})
            elseif v.id == 150 and GameScene.layers["activity"].module.pageTable[150] and GameScene.layers["activity"].module.pageTable[150].module.show then
                UIRequest({type = 8020, update = true})
            elseif v.id == 151 and GameScene.layers["activity"].module.pageTable[151] and GameScene.layers["activity"].module.pageTable[151].module.show then
                UIRequest({type = 8022, update = true})
            elseif v.id == 152 and GameScene.layers["activity"].module.pageTable[152] and GameScene.layers["activity"].module.pageTable[152].module.show then
                UIRequest({type = 8024, update = true})
            elseif v.id == 153 and GameScene.layers["activity"].module.pageTable[153] and GameScene.layers["activity"].module.pageTable[153].module.show then
                UIRequest({type = 8026, update = true})
            elseif v.id == 154 and GameScene.layers["activity"].module.pageTable[154] and GameScene.layers["activity"].module.pageTable[154].module.show then
                UIRequest({type = 8028, update = true})
            elseif v.id == 155 and GameScene.layers["activity"].module.pageTable[155] and GameScene.layers["activity"].module.pageTable[155].module.show then
                UIRequest({type = 8032, update = true})
            elseif v.id == 165 and GameScene.layers["activity"].module.pageTable[165] and GameScene.layers["activity"].module.pageTable[165].module.show then
                UIRequest({type = 8045, update = true})
            elseif v.id == 167 and GameScene.layers["activity"].module.pageTable[167] and GameScene.layers["activity"].module.pageTable[167].module.show then
                UIRequest({type = 8071})
            elseif v.id == 168 and GameScene.layers["activity"].module.pageTable[168] and GameScene.layers["activity"].module.pageTable[168].module.show then
                UIRequest({type = 8073})
            elseif v.id == 169 and GameScene.layers["activity"].module.pageTable[169] and GameScene.layers["activity"].module.pageTable[169].module.show then
                UIRequest({type = 8075})
            elseif v.id == 170 and GameScene.layers["activity"].module.pageTable[170] and GameScene.layers["activity"].module.pageTable[170].module.show then
                UIRequest({type = 8077})
            elseif v.id == 171 and GameScene.layers["activity"].module.pageTable[171] and GameScene.layers["activity"].module.pageTable[171].module.show then
                UIRequest({type = 8079})
            elseif v.id == 172 and GameScene.layers["activity"].module.pageTable[172] and GameScene.layers["activity"].module.pageTable[172].module.show then
                UIRequest({type = 8081})
            elseif v.id == 175 and GameScene.layers["activity"].module.pageTable[175] and GameScene.layers["activity"].module.pageTable[175].module.show then
                UIRequest({type = 8113})
            elseif v.id == 176 and GameScene.layers["activity"].module.pageTable[176] and GameScene.layers["activity"].module.pageTable[176].module.show then
                UIRequest({type = 8115})
            elseif v.id == 177 and GameScene.layers["activity"].module.pageTable[177] and GameScene.layers["activity"].module.pageTable[177].module.show then
                UIRequest({type = 8117})
            elseif v.id == 178 and GameScene.layers["activity"].module.pageTable[178] and GameScene.layers["activity"].module.pageTable[178].module.show then
                UIRequest({type = 8120})
            elseif v.id == 179 and GameScene.layers["activity"].module.pageTable[179] and GameScene.layers["activity"].module.pageTable[179].module.show then
                UIRequest({type = 8122})
            elseif v.id == 180 and GameScene.layers["activity"].module.pageTable[180] and GameScene.layers["activity"].module.pageTable[180].module.show then
                UIRequest({type = 8130})
            elseif v.id == 193 and GameScene.layers["activity"].module.pageTable[193] and GameScene.layers["activity"].module.pageTable[193].module.show then
                UIRequest({type = 3688})
            elseif v.id == 207 and GameScene.layers["activity"].module.pageTable[207] and GameScene.layers["activity"].module.pageTable[207].module.show then
                UIRequest({type = 8856})
            end
        end
    end

    UIRequest({type = 999902})
end

function UIVip(t)
    print("VIP信息117，接受客户端数据")
    printT(t)
    if t.isup and t.isup == 1 then
        if GameScene.rootItems and gameConfig:checkBuildOpen(154) then
            gameWindows:openWindow("vipUpgrade", {vip = t.vip.vip}, nil)
        else
            GameScene.vipup = t.vip
        end
    else
        if GameScene.vip and GameScene.rootItems and gameConfig:checkBuildOpen(154) then
            if t.vip.vip > GameScene.vip.vip then
                print("弹出Vip窗口")
                gameWindows:openWindow("vipUpgrade", {vip = t.vip.vip}, nil)
            end
        end
    end

    if gameWindows.windows["recharge"].show then
        gameWindows.windows["recharge"].module:reloaddata(t.vip)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloaddata(t.vip)
    end
    GameScene.vip= t.vip

    if not GameScene.openactivityinpost and GameScene.vip.firststatus == 2 then
        print("openactivityinpost.not===")
        GameScene.openactivityinpost = {}
        GameScene.openactivityinpost[tostring(162)] = 0
    elseif GameScene.openactivityinpost and GameScene.vip.firststatus == 2 then
        print("openactivityinpost.has===")
        GameScene.openactivityinpost[tostring(162)] = 0
    end

    UIRequest({type = 1001})
    UIRequest({type = 46111})

    --
    if GameScene.layers["zhongqiuactivity"] and GameScene.layers["zhongqiuactivity"].show then
        GameScene.layers["zhongqiuactivity"].module:request()
    end
    --
end

function UIVipStatus(t)
    print("VIP状态300，接受客户端数据")
    -- printT(t)
    GameScene.vipstatus= t.vipstatus
    
    if gameWindows.windows["buypower"].show then
        gameWindows.windows["buypower"].module:reloadShowData()
    end

    UIRequest({type = 46111})
end

function UIMonthCard(t)
    print("月卡查询2090，接受客户端数据")
    --printT(t)

    gameWindows.windows["recharge"].module.monthcard = t.monthcard

    if GameScene.layers["activity"].module.pageTable[5] and GameScene.layers["activity"].module.pageTable[5].module.show then
        GameScene.layers["activity"].module.pageTable[5].module:reloaddata(t.monthcard)
    end
    
    if GameScene.layers["activity"].module.openPageTable then
        for k,v in pairs(GameScene.layers["activity"].module.openPageTable) do
            if v.id == 101 then
                UIRequest({type = 3680, update = true})           
            elseif v.id == 112 then
                UIRequest({type = 3684, update = true})           
            elseif v.id == 117 then
                UIRequest({type = 5531, update = true})
            end
        end
    end    

end

function UIMonthCardGet(t)
    print("月卡领2091，接受客户端数据")
    --printT(t)


    if GameScene.layers["activity"].module.pageTable[5] and GameScene.layers["activity"].module.pageTable[5].module.show then
        GameScene.layers["activity"].module.pageTable[5].module:reloaddata(t.monthcard)
    end
    showRewardPopupWindow(t.reward)
    UIRequest({type = 1001})
end

function UIMonthCardReward(t)
    print("月卡奖励2092，接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[8] and GameScene.layers["activity"].module.pageTable[8].module.show then
        GameScene.layers["activity"].module.pageTable[8].module:reloaddata(t.monthcardreward)
    end

end

function UIMonthCardRewardGet(t)
    print("月卡奖励领取2093，接受客户端数据")
    --printT(t)


    if GameScene.layers["activity"].module.pageTable[8] and GameScene.layers["activity"].module.pageTable[8].module.show then
        GameScene.layers["activity"].module.pageTable[8].module:reloaddata(t.monthcardreward)
    end
    showRewardPopupWindow(t.reward)
    UIRequest({type = 1001})
end

function UIGrowPlan(t)
    print("成长计划2094，接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[7] and GameScene.layers["activity"].module.pageTable[7].module.show then
        GameScene.layers["activity"].module.pageTable[7].module:reloaddata(t.growplan)
    end
end

function UIGrowPlanBuy(t)
    print("成长计划2095，接受客户端数据")
    --printT(t)
    if t.Result and t.Result == 1 then
        runGamePrompt({msg = "购买成功"})
    end
    UIRequest({type = 2094,update = true})
    UIRequest({type = 4000}) -- 刷新全民福利人数以及达到某人数物品的领取状态
    UIRequest({type = 1001})
end

function UIGrowPlanReward(t)
    print("成长计划2096，接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[7] and GameScene.layers["activity"].module.pageTable[7].module.show then
        GameScene.layers["activity"].module.pageTable[7].module:reloaddata(t.growplan)
    end
    showRewardPopupWindow(t.reward)
    UIRequest({type = 1001})
end

function UIGrowPlanGlobal(t)
    print("成长计划4000，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[7] and GameScene.layers["activity"].module.pageTable[7].module.show then
        GameScene.layers["activity"].module.pageTable[7].module:reloadGeneralData(t.growplanGlobal)
    end
end

function UIGrowPlanGlobalReward(t)
    print("成长计划4001，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[7] and GameScene.layers["activity"].module.pageTable[7].module.show then
        GameScene.layers["activity"].module.pageTable[7].module:reloadGeneralData(t.growplanGlobal)
    end
    showRewardPopupWindow(t.reward)
    UIRequest({type = 1001})
end

function UIGrowPlan2(t)
    print("成长计划7091，接受客户端数据")
    --printT(t)

    if GameScene.layers["activity"].module.pageTable[149] and GameScene.layers["activity"].module.pageTable[149].module.show then
        GameScene.layers["activity"].module.pageTable[149].module:reloaddata(t.growplan)
    end
end

function UIGrowPlan2Buy(t)
    print("成长计划7092，接受客户端数据")
    --printT(t)
    if t.Result and t.Result == 1 then
        runGamePrompt({msg = "购买成功"})
    end
    UIRequest({type = 7091,update = true})
    UIRequest({type = 7094}) -- 刷新全民福利人数以及达到某人数物品的领取状态
    UIRequest({type = 1001})
end

function UIGrowPlan2Reward(t)
    print("成长计划7093，接受客户端数据")
    printT(t)

    local isallreward = true
    if t.growplan and t.growplan.rewards and next(t.growplan.rewards) then
        for k,v in pairs(t.growplan.rewards) do
            if v.status ~= 2 then
                isallreward = false
                break
            end
        end

        if isallreward then
            UIRequest({type = 7091,update = true})
        end
    end

    if GameScene.layers["activity"].module.pageTable[149] and GameScene.layers["activity"].module.pageTable[149].module.show then
        GameScene.layers["activity"].module.pageTable[149].module:reloaddata(t.growplan)
    end
    showRewardPopupWindow(t.reward,nil,function (  )
        if isallreward then
            local maxStage = table.getTableLength(gamedata.config.growplan_x1)
            if t.growplan and t.growplan.stage and t.growplan.stage < maxStage then
                gameWindows:openWindow("chengzhangjihuaUp", {stage = t.growplan.stage + 1,activityid = 149}, nil)
            end
        end
    end)
    UIRequest({type = 1001})
end


function UIGrowPlan4(t)
    print("成长计划8120，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[178] and GameScene.layers["activity"].module.pageTable[178].module.show then
        GameScene.layers["activity"].module.pageTable[178].module:reloaddata(t.growplan)
    end
end

function UIGrowPlan4Reward(t)
    print("成长计划8121，接受客户端数据")
    printT(t)

    local isallreward = true
    if t.growplan and t.growplan.rewards and next(t.growplan.rewards) then
        for k,v in pairs(t.growplan.rewards) do
            if v.status ~= 2 then
                isallreward = false
                break
            end
        end

        if isallreward then
            UIRequest({type = 8120,update = true})
        end
    end

    if GameScene.layers["activity"].module.pageTable[178] and GameScene.layers["activity"].module.pageTable[178].module.show then
        GameScene.layers["activity"].module.pageTable[178].module:reloaddata(t.growplan)
    end
    showRewardPopupWindow(t.reward,nil,function (  )
        if isallreward then
            local maxStage = table.getTableLength(gamedata.config.growplan_x2)
            if t.growplan and t.growplan.stage and t.growplan.stage < maxStage then
                gameWindows:openWindow("chengzhangjihuaUp", {stage = t.growplan.stage + 1,activityid = 178}, nil)
            end
        end
    end)
    UIRequest({type = 1001})
end

function UIGrowPlan5(t)
    print("成长计划8122，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[179] and GameScene.layers["activity"].module.pageTable[179].module.show then
        GameScene.layers["activity"].module.pageTable[179].module:reloaddata(t.growplan)
    end
end

function UIGrowPlan5Reward(t)
    print("成长计划8123，接受客户端数据")
    printT(t)

    local isallreward = true
    if t.growplan and t.growplan.rewards and next(t.growplan.rewards) then
        for k,v in pairs(t.growplan.rewards) do
            if v.status ~= 2 then
                isallreward = false
                break
            end
        end

        if isallreward then
            UIRequest({type = 8122,update = true})
        end
    end

    if GameScene.layers["activity"].module.pageTable[179] and GameScene.layers["activity"].module.pageTable[179].module.show then
        GameScene.layers["activity"].module.pageTable[179].module:reloaddata(t.growplan)
    end
    showRewardPopupWindow(t.reward,nil,function (  )
        if isallreward then
            local maxStage = table.getTableLength(gamedata.config.growplan_x3)
            if t.growplan and t.growplan.stage and t.growplan.stage < maxStage then
                gameWindows:openWindow("chengzhangjihuaUp", {stage = t.growplan.stage + 1,activityid = 179}, nil)
            end
        end
    end)
    UIRequest({type = 1001})
end

function UIGrowPlan2Global(t)
    print("成长计划7094，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[149] and GameScene.layers["activity"].module.pageTable[149].module.show then
        GameScene.layers["activity"].module.pageTable[149].module:reloadGeneralData(t.growplanGlobal)
    end
end

function UIGrowPlan2GlobalReward(t)
    print("成长计划7095，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[149] and GameScene.layers["activity"].module.pageTable[149].module.show then
        GameScene.layers["activity"].module.pageTable[149].module:reloadGeneralData(t.growplanGlobal)
    end
    showRewardPopupWindow(t.reward)
    UIRequest({type = 1001})
end

function UIRechargeDouble(t)
    print("充值双倍2097，接受客户端数据")
    --printT(t)
    if GameScene.layers["activity"].module.pageTable[6] and GameScene.layers["activity"].module.pageTable[6].module.show then
        GameScene.layers["activity"].module.pageTable[6].module:reloaddata(t.rechargedouble)
    end
end

function UIFirstRechargeReward(t)
    print("充值双倍2098，接受客户端数据")

    if not GameScene.openactivityinpost then
        print("openactivityinpost.not===2098")
        GameScene.openactivityinpost = {}
        GameScene.openactivityinpost[tostring(162)] = 0
    elseif GameScene.openactivityinpost then
        print("openactivityinpost.has===2098")
        GameScene.openactivityinpost[tostring(162)] = 0
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloaddata(t.vip)
    end
    showRewardPopupWindow(t.reward)
    UIRequest({type = 1001})
end


function UIFirstRechargeStatus(t)
    print("2099，接受客户端数据")

    

    if GameScene.rechargeStatus then

        local nowRechargeStatus = true
        local oldRechargeStatus = true

        for i=3,8 do
            if t.status[tostring(i)] ~= 0 then
                nowRechargeStatus = false
            end

            if GameScene.rechargeStatus[tostring(i)] ~= 0 then
                oldRechargeStatus = false
            end
        end

        for i=13,18 do
            if t.status[tostring(i)] ~= 0 then
                nowRechargeStatus = false
            end

            if GameScene.rechargeStatus[tostring(i)] ~= 0 then
                oldRechargeStatus = false
            end
        end

        if not oldRechargeStatus and nowRechargeStatus then
            print("充值状态重置")
            runGamePrompt({msg = "多倍充值状态已重置，魔王大人可继续享受多倍充值！"})
        end

    end

    GameScene.rechargeStatus = t.status
    if gameWindows.windows["recharge"].show then
        gameWindows.windows["recharge"].module:reloadstatus(t.status)
    end

end


--
function UIRechargeDouble2(t)
    print("4006，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[76] and GameScene.layers["activity"].module.pageTable[76].module.show then
        GameScene.layers["activity"].module.pageTable[76].module:reloaddata(t.rechargedouble)
    end
end


--
function UICPRechargeDouble(t)
    print("5034，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[87] and GameScene.layers["activity"].module.pageTable[87].module.show then
        GameScene.layers["activity"].module.pageTable[87].module:reloaddata(t)
    end
end

function ForeverRechargeQuery(t)
    print("5319，接受客户端数据")
    printT(t)

    if gameWindows.windows["accRecharge"].show then
        gameWindows.windows["accRecharge"].module:reload(t.data)
    end

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:reloadforeverddata(t.data)
    end
    --UIRequest({type = 1001})
end

function ForeverRechargeReward(t)
    print("5320，接受客户端数据")

    showRewardPopupWindow(t.reward)
    UIRequest({type = 5319})

end


function UIWeekFundQueryX1(t)
    printT(t,"8071，接受客户端数据")

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[167] and GameScene.layers["activity"].module.pageTable[167].module and GameScene.layers["activity"].module.pageTable[167].module.show then
        GameScene.layers["activity"].module.pageTable[167].module:reloaddata(t.weekFundData)
    end

end

function UIWeekFundAwardX1(t)
    printT(t,"8072，接受客户端数据")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[167] and GameScene.layers["activity"].module.pageTable[167].module and GameScene.layers["activity"].module.pageTable[167].module.show then
        UIRequest({type = 8071})
    end
    
end

function UIWeekFundQueryX2(t)
    printT(t,"8073，接受客户端数据")

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[168] and GameScene.layers["activity"].module.pageTable[168].module and GameScene.layers["activity"].module.pageTable[168].module.show then
        GameScene.layers["activity"].module.pageTable[168].module:reloaddata(t.weekFundData)
    end

end

function UIWeekFundAwardX2(t)
    printT(t,"8074，接受客户端数据")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[168] and GameScene.layers["activity"].module.pageTable[168].module and GameScene.layers["activity"].module.pageTable[168].module.show then
        UIRequest({type = 8073})
    end
    
end

function UICPWeekFundQueryX1(t)
    printT(t,"8075，接受客户端数据")

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[169] and GameScene.layers["activity"].module.pageTable[169].module and GameScene.layers["activity"].module.pageTable[169].module.show then
        GameScene.layers["activity"].module.pageTable[169].module:reloaddata(t.weekFundData)
    end
end

function UICPWeekFundAwardX1(t)
    printT(t,"8076，接受客户端数据")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[169] and GameScene.layers["activity"].module.pageTable[169].module and GameScene.layers["activity"].module.pageTable[169].module.show then
        UIRequest({type = 8075})
    end
    
end

function UICPWeekFundQueryX2(t)
    printT(t,"8077，接受客户端数据")

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[170] and GameScene.layers["activity"].module.pageTable[170].module and GameScene.layers["activity"].module.pageTable[170].module.show then
        GameScene.layers["activity"].module.pageTable[170].module:reloaddata(t.weekFundData)
    end
end

function UICPWeekFundAwardX2(t)
    printT(t,"8078，接受客户端数据")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[170] and GameScene.layers["activity"].module.pageTable[170].module and GameScene.layers["activity"].module.pageTable[170].module.show then
        UIRequest({type = 8077})
    end
 
end

function UIRCWeekFundQueryX1(t)
    printT(t,"8079，接受客户端数据")

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[171] and GameScene.layers["activity"].module.pageTable[171].module and GameScene.layers["activity"].module.pageTable[171].module.show then
        GameScene.layers["activity"].module.pageTable[171].module:reloaddata(t.weekFundData)
    end
end

function UIRCWeekFundAwardX1(t)
    printT(t,"8080，接受客户端数据")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[171] and GameScene.layers["activity"].module.pageTable[171].module and GameScene.layers["activity"].module.pageTable[171].module.show then
        UIRequest({type = 8079})
    end

end

function UIRCWeekFundQueryX2(t)
    printT(t,"8081，接受客户端数据")

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[172] and GameScene.layers["activity"].module.pageTable[172].module and GameScene.layers["activity"].module.pageTable[172].module.show then
        GameScene.layers["activity"].module.pageTable[172].module:reloaddata(t.weekFundData)
    end
end

function UIRCWeekFundAwardX2(t)
    printT(t,"8082，接受客户端数据")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[172] and GameScene.layers["activity"].module.pageTable[172].module and GameScene.layers["activity"].module.pageTable[172].module.show then
        UIRequest({type = 8081})
    end
   
end
��  