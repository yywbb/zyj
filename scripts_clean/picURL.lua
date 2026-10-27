
require"log"
local myfile = require("myfile")
local picURL = {
    picpath = "UI/public/icons/",
    active = false,
    
    picTag = {
        jpg = "FF D8 ",
        png = "89 50 4E 47 0D 0A 1A 0A ",
    }
}

picURL.__index = picURL

-- param = {
--    url = "",  图片下载地址
--    userid = ，用户id
--    sprite = , 显示头像的sprite对象
-- }

function picURL:init(param)
    local self = {___xxx = 222}
    setmetatable(self, picURL)

    self.param = param

    return self
end

function picURL:setPic()
    if not self.param.url or not self.param.userid or not self.param.sprite then return end
    
    local spritetemp = CCSprite:create(gWPath..self.picpath..self.picname)

    if spritetemp then 
        local o_size = spritetemp:getContentSize()
        local scale = math.min(150/o_size.width,150/o_size.height)
        self.param.sprite:setDisplayFrame(spritetemp:displayFrame())
        self.param.sprite:setScale(scale)
    end
end

function picURL:downloadPic()
    self.active = true
    local responseMethod,executeHttpDownload
    responseMethod =  function (tag,response)
        cclog("CHttpResponse-----%s %s %s %s", tag, response, response:isSucceed(), response:getResponseCode())
        if not response:isSucceed() then
            cclog("download %s error msg:%s", self.url, response:getErrorBuffer())

            if self.active then
                executeHttpDownload()
            end
        else
            self:writePic(response:getResponseDataBuffer())
            if self.active then
                self:setPic()
            end
        end
    end
    executeHttpDownload = function()
        local httpReq = CCHttpRequest:new()
        httpReq:setUrl(self.param.url)
        httpReq:setRequestType(0)

        httpReq:registerScriptTapHandler(responseMethod)
        CCHttpClient:getInstance():setTimeoutForConnect(5)
        CCHttpClient:getInstance():setTimeoutForRead(5)
        CCHttpClient:getInstance():send(httpReq)
        httpReq:release()
    end
    executeHttpDownload()
end 

function picURL:checkPicFormat(picdata)
    local headdata = string.gsub(string.sub(picdata,1,8),"(.)",function (x) return string.format("%02X ",string.byte(x)) end)

    for k,v in pairs(self.picTag) do
        if v == string.sub(headdata,1,string.len(v)) then
            return k
        end
    end

    return nil
end

function picURL:writePic(picdata)
    myfile.mkdir(gWPath.."UI")
    myfile.mkdir(gWPath.."UI/public")
    myfile.mkdir(gWPath.."UI/public/icons")
    
    local picformat = self:checkPicFormat(picdata)
    if picformat then
        self.picname = self.param.userid.."_icon."..picformat
        WriteFile(gWPath..self.picpath..self.picname, picdata)
    end
end

function picURL:clear()
    self.active = false
end

return picURL
