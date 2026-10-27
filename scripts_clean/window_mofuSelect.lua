--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 15/12/17
-- Time: 15:52
-- To change this template use File | Settings | File Templates.
--



local mofuselect = {
    rootNode = nil,
    rootItems = nil,
    ListTableView = {},

    maxNum = 1, --设置可以多少个

    showdata = {}, --展示的物品列表
    selectedData = {},  --被选择的物品列表
    infodata = {}, --被强化物品信息
    nextidtyep = false, --是否达到最大级状态
}

function mofuselect.open(self,touchPriority,data,callback)
    -- print("mofuselect..open")
    -- printT(data)
    
    self.rootNode, self.rootItems = CCBReaderLoad("mofu/tc_mofu_select", nil, true, "tc_mofu_select")

    self.touchPriority = touchPriority
    self.callback = callback

    self.infodata = data.infodata
    if data.choosedata and next(data.choosedata) then
        for k,v in pairs(data.choosedata) do
            self.selectedData[tostring(v.iid or "")] = v
        end
    end

    self.selecttype = data.selecttype


    UIRequest({type = 10029,param = "change_gem_type",param2 = data.listtype or self.infodata.type,param3 = data.infodata.iid,param4 = data.nolevelup})



    return self.rootNode
end


function mofuselect.reload(self,data)


    if self.selecttype == 1 then
        self.maxNum = 8
        self.showdata = data.data

        -- 判断是否达到最大等级状态
        self:setexp_up()
    else
        self.maxNum = 1
        self.showdata = data.data
    end

    self.rootItems.closeButton:addHandleOfControlEvent(function()
        self.callback = nil
        gameWindows:closeWindow("mofuselect")
    end, CCControlEventTouchUpInside)
    self.rootItems.closeButton:setSwallowsTouch(true)
    self.rootItems.closeButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.doLab,nil,19)
    self.rootItems.doButton:addHandleOfControlEvent(function()
        -- print("ok")

        gameWindows:closeWindowDirect("mofuselect")
        if guide.controller then
            guide.controller:UIComplete(8082)
        end

    end, CCControlEventTouchUpInside)
    self.rootItems.doButton:setSwallowsTouch(true)
    self.rootItems.doButton:setTouchPriority(self.touchPriority)

    ui.setLabelString(self.rootItems.titilenameLabel,nil,18)
    

    self:createSelectList()

    -- 设置选择个数显示
    self:setSelectNum()

    --
    if table.getTableLength(self.showdata) == 0 then
        self.callback = nil
    end
    ui.setGoto(self.rootItems.gotonode,table.getTableLength(self.showdata) == 0,"mofu")

end

function mofuselect.close(self)
    self.rootNode:removeAllChildrenWithCleanup(true)
    self.rootNode:removeFromParentAndCleanup(true)
    self.rootNode = nil
    self.rootItems = nil


    if self.callback then
        local data = {}
        for k,v in pairs(self.selectedData) do
            table.insert(data,v)
        end
        self.callback(data)
    end

    self.maxNum = 1

    self.showdata = {}
    self.selectedData = {}
    self.infodata = {}
    self.nextidtyep = false

    self.ListTableView = nil
    self.selectedData = {}
end





function mofuselect.createSelectList(self)

    local celldict = {}
    local ListHandle = LuaEventHandler:create(function(fn, myTable, a1, a2)
        local r
        if fn == "cellSize" then
            r = CCSizeMake(1040, 230)
        elseif fn == "cellAtIndex" then

            local cellCCB,ccbDocumentControler = 0,0
            local first = true
            if not a2 then
                a2 = CCTableViewCell:create()
                cellCCB, ccbDocumentControler = CCBReaderLoad("mofu/cell_mofu_xuanze", nil, true, "cell_mofu_xuanze")
                celldict[a2] = {cellCCB=cellCCB,ccbDocumentControler=ccbDocumentControler }
            else
                first = false
                cellCCB = celldict[a2].cellCCB
                ccbDocumentControler = celldict[a2].ccbDocumentControler
            end
            -- printT(self.selectedData)
            -- printT(self.showdata)
            -- print("textttttt",self.showdata[(a1+1)].iid)
            -- printT(self.showdata[(a1+1)])
            if self.selectedData[tostring(self.showdata[tostring(a1+1)].iid or "")] then
                ccbDocumentControler.isSelect:setVisible(true)
            else
                ccbDocumentControler.isSelect:setVisible(false)
            end

            local celldata = self.showdata[tostring(a1+1)]
            celldata.temp = ui.IDconfig(celldata.cid)
            ui.setLabelString(ccbDocumentControler.nameLabel,celldata.temp.name,((celldata.temp.quality and celldata.temp.quality ~= 0) and celldata.temp.quality or 1)*2-1)
            
            ui.setNewIcon(ccbDocumentControler,{cid=celldata.cid})

            local string = ""
            for i=1,4 do
                if tonumber(celldata.temp["attr"..i]) ~= 0 and celldata.temp["attr"..i] ~= "" then
                    -- print("celldata111==",celldata.temp["attr"..i])
                    if celldata.temp["attr"..i] ~= "critical" then
                        -- print("enterinl...")
                        string =  gameConfig.strings:string_common("attr_type",celldata.temp["attr"..i])..celldata.temp["init"..i] or {}
                    else
                        string =  gameConfig.strings:string_common("attr_type",celldata.temp["attr"..i])..(tonumber(celldata.temp["init"..i])*100).."%" or {}
                    end
                    ccbDocumentControler["propertyLabel"..i]:setString(string)
                    ccbDocumentControler["propertyLabel"..i]:setVisible(true)
                else
                    ccbDocumentControler["propertyLabel"..i]:setVisible(false)
                end
            end


            cellCCB:setPosition(930/2, 0)
            cellCCB:setScale(0.89)
            if first then
                a2:addChild(cellCCB)
            end

            r = a2

        elseif fn == "numberOfCells" then
            r = table.getTableLength(self.showdata)
        elseif fn == "cellTouched" then
            if self.selectedData[tostring(self.showdata[tostring(a1:getIdx()+1)].iid or "")] then
                -- print("touch11111")
                self.selectedData[tostring(self.showdata[tostring(a1:getIdx()+1)].iid or "")] = nil
            else
                if self.maxNum == 1 then
                    -- print("touch2222")
                    self.selectedData = {}
                    self.selectedData[tostring(self.showdata[tostring(a1:getIdx()+1)].iid or "")] = self.showdata[tostring(a1:getIdx()+1)]
                elseif self.maxNum > 1 then
                    -- print("touch33333",self.uplevel1,self.infodata.maxlv1)

                    if table.getTableLength(self.selectedData) >= self.maxNum then
                        -- print("touch6666")
                        runGamePrompt({msg = "最多可选"..self.maxNum.."个"})
                    elseif self.nextidtyep then
                        -- print("touch44444")
                        runGamePrompt({msg = "强化等级已达上限"})
                    elseif table.getTableLength(self.selectedData) < self.maxNum then
                        -- print("touch55555")
                        self.selectedData[tostring(self.showdata[tostring(a1:getIdx()+1)].iid or "")] = self.showdata[tostring(a1:getIdx()+1)]
                    end
                end
            end
            if guide.controller then
                guide.controller:UIComplete(8082)
            end
            self:setSelectNum()
            self.ListTableView:reloadData()
            if self.maxNum > 1 then
                self:setexp_up()
            end
            
        elseif fn == "scrollViewDidScroll" then

        end
        return r
    end)

    self.ListTableView = ui.createLuaTableView({
        handle = ListHandle,
        viewwidth = self.rootItems.listscroll:getContentSize().width,
        viewheight = self.rootItems.listscroll:getContentSize().height,
        dire = 1
    })
    self.rootItems.listscroll:addChild(self.ListTableView)
    self.ListTableView:setTouchPriority(self.touchPriority)
end

function mofuselect.setSelectNum(self)
    local num = 0
    if next(self.selectedData) then
        num = table.getTableLength(self.selectedData)
    end
    self.rootItems.select_num:setString(num.."/"..self.maxNum)
end

function mofuselect.setexp_up(self)
    -- print("setexp_up====")
    --是否达到最大级状态
    self.nextidtyep = false

    local mofuconfig = gamedata.config.sigil
    local allexpnum = 0

    for k,v in pairs(self.selectedData) do
        allexpnum = allexpnum + tonumber(mofuconfig[tostring(v.cid)].self_exp) + v.exp
    end

    -- 被选择的魔符兑换出的总经验（加上需要强化的魔符 自带经验
    allexpnum = allexpnum + self.infodata.exp
    -- print("allexpnum===",allexpnum)
    -- printT(self.infodata)
    local cidnum = self.infodata.cid --升级后的cid（一直变化着
    local expnum = 0 --升级后余下来的经验
    for i=1,15 do
        -- print("iiii-==",i,mofuconfig[tostring(cidnum)].nextid)
        if mofuconfig[tostring(cidnum)].nextid == 0 then
            -- print("cidnum===0000",cidnum)
            self.nextidtyep = true
            expnum = allexpnum
            break
        end
        if allexpnum >= mofuconfig[tostring(cidnum)].exp then
            -- print("jianfenshu===",allexpnum,mofuconfig[tostring(cidnum)].exp)
            allexpnum = allexpnum - mofuconfig[tostring(cidnum)].exp
            cidnum = mofuconfig[tostring(cidnum)].nextid
        else
            expnum = allexpnum
            break
        end
        -- print("cidnum===",cidnum)
    end
    -- print("expnum-==",expnum)
end


return mofuselect
