--
-- Author: songyibo
-- Date: 2020-05-12 14:54:02
--

local chengzhangjiahuaUp = {
    rootNode = nil,
    rootItems = nil,
    input_cdk = nil,
    inputcontent = "",
}

function chengzhangjiahuaUp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("activityreward_new/tc_chengzhangjihua", nil, true, "tc_chengzhangjihua")
    self.touchPriority = touchPriority

    self.activityid = data.activityid
    self:reload(data,callback)
    return self.rootNode
end

function chengzhangjiahuaUp.reload(self,data,callback)
    self.callback = callback

    local bannerName = "chengzhangjihua_spr1"
    local titleName = "chengzhangjihuastage"
    if self.activityid == 149 then
        bannerName = "chengzhangjihua_spr1"
        titleName = "chengzhangjihuastage"
    elseif self.activityid == 178 then
        bannerName = "jiyuanjihua_banner2"
        titleName = "jiyuanjihuastage"
    elseif self.activityid == 179 then
        bannerName = "xianyuanjihua_banner2"
        titleName = "xianyuanjihuastage"
    end

    setSpriteFrameByName(self.rootItems.banner, bannerName)
    setSpriteFrameByName(self.rootItems.title, titleName..data.stage)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        gameWindows:closeWindow("chengzhangjihuaUp")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)
    ui.setLabelString(self.rootItems.doLab,nil,19)
end

function chengzhangjiahuaUp.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return chengzhangjiahuaUp