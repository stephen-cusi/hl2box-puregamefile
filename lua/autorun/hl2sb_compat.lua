-- Compatibility that must run during autorun, after the shared libraries.
-- Keep the registry order used by the previous separate autorun files.
include( "hl2sb/original/vehicle.lua" )

if ( SERVER ) then
	include( "hl2sb/compat/server_commands.lua" )
end
