--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/27
-- Time: 上午午10:57
-- To change this template use File | Settings | File Templates.
--

local treasuresDiscount_x3 = {
	buttontouch = -103,

	ListTableView = nil,
	normalCellSize = {x=1080, y=245},
	-- taskTab = {},
	data = {},
	treasuresStatus = {},
	index = nil,
    goldNum = nil,
    isscrolltouched = false,
    pageconfig = {"1","2","3","4","5"} ,
    pagename = {},
    selectpage = "",
    pagedata = {},
    pageLevel = {},
    rolelv = 0,

}

function treasuresDiscount_x3.init(self, size)
	self.contentsize = size
    self.show = true
    self.coverccb, self.coveritems = CCBReaderLoad("activityreward_new/duihuanshop",nil, true, "zhutizhekou")
    self.coveritems.topnode:setPositionY(self.contentsize.y-180)
    self.coveritems.listnode:setContentSize(CCSizeMake(gameConfig.originSize.width,self.contentsize.y-640-200))-- -160-180


    -- self.pagedata =  gamedata.config.exchange_shop
    local function touchbegin(pos)
        self.isscrolltouched = false
        self.touchbegin = {x = pos.x, y = pos.y}
    end

    gameTouch:rigistFunc("begin","treasuresDiscount_x3",touchbegin)

    local function touchend(pos)
        if math.abs(pos.x - (self.touchbegin and self.touchbegin.x or pos.x)) > 20 or math.abs(pos.y - (self.touchbegin and self.touchbegin.y or pos.y)) > 20 then
            self.isscrolltouched = false
        elseif self.coveritems.listnode and ui.isTouched(self.coveritems.listnode,pos.x,pos.y) then
            self.isscrolltouched = true
        end
    end

    gameTouch:rigistFunc("end","treasuresDiscount_x3",touchend)

    self.endTime = ""
    if gamedata.config.activity_time["34"]["open_type"] and gamedata.config.activity_time["34"]["open_type"] == 2 then
        self.coveritems.describe:setVisible(false)
        self.coveritems.time:setVisible(false)
    elseif gamedata.config.activity_time["34"]["open_type"] and gamedata.config.activity_time["34"]["open_type"] == 1 then
        local timediff = GameScene.roleinfo.servertime + 86400*(gamedata.config.activity_time["34"]["continued_time"]-1)
        local temp = os.date("*t", timediff)
        self.endTime = temp.year .. "年" .. temp.month .. "月" .. temp.day .. "日"  .. "24时"
    elseif gamedata.config.activity_time["34"]["open_type"] and gamedata.config.activity_time["34"]["open_type"] == 3 then
        local year, month, day, hour, min, sec = ui.getDate(gamedata.config.activity_time["34"]["end"])
        self.endTime = year .. "年" .. month .. "月" .. day .. "日" .. hour .. "时"
        if tonumber(hour) < 1 and tonumber(min) < 1 and tonumber(sec) < 1 then
            local endt = os.time({year=tonumber(year),month=tonumber(month),day=tonumber(day),hour=tonumber(hour),min=tonumber(min),sec=tonumber(sec),isdst=false}) - 1
            local endtab = os.date("*t",endt)
            self.endTime = endtab.year.."年"..endtab.month.."月"..endtab.day.."日".."24时"
        end
    end

    local activityConfig = gamedata.config.activity_time or {}
    local generalConfig = gamedata.config.generalanimation or {}
    -- if activityConfig[tostring(34)].generalanimation ~= 0 then
        local name = generalConfig[tostring(activityConfig[tostring(34)].generalanimation)].name
        self.coveritems["generalNode"]:removeAllChildrenWithCleanup(true)
        local Gneral1 = CCSkeletonAnimation:create(name .."/" .. name .. ".json", name .."/" .. name .. ".atlas",1) -- yudi
        Gneral1:setAnimation("stand",true,0)
        Gneral1:setScale(2)
        Gneral1:setPosition(0,0)
        self.coveritems["generalNode"]:addChild(Gneral1)
    -- end

    --
    if self.coveritems.title and activityConfig[tostring(34)] then
        self.coveritems.title:setString(activityConfig[tostring(34)].name or "")
    end
    --


    local exchange = gamedata.config.exchange_shop
    local length = table.getTableLength(exchange)
    self.pageLevel = {}
    for i=1,length do
       local exlv = exchange[tostring(i)][tostring(1)].label_level or 0
       table.insert(self.pageLevel,exlv)
    end
    
    printT(self.pageLevel,"pageLevel")


    self:onInit()
    self:initPage()
    -- self:reloadData()
    return self.coverccb
end

function treasuresDiscount_x3.onInit(self)
    if self.coveritems.aboutBtn then
        self.coveritems.aboutBtn:setVisible(false)
        self.coveritems.aboutBtn:setTouchPriority(self.buttontouch)
        self.coveritems.aboutBtn:setSwallowsTouch(true)
        self.coveritems.aboutBtn:addHandleOfControlEvent(function()
            -- 说明
            if GameScene.layers["activity"].module.isContentScroll then  return end
            gameWindows:openWindow("multipleRebateHelp", {explain = nil, title = "物品兑换限制"}, nil)
        end, CCControlEventTouchUpInside)
    end

    ui.setLabelString(self.coveritems.describe, nil, 14)	
    ui.setLabelString(self.coveritems.time, self.endTime, 14)
end

--按钮高亮状态的显示
function  treasuresDiscount_x3.shiftlayerpage(self,page)
    for km,vm in ipairs(self.pageconfig) do
        if tostring(vm) == tostring(page) then
            setSpriteFrameByName(self.coveritems["btnspr"..vm], "b_n_button_tab2")
        else
            setSpriteFrameByName(self.coveritems["btnspr"..vm], "b_n_button_tab1")
        end
    end
end


function treasuresDiscount_x3.initPage(self)

    for k,v in pairs(gamedata.config.exchange_shop) do
        -- printT(v,"v---"..k)
        if k == tostring(1) then
            self.pagedata[k] = v
        elseif k == tostring(2) then 
            self.pagedata[k] = v
        elseif k == tostring(3) then 
            self.pagedata[k] = v
        elseif k == tostring(4) then  
            self.pagedata[k] = v
        elseif k == tostring(5) then  
            self.pagedata[k] = v
        end    

    end

    local tablelength  = table.getTableLength(self.pagedata) or 0
    -- printT(self.pagedata,"self.pagedata")

    --设置标签名字
    for i=1,5 do 
         if i <= tablelength then
            self.coveritems["btnnode"..i]:setVisible(true)
            self.coveritems["plantitle"..i]:setString(self.pagedata[tostring(i)][tostring(1)].name)
         else
            self.coveritems["btnnode"..i]:setVisible(false)
         end   
    end

    --显示页签得按钮
    for k=1,tablelength do
        self.coveritems["planbutton"..k]:setSwallowsTouch(true)
        self.coveritems["planbutton"..k]:setTouchPriority(-102)
        self.coveritems["planbutton"..k]:addHandleOfControlEvent(function()
            if GameScene.layers["activity"].module.isContentScroll then  return end
            if self.pageLevel[k] <= self.rolelv then
                self:shiftPage(tostring(k))
            else    
                runGamePrompt({msg = "队伍达到"..self.pageLevel[k].."级开启，努力升级吧！！"})
            end
        end,CCControlEventTouchUpInside)  
    end
 
end


function treasuresDiscount_x3.shiftPage(self,type)

    print("-------------------"..type)
    if type and self.selectpage == type then
        return
    end

    if type then
        self.selectpage = type
    end

    self:shiftlayerpage(self.selectpage)
    -- printT(gamedata.config.exchange_shop,"exchange_shop")
    self.treasuresStatus = self.treasuresStatusAll[self.selectpage]
    print(self.treasuresStatus,"shiftPage-- treasuresStatus")


    if self.coveritems then
        print(self.treasuresStatus,"shiftPage-- self.coveritems")
        if table.getTableLength(self.treasuresStatus) >0 then
            self.coveritems.listnode:removeChild(self.ListTableView,true)
            self.ListTableView = nil
            self:createList()
        end    
    end
end

function treasuresDiscount_x3.screenLevelData(self, data)

    local rolelv = GameScene.roleinfo.level or 0
    local exchange = gamedata.config.exchange_shop
    self.rolelv  = rolelv


    local tablelength  = table.getTableLength(self.pageLevel) or 0
    --显示页签得按钮
    for k=1,tablelength do
        if tonumber(self.pageLevel[k]) <= tonumber(self.rolelv) then
            if self.coveritems["btnspr"..k] then
                ui.removeGray("CCSprite",self.coveritems["btnspr"..k])
            end   
        else  
            if self.coveritems["btnspr"..k] then
                ui.addGray("CCSprite",self.coveritems["btnspr"..k])
            end    
        end
    end

    self.treasuresStatusAll = data

    local _index = 1
    local haveOne = false
    for i,v in pairs(data) do
        if _index ~= i then
            haveOne = false
        end    
        _index = i
         --获取到最大等级
        local currentMaxLevel = 1
        for k,w in pairs(v) do
            if exchange[tostring(i)] and exchange[tostring(i)][tostring(k)] then
                local downlevel = exchange[tostring(i)][tostring(k)].down_level
                local up_level = exchange[tostring(i)][tostring(k)].up_level
    
                self.treasuresStatusAll[i][k].order  = exchange[tostring(i)][tostring(k)].order
                self.treasuresStatusAll[i][k].ids =  exchange[tostring(i)][tostring(k)].id
                print("downlevel:",downlevel," up_level:",up_level)
                if up_level == 999 then
                   self.treasuresStatusAll[i][k].isshow = 1
                    haveOne = true
                elseif rolelv>=downlevel and rolelv<=up_level then
                   self.treasuresStatusAll[i][k].isshow = 1
                    haveOne = true
                end 
                -- print("currentMaxLevel:",currentMaxLevel)
                if currentMaxLevel < up_level then
                    currentMaxLevel = up_level
                end                 
            end
        end
        -- print("maxLevel:",currentMaxLevel," haveOne:",haveOne)
        if not haveOne then --此列一个显示的都没有
            for k,w in pairs(v) do
                if exchange[tostring(i)] and exchange[tostring(i)][tostring(k)] then
                    local level = exchange[tostring(i)][tostring(k)].up_level
                    if level == currentMaxLevel then
                      self.treasuresStatusAll[i][k].isshow = 1
                    end 
                end
            end       
        end    
    end
    --printT(self.treasuresStatusAll,"screenLevelData")
end

function treasuresDiscount_x3.reloaddata(self, data)
    if not self.show then return end

    --print("treasuresDiscount_x3.reloaddata")
    self:screenLevelData(data.activityTreasure)

    --printT(self.treasuresStatusAll,"reloaddata")

    if self.selectpage == "" then
        self.selectpage = "1"
    end    
    
    --print("reloaddata page:",self.selectpage)
    self.treasuresStatus = self.treasuresStatusAll[tostring(self.selectpage)]
    --printT(self.treasuresStatus,"self.treasuresStatus")
    self:shiftlayerpage(self.selectpage)


    if self.coveritems then
        if not self.ListTableView then
            print("reloaddata createList:")
            self:createList()
        else
            self.treasuresStatusSort = {}
            local tablelength = 0
            for i,v in pairs(self.treasuresStatus) do
                if v.isshow and v.isshow ==1 then
                 tablelength = tablelength+1
                 table.insert(self.treasuresStatusSort,v)
                end    
            end

            local sortfunc = function (a,b)
                return a.order < b.order
            end
            table.sort(self.treasuresStatusSort,sortfunc)
            --printT(self.treasuresStatusSort,"treasuresStatusSort")


            self.ListTableView:reloadData() -- 刷新列表
            print("is ListTableView")
        end
    end

end

function treasuresDiscount_x3.createList(self)
    --print("createList come in")
    self.coveritems.listnode:removeAllChildrenWithCleanup(true)
    self.ListTableView = nil

    local celldict = {}
    local unrecycleCell = {}
    self.treasuresStatusSort = {}
    local tablelength = 0
    for i,v in pairs(self.treasuresStatus) do
        if v.isshow and v.isshow ==1 then
         tablelength = tablelength+1
         table.insert(self.treasuresStatusSort,v)
        end    
    end

    local sortfunc = function (a,b)
        return a.order < b.order
    end
    table.sort(self.treasuresStatusSort,sortfunc)
    --printT(self.treasuresStatusSort,"treasuresStatusSort")


    --print(tablelength,":tablelength")
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(self.normalCellSize.x, self.normalCellSize.y)
        elseif fn == "cellAtIndex" then
            --
            -- local dataconfig = gamedata.config.exchange_shop[self.selectpage] or {}
            -- print(a1,"a1")
            -- printT(dataconfig,"dataconfig")
            local data = {}
            -- for k,v in pairs(dataconfig) do
            --     printT(v,"dataconfig k:"..k)
            --     if v.order and (v.order == (a1+1)) then
            --         data = v
            --     end
            -- end
            -- if not next(data) then
            --     data = dataconfig[tostring(a1+1)]
            -- end
            -- printT(data,"data-----"..(a1+1))        
            -- local treasuresStatus = self.treasuresStatus[tostring(data.id)]
            -- if treasuresStatus.isshow and treasuresStatus.isshow == 0 then
            --     return
            -- end   

            local sortdata = self.treasuresStatusSort[a1+1]
            local dataconfig = gamedata.config.exchange_shop[self.selectpage] or {}
            for i,v in pairs(dataconfig) do
                if sortdata.ids == v.id then
                   data = v
                end
            end

            --printT(data,"cell data")

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("activityreward_new/cell_zhenpinzhekou2", nil, true, "cell_zhenpinzhekou")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
           

            local index =  0
            for i,v in pairs(self.treasuresStatus) do
                if tostring(data.id) == tostring(v.ids) then
                    index =  i
                end   
            end
            self:setCell(ccbDocumentControler, data, index,a1+1)
            cellCCB:setPosition(self.normalCellSize.x/2, 14)
            if first then
                a2:addChild(cellCCB)
            end
            r = a2
        elseif fn == "numberOfCells" then
        	-- printT(self.treasuresStatusSort,"treasuresStatusSort =====")
            r = table.getTableLength(self.treasuresStatusSort)
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

function treasuresDiscount_x3.setCell(self, item, cellData, index,listIndex)

	local data = cellData
    local props = ui.getIDandNUMs(data.generals) or {}
    local consumnum = #props
    local treasuresStatus = self.treasuresStatusSort[listIndex]
	local goldCellTab = ui.getIDandNUMs(data.target) or {}
	for k,v in pairs(goldCellTab) do
		table.insert(props, v)
	end

    local canExchangeMax = 99999999
    local remaining_num = (data.count - treasuresStatus.num) or 0
    local notprops = false
	
	self.goldNum = props[1] and props[1].num or 0
	item.surplusNum:setString(((data.count - treasuresStatus.num) < 0 and 0 or (data.count - treasuresStatus.num)) .. "/" .. data.count) -- 剩余次数

	setSpriteFrameByName(item.discountLv, (data.discount .. "zhe") or "alpha")
	ui.setLabelString(item.exchangeLab, nil, 18)

    for i=1, 5 do
        if item["reward"..i] then
            if props[i] and props[i].cid then
                item["reward"..i]:setVisible(true)
                local config = ui.IDconfig(props[i].cid)
                if config then
                    if i<= consumnum then
                        local hasnum = treasuresStatus[tostring(props[i].cid)] or 0
                        if props[i].cid == 1000 or props[i].cid == 1001 then
                            --print("treasuresDiscount_x3---1---cid-num", props[i].cid, props[i].num)
                            ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                        else
                            --print("treasuresDiscount_x3---2---cid-hasnum/num", props[i].cid, hasnum,"/",props[i].num)
                            ui.setNewIcon(item,{cid = props[i].cid, num = hasnum.."/"..props[i].num,},i-1)
                        end

                        if canExchangeMax > math.floor(hasnum/props[i].num) then
                            canExchangeMax = math.floor(hasnum/props[i].num)
                        end

                        if hasnum< props[i].num then
                            notprops = true
                            ui.setLabelString(item["i_num"..(i-1==0 and "" or "_"..(i-1))], nil, 24)
                        end
                    else
                        --print("treasuresDiscount_x3---3---cid-num", props[i].cid, props[i].num)
                        ui.setNewIcon(item,{cid = props[i].cid, num = props[i].num,},i-1)
                    end

                    --
                    item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                        if not self.isscrolltouched then return end
                        if gameTouch.isScrollling then return end
                        ui.setPopwindowByCid(props[i].cid)
                    end, CCControlEventTouchUpInside)
                    item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                    --
                end
                if i<= consumnum then
                    item["reward"..i]:setPositionX(100+(i-1)*120)
                else
                    item["reward"..i]:setPositionX(150+(i-1)*120)
                end
                item.esprite:setPositionX(186+(consumnum-1)*120)
            else
                item["reward"..i]:setVisible(false)
                --
                item["i_button"..(i>1 and "_"..i-1 or "")]:addHandleOfControlEvent(function()
                    if not self.isscrolltouched then return end
                    if gameTouch.isScrollling then return end
                    --
                end, CCControlEventTouchUpInside)
                item["i_button"..(i>1 and "_"..i-1 or "")]:setTouchPriority(-103)
                --
            end
        end
    end	

    local goldNum = ui.getIDandNUMs(data.generals) or {}
    item.exchangeBtn:setTouchPriority(self.buttontouch)
    item.exchangeBtn:addHandleOfControlEvent(function()
        if not self.isscrolltouched then return end
        if gameTouch.isScrollling then return end

        print("click index:"..index)
        local cb = function(num)
            gameTouch:clickprofbytime(1)
            -- UIRequest({type = 4017, treasures = index, goldNum = props[1].num or 0, num = num})
            UIRequest({type = 4017, id = data.id,num = num, index = index, pageid =  self.selectpage ,goldNum = props[1].num})
        end
        if remaining_num >0 then
            if notprops then
                cb(1)
            else 
                if remaining_num > 5 then
                    ui.exchangeMore(cb,canExchangeMax,data.count - treasuresStatus.num,data.count)
                else
                    cb(1)
                end
            end
        else
            runGamePrompt({msg = "次数已经用完了"})
        end
    end, CCControlEventTouchUpInside)

    if remaining_num >0 then
		-- 正常
        ui.removeGray("CCControlButton",item.exchangeBtn)
        ui.removeGray("CCLabelTTF",item.exchangeLab)		
	else
		-- 置灰
        ui.addGray("CCControlButton",item.exchangeBtn)
        ui.addGray("CCLabelTTF",item.exchangeLab)
	end
end

function treasuresDiscount_x3.clear(self)
    if self.coverccb then 
    	self.ListTableView = nil 
        self.coverccb:removeAllChildrenWithCleanup(true)
        self.coverccb:removeFromParentAndCleanup(true)
        self.coverccb = nil
        self.coveritems = nil
        self.data = {}
        self.treasuresStatus = {}
        gameTouch:UnrigistFunc("begin","treasuresDiscount_x3")
        gameTouch:UnrigistFunc("end","treasuresDiscount_x3")
        pageLevel = {}
        pagename = {}
        selectpage = ""
        pagedata = {}
        rolelv = 0
    end
	self.show = false
end


return treasuresDiscount_x3
