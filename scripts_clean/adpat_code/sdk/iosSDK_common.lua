--公共的iosSDK的接口

require "log"
local device = require"device"

local iosSDK_common = {
    messageNum = 99,
    session = nil,
    userid = nil,
    nickname = nil,
}

--登录
function iosSDK_common.Login(self)
    cclog("SDK.Login")
    UIResponse({type = 9998, log = "渠道登录..." })
    gamedata.ios_channelsdk:Login()
end

--平台登录游戏
function iosSDK_common.LoginCB(self,uid,uuid,ucid)
    cclog("iosSDK_common.LoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuid, ucid)
    -- cclog("SDK.LoginCB:\nuid = " .. uid .. "\nuuid = " .. uuid .. "\nucid = " .. ucid);
    self.session = uuid
    self.userid = ucid
    self.nickname = uid

     UIReponse({ type = 901, nickname = self.nickname, sessionId = self.session, uin = self.userid})

end

--秒针检测创建角色的
function iosSDK_common.CreateRole(self,name)
    cclog("SDK.CreateRole")
    gamedata.ios_channelsdk:CreateRole(name)
end


function iosSDK_common.forceUpdate(self)
    cclog("iosSDK_common.forceUpdate: ")
    gamedata.ios_channelsdk:forceUpdate()
end

function iosSDK_common.forceUpdateWithUrl(self,url)
    cclog("iosSDK_common.forceUpdateWithUrl: ")
    gamedata.ios_channelsdk:forceUpdateWithUrl(url)
end

function iosSDK_common.loginAccountSuc(self,uid)
    cclog("iosSDK_common.loginAccountSuc:  uid=  %s ", uid)
    gamedata.ios_channelsdk:loginAccountSuc(uid)
end

function iosSDK_common.LoginToken(self,token)
    cclog("iosSDK_common.token:  token=  %s ", token)
    gamedata.ios_channelsdk:LoginToken(guid)
end

--判断是否登录
function iosSDK_common.isLogin(self)
    if not self.uid then
        return true
    else
        return false
    end
end

--切换用户
function iosSDK_common.changeUser(self)

    gamedata.ios_channelsdk:changeUser()
    
end

--重新登录
function iosSDK_common.reLogin(self)
    cclog("iosSDK_common.reLogin")

end

--玩家的基本信息
function iosSDK_common.UserInformationAllData(self, roleId, rolenName, roleLv, serverId, serverName, vip, gold, ext1, ext2, ext3)
    cclog("iosSDK_common.UserInformationAllData %d    %s    %d    %d     %s",roleId,rolenName,roleLv,serverId,serverName)
    gamedata.ios_channelsdk:UserInformation(roleId,rolenName,roleLv,serverId,serverName,vip,gold,ext1,ext2,ext3)

end

--分享结果
function iosSDK_common.ShareResult( self,shResult )

end 

--支付
function iosSDK_common.RechargeAllData(self, orderId, payAmount, goodsName, goodsDesc, gold, goodsId, parma1, parma2, parma3, parma4, parma5, parma6)
    
    gamedata.ios_channelsdk:Pay(orderId, payAmount, goodsName, goodsDesc, gold,goodsId,parma1,parma2,parma3,parma4,parma5,parma6)
end

function iosSDK_common.BtnChannelLogin(self)
     gamedata.ios_channelsdk:BtnChannelLogin()
end

function iosSDK_common.majiaBuy(self, productid)
     gamedata.ios_channelsdk:buyMaJiaGold(productid)
end

function iosSDK_common.getMaJiaGold(self)
     return gamedata.ios_channelsdk:getMaJiaGold()
end

function iosSDK_common.openHP(self)
     return gamedata.ios_channelsdk:openHP()
end

--实名认证状态sdk登录成功会自动调用  -1未查询到信息   0 未实名  1 实名的未成年  2 实名的成年
function iosSDK_common.SaveIDCard(self, idcardstatus)
     cclog("iosSDK_common.saveIDCard:  idcardstatus=  %s ", idcardstatus)
     self.idCardStatus  = idcardstatus
     UIReponse({ type = 902, idCardStatus = self.idCardStatus })
end

--实名认证成功通知 1 实名的未成年  2 实名的成年
function iosSDK_common.idCardSuccess(self,updateIdcardStatus)
    cclog("iosSDK_common idCardSuccess 实名认证成功回调")
    self.idCardStatus  = updateIdcardStatus
    UIReponse({ type = 902, idCardStatus = self.idCardStatus })
    --其他更新操作
end

--跳入实名认证
function iosSDK_common.toIDCard(self)
      gamedata.ios_channelsdk:toIDCard()
end

--登录相关状态重置
function iosSDK_common.loginOutStatusRest(self)
     gamedata.ios_channelsdk:loginOutStatusRest()
end


return iosSDK_common
