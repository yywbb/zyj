local CCFileUtils = {
}


function CCFileUtils.sharedFileUtils()
	return CCFileUtils
end

function CCFileUtils.addSearchPath(self,path)
	cc.FileUtils:getInstance():addSearchPath(path)
end

function CCFileUtils.fullPathForFilename(self,path)
	local _path = cc.FileUtils:getInstance():fullPathForFilename(path)
	if _path == "" then
		return path
	else
		return _path
	end
end

function CCFileUtils.purgeCachedEntries(self)
	cc.FileUtils:getInstance():purgeCachedEntries()
end

function CCFileUtils.purgeFileUtils(self)
	cc.FileUtils:getInstance():destroyInstance()
end

return CCFileUtils