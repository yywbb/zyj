require "log"
local device = require"device"

local xsdk = {
    messageNum = 99,
    session = nil,
    userid = nil,
    nickname = nil,
}

--登录
function xsdk.Login( self )
    cclog("xsdk.Login")
    gamedata.ios_channelsdk:Login()
end

--登录平台
function  xsdk.LoginCB( self,uid,uuid,ucid )
    cclog("xsdk.LoginCB" .. uid .. " " .. uuid .. " " .. ucid);
    self.session = uuid;
    self.userid = ucid;
    self.nickname = uid;
    UIRequest({type = 90, nickname = self.nickname, sessionId = self.session, uin = self.userid, messageNum = self.messageNum, devicemodel = device.model,systemVersion = device:getsystemVersion()})

end

--判断是否登录
function xsdk.isLogin( self )
    if not self.uid then
        return true;
    else
        return false;
    end
end

--切换用户
function xsdk.changeUser(self)

end

--重新登录
function xsdk.reLogin( self )
    cclog("xsdk.reLogin");
    UIRequest({type = 90, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum});
end

function xsdk.Recharge( self, orderId, payAmount, goodsName, goodsDesc )

    gamedata.ios_channelsdk:Pay(orderId, payAmount, goodsName, goodsDesc);
end

return xsdk;
