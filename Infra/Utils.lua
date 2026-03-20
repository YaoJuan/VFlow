-- =========================================================
-- VFlow Utils - 通用工具函数
-- =========================================================

local VFlow = _G.VFlow
if not VFlow then return end

VFlow.Utils = {}
local Utils = VFlow.Utils

--- 深度合并：将 defaults 中缺失的字段补填到 target，已有值不覆盖
-- 对嵌套 table 递归处理（如 timerFont、barColor 等子表）
-- @param target table 目标表（已有配置）
-- @param defaults table 默认值表
function Utils.applyDefaults(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = {}
                Utils.applyDefaults(target[k], v)
            else
                target[k] = v
            end
        elseif type(v) == "table" and type(target[k]) == "table" then
            Utils.applyDefaults(target[k], v)
        end
    end
end

--- 合并多个 layout 数组（支持 nil 和 false，用于条件性添加）
-- 用法: mergeLayouts(layout1, condition and layout2, layout3)
function Utils.mergeLayouts(...)
    local result = {}
    for i = 1, select("#", ...) do
        local layout = select(i, ...)
        if type(layout) == "table" then
            for _, item in ipairs(layout) do
                table.insert(result, item)
            end
        end
    end
    return result
end

-- 向后兼容：保留 VFlow.LayoutUtils 别名
VFlow.LayoutUtils = {
    mergeLayouts = Utils.mergeLayouts,
}
