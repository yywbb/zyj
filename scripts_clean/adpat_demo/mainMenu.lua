--
-- Author: songyibo
-- Date: 2018-08-04 16:26:59
--
cc.FileUtils:getInstance():addSearchPath("res")
cc.FileUtils:getInstance():addSearchPath("res/UI")
cc.FileUtils:getInstance():addSearchPath("res/ccb")
cc.FileUtils:getInstance():addSearchPath("res/skill")

ui = require "adpat_demo.util.ui"
require "adpat_demo.util.CCBReaderLoad"


require "adpat_demo.VisibleRect"
require "adpat_demo.TestEditBox"
require "adpat_demo.TestHttp"
require "adpat_demo.TestShader"
require "adpat_demo.TestSpine"
require "adpat_demo.TestTableView"
require "adpat_demo.TestThreadScene"
require "adpat_demo.WebViewScene"
require "adpat_demo.TestTouch"

CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("UI/public/publicobject1.plist")
CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile("UI/public/publicobject_buya.plist")

display = {cx = cc.Director:getInstance():getWinSize().width/2,cy = cc.Director:getInstance():getWinSize().height/2}

local function MainMenuCallback()
    local scene = cc.Scene:create()
    scene:addChild(CreateTestMenu())
    cc.Director:getInstance():setDepthTest(false)
    cc.Director:getInstance():replaceScene(scene)
end

-- add the menu item for back to main menu
function CreateBackMenuItem()
    local label = cc.Label:createWithTTF("MainMenu", "fonts/arial.ttf", 20)
    label:setAnchorPoint(cc.p(0.5, 0.5))
    local MenuItem = cc.MenuItemLabel:create(label)
    MenuItem:registerScriptTapHandler(MainMenuCallback)

    local s = cc.Director:getInstance():getOpenGLView():getVisibleRect()
    local Menu = cc.Menu:create()
    Menu:addChild(MenuItem)
    Menu:setPosition(0, 0)
    MenuItem:setPosition(s.width - 50, s.y + 25)

    return Menu
end

local LINE_SPACE = 150

local CurPos = {x = 0, y = 0}
local BeginPos = {x = 0, y = 0}


local _allTests = {
    { isSupported = true,   name = "EditBox"           , create_func=             EditBoxTestMain  },
    { isSupported = true,   name = "Http"              , create_func=             HttpTestMain  },
    { isSupported = true,   name = "Shader"            , create_func=             TestShaderMain  },
    { isSupported = true,   name = "TableView"         , create_func=             TestTableViewMain  },
    { isSupported = true,   name = "Spine"             , create_func=             TestSpineMain  },
    { isSupported = true,   name = "Thread"            , create_func=             TestThreadMain  },
    { isSupported = true,   name = "WebView"           , create_func=             TestWebViewMain  },
    { isSupported = true,   name = "Touch"             , create_func=             TestTouchMain  },
}

local TESTS_COUNT = table.getn(_allTests)

-- create scene
local function CreateTestScene(nIdx)
    --cc.Director:getInstance():purgeCachedData()
    local scene = _allTests[nIdx].create_func()
    return scene
end
-- create menu
function CreateTestMenu()
    local menuLayer = cc.Layer:create()

    local function closeCallback()
        cc.Director:getInstance():endToLua()
    end

    local function menuCallback(tag)
        print(tag)
        local Idx = tag - 10000
        local testScene = CreateTestScene(Idx)
        if testScene then
            cc.Director:getInstance():replaceScene(testScene)
        end
    end
    local s = cc.Director:getInstance():getWinSize()
    -- add menu items for tests
    local MainMenu = cc.Menu:create()
    local index = 0
    local obj = nil
    for index, obj in pairs(_allTests) do
        local testLabel = cc.Label:createWithTTF(obj.name, "fonts/arial.ttf", 48)
        testLabel:setAnchorPoint(cc.p(0.5, 0.5))
        local testMenuItem = cc.MenuItemLabel:create(testLabel)
        if not obj.isSupported then
            testMenuItem:setEnabled(false)
        end

        testMenuItem:registerScriptTapHandler(menuCallback)
        testMenuItem:setPosition(cc.p(s.width / 2, (s.height - (index) * LINE_SPACE)))
        MainMenu:addChild(testMenuItem, index + 10000, index + 10000)
    end

    MainMenu:setContentSize(cc.size(s.width, (TESTS_COUNT + 1) * (LINE_SPACE)))
    MainMenu:setPosition(CurPos.x, CurPos.y)
    menuLayer:addChild(MainMenu)

    -- handling touch events
    local function onTouchBegan(touch, event)
        BeginPos = touch:getLocation()
        -- CCTOUCHBEGAN event must return true
        return true
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        local nMoveY = location.y - BeginPos.y
        local curPosx, curPosy = MainMenu:getPosition()
        local nextPosy = curPosy + nMoveY
        local winSize = cc.Director:getInstance():getWinSize()
        if nextPosy < 0 then
            MainMenu:setPosition(0, 0)
            return
        end

        if nextPosy > ((TESTS_COUNT + 1) * LINE_SPACE - winSize.height) then
            MainMenu:setPosition(0, ((TESTS_COUNT + 1) * LINE_SPACE - winSize.height))
            return
        end

        MainMenu:setPosition(curPosx, nextPosy)
        BeginPos = {x = location.x, y = location.y}
        CurPos = {x = curPosx, y = nextPosy}
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    local eventDispatcher = menuLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, menuLayer)

    return menuLayer
end
