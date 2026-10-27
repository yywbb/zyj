--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/6/10
-- Time: 17:03
-- To change this template use File | Settings | File Templates.
--


local startactivityhelp = {
    rootNode = nil,
    rootItems = nil,
}

function startactivityhelp.open(self,touchPriority,data,callback)
    self.rootNode, self.rootItems = CCBReaderLoad("start2/n_kaifuqiri_help", nil, true, "kaifuqiri_help")

    self.touchPriority = touchPriority
    self:reload(data,callback)

    return self.rootNode
end

function startactivityhelp.reload(self,data,callback)
    self.callback = callback

    local taskconfig = gamedata.config.begin7day_task or {}
    local dayconfig = gamedata.config.begin7day or {}

    local showid = 10404
    if taskconfig["80007"].show and taskconfig["80007"].show > 0 then
        showid = taskconfig["80007"].show
    end
    self.rootItems.generalname:setString(gamedata.config.general[tostring(showid)].name)

    self.rootItems["generalNode"]:removeAllChildrenWithCleanup(true)
    local generalName = gamedata.config.generalanimation[tostring(ui.IDconfig(showid).animationid)].name
    local Gneral1 = CCSkeletonAnimation:create(generalName.."/"..generalName..".json",generalName.."/"..generalName..".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1.5)
    Gneral1:setPosition(0,0)
    self.rootItems["generalNode"]:addChild(Gneral1)

    ui.setLabelString(self.rootItems.title,nil,21)
    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("startactivityhelp")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("startactivityhelp")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    --
    local dayconfig1 = {}
    for k,v in pairs(dayconfig) do
        table.insert(dayconfig1,v)
    end

    local sortByDay = function(a,b) return a["1"].day < b["1"].day end
    table.sort(dayconfig1, sortByDay)

    local targets = {}
    for k,v in ipairs(dayconfig1) do
        for kk,vv in pairs(v) do
            if tostring(kk) == "4" then
                if vv["task1"] and vv["task1"] > 0 then
                    table.insert(targets,taskconfig[tostring(vv["task1"])])
                end
            end
        end
    end

    for i = 1,7 do
        local discount = ui.Split(targets[i].discount or "", ";")
        local sale = ui.Split(discount[1] or "", ",")

        local target = ui.Split(targets[i].target or "", ";")
        local reward = ui.Split(target[1] or "", ",")
        if reward[1] and reward[1]+0 > 0 then
            self.rootItems["desc"..i]:setString("第"..i.."天： "..(gamedata.config.props[tostring(reward[1])].name or "").."，最低折限"..sale[2].."人购买")
        end
    end
end

function startactivityhelp.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return startactivityhelp