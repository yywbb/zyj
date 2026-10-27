--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/8
-- Time: 上午10:06
-- To change this template use File | Settings | File Templates.
--


function UIGeneralFragmentResolve(t)
    print("乾坤炉1036,接受客户端数据")
    -- printT(t)
    -- showRewardPopupWindow(t.reward,nil,nil)

    -- GameScene:addUpdate(1012)
    updateDataLife(t.cid)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end
end

function UIGeneralResolve2(t)
    print("1039,接受客户端数据")
    -- printT(t)
    updateDataLife(t.cid)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end
end


function UIEquipResolve(t)
    print("乾坤炉1104,接受客户端数据")
    printT(t)

    -- showRewardPopupWindow(t.reward,nil,nil)
    
    -- GameScene:addUpdate(10025,"offequips")
    -- GameScene:addUpdate(10025,"offtreasures")
    -- GameScene:addUpdate(10025,"equips")
    -- GameScene:addUpdate(10025,"treasures")
    updateDataLife(t.cid)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end
end

function UIGeneralReset(t)
    print("乾坤炉1035,接受客户端数据")
    -- printT(t)

    
    -- showRewardPopupWindow(t.reward,nil,nil)
    -- UIRequest({type = 1001})

    updateDataLife(t.cid)

    -- GameScene:addUpdate(10023)
    -- GameScene:addUpdate(10024)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end

    if t.updateExclusiveArtifact then
        UIRequest({type = 8101})
        UIRequest({type = 8105})
    end
    
end

function UIFashionDressReset(t)
    print("乾坤炉1077,接受客户端数据")
    printT(t)

    
    -- showRewardPopupWindow(t.reward,nil,nil)
    -- UIRequest({type = 1001})

    updateDataLife(t.reward)

    -- GameScene:addUpdate(10023)
    -- GameScene:addUpdate(10024)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end

    UIRequest({type = 1070})
end

function UIEquipReset(t)
    print("乾坤炉1117,接受客户端数据")
    -- printT(t)

    -- showRewardPopupWindow(t.reward,nil,nil)

    updateDataLife(t.cid)

    -- GameScene:addUpdate(10025,"offequips")
    -- GameScene:addUpdate(10025,"offtreasures")
    -- GameScene:addUpdate(10025,"equips")
    -- GameScene:addUpdate(10025,"treasures")

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end

    -- UIRequest({type = 1001})
end

function UIGeneralResolve(t)
    print("乾坤炉1037,接受客户端数据")
    -- printT(t)

    -- showRewardPopupWindow(t.reward,nil,nil)

    -- GameScene:addUpdate(10023)
    -- GameScene:addUpdate(10024)
    updateDataLife(t.cid)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end

    -- UIRequest({type = 1001})
end

function UIResolveQuality( t )
    print("乾坤炉品质3850")
    printT(t)
    GameScene.layers["qiankunlu"].module.resolvequality = t.quality
    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadResolveQuality(t)
        --UIRequest({type = 10322, param = {"lianhua"}})
    end
end


function UIPetReset(t)
    print("1065,接受客户端数据")
    printT(t)

    updateDataLife(t.reward)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end

    UIRequest({type = 1040})
end

function UIbagLimitTip(t)
    print("5555,接受客户端数据")

    local msg = (t.opt == 1) and "数量超1000件，请及时消耗掉，数量过多，会导致系统卡顿。"
                             or "数量超过500件，请及时消耗掉，数量过多，会导致系统卡顿。"

    if t.kind == 1 then
        gameWindows:openWindow("baglimittip",{msg = "宝物"..msg,confirmtext = "去强化"},function()
            --GameScene:shiftLayerById(142)
            GameScene:shiftLayer("treasureup","up",{page = "up"})
        end)
    elseif t.kind == 2 then
        gameWindows:openWindow("baglimittip",{msg = "装备"..msg,confirmtext = "去炼化"},function()
            GameScene:shiftLayerById(161)
        end)
    elseif t.kind == 3 then
        gameWindows:openWindow("baglimittip",{msg = "命格"..msg},function()
            GameScene:shiftLayer("soulResolveList","up")
        end)
    elseif t.kind == 4 then
        gameWindows:openWindow("baglimittip",{msg = "器灵"..msg,confirmtext = "去炼化"},function()
            GameScene:shiftLayer("qiLingRefining","up")
        end)
    end        
end

function UIRedfragmentResolve(t)
    print("6901,接受客户端数据")
    printT(t)
    
    GameScene:addUpdate(10030)

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end
end
