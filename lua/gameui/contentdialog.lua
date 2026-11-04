local UI = include( "hl2sb/menu/ui.lua" )
include( "autorun/detect_source_games.lua" )

local frame

local function ReadSelected()
    local selected = {}
    local f = io.open( engine.GetGameDirectory() .. "/gamecontent.txt", "r" )
    if ( not f ) then return selected, false end
    for line in f:lines() do
        local value = line:match( "^%s*(.-)%s*$" )
        if ( value and value ~= "" and value:sub( 1, 1 ) ~= "#" ) then selected[ tonumber( value ) or value:lower() ] = true end
    end
    f:close()
    return selected, true
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
    local selected, hasSelection = ReadSelected()
    local games = HL2SB_DetectSourceGames and HL2SB_DetectSourceGames() or {}
    local checks = {}
    local y = 0
    for _, game in ipairs( games ) do
        local id = tonumber( game.appId ) or 0
        local folder = tostring( game.folder or "" ):lower()
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
        row:SetChecked( selected[ folder ] or selected[ id ] or ( not hasSelection and game.mounted ) or false )
        if ( folder == "" ) then row:SetEnabled( false ) end
        checks[ #checks + 1 ] = { row = row, folder = folder }
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
        local folders = {}
        for _, item in ipairs( checks ) do
            if ( item.folder ~= "" and item.row:GetChecked() ) then folders[ #folders + 1 ] = item.folder end
        end
        table.sort( folders )
        local ok = true
        for _, folder in ipairs( folders ) do if ( not f:write( folder, "\n" ) ) then ok = false break end end
        if ( not f:close() ) then ok = false end
        if ( ok and engine.SetContentMounted ) then
            local allApplied = true
            for _, item in ipairs( checks ) do
                if ( item.folder ~= "" and not engine.SetContentMounted( item.folder, item.row:GetChecked() ) ) then allApplied = false end
            end
            status:SetText( UI.Phrase( allApplied and "content_applied" or "content_fixed" ) )
        else
            status:SetText( UI.Phrase( ok and "restart" or "write_failed" ) )
        end
    end )
    UI.Button( frame, UI.Phrase( "close" ), w - margin - buttonWidth, h - margin - buttonHeight, buttonWidth, buttonHeight, touch, function() frame:Close() frame = nil end )
    UI.Layout( frame )
end

concommand.Add( "OpenContentDialog", Open, nil, "Open content dialog.", FCVAR_CLIENTDLL or 0 )
