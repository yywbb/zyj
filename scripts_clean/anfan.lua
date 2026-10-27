--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/1/5
-- Time: 下午4:48
-- To change this template use File | Settings | File Templates.
--
require"log"
local anfan_sdk = {
    messageNum = 99,
    uid=nil,
    uuid=nil,
    ucid=nil,
}
function anfan_sdk.Login(self)
    local luaj = require"luaj"
    --local javaClassName = "com.ldfs.sanguo.AnfanUtils"
    --local javaClassName = "com/ldfs/sanguo/AnfanUtils"
    local javaClassName = "com/ldfs/sanguo/AnfanUtils"
    local javaMethodName = "Login"
    local javaMethodSig = "()V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
end

function anfan_sdk.LoginCB(self,uid, uuid, ucid)
    cclog("anfan_sdk.LoginCB "..uid.." "..uuid.." "..ucid)
    self.uid = uid
    self.uuid = uuid
    self.ucid = ucid
    UIRequest({type=90, nickname=self.uid, sessionId=self.uuid, uin=self.ucid, messageNum=self.messageNum})
end


function anfan_sdk.isLogin(self)
    if not self.uid then
        return true
    else
        return false
    end
end

function anfan_sdk.reLogin(self)
    cclog("anfan_sdk.reLogin")
    UIRequest({type=90, nickname=self.uid, sessionId=self.uuid, uin=self.ucid, messageNum=self.messageNum})
end

function anfan_sdk.changeUser(self)
    local luaj = require"luaj"
    --local javaClassName = "com.ldfs.sanguo.AnfanUtils"
    --local javaClassName = "com/ldfs/sanguo/AnfanUtils"
    local javaClassName = "com/ldfs/sanguo/AnfanUtils"
    local javaMethodName = "ChangeUser"
    local javaMethodSig = "()V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
end

function anfan_sdk.Recharge(self, orderId, payAmount, goodsName, goodsDesc)
    cclog("anfan_sdk.Recharge %d %f %s %s", orderId, payAmount, goodsName, goodsDesc)
    local luaj = require"luaj"
    --local javaClassName = "com.ldfs.sanguo.AnfanUtils"
    --local javaClassName = "com/ldfs/sanguo/AnfanUtils"
    local javaClassName = "com/ldfs/sanguo/AnfanUtils"
    local javaMethodName = "Pay"
    local javaParams = {string.format("%d",orderId), payAmount, goodsName, goodsDesc}
    local javaMethodSig = "(Ljava/lang/String;FLjava/lang/String;Ljava/lang/String;)V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
end

--分享
function anfan_sdk.showShare(self)
    local luaj = require"luaj"
    --local javaClassName = "com.ldfs.sanguo.AnfanUtils"
    --local javaClassName = "com/ldfs/sanguo/AnfanUtils"
    local javaClassName = "com/ldfs/sanguo2/AnfanUtils"
    local javaMethodName = "showShare"
    local javaMethodSig = "()V"
    luaj.callStaticMethod(javaClassName, javaMethodName, javaParams, javaMethodSig)
end


return anfan_sdk