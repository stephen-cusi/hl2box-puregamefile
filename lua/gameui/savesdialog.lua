local UI = include( "hl2sb/menu/ui.lua" )
local frame

local function Open()
    if ( frame and frame.Close ) then frame:Close() end
    local touch, w, h
    frame, touch, w, h = UI.Frame( UI.Phrase( "saves" ) )
    local margin, rowHeight = 12, touch and 48 or 30
    local buttonHeight = touch and 42 or 28
    local statusY = h - margin - buttonHeight - 29
    local list, canvas = UI.Scroll( frame, margin, 36, w - margin * 2, math.max( 1, statusY - 40 ), touch )
    local status = vgui.Create( "DLabel", frame )
    UI.Font( status, touch )
    status:SetPos( margin, statusY )
    status:SetSize( w - margin * 2, 25 )
    status:SetText( "" )
    local names = file.Find( "hl2sb_saves/*.txt", "DATA" ) or {}
    table.sort( names )
    local y, shown = 0, 0
    for _, filename in ipairs( names ) do
        local name = filename:match( "^(.-)%.txt$" )
        if ( name and name != "_menu_probe" and name:match( "^[%w_-]+$" ) ) then
            shown = shown + 1
            local label = vgui.Create( "DLabel", canvas )
            UI.Font( label, touch )
            label:SetText( name )
            label:SetPos( 4, y )
            label:SetSize( w - margin * 2 - ( touch and 230 or 170 ), rowHeight )
            local bw = touch and 90 or 70
            local x = w - margin * 2 - ( touch and 38 or 22 ) - bw * 2 - 8
            UI.Button( canvas, UI.Phrase( "load" ), x, y, bw, buttonHeight, touch, function()
                if ( HL2SB_MenuConsoleCommand and HL2SB_MenuConsoleCommand( "gm_load " .. name ) ) then status:SetText( UI.Phrase( "load_sent" ) ) end
            end )
            UI.Button( canvas, UI.Phrase( "delete" ), x + bw + 6, y, bw, buttonHeight, touch, function()
                if ( not Derma_Query ) then return end
                Derma_Query( name, UI.Phrase( "delete" ), UI.Phrase( "delete" ), function()
                    file.Delete( "hl2sb_saves/" .. filename, "DATA" )
                    Open()
                end, UI.Phrase( "close" ) )
            end )
            y = y + rowHeight
        end
    end
    if ( shown == 0 ) then
        local label = vgui.Create( "DLabel", canvas )
        UI.Font( label, touch )
        label:SetText( UI.Phrase( "no_saves" ) )
        label:SetPos( 4, 0 )
        label:SetSize( w - 40, rowHeight )
    end
    local buttonWidth = touch and 150 or 110
    UI.Button( frame, UI.Phrase( "save" ), margin, h - margin - buttonHeight, buttonWidth, buttonHeight, touch, function()
        if ( HL2SB_MenuConsoleCommand and HL2SB_MenuConsoleCommand( "gm_save" ) ) then status:SetText( UI.Phrase( "save_sent" ) ) end
    end )
    UI.Button( frame, UI.Phrase( "refresh" ), margin + buttonWidth + 8, h - margin - buttonHeight, buttonWidth, buttonHeight, touch, Open )
    UI.Button( frame, UI.Phrase( "close" ), w - margin - buttonWidth, h - margin - buttonHeight, buttonWidth, buttonHeight, touch, function() frame:Close() frame = nil end )
    UI.Layout( frame )
end

function OpenSavesDialog() Open() end
concommand.Add( "OpenSavesDialog", Open, nil, "Open saves dialog.", FCVAR_CLIENTDLL or 0 )
