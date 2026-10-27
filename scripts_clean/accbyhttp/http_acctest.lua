--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/8/29
-- Time: 下午1:59
-- To change this template use File | Settings | File Templates.
--

require("Prompts")
local http_acctest = {

    busytimer = nil,

    strings={
        [0] = "地址出错",
        [1] = "网络连接中断...",
        [2] = "请求超时...",
        [3] = "请求无响应",
        [4] = "请求出错",
    },
}

function http_acctest.runGamePrompt(self,dataTable)

    local promptLoaderLayer, ccbDocumentControler = CCBReaderLoad("Prompts/GamePrompt", nil, true, "GamePrompt")

    local openGLView = CCDirector:sharedDirector():getOpenGLView()
    local frameSize = openGLView:getFrameSize()

    promptLoaderLayer:setPosition(ccp(frameSize.width/2, frameSize.height * 0.618))
    ccbDocumentControler.node:setScale(frameSize.width/1080)

    local nowScene = CCDirector:sharedDirector():getRunningScene()
    nowScene:addChild(promptLoaderLayer,10000)

    local promptLabel = tolua.cast(ccbDocumentControler.promptLabel, "CCLabelTTF") --提示信息label
    promptLabel:setString(dataTable["msg"] or "")

    -------------------------------------------------------------------------------------------------------------------
    local animationManager = getAnimationManager(ccbDocumentControler)
    --动画完成操作
    animationManager:setAnimationCompletedCallback(function()
    --移除
        promptLoaderLayer:removeFromParentAndCleanup(true)
    end)
    --先播放动画
    animationManager:runAnimationsForSequenceNamed("prompt")
end

function http_acctest.loginsucess( self,responsedata )

    local data = {
        type = 3,
        user = responsedata.result.user,
        uid = responsedata.result.uid,
        session = responsedata.result.session,
        first = responsedata.result.first,
        serverlist = {}, 
        recentlist = {}
    }
    cclog("最近登录的用户名：%s", data.user)

    local path = CCFileUtils:sharedFileUtils():fullPathForFilename("GameServer.json")
    local ServerInfo = LoadJsonFileToTable(path)

    local alllist = {}
    for k, v in pairs(ServerInfo) do
        local serverdata = responsedata.result.serverlist[k]

        if serverdata then
            if serverdata.status == "offline" or serverdata.status == "fault" then

            else
                local defaut = {
                    id=v.id,
                    status=serverdata.status,
                    tag = serverdata.tag,
                    name=v.name,
                    ip=v.ip,
                    port=v.port,
                }      
                table.insert(data.serverlist, defaut)    
                alllist[v.id] = defaut                          
            end
        else
            local defaut = {
                id=v.id,
                status="online",
                tag = "new",
                name=v.name,
                ip=v.ip,
                port=v.port,
            }

            table.insert(data.serverlist, defaut)    
            alllist[v.id] = defaut                             
        end
    end

    for k, v in ipairs(responsedata.result.recentlist) do
        if alllist[v.id] then
            table.insert(data.recentlist, alllist[v.id])
            cclog("最近登陆的服务器id为: %s ", v.id)
        end
    end

    local sort = function( a,b )
        return a.id>b.id
    end
    table.sort(data.serverlist,sort)

    UIResponse(data)    
end

function http_acctest.deviceStr( self,str )
    local step = 1
    local len = #str
    print("len====",len)

    local newstr = ""

    local firstbyte = {
        [1] = 0,
        [2] = 192,
        [3] = 224,
        [4] = 240,
        [5] = 248,
        [6] = 252,
    }

    while step <= len do
        local byte = tonumber(string.byte(string.sub(str,step,step)))
        local bytenum = 1
        if byte<=127 then
            bytenum = 1
        elseif byte>=192 and byte<=223 then
            bytenum = 2
        elseif byte>=224 and byte<=239 then
            bytenum = 3
        elseif byte>=240 and byte<=247 then
            bytenum = 4
        elseif byte>=248 and byte<=251 then
            bytenum = 5
        elseif byte>=252 and byte<=253 then
            bytenum = 6
        end

        step = step + bytenum

        local needfilter = false

        if (byte>=40 and byte<=41) or (byte>=48 and byte<=57) or (byte>=65 and byte<=90) or (byte>=97 and byte<=122) then
        else
            needfilter = true
        end


        local showstr = needfilter and "" or string.sub(str,step-bytenum,step-1)
        print("showstr==",showstr,"realstr=",string.sub(str,step-bytenum,step-1),"unicode==",unicode)

        local temp = newstr
        temp = temp..showstr
        newstr = temp
    end

    return newstr
end

function http_acctest.autologin(self)

    self.geturl = gamedata.sdk.address.autologinAddress
    if not self.geturl or self.geturl == "" then 
        self:runGamePrompt({msg = self.strings[0]})
        return 
    end
    
    local responseMethod,executeHttpPost
    responseMethod =  function(tag,response)

        local success = true
        if not response:isSucceed() then
            cclog("post %s error msg:%s", self.geturl, response:getErrorBuffer())

            if ui.isWiFI3G() ==0 then
                self:runGamePrompt({msg = self.strings[1]})
            elseif string.find(response:getErrorBuffer(),"timedout") or string.find(response:getErrorBuffer(),"timed out") then
                self:runGamePrompt({msg = self.strings[2]})
            else
                self:runGamePrompt({msg = self.strings[4]})
            end 
            success = false
        else
            if not response:getResponseDataBuffer() then
                self:runGamePrompt({msg = self.strings[3]})
                success = false
            else
                require"myjson"
                print("getResponseDataBuffer",response:getResponseDataBuffer())
                local responsedata = LoadJsonStringToTable(response:getResponseDataBuffer())

                if not responsedata then
                    self:runGamePrompt({msg = self.strings[4]})
                    success = false
                else
                    printT(responsedata)
                    if not responsedata.success or responsedata.success == "false" then
                        self:runGamePrompt({msg = responsedata.msg or self.strings[4]})
                        success = false
                    else

                        self:loginsucess(responsedata)
                    end                    
                end
            end
        end
    end

    executeHttpPost = function()

        local timestamp = os.time_ and os.time_() or os.time()

        local device = "device="..self:deviceStr(gamedata.device.model)    
        local os = "&os="..gamedata.device.platform     
        local uuid = "&uuid="..gamedata.device.getOpenUDID()
        local version = "&version="..gamedata.device.getsystemVersion()

        local requestdata = device..os.."&timestamp="..timestamp..uuid..version
        
        require"mymd5"
        local md5code = md5sumhexa(requestdata)

        local requesturl = self.geturl.."?"..requestdata.."&sign="..md5code
        print("autologin requestdata",requesturl)

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(requesturl)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(10)
        CCHttpClient:getInstance():setTimeoutForRead(10)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    executeHttpPost()

    return true
end

function http_acctest.userrigist(self,params)

    self.geturl = gamedata.sdk.address.testrigistAddress
    if not self.geturl or self.geturl == "" then 
        self:runGamePrompt({msg = self.strings[0]})
        return 
    end
    
    local responseMethod,executeHttpPost
    responseMethod =  function(tag,response)

        local success = true
        if not response:isSucceed() then
            cclog("post %s error msg:%s", self.geturl, response:getErrorBuffer())

            if ui.isWiFI3G() ==0 then
                self:runGamePrompt({msg = self.strings[1]})
            elseif string.find(response:getErrorBuffer(),"timedout") or string.find(response:getErrorBuffer(),"timed out") then
                self:runGamePrompt({msg = self.strings[2]})
            else
                self:runGamePrompt({msg = self.strings[4]})
            end 
            success = false
        else
            if not response:getResponseDataBuffer() then
                self:runGamePrompt({msg = self.strings[3]})
                success = false
            else
                require"myjson"
                print("getResponseDataBuffer",response:getResponseDataBuffer())
                local responsedata = LoadJsonStringToTable(response:getResponseDataBuffer())

                if not responsedata then
                    self:runGamePrompt({msg = self.strings[4]})
                    success = false
                else
                    printT(responsedata)
                    if not responsedata.success or responsedata.success == "false" then
                        self:runGamePrompt({msg = responsedata.msg or self.strings[4]})
                        success = false
                    else
                        UIResponse({type = 10,uid = responsedata.result.uid,result = true})
                    end                    
                end
            end
        end
    end

    executeHttpPost = function()

        local timestamp = os.time_ and os.time_() or os.time()

        local requestdata = "account="..params.account.."&password="..params.password.."&timestamp="..timestamp
        
        require"mymd5"
        local md5code = md5sumhexa(requestdata)

        local requesturl = self.geturl.."?"..requestdata.."&sign="..md5code
        print("testrigist requestdata",requesturl)

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(requesturl)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(10)
        CCHttpClient:getInstance():setTimeoutForRead(10)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    executeHttpPost()

    return true
end

function http_acctest.userlogin(self,params)

    self.geturl = gamedata.sdk.address.testloginAddress
    if not self.geturl or self.geturl == "" then 
        self:runGamePrompt({msg = self.strings[0]})
        return 
    end
    
    local responseMethod,executeHttpPost
    responseMethod =  function(tag,response)

        local success = true
        if not response:isSucceed() then
            cclog("post %s error msg:%s", self.geturl, response:getErrorBuffer())

            if ui.isWiFI3G() ==0 then
                self:runGamePrompt({msg = self.strings[1]})
            elseif string.find(response:getErrorBuffer(),"timedout") or string.find(response:getErrorBuffer(),"timed out") then
                self:runGamePrompt({msg = self.strings[2]})
            else
                self:runGamePrompt({msg = self.strings[4]})
            end 
            success = false
        else
            if not response:getResponseDataBuffer() then
                self:runGamePrompt({msg = self.strings[3]})
                success = false
            else
                require"myjson"
                print("getResponseDataBuffer",response:getResponseDataBuffer())
                local responsedata = LoadJsonStringToTable(response:getResponseDataBuffer())

                if not responsedata then
                    self:runGamePrompt({msg = self.strings[4]})
                    success = false
                else
                    printT(responsedata)
                    if not responsedata.success or responsedata.success == "false" then
                        self:runGamePrompt({msg = responsedata.msg or self.strings[4]})
                        success = false
                    else

                        UIResponse({type = 11,uid = responsedata.result.uid,result = true})
                    end                    
                end
            end
        end
    end

    executeHttpPost = function()

        local timestamp = os.time_ and os.time_() or os.time()

        local requestdata = "account="..params.account.."&password="..params.password.."&timestamp="..timestamp
        
        require"mymd5"
        local md5code = md5sumhexa(requestdata)

        local requesturl = self.geturl.."?"..requestdata.."&sign="..md5code
        print("testlogin requestdata",requesturl)

        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(requesturl)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(10)
        CCHttpClient:getInstance():setTimeoutForRead(10)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    executeHttpPost()

    return true
end


return http_acctest

