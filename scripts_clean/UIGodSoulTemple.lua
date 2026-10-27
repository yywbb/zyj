function UIGodSoulTempleQuery(t)
	print("神魂殿查询 7030")
	printT(t)

	if GameScene.layers["godSoulTemple"].show then
        GameScene.layers["godSoulTemple"].module:pageDataCallback(t.pageName, "reloadData", t)
    end

    if GameScene.layers["qiankunlu"].show then
    	GameScene.layers["qiankunlu"].module:setGodSoulTempleData(t)
    end

    --  if GameScene.layers["main"].show then
    --     GameScene.layers["main"].module:setgodSoulTempleHint(t)
    -- end
end

function UIGodSoulTempleLevelUp(t)
	print("神魂殿查询 7031")
	printT(t)

	if GameScene.layers["godSoulTemple"].show then
        GameScene.layers["godSoulTemple"].module:pageDataCallback(t.pageName, "reloadData",t)
    end
end

function UIGodSoulTempleRefineSoulQuery(t)
    print("神魂殿查询 7032")
    printT(t)

    if GameScene.layers["godSoulTempleRefineSoul"].show then
        GameScene.layers["godSoulTempleRefineSoul"].module:reloadData(t)
    end

end

function UIGodSoulTempleRefineSoul(t)
    print("神魂殿查询 7033")
    printT(t)

    if GameScene.layers["godSoulTempleRefineSoul"].show then
        GameScene.layers["godSoulTempleRefineSoul"].module:reloadData(t)
        GameScene.layers["godSoulTempleRefineSoul"].module:reloadRefineSoulConsume(t.RefineSoulConsume)
    end

    GameScene:addUpdate(1012)
end

function UIGodSoulTempleCuishenQuery(t)
    print("神魂殿查询 7034")
    printT(t)
    if GameScene.layers["godSoulTempleCuishen"].show then
        GameScene.layers["godSoulTempleCuishen"].module:reloadData(t)
    end

end

function UIGodSoulTempleCuishen(t)
    print("神魂殿查询 7035")
    printT(t)
    if GameScene.layers["godSoulTempleCuishen"].show then
        GameScene.layers["godSoulTempleCuishen"].module:reloadData(t)
        GameScene.layers["godSoulTempleCuishen"].module:requestConsumeData()
    end
    GameScene:addUpdate(1200)
end