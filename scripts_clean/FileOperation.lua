--
-- Created by IntelliJ IDEA.
-- User: liliang
-- Date: 13-5-24
-- Time: 上午10:09
-- To change this template use File | Settings | File Templates.
--

local file = {}
local util = require"cjson.util"
local myfile = require"myfile"

--创建文件夹
function file.file_mkdir(dir)
	myfile.mkdir(gWPath .. "resource/" .. dir)
end

--读文件
function file.file_read(fileName)
	return util.file_load(CCFileUtils:sharedFileUtils():fullPathFromRelativePath(fileName))
end

--写文件
function file.file_write(fileName)
	local file = file.file_read(fileName)
	util.file_save(gWPath .. "resource/" .. fileName, file)
end

function file.isFileExist(fileName)
	if (util.file_load(gWPath .. fileName) == nil) then
		return false
	end
	return true
end

return file