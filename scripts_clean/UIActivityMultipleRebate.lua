--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 16/2/17
-- Time: 上午9:59
-- To change this template use File | Settings | File Templates.
--


function UIMonthGrowQuery(t)
    print("月成长基金3680，接受客户端数据")
    -- printT(t)
    if GameScene.layers["activity"].module.openPageTable[101] and GameScene.layers["activity"].module.pageTable[101] and GameScene.layers["activity"].module.pageTable[101].module.show then
        GameScene.layers["activity"].module.pageTable[101].module:reloaddata(t)
    end   
	
end

function UIMonthGrowGetReward(t)
    print("月成长基金3681，接受客户端数据")
   	-- printT(t) 
     if GameScene.layers["activity"].module.pageTable[101] and GameScene.layers["activity"].module.pageTable[101].module.show then
        GameScene.layers["activity"].module.pageTable[101].module:reloaddata(t)
    end   	
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end

function UIMonthGrowWelfareQuery(t)
    print("月成长基金3682，接受客户端数据")
   	-- printT(t) 
    if GameScene.layers["activity"].module.openPageTable[22] and GameScene.layers["activity"].module.pageTable[22] and GameScene.layers["activity"].module.pageTable[22].module.show then
        GameScene.layers["activity"].module.pageTable[22].module:reloaddata(t)
    end

end

function UIMonthGrowWelfareGetReward(t)
    print("月成长基金3683，接受客户端数据")
   	-- printT(t) 
    if GameScene.layers["activity"].module.pageTable[22] and GameScene.layers["activity"].module.pageTable[22].module.show then
        GameScene.layers["activity"].module.pageTable[22].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end


function UIMonthGrowQueryX1(t)
    print("月成长基金3684，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.openPageTable[112] and GameScene.layers["activity"].module.pageTable[112] and GameScene.layers["activity"].module.pageTable[112].module.show then
        GameScene.layers["activity"].module.pageTable[112].module:reloaddata(t)
    end   
    
end

function UIMonthGrowGetRewardX1(t)
    print("月成长基金3685，接受客户端数据")
     printT(t) 
     if GameScene.layers["activity"].module.pageTable[112] and GameScene.layers["activity"].module.pageTable[112].module.show then
        GameScene.layers["activity"].module.pageTable[112].module:reloaddata(t)
    end     
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end

function UIMonthGrowWelfareQueryX1(t)
    print("月成长基金3686，接受客户端数据")
     printT(t) 
    if GameScene.layers["activity"].module.openPageTable[113] and GameScene.layers["activity"].module.pageTable[113] and GameScene.layers["activity"].module.pageTable[113].module.show then
        GameScene.layers["activity"].module.pageTable[113].module:reloaddata(t)
    end

end

function UIMonthGrowWelfareGetRewardX1(t)
    print("月成长基金3687，接受客户端数据")
     printT(t) 
    if GameScene.layers["activity"].module.pageTable[113] and GameScene.layers["activity"].module.pageTable[113].module.show then
        GameScene.layers["activity"].module.pageTable[113].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end

function UIMonthGrowQueryX2(t)
    print("月成长基金5531，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.openPageTable[117] and GameScene.layers["activity"].module.pageTable[117] and GameScene.layers["activity"].module.pageTable[117].module.show then
        GameScene.layers["activity"].module.pageTable[117].module:reloaddata(t)
    end   
    
end

function UIMonthGrowGetRewardX2(t)
    print("月成长基金5532，接受客户端数据")
     printT(t) 
     if GameScene.layers["activity"].module.pageTable[117] and GameScene.layers["activity"].module.pageTable[117].module.show then
        GameScene.layers["activity"].module.pageTable[117].module:reloaddata(t)
    end     
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end

function UIMonthGrowWelfareQueryX2(t)
    print("月成长基金5533，接受客户端数据")
     printT(t) 
    if GameScene.layers["activity"].module.openPageTable[118] and GameScene.layers["activity"].module.pageTable[118] and GameScene.layers["activity"].module.pageTable[118].module.show then
        GameScene.layers["activity"].module.pageTable[118].module:reloaddata(t)
    end

end

function UIMonthGrowWelfareGetRewardX2(t)
    print("月成长基金5534，接受客户端数据")
     printT(t) 
    if GameScene.layers["activity"].module.pageTable[118] and GameScene.layers["activity"].module.pageTable[118].module.show then
        GameScene.layers["activity"].module.pageTable[118].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end

--神奇基金
function UIMagicFundQuery(t)
    print("神奇基金 3688 接受客户端数据")
    printT(t) 

    if GameScene.layers["activity"].module.openPageTable[193] and GameScene.layers["activity"].module.pageTable[193] and GameScene.layers["activity"].module.pageTable[193].module.show then
        GameScene.layers["activity"].module.pageTable[193].module:reloaddata(t)
    end  
end

function UIMagicFundReward(t)
    print("神奇基金 3689 接受客户端数据")
    printT(t) 

    if GameScene.layers["activity"].module.pageTable[193] and GameScene.layers["activity"].module.pageTable[193].module.show then
        GameScene.layers["activity"].module.pageTable[193].module:reloaddata(t)
    end     
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
end

function UIShareActivityQuery(t)
    print("分享3690，接受客户端数据")
   	-- printT(t) 
    if GameScene.layers["activity"].module.pageTable[23] and GameScene.layers["activity"].module.pageTable[23].module.show then
        GameScene.layers["activity"].module.pageTable[23].module:reloaddata(t)
    end	
end

function UIShareActivity(t)
    print("分享3691，接受客户端数据")
   	-- printT(t) 
    if GameScene.layers["activity"].module.pageTable[23] and GameScene.layers["activity"].module.pageTable[23].module.show then
        GameScene.layers["activity"].module.pageTable[23].module:reloaddata(t)
        -- return 0, 503, {type = 503, msg = "分享成功" }
        runGamePrompt({msg = "分享成功"})
    end
    -- showRewardPopupWindow(t.reward, nil,nil)	

end


--
function UITitbitDiscountQury(t)
    print("珍品折扣4010，接受客户端数据")
    -- printT(t) 
    if GameScene.layers["activity"].module.pageTable[24] and GameScene.layers["activity"].module.pageTable[24].module.show then
        GameScene.layers["activity"].module.pageTable[24].module:reloaddata(t)
    end         

end

function UITitbitDiscountBuy(t)
    print("珍品折扣4011，接受客户端数据")
    -- printT(t) 
    if GameScene.layers["activity"].module.pageTable[24] and GameScene.layers["activity"].module.pageTable[24].module.show then
        GameScene.layers["activity"].module.pageTable[24].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end

--x1
function UITitbitDiscountX1Qury(t)
    print("珍品折扣4012，接受客户端数据")
    -- printT(t)
    if GameScene.layers["activity"].module.pageTable[32] and GameScene.layers["activity"].module.pageTable[32].module.show then
        GameScene.layers["activity"].module.pageTable[32].module:reloaddata(t)
    end

end

function UITitbitDiscountX1Buy(t)
    print("珍品折扣4013，接受客户端数据")
    -- printT(t)
    if GameScene.layers["activity"].module.pageTable[32] and GameScene.layers["activity"].module.pageTable[32].module.show then
        GameScene.layers["activity"].module.pageTable[32].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end

--x2
function UITitbitDiscountX2Qury(t)
    print("珍品折扣4014，接受客户端数据")
    -- printT(t)
    if GameScene.layers["activity"].module.pageTable[33] and GameScene.layers["activity"].module.pageTable[33].module.show then
        GameScene.layers["activity"].module.pageTable[33].module:reloaddata(t)
    end

end

function UITitbitDiscountX2Buy(t)
    print("珍品折扣4015，接受客户端数据")
    -- printT(t)
    if GameScene.layers["activity"].module.pageTable[33] and GameScene.layers["activity"].module.pageTable[33].module.show then
        GameScene.layers["activity"].module.pageTable[33].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end

--x3
function UITitbitDiscountX3Qury(t)
    print("珍品折扣4016，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[34] and GameScene.layers["activity"].module.pageTable[34].module.show then
        GameScene.layers["activity"].module.pageTable[34].module:reloaddata(t)
    end

end

function UITitbitDiscountX3Buy(t)
    print("珍品折扣4017，接受客户端数据")
    -- printT(t)
    -- return { type = 4017, reward = gamedata:SomethingProcess(SomeThings), activityTreasure = gamedata.cache.activityTreasureX3, exchange = true, equiphaschange = equiphaschange, index = index, pageid = pageid}
    --
    if t.index and gamedata.config.exchange_shop and gamedata.config.exchange_shop[tostring(t.pageid)] and gamedata.config.exchange_shop[tostring(t.pageid)][tostring(t.index)].open and gamedata.config.exchange_shop[tostring(t.pageid)][tostring(t.index)].open > 0 then
        local reward = t.reward["1"]
        if reward then
            local cid = reward.cid
            local num = reward.num
            local propConfig = gamedata.config.props[tostring(cid)]
            local function cb()
                UIRequest({type= 1201, cid = cid,num = num})
            end
            local rich = {
                {fontID = 48,content = "是否直接使用",},
                {fontID = 9,content =  propConfig.name,},
                {fontID = 48,content = "×"..num,},
            }
            gameWindows:openWindow("confirm",{rich = rich}, cb)
        end
    end
    --

    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})
    UIRequest({type = 4016})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end


--cp
--
function UICPTitbitDiscountQury(t)
    print("5030，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[85] and GameScene.layers["activity"].module.pageTable[85].module.show then
        GameScene.layers["activity"].module.pageTable[85].module:reloaddata(t)
    end

end

function UICPTitbitDiscountBuy(t)
    print("5031，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[85] and GameScene.layers["activity"].module.pageTable[85].module.show then
        GameScene.layers["activity"].module.pageTable[85].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end



--cpX1
--
function UICPTitbitDiscountX1Qury(t)
    print("4018，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[157] and GameScene.layers["activity"].module.pageTable[157].module.show then
        GameScene.layers["activity"].module.pageTable[157].module:reloaddata(t)
    end

end

function UICPTitbitDiscountX1Buy(t)
    print("4019，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[157] and GameScene.layers["activity"].module.pageTable[157].module.show then
        GameScene.layers["activity"].module.pageTable[157].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end


--cpX2
--
function UICPTitbitDiscountX2Qury(t)
    print("4020，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[158] and GameScene.layers["activity"].module.pageTable[158].module.show then
        GameScene.layers["activity"].module.pageTable[158].module:reloaddata(t)
    end

end

function UICPTitbitDiscountX2Buy(t)
    print("4021，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[158] and GameScene.layers["activity"].module.pageTable[158].module.show then
        GameScene.layers["activity"].module.pageTable[158].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end


--cpX3
--
function UICPTitbitDiscountX3Qury(t)
    print("4022，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[159] and GameScene.layers["activity"].module.pageTable[159].module.show then
        GameScene.layers["activity"].module.pageTable[159].module:reloaddata(t)
    end

end

function UICPTitbitDiscountX3Buy(t)
    print("4023，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[159] and GameScene.layers["activity"].module.pageTable[159].module.show then
        GameScene.layers["activity"].module.pageTable[159].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end


--cpX4
--
function UICPTitbitDiscountX4Qury(t)
    print("4024，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[160] and GameScene.layers["activity"].module.pageTable[160].module.show then
        GameScene.layers["activity"].module.pageTable[160].module:reloaddata(t)
    end

end

function UICPTitbitDiscountX4Buy(t)
    print("4025，接受客户端数据")
     printT(t)
    if GameScene.layers["activity"].module.pageTable[160] and GameScene.layers["activity"].module.pageTable[160].module.show then
        GameScene.layers["activity"].module.pageTable[160].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end

--cpX5
--
function UICPTitbitDiscountX5Qury(t)
    print("8034，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[163] and GameScene.layers["activity"].module.pageTable[163].module.show then
        GameScene.layers["activity"].module.pageTable[163].module:reloaddata(t)
    end

end

function UICPTitbitDiscountX5Buy(t)
    print("8035，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[163] and GameScene.layers["activity"].module.pageTable[163].module.show then
        GameScene.layers["activity"].module.pageTable[163].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end

-- 合服商店
function UIhefuShopQury(t)
    print("8047，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[164] and GameScene.layers["activity"].module.pageTable[164].module.show then
        GameScene.layers["activity"].module.pageTable[164].module:reloaddata(t)
    end

end

function UIhefuShopBuy(t)
    print("8048，接受客户端数据")
    printT(t)
    if GameScene.layers["activity"].module.pageTable[164] and GameScene.layers["activity"].module.pageTable[164].module.show then
        GameScene.layers["activity"].module.pageTable[164].module:reloaddata(t)
    end
    showRewardPopupWindow(t.reward, nil,nil)
    UIRequest({type = 1001})

    if t.equiphaschange and tonumber(t.equiphaschange) == 1 then
        GameScene:addUpdate(10025,"offtreasures")
        GameScene:addUpdate(10025,"treasures")
        GameScene:addUpdate(10025,"offequips")
        GameScene:addUpdate(10025,"equips")
        GameScene:addUpdate(10021)
    end        
end



