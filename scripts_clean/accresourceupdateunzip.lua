--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/31
-- Time: 下午2:09
-- To change this template use File | Settings | File Templates.
--

local uiqueue = require("uiqueue")
function resourceupdateunzip()
    while true do
        local uireq = uiqueue.getrequestfromui()
        if nil ~= uireq then
            if uireq.type == 666666 then
                if uireq.opt == "needunzip" then
                    CCDeviceModel:unzipfile(uireq.zippath,uireq.writepath,true)
                    UIResponse({type=666666})                     
                end
                if uireq.opt == "noneedunzip" then
                    if uireq.restart and uireq.restart ==1 then
                        UIReponse({type = 777777})
                        return 777777
                    end
                    return 1
                end
            elseif uireq.type == 998 then
                require"config"
                AndroidNetLoad()
            elseif uireq.type == 777777 then
                return 777777
            elseif uireq.type == 95 then
                gamedata.sdk.NetSyncChannel(uireq)
            end
        end
    end
end