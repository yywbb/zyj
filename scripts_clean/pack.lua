---
-- Srend and recive message pak.
-- User: jutian
-- Date: 13-4-28
-- Time: 上午11:36
--

local MAGIC = 0xee1c;

local struct = require("struct")

local ser = 0

function PackHeader(len, mytype, ser)
    return struct.pack(">iiii", MAGIC, len, mytype, ser)
end

function UnPackHeader(head)
    local magic, len, mytype, ser = struct.unpack(">iiii", head)
    if magic ~= MAGIC then
        cclog("magic code err!!!! %d %d %d %d", magic, len, mytype, ser);
        return nil
    end
    return len, mytype, ser
end

function MakeSer()
    ser = ser + 1
    return ser
end


function recvHeader(fd)
    fd.rlen = 16
    fd.stat = 0
    fd.rbuf = ""
    while 1 do
        if nil == TCPSelect1conn(fd) then
            return nil;
        end
        if fd.rlen == 0 then
            len, mytype, ser = UnPackHeader(fd.rbuf)

            if len == nil then
                return nil;
            end
            fd.rbuf = ""
            fd.type = mytype
            fd.len = len
            fd.ser = ser
            cclog("in pack -> recv type:%d len:%d head success", fd.type, fd.len);
            break;
        end
    end
    return 1;
end

function recvBody(fd)
    fd.rlen = fd.len
    fd.stat = 1
    while 1 do
        if nil == TCPSelect1conn(fd) then
            return nil;
        end
        --		print("pack recvBody fd.rlen = ", fd.rlen, type(fd.rlen))
        if fd.rlen == 0 then
            cclog("in pack -> recv type:%d len:%d data success", fd.type, fd.len);
            break;
        end
    end
    return 1;
end



function ReqResponse(fd, req, type)
    if nil ~= req then
        fd.wbuf = PackHeader(string.len(req), type, MakeSer()) .. req
    else
        fd.wbuf = PackHeader(0, type, MakeSer())
    end
    if nil == recvHeader(fd) then
        return nil;
    end
    if nil == recvBody(fd) then
        return nil;
    end
    return 1;
end
