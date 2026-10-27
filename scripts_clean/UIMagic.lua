--法宝
--zhangzhixin

--法宝查询
function UIInstrumentQuery(t)
    print("法宝查询1360，接受客户端数据")
    printT(t)
    if t.id == -1 then
	   -- GameScene:shiftLayer("magic","up",t)
       GameScene.layers["magic"].module:load(t)
    elseif GameScene.layers["magic"].show   then
        GameScene.layers["magic"].module:unlock(t)
    end
end

--法宝解锁
function UIInstrumentUnlock(t)
    print("法宝解锁1361，接受客户端数据")
    printT(t)
    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)  
    UIRequest({type = 1360,id = t.id})
	-- if GameScene.layers["magic"].show  then
	-- 	GameScene.layers["magic"].module:unlock(t)
	-- end
end

--法宝锻造预览
function UIInstrumentForgePreview(t)
    print("法宝锻造预览1362，接受客户端数据")
    printT(t)
    UIRequest({type = 1001})
    -- GameScene:addUpdate(1012)
	if GameScene.layers["magic"].show   then
		GameScene.layers["magic"].module:preview(t.data)
	end
end

-- 法宝锻造确认
function UIInstrumentForgeConfirm(t)
    print(" 法宝锻造确认1363，接受客户端数据")
    printT(t)
    if t.isChage == 1 then
        GameScene:addUpdate(10021)
        GameScene:addUpdate(10023)   
    end 
	if GameScene.layers["magic"].show   then
		GameScene.layers["magic"].module:changeAttr(t)
	end
end


--
function UIInstrumentForgeAutomatic(t)
    print(" 1364，接受客户端数据")
    printT(t)

    GameScene:addUpdate(10021)
    GameScene:addUpdate(10023)

    if gameWindows.windows["instrumentForgeAutomatic"].show then
        gameWindows.windows["instrumentForgeAutomatic"].module:reloadData(t)
    end

    UIRequest({type = 1001})
    UIRequest({type = 1360})
end


function UIBreakForgePreview(t)
    print(" 1365，接受客户端数据")
    printT(t)
    UIRequest({type = 1360})
end