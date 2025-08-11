local ffi = require "ffi"
local pui = require "gamesense/pui" 
local http = require "gamesense/http"
local adata = require "gamesense/antiaim_funcs"
local images = require "gamesense/images"
local vector = require "vector"
local msgpack = require "gamesense/msgpack"
local base64 = require "gamesense/base64"
local clipboard = require "gamesense/clipboard"
local crr_t = ffi.typeof('void*(__thiscall*)(void*)')
local cr_t = ffi.typeof('void*(__thiscall*)(void*)')
local gm_t = ffi.typeof('const void*(__thiscall*)(void*)')
local gsa_t = ffi.typeof('int(__fastcall*)(void*, void*, int)')

table.clear = require "table.clear"
table.ifind = function (t, j)  for i = 1, #t do if t[i] == j then return i end end  end
table.append = function (t, ...)  for i, v in ipairs{...} do table.insert(t, v) end  end
table.mfind = function (t, j)  for i = 1, table.maxn(t) do if t[i] == j then return i end end  end
table.find = function (t, j)  for k, v in pairs(t) do if v == j then return k end end return false  end
table.filter = function (t)  local res = {} for i = 1, table.maxn(t) do if t[i] ~= nil then res[#res+1] = t[i] end end return res  end
table.copy = function (o) if type(o) ~= "table" then return o end local res = {} for k, v in pairs(o) do res[table.copy(k)] = table.copy(v) end return res end
table.ihas = function (t, ...) local arg = {...} for i = 1, table.maxn(t) do for j = 1, #arg do if t[i] == arg[j] then return true end end end return false end
table.distribute = function (t, r, k)  local result = {} for i, v in ipairs(t) do local n = k and v[k] or i result[n] = r == nil and i or v[r] end return result  end
table.place = function (t, path, place)  local p = t for i, v in ipairs(path) do if type(p[v]) == "table" then p = p[v] else p[v] = (i < #path) and {} or place  p = p[v]  end end return t  end

contains = function(tbl, val)
	if tbl == nil then
		return false
	end
	
	for i=1, #tbl do
        if tbl[i] == val then return true end
    end

	return false
end

ffi.cdef[[
    struct animation_layer_tt {
        char pad_0000[20];
        uint32_t m_nOrder; //0x0014
        uint32_t m_nSequence; //0x0018
        float m_flPrevCycle; //0x001C
        float m_flWeight; //0x0020
        float m_flWeightDeltaRate; //0x0024
        float m_flPlaybackRate; //0x0028
        float m_flCycle; //0x002C
        void *m_pOwner; //0x0030 // player's thisptr
        char pad_0038[4]; //0x0034
    };

    struct animstate_tt {
        char pad[3];
        char m_bForceWeaponUpdate; //0x4
        char pad1[91];
        void* m_pBaseEntity; //0x60
        void* m_pActiveWeapon; //0x64
        void* m_pLastActiveWeapon; //0x68
        float m_flLastClientSideAnimationUpdateTime; //0x6C
        int m_iLastClientSideAnimationUpdateFramecount; //0x70
        float m_flAnimUpdateDelta; //0x74
        float m_flEyeYaw; //0x78
        float m_flPitch; //0x7C
        float m_flGoalFeetYaw; //0x80
        float m_flCurrentFeetYaw; //0x84
        float m_flCurrentTorsoYaw; //0x88
        float m_flUnknownVelocityLean; //0x8C
        float m_flLeanAmount; //0x90
        char pad2[4];
        float m_flFeetCycle; //0x98
        float m_flFeetYawRate; //0x9C
        char pad3[4];
        float m_fDuckAmount; //0xA4
        float m_fLandingDuckAdditiveSomething; //0xA8
        char pad4[4];
        float m_vOriginX; //0xB0
        float m_vOriginY; //0xB4
        float m_vOriginZ; //0xB8
        float m_vLastOriginX; //0xBC
        float m_vLastOriginY; //0xC0
        float m_vLastOriginZ; //0xC4
        float m_vVelocityX; //0xC8
        float m_vVelocityY; //0xCC
        char pad5[4];
        float m_flUnknownFloat1; //0xD4
        char pad6[8];
        float m_flUnknownFloat2; //0xE0
        float m_flUnknownFloat3; //0xE4
        float m_flUnknown; //0xE8
        float m_flSpeed2D; //0xEC
        float m_flUpVelocity; //0xF0
        float m_flSpeedNormalized; //0xF4
        float m_flFeetSpeedForwardsOrSideWays; //0xF8
        float m_flFeetSpeedUnknownForwardOrSideways; //0xFC
        float m_flTimeSinceStartedMoving; //0x100
        float m_flTimeSinceStoppedMoving; //0x104
        bool m_bOnGround; //0x108
        bool m_bInHitGroundAnimation; //0x109
        char pad7[2];
        float m_flJumpToFall;
        float m_flTimeSinceInAir; //0x110
        float m_flLastOriginZ; //0x114
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation; //0x118
        float m_flStopToFullRunningFraction; //0x11C
        char pad8[4];
        float m_flMagicFraction; //0x124
        char pad9[60];
        float m_flWorldForce; //0x164
        char pad10[462];
        float m_flMaxYaw; //0x334
    };
    
    typedef struct {
        float x;
        float y;
        float z;
    } Vector;
    
    typedef struct {
        float m[3][4];
    } matrix3x4_t;
]]

local ClassPointer = ffi.typeof('void***')
local GetClientEntityType = ffi.typeof('void*(__thiscall*)(void*, int)')
local GetStudioModelType = ffi.typeof('void*(__thiscall*)(void*, const void*)')
local GetSequenceActivityType = ffi.typeof('int(__fastcall*)(void*, void*, int)')

local RawEntityList = client.create_interface('client_panorama.dll', 'VClientEntityList003')
local EntityListPointer = ffi.cast(ClassPointer, RawEntityList) or error('Entity list interface not found', 2)
local GetClientEntity = ffi.cast(GetClientEntityType, EntityListPointer[0][3])

local RawModelInfo = client.create_interface('engine.dll', 'VModelInfoClient004')
local ModelInfoPointer = ffi.cast(ClassPointer, RawModelInfo) or error('Model info interface not found', 2)
local GetStudioModel = ffi.cast(GetStudioModelType, ModelInfoPointer[0][32])

local Data = database.read("ORION_DATA") or {}

local Globals = {
	screen_x, screen_y,
	UserName,
}

Globals.screen_x, Globals.screen_y = client.screen_size()
Globals.UserName = panorama.open("CSGOHud").MyPersonaAPI.GetName()

local Data = database.read("ORION_DATA") or {}

if Data.KillCount == nil then Data.KillCount = 0 end
if Data.Coins == nil then Data.Coins = 0 end

local refs = {
	rage = {
		aimbot = {
			force_baim = pui.reference("RAGE", "Aimbot", "Force body aim"),
			force_sp = pui.reference("RAGE", "Aimbot", "Force safe point"),
			hit_chance = pui.reference("RAGE", "Aimbot", "Minimum hit chance"),
			damage = pui.reference("RAGE", "Aimbot", "Minimum damage"),
			damage_ovr = { pui.reference("RAGE", "Aimbot", "Minimum damage override") },
			double_tap = { pui.reference("RAGE", "Aimbot", "Double tap") },
			dt_fl = { pui.reference("RAGE", "Aimbot", "Double tap fake lag limit") },
		},
		other = {
			peek = pui.reference("RAGE", "Other", "Quick peek assist"),
			duck = pui.reference("RAGE", "Other", "Duck peek assist"),
			log_misses = pui.reference("RAGE", "Other", "Log misses due to spread"),
            AntiAimCorrection = pui.reference("RAGE", "Other", "Anti-Aim Correction"),
		}
	},
	aa = {
		angles = {
			enable = pui.reference("AA", "Anti-Aimbot angles", "Enabled"),
			pitch = { pui.reference("AA", "Anti-Aimbot angles", "Pitch") },
			yaw = { pui.reference("AA", "Anti-Aimbot angles", "Yaw") },
			base = pui.reference("AA", "Anti-Aimbot angles", "Yaw base"),
			jitter = { pui.reference("AA", "Anti-Aimbot angles", "Yaw jitter") },
			body = { pui.reference("AA", "Anti-Aimbot angles", "Body yaw") },
			edge = pui.reference("AA", "Anti-Aimbot angles", "Edge yaw"),
			fs_body = pui.reference("AA", "Anti-Aimbot angles", "Freestanding body yaw"),
			freestand = pui.reference("AA", "Anti-Aimbot angles", "Freestanding"),
			roll = pui.reference("AA", "Anti-Aimbot angles", "Roll"),
		},
		fakelag = {
			enable = pui.reference("AA", "Fake lag", "Enabled"),
			amount = pui.reference("AA", "Fake lag", "Amount"),
			variance = pui.reference("AA", "Fake lag", "Variance"),
			limit = pui.reference("AA", "Fake lag", "Limit"),
		},
		other = {
			slowmo = pui.reference("AA", "Other", "Slow motion"),
			legs = pui.reference("AA", "Other", "Leg movement"),
			onshot = pui.reference("AA", "Other", "On shot anti-aim"),
			fp = pui.reference("AA", "Other", "Fake peek"),
		}
	},
	misc = {
		clantag = pui.reference("MISC", "Miscellaneous", "Clan tag spammer"),
		log_damage = pui.reference("MISC", "Miscellaneous", "Log damage dealt"),
		ping_spike = pui.reference("MISC", "Miscellaneous", "Ping spike"),
		settings = {
			dpi = pui.reference("MISC", "Settings", "DPI scale"),
			accent = pui.reference("MISC", "Settings", "Menu color"),
			maxshift = pui.reference("MISC", "Settings", "sv_maxusrcmdprocessticks2")
		},
		movement = {
			AirStrafe = pui.reference("Misc", "Movement", "Air strafe")
		}
	},
    PList = {
        ResetAll = pui.reference("Players", "Players", "Reset All"),
        ForceBodyYaw = pui.reference("Players", "Adjustments", "Force Body Yaw"),
        CorrectionActive = pui.reference("Players", "Adjustments", "Correction Active"),
    }
}

local a = function (...) return ... end

local color do
    local helpers = {
        RGBtoHEX = a(function (col, short)
            if short then
                return string.format("%02X%02X%02X", col.r, col.g, col.b)
            else
                return string.format("%02X%02X%02X%02X", col.r, col.g, col.b, col.a)
            end
        end),
        HEXtoRGB = a(function (hex)
            hex = string.gsub(hex, "^#", "")
            return tonumber(string.sub(hex, 1, 2), 16),
                   tonumber(string.sub(hex, 3, 4), 16),
                   tonumber(string.sub(hex, 5, 6), 16),
                   tonumber(string.sub(hex, 7, 8), 16) or 255
        end)
    }

	local create

	local mt = {
		__eq = function (a, b)
			return a.r == b.r and a.g == b.g and a.b == b.b and a.a == b.a
		end,
		lerp = function (f, t, w)
			return create(f.r + (t.r - f.r) * w, f.g + (t.g - f.g) * w, f.b + (t.b - f.b) * w, f.a + (t.a - f.a) * w)
		end,
		to_hex = helpers.RGBtoHEX,
		alphen = function (self, a, r)
			return create(self.r, self.g, self.b, r and a * self.a or a)
		end,
	}	mt.__index = mt

	create = ffi.metatype(ffi.typeof("struct { uint8_t r; uint8_t g; uint8_t b; uint8_t a; }"), mt)

    color = setmetatable({
        rgb = a(function (r,g,b,a)
            r = math.min(r or 255, 255)
            return create(r, g and math.min(g, 255) or r, b and math.min(b, 255) or r, a and math.min(a, 255) or 255)
        end),
        hex = a(function (hex)
            local r,g,b,a = helpers.HEXtoRGB(hex)
            return create(r,g,b,a)
        end)
    }, {
        __call = a(function (self, r, g, b, a)
            return type(r) == "string" and self.hex(r) or self.rgb(r, g, b, a)
        end),
    })
end

local colors = {
	hex		= "\aC04D9A",
	accent	= color.hex("C04D9A"),
	back	= color.rgb(23, 26, 28),
	dark	= color.rgb(5, 6, 8),
	white	= color.rgb(255),
	black	= color.rgb(0),
	null	= color.rgb(0, 0, 0, 0),
	text	= color.rgb(230),
}

local printc do
	local native_print = vtable_bind("vstdlib.dll", "VEngineCvar007", 25, "void(__cdecl*)(void*, const void*, const char*, ...)")

	printc = function (...)
		for i, v in ipairs{...} do
			local r = "\aD9D9D9" .. string.gsub(tostring(v), "[\r\v]", {["\r"] = "\aD9D9D9", ["\v"] = "\a".. (colors.hex:sub(1, 7))})
			for col, text in r:gmatch("\a(%x%x%x%x%x%x)([^\a]*)") do
				native_print(color.hex(col), text)
			end
		end
		native_print(color.rgb(217, 217, 217), "\n")
	end
end

local debug = function (...)
	if _DEBUG then printc("  \vOrion Solutions\r  ", ...) end
end

local callbacks do
	local event_mt = {
		__call = function (self, bool, fn)
			local action = bool and client.set_event_callback or client.unset_event_callback
			action(self[1], fn)
		end,
		set = function (self, fn)
			client.set_event_callback(self[1], fn)
		end,
		unset = function (self, fn)
			client.unset_event_callback(self[1], fn)
		end,
		fire = function (self, ...)
			client.fire_event(self[1], ...)
		end,
	}	event_mt.__index = event_mt

	callbacks = setmetatable({}, {
		__index = function (self, key)
			self[key] = setmetatable({key}, event_mt)
			return self[key]
		end,
	})
end

local GUI = {
	Header = function(name, group) 
		r = {}
		r[#r+1] = group:label("\f<c> "..name)
		r[#r+1] = group:label("\f<silent>‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾") 
		return r
	end,
	Feature = function (main, settings)
	    main = main.__type == "pui::element" and {main} or main
		local feature, g_depend = settings(main[1])

	    for k, v in pairs(feature) do
			v:depend({main[1], g_depend})
		end
		feature[main.key or "on"] = main[1]

		return feature
	end,
	Space = function(group) group:label("\n") end,
    Lock = function (id, item, to, min)
		if _LEVEL < (min or 2) then
			local cb = function (this) client.delay_call(.1, function() this:set(to or false) end) end
			item:set_callback(cb, true)
			item:set_enabled(false)
		end

		return item
	end
}

local Groups = {
    Angles = pui.group("AA", "Anti-aimbot angles"),
    FakeLag = pui.group("AA", "Fake lag"),
    Other = pui.group("AA", "Other"),
    LuaB = pui.group("LUA", "B"),
	LuaA = pui.group("LUA", "A")
}

pui.macros.silent = "\aCDCDCD40"
pui.macros.p = "\aCDCDCD40•\r"
pui.macros.c = "\v•\r" 
pui.macros.orion = colors.hex

local AA = {
	States = {
		{"global", "Global", "D"},
		{"stand", "Standing", "S"},
		{"run", "Running", "R"},
		{"walk", "Walking", "W"},
		{"air", "In-air", "A"},
		{"airduck", "Air-crouching", "AC"},
		{"crouch", "Crouching", "C"},
		{"sneak", "Sneaking", "3"},
	},
	Presets = {
		Custom = {
			[1] = {},
		},
	}
}

local Menu = {
    GUI.Header("Orion Solutions", Groups.FakeLag),

    Tabs = Groups.FakeLag:combobox("\n", "Home", "Rage", "Anti-Aim", "Visuals", "Miscellaneous"),

    Home = {
		GUI.Header("Info", Groups.FakeLag),
		Groups.FakeLag:label("\f<silent>User: \v"..Globals.UserName),
        Groups.FakeLag:label("\f<silent>Build: \vDebug"),

		Statistics = {
		   GUI.Header("Statistics", Groups.Other),
           KillCounter = Groups.Other:label("\f<silent>Kills: \v" .. Data.KillCount),
		   CoinCounter = Groups.Other:label("\f<silent>Coins: \v" .. Data.Coins),
		},

        ConfigSystem = {
            
        }
	},

    Rage = {
        GUI.Header("Rage", Groups.Angles),

		Resolver = GUI.Feature({Groups.Angles:checkbox("Resolver")}, function (Parent)
		    return {
				Mode = Groups.Angles:combobox("Resolver Mode", {"Standard", "Aggressive", "Brute Force", "Adaptive", "Maximum"}),
				Options = Groups.Angles:multiselect("Resolver Options", {"Resolve On Miss", "Predict Movement", "Handle Defensive", "Detect Jitter", "Low Delta Priority"}),
			    DesyncPrediction = Groups.Angles:slider("Desync Prediction ", 0, 100, 50, true, "%"),
		    }, true
	    end),

		JumpScout = Groups.Angles:checkbox("Jump Scout"),
    },

    AntiAim = {
        GUI.Header("AntiAim", Groups.Other),

        Enable = Groups.Other:checkbox("Enable Anti-Aim"),
        Type = Groups.Other:combobox("Type", "GameSense", "Orion Solutions"),
		Presets = Groups.Other:combobox("\v•\r Presets", {"Soon", "Custom"}),
        Condition = Groups.Other:combobox("\v•\r Condition", table.distribute(AA.States, 2), nil, false),
        --combobox("\v•\r  State  \a373737FF----------------------------", table.distribute(antiaim.states, 2), nil, false),

        Conditions = {},
    },

    Visuals = {
		GUI.Header("Visuals", Groups.Angles),

        WaterMark = Groups.Angles:checkbox("WaterMark", true, true)
	},

	Miscellaneous = {
		GUI.Header("Miscellaneous" , Groups.Angles),

        Groups.Angles:label("Accent color"),
	    AccentColor = Groups.Angles:color_picker("Accent color", colors.accent.r, colors.accent.g, colors.accent.b, 255),
        AntiBackStab = GUI.Feature({Groups.Angles:checkbox("Anti BackStab")}, function (Parent)
		    return {
			    Distance = Groups.Angles:slider("Distance ", 0, 500, 160),
		    }, true
	    end),
		BuyBot = GUI.Feature({Groups.Angles:checkbox("Buy Bot")}, function(Parent)
			return {
				PistolRound = Groups.Angles:checkbox("Disable On Pistol Round"),
			    Primary = Groups.Angles:combobox("Primary Weapon", {
                    "None", "Scout", "Auto", "AWP"
                }),
			    Secondary = Groups.Angles:combobox("Secondary Weapon", {
				    "None", "Glock", "USP-S", "P250", "Deagle", "Tec-9 / Five-SeveN", "CZ75", "Dual Berettas"
                }),
			    Grenades = Groups.Angles:checkbox("Grenades"),
			    Kevlar = Groups.Angles:checkbox("Kevlar"),
			    Taser = Groups.Angles:checkbox("Zues"),
			}, true
		end)
	},
}

do 
    New = function(path, ref)
        ref:set_callback(function (self) table.place(AA.Presets.Custom, path, self.value) end, true)
		return ref
    end

    for i, v in ipairs(AA.States) do
        local ID, Name, Short = v[1], v[2], v[3]

        Menu.AntiAim.Conditions[ID], pui.macros._p = {}, "\n"..Short
        local CTX = Menu.AntiAim.Conditions[ID]

        if ID ~= "global" then
			CTX.Override = New({id, "Override"}, Groups.Angles:checkbox("Override \v".. Name))
		end

        pui.traverse(CTX, function (ref, path)
			ref:depend({Menu.AntiAim.Condition, Name}, {Menu.AntiAim.Type, "Orion Solutions"}, {Menu.AntiAim.Presets, "Custom"}, path[#path] ~= "Override" and CTX.Override or nil)
		end)
    end
end

local Render = {
    Rectangle = function(x, y, w, h, n, r, g, b, a)
        x, y, w, h, n = x, y, w, h, n or 0
		
		if n == 0 then
			renderer.rectangle(x, y, w, h, r, g, b, a)
		else
			renderer.circle(x + n, y + n, r, g, b, a, n, 180, 0.25)
			renderer.rectangle(x + n, y, w - n - n, n, r, g, b, a)
			renderer.circle(x + w - n, y + n, r, g, b, a, n, 90, 0.25)
			renderer.rectangle(x, y + n, w, h - n - n, r, g, b, a)
			renderer.circle(x + n, y + h - n, r, g, b, a, n, 270, 0.25)
			renderer.rectangle(x + n, y + h - n, w - n - n, n, r, g, b, a)
			renderer.circle(x + w - n, y + h - n, r, g, b, a, n, 0, 0.25)
		end
    end,

    RectangleEdge = function (x, y, w, n, r, g, b, a)
		renderer.circle(x + n, y + n, r, g, b, a, n, 180, 0.25)
		renderer.rectangle(x + n, y, w - n - n, n, r, g, b, a)
		renderer.circle(x + w - n, y + n, r, g, b, a, n, 90, 0.25)
	end
}

local RESOLVER_CONST = {
    LAYER_AIMMATRIX = 0,
    LAYER_WEAPON_ACTION = 1,
    LAYER_WEAPON_ACTION_RECROUCH = 2,
    LAYER_ADJUST = 3,
    LAYER_MOVEMENT_JUMP_OR_FALL = 4,
    LAYER_MOVEMENT_LAND_OR_CLIMB = 5,
    LAYER_MOVEMENT_MOVE = 6,
    LAYER_MOVEMENT_STRAFECHANGE = 7,
    LAYER_WHOLE_BODY = 8,
    LAYER_FLASHED = 9,
    LAYER_FLINCH = 10,
    LAYER_ALIVELOOP = 11,
    LAYER_LEAN = 12,
    
    MAX_DESYNC_DELTA = 58,
    BRUTE_FORCE_STEPS = 5,
    MAX_HISTORY_SIZE = 64,
    MIN_DELTA_FOR_CORRECTION = 5,
    JITTER_DETECTION_THRESHOLD = 40,
    DEFENSIVE_TRIGGER_TIME = 0.15,
    RESOLVER_CHANGE_TIMEOUT = 2.0,
    
    STATE_STAND = 1,
    STATE_MOVE = 2,
    STATE_CROUCH = 3,
    STATE_AIR = 4,
    STATE_SLOWWALK = 5,
    STATE_CROUCHWALK = 6
}

local SequenceActivitySignature = client.find_signature('client_panorama.dll', '\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x8B\xF1\x83')
GetModel = function(EntityPointer)
	if EntityPointer then
		EntityPointer = ffi.cast(ClassPointer, EntityPointer)
		local ClientUnknown = ffi.cast('void*(__thiscall*)(void*)', EntityPointer[0][0])(EntityPointer)

		if ClientUnknown then
			ClientUnknown = ffi.cast(ClassPointer, ClientUnknown)
			local Renderable = ffi.cast('void*(__thiscall*)(void*)', ClientUnknown[0][5])(ClientUnknown)

			if Renderable then
				Renderable = ffi.cast(ClassPointer, Renderable)
                return ffi.cast('const void*(__thiscall*)(void*)', Renderable[0][8])(Renderable)
			end
		end
	end
end

GetAnimationState = function(EntityPointer)
	if not EntityPointer then
		return nil
	end
	return ffi.cast('struct animstate_tt*', ffi.cast('uintptr_t', EntityPointer) + 0x3914)
end
	
GetSequenceActivity = function(EntityPointer, Sequence)
	if not EntityPointer or not Sequence then return -1 end
    
    local ModelPointer = GetModel(EntityPointer)
    if not ModelPointer then return -1 end
    
    local StudioModel = GetStudioModel(ModelInfoPointer, ModelPointer)
    if not StudioModel then return -1 end
    
    local SequenceActivityfn = ffi.cast(GetSequenceActivity, SequenceActivitySignature)
    return SequenceActivityfn(EntityPointer, studio_model, Sequence)
end

GetAnimationLayer = function(EntityPointer, LayerIndex)
	if not EntityPointer then return nil end
    
    local AnimationLayerPointer = ffi.cast('struct animation_layer_tt**', ffi.cast('char*', EntityPointer) + 0x2990)
    if AnimationLayerPointer == nil or AnimationLayerPointer[0] == nil then return nil end
    
    return (LayerIndex >= 0 and LayerIndex <= 13) and AnimationLayerPointer[0][LayerIndex] or nil
end

GetAllAnimationLayers = function(EntityPointer)
	if not EntityPointer then return {} end
    
    local Layers = {}
    for i = 0, 13 do
        local Layer = GetAnimationLayer(EntityPointer, i)
        if Layer then
            Layers[i] = {
                sequence = Layer.m_nSequence,
                weight = Layer.m_flWeight,
                cycle = Layer.m_flCycle,
                playback_rate = Layer.m_flPlaybackRate,
                prev_cycle = Layer.m_flPrevCycle,
                weight_delta_rate = Layer.m_flWeightDeltaRate
            }
        end
    end
    
    return Layers
end

MathUtil = {
    clamp = function(value, min_val, max_val)
        if value > max_val then return max_val end
        if value < min_val then return min_val end
        return value
    end,
    
    normalize_yaw = function(yaw)
        while yaw > 360 do yaw = yaw - 360 end
        while yaw < 0 do yaw = yaw + 360 end
        return yaw
    end,
    
    to_180_range = function(yaw)
        if yaw > 180 then return yaw - 360 end
        return yaw
    end,
    
    lerp = function(a, b, t)
        return a + (b - a) * t
    end,
    
    approach_angle = function(target, current, speed)
        local delta = MathUtil.to_180_range(target - current)
        if speed > math.abs(delta) then
            return target
        end
        return MathUtil.normalize_yaw(current + (delta >= 0 and speed or -speed))
    end,
    
    angle_diff = function(a, b)
        local diff = math.abs(MathUtil.to_180_range(a) - MathUtil.to_180_range(b)) % 360
        return diff > 180 and 360 - diff or diff
    end
}

VectorUtil = {
    length = function(vec)
        return math.sqrt(vec.x*vec.x + vec.y*vec.y + vec.z*vec.z)
    end,
    
    length2d = function(vec)
        return math.sqrt(vec.x*vec.x + vec.y*vec.y)
    end,
    
    get_velocity = function(player)
        local vx = entity.get_prop(player, "m_vecVelocity[0]") or 0
        local vy = entity.get_prop(player, "m_vecVelocity[1]") or 0
        local vz = entity.get_prop(player, "m_vecVelocity[2]") or 0
        return {x = vx, y = vy, z = vz}
    end,
    
    get_origin = function(player)
        local x = entity.get_prop(player, "m_vecOrigin[0]") or 0
        local y = entity.get_prop(player, "m_vecOrigin[1]") or 0
        local z = entity.get_prop(player, "m_vecOrigin[2]") or 0
        return {x = x, y = y, z = z}
    end,
    
    predict_position = function(player, time_delta)
        local origin = VectorUtil.get_origin(player)
        local velocity = VectorUtil.get_velocity(player)
        
        return {
            x = origin.x + velocity.x * time_delta,
            y = origin.y + velocity.y * time_delta,
            z = origin.z + velocity.z * time_delta
        }
    end
}

StateUtil = {
    get_state = function(player)
        local duck_amount = entity.get_prop(player, "m_flDuckAmount") or 0
        local flags = entity.get_prop(player, "m_fFlags") or 0
        local in_air = bit.band(flags, 1) == 0
        local velocity = VectorUtil.get_velocity(player)
        local speed2d = VectorUtil.length2d(velocity)
        
        if in_air then
            return RESOLVER_CONST.STATE_AIR
        elseif duck_amount > 0.7 then
            return speed2d > 20 and RESOLVER_CONST.STATE_CROUCHWALK or RESOLVER_CONST.STATE_CROUCH
        elseif speed2d < 5 then
            return RESOLVER_CONST.STATE_STAND
        elseif speed2d < 40 then
            return RESOLVER_CONST.STATE_SLOWWALK
        else
            return RESOLVER_CONST.STATE_MOVE
        end
    end,
    
    is_breaking_lc = function(player, PlayerData)
        if not PlayerData.position_history or #PlayerData.position_history < 2 then
            return false
        end
        
        local cur_pos = VectorUtil.get_origin(player)
        local old_pos = PlayerData.position_history[#PlayerData.position_history]
        local vel = VectorUtil.get_velocity(player)
        local speed = VectorUtil.length2d(vel)
        
        local time_delta = globals.tickinterval() * (globals.tickcount() - PlayerData.last_tickcount)
        local max_possible_delta = speed * time_delta
        
        local actual_delta = VectorUtil.length({
            x = cur_pos.x - old_pos.x,
            y = cur_pos.y - old_pos.y,
            z = cur_pos.z - old_pos.z
        })
        
        return actual_delta > max_possible_delta * 1.5 or actual_delta > 64
    end
}

local PlayerData = {}
local resolver_stats = {
    total_hits = 0,
    total_misses = 0,
    hits_by_method = {
        animation = 0,
        matrix = 0,
        brute = 0,
        adaptive = 0,
        maximum = 0
    },
    misses_by_method = {
        animation = 0,
        matrix = 0,
        brute = 0,
        adaptive = 0,
        maximum = 0
    },
    misses_by_reason = {
        spread = 0,
        prediction = 0,
        lagcomp = 0,
        correction = 0,
        unknown = 0
    }
}

local MAX_PLAYERS = 64
for i = 1, MAX_PLAYERS do
    PlayerData[i] = {
        side = 1,             -- 1 = right, 2 = left, 0 = center
        desync = 25,          -- Desync value (0-60)
        last_pitch = 0,       -- For defensive AA detection
        anim_debug = 0,       -- Debug value for logs
        
        current_state = 0,    -- Current movement state
        is_breaking_lc = false, -- Lagcomp breaker detection
        defensive_triggered = false, -- Defensive AA active
        desync_pattern = "unknown", -- Detected pattern
        max_desync_delta = RESOLVER_CONST.MAX_DESYNC_DELTA, -- Maximum desync angle
        
        animation_layers_history = {}, -- Stores recent animation layers
        eye_angles_history = {},     -- Stores recent eye angles
        position_history = {},       -- Stores recent player positions
        simulation_time_history = {}, -- Stores recent simulation times
        jitter_data = {},           -- Jitter analysis data
        
        shots_fired = 0,
        shots_hit = 0,
        shots_missed = 0,
        last_hit_side = 0,
        last_miss_side = 0,
        miss_count = 0,         -- Consecutive misses for brute force
        last_missed_reason = "", -- Last miss reason
        
        brute_stage = 0,
        brute_direction = 1,    -- Direction to brute force
        brute_yaw_offset = 0,   -- Current brute force yaw
        
        last_update = 0,
        last_shot_time = 0,
        last_miss_time = 0,
        last_hit_time = 0,
        last_defensive_time = 0,
        last_resolving_method = "animation",
        last_tickcount = 0
    }
end

AnalyzeAnimationLayer = function(Layers)
	if not Layers or not Layers[RESOLVER_CONST.LAYER_MOVEMENT_MOVE] then
        return nil
    end
    
    local layer6 = Layers[RESOLVER_CONST.LAYER_MOVEMENT_MOVE]
    local playback_rate = layer6.playback_rate or 0
    local digits = {}
    
    for i = 1, 13 do
        digits[i] = math.floor(playback_rate * (10^i)) % 10
    end
    
    local anim_45 = tonumber(digits[4] .. digits[5]) or 0
    local anim_67 = tonumber(digits[6] .. digits[7]) or 0
    local anim_89 = tonumber(digits[8] .. digits[9]) or 0
    local anim_4567 = tonumber(anim_45 .. digits[6] .. digits[7]) or 0
    local anim_6789 = tonumber(anim_67 .. digits[8] .. digits[9]) or 0
    
    local r_side_r = digits[4] + digits[5] + digits[6] + digits[7]
    local r_side_s = digits[6] + digits[7] + digits[8] + digits[9]
    
    local diff_1 = math.abs(anim_6789 - anim_67)
    local diff_2 = math.abs(anim_4567 - anim_45)

    local weight_spread = 0
    local cycle_delta = 0
    
    if Layers[RESOLVER_CONST.LAYER_AIMMATRIX] and Layers[RESOLVER_CONST.LAYER_WEAPON_ACTION] then
        weight_spread = math.abs(Layers[RESOLVER_CONST.LAYER_AIMMATRIX].weight - Layers[RESOLVER_CONST.LAYER_WEAPON_ACTION].weight)
        cycle_delta = math.abs(Layers[RESOLVER_CONST.LAYER_AIMMATRIX].cycle - Layers[RESOLVER_CONST.LAYER_WEAPON_ACTION].cycle)
    end
    
    return {
        is_moving = digits[3] ~= 0,
        anim_45 = anim_45,
        anim_67 = anim_67,
        anim_89 = anim_89,
        anim_4567 = anim_4567,
        anim_6789 = anim_6789,
        r_side_r = r_side_r,
        r_side_s = r_side_s,
        diff_1 = diff_1,
        diff_2 = diff_2,
        digits = digits,
        weight_spread = weight_spread,
        cycle_delta = cycle_delta
    }
end

DetectJitterPattern = function(Player, PlayerData)
	if not PlayerData.animation_layers_history or #PlayerData.animation_layers_history < 3 then
        return "unknown", 0
    end
    
    local angle_switches = 0
    local last_side = 0
    local pattern_type = "unknown"
    local jitter_amount = 0
    
    if #PlayerData.eye_angles_history >= 3 then
        local angles = PlayerData.eye_angles_history
        
        for i = 1, #angles - 1 do
            local diff = MathUtil.angle_diff(angles[i].y, angles[i + 1].y)
            if diff > RESOLVER_CONST.JITTER_DETECTION_THRESHOLD then
                angle_switches = angle_switches + 1
                jitter_amount = math.max(jitter_amount, diff)
            end
        end
    end
    
    if #PlayerData.animation_layers_history >= 3 then
        local layers = PlayerData.animation_layers_history
        
        local weight_changes = 0
        local weight_sum = 0
        
        for i = 1, #layers - 1 do
            if layers[i][RESOLVER_CONST.LAYER_AIMMATRIX] and layers[i+1][RESOLVER_CONST.LAYER_AIMMATRIX] then
                local diff = math.abs(layers[i][RESOLVER_CONST.LAYER_AIMMATRIX].weight - layers[i+1][RESOLVER_CONST.LAYER_AIMMATRIX].weight)
                if diff > 0.2 then
                    weight_changes = weight_changes + 1
                    weight_sum = weight_sum + diff
                end
            end
        end
        
        if weight_changes > 0 then
            jitter_amount = math.max(jitter_amount, (weight_sum / weight_changes) * 100)
        end
    end
    
    if angle_switches >= 2 then
        pattern_type = "random"
    elseif angle_switches == 1 then
        pattern_type = "switch"
    elseif angle_switches == 0 then
        pattern_type = "static"
    end
    
    if pattern_type == "random" then
        jitter_amount = math.min(jitter_amount * 1.2, RESOLVER_CONST.MAX_DESYNC_DELTA)
    elseif pattern_type == "switch" then
        jitter_amount = math.min(jitter_amount, RESOLVER_CONST.MAX_DESYNC_DELTA)
    else
        jitter_amount = math.min(jitter_amount * 0.8, RESOLVER_CONST.MAX_DESYNC_DELTA)
    end
    
    return pattern_type, jitter_amount
end

DetectDefensiveAntiAim = function(Player, PlayerData)
	local EntityPointer = GetClientEntity(EntityListPointer, Player)
    if not EntityPointer then return false end
    
    local AnimationState = GetAnimationState(EntityPointer)
    if not AnimationState then return false end
    
    local defensiveActive = false
    
    if #PlayerData.eye_angles_history >= 3 then
        local current_pitch = PlayerData.eye_angles_history[1].x
        local prev_pitch = PlayerData.eye_angles_history[2].x
        
        if math.abs(current_pitch - prev_pitch) > 45 then
            defensiveActive = true
        end
    end--xd55
    
    if #PlayerData.animation_layers_history >= 2 then
        local current = PlayerData.animation_layers_history[1]
        local previous = PlayerData.animation_layers_history[2]
        
        if current[RESOLVER_CONST.LAYER_AIMMATRIX] and previous[RESOLVER_CONST.LAYER_AIMMATRIX] then
            local cycle_delta = math.abs(current[RESOLVER_CONST.LAYER_AIMMATRIX].cycle - previous[RESOLVER_CONST.LAYER_AIMMATRIX].cycle)
            local weight_delta = math.abs(current[RESOLVER_CONST.LAYER_AIMMATRIX].weight - previous[RESOLVER_CONST.LAYER_AIMMATRIX].weight)
            
            if cycle_delta > 0.9 or weight_delta > 0.9 then
                defensiveActive = true
            end
        end
    end
    
    if PlayerData.defensive_triggered and 
       globals.curtime() - PlayerData.last_defensive_time < RESOLVER_CONST.DEFENSIVE_TRIGGER_TIME then
        defensiveActive = true
    end

    if #PlayerData.simulation_time_history >= 2 then
        local sim_diff = PlayerData.simulation_time_history[1] - PlayerData.simulation_time_history[2]
        if sim_diff > globals.tickinterval() * 2 or sim_diff < 0 then
            defensiveActive = true
        end
    end
    
    if defensiveActive and not PlayerData.defensive_triggered then
        PlayerData.last_defensive_time = globals.curtime()
    end
    
    return defensiveActive
end

CalculateMaxDesync = function(Player, State)
	local MaxDesync = RESOLVER_CONST.MAX_DESYNC_DELTA

    if State == RESOLVER_CONST.STATE_AIR then
        MaxDesync = MaxDesync * 0.85
    elseif State == RESOLVER_CONST.STATE_MOVE then
        MaxDesync = MaxDesync * 0.9
    elseif State == RESOLVER_CONST.STATE_CROUCH then
        MaxDesync = MaxDesync * 0.95
    elseif State == RESOLVER_CONST.STATE_SLOWWALK then
        MaxDesync = MaxDesync * 0.92
    end
    
    return MaxDesync
end

ResolvePlayerAngle = function(Player, PlayerData)
	local resolved_side = 0
    local resolved_desync = 0
    local confidence = 0
    local resolver_method = "unknown"
    
    if Menu.Rage.Resolver.Options.value == "Resolve On Miss" and PlayerData.miss_count > 0 and PlayerData.last_miss_side ~= 0 and
       globals.curtime() - PlayerData.last_miss_time < RESOLVER_CONST.RESOLVER_CHANGE_TIMEOUT then
        
        if PlayerData.miss_count >= 3 then
            local brute_steps = RESOLVER_CONST.BRUTE_FORCE_STEPS
            local step_size = RESOLVER_CONST.MAX_DESYNC_DELTA / brute_steps
            local brute_stage = PlayerData.brute_stage % brute_steps
            local side_multiplier = PlayerData.brute_direction
            
            resolved_desync = step_size * (brute_stage + 1)
            resolved_side = side_multiplier > 0 and 1 or 2
            
            PlayerData.brute_stage = PlayerData.brute_stage + 1
            if PlayerData.brute_stage >= brute_steps then
                PlayerData.brute_direction = -PlayerData.brute_direction
                PlayerData.brute_stage = 0
            end
            
            return resolved_side, resolved_desync, 0.7, "brute"
        else
            resolved_side = PlayerData.last_miss_side == 1 and 2 or 1
            resolved_desync = PlayerData.max_desync_delta * 0.9
            return resolved_side, resolved_desync, 0.6, "miss"
        end
    end

	local ReoslverMode = Menu.Rage.Resolver.Mode.value
    
    if Menu.Rage.Resolver.Options.value == "Handle Defensive" and PlayerData.defensive_triggered then
        resolved_desync = RESOLVER_CONST.MAX_DESYNC_DELTA
        if PlayerData.last_hit_side ~= 0 and globals.curtime() - PlayerData.last_hit_time < 5.0 then
            resolved_side = PlayerData.last_hit_side
        else
            if #PlayerData.animation_layers_history > 0 then
                local layers = PlayerData.animation_layers_history[1]
                if layers[RESOLVER_CONST.LAYER_AIMMATRIX] then
                    resolved_side = layers[RESOLVER_CONST.LAYER_AIMMATRIX].weight > 0.5 and 1 or 2
                else
                    resolved_side = 1
                end
            else
                resolved_side = 1
            end
        end
        
        return resolved_side, resolved_desync, 0.65, "defensive"
    end
    
    if #PlayerData.animation_layers_history > 0 then
        local analysis = AnalyzeAnimationLayer(PlayerData.animation_layers_history[1])
        
        if analysis then
            if not analysis.is_moving then
                if (analysis.diff_1 > 10 and analysis.diff_1 < 500) or 
                   (analysis.diff_1 > 1200 and analysis.diff_1 < 2200) or 
                   (analysis.diff_1 > 2500 and analysis.diff_1 < 3100) or 
                   (analysis.diff_1 > 4600 and analysis.diff_1 < 5300) or 
                   (analysis.diff_1 > 7000 and analysis.diff_1 < 8000) then
                    resolved_side = 2  -- Left
                elseif (analysis.diff_1 > 500 and analysis.diff_1 < 1200) or 
                       (analysis.diff_1 > 2200 and analysis.diff_1 < 2500) or 
                       (analysis.diff_1 > 3100 and analysis.diff_1 < 4600) or 
                       (analysis.diff_1 > 5300 and analysis.diff_1 < 7000) or 
                       (analysis.diff_1 > 8000 and analysis.diff_1 < 9000) then
                    resolved_side = 1  -- Right
                end
                
                local tmp_desync = -3.4117 * analysis.r_side_s + 98.9393
                if tmp_desync < 64 then
                    resolved_desync = tmp_desync
                end
                
                PlayerData.anim_debug = analysis.diff_1
            else
                -- Moving pattern analysis
                if (analysis.diff_2 > 10 and analysis.diff_2 < 500) or 
                   (analysis.diff_2 > 1200 and analysis.diff_2 < 2200) or 
                   (analysis.diff_2 > 2500 and analysis.diff_2 < 3100) or 
                   (analysis.diff_2 > 4600 and analysis.diff_2 < 5700) or 
                   (analysis.diff_2 > 7000 and analysis.diff_2 < 8000) then
                    resolved_side = 2  -- Left
                elseif (analysis.diff_2 > 500 and analysis.diff_2 < 1200) or 
                       (analysis.diff_2 > 2200 and analysis.diff_2 < 2500) or 
                       (analysis.diff_2 > 3100 and analysis.diff_2 < 4600) or 
                       (analysis.diff_2 > 5700 and analysis.diff_2 < 7000) or 
                       (analysis.diff_2 > 8000 and analysis.diff_2 < 9000) then
                    resolved_side = 1  -- Right
                end
                
                local tmp_desync = -3.4117 * analysis.r_side_r + 98.9393
                if tmp_desync < 64 then
                    resolved_desync = tmp_desync
                end
                
                PlayerData.anim_debug = analysis.diff_2
            end
            
            if analysis.weight_spread > 0.5 then
                resolved_desync = math.min(resolved_desync * 1.15, RESOLVER_CONST.MAX_DESYNC_DELTA)
            end
            
            -- Jitter detection
            if Menu.Rage.Resolver.Options.value == "Detect Jitter" then
                local jitter_pattern, jitter_amount = DetectJitterPattern(player, PlayerData)
                
                if jitter_pattern ~= "unknown" and jitter_pattern ~= "static" then
                    resolved_desync = math.min(jitter_amount, RESOLVER_CONST.MAX_DESYNC_DELTA)
                    if jitter_pattern == "random" and PlayerData.last_miss_side ~= 0 then
                        resolved_side = PlayerData.last_miss_side == 1 and 2 or 1
                    end
                    
                    PlayerData.desync_pattern = jitter_pattern
                end
            end
            
            resolver_method = "animation"
            confidence = 0.8
        end
    end
    
    resolved_desync = MathUtil.clamp(math.abs(math.floor(resolved_desync)), 0, PlayerData.max_desync_delta)
    
    if ReoslverMode == "Aggressive" then
        resolved_desync = math.min(resolved_desync * 1.2, RESOLVER_CONST.MAX_DESYNC_DELTA)
        resolver_method = "aggressive"
    elseif ReoslverMode == "Brute Force" then
        if PlayerData.shots_fired > 0 then
            local hit_ratio = PlayerData.shots_hit / PlayerData.shots_fired
            if hit_ratio < 0.3 and PlayerData.shots_fired > 3 then
                local brute_factor = 0.5 + (PlayerData.brute_stage % 5) * 0.1
                resolved_desync = RESOLVER_CONST.MAX_DESYNC_DELTA * brute_factor
                
                if PlayerData.brute_stage % 2 == 0 then
                    resolved_side = resolved_side == 1 and 2 or 1
                end
                
                PlayerData.brute_stage = (PlayerData.brute_stage + 1) % 5
                resolver_method = "brute"
            end
        end
    elseif ReoslverMode == "Adaptive" then
        local hit_ratio = PlayerData.shots_hit / math.max(PlayerData.shots_fired, 1)
        
        if hit_ratio > 0.7 then
            resolved_desync = resolved_desync * 0.9
        elseif hit_ratio < 0.3 and PlayerData.shots_fired > 3 then
            resolved_side = PlayerData.last_miss_side == 1 and 2 or 1
            resolved_desync = PlayerData.max_desync_delta
        end
        
        resolver_method = "adaptive"
    elseif ReoslverMode == "Maximum" then
        resolved_desync = RESOLVER_CONST.MAX_DESYNC_DELTA
        resolver_method = "maximum"
    end

    if 	Menu.Rage.Resolver.Options.value == "Low Delta Priority" and resolved_desync > 30 then
        resolved_desync = resolved_desync * 0.85
    end
    
    local prediction_strength = Menu.Rage.Resolver.DesyncPrediction.value / 100
    if prediction_strength > 0 and #PlayerData.animation_layers_history > 1 then
        local analysis1 = AnalyzeAnimationLayer(PlayerData.animation_layers_history[1])
        local analysis2 = AnalyzeAnimationLayer(PlayerData.animation_layers_history[2])
        
        if analysis1 and analysis2 then
            local delta_weight = 0
            local delta_cycle = 0
            
            if analysis1.weight_spread > 0 and analysis2.weight_spread > 0 then
                delta_weight = analysis1.weight_spread - analysis2.weight_spread
            end
            
            if analysis1.cycle_delta > 0 and analysis2.cycle_delta > 0 then
                delta_cycle = analysis1.cycle_delta - analysis2.cycle_delta
            end
            
            local predicted_desync = resolved_desync
            if math.abs(delta_weight) > 0.1 then
                predicted_desync = resolved_desync + (delta_weight * 20 * prediction_strength)
            end
            
            resolved_desync = MathUtil.lerp(resolved_desync, predicted_desync, prediction_strength)
            resolved_desync = MathUtil.clamp(resolved_desync, 0, PlayerData.max_desync_delta)
        end
    end
    
    return resolved_side, resolved_desync, confidence, resolver_method
end

UpdatePlayerHistory = function(Player, PlayerData)
	local EntityPointer = GetClientEntity(EntityListPointer, Player)
    if not EntityPointer then return end

    local pitch = entity.get_prop(Player, "m_angEyeAngles[0]") or 0
    local yaw = entity.get_prop(Player, "m_angEyeAngles[1]") or 0
    
    if pitch and yaw then
        table.insert(PlayerData.eye_angles_history, 1, {x = pitch, y = yaw})
        if #PlayerData.eye_angles_history > RESOLVER_CONST.MAX_HISTORY_SIZE then
            table.remove(PlayerData.eye_angles_history)
        end
    end
    
    local sim_time = entity.get_prop(Player, "m_flSimulationTime")
    if sim_time then
        table.insert(PlayerData.simulation_time_history, 1, sim_time)
        
        if #PlayerData.simulation_time_history > 16 then
            table.remove(PlayerData.simulation_time_history)
        end
    end
    
    local origin = VectorUtil.get_origin(Player)
    table.insert(PlayerData.position_history, 1, origin)
    
    if #PlayerData.position_history > 16 then
        table.remove(PlayerData.position_history)
    end
    
    local layers = GetAllAnimationLayers(EntityPointer)
    if next(layers) then
        table.insert(PlayerData.animation_layers_history, 1, layers)
        
        if #PlayerData.animation_layers_history > 8 then
            table.remove(PlayerData.animation_layers_history)
        end
    end
    
    PlayerData.current_state = StateUtil.get_state(Player)
    PlayerData.max_desync_delta = CalculateMaxDesync(Player, PlayerData.current_state)
    PlayerData.is_breaking_lc = StateUtil.is_breaking_lc(Player, PlayerData)
    PlayerData.defensive_triggered = DetectDefensiveAntiAim(Player, PlayerData)
    
    PlayerData.last_tickcount = globals.tickcount()
end

ResolverUpdate = function()
	if not Menu.Rage.Resolver.on.value then
		return 
	end

	local Players = entity.get_players(true)
    
    for _, Player in ipairs(Players) do
        if not entity.is_alive(Player) then goto continue end
        
        UpdatePlayerHistory(Player, PlayerData[Player])
        
        local side, desync, confidence, method = ResolvePlayerAngle(Player, PlayerData[Player])

        PlayerData[Player].side = side
        PlayerData[Player].desync = desync
        PlayerData[Player].last_resolving_method = method
        PlayerData[Player].last_update = globals.curtime()
        
        plist.set(Player, "Force Body Yaw", true)
        
        if side == 1 then
            plist.set(Player, "Force Body Yaw Value", desync)  -- Right
        elseif side == 2 then
            plist.set(Player, "Force Body Yaw Value", -desync)  -- Left
        else
            plist.set(Player, "Force Body Yaw Value", 0)  -- Center
        end
        
        if PlayerData[Player].defensive_triggered then
            local Player_pitch = entity.get_prop(Player, "m_angEyeAngles[0]") or 0
            
            if Player_pitch < -80 then  -- Extremely low pitch, likely defensive
                plist.set(Player, "Force Pitch", true)
                plist.set(Player, "Force Pitch Value", PlayerData[Player].last_pitch or 0)
            else
                plist.set(Player, "Force Pitch", false)
                PlayerData[Player].last_pitch = Player_pitch
            end
        else
            plist.set(Player, "Force Pitch", false)
        end
        
        ::continue::
    end
end

AnalyzeMissReason = function(e)
	local reason = e.reason
    local target = e.target
    
    if not PlayerData[target] then return "unknown" end
    
    if reason == "?" then
        local target_data = PlayerData[target]
        
        if target_data.is_breaking_lc then
            resolver_stats.misses_by_reason.lagcomp = resolver_stats.misses_by_reason.lagcomp + 1
            return "lagcomp"
        end
        
        if target_data.defensive_triggered then
            resolver_stats.misses_by_reason.correction = resolver_stats.misses_by_reason.correction + 1
            return "defensive"
        end
        
        if math.abs(target_data.desync - RESOLVER_CONST.MAX_DESYNC_DELTA) > 10 then
            resolver_stats.misses_by_reason.prediction = resolver_stats.misses_by_reason.prediction + 1
            return "prediction"
        end
        
        resolver_stats.misses_by_reason.spread = resolver_stats.misses_by_reason.spread + 1
        return "spread"
    else
        if reason == "spread" then
            resolver_stats.misses_by_reason.spread = resolver_stats.misses_by_reason.spread + 1
        elseif reason == "prediction error" then
            resolver_stats.misses_by_reason.prediction = resolver_stats.misses_by_reason.prediction + 1
        else
            resolver_stats.misses_by_reason.unknown = resolver_stats.misses_by_reason.unknown + 1
        end
        
        return reason
    end
end

local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear'}

client.set_event_callback('aim_hit', function(e)
    if not Menu.Rage.Resolver.on.value then
		return 
	end
    
    local player = e.target
    if not PlayerData[player] then return end

    local p_data = PlayerData[player]
    local group = hitgroup_names[e.hitgroup + 1] or '?'
    local method = p_data.last_resolving_method or "unknown"
    
    p_data.shots_hit = p_data.shots_hit + 1
    p_data.shots_fired = p_data.shots_fired + 1
    p_data.last_hit_side = p_data.side
    p_data.last_hit_time = globals.curtime()
    p_data.miss_count = 0
    
    resolver_stats.total_hits = resolver_stats.total_hits + 1
    
    if resolver_stats.hits_by_method[method] then
        resolver_stats.hits_by_method[method] = resolver_stats.hits_by_method[method] + 1
    end
    
        client.color_log(120, 255, 140,
        string.format('[Orion Solutions] Hit %s in the %s for %d damage (%d health remaining) (Side: %s | Desync: %.1f° | Method: %s)',
        entity.get_player_name(player),
        group,
        e.damage,
        entity.get_prop(player, 'm_iHealth'),
        p_data.side == 1 and "Right" or (p_data.side == 2 and "Left" or "Center"),
        p_data.desync,
        method
        ))
end)

client.set_event_callback('aim_miss', function(e)
    if not Menu.Rage.Resolver.on.value then
		return 
	end
    
    local player = e.target
    if not PlayerData[player] then return end

    local p_data = PlayerData[player]
    local group = hitgroup_names[e.hitgroup + 1] or '?'
    local method = p_data.last_resolving_method or "unknown"
    
    local detailed_reason = AnalyzeMissReason(e)
    
    p_data.shots_missed = p_data.shots_missed + 1
    p_data.shots_fired = p_data.shots_fired + 1
    p_data.miss_count = p_data.miss_count + 1
    p_data.last_miss_side = p_data.side
    p_data.last_miss_time = globals.curtime()
    p_data.last_missed_reason = detailed_reason
    
    resolver_stats.total_misses = resolver_stats.total_misses + 1
    
    if resolver_stats.misses_by_method[method] then
        resolver_stats.misses_by_method[method] = resolver_stats.misses_by_method[method] + 1
    end
    
    client.color_log(255, 120, 120,
        string.format('[Orion Solutions] Missed %s (%s) due to %s | Detailed: %s (Side: %s | Desync: %.1f° | Method: %s)',
        entity.get_player_name(player),
        group,
        e.reason,
        detailed_reason,
        p_data.side == 1 and "Right" or (p_data.side == 2 and "Left" or "Center"),
        p_data.desync,
        method
    ))
end)

local my = {
	entity = entity.get_local_player(),
	valid,
	State,
	velocity,
}

my_setup = function(cmd)
	my.entity = entity.get_local_player()
	my.valid = (my.entity ~= nil ) and entity.is_alive(my.entity)
	local velocity = vector(entity.get_prop(my.entity, "m_vecVelocity"))
	my.velocity = velocity:length2d()

	if my.valid then
		local flags = entity.get_prop(my.entity, "m_fFlags")
		local grounded = bit.band(flags, bit.lshift(1, 0)) == 1
		
		if grounded or not cmd.in_jump == 1 then
			if (cmd.in_duck == 1) then
				my.state = 4 
			else

				if (my.velocity > 5) or (cmd.in_speed == 1) then
				
					if refs.aa.other.slowmo.hotkey:get() then
						my.state = 6
					else
						my.state = 2
					end
				else
					my.state = 1
				end
			end
		else
			if (cmd.in_duck == 1) then
				my.state = 5 
			else
				my.state = 3

			end
		end
	end
end

local function AntiAim()
	--print(AA.States[my.state])
	if Menu.AntiAim.Enable:get() then
		refs.aa.angles.enable:set(true)
	else
		refs.aa.angles.enable:set(false)
	end
end

function is_localplayer_in_game()
    local local_player = entity.get_local_player()

    if local_player == nil then
        return false
    end
    
    -- If all checks passed, we're in game
    return true
end

WaterMark = function()
    if not Menu.Visuals.WaterMark:get() then
        return
    end

    local Latency = math.floor(client.latency() * 1000 + 0.5)
    local pingText = "Ping: " .. tostring(Latency) .. "MS"

    local fullText = "Orion Solutions • " .. Globals.UserName .. " • " .. pingText .. " • Debug"
    local TextWidth, TextHeight = renderer.measure_text(nil, fullText)
    local Left = Globals.screen_x - TextWidth - 25

    local Player = entity.get_local_player()
    local SteamID3 = entity.get_steam64(Player)
    local Avatar = images.get_steam_avatar(SteamID3)

    Render.Rectangle(Left - 33, 9, TextWidth + 12 + 17, 22, 5, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a)
    Render.Rectangle(Left - 32, 10, TextWidth + 10 + 17, 20, 5, 23, 23, 23, 255)

    local currentX = Left - 10
    renderer.text(currentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, "Orion Solutions •")
    local partWidth = renderer.measure_text(nil, "Orion Solutions •")
    currentX = currentX + partWidth

    local userText = " " .. Globals.UserName
    renderer.text(currentX, 10 + TextHeight/4, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a, nil, 200, userText)
    partWidth = renderer.measure_text(nil, userText)
    currentX = currentX + partWidth

    renderer.text(currentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, " • ")
    partWidth = renderer.measure_text(nil, " • ")
    currentX = currentX + partWidth

    renderer.text(currentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, pingText)
    partWidth = renderer.measure_text(nil, pingText)
    currentX = currentX + partWidth

    renderer.text(currentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, " • ")
    partWidth = renderer.measure_text(nil, " • ")
    currentX = currentX + partWidth
    
    renderer.text(currentX, 10 + TextHeight/4, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a, nil, 200, "Debug")

    if is_localplayer_in_game() then
        Avatar:draw(Left - 28, 13 , 14.5, 15)
	    renderer.circle_outline(Left - 28 + 7.9, 12 + 8, 23, 23, 23, 255, 10, 0, 1, 3)
    end
end

AntiBackStab = function()
	if not Menu.Miscellaneous.AntiBackStab.on.value then return end

	local lp = entity.get_local_player()
	if not lp then return end
	local lppos = vector(entity.get_origin(lp))

	local target = client.current_threat()
	if not target then return end
	local tpos = vector(entity.get_origin(target))

	dist = lppos:dist(tpos)

	local weapon = entity.get_player_weapon(target)
	if dist <= Menu.Miscellaneous.AntiBackStab.Distance.value and entity.get_classname(weapon) == "CKnife" then
		refs.aa.angles.yaw[2]:override(180)
	else
		refs.aa.angles.yaw[2]:override(0)
	end
end

local BoughtThisRound = false
ResetBuybot = function()
	BoughtThisRound = false
end

HasWeapon = function(WeaponName)
	local CurrentWeapon = entity.get_player_weapon(entity.get_local_player())
    return CurrentWeapon == WeaponName
end

BuyWeapon = function()
	if BoughtThisRound then
		return 
	end

	BoughtThisRound = true

	client.delay_call(0.1, function()
		local PrimaryWeapon = Menu.Miscellaneous.BuyBot.PrimaryWeapon.value
		local SecondaryWeapon = Menu.Miscellaneous.BuyBot.SecondaryWeapon.value

		local BuyCommands = {}

		if PrimaryWeapon and PrimaryWeapon ~= "None" then
			local PrimaryWeaponCMD = {
				["Scout"] = "buy ssg08",
				["Auto"] = "buy scar20",
				["AWP"] = "buy awp"
			}
			if PrimaryWeaponCMD[PrimaryWeapon] and not HasWeapon(PrimaryWeapon) then
				table.insert(BuyCommands, PrimaryWeaponCMD[PrimaryWeapon])
			end
		end

		if SecondaryWeapon and SecondaryWeapon ~= "None" then
            local SecondaryWeaponCMD = {
                ["Glock"] = "buy glock",
                ["USP-S"] = "buy usp_silencer",
                ["P250"] = "buy p250",
                ["Deagle"] = "buy deagle",
                ["Tec-9 / Five-SeveN"] = "buy tec9",
                ["CZ75"] = "buy cz75a",
                ["Dual Berettas"] = "buy elite"
            }
            if SecondaryWeaponCMD[SecondaryWeapon] and not has_weapon(SecondaryWeapon) then
                table.insert(BuyCommands, SecondaryWeaponCMD[SecondaryWeapon])
            end
        end

		if Menu.Miscellaneous.BuyBot.Grenades.value then
			table.insert(BuyCommands, "buy smokegrenade")
            table.insert(BuyCommands, "buy hegrenade")
            table.insert(BuyCommands, "buy incgrenade")
		end

		if Menu.Miscellaneous.BuyBot.Kevlar.value then
			table.insert(BuyCommands, "buy vesthelm")
		end

		if Menu.Miscellaneous.BuyBot.Taser.value then
			table.insert(BuyCommands, "buy taser")
		end

		for _, cmd in ipairs(BuyCommands) do
            client.exec(cmd)
        end
	end)
end

BuyBotHandler = function()
	if Menu.Miscellaneous.BuyBot.on.Value and not BoughtThisRound then
		if Menu.Miscellaneous.BuyBot.PistolRound.value or not not game_rules.is_pistol_round() then
			BuyWeapon()
		end
	end
end

client.set_event_callback("round_start", ResetBuybot)
client.set_event_callback("player_spawn", BuyBotHandler)

MenuUpdate = function()
    refs.aa.angles.enable:depend({Menu.Tabs, "yg"})
	refs.aa.angles.pitch[1]:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.pitch[2]:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.base:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.yaw[1]:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.yaw[2]:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.jitter[1]:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.jitter[2]:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.body[1]:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.body[2]:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.edge:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.fs_body:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.freestand:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.freestand.hotkey:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})
	refs.aa.angles.roll:depend({Menu.Tabs, "Anti-Aim"}, {Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "GameSense"})

	refs.aa.other.slowmo:depend({Menu.Tabs, "AntiAim"})
	refs.aa.other.slowmo.hotkey:depend({Menu.Tabs, "AntiAim"})
	refs.aa.other.legs:depend({Menu.Tabs, "AntiAim"})
	refs.aa.other.onshot:depend({Menu.Tabs, "AntiAim"})
	refs.aa.other.onshot.hotkey:depend({Menu.Tabs, "AntiAim"})
	refs.aa.other.fp:depend({Menu.Tabs, "AntiAim"})
	refs.aa.other.fp.hotkey:depend({Menu.Tabs, "AntiAim"})

	refs.aa.fakelag.enable:depend({Menu.Tabs, "yg"})
	refs.aa.fakelag.enable.hotkey:depend({Menu.Tabs, "yg"})
	refs.aa.fakelag.variance:depend({Menu.Tabs, "yg"})
	refs.aa.fakelag.amount:depend({Menu.Tabs, "yg"})
	refs.aa.fakelag.limit:depend({Menu.Tabs, "yg"})

	pui.traverse(Menu.Home.Statistics, function(ref, path)
		ref:depend({Menu.Tabs, "Home"})
	end)

	pui.traverse(Menu.Rage, function (ref, path)
		ref:depend({Menu.Tabs, "Rage"})
	end)
	
	pui.traverse(Menu.AntiAim, function(ref,path)
		ref:depend({Menu.Tabs, "Anti-Aim"})
	end)

	pui.traverse(Menu.Visuals, function (ref, path)
		ref:depend({Menu.Tabs, "Visuals"})
	end)

	pui.traverse(Menu.Miscellaneous, function (ref, path)
		ref:depend({Menu.Tabs, "Miscellaneous"})
	end)

	Menu.AntiAim.Type:depend({Menu.AntiAim.Enable, true})
	Menu.AntiAim.Presets:depend({Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "Orion Solutions"})
	Menu.AntiAim.Condition:depend({Menu.AntiAim.Enable, true}, {Menu.AntiAim.Type, "Orion Solutions"}, {Menu.AntiAim.Presets, "Custom"})
end

MenuUpdate()

local function Lerp(a, b, t)
    if a == nil or b == nil or t == nil then
        return 0  -- Default fallback
    end
    return a + (b - a) * t
end

local notification = {
    start_time = 0,       
    check = false,        
    start_time2 = 0,      
    check2 = false,       
    alpha = 0,            
    text_alpha = 0,       
    menu_alpha = 0        
}

local ba = [[
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <path d="M12 3a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm-1 2h2v6h-2zm-5 1c-2 2-3 4-2 6s3 3 5 1 1-4-1-6zm8 0c2 2 3 4 1 6s-5 1-5-1 1-4 1-6zm-3 7h2v6a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-6z" fill="#ffffff"/>
</svg>
]]

notification.OnLoad = function()
    local self = notification

    self.alpha = Lerp(self.alpha, self.check and 0 or 1, globals.frametime() * 6)
    self.menu_alpha = Lerp(self.menu_alpha, ui.is_menu_open() and 1 or 0, globals.frametime() * 6)
    self.text_alpha = Lerp(self.text_alpha, self.check2 and 1 or 0, globals.frametime() * 6)

    local function draw_notification_bar(x, y, width, height, r, g, b, a)
        renderer.gradient(x + 30, y + 2, width - 4, height - 4, 15, 15, 15, a / 2, 0, 0, 0, 0, true)
        renderer.rectangle(x, y, 30, height, 25, 25, 25, a)
        renderer.triangle(x, y, x, y + height, x - 10, y + height, 25, 25, 25, a)
        renderer.triangle(x + 30, y, x + 30, y + height, x + 30 + 10, y, 25, 25, 25, a)
        renderer.gradient(x - 1, y - 2, 41, 2, r, g, b, a, r, g, b, a, true)
        renderer.line(x, y - 2, x - 10, y - 2 + height + 1, r, g, b, a)
        renderer.line(x - 1, y - 2, x - 1 - 10, y - 2 + height + 1, r, g, b, a)
        renderer.line(x - 2, y - 2, x - 2 - 10, y - 2 + height + 1, r, g, b, a)
        renderer.line(x + 41, y - 1, x + 41 - 10, y - 1 + height, 10, 10, 10, a)
        
        local icon_texture = renderer.load_svg(ba or "", 23, 23)
        renderer.texture(icon_texture, x + 4, y - 1, 23, 23, r, g, b, a, "f")
    end

    local menu_x, menu_y = ui.menu_position()
    local r, g, b, a = 255, 255, 255, 255 
	local accent_r, accent_g, accent_b = Menu.Miscellaneous.AccentColor:get()

    draw_notification_bar(menu_x + 12, menu_y - 25, 250 * self.menu_alpha, 20, accent_r, accent_g, accent_b, 255 * self.menu_alpha)

    local gradient_text = "O R I O N  S O L U T I O N S" 

    renderer.text(menu_x + 12 + 40 + 1, menu_y - 22 - 1, 0, 0, 0, 255 * self.menu_alpha, nil, nil, "O R I O N  S O L U T I O N S")
    renderer.text(menu_x + 12 + 40 - 1, menu_y - 22 + 1, 0, 0, 0, 255 * self.menu_alpha, nil, nil, "O R I O N  S O L U T I O N S")
    renderer.text(menu_x + 12 + 40 - 1, menu_y - 22 - 1, 0, 0, 0, 255 * self.menu_alpha, nil, nil, "O R I O N  S O L U T I O N S")
    renderer.text(menu_x + 12 + 40 + 2, menu_y - 22 + 2, 0, 0, 0, 255 * self.menu_alpha, nil, nil, "O R I O N  S O L U T I O N S")
    renderer.text(menu_x + 12 + 40 + 1, menu_y - 22 + 1, 255, 255, 255, 255 * self.menu_alpha, nil, nil, gradient_text)
    renderer.text(menu_x + 12 + 40, menu_y - 22, 255, 255, 255, 255 * self.menu_alpha, nil, nil, "O R I O N  S O L U T I O N S")

    local current_time = globals.realtime()
    if self.start_time2 + 3 < current_time then
        self.start_time2 = current_time
        self.check2 = true
    end
    if self.start_time + 5 < current_time then
        self.start_time = current_time
        self.check = true
    end
end

Menu.Miscellaneous.AccentColor:set_callback(function(this)
    local r, g, b = unpack(this.value)
    colors.accent = color.rgb(r, g, b, 255)
    colors.hex = "\a".. colors.accent:to_hex()
	colors.hexs = string.sub(colors.hex, 1, -3)

    refs.misc.settings.accent:set(Menu.Miscellaneous.AccentColor.value)
end, true)

local Y = 0  -- Initialize with default value
local Alpha = 255
local ShowLoding = true

client.set_event_callback("paint_ui", function()
	if ShowLoding then
		local Screen = vector(client.screen_size())
    	local Size = vector(Screen.x, Screen.y)

		renderer.blur(0, 0, Screen.x, Screen.y, 15, 15, 15, 150)  -- Adjust alpha as needed
    	local Sizing = Lerp(0.1, 0.9, math.sin(globals.realtime() * 0.9) * 0.5 + 0.5)
    	local Rotation = Lerp(0, 360, globals.realtime() % 1)
    	Alpha = Lerp(Alpha, 0, globals.frametime() * 0.5)
    	Y = Lerp(Y, 20, globals.frametime() * 2)  -- Fixed: `Y` instead of `y`
	
		renderer.rectangle(0, 0, Size.x, Size.y, 13, 13, 13, Alpha)
    	renderer.circle_outline(Screen.x / 2, Screen.y / 2, 255, 255, 255, Alpha, 20, Rotation, Sizing, 3)
    	renderer.text(Screen.x / 2, Screen.y / 2 + 40, 255, 255, 255, Alpha, 'c', 0, 'Loading...')
    	renderer.text(Screen.x / 2, Screen.y / 2 + 60, 255, 255, 255, Alpha, 'c', 0, 'Welcome - ' .. Globals.UserName)
	end

    notification.OnLoad()

    WaterMark()
end)

client.delay_call(8, function()
    ShowLoding = false
end)

client.set_event_callback("paint", function()
	Menu.Home.Statistics.KillCounter:set("\f<silent>Kills: \v" .. Data.KillCount)
	Menu.Home.Statistics.CoinCounter:set("\f<silent>Coins: \v" .. Data.Coins)
end)

client.set_event_callback("player_death", function(e)
	if client.userid_to_entindex(e.attacker) == entity.get_local_player() then
		Data.KillCount = (Data.KillCount or 0) + 1
		Data.Coins = (Data.Coins or 0) + 1
		if e.headshot then
			Data.Coins = (Data.Coins or 0) + 1
		end
	end
end)

local shooterid = 0 

client.set_event_callback("weapon_fire", function(e)
	if client.userid_to_entindex(e.userid) ~= entity.get_local_player() and entity.is_enemy(client.userid_to_entindex(e.userid)) then
		shooter = client.userid_to_entindex(e.userid)
		shooterid = shooter
	end
end)

local closest_ray_point = function (p, s, e)
	local t, d = p - s, e - s
	local l = d:length()
	d = d / l
	local r = d:dot(t)
	if r < 0 then return s elseif r > l then return e end
	return s + d * r
end

client.set_event_callback("bullet_impact", function(e)
    local shooter = client.userid_to_entindex(e.userid)
    if not shooter or shooter ~= entity.get_local_player() then return end
    
    local impact_pos = {e.x, e.y, e.z}
    local local_pos = {entity.get_origin(shooter)}
    
    local dir = {
        x = impact_pos[1] - local_pos[1],
        y = impact_pos[2] - local_pos[2],
        z = impact_pos[3] - local_pos[3]
    }
    
    local length = math.sqrt(dir.x^2 + dir.y^2 + dir.z^2)
    if length > 0 then
        dir.x = dir.x / length
        dir.y = dir.y / length
        dir.z = dir.z / length
    end
    
    local closest_player = nil
    local closest_dist = 100
    
    local players = entity.get_players(true)
    for i, player_idx in ipairs(players) do
        local head_pos = {entity.hitbox_position(player_idx, 0)}
        
        if head_pos and #head_pos >= 3 then
            local to_player = {
                x = head_pos[1] - local_pos[1],
                y = head_pos[2] - local_pos[2],
                z = head_pos[3] - local_pos[3]
            }
            
            local proj_length = to_player.x * dir.x + to_player.y * dir.y + to_player.z * dir.z
            
            if proj_length > 0 then
                local point = {
                    x = local_pos[1] + dir.x * proj_length,
                    y = local_pos[2] + dir.y * proj_length,
                    z = local_pos[3] + dir.z * proj_length
                }
                
                local dist = math.sqrt(
                    (point.x - head_pos[1])^2 +
                    (point.y - head_pos[2])^2 +
                    (point.z - head_pos[3])^2
                )
                
                if dist < closest_dist then
                    closest_dist = dist
                    closest_player = player_idx
                end
            end
        end
    end

    if shooterid == client.userid_to_entindex(e.userid) then
		head = entity.hitbox_position(entity.get_local_player(), 0)
		impact = vector(e.x, e.y, e.z)
		enemy_view = vector(entity.get_origin(shooterid))
		enemy_view.z = enemy_view.z + 64
		closest_ray_point(head,enemy_view,impact)
	end
end)

client.set_event_callback('setup_command', function(cmd)
    AntiBackStab()
    my_setup(cmd)
	AntiAim()

	local air_strafe = ui.reference("Misc", "Movement", "Air strafe")
	if Menu.Rage.JumpScout:get() then
		local vel_x, vel_y = entity.get_prop(entity.get_local_player(), "m_vecVelocity")
        local vel = math.sqrt(vel_x^2 + vel_y^2)
        ui.set(air_strafe, not (cmd.in_jump and (vel < 10)) or ui.is_menu_open())
	end
end)

client.set_event_callback("net_update_end", ResolverUpdate)

client.set_event_callback("shutdown", function()
	database.write("ORION_DATA", data)
	refs.aa.angles.enable:set(false)
end)