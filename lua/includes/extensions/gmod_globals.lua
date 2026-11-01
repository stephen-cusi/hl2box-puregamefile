--[[----------------------------------------------------------------------------
    gmod_globals.lua

    GMod-style global helpers for HL2SB.

    The Team Sandbox Lua SDK exposes most things as *libraries* (gpGlobals.curtime,
    surface.GetScreenSize, global ConVar(...)), while GMod scripts call plain free
    functions (CurTime, ScrW, GetConVar, ...).  This file bridges just the ones
    that are pure Lua / already-backend and can be done without touching an
    entity binding, so stock GMod scripts load without "attempt to call global
    'CurTime' (a nil value)".

    Note: LocalPlayer() / IsValid() in their Entity form need a client entity
    binding and the entity-iteration set (ents.GetAll / player.GetAll), which are
    intentionally NOT defined here - they belong with the C++ entity work.

    Loaded every level from lua/includes/extensions/.
-----------------------------------------------------------------------------]]--

-- ===========================================================================
-- HL2SB GMod SWEP compat: activity / player-animation constants.  These must
-- exist before any weapon script loads (weapons are walked after includes/),
-- and GMod SWEPs use the ACT_VM_* / ACT_MP_* / PLAYER_* symbols directly.
-- Values come from Source's ai_activity.h / shareddefs.h Activity +
-- PLAYER_ANIM enums. Angle is registered by the native math library.
-- ===========================================================================

-- ===========================================================================
-- HL2SB: the ACT_* globals used to be hand-copied here from the Valve SDK
-- numbering (ACT_HL2MP_IDLE = 988 ...).  That was WRONG for this engine: models
-- resolve activities BY NAME at load (animation.cpp:151,
-- ActivityList_IndexForName) against THIS engine's list, whose values differ
-- (ACT_HL2MP_IDLE is 975 here, not 988).  The engine now publishes every
-- registered activity as a flat global with its own true value
-- (REGISTER_SHARED_ACTIVITY in activitylist.h, ~1975 entries incl. the zombie
-- swim/gesture families scp049 needs), so this block must NOT re-shadow them.
-- ===========================================================================

-- HL2SB: small GMod enum gaps the enum libs do not cover.  Values are this
-- engine's own (public/soundflags.h, shareddefs.h, public/const.h).
CHAN_VOICE		= CHAN_VOICE or 2
HITGROUP_HEAD		= HITGROUP_HEAD or 1
HITGROUP_CHEST		= HITGROUP_CHEST or 2
HITGROUP_STOMACH	= HITGROUP_STOMACH or 3
HITGROUP_LEFTARM	= HITGROUP_LEFTARM or 4
HITGROUP_RIGHTARM	= HITGROUP_RIGHTARM or 5
HITGROUP_LEFTLEG	= HITGROUP_LEFTLEG or 6
HITGROUP_RIGHTLEG	= HITGROUP_RIGHTLEG or 7
HITGROUP_GEAR		= HITGROUP_GEAR or 10
COLLISION_GROUP_IN_VEHICLE	= COLLISION_GROUP_IN_VEHICLE or 10
COLLISION_GROUP_DEBRIS		= COLLISION_GROUP_DEBRIS or 1

PLAYER_IDLE	= 0
PLAYER_WALK	= 1
PLAYER_JUMP	= 2
PLAYER_SUPERJUMP	= 3
PLAYER_DIE	= 4
PLAYER_ATTACK1	= 5
PLAYER_IN_VEHICLE	= 6
PLAYER_RELOAD	= 8
PLAYER_START_AIMING	= 9
PLAYER_LEAVE_AIMING	= 10

AddCSLuaFile = AddCSLuaFile or function( ... ) return true end

-- ===========================================================================
-- HL2SB (2026-10-08): base-gamemode globals used by the ported base files.
--
--   Format         - string.format alias (GMod extensions/string.lua spells
--                    it out with a format cache; a straight alias answers
--                    the same contract).
--   ents.FindInBox - the engine binding is spelled Entities.GetInBox here.
--
-- ===========================================================================
if ( not _CLIENT ) then
	if ( _GAMEUI ) then
		GetConVar = GetConVar or function( name ) return ConVar( name ) end
		GetConVarNumber = GetConVarNumber or function( name )
			local c = ConVar( name )
			return c and c:GetFloat() or 0
		end
		GetConVarString = GetConVarString or function( name )
			local c = ConVar( name )
			return c and c:GetString() or ""
		end
	end

	return
end

-- ===========================================================================
-- Client side
-- ===========================================================================

-- HL2SB: GMod's ScreenScale family.  These are ENGINE globals in GMod (C++),
-- not util.lua helpers -- GMod's own lua/includes/util.lua (ours, byte for
-- byte) does not define them, and lua/includes/notification.lua needs them on
-- line 2:
--
--     local textH = math.max( 12, math.ceil( ScreenScaleH( 9 ) ) )
--
-- Without them that file fails to load completely, which shows up as exactly
-- one [Lua] FAILED line -- that is how the undo notification vanished.
--
-- In the game client, the original client globals provide ScreenScale and
-- ScreenScaleH. The menu state uses its own fallback.
if ( _GAMEUI ) then
	ScreenScale = ScreenScale or function( size ) return size * ( ScrW() / 640 ) end
	ScreenScaleH = ScreenScaleH or function( size ) return size * ( ScrH() / 480 ) end
end

if ( _GAMEUI ) then
	GetConVar = GetConVar or function( name ) return ConVar( name ) end
	GetConVarNumber = GetConVarNumber or function( name )
		local c = ConVar( name )
		return c and c:GetFloat() or 0
	end
	GetConVarString = GetConVarString or function( name )
		local c = ConVar( name )
		return c and c:GetString() or ""
	end
end

-- ===========================================================================
-- HL2SB: the `achievements` table (GMod global, client)
--
-- GMod ships the achievement callbacks in lua/includes/init.lua; this fork has
-- no achievement system at all.  The only definition anywhere was
-- lua/includes/modules/gmod_compatibility/sh_init.lua:1172, which is inert
-- behind GMOD_COMPATIBILITY = false -- so the global was nil, and
--
--   gamemodes/sandbox/gamemode/spawnmenu/spawnmenu.lua:109
--       achievements.SpawnMenuOpen()      -- last line of PANEL:Open()
--
-- threw every time the spawnmenu was opened.  PANEL:Open() has already run
-- MakePopup / SetVisible by then, so the menu still appeared -- but the error
-- propagated out through hook.Run("OnSpawnMenuOpen"), which means the
-- SpawnMenuOpened hook never ran (GMod's opening hints and the menubar parent
-- hand-off both live there) and ds_debug.log got one red line per press.
--
-- Shapes copied from sh_init.lua:1172 so nothing else can notice: no-ops, and
-- false/0/"" for the getters.
-- ===========================================================================
if ( achievements == nil ) then

	achievements = {
		BalloonPopped  = function() end,
		Count          = function() return 0 end,
		EatBall        = function() end,
		GetCount       = function() return 0 end,
		GetDesc        = function() return "" end,
		GetGoal        = function() return 0 end,
		GetName        = function() return "" end,
		IncBaddies     = function() end,
		IncBystander   = function() end,
		IncGoodies     = function() end,
		IsAchieved     = function() return false end,
		Remover        = function() end,
		SpawnedNPC     = function() end,
		SpawnedProp    = function() end,
		SpawnedRagdoll = function() end,
		SpawnMenuOpen  = function() end,
	}

end
-- GMod: Player:IsAdmin().  This engine has no usergroup system (cod-c4's
-- shared.lua died on the missing method).  Minimum GMod-default semantics:
-- single player is always allowed (GMod exempts SP from the admin gate), and
-- in multiplayer nobody is an admin by default - same as GMod without a
-- users.txt.

-- GMod: player.GetHumans() - non-bot players (the save loader's "the one
-- human" fallback).

-- ===========================================================================
-- HL2SB GMod compat: DEFINE_BASECLASS( name )  (both realms)
--
-- The loader's GLua rewrite pass replaces the literal identifier
-- DEFINE_BASECLASS (calls AND definitions) with
-- `local BaseClass = baseclass.Get` before the file is parsed, so a plain
-- `function DEFINE_BASECLASS( name )` definition becomes `function local ...`
-- -- a syntax error that killed THIS WHOLE FILE on 2026-09-20, taking
-- Angle/CurTime/every global here down with it (util.lua then failed with
-- "attempt to call a nil value (global 'Angle')" and every SENT broke).
-- Assemble the name at runtime so the rewriter never sees the token.
-- The result is also mirrored onto the global BaseClass so the
-- BaseClass:Initialize( self ) pattern keeps resolving.
-- ===========================================================================
-- (2026-09-20 晚) 定义已移到引擎 C++ 侧（lsrcinit.cpp，编译期拼名）：
-- Lua 侧 rawset(_G,...) 在当前加载管线里写不进可见的全局表，
-- 探针实测 DEFINE_BASECLASS=nil。这里不再重复定义。

-- HL2SB diagnostic: proves this file ran to the end (the 2026-09-20 syntax
-- error in the DEFINE_BASECLASS block silently killed every global here).
-- SERVER/CLIENT values added 2026-09-21: if the CLIENT state shows
-- SERVER=true, the realm stamping was overwritten after openlibs and every
-- `if ( SERVER ) then return end` guard in addon client halves (sent_ball's
-- ENT:Draw!) skipped, leaving entities to draw their raw shadow models.
print( "[HL2SB] gmod_globals loaded: DEFINE_BASECLASS=" .. type( rawget( _G, "DEFINE_BASE" .. "_CLASS" ) ) .. " Angle=" .. type( Angle ) .. " SERVER=" .. tostring( SERVER ) .. " CLIENT=" .. tostring( CLIENT ) )



-- HL2SB GMod compat (2026-09-24): meta-table chain for FindMetaTable reads.
-- Addons capture methods straight off the bare metatable (PLAYER.Alive,
-- ENTITY.OnGround) - a RAW table read that never triggers the userdata
-- __index chain.  GMod carries every method on each metatable itself; this
-- fork spreads them across Entity/Animating metas.  Give the derived
-- metatables a meta-level __index that falls back to the Entity metatable so
-- PLAYER.SomeEntityMethod resolves.  (Ents created from Lua keep working:
-- only misses fall through.)
if ( FindMetaTable ~= nil ) then
	local entmeta = FindMetaTable( "Entity" )
	if ( entmeta ~= nil ) then
		for _, mtname in ipairs( { "Player", "NPC", "Vehicle", "Weapon", "NextBot" } ) do
			local mt = FindMetaTable( mtname )
			if ( mt ~= nil and mt ~= entmeta and getmetatable( mt ) == nil ) then
				setmetatable( mt, { __index = entmeta } )
			end
		end

		-- HL2SB (2026-09-25): the reverse gap - bone/flex/pose methods live on
		-- the CBaseAnimating metatable in this fork, but addons capture them as
		-- ENTITY.GetBoneMatrix / ENTITY.DestroyShadow (First Person Body does:
		-- 3896 failed shadow-hook frames in one session).  Chain Entity ->
		-- CBaseAnimating at the meta level; CBaseAnimating has no meta of its
		-- own, so the lookup terminates there (no cycle).
		local animmeta = FindMetaTable( "CBaseAnimating" )
		if ( animmeta ~= nil and animmeta ~= entmeta and getmetatable( entmeta ) == nil ) then
			setmetatable( entmeta, { __index = animmeta } )
		end
	end
end

