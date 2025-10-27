local http = require 'gamesense/http'
local json = require 'json'
local ffi = require 'ffi'

local function GetHWID()
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

    return tostring(adapter_info.vendor_id) ..
           tostring(adapter_info.sub_sys_id) ..
           tostring(adapter_info.device_id)
end

local function Orion_Login(username, password)
    if not username or username == "" or not password or password == "" then
        print("[Orion Loader] ❌ Please provide both username and password.")
        return
    end

    local hwid = GetHWID()
    print("[Orion Loader] 🔑 Attempting login for " .. username)

    local login_payload = json.stringify({
        username = username,
        password = password,
        hwid = hwid
    })

    http.post("https://orionsolutions.shop/API/Login.php", {
        headers = {
            ["Content-Type"] = "application/json"
        },
        body = login_payload
    }, function(ok, res)
        if not ok then
            print("[Orion Loader] ❌ Network error.")
            return
        end

        if res.status ~= 200 then
            print("[Orion Loader] ❌ Login failed (HTTP " .. tostring(res.status) .. ")")
            return
        end

        local data = json.parse(res.body)
        if not data or not data.success then
            print("[Orion Loader] ❌ " .. tostring(data and data.error or "Invalid response"))
            return
        end

        local token = data.token
        if not token then
            print("[Orion Loader] ❌ No token returned from server.")
            return
        end

        print("[Orion Loader] ✅ Logged in as " .. username)
        print("[Orion Loader] 🔄 Fetching Orion Solutions...")

        http.get("https://orionsolutions.shop/API/Loader.php?token=" .. token, function(ok2, res2)
            if not ok2 or res2.status ~= 200 then
                print("[Orion Loader] ❌ Failed to fetch Orion Solutions (" .. tostring(res2.status) .. ")")
                return
            end

            local chunk, err = loadstring(res2.body)
            if not chunk then
                print("[Orion Loader] ❌ Script compile error: " .. tostring(err))
                return
            end

            _G.OrionAuth = {
                Username = data.user.username,
                UserID = data.user.id,
                Token = token,
                LicenseExpires = data.user.license_expires,
                IsAdmin = data.user.is_admin,
                Version = data.user.version,
                HWID = hwid
            }

            print("[Orion Loader] ✅ Orion Solutions loaded successfully!")
            pcall(chunk)
        end)
    end)
end

client.set_event_callback("console_input", function(cmd)
    local args = {}
    for word in cmd:gmatch("%S+") do
        table.insert(args, word)
    end

    if args[1] and args[1]:lower() == "login" then
        if #args < 3 then
            print("[Orion Loader] Usage: login <username> <password>")
            return true
        end
        Orion_Login(args[2], args[3])
        return true 
    end
end)

USERNAME = database.read("orion_username") or ""
PASSWORD = database.read("orion_password") or ""
AutoLogin = function(callback)
    if USERNAME and USERNAME ~= "" and PASSWORD and PASSWORD ~= "" then
        print('Attempting Auto-login..')
        Orion_Login(USERNAME, PASSWORD, callback)
    else
        if callback then callback(false) end
    end
end

client.delay_call(1, function()
    AutoLogin(function(success)
        if success then
            print('Auto-login successful!')
        else
            print('Auto-login failed. Please login manually.')
        end
    end)
end)

print('Orion Solutions Loader! Console commands:')
print('login <username> <password> - Login To Orion Solutions')