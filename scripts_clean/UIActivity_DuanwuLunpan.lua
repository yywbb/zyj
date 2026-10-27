--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/6/26
-- Time: 下午7:42
-- To change this template use File | Settings | File Templates.
--

function UIDuanWuQuery(t)
    print("端午轮盘3300，接受客户端数据")

    printT(t)

    if  GameScene.layers["activity"].module.pageTable[38] then
        GameScene.layers["activity"].module.pageTable[38].module:reloaddata(t.maindata)
    end

end

function UIDuanWuLotteryQuery(t)
    print("端午轮盘3301，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[38] then
        GameScene.layers["activity"].module.pageTable[38].module:actionShowSet(t)
    end



    -- if  GameScene.layers["activity"].module.pageTable[38] then
    --     GameScene.layers["activity"].module.pageTable[38].module:reloaddata(t.maindata)
    -- end


    -- if t.reward then
    --     showRewardPopupWindow(t.reward, nil, nil)
    -- end 

    -- local scorestring = gameConfig.strings:string_common("lunpan",1)..(gamedata.config.global_kv.dragonboatfestival_number.value or 0)
    -- runGamePrompt({msg = scorestring})
    -- UIRequest({type = 1001})
end

function UIDuanWuDuihuan(t)
    print("端午轮盘3302，接受客户端数据")
    if gameWindows.windows["lunpanchange"].show then
        gameWindows.windows["lunpanchange"].module:changeinit(t.maindata.pointScore)
    end

    if  GameScene.layers["activity"].module.pageTable[38] then
        GameScene.layers["activity"].module.pageTable[38].module:reloaddata(t.maindata)
    end
    
    if t.reward then
        showRewardPopupWindow(t.reward, nil, nil)
    end
    UIRequest({type = 1001})
end


function UITurntableQuery(t)
    print("4630，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[63] then
        GameScene.layers["activity"].module.pageTable[63].module:reloaddata(t.turntable)
    end

end

function UITurntableLottery(t)
    print("4631，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[63] then
        GameScene.layers["activity"].module.pageTable[63].module:actionShowSet(t)
    end

end


--
function UIDivideStallCarnivalQuery(t)
    print("4650，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[64] and GameScene.layers["activity"].module.pageTable[64].module.show then
        GameScene.layers["activity"].module.pageTable[64].module:reloaddata(t.carnival)
    end

end

function UIDivideStallCarnivalDraw(t)
    print("4651，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[64] and GameScene.layers["activity"].module.pageTable[64].module.show then
        GameScene.layers["activity"].module.pageTable[64].module:actionShowSet(t)
    end

end

--
function UIIntegralTurntableQuery(t)
    print("4660，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[66] and GameScene.layers["activity"].module.pageTable[66].module.show then
        GameScene.layers["activity"].module.pageTable[66].module:reloaddata(t.integralturntable)
    end

end

function UIIntegralTurntableLuckDraw(t)
    print("4661，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[66] and GameScene.layers["activity"].module.pageTable[66].module.show then
        GameScene.layers["activity"].module.pageTable[66].module:actionShowSet(t)
    end

end

function UIRechargeScore(t)
    print("118，接受客户端数据")
    printT(t)

    if t.reward and next(t.reward) then
        showRewardPopupWindow(t.reward, nil, nil)
        UIRequest({type = 1001})
    end

    --UIRequest({type = 4660})

end

--
function UITurntableWorldQuery(t)
    print("4635，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[73] then
        GameScene.layers["activity"].module.pageTable[73].module:reloaddata(t.turntable)
    end

end

function UITurntableWorldDraw(t)
    print("4636，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[73] then
        GameScene.layers["activity"].module.pageTable[73].module:actionShowSet(t)
    end

end


function UITurntableRecord(t)
    print("4885，接受客户端数据")
    printT(t)

    if gameWindows.windows["turntablerecord"].show then
        gameWindows.windows["turntablerecord"].module:reload(t)
    end

end

function UITurntableRecordCommon(t)
    print("5346，接受客户端数据")
    printT(t)

    if gameWindows.windows["turntablerecord"].show then
        gameWindows.windows["turntablerecord"].module:reload(t)
    end
end


function UICPTurntableQuery(t)
    print("5037，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[90] then
        GameScene.layers["activity"].module.pageTable[90].module:reloaddata(t)
    end

end

function UICPTurntableLottery(t)
    print("5038，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[90] then
        GameScene.layers["activity"].module.pageTable[90].module:actionShowSet(t)
    end

end


--
function UICPIntegralTurntableQuery(t)
    print("5057，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[97] and GameScene.layers["activity"].module.pageTable[97].module.show then
        GameScene.layers["activity"].module.pageTable[97].module:reloaddata(t)
    end

end

function UICPIntegralTurntableLuckDraw(t)
    print("5058，接受客户端数据")
    printT(t)

    if  GameScene.layers["activity"].module.pageTable[97] and GameScene.layers["activity"].module.pageTable[97].module.show then
        GameScene.layers["activity"].module.pageTable[97].module:actionShowSet(t)
    end

end