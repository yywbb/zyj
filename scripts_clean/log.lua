---
-- Log functions
-- User: jutian
-- Date: 13-4-28
-- Time: 上午11:39
--


io.output():setvbuf('no')

local LOGTAG = { info = "[INFO] ", error = "[ERROR]" }
--- 网络线程采用不同的日志标志
if isNetThread then
    LOGTAG = { info = "{INFO} ", error = "{ERROR}" }
end

function echo(...)
    if gamedata and not gamedata.isshowlog then return end
    local arr = {}
    for i, a in ipairs({ ... }) do
        arr[#arr + 1] = tostring(a)
    end
    CCLuaLog(table.concat(arr, "\t"))
end

--- Replace print width echo
print = echo

--- Print width format str
function printf(fmt, ...)
    echo(string.format(tostring(fmt), ...))
end

--- Echo error massage width stacktrace.
function echoError(fmt, ...)
    echo(string.format("%s%s %s%s", LOGTAG.error, tostring(os.time()), string.format(tostring(fmt), ...), debug.traceback("", 2)))
end

--- echo info level message width string format.
function echoInfo(fmt, ...)
    if gamedata and not gamedata.isshowlog then return end
    local param_t = {}
    local can = true
    local i1 = 0
    for i, a in pairs({ ... }) do
        local b = a
        if b == nil then
            b = "nil"
        end
        if i > i1 + 1 then
            print(i,i1)
            for j=i1+1,i-1,1 do table.insert(param_t,"nil") end
        end
        table.insert(param_t,b)
        if type(a) ~= "string" and type(a) ~= "number" then
            can = false
        end
        i1 = i
    end
    fmt=string.gsub(fmt,"%%p", "%%s")
    if string.find(fmt,"%%p") or not can then
        echo(LOGTAG.info .. " ".. tostring(os.time()) .." ".. tostring(fmt))
    else
        if #param_t > 0 then
            echo(LOGTAG.info .. " ".. tostring(os.time()) .." ".. string.format(tostring(fmt), unpack(param_t)))
        else
            echo(LOGTAG.info .. " ".. tostring(os.time()) .." ".. tostring(fmt))
        end
    end
end


--[[
%c - 接受一个数字, 并将其转化为ASCII码表中对应的字符
%d, %i - 接受一个数字并将其转化为有符号的整数格式
%o - 接受一个数字并将其转化为八进制数格式
%u - 接受一个数字并将其转化为无符号整数格式
%x - 接受一个数字并将其转化为十六进制数格式, 使用小写字母
%X - 接受一个数字并将其转化为十六进制数格式, 使用大写字母
%e - 接受一个数字并将其转化为科学记数法格式, 使用小写字母e
%E - 接受一个数字并将其转化为科学记数法格式, 使用大写字母E
%f - 接受一个数字并将其转化为浮点数格式
%g(%G) - 接受一个数字并将其转化为%e(%E, 对应%G)及%f中较短的一种格式
%q - 接受一个字符串并将其转化为可安全被Lua编译器读入的格式
%s - 接受一个字符串并按照给定的参数格式化该字符串]]
-- cclog
cclog = echoInfo

log = function(str) echo(LOGTAG.info .. " " .. str) end


--- Print a table struct whith style
-- @param t table
-- @param str Optional String desc message of the table
function printT(t, str, ...)
    if not gamedata.isshowlog then return end
    if nil == str then
        str = "Show table struct:"
    end

    if "table" ~= type(t) then
        cclog("Skip printT, it's not a table.")
        return
    end

    --- Get readable string format of a value for print or log.
    local function strValue(v)
        if type(v) == "string" then
            return string.format("%q", v)
        elseif type(v) == "table" then
            return "table:"
        elseif type(v) == "userdata" then
            return "userdata" --string.format("userdata:%p", v)
        elseif type(v) == "boolean" then
            return v and "true" or "false"
        elseif type(v) == "function" then
            return "function"
        else
            return v
        end
    end

    --- Reale print Table function
    local function _printT(t, deep)
        deep = deep or 0
        --local indent = string.format("%s%%s", string.format(string.format("%%%ds", deep * 4), ""))
        local indent = string.rep(" ", deep * 4) .. "%s"
        --    printf("indent:%q",indent)

        --start of the table.
        printf(indent, "{")

        for k, v in pairs(t) do
            printf(indent, string.format("%4s%-15s = %s", "", strValue(k), strValue(v)));
            if type(v) == "table" then
                deep = deep + 1
                --TODO refactor to tail function call
                _printT(v, deep)
                deep = deep - 1
            end
        end

        --print end of the table.
        if 0 == deep then
            printf(indent, "} --[Table end] \n")
        else
            printf(indent, "}")
        end
    end

    cclog(str, ...)
    _printT(t, 0)
end

-- todo not test method gen_hook do not use it.
function gen_hook(p)
    return function()
        local i = 1
        while true do
            local name = debug.getlocal(2, i)
            if name == nil or string.byte(name) == 40 then -- '(' is 40
                break
            end
            p[i] = name
            i = i + 1
        end
        error()
    end
end


--- Show message and function trace to sourcefile.
-- @param msg String message has %s format info. Example: The net callback defined in: %s
-- @param func Function need trace
-- 注意：此函数影响性能，只为方便调试使用
function cctrace(msg, func)
    if gamedata and not gamedata.isshowlog then return end
    local funcinfo = debug.getinfo(func)
    printf(LOGTAG.info .. msg, string.format("%s:%d", funcinfo.source, funcinfo.linedefined))
    --printT(funcinfo)
end