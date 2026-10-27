--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 14-8-1
-- Time: 上午10:19
-- To change this template use File | Settings | File Templates.
--

ResourceDownload = {
    need = false,
    version = 0,
    dict = {},
    needrestart = true,
}

ConfigDownload = {
    need = false,
    dict = {}
}

function UIDownloadProxyCallback(uireq)
    cclog("NET type:%d cmd:%s recv request from UI", 20, "UIDownloadProxyCallback")
    cclog("url:%s file:%s", uireq.url, uireq.file)
    if ResourceDownload.need then
        cclog("resource download complete")
        ResourceDownload.dict[uireq.url] = nil
        if next(ResourceDownload.dict) == nil then
            CCFileUtils:sharedFileUtils():purgeCachedEntries()
            ResourceDownload.need = false
            SQLite3UpdateResourceVersion(ResourceDownload.version)
            if CCFileUtils:sharedFileUtils():fullPathForFilename("config_version.lua") ~= "config_version.lua" then
                UIResponse({type = 9998, version = require("config_version.lua").gameversion.."."..ResourceDownload.version })
            end
            if ResourceDownload.needrestart then
                UIResponse({type=8888883})
            else
                UIResponse({type=888888})
            end
            return 999
        end
    end
    if ConfigDownload.need then
        local info = ConfigDownload.dict[uireq.url]
        if info ~= nil then
            CCFileUtils:sharedFileUtils():purgeCachedEntries()
            SQLite3UpdateConfigVersion(info.section, info.type, info.version)

            if LoadJsonFileToTableforNet then
                gamedata.config[info.type] = LoadJsonFileToTableforNet(uireq.file)
            else
                gamedata.config[info.type] = LoadJsonFileToTable(uireq.file)
            end

            UIupdateConfig(info.type)
            ConfigDownload.dict[uireq.url] = nil
            if next(ConfigDownload.dict) == nil then
                cclog("config download complete")
                ResourceDownload.need = false
                if Netloadconfig() then
                    return 0,4,{type = 4}
                else
                    return 0,503,{type = 503, msgtype = "restartgame",msg = "配置文件损坏，请重启游戏更新配置文件。如问题仍存在请删除游戏并重新下载安装。"}
                end
            end
        end
    end
    return nil
end
