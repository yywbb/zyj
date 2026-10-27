--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/1/12
-- Time: 16:25
-- To change this template use File | Settings | File Templates.
--

function UIIDCardParam(t)
    if gamedata.sdk then
        gamedata.sdk.idCardStatus = tonumber(t.idCardStatus) or gamedata.sdk.idCardStatus
    end

    userAccountCheck(gameWindows.windows["shiming"].show and gameWindows.windows["shiming"].module.callback or nil)
end

function checkIsopen()
    local isopen = gamedata.config.global_kv.Prevent_addiction and tonumber(gamedata.config.global_kv.Prevent_addiction.value) or 0
    return isopen == 1
end


function defaultIdCardStatus( ... )
    gamedata.sdk.idCardStatus = gamedata.sdk.idCardStatus or -1
end

local onlinetime = 0
local onehourtip = false
local twohourtip = false
local exittip = false

local isten = 0
-- local threehuortip = false
local guidetime = 0

function OnlinetimeRequest( ... )
    if not checkIsopen() then return end 
    UIRequest({type = 5340})
end

function UIOnlinetimeQuery( t )
    if not checkIsopen() then return end
    print("在线时间查询")
    printT(t)

    if gamedata.sdk.idCardStatus == -1 then
        gamedata.sdk.idCardStatus = t.status
    end

    local onehourtimes = 3600

    -- if onlinetime==0 then
    --     if t.time>=onehourtimes then
    --         onehourtip = true
    --     end
    -- end

    onlinetime = t.time
    isten = t.isten or 0

    if not gameTimer.times["Onlinetimecheck"] 
    and (gamedata.sdk.idCardStatus==0 or gamedata.sdk.idCardStatus==1) 
    then
        gameTimer:rigistTime("Onlinetimecheck",9999)
        gameTimer:rigistTimeFunc("Onlinetimecheck",function()
            if gameTimer.times["Onlinetimecheck"] <= 0 then
                gameTimer:rigistTime("Onlinetimecheck",9999)
            end
            onlinetime = onlinetime + 1
            print("在线时间",onlinetime)
            if guide.controller.isOnGuide then 
                guidetime = onlinetime
                return 
            end

            local time = gamedata.config.global_kv.cumulative_time and tonumber(gamedata.config.global_kv.cumulative_time.value) or 5400
            if gamedata.holidays and gamedata.holidays == 1 then
                time = gamedata.config.global_kv.cumulative_festival_time and tonumber(gamedata.config.global_kv.cumulative_festival_time.value) or 10800
            end

            local daynum =  math.floor((time ) / (24*3600))
            local hournum = (time % (24*3600)) / 3600
            local minutenum = (time % 3600) / 60
            local day =  daynum - daynum % 1
            local hour = hournum - hournum % 1
            local minute = minutenum - minutenum % 1

            local maxHourStr = gameConfig.strings:dayMinute(day,hour,minute)

            if onlinetime>=math.max(time, guidetime+5) then
                if not twohourtip then
                    gameWindows:openWindow("shiming",{
                            page = "tishi3",
                            des  = "您已累计在线"..maxHourStr.."，根据国家法规您的账号当天已经超出所规定的游玩时间，还请您第二天早上8点后登陆游戏！",
                            time = 5,
                        })
                    -- if gamedata.sdk.idCardStatus == 0 then
                    --     loading:exitGame("您的账号未实名认证，根据国家法规已纳入防沉迷系统，请进行实名认证或5小时后再玩",true)
                    -- elseif gamedata.sdk.idCardStatus == 1 then
                    --     loading:exitGame("您已累计在线3小时，即将强制下线！5小时后可重新登录游戏！",false)
                    -- end
                    twohourtip = true
                end
            -- elseif onlinetime>=1*3600 and onlinetime<1.5*3600 then
            --     if not twohourtip then
            --         if gameWindows.windows["shiming"].show then
            --         else
            --             gameWindows:openWindow("shiming",{
            --                     page = "tishi3",
            --                     des  = "您已累计在线2小时，请注意休息！",
            --                 })

            --             twohourtip = true                         
            --         end
            --     end
            -- elseif onlinetime>=onehourtimes and onlinetime<1.5*onehourtimes then
            --     if not onehourtip then
            --         if gameWindows.windows["shiming"].show then
            --         else
            --             gameWindows:openWindow("shiming",{
            --                     page = "tishi3",
            --                     des  = "您已累计在线1小时，请注意休息！",
            --                 })

            --             onehourtip = true                         
            --         end
            --     end
            elseif isten~=0 then

                if not exittip then
                    gameWindows:openWindow("shiming",{
                            page = "tishi3",
                            des  = "您的账号在此时间段无法游玩，还请您在早上8点后登陆游戏！",
                            time = 5,
                        })
                    exittip = true
                end
            end
        end)
    end

end


local rewardcb = nil
function userAccountCheck( callback )
    print("实名认证状态检查",gamedata.sdk.idCardStatus)

    if LoginScene.status then return end

    if not checkIsopen() then 
        callback()
        return 
    end 

    rewardcb = nil

    if gamedata.sdk.idCardStatus == -1 then
        --无信息
        if callback then callback() end
    elseif gamedata.sdk.idCardStatus == 0 then
        --未实名
        gameWindows:openWindow("shiming",{page = "renzheng"},callback)
    elseif gamedata.sdk.idCardStatus == 1 then
        --已实名未成年
        rewardcb = callback
        local des = "根据您的身份信息已被识别为未成年人，即日起您的游戏时长被限制为1.5小时，每天22点到次日8点期间不得游玩！。"

        if gamedata.holidays and gamedata.holidays == 1 then
            des = "根据您的身份信息已被识别为未成年人，节假日期间您的游戏时长被限制为3小时，每天22点到次日8点期间不得游玩！。"
        end
        gameWindows:openWindow("shiming",{page = "tishi",des = des},function()
            UIRequest({type = 5341})
        end)
    elseif gamedata.sdk.idCardStatus == 2 then
        --已实名已成年
        rewardcb = callback
        UIRequest({type = 5341})
    end

    GameScene:updateRenzheng()
    OnlinetimeRequest()
end

function UIRealnameRewardQuery( t )
    print("实名认证奖励查询")
    printT(t)
    if t.status ==1 then
        gameWindows:openWindow("shiming",{page = "jiangli"},rewardcb)
    else
        if rewardcb then rewardcb() end
    end

end

function UIRealnameReward( t )
    print("实名认证奖励领取")
    printT(t)
    showRewardPopupWindow(t.reward,nil,rewardcb)
    UIRequest({type = 1001})
end

function UIUserKick( t )
    print("玩家被踢5347")
    printT(t)

    if t.status == 1 then
        loading:exitGame("您的账号在异地登录，由于您当前处于防沉迷系统，您将会被强制下线！",true)
    end
end

function UIOnlinetimeUpdate()
    print("深度推广在线计时--")
    local onlineTime = 0
    if  gameTimer.times["OnlinetimeUpdate"] then
        gameTimer:UnrigistTimeFunc("OnlinetimeUpdate")
    end 
    if not gameTimer.times["OnlinetimeUpdate"] and gamedata.gameconfig and gamedata.gameconfig.isshengduTG then
        gameTimer:rigistTime("OnlinetimeUpdate",10*60+50)
        gameTimer:rigistTimeFunc("OnlinetimeUpdate",function()
            print("在线计时时间",onlineTime)
            local mod = math.fmod( onlineTime, 60 )-- 取余数
            if onlineTime>=60 and mod == 0 then
                local line = math.modf( onlineTime / 60 )  -- 取整数
                print("深度推广在线计时 :"..line)
                gamedata.sdk:sdkShengDu("time"..line)
                if  line == 10 then
                    gameTimer:UnrigistTimeFunc("OnlinetimeUpdate")
                end
            end    
            onlineTime = onlineTime + 1
        end)    
    end
end

--防沉迷充值限制
function RechargeLimit(rmb)
    print("idCardStatus",gamedata.sdk.idCardStatus)
    print("RechargeLimit",rmb)
    print("m_cumulative_recharge",GameScene.vipstatus.m_cumulative_recharge)
    print("age",gamedata.age)
	
    if not sdk:isValid() then
        runGamePrompt({msg = gameConfig.strings:string_common("popups","change_qudao")})
        return true
    end
    
    if not gamedata.sdk.idCardStatus then
        return false
    end

    if gameConfig:checkBuildOpen(364) and gamedata.sdk.idCardStatus then 
        if gamedata.sdk.idCardStatus == 0 then
            gameWindows:openWindow("shiming",{page = "renzheng"})
            return true
        end
    end

    local isopen = gamedata.config.global_kv.Prevent_addiction and tonumber(gamedata.config.global_kv.Prevent_addiction.value) or 0
    if isopen ~= 1 then
        return false
    end

    if gamedata.sdk.idCardStatus and gamedata.sdk.idCardStatus == -1 then
        return false
    end

    if gamedata.age and gamedata.age < 8 then
        gameWindows:openWindow("shiming",{page = "tishi5",des = "根据国家相关规定，不可向8岁以下玩家提供付费服务。"})
        return true
    elseif gamedata.age and gamedata.age >= 8 and gamedata.age < 16 then

        local single = gamedata.config.global_kv.single_recharge_8 and tonumber(gamedata.config.global_kv.single_recharge_8.value) or 0

        local cumulative = gamedata.config.global_kv.cumulative_recharge_8 and tonumber(gamedata.config.global_kv.cumulative_recharge_8.value) or 0

        local curCumulative = GameScene.vipstatus.m_cumulative_recharge
        if rmb > single then
            gameWindows:openWindow("shiming",{page = "tishi5",des = string.format("根据国家相关规定，8周岁以上未满16周岁的玩家单次付费不可大于%d元。当月剩余可付费金额：%d元。", single,math.max(0,cumulative - curCumulative))})
            return true
        elseif curCumulative + rmb > cumulative then
            gameWindows:openWindow("shiming",{page = "tishi5",des = string.format("根据国家相关规定，8周岁以上未满16周岁的玩家当月累计付费不可大于%d元。当月剩余可付费金额：%d元。", cumulative,math.max(0,cumulative - curCumulative))})
            return true
        end

    elseif gamedata.age and gamedata.age >= 16 and gamedata.age < 18 then
        local single = gamedata.config.global_kv.single_recharge_16 and tonumber(gamedata.config.global_kv.single_recharge_16.value) or 0

        local cumulative = gamedata.config.global_kv.cumulative_recharge_16 and tonumber(gamedata.config.global_kv.cumulative_recharge_16.value) or 0

        local curCumulative = GameScene.vipstatus.m_cumulative_recharge

        print(single,cumulative,curCumulative)
        if rmb > single then
            gameWindows:openWindow("shiming",{page = "tishi5",des = string.format("根据国家相关规定，16周岁以上未满18周岁的玩家单次付费不可大于%d元。当月剩余可付费金额：%d元。", single,math.max(0,cumulative - curCumulative))})
            return true
        elseif curCumulative + rmb > cumulative then
            gameWindows:openWindow("shiming",{page = "tishi5",des = string.format("根据国家相关规定，16周岁以上未满18周岁的玩家当月累计付费不可大于%d元。当月剩余可付费金额：%d元。", cumulative,math.max(0,cumulative - curCumulative))})
            return true
        end
    end

    return false
end�/  