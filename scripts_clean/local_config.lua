--[[
-- Local server config file
-- User: inaction
-- Date: 13-10-16
-- Time: 下午6:30
]]
--- Set to false to disable local server config
local localEnabled = false

--- Local server config
local accserver = { host = "192.168.1.200", port = 7220 }

if localEnabled then
    return accserver
else
    return {}
end