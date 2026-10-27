--
-- Created by IntelliJ IDEA.
-- User: caoxiang
-- Date: 15/6/19
-- Time: 下午1:21
-- To change this template use File | Settings | File Templates.
--

--通关奖励
local levelReward = {
    rootNode = nil,
    rootItems = nil,
}

function levelReward.open(self,touchPriority,data,callback)
    self.rootNode,self.rootItems = CCBReaderLoad("copy/tc_tongguanjiangli",nil,true,"tc_tongguanjiangli");
    self.touchPriority = touchPriority;
    self:reload(data,callback);

    if guide.controller then
        guide.controller:setGuideLayerVisible(true)
    end

    return self.rootNode;
end

function levelReward.reload(self,data,callback)
    self.callback = callback;

    -- self.rootItems.mapname:setString("第" .. gameConfig.strings.bigNum[data.mapID] .. "关   " .. data.config.name);
    self.rootItems.mapname:setString(gameConfig.strings:lvNum(gameConfig.strings.bigNum[data.mapID],data.config.name));
    ui.setLabelString(self.rootItems.mapname,nil,21)

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        guide:setGuideProlayer(true)
        gameWindows:closeWindow("levelReward")

    end,CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true);
    self.rootItems.closeButton:setTouchPriority(self.touchPriority);

    local nowpoint = table.getTableLength(data.points);
    if data.points[tostring(nowpoint)].star > 0 then
        self.rootItems.pointnum:setString(nowpoint .. "/" .. data.totalpoint);
    else
        self.rootItems.pointnum:setString((nowpoint - 1) .. "/" .. data.totalpoint);
    end

    local prop = {
        [1] = {},
        [2] = {},
        [3] = {},
    }
    prop[1].cid, prop[1].num = ui.getIDandNUM(data.config["prestige-reward"]);
    prop[2].cid, prop[2].num = ui.getIDandNUM(data.config["prestige-rewardv6"]);
    prop[3].cid, prop[3].num = ui.getIDandNUM(data.config["prestige-rewardv12"]);

    for i =1, 3 do
        local config = ui.IDconfig(prop[i].cid);
        ui.setNewIconName(self.rootItems,{ name = config.name, num = prop[i].num, cid = prop[i].cid},i-1);
        self.rootItems["getbutton" .. i]:setSwallowsTouch(true);
        self.rootItems["getbutton"..i]:setTouchPriority(self.touchPriority);

        self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
            ui.setPopwindowByCid(prop[i].cid)
         end, CCControlEventTouchUpInside)
        self.rootItems["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(self.touchPriority);
    end

    self:resetprestigeReward(data)
end

function levelReward.resetprestigeReward(self,data)
    for i=1, 3 do
        if data["pa"..i] == 1 then
            -- self.rootItems["gettext"..i]:setString("领取")
            self.rootItems["gettext"..i]:setString(gameConfig.strings:string_common("moreCommon",6))
            self.rootItems["getbutton"..i]:addHandleOfControlEvent(function()
                print("getbutton")
                -- runGamePrompt({msg = "未通关"})
                 runGamePrompt({msg = gameConfig.strings:string_common("moreCommon","weitongguan")})

            end, CCControlEventTouchUpInside)
            ui.addGray("CCControlButton", self.rootItems["getbutton"..i])
            ui.addGray("CCLabelTTF",self.rootItems["gettext"..i])
        elseif data["pa"..i] == 2 then
            if GameScene.roleinfo.vip < 3*(i-1) then
                -- self.rootItems["gettext"..i]:setString("领取")
                self.rootItems["gettext"..i]:setString(gameConfig.strings:string_common("moreCommon",6))
                self.rootItems["getbutton"..i]:addHandleOfControlEvent(function()
                    print("getbutton")
                    shortVip()
                end, CCControlEventTouchUpInside)
                ui.addGray("CCControlButton", self.rootItems["getbutton"..i])
                ui.addGray("CCLabelTTF",self.rootItems["gettext"..i])
            else
                -- self.rootItems["gettext"..i]:setString("领取")
                self.rootItems["gettext"..i]:setString(gameConfig.strings:string_common("moreCommon",6))
                self.rootItems["getbutton"..i]:addHandleOfControlEvent(function()
                    print("getbutton")
                    UIRequest({type = data.copytype=="normal" and 1304 or 1334, map = data.id, method = 3*(i-1)})
                end, CCControlEventTouchUpInside)
                ui.removeGray("CCControlButton", self.rootItems["getbutton"..i])
                ui.removeGray("CCLabelTTF",self.rootItems["gettext"..i])
            end
        elseif data["pa"..i] == 3 then
            -- self.rootItems["gettext"..i]:setString("已领取")
            self.rootItems["gettext"..i]:setString(gameConfig.strings:string_common("moreCommon",5))
            self.rootItems["getbutton"..i]:addHandleOfControlEvent(function()
                print("getbutton")
                -- runGamePrompt({msg = "已领取"})
                runGamePrompt({msg = gameConfig.strings:string_common("moreCommon",5)})
            end, CCControlEventTouchUpInside)
            ui.addGray("CCControlButton", self.rootItems["getbutton"..i])
            ui.addGray("CCLabelTTF",self.rootItems["gettext"..i])
        end
        ui.setLabelString(self.rootItems["gettext"..i],nil,18)
    end

end



function levelReward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true);
    self.rootNode:removeFromParentAndCleanup(true);
    self.rootNode = nil;
    self.rootItems = nil;
    if self.callback then
        self.callback();
    end
    if guide.controller then
        guide.controller:UIComplete(8046)
    end
end

return levelReward;












