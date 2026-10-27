--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 14-1-20
-- Time: 下午1:56
-- To change this template use File | Settings | File Templates.
--

local isgotorecharge

local logError = require("logError")

local function usePropByid(id,num,msg)
    runGamePrompt({msg = gameConfig.strings:somethingCanUsed(msg,num,ui.IDconfig(id).name)})
    gameWindows:openWindow("propusebynum",{id = id})
end

local function buyPropertyByid(id,msg)
    if msg then
        runGamePrompt({msg = msg})
    end 
    
    gameWindows:openWindow("buyProperty",{id = id})
end

function shortPropById(id,num,updatetable)

    local seq = 0
    for k,v in pairs(gamedata.config.shop) do
        if v.id == (id or 0) then
            seq = v.seq
        end
    end

    --if seq ~= 0 then
    --    gameWindows:openWindow("buypropById",{cid=id,num=num,seq = seq,updatetable = updatetable},nil)
    --else
        local config = ui.IDconfig(id)
        if config then runGamePrompt({msg = gameConfig.strings:notEnough(config.name) }) end
    --end

end

function shortCoin()

    local cb = function()
        GameScene:shiftLayerById(41)
    end
    gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("confirm",1)},cb)

end

function shortGold()
    if gameConfig.ischargeOpen then
        local cb = function()
            --GameScene:shiftLayer("recharge","up")
            gameWindows:openWindow("recharge",{pagetype = "info"})
        end
        gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("confirm",2)},cb)
    else
        runGamePrompt({msg = gameConfig.strings:string_common("popups","goldbz")})
    end

end


function shortVip()
    if not gameConfig:checkBuildOpen(154) then
        runGamePrompt({msg = gameConfig.strings:string_common("popups","illconditioned")})
        return
    end

    if gameConfig.ischargeOpen then
        local cb = function()
        --GameScene:shiftLayer("recharge","up")
            gameWindows:openWindow("recharge",{pagetype = "info"})
        end
        gameWindows:openWindow("confirm",{msg = gameConfig.strings:string_common("popups","vipInsufficientForRecharge")},cb)
    else
        runGamePrompt({msg = gameConfig.strings:string_common("popups","vipbz")})
    end
end

function shortphysical(props)

--    if props["20014"] and props["20014"].num > 0 then
--        usePropByid(20014,props["20014"].num,"体力不足")
--    elseif props["20019"] and props["20019"].num > 0 then
--        usePropByid(20019,props["20019"].num,"体力不足")
--    else
        -- buyPropertyByid(2,"体力不足")

        
        gameWindows:openWindow("buypower",{props = props,id = 2})



--        local needgold = gamedata.config.buycount_price[tostring(GameScene.vipstatus.b_physical+1)].stamina
--
--        local cb = function()
--            if GameScene.roleinfo.gold < needgold then
--                shortGold()
--            elseif GameScene.vipstatus.b_physical >= gamedata.config.vip[tostring(GameScene.vip.vip)].b_physical then
--                shortVip()
--            else
--                UIRequest({type = 301, cid = 2,gold = needgold})
--            end
--        end
--        gameWindows:openWindow(
--            "confirm",
--            {msg = "体力不足，是否花费"..needgold.."元宝购买30点体力?您是VIP"..GameScene.vip.vip..",当前购买次数("..GameScene.vipstatus.b_physical.."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].b_physical..")"},
--            cb
--        )
--    end

end

function shortenergy(props)
--    if props["20015"] and props["20015"].num > 0 then
--        usePropByid(20015,props["20015"].num,"精力不足")
--    elseif props["20020"] and props["20020"].num > 0 then
--        usePropByid(20020,props["20020"].num,"精力不足")
--    else
        -- buyPropertyByid(3,"精力不足")
        -- printT(props,"props===shortenergy")

        gameWindows:openWindow("buypower",{props = props,id = 3})
--        local needgold = gamedata.config.buycount_price[tostring(GameScene.vipstatus.b_energy+1)].energy
--        local cb = function()
--            if GameScene.roleinfo.gold < needgold then
--                shortGold()
--            elseif GameScene.vipstatus.b_energy >= gamedata.config.vip[tostring(GameScene.vip.vip)].b_energy then
--                shortVip()
--            else
--                UIRequest({type = 301, cid = 3, gold = needgold})
--            end
--        end
--        gameWindows:openWindow(
--            "confirm",
--            {msg = "精力不足，是否花费"..needgold.."元宝购买6点精力?您是VIP"..GameScene.vip.vip..",当前购买次数("..GameScene.vipstatus.b_energy.."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].b_energy..")"},
--            cb
--        )
--    end
end

function shortathletics()
    buyPropertyByid(1,gameConfig.strings:string_common("popups","insufficientNumberOfChallenges"))

--    local needgold = gamedata.config.buycount_price[tostring(GameScene.vipstatus.b_athletics+1)].athletics
--    print("needgold==",needgold)
--    print("gold==",GameScene.roleinfo.gold)
--    print("b_athletics==",GameScene.vipstatus.b_athletics)
--    print("b_athleticsdata==",gamedata.config.vip[tostring(GameScene.vip.vip)].b_athletics)
--    local cb = function()
--        if GameScene.roleinfo.gold < needgold then
--            shortGold()
--        elseif GameScene.vipstatus.b_athletics >= gamedata.config.vip[tostring(GameScene.vip.vip)].b_athletics then
--            shortVip()
--        else
--            print("request")
--            UIRequest({type = 301, cid = 1, gold = needgold})
--        end
--    end
--    gameWindows:openWindow(
--        "confirm",
--        {msg = "挑战次数不足，是否花费"..needgold.."元宝购买3次挑战次数?您是VIP"..GameScene.vip.vip..",当前购买次数("..GameScene.vipstatus.b_athletics.."/"..gamedata.config.vip[tostring(GameScene.vip.vip)].b_athletics..")"},
--        cb
--    )
end

function shortFriendCopykill()
    buyPropertyByid(4,gameConfig.strings:string_common("popups","insufficientNumberOfChallenges"))
end

function shortMieshendianReset()
    buyPropertyByid(5,gameConfig.strings:string_common("popups","resetCountLess"))
end

function singlebossBuyTimes()
    buyPropertyByid(6,nil)
end

function activityCoinBuyTimes()
    buyPropertyByid(7,nil)
end

function activityExpBuyTimes()
    buyPropertyByid(8,nil)
end

function activityForgeStoneBuyTimes()
    buyPropertyByid(9,nil)
end

function activityEquipStarBuyTimes()
    buyPropertyByid(11,nil)
end

function activityZhenfuBuyTimes()
    buyPropertyByid(12,nil)
end

function HomeChallengeBuyTimes()
    buyPropertyByid(13,nil)
end

function GangBossBuyTimes()
    buyPropertyByid(14,nil)
end

function DaoGuanBuyTimes(msg)
    buyPropertyByid(15,msg)
end

function HeroBossBuyTimes()
    buyPropertyByid(16,nil)
end

function activityForgingBuyTimes()
    buyPropertyByid(17,nil)
end

function passkillBuyTimes()
    buyPropertyByid(10,gameConfig.strings:string_common("popups","insufficientNumberOfChallenges"))
end

function activityBlessingCaveBuyTimes()
    buyPropertyByid(18,nil)
end

function minigame2048BuyTimes()
    buyPropertyByid(20,nil)
end
local function UmengData(t)
    if t.datatype == "buy" then
       -- MobClickCpp:buy(t.name,t.amount,t.gold/t.amount)
    elseif t.datatype == "use" then
       -- MobClickCpp:use(t.name,t.amount,t.gold/t.amount)
    elseif t.datatype == "startLevel" then
       -- MobClickCpp:startLevel(t.level)
    elseif t.datatype == "failLevel" then
       -- MobClickCpp:failLevel(t.level)
    elseif t.datatype == "finishLevel" then
       -- MobClickCpp:finishLevel(t.level)
    elseif t.datatype == "setUserLevel" then
       -- MobClickCpp:setUserLevel(t.level)
    end
end


function UIPrompt(t)
    if t.msgtype == "shortgold" then
        shortGold()
    elseif t.msgtype == "shortgoldNoOpenWindow" then
        runGamePrompt({msg = gameConfig.strings:string_common("popups","goldbz")})
    elseif t.msgtype == "shortcoin" then
        shortCoin()
    elseif t.msgtype == "shortphysical" then
        shortphysical(t.param)
    elseif t.msgtype == "shortenergy" then
        shortenergy(t.param)
    elseif t.msgtype == "shortvip" then
        shortVip()
    elseif t.msgtype == "shortprop" then
        shortPropById(t.id,t.num,t.updatetable)
    elseif t.msgtype == "shortFriendKill" then
        shortFriendCopykill()
    elseif t.msgtype == "shortMieshendianReset" then
        shortMieshendianReset()
    elseif t.msgtype == "shortCopyChallenge" then
        runGamePrompt({msg = t.msg})
    elseif t.msgtype == "umeng" then
        UmengData(t)
    elseif t.msgtype == "restartgame" then
        --loading:exitGame(logError.errorMessage[t.msg] or "",true)  --全部国际化完成后打开注释，关掉下一行
        loading:exitGame(t.msg or "",true)
    elseif t.msgtype == "func" then
        runGamePrompt({msg = logError[t.func](logError,t.param)})
    elseif t.msg and t.msg ~= "" and type(t.msg) == "number" then
        runGamePrompt({msg = logError.errorMessage[t.msg] or ""})
    elseif  t.msg and t.msg ~= "" and type(t.msg) == "string" then
        runGamePrompt({msg = t.msg or ""})    
    elseif t.msgtype == "shortg_gold" then
        runGamePrompt({msg = gameConfig.strings:string_common("babelTower", 2)})
    elseif t.msgtype == "godCompetition_power" then
        print("godCompetition_power")
        runGamePrompt({msg = t.msg})
    end
end


function UIconfigUpdate(t)
    printT(t,"配置文件有更新")
    if t.needupdate then
        loading:exitGame(logError.otherMsg[7],true)
    else
       if GameScene.layers["examination"].show then
          GameScene.layers["examination"].module:checkRequestTimeOut()
       end 
    end
end


function UIOffline(t)
    printT(t,"UIOffline")
    loading:exitGame(t.des or logError.otherMsg[8],true)
end


function UIGameloading(t)
    printT(t)
    loading:startGameloading(t.idx)
end

function UINetConectSucess()
    loading:netOpen()
end

--function UIForegroundCallBack()
--    CCDeviceModel:ForegroundCallBack()
--end

-- 超时
function UIPromptTimeOut()
    cclog("UIPromptTimeOut = %s", "连接超时")
    loading:netClosed()

    return 0, nil
end

-- 无信号
function UIPromptNoSignal()
    cclog("UIPromptNoSignal = %s", "无信号")
    loading:netClosed()

    return 0, nil
end

 �)  