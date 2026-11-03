-- 只记录分类和调用位置，不把任意异常原文中的动态值交给Java或网络。
local function localReportLua(message, source)
    local bridge = CCLuaJavaBridge or LuaJavaBridge
    if not bridge or not bridge.callStaticMethod then return end
    local text = tostring(message)
    local kind = "runtime"
    if text:find("nil value", 1, true) then kind = "nil_value"
    elseif text:find("bad argument", 1, true) then kind = "argument"
    elseif text:find("arithmetic", 1, true) then kind = "arithmetic"
    elseif text:find("assertion failed", 1, true) then kind = "assertion" end
    local lines = {"lua_error=" .. kind}
    local function location(line)
        local file, number = line:match('%[string "([^"]+)"%]:(%d+)')
        if not file then file, number = line:match('([%w_./-]+%.lua):(%d+)') end
        if file and #file <= 160 and #number <= 9 and file:match('^[%w_./-]+$') then
            lines[#lines + 1] = "at " .. file .. ":" .. number
        end
    end
    location(text:sub(1, 512))
    local trace = debug.traceback("", 3)
    for line in trace:gmatch("[^\r\n]+") do
        if #lines >= 80 then break end
        location(line)
        local name = line:match("in function '([%w_%.:]+)'")
        if name and #name <= 120 then lines[#lines + 1] = "in " .. name end
    end
    bridge.callStaticMethod("com/zyj/local/ClientReports", "reportLua",
        {source, table.concat(lines, "\n")}, "(Ljava/lang/String;Ljava/lang/String;)V")
end
pcall(function()
    local bridge = CCLuaJavaBridge or LuaJavaBridge
    if bridge and bridge.callStaticMethod then
        bridge.callStaticMethod("com/zyj/local/ClientReports", "installThread", {}, "()V")
    end
end)
