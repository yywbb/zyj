--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/7/10
-- Time: 下午2:06
-- To change this template use File | Settings | File Templates.
--

-- function UIGlobalParam(t)
--     local acc_id = t.acc_id
--     local game_id = t.game_id
--     local role_id = t.role_id
--     local channel = t.channel
--     if MiPushSDK then
--         cclog("set MiPushSDK")
--         local alias = string.format("%s_%s_%s", acc_id, game_id, role_id)
--         local acc_topic = string.format("acc_%s",acc_id)
--         local accgame_topic = string.format("acc_%s_%s",acc_id, game_id)
--         local channel_topic = string.format("channel_%s",channel)
--         MiPushSDK.setAlias(alias)
--         MiPushSDK.subscribe(acc_topic)
--         MiPushSDK.subscribe(accgame_topic)
--         MiPushSDK.subscribe(channel_topic)
--     else
--         cclog("no MiPushSDK")
--     end
-- end



function UIGlobalParam(t)
    local acc_id = t.acc_id
    local game_id = t.game_id
    local role_id = t.role_id
    local channel = t.channel
    cclog("UIGlobalParam acc_id:%d game_id:%d role_id:%d channel:%s", acc_id, game_id, role_id, channel)
    local alias = string.format("%s_%s_%s", acc_id, game_id, role_id)
    local acc_topic = string.format("acc_%s",acc_id)
    local accgame_topic = string.format("acc_%s_%s",acc_id, game_id)
    local channel_topic = string.format("channel_%s",channel)
    local deviceApi = require"device"
    if deviceApi.platform == "ios"then
        cclog("ios check")
        if MiPushSDK then
            cclog("ios set MiPushSDK")
            MiPushSDK.setAlias(alias)
            MiPushSDK.subscribe(acc_topic)
            MiPushSDK.subscribe(accgame_topic)
            MiPushSDK.subscribe(channel_topic)
        end
    elseif deviceApi.platform == "android" then
        cclog("android check")
        local luaj = require"luaj"
        --local javaClassName1 = "com/ldfs/sanguo2/AndroidUtils"
        -- local javaClassName1 = "com/ldfs/sanguo/AndroidUtils"
        local javaClassName1 = gameConfig.AD_packageName.."/AndroidUtils"
        local javaMethodName1 = "MiPush_setAlias"
        local javaParams1 = {alias}
        local javaMethodSig1 = "(Ljava/lang/String;)V"
        luaj.callStaticMethod(javaClassName1, javaMethodName1, javaParams1, javaMethodSig1)

        --local javaClassName2 = "com/ldfs/sanguo2/AndroidUtils"
        --local javaClassName2 = "com/ldfs/sanguo/AndroidUtils"
        local javaClassName2 = gameConfig.AD_packageName.."/AndroidUtils"
        local javaMethodName2 = "MiPush_subscribe"
        local javaMethodSig2 = "(Ljava/lang/String;)V"
        local javaParams2 = {acc_topic }
        luaj.callStaticMethod(javaClassName2, javaMethodName2, javaParams2, javaMethodSig2)
        javaParams2 = {accgame_topic }
        luaj.callStaticMethod(javaClassName2, javaMethodName2, javaParams2, javaMethodSig2)
        javaParams2 = {channel_topic }
        luaj.callStaticMethod(javaClassName2, javaMethodName2, javaParams2, javaMethodSig2)
    end
end