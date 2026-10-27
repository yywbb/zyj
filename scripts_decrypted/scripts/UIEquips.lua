--
-- Created by IntelliJ IDEA.
-- User: f
-- Date: 14-10-9
-- Time: 16:26
-- To change this template use File | Settings | File Templates.
--

function UIEquips(t)
    print("10025 接受客户端数据")
    --printT(t)
    if t.param == "all" then

    elseif t.param == "equips" then
        GameScene.layers["equips"].module:setEquipDataByType("equips",t.equips)
        if GameScene.layers["equips"].show then
            GameScene.layers["equips"].module:setPage()
        end
        if GameScene.layers["equips_resolve"].show then
            GameScene.layers["equips_resolve"].module:ReloadData(t.equips)
        end
        -- 装备注灵需要用到装备的数据
        -- GameScene.layers["equipsup"].module:setEquipDataByType(t.equips)
        -- if GameScene.layers["equipsup"].show then
        --     GameScene.layers["equipsup"].module:setEquipDataByType(t.equips)
        -- end
    elseif t.param == "treasures" then
        GameScene.layers["equips"].module:setEquipDataByType("treasures",t.treasures)
        if GameScene.layers["equips"].show then
            GameScene.layers["equips"].module:setPage()
        end
        if GameScene.layers["treasure_resolve"].show then
            GameScene.layers["treasure_resolve"].module:ReloadData(t.treasures)
        end
    elseif t.param == "slotequips" then 
        GameScene.layers["equipsup"].module:setEquipsData(t.slotequips)
        if GameScene.layers["equipsup"].show then
            GameScene.layers["equipsup"].module:reloadEquipsData()
        end
    elseif t.param == "offequips" then
        GameScene.layers["qiankunlu"].module:setEquipsData(t.OffEquip)
        if GameScene.layers["qiankunlu"].show then
            GameScene.layers["qiankunlu"].module:reloadPageData()
        end
    elseif t.param == "offtreasures" then
        GameScene.layers["qiankunlu"].module:setTreasuresData(t.OffTreasure)
        GameScene.layers["treasureup"].module:setTreasuresData(t.OffTreasure)
        if GameScene.layers["qiankunlu"].show then
            GameScene.layers["qiankunlu"].module:reloadPageData()
        end
        if GameScene.layers["treasureup"].show then
            GameScene.layers["treasureup"].module:ReloadData()
        end
    elseif t.param == "equipstage" then
        GameScene.layers["equipstage"].module:setEquipstagedData(t.equipstage)
        if GameScene.layers["equipstage"].show then
            GameScene.layers["equipstage"].module:ReloadData()
        end
    else
        GameScene.layers["equips"].module:setEquipDataByType(t.param,t.equips)
        if GameScene.layers["equips"].show then
            GameScene.layers["equips"].module:setPage()
        end
    end
end

function UIEquipStrengthen(t)
    print("装备强化1101 接受客户端数据")
    --printT(t)


    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10025,"offequips")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)

    GameScene:addUpdate(10023)
    UIRequest({type = 1001})

    GameScene:UpdatePresentLayer()

    --resetEquipStrengthen(t.equip,function() GameScene:UpdatePresentLayer() end)
    -- if gameWindows.windows["equipInfo"].show then
    --     gameWindows.windows["equipInfo"].module:reloaddata(t)
    -- end
    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:reloaddata(t)
    end
end

function UIEquipCast(t)
    print("装备注灵5521 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    if t.ison and t.ison == 1 then
        GameScene:addUpdate(10023)
    else
        GameScene:addUpdate(10025,"offequips")
    end
    GameScene:addUpdate(1200)
    UIRequest({type = 1001})

    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:reloaddata(t)
    end
end

function UITreasureUp(t)
    print("宝物强化1105 接受客户端数据")

    --updateTreasureUp(t.equip)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"treasures")
    GameScene:addUpdate(10025,"offtreasures")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    GameScene:addUpdate(1200)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    if gameWindows.windows["equipInfo"].show then
        gameWindows.windows["equipInfo"].module:reloaddata(t)
    end

end

function UITreasureRefine(t)
    print("宝物精炼1106 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"treasures")
    GameScene:addUpdate(10025,"offtreasures")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    --resetTreasureRefine(t,function() GameScene:UpdatePresentLayer() end)
    if gameWindows.windows["equipInfo"].show then
        gameWindows.windows["equipInfo"].module:reloaddata(t)
    end

end

function UIEquipRefine(t)
    print("装备精炼1102 接受客户端数据")

    --updateEquipRefine(t.equip)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10025,"offequips")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    GameScene:addUpdate(1200)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    -- if gameWindows.windows["equipInfo"].show then
    --     gameWindows.windows["equipInfo"].module:reloaddata(t)
    -- end

    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:reloaddata(t)
    end
end

function UIEquipFragmentAll(t)
    print("装备碎片1107 接受客户端数据")
    --printT(t)
    GameScene.layers["equips"].module:ReloadFragmentData(t)
    if GameScene.layers["equips"].show then
        GameScene.layers["equips"].module:setPage()
    end

    if t.equipfragments then
        GameScene.layers["qiankunlu"].module:setEquipsFragmentData(t.equipfragments)
    end

    if t.treasurefragments then
        GameScene.layers["qiankunlu"].module:setTreasuresFragmentData(t.treasurefragments)
    end

    GameScene.layers["rob"].module.treasureData = t.treasures
    GameScene.layers["rob"].module.horseData = t.horses
    GameScene.layers["rob"].module.meterialData = t.meterials
    if GameScene.layers["rob"].show then
        GameScene.layers["rob"].module:setshiftPage()
    end
end

function UIEquipFragmentList(t)
    print("装备碎片11071 接受客户端数据")

    if t.equipfragments then
        GameScene.layers["qiankunlu"].module:setEquipsFragmentData(t.equipfragments)
    end

    if t.treasurefragments then
        GameScene.layers["qiankunlu"].module:setTreasuresFragmentData(t.treasurefragments)
    end
    
    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData()
    end

    GameScene.layers["equips"].module:ReloadFragmentData(t)
    if GameScene.layers["equips"].show then
        GameScene.layers["equips"].module:setPage()
    end
end

function UIEquipFragmentCompound(t)
    print("装备碎片合成1108 接受客户端数据")
    printT(t)
    GameScene:addUpdate(10021)
    if t.equiptype == "equip" then
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,t.type)
        GameScene:addUpdate(11071,"equip")
        showRewardPopupWindow(t.reward,nil)
        UIRequest({type = 1001})
    elseif t.equiptype == "treasure" then
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,t.type)
        GameScene:addUpdate(11071,"treasure")

        if GameScene.layers["rob"].show then
            GameScene.layers["rob"].module:compond(t)
        else
            GameScene:UpdatePresentLayer()
        end
        UIRequest({type = 10322})
    elseif t.equiptype == "meterial" then
        GameScene:addUpdate(11071,"meterial")
        GameScene:addUpdate(1200)

        if GameScene.layers["rob"].show then
            GameScene.layers["rob"].module:compond(t)
        else
            GameScene:UpdatePresentLayer()
        end
        UIRequest({type = 10322})
    end

    if t.cid and t.cid > 0 then 
        UIRequest({type = 12002, id = t.cid})
    end
end

function UIQuickEquipStrengthen(t)
    print("装备强化1109 接受客户端数据")
    --printT(t)


    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10025,"offequips")

    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:setChangedEquip(t.changeequips,t.criticalnum)
    end

    UIRequest({type = 1001})

    GameScene:addUpdate(10023)

    GameScene:UpdatePresentLayer()
    UIRequest({type = 10322})

end


function UIEquipRefineEx(t)
    print("装备一键精炼1115 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10025,"offequips")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    GameScene:addUpdate(1200)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    -- if gameWindows.windows["equipInfo"].show then
    --     gameWindows.windows["equipInfo"].module:reloaddata(t)
    -- end

    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:reloaddata(t)
    end
    UIRequest({type = 10322})
end

function UITreasureRefineEx(t)
    print("宝物一键精炼1116 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"treasures")
    GameScene:addUpdate(10025,"offtreasures")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    GameScene:addUpdate(1200)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    if gameWindows.windows["equipInfo"].show then
        gameWindows.windows["equipInfo"].module:reloaddata(t)
    end
    UIRequest({type = 10322})
end

-------------
function UIEquipBaptizePreview(t)
    print("装备洗炼 接受客户端数据")
    --printT(t)

    -- if gameWindows.windows["equipInfo"].show then
    --     gameWindows.windows["equipInfo"].module:setXilianPreview(t.equip)
    -- end
    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:setXilianPreview(t.equip)
    end
    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
    UIRequest({type = 10322})
end

function UIEquipBaptizeConfirm(t)
    print("装备洗炼 接受客户端数据")
    --printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10025,"offequips")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    GameScene:addUpdate(1200)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    -- if gameWindows.windows["equipInfo"].show then
    --     gameWindows.windows["equipInfo"].module:reloaddata(t)
    -- end
    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:reloaddata(t)
    end
    UIRequest({type = 1001})
    UIRequest({type = 10322})
end

------
------

function UITreasureStrengthen(t)
    print("宝物强化1118 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"treasures")
    GameScene:addUpdate(10025,"offtreasures")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    -- GameScene:addUpdate(1001)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    if GameScene.layers["treasureup"].show then
        GameScene.layers["treasureup"].module:ReloadData(t.equip)
    end
    UIRequest({type = 1001})
    UIRequest({type = 10322})
end

function UITreasureStrengthebyprop(t )
    print("1210 接受客户端数据")
    printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"treasures")
    GameScene:addUpdate(10025,"offtreasures")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    GameScene:addUpdate(1200)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    if GameScene.layers["treasureup"].show then
        GameScene.layers["treasureup"].module:ReloadData(t.equip)
    end
    UIRequest({type = 1001})
    UIRequest({type = 10322})
end

function UITreasureRefine2(t)
    print("宝物精炼1119 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"treasures")
    GameScene:addUpdate(10025,"offtreasures")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    GameScene:addUpdate(1001)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    if GameScene.layers["treasureup"].show then
        GameScene.layers["treasureup"].module:ReloadData(t.equip)
    end
    UIRequest({type = 1001})

    UIRequest({type = 10322})
end


--
function UIEquipBaptizeAutomatic(t)
    print("1124 接受客户端数据")
    printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"offequips")
    GameScene:addUpdate(10025,gamedata.config.equip[tostring(t.equip.cid)].type)
    GameScene:addUpdate(1200)

    GameScene:addUpdate(10023)
    GameScene:UpdatePresentLayer()

    if gameWindows.windows["equipbaptize"].show then
         gameWindows.windows["equipbaptize"].module:reloadData(t)
    end
    if GameScene.layers["equipsup"].show then
        GameScene.layers["equipsup"].module:reloaddata(t)
    end
    UIRequest({type = 1001})
    UIRequest({type = 10322})
end S8  