--
-- Created by IntelliJ IDEA.
-- User: admin
-- Date: 15/4/1
-- Time: 下午2:45
-- To change this template use File | Settings | File Templates.
--

function TableViewBeginDragging()
    print("TableViewBeginDragging",gameTouch.isScrollling)
    gameTouch.isScrollling = true
end

function TableViewEndDragging()
    print("TableViewEndDragging",gameTouch.isScrollling)
    gameTouch.isScrollling = false
end