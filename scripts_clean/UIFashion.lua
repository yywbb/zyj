--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 16/6/12
-- Time: 18:10
-- To change this template use File | Settings | File Templates.
--
function savePartnerfashionOnceToSqlite(p_id,status)
    local rid = GameScene.roleinfo.id or 0
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
    if rid < 1000000 then
        rid = serverid*1000000 + rid
    end    
    local mydb = SQLite3Open()
    if nil == mydb then
        return nil
    end
    local SQL = "UPDATE partnerfashion SET pf_once=".. status .. " WHERE rid=" .. rid .. " AND pf_id="..p_id
    mydb:exec(SQL)
    if (mydb:changes() == 0) and (status == 1) then
        SQL = string.format("INSERT INTO partnerfashion (rid,pf_id,pf_once) VALUES (%d,%d,%d)",rid,p_id,status)
        mydb:exec(SQL)
    end
    mydb:close()
end
--
function getPartnerfashionOnceFromSqlite(p_id)
    local once = 0
    local rid = GameScene.roleinfo.id or 0
    local serverid = gameWindows.windows["roleinfo"].module.SelectedServer.id or 1
    if rid < 1000000 then
        rid = serverid*1000000 + rid
    end    
    local mydb = SQLite3Open()
    if nil == mydb then
        return 0
    end
    local SQL = "SELECT count(*) AS pftexist FROM sqlite_master WHERE type='table' AND name='partnerfashion'"
    local ret = 0
    for row in mydb:nrows(SQL) do
        ret = row["pftexist"]
    end
    if ret == 0 then
        local SQL = "CREATE TABLE IF NOT EXISTS partnerfashion (rid INTEGER, pf_id INTEGER, pf_once INTEGER)";
        mydb:exec(SQL)
        return 0
    end
    local SQL = "SELECT * FROM partnerfashion WHERE rid=" .. rid .. " AND pf_id="..p_id
    for row in mydb:rows(SQL) do
        once = tonumber(row[3]) or once
        break
    end
    mydb:close()
    return once
end
--

function UIFashionDressQuery(t)
    print("1070，接受客户端数据")
    printT(t)

    GameScene.fashiondata = t.fashion

    -- if GameScene.layers["fashion"].show then
    --     GameScene.layers["fashion"].module:ReloadData(t)
    -- end
    if GameScene.layers["lead"].show then
        GameScene.layers["lead"].module:pageDataCallback("fashion","ReloadData",t)
    end
    
    GameScene.layers["qiankunlu"].module:setFashionData(t.fashion)
end

function UIFashionDressHide(t)
    print("1071，接受客户端数据")
    --printT(t)

    UIRequest({type = 1054, param = "update"})

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
end

function UIFashionDressStrange(t)
    print("1072，接受客户端数据")
    --printT(t)

    UIRequest({type = 1001})
    UIRequest({type = 1070})
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
end

function UIFashionDressChange(t)
    print("1073，接受客户端数据")
    --printT(t)

    UIRequest({type = 1070})
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    UIRequest({type = 1054, param = "update"})
end

function UIActivityQShopQuery(t)
    print("4400，接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[52] and GameScene.layers["activity"].module.pageTable[52].module.show then
        GameScene.layers["activity"].module.pageTable[52].module:reloaddata(t._item,t.scoredata)
    end
end

function UIActivityQShopReward(t)
    print("4401，接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[52] and GameScene.layers["activity"].module.pageTable[52].module.show then
        GameScene.layers["activity"].module.pageTable[52].module:reloaddata(t._item,t.scoredata)
    end

    local id = 0
    if t._reward then
        for k,v in pairs(t._reward) do
            if v.cid >= 80001 and v.cid <= 81000 then
                id = v.cid
            end
        end
    end

    if id > 0 then
        gameWindows:openWindow("fashionGet",{id = id})
        UIRequest({type = 1054, param = "update"})
        UIRequest({type = 1070})
    else
        showRewardPopupWindow(t._reward,nil)
    end

    -- UIRequest({type = 4400})
    UIRequest({type = 1001})
    GameScene:addUpdate(1200)
end

--
function UIMidAutumnShopQuery(t)
    print("4600，接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[54] and GameScene.layers["activity"].module.pageTable[54].module.show then
        GameScene.layers["activity"].module.pageTable[54].module:reloaddata(t._item,t.scoredata)
    end
end

function UIMidAutumnShopReward(t)
    print("4601，接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[54] and GameScene.layers["activity"].module.pageTable[54].module.show then
        GameScene.layers["activity"].module.pageTable[54].module:reloaddata(t._item,t.scoredata)
    end

    local id = 0
    if t._reward then
        for k,v in pairs(t._reward) do
            if v.cid >= 80001 and v.cid <= 81000 then
                id = v.cid
            end
        end
    end

    if id > 0 then
        gameWindows:openWindow("fashionGet",{id = id})
        UIRequest({type = 1054, param = "update"})
        UIRequest({type = 1070})
    else
        showRewardPopupWindow(t._reward,nil)
    end

    UIRequest({type = 1001})
    GameScene:addUpdate(1200)
end

function UIMidAutumnShopQuery_x1(t)
    print("4602 接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[208] and GameScene.layers["activity"].module.pageTable[208].module.show then
        GameScene.layers["activity"].module.pageTable[208].module:reloaddata(t._item,t.scoredata)
    end
end

function UIMidAutumnShopReward_x1(t)
    print("4603 接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[208] and GameScene.layers["activity"].module.pageTable[208].module.show then
        GameScene.layers["activity"].module.pageTable[208].module:reloaddata(t._item,t.scoredata)
    end

    local id = 0
    if t._reward then
        for k,v in pairs(t._reward) do
            if v.cid >= 80001 and v.cid <= 81000 then
                id = v.cid
            end
        end
    end

    if id > 0 then
        gameWindows:openWindow("fashionGet",{id = id})
        UIRequest({type = 1054, param = "update"})
        UIRequest({type = 1070})
    else
        showRewardPopupWindow(t._reward,nil)
    end

    UIRequest({type = 1001})
    GameScene:addUpdate(1200)
end
--
--
function UIChristmasShopQuery(t)
    print("4405，接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[62] and GameScene.layers["activity"].module.pageTable[62].module.show then
        GameScene.layers["activity"].module.pageTable[62].module:reloaddata(t._item,t.scoredata)
    end
end

function UIChristmasShopReward(t)
    print("4406，接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[62] and GameScene.layers["activity"].module.pageTable[62].module.show then
        GameScene.layers["activity"].module.pageTable[62].module:reloaddata(t._item,t.scoredata)
    end

    local id = 0
    if t._reward then
        for k,v in pairs(t._reward) do
            if v.cid >= 80001 and v.cid <= 81000 then
                id = v.cid
            end
        end
    end

    if id > 0 then
        gameWindows:openWindow("fashionGet",{id = id})
        UIRequest({type = 1054, param = "update"})
        UIRequest({type = 1070})
    else
        showRewardPopupWindow(t._reward,nil)
    end

    -- UIRequest({type = 4405})
    UIRequest({type = 1001})
    GameScene:addUpdate(1200)
end


--
function UICPActivityQShopQuery(t)
    print("5035，接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[88] and GameScene.layers["activity"].module.pageTable[88].module.show then
        GameScene.layers["activity"].module.pageTable[88].module:reloaddata(t._item,t.scoredata,t.cpnum,t.cpday)
    end
end

function UICPActivityQShopReward(t)
    print("5036，接受客户端数据")
    printT(t)
    if  GameScene.layers["activity"].module.pageTable[88] and GameScene.layers["activity"].module.pageTable[88].module.show then
        GameScene.layers["activity"].module.pageTable[88].module:reloaddata(t._item,t.scoredata,t.cpnum,t.cpday)
    end

    local id = 0
    if t._reward then
        for k,v in pairs(t._reward) do
            if v.cid >= 80001 and v.cid <= 81000 then
                id = v.cid
            end
        end
    end

    if id > 0 then
        gameWindows:openWindow("fashionGet",{id = id})
        UIRequest({type = 1054, param = "update"})
        UIRequest({type = 1070})
    else
        showRewardPopupWindow(t._reward,nil)
    end

    -- UIRequest({type = 5035})
    UIRequest({type = 1001})
    GameScene:addUpdate(1200)
end


--武将时装

function UIPartnerFashionBuy(t)
    print("6910，接受客户端数据")
    printT(t)

    local showreward = {}
    if t.reward and next(t.reward) then
        for k,v in pairs(t.reward) do
            local conf = ui.IDconfig(v.cid) or {}
            if conf.staffType and conf.staffType == "partnerfashion" then
                table.insert(showreward,v)
            end 
        end    
    end 
    if next(showreward) then
        showRewardPopupWindow(showreward,nil)
    end
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10211)
    UIRequest({type = 1001})
    UIRequest({type = 6911})

end

function UIPartnerFashionQuery(t)
    print("6911，接受客户端数据")
    printT(t)

    GameScene.partnerfashion = t.partnerfashion or {}

    if GameScene.layers["partnerfashion_collect"].show then
        GameScene.layers["partnerfashion_collect"].module:reloaddata(t)
    end

    if gameWindows.windows["partner_fashion"].show then
        gameWindows.windows["partner_fashion"].module:reload(t)
    end

    if GameScene.layers["activity"].module.pageTable[161] and GameScene.layers["activity"].module.pageTable[161].module.show then
        GameScene.layers["activity"].module.pageTable[161].module:reloadData(t)
    end

end

function UIPartnerFashionUse(t)
    print("6912，接受客户端数据")
    printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10211)

    GameScene:UpdatePresentLayer()

    if t.general then
        if gameWindows.windows["partner_fashion"].show then
            gameWindows.windows["partner_fashion"].module:reloadgeneral({cid = t.general.illusionGeneralCid or t.general.cid, general = t.general})
        end 
        --
        if gameWindows.windows["generalInfoRole"].show then
            gameWindows:closeWindowDirect("generalInfoRole")
        end 
    end

    UIRequest({type = 10023})

end

function UIPartnerFashionRecovery(t)
    print("6913，接受客户端数据")
    printT(t)

end

function UIPartnerFashionHasRecovery(t)
    print("6914，接受客户端数据")
    printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10211)

    GameScene:UpdatePresentLayer()

    local needreloadgeneralcid = 0
    if gameWindows.windows["partner_fashion"].show then
        if t.generals and next(t.generals) then
            for k,v in pairs(t.generals) do
                if gameWindows.windows["partner_fashion"].module.general_iid and gameWindows.windows["partner_fashion"].module.general_iid == v.iid then
                    needreloadgeneralcid = v.cid
                end    
            end    
        end 
        --
        if needreloadgeneralcid > 0 then
            gameWindows.windows["partner_fashion"].module:reloadgeneral({cid = needreloadgeneralcid, general = t.generals[needreloadgeneralcid]})
        else
            UIRequest({type = 6911})
        end    
    else    
        UIRequest({type = 6911})
    end

    if gameWindows.windows["generalInfoRole"].show then
        if t.generals and next(t.generals) then
            for k,v in pairs(t.generals) do
                if gameWindows.windows["generalInfoRole"].module.data.general.iid and gameWindows.windows["generalInfoRole"].module.data.general.iid == v.iid then
                    gameWindows:closeWindowDirect("generalInfoRole")
                end    
            end    
        end   
    end

end

function UINaiLiCodeRank(t)
    print("8245, 接受客户端数据")
    printT(t)

    if gameWindows.windows["dayuanxiaorank"].show then
        gameWindows.windows["dayuanxiaorank"].module:reloadData(t)
    end

    if gameWindows.windows["nailicode"].show then
        gameWindows.windows["nailicode"].module:reloadData(t.myRank)
    end

end



