--
-- Created by IntelliJ IDEA.
-- User: lipurpose
-- Date: 18-6-5
-- Time: 上午11:01
-- To change this template use File | Settings | File Templates.
--

function UIArtifactCast(t)
    print("5501,接受客户端数据")
    --printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1200)
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    if GameScene.layers["artifactCreate"].show then
        GameScene.layers["artifactCreate"].module:castSuccess(t)
    end
    UIRequest({type = 10323})
end

function UIArtifactCommpond(t)
    print("5502,接受客户端数据")
    --printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10031)
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    if GameScene.layers["artifactCreate"].show then
        GameScene.layers["artifactCreate"].module:commpondSuccess(t)
    end
    UIRequest({type = 10323})
end

function UIArtifactChange(t)
    print("5503,接受客户端数据")
    --printT(t)
    --GameScene.layers["slotsInfo"].module:artifactEquipSuccess(t.slot)
    if t.reward and next(t.reward) then
        updateDataLife(t.reward)
    end

    publicArtifactUpdata(t)
end

function UIArtifactOpenPos(t)
    print("5504,接受客户端数据")
    --printT(t)
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    if GameScene.layers["artifactMount"].show then
        GameScene.layers["artifactMount"].module:reloadData(t)
    end
    GameScene:addUpdate(1200)
    UIRequest({type = 1001})
    if t.artifact.sid then
        if GameScene.layers["slotsInfo"].show then
            UIRequest({type = 10021})
        else
            GameScene:addUpdate(10021)
        end
        GameScene:addUpdate(10322)
    end
end

function UIArtifactMountJewel(t)
    print("5505,接受客户端数据")
    --printT(t)
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    GameScene.layers["artifactList"].module:reloadJewelData({data = t.jewelData})
    if GameScene.layers["artifactMount"].show then
        GameScene.layers["artifactMount"].module:reloadData(t)
    end
    if t.artifact.sid then
        if GameScene.layers["slotsInfo"].show then
            UIRequest({type = 10021})
        else
            GameScene:addUpdate(10021)
        end
        GameScene:addUpdate(10322)
        GameScene:addUpdate(10023)
    end
    if t.mountType == 1 then
        runGamePrompt({msg = {color = ui.greenColor,str = gameConfig.strings:string_common("artifact",103)}})
    else
        runGamePrompt({msg = {color = ui.greenColor,str = gameConfig.strings:string_common("artifact",118)}})
    end
end

function UIJewelUpgrade(t)
    print("5506,接受客户端数据")
    --printT(t)
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    GameScene.layers["artifactList"].module:reloadJewelData({data = t.jewelData})
    if GameScene.layers["artifactMount"].show then
        GameScene.layers["artifactMount"].module:upDateJewel(t)
    end
    GameScene:addUpdate(1200)
    if t.artifact.sid then
        if GameScene.layers["slotsInfo"].show then
            UIRequest({type = 10021})
        else
            GameScene:addUpdate(10021)
        end
        GameScene:addUpdate(10322)
    end
    if t.isOk <= 0 then
        runGamePrompt({msg = gameConfig.strings:string_common("artifact",72)})
    else
        runGamePrompt({msg = {color = ui.greenColor,str = gameConfig.strings:string_common("artifact",137)}})
    end
end

function UIJewelCommpond(t)
    print("5507,接受客户端数据")
    --printT(t)
    GameScene:addUpdate(1200)
    GameScene:addUpdate(10021)
    GameScene.layers["artifactList"].module:reloadJewelData(t)
    if gameWindows.windows["jewelUp"].show then
        gameWindows.windows["jewelUp"].module:commpondSuccess(t)
    end
    if GameScene.layers["artifactMount"].show then
        GameScene.layers["artifactMount"].module:jewelUpdate(t)
    end
end

function UIArtifactCheck(t)
    print("5508,接受客户端数据")
    --printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1200)
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    if GameScene.layers["artifactCheck"].show then
        GameScene.layers["artifactCheck"].module:checkSuccess(t)
    end
    UIRequest({type = 1001})
    UIRequest({type = 10323})
end

function UIArtifactCheckTime(t)
    print("5509,接受客户端数据")
    --printT(t)
    if GameScene.layers["artifactCheck"].show then
        GameScene.layers["artifactCheck"].module:setTime(t)
    end
    if gameWindows.windows["checkTimeList"].show then
        gameWindows.windows["checkTimeList"].module:setTime(t)
    end
end


-- 一键打造
function UIUserArtifactOnceMake( t )
    print("5515,接受客户端数据")
    --printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1200)
    GameScene.layers["artifactList"].module:reloadData(t)
    if GameScene.layers["artifactCreate"].show then
        GameScene.layers["artifactCreate"].module:castSuccess(t)
    end
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    UIRequest({type = 10323})

    gameWindows:openWindow("onceCheckedPanel",t)
end
-- 一键鉴定
function UIUserArtifactOnceCheckup( t )
    print("5516,接受客户端数据")
    --printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1200)
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    if GameScene.layers["artifactCheck"].show then
        GameScene.layers["artifactCheck"].module:setArtifactData()
        GameScene.layers["artifactCheck"].module:resetArtifactSelect()
    end

    UIRequest({type = 1001})
    UIRequest({type = 10323})

    gameWindows:openWindow("onceCheckedPanel",t)
end
-- 一键重铸
function UIUserArtifactRecast( t )
    print("5517,接受客户端数据")
    --printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(1200)
    
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    if GameScene.layers["artifactCreate"].show then
        
        GameScene.layers["artifactCreate"].module.comppondNeedChange = true
        GameScene.layers["artifactCreate"].module:reloadData()
        -- GameScene.layers["artifactCreate"].module:updateItem()
    end
    UIRequest({type = 10323})
    
    gameWindows:openWindow("onceCheckedPanel",t)
end

-- 神器锁定
function UIUserArtifactLock( t )
    print("5518,接受客户端数据",t.isLock,t.artifactSid)

    --刷新阵容界面
    if t.data[tostring(t.artifactSid)].sid then
        if GameScene.layers["slotsInfo"].show then
            UIRequest({type = 10021})
        else
            GameScene:addUpdate(10021)
        end
        GameScene:addUpdate(10322)
    end

    --背包加锁
    if GameScene.layers["artifactList"].show then
        GameScene.layers["artifactList"].module:lockCallback(t)
    end
    
    --神器详情加锁
    if gameWindows.windows["artifactInfo"].show then
        gameWindows.windows["artifactInfo"].module:updateLockState(t)
    end

    --重铸加锁
    if gameWindows.windows["onceRecoin"].show then
        gameWindows.windows["onceRecoin"].module:lockCallback(t)
    end

    --强化选择消耗加锁
    if GameScene.layers["artifactStrengthen"].show then
        GameScene.layers["artifactStrengthen"].module:lockCallback(t)
    end

    if gameWindows.windows["onceAddStrengthen"].show then
        gameWindows.windows["onceAddStrengthen"].module:lockCallback(t)
    end

    --神器选择界面

    if GameScene.layers["artifactCreate"].show then
        GameScene.layers["artifactCreate"].module:reloadData(t)
    end

    if gameWindows.windows["artifactSelect"].show then
        gameWindows.windows["artifactSelect"].module:lockCallback(t)
    end

    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)

    if gameWindows.windows["qiankunluselect"].show then
        gameWindows.windows["qiankunluselect"].module:lockCallback(t)
    end

    --神技互换
    if GameScene.layers["artifactSkillSwop"].show then
        GameScene.layers["artifactSkillSwop"].module:lockCallback(t)
    end

    if GameScene.layers["artifactSkillStrengthen"].show then
        GameScene.layers["artifactSkillStrengthen"].module:lockCallback(t)
    end
    


    GameScene:addUpdate(10021)
    GameScene:addUpdate(10322)
    GameScene:addUpdate(10032)

end

-- 神器强化
function UIUserArtifactStrengthen( t )
    print("5519,接受客户端数据")
    --printT(t)
    if GameScene.layers["artifactStrengthen"].show then
        GameScene.layers["artifactStrengthen"].module:updateArtifactData(t)
    end
    
    publicArtifactUpdata(t)
    UIRequest({type = 10032})
end

-- 重生
function UIUserArtifactRenascence( t )
    print("5520,接受客户端数据")
    --printT(t)
    GameScene.layers["artifactList"].module:reloadData(t)

    -- if t.reward and table.getTableLength(t.reward) > 0 then
    --     gameWindows:openWindow("getStaff",t.reward)
    -- end

    

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:reloadPageData(t)
    end

    UIRequest({type = 10032})
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10322)
end

-- 神器开孔
function UIUserArtifactOpening( t )
    print("5540,接受客户端数据")
    --printT(t)
    if gameWindows.windows["artifactInfo"].show then
        gameWindows.windows["artifactInfo"].module:updateArtifactState(t.artifactData)
    end

    if GameScene.layers["artifactWash"].show then
        GameScene.layers["artifactWash"].module:updateReload(t)
        GameScene.layers["artifactWash"].module:setShowSkillGongming(1)
    end

    publicArtifactUpdata(t)

    GameScene:addUpdate(1200)
    UIRequest({type = 1001})

end
-- 技能洗练
function UIUserArtifactBaptize( t )
    print("5541,接受客户端数据")
    --printT(t)
    if GameScene.layers["artifactWash"].show then
        GameScene.layers["artifactWash"].module:updateReload(t)
        GameScene.layers["artifactWash"].module:setShowSkillGongming(2)
    end
    publicArtifactUpdata(t)

end
-- 技能替换
function UIUserArtifactBaptizeReplace( t )
    print("5542,接受客户端数据 技能替换")
    --printT(t)
    if GameScene.layers["artifactWash"].show then
        GameScene.layers["artifactWash"].module:updateReload(t)
        GameScene.layers["artifactWash"].module:setShowSkillGongming(1)
        GameScene.layers["artifactWash"].module:setShowSkillGongming(2)
    end

    publicArtifactUpdata(t)

end

function UIUserArtifactSkillWashCancel(t)
    print("5544,接受客户端数据 技能洗炼取消")
    --printT(t)
    if GameScene.layers["artifactWash"].show then
        GameScene.layers["artifactWash"].module:updateReload(t)
        GameScene.layers["artifactWash"].module:setShowSkillGongming(2)
    end
    publicArtifactUpdata(t)
end

function UIUserArtifactSkillExchange(t)
    print("5545,技能互换")
    --printT(t)
    if GameScene.layers["artifactSkillSwop"].show then
        GameScene.layers["artifactSkillSwop"].module:swopCallback(t.data)
    end
    
    UIRequest({type = 1001})

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10322)
    GameScene:addUpdate(10032)
end

function UIUserArtifactStrenExchange(t)
    print("5546,强化互换")
    --printT(t)
    if GameScene.layers["artifactSkillStrengthen"].show then
        GameScene.layers["artifactSkillStrengthen"].module:swopCallback(t.data)
    end
    
    UIRequest({type = 1001})

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10322)
    GameScene:addUpdate(10032)
    if GameScene:checkUpdate(10032) then
    end
end

function publicArtifactUpdata( t)

    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)

    if GameScene.layers["artifactCreate"].show then
        GameScene.layers["artifactCreate"].module:reloadData(t)
    end
    
    if GameScene.layers["slotsInfo"].show then
        UIRequest({type = 10021})
    else
        GameScene:addUpdate(10021)
    end
    GameScene:addUpdate(10322)
    GameScene:addUpdate(10032)
    GameScene:addUpdate(10023)
end

-- 技能点化
function UIUserArtifactSkillUp( t )
    print("5543,接受客户端数据")
    --printT(t)
    -- if GameScene.layers["artifactWash"].show then
    --     GameScene.layers["artifactWash"].module:updateReload(t)
    -- end
end


function UIAutoMoFuQuery(t)
    print("6405,接受客户端数据")
    --printT(t)
    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:updateAutoQuery(t)
    end
end

function UIAutoMoFuCompose(t)
    print("6406,接受客户端数据")
    --printT(t)
    if t.curState == 1 then
        if GameScene.layers["slotsInfo"].show then
            GameScene.layers["slotsInfo"].module:updateAutoCompose(t)
        end
    end
    
end


function UIJewelListData(t)
    print("10031,接受客户端数据")
    --printT(t)
    GameScene.layers["artifactList"].module:reloadJewelData(t)
    if gameWindows.windows["jewelSelect"].show then
        gameWindows.windows["jewelSelect"].module:reloadData(t)
    end
    if gameWindows.windows["artifactMount"].show then
        gameWindows.windows["artifactMount"].module:setData(t)
    end
    if gameWindows.windows["jewelUp"].show then
        gameWindows.windows["jewelUp"].module:reloadData(t)
    end
    if GameScene.layers["artifactMount"].show then
        GameScene.layers["artifactMount"].module:setArtifactData(t)
    end
    if GameScene.layers["artifactSkillStrengthen"].show then
        GameScene.layers["artifactSkillStrengthen"].module:setArtifactData(t)
    end
end

function UIArtifactData(t)
    print("10032,接受客户端数据")
    --printT(t)
    GameScene.layers["artifactList"].module:reloadData(t)
    GameScene.layers["qiankunlu"].module:setArtifactData(t.data)
    if GameScene.layers["artifactCreate"].show then
        GameScene.layers["artifactCreate"].module:reloadData(t)
    end
    if GameScene.layers["artifactCheck"].show then
        GameScene.layers["artifactCheck"].module:setArtifactData(t)
    end
    if gameWindows.windows["artifactSelect"].show then
        gameWindows.windows["artifactSelect"].module:reloadData(t)
    end
    if GameScene.layers["artifactMount"].show then
        GameScene.layers["artifactMount"].module:setArtifactData(t)
    end

    if GameScene.layers["artifactStrengthen"].show then
        GameScene.layers["artifactStrengthen"].module:setArtifactData(t)
    end
    
    if gameWindows.windows["onceRecoin"].show then
        gameWindows.windows["onceRecoin"].module:reloadData(t)
    end

     if GameScene.layers["artifactSkillStrengthen"].show then
        GameScene.layers["artifactSkillStrengthen"].module:setArtifactData(t)
    end
    
end

local pageconfig = {"attack","defence","life","skill"}
function CheckCanUpgrade(cid,hasNum,propNum,checkLevel)
    hasNum = hasNum or 0
    local config = gamedata.config.trump_gem[tostring(cid)]
    if not config then
        return false
    end
    local jewelData = GameScene.layers["artifactList"].module.jewelData.primeData--GameScene.layers["artifactList"].module.jewelData[GameScene.layers["artifactList"].module.jewelConfig[cfgType + 1]]
    if config.per_cid <= 0 then
        return false
    end

    if checkLevel then
        local jewelNConfig = gamedata.config.trump_gem[tostring(config.per_cid)]
        if GameScene.roleinfo.level < jewelNConfig.gem_lvbet then
            return false
        end
    end

    local useTable = ui.getIDandNUMs(config.gem_lv)
    for k,v in ipairs(useTable) do
        if v.cid == cid then
            if not jewelData[tostring(v.cid)] or jewelData[tostring(v.cid)].num + hasNum < v.num then
                return false
            end
        else
            if propNum < v.num then
                return false
            end
        end
    end
    
    return true
end

function GetArtifctScore(artifact)
    if artifact.isChecked <= 0 then
        return 0
    end
    local config = gamedata.config.trump[tostring(artifact.cid)]
    local totalScore = 0
    local config1 = gamedata.config.trump_rank[tostring(artifact.attr1)]
    totalScore  = totalScore + (config1 and config1.score or 0)
    config1 = gamedata.config.trump_rank[tostring(artifact.attr2)]
    totalScore  = totalScore + (config1 and config1.score or 0)
    local skillScore,skillNum = 0,0
    for i = 1,3 do
        if artifact["skill"..i] > 0 then
            local skillConfig = gamedata.config.breakskill[tostring(artifact["skill"..i])]
            skillScore = skillScore + (skillConfig and skillConfig.integral or 0)
            skillNum = skillNum + 1
        end
    end
    totalScore = totalScore + gamedata.config.trump_numskill[tostring(skillNum + 1)].weight * skillScore
    return math.floor(totalScore)
end










 �E  