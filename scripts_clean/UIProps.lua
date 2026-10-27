--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-18
-- Time: 下午3:47
-- To change this template use File | Settings | File Templates.
--

function UIPropsList(t)
    print("1200 接受客户端数据")

    --printT(t)

    GameScene.props =  t.props

    GameScene.layers["equips"].module:ReloadPropsData(t)
    if GameScene.layers["equips"].show then
        GameScene.layers["equips"].module:showProps()
    end
end

function UIPropsUse(t)
    print("1201 接受客户端数据")
    -- printT(t)

    if t.rewards and next(t.rewards) then
        GameScene:addUpdate(1200)
        showRewardPopupWindow(t.rewards,nil)
    else
        GameScene.layers["equips"].module:ReloadPropsData(t)
        if GameScene.layers["equips"].show then
            GameScene.layers["equips"].module:showProps()
        end
    end

    if gameWindows.windows["propusebynum"].show then
        gameWindows.windows["propusebynum"].module:reloadData({id=t.id})
    end

    if gameWindows.windows["buypower"].show then
        gameWindows.windows["buypower"].module:setPropdata(t.propscachedata)
    end

    if t.id then
        UIRequest({type = 12002, id = t.id})
    end

    GameScene.props =  t.props

    UIRequest({type =1001})
--    UIRequest({type =10025})
--    UIRequest({type =11071})

    if GameScene.layers["activity"].module.pageTable[34] and GameScene.layers["activity"].module.pageTable[34].module.show then
        UIRequest({type = 4016})
    end

end

function UIPropNumQuery(t)
    printT(t,"道具数量查询")

    if gameWindows.windows["infoAndAccess"].show then
        gameWindows.windows["infoAndAccess"].module:setPropNum(t.nums)
    end
        
end

function UIPropQueryById(t)
    print("12001 接受客户端数据")
    printT(t)
    if t.order == 11001 then
        setEquipStrengthenCoin(t.nums)
    elseif t.order == 10001 then
        --setSkill_upNum(t.nums)
        if gameWindows.windows["generalInfo"].show then
            gameWindows.windows["generalInfo"].module:setSkillPropNum(t.nums)
        end
    elseif t.order == 10002 then
        if gameWindows.windows["buypower"].show then
            gameWindows.windows["buypower"].module:setPropdataNum(t.nums)
        end
    elseif t.order == 11002 then
        --setEquipRefineNum(t.nums)
        if gameWindows.windows["equipInfo"].show then
            gameWindows.windows["equipInfo"].module:setRefineNum(t.nums)
        end
    elseif t.order == 11003 then
        setTreasureUpNum(t.nums)
    elseif t.order == 11004 then
        -- if gameWindows.windows["equipInfo"].show then
        --     gameWindows.windows["equipInfo"].module:setXilianNum(t.nums)
        -- end
        if GameScene.layers["equipsup"].show then
            GameScene.layers["equipsup"].module:setXilianNum(t.nums)
        end
        --
        if gameWindows.windows["equipbaptize"].show then
             gameWindows.windows["equipbaptize"].module:setpropNum(t.nums)
        end
        --
        if gameWindows.windows["instrumentForgeAutomatic"].show then
            gameWindows.windows["instrumentForgeAutomatic"].module:setpropNum(t.nums)
        end
    elseif t.order == 11005 then
        if GameScene.layers["treasureup"].show then
            GameScene.layers["treasureup"].module:setPropNum(t.nums)
        end
    elseif t.order == 10101 then
        --setGeneralTrainNum(t.nums)
        if gameWindows.windows["generalInfo"].show then
            gameWindows.windows["generalInfo"].module:setTrainPropNum(t.nums)
        end
        if GameScene.layers["generalup"].show then
            GameScene.layers["generalup"].module:setTrainPropNum(t.nums)
        end
        if gameWindows.windows["generalcultivate"].show then
            gameWindows.windows["generalcultivate"].module:setpropNum(t.nums)
        end
    elseif t.order == 10102 then
        --setPropNum(t.nums)
        if gameWindows.windows["generalInfo"].show then
            gameWindows.windows["generalInfo"].module:setInheritPropNum(t.nums)
        end
    elseif  t.order == 10103 then
        if GameScene.layers["generalup"].show then
            GameScene.layers["generalup"].module:setAwankenPropNum(t.nums)
        end
    elseif t.order == 25061 then
        --setSoulStrengthenProp(t.nums)
        if gameWindows.windows["soulInfo"].show then
            gameWindows.windows["soulInfo"].module:setUpPropNum(t.nums)
        end
    elseif t.order == 13201 then
        if GameScene.layers["friendcopy"].show then
            GameScene.layers["friendcopy"].module:setPropNum(t)
        end
    elseif t.order == 10201 then
        if GameScene.layers["exchange"].show then
            GameScene.layers["exchange"].module:setCoinNum(t.nums)
        end
    elseif t.order == 21001 then
        if gameWindows.windows["cup"].show then
            gameWindows.windows["cup"].module:setCupPropNum(t.nums)
        end
        if GameScene.layers["cup"].show then
            GameScene.layers["cup"].module:setpropnum(t.nums)
        end
    elseif t.order == 22001 then
        if GameScene.layers["gang"].show then
            GameScene.layers["gang"].module:setpropNum(t.nums)
        end
    elseif t.order == 32011 then
        if gameWindows.windows["shopbuy"].show then
            gameWindows.windows["shopbuy"].module:setpropNum(t.nums)
        end
    elseif t.order == 32021 then
        if gameWindows.windows["buyItem"].show then
            gameWindows.windows["buyItem"].module:setPropNum(t.nums)
        end
    elseif t.order == 32012 then
        if gameWindows.windows["buyprop"].show then
            gameWindows.windows["buyprop"].module:setpropNum(t.nums)
        end
    elseif t.order == 11121 then
        if GameScene.layers["rob"].show then
            GameScene.layers["rob"].module:setPropNum(t.nums)
        end
    elseif t.order == 18001 then
        if GameScene.layers["devil"].show then
            GameScene.layers["devil"].module:setPropNum(t.nums)
        end
    elseif t.order == 19001 then
        if GameScene.layers["lead"].show then
            -- GameScene.layers["lead"].module:setPropNum(t.nums)
            GameScene.layers["lead"].module:pageDataCallback("mogong","setPropNum",t.nums)
        end
    elseif t.order == 40001 then
        if GameScene.layers["gang_xianchi"].show then
            GameScene.layers["gang_xianchi"].module:setPropNum(t.nums)
        end
    elseif t.order == 10121 then
        if GameScene.layers["generals"].show then
            GameScene.layers["generals"].module:setGneneral(t.nums)
        end
    elseif t.order == 12011 then
        if gameWindows.windows["propusebynum"].show then
            gameWindows.windows["propusebynum"].module:setpropNum(t.nums)
        end
    elseif t.order == 10401 then
        if GameScene.layers["generalup"].show then
            GameScene.layers["generalup"].module:setUpNum(t.nums)
        end
    elseif t.order == 11301 then
        if GameScene.layers["slotsInfo"].show then
            GameScene.layers["slotsInfo"].module:setStoneFragment(t.nums)
        end
    elseif t.order == 12341 then
        print("UIProps...get")
        if GameScene.layers["devil"].show then
            GameScene.layers["devil"].module:pageDataCallback("mochong","getSpendPropsData",t.nums)
            -- GameScene.layers["devil"].module:getSpendPropsData(t.nums)
        end
        if GameScene.layers["devil"].show then
            GameScene.layers["devil"].module:pageDataCallback("jinjie","getSpendPropsData",t.nums)
            -- GameScene.layers["devil"].module:getSpendPropsData(t.nums)
        end
    elseif t.order == 14001 then
        if GameScene.layers["penglai"].show then
            GameScene.layers["penglai"].module:setPropNum(t.nums)
        end
    elseif t.order == 14002 then
        print("UIProps..equipstage")
        printT(t.nums)
        if GameScene.layers["equipsup"].show then
            GameScene.layers["equipsup"].module:setStageUpSpendPropsData(t.nums)
        end
        if GameScene.layers["equipstage"].show then
            GameScene.layers["equipstage"].module:setSpendPropsData(t.nums)
        end
    elseif t.order == 14003 then
        print("UIProps..equipsup")
        printT(t.nums)
        if GameScene.layers["equipsup"].show then
            GameScene.layers["equipsup"].module:setSpendPropsData(t.nums)
        end
    elseif t.order == 14004 then
        print("UIProps..equipsup")
        printT(t.nums)
        if GameScene.layers["equipsup"].show then
            GameScene.layers["equipsup"].module:setCSpendPropsData(t.nums)
        end
    elseif t.order == 10721 then
        -- if GameScene.layers["fashion"].show then
        --     GameScene.layers["fashion"].module:setUpPropNum(t.nums)
        -- end
        if GameScene.layers["lead"].show then
            GameScene.layers["lead"].module:pageDataCallback("fashion","setUpPropNum",t.nums)
        end

    elseif t.order == 10771 then
        -- if GameScene.layers["gamestar"].show then
        --     GameScene.layers["gamestar"].module:setUpPropNum(t.nums)
        -- end
        if GameScene.layers["lead"].show then
            GameScene.layers["lead"].module:pageDataCallback("gamestar","setUpPropNum",t.nums)
        end
    elseif t.order == 14505 then
        if gameWindows.windows["clubchance"].show then
            gameWindows.windows["clubchance"].module:setPropNum(t.nums)
        end
    elseif t.order == 42021 then
        if gameWindows.windows["deploymentLevelUp"].show then
            gameWindows.windows["deploymentLevelUp"].module:setPropNum(t.nums)
        end
    elseif t.order == 37321 then
        if GameScene.layers["safemask"].show then
            GameScene.layers["safemask"].module:setUpPropNum(t.nums)
        end
    elseif t.order == 37322 then
        if GameScene.layers["safemask"].show then
            GameScene.layers["safemask"].module:setEvolvePropNum(t.nums)
        end
    elseif t.order == 14005 then
        -- if GameScene.layers["wingmain"].show then
        --     GameScene.layers["wingmain"].module:setSpendPropsData(t.nums)
        -- end

        if GameScene.layers["lead"].show then
            GameScene.layers["lead"].module:pageDataCallback("wing","setSpendPropsData",t.nums)
        end
    elseif t.order == 14006 then
        -- if GameScene.layers["wingmain"].show then
        --     GameScene.layers["wingmain"].module:setStageSpendPropsData(t.nums)
        -- end
        if GameScene.layers["lead"].show then
            GameScene.layers["lead"].module:pageDataCallback("wing","setStageSpendPropsData",t.nums)
        end
    elseif t.order == 14007 then
        if gameWindows.windows["wingcolorset"].show then
            gameWindows.windows["wingcolorset"].module:setSpendPropsData(t.nums)
        end
    elseif t.order == 10621 then
        -- if GameScene.layers["devourcollectup"].show then
        --     GameScene.layers["devourcollectup"].module:setPropsData(t.nums)
        -- end
        if GameScene.layers["devil"].show then
            GameScene.layers["devil"].module:pageDataCallback("shengji","setPropsData",t.nums)
        end
        if GameScene.layers["devil"].show then
            GameScene.layers["devil"].module:pageDataCallback("jinjie","setPropsData",t.nums)
        end
        if GameScene.layers["devil"].show then
            GameScene.layers["devil"].module:pageDataChange(t.nums,"petFragmentData")
        end
    elseif t.order == 33001 then
        if  GameScene.layers["activity"].module.pageTable[63] then
            GameScene.layers["activity"].module.pageTable[63].module:setItemNum(t.nums)
        end
    elseif t.order == 33002 then
        if  GameScene.layers["activity"].module.pageTable[73] then
            GameScene.layers["activity"].module.pageTable[73].module:setItemNum(t.nums)
        end
    elseif t.order == 33003 then
        if  GameScene.layers["activity"].module.pageTable[38] then
            GameScene.layers["activity"].module.pageTable[38].module:setItemNum(t.nums)
        end
    elseif t.order == 33004 then
        if  GameScene.layers["activity"].module.pageTable[64] then
            GameScene.layers["activity"].module.pageTable[64].module:setItemNum(t.nums)
        end
    elseif t.order == 33005 then
        if  GameScene.layers["activity"].module.pageTable[45] then
            GameScene.layers["activity"].module.pageTable[45].module:setItemNum(t.nums)
        end
    elseif t.order == 33006 then
        if  GameScene.layers["activity"].module.pageTable[80] then
            GameScene.layers["activity"].module.pageTable[80].module:setItemNum(t.nums)
        end
    elseif t.order == 33007 then
        if GameScene.layers["soul"].show then
            GameScene.layers["soul"].module:setItemNum(t.nums)
        end
    elseif t.order == 33008 then
        if  GameScene.layers["activity"].module.pageTable[90] then
        GameScene.layers["activity"].module.pageTable[90].module:setItemNum(t.nums)
        end
    elseif t.order == 33009 then
        if GameScene.layers["artifactCreate"].show then
            GameScene.layers["artifactCreate"].module:setUsePropNums(t.nums)
        end
    elseif t.order == 33013 then
        if gameWindows.windows["onceCheckup"].show then
            gameWindows.windows["onceCheckup"].module:checkPropNums(t.nums)
            return;
        end
        if GameScene.layers["artifactCheck"].show then
            GameScene.layers["artifactCheck"].module:checkPropNums(t.nums)
        end
    elseif t.order == 10261 then
        if GameScene.layers["exclusiveArtifactUp"].show then
            GameScene.layers["exclusiveArtifactUp"].module:refreshCostTable(t.nums)
        end
    elseif t.order == 33010 then
        if  GameScene.layers["activity"].module.pageTable[103] then
            GameScene.layers["activity"].module.pageTable[103].module:setPropNum(t.nums)
        end
    elseif t.order == 33011 then
        if  GameScene.layers["activity"].module.pageTable[109] then
            GameScene.layers["activity"].module.pageTable[109].module:setPropNum(t.nums)
        end
    elseif t.order == 33015 then
        if GameScene.layers["generalup"].show then
            GameScene.layers["generalup"].module:setXiuLianPropShow(t.nums)
        end
    elseif t.order == 33016 then
        if gameWindows.windows["artifactOpenPos"].show then
            gameWindows.windows["artifactOpenPos"].module:getUseIdNum(t.nums)
        end
    elseif t.order == 33012 then
        if gameWindows.windows["activityAuctionChooseAntique"].show then
            gameWindows.windows["activityAuctionChooseAntique"].module:reloadData(t.nums)
        end
        if gameWindows.windows["activityantiqueOnekey"].show then
            gameWindows.windows["activityantiqueOnekey"].module:reloadData(t.nums)
        end
    elseif t.order == 33014 then
        if gameWindows.windows["jewelUp"].show then
            gameWindows.windows["jewelUp"].module:getUseIdNum(t.nums)
        end
        if GameScene.layers["artifactMount"].show then
            GameScene.layers["artifactMount"].module:getUseIdNum(t.nums)
        end
        if gameWindows.windows["jewelInfo"].show then
            gameWindows.windows["jewelInfo"].module:getUseIdNum(t.nums)
        end
    elseif t.order == 33090 then
        if gameWindows.windows["shopExchange"].show then
            gameWindows.windows["shopExchange"].module:setpropNum(t.nums)
        end
    elseif t.order == 33092 then
        if gameWindows.windows["useropt"].show then
            gameWindows.windows["useropt"].module:reloadRename({type = "rename",nums = t.nums},nil)
        else
            gameWindows:openWindow("useropt",{type = "rename",nums = t.nums},nil)
        end
        
    elseif t.order == 33093 then
        if GameScene.layers["chat"].show then
            GameScene.layers["chat"].module:setLabanum(t.nums)
        end
    elseif t.order == 33094 then
        if GameScene.layers["chat"].show then
            GameScene.layers["chat"].module:setcrossLabanum(t.nums)
        end
    elseif t.order == 12101 then
        if GameScene.layers["treasureup"].show then
            GameScene.layers["treasureup"].module:setUpPropNum(t.nums)
        end
    elseif t.order == 32000 then
        if gameWindows.windows["mobileShop"].show then
            gameWindows.windows["mobileShop"].module:reloadListData(t.nums)
        end
    elseif t.order == 32001 then
        --乾坤炉道具数量更新
        if GameScene.layers["qiankunlu"].show then
            GameScene.layers["qiankunlu"].module:setUpPropNum(t.nums)
        end
    elseif t.order == 32002 then
        --神器洗练道具数量更新
        if GameScene.layers["artifactWash"].show then
            GameScene.layers["artifactWash"].module:setUpPropNum(t.nums)
        end
    elseif t.order == 32003 then
        --神器详情开孔消耗道具
        if gameWindows.windows["artifactInfo"].show then
            gameWindows.windows["artifactInfo"].module:setPropNum(t.nums)
        end
    elseif t.order == 33020 then
        if GameScene.layers["generalup"].show then
            GameScene.layers["generalup"].module:setTupoPropNum(t.nums)
        end
    elseif t.order == 32005 then
        if gameWindows.windows["changebreakskill"].show then
            gameWindows.windows["changebreakskill"].module:setPropNum(t.nums)
        end
    elseif t.order == 32004 then
        --武将飞升道具查询

        if GameScene.layers["generalup"].show then
            GameScene.layers["generalup"].module:setFeiShengConsume(t.nums)
        end

        -- if gameWindows.windows["generalFeiSheng"].show then
        --     gameWindows.windows["generalFeiSheng"].module:setFeiShengConsume(t.nums)
        -- end
        
        -- if GameScene.layers["generalFeiSheng"].show then
        --     GameScene.layers["generalFeiSheng"].module:setFeiShengConsume(t.nums)
        -- end

        if GameScene.layers["lead"].show then
            GameScene.layers["lead"].module:pageDataCallback("feisheng","setFeiShengConsume",t.nums)
        end
    elseif t.order == 32006 then
        if GameScene.layers["safemask"].show then
            GameScene.layers["safemask"].module:setFeiShengPropNum(t.nums)
        end
    elseif t.order == 32007 then
        if GameScene.layers["magic"].show then
            GameScene.layers["magic"].module:setTupoPropNum(t.nums)
        end
    elseif t.order == 32008 then
        if GameScene.layers["change"].show then
            GameScene.layers["change"].module:setGeneralChangePropNum(t.nums)
        end
    elseif t.order == 32009 then
        if GameScene.layers["godSoulTempleCuishen"].show then
            GameScene.layers["godSoulTempleCuishen"].module:setPropNum(t.nums)
        end
    elseif t.order == 32010 then
        if gameWindows.windows["recruit"].show then
            gameWindows.windows["recruit"].module:setPropNum(t.nums)
        end
    elseif t.order == 33018 then
        if GameScene.layers["lead"].show then
            GameScene.layers["lead"].module:pageDataCallback("awaken","setAwakenConsume",t.nums)
        end
    elseif t.order == 33019 then
        if GameScene.layers["generalup"].show then
            GameScene.layers["generalup"].module:setUpStarPropNum(t.nums)
        end
    elseif t.order == 33017 then
        if  GameScene.layers["activity"].module.pageTable[174] then
            GameScene.layers["activity"].module.pageTable[174].module:setItemNum(t.nums)
        end
    elseif t.order == 50001 then
        if gameWindows.windows["openfeastinfo"].show then
            gameWindows.windows["openfeastinfo"].module:setpropNum(t.nums)
        end
        if gameWindows.windows["openzaotanginfo"].show then
            gameWindows.windows["openzaotanginfo"].module:setpropNum(t.nums)
        end
        if gameWindows.windows["gangProduceAgain"].show then
            gameWindows.windows["gangProduceAgain"].module:setpropNum(t.nums)
        end
    elseif t.order == 33021 then
        if GameScene.layers["qiLingRefining"].show then
            GameScene.layers["qiLingRefining"].module:reloadPropNum(t.nums)
        end

        if gameWindows.windows["qilingIntensify"].show then
            gameWindows.windows["qilingIntensify"].module:reloadPropNum(t.nums)
        end
    elseif t.order == 33022 then
        if GameScene.layers["exclusiveArtifact"].show then
            GameScene.layers["exclusiveArtifact"].module:reloadPropNum(t.nums)
        end
    elseif t.order == 33023 then
        if GameScene.layers["qiLingBag"].show then
            GameScene.layers["qiLingBag"].module:setQilings(t.nums)
        end
    elseif t.order == 34306 then
        if GameScene.layers["tokenBag"].show then
            GameScene.layers["tokenBag"].module:ReloadData(t.nums)
        end
    elseif t.order == 34307 then
        if GameScene.layers["tokenMain"].show then
            GameScene.layers["tokenMain"].module:pageDataCallback("token", "reloadPropNum", t.nums)
        end    
    elseif t.order == 34308 then
        if gameWindows.windows["generalJXRebirth"].show then
            gameWindows.windows["generalJXRebirth"].module:setPropNum(t.nums)
        end 
        if gameWindows.windows["generalUpStarRebirth"].show then
            gameWindows.windows["generalUpStarRebirth"].module:setPropNum(t.nums)
        end 
    elseif t.order == 34401 then
        if GameScene.layers["treasureup"].show then
            GameScene.layers["treasureup"].module:setSpendPropsData(t.nums)
        end
    end

end


--
function UIPropRecovery(t)
    print("4620 接受客户端数据")
    -- printT(t)

    if t.rewards and next(t.rewards) then
        showRewardPopupWindow(t.rewards,nil)
    end

    UIRequest({type =1001})
    GameScene:addUpdate(1200)

    GameScene:UpdatePresentLayer()

end



function UILimitPropListQuery(t)
    print("5901 接受客户端数据")
    printT(t)

    if t.countdownGift and next(t.countdownGift) then
        for k, v in pairs(t.countdownGift) do
            if v.limitTime and v.limitTime > 0 then
                if gameTimer.times["limitProp_"..v.iid] then
                    gameTimer:UnrigistTimeFunc("limitProp_"..v.iid)
                end
                gameTimer:rigistTime("limitProp_"..v.iid,v.limitTime+1)
            end
        end
    end

    GameScene:addUpdate(1200)
    GameScene.layers["equips"].module:ReloadLimitPropsData(t)

end

function UILimitPropUse(t)
    print("5902 接受客户端数据")
    printT(t)

    if t.rewards and next(t.rewards) then
        GameScene:addUpdate(5901)
        GameScene:addUpdate(1200)
        showRewardPopupWindow(t.rewards,nil)
        GameScene.layers["equips"].module:ReloadLimitPropsData(t)
    --else
        --GameScene.layers["equips"].module:ReloadLimitPropsData(t)

    end

    if t.cid then
        UIRequest({type = 12002, id = t.cid})
    end

    UIRequest({type =1001})

end


function UIPropBuyQuery(t)
    print("7501 道具购买次数 接受客户端数据")
    printT(t)

    if gameWindows.windows["price_props"].show then 
        gameWindows.windows["price_props"].module:reload(t.data)
    end
end