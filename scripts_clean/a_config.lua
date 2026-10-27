--
-- Created by IntelliJ IDEA.
-- User: lichungeng
-- Date: 16/5/19
-- Time: 下午5:39
-- To change this template use File | Settings | File Templates.
--

local config = {
   config = {},
}

function config.init(self)
    if not next(self.config) then
        require"myjson"
        local path = CCFileUtils:sharedFileUtils():fullPathForFilename("config.json")
        self.config = LoadJsonFileToTable(path)
    end
end

config:init()

return config

