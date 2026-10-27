--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14-9-26
-- Time: 上午10:28
-- To change this template use File | Settings | File Templates.
--


function UIBanHaoNumberChange(t)
    print("版号相关次数发生改变 7000，接受客户端数据")
    printT(t)
   
    if GameScene.layers["shopList"].show then
        GameScene.layers["shopList"].module:ReloadbanhaoTimes(t)
    end
 
    if GameScene.layers["devil"].show then
        GameScene.layers["devil"].module:ReloadbanhaoTimes(t)
    end

    if GameScene.layers["soul"].show then
        GameScene.layers["soul"].module:ReloadbanhaoTimes(t)
    end

    if GameScene.layers["qiankunlu"].show then
        GameScene.layers["qiankunlu"].module:ReloadbanhaoTimes(t)
    end
end