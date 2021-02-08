local Settings = {}
print("[gmpl] Init settings")

local admin_server_access = true
local admin_dir_access = false

function init()
    return _G.shared_settings
end

function Settings:set_admin_server_access(bVal)
    admin_server_access = bVal
end

function Settings:set_admin_dir_access(bVal)
    admin_dir_access = bVal
end

function Settings:get_admin_server_access()
    return admin_server_access
end

function Settings:get_admin_dir_access()
    return admin_dir_access
end

_G.shared_settings = Settings

return _G.shared_settings