---
-- Network connection manager
-- User: jutian
-- Date: 13-4-28
-- Time: 上午11:36
--

local socket = require("socket")

local sendtimes = 0
local lastcleartime = os.time()

local lastScendRequest = nil
local sensitiveReq = {
    [5] = "select server",
    [2] = "config check",
    [1000] = "user data",
    [999900] = "user data",
    [200] = "user data",
}
local loginrequest = {
    [3] = true,
    [90] = true,
    [900001] = true,
    [900002] = true,
    [900000] = true,
}


local lastSendTime = os.time()
local bRecvTimeout = false
local connectNoticStatus = 0 ---0 normal 1 off

NET_SELECT_TIMEOUT_NORMAL = 0.01
NET_SELECT_TIMEOUT_LARGE = 0.00001
NET_SELECT_TIMEOUT_BACKGROUND = 0.01
NET_SELECT_TIMEOUT = NET_SELECT_TIMEOUT_NORMAL

local uiqueue = require("uiqueue")

local m_iContentType = 0 -- 0尝试连接IPV4 1尝试连接IPV6 -1始终无法连接

local function transFromate(destHost)
    local tmpReturnStr = "64:ff9b:"
    local stringMaxLen = string.len(destHost)
    local fuhao = '%.'
    local tmpContentNum = 0
    local i = 0
    local j = 0
    local function cheackStrLen(destStr)
        local tmp0xLen = string.len(destStr)
        local tmpStr = ""
        if tmp0xLen > 1 then
            tmpStr = destStr
        else
            tmpStr = "0"..destStr
        end
        return tmpStr
    end
    local function dealOnce(destStr)
        if tmpContentNum == 0 then
            tmpReturnStr = tmpReturnStr..":"
            tmpContentNum = tmpContentNum + 1
        else
            tmpContentNum = 0
        end
        local tmp0xLen = string.len(destStr)
        local tmp0x = string.find(destStr, "x", 0)
        if tmp0x == nil or tmp0x > tmp0xLen then
            tmpReturnStr = tmpReturnStr..cheackStrLen(destStr)
        else
            tmpReturnStr = tmpReturnStr..cheackStrLen(string.sub(destStr,tmp0x+1,tmp0xLen))
        end
    end
    repeat
        local k = 0
        local fid = ""
        k = string.find(destHost, fuhao, i)
        if k == nil or k > stringMaxLen then
            if j <= stringMaxLen then
                fid = string.sub(destHost,i,stringMaxLen)
                dealOnce(string.format("%#x",tonumber(fid)))
            end
            break
        end
        fid = string.sub(destHost,i,k-1)
        j = k + 1
        i = j
        dealOnce(string.format("%#x",tonumber(fid)))
    until j > stringMaxLen
    print("ipv6====",tmpReturnStr)
    return tmpReturnStr
end

--TODO 建立连接这里需要检查，参考异步下载的C++代码
--- Connect to a server width socket
function ConnectToServer(server)

    local tempserver = {
        hostipv4 = nil,
        hostipv6 = nil,
        port = server.port
    }
    local addrinfo = socket.dns.getaddrinfo(server.host)
    if not addrinfo or not next(addrinfo) then
        UIResponse({type = 9998, log = "网络连接中断......", error = "no addrinfo"})
        cclog("Connection to[%s:%s] failed. errmsg:%s", server.host, server.port, "no addrinfo")
        if connectNoticStatus == 0 then
            connectNoticStatus = 1
            --uiqueue.setresponsetoui({type=502})
        end
        return nil
    end

    for k,v in pairs(addrinfo) do
        print(v.family,v.addr)
        if v.family == "inet" then
            tempserver.hostipv4 = v.addr
        elseif v.family == "inet6" then
            tempserver.hostipv6 = v.addr
        end
    end


    m_iContentType = 0
    if not tempserver.hostipv4 then m_iContentType = 1 end
    cclog("Prepare connect to server, host:%s port:%s", server.host, server.port)
    --local tmpHostv6 = transFromate(server.host)
    local sock = nil
    local errmsg = nil
    local ret = nil
    local function dealIPv4orIPv6()
        repeat
            sock = nil
            errmsg = nil
            if m_iContentType == 0 then
                sock, errmsg = socket.tcp()
            elseif tempserver.hostipv6 then
                sock, errmsg = socket.tcp6()
            end
            if errmsg then
                cclog("tcp initialize error:%s retry", errmsg)
            end
        until sock
        cclog("init tcp success, m_iContentType= %d",m_iContentType)
        errmsg = nil
        sock:settimeout(5)
        if m_iContentType == 0 then
            ret, errmsg = sock:connect(tempserver.hostipv4, server.port)
        elseif tempserver.hostipv6 then
            ret, errmsg = sock:connect(tempserver.hostipv6, server.port)
        end
        if not ret then
            local tmpFamily = sock:getfamily()
            print("tmpFamily===:",tmpFamily)
            if m_iContentType == 0 and tempserver.hostipv6 then
                m_iContentType = 1
                dealIPv4orIPv6()
            end
        end
    end
    dealIPv4orIPv6()
    --TODO Here has a bug: Too many open files retry maybe crash the client.
    -- ret, errmsg = sock:connect("64:ff9b::b65c:a13b", server.port)
    if ret == nil then
        UIResponse({type = 9998, log = "网络连接中断......", error = errmsg})
        cclog("Connection to[%s:%s] failed. errmsg:%s", server.host, server.port, errmsg)
        if connectNoticStatus == 0 then
            connectNoticStatus = 1
            --uiqueue.setresponsetoui({type=502})
        end
        return nil, errmsg
    else
        connectNoticStatus = 0
        bRecvTimeout = false
        cclog("Connection to[%s:%s] succeed.", server.host, server.port)
        uiqueue.setresponsetoui({type=505})
    end

    sock:settimeout(0)
    sock:setoption("keepalive", true)
    --tcp-nodelay
    --sock:setoption("tcp-nodelay", true)
    return { sock = sock, stat = 0, rlen = 16, wlen = 0, rbuf = "", wbuf = nil }
end



--- 接收和发送网络数据
-- @param fd Table contents sockets items
-- @return nil or 1, nil: connection error and connection closed. 1: recived data ok.

function TCPSelect1conn(fd)
    local rlist, wlist, err = {}, {}, nil
    table.insert(rlist, fd.sock)
    if nil ~= fd.wbuf then
        table.insert(wlist, fd.sock)
    end

    --- Select socket by 0.001 second
    rlist, wlist, err = socket.select(rlist, wlist, NET_SELECT_TIMEOUT_NORMAL)
    if err and err ~= "timeout" then
        cclog("socket.select err %s",err)
    end

    for k, v in ipairs(rlist) do
        if v == fd.sock then
            cclog("need recv len:%d", fd.rlen)
            local needrevlen = fd.rlen
--            if fd.rlen > 4*1024 then
--                needrevlen = 4*1024
--            end
            data, errmsg, part = fd.sock:receive(needrevlen)

            --- Must close this debug message after your debug.
            -- cclog("Socket received data: %q \n\terrmsg : %s \n\tpart   : %s", tostring(data), tostring(errmsg), tostring(part))

            if data == nil then
                cclog("data is nil, errmsg:%s",errmsg)
                if errmsg == "timeout" then
                    local recvlen = string.len(part)
                    fd.rlen = fd.rlen - recvlen
                    fd.rbuf = fd.rbuf .. part
                    cclog("timeout len:%d",fd.rlen)
                    bRecvTimeout = true

                else
                    -- 其它错误表示链接出错？直接中断socket 连接
                    cclog("socket errmsg:%s",errmsg);
                    fd.sock:close()
                    if connectNoticStatus == 0 then
                        connectNoticStatus = 1
                        --uiqueue.setresponsetoui({type=502})
                    end
                    return nil;
                end

            else
                local recvlen = string.len(data)
                fd.rlen = fd.rlen - recvlen
                fd.rbuf = fd.rbuf .. data
                bRecvTimeout = false
            end
        end
    end

    local now = os.time()

    for k, v in ipairs(wlist) do
        if v == fd.sock then

            if sendtimes <30 then
                --Log("send")
                fd.sock:send(fd.wbuf)
                cclog("# Send request data length: %d", string.len(fd.wbuf));
                fd.wbuf = nil

                if fd.wtype and fd.wtype ~=999901 and fd.wtype ~=999904 and fd.wtype ~=20000 and  fd.wtype ~=10001 and fd.wtype ~=10003 and fd.wtype ~=999906 then
                    lastSendTime = os.time()
                    bRecvTimeout = true
                    lastScendRequest = fd.wtype
                    uiqueue.setresponsetoui({type = 504,idx = fd.wtype})
                end

                if fd.wtype and loginrequest[fd.wtype] then
                    UIResponse({type = 9998, log = fd.wtype == 3 and "游戏登录......" or "游戏登录..."})
                end
                if fd.wtype and sensitiveReq[fd.wtype] then
                    UIResponse({type = 9998, log2 = sensitiveReq[fd.wtype]})
                end

            else
                UIReqeustClear()
                uiqueue.setresponsetoui({type = 999903})
            end

            if now - lastcleartime >10 then
                sendtimes = 0
                lastcleartime = now
            end

        end
    end


    local ostime = os.time()
    local overtime = 0

    if bRecvTimeout then
        overtime = ostime - lastSendTime
        if overtime > 0 then
            cclog("bRecvTimeout overtime======: %d", overtime);
        end
    end

    local overtimelimit = 10
--    if lastScendRequest and sensitiveReq[lastScendRequest] then
--        overtimelimit = 15
--    end


    if overtime > overtimelimit then
        UIResponse({type = 9998, error = "server time out,  Request "..(lastScendRequest or "")})
        uiqueue.setresponsetoui({type=501})
        fd.sock:close()
        return nil
    end
    return 1;
end

function checkNetSatus(uireq)
    if connectNoticStatus ==0 then
        if not bRecvTimeout then
            return true
        else
            return false
        end
    else
        uiqueue.setresponsetoui({type=502})
        return false
    end

end
