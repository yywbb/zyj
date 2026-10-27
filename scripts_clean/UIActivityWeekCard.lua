

function UIActivityWeekCardQuery(t)
    print("周卡活动5801，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[109] 
        and GameScene.layers["activity"].module.pageTable[109].module.show then
        GameScene.layers["activity"].module.pageTable[109].module:reloadData(t)
    end
end

function UIActivityWeekCardReward(t)
    print("周卡活动5803，接受客户端数据")
    printT(t)
    
    if GameScene.layers["activity"].module.pageTable[109] 
        and GameScene.layers["activity"].module.pageTable[109].module.show then
        GameScene.layers["activity"].module.pageTable[109].module:getReward(t)
    end
end

function UIActivityWeekCardActive(t)
    print("周卡活动5802，接受客户端数据")
    printT(t)

    if GameScene.layers["activity"].module.pageTable[109] 
        and GameScene.layers["activity"].module.pageTable[109].module.show then
        GameScene.layers["activity"].module.pageTable[109].module:reSet(t)
    end
    UIRequest({type = 1001})
end
    










