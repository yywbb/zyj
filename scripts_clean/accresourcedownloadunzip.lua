--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/31
-- Time: 下午2:09
-- To change this template use File | Settings | File Templates.
--

local uiqueue = require("uiqueue")
function unzipresource()
    while true do
        local uireq = uiqueue.getrequestfromui()
        if nil ~= uireq then
            if uireq.type == 666666 then
                if uireq.opt == "needunzip" then
                    CCDeviceModel:unzipfile(uireq.zippath,uireq.writepath,true)
                    UIResponse({type=666666})                
                end
                if uireq.opt == "noneedunzip" then
                    return 1
                end
            elseif uireq.type == 998 then
                require"config"
                AndroidNetLoad()
            end
        end
    end
end