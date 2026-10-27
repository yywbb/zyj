--[[
-- Lua 基础对象的公共方法集合，需要在初始化时被调用
-- Created by IntelliJ IDEA.
-- User: liliang
-- Date: 13-8-31
-- Time: 上午11:10
]]


--- Import module width relative path
-- @param moduleName The module name should be imported
-- @param currentModuleName
-- @return Imported module result
function import(moduleName, currentModuleName)
    local currentModuleNameParts
    local moduleFullName = moduleName
    local offset = 1

    while true do
        if string.byte(moduleName, offset) ~= 46 then -- .
            moduleFullName = string.sub(moduleName, offset)
            if currentModuleNameParts and #currentModuleNameParts > 0 then
                moduleFullName = table.concat(currentModuleNameParts, ".") .. "." .. moduleFullName
            end
            break
        end
        offset = offset + 1

        if not currentModuleNameParts then
            if not currentModuleName then
                local n, v = debug.getlocal(3, 1)
                currentModuleName = v
            end

            currentModuleNameParts = string.split(currentModuleName, ".")
        end
        table.remove(currentModuleNameParts, #currentModuleNameParts)
    end

    return require(moduleFullName)
end


--- Split a string by a str delimiter.
-- @param str Source string.
-- @param delimiter String of delimiter.
-- @return array splited
function string.split(str, delimiter)
    if (delimiter == '') then return false end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function() return string.find(str, delimiter, pos, true) end do
        table.insert(arr, string.sub(str, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str, pos))
    return arr
end

--- Trim string " "
function string.trim(str)
    str = string.gsub(str, "^[ \t\n\r]+", "")
    return string.gsub(str, "[ \t\n\r]+$", "")
end



---
-- 序列化一个table 对象为 lua 代码，需要时可以将其 require 进来直接使用
-- @param t The table need to be serialized.
-- @return String of the table serialized to lua codes can be required.
function serialize(t)
    local mark = {}
    local assign = {}

    local function ser_table(tbl, parent)
        mark[tbl] = parent
        local tmp = {}
        for k, v in pairs(tbl) do
            local key = type(k) == "number" and "[" .. k .. "]" or k
            if type(v) == "table" then
                local dotkey = parent .. (type(k) == "number" and key or "." .. key)
                if mark[v] then
                    table.insert(assign, dotkey .. "=" .. mark[v])
                else
                    table.insert(tmp, key .. "=" .. ser_table(v, dotkey))
                end
            elseif type(v) == "number" then
                table.insert(tmp, key .. "=" .. v)
            elseif type(v) == "string" then
                table.insert(tmp, key .. "=\"" .. v .. "\"")
            elseif type(v) == "boolean" then
                table.insert(tmp, key .. "=" .. v)
            end
        end
        return "{" .. table.concat(tmp, ",") .. "}"
    end

    return "do local ret=" .. ser_table(t, "ret") .. table.concat(assign, " ") .. " return ret end"
end


--- Clone object to new object
-- @param object src Object
-- @return clone object
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end

    return _copy(object)
end


--- 获取table中元素的个数
-- @param ht required table.
-- @return number of table elements count.
table.getTableLength = function(ht)
    if (ht == nil) then ht = {} end
    local n = 0
    for _, v in pairs(ht) do
        n = n + 1
    end
    return n
end

table.count = table.getTableLength


--- Get table keys as a new table array
-- @param t Table required.
-- @return array of keys
function table.keys(t)
    local keys = {}
    for k, v in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end


--- Get table values as a new table array
-- @param t Table required.
-- @return array of values
function table.values(t)
    local values = {}
    for k, v in pairs(t) do
        values[#values + 1] = v
    end
    return values
end


--- Copy a table to a new table
-- @param t tale
-- @return new Table has same data
function table.copy(t)
    local t2 = {}
    for k, v in pairs(t) do
        if (type(v) == "table") then
            t2[k] = table.copy(v)
        else
            t2[k] = v
        end
    end
    return t2
end


--- Merge tables from src and dest to a new table
-- @param dest source table 1
-- @param src source table 2
-- @return A new table contains desc and src
function table.merge(dest, src, debug)
    debug = not not debug
    local ret = {}
    if dest and next(dest) ~= nil then
        for k, v in pairs(dest) do
            if debug then
                cclog("merge key:[%s] to dest.", k)
            end
            if (type(v) == "table") then
                ret[k] = v--table.copy(v)
            else
                ret[k] = v
            end
        end
    end
    if src and next(src) ~= nil then
        for k, v in pairs(src) do
            if debug then
                cclog("merge key:[%s] to dest.", k)
            end
            if (type(v) == "table") then
                ret[k] = v--table.copy(v)
            else
                ret[k] = v
            end
        end
    end


    return ret
end


---concat2
---at & bt are all array
function table.concat2(at,bt)
    for k,v in ipairs(bt) do
        table.insert(at,v)
    end
end

--- Merge a simple Protobuf fields to a table
-- @param dest Table of dest.
-- @param pb Protobuff object width simple struct(Simple key and silple values)
-- @param debug Option boolean : true, enable debug log; nil or false, disable debug log.
-- @return merged dest table,
function table.mergePb(dest, pb, debug)
    local pbFields = pb._fields
    if (pbFields == nil or "table" ~= type(pbFields)) then
        cclog("pb is not a protobuf format table. Return unmodified dest.")
        return dest
    end

    --[[if debug then
    cclog("Merging protobuff:%p fields into table:%p", pb, dest)
        cclog("Show protobuf struct:\n%s", tostring(pb))
    end]]

    --- reale merge method of protobuff to table
    local function pb2table(dest, t)
        for k, v in pairs(t) do
            if type(v) ~= "table" or type(v) ~= "usertype" then
                if debug then
                    cclog("Set dest.%-15s = %s", k.name, v)
                end

                dest[k.name] = v
            else
                cclog("Skip protobuf key pb[%s], it's type is table. need update this method?")
            end
            --            if(type(k) == "table") then p(k) end
        end
        return dest
    end

    return pb2table(dest, pbFields)
end

--- Auto init protobuff Mode
-- @param pbMode Protobuff name
-- @param pbBuff Connection fd object contains protobuff stream obj
-- @return Protobuff module instance object
function initPb(pbMode, pbBuff)
    --    cclog("Protobuff name: %s", pbMode._NAME)
    assert(pbMode._NAME, "pbMode is not a protobuff Module obj.")
    local result
    for k, v in pairs(pbMode) do
        if "_" ~= string.sub(k, 1, 1) then
            cclog("Init protobuff %s:%s", pbMode._NAME, k)
            result = v()
            result:ParseFromString(pbBuff.rbuf)
            break
        end
    end
    return result
end

--- Init protobuff request
-- @param pbMode protobuff Module
-- @param req UIRequest object
-- @param fields Fields array need to get from UIRequest
-- @return 1,req.type, Serialized protobuff string
function initPbRequest(pbMode, req, fields)
    assert(pbMode._NAME, "pbMode is not a protobuff Module obj.")
    local result
    for k, v in pairs(pbMode) do
        if "_" ~= string.sub(k, 1, 1) then
            cclog("Init protobuff %s:%s", pbMode._NAME, k)
            result = v()
            break
        end
    end

    if nil ~= fields then
        each(fields, function(field) result[field] = req[field] end)
    end

    return 1, req.type, result:SerializeToString()
end

--- Merge table by filter
-- @param t1 source table 1
-- @param t2 source table 2
-- @param filter filter {path="././id"}
function table.iMerge(t1, t2, filter, debug)
    if nil == t1 or "table" ~= type(t1) then
        t1 = {}
    end

    local function _merge(dest, src)
        for k, v in pairs(src) do
            if debug then
                cclog("merge key:[%s] to dest.", k)
            end
            if "table" == type(v) then
                if nil == dest[k] then dest[k] = {} end
                _merge(dest[k], v)
            else
                dest[k] = v
            end
        end
    end

    if nil ~= t2 and 'table' == type(t2) then
        if nil == filter then
            _merge(t1, t2)
        else
            if nil == t1[filter] then
                t1[filter] = {}
            end
            _merge(t1[filter], t2)
        end
    end
end


--- simple each function for table:Array
-- @param t Table of an array
-- @param callback The callback Function accept element of table as the pramater.
function each(t, callback)
    for index, v in ipairs(t) do
        callback(v, index)
    end
end

function each2(t, callback)
    for key, v in pairs(t) do
        callback(v, key)
    end
end

--- Set table key to default value if t[k] is nil
function table.nil2value(t, k, defaultValue)
    if 'table' == type(t) and nil == t[k] and nil ~= defaultValue then
        t[k] = defaultValue
    end
end

--- 三元表达式处理,有bug:表达式作为参数会提前进行计算，而不是完全意义上的三元计算
function yesorno(condition, yesValue, noValue)
    if condition then return yesValue else return noValue end
end

function math.mod(num1,num2)
    return num1%num2
end