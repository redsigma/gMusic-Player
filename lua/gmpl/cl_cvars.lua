/*
    Convars that update at client side
*/

local dermaBase = {}

local function init(baseMenu)
	dermaBase = baseMenu
end
-------------------------------------------------------------------------------
/*
    Use gm_showspare1 to toggle the music player
    note: won't apply if the key is binded directly to F3
*/
net.Receive("sv_keypress_F3", function(length, sender)
    if !IsValid(dermaBase.hotkey) then return end

	if !dermaBase.hotkey:GetChecked() then
		net.Start("sv_gmpl_show")
		net.SendToServer()
    elseif input.LookupKeyBinding(KEY_F3) == "gmplshow" then
        return
	end
end )

/*
    Used to update the server settings from first admin that it's connected
    Must run only once for the first admin to grab the values from him
*/
net.Receive("cl_update_cvars_from_first_admin", function()
    print("Getting settings from first admin")
    if IsValid(LocalPlayer()) and LocalPlayer():IsAdmin() then
		local settings = {}
		settings.admin_server_access = GetConVar("gmpl_svadminplay"):GetBool()
        settings.admin_dir_access = GetConVar("gmpl_svadmindir"):GetBool()

		net.Start("sv_update_cvars_from_first_admin")
		net.WriteTable(settings)

        net.WriteTable(dermaBase.song_data.get_left_song_list())
        net.WriteTable(dermaBase.song_data.get_right_song_list())
		net.SendToServer()
	end
end)

/*
    Used for each client to update the server cvars
*/
net.Receive("cl_update_cvars", function()
    local admin_server_access = net.ReadBool()
    local admin_dir_access = net.ReadBool()
    local songs_inactive = net.ReadTable()
    local songs_active = net.ReadTable()

    dermaBase.cbadminaccess:SetChecked(admin_server_access)
    dermaBase.cbadminaccess:RefreshConVar()

    dermaBase.cbadmindir:SetChecked(admin_dir_access)
    dermaBase.cbadmindir:RefreshConVar()

    shared_settings:set_admin_server_access(admin_server_access)
	shared_settings:set_admin_dir_access(admin_dir_access)

    -- print("Settings settings from server")
    -- PrintTable(songs_inactive)
    -- PrintTable(songs_active)
    dermaBase.foldersearch:UpdateMusicDir(songs_inactive, songs_active)
end)

/*
    Triggered after an admin changes the shared settings
*/
net.Receive("refreshAdminAccess", function(length, sender)
	local admin_only = net.ReadBool()
    -- print("Received admin server access:", admin_only)
    dermaBase.cbadminaccess:SetChecked(admin_only)
    dermaBase.cbadminaccess:RefreshConVar()
    shared_settings:set_admin_server_access(bVal)
end)
net.Receive("refreshAdminAccessDir", function(length, sender)
	local admin_only = net.ReadBool()
    -- print("Received music dir:", admin_only)
    dermaBase.cbadmindir:SetChecked(admin_only)
    dermaBase.cbadmindir:RefreshConVar()
    shared_settings:set_admin_dir_access(bVal)
end)


return init