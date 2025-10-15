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

local FirebaseConfig = {
    apiKey = 'AIzaSyBkx75L5S_QWWdKXPR10xTyjEOpTFIIc3g',
    projectId = 'orion-solutions-68199',
    databaseURL = 'https://orion-solutions-68199-default-rtdb.europe-west1.firebasedatabase.app'
}

FireBaseRequest = function(endpoint, method, data, callback)
    local method_l = string.lower(tostring(method or 'get'))
    local url = FirebaseConfig.databaseURL .. endpoint .. '.json?auth=' .. FirebaseConfig.apiKey

    local options = {
        headers = {
            ['Content-Type'] = 'application/json'
        },
    }

    if method_l == 'get' and data ~= nil then
        if type(data) == 'table' then
            options.params = data
        end
    elseif data ~= nil then
        options.json = data
    end

    local http_fn = http[method_l] or http.request
    local cb = function(success, response)
        if not success then
            callback(false, 'HTTP request failed')
            return
        end

        local status = response.status or 0
        local result

        if response.body and type(response.body) == 'string' then
            local ok, parsed = pcall(json.parse, response.body)
            if ok then
                result = parsed
            else
                result = response.body
            end
        else
            result = response.body or {}
        end

        if status >= 200 and status < 300 then
            callback(true, result)
        else
            callback(false, result and (result.error or result) or response.status_message or 'Unknown error')
        end
    end

    http_fn(url, options, cb)
end

local FireBase = {
    read = function(path, callback)
        FireBaseRequest(path, 'GET', nil, callback)
    end,
    
    write = function(path, data, callback)
        FireBaseRequest(path, 'PUT', data, callback)
    end,
    
    update = function(path, data, callback)
        FireBaseRequest(path, 'PATCH', data, callback)
    end,
    
    delete = function(path, callback)
        FireBaseRequest(path, 'DELETE', nil, callback)
    end
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

local PATHS = {
    Users = '/users',
    Invites = '/invites',
    Settings = '/settings',
    OnlineUsers = '/online_users',
    BannedUsers = '/banned_users'
}

local Globals = {
    UserData = {
        LoggedIN = false,
        Username = nil,
        UserID = nil,
        IsAdmin = false,
        Version = 'Live',
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

local utils do
    utils = {}

    utils.lerp = function(start, end_pos, time, ampl)
        if start == end_pos then return end_pos end
        ampl = ampl or 1/globals.frametime()
        local frametime = globals.frametime() * ampl
        time = time * frametime
        local val = start + (end_pos - start) * time
        if(math.abs(val - end_pos) < 0.25) then return end_pos end
        return val 
    end

    utils.to_hex = function(color, cut)
        return string.format('%02X%02X%02X'.. (cut and '' or '%02X'), color.r, color.g, color.b, color.a or 255)
    end

    utils.to_rgb = function(hex)
        hex = hex:gsub('^#', '')
        return color(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), tonumber(hex:sub(7, 8), 16) or 255)
    end

    utils.printc = function(text)
        local result = {}

        for color, content in text:gmatch('\a([A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])([^%z\a]*)') do
            table.insert(result, {color, content})
        end
        local len = #result
        for i, t in pairs(result) do
            c = utils.to_rgb(t[1])
            client.color_log(c.r, c.g, c.b, t[2], len ~= i and '\0' or '')
        end
    end

    utils.normalize_yaw = function(x)
        return ((x + 180) % 360) - 180
    end
    
    utils.sine_yaw = function(tick, min, max)
        local amplitude = (max - min) / 2
        local center = (max + min) / 2
        return center + amplitude * math.sin(tick * 0.05)
    end
    
    utils.shuffle_table = function(t)
        for i = #t, 2, -1 do
            local j = math.random(i)
            t[i], t[j] = t[j], t[i]
        end
    end

    utils.rectangle = function(x, y, w, h, r, g, b, a, radius)
        radius = math.min(radius, w / 2, h / 2)

        local radius_2 = radius * 2

        renderer.rectangle(x + radius, y, w - radius_2, h, r, g, b, a)
        renderer.rectangle(x, y + radius, radius, h - radius_2, r, g, b, a)
        renderer.rectangle(x + w - radius, y + radius, radius, h - radius_2, r, g, b, a)

        renderer.circle(x + radius, y + radius, r, g, b, a, radius, 180, 0.25)
        renderer.circle(x + radius, y + h - radius, r, g, b, a, radius, 270, 0.25)
        renderer.circle(x + w - radius, y + radius, r, g, b, a, radius, 90, 0.25)
        renderer.circle(x + w - radius, y + h - radius, r, g, b, a, radius, 0, 0.25)
    end

    utils.rectangle_outline = function(x, y, w, h, r, g, b, a)
        renderer.line(x, y, x + w, y, r, g, b, a)  -- Верхняя линия
        renderer.line(x + w, y, x + w, y + h, r, g, b, a)  -- Правая линия
        renderer.line(x + w, y + h, x, y + h, r, g, b, a)  -- Нижняя линия
        renderer.line(x, y + h, x, y, r, g, b, a)  -- Левая линия
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
pui.macros.z = '\affffff'
pui.macros.red = '\aff0000'
pui.macros.green = '\a00ff00'

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

local FakeLagAmount = {
    'Dynamic',
    'Maximum',
    'Fluctuate'
}

local ConfigType = {'Local', 'Cloud'}

local ToolTips = {
    BackTrack = {[2] = 'Default', [7] = 'Maximum'},
    AspectRatios = { {125, '5:4'}, {133, '4:3'}, {150, '3:2'}, {160, '16:10'}, {178, '16:9'}, {200, '2:1'}, }
}

local NILFN = function()end

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

    local DefaultConfig = 'eyJDYXNpbm8iOnsiQmV0QW1vdW50IjoiIiwiR2FtZSI6IkNvaW4gRmxpcCJ9LCJUYWJzIjoiSG9tZSIsIlZpc3VhbHMiOnsiQXNwZWN0UmF0aW8iOnsib24iOnRydWUsIlJhdGlvIjoxMzN9LCJCdWxsZXRUcmFjZXIiOnsiQ29sb3IiOiIjNzY3NkZGRkYiLCJvbiI6dHJ1ZX0sIldhdGVyTWFyayI6dHJ1ZX0sIkxPR0dFRElOIjp0cnVlLCJNaXNjZWxsYW5lb3VzIjp7IkFjY2VudENvbG9yIjoiI0E5OTNGRkZGIiwiQ2xhblRhZyI6dHJ1ZSwiQnV5Qm90Ijp7IkdyZW5hZGVzIjpbIkhFIEdyZW5hZGUiLCJNb2xvdG92IiwiU21va2UiLCJ+Il0sIlV0aWxpdGllcyI6WyJBcm1vciIsIkhlbG1ldCIsIlpldXMiLCJEZWZ1c2VyIiwifiJdLCJTZWNvbmRhcnkiOiJEZWFnbGVcL1Jldm9sdmVyIiwib24iOnRydWUsIlByaW1hcnkiOiJTY291dCJ9LCJBbnRpQmFja1N0YWIiOnsib24iOnRydWUsIkRpc3RhbmNlIjoxNjB9LCJGYXN0TGFkZGVyIjp0cnVlLCJMb2dzIjp7IkxvZ3NUeXBlIjpbIlNjcmVlbiIsIkNvbnNvbGUiLCJ+Il0sIm9uIjp0cnVlLCJMb2dzT3B0aW9uIjpbIkhpdCIsIk1pc3MiLCJDYXNpbm8iLCJDb25maWcgQ2hhbmdlcyAoU29vbikiLCJ+Il19fSwiSVNBRE1JTiI6dHJ1ZSwiQXV0aCI6eyJQYXNzV29yZCI6IioqKioqKioqKioqKioiLCJSZW1lbWJlck1lIjp0cnVlLCJVc2VyTmFtZSI6Ikluc3BleCJ9LCJSYWdlIjp7Ikp1bXBTY291dCI6dHJ1ZSwiUmVzb2x2ZXIiOnsiTW9kZSI6IlNvb24iLCJvbiI6dHJ1ZX0sIkJhY2tUcmFja0V4cGxvaXQiOnsib24iOnRydWUsIkJhY2tUcmFja1ZhbHVlIjo3fSwiSW1wcm92ZWRQcmVkaWN0aW9uIjp0cnVlfX0='

    db.db.configs['Local'][1] = {'Default', DefaultConfig}
    db.db.configs['Cloud'][2] = {'Default Cloud'}
    db.configs = {'Default'}
    db.configs.authors = {'qqwerty', 'debil', 'esoterik', 'dalbaeb'}
end

local ConditionList = {
    'Standing',      -- State 1
    'Running',       -- State 2  
    'Slowwalking',   -- State 6
    'Crouching',     -- State 4
    'Crouch Moving', -- State 5
    'Jumping',       -- State 3
    'Air Crouching', -- State 7 (new)
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
        [1] = {'stand', 'Standing', 'S'},
        [2] = {'run', 'Running', 'R'},
        [3] = {'air', 'In Air', 'A'},
        [4] = {'crouch', 'Crouching', 'C'},
        [5] = {'crouch_move', 'Crouch Moving', 'CM'},
        [6] = {'walk', 'Slow Walking', 'SW'},
        [7] = {'air_crouch', 'Air Crouching', 'AC'},  -- New
        [9] = {'fakelag', 'Fake Lagging', 'FL'},
        [10] = {'manual', 'Manual Yaw', 'M'},
        [11] = {'safehead', 'Safe Head', 'SH'},
        [12] = {'dormant', 'Dormant', 'D'}
    },
    ConditionSystem = {
        Pitch = {
            Standing = "Off", 
            Running = "Off",
            Slowwalking = "Off",
            Crouching = "Off",
            ["Crouch Moving"] = "Off",
            Jumping = "Off", 
            ["Air Crouching"] = "Off",
            ["Fake Lagging"] = "Off",
            ["Manual Yaw"] = "Off",
            ["Safe Head"] = "Off",
            Dormant = "Off"
        },
        Yaw = {
            Standing = "180", 
            Running = "180",
            Slowwalking = "180",
            Crouching = "180",
            ["Crouch Moving"] = "180",
            Jumping = "180", 
            ["Air Crouching"] = "180",
            ["Fake Lagging"] = "180",
            ["Manual Yaw"] = "180",
            ["Safe Head"] = "180",
            Dormant = "180"
        },
        YawOffset = {
            Standing = 0, 
            Running = 0,
            Slowwalking = 0,
            Crouching = 0,
            ["Crouch Moving"] = 0,
            Jumping = 0, 
            ["Air Crouching"] = 0,
            ["Fake Lagging"] = 0,
            ["Manual Yaw"] = 0,
            ["Safe Head"] = 0,
            Dormant = 0
        },
        YawJitter = {
            Standing = "Off", 
            Running = "Off",
            Slowwalking = "Off",
            Crouching = "Off",
            ["Crouch Moving"] = "Off",
            Jumping = "Off", 
            ["Air Crouching"] = "Off",
            ["Fake Lagging"] = "Off",
            ["Manual Yaw"] = "Off",
            ["Safe Head"] = "Off",
            Dormant = "Off"
        },
        YawJitterOffset = {
            Standing = 0, 
            Running = 0,
            Slowwalking = 0,
            Crouching = 0,
            ["Crouch Moving"] = 0,
            Jumping = 0, 
            ["Air Crouching"] = 0,
            ["Fake Lagging"] = 0,
            ["Manual Yaw"] = 0,
            ["Safe Head"] = 0,
            Dormant = 0
        },
        BodyYawMode = {
            Standing = "Off", 
            Running = "Off",
            Slowwalking = "Off",
            Crouching = "Off",
            ["Crouch Moving"] = "Off",
            Jumping = "Off", 
            ["Air Crouching"] = "Off",
            ["Fake Lagging"] = "Off",
            ["Manual Yaw"] = "Off",
            ["Safe Head"] = "Off",
            Dormant = "Off"
        },
        BodyYawOffset = {
            Standing = 0, 
            Running = 0,
            Slowwalking = 0,
            Crouching = 0,
            ["Crouch Moving"] = 0,
            Jumping = 0, 
            ["Air Crouching"] = 0,
            ["Fake Lagging"] = 0,
            ["Manual Yaw"] = 0,
            ["Safe Head"] = 0,
            Dormant = 0
        },
        FreestandingBodyYaw = {
            Standing = false, 
            Running = false,
            Slowwalking = false,
            Crouching = false,
            ["Crouch Moving"] = false,
            Jumping = false, 
            ["Air Crouching"] = false,
            ["Fake Lagging"] = false,
            ["Manual Yaw"] = false,
            ["Safe Head"] = false,
            Dormant = false
        },
        EdgeYaw = {
            Standing = false, 
            Running = false,
            Slowwalking = false,
            Crouching = false,
            ["Crouch Moving"] = false,
            Jumping = false, 
            ["Air Crouching"] = false,
            ["Fake Lagging"] = false,
            ["Manual Yaw"] = false,
            ["Safe Head"] = false,
            Dormant = false
        },
        Freestanding = {
            Standing = false, 
            Running = false,
            Slowwalking = false,
            Crouching = false,
            ["Crouch Moving"] = false,
            Jumping = false, 
            ["Air Crouching"] = false,
            ["Fake Lagging"] = false,
            ["Manual Yaw"] = false,
            ["Safe Head"] = false,
            Dormant = false
        },
        Roll = {
            Standing = 0, 
            Running = 0,
            Slowwalking = 0,
            Crouching = 0,
            ["Crouch Moving"] = 0,
            Jumping = 0, 
            ["Air Crouching"] = 0,
            ["Fake Lagging"] = 0,
            ["Manual Yaw"] = 0,
            ["Safe Head"] = 0,
            Dormant = 0
        },
        Defensive = {
            Enabled = false,
            Force = false,
            Duration = 13,
            Disablers = {"Body Yaw", "Yaw Jitter"},
            Pitch = "None",
            PitchValue = 0,
            Yaw = "None",
            YawValue = 0,
            RemainingTicks = 0,
            MaxTicks = 13
        },
    },
    Presets = {
        Custom = {
            [1] = {},
        },
    },
    
    -- Enhanced conditions system
    Conditions = {
        -- Toggle conditions on/off
        Dormant = false,
        SafeHead = false,
        
        -- Safe Head weapon filters
        SafeHeadWeapons = {
            Knife = false,
            Zeus = false, 
            HeightAdvantage = false
        },
        
        -- Manual AA states
        ManualAA = {
            Active = false,
            Direction = nil, -- 'forward', 'left', 'right'
            LastDirection = nil
        },
        
        -- Exploit states
        Exploit = {
            DoubleTap = false,
            HideShots = false,
            FakeDuck = false
        },
        
        -- Defensive AA
        Defensive = {
            Enabled = false,
            Force = false,
            Flicking = false,
            RemainingTicks = 0,
            MaxTicks = 13
        }
    },
    
    -- Helper functions for condition detection
    Functions = {
        HeightAdvantage = function(localPlayer)
            if not localPlayer then return false end
            local origin = vector(entity.get_origin(localPlayer))
            local threat = client.current_threat()
            if not threat then return false end
            local threat_origin = vector(entity.get_origin(threat))
            local height_to_threat = origin.z - threat_origin.z
            return height_to_threat > 50
        end,
        
        IsFakeLagging = function()
            return References.AntiAim.FakeLag.Enable:get() and 
                   not (References.Rage.Aimbot.DoubleTap[1]:get() and References.Rage.Aimbot.DoubleTap[2]:get())
        end,
        
        GetWeaponType = function(weapon)
            if not weapon then return nil end
            local csgoweapon = csgo_weapons(weapon)
            if not csgoweapon then return nil end
            
            if csgoweapon.is_knife then return 'knife' end
            if csgoweapon.is_taser then return 'zeus' end
            return 'other'
        end,
        
        ShouldUseSafeHead = function(weapon)
            local weaponType = AA.Functions.GetWeaponType(weapon)
            if weaponType == 'knife' and AA.Conditions.SafeHeadWeapons.Knife then
                return true
            elseif weaponType == 'zeus' and AA.Conditions.SafeHeadWeapons.Zeus then
                return true
            end
            return false
        end
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
            GUI.Space(Groups.Other),
            GUI.Header('Users', Groups.Other),
            OnlineUsers = Groups.Other:label('\f<silent>Online: \v0'),
        },

        ConfigSystem = {
            NewConfigHeader = GUI.Header('New Config', Groups.FakeLag),
            Name = Groups.FakeLag:textbox('Name', nil, false),
            Create = Groups.FakeLag:button('Create & Save'),
            Import = Groups.FakeLag:button('Import & Load'),

            GUI.Space(Groups.Other),
            GUI.Header('Config Type', Groups.Other),
            Type = Groups.Other:combobox('\n', ConfigType, nil, false),

            GUI.Header('Your Configs', Groups.Angles),
		    List = Groups.Angles:listbox('Configs', db.configs, nil, false),
		    Selected = Groups.Angles:label('Selected: \vDefault'),
		    Load = Groups.Angles:button('Load'),
		    Save = Groups.Angles:button('Save'),
		    Export = Groups.Angles:button('Export'),
		    Delete = Groups.Angles:button('\aFF0000FFDelete'),

            Upload = Groups.FakeLag:button('\v Upload To Cloud')
        },
    },

    Rage = {
        GUI.Header('Rage', Groups.Angles),

        Resolver = GUI.Feature({Groups.Angles:checkbox('Resolver')}, function (Parent)
		    return {
                Mode = Groups.Angles:combobox('Resolver Mode', ResolverModes),
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

        ConditionSettings = {
            Builder = {
                GUI.Header('Condition Settings', Groups.Angles),

                SelectedCondition = Groups.Angles:combobox('Configure Condition', ConditionList),
    
                Pitch = Groups.Angles:combobox('Pitch', {'Off', 'Default', 'Up', 'Down', 'Zero', 'Custom'}),
                YawBase = Groups.Angles:combobox('Yaw Base', {'Local View', 'At Targets'}),
                Yaw = Groups.Angles:combobox('Yaw', {'Off', '180', 'Spin', 'Static', '180 Z', 'Crosshair'}),
                YawOffset = Groups.Angles:slider('Yaw Offset', -180, 180, 0),
                YawJitter = Groups.Angles:combobox('Yaw Jitter', {'Off', 'Offset', 'Center', 'Random', 'Skitter'}),
                YawJitterOffset = Groups.Angles:slider('Yaw Jitter Offset', -180, 180, 0),
                BodyYaw = Groups.Angles:combobox('Body Yaw', {"Off", 'Opposite', 'Jitter', 'Static'}),
                BodyYawOffset = Groups.Angles:slider("Body Yaw Offset", -180, 180, 0),
                FreestandingBodyYaw = Groups.Angles:checkbox('Freestanding Body Yaw'),
                EdgeYaw = Groups.Angles:checkbox('Edge Yaw'),
                Freestanding = Groups.Angles:checkbox('Freestanding'),
                Roll = Groups.Angles:slider("Roll", -45, 45, 0),
            },

            Defensive = {
                -- Defensive AA Settings
                GUI.Header('Defensive AA', Groups.Angles),
                DefensiveEnabled = Groups.Angles:checkbox('Defensive AA'),
                DefensiveForce = Groups.Angles:checkbox('Force Defensive'),
                DefensiveDuration = Groups.Angles:slider('Defensive Duration', 1, 13, 13, true, 'ticks'),
			    DefensiveDisablers = Groups.Angles:multiselect('Defensive Disablers', {"Body Yaw", "Yaw Jitter"}),
                DefensivePitch = Groups.Angles:combobox('Defensive Pitch', {'None', 'Random', 'Up', 'Down', 'Custom'}),
                DefensivePitchValue = Groups.Angles:slider('Defensive Pitch Value', -89, 89, 0, true, '°'),
                DefensiveYaw = Groups.Angles:combobox('Defensive Yaw', {'None', 'Sideways', 'Random', 'Opposite', 'Custom'}),
                DefensiveYawValue = Groups.Angles:slider('Defensive Yaw Value', -180, 180, 0, true, '°'),

            },
        }
    },

    Visuals = {
        GUI.Header('Visuals', Groups.Angles),

        WaterMark = Groups.Angles:checkbox('WaterMark', true, true),
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

    Auth = {
        UserNameLabel = Groups.Angles:label('UserName'),
        UserName = Groups.Angles:textbox('UserName'),
        PassWordLabel = Groups.Angles:label('PassWord'),
        PassWord = Groups.Angles:textbox('PassWord'),
        Login = Groups.Angles:button('Login'),
        RememberMe = Groups.Angles:checkbox('Remember Me'),

        StatusLabel = Groups.Angles:label(' '),
    },

    LOGGEDIN = Groups.Angles:checkbox('LOGGED IN'),
    ISADMIN = Groups.Angles:checkbox('IS ADMIN'),
}

client.exec('Clear')
client.exec('con_filter_enable 0')
client.exec('con_filter_text \'[gamesense] / [Orion Solutions]\'')

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

VectorUtil = {
    length = function(vec)
        return math.sqrt(vec.x*vec.x + vec.y*vec.y + vec.z*vec.z)
    end,
    
    length2d = function(vec)
        return math.sqrt(vec.x*vec.x + vec.y*vec.y)
    end,
    
    get_velocity = function(Player)
        local vx = entity.get_prop(Player, 'm_vecVelocity[0]') or 0
        local vy = entity.get_prop(Player, 'm_vecVelocity[1]') or 0
        local vz = entity.get_prop(Player, 'm_vecVelocity[2]') or 0
        return {x = vx, y = vy, z = vz}
    end,
    
    get_origin = function(Player)
        local x = entity.get_prop(Player, 'm_vecOrigin[0]') or 0
        local y = entity.get_prop(Player, 'm_vecOrigin[1]') or 0
        local z = entity.get_prop(Player, 'm_vecOrigin[2]') or 0
        return {x = x, y = y, z = z}
    end,
    
    predict_position = function(Player, time_delta)
        local origin = VectorUtil.get_origin(Player)
        local velocity = VectorUtil.get_velocity(Player)
        
        return {
            x = origin.x + velocity.x * time_delta,
            y = origin.y + velocity.y * time_delta,
            z = origin.z + velocity.z * time_delta
        }
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

-- Firebase Storage Configuration
local FIREBASE_LOGO_URL = 'https://firebasestorage.googleapis.com/v0/b/orion-solutions-68199.firebasestorage.app/o/logo.png?alt=media&token=67b51834-a77d-423c-8502-bea77a714cec'

-- Global logo variables
local logo = nil
local logo_texture = nil
local logo_loaded = false

local UserPfpCache = {}

local function downloadFirebaseStorageFile(storagePathOrUrl, callback)
    local url
    if storagePathOrUrl:find('^https://') then
        -- full URL (logo, special cases)
        url = storagePathOrUrl
    else
        -- Firebase Storage path (pfps, etc.)
        url = 'https://firebasestorage.googleapis.com/v0/b/orion-solutions-68199.firebasestorage.app/o/'
            .. storagePathOrUrl .. '?alt=media'
    end

    http.get(url, {}, function(success, response)
        if success and response.status == 200 and response.body then
            callback(true, response.body)
        else
            callback(false, nil)
        end
    end)
end

-- Load logo with caching and fallbacks
local function loadLogo()
    -- 1. Try local cache first
    pcall(function()
        logo = readfile('orion_logo.png')
        if logo then
            logo_loaded = true
            return
        end
    end)

    -- 2. If no cache, download from Firebase Storage
    if not logo then
        downloadFirebaseStorageFile(FIREBASE_LOGO_URL, function(success, data)
            if success then
                logo = data
                logo_loaded = true

                -- save to cache
                pcall(function()
                    writefile('orion_logo.png', data)
                end)
            else
                logo_loaded = false
            end
        end)
    end
end

loadLogo()

local function loadUserPfp(username, steamid, pathOrUrl, callback)
    if UserPfpCache[username] then
        callback(UserPfpCache[username])
        return
    end

    if not pathOrUrl or pathOrUrl == '' then
        callback(nil)
        return
    end

    downloadFirebaseStorageFile(pathOrUrl, function(success, data)
        if success then
            local tex = renderer.load_png(data, 64, 64) 
            if tex then
                UserPfpCache[username] = tex
                callback(tex)
                return
            end
        end
        callback(nil)
    end)
end

local function getUserProfileImage(username, steamid, callback)
    if UserPfpCache[username] then
        callback(UserPfpCache[username])
        return
    end

    FireBase.read(PATHS.Users .. '/' .. username, function(success, userData)
        if success and userData then
            local imgUrl = userData.profileImageStatic or userData.profileImage
            if imgUrl and imgUrl ~= '' then
                loadUserPfp(username, steamid, imgUrl, callback)
                return
            end
        end
        callback(nil) 
    end)
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
    Flicking = false, -- For defensive flick
    Exploit = '', -- Current exploit state
    OnGround = false,
    Moving = false,
    Crouching = false
}

LocalPlayerState = function(cmd)
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
        
        LocalPlayer.State = 1 -- Default to Standing

        if LocalPlayer.OnGround then
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
                LocalPlayer.State = 5 -- Air Crouching
            else
                LocalPlayer.State = 3 -- In Air / Jumping
            end
        end

        local baseState = LocalPlayer.State

        if LocalPlayer.ManualYaw then 
            LocalPlayer.State = 10 
        elseif AA.Conditions.Dormant and #entity.get_players(true) == 0 then
            LocalPlayer.State = 12 
        elseif References.AntiAim.FakeLag.Enable:get() and not (References.Rage.Aimbot.DoubleTap[1]:get() and References.Rage.Aimbot.DoubleTap[2]:get()) then
            LocalPlayer.State = 9
        end

        if AA.Conditions.SafeHead then
            local csgoweapon = csgo_weapons(LocalPlayer.Weapon)
            if csgoweapon then
                local height_advantage = AA.Functions.HeightAdvantage(LocalPlayer.Entity)
                if (csgoweapon.is_knife and AA.Conditions.SafeHeadWeapons.Knife) or
                   (csgoweapon.is_taser and AA.Conditions.SafeHeadWeapons.Zeus) or
                   (AA.Conditions.SafeHeadWeapons.HeightAdvantage and height_advantage) then
                    LocalPlayer.State = 11
                end
            end
        end
    end
end

AntiAim = function(cmd)
    if not LocalPlayer.Valid then return end

    References.AntiAim.Angles.Yaw[2]:set_visible(false)
    References.AntiAim.Angles.Yaw[2]:set_enabled(false)
    
    local stateData = AA.States[LocalPlayer.State]
    if stateData and LocalPlayer.State ~= LocalPlayer.LastState then
        print("AA State: " .. stateData[2])
        LocalPlayer.LastState = LocalPlayer.State
    end

    local stateToConditionMap = {
        [1] = "Standing",
        [2] = "Running", 
        [3] = "Jumping",
        [4] = "Crouching", 
        [5] = "Crouch Moving", 
        [6] = "Slowwalking",   
        [7] = "Air Crouching", 
        [9] = "Fake Lagging", 
        [10] = "Manual Yaw", 
        [11] = "Safe Head",
        [12] = "Dormant" 
    }

    local currentCondition = stateToConditionMap[LocalPlayer.State] or "Standing"
    local pitchSetting = AA.ConditionSystem.Pitch[currentCondition] or "Off"
    local yawOffset = AA.ConditionSystem.YawOffset[currentCondition] or 0
    local yawSetting = AA.ConditionSystem.Yaw[currentCondition] or "180"
    local yawJitterSetting = AA.ConditionSystem.YawJitter[currentCondition] or "Off"
    local bodyYawMode = AA.ConditionSystem.BodyYawMode[currentCondition] or "Off"
    local bodyYawOffset = AA.ConditionSystem.BodyYawOffset[currentCondition] or 0
    local freestandingBodyYaw = AA.ConditionSystem.FreestandingBodyYaw[currentCondition] or false
    local edgeYaw = AA.ConditionSystem.EdgeYaw[currentCondition] or false
    local freestanding = AA.ConditionSystem.Freestanding[currentCondition] or false
    local rollValue = AA.ConditionSystem.Roll[currentCondition] or 0

    References.AntiAim.Angles.Pitch[1]:set(pitchSetting)

    References.AntiAim.Angles.Yaw[1]:set(yawSetting)

    References.AntiAim.Angles.YawJitter[1]:set(yawJitterSetting)

    References.AntiAim.Angles.BodyYaw[1]:set(bodyYawMode)

    References.AntiAim.Angles.BodyYaw[2]:set(bodyYawOffset)

    References.AntiAim.Angles.FreestandingBodyYaw:set(freestandingBodyYaw)

    References.AntiAim.Angles.EdgeYaw:set(edgeYaw)

    References.AntiAim.Angles.Freestanding:set(freestanding)

    References.AntiAim.Angles.Roll:set(rollValue)

    References.AntiAim.Angles.Yaw[2]:override(yawOffset)

    local yawBaseSetting = Menu.AntiAim.ConditionSettings.Builder.YawBase:get()
    References.AntiAim.Angles.YawBase:set(yawBaseSetting)

    if globals.tickcount() % 64 == 0 then
        print(string.format("State: %d | Condition: %s | Pitch: %s | Yaw: %s | Yaw Jitter: %s | Body Yaw: %s | Body Yaw Offset: %d | FS Body Yaw: %s | Edge Yaw: %s | Freestanding: %s | Roll: %d | Yaw Offset: %d | Yaw Base: %s", 
            LocalPlayer.State, currentCondition, pitchSetting, yawSetting, yawJitterSetting, bodyYawMode, bodyYawOffset, 
            freestandingBodyYaw and "ON" or "OFF", edgeYaw and "ON" or "OFF", freestanding and "ON" or "OFF", 
            rollValue, yawOffset, yawBaseSetting))
    end
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


notification.OnLoad = function()
    local self = notification

    self.alpha = MathUtil.lerp(self.alpha, self.check and 0 or 1, globals.frametime() * 6)
    self.menu_alpha = MathUtil.lerp(self.menu_alpha, ui.is_menu_open() and 1 or 0, globals.frametime() * 6)
    self.text_alpha = MathUtil.lerp(self.text_alpha, self.check2 and 1 or 0, globals.frametime() * 6)

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
        

    
        local icon_texture = renderer.load_png(logo, 23,23)
        renderer.texture(icon_texture, x + 4, y - 1, 23, 23, 255, 255, 255, a, 'f')
    end

    local menu_x, menu_y = ui.menu_position()
    local r, g, b, a = 255, 255, 255, 255 
	local accent_r, accent_g, accent_b = Menu.Miscellaneous.AccentColor:get()

    draw_notification_bar(menu_x + 12, menu_y - 25, 250 * self.menu_alpha, 20, accent_r, accent_g, accent_b, 255 * self.menu_alpha)

    local gradient_text = 'O R I O N  S O L U T I O N S' 

    renderer.text(menu_x + 12 + 40 + 1, menu_y - 22 - 1, 0, 0, 0, 255 * self.menu_alpha, nil, nil, 'O R I O N  S O L U T I O N S')
    renderer.text(menu_x + 12 + 40 - 1, menu_y - 22 + 1, 0, 0, 0, 255 * self.menu_alpha, nil, nil, 'O R I O N  S O L U T I O N S')
    renderer.text(menu_x + 12 + 40 - 1, menu_y - 22 - 1, 0, 0, 0, 255 * self.menu_alpha, nil, nil, 'O R I O N  S O L U T I O N S')
    renderer.text(menu_x + 12 + 40 + 2, menu_y - 22 + 2, 0, 0, 0, 255 * self.menu_alpha, nil, nil, 'O R I O N  S O L U T I O N S')
    renderer.text(menu_x + 12 + 40 + 1, menu_y - 22 + 1, 255, 255, 255, 255 * self.menu_alpha, nil, nil, gradient_text)
    renderer.text(menu_x + 12 + 40, menu_y - 22, 255, 255, 255, 255 * self.menu_alpha, nil, nil, 'O R I O N  S O L U T I O N S')

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

WaterMark = function()
    if not Menu.Visuals.WaterMark:get() then
        return
    end

    local Latency = math.floor(client.latency() * 1000 + 0.5)
    local pingText = 'Ping: ' .. tostring(Latency) .. 'MS'
    local versionText = Globals.UserData.Version or 'Unknown'
    local fullText = 'Orion Solutions • ' .. Globals.UserData.Username .. ' • ' .. pingText .. ' • ' .. versionText
    local TextWidth, TextHeight = renderer.measure_text(nil, fullText)
    local Left = Globals.ScreenX - TextWidth - 25

    -- background + glow
    Glow(Left - 33, 9, TextWidth + 12 + 17, 22, 2, 23, 23, 23, 255, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a, true)
    RoundedRect(Left - 32, 10, TextWidth + 10 + 17, 20, 23, 23, 23, 255, 5)

    Render.Rectangle(Left - 33, 9, TextWidth + 12 + 17, 22, 5, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a)
    Render.Rectangle(Left - 32, 10, TextWidth + 10 + 17, 20, 5, 23, 23, 23, 255)

    -- draw watermark text
    local currentX = Left - 10
    renderer.text(currentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, 'Orion Solutions •')
    currentX = currentX + renderer.measure_text(nil, 'Orion Solutions •')

    local userText = ' ' .. Globals.UserData.Username
    renderer.text(currentX, 10 + TextHeight/4, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a, nil, 200, userText)
    currentX = currentX + renderer.measure_text(nil, userText)

    renderer.text(currentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, ' • ')
    currentX = currentX + renderer.measure_text(nil, ' • ')

    renderer.text(currentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, pingText)
    currentX = currentX + renderer.measure_text(nil, pingText)

    renderer.text(currentX, 10 + TextHeight/4, 255, 255, 255, 255, nil, 200, ' • ')
    currentX = currentX + renderer.measure_text(nil, ' • ')

    renderer.text(currentX, 10 + TextHeight/4, colors.accent.r, colors.accent.g, colors.accent.b, colors.accent.a, nil, 200, versionText)

    -- draw profile picture
    local SteamID3 = panorama.open().MyPersonaAPI.GetXuid()
    getUserProfileImage(Globals.UserData.Username, SteamID3, function(tex)
        if not tex then
            -- fallback: steam avatar (square)
            local fallback = images.get_steam_avatar(SteamID3)
            fallback:draw(Left - 28, 13, 15, 15)
            renderer.circle_outline(Left - 20, 20, 23, 23, 23, 255, 10, 0, 1, 3)
            return
        end

        -- circular PFP render
        renderer.texture(tex, Left - 28, 13, 15, 15, 255, 255, 255, 255, 'f')
        renderer.circle_outline(Left - 20, 20, 23, 23, 23, 255, 10, 0, 1, 3)
    end)
end

local Shots = Shots or {}
local Logs = Logs or {}
local HitLogs = HitLogs or {}
local CasinoLogs = CasinoLogs or {}
local HitgroupNames = {'Generic', 'Head', 'Chest', 'Stomach', 'Left Arm', 'right Arm', 'Left Leg', 'Right Leg', 'Neck', '?', 'Gear'}

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
                        local w, h = DrawLog(HitText, (Globals.ScreenX / 2), Globals.ScreenY / 2 + offset, 255, 255, 255, 0, '')
                        DrawLog(HitText, (Globals.ScreenX / 2) - w/2, (Globals.ScreenY / 2 + offset) + 200, 255, 255, 255, s.Alpha, 'Hit')
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
        Menu.Auth.StatusLabel:override('Status: Loading...')
        Menu.LOGGEDIN:set(true)
    else
        Menu.Auth.StatusLabel:override('Status: Not Logged In')
        Menu.LOGGEDIN:set(false)
    end

    Menu.LOGGEDIN:set_visible(false)
    Menu.ISADMIN:set_visible(false)

    if not Globals.UserData.IsAdmin then
        Menu.ISADMIN:set(false)
    else
        Menu.ISADMIN:set(true)
    end

    Menu.Tabs:depend({Menu.LOGGEDIN, true})

    pui.traverse(Menu.Auth, function(ref, path)
		ref:depend({Menu.LOGGEDIN, false})
	end)

    pui.traverse(Menu.Home, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Home'})
	end)

    pui.traverse({Menu.Home.ConfigSystem.NewConfigHeader, Menu.Home.ConfigSystem.Name, Menu.Home.ConfigSystem.Create, Menu.Home.ConfigSystem.Import, Menu.Home.ConfigSystem.Export, Menu.Home.ConfigSystem.Upload}, function(ref, path)
        ref:depend({Menu.LOGGEDIN, true}, {Menu.Home.ConfigSystem.Type, 'Local'})
    end)

    pui.traverse(Menu.MainHeader, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true})
	end)

    pui.traverse(Menu.Rage, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Rage'})
	end)

    pui.traverse(Menu.AntiAim, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.Tabs, 'Anti-Aim'})
	end)

    pui.traverse(Menu.AntiAim.ConditionSettings.Builder, function(ref, path)
		ref:depend({Menu.LOGGEDIN, true}, {Menu.AntiAim.AntiAimType, 'Builder'})
	end)

    pui.traverse(Menu.AntiAim.ConditionSettings.Defensive, function(ref, path)
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

    Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:set_callback(function(self)
        local selectedCondition = self:get()
        Menu.AntiAim.ConditionSettings.Builder.Pitch:set(AA.ConditionSystem.Pitch[selectedCondition] or "Off")
        Menu.AntiAim.ConditionSettings.Builder.Yaw:set(AA.ConditionSystem.Yaw[selectedCondition] or "180")
        Menu.AntiAim.ConditionSettings.Builder.YawOffset:set(AA.ConditionSystem.YawOffset[selectedCondition] or 0)
        Menu.AntiAim.ConditionSettings.Builder.YawJitter:set(AA.ConditionSystem.YawJitter[selectedCondition] or "Off")
        Menu.AntiAim.ConditionSettings.Builder.YawJitterOffset:set(AA.ConditionSystem.YawJitterOffset[selectedCondition] or 0)
        Menu.AntiAim.ConditionSettings.Builder.BodyYaw:set(AA.ConditionSystem.BodyYawMode[selectedCondition] or "Off")
        Menu.AntiAim.ConditionSettings.Builder.BodyYawOffset:set(AA.ConditionSystem.BodyYawOffset[selectedCondition] or 0)
        Menu.AntiAim.ConditionSettings.Builder.FreestandingBodyYaw:set(AA.ConditionSystem.FreestandingBodyYaw[selectedCondition] or false)
        Menu.AntiAim.ConditionSettings.Builder.EdgeYaw:set(AA.ConditionSystem.EdgeYaw[selectedCondition] or false)
        Menu.AntiAim.ConditionSettings.Builder.Freestanding:set(AA.ConditionSystem.Freestanding[selectedCondition] or false)
        Menu.AntiAim.ConditionSettings.Builder.Roll:set(AA.ConditionSystem.Roll[selectedCondition] or 0)
    end)

    Menu.AntiAim.ConditionSettings.Builder.Pitch:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.Pitch[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.Yaw:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.Yaw[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.YawOffset:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.YawOffset[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.YawJitter:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.YawJitter[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.YawJitterOffset:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.YawJitterOffset[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.BodyYaw:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.BodyYawMode[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.BodyYawOffset:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.BodyYawOffset[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.FreestandingBodyYaw:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.FreestandingBodyYaw[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.EdgeYaw:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.EdgeYaw[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.Freestanding:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.Freestanding[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Builder.Roll:set_callback(function(self)
        local selectedCondition = Menu.AntiAim.ConditionSettings.Builder.SelectedCondition:get()
        AA.ConditionSystem.Roll[selectedCondition] = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Defensive.DefensiveEnabled:set_callback(function(self)
        AA.ConditionSystem.Defensive.Enabled = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Defensive.DefensiveForce:set_callback(function(self)
        AA.ConditionSystem.Defensive.Force = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Defensive.DefensiveDuration:set_callback(function(self)
        AA.ConditionSystem.Defensive.Duration = self:get()
        AA.ConditionSystem.Defensive.MaxTicks = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Defensive.DefensiveDisablers:set_callback(function(self)
        AA.ConditionSystem.Defensive.Disablers = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Defensive.DefensivePitch:set_callback(function(self)
        AA.ConditionSystem.Defensive.Pitch = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Defensive.DefensivePitchValue:set_callback(function(self)
        AA.ConditionSystem.Defensive.PitchValue = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Defensive.DefensiveYaw:set_callback(function(self)
        AA.ConditionSystem.Defensive.Yaw = self:get()
    end)

    Menu.AntiAim.ConditionSettings.Defensive.DefensiveYawValue:set_callback(function(self)
        AA.ConditionSystem.Defensive.YawValue = self:get()
    end)
end

client.set_event_callback('paint_ui', function()
    References.AntiAim.Angles.Yaw[1]:set_visible(false)
    References.AntiAim.Angles.Yaw[2]:set_visible(false)

    References.AntiAim.Angles.YawJitter[1]:set_visible(false)
    References.AntiAim.Angles.YawJitter[2]:set_visible(false)

    References.AntiAim.Angles.BodyYaw[1]:set_visible(false)
    References.AntiAim.Angles.BodyYaw[2]:set_visible(false)
    References.AntiAim.Angles.FreestandingBodyYaw:set_visible(false)
end)

MenuUpdate()
setup_aspect_ratio()

GetNextUserID = function(callback)
    FireBase.read(PATHS.Settings .. '/last_user_id', function(success, id)
        if success and id then
            last_user_id = tonumber(id) or 1
        else
            last_user_id = 1
        end
        last_user_id = last_user_id + 1
        FireBase.write(PATHS.Settings .. '/last_user_id', last_user_id, function()
            callback(last_user_id)
        end)
    end)
end

SaveCredentials = function(username, password)
    local credentials = {
        username = username,
        password = password,
        timestamp = Time.UnixTime()
    }
    database.write('orion_credentials', json.stringify(credentials))
end

-- Add this function to load credentials
LoadCredentials = function()
    local saved = database.read('orion_credentials')
    if saved then
        local ok, credentials = pcall(json.parse, saved)
        if ok and credentials and credentials.username and credentials.password then
            return credentials.username, credentials.password
        end
    end
    return nil, nil
end

local real_password = ''
local last_password_len = 0

client.set_event_callback('paint_ui', function()
    if not Globals.UserData.LoggedIN then
        local current_input = Menu.Auth.PassWord:get()
        local current_len = #current_input
        
        -- Only process if length changed
        if current_len ~= last_password_len then
            if current_len > last_password_len then
                -- Added characters
                local new_chars = current_input:sub(last_password_len + 1)
                real_password = real_password .. new_chars
                Menu.Auth.PassWord:set(string.rep('*', #real_password))
            else
                -- Removed characters (backspace/delete)
                real_password = real_password:sub(1, current_len)
            end
            last_password_len = current_len
        end
    end
end)

local function updateOnlineStatus()
    if not Globals.UserData.LoggedIN or not Globals.UserData.UserID then
        return
    end
    
    local userid_str = tostring(Globals.UserData.UserID)
    local online_data = {
        [userid_str] = {
            username = Globals.UserData.Username,
            last_active = Time.UnixTime(),  -- Use Unix timestamp for calculations
            login_time = Time.RealTime(),    -- Formatted time for display
            is_admin = Globals.UserData.IsAdmin,
            version = Globals.UserData.Version or 'Live',
            steamid = Globals.UserData.SteamID,
            userid = Globals.UserData.UserID,
            profileImage = Globals.UserData.ProfileImage or ''  -- Add profile image if available
        }
    }
    
    FireBase.update(PATHS.OnlineUsers, online_data, function(success, error)
        if not success then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Firebase\f<z>] Failed to update online status')))
        end
    end)
end

-- Function to get online users count using last_active
local function getOnlineUsersCount(callback)
    FireBase.read(PATHS.OnlineUsers, function(success, users)
        if not success or not users or users == json.null then
            callback(0)
            return
        end
        
        local count = 0
        local current_time = Time.UnixTime()
        
        -- Check each user and count active ones (within last 2 minutes)
        for user_id, user_data in pairs(users) do
            if user_data and type(user_data) == 'table' and user_data.last_active then
                local time_diff = current_time - user_data.last_active
                if time_diff <= 120 then  -- 2 minutes = active
                    count = count + 1
                end
            end
        end
        
        callback(count)
    end)
end

Login = function(username, password, remember)
    -- Check if this is an auto-login attempt
    local is_auto_login = false
    local saved = database.read('orion_credentials')
    if saved then
        local ok, credentials = pcall(json.parse, saved)
        if ok and credentials and credentials.username == username and credentials.password == password then
            is_auto_login = true
        end
    end

    FireBase.read(PATHS.Users .. '/' .. username, function(success, user)
        if not success then
            Menu.Auth.StatusLabel:override('Database error')
            return
        end

        if user == nil or user == json.null then
            Menu.Auth.StatusLabel:override("User doesn't exist")
            return
        end

        if not user.password or not user.userid then
            Menu.Auth.StatusLabel:override('Invalid account data')
            return
        end

        if user.password ~= password then
            Menu.Auth.StatusLabel:override('Wrong password')
            return
        end

        -- SteamID verification
        local current_steamid = panorama.open().MyPersonaAPI.GetXuid()
        if user.steamid and user.steamid ~= current_steamid then
            Menu.Auth.StatusLabel:override('Account Is Locked To Another HWID')
            return
        end

        -- If no SteamID is stored yet, store it now
        if not user.steamid then
            FireBase.update(PATHS.Users .. '/' .. username, {
                steamid = current_steamid
            }, function(update_success)
                if not update_success then
                    utils.printc(pui.format(string.format('\f<z>[\f<orion>Firebase\f<z>] Failed To Store HWID For User: \f<orion>%s', username)))
                end
            end)
        end

        local userid_str = tostring(user.userid)
        local online_update = {
            [userid_str] = {
                username = username,
                last_active = Time.UnixTime(),
                login_time = Time.RealTime(),
                is_admin = user.is_admin or false,
                version = user.version or 'Live',
                steamid = current_steamid  -- Include SteamID in online users
            }
        }
        
        -- Initialize stats with existing data or defaults
        Globals.UserData.Stats = {
            KillCount = user.stats and user.stats.KillCount or 0,
            Coins = user.stats and user.stats.Coins or 0,
            TimesLoaded = (user.stats and user.stats.TimesLoaded or 0) + 1
        }
        
        FireBase.update(PATHS.OnlineUsers, online_update, function(update_success, error)
            if update_success then
                Globals.UserData.LoggedIN = true
                Globals.UserData.Username = username
                Globals.UserData.UserID = userid_str
                Globals.UserData.IsAdmin = user.is_admin or false
                Globals.UserData.Version = user.version or 'Live'
                Globals.UserData.SteamID = current_steamid
                Globals.UserData.LoginTime = Time.RealTime()
                
                -- Only save credentials if remember is true AND we're not auto-logging in
                if remember and not is_auto_login then
                    SaveCredentials(username, password)
                end
                
                MenuUpdate()
                Menu.Auth.StatusLabel:override('Login successful')
                
                -- Update menu with stats
                if Menu.Stats then
                    Menu.Stats.KillCounter:override('\f<silent>Kills: \v' .. Globals.UserData.Stats.KillCount)
                    Menu.Stats.CoinCounter:override('\f<silent>Coins: \v' .. Globals.UserData.Stats.Coins)
                    Menu.Stats.TimesLoaded:override('\f<silent>Times Loaded: \v' .. Globals.UserData.Stats.TimesLoaded)
                    Menu.Casino.Balance:override('\f<silent>Balance: \v' .. Globals.UserData.Stats.Coins)
                end
                
                -- Initialize online users count after successful login
                getOnlineUsersCount(function(count)
                    Globals.OnlineUsers = count
                end)
                
            else
                Menu.Auth.StatusLabel:override('Status update failed')
            end
        end)

        if user == nil or user == json.null then
    Menu.Auth.StatusLabel:override("User doesn't exist")
    return
end

    end)
end

Menu.Auth.Login:set_callback(function()
    local username = Menu.Auth.UserName:get()
    local remember = Menu.Auth.RememberMe:get()
    
    Login(username, real_password, remember)

    
end)

IsNumber = function(v)
    return tonumber(v) ~= nil
end

AddCasinoLog = function(message)
    if #CasinoLogs >= 3 then  -- Limit to 3 casino messages at once
        table.remove(CasinoLogs, 1)
    end
    
    CasinoLogs[#CasinoLogs + 1] = {
        Message = message,
        TimeCreated = globals.curtime(),
        Alpha = 255
    }
end

Menu.Casino.Flip:set_callback(function()
    local Amount = tonumber(Menu.Casino.BetAmount:get())

    if not IsNumber(Amount) or Amount == nil or Amount <= 0 then 
        AddCasinoLog('Invalid Bet Amount')
        return 
    end

    if Amount > Globals.UserData.Stats.Coins then
        AddCasinoLog('Not enough Coins to bet')
        return
    end

    Globals.UserData.Stats.Coins = Globals.UserData.Stats.Coins - Amount

    if client.random_int(0, 1) == 0 then 
        local Winnings = Amount * 2
        Globals.UserData.Stats.Coins = Globals.UserData.Stats.Coins + Winnings
        AddCasinoLog('You Won: '..Winnings..' Coins! (Bet: '..Amount..') | New Balance: '..Globals.UserData.Stats.Coins)
    else
        AddCasinoLog('You Lost: '..Amount..' Coins | New Balance: '..Globals.UserData.Stats.Coins)
    end

    SaveStatsToFirebase()
end)

Menu.Miscellaneous.AccentColor:set_callback(function(this)
    local r, g, b, a = unpack(this.value)
    colors.accent = color.rgb(r, g, b, a)
    colors.hex = '\a'.. colors.accent:to_hex()
	colors.hexs = string.sub(colors.hex, 1, -3)

    References.Miscellaneous.Settings.MenuColor:set(Menu.Miscellaneous.AccentColor.value)
end, true)

--Menu.Miscellaneous.Filter:set_callback(function(self)
--    client.delay_call(0, function()
--        cvar.con_filter_enable:set_int(self.value and 1 or 0)
--        cvar.con_filter_text:set_string(self.value and 'Orion Solutions ['..Globals.UserData.Version ..']' or '')
--    end)
--end, true)

local Y = 0  -- Initialize with default value
local Alpha = 255
local ShowLoding = true

client.set_event_callback('paint_ui', function()
    if not Globals.UserData.LoggedIN then
        return
    end

	if ShowLoding and Globals.UserData.LoggedIN then
		local Screen = vector(client.screen_size())
    	local Size = vector(Screen.x, Screen.y)

		renderer.blur(0, 0, Screen.x, Screen.y, 15, 15, 15, 150)  -- Adjust alpha as needed
    	local Sizing = MathUtil.lerp(0.1, 0.9, math.sin(globals.curtime() * 0.9) * 0.5 + 0.5)
    	local Rotation = MathUtil.lerp(0, 360, globals.curtime() % 1)
    	Alpha = MathUtil.lerp(Alpha, 0, globals.frametime() * 0.5)
    	Y = MathUtil.lerp(Y, 20, globals.frametime() * 2)  -- Fixed: `Y` instead of `y`
	
		renderer.rectangle(0, 0, Size.x, Size.y, 13, 13, 13, Alpha)
    	renderer.circle_outline(Screen.x / 2, Screen.y / 2, 255, 255, 255, Alpha, 20, Rotation, Sizing, 3)
    	renderer.text(Screen.x / 2, Screen.y / 2 + 40, 255, 255, 255, Alpha, 'c', 0, 'Loading...')
    	renderer.text(Screen.x / 2, Screen.y / 2 + 60, 255, 255, 255, Alpha, 'c', 0, 'Welcome - ' .. Globals.UserData.Username)
	end

    notification.OnLoad()

    LocalPlayer.Entity = entity.get_local_player()
    LocalPlayer.Valid = LocalPlayer.Entity and entity.is_alive(LocalPlayer.Entity)

    local Screen = vector(client.screen_size())
    WaterMark()
    RenderScreenLogs()

    if Globals.UserData.LoggedIN then
        Menu.Home.Statistics.KillCounter:override(pui.macros.silent .. 'Kills: \v' .. Globals.UserData.Stats.KillCount)
        Menu.Home.Statistics.CoinCounter:override(pui.macros.silent .. 'Coins: \v' .. Globals.UserData.Stats.Coins)
        Menu.Home.Statistics.TimesLoadedCounter:override(pui.macros.silent .. 'Times Loaded: \v' .. Globals.UserData.Stats.TimesLoaded)
        Menu.Home.Statistics.OnlineUsers:override(pui.macros.silent .. 'Online: \v' .. Globals.OnlineUsers)
        Menu.Casino.Balance:override(pui.macros.silent .. 'Balance: \v' .. Globals.UserData.Stats.Coins)
    end
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

    cvar.cam_idealdist:set_raw_float(100)
end)

client.delay_call(8, function()
    ShowLoding = false
end)

-- Function to save stats to Firebase
SaveStatsToFirebase = function()
    if not Globals.UserData.LoggedIN or not Globals.UserData.Username then
        return
    end

    -- Prepare update
    local update_data = {
        ['stats'] = Globals.UserData.Stats
    }

    FireBase.update(PATHS.Users .. '/' .. Globals.UserData.Username, update_data, function(success, error)
        if success then
        else
        end
    end)
end

UpdateStats = function(kills, coins, loaded)
    if not Globals.UserData.LoggedIN then return end
    
    Globals.UserData.Stats.KillCount = (Globals.UserData.Stats.KillCount or 0) + (kills or 0)
    Globals.UserData.Stats.Coins = (Globals.UserData.Stats.Coins or 0) + (coins or 0)
    Globals.UserData.Stats.TimesLoaded = (Globals.UserData.Stats.TimesLoaded or 0) + (loaded or 0)
    
    SaveStatsToFirebase()
end

-- Track player kills and coins
client.set_event_callback('player_death', function(e)
    if not Globals.UserData.LoggedIN then
        return
    end

    if client.userid_to_entindex(e.attacker) == entity.get_local_player() then
        local coins = 1
        if e.headshot then
            coins = coins + 1  -- Bonus coin for headshot
        end
        UpdateStats(1, coins)  -- 1 kill, X coins
    end
end)

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
    LocalPlayerState(cmd)
    AntiAim(cmd)

    local air_strafe = ui.reference('Misc', 'Movement', 'Air strafe')
    if Menu.Rage.JumpScout:get() then
        local vel_x, vel_y = entity.get_prop(entity.get_local_player(), 'm_vecVelocity')
        local vel = math.sqrt(vel_x^2 + vel_y^2)
        ui.set(air_strafe, not (cmd.in_jump and (vel < 10)) or ui.is_menu_open())
    end
end)

Resolve = function(Player)
    if not Menu.Rage.Resolver.on.value then        
        plist.set(Player, 'Correction active', true)

        plist.set(Player, 'Force body yaw', false)
        plist.set(Player, 'Force body yaw value', 0)

        return
    end

    if Menu.Rage.Resolver.Mode.value == 'Math.Random' then
        plist.set(Player, 'Correction active', false)

        plist.set(Player, 'Force body yaw', true)
        plist.set(Player, 'Force body yaw value', math.random(-60, 60))
    elseif Menu.Rage.Resolver.Mode.value == 'Soon' then
        plist.set(Player, 'Correction active', true)

        plist.set(Player, 'Force body yaw', false)
        plist.set(Player, 'Force body yaw value', 0)
    end
end

client.set_event_callback('net_update_start', function()
    local Enemies = entity.get_players(true)
    for i = 1, #Enemies do 
        local Player = Enemies[i]
        Resolve(Player)
    end
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

-- Periodic stats saver (every 30 seconds)
client.set_event_callback('run_command', function()
    if not Globals.UserData.LoggedIN then
        return
    end

    local current_time = globals.curtime()
    if not Globals.UserData.LastUpdateTime or (current_time - Globals.UserData.LastUpdateTime) > 30 then
        SaveStatsToFirebase()
        Globals.UserData.LastUpdateTime = current_time
    end

    -- Update online status every 15 seconds
    if not Globals.UserData.LastOnlineUpdate or (current_time - Globals.UserData.LastOnlineUpdate) > 10 then
        updateOnlineStatus()
        Globals.UserData.LastOnlineUpdate = current_time
    end
    
    -- Update online count every 30 seconds
    if not Globals.LastOnlineCountUpdate or (current_time - Globals.LastOnlineCountUpdate) > 30 then
        getOnlineUsersCount(function(count)
            Globals.OnlineUsers = count
        end)
        Globals.LastOnlineCountUpdate = current_time
    end
    
    -- Run cleanup every minute
    if not Globals.LastCleanup or (current_time - Globals.LastCleanup) > 60 then
        getOnlineUsersCount(function(count) end)  -- This will trigger cleanup
        Globals.LastCleanup = current_time
    end
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
        -- Only show BT if it's more than 1 tick (indicating actual backtrack)
        local btDisplay = (s.BT and s.BT > 1) and string.format(' (\f<green>%d\f<z> BT)', s.BT) or ''
        utils.printc(pui.format(string.format('\f<z>[\f<green>Orion Solutions\f<z>] \f<z>Hit ' .. '\f<green>' .. entity.get_player_name(e.target) .. '\f<z> In The ' .. '\f<green>' .. Hitgroup .. '\f<z> For ' .. '\f<green>' .. s.Damage .. '\f<z> Damage' .. btDisplay .. (s.LC and ' ('..'\f<z>LC)' or ''))))
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
            utils.printc(pui.format(string.format('\f<z>[\f<red>Orion Solutions\f<z>] \f<z>Missed ' .. '\f<red>' .. entity.get_player_name(s.Target) .. '\f<z> In The ' .. '\f<red>' .. HitGroup .. '\f<z> Due To ' .. '\f<red>' .. s.Reason)))
        end
    end
end)

-- Save on shutdown
client.set_event_callback('shutdown', function()
    if Globals.UserData.LoggedIN and Globals.UserData.UserID then
        SaveStatsToFirebase()

        local UserIdString = tostring(Globals.UserData.UserID)
        local RemoveData = {
            [UserIdString] = json.null
        }

        FireBase.update(PATHS.OnlineUsers, RemoveData, function(success, error) end)
    end
end)

client.delay_call(0, function()
    local saved = database.read('orion_credentials')
    if saved then
        local ok, credentials = pcall(json.parse, saved)
        if ok and credentials and credentials.username and credentials.password then
            -- Check SteamID before auto-login
            FireBase.read(PATHS.Users .. '/' .. credentials.username, function(success, user)
                if success and user then
                    local current_steamid = panorama.open().MyPersonaAPI.GetXuid()
                    if not user.steamid or user.steamid == current_steamid then
                        -- Proceed with auto-login
                        Menu.Auth.UserName:set(credentials.username)
                        Menu.Auth.PassWord:set(credentials.password)
                        Menu.Auth.RememberMe:set(true)
                        Login(credentials.username, credentials.password, true)
                    else
                        utils.printc(pui.format(string.format('\f<z>[\f<orion>Auth\f<z>] \f<z>Auto-Login Failed: HWID Mismatch')))
                    end
                end
            end)
        end
    end
end)

SaveConfigToFirebase = function(name, encoded)
    local username = Globals.UserData.Username or 'Unknown'
    local path = string.format('/configs/%s/%s', username, name)
    local data = {
        author = username,
        cfg = encoded,
        timestamp = Time.UnixTime()
    }
    FireBase.write(path, data, function(success)
        if success then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Auth\f<z>] \f<z>Config: \f<orion>%s Uploaded To Cloud', name)))
        else
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Auth\f<z>] \f<z>Failed To Upload Config To Cloud')))
        end
    end)
end

RefreshCloudConfigList = function()
    if not Globals.UserData.LoggedIN then 
        utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Not logged in, cannot refresh cloud configs')))
        return 
    end
    
    local username = Globals.UserData.Username or 'Unknown'
    utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Refreshing cloud configs for user: \f<orion>%s', username)))

    FireBase.read('/configs/' .. username, function(success, data)
        if not success or not data or data == json.null then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>No cloud configs found for user: \f<orion>%s', username)))
            
            -- Clear the cloud configs array
            db.db.configs['Cloud'] = {}
            
            -- Update UI with empty message
            local displayList = {'No Cloud Configs'}
            Menu.Home.ConfigSystem.List:update(displayList)
            Menu.Home.ConfigSystem.List:set(0)
            Menu.Home.ConfigSystem.Selected:set('Selected - \vNone')
            return
        end

        db.db.configs['Cloud'] = {} -- Reset and ensure it's an array
        local displayList = {}

        for cfgName, cfgData in pairs(data) do
            if cfgData and cfgData.cfg then
                -- Store as array element with name and config data
                table.insert(db.db.configs['Cloud'], {cfgName, cfgData.cfg})
                local author = cfgData.author or username
                table.insert(displayList, string.format('[%s] ~ %s', author, cfgName))
            end
        end

        -- Sort alphabetically by config name
        table.sort(db.db.configs['Cloud'], function(a, b)
            return (a[1] or '') < (b[1] or '')
        end)

        -- Update the listbox
        if #displayList > 0 then
            Menu.Home.ConfigSystem.List:update(displayList)
            Menu.Home.ConfigSystem.List:set(0) -- Select first item
            
            local firstConfig = db.db.configs['Cloud'][1]
            if firstConfig then
                Menu.Home.ConfigSystem.Selected:set('Selected - \v' .. (firstConfig[1] or 'Unknown'))
            end

            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Loaded cloud configs: \f<orion>%d', #displayList)))
        else
            Menu.Home.ConfigSystem.List:update({'No Cloud Configs'})
            Menu.Home.ConfigSystem.List:set(0)
            Menu.Home.ConfigSystem.Selected:set('Selected - \vNone')
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>No cloud configs available')))
        end
    end)
end

local Config do 
    Config = pui.setup(Menu)

    Update = function()
        db.configs = {}
        db.configs.authors = {}

        local typeIndex = Menu.Home.ConfigSystem.Type:get()
        local typeList = Menu.Home.ConfigSystem.Type:get_list()
        local cfgType = typeList[typeIndex] or 'Local'

        for i, cfgs in pairs(db.db.configs[cfgType] or {}) do
            table.insert(db.configs, pui.format('[\v' .. i .. '\r] ' .. cfgs[1]))
        end

        Menu.Home.ConfigSystem.List:update(db.configs)
    end Update()

    GetConfig = function()
        -- Get config type - it's already the string value
        local cfgType = Menu.Home.ConfigSystem.Type:get() or 'Local'
        local listIndex = Menu.Home.ConfigSystem.List.value + 1

        if cfgType == 'Cloud' then
            -- Cloud config logic
            local cloudConfigs = db.db.configs['Cloud'] or {}
        
            local t = cloudConfigs[listIndex]
        
            if not t then
                utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>No cloud config found at index: \f<orion>%d', #listIndex)))
                return nil, nil
            end
        
            local name = t[1] or 'Unknown'
            local cfg = t[2] or ''
            return name, cfg
        else
            -- Local config logic
            local localConfigs = db.db.configs['Local'] or {}
        
            local t = localConfigs[listIndex]
        
            if not t then
                 utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>No local config found at index: \f<orion>%d', #listIndex)))
                return nil, nil
            end
        
            local name = t[1] or 'Unknown'
            local cfg = t[2] or ''
            return name, cfg
        end
    end

    Create = function(name, cfg)
        name = cfg and name or Menu.Home.ConfigSystem.Name:get()
        if #name >= 1 then
            table.insert(db.db.configs['Local'], {name, cfg or base64.encode(json.stringify(Config:save())) } )
            db.save()
            Menu.Home.ConfigSystem.Name:set('')
        end
        Update()
        Menu.Home.ConfigSystem.List:set(#db.db.configs['Local'] - 1)
    end

    Menu.Home.ConfigSystem.Delete:set_callback(function()
        local val = Menu.Home.ConfigSystem.List:get()
        local cfgType = Menu.Home.ConfigSystem.Type:get() or 'Local'

        if cfgType == 'Cloud' then
            local cloudConfigs = db.db.configs['Cloud'] or {}
            local configToDelete = cloudConfigs[val + 1]
    
            if not configToDelete then
                utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>No cloud config selected to delete!')))
                return
            end
    
            local configName = configToDelete[1] or 'Unknown'
            local username = Globals.UserData.Username or 'Unknown'
    
            local path = string.format('/configs/%s/%s', username, configName)
            FireBase.delete(path, function(success, response)
                if success then
                    utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Deleted cloud config: \f<orion>%s', configName)))
                    RefreshCloudConfigList()
                else
                    utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Failed to delete cloud config: \f<orion>%s', configName)))
                end
            end)
        else
            local configName = db.db.configs['Local'][val + 1] and db.db.configs['Local'][val + 1][1] or ''
    
            if configName == 'Default' then
                utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Cannot Delete Default config!')))
                return
            end
    
            table.remove(db.db.configs['Local'], val + 1)
            Menu.Home.ConfigSystem.List:set(math.max(0, val - 1))
            db.save()
            Update()
        end
    end)

    Menu.Home.ConfigSystem.Save:set_callback(function()
        local cfgType = Menu.Home.ConfigSystem.Type:get() or 'Local'
        local cfg = base64.encode(json.stringify(Config:save()))
        local listIndex = Menu.Home.ConfigSystem.List.value + 1

        if cfgType == 'Cloud' then
            local cloudConfigs = db.db.configs['Cloud'] or {}
            local configToUpdate = cloudConfigs[listIndex]
        
            if not configToUpdate then
                utils.printc(pui.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>No cloud config selected to save!'))
                return
            end
        
            local configName = configToUpdate[1] or 'Unknown'
            local username = Globals.UserData.Username or 'Unknown'

            db.db.configs['Cloud'][listIndex][2] = cfg

            local path = string.format('/configs/%s/%s', username, configName)
            local data = {
                author = username,
                cfg = cfg,
                timestamp = Time.UnixTime()
            }
        
            FireBase.write(path, data, function(success, response)
                if success then
                    utils.printc(pui.format(string.format("\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Config '\f<orion>%s\f<z>' saved to cloud", configName)))
                else
                    db.db.configs['Cloud'][listIndex][2] = configToUpdate[2]
                end
            end)
        else
            if db.db.configs['Local'] and db.db.configs['Local'][listIndex] then
                db.db.configs['Local'][listIndex][2] = cfg
                db.save()
                utils.printc(pui.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Config saved locally'))
            else
                utils.printc(pui.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Config not found for saving'))
            end
        end
    end)

    Menu.Home.ConfigSystem.Export:set_callback(function()
        local name, cfg = GetConfig()
        local text = string.format('OrionConfigs::%s::%s', name, cfg)
        clipboard.set(text)
    end)

    Load = function(self)
        local cfgType = Menu.Home.ConfigSystem.Type:get() or 'Local'

        local name, config = GetConfig()
        if not name or not config then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>No config selected to load!')))
            return
        end

        utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Loading \f<orion> %s \f<z>Config: \f<orion>%s', cfgType, name)))

        local success, decrypted = pcall(json.parse, base64.decode(config))
        if success and decrypted then
            Config:load(decrypted)
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Loaded Config')))
        
            if cfgType == 'Local' then
                db.save()
            end
        else
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Failed to parse config data!')))
        end
    end

    Menu.Home.ConfigSystem.Import:set_callback(function()
        local text = clipboard.get()
        local name, config = text:match('OrionConfigs::([%s%S]+)::([%s%S]+)')
        if not name or not config then return end
        Create(name,config)
        Load(Menu.Home.ConfigSystem.Load)
    end)

    Menu.Home.ConfigSystem.Load:set_callback(Load)
    Menu.Home.ConfigSystem.Create:set_callback(Create)

    Menu.Home.ConfigSystem.List:set_callback(function(self)
        local cfgType = Menu.Home.ConfigSystem.Type:get() or 'Local'
    
        if cfgType == 'Cloud' then
            local cloudConfigs = db.db.configs['Cloud'] or {}
            local selectedConfig = cloudConfigs[self.value + 1]
            if selectedConfig then
                local name = selectedConfig[1] or 'Unknown'
                Menu.Home.ConfigSystem.Selected:set('Selected - \v' .. name)
            else
                Menu.Home.ConfigSystem.Selected:set('Selected - \vNone')
            end
        else
            local localConfigs = db.db.configs['Local'] or {}
            local selectedConfig = localConfigs[self.value + 1]
            if selectedConfig then
                local name = selectedConfig[1] or 'Unknown'
                Menu.Home.ConfigSystem.Selected:set('Selected - \v' .. name)
            else
                Menu.Home.ConfigSystem.Selected:set('Selected - \vNone')
            end
        end
    end, true)

    Menu.Home.ConfigSystem.Upload:set_callback(function()
        if not Globals.UserData.LoggedIN then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>You must be logged in to upload configs!')))
            return
        end

        local name, cfg = GetConfig()
        if not name or name == '' then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>No config selected to upload!')))
            return
        end

        if name == 'Default' then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Cannot Upload \f<orion>Default \f<z>Config!')))
            return
        end
    
        if not cfg or cfg == '' then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Config data missing for: \f<orion>%s', name)))
            return
        end

        local username = Globals.UserData.Username or 'Unknown'
        local path = string.format('/configs/%s/%s', username, name)

        local data = {
            author = username,
            cfg = cfg,
            timestamp = Time.UnixTime()
        }

        FireBase.write(path, data, function(success, response)
            if success then
                utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Successfully uploaded config: \f<orion>%s', name)))
            else
                utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Failed to upload config: \f<orion>%s — %s', name, tostring(response))))
            end
        end)
    end)

    Menu.Home.ConfigSystem.Type:set_callback(function(this)
        local currentValue = this.value
        local cfgType = currentValue or 'Local'  -- Since value is already the string

        if cfgType == 'Cloud' then
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Switching to Cloud configs...')))
            RefreshCloudConfigList()
        else
            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Switching to Local configs...')))
            local localList = {}

            -- Format: [index] ConfigName
            for i = 1, #db.db.configs['Local'] do
                local cfg = db.db.configs['Local'][i]
                local cfgName = type(cfg) == 'table' and (cfg[1] or 'Unnamed') or tostring(cfg)
                table.insert(localList, string.format('[%d] %s', i, cfgName))
            end

            -- Update the List UI for Local mode
            Menu.Home.ConfigSystem.List:update(localList)

            utils.printc(pui.format(string.format('\f<z>[\f<orion>Orion Solutions\f<z>] \f<z>Loaded \f<orion>%d \f<z>Local Configs:', #localList)))
        end

       -- Reset selection text
        Menu.Home.ConfigSystem.Selected:set('Selected - \vNone')
    end)
end

--Used If I Ever Have To Clear A Path :)
--client.delay_call(1, function()
--    FireBase.update(PATHS.Users, json.null, function(success, error)
--        if success then
--            client.log('[Orion] Removed Invites path from database on launch')
--        else
--            client.log('[Orion] Failed to remove Invites path: ' .. (error or 'unknown'))
--        end
--    end)
--end)