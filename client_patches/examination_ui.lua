local examinationSend = UIRequest
function UIRequest(req,...)
    local opcode = tonumber(req.type)
    if opcode and opcode >= 7002 and opcode <= 7005 then
        local page, window = package.loaded.Layer_examination, package.loaded.window_examinnationRank
        req.examinationView = {page=page and page.localExaminationGeneration,window=window and window.localExaminationGeneration}
    end
    return examinationSend(req,...)
end

function UIExaminationStatusQuery(t)
    local page = package.loaded.Layer_examination
    if page and page.rootNode and GameScene.layers.examination.show
            and (t.examinationView or {}).page == page.localExaminationGeneration then page:reload(t) end
    if GameScene.layers.main.show then GameScene.layers.main.module:sanjieliankaoUpdateTime(t) end
end

for _, entry in ipairs({{7003,"UIExaminationStart"},{7004,"UIExaminationEnd"},{7005,"UExaminationPaihangbang"}}) do
    local opcode, receive = entry[1], _G[entry[2]]
    _G[entry[2]] = function(t)
        if t.localExaminationIgnored then return end
        local view = t.examinationView or {}
        local page, window = package.loaded.Layer_examination, package.loaded.window_examinnationRank
        if opcode == 7005 then
            if window and window.rootNode and view.window == window.localExaminationGeneration and tonumber(window.phtype) == t.examKind then return receive(t) end
        elseif page and page.rootNode and GameScene.layers.examination.show and view.page == page.localExaminationGeneration
                and tonumber(page.currenntKaoshitype) == t.examKind and (opcode ~= 7004 or tonumber(page.timuid) == t.examQuestion) then
            return receive(t)
        end
    end
end
