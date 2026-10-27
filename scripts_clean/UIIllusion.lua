--
-- Author: songyibo
-- Date: 2020-09-08 16:19:02
--
function UIIllusionQuery(t)
    printT(t,"8110 幻化查询")
    GameScene.layers["illusion"].module:reloaddata(t.data)
end


function UIIllusionExe(t)
    printT(t,"8111 幻化")
    if GameScene.layers["illusion"].show then
        GameScene.layers["illusion"].module:reloaddata(t.data)
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)

    UIRequest({type = 10023})
end


function UIIllusionCancel(t)
    printT(t,"8112 解除幻化")
    if GameScene.layers["illusion"].show then
        GameScene.layers["illusion"].module:reloaddata(t.data)
    end

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)

    UIRequest({type = 10023})
end

function UIIllusionActivityQuery(t)
    printT(t,"8113 幻化活动查询")
    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[175] and GameScene.layers["activity"].module.pageTable[175].module and GameScene.layers["activity"].module.pageTable[175].module.show then
        GameScene.layers["activity"].module.pageTable[175].module:reloaddata(t)
    end
end

function UIIllusionActivityReward(t)
    printT(t,"8114 幻化活动领奖")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[175] and GameScene.layers["activity"].module.pageTable[175].module and GameScene.layers["activity"].module.pageTable[175].module.show then
        UIRequest({type = 8113})
    end
end

function UIIllusionActivityQueryX1(t)
    printT(t,"8115 幻化活动查询")
    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[176] and GameScene.layers["activity"].module.pageTable[176].module and GameScene.layers["activity"].module.pageTable[176].module.show then
        GameScene.layers["activity"].module.pageTable[176].module:reloaddata(t)
    end
end

function UIIllusionActivityRewardX1(t)
    printT(t,"8116 幻化活动领奖")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[176] and GameScene.layers["activity"].module.pageTable[176].module and GameScene.layers["activity"].module.pageTable[176].module.show then
        UIRequest({type = 8115})
    end
end

function UIIllusionActivityTaskQuery(t)
    printT(t,"8117 幻化馆查询")
    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[177] and GameScene.layers["activity"].module.pageTable[177].module and GameScene.layers["activity"].module.pageTable[177].module.show then
        GameScene.layers["activity"].module.pageTable[177].module:reloaddata(t)
    end
end

function UIIllusionActivityTaskReward(t)
    printT(t,"8118 幻化馆领奖")

    if t.reward then
        showRewardPopupWindow(t.reward,nil)
    end

    if GameScene.layers["activity"] and GameScene.layers["activity"].module and GameScene.layers["activity"].module.pageTable[177] and GameScene.layers["activity"].module.pageTable[177].module and GameScene.layers["activity"].module.pageTable[177].module.show then
        UIRequest({type = 8117})
    end
    UIRequest({type = 1001})
end

function clearIllusionToSqlite()
    local mydb = SQLite3Open()
    if nil == mydb then
        return 0
    end
    local SQL = "DROP TABLE IF EXISTS IllusionHint";
    mydb:exec(SQL)
    mydb:close()
    print("clearIllusionToSqlite")
end


function saveIllusionToSqlite(cid,endtime)
    print("saveIllusionToSqlite",cid,endtime)

    local rid = GameScene.roleinfo.id or 0
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
    if rid < 1000000 then
        rid = serverid*1000000 + rid
    end    
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end
    local SQL = "UPDATE IllusionHint SET illusion_endtime=".. endtime .. " WHERE rid=" .. rid .. " AND illusion_cid="..cid
    mydb:exec(SQL)
    if (mydb:changes() == 0) then
        SQL = string.format("INSERT INTO IllusionHint (rid,illusion_cid,illusion_endtime) VALUES (%d,%d,%d)",rid,cid,endtime)
        mydb:exec(SQL)
    end
    mydb:close()
end
--
function getIllsionFromSqlite()
    if not GameScene.roleinfo then
        return {}
    end
    print("getIllsionFromSqlite")
    local illusionHints = {}
    local rid = GameScene.roleinfo.id or 0
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
    if rid < 1000000 then
        rid = serverid*1000000 + rid
    end    
    local mydb = SQLite3Open()
    if nil == mydb then
        return {}
    end
    local SQL = "SELECT count(*) AS pftexist FROM sqlite_master WHERE type='table' AND name='IllusionHint'"
    local ret = 0
    for row in mydb:nrows(SQL) do
        ret = row["pftexist"]
    end
    if ret == 0 then
        local SQL = "CREATE TABLE IF NOT EXISTS IllusionHint (rid INTEGER, illusion_cid INTEGER, illusion_endtime INTEGER)";
        mydb:exec(SQL)
        return {}
    end
    local SQL = "SELECT * FROM IllusionHint WHERE rid=" .. rid
    for row in mydb:rows(SQL) do
        local cid = row[2] or 0
        local endtime = row[3] or 0
        illusionHints[cid] = {cid = cid,endtime = endtime}
        break
    end
    mydb:close()
    return illusionHints
end