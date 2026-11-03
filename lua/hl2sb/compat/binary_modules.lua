-- Platform-specific module paths for the shared Lua runtime.
-- jit.arch: "x64" / "x86" / "arm" / "arm64" (the shared runtime provides it).
local is64bit = ( jit != nil and jit.arch != nil and jit.arch != "x86" and jit.arch != "arm" )
local suffix, binext
if ( system.IsWindows() ) then
	suffix, binext = ( is64bit and "win64" or "win32" ), ".dll"
elseif ( system.IsAndroid and system.IsAndroid() ) then
	suffix, binext = ( is64bit and "android64" or "android32" ), ".so"
elseif ( system.IsOsx and system.IsOsx() ) then
	suffix, binext = ( is64bit and "osx64" or "osx" ), ".so"
else
	suffix, binext = ( is64bit and "linux64" or "linux" ), ".so"
end
local fmt = "lua/bin/gm" .. ( ( CLIENT and !MENU_DLL ) and "cl" or "sv" ) .. "_%s_" .. suffix .. binext
function util.IsBinaryModuleInstalled( name )
	if ( !isstring( name ) ) then
		error( "bad argument #1 to 'IsBinaryModuleInstalled' (string expected, got " .. type( name ) .. ")", 2 )
	elseif ( #name == 0 ) then
		error( "bad argument #1 to 'IsBinaryModuleInstalled' (string cannot be empty)", 2 )
	end

	return file.Exists( string.format( fmt, name ), "MOD" )
end
