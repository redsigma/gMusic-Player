local local_player = LocalPlayer()
local dermaBase = {}

Media = {}
Media.__index = Media

/*
    List of audio files in the song list
*/
-- local populatedSongs = {}

function Media:new(coreBase)
	dermaBase = coreBase
	local MediaPlayer = setmetatable({}, Media)

	local action = include("includes/func/audio.lua")(dermaBase)
	for k,v in pairs(action) do
        self[k] = v
    end
	return MediaPlayer
end
setmetatable(Media, {  __call = Media.new })

function Media:ToggleListenUI()
    if !dermaBase.main.IsServerMode() then return end

    if local_player:IsAdmin() then
        dermaBase.buttonplay:SetText("Play / AutoPlay")
        dermaBase.buttonpause:SetText("Pause / Loop")
        dermaBase.buttonstop:SetVisible(true)
        dermaBase.buttonswap:SetVisible(false)
    else
        dermaBase.buttonplay:SetText("Resume Live")
        dermaBase.buttonpause:SetText("Pause")
        dermaBase.buttonstop:SetVisible(false)
        dermaBase.buttonswap:SetVisible(true)
    end
end

function Media:ToggleNormalUI()
    dermaBase.buttonplay:SetText("Play / AutoPlay")
    dermaBase.buttonpause:SetText("Pause / Loop")
    dermaBase.buttonstop:SetVisible(true)
    dermaBase.buttonswap:SetVisible(false)
end

function Media:ToggleListenUI()
    dermaBase.buttonplay:SetText("Resume Live")
    dermaBase.buttonpause:SetText("Pause")
    dermaBase.buttonstop:SetVisible(false)
    dermaBase.buttonswap:SetVisible(true)
end
-----------------------------------------------------------------------------
local function song_host_disconnected(ply)
    dermaBase.labelswap:SetText(
        "Unavailable: " .. dermaBase.interface.get_song_host())
    ply:PrintMessage(HUD_PRINTCONSOLE, "[gMusic Player] Cannot get Live Song. The host disconnected or it's no longer admin.")
end
-----------------------------------------------------------------------------
local think_indicator = vgui.Create("Panel")
think_indicator:SetSize(50,50)
think_indicator:AlignTop()
think_indicator:SetPos(10,0)
think_indicator.Paint = function(self, w, h)
    surface.SetDrawColor(255,0,0,255)
    surface.DrawRect(0,0,w,h)
end

function Media:real_time_seek()
    -- i moved the populatedSongs to meth_songs so change this
    Media.serverAutoPlayThink()

    if !Media.hasValidity() then return end

	-- if !Media.breakOnStop && Media.hasState() == GMOD_CHANNEL_STOPPED then
	-- 	if Media.isAutoPlay() then
	-- 		if dermaBase.main.IsServerMode() then
	-- 			if dermaBase.cbadminaccess:GetChecked() then
	-- 				if local_player:IsAdmin() then
	-- 					print("stopsmart---- checked IS admin ")
	-- 					Media.stopsmart()
	-- 				else
	-- 					print("stopsmart---- checked NOT admin ")
	-- 					-- gather next song from admin
	-- 					net.Start("sv_getAutoPlaySong")
	-- 					net.SendToServer()
	-- 				end
	-- 			else --aaccess off
	-- 				print("stopsmart---- NOT checked ")
	-- 				Media.stopsmart()
	-- 			end
	-- 		else -- not server
	-- 			print("stopsmart---- NOT on server")
	-- 			Media.stopsmart()
	-- 		end
	-- 	else
	-- 		print("stopsmart---- STOP no autoplay")
	-- 		Media.stop()
	-- 	end
	-- 	Media.breakOnStop = true
	-- end

    // client side
	if dermaBase.main:IsVisible() then
        if !Media.isThinking() then
            think_indicator:Hide()
            return
        end
        think_indicator:Show()
        if Media.hasState() == GMOD_CHANNEL_STALLED then
            -- print("[think] stalled retry")
            -- Media.retry()
            return
        end

        if !Media.isStopped() || Media.hasState() == GMOD_CHANNEL_PLAYING ||
            Media.clientHasControl() then
            if Media.hasState() == GMOD_CHANNEL_STOPPED then
                Media.setstop(true)
            else
                dermaBase.sliderseek:AllowSeek(true)
                dermaBase.sliderseek:SetTime(Media.getTime())
            end
        elseif Media.isLooped() then
            // restart if
            dermaBase.sliderseek:AllowSeek(true)
            dermaBase.sliderseek:SetTime(dermaBase.sliderseek:GetMin())
        elseif Media.isAutoPlayed() then
            print("Media is autoplayed so play next song")

            Media.playNext()
        else
            print("AUDIO STOPPED v2")
            if dermaBase.main.IsServerMode() then
                Media.sv_stop()
                net.Start("sv_stop_live")
                net.SendToServer()
            else
                Media.cl_stop()
            end
        end
	end
end
hook.Add("Tick", "gmpl_RealTimePost", function()
    Media.checkServerStop()
end)




-- net.Receive("askAdminForLiveSeek", function(length, sender)
-- 	local user = net.ReadEntity()
-- 	if local_player:IsAdmin() then
-- 		local seekTime = 0

-- 		if Media.hasValidity() then
-- 			seekTime = Media.getServerTime()
-- 			songIndex = dermaBase.songlist:GetSelectedLine()
-- 			net.Start("toServerUpdateSeek")
-- 			net.WriteDouble(seekTime)
-- 			net.SendToServer()
-- 		else
-- 			user:PrintMessage(HUD_PRINTTALK, "[gMusic Player] No song is playing on the server")
-- 		end
-- 	else
-- 		song_host_disconnected(user)
-- 	end
-- end)

net.Receive("cl_stop_live", function(length, sender)
    print("[net] stop sv")
    Media.sv_stop()
    dermaBase.labelswap:SetText("No song currently playing")
end)

net.Receive("cl_play_live", function(length, sender)
    local live_song = net.ReadString()
    if live_song then
        chat.AddText(Color(0,220,220), "Playing: " ..
            string.StripExtension(string.GetFileFromFilename(live_song)))
    end
    print("[net] play song")
    local is_looped = net.ReadBool()
    local is_autoplayed = net.ReadBool()
    local index_song = net.ReadUInt(16)
    local live_host = net.ReadEntity()
    dermaBase.interface.set_song_host(live_host)

    if dermaBase.main.IsServerMode() then
        -- dermaBase.set_server_TSS(true)
        -- Media.uiTitle(live_song)
        -- if !Media.clientHasControl() then
            print("[net] play sv song", index_song, live_song, "| loop:", is_looped, "| autoplay:", is_autoplayed)
            Media.playServer(live_song, index_song, is_autoplayed, is_looped)
        -- else
        --     print("[net] update ui seek")
        --     dermaBase.interface.refresh_seek()
        -- end
    else
        print("[net] update sv song", index_song, live_song, "| loop:", is_looped, "| autoplay:", is_autoplayed)
        Media.updateServer(live_song, index_song, is_autoplayed, is_looped)
    end

    -- this should be more like play song but muted
    -- if !Media.clientHasControl() then
    --     Media.playServer(live_song, index_song, is_autoplayed, is_looped)
    -- end
end)

net.Receive("cl_set_loop", function(length, sender)
	if !Media.hasValidity() || !dermaBase.main.IsServerMode() then return end

    local is_looped = net.ReadBool()
    Media.setloop(is_looped)
    if Media.hasState() == GMOD_CHANNEL_PLAYING then
        if is_looped then
            Media.uiLoop()
        elseif Media.isAutoPlayed() then
            Media.uiAutoPlay()
        else
            Media.uiPlay()
        end
    end
end)

net.Receive("cl_set_autoplay", function(length, sender)
	if !Media.hasValidity() || !dermaBase.main.IsServerMode() then return end

    local is_autoplayed = net.ReadBool()
    print("[net] sv autoplay:", is_autoplayed)
    Media.setautoplay(is_autoplayed)
    if Media.clientHasControl() then return end

    if Media.hasState() == GMOD_CHANNEL_PLAYING then
        if is_autoplayed then
            Media.uiAutoPlay()
        elseif Media.isLooped() then
            Media.uiLoop()
        else
            Media.uiPlay()
        end
    end
end)

net.Receive("cl_pause_live", function(length, sender)
    if !dermaBase.main.IsServerMode() then return end
    -- local live_song = net.ReadString()
    -- Media.uiTitle(live_song)

    -- if Media.clientHasControl() then return end
    local is_server_pause = net.ReadBool()
    print("[net] sv pause:",is_server_pause)
    if local_player:IsAdmin() then
        print("[net] pause sv:", is_server_pause)
        Media.sv_pause()
        Media.sv_uiRefresh()
        net.Start("sv_update_song_state")
        net.WriteBool(Media.isPaused())
        net.WriteBool(Media.isAutoPlayed())
        net.WriteBool(Media.isLooped())
        net.SendToServer()
    else
        if is_server_pause then
            Media.sv_pause(is_server_pause)
            Media.sv_uiRefresh()
        else
            net.Start("sv_play_live_seek_from_host")
            net.SendToServer()
        end
    end
    -- if is_server_pause then
    --     Media.uiPause()
    -- else
    --     Media.uiP
    -- end



    -- if is_server_paused then
    --     -- if Media.hasValidity() then
    --     --     Media.setpause(is_server_paused)
    --     -- else
    --     net.Start("sv_refresh_song_state")
    --     net.SendToServer()
    --     -- end
    -- else
    --     net.Start("sv_play_live_seek_from_host")
    --     net.SendToServer()
    -- end
end)


net.Receive("cl_play_live_seek_from_host", function(length, sender)
	local user = net.ReadEntity()
	if local_player:IsAdmin() then
        print("[net] play live for user:", user)
		if Media.hasValidity() then
			net.Start("sv_play_live_seek_for_user")
            net.WriteEntity(user)
			net.WriteDouble(Media.getServerTime())
			net.SendToServer()
		else
			user:PrintMessage(HUD_PRINTTALK, "[gMusic Player] No song is playing on the server")
		end
	else
        song_host_disconnected(user)
	end
end)
net.Receive("cl_play_live_seek", function(length, sender)
    if !dermaBase.main.IsServerMode() then return end
    -- dermaBase.set_server_TSS(true)
    local live_seek = net.ReadDouble()
    local live_song = net.ReadString()
    local live_song_index = net.ReadUInt(16)
    local is_autoplayed = net.ReadBool()
    local is_looped = net.ReadBool()

    print("[net] seek sv song:", live_song_index, live_seek, "| loop:", is_looped, "| autoplay:", is_autoplayed)
    -- Media.clientControl(false)
    Media.playServer(
        live_song, live_song_index, is_autoplayed, is_looped, live_seek)
end)

net.Receive("cl_refresh_song_state", function(length, sender)
    local is_paused = net.ReadBool()
    local is_autoplayed = net.ReadBool()
    local is_looped = net.ReadBool()
    local live_seek = net.ReadDouble()
    local live_song = net.ReadString()
    local live_song_index = net.ReadUInt(16)
    local live_host = net.ReadEntity()

    print("[net] update state| loop:", is_looped, "| autoplay:", is_autoplayed, "| pause:", is_paused)

    // sync with server only if needed
    -- if is_paused then
    --     Media.setpause(is_paused)
    -- elseif is_autoplayed then
    --     Media.setautoplay(is_autoplayed)
    --     Media.uiAutoPlay()
    -- elseif is_looped then
    --     Media.setloop(is_looped)
    --     Media.uiLoop()
    -- end

    if #live_song == 0 then
        if !dermaBase.main.playingFromAnotherMode() then
            Media.uiTitle(false)
        end
        Media.clientControl(false)
        dermaBase.labelswap:SetText("No song currently playing")
        return
    end

    print("[net] update sv song", live_song_index, live_song, "| loop:", is_looped, "| autoplay:", is_autoplayed)
    Media.updateServer(live_song, live_song_index, is_autoplayed, is_looped, live_seek)
    if is_paused then
        Media.sv_pause()
        Media.uiPause()
        -- Media.setpause(is_paused)
    end
    dermaBase.interface.set_song_host(live_host)
end)

-- net.Receive("cl_update_host", function(length, sender)
--     local live_host = net.ReadEntity()
--     print("[net] update host:", live_host)
--     dermaBase.interface.set_song_host(live_host)
-- end)



// TODO WORK ON adding the song table of the admin host on the server and tehn you just
//increment from that table the next song.
//If the same admin host tries to change the song check if it is the same admin and if not
//check if the song basename is the one he wants to play(the key probably wont be a good idea)
-- net.Receive( "cl_ansAutoPlaySong", function(length, sender)
-- 	local nextAutoPlayedSong = net.ReadString()
-- 	-- local currSong = populatedSongs[Media.songIndex(1, true)] or ""
-- 	Media.uiAutoPlay()
-- 	Media.playServer(nextAutoPlayedSong)
-- end)

net.Receive("cl_set_seek", function(length, sender)
	if dermaBase.main.IsServerMode() then
		local seekTime = net.ReadDouble()
		if Media.hasValidity() then
			Media.seek(seekTime)
		end
	end
end)

