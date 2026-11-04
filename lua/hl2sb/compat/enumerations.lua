-- HL2SB: the engine's _E table does not publish every GMod enumeration.
-- Pre-create the missing ones with GMod's values so this file (and the
-- scripts that read the globals it produces) does not die on
-- "attempt to index a nil value (field 'DOCK_TYPE')".
_E = _E or {}

_E.DOCK_TYPE = _E.DOCK_TYPE or {
	NONE = 0, FILL = 1, LEFT = 2, RIGHT = 3, TOP = 4, BOTTOM = 5,
}

-- HL2SB: mouse button codes.  GMod publishes MOUSE_LEFT / MOUSE_RIGHT /
-- MOUSE_MIDDLE as flat globals in every realm (source ButtonCode.h values);
-- the engine's _E table has no MOUSE group, and the derma controls compare
-- incoming mouse codes against them (DNumSlider, DColorCube, DAlphaBar,
-- DNumberScratch, DMenuOption...).
_E.MOUSE = _E.MOUSE or {
	LEFT = 107, RIGHT = 108, MIDDLE = 109,
}

_E.CULL_MODE = _E.CULL_MODE or {
	COUNTER_CLOCKWISE = 0, CLOCKWISE = 1,
}

_E.STENCIL_COMPARISON_FUNCTION = _E.STENCIL_COMPARISON_FUNCTION or {
	NEVER = 0, LESS = 1, EQUAL = 2, LESS_OR_EQUAL = 3,
	GREATER = 4, NOT_EQUAL = 5, GREATER_OR_EQUAL = 6, ALWAYS = 7,
}

_E.STENCIL_OPERATION = _E.STENCIL_OPERATION or {
	KEEP = 0, ZERO = 1, REPLACE = 2, INCRSAT = 3, DECRSAT = 4,
	INVERT = 5, INCR = 6, DECR = 7,
}

-- GMod-only enums the merge loop below would error on if absent.
_E.INPUT = _E.INPUT or {}
_E.SURFACE = _E.SURFACE or {}
_E.USABILITY_TYPE = _E.USABILITY_TYPE or {}
_E.RENDER_MODE = _E.RENDER_MODE or {}
_E.RENDER_GROUP = _E.RENDER_GROUP or {}
_E.EDICT_FLAG = _E.EDICT_FLAG or {}
_E.PLAYER_ANIMATION = _E.PLAYER_ANIMATION or {}

-- Copy all ACT_* and BUTTON_*/KEY_* enums to the global table
local enumsToCopyToGlobal = {
    ACTIVITY = false,

    BUTTON = function(enum, enumValue)
        -- KEYPAD should be KEY_PAD
        if (enum:StartsWith("KEYPAD")) then
            enum = "KEY_PAD" .. enum:sub(7)
        elseif (enum == "KEY_BRACKET_LEFT") then
            enum = "KEY_LBRACKET"
		elseif (enum == "KEY_BRACKET_RIGHT") then
            enum = "KEY_RBRACKET"
		elseif (enum == "KEY_SHIFT_LEFT") then
            enum = "KEY_LSHIFT"
		elseif (enum == "KEY_SHIFT_RIGHT") then
			enum = "KEY_RSHIFT"
		elseif (enum == "KEY_CONTROL_LEFT") then
			enum = "KEY_LCONTROL"
		elseif (enum == "KEY_CONTROL_RIGHT") then
			enum = "KEY_RCONTROL"
		elseif (enum == "KEY_ALT_LEFT") then
			enum = "KEY_LALT"
		elseif (enum == "KEY_ALT_RIGHT") then
			enum = "KEY_RALT"
		elseif (enum == "KEY_WINDOWS_LEFT") then
			enum = "KEY_LWIN"
		elseif (enum == "KEY_WINDOWS_RIGHT") then
            enum = "KEY_RWIN"
        else
            local replacements = {
                CAPS_LOCK = "CAPSLOCK",
                NUM_LOCK = "NUMLOCK",
                SCROLL_LOCK = "SCROLLLOCK",
				_TOGGLE = "TOGGLE",
            }

			for key, replacement in pairs(replacements) do
				if (enum:EndsWith(key)) then
					enum = enum:sub(1, -key:len()) .. replacement
				end
			end
        end

		return enum, enumValue
	end,
}

for enumKey, modifier in pairs(enumsToCopyToGlobal) do
    if ((enumKey == "BUTTON" or enumKey == "ACTIVITY") and not _GAMEUI and (CLIENT or SERVER)) then
        continue
    end
    if (not _E[enumKey]) then
        error("Missing enumeration table for key: " .. enumKey)
        continue
    end

    for enum, enumValue in pairs(_E[enumKey]) do
		local enumName = enum
        if (modifier) then
            enumName, enumValue = modifier(enum, enumValue)
        end

		_G[enumName] = enumValue
	end
end

local function stripUnderscores(enum)
  return enum:gsub("_", "")
end

local enumsToMergeWithKey = {
  -- OUR_ENUMERATION = "GMOD_ENUM",

	CONTENTS = "CONTENTS",
	COLLISION_GROUP = "COLLISION_GROUP",
	-- ENTITY_EFFECT = "EF", -- See below
	FCVAR = "FCVAR",
	EDICT_FLAG = "FL_EDICT",
	-- ENGINE_FLAG = "FL", -- See below
	SOLID_FLAG = "FSOLID",
	GESTURE_SLOT = "GESTURE_SLOT",
	INPUT = "IN",
	LIFE = "LIFE",
	MASK = "MASK",
	MOVE_COLLIDE = "MOVECOLLIDE",
	MOVE_TYPE = "MOVETYPE",
	OBSERVER_MODE = "OBS_MODE",
	SOLID = "SOLID",
	SURFACE = "SURF",

	DAMAGE_TYPE = {"DMG", stripUnderscores},
	HIT_GROUP = {"HITGROUP", stripUnderscores},
}

for enumKey, enumTargetKey in pairs(enumsToMergeWithKey) do
  if (enumKey == "CONTENTS" and not _GAMEUI and (CLIENT or SERVER)) then
    continue
  end
  if (not _E[enumKey]) then
    error("Missing enumeration table for key: " .. enumKey)
    continue
  end

  local modifier

  if (istable(enumTargetKey)) then
    modifier = enumTargetKey[2]
    enumTargetKey = enumTargetKey[1]
  end

  for enumKey, enumValue in pairs(_E[enumKey]) do
    if (modifier) then
      enumKey = modifier(enumKey)
    end

		_G[enumTargetKey .. "_" .. enumKey] = enumValue
	end
end

--[[
	We don't have the Kinect SDK
--]]
SENSORBONE = {
	SHOULDER_RIGHT = 8,
	SHOULDER_LEFT = 4,
	HIP = 0,
	ELBOW_RIGHT = 9,
	KNEE_RIGHT = 17,
	WRIST_RIGHT = 10,
	ANKLE_LEFT = 14,
	FOOT_LEFT = 15,
	WRIST_LEFT = 6,
	FOOT_RIGHT = 19,
	HAND_RIGHT = 11,
	SHOULDER = 2,
	HIP_LEFT = 12,
	HIP_RIGHT = 16,
	HAND_LEFT = 7,
	ANKLE_RIGHT = 18,
	SPINE = 1,
	ELBOW_LEFT = 5,
	KNEE_LEFT = 13,
	HEAD = 3,
}

if (CLIENT or _GAMEUI) then
	NODOCK = _E.DOCK_TYPE.NONE
	FILL = _E.DOCK_TYPE.FILL
	LEFT = _E.DOCK_TYPE.LEFT
	RIGHT = _E.DOCK_TYPE.RIGHT
	TOP = _E.DOCK_TYPE.TOP
	BOTTOM = _E.DOCK_TYPE.BOTTOM

	if (_GAMEUI) then
		MOUSE_LEFT = _E.MOUSE.LEFT
		MOUSE_RIGHT = _E.MOUSE.RIGHT
		MOUSE_MIDDLE = _E.MOUSE.MIDDLE
	end

    if ( _GAMEUI ) then
    STENCILCOMPARISONFUNCTION_NEVER = _E.STENCIL_COMPARISON_FUNCTION.NEVER
    STENCILCOMPARISONFUNCTION_LESS = _E.STENCIL_COMPARISON_FUNCTION.LESS
    STENCILCOMPARISONFUNCTION_EQUAL = _E.STENCIL_COMPARISON_FUNCTION.EQUAL
    STENCILCOMPARISONFUNCTION_LESSEQUAL = _E.STENCIL_COMPARISON_FUNCTION.LESS_OR_EQUAL
    STENCILCOMPARISONFUNCTION_GREATER = _E.STENCIL_COMPARISON_FUNCTION.GREATER
    STENCILCOMPARISONFUNCTION_NOTEQUAL = _E.STENCIL_COMPARISON_FUNCTION.NOT_EQUAL
    STENCILCOMPARISONFUNCTION_GREATEREQUAL = _E.STENCIL_COMPARISON_FUNCTION.GREATER_OR_EQUAL
    STENCILCOMPARISONFUNCTION_ALWAYS = _E.STENCIL_COMPARISON_FUNCTION.ALWAYS

    STENCIL_NEVER = _E.STENCIL_COMPARISON_FUNCTION.NEVER
    STENCIL_LESS = _E.STENCIL_COMPARISON_FUNCTION.LESS
    STENCIL_EQUAL = _E.STENCIL_COMPARISON_FUNCTION.EQUAL
    STENCIL_LESSEQUAL = _E.STENCIL_COMPARISON_FUNCTION.LESS_OR_EQUAL
    STENCIL_GREATER = _E.STENCIL_COMPARISON_FUNCTION.GREATER
    STENCIL_NOTEQUAL = _E.STENCIL_COMPARISON_FUNCTION.NOT_EQUAL
    STENCIL_GREATEREQUAL = _E.STENCIL_COMPARISON_FUNCTION.GREATER_OR_EQUAL
    STENCIL_ALWAYS = _E.STENCIL_COMPARISON_FUNCTION.ALWAYS

    STENCILOPERATION_KEEP = _E.STENCIL_OPERATION.KEEP
    STENCILOPERATION_ZERO = _E.STENCIL_OPERATION.ZERO
    STENCILOPERATION_REPLACE = _E.STENCIL_OPERATION.REPLACE
    STENCILOPERATION_INCRSAT = _E.STENCIL_OPERATION.INCREMENT_CLAMP
	STENCILOPERATION_DECRSAT = _E.STENCIL_OPERATION.DECREMENT_CLAMP
	STENCILOPERATION_INVERT = _E.STENCIL_OPERATION.INVERT
	STENCILOPERATION_INCR = _E.STENCIL_OPERATION.INCREMENT_WRAP
	STENCILOPERATION_DECR = _E.STENCIL_OPERATION.DECREMENT_WRAP

    STENCIL_KEEP = _E.STENCIL_OPERATION.KEEP
    STENCIL_ZERO = _E.STENCIL_OPERATION.ZERO
    STENCIL_REPLACE = _E.STENCIL_OPERATION.REPLACE
    STENCIL_INCRSAT = _E.STENCIL_OPERATION.INCREMENT_CLAMP
	STENCIL_DECRSAT = _E.STENCIL_OPERATION.DECREMENT_CLAMP
	STENCIL_INVERT = _E.STENCIL_OPERATION.INVERT
	STENCIL_INCR = _E.STENCIL_OPERATION.INCREMENT_WRAP
    STENCIL_DECR = _E.STENCIL_OPERATION.DECREMENT_WRAP
    end
elseif (SERVER) then
	CONTINUOUS_USE = _E.USABILITY_TYPE.CONTINUOUS
	ONOFF_USE = _E.USABILITY_TYPE.ON_OFF
	DIRECTIONAL_USE = _E.USABILITY_TYPE.DIRECTIONAL
	SIMPLE_USE = _E.USABILITY_TYPE.IMPULSE
end

-- HL2SB: RENDERGROUP_* used to live only in the CLIENT branch above, but GMod
-- defines them as shared globals.  scp173's server-side line-of-sight check
-- compares a victim-blocking prop's RenderGroup against RENDERGROUP_OPAQUE /
-- RENDERGROUP_OPAQUE_BRUSH; with the globals nil on the server the comparison
-- never fired and the statue walked while watched through solid props.
-- The engine only publishes RENDER_GROUP in the CLIENT enumerations lib
-- (public/lc_enumerations.cpp), so on the server _E.RENDER_GROUP is empty:
-- fill the gaps with the enum's own values (public/engine/IClientLeafSystem.h,
-- RENDER_GROUP_OPAQUE_STATIC = 0 + (NUM_OPAQUE_ENT_BUCKETS-1)*2 = 6).
_E.RENDER_GROUP.OPAQUE_STATIC_HUGE = _E.RENDER_GROUP.OPAQUE_STATIC_HUGE or 0
_E.RENDER_GROUP.OPAQUE_ENTITY_HUGE = _E.RENDER_GROUP.OPAQUE_ENTITY_HUGE or 1
_E.RENDER_GROUP.OPAQUE_STATIC = _E.RENDER_GROUP.OPAQUE_STATIC or 6
_E.RENDER_GROUP.OPAQUE_ENTITY = _E.RENDER_GROUP.OPAQUE_ENTITY or 7
_E.RENDER_GROUP.TRANSLUCENT_ENTITY = _E.RENDER_GROUP.TRANSLUCENT_ENTITY or 8
_E.RENDER_GROUP.TWOPASS = _E.RENDER_GROUP.TWOPASS or 9
_E.RENDER_GROUP.VIEW_MODEL_OPAQUE = _E.RENDER_GROUP.VIEW_MODEL_OPAQUE or 10
_E.RENDER_GROUP.VIEW_MODEL_TRANSLUCENT = _E.RENDER_GROUP.VIEW_MODEL_TRANSLUCENT or 11
_E.RENDER_GROUP.OPAQUE_BRUSH = _E.RENDER_GROUP.OPAQUE_BRUSH or 12
_E.RENDER_GROUP.OTHER = _E.RENDER_GROUP.OTHER or 13

TRANSMIT_ALWAYS = _E.EDICT_FLAG.ALWAYS
TRANSMIT_NEVER = _E.EDICT_FLAG.DONTSEND
TRANSMIT_PVS = _E.EDICT_FLAG.PVSCHECK




if _GAMEUI then
SF_CITIZEN_AMMORESUPPLIER = 524288
SF_CITIZEN_FOLLOW = 65536
SF_CITIZEN_IGNORE_SEMAPHORE = 2097152
SF_CITIZEN_MEDIC = 131072
SF_CITIZEN_NOT_COMMANDABLE = 1048576
SF_CITIZEN_RANDOM_HEAD = 262144
SF_CITIZEN_RANDOM_HEAD_FEMALE = 8388608
SF_CITIZEN_RANDOM_HEAD_MALE = 4194304
SF_CITIZEN_USE_RENDER_BOUNDS = 16777216
SF_FLOOR_TURRET_CITIZEN = 512
SF_NPC_ALTCOLLISION = 4096
SF_NPC_ALWAYSTHINK = 1024
SF_NPC_DROP_HEALTHKIT = 8
SF_NPC_FADE_CORPSE = 512
SF_NPC_FALL_TO_GROUND = 4
SF_NPC_GAG = 2
SF_NPC_LONG_RANGE = 256
SF_NPC_NO_PLAYER_PUSHAWAY = 16384
SF_NPC_NO_WEAPON_DROP = 8192
SF_NPC_START_EFFICIENT = 16
SF_NPC_TEMPLATE = 2048
SF_NPC_WAIT_FOR_SCRIPT = 128
SF_NPC_WAIT_TILL_SEEN = 1
SF_PHYSBOX_MOTIONDISABLED = 32768
SF_PHYSBOX_ALWAYS_PICK_UP = 1048576
SF_PHYSBOX_NEVER_PICK_UP = 2097152
SF_PHYSBOX_NEVER_PUNT = 4194304
SF_PHYSPROP_MOTIONDISABLED = 8
SF_PHYSPROP_PREVENT_PICKUP = 512
SF_PHYSPROP_IS_GIB = 4194304
SF_ROLLERMINE_FRIENDLY = 65536
SF_WEAPON_START_CONSTRAINED = 1
SF_WEAPON_NO_PLAYER_PICKUP = 2
SF_WEAPON_NO_PHYSCANNON_PUNT = 4

CT_DEFAULT = 0
CT_DOWNTRODDEN = 1
CT_REFUGEE = 2
CT_REBEL = 3
CT_UNIQUE = 4
end

TEXFILTER = {
	NONE = 0,
	POINT = 1,
	LINEAR = 2,
	ANISOTROPIC = 3,
}

--[[
	We renamed some of these enums to fit our conventions, so for compatibility let's just
	copy the values from the wiki:
	https://github.com/luttje/glua-api-snippets/blob/lua-language-server-addon/library/enums.lua
--]]

---@enum EF
--- Performs bone merge on client side
--- For use with EF_BONEMERGE. If this is set, then it places this ents origin at its parent and uses the parent's bbox + the max extents of the aiment. Otherwise, it sets up the parent's bones every frame to figure out where to place the aiment, which is inefficient because it'll setup the parent's bones even if the parent is not in the PVS.
--- DLIGHT centered at entity origin
--- Player flashlight
--- Don't interpolate the next frame
--- Disables shadow
--- Prevents the entity from drawing and networking.
--- Don't receive shadows
--- Makes the entity blink
--- Always assume that the parent entity is animating.
--- Internal flag that is set by [Entity:FollowBone](https://wiki.facepunch.com/gmod/Entity:FollowBone).
--- Makes the entity not accept being lit by projected textures, including the player's flashlight.
EF_NOFLASHLIGHT = 8192

---@enum EFL
--- This entity is marked for death -- This allows the game to actually delete ents at a safe time.
--- **WARNING**: You should never set this flag manually.
--- Entity is dormant, no updates to client
--- Lets us know when the noclip command is active
--- Set while a model is setting up its bones
--- This is a special entity that should not be deleted when we respawn entities via [game.CleanUpMap](https://wiki.facepunch.com/gmod/game.CleanUpMap).
--- One of the child entities is a player
EFL_HAS_PLAYER_CHILD = 16
--- (Client only) need shadow manager to update the shadow
--- Another entity is watching events on this entity (used by teleport)
--- The default behavior in ShouldTransmit is to not send an entity if it doesn't have a model. Certain entities want to be sent anyway because all the drawing logic is in the client DLL. They can set this flag and the engine will transmit them even if they don't have model
--- This is set on bots that are frozen
--- Non-networked entity
--- Don't attach the edict
--- Some 'dirty' bits with respect to absolute computations. Used internally by the engine when an entity's absolute position needs to be recalculated.
--- Some 'dirty' bits with respect to absolute computations. Used internally by the engine when an entity's absolute velocity needs to be recalculated.
--- Some 'dirty' bits with respect to absolute computations. Used internally by the engine when an entity's absolute angular velocity needs to be recalculated.
--- Marks the entity as having a 'dirty' surrounding box. Used internally by the engine to recompute the entity's collision bounds.
--- Used internally by the engine when an entity's "spatial partition" needs to be recalculated.
--- This is set if the entity detects that it's in the skybox. This forces it to pass the "in PVS" for transmission
--- Entities with this flag set show up in the partition even when not solid
--- Used to determine if an entity is floating
--- The entity is currently being lifted by a Barnacle.
--- The entity is not affected by 'rotorwash push'--the wind-push effect caused by helicopters close to the ground in Half-Life 2.
--- Avoid executing the entity's Think
--- The entity is currently not simulating any physics.
--- The entity is about to have its untouch callback checked, e.g. when this entity stops touching another entity.
--- Entity shouldn't block NPC line-of-sight
--- NPCs should not walk on this entity
--- The entity shouldn't dissolve
--- Mega physcannon can't ragdoll these guys
--- Don't adjust this entity's velocity when transitioning into water
--- Physcannon can't pick these up or punt them
--- Doesn't accept forces from physics damage

---@enum FL
--- Is the entity on ground or not
--- Is player ducking or not
--- Is the player in the process of ducking or standing up
--- The player is jumping out of water
--- This player is controlling a func_train
--- Indicates the entity is standing in rain
--- Completely freezes the player
--- Bots will still be able to look around.
--- This player is controlling something UI related in the world, this prevents his movement, but doesn't freeze mouse movement, jumping, etc.
--- Is this entity a player or not
--- Bots have this flag
--- Is the player in water or not
--- This entity can fly
--- This entity can swim
--- This entity is a func_conveyor
--- NPCs have this flag (NPC: Ignore player push)
--- Whether the player has god mode enabled
--- Makes the entity invisible to AI
--- This entity can be aimed at
--- Not all corners are valid
--- It's a static prop
--- worldgraph has this ent listed as something that blocks a connection
--- This entity is a grenade, unused
--- Changes the SV_Movestep() behavior to not do any processing
--- Doesn't generate touch functions, calls [ENTITY:EndTouch](https://wiki.facepunch.com/gmod/ENTITY:EndTouch) when this flag gets set during a touch callback
--- Base velocity has been applied this frame (used to convert base velocity into momentum)
--- This entity is a brush and part of the world
--- This entity can be seen by NPCs
--- This entity is about to get removed
--- This entity is on fire
--- The entity is currently dissolving
--- This entity is about to become a ragdoll
--- This moving door can't be blocked by the player
