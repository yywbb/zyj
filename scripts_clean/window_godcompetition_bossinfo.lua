local godcompetition_bossinfos = {
    root = nil,
    rootNode = nil,
    rootItems = nil,

    pages = {"boss1","boss2","boss3"},
    choosepage = "boss1",

    boss1Data = {},
    boss2Data = {},
    boss3Data = {},
}

function godcompetition_bossinfos.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    
    printT(data,"godcompetition_bossinfos")

    self.rootNode, self.rootItems = CCBReaderLoad("fengshensai/tc_buffinfo.ccbi", nil, true, "tc_buffinfo")
    gameTouch:clickprofbytime(0.5)

    local bossConfig = gamedata.config.apex_boss
    for k,v in pairs(bossConfig) do
        if v.bossid == data.bossid then
            self.choosepage = "boss"..v.id
            if data.opentype == "pvp" then
                self.rootItems["boss_biaoji"..v.id]:setVisible(true)
            else
                self.rootItems["boss_biaoji"..v.id]:setVisible(false)
            end
        else
            self.rootItems["boss_biaoji"..v.id]:setVisible(false)
        end
    end
    
    self.root:addChild(self.rootNode)

    self.rootItems.closeBtn:addHandleOfControlEvent(function()
        gameWindows:closeWindow("godcompetition_bossinfos")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeBtn:setSwallowsTouch(true)
    self.rootItems.closeBtn:setTouchPriority(self.touchPriority-1)
    
    if data then
        self.boss1Data = data.buff1 or {}
        self.boss2Data = data.buff2 or {}
        self.boss3Data = data.buff3 or {}
    end    
                        
    local period = data.period or 1
    self.rootItems.title:setString(gameConfig.strings:godcompetition_period(period))

    self:reloadData()

    return self.root
end



function godcompetition_bossinfos.reloadData(self)

    for i,v in ipairs(self.pages) do
        print("page===",i,v)
        self.rootItems[v.."SelectBTn"]:addHandleOfControlEvent(function()
            print("page===222",i,v)
            self:shiftServiceScoreNode(v)
        end, CCControlEventTouchUpInside)
        self.rootItems[v.."SelectBTn"]:setSwallowsTouch(true)
        self.rootItems[v.."SelectBTn"]:setTouchPriority(self.touchPriority-1)
    end
    print("choosepage==",self.choosepage)
    self:shiftServiceScoreNode(self.choosepage)

end


function godcompetition_bossinfos.shiftServiceScoreNode(self,type)
    print("i...am..shiftServiceScoreNode",type)
    self.choosepage = type
    local buffdata = {}
    for k,v in ipairs(self.pages) do
        if v == self.choosepage then
            self.rootItems[v.."Select"]:setVisible(true)
            buffdata = self[v.."Data"]
        else
            self.rootItems[v.."Select"]:setVisible(false)
        end
    end
    
    printT(buffdata,"bossBuff")
    if buffdata then
        local breakskill = gamedata.config.breakskill
        for k,v in pairs(buffdata) do
            print(k,v)
            if breakskill[tostring(v)] then
                self.rootItems["desc"..k]:setString(breakskill[tostring(v)].desc)
            end    
        end    
    end    
end
   
function godcompetition_bossinfos.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.worldwarstatus = 0


    self.boss1Data = {}
    self.boss2Data = {}
    self.boss3Data = {}
    self.sevicechoosepage = "boss1"
    self.data = {}
end

return godcompetition_bossinfos