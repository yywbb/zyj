--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 14-8-1
-- Time: 上午9:46
-- To change this template use File | Settings | File Templates.
--
require"Prompts"
require("localfile")
DOWNLOADLIST = {}
local DONWLOADURL = 0

local isbusy = false
local busytimer = nil

local function getUrlByInfo(download_info)
    local url_ = download_info.url
    if download_info.status == 2 or download_info.status == 4 or download_info.status == 6 or download_info.status == 8 then
        url_ = download_info.url
    elseif  download_info.status == 1 or download_info.status == 3 or download_info.status == 7 or download_info.status == 9 then
        url_ = download_info.urls.url2 or download_info.url
    else
        url_ = download_info.urls.url3 or download_info.url
    end
    return url_
end

local function HttpDownloadFile(url, callback)
    cclog("HttpDownloadFile url:%s", url)
    --print("startime========",os.time())
    DONWLOADURL = url
    local retry = 0
    local download_info = DOWNLOADLIST[url]
    local responseMethod,executeHttpDownload
    responseMethod =  function (tag,response)
        if not LoginScene or not LoginScene.status then return end
        print(tag,response:isSucceed(),response:getResponseCode())
        if not response:isSucceed() then
            print(response:getErrorBuffer())

            if LoginScene.status then
                if not isbusy then
                    if ui.isWiFI3G() ==0 then
                        runGamePrompt({msg = "网络连接中断..."})
                    elseif string.find(response:getErrorBuffer(),"timedout") or string.find(response:getErrorBuffer(),"timed out") then
                        download_info.status = download_info.status + 1 
                    else
                        --runGamePrompt({msg = "下载失败,重试中"})
                        download_info.status = download_info.status + 1 
                    end 
                    isbusy = true
                    busytimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
                        isbusy = false
                        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(busytimer)
                    end, 4, false)
                end
                executeHttpDownload(getUrlByInfo(download_info), download_info.status)
            else
                loading:exitGame(gameConfig.strings:string_common("loading",1))
                return
            end
        else
            --print("endtime========",os.time())
            callback(tag, response)
        end
    end
    executeHttpDownload = function(urlp, count)
        cclog("downloadexecute %s count %d", urlp, count or 0)
        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(urlp)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(5)
        local readtimeout = 10
        if count >= 6 then
            readtimeout = 50
        elseif count >= 2 then
            readtimeout = 20
        end
        CCHttpClient:getInstance():setTimeoutForRead(readtimeout)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end

    executeHttpDownload(getUrlByInfo(download_info),download_info.status)
end

local function DownloadFileWriteToPath(data, path)
    WriteFile(path, data)
end

local speedtimer = nil

local function startCheckSpeed()
    speedtimer = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
        local sizedownload = CCHttpClient:getInstance():getDownLoadSizeOfGet()
        local download_info = DOWNLOADLIST[DONWLOADURL]
        local sizedownKB = string.format("%0.1f",(sizedownload or 0)/1024)
        local totalKB = string.format("%0.1f",(download_info.len or 0)/1024)
        local total = ""--(totalKB=="0.0" and "" or "/"..totalKB.."KB")
        if download_info.filename then
            UIResponse({type = 9998, log2 = download_info.filename..download_info.status.." ("..sizedownKB.."KB"..total..")" })
        end
    end, 0, false)
end
local function stopCheckSpeed()
    if speedtimer then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(speedtimer)
    end
end

local errorlist = {}
function UIDownloadProxy(t)
    cclog("UI type:%d cmd:%s recv request from NET", t.type, "UIDownloadProxy")
    local url = t.url
    local urls = {url = t.url, url2 = t.url2, url3=t.url3}
    local path = t.file
    local rate = t.rate
    printT(urls,"download urls")
    DOWNLOADLIST[url] = {url=url, urls=urls, file=path, len = t.len, filename = t.filename,rate = rate, status=0}
    local function DownLoadCallback(tag, response)
        cclog("DownLoadCallback")
        local data = response:getResponseDataBuffer()
        print((DOWNLOADLIST[DONWLOADURL].len or "nolength"),DOWNLOADLIST[DONWLOADURL].file,string.len(data))

        if DOWNLOADLIST[DONWLOADURL].len and tonumber(DOWNLOADLIST[DONWLOADURL].len) and tonumber(DOWNLOADLIST[DONWLOADURL].len)>0 and string.len(data) ~= tonumber(DOWNLOADLIST[DONWLOADURL].len) then
            DOWNLOADLIST[DONWLOADURL].status = DOWNLOADLIST[DONWLOADURL].status + 1
            HttpDownloadFile( DONWLOADURL, DownLoadCallback)
        else

            DownloadFileWriteToPath(response:getResponseDataBuffer(), DOWNLOADLIST[DONWLOADURL].file)
            local Succeed = true
            if DOWNLOADLIST[DONWLOADURL].rate and DOWNLOADLIST[DONWLOADURL].rate.type == "resource" then
            else
                local path = DOWNLOADLIST[DONWLOADURL].file
                local filename = DOWNLOADLIST[DONWLOADURL].filename
                if not LoadJsonFileToTable(path) then
                    print("config error ",filename)
                    Succeed = false
                    errorlist[filename] = (errorlist[filename] or 0) +1
                    if errorlist[filename] >=4 then
                        Succeed = true
                        errorlist[filename] = 0
                    end
                else
                    print("config Succeed ",filename)
                end
            end
            if Succeed then
                require"UIRequest"
                UIRequest_({ type = 20, url=DONWLOADURL, file=DOWNLOADLIST[DONWLOADURL].file })

                DOWNLOADLIST[DONWLOADURL] = nil
                local nextdownload = next(DOWNLOADLIST)
                if nextdownload then
                    if LoginScene.status and rate then
                        LoginScene:showDownloadProcess(rate)
                    end
                    HttpDownloadFile( nextdownload, DownLoadCallback)
                else
                    stopCheckSpeed()
                end
            else
                DOWNLOADLIST[DONWLOADURL].status = DOWNLOADLIST[DONWLOADURL].status + 1
                HttpDownloadFile( DONWLOADURL, DownLoadCallback)
            end
        end
    end
    if DOWNLOADLIST and table.getTableLength(DOWNLOADLIST) == 1 then
        HttpDownloadFile(url,  DownLoadCallback)
        startCheckSpeed()
    end
end