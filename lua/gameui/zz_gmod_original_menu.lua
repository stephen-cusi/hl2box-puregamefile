if not MENU_DLL then return end

include("includes/modules/utf8.lua")
include("includes/modules/markup.lua")
include("gmod_original/includes/util/workshop_files.lua")
include("gmod_original/includes/util/javascript_util.lua")
include("gmod_original/menu/menu.lua")

local pending = false
local nextCheck = 0
local activated = false
local boundHTML = nil
hook.Add("Think", "HL2SBOriginalMenuReady", function()
    if activated or pending or SysTime() < nextCheck then return end
    local menu = pnlMainMenu
    if not IsValid(menu) or not IsValid(menu.HTML) or menu.HTML:IsLoading() then return end
    nextCheck = SysTime() + 1
    pending = true
    if boundHTML ~= menu.HTML then
        boundHTML = menu.HTML
        local expectedHTML = boundHTML
        boundHTML:AddFunction("hl2sb_menu", "ready", function(ready)
            pending = false
            if not ready or not IsValid(menu) or not IsValid(expectedHTML) or menu.HTML ~= expectedHTML then return end
            local gamemodes = util.TableToJSON(engine.GetGamemodes())
            if gamemodes then
                menu:Call("UpdateGamemodes(" .. gamemodes .. ");UpdateCurrentGamemode('" .. engine.ActiveGamemode():JavascriptSafe() .. "')")
            end
            local previousRemove = menu.OnRemove
            menu.OnRemove = function(self)
                HL2SB_RestoreMenuOverride()
                if previousRemove then previousRemove(self) end
            end
            activated = HL2SB_SetMenuOverride(menu)
        end)
    end
    menu.HTML:QueueJavascript([[hl2sb_menu.ready(!!(window.angular && angular.element(document.body).injector() && window.gScope && typeof gScope.MenuOption === "function" && document.querySelector("[ng-view] .options a"))) ]])
    timer.Simple(2, function() pending = false end)
end)
