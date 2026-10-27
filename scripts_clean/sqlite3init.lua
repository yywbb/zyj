--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-4-28
-- Time: 下午2:19
-- To change this template use File | Settings | File Templates.
--

require("sqlite3")

local function getOneResult(udata, cols, values, names)
    for i = 1, cols do print('', names[i], values[i]) end
    return 0
end

local function tableExists(db, tname)
    local SQL = string.format("select count(*) as texist from sqlite_master where type='table' and name='%s'", tname);
    local ret = 0
    for row in db:nrows(SQL) do
        ret = row["texist"]
    end
    if ret == 0 then
        return nil
    end
    return 1
end

function SQLite3Open()

    local path = CCFileUtils:sharedFileUtils():fullPathForFilename("sanguo.sqlite")
    local destpath = gWPath.."sanguo.sqlite"
    print("sqlite path: ",path)
    if path == "sanguo.sqlite" then
        path = destpath
    elseif path ~= destpath then
        CCDeviceModel:copyFile(path,destpath)
        CCFileUtils:sharedFileUtils():purgeCachedEntries()
        path = CCFileUtils:sharedFileUtils():fullPathForFilename("sanguo.sqlite")
    end
    print("sqlite path2: ",path)
    --log(string.format("SQLite3Open path:%s", path));
    local mydb, errcode = sqlite3.open(path)
    --print("sqlite3open mydb=", mydb, "errcode=", errcode)
    if nil == mydb then
        cclog("SQLite3Open sqlite3 error:%d", errcode);
        return nil;
    else
        --print("SQLite3Open success")
    end
    return mydb
end

function SQLite3Init()

    local mydb = SQLite3Open()
    if nil == mydb then
        return mydb
    end

    ---log("check ConfigInfo");
    if tableExists(mydb, "ConfigInfo") == nil then
        ---log("ConfigInfo not exist");
        ---local SQL = "CREATE TABLE IF NOT EXISTS ConfigInfo (ID INTEGER, TYPE TEXT, VersionNum INTEGER)";
        local SQL = "CREATE TABLE IF NOT EXISTS ConfigInfo (SECTION INTEGER, TYPE TEXT, VersionNum INTEGER)";
        mydb:exec(SQL)
        --log("ConfigInfo create");
    else
        ---log("ConfigInfo exist");
    end

    if tableExists(mydb, "ConfigVersion") == nil then
        local SQL = "CREATE TABLE IF NOT EXISTS ConfigVersion (Section INTEGER, VersionNum INTEGER)";
        mydb:exec(SQL)
    end  

    ---log("check ResourcesVersion");
    if tableExists(mydb, "ResourcesVersion") == nil then
        --log("ResourcesVersion not exist");
        local SQL = "CREATE TABLE IF NOT EXISTS ResourcesVersion (VersionNum INTEGER)";
        mydb:exec(SQL)
        --log("ResourcesVersion create");
    else
        ---log("ResourcesVersion exist");
    end

    if tableExists(mydb, "ServerListVersion") == nil then
        local SQL = "CREATE TABLE IF NOT EXISTS ServerListVersion (VersionNum INTEGER)";
        mydb:exec(SQL)
    end

    if tableExists(mydb, "ServerInfo") == nil then
        local SQL = "CREATE TABLE IF NOT EXISTS ServerInfo (id INTEGER, name TEXT, ip TEXT, port INTEGER)";
        mydb:exec(SQL)
    end

    ---log("check LocalInfoTable");
    if tableExists(mydb, "LocalInfoTable") == nil then
        --log("LocalInfoTable not exist");
        local SQL = "CREATE TABLE IF NOT EXISTS LocalInfoTable (KEY TEXT,VALUE TEXT)";
        mydb:exec(SQL)
        --log("LocalInfoTable create");

        SQL = "INSERT INTO LocalInfoTable (KEY,VALUE) VALUES ('music','true')"
        mydb:exec(SQL)
        SQL = "INSERT INTO LocalInfoTable (KEY,VALUE) VALUES ('sound','true')"
        mydb:exec(SQL)
    else
        ---log("LocalInfoTable exist");
    end

    if tableExists(mydb, "ErrorInfoTable") == nil then
        --log("ErrorInfoTable not exist");
        local SQL = "CREATE TABLE IF NOT EXISTS ErrorInfoTable (KEY TEXT,VALUE TEXT)";
        mydb:exec(SQL)
        --log("ErrorInfoTable create");

        SQL = "INSERT INTO ErrorInfoTable (KEY,VALUE) VALUES ('neterror','')"
        mydb:exec(SQL)
    else
        ---log("ErrorInfoTable exist");
    end




    mydb:close()
    return 1;
end

---SQLite3Init()

