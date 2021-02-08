/*
    Convars stored server side for updating each client
*/

-------------------------------------------------------------------------------
local function printMessage(nrMsg, sender, bVal)
	local str
    str = "[gMusic Player] " .. sender:Nick()
	if nrMsg == 1 then
        if bVal then
            str = str .. " restricted clients from playing on server";
        else
            str = str .. " allowed clients to play on server";
        end
	elseif nrMsg == 2 then
        if bVal then
            str = str .. " restricted clients from editing the song list";
        else
            str = str .. " allowed clients to edit the song list";
        end
	end
	PrintMessage(HUD_PRINTTALK, str)

    -- print("\nshared settings sv_cvars:", shared_settings)
    -- PrintTable(shared_settings)
    -- print("admin_server_access = ", shared_settings:get_admin_server_access())
    -- print("admin_dir_access = ", shared_settings:get_admin_dir_access())
end
-------------------------------------------------------------------------------
/*
    Update Music Dir Access for each client
*/
net.Receive("toServerRefreshAccessDir", function(length, sender)
	if !IsValid(sender) then return end

    local bVal = net.ReadBool()
    if sender:IsAdmin() then
        shared_settings:set_admin_dir_access(bVal)
    end
    net.Start("refreshAdminAccessDir")
    net.WriteBool(shared_settings:get_admin_dir_access())
    printMessage(2, sender, bVal)
    net.Send(player.GetAll())
end)

/*
    Update shared settings for each client
*/
net.Receive("toServerRefreshAccess", function(length, sender)
    if !IsValid(sender) then return end

    local bVal = net.ReadBool()
    if sender:IsAdmin() then
        shared_settings:set_admin_server_access(bVal)
    end
    net.Start("refreshAdminAccess")
    net.WriteBool(shared_settings:get_admin_server_access())
    printMessage(1, sender, bVal)
    net.Send(player.GetAll())
end)