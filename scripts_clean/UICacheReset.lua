--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/1/23
-- Time: 上午10:02
-- To change this template use File | Settings | File Templates.
--

function UICacheReset(t)


   if guide.controller and guide.controller.excute.section and guide.controller.excute.section ==1 and guide.controller.excute.step <=4 then
       return
   end

   print("零点数据刷新，请返回主界面即可刷新")
   --runGamePrompt({msg = "零点数据刷新，请返回主界面即可刷新"})

    if battleScene and battleScene.show then
        battleScene.cacheresetCallBack = function()
            if GameScene and GameScene.rootItems then
                GameScene:cacheresetrequest("cachereset")
            end
        end
    elseif GameScene and GameScene.rootItems then
        GameScene:cacheresetrequest("cachereset")
    else
    end

end