--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-2
-- Time: 下午6:21
-- To change this template use File | Settings | File Templates.
--

function UISlotsAllInfo(t) 
    print("1002 接受客户端数据")
    -- printT(t)

    GameScene.protagonist = t.protagonist

    if t.protagonist.nexttime and t.protagonist.nexttime > 0 then
        gameTimer:rigistTime("leadTrainTimer",t.protagonist.nexttime)
    end

    GameScene.layers["hadescopy_map"].module:setSlotData(table.copy(t.slots))
    --GameScene.layers["slotsInfo"].module.slotdata = t.slots
    GameScene.layers["slotsInfo"].module:setSlotData(table.copy(t.slots))
    GameScene.layers["slotsInfo"].module.cheerdata = t.cheers
    GameScene.layers["slotsInfo"].module.slotgems = t.slotgems
    GameScene.layers["slotsInfo"].module.gems = t.gems
    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:reload()
    end

    GameScene.layers["qiankunlu"].module:setGeneralData(t.offgenerals)
    GameScene.layers["qiankunlu"].module:setEquipsData(t.OffEquip)
    GameScene.layers["qiankunlu"].module:setTreasuresData(t.OffTreasure)

    GameScene.layers["treasureup"].module:setTreasuresData(t.OffTreasure)

    GameScene.layers["equips"].module:setEquipDataByType("equips",t.equips)
    GameScene.layers["equips"].module:setEquipDataByType("treasures",t.treasures)
    GameScene.layers["equips"].module:setEquipDataByType("weapon",t.weapon)
    GameScene.layers["equips"].module:setEquipDataByType("head",t.head)
    GameScene.layers["equips"].module:setEquipDataByType("armor",t.armor)
    GameScene.layers["equips"].module:setEquipDataByType("accessory",t.accessory)
    GameScene.layers["equips"].module:setEquipDataByType("horse",t.horse)
    GameScene.layers["equips"].module:setEquipDataByType("treasure",t.treasure)

    GameScene.layers["equipsup"].module:setEquipsData(t.slotequips)

    GameScene.layers["generals"].module:ReloadGenerals(t.generals)
    GameScene.layers["generalup"].module:ReloadGenerals(t.generals)

    GameScene.layers["soul"].module:relaodList("all",t.souls)
    GameScene.layers["soul"].module:relaodList("star2",t.souls2)
    GameScene.layers["soul"].module:relaodList("star3",t.souls3)
    GameScene.layers["soul"].module:relaodList("star4",t.souls4)
    GameScene.layers["soul"].module:relaodList("star5",t.souls5)

    GameScene.layers["mofulist"].module:mofudataReload(t.gems)
    GameScene.layers["mofulist"].module:slotmofudataReload(t.slotgems)

    GameScene.layers["qiankunlu"].module:setArtifactData(t.artifacts)
    

    -- GameScene.layers["equipstage"].module:setEquipstagedData(t.equipstage)

    

    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:initSlot()
    end

    if GameScene.layers["tokenMain"].show then
        GameScene.layers["tokenMain"].module:pageDataCallback("token", "reloadSlotData")
    end

    if t.slotrequireparam and t.slotrequireparam == "error" then
        GameScene:UpdatePresentLayer()
    end
end

function UIGeneralOnSlot(t)
    print("在阵武将1024 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
end


function UIGeneralSlot(t)
    print("在阵武将1027 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)

    if GameScene.layers["slotsInfo"].show then
        UIRequest({type = 10021})
    else
        GameScene:addUpdate(10021)
    end
end

function UIMagicstoneUp(t)
    print("神石升级1130 接受客户端数据")
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)
    GameScene.layers["slotsInfo"].module.changedstone = t.changedstone
    GameScene:UpdatePresentLayer()
    UIRequest({type = 10322})
end

function UISlots(t)
    print("10021 接受客户端数据")
    printT(t)

    if t.slots then
        GameScene.layers["hadescopy_map"].module:setSlotData(table.copy(t.slots))
        GameScene.layers["slotsInfo"].module:setSlotData(table.copy(t.slots))
    end

    if t.cheers then
        GameScene.layers["slotsInfo"].module.cheerdata = t.cheers
    end
    
    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:reload()
    end
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:initSlot()
    end

    if GameScene.layers["safemask"].show then
        GameScene.layers["safemask"].module:reloadSlotData()
    end

    if GameScene.layers["tokenMain"].show then
         GameScene.layers["tokenMain"].module:pageDataCallback("token", "reloadSlotData")
    end

    if GameScene.layers["exclusiveArtifact"].show then
        GameScene.layers["exclusiveArtifact"].module:reload()
    end


    UIRequest({type = 1032})
end

function UISlotChangeEquip(t)
    print("更换装备1005 接受客户端数据")
    --printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)

    local equiptype =  gamedata.config.equip[tostring(t.equipCID)].type
    if equiptype == "horse" or equiptype == "treasure" then
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offtreasures")
    else
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10025,"slotequips")
        GameScene:addUpdate(10025,"offequips")
        if not GameScene:checkUpdate(10025,"slotequips") then

        end
    end
    GameScene:addUpdate(10025,equiptype)
    GameScene:UpdatePresentLayer()

    UIRequest({type = 10322})
end

function UISlotChangeSoul(t)
    print("更换武魂1006 接受客户端数据")
    --printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    for k,v in pairs(t.changes) do
        GameScene:addUpdate(10026,k)
    end
    GameScene:addUpdate(10026,"all")
    GameScene:UpdatePresentLayer()
    UIRequest({type = 10322})
end

function UIQuickEquip(t)
    print("一键装备1007 接受客户端数据")
    --printT(t)
    if t.method == 1 then
        if not next(t.changeTable) then
            runGamePrompt({msg = "无装备可更换"})
        else
            GameScene:addUpdate(10021)
            GameScene:addUpdate(10023)
            for k,v in pairs(t.changeTable) do
                if v == "horse" or v == "treasure" then
                    GameScene:addUpdate(10025,"treasures")
                    GameScene:addUpdate(10025,"offtreasures")
                else
                    GameScene:addUpdate(10025,"equips")
                    GameScene:addUpdate(10025,"slotequips")
                    GameScene:addUpdate(10025,"offequips")
                    if not GameScene:checkUpdate(10025,"slotequips") then

                    end
                end
                GameScene:addUpdate(10025,v)
            end
            GameScene:UpdatePresentLayer()
        end
    elseif t.method == 2 then
        if not next(t.changeTable) then
            runGamePrompt({msg = "无命格可更换"})
        else
            GameScene:addUpdate(10021)
            GameScene:addUpdate(10023)
            for k,v in pairs(t.changeTable) do
                GameScene:addUpdate(10026,k)
            end
            GameScene:addUpdate(10026,"all")

            GameScene:UpdatePresentLayer()
        end
    end
    UIRequest({type = 10322})
end

function UIUpgradeSkill(t)
    print("技能升级1008 接受客户端数据")
    --printT(t)
    --resetSkill_up(t,function() GameScene:UpdatePresentLayer() end)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)
    UIRequest({type = 1002})
    GameScene:UpdatePresentLayer()

    if gameWindows.windows["generalInfo"].show then
        gameWindows.windows["generalInfo"].module:reloaddata(t)
    end

end

function UISlotArrange(t)
    print("1009 接受客户端数据")

    GameScene:addUpdate(10025,"slotequips")
    GameScene:addUpdate(10023)
    
    GameScene.layers["hadescopy_map"].module:setSlotData(table.copy(t.slots))
    GameScene.layers["slotsInfo"].module:setSlotData(table.copy(t.slots))
    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:reload()
    end

    if GameScene.layers["deployment"].show then
        GameScene.layers["deployment"].module:reloadData(table.copy(t.slots))
    end

    if not GameScene:checkUpdate(10025,"slotequips") then

    end

end


function UISlotChange(t)
    print("1003 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10211)

    if t.changelslot.pos2 then
    else
        GameScene:addUpdate(10024)
    end
    GameScene:addUpdate(10025,"treasures")
    GameScene:addUpdate(10025,"offtreasures")
    GameScene:addUpdate(10025,"equips")
    GameScene:addUpdate(10025,"offequips")
    GameScene:addUpdate(10025,"weapon")
    GameScene:addUpdate(10025,"head")
    GameScene:addUpdate(10025,"armor")
    GameScene:addUpdate(10025,"accessory")
    GameScene:addUpdate(10025,"treasure")
    GameScene:addUpdate(10025,"horse")
    GameScene:addUpdate(10025,"slotequips")

    GameScene:UpdatePresentLayer()
end

function UICheerChange(t)
    print("1004 接受客户端数据")

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(10211)
    GameScene:UpdatePresentLayer()
    UIRequest({type = 10322,param = {"cheer"}})
end



function UICheckOtherSlotsInfo(t)
    print("1020其他人阵容， 接受客户端数据")
    printT(t)

    if GameScene.templayers["other_slotinfo"].show then
        GameScene.templayers["other_slotinfo"]:reload(t.slots,t.cheers,t.protagonist or {},t.slotgems,t.gems,t.exclusiveArtifactDatas,t.exclusiveArtifactQiLingDatas)
    end
end

function UIWorldWarChampionSlotInfo(t)
    print("4719 跨服战冠军阵容， 接受客户端数据")
    printT(t)

    if GameScene.templayers["other_slotinfo"].show then
        GameScene.templayers["other_slotinfo"]:reload(t.slots,t.cheers,t.protagonist or {},t.slotgems,t.gems,t.exclusiveArtifactDatas,t.exclusiveArtifactQiLingDatas)
    end
end

function UISomeIds(t)
    print("1031 接受客户端数据")
    --printT(t)

    if GameScene.layers["chat"].show then
        GameScene.layers["chat"].module:reloadFreeNum(t)
    end
end

function UISlotGems(t)
    print("10022 接受客户端数据")
    --printT(t)
    GameScene.layers["slotsInfo"].module.slotgems = t.slotgems
    GameScene.layers["mofulist"].module:slotmofudataReload(t.slotgems)
    GameScene.layers["mofulist"].module:mofudataReload(t.gems)
    if GameScene.layers["mofulist"].show then
        GameScene.layers["mofulist"].module:reloadstatus()
    end
    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:reload()
    end
    -- if gameWindows.windows["mofuproperty"].show then
    --     gameWindows.windows["mofuproperty"].module:slotGemsReload(t.slotgems)
    -- end
end

function UIGems(t)
    print("10028 接受客户端数据")
    --printT(t)
    GameScene.layers["slotsInfo"].module.gems = t.gems
    GameScene.layers["mofulist"].module:mofudataReload(t.gems)
    if GameScene.layers["mofulist"].show then
        print("ui10028mofulist")
        GameScene.layers["mofulist"].module:reloadstatus()
    end
    if GameScene.layers["slotsInfo"].show then
        GameScene.layers["slotsInfo"].module:reload()
    end
end


--灵阵图
function UISlotSpiritQuery(t)
    print("4200 接受客户端数据")
    printT(t)

    if GameScene.layers["deployment"].show then
        GameScene.layers["deployment"].module:reloadSlotSpirit(t.slotSpirit)
    end

end

function UISlotSpiritUse(t)
    print("4201 接受客户端数据")
    printT(t)

    if GameScene.layers["deployment"].show then
        GameScene.layers["deployment"].module:reloadSlotSpirit(t.slotSpirit)
    end

end

function UISlotSpiritChange(t)
    print("4203 接受客户端数据")
    printT(t)

    if GameScene.layers["deployment"].show then
        GameScene.layers["deployment"].module:reloadSlotSpirit(t.slotSpirit)
    end

end

function UISlotSpiritAdditionQuery(t)
    print("4204 接受客户端数据")
    printT(t)

    if t.data then
        if t.opt and t.opt == "addmain" then
            if gameWindows.windows["deploymentUp"].show then
                gameWindows.windows["deploymentUp"].module:reload(t.data)
            else
                gameWindows:openWindow("deploymentUp",t.data)
            end
        elseif t.opt and t.opt == "up" then
            if gameWindows.windows["deploymentLevelUp"].show then
                gameWindows.windows["deploymentLevelUp"].module:reloadAddition(t.data)
            end
        end
    end
end

function UISlotSpiritLevelup(t)
    print("4202 接受客户端数据")
    printT(t)

    GameScene:addUpdate(1200)
    UIRequest({type =1001})

    if GameScene.layers["deployment"].show then
        GameScene.layers["deployment"].module:reloadSlotSpirit(t.slotSpirit)
    end

    if gameWindows.windows["deploymentLevelUp"].show then
        gameWindows.windows["deploymentLevelUp"].module:reload(t.slotSpirit)
    end

    UIRequest({type = 4204, opt = "up"})

end

--
function UISlotCoverQuery(t)
    print("3730 接受客户端数据")
    printT(t)

    GameScene.layers["slotsInfo"].module.safemask = t.safemask
    if GameScene.layers["safemask"].show then
        GameScene.layers["safemask"].module:ReloadData(t)
        GameScene:checkUpdate(10021)
    end

end

function UISlotCoverup(t)
    print("3731 接受客户端数据")
    printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)
    UIRequest({type =1001})

    if GameScene.layers["safemask"].show then
        GameScene.layers["safemask"].module:ReloadUpData()
    end

    UIRequest({type = 3730})
    UIRequest({type = 3732})
    UIRequest({type = 10322,param = {"slotsinfo"}})
end

function UISlotCoverMasterQuery(t)
    print("3732 接受客户端数据")
    printT(t)

    if GameScene.layers["safemask"].show then
        GameScene.layers["safemask"].module:ReloadMasterData(t)
    end

end

function UIPureSlots(t)
    print("70110 阵容数据")
    printT(t)
    if gameWindows.windows["babelTowerEnter"].show then
        gameWindows.windows["babelTowerEnter"].module:judgeEnterCondition(t.slots)
    end
end


--
function UISlotCoverLevel2Up(t)
    print("3735 接受客户端数据")
    printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)
    UIRequest({type =1001})

    if GameScene.layers["safemask"].show then
        GameScene.layers["safemask"].module:ReloadEvolveData()
    end

    UIRequest({type = 3730})
    UIRequest({type = 3732})

    UIRequest({type = 10322,param = {"slotsinfo"}})
end

--
function UISlotCoverFeiSheng(t)
    print("3736 接受客户端数据")
    printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(1200)
    UIRequest({type =1001})

    if GameScene.layers["safemask"].show then
        GameScene.layers["safemask"].module:ReloadFeiShengData()
    end

    UIRequest({type = 3730})
    UIRequest({type = 3732})

    UIRequest({type = 10322,param = {"slotsinfo"}})
end

function UIGeneralAwakenRebirth(t)
    print("8096 接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)

    UIRequest({type = 8097, iid = t.iid})
    
end


function UIQueryGeneralById(t)
    print("8097 接受客户端数据")
    printT(t)

    GameScene:addUpdate(1200)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)
    GameScene:addUpdate(10024)
    GameScene:addUpdate(1012)

    if GameScene.layers["generalup"].show then
        GameScene.layers["generalup"].module:ReloadData()
    end
end

function UIGeneralUpStarRebirth(t)
    print("8301 接受客户端数据")
    printT(t)

    showRewardPopupWindow(t.reward,nil,function()
        UIRequest({type = 1001})
    end)

    UIRequest({type = 8097, iid = t.iid})
    
end�@  