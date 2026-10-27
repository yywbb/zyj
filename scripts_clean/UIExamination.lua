--
-- Author: songyibo
-- Date: 2019-03-21 11:16:04
--



function UIExaminationStatusQuery(t)
    printT(t,"7002 三界联考查询")
    if GameScene.layers["examination"].show then
        GameScene.layers["examination"].module:reload(t)
    end
    
    if GameScene.layers["main"].show then
        GameScene.layers["main"].module:sanjieliankaoUpdateTime(t)
    end
end


function UIExaminationStart(t)
    printT(t,"7003 三界联考开始考试一个题目")
    if GameScene.layers["examination"].show then
        GameScene.layers["examination"].module:startKaoshi(t)
    end

end


function UIExaminationEnd(t)
    printT(t,"7004  三界联考结束考试一个题目")
    if GameScene.layers["examination"].show then
        GameScene.layers["examination"].module:endKaoshi(t)
    end

end

function UExaminationPaihangbang(t)
    printT(t,"7005 三界联考排行榜查询")
    if gameWindows.windows["examinationrank"].show then
        gameWindows.windows["examinationrank"].module:reload(t.data)
    end
end


