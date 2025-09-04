local http = require 'gamesense/http'
local pui = require 'gamesense/pui'
local ffi = require 'ffi'

local Globals = {
    Groups = {
        Angles = pui.group("AA", "Anti-aimbot angles"),
        FakeLag = pui.group("AA", "Fake lag"),
        Other = pui.group("AA", "Other"),
        LuaB = pui.group("LUA", "B"),
	    LuaA = pui.group("LUA", "A")
    },
    UserData = {
        IsLoggedIn = false,
        UserName = nil,
        IsAdmin = false,
        Version = nil,
    },
    ScreenX, ScreenY
}

Globals.ScreenX, Globals.ScreenY = client.screen_size()

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
	hex		= "\a7676FF",
	accent	= color.hex("7676FF"),
	back	= color.rgb(23, 26, 28),
	dark	= color.rgb(5, 6, 8),
	white	= color.rgb(255),
	black	= color.rgb(0),
	null	= color.rgb(0, 0, 0, 0),
	text	= color.rgb(230),
}


pui.macros.silent = "\aCDCDCD40"
pui.macros.p = "\a7676FF•\r"
pui.macros.c = "\v•\r" 
pui.macros.orion = colors.hex
pui.macros.orionb = string.sub(colors.hex, 2, 7)

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

local Menu = {
    GUI.Header('Orion Solutions', Globals.Groups.FakeLag),

    Auth = {
        UserNameLabel = Globals.Groups.Angles:label("UserName"),
        UserName = Globals.Groups.Angles:textbox("UserName"),
        PassWordLabel = Globals.Groups.Angles:label("PassWord"),
        PassWord = Globals.Groups.Angles:textbox("PassWord"),
        Login = Globals.Groups.Angles:button("Login"),
        RememberMe = Globals.Groups.Angles:checkbox("Remember Me"),

        StatusLabel = Globals.Groups.Angles:label(" "),

        LoggedIn = Globals.Groups.Angles:checkbox("LOGGED IN"),
    }
}