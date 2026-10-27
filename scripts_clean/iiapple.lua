--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/4/24
-- Time: 下午1:58
-- To change this template use File | Settings | File Templates.
--

--
require"log"
local iiapple_sdk = {
    messageNum = 99,
    session = nil,
    userid = nil,
    nickname = nil
}
function iiapple_sdk.Login(self)
    cclog("iiapple_sdk.Login")
    gamedata.ios_channelsdk:Login()
end

function iiapple_sdk.LoginCB(self,uid, uuid, ucid)
    cclog("iiapple_sdk.LoginCB "..uid.." "..uuid.." "..ucid)
    self.session = uuid
    self.userid = ucid
    self.nickname = uid
    UIRequest({type=90, nickname=self.nickname, sessionId=self.session, uin=self.userid, messageNum=self.messageNum})
end


function iiapple_sdk.isLogin(self)
    if not self.uid then
        return true
    else
        return false
    end
end

function iiapple_sdk.reLogin(self)
    cclog("iiapple_sdk.reLogin")
    UIRequest({type=90, nickname=self.uid, sessionId=self.uuid, uin=self.ucid, messageNum=self.messageNum})
end

function iiapple_sdk.changeUser(self)

end

function iiapple_sdk.Recharge(self, orderId, payAmount, goodsName, goodsDesc)
    gamedata.ios_channelsdk:Pay(orderId, payAmount, goodsName, goodsDesc)
end


return iiapple_sdk