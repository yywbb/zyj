--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/8
-- Time: 上午10:06
-- To change this template use File | Settings | File Templates.
--


-- 魔符升级
function UISigilLevelUp(t)
    print("魔符1140,接受客户端数据")
    -- printT(t)
    local mofudata = {}
    local selectlistdata = {}
    local tempconfig = gamedata.config.sigil
    for k,v in pairs(t.gems) do
        v.temp = ui.IDconfig(v.cid)
        -- print("t.gems===iid",t.iid,v.iid)
        -- printT(v)
        if tonumber(t.iid) == tonumber(v.iid) then
            mofudata = v
        elseif tonumber(t.propertytype) == tonumber(v.temp.type) and v.ison == 0 then
            -- print("selectlistdataid=",v.iid)
            table.insert(selectlistdata,v)
        end 
    end


    local sortfunc = function( a,b )
        return a.temp.order > b.temp.order
    end
    table.sort(selectlistdata,sortfunc)

    local data = {}
    data.mofudata = mofudata
    data.selectlistdata = selectlistdata


    gameWindows.windows["mofulevelup"].module:selectdataReload({data=data.selectlistdata})
    
    if gameWindows.windows["mofulevelup"].show then
        -- print("mofulevelup reload")

        gameWindows.windows["mofulevelup"].module:reload(data)
    end

    GameScene:addUpdate(10028)
    GameScene:addUpdate(10022)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)


    GameScene.layers["mofulist"].module:mofudataReload(t.gems)
    
    if GameScene.layers["mofulist"].show then

        GameScene.layers["mofulist"].module:reloadstatus()
    end

    --
    GameScene.layers["slotsInfo"].module.slotgems = t.slotmofudata
    GameScene.layers["slotsInfo"].module.gems = t.gems
    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:reload()
    end

    GameScene:UpdatePresentLayer()

    UIRequest({type = 10322,param = {"gem"}})
end


-- 魔符
function UISigilChangePos(t)
    print("魔符1141,接受客户端数据")
    -- printT(t)

    GameScene.layers["slotsInfo"].module.slotgems = t.slotgems
    GameScene.layers["slotsInfo"].module.gems = t.gems
    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:reload()
    end

    GameScene:addUpdate(10022)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)

    GameScene:UpdatePresentLayer()
    UIRequest({type = 10322,param = {"gem"}})
end

function UISigilCanLevelUp(t)
    print("魔符1142,接受客户端数据")
    printT(t)
    if gameWindows.windows["mofuproperty"].show then
        gameWindows.windows["mofuproperty"].module:setCanLevelUpGemsReload(t.data)
    end

    if gameWindows.windows["mofulevelup"].show then
        gameWindows.windows["mofulevelup"].module:setCanLevelUpGemsReload(t.data)
    end
end