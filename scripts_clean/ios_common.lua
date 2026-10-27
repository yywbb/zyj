--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 15/1/29
-- Time: 上午11:44
-- To change this template use File | Settings | File Templates.
--

local ios_common_data = {
    messageNum = 99,
    uid=nil,
    uuid=nil,
    ucid=nil,
}

function ios_common_data.Login(self)
    gamedata.ios_channelsdk:Login()
end


return ios_common_data