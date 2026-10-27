--
-- Created by IntelliJ IDEA.
-- User: jutian
-- Date: 14-2-14
-- Time: 下午1:21
-- To change this template use File | Settings | File Templates.
--

local music = {
    resource = {
        music = {
            background = "UI/story/story2.mp3",
            --battle = "UI/story/battle.mp3",
            story1 = "UI/story/story1.mp3",
            story2 = "UI/story/story2.mp3",
            story3 = "UI/story/story3.mp3",
            story3_2 = "UI/story/story3_2.mp3",
            story4= "UI/story/story4.mp3",

            bg1 = "music/bg.mp3",
            bg2 = "music/bg2.mp3",
            bg3 = "music/bg3.mp3",
            fmt = "music/fmt_bg.mp3",
            qxtl= "music/qxtl_bg.mp3",
            --mwbl= "music/mwbl_bg.mp3",
            plxd= "music/plxd_bg.mp3",
            jjc= "music/jjc_bg.mp3",
            battle = "music/battle_bg.mp3",
        },
        sound = {
            root_path = "music/",
            battle_success = "music/battle_success.mp3",
            --battle_fail = "music/battle_fail.mp3",
            equip_strengthen = "music/equip_strengthen.mp3",
            role_levelup =  "music/role_levelup.mp3",
            button_click = "music/button_click.mp3",
            invalid = "music/invalid.mp3",
            battle_fail = "music/battle_fail.mp3",

            cg = "music/cg.mp3",
            qy = "music/qy.mp3",
            ct = "music/ct.mp3",
            yjzb = "music/yjzb.mp3",
            zm1 = "music/zm1.mp3",
            zm2 = "music/zm2.mp3",
            xlshjhtp = "music/xlshjhtp.mp3",
            czcg = "music/czcg.mp3",
            hc = "music/hc.mp3",
            py = "music/py.mp3",
            wjsj = "music/wjsj.mp3",
            lt = "music/lt.mp3",
            qh = "music/qh.mp3",
            wjdh = "music/wjdh.mp3",
            fj = "music/fj.mp3",
            lmqy = "music/lmqy.mp3",
            tsy = "music/tsy.mp3",
            jllq = "music/jllq.mp3",
            fh = "music/fh.mp3",
            sydj = "music/sydj.mp3",
            ccgm = "music/ccgm.mp3",
            scyj = "music/scyj.mp3",
            ldcd = "music/ldcd.mp3",
            zbqh = "music/zbqh.mp3",
            xzsl = "music/xzsl.mp3",
        },
    }
    ,handle = {}
    ,isMusicOn = true
    ,isSoundOn = true
    ,lastguidesound = nil
    ,layer_background = {}
    ,layer_last = nil
    ,opt_sound = {}
    ,volume = {
        music = 0.5,
        sound = 0.8
    }
}

music.layer_background = {
    default = music.resource.music.bg3,
    penglai = music.resource.music.plxd,
    worldboss = music.resource.music.qxtl,
    bloodbattle = music.resource.music.fmt,
    --fort = music.resource.music.mwbl,
    battle = music.resource.music.battle,
    sports2 = music.resource.music.jjc,
}

function music.Init(self)
    cclog("music.Init")
    self.audio =  require"audio"
--    for k,v in pairs(self.resource.music) do
--        self.audio.preloadMusic(v)
--    end
----
--    for k,v in pairs(self.resource.sound) do
--        if v == self.resource.sound.root_path then
--
--        else
--            self.audio.preloadSound(v)
--        end
--    end

    self.audio.disable()
    ---self.audio.setMusicVolume(1.0)
    require"sqlite3init"
    local mydb = SQLite3Open()
    local SQL = "SELECT * FROM LocalInfoTable where KEY = 'music'"
    for row in mydb:rows(SQL) do
        if row[2] == "true" then
            self.isMusicOn = true
            cclog("music music is on")
        else
            self.isMusicOn = false
            cclog("music music is off")
        end
        break
    end

    SQL = "SELECT * FROM LocalInfoTable where KEY = 'sound'"
    for row in mydb:rows(SQL) do
        if row[2] == "true" then
            self.isSoundOn = true
            cclog("music sound is on")
        else
            self.isSoundOn = false
            cclog("music sound is off")
        end
        break
    end
    mydb:close()
end

function music.ChangeLayer(self,layer)
    cclog("music.ChangeLayer %s", layer)
    local new_bg
    if  self.layer_background[layer] then
        new_bg = self.layer_background[layer]
    else
        new_bg =  self.layer_background.default
    end
    if new_bg ~= self.layer_last then
        self.layer_last = new_bg
        if not self.isMusicOn then
            return
        end
        self.audio.playMusic(self.layer_last,true)
    end
end

function music.GameStart(self)
    cclog("music.GameStart")
    self.audio.enable()
    if self.isMusicOn then
        self.audio.setMusicVolume(self.volume.music)
    else
        self.audio.setMusicVolume(0)
    end
    if self.isSoundOn then
        self.audio.setSoundsVolume(self.volume.sound)
    else
        self.audio.setSoundsVolume(0)
    end
    self.layer_last = self.layer_background.default
    if not self.isMusicOn then
        return
    end
    self.audio.playMusic(self.layer_last,true)
end

function music.BattleStart(self)
    cclog("music.BattleStart")
    if not self.isMusicOn then
        return
    end
--    self.audio.playMusic(self.resource.music.battle,true)
--    self.audio.setMusicVolume(0.5)
    self.audio.playMusic(self.layer_background.battle,true)
end

function music.BattleEnd(self)
    cclog("music.BattleEnd")
    if not self.isMusicOn then
        return
    end
--    self.audio.playMusic(self.resource.music.background,true)
--    self.audio.setMusicVolume(0.5)
    self.audio.playMusic(self.layer_last,true)
end

function music.story(self,name)
    if not self.isMusicOn then
        return
    end
    self.audio.playMusic(self.resource.music[name],true)
end


function music.BattleSuccess(self, star)
    cclog("Sound.BattleSuccess")
    if not self.isSoundOn then
        return
    end
    self.audio.playSound(self.resource.sound.battle_success,false)
--    local sequence1 = CCSequence:createWithTwoActions(CCDelayTime:create(action.screenAnimation.destdelay), CCCallFunc:create(delayfunction))
--    if star == 1 then
--        self.audio.playSound(self.resource.sound.battle_success_1,false)
--    elseif star == 2 then
--        self.audio.playSound(self.resource.sound.battle_success_2,false)
--    else
--        self.audio.playSound(self.resource.sound.battle_success_3,false)
--    end
end

function music.BattleFail(self)
    cclog("Sound.BattleFail")
    if not self.isSoundOn then
        return
    end
    self.audio.playSound(self.resource.sound.battle_fail,false)
end

function music.EquipStrengthen(self)
    cclog("Sound.EquipStrengthen")
    if not self.isSoundOn then
        return
    end
    self.audio.playSound(self.resource.sound.equip_strengthen,false)
end

function music.RoleLevelup(self)
    cclog("Sound.RoleLevelup")
    if not self.isSoundOn then
        return
    end
    self.audio.playSound(self.resource.sound.equip_strengthen,false)
end

function music.PlaySound(self, sound)
    cclog("Sound.PlaySound")
    if not self.isSoundOn then
        return
    end
    if sound and sound ~= "" then
        return self.audio.playSound(self.resource.sound.root_path..sound,false)
    else
        return nil
    end
end

function music.StopSound(self, handle)
    cclog("Sound.StopSound")
    if not self.isSoundOn or not handle then
        return
    end

    return self.audio.stopSound(handle)
end


function music.PlayGuideSound(self, sound)
    cclog("Sound.PlayGuideSound")
    if not self.isSoundOn then
        return
    end
    if self.lastguidesound then
        self.audio.stopSound(self.lastguidesound)
    end
    self.lastguidesound = self.audio.playSound(self.resource.sound.root_path..sound,false)
    return
end

function music.PlayButtonClick(self)
    cclog("Sound.PlayButtonClick")
    if not self.isSoundOn then
        return
    end
    self.audio.playSound(self.resource.sound.button_click,false)
end

function music.PlayInvalid(self)
    cclog("Sound.PlayInvalid")
    if not self.isSoundOn then
        return
    end
    self.audio.playSound(self.resource.sound.invalid,false)
end

function music.PlayOptSound(self,opt)
    cclog("Sound.PlayOptSound opt:%s",opt)
    if not self.isSoundOn then
        return
    end
    if self.resource.sound[opt] then
        self.audio.playSound(self.resource.sound[opt],false)
    end
end

function music.SetMusic(self,isMusic)
    cclog("music.SetMusic %s", isMusic and "true" or "false")
    if isMusic == self.isMusicOn then
        return
    end
    if isMusic then
        if not self.layer_last then
            self.layer_last = self.layer_background.default
        end
        self.audio.playMusic(self.layer_last,true)
        self.audio.setMusicVolume(self.volume.music)
    else
        self.audio.stopMusic()
    end
    require"sqlite3init"
    local mydb = SQLite3Open()
    local SQL = ""
    if isMusic then
        SQL = "UPDATE LocalInfoTable SET VALUE='true' WHERE KEY ='music'"
    else
        SQL = "UPDATE LocalInfoTable SET VALUE='false' WHERE KEY ='music'"
    end
    mydb:exec(SQL)
    mydb:close()
    self.isMusicOn = isMusic
end

function music.SetSound(self,isSound)
    cclog("music.SetSound %s", isSound and "true" or "false")
    if isSound == self.isSoundOn then
        return
    end
    require"sqlite3init"
    local mydb = SQLite3Open()
    local SQL = ""
    if isSound then
        SQL = "UPDATE LocalInfoTable SET VALUE='true' WHERE KEY ='sound'"
        self.audio.setSoundsVolume(self.volume.sound)
    else
        SQL = "UPDATE LocalInfoTable SET VALUE='false' WHERE KEY ='sound'"
        self.audio.setSoundsVolume(0)
    end
    mydb:exec(SQL)
    mydb:close()
    self.isSoundOn = isSound
end



return music

