local pending = {}
local clock = SysTime
local driver = vgui.Create( "Panel" )
driver:SetSize( 0, 0 )
driver:SetMouseInputEnabled( false )
driver:SetKeyboardInputEnabled( false )

timer = timer or {}

function timer.Create( name, delay, repetitions, callback )
	pending[ name ] = { next = clock() + delay, delay = delay, left = repetitions, callback = callback }
end

function timer.Remove( name )
	pending[ name ] = nil
end

function timer.Exists( name )
	return pending[ name ] ~= nil
end

function driver:Think()
	local now = clock()
	local due = {}
	for name, item in pairs( pending ) do
		if ( now >= item.next ) then due[ #due + 1 ] = { name, item } end
	end
	for _, entry in ipairs( due ) do
		local name, item = entry[ 1 ], entry[ 2 ]
		if ( pending[ name ] == item ) then
			if ( item.left == 1 ) then
				pending[ name ] = nil
			else
				if ( item.left > 1 ) then item.left = item.left - 1 end
				item.next = now + item.delay
			end
			item.callback()
		end
	end
end
