
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

function MainScene:onCreate()
    -- add background image
    -- display.newSprite("HelloWorld.png")
    --     :move(display.center)
    --     :addTo(self)

    -- add HelloWorld label
    -- cc.Label:createWithSystemFont("Hello World", "Arial", 40)
    --     :move(display.cx, display.cy + 200)
    --     :addTo(self)
    -- local sprite = display.newSprite("HelloWorld.png")
    -- local sprite = display.newSprite("clickme-down.png")
    -- self:addChild(sprite)
    -- sprite:move(display.center)

    

    local label = cc.Label:createWithSystemFont("Hello World", "Arial", 40)
    self:addChild(label)
    label:move(display.cx, display.cy + 200)

    local timeCB ={}
    timeCB["change"] = function()
        print("round change")
    end
    self.roundccb,self.rounditem = CCBReaderLoad("UIEffect/huihe/huihe", nil, true, "huihe",timeCB)
    self:addChild(self.roundccb)
    self.roundccb:setPosition(ccp(540,540))
    dump(self.rounditem," ----- -------- ")

    local animationManager = self.rounditem["mAnimationManager"]
    dump(animationManager," ----- 22222-------- ")
    local callfunc = function()
        print("11111------------11111111")
        self.roundccb:removeFromParentAndCleanup(true)
    end
    animationManager:setAnimationCompletedCallback(callfunc)
    animationManager:runAnimationsForSequenceNamed("huihe_qiehuan")
    
end

return MainScene
