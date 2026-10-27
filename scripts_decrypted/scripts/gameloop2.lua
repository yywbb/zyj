---
-- Game loop Send data
-- User: WangTao
-- Date: 13-5-3
-- Time: 下午3:04
--

local timeinteval = {
    [1306] = 1,
    [1307] = 1,
    [3621] = 1,

    [3701] = 1,
    [1341] = 1,
    [1342] = 1,

    [1407] = 1,

}

local requestwithoutnet = {
    [1] = true,
    [777777] = true,
}

local serTable = {}

require"network"
NetLastResponseType = nil

--bSDKActivity = false

local backtime = nil

local uiqueue = require("uiqueue")
bBackGround = false
local bGameLoop2ConnectFirst = true
function GameLoop2(address, uicallbacks, netcallbacks, netextcallbacks)
    local fd = false
    local bPrepareConnect = true
    while 1 do
        --uiqueue.autorelease()
        if not fd and bPrepareConnect then
            fd = ConnectToServer(address)
            print(bGameLoop2ConnectFirst)
            if fd ~= nil then
                if bGameLoop2ConnectFirst then
                    cclog("connect first")
                    bGameLoop2ConnectFirst = false
                else
                    cclog("connect times")
                    UIReqeustClear()
                    UIRequest_({ type = 1000 })
                end
                bPrepareConnect = false
                fd.rbuf = ""
                fd.stat = 0
                fd.rlen = 16
            else
                fd = false
                socket.sleep(1)
            end
            print(bGameLoop2ConnectFirst)
        end
        if bBackGround then
            socket.sleep(0.1)
        end
        if fd == false or fd.wbuf == nil then
            local uireq = uiqueue.getrequestfromui()

            if checkNetSatus() or (uireq and requestwithoutnet[uireq["type"]]) then
                --local uireq = uiqueue.getrequestfromui()  

                --- 1 判断是否有ui请求
                if nil ~= uireq and (not timeinteval[uireq["type"]]  or (os.time() > timeinteval[uireq["type"]]+2)) then

                    if timeinteval[uireq["type"]] then timeinteval[uireq["type"]] = os.time() end
                    local func = uicallbacks[tonumber(uireq["type"], 10)]
                    if nil == func then
                        local errMsg = string.format("UICallback not exists check gameserver[game_ui_callback][%d] or The implements not required into gameserver.lua.", uireq.type)
                        echoError(errMsg)
                        UIRequest({type=999988, msg=errMsg, from="net", noneedfix = true})
                        --__G_TRACKBACK__(errMsg)
                    else
                        cclog("# Net recieve UI call ID: %d", uireq.type)
                        --- 1. 接收UI请求从缓存取数据，
                        -- ret: 缓存中是否有对应的数据 0:有 1:没有
                        local func1,func2 = func,__G_TRACKBACK__
                        if type(func) == "table" then
                            func1 = func[1]
                            if #func > 1 then
                                func2 = func[2]
                            end
                        end
                        cctrace("# Net execute UI callback function defined in: %s", func1)
                        local bcall, ret, mytype, body = xpcall(function() return func1(uireq) end,func2);
                        --uiqueue.autorelease()
                        if bcall then
                            cclog("GameLoop return ret:%s type:%s", ret or "nil", mytype or "nil");
                            --- 2. ret==0 缓存中有数据，直接将数据返回给 UI 层
                            if ret == 0 then
                                if nil ~= body and body ~= "" then
                                    --海外版使用的是UIResponsByJson
                                    uiqueue.setresponsetoui(body)
                                end
                                --- 2. ret==1 缓存中无数据，需向服务器发送请求
                            elseif ret == 1 then

                                local ser = MakeSer()
                                if nil ~= body then
                                    --TODO 如果发送了多个请求这样写会出错的吧？
                                    fd.wbuf = PackHeader(string.len(body), mytype, ser) .. body
                                    fd.wtype = mytype
                                else
                                   if not fd then
                                       uiqueue.pushrequesttoclient(uireq)
                                   else
                                       fd.wbuf = PackHeader(0, mytype, ser)
                                       fd.wtype = mytype
                                   end                                
                                end
                                print("serTable[ser]  send",ser,mytype)
                                serTable[ser] = mytype

                                --- 3. 999 是一个特例待查证
                            elseif ret == 999 then
                                if fd then
                                   fd.sock:close()
                                end
                                return 999
                            elseif ret == 997 then
                                if fd then
                                    -- if bSDKActivity then
                                    -- else
                                        fd.sock:close()
                                        fd = false
                                        bPrepareConnect = false
                                    --end

                                end

                                backtime = gamedata:time()
                            elseif ret == 996 then

                                if backtime then
                                    local date1 = os.date("*t", gamedata:time())
                                    local date2 = os.date("*t", backtime)

                                    if gamedata:time() - backtime > 30*60 or date1.day ~= date2.day then
                                        if fd then
                                            fd.sock:close()
                                        end
                                        UIResponseClear()
                                        UIReponse({type = 777777})
                                        backtime = nil
                                        return 777777
                                    end
                                end
                                -- if bSDKActivity then
                                --     bSDKActivity = false
                                -- else
                                    bPrepareConnect = true
                                    gamedata.reconnect_type = 2
                                -- end
                                backtime = nil
                            elseif ret == 995 then
                                if fd then
                                    gamedata.reconnect_type = 4
                                    fd.sock:close()
                                    uiqueue.setresponsetoui({type=501})
                                    return nil
                                end
                            elseif ret == 9951 then
                                if fd then
                                    gamedata.reconnect_type = 4
                                    fd.sock:close()
                                    return nil
                                end
                            elseif ret == 777777 then
                                if fd then
                                    fd.sock:close()
                                end
                                return 777777
                            end
                        else
                            cctrace("# Net execute UI Error callback function defined in: %s", func2)
                            cclog("[Error]GameLoop UI Request Process Error");
                        end
                    end
                end
            else
                -- UIReqeustClear()
                local requests = {}
                table.insert(requests,uireq)

                local req = uiqueue.getrequestfromui()
                while req do
                    table.insert(requests,req)
                    req = uiqueue.getrequestfromui()
                end

                for k,v in ipairs(requests) do
                    uiqueue.pushrequesttoclient(v)
                end
            end
        end
        if fd ~= false then
            --- 2 处理网络消息数据:发送和接收
            if nil == TCPSelect1conn(fd) then
                cclog("Net connect disconnect")
                gamedata.reconnect_type = 3
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

                    cclog("# In gameloop -> recv type:%d len:%d head success    ser %d", fd.type, fd.len,fd.ser);
--                    if fd.len > 4096 then
--                        NET_SELECT_TIMEOUT = NET_SELECT_TIMEOUT_LARGE
--                    end
                elseif fd.stat == 1 then --收到数据
                    --NET_SELECT_TIMEOUT = NET_SELECT_TIMEOUT_NORMAL
                    --追加ack机制，client收到消息后，自动回应服务器收到了
--                    if fd.wbuf then
--                        fd.wbuf = fd.wbuf .. PackHeader(0, -1, fd.ser)
--                    else
--                        fd.wbuf = PackHeader(0, -1, fd.ser)
--                    end
                    cclog("# In gameloop -> recv type:%d len:%d data success    ser %d", fd.type, fd.len,fd.ser);
                    local func = netcallbacks[fd.type]
                    local uirep,bcall = nil,false

                    if fd.type ~= 999902 then
                        NetLastResponseType = fd.type
                    end

                    -- 1.先进行网络处理：pb to table, 缓存更新等等
                    if nil == func then
                        cclog("Warn netcallbacks not reg callback ID:%d", fd.type)
                    elseif  serTable[fd.ser] or fd.ser ==0 or fd.type == 1000 then
                        local func1,func2 = func,__G_TRACKBACK__
                        if type(func) == "table" then
                            func1 = func[1]
                            if #func > 1 then
                                func2 = func[2]
                            end
                        end
                        bcall,uirep = xpcall(function() return func1(fd) end,func2)

                        --uiqueue.autorelease()
                        if not bcall then
                            cclog("[Error]GameLoop Net Reponse Process Error");
                        end
                        if  fd.type ~= 1000 then
                            serTable[fd.ser] = nil
                        end
                    else
                        print("serTable[fd.ser]",serTable[fd.ser])
                        cclog("receive more than one time :type=%d  ser=%d", fd.type,fd.ser)
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
   1  