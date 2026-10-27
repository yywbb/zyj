

local CCHttpRequest = {
	
    requestTypeConfig = {
        [0] = "GET",
        [1] = "POST",
        [2] = "PUT",
        [3] = "DELETE",
    }

}

CCHttpRequest.__index = CCHttpRequest

function CCHttpRequest:new()
    local self = {___xxx = 222 }
    setmetatable(self, CCHttpRequest)

    return self
end

function CCHttpRequest.setUrl( self,Url )
	self.requestUrl = Url
end

function CCHttpRequest.setRequestType( self,requestType )
	self.requestType = self.requestTypeConfig[requestType]
end

function CCHttpRequest.registerScriptTapHandler( self,scriptTapHandler )
	self.scriptTapHandler = scriptTapHandler
end

function CCHttpRequest.setHeader( self,header )
	self.header = header
end

function CCHttpRequest.setRequestData( self,requestData )
	self.requestData = requestData
end

function CCHttpRequest.excute( self )
	if string.find(self.requestUrl,".zip") then
		self:excuteAsDownloader()
	else
		self:excuteAsRequest()
	end
end

function CCHttpRequest.excuteAsDownloader( self )

	local responseMeta = require"adpat_code/CCHttpResponse"
	response = responseMeta:new()

	response.scriptTapHandler = self.scriptTapHandler

	local download = DownloaderManager:getInstance()
    local _h = LuaEventHandler:create(function(fn, v)
        if fn == "error" then
            print("errCode "..v)        	
        	response.issucceed = false
        	response.errorBuffer = v
        	response.scriptTapHandler("",response)
        	
        elseif fn == "downloadSize" then
            print("downloading...  "..v)
			CCHttpClient:setDownloadSize(v)

        elseif fn == "success" then
            print("download success")
        	response.issucceed = true
        	response.dataBuffer = v
        	response.scriptTapHandler("",response)

        end
    end)
    download:setUrl(self.requestUrl)
    download:setDelegate(_h)
    download:start()
end


-- cc.XMLHTTPREQUEST_RESPONSE_STRING       = 0
-- cc.XMLHTTPREQUEST_RESPONSE_ARRAY_BUFFER = 1
-- cc.XMLHTTPREQUEST_RESPONSE_BLOB         = 2
-- cc.XMLHTTPREQUEST_RESPONSE_DOCUMENT     = 3
-- cc.XMLHTTPREQUEST_RESPONSE_JSON         = 4
function CCHttpRequest.excuteAsRequest( self )

    local responseMeta = require"adpat_code/CCHttpResponse"
    response = responseMeta:new()

    response.scriptTapHandler = self.scriptTapHandler


    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = 0 --responseType default string
    xhr:open(self.requestType, self.requestUrl)

    local function onReadyStateChanged()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            print("Http Status Code:" .. xhr.statusText)
            response.issucceed = true
            response.dataBuffer = xhr.response
            response.scriptTapHandler("",response)
        else
            print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
            response.issucceed = false
            response.errorBuffer = xhr.status
            response.scriptTapHandler("",response)
        end
        xhr:unregisterScriptHandler()
    end

    xhr:registerScriptHandler(onReadyStateChanged)
    
    if self.header then
        local spliteridx = string.find(self.header,":")

        xhr:setRequestHeader(string.sub(self.header,1,spliteridx-1),string.sub(self.header,spliteridx+2,string.len(self.header)))
    end

    if self.requestData then
        xhr:send(self.requestData)
    else
        xhr:send()
    end
end

function CCHttpRequest.release( self )
	self.requestUrl = nil
	self.requestType = nil
	self.scriptTapHandler = nil
	self.header = nil
	self.requestData = nil
end

return CCHttpRequest