--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 14/12/2
-- Time: 下午5:38
-- To change this template use File | Settings | File Templates.
--


function UIBroadcast(t)
    print("BroadcastData",t.BroadcastData)
    myque.push(GameScene.serveBroadcast,t.BroadcastData)
    myque.push(GameScene.layers["main"].module.serveBroadcast,t.BroadcastData)

end