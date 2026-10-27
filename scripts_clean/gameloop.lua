---
-- Game loop Send data
-- User: WangTao
-- Date: 13-5-3
-- Time: 下午3:04
--

local uiqueue = require("uiqueue")

function GameLoop(fd, uicallbacks, netcallbacks, netextcallbacks)
    if fd then
        fd.rbuf = ""
        fd.stat = 0
        fd.rlen = 16
    end
    while 1 do
        --uiqueue.autorelease()
        local uireq = uiqueue.getrequestfromui()

        --- 1 判断是否有ui请求
        if nil ~= uireq then
            local func = uicallbacks[tonumber(uireq["type"], 10)]
            if nil == func then
                local errMsg = string.format("UICallback not exists check gameserver[game_ui_callback][%d] or The implements not required into gameserver.lua.", uireq.type)
                echoError(errMsg)
                __G_TRACKBACK__(errMsg)
            else
                cclog("# Net recieve UI call ID: %d", uireq.type)
                cctrace("# Net execute UI callback function defined in: %s", func)

                --- 1. 接收UI请求从缓存取数据，
                -- ret: 缓存中是否有对应的数据 0:有 1:没有
                local ret, mytype, body = func(uireq);
                --uiqueue.autorelease()
                cclog("GameLoop return ret:%s type:%s", ret or "nil", mytype or "nil");
                --- 2. ret==0 缓存中有数据，直接将数据返回给 UI 层
                if ret == 0 then
                    if nil ~= body and body ~= "" then
                        --海外版使用的是UIResponsByJson
                        uiqueue.setresponsetoui(body)
                    end
                    --- 2. ret==1 缓存中无数据，需向服务器发送请求
                elseif ret == 1 then
                    if nil ~= body then
                        --TODO 如果发送了多个请求这样写会出错的吧？
                        fd.wbuf = PackHeader(string.len(body), mytype, MakeSer()) .. body
                        fd.wtype = mytype
                    else
                        fd.wbuf = PackHeader(0, mytype, MakeSer())
                        fd.wtype = mytype
                    end
                    --- 3. 999 是一个特例待查证
                elseif ret == 999 then
                    if fd then
                        fd.sock:close()
                    end
                    return 999
                elseif ret == 998 then
                    if fd then
                        fd.sock:close()
                    end
                    return 998
                elseif ret == 777777 then
                    if fd then
                        fd.sock:close()
                    end
                    return 777777
                end
            end
        end
        if fd then
            --- 2 处理网络消息数据:发送和接收
            if nil == TCPSelect1conn(fd) then
                cclog("Net connect disconnect")
                return nil
            end

            if fd.rlen == 0 then
                if fd.stat == 0 then --收到数据头
                    local len, mytype, ser = UnPackHeader(fd.rbuf)
                    if len == nil then
                        return nil
                    end
                    fd.stat = 1
                    fd.rbuf = ""
                    fd.type = mytype
                    fd.len = len
                    fd.ser = ser
                    fd.rlen = len
                    cclog("# In gameloop -> recv type:%d len:%d head success", fd.type, fd.len);
                elseif fd.stat == 1 then --收到数据
                    cclog("# In gameloop -> recv type:%d len:%d data success", fd.type, fd.len);
                    local func = netcallbacks[fd.type]
                    local uirep

                    -- 1.先进行网络处理：pb to table, 缓存更新等等
                    if nil ~= func then
                        uirep = func(fd)
                        --uiqueue.autorelease()
                    else
                        cclog("Warn netcallbacks not reg callback ID:%d", fd.type)
                    end

                    cclog("# Check response data from net callbacks. Has data: %s", nil ~= uirep);
                    --printT(uirep)

                    -- 2.首先进行意外处理：如果需要拦截请在意外处理中返回 nil
                    if nil ~= netextcallbacks and nil ~= next(netextcallbacks) and nil ~= netextcallbacks[fd.type] then
                        uirep = netextcallbacks[fd.type](uirep)
                        netextcallbacks[fd.type] = nil
                    end

                    -- 3. 最后进行常规处理，将处理结果按照正常的接口返回给UI
                    if nil ~= uirep and "" ~= uirep then
                        --海外版使用的是UIResponsByJson
                        uiqueue.setresponsetoui(uirep)
                    end
                    fd.stat = 0
                    fd.rlen = 16
                    fd.rbuf = ""
                end
            end
        end

        uiqueue.autorelease()
    end

    return 1
end
