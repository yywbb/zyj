--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/31
-- Time: 下午2:09
-- To change this template use File | Settings | File Templates.
--

local uiqueue = require("uiqueue")

require"syncconfig2"

function acc_net_service()
    while true do
        local uireq = uiqueue.getrequestfromui()
        if nil ~= uireq then
            if uireq.type == 666666 then
                if uireq.opt == "needunzip" then
                    CCDeviceModel:unzipfile(uireq.zippath,uireq.writepath,true)
                    UIResponse({type=666666})                     
                end
            elseif uireq.type == 6666666 then
                gamedata.section = uireq.section
                local ret,type,body = NetunzipFileCallBack(uireq)
                UIResponse(body)

            elseif uireq.type == 777777 then
                return 777777
            elseif uireq.type == 999988 then
                UIResponse({
                    type = 999988,
                    redirect = not uireq.noneedfix,
                    needsend = true,
                    from = uireq.from,
                    msg = uireq.msg,
                })
            elseif uireq.type == 999 then
                gamedata.role.uuid = uireq.uuid
                gamedata.selectserver = uireq.server.id
                gamedata.serverlist[tonumber(gamedata.selectserver)]=uireq.server
                return 1
            end
        end
    end
end