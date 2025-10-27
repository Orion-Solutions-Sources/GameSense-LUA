local http = require 'gamesense/http'
local pui = require 'gamesense/pui'
local color = require 'gamesense/color'
local msgpack = require 'gamesense/msgpack'
local base64 = require 'gamesense/base64'
local json = require 'json'
local ffi = require 'ffi'
local images = require 'gamesense/images'
local vector = require 'vector'
local clipboard = require 'gamesense/clipboard'
local weapons = require 'gamesense/csgo_weapons'

if not _G.OrionAuth then
    print("[Orion Solutions] ⚠ No OrionAuth data received.")
    print("[Orion Solutions] You must run this script through the loader.")
    return
end

print(string.format(
    "[Orion Solutions] 👋 Welcome back, %s! (UserID: %s, License Expires: %s)",
    _G.OrionAuth.Username or "Unknown",
    tostring(_G.OrionAuth.UserID or "nil"),
    tostring(_G.OrionAuth.LicenseExpires or "Unknown")
))

table.clear = require 'table.clear'
table.ifind = function (t, j)  for i = 1, #t do if t[i] == j then return i end end  end
table.append = function (t, ...)  for i, v in ipairs{...} do table.insert(t, v) end  end
table.mfind = function (t, j)  for i = 1, table.maxn(t) do if t[i] == j then return i end end  end
table.find = function (t, j)  for k, v in pairs(t) do if v == j then return k end end return false  end
table.filter = function (t)  local res = {} for i = 1, table.maxn(t) do if t[i] ~= nil then res[#res+1] = t[i] end end return res  end
table.copy = function (o) if type(o) ~= 'table' then return o end local res = {} for k, v in pairs(o) do res[table.copy(k)] = table.copy(v) end return res end
table.ihas = function (t, ...) local arg = {...} for i = 1, table.maxn(t) do for j = 1, #arg do if t[i] == arg[j] then return true end end end return false end
table.distribute = function (t, r, k)  local result = {} for i, v in ipairs(t) do local n = k and v[k] or i result[n] = r == nil and i or v[r] end return result  end
table.place = function (t, path, place)  local p = t for i, v in ipairs(path) do if type(p[v]) == 'table' then p = p[v] else p[v] = (i < #path) and {} or place  p = p[v]  end end return t  end

local References = {
	Rage = {
		Aimbot = {
            Enabled = pui.reference('RAGE', 'Aimbot', 'Enabled'),
			ForceBaim = pui.reference('RAGE', 'Aimbot', 'Force body aim'),
			ForceSafePoint = pui.reference('RAGE', 'Aimbot', 'Force safe point'),
			HitChance = pui.reference('RAGE', 'Aimbot', 'Minimum hit chance'),
			Damage = pui.reference('RAGE', 'Aimbot', 'Minimum damage'),
			DamageOverride = { pui.reference('RAGE', 'Aimbot', 'Minimum damage override') },
			DoubleTap = { pui.reference('RAGE', 'Aimbot', 'Double tap') },
            DT = pui.reference('RAGE', 'Aimbot', 'Double tap'),
			DoubleTapFakeLagLimit = { pui.reference('RAGE', 'Aimbot', 'Double tap fake lag limit') },
		},
		Other = {
			QuickPeek = pui.reference('RAGE', 'Other', 'Quick peek assist'),
			Duck = pui.reference('RAGE', 'Other', 'Duck peek assist'),
			LogMisses = pui.reference('RAGE', 'Other', 'Log misses due to spread'),
            AntiAimCorrection = pui.reference('RAGE', 'Other', 'Anti-Aim Correction'),
		}
	},
	AntiAim = {
		Angles = {
			Enable = pui.reference('AA', 'Anti-Aimbot angles', 'Enabled'),
			Pitch = { pui.reference('AA', 'Anti-Aimbot angles', 'Pitch') },
			Yaw = { pui.reference('AA', 'Anti-Aimbot angles', 'Yaw') },
			YawBase = pui.reference('AA', 'Anti-Aimbot angles', 'Yaw base'),
			YawJitter = { pui.reference('AA', 'Anti-Aimbot angles', 'Yaw jitter') },
			BodyYaw = { pui.reference('AA', 'Anti-Aimbot angles', 'Body yaw') },
			EdgeYaw = pui.reference('AA', 'Anti-Aimbot angles', 'Edge yaw'),
			FreestandingBodyYaw = pui.reference('AA', 'Anti-Aimbot angles', 'Freestanding body yaw'),
			Freestanding = pui.reference('AA', 'Anti-Aimbot angles', 'Freestanding'),
			Roll = pui.reference('AA', 'Anti-Aimbot angles', 'Roll'),
		},
		FakeLag = {
			Enable = pui.reference('AA', 'Fake lag', 'Enabled'),
			Amount = pui.reference('AA', 'Fake lag', 'Amount'),
			Variance = pui.reference('AA', 'Fake lag', 'Variance'),
			Limit = pui.reference('AA', 'Fake lag', 'Limit'),
		},
		Other = {
			SlowWalk = pui.reference('AA', 'Other', 'Slow motion'),
			Legs = pui.reference('AA', 'Other', 'Leg movement'),
			OnShot = pui.reference('AA', 'Other', 'On shot anti-aim'),
			FakePeek = pui.reference('AA', 'Other', 'Fake peek'),
		}
	},
	Miscellaneous = {
		Clantag = pui.reference('MISC', 'Miscellaneous', 'Clan tag spammer'),
		LogDamage = pui.reference('MISC', 'Miscellaneous', 'Log damage dealt'),
		PingSpike = pui.reference('MISC', 'Miscellaneous', 'Ping spike'),
		Settings = {
			DPI = pui.reference('MISC', 'Settings', 'DPI scale'),
			MenuColor = pui.reference('MISC', 'Settings', 'Menu color'),
		},
		Movement = {
			AirStrafe = pui.reference('Misc', 'Movement', 'Air strafe')
		}
	},
    PList = {
        ResetAll = pui.reference('Players', 'Players', 'Reset All'),
        ForceBodyYaw = pui.reference('Players', 'Adjustments', 'Force Body Yaw'),
        CorrectionActive = pui.reference('Players', 'Adjustments', 'Correction Active'),
    }
}

local Time = {
    UnixTime = function()
        return client.unix_time()
    end,

    RealTime = function()
        local hours, minutes = client.system_time()
        return string.format('%02d:%02d', hours, minutes)
    end
}

local References = {
	Rage = {
		Aimbot = {
            Enabled = pui.reference('RAGE', 'Aimbot', 'Enabled'),
			ForceBaim = pui.reference('RAGE', 'Aimbot', 'Force body aim'),
			ForceSafePoint = pui.reference('RAGE', 'Aimbot', 'Force safe point'),
			HitChance = pui.reference('RAGE', 'Aimbot', 'Minimum hit chance'),
			Damage = pui.reference('RAGE', 'Aimbot', 'Minimum damage'),
			DamageOverride = { pui.reference('RAGE', 'Aimbot', 'Minimum damage override') },
			DoubleTap = { pui.reference('RAGE', 'Aimbot', 'Double tap') },
            DT = pui.reference('RAGE', 'Aimbot', 'Double tap'),
			DoubleTapFakeLagLimit = { pui.reference('RAGE', 'Aimbot', 'Double tap fake lag limit') },
		},
		Other = {
			QuickPeek = pui.reference('RAGE', 'Other', 'Quick peek assist'),
			Duck = pui.reference('RAGE', 'Other', 'Duck peek assist'),
			LogMisses = pui.reference('RAGE', 'Other', 'Log misses due to spread'),
            AntiAimCorrection = pui.reference('RAGE', 'Other', 'Anti-Aim Correction'),
		}
	},
	AntiAim = {
		Angles = {
			Enable = pui.reference('AA', 'Anti-Aimbot angles', 'Enabled'),
			Pitch = { pui.reference('AA', 'Anti-Aimbot angles', 'Pitch') },
			Yaw = { pui.reference('AA', 'Anti-Aimbot angles', 'Yaw') },
			YawBase = pui.reference('AA', 'Anti-Aimbot angles', 'Yaw base'),
			YawJitter = { pui.reference('AA', 'Anti-Aimbot angles', 'Yaw jitter') },
			BodyYaw = { pui.reference('AA', 'Anti-Aimbot angles', 'Body yaw') },
			EdgeYaw = pui.reference('AA', 'Anti-Aimbot angles', 'Edge yaw'),
			FreestandingBodyYaw = pui.reference('AA', 'Anti-Aimbot angles', 'Freestanding body yaw'),
			Freestanding = pui.reference('AA', 'Anti-Aimbot angles', 'Freestanding'),
			Roll = pui.reference('AA', 'Anti-Aimbot angles', 'Roll'),
		},
		FakeLag = {
			Enable = pui.reference('AA', 'Fake lag', 'Enabled'),
			Amount = pui.reference('AA', 'Fake lag', 'Amount'),
			Variance = pui.reference('AA', 'Fake lag', 'Variance'),
			Limit = pui.reference('AA', 'Fake lag', 'Limit'),
		},
		Other = {
			SlowWalk = pui.reference('AA', 'Other', 'Slow motion'),
			Legs = pui.reference('AA', 'Other', 'Leg movement'),
			OnShot = pui.reference('AA', 'Other', 'On shot anti-aim'),
			FakePeek = pui.reference('AA', 'Other', 'Fake peek'),
		}
	},
	Miscellaneous = {
		Clantag = pui.reference('MISC', 'Miscellaneous', 'Clan tag spammer'),
		LogDamage = pui.reference('MISC', 'Miscellaneous', 'Log damage dealt'),
		PingSpike = pui.reference('MISC', 'Miscellaneous', 'Ping spike'),
		Settings = {
			DPI = pui.reference('MISC', 'Settings', 'DPI scale'),
			MenuColor = pui.reference('MISC', 'Settings', 'Menu color'),
		},
		Movement = {
			AirStrafe = pui.reference('Misc', 'Movement', 'Air strafe')
		}
	},
    PList = {
        ResetAll = pui.reference('Players', 'Players', 'Reset All'),
        ForceBodyYaw = pui.reference('Players', 'Adjustments', 'Force Body Yaw'),
        CorrectionActive = pui.reference('Players', 'Adjustments', 'Correction Active'),
    }
}

local Globals = {
    UserData = {
        LoggedIN = true,
        Username = _G.OrionAuth.Username,
        UserID = _G.OrionAuth.UserID,
        HWID = _G.OrionAuth.HWID,
        IsAdmin = _G.OrionAuth.IsAdmin,
        Version = _G.OrionAuth.Version,
        LastUpdateTime = 0,
        LoginTime = nil,
        Stats = {  -- Add stats section
            KillCount = 0,
            Coins = 0,
            TimesLoaded = 0
        },
    },
    ScreenX, ScreenY,
    OnlineUsers = 0,
    LastOnlineUpdate = 0,
    LastOnlineCountUpdate = 0,
    LastCleanup = 0
}

client.exec('Clear')

GetHWID = function()
    local material_adapter_info_t = ffi.typeof([[struct {
        char driver_name[512];
        uint32_t vendor_id;
        uint32_t device_id;
        uint32_t sub_sys_id;
        uint32_t revision;
        int dx_support_level;
        int min_dx_support_level;
        int max_dx_support_level;
        uint32_t driver_version_high;
        uint32_t driver_version_low;
    }]])

    local native_GetCurrentAdapter = vtable_bind("materialsystem.dll", "VMaterialSystem080", 25, "int(__thiscall*)(void*)")
    local native_GetAdapterInfo = vtable_bind("materialsystem.dll", "VMaterialSystem080", 26, "void(__thiscall*)(void*, int, void*)")

    local adapter_info = material_adapter_info_t()
    native_GetAdapterInfo(native_GetCurrentAdapter(), adapter_info)

    local gpu = tostring(adapter_info.vendor_id) ..
                tostring(adapter_info.sub_sys_id) ..
                tostring(adapter_info.device_id)

    if gpu == "0" or #ffi.string(adapter_info.driver_name) < 3 then
        return nil
    end

    return gpu
end

Globals.ScreenX, Globals.ScreenY = client.screen_size()

local a = function (...) return ... end

local color do
    local helpers = {
        RGBtoHEX = a(function (col, short)
            if short then
                return string.format('%02X%02X%02X', col.r, col.g, col.b)
            else
                return string.format('%02X%02X%02X%02X', col.r, col.g, col.b, col.a)
            end
        end),
        HEXtoRGB = a(function (hex)
            hex = string.gsub(hex, '^#', '')
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

	create = ffi.metatype(ffi.typeof('struct { uint8_t r; uint8_t g; uint8_t b; uint8_t a; }'), mt)

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
            return type(r) == 'string' and self.hex(r) or self.rgb(r, g, b, a)
        end),
    })
end

local colors = {
	hex		= '\aafafff',
	accent	= color.hex('afafff'),
	back	= color.rgb(23, 26, 28),
	dark	= color.rgb(5, 6, 8),
	white	= color.rgb(255),
	black	= color.rgb(0),
	null	= color.rgb(0, 0, 0, 0),
	text	= color.rgb(230),
}

local Utils do
    Utils = {}

    Utils.Lerp = function(start, end_pos, time, ampl)
        if start == end_pos then return end_pos end
        ampl = ampl or 1/globals.frametime()
        local frametime = globals.frametime() * ampl
        time = time * frametime
        local val = start + (end_pos - start) * time
        if(math.abs(val - end_pos) < 0.25) then return end_pos end
        return val 
    end

    Utils.ToHex = function(color, cut)
        return string.format('%02X%02X%02X'.. (cut and '' or '%02X'), color.r, color.g, color.b, color.a or 255)
    end

    Utils.ToRGB = function(hex)
        hex = hex:gsub('^#', '')
        return color(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), tonumber(hex:sub(7, 8), 16) or 255)
    end

    Utils.Print = function(text)
        local result = {}

        for color, content in text:gmatch('\a([A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])([^%z\a]*)') do
            table.insert(result, {color, content})
        end
        local len = #result
        for i, t in pairs(result) do
            c = Utils.ToRGB(t[1])
            client.color_log(c.r, c.g, c.b, t[2], len ~= i and '\0' or '')
        end
    end
end

local GUI = {
	Header = function(name, group) 
		r = {}
		r[#r+1] = group:label('\f<c> '..name)
		r[#r+1] = group:label('\f<silent>‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾') 
		return r
	end,
	Feature = function (main, settings)
	    main = main.__type == 'pui::element' and {main} or main
		local feature, g_depend = settings(main[1])

	    for k, v in pairs(feature) do
			v:depend({main[1], g_depend})
		end
		feature[main.key or 'on'] = main[1]

		return feature
	end,
	Space = function(group) group:label('\n') end,
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
    Angles = pui.group('AA', 'Anti-aimbot angles'),
    FakeLag = pui.group('AA', 'Fake lag'),
    Other = pui.group('AA', 'Other'),
    LuaB = pui.group('LUA', 'B'),
	LuaA = pui.group('LUA', 'A')
}

pui.macros.silent = '\aCDCDCD40'
pui.macros.p = '\a7676FF•\r'
pui.macros.c = '\v•\r' 
pui.macros.orion = colors.hex
pui.macros.orionb = string.sub(colors.hex, 2, 7)
pui.macros.white = '\affffff'
pui.macros.red = '\aff0000'
pui.macros.green = '\a00ff00'
pui.macros.blue = '\a00ffff'
pui.macros.yellow = '\affff00'

local PrimaryWeapons = {
    '-', 
    'AWP', 
    'SCAR20/G3SG1', 
    'Scout', 
    'M4/AK47', 
    'Famas/Galil', 
    'Aug/SG553', 
    'M249/Negev', 
    'Mag7/SawedOff', 
    'Nova', 
    'XM1014', 
    'MP9/Mac10', 
    'UMP45', 
    'PPBizon', 
    'MP7'
}

local SecondaryWeapons = {
    '-', 
    'CZ75/Tec9/FiveSeven', 
    'P250', 
    'Deagle/Revolver', 
    'Dualies'
}

local Grenades = {
    'HE Grenade', 
    'Molotov', 
    'Smoke'
}

local Utilities = {
    'Armor', 
    'Helmet', 
    'Zeus', 
    'Defuser'
}

local Commands = {
	['AWP'] = 'buy awp',
	['SCAR20/G3SG1'] = 'buy scar20',
	['Scout'] = 'buy ssg08',
	['M4/AK47'] = 'buy m4a1',
	['Famas/Galil'] = 'buy famas',
	['Aug/SG553'] = 'buy aug',
    ['M249'] = 'buy m249',
    ['Negev'] = 'buy negev',
	['Mag7/SawedOff'] = 'buy mag7',
	['Nova'] = 'buy nova',
	['XM1014'] = 'buy xm1014',
	['MP9/Mac10'] = 'buy mp9',
	['UMP45'] = 'buy ump45',
	['PPBizon'] = 'buy bizon',
	['MP7'] = 'buy mp7',
	['CZ75/Tec9/FiveSeven'] = 'buy tec9',
	['P250'] = 'buy p250',
	['Deagle/Revolver'] = 'buy deagle',
	['Dualies'] = 'buy elite',
	['HE Grenade'] = 'buy hegrenade',
	['Molotov'] = 'buy molotov',
	['Smoke'] = 'buy smokegrenade',
	['Flash'] = 'buy flashbang',
	['Decoy'] = 'buy decoy',
	['Armor'] = 'buy vest',
	['Helmet'] = 'buy vesthelm',
	['Zeus'] = 'buy taser 34',
	['Defuser'] = 'buy defuser'
}

local LogsType = {
    'Screen',
    'Console'
}

local LogsOption = {
    'Hit',
    'Miss',
    'Casino',
    'Config Changes (Soon)'
}

local ResolverModes = {
    'Math.Random',
    'Soon'
}

local WaterMarkModes = {
    "Modern",
    "Simple"
}

local FakeLagAmount = {
    'Dynamic',
    'Maximum',
    'Fluctuate'
}

local ToolTips = {
    BackTrack = {[2] = 'Default', [7] = 'Maximum'},
    AspectRatios = { {125, '5:4'}, {133, '4:3'}, {150, '3:2'}, {160, '16:10'}, {178, '16:9'}, {200, '2:1'}, }
}

local TabNames = {'Home', 'Rage', 'Anti-Aim', 'Visuals', 'Miscellaneous', 'Casino'}

local db do
    db = {}
    local Key = 'OrionConfigs::db'
    db.db = database.read(Key)

    db.save = function()
        database.write(Key, db.db)
        client.delay_call(0, function()
            database.flush()
        end)
    end

    do
        if not db.db then
            db.db = {
                configs = {
                    ['Local'] = {},
                    ['Cloud'] = {},
                }
            }
        end
    end

    db.db.configs['Local'][1] = {"Default"}
    db.db.configs['Cloud'][2] = {""}
    db.configs = {""}
    db.configs.authors = {'qqwerty', 'debil', 'esoterik', 'dalbaeb'}
end

local ConditionList = {
    'Standing',      -- State 1
    'Running',       -- State 2  
    'Slowwalking',   -- State 6
    'Crouching',     -- State 4
    'Crouch Moving', -- State 5
    'Jumping',       -- State 3
    'Air Crouching', -- State 7 (NEW)
    'Fake Ducking',  -- State 8 (NEW)
    'Fake Lagging',  -- State 9
    'Manual Yaw',    -- State 10
    'Safe Head',     -- State 11
    'Dormant'        -- State 12
}

local AntiAimTypes = {
    "Builder",
    "Defensive"
}

local AA = {
    States = {
        {'stand', 'Standing', 'S'},
        {'run', 'Running', 'R'},
        {'air', 'In Air', 'A'},
        {'crouch', 'Crouching', 'C'},
        {'crouch_move', 'Crouch Moving', 'CM'},
        {'walk', 'Slow Walking', 'SW'},
        {'air_crouch', 'Air Crouching', 'AC'},  -- New
        {'fakeduck', 'Fake Ducking', 'FD'},  -- New
        {'fakelag', 'Fake Lagging', 'FL'},
        {'manual', 'Manual Yaw', 'M'},
        {'safehead', 'Safe Head', 'SH'},
        {'dormant', 'Dormant', 'D'}
    },
    Presets = {
        Custom = {
            [1] = {},
        },
    }
}

local gap,length = {},{}
do
    for i=0, 100 do
        gap[i] = 'Gap: '..i..'px'
    end
    for i=0, 200 do
        length[i] = 'length: '..i..'px'
    end
end

local Menu = {
    MainHeader = GUI.Header('Orion Solutions', Groups.FakeLag),

    Tabs = Groups.FakeLag:combobox('\n', TabNames),

    Home = {
        Statistics = {
            GUI.Header('Statistics', Groups.Other),
            TimesLoadedCounter = Groups.Other:label('\f<silent>Times Loaded: \v0'),
            KillCounter = Groups.Other:label('\f<silent>Kills: \v0'),
            CoinCounter = Groups.Other:label('\f<silent>Coins: \v0'),
        },

        ConfigSystem = {
            NewConfigHeader = GUI.Header('New Config', Groups.FakeLag),
            Name = Groups.FakeLag:textbox('Name', nil, false),
            Create = Groups.FakeLag:button('Create & Save'),

            GUI.Space(Groups.Other),
            GUI.Header('Config Type', Groups.Other),
            Type = Groups.Other:combobox('Type', {'Local', 'Community'}),

            GUI.Header('Your Configs', Groups.Angles),
		    List = Groups.Angles:listbox('Configs', {}, nil, false),
		    Selected = Groups.Angles:label('Selected: \vDefault'),
		    Load = Groups.Angles:button('Load'),
		    Save = Groups.Angles:button('Save'),
		    Export = Groups.Angles:button('Export'),
		    Delete = Groups.Angles:button('\aFF0000FFDelete'),
        },
    },

    Rage = {
        GUI.Header('Rage', Groups.Angles),

        Resolver = GUI.Feature({Groups.Angles:checkbox('Resolver')}, function (Parent)
		    return {
                Mode = Groups.Angles:multiselect('Resolver Mode', ResolverModes),
		    }, true
	    end),

        BackTrackExploit = GUI.Feature({Groups.Angles:checkbox('Enhance Backtrack')}, function (Parent)
		    return {
			    BackTrackValue = Groups.Angles:slider('Value ', 2, 7, 1, true, nil, 0.1, ToolTips.BackTrack),
		    }, true
	    end),

        ImprovedPrediction = Groups.Angles:checkbox('Improved Prediction'),
		JumpScout = Groups.Angles:checkbox('Jump Scout'),
    },
    
    AntiAim = {
        FakeLag = {
            EnableFakeLag = GUI.Feature({Groups.FakeLag:checkbox('Enable FakeLag')}, function (Parent)
		        return {
                    Amount = Groups.FakeLag:combobox('Amount', FakeLagAmount),
                    Variance = Groups.FakeLag:slider('Variance ', 0, 100, 0, true, '%', 1),
			        Limit = Groups.FakeLag:slider('Limit ', 1, 15, 1),
		        }, true
	        end),
        },

        --ActiveConditions = Groups.FakeLag:multiselect('Active Conditions', ConditionList),
        AntiAimType = Groups.FakeLag:combobox('Types', AntiAimTypes),

        Builder = {
            GUI.Header('Condition Settings', Groups.Angles),
            Condition = Groups.Angles:combobox("\v•\r  Condition  \a373737FF", table.distribute(AA.States, 2), nil, false),

            States = {},
        },

        Defensive = {
            GUI.Header('Defensive AA', Groups.Angles),

        }
    },

    Visuals = {
        GUI.Header('Visuals', Groups.Angles),

        WaterMark = GUI.Feature({Groups.Angles:checkbox('WaterMark')}, function (Parent)
		    return {
                Mode = Groups.Angles:multiselect('Mode', WaterMarkModes),
		    }, true
	    end),
        AspectRatio = GUI.Feature({Groups.Angles:checkbox('Aspect Ratio')}, function(Parent)
            return {
                Ratio = Groups.Angles:slider('\nRatio', 80, 200, 133, true, nil, 0.01, table.distribute(ToolTips.AspectRatios, 2, 1))
            }, true
        end),
        
        GUI.Space(Groups.Angles),
        GUI.Header('Effects', Groups.Angles),

        BulletTracer = GUI.Feature({Groups.Angles:checkbox('BulletTracer')}, function(Parent)
            return {
                Color = Groups.Angles:color_picker('Color', colors.accent.r, colors.accent.g, colors.accent.b, 255),
            }, true
        end),

        CrosshairIndicator = GUI.Feature({Groups.Angles:checkbox('Crosshair Indicator')}, function(Parent)
            return {
                Elements = Groups.Angles:multiselect('Elements', {"Orion Solutions", "Condition", "Double Tap", "Hide Shots", "Min. Damage", "Ping Spike", "Freestanding"}),
                Color = Groups.Angles:color_picker('Text Color', 255, 255, 255, 255),
            }, true
        end),
    },

    Miscellaneous = {
        GUI.Header('Miscellaneous', Groups.Angles),
		Groups.Angles:label('Accent color'),
	    AccentColor = Groups.Angles:color_picker('Accent color', colors.accent.r, colors.accent.g, colors.accent.b, 255),
        AntiBackStab = GUI.Feature({Groups.Angles:checkbox('Anti BackStab')}, function (Parent)
		    return {
			    Distance = Groups.Angles:slider('Distance ', 0, 500, 160),
		    }, true
	    end),
		BuyBot = GUI.Feature({Groups.Angles:checkbox('Buy Bot')}, function(Parent)
			return {
			    Primary = Groups.Angles:combobox('Primary Weapon', PrimaryWeapons),
			    Secondary = Groups.Angles:combobox('Secondary Weapon', SecondaryWeapons),
			    Grenades = Groups.Angles:multiselect('Grenades', Grenades),
			    Utilities = Groups.Angles:multiselect('Utilities', Utilities),
			}, true
		end),
        Logs = GUI.Feature({Groups.Angles:checkbox('Logs')}, function (Parent)
		    return {
			    LogsType = Groups.Angles:multiselect('Logs Type', LogsType),
                LogsOption = Groups.Angles:multiselect('Logs Option', LogsOption),
		    }, true
	    end),
        ClanTag = Groups.Angles:checkbox('Orion-Tag'),
        FastLadder = Groups.Angles:checkbox('Fast Ladder'),
        Filter = Groups.Angles:checkbox('Console Filter'),
	},

    Casino = {
        GUI.Header('Games', Groups.Other),
        Game = Groups.Other:combobox('Games', 'Coin Flip', 'Coming Soon...'),

        GUI.Header('Casino', Groups.Angles),
        BetAmountLabel = Groups.Angles:label('Bet Amount: '),
        BetAmount = Groups.Angles:textbox('Bet Amount'),
        Flip = Groups.Angles:button('Flip Coin'),
        
        GUI.Space(Groups.FakeLag),
        Balance = Groups.FakeLag:label('\f<silent> Balance: \v0'),
    },

    LOGGEDIN = Groups.Angles:checkbox('LOGGED IN'),
    ISADMIN = Groups.Angles:checkbox('IS ADMIN'),
}

function UpdateCloudConfigs(configs)
    db.configs = {}
    for _, cfg in ipairs(configs) do
        local display = string.format("[%s] %s", cfg.Visibility or "Private", cfg.ConfigName or "Unnamed")
        table.insert(db.configs, display)
    end
    Menu.Home.ConfigSystem.List:update(db.configs)
    if #db.configs > 0 then
        Menu.Home.ConfigSystem.List.value = 0
        Menu.Home.ConfigSystem.Selected:set("Selected - " .. db.configs[1])
    else
        Menu.Home.ConfigSystem.Selected:set("No configs found")
    end
end

function LoadCloudConfigs()
    local userID = Globals.UserData.UserID
    if not userID then
        Utils.Print(pui.format('\f<white>[Orion Solutions] ⚠️ No user ID found — please log in first'))
        return
    end

    local url = string.format("https://orionsolutions.shop/API/GetConfigs.php?user_id=%s", userID)
    http.get(url, function(success, response)
        if not success or response.status ~= 200 then
            Utils.Print(pui.format("[Orion Solutions] ⚠️ Failed to fetch configs (Network Error)"))
            return
        end

        local ok, data = pcall(function() return json.parse(response.body) end)
        if not ok or not data or not data.success then
            Utils.Print(pui.format("[Orion Solutions] ⚠️ Invalid server response"))
            return
        end

        UpdateCloudConfigs(data.configs)
        Utils.Print(pui.format(string.format("[Orion Solutions] ✅ Loaded %d Cloud Configs", #data.configs)))
    end)
end

do
    local new = function (path, ref)
		ref:set_callback(function (self) table.place(AA.Presets.Custom, path, self.value) end, true)
		return ref
	end

    for i, v in ipairs(AA.States) do
        local ID, Name, Short = v[1], v[2], v[3]

        Menu.AntiAim.Builder.States[ID], pui.macros._p = {}, "\n" .. Short
        local CTX = Menu.AntiAim.Builder.States[ID]

        CTX.override = new({ID, "Override"}, Groups.Angles:checkbox("Override \v" .. Name))

        CTX.Pitch = new({ID, "Pitch"}, Groups.Angles:combobox('Pitch', {'Off', 'Default', 'Up', 'Down', 'Zero', 'Custom'}))
        CTX.YawBase = new({ID, "YawBase"}, Groups.Angles:combobox('Yaw Base', {'Local View', 'At Targets'}))
        CTX.Yaw = new({ID, "Yaw"}, Groups.Angles:combobox('Yaw', {'Off', '180', 'Spin', 'Static', '180 Z', 'Crosshair'}))
        CTX.YawOffset = new({ID, "YawOffset"}, Groups.Angles:slider('Yaw Offset', -180, 180, 0))
        CTX.YawJitter = new({ID, "YawJitter"}, Groups.Angles:combobox('Yaw Jitter', {'Off', 'Offset', 'Center', 'Random', 'Skitter'}))
        CTX.YawJitterOffset = new({ID, "YawJitterOffset"}, Groups.Angles:slider('Yaw Jitter Offset', -180, 180, 0))
        CTX.BodyYaw = new({ID, "BodyYaw"}, Groups.Angles:combobox('Body Yaw', {"Off", 'Opposite', 'Jitter', 'Static'}))
        CTX.BodyYawOffset = new({ID, "BodyYawOffset"}, Groups.Angles:slider("Body Yaw Offset", -180, 180, 0))
        CTX.FreestandingBodyYaw = new({ID, "FreestandingBodyYaw"}, Groups.Angles:checkbox('Freestanding Body Yaw'))
        CTX.EdgeYaw = new({ID, "EdgeYaw"}, Groups.Angles:checkbox('Edge Yaw'))
        CTX.Freestanding = new({ID, "Freestanding"}, Groups.Angles:checkbox('Freestanding'))
        CTX.Roll = new({ID, "Roll"}, Groups.Angles:slider("Roll", -45, 45, 0))

        pui.traverse(CTX, function(ref, path)
            ref:depend({Menu.AntiAim.Builder.Condition, Name}, path[#path] ~= "override" and CTX.override or nil)
        end)

        CTX.YawOffset:depend({CTX.Yaw, '180', 'Spin', 'Static', '180 Z', 'Crosshair'})
        CTX.BodyYawOffset:depend({CTX.BodyYaw, 'Jitter'})
        CTX.YawJitterOffset:depend({CTX.YawJitter, 'Offset', 'Center', 'Random', 'Skitter'})
    end

    pui.macros._p = nil
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
    end,

    avg = function(t)
        if not t or #t == 0 then return 0 end
        local sum = 0
        for i = 1, #t do
            sum = sum + (t[i] or 0)
        end
        return sum / #t
    end
}

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

-- State variables (place with your other vars)
local aspect_ratio_active = false
local aspect_ratio_value = 0
local aspect_ratio_default = 0

-- Calculate default aspect ratio
local function calculate_default_aspect()
    local screen_width, screen_height = client.screen_size()
    aspect_ratio_default = screen_width / screen_height
    aspect_ratio_value = aspect_ratio_default
end

-- Handle aspect ratio changes
local function update_aspect_ratio()
    if not aspect_ratio_active then return end
    
    if Menu.Visuals.AspectRatio.on.value then
        local target = Menu.Visuals.AspectRatio.Ratio.value * 0.01
        aspect_ratio_value = MathUtil.lerp(aspect_ratio_value, target, globals.frametime() * 8)
        aspect_ratio_active = math.abs(target - aspect_ratio_value) > 0.001
        client.set_cvar('r_aspectratio', aspect_ratio_value)
    else
        aspect_ratio_value = MathUtil.lerp(aspect_ratio_value, aspect_ratio_default, globals.frametime() * 8)
        client.set_cvar('r_aspectratio', aspect_ratio_value)
        
        if math.abs(aspect_ratio_value - aspect_ratio_default) < 0.001 then
            client.unset_event_callback('paint', update_aspect_ratio)
            client.set_cvar('r_aspectratio', 0)
            aspect_ratio_active = false
        end
    end
end

-- Activate aspect ratio updates
local function activate_aspect_ratio()
    aspect_ratio_active = true
end

-- Initialize aspect ratio system
local function setup_aspect_ratio()
    calculate_default_aspect()
    
    Menu.Visuals.AspectRatio.on:set_callback(function(this)
        aspect_ratio_active = true
        if this:get() then
            client.set_event_callback('paint', update_aspect_ratio)
        end
    end, true)
    
    Menu.Visuals.AspectRatio.Ratio:set_callback(activate_aspect_ratio, true)
    
    -- Reset on startup
    client.delay_call(0, function()
        client.set_cvar('r_aspectratio', 0)
    end)
end

RoundedRect = function(x, y, w, h, r, g, b, a, radius)
    radius = math.min(radius or 5, math.min(w/2, h/2))

    renderer.rectangle(x + radius, y, w - radius * 2, h, r, g, b, a)
    renderer.rectangle(x, y + radius, w, h - radius * 2, r, g, b, a)

    renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
    renderer.circle(x + w - radius, y + radius, r, g, b, a, radius, 90, 0.25)
    renderer.circle(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25)
    renderer.circle(x + radius, y + h - radius, r, g, b, a, radius, 270, 0.25)
end

RoundedRectOutline = function(x, y, w, h, r, g, b, a, radius, thickness)
    radius = math.min(radius or 5, math.min(w/2, h/2))
    thickness = thickness or 1

    renderer.rectangle(x + radius, y, w - radius * 2, thickness, r, g, b, a)

    renderer.rectangle(x + radius, y + h - thickness, w - radius * 2, thickness, r, g, b, a)

    renderer.rectangle(x, y + radius, thickness, h - radius * 2, r, g, b, a)

    renderer.rectangle(x + w - thickness, y + radius, thickness, h - radius * 2, r, g, b, a)

    renderer.circle_outline(x + radius, y + radius, r, g, b, a, radius, 180, 0.25, thickness)
    renderer.circle_outline(x + w - radius, y + radius, r, g, b, a, radius, 90, 0.25, thickness)
    renderer.circle_outline(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25, thickness)
    renderer.circle_outline(x + radius, y + h - radius, r, g, b, a, radius, 270, 0.25, thickness)
end

Glow = function(x, y, w, h, glow_intensity, bg_r, bg_g, bg_b, bg_a, glow_r, glow_g, glow_b, glow_a, draw_background)
    local t = 1
    local u = 1
    
    if draw_background then
        RoundedRect(x, y, w, h, bg_r, bg_g, bg_b, bg_a, 5)
    end

    for l = 0, glow_intensity do
        local glow_alpha = glow_a * (l/glow_intensity)^3
        RoundedRectOutline(
            x + (l - glow_intensity - u) * t, 
            y + (l - glow_intensity - u) * t, 
            w - (l - glow_intensity - u) * t * 2, 
            h - (l - glow_intensity - u) * t * 2, 
            glow_r, glow_g, glow_b, glow_alpha/1.5, 
            5, 
            t + (glow_intensity - l + u)
        )
    end
end

local LocalPlayer = {
    Entity = entity.get_local_player(),
    Valid = false,
    Threat = client.current_threat(),
    Scoped = false,
    Weapon = nil,
    Side = 0,
    Origin = vector(),
    Velocity = -1,
    MoveType = -1,
    Jumping = false,
    InScore = false,
    CommandNumber = 0,
    State = 0,
    LastState = 0,
    ManualYaw = nil, 
    Exploit = '', -- Current exploit state
    OnGround = false,
    Moving = false,
    Crouching = false,
    FakeDucking = nil,
}

LocalPlayer.GetExploitState = function()
    if References.Rage.Other.Duck:get() then
        return 'fd'
    elseif References.Rage.Aimbot.DoubleTap[1]:get() and References.Rage.Aimbot.DoubleTap[2]:get() then
        return 'dt'
    elseif References.AntiAim.Other.OnShot[1]:get() and References.AntiAim.Other.OnShot[2]:get() then
        return 'osaa'
    end
    return ''
end

LocalPlayer.UpdateState = function(cmd)
    LocalPlayer.Entity = entity.get_local_player()
    LocalPlayer.Valid = (LocalPlayer.Entity ~= nil) and entity.is_alive(LocalPlayer.Entity)
    
    if LocalPlayer.Valid then
        local velocity = vector(entity.get_prop(LocalPlayer.Entity, 'm_vecVelocity'))
        LocalPlayer.Velocity = velocity:length2d()
        
        local flags = entity.get_prop(LocalPlayer.Entity, 'm_fFlags')
        LocalPlayer.OnGround = bit.band(flags, 1) ~= 0
        LocalPlayer.Crouching = entity.get_prop(LocalPlayer.Entity, "m_flDuckAmount") > 0.9
        LocalPlayer.Moving = LocalPlayer.Velocity > 5
        
        LocalPlayer.InScore = cmd.in_score == 1
        LocalPlayer.Scoped = entity.get_prop(LocalPlayer.Entity, 'm_bIsScoped') == 1
        LocalPlayer.Weapon = entity.get_player_weapon(LocalPlayer.Entity)
        LocalPlayer.FakeDucking = References.Rage.Other.Duck:get()
        
        LocalPlayer.State = 1 -- Default to Standing

        if LocalPlayer.FakeDucking then
            LocalPlayer.State = 8 -- Fake Ducking
        elseif LocalPlayer.OnGround then
            if LocalPlayer.Crouching then
                if LocalPlayer.Moving then
                    LocalPlayer.State = 5 -- Crouch Moving
                else
                    LocalPlayer.State = 4 -- Crouching
                end
            else
                if LocalPlayer.Moving then
                    if References.AntiAim.Other.SlowWalk:get() and References.AntiAim.Other.SlowWalk.hotkey:get() then
                        LocalPlayer.State = 6 -- Slow Walking
                    else
                        LocalPlayer.State = 2 -- Running
                    end
                else
                    LocalPlayer.State = 1 -- Standing
                end
            end
        else
            if LocalPlayer.Crouching then
                LocalPlayer.State = 7 -- Air Crouching
            else
                LocalPlayer.State = 3 -- In Air / Jumping
            end
        end

        local baseState = LocalPlayer.State

        if LocalPlayer.ManualYaw then 
            LocalPlayer.State = 10 
        elseif References.AntiAim.FakeLag.Enable:get() and not (References.Rage.Aimbot.DoubleTap[1]:get() and References.Rage.Aimbot.DoubleTap[2]:get()) then
            LocalPlayer.State = 9
        end
    end
end

AntiAim = function(cmd)
    if not LocalPlayer.Valid then
        return
    end

    local StateData = AA.States[LocalPlayer.State]
    if StateData and LocalPlayer.State ~= LocalPlayer.LastState then
        LocalPlayer.LastState = LocalPlayer.State
    end

    local SateToConditionMap = {
        [0] = "Default",
        [1] = "Standing",
        [2] = "Running",
        [3] = "In-Air",
        [4] = "Crouching",
        [5] = "Couch Moving",
        [6] = "Slowwalking",
        [7] = "Air Crouching",
        [8] = "Fake Ducking",
        [9] = "Fake Lagging",
        [10] = "Manual Yaw"
    } 

    local CurrentStateID = StateData and StateData[1] or "Default"
    local StateSettings = AA.Presets.Custom[CurrentStateID]

    local OverrideEnabled = false
    if Menu.AntiAim.Builder.States[CurrentStateID] and Menu.AntiAim.Builder.States[CurrentStateID].override then
        OverrideEnabled = Menu.AntiAim.Builder.States[CurrentStateID].override:get()
    end

    local pitchSetting          = StateSettings.Pitch or "Off"
    local yawBaseSetting        = StateSettings.YawBase or "Local View"
    local yawSetting            = StateSettings.Yaw or "Off"
    local yawOffset             = StateSettings.YawOffset or 0
    local yawJitterSetting      = StateSettings.YawJitter or "Off"
    local yawJitterOffset       = StateSettings.YawJitterOffset or 0
    local bodyYawMode           = StateSettings.BodyYaw or "Off"
    local bodyYawOffset         = StateSettings.BodyYawOffset or 0
    local freestandingBodyYaw   = StateSettings.FreestandingBodyYaw or false
    local edgeYaw               = StateSettings.EdgeYaw or false
    local freestanding          = StateSettings.Freestanding or false
    local rollValue             = StateSettings.Roll or 0

    if OverrideEnabled then
        References.AntiAim.Angles.Pitch[1]:set(pitchSetting)
        References.AntiAim.Angles.YawBase:set(yawBaseSetting)
        References.AntiAim.Angles.Yaw[1]:set(yawSetting)
        References.AntiAim.Angles.Yaw[2]:override(yawOffset)
        References.AntiAim.Angles.YawJitter[1]:set(yawJitterSetting)
        References.AntiAim.Angles.YawJitter[2]:override(yawJitterOffset)
        References.AntiAim.Angles.BodyYaw[1]:set(bodyYawMode)
        References.AntiAim.Angles.BodyYaw[2]:set(bodyYawOffset)
        References.AntiAim.Angles.FreestandingBodyYaw:set(freestandingBodyYaw)
        References.AntiAim.Angles.EdgeYaw:set(edgeYaw)
        References.AntiAim.Angles.Freestanding:set(freestanding)
        References.AntiAim.Angles.Roll:set(rollValue)
    end
end

local DiscordAvatarCache = {}

-- Async load + cache
local function requestDiscordAvatar(username)
    if DiscordAvatarCache[username] ~= nil then
        return
    end

    DiscordAvatarCache[username] = false  -- mark as "loading"

    local apiUrl = "https://orionsolutions.shop/API/GetUser.php?username=" .. username

    http.get(apiUrl, {}, function(success, response)
        if not success or response.status ~= 200 then
            DiscordAvatarCache[username] = nil
            return
        end

        local data = json.parse(response.body)
        if data and data.DiscordID and data.DiscordAvatar then
            local avatarUrl = string.format(
                "https://cdn.discordapp.com/avatars/%s/%s.png?size=128",
                data.DiscordID, data.DiscordAvatar
            )

            http.get(avatarUrl, {}, function(s2, resp2)
                if s2 and resp2.status == 200 and resp2.body then
                    local tex = renderer.load_png(resp2.body, 64, 64)
                    if tex then
                        DiscordAvatarCache[username] = tex
                    else
                        DiscordAvatarCache[username] = nil
                    end
                else
                    DiscordAvatarCache[username] = nil
                end
            end)
        else
            DiscordAvatarCache[username] = nil
        end
    end)
end

WaterMark = function()
    if not Menu.Visuals.WaterMark.on.value and not Globals.UserData.LoggedIN then
        return
    end

    local Latency = math.floor(client.latency() * 1000 + 0.5)
    local PingText = 'Ping: ' .. tostring(Latency) .. 'MS'
    local VersionText = Globals.UserData.Version or 'Unknown'
    local FullText = 'Orion Solutions • ' .. Globals.UserData.Username .. ' • ' .. PingText .. ' • ' .. VersionText
    local TextWidth, TextHeight = renderer.measure_text(nil, FullText)
    local Left = Globals.ScreenX - TextWidth - 25

    Glow(Left - 33, 9, TextWidth + 12 + 17, 22, 2, 23, 23, 23, 255, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a, true)
    RoundedRect(Left - 32, 10, TextWidth + 10 + 17, 20, 23, 23, 23, 255, 5)

    Render.Rectangle(Left - 33, 9, TextWidth + 12 + 17, 22, 5, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a)
    Render.Rectangle(Left - 32, 10, TextWidth + 10 + 17, 20, 5, 23, 23, 23, 255)

    local CurrentX = Left - 10
    renderer.text(CurrentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, 'Orion Solutions •')
    CurrentX = CurrentX + renderer.measure_text(nil, 'Orion Solutions •')

    local UserText = ' ' .. Globals.UserData.Username
    renderer.text(CurrentX, 10 + TextHeight/4, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a, nil, 200, UserText)
    CurrentX = CurrentX + renderer.measure_text(nil, UserText)

    renderer.text(CurrentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, ' • ')
    CurrentX = CurrentX + renderer.measure_text(nil, ' • ')

    renderer.text(CurrentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, PingText)
    CurrentX = CurrentX + renderer.measure_text(nil, PingText)

    renderer.text(CurrentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, ' • ')
    CurrentX = CurrentX + renderer.measure_text(nil, ' • ')

    renderer.text(CurrentX, 10 + TextHeight/4, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a, nil, 200, VersionText)

    -- get Discord avatar or fallback
    local avatar = DiscordAvatarCache[Globals.UserData.Username]

    if avatar == nil then
        requestDiscordAvatar(Globals.UserData.Username)
    elseif avatar then
        renderer.texture(avatar, Left - 28, 13, 15, 15, 255, 255, 255, 255, 'f')
    end

    renderer.circle_outline(Left - 20, 20, 23, 23, 23, 255, 10, 0, 1, 3)
end

local function get_current_condition()
    local stateToConditionMap = {
        [1] = "Standing",
        [2] = "Running", 
        [3] = "Jumping",
        [4] = "Crouching", 
        [5] = "Crouch Moving", 
        [6] = "Slowwalking",   
        [7] = "Air Crouching", 
        [8] = "Fake Ducking",  -- NEW
        [9] = "Fake Lagging", 
        [10] = "Manual Yaw", 
        [11] = "Safe Head",
        [12] = "Dormant" 
    }
    
    return stateToConditionMap[LocalPlayer.State] or "STANDING"
end

local SimpleUI = {
    Name = "Orion Solutions",
    Build = Globals.UserData.Version or 'Unknown',
    CurrentCondition = get_current_condition() or "Unknown",
    ImageSize = 32,
    Avatar = nil,
    AvatarLoaded = false,
    PanoramaAPI = panorama.open()
}

SimpleUI.LoadProfilePicture = function()
    local username = Globals.UserData.Username
    if not Globals.UserData.LoggedIN or not Globals.UserData.Username then
        return
    end

    -- Check cache
    if DiscordAvatarCache[Globals.UserData.Username] == nil then
        requestDiscordAvatar(Globals.UserData.Username) -- fire async request (no callback)
        return
    end

    -- If it's already loaded
    if type(DiscordAvatarCache[Globals.UserData.Username]) ~= "boolean" then
        SimpleUI.Avatar = DiscordAvatarCache[Globals.UserData.Username]
    end
end

SimpleUI.Paint = function()
    SimpleUI.LoadProfilePicture()

    local screen_x, screen_y = client.screen_size()
    local position_x, position_y = 5, screen_y / 2

    SimpleUI.Build = Globals.UserData.Version or 'Unknown'

    SimpleUI.CurrentCondition = get_current_condition() or "Unknown"

    local text_lines = {
        string.format('%s', SimpleUI.Name),
        string.format('[%s]', string.upper(SimpleUI.Build)),
        string.format('Condition: %s', SimpleUI.CurrentCondition)  -- Add condition line
    }
    local text = table.concat(text_lines, '\n')

    local text_width, text_height = renderer.measure_text('-', text)

    if SimpleUI.Avatar ~= nil then
        position_y = position_y - SimpleUI.ImageSize / 2

        if type(SimpleUI.Avatar) == 'userdata' and SimpleUI.Avatar.draw then
            SimpleUI.Avatar:draw(
                position_x, position_y,
                SimpleUI.ImageSize, SimpleUI.ImageSize,
                255, 255, 255, 255, 'f'
            )
        else
            renderer.texture(
                SimpleUI.Avatar, position_x, position_y,
                SimpleUI.ImageSize, SimpleUI.ImageSize,
                255, 255, 255, 255, 'f'
            )
        end

        position_x = position_x + SimpleUI.ImageSize + 5
        position_y = position_y + (SimpleUI.ImageSize - text_height) / 2
    else
        position_y = position_y - text_height / 2
    end

    local accent_r, accent_g, accent_b = Menu.Miscellaneous.AccentColor:get()

    renderer.text(
        position_x, position_y,
        accent_r, accent_g, accent_b, 255,
        '-', nil, text
    )
end

Menu.Miscellaneous.AccentColor:set_callback(function(this)
    local r, g, b, a = unpack(this.value)
    colors.accent = color.rgb(r, g, b, a)
    colors.hex = '\a'.. colors.accent:to_hex()
	colors.hexs = string.sub(colors.hex, 1, -3)

    References.Miscellaneous.Settings.MenuColor:set(Menu.Miscellaneous.AccentColor.value)
end, true)

Menu.Miscellaneous.Filter:set_callback(function(self)
    client.delay_call(0, function()
        cvar.con_filter_enable:set_int(self.value and 1 or 0)
        cvar.con_filter_text:set_string(self.value and 'Orion Solutions ['..Globals.UserData.Version ..']' or '')
    end)
end, true)

-- Crosshair Indicator System
local CrosshairIndicator = {
    alpha_values = {},
    y_values = {},
    transparency = 0
}

local function render_crosshair_indicator()
    if not Menu.Visuals.CrosshairIndicator.on.value then return end
    if not LocalPlayer.Valid then return end

    local weapon = entity.get_player_weapon(LocalPlayer.Entity)
    if not weapon then return end
    
    local csgoweapon = weapons(weapon)
    if not csgoweapon then return end

    -- Calculate transparency based on game state
    local game_rules = entity.get_game_rules()
    if game_rules then
        local m_gamePhase = entity.get_prop(game_rules, 'm_gamePhase')
        local NextPhase = entity.get_prop(game_rules, 'm_timeUntilNextPhaseStarts')
        CrosshairIndicator.transparency = MathUtil.lerp(
            CrosshairIndicator.transparency, 
            (csgoweapon.is_grenade or LocalPlayer.InScore or (m_gamePhase == 5) or (NextPhase ~= 0)) and 0.5 or 1, 
            0.03
        )
    end

    -- Define elements and their states
    local elements_data = {
        {"Orion Solutions", true}, -- Always active
        {"Condition", true}, -- Always active, shows current condition
        {"Double Tap", References.Rage.Aimbot.DT.value and References.Rage.Aimbot.DT:get_hotkey()},
        {"Hide Shots", References.AntiAim.Other.OnShot.value and References.AntiAim.Other.OnShot:get_hotkey()},
        {"Min. Damage", References.Rage.Aimbot.DamageOverride.value and References.Rage.Aimbot.DamageOverride:get_hotkey()},
        {"Ping Spike", References.Miscellaneous.PingSpike.value and References.Miscellaneous.PingSpike:get_hotkey()},
        {"Freestanding", References.AntiAim.Angles.Freestanding.value}
    }

    local y_offset = 20
    local flags = '-cd'
    local r, g, b, a = Menu.Visuals.CrosshairIndicator.Color:get()
    a = a * CrosshairIndicator.transparency

    -- Initialize arrays if needed
    for i = 1, #elements_data do
        if not CrosshairIndicator.alpha_values[i] then
            CrosshairIndicator.alpha_values[i] = 0
            CrosshairIndicator.y_values[i] = 0
        end
    end

    -- Render elements
    for i, element_data in ipairs(elements_data) do
        local element_name, element_active = element_data[1], element_data[2]
        
        -- Special handling for Orion Solutions - always enabled in menu
        if element_name == "Orion Solutions" then
            element_enabled = true
        -- Special handling for Condition - always enabled in menu  
        elseif element_name == "Condition" then
            element_enabled = true
        else
            -- Check if this element is enabled in the menu
            element_enabled = false
            for _, enabled_element in ipairs(Menu.Visuals.CrosshairIndicator.Elements.value) do
                if enabled_element == element_name then
                    element_enabled = true
                    break
                end
            end
        end

        if not element_enabled then
            CrosshairIndicator.alpha_values[i] = MathUtil.lerp(CrosshairIndicator.alpha_values[i], 0, 0.03)
            goto continue
        end

        -- Update alpha and y values
        CrosshairIndicator.alpha_values[i] = MathUtil.lerp(
            CrosshairIndicator.alpha_values[i], 
            element_active and CrosshairIndicator.transparency or 0, 
            0.03
        )

        if CrosshairIndicator.alpha_values[i] > 0.01 then
            local text = element_name:upper()
            
            -- Special text for Condition element
            if element_name == "Condition" then
                text = get_current_condition()
            end

            if element_name == "Orion Solutions" then
                text = "Orion Solutions [" .. Globals.UserData.Version .. "]"
            end
            
            local text_width, text_height = renderer.measure_text(flags, text)
            
            CrosshairIndicator.y_values[i] = MathUtil.lerp(
                CrosshairIndicator.y_values[i], 
                element_active and text_height or 0, 
                0.03
            )

            local current_alpha = a * CrosshairIndicator.alpha_values[i]

            renderer.text(Globals.ScreenX / 2, Globals.ScreenY / 2 + y_offset, r, g, b, current_alpha, flags, 0, text)
            y_offset = y_offset + CrosshairIndicator.y_values[i]
        end

        ::continue::
    end
end

SafeSetCvar = function(cvarObj, val)
    if cvarObj and cvarObj.set_int then
        cvarObj:set_int(val)
    end
end

ImprovedPrediction = function()
    if Menu.Rage.ImprovedPrediction:get() then
        SafeSetCvar(cvar.cl_interp_ratio, 0)
        SafeSetCvar(cvar.cl_interp, 0)
        SafeSetCvar(cvar.cl_updaterate, 62)
    else
        SafeSetCvar(cvar.cl_interp_ratio, 1)
        SafeSetCvar(cvar.cl_interp, 0.15)
        SafeSetCvar(cvar.cl_updaterate, 64)
    end
end

local BackTrackCache = {}
local MAX_BACKTRACK_RECORDS = 64
local BACKTRACK_CLEANUP_INTERVAL = 30
local LastCleanupTime = globals.curtime()

ShouldCleanup = function()
    return globals.curtime() - LastCleanupTime >= BACKTRACK_CLEANUP_INTERVAL
end

CleanupBackTrackCache = function()
    local CurrentTime = globals.curtime()
    --if CurrentTime - LastCleanupTime < BACKTRACK_CLEANUP_INTERVAL then
    --    return
    --end

    if not ShouldCleanup() then
        return
    end
    
    LastCleanupTime = CurrentTime

    for player, records in pairs(BackTrackCache) do
        if not entity.is_alive(player) then
            BackTrackCache[player] = nil
        else
            local newest_time = records[#records] or 0
            local cutoff_time = newest_time - 5.0
            
            for i = #records, 1, -1 do
                if records[i] < cutoff_time then
                    table.remove(records, i)
                end
            end

            if #records == 0 then
                BackTrackCache[player] = nil
            end
        end
    end
end

UpdateNetvars = function(cmd)
    LocalPlayer.Entity = entity.get_local_player()
    LocalPlayer.Valid = LocalPlayer.Entity and entity.is_alive(LocalPlayer.Entity)
    LocalPlayer.CommandNumber = cmd.command_number

    if LocalPlayer.Valid then
        local velocity = vector(entity.get_prop(LocalPlayer.Entity, 'm_vecVelocity'))
        LocalPlayer.Velocity = velocity:length2d()
        LocalPlayer.Origin = vector(entity.get_prop(LocalPlayer.Entity, 'm_vecOrigin'))
        LocalPlayer.Scoped = entity.get_prop(LocalPlayer.Entity, 'm_bIsScoped') == 1
        LocalPlayer.Weapon = entity.get_player_weapon(LocalPlayer.Entity)
        LocalPlayer.MoveType = entity.get_prop(LocalPlayer.Entity, 'm_MoveType')
        LocalPlayer.Threat = client.current_threat()
        LocalPlayer.Jumping = cmd.in_jump == 1
        LocalPlayer.InScore = cmd.in_score == 1


        if LocalPlayer.Side == 0 then
            LocalPlayer.Side = (cmd.sidemove > 0) and 1 or (cmd.sidemove < 0) and -1 or 0
        end

        if not LocalPlayer.Scoped then
            LocalPlayer.Side = 0
        end
    end
end

local Shots = Shots or {}
local Logs = Logs or {}
local HitLogs = HitLogs or {}
local CasinoLogs = CasinoLogs or {}
local HitgroupNames = {'Generic', 'Head', 'Chest', 'Stomach', 'Left Arm', 'right Arm', 'Left Leg', 'Right Leg', 'Neck', '?', 'Gear'}

DrawLog2 = function(text, x, y, r, g, b, a, text2)
    local accent_r, accent_g, accent_b = Menu.Miscellaneous.AccentColor:get()

    if text2 == 'Hit' then
        r, g, b = 0, 255, 0
    elseif text2 == 'Miss' then
        r, g, b = 255, 0, 0
    elseif text2 == 'Casino' then
        r, g, b = 255, 215, 0
    else
        r, g, b = accent_r, accent_g, accent_b
    end

    local width, height = renderer.measure_text('b', text)
    height = math.max(20, height + 6)

    local t2w, t2h = renderer.measure_text('b', text2 or '')
    local tag_w = math.max(30, (text2 and text2 ~= '' and (t2w + 14) or 30))
    local total_w = tag_w + width + 35

    Glow(x - 8, y - 4, total_w + 16, height + 8, 3, 23, 23, 23, a, r, g, b, a, true)
    RoundedRect(x - 7, y - 3, total_w + 14, height + 6, 23, 23, 23, 230, 6)

    RoundedRect(x - 7, y - 3, tag_w, height + 6, r, g, b, 255, 6)

    local text_y = y + math.floor((height - renderer.measure_text('b', 'A')) / 2)
    renderer.text(x + tag_w + 10, text_y, 255, 255, 255, 255, 'b', 0, text)

    if text2 and text2 ~= '' then
        local tag_y = y + math.floor((height - t2h) / 2)
        renderer.text(x + 8, tag_y, 23, 23, 23, 255, 'b', 0, text2)
    end

    return total_w, height
end

DrawLog = function(text, x, y, r, g, b, a, text2)
     -- measure main text (right body)
    local width, height = renderer.measure_text('b', text)
    height = math.max(20, height + 6) -- keep min height = 20

    if text2 == 'Hit' then
        r = 0
        g = 255
        b = 0
    elseif text2 == 'Miss' then
        r = 255
        g = 0
        b = 0
    elseif text2 == 'Casino' then
        r = 255
        g = 215
        b = 0
    end

    -- measure tag text (left tag)
    local t2w, t2h = renderer.measure_text('b', text2 or '')


    -- tag width = text2 + 10px (5px padding each side); keep >= 30 for shape integrity
    local tag_w = math.max(30, (text2 and text2 ~= '' and (t2w + 10) or 30))


    local total_w = tag_w + (width + 40)


    renderer.gradient(x + tag_w, y + 2, total_w - 4, height - 4, 15, 15, 15, a / 2, 0, 0, 0, 0, true)
    renderer.rectangle(x, y, tag_w, height, 25, 25, 25, a)
    renderer.triangle(x, y, x, y + height, x - 10, y + height, 25, 25, 25, a)
    renderer.triangle(x + tag_w, y, x + tag_w, y + height, x + tag_w + 10, y, 25, 25, 25, a)
    renderer.gradient(x - 1, y - 2, tag_w + 11, 2, r, g, b, a, r, g, b, a, true)


    -- accent slashes
    renderer.line(x, y - 2, x - 10, y - 2 + height + 1, r, g, b, a)
    renderer.line(x - 1, y - 2, x - 11, y - 2 + height + 1, r, g, b, a)
    renderer.line(x - 2, y - 2, x - 12, y - 2 + height + 1, r, g, b, a)

    renderer.line(x + tag_w + 11, y - 1, x + tag_w + 1, y - 1 + height, 10, 10, 10, a)
    renderer.text(x + tag_w + 15, y + math.floor((height - (height - 6)) / 2), 255, 255, 255, a, 'b', 0, text)


    -- draw text2 INSIDE the tag, centered vertically with 5px left padding
    if text2 and text2 ~= '' then
        local t2_y = y + math.floor((height - t2h) / 2)
        renderer.text(x + 5, t2_y, r, g, b, 255, 'b', 0, text2)
    end


    -- optional icon support (kept from your original, but disabled by default)
    -- local icon_texture = renderer.load_png(logo, 23, 23)
    -- renderer.texture(icon_texture, x + 4, y + math.floor((height - 23) / 2), 23, 23, 255, 255, 255, a, 'f')


    return total_w, height
end

MeasureLog = function(text, text2)
    local width, height = renderer.measure_text('b', text)
    height = math.max(20, height + 6)
    local t2w = renderer.measure_text('b', text2 or '')
    local tag_w = math.max(30, (text2 and text2 ~= '' and (t2w + 14) or 30))
    local total_w = tag_w + width + 35
    return total_w, height
end

RenderScreenLogs = function()
    if not Menu.Miscellaneous.Logs.on.value then
        return
    end

    if table.find(Menu.Miscellaneous.Logs.LogsType.value, 'Screen') then
        local now = globals.curtime()
        local offset = 0
        local logs_to_remove = {}
    
        -- Process combat logs (shots/hits/misses)
        for i = 1, #Logs do
            local id = Logs[i]
            local s = Shots[id]
            if s then
                local elapsed = now - s.TimeFired
            
                s.Alpha = math.floor(255 * (1 - math.min(elapsed / 3, 1)))
            
                if elapsed > 3 then
                    table.insert(logs_to_remove, i)
                else
                    if s.Hit and table.find(Menu.Miscellaneous.Logs.LogsOption.value, 'Hit') then
                        local HitText = 'Hit '.. entity.get_player_name(s.Target) .. ' For '..s.Damage.. ' In The '..HitgroupNames[s.HitGroup + 1]
                        local w, h = MeasureLog(HitText, "")
                        DrawLog(HitText, (Globals.ScreenX / 2) - w/2, (Globals.ScreenY / 2 + offset) + 200, 255, 255, 255, s.Alpha, "Hit")
                        offset = offset + h + 10
                    elseif s.Miss and table.find(Menu.Miscellaneous.Logs.LogsOption.value, 'Miss') then
                        local w, h = DrawLog('Missed '.. entity.get_player_name(s.Target) .. ' Due To '..s.Reason, (Globals.ScreenX / 2), Globals.ScreenY / 2 + offset, 255, 255, 255, 0, '')
                        DrawLog('Missed '.. entity.get_player_name(s.Target) .. ' Due To '..s.Reason, (Globals.ScreenX / 2) - w/2, (Globals.ScreenY / 2 + offset) + 200, 255, 255, 255, s.Alpha, 'Miss')
                        offset = offset + h + 10
                    end
                end
            else
                table.insert(logs_to_remove, i)
            end
        end
    
        if table.find(Menu.Miscellaneous.Logs.LogsOption.value, 'Casino') then
            -- Process casino logs
            for i = 1, #CasinoLogs do
                local casino_log = CasinoLogs[i]
                if casino_log then
                    local elapsed = now - casino_log.TimeCreated
            
                    casino_log.Alpha = math.floor(255 * (1 - math.min(elapsed / 5, 1)))  -- 5 second duration for casino logs
            
                    if elapsed > 5 then
                        table.insert(logs_to_remove, i + #Logs)  -- Offset by combat logs count
                    else
                        local w, h = DrawLog(casino_log.Message, (Globals.ScreenX / 2), Globals.ScreenY / 2 + offset, 255, 255, 255, 0, '')
                        DrawLog(casino_log.Message, (Globals.ScreenX / 2) - w/2, (Globals.ScreenY / 2 + offset) + 200, 255, 255, 255, casino_log.Alpha, 'Casino')
                        offset = offset + h + 10
                    end
                end
            end
        end

        -- Remove expired logs
        for i = #logs_to_remove, 1, -1 do
            if logs_to_remove[i] <= #Logs then
                table.remove(Logs, logs_to_remove[i])
            else
                table.remove(CasinoLogs, logs_to_remove[i] - #Logs)
            end
        end
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
	if dist <= Menu.Miscellaneous.AntiBackStab.Distance.value and entity.get_classname(weapon) == 'CKnife' then
		References.AntiAim.Angles.Yaw[2]:override(180)
	else
		References.AntiAim.Angles.Yaw[2]:override(0)
	end
end

FastLadder = function(cmd)
    if not Menu.Miscellaneous.FastLadder:get() then
        return
    end

    if not LocalPlayer.Valid then
        return
    end

    if entity.get_prop(LocalPlayer.Entity, 'm_MoveType') ~= 9 then return end

    local weapon = entity.get_player_weapon(LocalPlayer.Entity)
    if not weapon then return end

    local throw_time = entity.get_prop(weapon, 'm_fThrowTime')

    if throw_time ~= nil and throw_time ~= 0 then
        return
    end

    if cmd.forwardmove > 0 then
        if cmd.pitch < 45 then
            cmd.pitch = 89
            cmd.in_moveright = 1
            cmd.in_moveleft = 0
            cmd.in_forward = 0
            cmd.in_back = 1
        
            if cmd.sidemove == 0 then
                cmd.yaw = cmd.yaw + 90
            end
        
            if cmd.sidemove < 0 then
                cmd.yaw = cmd.yaw + 150
            end
        
            if cmd.sidemove > 0 then
                cmd.yaw = cmd.yaw + 30
            end
        end
    elseif cmd.forwardmove < 0 then
        cmd.pitch = 89
        cmd.in_moveleft = 1
        cmd.in_moveright = 0
        cmd.in_forward = 1
        cmd.in_back = 0
        
        if cmd.sidemove == 0 then
            cmd.yaw = cmd.yaw + 90
        end
        
        if cmd.sidemove > 0 then
            cmd.yaw = cmd.yaw + 150
        end
        
        if cmd.sidemove < 0 then
            cmd.yaw = cmd.yaw + 30
        end
    end
end

AutoBuy = function()
    for k, v in pairs(Commands) do
        if k == Menu.Miscellaneous.BuyBot.Primary.value then
            client.exec(v)
        end
    end

    for k, v in pairs(Commands) do
        if k == Menu.Miscellaneous.BuyBot.Secondary.value then
            client.exec(v)
        end
    end

    local UtilityPurchase = Menu.Miscellaneous.BuyBot.Utilities.value

    for i = 1, #UtilityPurchase do
        local n = UtilityPurchase[i]

        for k, v in pairs(Commands) do
            if k == n then
                client.exec(v)
            end
        end
    end

    local GrenadePurchase = Menu.Miscellaneous.BuyBot.Grenades.value

    for i = 1, #GrenadePurchase do
        local N = GrenadePurchase[i]
            
        for k, v in pairs(Commands) do
            if k == N then
                client.exec(v)
            end
        end
    end
end

local ClantagFrames = {
    '[✦Orion✦]',
    '[✦Orion]',
    '[✦Orio]',
    '[✦Ori]',
    '[✦Or]',
    '[✦O]',
    '[✦]',
    '[✦O]',
    '[✦Or]',
    '[✦Ori]',
    '[✦Orio]',
    '[✦Orion]',
    '[✦Orion✦]',
}

ClanTag = function(Tag)
    client.set_clan_tag(Tag)
end

MenuUpdate = function()
    if Globals.UserData.LoggedIN then
        References.AntiAim.Angles.Enable:depend({Menu.Tabs, 'yg'})
        References.AntiAim.Angles.Pitch[1]:depend({Menu.Tabs, 'yg'})
        References.AntiAim.Angles.Pitch[2]:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.YawBase:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.Yaw[1]:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.Yaw[2]:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.YawJitter[1]:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.YawJitter[2]:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.BodyYaw[1]:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.BodyYaw[2]:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.EdgeYaw:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.FreestandingBodyYaw:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.Freestanding:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.Freestanding.hotkey:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.Angles.Roll:depend({Menu.Tabs, 'yg'})

        References.AntiAim.Other.SlowWalk:depend({Menu.Tabs, 'Anti-Aim'})
	    References.AntiAim.Other.SlowWalk.hotkey:depend({Menu.Tabs, 'Anti-Aim'})
	    References.AntiAim.Other.Legs:depend({Menu.Tabs, 'Anti-Aim'})
	    References.AntiAim.Other.OnShot:depend({Menu.Tabs, 'Anti-Aim'})
	    References.AntiAim.Other.OnShot.hotkey:depend({Menu.Tabs, 'Anti-Aim'})
	    References.AntiAim.Other.FakePeek:depend({Menu.Tabs, 'Anti-Aim'})
	    References.AntiAim.Other.FakePeek.hotkey:depend({Menu.Tabs, 'Anti-Aim'})

	    References.AntiAim.FakeLag.Enable:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.FakeLag.Enable.hotkey:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.FakeLag.Variance:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.FakeLag.Amount:depend({Menu.Tabs, 'yg'})
	    References.AntiAim.FakeLag.Limit:depend({Menu.Tabs, 'yg'})
    end

    Menu.AntiAim.FakeLag.EnableFakeLag.on:set_callback(function(self)
        References.AntiAim.FakeLag.Enable:set(self:get())
    end, true)

    Menu.AntiAim.FakeLag.EnableFakeLag.Amount:set_callback(function(self)
        if Menu.AntiAim.FakeLag.EnableFakeLag.on:get() then
            pcall(function()
                References.AntiAim.FakeLag.Amount:set(self:get())
            end)
        end
    end, true)

    Menu.AntiAim.FakeLag.EnableFakeLag.Variance:set_callback(function(self)
        if Menu.AntiAim.FakeLag.EnableFakeLag.on:get() then
            References.AntiAim.FakeLag.Variance:set(self:get())
        end
    end, true)

    Menu.AntiAim.FakeLag.EnableFakeLag.Limit:set_callback(function(self)
        if Menu.AntiAim.FakeLag.EnableFakeLag.on:get() then
            References.AntiAim.FakeLag.Limit:set(self:get())
        end
    end, true)

    Menu.AntiAim.FakeLag.EnableFakeLag.Limit:set_callback(function(self)
        References.AntiAim.FakeLag.Limit:set(self:get())
    end, true)
    
    if Globals.UserData.LoggedIN then
        Menu.LOGGEDIN:set(true)
    else
        Menu.LOGGEDIN:set(false)
    end

    Menu.LOGGEDIN:set_visible(false)
    Menu.ISADMIN:set_visible(false)

    pui.traverse({Menu.MainHeader, Menu.Tabs}, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true})
	end)

    pui.traverse(Menu.Home, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Home'})
	end)

    pui.traverse(Menu.Rage, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Rage'})
	end)

    pui.traverse(Menu.AntiAim, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Anti-Aim'})
	end)

    pui.traverse(Menu.AntiAim.Builder, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.AntiAim.AntiAimType, 'Builder'})
	end)

    pui.traverse(Menu.AntiAim.Defensive, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.AntiAim.AntiAimType, 'Defensive'})
	end)

    pui.traverse(Menu.Visuals, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Visuals'})
	end)

    pui.traverse(Menu.Miscellaneous, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Miscellaneous'})
	end)

    pui.traverse(Menu.Casino, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Casino'})
	end)

    Menu.Casino.BetAmount:depend({Menu.LOGGEDIN, true}, {Menu.Casino.Game, 'Coin Flip'})
    Menu.Casino.BetAmountLabel:depend({Menu.LOGGEDIN, true}, {Menu.Casino.Game, 'Coin Flip'})
    Menu.Casino.Flip:depend({Menu.LOGGEDIN, true}, {Menu.Casino.Game, 'Coin Flip'})
end

client.set_event_callback('setup_command', function(cmd)
    if not Globals.UserData.LoggedIN then
        return
    end

    if Menu.Rage.BackTrackExploit.on.value then
        cvar.sv_maxunlag:set_float(Menu.Rage.BackTrackExploit.BackTrackValue.value / 10)

        local Players = entity.get_players(true)
        for i = 1, #Players do
            local Player = Players[i]
            if not BackTrackCache[Player] then
                BackTrackCache[Player] = {}
            end

            local simtime = entity.get_prop(Player, 'm_flSimulationTime')
            if simtime then
                table.insert(BackTrackCache[Player], simtime)

                while #BackTrackCache[Player] > MAX_BACKTRACK_RECORDS do
                    table.remove(BackTrackCache[Player], 1)
                end
            end

            if #BackTrackCache[Player] > 0 then
                entity.set_prop(Player, 'm_flSimulationTime', BackTrackCache[Player][#BackTrackCache[Player]])
            end
        end
        
        CleanupBackTrackCache()
    else
        cvar.sv_maxunlag:set_float(0.2)
    end

    AntiBackStab()
    ImprovedPrediction()
    UpdateNetvars(cmd)
    FastLadder(cmd)
    LocalPlayer.UpdateState(cmd)
    AntiAim(cmd)

    if Menu.Rage.JumpScout:get() then
        local vel_x, vel_y = entity.get_prop(entity.get_local_player(), 'm_vecVelocity')
        local vel = math.sqrt(vel_x^2 + vel_y^2)
        References.Miscellaneous.Movement.AirStrafe:set(not (cmd.in_jump and (vel < 10)) or ui.is_menu_open())
    end
end)

client.set_event_callback('paint_ui', function()
    if not Globals.UserData.LoggedIN then
        return
    end
    References.AntiAim.Angles.Yaw[1]:set_visible(false)
    References.AntiAim.Angles.Yaw[2]:set_visible(false)

    References.AntiAim.Angles.YawJitter[1]:set_visible(false)
    References.AntiAim.Angles.YawJitter[2]:set_visible(false)

    References.AntiAim.Angles.BodyYaw[1]:set_visible(false)
    References.AntiAim.Angles.BodyYaw[2]:set_visible(false)
    References.AntiAim.Angles.FreestandingBodyYaw:set_visible(false)

    if table.find(Menu.Visuals.WaterMark.Mode.value, 'Modern') then
        WaterMark()
    end

    if table.find(Menu.Visuals.WaterMark.Mode.value, 'Simple') then
        SimpleUI.Paint()
    end

    RenderScreenLogs()
end)

local BulletTracerQueue = {}

client.set_event_callback('paint', function()
    if not Globals.UserData.LoggedIN then
        return
    end
    if Menu.Visuals.BulletTracer.on.value then
        for tick, data in pairs(BulletTracerQueue) do
            if globals.curtime() <= data[7] then
                local x1, y1 = renderer.world_to_screen(data[1], data[2], data[3])
                local x2, y2 = renderer.world_to_screen(data[4], data[5], data[6])
                if x1 ~= nil and x2 ~= nil and y1 ~= nil and y2 ~= nil then
                    
                    local r,g,b,a = Menu.Visuals.BulletTracer.Color:get()
                    renderer.line(x1, y1, x2, y2, r,g,b,a)
                end

            end
        end
    end

    if not Menu.Miscellaneous.ClanTag:get() then
        ClanTag('')
        return
    else
        local tick = globals.tickcount()
        local frame_duration = 20 -- Number of ticks per frame ( Lower ticks Faster )
        local frame_index = math.floor((tick / frame_duration) % #ClantagFrames) + 1
        local CurrentTag = ClantagFrames[frame_index]
        ClanTag(CurrentTag)
    end

    render_crosshair_indicator()
end)

local RoundStarted = false
client.set_event_callback('net_update_end', function()
    if not Globals.UserData.LoggedIN then
        return
    end

    if RoundStarted then
        AutoBuy()
        RoundStarted = false
    end
end)

client.set_event_callback('round_prestart', function(e)
    if not Globals.UserData.LoggedIN then
        return
    end

    BulletTracerQueue = {}

    RoundStarted = true
end)

client.set_event_callback('aim_fire', function(e)
    if not Globals.UserData.LoggedIN then
        return
    end

    if Menu.Visuals.BulletTracer.on.value then

        local lx, ly, lz = client.eye_position()
        BulletTracerQueue[globals.tickcount()] = {lx, ly, lz, e.x, e.y, e.z, globals.curtime() + 3}
    end

    if #Logs >= 5 then
        table.remove(Logs, 1)
    end

    Logs[#Logs + 1] = e.id

    Shots[e.id] = {
        Id = e.id,
        Target = e.target,
        TimeFired = globals.curtime(),
        TimeHit = nil,
        TimeMiss = nil,
        Hit = false,
        Miss = false,
        Damage = 0,
        HitGroup = 0,
        Target = '',
        HitChance = 0,
        BT = 0,
        Reason = '',
        Alpha = 255
    }


end)

client.set_event_callback('aim_hit', function(e)
    if not Globals.UserData.LoggedIN then
        return
    end

    local s = Shots[e.id]
    if not s then 
        goto continue
    end
    s.Hit = true
    s.Miss = false
    s.TimeHit = globals.curtime()
    s.Damage = e.damage
    s.HitGroup = e.hitgroup
    s.Target = e.target
    s.HitChance = e.hit_chance
    s.BT = globals.tickcount() - e.tick
    s.LC = e.teleported
    s.Reason = ''

    ::continue::

    if table.find(Menu.Miscellaneous.Logs.LogsOption.value, 'Hit') then
        local Hitgroup = HitgroupNames[s.HitGroup + 1] or 'Unknown'
        local btDisplay = (s.BT and s.BT > 1) and string.format(' (\f<green>%d\f<white> BT)', s.BT) or ''
        Utils.Print(pui.format(string.format('\f<white>[\f<green>Orion Solutions\f<white>] \f<white>Hit ' .. '\f<green>' .. entity.get_player_name(e.target) .. '\f<white> In The ' .. '\f<green>' .. Hitgroup .. '\f<white> For ' .. '\f<green>' .. s.Damage .. '\f<white> Damage' .. btDisplay .. (s.LC and ' ('..'\f<white>LC)' or ''))))
    end
end)

client.set_event_callback('aim_miss', function(e)
    if not Globals.UserData.LoggedIN then
        return
    end

    local s = Shots[e.id]
    if not s then 
        goto continue
    end

    s.Hit = false  -- This should be false for misses
    s.Miss = true  -- This should be true for misses
    s.TimeMiss = globals.curtime()
    s.Damage = e.damage or 0  -- e.damage might be nil in miss events
    s.HitGroup = e.hitgroup or 0
    s.Target = e.target
    s.HitChance = e.hit_chance or 0
    s.BT = globals.tickcount() - e.tick
    s.Reason = e.reason or 'unknown'  -- Miss events usually have a reason

    ::continue::

    if s.Reason == '?' then
        s.Reason = 'Resolver'
    elseif s.Reason == 'spread' then
        s.Reason = 'Spread'
    end

    if table.find(Menu.Miscellaneous.Logs.LogsType.value, 'Console') then
        if table.find(Menu.Miscellaneous.Logs.LogsOption.value, 'Miss') then
            local HitGroup = HitgroupNames[s.HitGroup + 1] or 'Unknown'
            Utils.Print(pui.format(string.format('\f<white>[\f<red>Orion Solutions\f<white>] \f<white>Missed ' .. '\f<red>' .. entity.get_player_name(s.Target) .. '\f<white> In The ' .. '\f<red>' .. HitGroup .. '\f<white> Due To ' .. '\f<red>' .. s.Reason)))
        end
    end
end)

MenuUpdate()
setup_aspect_ratio()
LoadCloudConfigs()

local Config do
    Config = pui.setup(Menu, Builder)

    ------------------------------------------------------------
    --  Fetch Cloud Configs from API
    ------------------------------------------------------------
    local function FetchCloudConfigs()
        if not Globals.UserData or not Globals.UserData.UserID then
            Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] You must be logged in to load cloud configs!'))
            return
        end

        local url = string.format("https://orionsolutions.shop/API/GetConfigs.php?user_id=%s", Globals.UserData.UserID)

        http.get(url, function(success, response)
            if not success or response.status ~= 200 then
                Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Failed to load cloud configs'))
                return
            end

            local ok, data = pcall(function() return json.parse(response.body) end)
            if not ok or not data or not data.success then
                Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Invalid response from API'))
                return
            end

            db.db.configs['Cloud'] = {}

            for _, cfg in pairs(data.configs or {}) do
                table.insert(db.db.configs['Cloud'], { cfg.ConfigName, cfg.ConfigData, cfg.Visibility or 'Private' })
            end

            local list = {}
            for i, cfg in ipairs(db.db.configs['Cloud']) do
                --table.insert(list, pui.format('\f<white>[\v'..i..'\r] ' .. cfg[1]))
                table.insert(list, '['..tostring(i)..'] ' .. cfg[1])
            end

            Menu.Home.ConfigSystem.List:update(list)
            Utils.Print(pui.format('\f<white>[\f<green>Orion Solutions\f<white>] Cloud configs loaded successfully'))
        end)
    end

    ------------------------------------------------------------
    --  Get Config
    ------------------------------------------------------------
    local function GetCloudConfig()
        local index = Menu.Home.ConfigSystem.List.value + 1
        local t = db.db.configs['Cloud'] and db.db.configs['Cloud'][index]
        if not t then return nil, nil end
        return t[1], t[2]
    end

    ------------------------------------------------------------
    --  Save / Upload Config
    ------------------------------------------------------------
    local function SaveCloudConfig(name, cfg, visibility)
        if not Globals.UserData or not Globals.UserData.UserID then
            Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] You must be logged in to save cloud configs!'))
            return
        end

        name = name or Menu.Home.ConfigSystem.Name:get()
        if not name or name == "" then
            Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Please enter a config name'))
            return
        end

        if name == "Default" then
            Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Config Cannot Be Name Default'))
            return
        end

        local payload = {
            user_id = Globals.UserData.UserID,
            config_name = name,
            config_data = base64.encode(json.stringify(Config:save())),
            visibility = visibility or "Private"
        }

        local options = {
            headers = { ["Content-Type"] = "application/json" },
            body = json.stringify(payload)
        }

        http.post("https://orionsolutions.shop/API/SaveConfig.php", options, function(success, response)
            if not success or response.status ~= 200 then
                Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Failed to save config'))
                return
            end

            local ok, res = pcall(function() return json.parse(response.body) end)
            if ok and res.success then
                Utils.Print(pui.format('\f<white>[\f<green>Orion Solutions\f<white>] Config saved: \f<orion>' .. name))
                FetchCloudConfigs()
            else
                Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Save failed - ' .. (res.error or 'Unknown error')))
            end
        end)
    end

    ------------------------------------------------------------
    --  Delete Config
    ------------------------------------------------------------
    local function DeleteCloudConfig()
        local index = Menu.Home.ConfigSystem.List.value + 1
        local cfg = db.db.configs['Cloud'][index]
        if not cfg then
            Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] No config selected'))
            return
        end

        local payload = {
            user_id = Globals.UserData.UserID,
            config_name = cfg[1]
        }

        local options = {
            headers = { ["Content-Type"] = "application/json" },
            body = json.stringify(payload)
        }

        http.post("https://orionsolutions.shop/API/DeleteConfig.php", options, function(success, response)
            if not success or response.status ~= 200 then
                Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Failed to delete config'))
                return
            end

            local ok, res = pcall(function() return json.parse(response.body) end)
            if ok and res.success then
                Utils.Print(pui.format('\f<white>[\f<green>Orion Solutions\f<white>] Deleted cloud config: ' .. cfg[1]))
                FetchCloudConfigs()
            else
                Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Delete failed - ' .. (res.error or 'Unknown error')))
            end
        end)
    end

    ------------------------------------------------------------
    --  Load Config
    ------------------------------------------------------------
    local function LoadCloudConfig()
        local name, encoded = GetCloudConfig()
        if not name or not encoded then
            Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] No cloud config selected to load'))
            return
        end

        local ok, decoded = pcall(json.parse, base64.decode(encoded))
        if not ok or not decoded then
            Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Failed to parse cloud config'))
            return
        end

        Config:load(decoded)
        Utils.Print(pui.format('\f<white>[\f<green>Orion Solutions\f<white>] Loaded cloud config: ' .. name))
    end

    ------------------------------------------------------------
    --  Menu Button Callbacks
    ------------------------------------------------------------
    Menu.Home.ConfigSystem.Create:set_callback(function()
        SaveCloudConfig(Menu.Home.ConfigSystem.Name:get(), nil, "Private")
    end)

    Menu.Home.ConfigSystem.Save:set_callback(function()
        local name, _ = GetCloudConfig()
        if name then
            SaveCloudConfig(name)
        else
            Utils.Print(pui.format('\f<white>[\f<red>Orion Solutions\f<white>] Please select a config to save'))
        end
    end)

    Menu.Home.ConfigSystem.Delete:set_callback(DeleteCloudConfig)
    Menu.Home.ConfigSystem.Load:set_callback(LoadCloudConfig)

    Menu.Home.ConfigSystem.List:set_callback(function(self)
        local index = (self.value or 0) + 1
        local selected = db.configs and db.configs[index] or nil
        if not selected then return end
        Menu.Home.ConfigSystem.Selected:set('Selected - \v' .. selected)
    end, true)


    ------------------------------------------------------------
    --  Initial Cloud Config Fetch
    ------------------------------------------------------------
    if Globals.UserData.LoggedIN then
        FetchCloudConfigs()
    end
end