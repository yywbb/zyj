--
-- Author: songyibo
-- Date: 2018-07-23 15:46:32
--

local TestHttp = class("TestHttp", function ()
    return cc.Layer:create()
end)


function TestHttp:ctor()
    self.progress = cc.Label:createWithSystemFont("Hello World", "Arial", 40)
    self.progress:setPosition(display.cx, display.cy + 200)
    self:addChild(self.progress)



    local function menuCallback(sender)
        -- self:download()
        self:http()
    end
    
    local  item = cc.MenuItemImage:create("HelloWorld.png", "HelloWorld.png")
    item:registerScriptTapHandler(menuCallback)

    local  menu = cc.Menu:create()
    menu:setPosition(cc.p(display.cx,display.cy))
    menu:addChild(item)
    self:addChild(menu)
    
    
end

function TestHttp:http()
    local responseMethod,executeHttpDownload
    responseMethod =  function (tag,response)
        print("CHttpResponse-----")
        if not response:isSucceed() then
            print("CHttpResponse----- fail")

            --executeHttpDownload()
        else
            print("CHttpResponse----- sucess")
            self:downloadcomplete(response:getResponseDataBuffer())
        end
    end
    executeHttpDownload = function()

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl("http://127.0.0.1:8080/account_server/test.zip")
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(3)

        CCHttpClient:getInstance():setTimeoutForRead(3)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    executeHttpDownload()
end

function TestHttp:download()
    local packageUrl = "http://127.0.0.1:8080/account_server/test.zip"
    local storagePath = cc.FileUtils:getInstance():getWritablePath().."download.zip"

    local download = DownloaderManager:getInstance()
    local _h = LuaEventHandler:create(function(fn, v)
        if fn == "error" then
            print("errCode "..v)
            download:start()
        elseif fn == "progress" then
            print("downloading...  "..v)
            self.progress:setString("progress "..v)
        elseif fn == "success" then
            print("download success")
            if v then
                self:downloadcomplete(v)
            end
        end
    end)
    download:setUrl(packageUrl)
    download:setDelegate(_h)
    download:start()
end

function TestHttp:downloadcomplete(data)
    print("downloadcomplete")

    local storagePath = cc.FileUtils:getInstance():getWritablePath()
    local filepath = storagePath.."download.zip"
    local filehandle = io.open(filepath,"wb")
    if nil ~= filehandle then
        filehandle:write(data)
        filehandle:close()
    else

    end
    print(filepath)
end

function HttpTestMain()
    print("EditBoxTestMain")
    local scene = cc.Scene:create()
    scene:addChild(TestHttp.new())
    scene:addChild(CreateBackMenuItem())
    return scene
end

