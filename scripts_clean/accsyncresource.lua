--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/4/1
-- Time: 下午3:26
-- To change this template use File | Settings | File Templates.
--

--local resourceserver = {host = "182.92.161.59", port = 8000} --开发测试服务器
--local resourceserver = {host = "47.94.56.53", port = 10011}--兼容测试
--local resourceserver = {host = "182.92.240.247", port = 20011} --热血测试服务器
--local resourceserver = {host = "182.92.240.247", port = 10001} --开发测试迭代服
--local resourceserver = {host = "acc-ios.zyj.16801.com", port = 10011}--ios官方
--local resourceserver = {host = "106.75.4.212", port = 10011} --神仙也疯狂（ios官方）
--local resourceserver = {host = "182.92.240.247", port = 20001}   --版本包
--local resourceserver = {host = "123.59.145.15", port = 10011}    --混服sever_2
--local resourceserver = {host = "115.159.106.82", port = 10011} --应用宝
--local resourceserver = {host = "123.59.89.135", port = 10011} --IOS越狱正式服
--local resourceserver = {host = "182.92.240.247", port = 30001} --IOS测试热更
--local resourceserver = {host = "182.92.240.247", port = 40001} --Android测试热更
--local resourceserver = {host = "106.75.3.2", port = 11011} --Android新热更服务器
--local resourceserver = {host = "106.75.3.2", port = 11016} --IOS新热更服务器
--local resourceserver = {host = "106.75.3.2", port = 11021} --ios越狱测试热更独立
--local resourceserver = {host = "59.110.51.125", port = 10011} --要播服务器
--local resourceserver = {host = "106.14.68.162", port = 10011} --android变态玩服务器
--local resourceserver = {host = "acc-ios.zyj.16801.com", port = 10041}--ios官方混清源
--local resourceserver = {host = "acc-ios.zyj.16801.com", port = 10071}--ios官方混航美
--local resourceserver = {host = "www.52muyou.com", port = 10011} --ios安趣评审服
--local resourceserver = {host = "acc.zyjiosly.52muyou.com", port = 10011} --ios安趣正式服
--local resourceserver = {host = "139.129.235.184", port = 10011} --7k7k正式服
--local resourceserver = {host = "221.5.35.186", port = 10011} --极品
--local resourceserver = {host = "acc.zyjiosly.52muyou.com", port = 20011} --汉风
--local resourceserver = {host = "zyja.jxwl9.com", port = 10011} --景讯
--local resourceserver = {host = "acc.zyjiosly.52muyou.com", port = 30011} --9377
--local resourceserver = {host = "acc-ios.zyj.16801.com", port = 11011} --安峰混国服
--local resourceserver = {host = "acc.zyjiosly.52muyou.com", port = 40011} --潮游戏
--local resourceserver = {host = "acc.zyjiosly.52muyou.com", port = 50011} --安峰独服
--local resourceserver = {host = "acc.zyjiosly.52muyou.com", port = 51011} --触动、万米混
--local resourceserver = {host = "acc.zyjiosly.52muyou.com", port = 35011} --鲸旗
--local resourceserver = {host = "120.132.30.34", port = 10011} --火柚
--local resourceserver = {host = "120.92.154.224", port = 10011} --爱上游戏
--local resourceserver = {host = "47.92.5.15", port = 10011} --圣泰
--local resourceserver = {host = "106.75.17.163", port = 10011} --摩天轮
--local resourceserver = {host = "47.95.28.75", port = 10011} --国服测试 
--local resourceserver = {host = "47.95.33.171", port = 10011} --独服测试 
--local resourceserver = {host = "101.37.15.132", port = 10011} --奇葩互娱
--local resourceserver = {host = "39.107.53.76", port = 10011}  --新越狱ios

local resourceserver = gamedata.sdk.address.resourceAddress

function SyncResourceFromAccServer()
    while 1 do
        fd = ConnectToServer(resourceserver)
        if fd ~= nil then
            require"syncresource2"
            ret = Step1SyncResource(fd)
            if ret == 0 then
                return 1
            elseif ret == 1 then
                fd.sock:close()
                require"GameDownloadProxy"
                require"commongameloopfunc"
                require"GameErrorMessage"
                require"config"
                local accresource_ui_callback = {
                    [20] = UIDownloadProxyCallback,
                    [997]    = UI997,
                    [996]    = UI996,
                    [998]    = AndroidNetLoad,
                    [999] = UINetQuitLoop,

                    [999988] = LuaExceptionReportCallBack,

                    [81] = UIContinueSysresourceCallBack,

                    [999906] = UIdeviceinfoCallBack,

                    [777777] = UInetLuaReloadCallBack,
                }
                -- 客户端接受服务器传来的数据
                local accresource_net_callback = {

                }
                require"gameloop"
                local loopret = GameLoop(nil, accresource_ui_callback, accresource_net_callback)

                if loopret ~= nil then
                    if loopret == 777777 then
                        fd.sock:close()
                        return 777777
                    else
                        break
                    end
                end
            end
        end
        socket.sleep(1)
    end
    return 1
end