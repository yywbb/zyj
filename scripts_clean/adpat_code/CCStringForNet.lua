

local CCString = {
	
}

CCString.__index = CCString

function CCString:createWithContentsOfFileforNet(jsonfile)
    local self = {___xxx = 222 }
    setmetatable(self, CCString)

    self.content = MyFileUtilsForNet:getInstance():getFileData(jsonfile,"rb")

    return self
end

function CCString:createWithContentsOfFile(jsonfile)
    local self = {___xxx = 222 }
    setmetatable(self, CCString)

    self.content = MyFileUtilsForNet:getInstance():getFileData(jsonfile,"rb")

    return self
end

function CCString.getCString( self )
    return self.content
end

return CCString