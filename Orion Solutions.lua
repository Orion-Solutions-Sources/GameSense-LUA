local ffi = require "ffi"
local pui = require "gamesense/pui" 
local http = require "gamesense/http"
local adata = require "gamesense/antiaim_funcs"
local images = require "gamesense/images"
local vector = require "vector"

local data = database.read("ORION_DATA") or {}

if data.KillCount == nil then data.KillCount = 0 end
if data.Coins == nil then data.Coins = 0 end

local Globals = {
	screen_x, screen_y,
	UserName,
}

Globals.screen_x, Globals.screen_y = client.screen_size()
Globals.UserName = entity.get_player_name(entity.get_local_player())
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
		}
	}
}

local a = function (...) return ... end
--taken from hystreria ngl
local color do
	local helpers = {
		RGBtoHEX = a(function (col, short)
			return string.format(short and "%02X%02X%02X" or "%02X%02X%02X%02X", col.r, col.g, col.b, col.a)
		end),
		HEXtoRGB = a(function (hex)
			hex = string.gsub(hex, "^#", "")
			return tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16), tonumber(string.sub(hex, 7, 8), 16) or 255
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
}

local groups = {
	angles = pui.group("AA", "Anti-aimbot angles"),
	fakelag = pui.group("AA", "Fake lag"),
	other = pui.group("AA", "Other"),
    LuaB = pui.group("LUA", "B"),
	LuaA = pui.group("LUA", "A"),
}

pui.macros.silent = "\aCDCDCD40"
pui.macros.p = "\aCDCDCD40•\r"
pui.macros.c = "\v•\r" 
pui.macros.orion = colors.hex
--118, 118, 255, 255

local ConditionName = ""
local UI = {
	GUI.Header("Orion Solutions", groups.fakelag),
	Tabs = groups.fakelag:combobox("\n", "Home", "Rage", "Anti-Aim", "Visuals", "Miscellaneous"),

	Home = {
		GUI.Header("Info", groups.fakelag),
		groups.fakelag:label("\f<silent>User: \v"..Globals.UserName),
        groups.fakelag:label("\f<silent>Build: \vDebug"),

		Statistics = {
		   GUI.Header("Statistics", groups.other),
		   KillCounter = groups.other:label("\f<silent>Kills: \v" .. data.KillCount),
		   CoinCounter = groups.other:label("\f<silent>Coins: \v" .. data.Coins),
		},
	},

	Rage = {
		GUI.Header("Rage", groups.angles),
		Resolver = GUI.Feature({groups.angles:checkbox("Resolver")}, function(Parent)
			return {
				Mode = groups.angles:combobox("\n Resolver Mode", "Normal", "Bruteforce"),
			}, true
		end),
	},
	
	AntiAim = {
		GUI.Header("AntiAim", groups.angles),
		Type = groups.angles:combobox("Type", "GameSense", "Orion(Nothing's here)"),
		Condition = groups.angles:combobox("Condtion", "Global", "Stand", "Walk/Run", "Air", "Duck", "AirDuck", "Sneak"),

	},

	Visuals = {
		GUI.Header("Visuals", groups.angles),

		WaterMark = groups.angles:checkbox("WaterMark", true, true)
	},

	Miscellaneous = {
		GUI.Header("Miscellaneous" , groups.angles),
        AntiBackStab = groups.angles:checkbox("Anti Backstab", true),
        AntiBackStabDistance = groups.angles:slider("Distance ", 0, 500, 160),
		
		
	},

	ConfigSystem = {

	}
}

local function Menu() 
	refs.aa.angles.enable:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.pitch[1]:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.pitch[2]:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.base:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.yaw[1]:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.yaw[2]:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.jitter[1]:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.jitter[2]:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.body[1]:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.body[2]:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.edge:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.fs_body:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.freestand:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.freestand.hotkey:depend({UI.Tabs, "AntiAim"})
	refs.aa.angles.roll:depend({UI.Tabs, "AntiAim"})

	refs.aa.other.slowmo:depend({UI.Tabs, "AntiAim"})
	refs.aa.other.slowmo.hotkey:depend({UI.Tabs, "AntiAim"})
	refs.aa.other.legs:depend({UI.Tabs, "AntiAim"})
	refs.aa.other.onshot:depend({UI.Tabs, "AntiAim"})
	refs.aa.other.onshot.hotkey:depend({UI.Tabs, "AntiAim"})
	refs.aa.other.fp:depend({UI.Tabs, "AntiAim"})
	refs.aa.other.fp.hotkey:depend({UI.Tabs, "AntiAim"})

	refs.aa.fakelag.enable:depend({UI.Tabs, "yg"})
	refs.aa.fakelag.enable.hotkey:depend({UI.Tabs, "yg"})
	refs.aa.fakelag.variance:depend({UI.Tabs, "yg"})
	refs.aa.fakelag.amount:depend({UI.Tabs, "yg"})
	refs.aa.fakelag.limit:depend({UI.Tabs, "yg"})

	pui.traverse(UI.Home.Statistics, function(ref, path)
		ref:depend({UI.Tabs, "Home"})
	end)

	pui.traverse(UI.Rage, function (ref, path)
		ref:depend({UI.Tabs, "Rage"})
	end)
	
	pui.traverse(UI.AntiAim, function(ref,path)
		ref:depend({UI.Tabs, "Anti-Aim"})
	end)

	pui.traverse(UI.Visuals, function (ref, path)
		ref:depend({UI.Tabs, "Visuals"})
	end)

	pui.traverse(UI.Miscellaneous, function (ref, path)
		ref:depend({UI.Tabs, "Miscellaneous"})
	end)		

	UI.Miscellaneous.AntiBackStabDistance:depend({UI.Miscellaneous.AntiBackStab, true})
end

Menu()

local render = {

	rectangle = function (x, y, w, h, n, r, g, b, a)
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

	rectangleedge = function (x, y, w, n, r, g, b, a)
		renderer.circle(x + n, y + n, r, g, b, a, n, 180, 0.25)
		renderer.rectangle(x + n, y, w - n - n, n, r, g, b, a)
		renderer.circle(x + w - n, y + n, r, g, b, a, n, 90, 0.25)
	end
}

WaterMark = function()
	if not UI.Visuals.WaterMark:get() then return end
	--images.image_draw(100, 100, 25, 25)
	local text_width, text_height = renderer.measure_text(nil, "Orion Solutions •\v" .. " " .. Globals.UserName .." •\v".. " Debug")
	left = Globals.screen_x - text_width - 25

	local Player = entity.get_local_player()
    local SteamID3 = entity.get_steam64(Player)
    local Avatar = images.get_steam_avatar(SteamID3)

	--render.rectangle(left - 16, 9.1, text_width + 12.1, 22, 5, 118, 118, 255, 255)
	render.rectangle(left - 33, 9, text_width + 12 + 17, 22, 5, 118, 118, 255, 255)
	render.rectangle(left - 32, 10, text_width + 10 + 17, 20, 5, 23, 23, 23, 255)
	--other text set up --redo this plez its ass and needs to be done right!!
	renderer.text(left - 10, 10 + text_height/4, 255, 255, 255, 255, nil, 200, "Orion Solutions •")
	parttext_width, parttext_height = renderer.measure_text(nil, "Orion Solutions •")
	renderer.text(left - 10 + parttext_width, 10 + text_height/4, 118, 118, 255, 255, nil, 200, " " .. Globals.UserName)
	prevlocation = left - 10 + parttext_width
	parttext_width, parttext_height = renderer.measure_text(nil, " " .. Globals.UserName)
	renderer.text(prevlocation + parttext_width, 10 + text_height/4, 255, 255, 255, 255, nil, 200, " • ")
	prevlocation = prevlocation + parttext_width
	parttext_width, parttext_height = renderer.measure_text(nil, " • ")
	renderer.text(prevlocation + parttext_width, 10 + text_height/4, 118, 118, 255, 255, nil, 200, "Debug")

	Avatar:draw(left - 28, 13 , 14.5, 15)
	renderer.circle_outline(left - 28 + 7.9, 12 + 8, 23, 23, 23, 255, 10, 0, 1, 3)
end

local States = {
	"Stand",
	"Running",
	"Air",
	"Duck",
	"AirDuck",
	"Sneak"
}

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
	--print(States[my.state])
end

AntiBackStab = function()
	if not UI.Miscellaneous.AntiBackStab:get() then return end

	local lp = entity.get_local_player()
	if not lp then return end
	local lppos = vector(entity.get_origin(lp))

	local target = client.current_threat()
	if not target then return end
	local tpos = vector(entity.get_origin(target))

	dist = lppos:dist(tpos)

	local weapon = entity.get_player_weapon(target)
	if dist <= UI.Miscellaneous.AntiBackStabDistance.value and entity.get_classname(weapon) == "CKnife" then
		refs.aa.angles.yaw[2]:override(180)
	else
		refs.aa.angles.yaw[2]:override(0)
	end
end

local hitgroup_names = {'generic', 'head', 'chest', 'stomach', 'left arm', 'right arm', 'left leg', 'right leg', 'neck', '?', 'gear'}

client.set_event_callback('aim_hit', function(e)
	local group = hitgroup_names[e.hitgroup + 1] or '?'
	print(string.format('Hit %s in the %s for %d damage (%d health remaining)', entity.get_player_name(e.target), group, e.damage, entity.get_prop(e.target, 'm_iHealth')))
end)


client.set_event_callback('aim_miss', function(e)
	local group = hitgroup_names[e.hitgroup + 1] or '?'
	print(string.format('Missed %s (%s) due to %s', entity.get_player_name(e.target), group, e.reason))
end)


client.set_event_callback("player_death", function(e)
	if client.userid_to_entindex(e.attacker) == entity.get_local_player() then
		data.KillCount = (data.KillCount or 0) + 1
		data.Coins = (data.Coins or 0) + 1
		if e.headshot then
			data.Coins = (data.Coins or 0) + 1
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
	if shooterid == client.userid_to_entindex(e.userid) then
		head = entity.hitbox_position(entity.get_local_player(), 0)
		impact = vector(e.x, e.y, e.z)
		enemy_view = vector(entity.get_origin(shooterid))
		enemy_view.z = enemy_view.z + 64
		-- closest_ray_point(head,enemy_view,impact)
	end
end)

client.set_event_callback("paint", function()
	Globals.kills = data.KillCount
	UI.Home.Statistics.KillCounter:set("\f<silent>Kills: \v" .. data.KillCount)
	UI.Home.Statistics.CoinCounter:set("\f<silent>Coins: \v" .. data.Coins)
	
	WaterMark()
	

end)

client.set_event_callback('setup_command', function(e)
	AntiBackStab()
	my_setup(e)
	AntiAim()
end)

client.set_event_callback("shutdown", function()
	database.write("ORION_DATA", data)
end)