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
function iosSDK_common.LoginCB(self,uid,uuid,ucid,channelid,channelname)
    cclog("iosSDK_common.LoginCB:  uid=  %s   uuid= %s    ucid= %s", uid, uuid, ucid)
    -- cclog("SDK.LoginCB:\nuid = " .. uid .. "\nuuid = " .. uuid .. "\nucid = " .. ucid);
    self.session = uuid
    self.userid = ucid
    self.nickname = uid

    self.channelid = channelid
    self.channelname = channelname
    if self.channelid and self.channelid ~= "" then 
        self.channelid = tonumber(self.channelid)
    end   

    -- if device.channel == "chujiani" or device.channel == "chujianii" or device.channel == "qingyuanmy" or device.channel == "qingyuanhy" or device.channel == "anqusw"
    --  or device.channel == "tutufk" or device.channel == "anquxy" or device.channel == "anquyjl" or device.channel == "anquyjd" or device.channel == "tuturx" or device.channel == "tutukps" or device.channel == "gavegame" 
    --   or device.channel == "tutukpx"  or device.channel == "tutumh" or device.channel == "hanfengbx" or device.channel == "hanfengqm"  or device.channel == "hanfengfg"  or device.channel == "hanfengdq" 
    --    or device.channel == "hanfengmw"  or device.channel == "hanfengbg" or device.channel == "jingxunmw" or device.channel == "jingxunmy" or device.channel == "jingxunlt" or device.channel == "9377" or device.channel == "9377jj" 
    --    or device.channel == "9377bym" or device.channel == "9377bys" or device.channel == "9377wd" or device.channel == "jingxunfs" or device.channel == "jingxunyj" or device.channel == "jingxunltc" or device.channel == "jingxundh" 
    --    or device.channel == "anfengbz" or device.channel == "anfengsw" or device.channel == "hanfengsg" or device.channel == "hanfengls" or device.channel == "asm8" or device.channel == "tutuhlw" or device.channel == "tutuhlx"
    --    or device.channel == "jingxunyq" or device.channel == "cyxfs" or device.channel == "hanfengyj" or device.channel == "hanfengfk" or device.channel == "hanfengzl" or device.channel == "cyxxy" or device.channel == "cyxdn" 
    --    or device.channel == "jingxunbz"  or device.channel == "anfengfk" or device.channel == "anfengjj" or device.channel == "hanfengsn" or device.channel == "hanfengsgk" or device.channel == "muyouios" or device.channel == "jingxunxyj" 
    --    or device.channel == "anfengswhd" or device.channel == "wanmiios" or device.channel == "asm8my" or device.channel == "anfengsgy" or device.channel == "9377jmf" or device.channel == "9377mfb" or device.channel == "9377wsx" 
    --    or device.channel == "anqunewfk" or device.channel == "anqurxn" or device.channel == "anqurnewmh" or device.channel == "anqunewhlx" or device.channel == "anqunewhlw" 
    --    or device.channel == "hanfengkp" or device.channel == "hanfengxy" or device.channel == "asm8yj"  or device.channel == "anfengwd" then
        UIRequest({type = 900000, nickname = self.nickname, sessionId = self.session, uin = self.userid, messageNum = self.messageNum, devicemodel = device.model,systemVersion = device:getsystemVersion(), channelid = self.channelid  ,channelname = self.channelname})
    -- else
    --     UIRequest({type = 90, nickname = self.nickname, sessionId = self.session, uin = self.userid, messageNum = self.messageNum, devicemodel = device.model,systemVersion = device:getsystemVersion()})
    -- end
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

function iosSDK_common.loginGuid(self,guid)
    cclog("iosSDK_common.loginGuid:  guid=  %s ", guid)
    gamedata.ios_channelsdk:loginGuid(guid)
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
    -- if  device.channel == "chujiani" or device.channel == "chujianii" or device.channel == "qingyuanmy" or device.channel == "qingyuanhy" or device.channel == "anqusw"
    --  or device.channel == "tutufk" or device.channel == "anquxy" or device.channel == "anquyjl" or device.channel == "anquyjd" or device.channel == "tuturx" or device.channel == "tutukps" or device.channel == "gavegame" 
    --  or device.channel == "tutukpx"  or device.channel == "tutumh" or device.channel == "hanfengbx" or device.channel == "hanfengqm"  or device.channel == "hanfengfg"  or device.channel == "hanfengdq" 
    --    or device.channel == "hanfengmw"  or device.channel == "hanfengbg" or device.channel == "jingxunmw" or device.channel == "jingxunmy" or device.channel == "jingxunlt" or device.channel == "9377" or device.channel == "9377jj" 
    --    or device.channel == "9377bym" or device.channel == "9377bys" or device.channel == "9377wd" or device.channel == "jingxunfs" or device.channel == "jingxunyj" or device.channel == "jingxunltc" or device.channel == "jingxundh" 
    --    or device.channel == "anfengbz" or device.channel == "anfengsw" or device.channel == "hanfengsg" or device.channel == "hanfengls" or device.channel == "asm8" or device.channel == "tutuhlw" or device.channel == "tutuhlx" 
    --    or device.channel == "jingxunyq" or device.channel == "cyxfs" or device.channel == "hanfengyj" or device.channel == "hanfengfk" or device.channel == "hanfengzl" or device.channel == "cyxxy" or device.channel == "cyxdn" 
    --    or device.channel == "jingxunbz" or device.channel == "anfengfk" or device.channel == "anfengjj" or device.channel == "hanfengsn" or device.channel == "hanfengsgk" or device.channel == "muyouios" or device.channel == "jingxunxyj"
    --    or device.channel == "anfengswhd" or device.channel == "wanmiios" or device.channel == "asm8my"  or device.channel == "anfengsgy"  or device.channel == "9377jmf" or device.channel == "9377mfb" or device.channel == "9377wsx" 
    --    or device.channel == "anqunewfk" or device.channel == "anqurxn" or device.channel == "anqurnewmh" or device.channel == "anqunewhlx" or device.channel == "anqunewhlw" 
    --    or device.channel == "hanfengkp" or device.channel == "hanfengxy" or device.channel == "asm8yj"  or device.channel == "anfengwd" then 
        UIRequest({type = 900000, nickname = self.nickname, sessionId = self.session, uin = self.userid, messageNum = self.messageNum, devicemodel = device.model,systemVersion = device:getsystemVersion(),channelid = self.channelid  ,channelname = self.channelname})
    -- else
    --     UIRequest({type = 90, nickname = self.nickname, sessionId = self.session, uin = self.userid, messageNum = self.messageNum, devicemodel = device.model,systemVersion = device:getsystemVersion()})
    -- end

end

--玩家的基本信息
function iosSDK_common.UserInformation(self,roleId,rolenName,roleLv,serverId,serverName)
    cclog("iosSDK_common.UserInformation %d    %s    %d    %d     %s",roleId,rolenName,roleLv,serverId,serverName)
    gamedata.ios_channelsdk:UserInformation(roleId,rolenName,roleLv,serverId,serverName)

end

function iosSDK_common.UserInformation19(self, roleId, rolenName, roleLv, serverId, serverName, vip, usergold)
   gamedata.ios_channelsdk:UserInformation19(roleId,rolenName,roleLv,serverId,serverName,vip,usergold)
end

--分享结果
function iosSDK_common.ShareResult( self,shResult )

end 

--支付
function iosSDK_common.Recharge(self, orderId, payAmount, goodsName, goodsDesc)
    
    gamedata.ios_channelsdk:Pay(orderId, payAmount, goodsName, goodsDesc)
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

return iosSDK_common
