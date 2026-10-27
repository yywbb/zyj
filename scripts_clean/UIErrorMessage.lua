--
-- Created by IntelliJ IDEA.
-- User: han-joy
-- Date: 13-10-16
-- Time: 下午4:33
-- To change this template use File | Settings | File Templates.
--


local logerr = require("logError")

function UIErrorMessage(t)
    if not t.errornum then runGamePrompt({msg = t.msg}) return end

    if not gameConfig:checkBuildOpen(154) and t.errornum == 50 then
        runGamePrompt({msg = "条件不满足"})
        return
    end

    local cnMessage = logerr.errorMessage[t.errornum] or "您的数据可能出现异常"
    --公会报名时间
    if t.errornum == 260 and gamedata.config.global_kv.gang2_signup_time then
        cnMessage = string.format(logerr.errorMessage[t.errornum], gamedata.config.global_kv.gang2_signup_time.value)
    end

    if t.errornum ~= 999996 then
        runGamePrompt({msg = cnMessage})
    end

    if logerr.errorFunc[t.errornum] then
        logerr.errorFunc[t.errornum](cnMessage)
    else
        gameWindows:closeAllWindowDirect()
        GameScene:UpdatePresentLayer(true)
    end

    return 0, nil
end

function UIErrorMessage7(t)
    cclog("UIPromptNoSignal = %s", t.msg)
    loading:exitGame(t.msg)
    return 0, nil
end

function UIRequestLocking(t)
    runGamePrompt({msg = "操作太频繁，请稍后再试"})
end


function UILuaException(t)
    if t.redirect and t.redirect==1 then
        runGamePrompt({msg = "数据出错,请返回主界面"})
    end

    if t.needsend and MYGameSendData and MYGameSendData.SendErrorLog then
        local msg = string.gsub(t.msg,"=",":")
        MYGameSendData:SendErrorLog(t.from,msg)
    end
end