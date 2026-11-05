-- 目标飘血数组由原生injured逐项结算；reborn只恢复模型，不能把数组当数值或再加一次血。
local function reviveDest(scene,action)
    for _,dest in ipairs(action.destAnimation) do
        for _,damage in ipairs((dest.animation or {}).damage or {}) do
            if type(damage.damage)=='number' and damage.damage<0 then
                scene[dest.postype].general[dest.pos]:reborn({damage=0})
                break
            end
        end
    end
end
jiusi=reviveDest
wangtuijiangqi=reviveDest
huanhua=reviveDest
zhuzhenyi=reviveDest
