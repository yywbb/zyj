
local wudaohui_pipei = {
    rootNode = nil,
    rootItems = nil,
}

function wudaohui_pipei.open(self,touchPriority,data,callback)
    printT(data,"pipei_open")
    self.touchPriority = touchPriority

    if data.index == "rule" then
        self.rootNode, self.rootItems = CCBReaderLoad("wudaohui/wudaohui_rule", nil, true, "wudaohui_rule")
        self:ruleReload()
    elseif data.index == "pipei" then
        self.rootNode, self.rootItems = CCBReaderLoad("wudaohui/wudaohui_pipei", nil, true, "wudaohui_pipei")
        self:reload(data)
        -- UIRequest({type = 4101,id = 0})
    end
    
    
    return self.rootNode
end



function wudaohui_pipei.ruleReload(self)
    self.rootItems.closeButton:addHandleOfControlEvent(function()
        gameWindows:closeWindowDirect("wudaohuipipei")

    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)


end

function wudaohui_pipei.reload(self,data,callback)
    print("wudaohui.reload===")
    self.data = data


    self.rootItems.delynumLabel:setVisible(false)

    self.rootItems.pipeiLabel:setString("正在匹配...")

    self.rootItems.leftNode:removeAllChildrenWithCleanup(true)
    self.rootItems.rightNode:removeAllChildrenWithCleanup(true)
    
    local mowang = gamedata.config.generalanimation[tostring(14224)].name

    local Gneral1 = CCSkeletonAnimation:create(mowang.."/"..mowang..".json",mowang.."/"..mowang..".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(1)
    self.rootItems.leftNode:addChild(Gneral1)

    local Gneral2 = CCSkeletonAnimation:create(mowang.."/"..mowang..".json",mowang.."/"..mowang..".atlas",1)
    Gneral2:setAnimation("stand",true,0)
    Gneral2:setScaleX(-1)
    -- Gneral2:setScaleY(0.8)
    self.rootItems.rightNode:addChild(Gneral2)
    

    self:setSuccessData(self.data.data)
    -- ui.setLabelString(self.rootItems.cancelText,nil,19)
    -- self.rootItems.cancelBtn:addHandleOfControlEvent(function()
    --     gameWindows:closeWindowDirect("wudaohuipipei")
    --     UIRequest({type = 4101,id = 1})
    -- end, CCControlEventTouchUpInside)
    -- self.rootItems.cancelBtn:setSwallowsTouch(true)
    -- self.rootItems.cancelBtn:setTouchPriority(self.touchPriority)

    -- self:setActionPlay()
    -- self:updatetime()
end




function wudaohui_pipei.updatetime(self)
    gameTimer:rigistTime("wudaohui_pipei", 20)
    gameTimer:rigistTimeFunc("wudaohui_pipei",function()
        
        if gameTimer.times["wudaohui_pipei"] >= 0 then
            -- ui.setLabelString(self.rootItems.noticeTimeLabel,ui.makeTimeText(gameTimer.times["wudaohui_pipei"],"hour"),21)
            print("1111111====",ui.makeTimeText(gameTimer.times["wudaohui_pipei"],"hour"))
            -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
        end
        if gameTimer.times["wudaohui_pipei"] == 0 then
            print("wudaohui_pipei====")
            gameTimer:UnrigistTimeFunc("wudaohui_pipei")

            self:updatetime()
            UIRequest({type = 4101,id = 0})
        end
    end)
end



function wudaohui_pipei.setSuccessData(self,data)
    gameTouch:clickprofbytime(5)
    self.rootItems.delynumLabel:setVisible(true)
    self.rootItems.pipeiLabel:setString("匹配成功...")

    gameTimer:UnrigistTimeFunc("wudaohui_pipei")
    gameTimer:UnrigistTimeFunc("wudaohui_update")
    UIRequest({type = 4101,id = 1})

    gameTimer:rigistTime("wudaohui_pipei_delay", 3)
    gameTimer:rigistTimeFunc("wudaohui_pipei_delay",function()
        
        if gameTimer.times["wudaohui_pipei_delay"] >= 0 then
            self.rootItems.delynumLabel:setString(gameTimer.times["wudaohui_pipei_delay"])
            print("1111111====",gameTimer.times["wudaohui_pipei_delay"])
            -- ui.setLabelString(self.coveritems.refresh_Label,refreshtimestring,14)
        end
        if gameTimer.times["wudaohui_pipei_delay"] == 0 then
            print("wudaohui_pipei_delay====")
            gameTimer:UnrigistTimeFunc("wudaohui_pipei_delay")

            local cb = function()
                print("battle==return")
                -- UIRequest({type = 3820})
                
                if GameScene.layers["wudaohui"].show then
                    GameScene.layers["wudaohui"].module:setFightEndData(data.result)
                end
            end

            gameWindows:closeWindowDirect("wudaohuipipei")
            
            gameTimer:rigistTime("wudaohui_pipeisuccess_delay", 2)
            gameTimer:rigistTimeFunc("wudaohui_pipeisuccess_delay",function()
                print("wudaohui_pipeisuccess_delay==",gameTimer.times["wudaohui_pipeisuccess_delay"])
                if gameTimer.times["wudaohui_pipeisuccess_delay"] == 0 then
                    gameTimer:UnrigistTimeFunc("wudaohui_pipeisuccess_delay")
                    print("sequence===")
                    UIRequest({type = 4100})
                    UIRequest({type = 4104})
                    UIRequest({type = 1001})
                end

            end)

            RunbattleCallBack("wudaohui", data,cb)


            
        end
    end)

end

function wudaohui_pipei.close(self)
    -- if gameTimer.times["wudaohui_pipei"] then
    --     gameTimer:UnrigistTimeFunc("wudaohui_pipei")
    -- end

    if gameTimer.times["wudaohui_pipei_delay"] then
        gameTimer:UnrigistTimeFunc("wudaohui_pipei_delay")
    end
    -- if gameTimer.times["wudaohui_pipeisuccess_delay"] then
    --     gameTimer:UnrigistTimeFunc("wudaohui_pipeisuccess_delay")
    -- end

    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil
end

return wudaohui_pipei

