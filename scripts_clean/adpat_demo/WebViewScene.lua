--
-- Author: songyibo
-- Date: 2018-07-09 17:11:55
--

local WebViewScene = class("WebViewScene", function ()
    return cc.Layer:create()
end)

function WebViewScene:ctor()
   	local winSize = cc.Director:getInstance():getVisibleSize()
    self._webView = ccexp.WebView:create()
    self._webView:setPosition(winSize.width / 2, -winSize.height)
    self._webView:setContentSize(winSize.width,  winSize.height - 300)
    self._webView:loadURL("https://www.baidu.com")
    self._webView:setScalesPageToFit(true)

    self._webView:setOnShouldStartLoading(function(sender, url)
        print("onWebViewShouldStartLoading, url is ", url)
        return true
    end)
    self._webView:setOnDidFinishLoading(function(sender, url)
        print("onWebViewDidFinishLoading, url is ", url)
    end)
    self._webView:setOnDidFailLoading(function(sender, url)
        print("onWebViewDidFinishLoading, url is ", url)
    end)

    self:addChild(self._webView)
   	

    self._webView:runAction(cc.MoveTo:create(1, cc.p(winSize.width / 2, winSize.height/2)))

end

function TestWebViewMain()
    print("TestWebViewMain")
    local scene = cc.Scene:create()
    scene:addChild(WebViewScene.new())
    scene:addChild(CreateBackMenuItem())
    return scene
end