--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/19
-- Time: 下午12:00
-- To change this template use File | Settings | File Templates.
--

local servicewar_betchoose = {
    rootNode = nil,
    rootItems = nil,
    maxbetmoneynum = 0,
    maxnum = 0,
    buynum = 0,
}

function servicewar_betchoose.open(self,touchPriority,data,callback)
    self.root = CCNode:create()
    self.touchPriority = touchPriority
    printT(data,"servicewar_betchoose===data")
    self.shenbang = data.shenbang
    self.division = data.division
    self.data = data.data
    self.choose = data.choose

    self.rootNode, self.rootItems = CCBReaderLoad("kuafuzhan/kuafuzhan_property", nil, true, "kuafuzhan_property")
    self.root:addChild(self.rootNode)
    self:reloadData()

    -- UIRequest({type = 4713, id = data.id})

    return self.root, true
end




function servicewar_betchoose.reloadData(self)

    self.maxnum = math.ceil(self.data.basicdata.maxbetmoneynum/tonumber(gamedata.config.global_kv.cross_battle_yazhu.value)) or 0

    self.maxbetmoneynum = self.data.basicdata.maxbetmoneynum-self.data.basicdata.nowbetmoneynum

    if self.maxbetmoneynum < 0 then
        self.maxbetmoneynum = 0
    end

    self.rootItems.nameLab:setString(self.data["player"..self.choose]["name"])
    local petchancestring = "倍率："..(self.data.basicdata["petchance"..self.choose] or 1).."倍"
    self.rootItems.petchanceLab:setString(petchancestring)
    ui.setNewIcon(self.rootItems,{cid = self.data["player"..self.choose].profile ,level = self.data["player"..self.choose].level})


    self.rootItems.petmaxDescLab:setString("本轮比赛剩余最大押注限额："..self.maxbetmoneynum)
    self.rootItems.owncoinLab:setString("当前拥有银币数量："..GameScene.roleinfo.coin)

    self.rootItems.closeButton:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarbetchoose")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab1,"取 消",19)
    self.rootItems.doButton1:addHandleOfControlEvent(function()

        gameWindows:closeWindow("servicewarbetchoose")
    end, CCControlEventTouchUpInside)
    self.rootItems.doButton1:setSwallowsTouch(true)
    self.rootItems.doButton1:setTouchPriority(self.touchPriority)


    ui.setLabelString(self.rootItems.doLab2,"确 定",19)
    self.rootItems.doButton2:addHandleOfControlEvent(function()
        if self.buynum <= 0 then
            runGamePrompt({msg = "请押注"})
            return
        end

        if self.buynum > GameScene.roleinfo.coin then
            shortCoin()
            return
        end

        local mark = self.choose or 1
        if self.choose == 2 then
            mark = 0
        end
        
        gameTouch:clickprofbytime(0.5)
        local buynum = self.buynum or 0
	    local id = self.data.basicdata.id

        if self.shenbang then
            UIRequest({type = 4722,id = id, mark = mark, money = buynum})
        else
            UIRequest({type = 4716,division = self.division,id = id, mark = mark, money = buynum})
        end

        gameWindows:closeWindowDirect("servicewarbetchoose")

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton2:setSwallowsTouch(true)
    self.rootItems.doButton2:setTouchPriority(self.touchPriority)


    self.rootItems.sub10:addHandleOfControlEvent(function()

        self.buynum = self.buynum-self.maxnum
        if self.buynum <= 0 then
            self.buynum = 0
        end
        self:numchange()

    end, CCControlEventTouchUpInside)
    self.rootItems.sub10:setSwallowsTouch(true)
    self.rootItems.sub10:setTouchPriority(self.touchPriority)


    self.rootItems.add10:addHandleOfControlEvent(function()

        if (self.maxnum+self.buynum) > GameScene.roleinfo.coin then
            if (self.maxbetmoneynum+self.buynum) > GameScene.roleinfo.coin then
                shortCoin()
                return
            end
        end

        if (self.maxnum+self.buynum) > self.maxbetmoneynum then
            self.buynum = self.maxbetmoneynum
            self:numchange()
            runGamePrompt({msg = "银币超过最大押注上限"})
            return
        end

        self.buynum = self.buynum+self.maxnum
        self:numchange()

    end, CCControlEventTouchUpInside)
    self.rootItems.add10:setSwallowsTouch(true)
    self.rootItems.add10:setTouchPriority(self.touchPriority)
    
--    local lvbetconfig = gamedata.config.cross_battle_lvbet
--    self.maxnum = 0
--    for i=1,table.getTableLength(lvbetconfig) do
--        local tempnum = table.getTableLength(lvbetconfig)-(i-1)
--        local tempconfig = lvbetconfig[tostring(tempnum)]
--        if tempconfig then
--            if GameScene.roleinfo.level >= tempconfig.interval then
--                self.maxnum = tempconfig.lv_bet/gamedata.config.global_kv.cross_battle_yazhu.value
--                break
--            end
--        end
--    end

    self.rootItems.subnum:setString("-"..self.maxnum)
    self.rootItems.addnum:setString("+"..self.maxnum)

    self.buynum = (self.maxbetmoneynum < self.maxnum) and self.maxbetmoneynum or self.maxnum
    self:numchange()

end

function servicewar_betchoose.numchange(self)

    self.rootItems.buynum:setString(self.buynum)
    local getdescstring = "猜对可获得:"..self.buynum*tonumber(self.data.basicdata["petchance"..self.choose] or 1)
    self.rootItems.getLab:setString(getdescstring)

end


function servicewar_betchoose.close(self)
    self.root:removeAllChildrenWithCleanup(true)
    self.root:removeFromParentAndCleanup(true)
    self.root = nil
    self.rootNode = nil
    self.rootItems = nil
    self.buynum = 0
    self.maxnum = 0
    self.maxbetmoneynum = 0
end

return servicewar_betchoose