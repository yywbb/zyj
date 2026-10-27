--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 13-4-28
-- Time: 上午11:37
-- To change this template use File | Settings | File Templates.
--

require("pack")
require("log")
require("sqlite3init")
local myfile = require("myfile")
require("localfile")
local sectionresource_pb = require("sectionresource_pb");
require("GameDownloadProxy")
require("UIRequest")
function SQLite3ResourceVersion()
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end
    local ret = 0
    local SQL = "SELECT VersionNum FROM ResourcesVersion"
    for row in mydb:nrows(SQL) do
        ---print("VersionNUm:"..row["VersionNum"])
        ret=row["VersionNum"]
    end
    if ret == 0 then
        SQL = "INSERT INTO ResourcesVersion VALUES (0)"
        mydb:exec(SQL)
        ---log(string.format("sqlite err in syncresource: %s",mydb:errmsg()));
    end
    mydb:close()
    return ret
end

function SQLite3UpdateResourceVersion(version)
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end

    local SQL = "UPDATE ResourcesVersion set VersionNum="..version
    mydb:exec(SQL)
    ---log(string.format("sqlite err:%s",mydb:errmsg()));
    mydb:close()
end

local RESOURCES = {}
local params_pb = require"params_pb"
local ids_pb = require"ids_pb"

function Step1SyncResource(fd)
    UIResponse({type = 9998,  log = "获取服务器状态..." })

    local event = {}
    local params_pb = require"params_pb"
    local params1 = params_pb.ParamS()
    local req = params1.params:add()
    req.i=gamedata.gameconfig.forceupdate or 1   
    req.s=gamedata.gameconfig.channel..(gamedata.sdk.channelid or "")

    print("获取服务器状态",gamedata.gameconfig.channel,gamedata.sdk.channelid)

    local ret2 = ReqResponse(fd,params1:SerializeToString(),990080)
    if nil == ret2 then
        return nil
    end
    local params = params_pb.ParamS()
    params:ParseFromString(fd.rbuf)
    cclog("NET type:%d cmd:%s recv request from UI", 990080, "EventPost")

    if params.params[1] then
        event = {
            title = params.params[1].s,
            content = params.params[2].s,
            begint = params.params[3].i,
            endt = params.params[4].i,
            opt = params.params[5].i,
            url = params.params[6].s,
            servertime = params.params[7] and (params.params[7].i or 0) or 0,
        }
    end
    printT(event,"event")

    UIResponse({type = 9998, log = "检查更新...." })

    local localresver = SQLite3ResourceVersion()
    local ret = nil
    print("localresver = ",localresver,"type:",type(localresver))

    local versiondata = params_pb.ParamS()
    local resreq = versiondata.params:add()
    local deviceApi = require"device"
    if deviceApi.platform == "android" then
        resreq.i = localresver + 2^30
    else
        resreq.i = localresver
    end

    resreq.s = gamedata.gameconfig.channel..(gamedata.sdk.channelid or "").."_"..gamedata.gameconfig.submit
    local resreq2bit = versiondata:SerializeToString()
    ret = ReqResponse(fd,resreq2bit,990003)

    if nil == ret then
        return nil
    end

    local resource = sectionresource_pb.SectionResource()
    resource:ParseFromString(fd.rbuf)
    local serverresver = resource.version
    local length =  resource.length

    log(string.format("resource version server %s local %s",serverresver,localresver));
    if localresver ~= serverresver then
        ResourceDownload.need = true
        --todo
        print("resource.needrestart",resource.needrestart)
        ResourceDownload.needrestart = resource.needrestart

        RESOURCES = resource.resources
        ResourceDownload.version = serverresver
    else
        ---log("Resource version is same, Resource Ok");
    end

    UIResponse({type = 9998, log = "检查更新....." })

    if not ResourceDownload.need and not next(event) then
        UIResponse({type=888888})
        return 0
    else
        UIResponse({type=80, event = event, needupdate = ResourceDownload.need,length = length})
    end

    return 1
end


function UIContinueSysresourceCallBack()
    cclog("NET type:%d cmd:%s recv request from UI", 81, "EventPost")

    if ResourceDownload.need then
        for k,v in ipairs(RESOURCES) do
            log(string.format("k:%s",k))
            ---log(string.format("filename:%s len:%s data:%s",v.filename, v.length, v.value));
            local len = v.urls[3]
            log(string.format("ResourceDownload data url:%s file:%s len:%s",v.url, v.file,(len or "nolength")))

            local file = gWPath..v.file
            log(string.format("file %s",file));
            local filedir  = getDirOfPath(file)
            log(string.format("mkdir %s",filedir));
            myfile.mkdir(filedir);
            ---WriteFile(filepath,v.value)

            local url = v.url
            local lenofurls = #(v.urls)
            local url2,url3
            if lenofurls >= 1 then
                url2 = v.urls[1]
                if lenofurls >= 2 then
                    url3 = v.urls[2]
                end
            end
            ResourceDownload.dict[url] = {url=url, file=file, url2=url2, url3=url3,len = len,}
            UIReponse({ type = 20 , url=url, url2=url2, url3=url3, file=file, len = len, rate = {type = "resource", num = k,total = #RESOURCES}})
        end
        RESOURCES = {}
    else
        UIResponse({type=888888})
        return 999
    end
    return nil
end

log("loading syncresource");