--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/4/1
-- Time: 下午3:55
-- To change this template use File | Settings | File Templates.
--

require"UILogin"
require"UIErrorMessage"
require"UIDownloadProxy"
require"UIReLogin"
local uiqueue = require("uiqueue")
local syncresource_ui_callback = {
    [9] = setLoginPercentFromServer,
    [20] = UIDownloadProxy,
    --错误信息相关
    [9999] = UIErrorMessage,
    [9997] = UIErrorMessage7,
    [888888] = UILoginShow,
}

local socket = require("socket")

function UIUpdate2()
    --local t1 = socket.gettime()
    for i=1,10,1 do
        local tret = uiqueue.popresponsefromclient()
        if tret ~= nil then
            --print(socket.gettime() - t1, "popresponsefromclient",tret["type"])
            cclog("UIUpdate2 PUSH  tret.type = %s tret = %s", tret["type"], tret)

            local func = syncresource_ui_callback[tonumber(tret["type"], 10)]
            ---assert(func, string.format("UI callback not exist in UIUpdate.lua", tret.type))

            if nil ~= func then
                local func1,func2 = func,__G_TRACKBACK__
                if type(func) == "table" then
                    func1 = func[1]
                    if #func > 1 then
                        func2 = func[2]
                    end
                end
                local bcall, ret, body = xpcall(func1,func2,tret)
                if bcall then
                    if ret ~= 0 then
                        if body ~= nil then
                            cclog("UIUpdate2 PUSH func =%s ret =%s body=%s", func1, ret, body)
                            uiqueue.pushrequesttoclient(body)
                        end
                    end
                else
                    cclog("[Error]UIUpdate2 Process Error");
                end
            else
                cclog("UIUpdate2 type:%s invalid content:%s", tret["type"], tret)
            end
            loading:stopGameloading(tret["type"])
            if guide.controller ~= nil and next(guide.controller) ~=nil then
                guide.controller:CompleteStep("uiupdate",tret["type"])
            end
            --print(socket.gettime() - t1, "UIUpdate",tret["type"])
        else
            break
        end
    end
end


function startUIUpdate1()
    if not UIUpdateScheduleScriptFunc2 then
        UIUpdateScheduleScriptFunc2 = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(UIUpdate2, 0, false)
    end
end

function pauseUIUpdate1()
    if UIUpdateScheduleScriptFunc2 then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(UIUpdateScheduleScriptFunc2)
        UIUpdateScheduleScriptFunc2 = nil
    end
end

startUIUpdate1()

--if not gamedata.music then
--    gamedata.music = require"music"
--    gamedata.music:Init()
--    ---gamedata.music:GameStart()
--end
