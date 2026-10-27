

local CCHttpResponse = {
	

}

CCHttpResponse.__index = CCHttpResponse

function CCHttpResponse:new()
    local self = {___xxx = 222 }
    setmetatable(self, CCHttpResponse)

    return self
end

function CCHttpResponse.isSucceed( self )
    return self.issucceed
end

function CCHttpResponse.getResponseDataBuffer( self )
    return self.dataBuffer
end

function CCHttpResponse.getErrorBuffer( self )
    return self.errorBuffer
end

function CCHttpResponse.getResponseCode( self )
	--占位用，无意义
    return 123
end

return CCHttpResponse