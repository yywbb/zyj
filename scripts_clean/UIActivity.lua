--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-26
-- Time: 上午10:28
-- To change this template use File | Settings | File Templates.
--
local mainactivitypage = {
    page4 = "activityranknode",
    page5 = "activityrechargenode",
    page6 = "activityhefunode", 
}

function UIActivityQuery(t)
    print("活动2000，接受客户端数据")
    printT(t)
    GameScene.playerreturnactivity = 0
    GameScene.fashionactivity = 0
    GameScene.fashionactivity2 = 0
    GameScene.fashionactivity3 = 0
    GameScene.huodongactivity = 0
    GameScene.nailiactivity = 0
    GameScene.cp_fashionactivity2 = 0
    GameScene.chongbangActivity = {}
    GameScene.speedgiftctivity = 0
    GameScene.discountgiftctivity = 0
    GameScene.hefuactivityopen = 0
    GameScene.sculptureactivityopen = 0

    if t.dailyCpActivityTimeStatus then
        GameScene.layers["activity"].module:setDailyCpActivityTimeStatus(t.dailyCpActivityTimeStatus)
    end

    for k,v in pairs(t.status) do
        if v.id == 62 and v.status == 1 then
            GameScene.fashionactivity3 = 1
        elseif v.id == 52 and v.status == 1 then
            GameScene.fashionactivity2 = 1
        elseif v.id == 88 and v.status == 1 then
            GameScene.fashionactivity2 = 1
            GameScene.cp_fashionactivity2 = 1
        elseif v.id == 43 and v.status == 1 then
            GameScene.fashionactivity = 1
        elseif v.id == 51 and v.status == 1 then
            GameScene.huodongactivity = 1
        elseif v.id == 54 and v.status == 1 then
            GameScene.nailiactivity = 1
        elseif v.id == 58 and v.status == 1 then
            GameScene.playerreturnactivity = 1
        elseif v.id >= 104 and v.id <= 106 and v.status == 1 then
            table.insert(GameScene.chongbangActivity,v.id + 266)
        elseif v.id >= 114 and v.id <= 115 and v.status == 1 then
            table.insert(GameScene.chongbangActivity,v.id + 273)
        elseif v.id >= 123 and v.id <= 128 and v.status == 1 then
            -- 129神器冲榜不显示弹窗
            table.insert(GameScene.chongbangActivity,v.id + 282)
        elseif v.id == 11 and v.status == 1 then
            table.insert(GameScene.chongbangActivity,113)
        elseif v.id >= 144 and v.id <= 147 and v.status == 1 then
            table.insert(GameScene.chongbangActivity,v.id + 401)
        elseif v.id >= 150 and v.id <= 152 and v.status == 1 then
            GameScene.discountgiftctivity = v.id
        elseif v.id >= 153 and v.id <= 155 and v.status == 1 then
            GameScene.speedgiftctivity = v.id
        elseif v.id == 119 and v.status == 1 then --合服在线好礼
            GameScene.hefuactivityopen = v.id
        elseif v.id == 180 and v.status == 1 then
            GameScene.sculptureactivityopen = 1
        end
        print(k,v)
        local tempconfig = gamedata.config.activity_time[tostring(v.id)]
        -- printT(tempconfig,"tempconfig===")
        -- print("activity====",tempconfig.systemid,v.status)
        if v.status == 0 then
            if not GameScene.openactivityinpost then
                GameScene.openactivityinpost = {}
                GameScene.openactivityinpost[tostring(tempconfig.systemid)]=v.status
            else
                GameScene.openactivityinpost[tostring(tempconfig.systemid)]=v.status
            end
        end
    end

    if gamedata.config.build[tostring(274)] and gamedata.config.build[tostring(274)].switch and gamedata.config.build[tostring(274)].switch == 1 then
        GameScene.fashionactivity2 = 0
    end    

    if not t.page then return end

    if t.id then
        if not t.status[tostring(t.id)] or t.status[tostring(t.id)].status ~= 1 then
            runGamePrompt({msg = "活动关闭!!"})
            return
        end
    end

    GameScene.layers["activity"].module:makepageconfig()


    local hasopen = false
    for k,v in pairs(t.status) do
        if v.status == 1 and GameScene.layers["activity"].module["pageTable"..t.page][v.id] then
            hasopen = true
            break
        end
    end

    if t.ischeck and t.ischeck == 1 then
        if hasopen then
            if GameScene.layers["main"].show  and mainactivitypage["page"..t.page] then
                GameScene.layers["main"].module:setNode(true,mainactivitypage["page"..t.page])
            end
        else
            if GameScene.layers["main"].show  and mainactivitypage["page"..t.page] then
                GameScene.layers["main"].module:setNode(false,mainactivitypage["page"..t.page])
            end
        end    
    else
        if hasopen then
            if not GameScene.layers["activity"].show then
                GameScene:shiftLayer("activity","up")
                GameScene.layers["activity"].module:reload(t)
            else
                GameScene.layers["activity"].module:reload(t)
            end
        else
            runGamePrompt({msg = "没有开启的"..gameConfig.strings:string_common("activity",20 + t.page)})
        end
    end
end

function UIActivityEveryday(t)
    print("UIActivityEverydayCallBack")
    if GameScene.layers["activity"].module.pageTable[51] then
        GameScene.layers["activity"].module.pageTable[51].module:reloaddata()
    end
end

function UIActivityIsOpen(t)
    print("活动是否开启")
    printT(t)

    if t.id == 100 then
        if GameScene.layers["main"].show then
            GameScene.layers["main"].module:setNode(t.status==1,"chaozhinode")
        end
    end
end

function UIActivityNewRankQuery(t)
    print("消息5601，接受客户端数据")
    printT(t)
    if t.ActivityRankId then
        if GameScene.layers["activity"].module.pageTable[t.ActivityRankId].module.show then
            GameScene.layers["activity"].module.pageTable[t.ActivityRankId].module:reloadData(t.data)
        end
    end
end

function UIActivityNewRankGet(t)
    print("消息5602，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[114].module.show then
        GameScene.layers["activity"].module.pageTable[114].module:reloadData(t)
    end
end

function UIActivityPowerGrowthX2(t)
    print("消息5603，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[115].module.show then
        GameScene.layers["activity"].module.pageTable[115].module:reloadData(t)
    end
end