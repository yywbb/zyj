--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-12-23
-- Time: 上午11:56
-- To change this template use File | Settings | File Templates.
--

require"myjson"

--
local function activityEx()
    local buildJson = gamedata.config.activity_time

    for k,v in pairs(buildJson) do
        if v.type_new and tonumber(v.type_new) > 0 then
            v.type = v.type_new
        end
    end

    gamedata.config.activity_time = buildJson

end
--

local function BuildEx()
    local buildJson = gamedata.config.build
    local build_key = {}
    local build_level = {}
    for k,v in pairs(buildJson) do

        if v.type == "layersub" or v.type == "copy_chapter" then
            if v.switch and v.switch == 1 and (not build_key[v.param1] or  v.level < build_key[v.param1].level) then
                build_key[v.param1] = v
            end
            if not build_key[v.param1..v.key] or v.level < build_key[v.param1..v.key].level then
                build_key[v.param1..v.key] = v
            end
        elseif v.type == "layer" or v.type == "window" then
            build_key[v.key] = v
        elseif v.type == "request" then
            build_key[v.param2] = v
        else
            build_key[k] = v
        end

        if not build_level[v.level] then
            build_level[v.level] = {}
        end
        table.insert(build_level[v.level],v)
    end

    gamedata.config.build_key = build_key
    gamedata.config.build_level = build_level
--    printT(buildEx)
end

local function roleexpEx()
   local rolejson = gamedata.config.role_exp
   local general_slot = {}
   local general_cheer = {}

    for i=1 , table.getTableLength(rolejson) do
        for k=table.getTableLength(general_slot), rolejson[tostring(i)].slotnum do
            if not general_slot[tostring(k)] and k~=0 then
                general_slot[tostring(k)] = i
            end
        end

        for j=table.getTableLength(general_cheer), rolejson[tostring(i)].cheernum do
            if not general_cheer[tostring(j)] and j~=0 then
                general_cheer[tostring(j)] = i
            end
        end
    end

   gamedata.config.general_slot = general_slot
   gamedata.config.general_cheer = general_cheer
end

local function noticeEx()
    if gameWindows and gameWindows.windows["post"] then
        gameWindows.windows["post"].module:getSizeTable()
    end
end

local extfunc = {
    build = BuildEx,
    role_exp = roleexpEx,
    notice_3  = noticeEx,
    activity_time = activityEx,
}



function UILoadConfig(t)
    print("ui加载config, 500，接受客户端数据")
    t.rate = t.rate or {type = "config", index = 1,total = 1}
    gamedata.section = t.section
    for k,v in pairs(t.configtype) do
        local filepath = gWPath .. "config/"..t.section .. "/" .. v .. ".json"
        gamedata.config[v] = LoadJsonFileToTable(filepath)
        cclog("ui load %s", v);
        if extfunc[v] then extfunc[v]() end
    end
    if LoginScene.status then
        LoginScene:showDownloadProcess(t.rate or {type = "config", index = 1,total = 1})
    end

end