--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-5-7
-- Time: 下午5:48
-- To change this template use File | Settings | File Templates.
--

local jsonm = require("cjson")
local json = jsonm.create()


function LoadJsonFileToTable(jsonfile)
    local json_text = CCString:createWithContentsOfFile(jsonfile):getCString();
    return json.decode(json_text)
end

function LoadJsonFileToTableforNet(jsonfile)
    local json_text = CCString:createWithContentsOfFileforNet(jsonfile):getCString();
    return json.decode(json_text)
end

function LoadJsonStringToTable(jsonstring)
    return json.decode(jsonstring)
end

function MakeJsonStringFromTable(t)
    return json.encode(t)
end