local CCLabelTTFDeprecated = {}

function CCLabelTTFDeprecated.create(self, text,FontName,FontSize )
    local label = cc.Label:create()
    label:setSystemFontName(CONFIG.config.sysFontName)
    if text then
        label:setString(text)
    end
    if FontSize then
        label:setSystemFontSize(FontSize)
    end
    return label
end

_G["CCLabelTTF"] = CCLabelTTFDeprecated