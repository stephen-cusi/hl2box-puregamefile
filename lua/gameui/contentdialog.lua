local UI = include( "hl2sb/menu/ui.lua" )
include( "autorun/detect_source_games.lua" )

local frame

local function ReadSelected()
    local selected = {}
    local f = io.open( engine.GetGameDirectory() .. "/gamecontent.txt", "r" )
    if ( not f ) then return selected end
    for line in f:lines() do
        local id = tonumber( line:match( "%s*(%d+)%s*" ) )
        if ( id ) then selected[ id ] = true end
    end
    f:close()
    return selected
end

local function Open()
    if ( frame and frame.Close ) then frame:Close() end
    local touch, w, h
    frame, touch, w, h = UI.Frame( UI.Phrase( "content" ) )
    local margin, rowHeight = 12, touch and 44 or 28
    local buttonHeight = touch and 42 or 28
    local statusY = h - margin - buttonHeight - 29
    local list, canvas = UI.Scroll( frame, margin, 36, w - margin * 2, math.max( 1, statusY - 40 ), touch )
    local status = vgui.Create( "DLabel", frame )
    UI.Font( status, touch )
    status:SetPos( margin, statusY )
    status:SetSize( w - margin * 2, 25 )
    status:SetText( "" )
    local selected = ReadSelected()
    local games = HL2SB_DetectSourceGames and HL2SB_DetectSourceGames() or {}
    local y = 0
    for _, game in ipairs( games ) do
        local id = tonumber( game.appId ) or 0
        local row = vgui.Create( "DCheckBoxLabel", canvas )
        UI.Font( row, touch )
        row:SetText( tostring( game.name or game.folder or "" ) )
        row:SetPos( 4, y )
        row:SetSize( w - margin * 2 - ( touch and 44 or 28 ), rowHeight )
        if ( touch ) then
            row.PerformLayout = function( pnl )
                pnl.Button:SetSize( 32, 32 )
                pnl.Button:SetPos( 0, math.floor( ( pnl:GetTall() - 32 ) / 2 ) )
                pnl.Label:SizeToContents()
                pnl.Label:SetPos( 40, math.floor( ( pnl:GetTall() - pnl.Label:GetTall() ) / 2 ) )
            end
        end
        row:SetChecked( selected[ id ] and true or false )
        if ( id <= 0 ) then row:SetEnabled( false ) end
        row.OnChange = function( _, checked ) if ( id > 0 ) then selected[ id ] = checked and true or nil end end
        y = y + rowHeight
    end
    if ( #games == 0 ) then
        local label = vgui.Create( "DLabel", canvas )
        UI.Font( label, touch )
        label:SetText( UI.Phrase( "no_games" ) )
        label:SetPos( 4, 0 )
        label:SetSize( w - 40, rowHeight )
    end
    local buttonWidth = touch and 160 or 110
    UI.Button( frame, UI.Phrase( "apply" ), margin, h - margin - buttonHeight, buttonWidth, buttonHeight, touch, function()
        local f = io.open( engine.GetGameDirectory() .. "/gamecontent.txt", "w" )
        if ( not f ) then status:SetText( UI.Phrase( "write_failed" ) ) return end
        local ids = {}
        for id, enabled in pairs( selected ) do if ( enabled ) then ids[ #ids + 1 ] = id end end
        table.sort( ids )
        local ok = true
        for _, id in ipairs( ids ) do if ( not f:write( tostring( id ), "\n" ) ) then ok = false break end end
        if ( not f:close() ) then ok = false end
        status:SetText( UI.Phrase( ok and "restart" or "write_failed" ) )
    end )
    UI.Button( frame, UI.Phrase( "close" ), w - margin - buttonWidth, h - margin - buttonHeight, buttonWidth, buttonHeight, touch, function() frame:Close() frame = nil end )
    UI.Layout( frame )
end

concommand.Add( "OpenContentDialog", Open, nil, "Open content dialog.", FCVAR_CLIENTDLL or 0 )
