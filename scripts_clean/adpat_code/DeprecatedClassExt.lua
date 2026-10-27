

-- This is the DeprecatedClass custom funcs

--tip
local function deprecatedTip(old_name,new_name)
    --print("\n********** \n"..old_name.." was deprecated please use ".. new_name .. " instead.\n**********")
end

--CCSequence class will be Deprecated,begin
local DeprecatedCCSequenceClassExt = {}

function DeprecatedCCSequenceClassExt.createWithTwoActions(self,...)
    deprecatedTip("CCSequence.createWithTwoActions","cc.Sequence.create")
    return self:create(...)
end
CCSequence.createWithTwoActions = DeprecatedCCSequenceClassExt.createWithTwoActions
--CCSequence class will be Deprecated,end


--CCSpawn class will be Deprecated,begin
local DeprecatedCCSpawnClassExt = {}

function DeprecatedCCSpawnClassExt.createWithTwoActions(self,...)
    deprecatedTip("CCSpawn.createWithTwoActions","cc.Spawn.create")
    return self:create(...)
end
CCSpawn.createWithTwoActions = DeprecatedCCSpawnClassExt.createWithTwoActions
--CCSequence class will be Deprecated,end


_G["CCHttpRequest"] = require"adpat_code/CCHttpRequest"
--HttpRequest class will be Deprecated,end


_G["CCHttpClient"] = require"adpat_code/CCHttpClient"
--HttpClient class will be Deprecated,end

_G["CCFileUtils"] = require"adpat_code/CCFileUtils"
--CCFileUtils class will be Deprecated,end

_G["CCLuaJavaBridge"] = LuaJavaBridge
--CCLuaJavaBridge class will be Deprecated,end

local CCSpriteFrameCacheDeprecated = {}

function CCSpriteFrameCacheDeprecated.addSpriteFramesWithFile(self,...)
    deprecatedTip("CCSpriteFrameCache:addSpriteFramesWithFile","CCSpriteFrameCache:addSpriteFrames")
    return self:addSpriteFrames(...)
end

CCSpriteFrameCache:getInstance().addSpriteFramesWithFile = CCSpriteFrameCacheDeprecated.addSpriteFramesWithFile


local SimpleAudioEngineDeprecated = {}

function SimpleAudioEngineDeprecated.setBackgroundMusicVolume(self,...)
    deprecatedTip("SimpleAudioEngine:setBackgroundMusicVolume","SimpleAudioEngine:setMusicVolume")
    return self:setMusicVolume(...)
end
SimpleAudioEngine.setBackgroundMusicVolume = SimpleAudioEngineDeprecated.setBackgroundMusicVolume

function SimpleAudioEngineDeprecated.stopBackgroundMusic(self,...)
    deprecatedTip("SimpleAudioEngine:stopBackgroundMusic","SimpleAudioEngine:stopMusic")
    return self:stopMusic(...)
end
SimpleAudioEngine.stopBackgroundMusic = SimpleAudioEngineDeprecated.stopBackgroundMusic

function SimpleAudioEngineDeprecated.getBackgroundMusicVolume(self,...)
    deprecatedTip("SimpleAudioEngine:getBackgroundMusicVolume","SimpleAudioEngine:getMusicVolume")
    return self:getMusicVolume(...)
end
SimpleAudioEngine.getBackgroundMusicVolume = SimpleAudioEngineDeprecated.getBackgroundMusicVolume

function SimpleAudioEngineDeprecated.preloadBackgroundMusic(self,...)
    deprecatedTip("SimpleAudioEngine:preloadBackgroundMusic","SimpleAudioEngine:preloadMusic")
    return self:preloadMusic(...)
end
SimpleAudioEngine.preloadBackgroundMusic = SimpleAudioEngineDeprecated.preloadBackgroundMusic

function SimpleAudioEngineDeprecated.resumeBackgroundMusic(self,...)
    deprecatedTip("SimpleAudioEngine:resumeBackgroundMusic","SimpleAudioEngine:resumeMusic")
    return self:resumeMusic(...)
end
SimpleAudioEngine.resumeBackgroundMusic = SimpleAudioEngineDeprecated.resumeBackgroundMusic


function SimpleAudioEngineDeprecated.isBackgroundMusicPlaying(self,...)
    deprecatedTip("SimpleAudioEngine:isBackgroundMusicPlaying","SimpleAudioEngine:isMusicPlaying")
    return self:isMusicPlaying(...)
end
SimpleAudioEngine.isBackgroundMusicPlaying = SimpleAudioEngineDeprecated.isBackgroundMusicPlaying

function SimpleAudioEngineDeprecated.willPlayBackgroundMusic(self,...)
    deprecatedTip("SimpleAudioEngine:willPlayBackgroundMusic","SimpleAudioEngine:willPlayMusic")
    return self:willPlayMusic(...)
end
SimpleAudioEngine.willPlayBackgroundMusic = SimpleAudioEngineDeprecated.willPlayBackgroundMusic

function SimpleAudioEngineDeprecated.rewindBackgroundMusic(self,...)
    deprecatedTip("SimpleAudioEngine:rewindBackgroundMusic","SimpleAudioEngine:rewindMusic")
    return self:rewindMusic(...)
end
SimpleAudioEngine.rewindBackgroundMusic = SimpleAudioEngineDeprecated.rewindBackgroundMusic

function SimpleAudioEngineDeprecated.playBackgroundMusic(self,...)
    deprecatedTip("SimpleAudioEngine:playBackgroundMusic","SimpleAudioEngine:playMusic")
    return self:playMusic(...)
end
SimpleAudioEngine.playBackgroundMusic = SimpleAudioEngineDeprecated.playBackgroundMusic

function SimpleAudioEngineDeprecated.pauseBackgroundMusic(self,...)
    deprecatedTip("SimpleAudioEngine:pauseBackgroundMusic","SimpleAudioEngine:pauseMusic")
    return self:pauseMusic(...)
end
SimpleAudioEngine.pauseBackgroundMusic = SimpleAudioEngineDeprecated.pauseBackgroundMusic



--Label

local LabelDeprecated = {}

function LabelDeprecated.setFontSize(self,...)
    return self:setSystemFontSize(...)
end
cc.Label.setFontSize = LabelDeprecated.setFontSize


function LabelDeprecated.setFontName(self,...)
    return self:setSystemFontName(...)
end
cc.Label.setFontName = LabelDeprecated.setFontName

function LabelDeprecated.getFontName(self,...)
    return self:getSystemFontName(...)
end
cc.Label.getFontName = LabelDeprecated.getFontName


function LabelDeprecated.setFntFile(self,...)
    return self:setBMFontFilePath(...)
end
cc.Label.setFntFile = LabelDeprecated.setFntFile

local SpriteDeprecated = {}
function SpriteDeprecated.setDisplayFrame(self,...)
    return self:setSpriteFrame(...)
end
cc.Sprite.setDisplayFrame = SpriteDeprecated.setDisplayFrame

function SpriteDeprecated.displayFrame(self,...)
    return self:getSpriteFrame(...)
end
cc.Sprite.displayFrame = SpriteDeprecated.displayFrame



local NodeDeprecated = {}
function NodeDeprecated.removeAllChildrenWithCleanup(self,...)
    return self:removeAllChildren(...)
end
cc.Node.removeAllChildrenWithCleanup = NodeDeprecated.removeAllChildrenWithCleanup


--Touch
local TouchDeprecated = {}
function TouchDeprecated.getID(self,...)
    return self:getId(...)
end
cc.Touch.getID = TouchDeprecated.getID

--Touch
local buttonDeprecated = {}
function buttonDeprecated.getTouchPriority(self,...)
    --adpat_fix
    return 0
end
cc.ControlButton.getTouchPriority = buttonDeprecated.getTouchPriority

-- dump(cc.Sprite,"-------")
-- local SpriteDeprecated = {} 

-- function SpriteDeprecated.getTextureRect(self,...)
--     --local rect = self:getTextureRect(...)
--     return self:getTextureRect(...)
--     return {origin = {x = rect.x,y = rect.y},size = {width = rect.width,height = rect.height}}
-- end
-- cc.Sprite.getTextureRect = SpriteDeprecated.getTextureRect
