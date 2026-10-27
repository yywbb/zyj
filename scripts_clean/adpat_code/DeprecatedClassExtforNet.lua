
cc = cc or {}

local CCDeviceModel = {}

function CCDeviceModel.unzipfile( self,zippath,writepath,overwrite )
    local zipfileutil = require("zipfileutil")
    zipfileutil.unzip(zippath,writepath)
end

_G["CCDeviceModel"] = CCDeviceModel


--functions of CCFileUtils will be deprecated end
local CCDeprecated = { }

function CCDeprecated.CCFileUtils()
    return MyFileUtilsForNet
end
_G["CCFileUtils"] = CCDeprecated.CCFileUtils()

function CCDeprecated.sharedFileUtils()
    return MyFileUtilsForNet:getInstance()
end
_G["CCFileUtils"].sharedFileUtils = CCDeprecated.sharedFileUtils

function CCDeprecated.purgeFileUtils()
    return MyFileUtilsForNet:destroyInstance()
end
_G["CCFileUtils"].purgeFileUtils = CCDeprecated.purgeFileUtils
--functions of CCFileUtils will be deprecated end



_G["CCString"] = require "adpat_code.CCStringForNet"