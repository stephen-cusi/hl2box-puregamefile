if ( HL2SBMenuUI ) then return HL2SBMenuUI end

local UI = {}
HL2SBMenuUI = UI

UI.touch = CreateConVar( "hl2sb_addons_touch", "0", 0,
    "Main menu layout: 0 = automatic, 1 = touch, 2 = desktop.", 0, 2 )

function UI.IsTouch()
    local mode = UI.touch and UI.touch:GetInt() or 0
    return mode == 1 or ( mode == 0 and system and system.IsAndroid and system.IsAndroid() ) or false
end

local function PlatformInfo()
    if ( system and system.GetPlatformInfo ) then
        local ok, info = pcall( system.GetPlatformInfo )
        if ( ok and type( info ) == "table" ) then return info end
    end
    return { os = system and system.IsAndroid and system.IsAndroid() and "android"
        or system and system.IsWindows and system.IsWindows() and "windows"
        or system and system.IsLinux and system.IsLinux() and "linux" or "unknown" }
end

local initial = PlatformInfo()
UI.platform = CreateConVar( "hl2sb_menu_platform", tostring( initial.os or "unknown" ), 0,
    "Detected platform; use hl2sb_menu_platform_info for available hardware details." )

concommand.Add( "hl2sb_menu_platform_info", function()
    local info = PlatformInfo()
    for _, key in ipairs( { "os", "osVersion", "arch", "processArch", "emulated", "cpu", "cores", "gpu", "gpuMemoryMB", "totalMemoryMB", "freeMemoryMB" } ) do
        if ( info[ key ] != nil ) then print( "[Menu platform] " .. key .. " = " .. tostring( info[ key ] ) ) end
    end
    print( "[Menu platform] screen = " .. tostring( ScrW() ) .. "x" .. tostring( ScrH() ) )
    print( "[Menu platform] touch = " .. tostring( UI.IsTouch() ) )
end, nil, "Print available platform and hardware information.", FCVAR_CLIENTDLL or 0 )

local phrases = include( "hl2sb/localization/menu.lua" )
if ( language and language.AddTable and istable( phrases ) ) then language.AddTable( phrases ) end
function UI.Phrase( key )
    local token = "hl2sb.menu." .. key
    return language and language.GetPhrase and language.GetPhrase( token ) or token
end

local face = system and system.IsAndroid and system.IsAndroid() and "DroidSansFallback" or "Microsoft YaHei"
surface.CreateFont( "HL2SB_MenuShared", { font = face, size = 15, weight = 500, extended = true } )
surface.CreateFont( "HL2SB_MenuSharedTouch", { font = face, size = 20, weight = 500, extended = true } )

function UI.Font( panel, touch )
    if ( panel and panel.SetFont ) then panel:SetFont( touch and "HL2SB_MenuSharedTouch" or "HL2SB_MenuShared" ) end
end

function UI.Frame( title )
    local touch = UI.IsTouch()
    local w = math.max( 1, math.min( touch and 720 or 520, ScrW() - 16 ) )
    local h = math.max( 1, math.min( touch and ScrH() - 16 or 560, ScrH() - 16 ) )
    local parent = VGui_GetGameUIPanel and VGui_GetGameUIPanel() or nil
    local frame = vgui.Create( "DFrame", parent )
    frame:SetTitle( title )
    frame:SetSize( w, h )
    frame:SetPos( math.max( 0, ( ScrW() - w ) / 2 ), math.max( 0, ( ScrH() - h ) / 2 ) )
    frame:SetSizable( false )
    frame:SetDeleteOnClose( true )
    frame:MakePopup()
    return frame, touch, w, h
end

function UI.Layout( frame )
    if ( HL2SB_MenuLayout ) then HL2SB_MenuLayout( frame ) end
end

function UI.Scroll( frame, x, y, w, h, touch )
    local list = vgui.Create( "DScrollPanel", frame )
    list:SetPos( x, y )
    list:SetSize( w, h )
    if ( touch and list:GetVBar() ) then list:GetVBar():SetWide( 32 ) end
    return list, list:GetCanvas()
end

function UI.Button( parent, text, x, y, w, h, touch, callback )
    local button = vgui.Create( "DButton", parent )
    UI.Font( button, touch )
    button:SetText( text )
    button:SetPos( x, y )
    button:SetSize( w, h )
    button.DoClick = callback
    return button
end

return UI
