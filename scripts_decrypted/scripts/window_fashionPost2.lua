
local fashionPost2 = {
    rootNode = nil,
    rootItems = nil,

    cancelTip = "fashion",
}

function fashionPost2.open(self,touchPriority,data,callback)
    if data and data.opt and data.opt == 3 then
        self.rootNode, self.rootItems = CCBReaderLoad("activityshengdan/shengdanpost", nil, true, "post2")
    else
        self.rootNode, self.rootItems = CCBReaderLoad("shizhuang/shizhuang_post2", nil, true, "post2")
        --



        if self.rootItems.changebg1 and self.rootItems.changebg2 and GameScene.layers["activity"].module.dailyCpActivityTimeStatus[52] then

            local cpnum = GameScene.layers["activity"].module.dailyCpActivityTimeStatus[52].cpnum or 0
            --单数火影 双数pantkill
            if cpnum%2 == 1 then
                self.rootItems.changebg2:setVisible(true)
                self.rootItems.changebg1:setVisible(false)
                if self.rootItems.changebg3 then
                    self.rootItems.changebg3:setVisible(false)
                end
                if self.rootItems.changebg4 then
                    self.rootItems.changebg4:setVisible(false)
                end
                if self.rootItems.changebg5 then
                    self.rootItems.changebg5:setVisible(false)
                end
                if self.rootItems.changebg6 then
                    self.rootItems.changebg6:setVisible(false)
                end
            else
                self.rootItems.changebg2:setVisible(false)
                self.rootItems.changebg1:setVisible(true)
                if self.rootItems.changebg3 then
                    self.rootItems.changebg3:setVisible(false)
                end
                if self.rootItems.changebg4 then
                    self.rootItems.changebg4:setVisible(false)
                end
                if self.rootItems.changebg5 then
                    self.rootItems.changebg5:setVisible(false)
                end
                if self.rootItems.changebg6 then
                    self.rootItems.changebg6:setVisible(false)
                end
            end

            -- if gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_chunjie" then
            --     self.rootItems.changebg2:setVisible(false)
            --     self.rootItems.changebg1:setVisible(false)
            --     if self.rootItems.changebg3 then
            --         self.rootItems.changebg3:setVisible(false)
            --     end
            --     if self.rootItems.changebg4 then
            --         self.rootItems.changebg4:setVisible(false)
            --     end
            --     if self.rootItems.changebg5 then
            --         self.rootItems.changebg5:setVisible(false)
            --     end
            --     if self.rootItems.changebg6 then
            --         self.rootItems.changebg6:setVisible(true)
            --     end
            -- elseif gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_shengdan" then
            --     self.rootItems.changebg2:setVisible(false)
            --     self.rootItems.changebg1:setVisible(false)
            --     if self.rootItems.changebg3 then
            --         self.rootItems.changebg3:setVisible(false)
            --     end
            --     if self.rootItems.changebg4 then
            --         self.rootItems.changebg4:setVisible(false)
            --     end
            --     if self.rootItems.changebg5 then
            --         self.rootItems.changebg5:setVisible(true)
            --     end
            --     if self.rootItems.changebg6 then
            --         self.rootItems.changebg6:setVisible(false)
            --     end
            -- elseif gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_shamate" then
            --     self.rootItems.changebg2:setVisible(false)
            --     self.rootItems.changebg1:setVisible(false)
            --     if self.rootItems.changebg3 then
            --         self.rootItems.changebg3:setVisible(false)
            --     end
            --     if self.rootItems.changebg4 then
            --         self.rootItems.changebg4:setVisible(true)
            --     end
            --     if self.rootItems.changebg5 then
            --         self.rootItems.changebg5:setVisible(false)
            --     end
            --     if self.rootItems.changebg6 then
            --         self.rootItems.changebg6:setVisible(false)
            --     end
            -- elseif gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_xiaodingdang" then
            --     self.rootItems.changebg2:setVisible(false)
            --     self.rootItems.changebg1:setVisible(false)
            --     if self.rootItems.changebg3 then
            --         self.rootItems.changebg3:setVisible(true)
            --     end
            --     if self.rootItems.changebg4 then
            --         self.rootItems.changebg4:setVisible(false)
            --     end
            --     if self.rootItems.changebg5 then
            --         self.rootItems.changebg5:setVisible(false)
            --     end
            --     if self.rootItems.changebg6 then
            --         self.rootItems.changebg6:setVisible(false)
            --     end
            -- elseif gamedata.config.activity_time["52"] and gamedata.config.activity_time["52"].icon and gamedata.config.activity_time["52"].icon == "activity_huoying" then
            --     self.rootItems.changebg2:setVisible(true)
            --     self.rootItems.changebg1:setVisible(false)
            --     if self.rootItems.changebg3 then
            --         self.rootItems.changebg3:setVisible(false)
            --     end
            --     if self.rootItems.changebg4 then
            --         self.rootItems.changebg4:setVisible(false)
            --     end
            --     if self.rootItems.changebg5 then
            --         self.rootItems.changebg5:setVisible(false)
            --     end
            --     if self.rootItems.changebg6 then
            --         self.rootItems.changebg6:setVisible(false)
            --     end
            -- else
            --     self.rootItems.changebg2:setVisible(false)
            --     self.rootItems.changebg1:setVisible(true)
            --     if self.rootItems.changebg3 then
            --         self.rootItems.changebg3:setVisible(false)
            --     end
            --     if self.rootItems.changebg4 then
            --         self.rootItems.changebg4:setVisible(false)
            --     end
            --     if self.rootItems.changebg5 then
            --         self.rootItems.changebg5:setVisible(false)
            --     end
            --     if self.rootItems.changebg6 then
            --         self.rootItems.changebg6:setVisible(false)
            --     end
            -- end
        end


    end
    self.touchPriority = touchPriority
    self:reload(data,callback)
    return self.rootNode
end

function fashionPost2.reload(self,data,callback)
    self.callback = callback
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("fashionPost2")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    self.rootItems.gotoButton:addHandleOfControlEvent(function()
        --self.callback = nil
        gameWindows:closeWindowDirect("fashionPost2")
        if GameScene.cp_fashionactivity2 and GameScene.cp_fashionactivity2 == 1 then
            GameScene:shiftLayerById(320)
        elseif data and data.opt and data.opt == 3 then
            GameScene:shiftLayerById(256)
        else
            GameScene:shiftLayerById(208)
        end
    end, CCControlEventTouchUpInside)
    self.rootItems.gotoButton:setSwallowsTouch(true)
    self.rootItems.gotoButton:setTouchPriority(self.touchPriority-1)

    ui.setLabelString(self.rootItems.gotoLab,nil,19)
    --

end

function fashionPost2.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
    if self.callback then
        self.callback()
    end
end

return fashionPost2

  :"  