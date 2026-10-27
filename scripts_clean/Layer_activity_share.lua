--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/18
-- Time: 下午17:20
-- To change this template use File | Settings | File Templates.
--

local share = {
    isscrolltouched = false,
	buttontouch = -103,
	data = {},
	deadline = nil,

	ListTableView = nil,
	normalCellSize = {x=1080, y=245},
	taskTab = {},
}

function share.init(self, size)
	self.contentsize = size
    self.show = true
    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/fenxiangyouli",nil, true, "fenxiangyouli")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-150))

    local activityConfig = gamedata.config.activity_time
    local generalConfig = gamedata.config.generalanimation
    local name = generalConfig[tostring(activityConfig[tostring(23)].generalanimation)].name    
    self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
    -- local Gneral1 = CCSkeletonAnimation:create("nvzhujuewujie/nvzhujuewujie.json","nvzhujuewujie/nvzhujuewujie.atlas",1)
    local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1)
    Gneral1:setAnimation("stand",true,0)
    Gneral1:setScale(2)
    Gneral1:setPosition(0,0)
    self.coveritems["generalNode"]:addChild(Gneral1)

	ui.setLabelString(self.coveritems.desc1, nil, 1)
	ui.setLabelString(self.coveritems.desc2, nil, 1)

    local function touchbegin(pos)
        self.isscrolltouched = false
    end

    gameTouch:rigistFunc("begin","share",touchbegin)

    local function touchend(pos)
        if self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","share",touchend)
    --

	-- self:reloaddata()
    return self.coverccb
end

function share.reloaddata(self,data)
    if not self.show then return end
    --todo
    self.status = {}
    self.data = {}
    local tab1 = {}
    -- self.coveritems.listnode:removeAllChildrenWithCleanup(true)
    -- self.ListTableView = nil
    tab1 = data.activityShare or {}
    
    self.data = gamedata.config.task or {}

    local tt = 0
    local sorting = nil
    for k,v in pairs(tab1) do
    	tt = tt + 1
    	if v.status == 0 then
    		sorting = tonumber(v.task)*10
    	elseif v.status == 1 then
    		sorting = tonumber(v.task)
    	elseif v.status == 2 then
    		sorting = tonumber(v.task)*100000
    	end    	
    	self.status[tt] = {task = v.task, status = v.status, sorting = sorting}
    end
	table.sort(self.status, function(a, b)
		return a.sorting < b.sorting
	end)

    if self.coveritems then
        if not self.ListTableView then
            self:createList()
        else

            self.ListTableView:reloadData()
            print("is ListTableView")
        end
    end

end


function share.createList(self)
    local celldict = {}
    local unrecycleCell = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_reward2", nil, true, "cell_reward2")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end

            local cid, num = ui.getIDandNUM(self.data[tostring(self.status[a1+1].task)].share_award)
            local desc = self.data[tostring(self.status[a1+1].task)].desc
            local name = "奖励: " .. ui.IDconfig(cid).name .. "x" .. num

  
	        ui.addGray("CCControlButton", ccbDocumentControler.getbutton)
	        ui.addGray("CCLabelTTF", ccbDocumentControler.gettext)
	        ccbDocumentControler.getbutton:setSwallowsTouch(false)
            if self.status[a1+1].status == 0 then
            	ui.setLabelString(ccbDocumentControler.gettext, "分 享", 18)
            elseif self.status[a1+1].status == 1 then
            	ui.setLabelString(ccbDocumentControler.gettext, "分 享", 18)
		        ui.removeGray("CCControlButton", ccbDocumentControler.getbutton)
		        ui.removeGray("CCLabelTTF", ccbDocumentControler.gettext)
		        ccbDocumentControler.getbutton:setSwallowsTouch(true) -- 取消置灰             	
            elseif self.status[a1+1].status == 2 then
            	ui.setLabelString(ccbDocumentControler.gettext, "已分享", 18)
            end
            
            ccbDocumentControler.des1:setString(desc)
            ccbDocumentControler.des2:setString(name)
            ui.setNewIcon(ccbDocumentControler,{cid = cid, num = num})

		    ccbDocumentControler.getbutton:setTouchPriority(self.buttontouch)
		    ccbDocumentControler.getbutton:addHandleOfControlEvent(function()
                if not self.isscrolltouched then return end
		    	gameWindows:openWindow("share",{receiveId = self.status[a1+1].task}, nil)
		    end, CCControlEventTouchUpInside) 

            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.status)
        elseif fn == "cellTouched" then

        elseif fn == "scrollViewDidScroll" then
            ----gameTouch.isScrollling = true
        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.coveritems.listnode:getContentSize().width,
        viewheight = self.coveritems.listnode:getContentSize().height,
        dire = 1
    })
    self.coveritems.listnode:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(-101)
end

function share.clear(self)
    gameTouch:UnrigistFunc("begin","share")
    gameTouch:UnrigistFunc("end","share")
    if self.coverccb then   
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
    end
    self.show = false
    self.ListTableView = nil
    self.data = {}
    self.show = false
end


return share
