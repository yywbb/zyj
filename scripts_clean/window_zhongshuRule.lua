--
-- Created by Lipurpose.
-- User: f
-- Date: 19/4/2018
-- Time: 18:26
-- To change this template use File | Settings | File Templates.
--

local zhongshuRule = {
    rootNode = nil,
    rootItems = nil,
}

function zhongshuRule.open(self,touchPriority,data,callback)
    
    self.rootNode, self.rootItems = CCBReaderLoad("zhongshu/zhongshu_rule", nil, true, "zhongshu_rule")
    
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function zhongshuRule.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("zhongshuRule")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


    -- local strT = {
    --     {fontID = 905,content = "1.活动开启期间，玩家可通过消耗水滴浇灌树苗获得灌溉积分与道具奖励。"},
    --     {fontID = 905,content = "2.完成任务即可获得水滴，也可通过点击当前拥有水滴处的“+”进行购买。"},
    --     {fontID = 905,content = "3.浇灌树苗时，每消耗10滴水滴，即可获得一次随机道具奖励。"},
    --     {fontID = 905,content = "4.累计积分到达一定分数时，可领取相应档位的宝箱奖励。"},
    --     {fontID = 905,content = "5.每日可领取5次水滴任务奖励，领取次数每日0点重置。"},
    --     {fontID = 905,content = "6.当日水滴任务奖励领取次数用完后，也可继续完成任务，任务进度将被保存，奖励可于次日进行领取。"},
    --     {fontID = 905,content = "7.玩家可消耗元宝刷新水滴任务，刷新任务时只会刷新出未接取的任务，已接取的任务在被完成前不会刷新。"},
    --     {fontID = 905,content = "8.累计灌溉积分到达5000即可进入排行榜，排名越高，获得奖励越丰厚。"},
    --     {fontID = 905,content = "9.活动最后一天24点结算灌溉排行榜排名，奖励通过邮件形式发放。"},
    --     {fontID = 905,content = "10.活动结束后，“水滴”道具不会消失。"},
    -- }

     -- ui.createRichLabel(strT,self.rootItems.richnode,true)
    if gamedata.config.system_intro["59"] then
        self.rootItems.desc:setString(gamedata.config.system_intro["59"].intro)
    end
    
end

function zhongshuRule.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return zhongshuRule