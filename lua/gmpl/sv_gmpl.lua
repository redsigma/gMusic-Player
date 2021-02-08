/*
    Handles server related events such as server-side music
*/

include("includes/modules/coms.lua")
local liveSong = ""
local liveSongIndex = 0
local liveSeek = 0
/*
    Check if looping is enabled
*/
local isLooped = false
/*
    Check if auto playing is enabled
*/
local isAutoPlayed = false
/*
    Check if song is paused
*/
local isPaused = false

/*
    Check if song is stopped
*/
local isStopped = true

local userWantLive = 0
/*
    Store the player that is currently playing on server
*/
local playerHost = 0

--[[-------------------------------------------------------------------------
Tables used for adminAccessDir = true
-------------------------------------------------------------------------]]--
local folderInactiveTable = {}
local folderActiveTable = {}

--[[-------------------------------------------------------------------------
Server Settings
-------------------------------------------------------------------------]]--
local server_has_started = false
local shared_settings = nil

local function initial_spawn(ply)
    print("Inittial spawn run...")
	net.Start("cl_gmpl_create")
	net.Send(ply)

    if istable(shared_settings) then
        net.Start("cl_update_cvars")
        net.WriteBool(shared_settings:get_admin_server_access())
        net.WriteBool(shared_settings:get_admin_dir_access())
        net.WriteTable(folderInactiveTable)
        net.WriteTable(folderActiveTable)
    else
        net.Start("cl_update_cvars_from_first_admin")
    end
    net.Send(ply)
end

net.Receive("sv_update_cvars_from_first_admin", function(length, sender)
	local settings = net.ReadTable()
    shared_settings = include("includes/func/settings.lua")
	shared_settings:set_admin_server_access(settings.admin_server_access)
	shared_settings:set_admin_dir_access(settings.admin_dir_access)
	server_has_started = true

    local inactive_dirs = net.ReadTable()
    local active_dirs = net.ReadTable()

	if table.IsEmpty(inactive_dirs) && table.IsEmpty(active_dirs) then
        return
    end

    folderInactiveTable = inactive_dirs
    folderActiveTable = active_dirs

    -- print("\n Server]] Inactive songs:")
    -- PrintTable(folderInactiveTable)
    -- print("\n Server]] Active songs:")
    -- PrintTable(folderActiveTable)



    -- // On Server first start
    -- local sql_result = nil
    -- sql.Query("DROP TABLE gmpl_music")

    -- if sql.TableExists("gmpl_music") then
    --     sql_result = sql.Query("DROP TABLE gmpl_music")
    --     print("Table exists. Droping...")
    --     if (sql.TableExists("gmpl_music")) then
    --         PrintMessage(HUD_PRINTCONSOLE,
    --             "[gMusic Player] Unhandled error code 2 |",
    --             sql.LastError(sql_result))
    --     end
    -- end
    -- sql_result = sql.Query("CREATE TABLE gmpl_music (music_folder varchar(255), active int)")
    -- if (sql.TableExists("gmpl_music")) then
    --     print("Created table gmpl_music on server")
    --     print(folderInactiveTable)
    --     for key, folder in pairs(folderInactiveTable) do
    --         sql.Query("INSERT INTO gmpl_music (`music_folder`, `active`)VALUES ('" .. sql.SQLStr(folder, true) .."', '0')")
    --     end
    --     print("Server print table:")
    --     PrintTable(sql.Query("SELECT * FROM gmpl_music"))
    -- else
    --     PrintMessage(HUD_PRINTCONSOLE,
    --         "[gMusic Player] Unhandled error code 3 |",
    --         sql.LastError(sql_result))
    -- end


end)

// On Player initial spawn
-------------------------------------------------------------------------------
hook.Add("Initialize", "checkUlib", function()
	if istable(hook.GetTable().ULibLocalPlayerReady) then
		print("[gMusic Player] Initializing - via Ulib")
		hook.Add("ULibLocalPlayerReady", "initPlayer", function(ply)
			initial_spawn(ply)
		end)
	else
		print("[gMusic Player] Initializing")
		hook.Add("PlayerInitialSpawn", "initPlayer", function(ply)
            initial_spawn(ply)
		end)
	end
end)
hook.Add("ShowSpare1", "openMenuF3", function( ply )
	net.Start("sv_keypress_F3")
	net.Send(ply)
end)
net.Receive("sv_gmpl_show", function(length, sender)
	if sender:IsValid() then
        net.Start("cl_gmpl_show")
        net.WriteType(playerHost)
        net.Send(sender)
	end
end)

// Settings Panel Options
-------------------------------------------------------------------------------
local function printMessage(nrMsg, sender, itemVal)
	local str
	if nrMsg == 1 then
		str = "Admin Access"
	elseif nrMsg == 2 then
		str = "Music Dir Access"
	end

	sender:PrintMessage(HUD_PRINTTALK, str .. " changed to " .. tostring(itemVal) .. " by " .. sender:Nick() )
end

net.Receive("sv_refresh_song_list", function(length, sender)
    print("[net] Refreshing song list")
	if sender:IsValid() then

        if shared_settings:get_admin_dir_access() then
            if !sender:IsAdmin() then return end
        end
        -- if sender:IsAdmin() then
        folderInactiveTable = net.ReadTable()
        folderActiveTable = net.ReadTable()

        -- print("\nServer changed server songs")
        -- print("inactive:")
        -- PrintTable(folderInactiveTable)
        -- print("active:")
        -- PrintTable(folderActiveTable)
        -- print("----------------------------")

        net.Start("cl_refresh_song_list")
        net.WriteTable(folderInactiveTable)
        net.WriteTable(folderActiveTable)

        sender:PrintMessage(HUD_PRINTTALK, "[gMusic Player] " ..
            sender:Nick() .. " has changed the song directories" )
        net.Send(player.GetAll())
        -- end
	end
end )

-- net.Receive("toServerUpdateSeek", function(length, sender )
-- 	if IsValid(userWantLive) && IsValid(userWantLive) then
-- 		liveSeek = net.ReadDouble()
-- 		net.Start("playLiveSeek")

-- 		net.WriteBool(isLooped)
-- 		net.WriteBool(isAutoPlayed)
-- 		net.WriteEntity(sender) -- the playerHost
-- 		net.WriteString(liveSong)
-- 		net.WriteDouble(liveSeek)

-- 		net.Send(userWantLive)
-- 	end
-- end )




net.Receive("sv_set_loop", function(length, sender)
	if !IsValid(sender) then return end

    isLooped = net.ReadBool()
    if isLooped then
        isAutoPlayed = false
    end
    net.Start("cl_set_loop")
    net.WriteBool(isLooped)
    net.Send(player.GetAll())
end)

net.Receive("sv_set_autoplay", function(length, sender)
	if !IsValid(sender) then return end

    isAutoPlayed = net.ReadBool()
    if isAutoPlayed then
        isLooped = false
    end
    net.Start("cl_set_autoplay")
    net.WriteBool(isAutoPlayed)
    net.Send(player.GetAll())
end)

net.Receive("sv_pause_live", function(length, sender)
	if !IsValid(sender) then return end
    local admin_only = shared_settings:get_admin_server_access()

    if shared_settings:get_admin_server_access() then
        if sender:IsAdmin() then
            isPaused = net.ReadBool()
            liveSeek = net.ReadDouble()
        end
    else
        isPaused = net.ReadBool()
        liveSeek = net.ReadDouble()
    end
    -- print("[SERVER] Server pause is:", isPaused)
    local has_player_host = IsEntity(playerHost) && playerHost:IsPlayer()
    -- if isPaused then
        net.Start("cl_pause_live")
        net.WriteBool(isPaused)
        -- net.WriteBool(isAutoPlayed)
        -- net.WriteBool(isLooped)
        -- net.WriteDouble(liveSeek)
        -- net.WriteString(liveSong)
        -- net.WriteUInt(liveSongIndex, 16)
        -- if has_player_host then
        --     net.WriteEntity(playerHost)
        -- end
        net.Send(player.GetAll())
    -- else
    --     if has_player_host then
    --         net.Start("cl_play_live_seek_from_host")
    --         net.WriteEntity(sender)
    --         net.Send(playerHost)
    --     end
    -- end

    -- net.Start("cl_pause_live")
    -- net.WriteBool(isPaused)
    -- net.Send(sender)
end)




/*
    Triggered when an admin plays song on server
*/
net.Receive("sv_play_live", function(length, sender)
    if !istable(shared_settings) then
        sender:PrintMessage(
            HUD_PRINTCONSOLE, "[gMusic Player] Unhandled error code 1")
        return
    end
    if !IsValid(sender) then return end

    if shared_settings:get_admin_server_access() then
        if sender:IsAdmin() then
            liveSong = net.ReadString()
            liveSongIndex = net.ReadUInt(16)
            playerHost = sender
            isPaused = false
            isStopped = false
        end
    else
        liveSong = net.ReadString()
        liveSongIndex = net.ReadUInt(16)
        playerHost = sender
        isPaused = false
        isStopped = false
    end

    net.Start("cl_play_live")
    net.WriteString(liveSong)
    net.WriteBool(isLooped)
    net.WriteBool(isAutoPlayed)
    net.WriteUInt(liveSongIndex, 16)
    if IsEntity(playerHost) && playerHost:IsPlayer() &&
        playerHost:IsConnected() then
        net.WriteEntity(playerHost)
    end
    net.Send(player.GetAll())
end)

/*
    Triggered when an admin stops song on server
*/
net.Receive("sv_stop_live", function(length, sender)
	if !IsValid(sender) then return end
    liveSong = ""
    liveSeek = 0
    playerHost = 0
    userWantLive = 0
    isLooped = false
    isAutoPlayed = false
    isPaused = false
    isStopped = true
    net.Start("cl_stop_live")
    net.SendOmit(sender)
end)

// Seek related sync
----------------------------------------------------------------------------



net.Receive("sv_set_seek", function(length, sender)
	liveSeek = net.ReadDouble()
	if IsValid(sender) then
		net.Start("cl_set_seek")
		net.WriteDouble(liveSeek)
		net.Send(player.GetAll())
	end
end)

// Sanity checks
----------------------------------------------------------------------------
-- /*
--     Updates the server side paused status
-- */
-- net.Receive("updateStatusPauseToServer", function(length, sender)
--     if !IsValid(sender) then return end
--     if shared_settings:get_admin_server_access() then
--         if sender:IsAdmin() then
--             isPaused = net.ReadBool()
--         end
--     else
--         isPaused = net.ReadBool()
--     end
--     print("---- [update] isPaused set to:", isPaused)
-- end)
/*
    Updates the server side seek time by grabing it from the current song host
    and sends it back to the user which asked
*/
net.Receive("sv_play_live_seek_from_host", function(length, sender)
    if !IsValid(sender) then return end

    -- print("--- [SERVER] Is paused:", isPaused)
    -- sender:PrintMessage(HUD_PRINTCONSOLE, "--- [SERVER] Is paused:" .. tostring(isPaused) )
    if isPaused then
        print("[net] sv is paused")
        net.Start("cl_pause_live")
        -- net.WriteString(liveSong)
        net.WriteBool(isPaused)
        net.Send(sender)
    else
        if IsEntity(playerHost) && playerHost:IsPlayer() then
            print("[net] play live from host")
            net.Start("cl_play_live_seek_from_host")
            net.WriteEntity(sender)
            net.Send(playerHost)
            -- Maybe add some OnDisconnect hook so if the playerhost disconnects
            -- then to make it nil
            -- Also if asking for liveSeek but playerHost is not longer here(it was before), so the text should be updated to no songs on server. HMM the net message when switching to Server Mode should handle this i think, so the problem remains if the admin disconnects while a song is playing or when the song ends hmm
        end
    end
end)
/*
    The actual update of the server side seek time
*/
net.Receive("sv_play_live_seek_for_user", function(length, sender)
    if !IsValid(sender) then return end
    local user_wants_live = net.ReadEntity()
    if shared_settings:get_admin_server_access() then
        if sender:IsAdmin() then
            liveSeek = net.ReadDouble()
        end
    else
        liveSeek = net.ReadDouble()
    end

    -- sender:PrintMessage(HUD_PRINTCONSOLE, "\n---[SERVER] user wants live:", user_wants_live, IsValid(user_wants_live))
    -- net.WriteEntity(playerHost)
    if !IsValid(user_wants_live) then return end
    net.Start("cl_play_live_seek")
    net.WriteDouble(liveSeek)
    net.WriteString(liveSong)
    net.WriteUInt(liveSongIndex, 16)
    net.WriteBool(isAutoPlayed)
    net.WriteBool(isLooped)
    net.Send(user_wants_live)

    -- print("---- [update-liveseek] liveSeek set to:", liveSeek)
    -- print("---- [update-liveseek] liveSong set to:", liveSong)
end)

/*
    Used for switching between client and server modes
    Clients can only live seek if only admins can play on server
*/
net.Receive("sv_play_live_seek", function(length, sender)
    if !IsValid(sender) then return end

    if shared_settings:get_admin_server_access() then
        if sender:IsAdmin() then
            liveSeek = net.ReadDouble()
            net.Start("cl_play_live_seek")
            net.WriteDouble(liveSeek)
            net.WriteString(liveSong)
            net.WriteUInt(liveSongIndex, 16)
            net.WriteBool(isAutoPlayed)
            net.WriteBool(isLooped)
            net.Send(sender)
        else
            if IsEntity(playerHost) && playerHost:IsPlayer() then
                net.Start("cl_play_live_seek_from_host")
                net.WriteEntity(sender)
                net.Send(playerHost)
            end
        end
    else
        liveSeek = net.ReadDouble()
        -- print("---- [askOrUpdate] liveSeek set to:", liveSeek)
        -- print("---- [askOrUpdate] liveSong set to:", liveSong)

        if #liveSong == 0 then return end
        net.Start("cl_play_live_seek")
        net.WriteDouble(liveSeek)
        net.WriteString(liveSong)
        net.WriteUInt(liveSongIndex, 16)
        net.WriteBool(isAutoPlayed)
        net.WriteBool(isLooped)
        net.Send(sender)
    end
end)

net.Receive("sv_refresh_song_state", function(length, sender)
    if !IsValid(sender) then return end

    -- sender:PrintMessage(HUD_PRINTCONSOLE, "---[SERVER] Song live:" .. liveSong)

    net.Start("cl_refresh_song_state")
    net.WriteBool(isPaused)
    net.WriteBool(isAutoPlayed)
    net.WriteBool(isLooped)
    net.WriteDouble(liveSeek)
    net.WriteString(liveSong)
    net.WriteUInt(liveSongIndex, 16)
    if isentity(playerHost) then
        sender:PrintMessage(HUD_PRINTCONSOLE, "---[SERVER] Writing playerHost" )
        net.WriteEntity(playerHost)
    end
    net.Send(sender)

    -- print("\n---- [request] user request song state")
end)

net.Receive("sv_update_song_state", function(length, sender)
    if !IsValid(sender) then return end
    print("[net] update sv states")
    if shared_settings:get_admin_server_access() then
        if sender:IsAdmin() then
            isPaused = net.ReadBool()
            isAutoPlayed = net.ReadBool()
            isLooped = net.ReadBool()
        end
    else
        isPaused = net.ReadBool()
        isAutoPlayed = net.ReadBool()
        isLooped = net.ReadBool()
    end
end)

-- net.Receive("sv_update_host", function(length, sender)
--     if !IsValid(sender) then return end

--     sender:PrintMessage(HUD_PRINTCONSOLE, "---[SERVER] Request playerHost")
--     net.Start("cl_update_host")
--     if isentity(playerHost) then
--         net.WriteEntity(playerHost)
--     end
--     net.Send(sender)
-- end)
