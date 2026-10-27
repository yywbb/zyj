--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-5-2
-- Time: 上午11:04
-- To change this template use File | Settings | File Templates.

require"UIRequest"


--local accserver = {host = "182.92.161.59", port = 8000} --开发测试服务器
--local accserver = {host = "47.94.56.53", port = 10011}--兼容测试
--local accserver = {host = "182.92.240.247", port = 20011} --热血测试服务器
--local accserver = {host = "182.92.240.247", port = 10001} --开发测试迭代服
--local accserver = {host = "acc-ios.zyj.16801.com", port = 10011} --ios官方
--local accserver = {host = "106.75.4.212", port = 10011} --神仙也疯狂（ios官方）
--local accserver = {host = "182.92.240.247", port = 20001}   --版本包
--local accserver = {host = "123.59.145.15", port = 10011}    --混服sever_2
--local accserver = {host = "115.159.106.82", port = 10011} --应用宝
--local accserver = {host = "123.59.89.135", port = 10011} --IOS越狱正式服
--local accserver = {host = "182.92.240.247", port = 30001} --IOS测试热更
--local accserver = {host = "182.92.240.247", port = 40001} --Android测试热更
--local accserver = {host = "106.75.3.2", port = 11011} --Android新热更服务器
--local accserver = {host = "106.75.3.2", port = 11016} --IOS新热更服务器
--local accserver = {host = "106.75.3.2", port = 11021} --ios越狱测试热更独立
--local accserver = {host = "59.110.51.125", port = 10011} --要播服务器
--local accserver = {host = "106.14.68.162", port = 10011} --android变态玩服务器
--local accserver = {host = "www.52muyou.com", port = 10011} --ios安趣评审服
--local accserver = {host = "acc.zyjiosly.52muyou.com", port = 10011} --ios安趣正式服
--local accserver = {host = "139.129.235.184", port = 10011} --7k7k正式服
--local accserver = {host = "221.5.35.186", port = 10011} --极品
--local accserver = {host = "acc.zyjiosly.52muyou.com", port = 20011} --汉风
--local accserver = {host = "zyja.jxwl9.com", port = 10011} --景讯
--local accserver = {host = "acc.zyjiosly.52muyou.com", port = 30011} --9377
--local accserver = {host = "acc.zyjiosly.52muyou.com", port = 40011} --潮游戏
--local accserver = {host = "acc.zyjiosly.52muyou.com", port = 50011} --安峰独服
--local accserver = {host = "acc.zyjiosly.52muyou.com", port = 51011} --触动、万米混
--local accserver = {host = "acc.zyjiosly.52muyou.com", port = 35011} --鲸旗
--local accserver = {host = "120.132.30.34", port = 10011} --火柚
--local accserver = {host = "120.92.154.224", port = 10011} --爱上游戏
--local accserver = {host = "47.92.5.15", port = 10011} --圣泰
--local accserver = {host = "106.75.17.163", port = 10011} --摩天轮    
--local accserver = {host = "47.95.28.75", port = 10011} --国服测试 
--local accserver = {host = "47.95.33.171 ", port = 10011} --独服测试 
--local accserver = {host = "101.37.15.132", port = 10011} --奇葩互娱
--local accserver = {host = "221.5.35.186", port = 10011} --极品服务器
--local accserver = {host = "101.37.15.132", port = 10011} --奇葩互娱
--local accserver = {host = "47.93.76.48", port = 18011} --麒麟游
--local accserver = {host = "39.107.53.76", port = 10011}  --新越狱ios

local accserver = gamedata.sdk.address.gameAddress 

if pcall(function()
    local localConfig = require("local_config")
    if nil ~= localConfig and "table" == type(localConfig) then
        accserver = table.merge(accserver, localConfig)
    end
end) then
    cclog("Using local server config.")
else
    cclog("Using default server config.")
end

require("gameloop")



function Step1SyncResourceEx(fd)
    cclog("Step1SyncResourceEx");
    require("syncresource2")
    return Step1SyncResource(fd)
end

function Step2SyncConfigEx(fd)
    cclog("Step2SyncConfigEx");
    require("syncconfig")
    return Step2SyncConfig(fd)
end


-- 客户端向服务器发送请求
function Step3AsynLoopEx()
    cclog("Step3AsynLoopEx");
    --UIRequest_({ type = 998 })
    require("GameUserRequest")
    require("GameSltServerRult")
    require("GameLoginandRegister")
    require"config"
    require"GameDownloadProxy"
    require"syncconfig2"
    require"commongameloopfunc"
    require"GameErrorMessage"
    require"GameRecharge"
    local SDK = require"SDKfunction"

    local acc_ui_callback = {
        [1] = UIReloginInAcc,
        [2] = UISyncConfigCallBack,
        [998]    = AndroidNetLoad,
        [997]    = UI997,
        [996]    = UI996,
        [3] = UIUserRequestCallback,
        [5] = UIGameSelectServerCallback,
        [10] = UINetUserRegisterAndCallback,
        [11] = UINetUserLoginAndCallback,
        [12] = UINetChangePassCallback,
        [999] = UINetQuitLoop,
        [20] = UIDownloadProxyCallback,
        [90] = SDK.AndroidSessionValid2,
        [900001] = SDK.AndroidSessionValid2,
        [900000] = SDK.appleUserSessionValid,

        [95] = SDK.NetSyncChannel,
        [999988] = LuaExceptionReportCallBack,
        [20000] = UIAppStorePay,
        [999906] = UIdeviceinfoCallBack,

        [777777] = UInetLuaReloadCallBack,

        [6666666] = NetunzipFileCallBack,

    }
    -- 客户端接受服务器传来的数据
    local acc_net_callback = {
        [2] = NetSyncConfigCallBack,
        [3] = NetUserResponseCallback,
        [5] = NetGameSltServerRultCallback,
        [10] = NetUserRegisterAndCallback,
        [11] = NetUserLoginAndCallback,
        [12] = NetChangePassCallback,
        [93] = NetUserResponseCallback,
        [99] = NetChannelLoginResponseCallback,
        [900001] = NetChannelLoginResponseCallback,
        [900000] = NetChannelLoginResponseCallback,
        [900002] = NetChannelLoginResponseCallback,
        [98] = NetGetGuidCallback,

        [999998] = NetErrorMessageCallback8,
        [999999] = NetErrorMessageCallback9,
    }
    return GameLoop(fd, acc_ui_callback, acc_net_callback)
end

AccServerSteps = {
    --[1] = Step1SyncResourceEx,
    --[2] = Step3AsynLoopEx
    [1] = Step3AsynLoopEx

}
function ProcessFromAccServer()
    local bFirst = true
    while 1 do
        local bError = false
        fd = ConnectToServer(accserver)
        if fd ~= nil then
            if not bFirst then
                UIReqeustClear()
                UIResponseClear()
                ---UIRequest_({ type = 3 })
                --UIReponse({type = 90})
                UIReponse({type = 777777})
                fd.sock:close()
                return 777777
            end
            for k, v in ipairs(AccServerSteps) do
                cclog("Callback key:%s function:%s", k, v);
                local ret = v(fd)
                if nil == ret then
                    log("Something happend! connection fd:accserver closed!");
                    fd.sock:close()
                    bError = true
                    bFirst = false
                elseif ret == 998 then
                    log("louout .......");
                    bError = true
                    bFirst = true
                elseif ret == 777777 then
                    fd.sock:close()
                    return 777777
                end
                CocosAutoRelease()
            end
            if not bError then
                break
            end
        else
            socket.sleep(1)
        end
    end
    return 1
end
