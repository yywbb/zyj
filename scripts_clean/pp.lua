require "log"
local device = require"device"
--require "gamedata"
local pp = {
    messageNum = 99,
    session = nil,
    userid = nil,
    nickname = nil,
}

--登录
function pp.Login( self )
    cclog("pp.Login")
    gamedata.ios_channelsdk:Login()
end

--登录平台
function  pp.LoginCB( self,uid,uuid,ucid )
    cclog("pp.LoginCB" .. uid .. " " .. uuid .. " " .. ucid);
    self.session = uuid;
    self.userid = ucid;
    self.nickname = uid;
    UIRequest({type = 90, nickname = self.nickname, sessionId = self.session, uin = self.userid, messageNum = self.messageNum, devicemodel = device.model,systemVersion = device:getsystemVersion()})

end

--判断是否登录
function pp.isLogin( self )
    if not self.uid then
        return true;
    else
        return false;
    end
end

--切换用户
function pp.changeUser(self)

end

--重新登录
function pp.reLogin( self )
    cclog("pp.reLogin");
    UIRequest({type = 90, nickname = self.uid, sessionId = self.uuid, uin = self.ucid, messageNum = self.messageNum});
end

function pp.Recharge( self, orderId, payAmount, goodsName, goodsDesc )
    if not GameScene.guid or GameScene.guid == "" then
        cclog("pp_guid is nil")
        return
    end

    cclog("Recharge pp_guid: " .. GameScene.guid)
    gamedata.ios_channelsdk:Pay(orderId, payAmount, goodsName, GameScene.guid);
end

--分享
function pp.showShare(self)

end

return pp;
