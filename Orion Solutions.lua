local ffi = require "ffi"
local pui = require "gamesense/pui" 
local http = require "gamesense/http"
local adata = require "gamesense/antiaim_funcs"
local images = require "gamesense/images"
local vector = require "vector"

local data = database.read("SURGEDATA") or {}


if data.kill_count == nil then data.kill_count = 0 end
if data.coins == nil then data.coins = 0 end

local globals = {
	screen_x, screen_y,
}

globals.screen_x, globals.screen_y = client.screen_size()
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
	hex		= "\a7676FFFF",
	--accent	= color.hex("74A6A9"),
	--back	= color.rgb(23, 26, 28),
	--dark	= color.rgb(5, 6, 8),
	--white	= color.rgb(255),
	--black	= color.rgb(0),
	--null	= color.rgb(0, 0, 0, 0),
	--text	= color.rgb(230),

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
	space = function(group) group:label("\n") end,
	header = function(name, group) 
		r = {}
		r[#r+1] = group:label("\f<c> "..name)
		r[#r+1] = group:label("\f<silent>‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾") 
		return r
	end

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
pui.macros.surge = colors.hex
--118, 118, 255, 255

local ui = {
    global = groups.fakelag:label("\f<silent>---------------\vSurge\f<silent>---------------"),
    tab = groups.fakelag:combobox("\n", "Config","Main","AntiAim"),
	--test = groups.fakelag:color_picker("s", 118, 118, 255, 255),

	GUI.header("Info" , groups.fakelag),
	groups.fakelag:label("\f<silent>User: \vJaylon"),
	groups.fakelag:label("\f<silent>Build: \vDebug"),
	GUI.header("Stats" , groups.fakelag),
	killcounter = groups.fakelag:label("\f<silent>Kills: \v" .. data.kill_count),
	coincounter = groups.fakelag:label("\f<silent>Coins: \v" .. data.coins),
	rage = {
		GUI.header("Rage" , groups.angles),
		--headhelper = groups.angles:checkbox("HeadHelper(\aFF3232B3beta\r)"),
		groups.angles:label("\f<silent>Nothing here yet"),

	},

	visuals = {
	
		GUI.header("Visuals" , groups.angles),
		watermark = groups.angles:checkbox("Watermark", true, true),
		


		
	},
	misc = {
		GUI.header("Misc" , groups.angles),
		antibackstab = groups.angles:checkbox("Anti Backstab", true),
		antibackstabdist = groups.angles:slider("Distance ", 0, 500, 160),


	},
	--timecounter = groups.fakelag:label("\f<silent>Time: \v" .. data.time)
}




local function Menu() 
	refs.aa.angles.enable:depend({ui.tab, "AntiAim"})
	refs.aa.angles.pitch[1]:depend({ui.tab, "AntiAim"})
	refs.aa.angles.pitch[2]:depend({ui.tab, "AntiAim"})
	refs.aa.angles.base:depend({ui.tab, "AntiAim"})
	refs.aa.angles.yaw[1]:depend({ui.tab, "AntiAim"})
	refs.aa.angles.yaw[2]:depend({ui.tab, "AntiAim"})
	refs.aa.angles.jitter[1]:depend({ui.tab, "AntiAim"})
	refs.aa.angles.jitter[2]:depend({ui.tab, "AntiAim"})
	refs.aa.angles.body[1]:depend({ui.tab, "AntiAim"})
	refs.aa.angles.body[2]:depend({ui.tab, "AntiAim"})
	refs.aa.angles.edge:depend({ui.tab, "AntiAim"})
	refs.aa.angles.fs_body:depend({ui.tab, "AntiAim"})
	refs.aa.angles.freestand:depend({ui.tab, "AntiAim"})
	refs.aa.angles.freestand.hotkey:depend({ui.tab, "AntiAim"})
	refs.aa.angles.roll:depend({ui.tab, "AntiAim"})



	refs.aa.fakelag.enable:depend({ui.tab, "yg"})
	refs.aa.fakelag.enable.hotkey:depend({ui.tab, "yg"})
	refs.aa.fakelag.variance:depend({ui.tab, "yg"})
	refs.aa.fakelag.amount:depend({ui.tab, "yg"})
	refs.aa.fakelag.limit:depend({ui.tab, "yg"})



	
	pui.traverse(ui.rage, function (ref, path)
		ref:depend({ui.tab, "Main"})
	end)	

	pui.traverse(ui.visuals, function (ref, path)
		ref:depend({ui.tab, "Main"})
	end)

	pui.traverse(ui.misc, function (ref, path)
		ref:depend({ui.tab, "Main"})
	end)		

	ui.misc.antibackstabdist:depend({ui.misc.antibackstab, true})




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




local function WaterMark()
	if not ui.visuals.watermark:get() then return end
	--images.image_draw(100, 100, 25, 25)
	local text_width, text_height = renderer.measure_text(nil, "Surge •\v" .." Jaylon •\v".. " Debug")
	left = globals.screen_x - text_width - 25

	local Player = entity.get_local_player()
    local SteamID3 = entity.get_steam64(Player)
    local Avatar = images.get_steam_avatar(SteamID3)

	--render.rectangle(left - 16, 9.1, text_width + 12.1, 22, 5, 118, 118, 255, 255)
	render.rectangle(left - 33, 9, text_width + 12 + 17, 22, 5, 118, 118, 255, 255)
	render.rectangle(left - 32, 10, text_width + 10 + 17, 20, 5, 23, 23, 23, 255)
	--other text set up --redo this plez its ass and needs to be done right!!
	renderer.text(left - 10, 10 + text_height/4, 255, 255, 255, 255, nil, 200, "Surge •")
	parttext_width, parttext_height = renderer.measure_text(nil, "Surge •")
	renderer.text(left - 10 + parttext_width, 10 + text_height/4, 118, 118, 255, 255, nil, 200, " Jaylon")
	prevlocation = left - 10 + parttext_width
	parttext_width, parttext_height = renderer.measure_text(nil, " Jaylon")
	renderer.text(prevlocation + parttext_width, 10 + text_height/4, 255, 255, 255, 255, nil, 200, " • ")
	prevlocation = prevlocation + parttext_width
	parttext_width, parttext_height = renderer.measure_text(nil, " • ")
	renderer.text(prevlocation + parttext_width, 10 + text_height/4, 118, 118, 255, 255, nil, 200, "Debug")


	Avatar:draw(left - 28, 13 , 14.5, 15)
	renderer.circle_outline(left - 28 + 7.9, 12 + 8, 23, 23, 23, 255, 10, 0, 1, 3)


end

local function AntiBackStab()

	if not ui.misc.antibackstab:get() then return end


	local lp = entity.get_local_player()
	if not lp then return end
	local lppos = vector(entity.get_origin(lp))


	local target = client.current_threat()
	if not target then return end
	local tpos = vector(entity.get_origin(target))

	dist = lppos:dist(tpos)

	local weapon = entity.get_player_weapon(target)
	if dist <= ui.misc.antibackstabdist.value and entity.get_classname(weapon) == "CKnife" then
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
		data.kill_count = (data.kill_count or 0) + 1
		data.coins = (data.coins or 0) + 1
		if e.headshot then
			data.coins = (data.coins or 0) + 1

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
	globals.kills = data.kill_count
	ui.killcounter:set("\f<silent>Kills: \v" .. data.kill_count)
	ui.coincounter:set("\f<silent>Coins: \v" .. data.coins)

	
	WaterMark()


end)

client.set_event_callback('setup_command', function(e)

	AntiBackStab()

end)

client.set_event_callback("shutdown", function()
	database.write("SURGEDATA", data)
end)


