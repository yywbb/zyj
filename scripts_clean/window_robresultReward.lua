--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/10
-- Time: 下午3:45
-- To change this template use File | Settings | File Templates.
--


local robresultreward = {
    rootNode = nil,
    rootItems = nil,
    ListTableView = nil,
    -- listScrollSize = {x=920,y=680}
    configdata = {}
}

function robresultreward.open(self,touchPriority,data,callback)
    self.touchPriority = touchPriority
    self.configdata = data.data
    print("....this...is..robreward...")
    printT(data)


    self.rootNode, self.rootItems = CCBReaderLoad("rub/rub_tenjiangli.ccbi", nil, true, "rub_tenjiangli")
    -- self.rootItems.listScroll:setContentSize(CCSizeMake(920,180))
    self:reload()
    
    return self.rootNode
end

function robresultreward.reload(self)

    
    ui.setLabelString(self.rootItems.backbtn_Text,nil,19)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority)
    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        print("i..am..remove..robresultreward..")
        gameWindows:closeWindowDirect("robresultreward")
    end, CCControlEventTouchUpInside)

    self:createItemArr()

end


function robresultreward.createItemArr(self)
    print("createItemArr")
    printT(self.configdata)
    -- printT(self.configdata.data.otherreward)
    if self.configdata.otherreward then
        print("createItemArr01")
        local indexNum = table.getTableLength(self.configdata.otherreward)
        print("indexNum:%d",indexNum)

        for i=1,indexNum do
            print("i..am..%d",i)
            local cellCCB,ccbDocumentControler = 0,0
            cellCCB, ccbDocumentControler = CCBReaderLoad("icons/new_iconName2.ccbi", nil, true, "new_iconName2")
            self.rootItems.rewardListScroll:addChild(cellCCB)

            local itemdata = self.configdata.otherreward[tostring(i)]
            printT(itemdata)

            ui.setNewIconName(ccbDocumentControler,itemdata)

            
            ccbDocumentControler.in_button:setSwallowsTouch(true)
            ccbDocumentControler.in_button:setTouchPriority(self.touchPriority)
            ccbDocumentControler.in_button:addHandleOfControlEvent(function()
                print("i..am..remove..robresultreward..")
                ui.setPopwindowByCid(itemdata.cid)
                
            end, CCControlEventTouchUpInside)


            local x = 0
            local y = 0
            if  i < 5 or i == 5 then
                x = 94 + (183)*(i-1)
                y = 440
            else
                x = 94 + (183)*(i-6)
                y = 160
            end
            cellCCB:setPosition(x,y)
        end



    end

end

function robresultreward.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil

    if self.callback then
        self.callback()
    end
end

return robresultreward