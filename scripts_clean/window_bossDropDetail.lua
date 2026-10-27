--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/4
-- Time: 下午2:25
-- To change this template use File | Settings | File Templates.
--

local bossDropDetail = {
    data = {},
	rootNode = nil,
	rootItems = nil,
	titleCellSize = {x=923, y=200},
	items = {},
    firstitems = {}
}

function bossDropDetail.open(self, touchPriority, data, callback)
	self.rootNode, self.rootItems = CCBReaderLoad("kingman/tc_diaoluoyulan", nil, true, "bossDropDetail")
	self.show = true
    self.data = data.data

	self.touchPriority = touchPriority
	self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindowDirect("bossDropDetail")
	end, CCControlEventTouchUpInside)
	self.rootItems.closeButton:setSwallowsTouch(true)
	self.rootItems.closeButton:setTouchPriority(self.touchPriority)
	
	ui.setLabelString(self.rootItems.tip,nil,24)
	-- self.rootItems.title:setString("BOSS详情")
    local hurtlablestring = self.data.curblood.."%"
    ui.setLabelString(self.rootItems.bloodBarLabel,hurtlablestring,13)
    ui.setSpriteTextureRect2(self.rootItems.bloodProgressBar,0,0,844*(self.data.curblood/100),31)

	
    local attConfigData = gamedata.config:getConfigByName("personalboss_att")
    local attBossData = {}
    for k,v in pairs(attConfigData) do
        if v["function"] == self.data.bosstype then
            table.insert(attBossData,v)
        end
    end
    local sortfun = function(a,b)
        return a.id < b.id 
    end
    table.sort(attBossData,sortfun)
    -- 双倍掉落判断
    local datatmp = ui.CheckHuodongByParam(4)
    local isEnd = false
    local useddata = 0
    printT(self.data,"self.data")
    if self.data.openlevel ~= 0 then
        local curidx = (self.data.openlevel+1)
        local bossconfig = attConfigData[tostring(curidx)]
        
        if not bossconfig then
            isEnd = true
            useddata = attConfigData[tostring(self.data.openlevel)]
        else
            useddata = bossconfig
        end
    else
        useddata = attBossData[1]
    end

    self:getBossFall(useddata)


    self:setCell(isEnd)
	-- self:upMaterialList()
	return self.rootNode
end
--获得王的男人掉落物品
function bossDropDetail.getBossFall( self,aiData )
    self.count = 0   
    for i = 1,4 do
        if aiData["drop"..i] ~= 0 then
            self.count = self.count + 1
            if aiData["drop"..i.."number"..i] and aiData["drop"..i.."number"..i] > 0 then
                table.insert( self.items, {cid = aiData["drop"..i], num = (aiData["drop"..i.."number"].."~"..aiData["drop"..i.."number"..i])} )
            else    
                table.insert( self.items, {cid = aiData["drop"..i]} )
            end
        end        
    end
    --firstDrop
    self.firstitems = ui.getIDandNUMs(aiData["firstDrop"])
end
function bossDropDetail.setCell(self, isget)
    for i = 1,3 do
        if self.firstitems[i] and self.firstitems[i] ~= 0 then
            ui.setNewIconName(self.rootItems,self.firstitems[i],i-1)
            if isget then
                self.rootItems.getrewardend:setVisible(true)
            end
        else
            self.rootItems["successDrop"..i]:setVisible(false)
        end
    end
    for i = 4,6 do
        local curidx = i-3
        if self.items[curidx] and self.items[curidx] ~= 0 then
            ui.setNewIconName(self.rootItems,self.items[curidx],i-1)
        else
            self.rootItems["failDrop"..curidx]:setVisible(false)
        end
    end
end
----------------------------------------------------------------------------

function bossDropDetail.close(self, _type) -- 退出
    self.items = {}
	self.bossSkillTab = {}
	self.treasureListTableView = nil
	self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
	self.rootNode = nil
	self.rootItems = nil

end

return bossDropDetail