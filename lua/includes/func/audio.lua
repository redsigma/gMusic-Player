local cl_PlayingSong = nil
local sv_PlayingSong = nil

local local_player = LocalPlayer()
local missingSong = false
/*
    Used server-side by clients as a muted live-seek indicator
*/
local client_has_control = false
local sv_song_loaded = false

local prevSelection = 0
local currSelection = 1

local colPlay	= Color(0, 150, 0)
local colAPlay	= Color(70, 190, 180)
local colPause	= Color(255, 150, 0)
local colAPause	= Color(210, 210, 0)
local colLoop	= Color(0, 230, 0)
local colALoop	= Color(45,205,115)
local col404	= Color(240, 0, 0)
local colBlack 	= Color(0, 0, 0)
local colWhite 	= Color(255, 255, 255)

local dermaBase = {}
local action = {}
local breakOnStop = false
/*
    Used to prevent realtime hooks from running indefinitely
*/
local cl_think = false
local sv_think = false
/*
    Used to prevent autoplayed songs from changing indefinitely
    Used to check if constanting thinking is required on server side
*/
local think_autoplay = false
local title_status = ""
/*
    Current active song title
*/
local title_song = nil
/*
    Current song absolute path
*/
local absolute_path = nil
/*
    Stores the last played song from client and server
*/
local cl_song = nil
local sv_song = nil

/*
    Used for highlighting the playing line in the song list
*/
local cl_song_index = 1
local sv_song_index = 0
local cl_song_prev_index = 0
local sv_song_prev_index = 0

local cl_seek = 0
local sv_seek = 0

/*
    Stores the client-side autoplay and loop states
*/
local cl_isAutoPlaying = false
local cl_isLooped = false

/*
    Stores the server-side autoplay and loop states
*/
local sv_isAutoPlaying = false
local sv_isLooped = false

/*
    Stores client-side pause and stop states
*/
local cl_isPaused = false
local cl_isStopped = true

/*
    Stores server-side pause and stop states
*/
local sv_isPaused = false
local sv_isStopped = true
/*
    Indicates when the next autoplayed song can start
*/
local sv_AutoplayNext = false

/*
    Stores the previous server-side volume. Used as a fake stop
*/
local sv_prev_volume = 0

local function init(baseMenu)
	dermaBase = baseMenu
	return action
end

local function isCurrentMediaValid()
    if dermaBase.main.IsServerMode() then
        return IsValid(sv_PlayingSong)
    else
        return IsValid(cl_PlayingSong)
    end
end

local function isOtherMediaValid()
    if dermaBase.main.IsServerMode() then
        return IsValid(cl_PlayingSong)
    else
        return IsValid(sv_PlayingSong)
    end
end

local function getMedia()
    if dermaBase.main.IsServerMode() then
	    return sv_PlayingSong
    else
	    return cl_PlayingSong
    end
end

local function isThinking()
    if dermaBase.main.IsServerMode() then
        return sv_think
    else
        return cl_think
    end
end

local function enableTSS()
    if !dermaBase.main:IsTSSEnabled() then
		dermaBase.main:SetTSSEnabled(true)
	end
end

local function disableTSS()
	if dermaBase.main:IsTSSEnabled() then
		dermaBase.main:SetTSSEnabled(false)
		dermaBase.contextmedia:SetTSS(false)
	end

    local prev_selection = 0
    local curr_selection = 0
    if dermaBase.main.IsServerMode() then
        prev_selection = sv_song_prev_index
        curr_selection = sv_song_index
    else
        prev_selection = cl_song_prev_index
        curr_selection = cl_song_index
    end
	if IsValid(dermaBase.songlist:GetLines()[prev_selection]) then
		dermaBase.songlist:HighlightLine(curr_selection, false, false)
	end
end

local function updateTitleSong(status, songFilePath)
    if songFilePath == false then
        dermaBase.main:SetText(" gMusic Player")
        dermaBase.main:SetTSSEnabled(false)
        dermaBase.contextmedia:SetTextColor(colBlack)
        dermaBase.contextmedia:SetText(false)
        disableTSS()
        return ""
    else
        enableTSS()
        if status == false then
            title_status = " Not On Disk: "
            dermaBase.main:SetBGColor(col404)
            dermaBase.contextmedia:SetTextColor(col404)
            dermaBase.contextmedia:SetMissing(true)
            missingSong = true
            MsgC(Color(100, 200, 200), "[gMusic Player]",
                Color(255, 255, 255),
                " Song file missing:\n> ", songFilePath, "\n")
        end

        if songFilePath then
            title_song =
                string.StripExtension(string.GetFileFromFilename(songFilePath))
            dermaBase.main:SetText(title_status .. title_song)
            dermaBase.contextmedia:SetText(title_song)
            absolute_path = songFilePath
        end
        return title_song
    end
end

local function updateListSelection(color, textcolor, is_server_mode)
    if is_server_mode then
        -- if it cant find the song number then better not bother coloring
        if IsValid(dermaBase.songlist:GetLines()[sv_song_index]) then
            dermaBase.songlist:HighlightLine(sv_song_index, color, textcolor)
        end
        if IsValid(dermaBase.songlist:GetLines()[sv_song_prev_index]) &&
            sv_song_prev_index != sv_song_index then
            dermaBase.songlist:HighlightLine(sv_song_prev_index, false, false)
        end
        if (cl_song_index != sv_song_index) then
            dermaBase.songlist:HighlightLine(cl_song_index, false, false)
        end
        sv_song_prev_index = sv_song_index
    else
        -- if it cant find the song number then better not bother coloring
        if IsValid(dermaBase.songlist:GetLines()[cl_song_index]) then
            dermaBase.songlist:HighlightLine(cl_song_index, color, textcolor)
        end
        if IsValid(dermaBase.songlist:GetLines()[cl_song_prev_index]) &&
            cl_song_prev_index ~= cl_song_index then
            dermaBase.songlist:HighlightLine(cl_song_prev_index, false, false)
        end
        if (cl_song_index != sv_song_index) then
            dermaBase.songlist:HighlightLine(sv_song_index, false, false)
        end
        cl_song_prev_index = cl_song_index
    end
end

local function updateTitleColor(status, song_filepath)
    local is_server_mode = dermaBase.main.IsServerMode()
    local color_bg = Color(150, 150, 150)
    local color_text = colWhite
    if status == 1 then
        if cl_isAutoPlaying || (is_server_mode && sv_isAutoPlaying) then
            title_status = " Auto Playing: "
            color_bg = colAPlay
            color_text = colBlack
        else
            title_status = " Playing: "
            color_bg = colPlay
            color_text = colWhite
        end
    elseif status == 2 then
        title_status = " Paused: "
        if is_server_mode then
            if shared_settings:get_admin_server_access() then
                if client_has_control then
                    color_bg = colAPause
                    color_text = colBlack
                else
                    color_bg = colPause
                    color_text = colBlack
                end
            else
                color_bg = colPause
                color_text = colBlack
            end
        else
            color_bg = colPause
            color_text = colBlack
        end
    elseif status == 3 then
        title_status = " Looping: "
        color_bg = colLoop
        color_text = colBlack
    end
    updateListSelection(color_bg, color_text, is_server_mode)
    dermaBase.main:SetBGColor(color_bg)
    dermaBase.main:SetTextColor(color_text)
    dermaBase.contextmedia:SetTextColor(color_bg)
    return updateTitleSong(status, song_filepath)
end

local function forced_loop(bool, is_server_mode)
    if !isCurrentMediaValid() then return end
    if !isbool(is_server_mode) then
        is_server_mode = dermaBase.main.IsServerMode()
    end

    local media = getMedia()
    media:EnableLooping(bool)
    if is_server_mode then
        sv_isLooped = bool
        sv_isAutoPlaying = false
        think_autoplay = false
    else
        cl_isLooped = bool
        cl_isAutoPlaying = false
    end
end
local function forced_autoplay(bool, is_server_mode)
    if !isCurrentMediaValid() then return end
    if !isbool(is_server_mode) then
        is_server_mode = dermaBase.main.IsServerMode()
    end

    local media = getMedia()
    media:EnableLooping(false)
    if is_server_mode then
        sv_isLooped = false
        sv_isAutoPlaying = bool
    else
        cl_isLooped = false
        cl_isAutoPlaying = bool
    end
end

/*
    Kill the client audio object
*/
local function kill_cl_song()
    if !IsValid(cl_PlayingSong) then return end

    cl_PlayingSong:Stop()
    cl_PlayingSong = nil
    cl_isStopped = true
    cl_isPaused = false
    timer.Stop("gmpl_cl_guard")
end
/*
    Server audio object needs to live for autoplay to work
*/
local function mute_sv_song()
    if !IsValid(sv_PlayingSong) then return end
    -- sv_PlayingSong:Stop()
    sv_prev_volume = sv_PlayingSong:GetVolume()
    sv_PlayingSong:SetVolume(0)
    -- sv_PlayingSong = nil
    -- sv_isPaused = false
    -- sv_isStopped = true
end
local function kill_song()
    if !isCurrentMediaValid() then return end

    if dermaBase.main.IsServerMode() then
        -- print("[core_kill] kill server")
        sv_PlayingSong:Stop()
        sv_PlayingSong = nil
        sv_isStopped = true
        sv_isPaused = false
        timer.Stop("gmpl_sv_guard")
    else
        -- print("[core_kill] kill client")
        cl_PlayingSong:Stop()
        cl_PlayingSong = nil
        cl_isStopped = true
        cl_isPaused = false
        timer.Stop("gmpl_cl_guard")
    end
end

local function updateAudioObject(CurrentSong, on_server)
	if !IsValid(CurrentSong) then return end

    if on_server then
        sv_PlayingSong = CurrentSong
        missingSong = false
    else
        cl_PlayingSong = CurrentSong
        missingSong = false
    end
end

-------------------------------------------------------------------------------
local function songLooped()
    if dermaBase.main.IsServerMode() then
        return sv_PlayingSong:IsLooping()
    else
        return cl_PlayingSong:IsLooping()
    end
end
local function sv_is_autoplay()
    return sv_isAutoPlaying
end
local function cl_is_autoplay()
    return cl_isAutoPlaying
end
local function songAutoPlay()
    if dermaBase.main.IsServerMode() then
        return sv_isAutoPlaying
    else
        return cl_isAutoPlaying
    end
end
local function songMissing() return missingSong end
local function songStopped()
    if dermaBase.main.IsServerMode() then
        return sv_isStopped
    else
        return cl_isStopped
    end
end
local function sv_is_pause()
    return sv_isPaused
end
local function cl_is_pause()
    return cl_isPaused
end
local function songPaused()
    if dermaBase.main.IsServerMode() then
        return sv_isPaused
    else
        return cl_isPaused
    end
end
local function songState() return getMedia():GetState() end
local function songLength() return getMedia():GetLength() end
local function songTime() return getMedia():GetTime() end
local function songServerTime()
    if IsValid(sv_PlayingSong) then
        return sv_PlayingSong:GetTime()
    end
    return 0
end
local function volumeState() return getMedia():GetVolume() end
local function songVol(time) getMedia():SetVolume(time) end
/*
    Used to allow clients to pause on server but only on their side
    Server songs will still be updated
*/
local function clientHasControl() return client_has_control end
local function clientSetControl(bool)
    client_has_control = bool
end

local function uiPlay()
	updateTitleColor(1, title_song)
end
local function uiPause()
	updateTitleColor(2, title_song)
end
local function uiLoop()
	updateTitleColor(3, title_song)
end
local function sv_tss_refresh()
    if sv_isPaused then
        updateTitleColor(2, title_song)
    elseif sv_isLooped then
        updateTitleColor(3, title_song)
    else
        updateTitleColor(1, title_song)
    end
end
local function uiTitle(song_path)
    updateTitleSong(true, song_path)
end

local function uiAPlay()
    if !isCurrentMediaValid() then return end
    local song_state = songState()

	if song_state == GMOD_CHANNEL_PLAYING then
		updateTitleColor(1, title_song)
	elseif song_state == GMOD_CHANNEL_PAUSED then
		updateTitleColor(2, title_song)
	end
end


local function playSong(song, song_index, is_autoplay, is_loop, seek)
    if isstring(song) then
        kill_song()
        sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
            if IsValid(CurrentSong) then
                cl_song = song
                cl_song_index = song_index
                // autoplay has priority
                -- print("recv loop, autoplay:", is_loop, is_autoplay)
                local is_looping = (is_loop || false)
                local is_autoplaying = (is_autoplay || false)
                if is_looping && is_autoplay then
                    is_looping = false
                end
                -- print("loop, autoplay after:", is_loop, is_autoplay)
                -- print("loop, autoplay sanity:", is_looping, is_autoplaying)
                CurrentSong:SetTime((seek || 0))
                CurrentSong:SetVolume(dermaBase.slidervol:GetValue() / 100)
                updateAudioObject(CurrentSong, false)
                if is_looping then
                    forced_loop(is_looping, false)
                    updateTitleColor(3, song)
                else
                    forced_autoplay(is_autoplaying, false)
                    updateTitleColor(1, song)
                end
                -- print("loop is:", CurrentSong:IsLooping())
                -- print("autoplay is:", isAutoPlaying)
                dermaBase.sliderseek:AllowSeek(true)
                dermaBase.sliderseek:SetMax(CurrentSong:GetLength())
                dermaBase.contextmedia:SetSeekLength(CurrentSong:GetLength())

                cl_PlayingSong:Play()
                cl_isPaused = false
                cl_isStopped = false
                mute_sv_song()
                -- if !dermaBase.main.IsServerMode() then
                    cl_think = true
                -- end
                timer.Start("gmpl_cl_guard")
            else
                updateTitleColor(false, song)
                dermaBase.sliderseek:ResetValue()
            end
        end)
    end
end
local function playSongServer(song, song_index, is_autoplay, is_loop, seek)
    if isstring(song) then
        kill_song()
        sv_song_loaded = false
        sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
            if IsValid(CurrentSong) then
                sv_song = song
                sv_song_index = song_index
                // autoplay has priority
                local is_looping = (is_loop || false)
                local is_autoplaying = (is_autoplay || false)
                if is_looping && is_autoplay then
                    is_looping = false
                end
                CurrentSong:SetTime((seek || 0))
                CurrentSong:SetVolume(dermaBase.slidervol:GetValue() / 100)
                updateAudioObject(CurrentSong, true)

                dermaBase.sliderseek:AllowSeek(true)
                dermaBase.sliderseek:SetMax(CurrentSong:GetLength())
                dermaBase.contextmedia:SetSeekLength(CurrentSong:GetLength())
                if is_looping then
                    forced_loop(is_looping, true)
                    if client_has_control then
                        updateTitleColor(2, song)
                        mute_sv_song()
                    else
                        updateTitleColor(3, song)
                    end
                else
                    forced_autoplay(is_autoplaying, true)
                    if client_has_control then
                        updateTitleColor(2, song)
                        mute_sv_song()
                    else
                        updateTitleColor(1, song)
                    end
                end
                sv_PlayingSong:Play()
                sv_isPaused = false
                sv_isStopped = false
                sv_AutoplayNext = false
                sv_prev_volume = 0
                kill_cl_song()
                sv_think = true
                timer.Start("gmpl_sv_guard")
            else
                updateTitleColor(false, song)
                dermaBase.sliderseek:ResetValue()
            end
        end)
        sv_song_loaded = true
    end
end

local function updateSongServer(song, song_index, is_autoplay, is_loop, seek)
    if isstring(song) then
        sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
            if IsValid(CurrentSong) then
                sv_song = song
                sv_song_index = song_index
                // autoplay has priority
                local is_looping = (is_loop || false)
                local is_autoplaying = (is_autoplay || false)
                if is_looping && is_autoplay then
                    is_looping = false
                end
                CurrentSong:SetTime((seek || 0))
                CurrentSong:SetVolume(0)
                updateAudioObject(CurrentSong, true)
                if is_looping then
                    forced_loop(is_looping, true)
                else
                    forced_autoplay(is_autoplaying, true)
                end
                if isnumber(seek) then
                    dermaBase.sliderseek:SetTime(seek)
                end
                sv_PlayingSong:Play()
                sv_isPaused = false
                sv_isStopped = false
                sv_AutoplayNext = false
                kill_cl_song()
                -- sv_think = true
            else
                updateTitleColor(false, song)
                dermaBase.sliderseek:ResetValue()
            end
        end)
    end
end

local function updateSongClient(song, song_index, is_autoplay, is_loop, seek)
    if isstring(song) then
        sound.PlayFile(song, "noblock noplay", function(CurrentSong, ErrorID, ErrorName)
            if IsValid(CurrentSong) then
                cl_song = song
                cl_song_index = song_index
                // autoplay has priority
                local is_looping = (is_loop || false)
                local is_autoplaying = (is_autoplay || false)
                if is_looping && is_autoplay then
                    is_looping = false
                end
                CurrentSong:SetTime((seek || 0))
                CurrentSong:SetVolume(0)
                updateAudioObject(CurrentSong, false)
                if is_looping then
                    forced_loop(is_looping, false)
                else
                    forced_autoplay(is_autoplaying, false)
                end

                cl_PlayingSong:Play()
                cl_isPaused = false
                cl_isStopped = false
                mute_sv_song()
                -- think = true
            else
                updateTitleColor(false, song)
                dermaBase.sliderseek:ResetValue()
            end
        end)
    end
end
/*
    Protect against seek burst which causes buffering block
*/
local function sv_buffer_guard()
    if IsValid(sv_PlayingSong) then
        if sv_PlayingSong:GetState() == GMOD_CHANNEL_STALLED then
            dermaBase.sliderseek:ReleaseSeek()
            dermaBase.sliderseek:AllowSeek(true)
            sv_PlayingSong:SetTime(sv_PlayingSong:GetTime() - 1)
            print("[sv_stall_stop] play song cuz stalled")
        end
    end
end
/*
    Protect against seek burst which causes buffering block
*/
local function cl_buffer_guard()
    if IsValid(cl_PlayingSong) then
        if cl_PlayingSong:GetState() == GMOD_CHANNEL_STALLED then
            dermaBase.sliderseek:ReleaseSeek()
            dermaBase.sliderseek:AllowSeek(true)
            cl_PlayingSong:SetTime(cl_PlayingSong:GetTime() - 1)
            print("[cl_stall_stop] play song cuz stalled")
        end
    end
end

local function playSongNext()
    local next_selection = cl_song_index + 1
    local song_list = dermaBase.song_data.get_current_list()
    print("[core-line] next selection:", next_selection)
    if next_selection > #song_list then
        next_selection = 1
    end
    if !dermaBase.main.IsServerMode() then
        playSong(song_list[next_selection], next_selection, true)
        cl_think = false
    else
        sv_think = false
    end


    dermaBase.songlist:SetSelectedLine(next_selection)
	-- if it cant find the song number then better not bother coloring
	-- if IsValid(dermaBase.songlist:GetLines()[currSelection]) then
	-- 	dermaBase.songlist:HighlightLine(currSelection, color, textcolor)
	-- 	if textcolor then
	-- 		dermaBase.main:SetTextColor(textcolor)
	-- 	end
end

-- local function playServerSongNext()
--     local next_selection = sv_song_index + 1
--     local song_list = dermaBase.song_data.get_current_list()
--     if next_selection > #song_list then
--         next_selection = 1
--     end
--     net.Start("sv_play_live")
--     net.WriteString(song_list[next_selection])
--     net.WriteUInt(next_selection, 16)
--     net.SendToServer()
--     dermaBase.songlist:SetSelectedLine(next_selection)
--     think = false
-- end

/*
    Used to keep track when the server song stopped in case autoplay is enabled
    Should no longer run if stopped
*/
local function checkServerStop()
    if sv_think && IsValid(sv_PlayingSong) then
        -- print("[think] think aplay is:", sv_think, think_autoplay)
        sv_isStopped = sv_PlayingSong:GetState() == GMOD_CHANNEL_STOPPED
        if sv_isStopped then
            // will swap flags because sv_think is set later in cl_play_live
            sv_think = false
            think_autoplay = true
        end
    end
end
/*
    Check next autoplayed song
    Works together with checkServerStop() in order to play only once
*/
local function serverAutoPlayThink()
    if shared_settings:get_admin_server_access() then
        if !local_player:IsAdmin() then return end
    end
    if !think_autoplay || !sv_isAutoPlaying then return end

    if sv_isStopped then
        think_autoplay = false
        local next_selection = sv_song_index + 1
        local song_list = dermaBase.song_data.get_current_list()
        if next_selection > #song_list then
            next_selection = 1
        end
        print("[core-svthink] autoplay on so play next", next_selection)
        net.Start("sv_play_live")
        net.WriteString(song_list[next_selection])
        net.WriteUInt(next_selection, 16)
        net.SendToServer()
        dermaBase.songlist:SetSelectedLine(next_selection)
    end
end

local function resumeSong(song, song_index)
	if title_song == song and !songStopped() then
		getMedia():Play()
        if dermaBase.main.IsServerMode() then
            sv_think = true
        else
            cl_think = true
        end
		if songLooped then
			updateTitleColor(3, song)
		else
			updateTitleColor(1, song)
		end
	else
		playSong(song, song_index)
	end
end

local function reset_ui()
    dermaBase.sliderseek:ResetValue()
    dermaBase.sliderseek:AllowSeek(false)
    updateTitleColor(false,false)
end

local function action_sv_pause(bool_pause)
    if sv_isStopped then return end
    if isbool(bool_pause) then
        // used as a setter
        sv_isPaused = !bool_pause
    end
    if sv_isPaused then
        sv_isPaused = false
        sv_PlayingSong:Play()
        sv_think = true
    else
        sv_isPaused = true
        sv_PlayingSong:Pause()
        sv_think = false
    end
end
local function action_cl_pause()
    if cl_isStopped then return end
    cl_isPaused = !cl_isPaused
    cl_PlayingSong:Pause()
    cl_think = false
    print("[cl_pause] song pause:", cl_isPaused)
end
local function action_sv_stop()
    if sv_isStopped then return end
    print("[sv_stop] stop song")

    reset_ui()
    title_song = nil
    client_has_control = false
    if IsValid(sv_PlayingSong) then
        sv_PlayingSong:Pause()
    end
    sv_song = nil
    sv_isStopped = true
    sv_isPaused = false
    think_autoplay = false
    sv_AutoplayNext = true
    sv_think = false
    timer.Stop("gmpl_sv_guard")
end
local function action_cl_stop()
    if cl_isStopped then return end
    print("[cl_stop] stop song")

    reset_ui()
    title_song = nil
    if IsValid(cl_PlayingSong) then
        cl_PlayingSong:Pause()
    end
    cl_song = nil
    cl_isStopped = true
    cl_isPaused = false
    cl_think = false
    timer.Stop("gmpl_cl_guard")
end



local function updateAudioStates(in_server_mode)

    if !isbool(in_server_mode) then return end
    print("\n")
    -- print("[core-states] client loop, autoplay:", cl_isLooped, cl_isAutoPlaying)
    -- print("[core-states] server loop, autoplay:", sv_isLooped, sv_isAutoPlaying)
    if in_server_mode then
        -- print("[core_svstates] song:", sv_song)
        if isOtherMediaValid() then
            print("[core_svstates] muting client")
            cl_seek = cl_PlayingSong:GetTime()
            kill_cl_song()
        end

        if isstring(sv_song) then
            dermaBase.main:SetTitleServerState(true)
            dermaBase.contextmedia:SetTSS(true)
            title_song = sv_song
            // update server side seek and also live seek from it

            -- if !client_has_control then
                net.Start("sv_play_live_seek")
                net.WriteDouble(songServerTime())
                net.SendToServer()
            -- end
            if sv_prev_volume != 0 then
                sv_PlayingSong:SetVolume(sv_prev_volume)
            end

            if sv_isStopped || client_has_control then return end
            -- print("[core-states] is loop, autoplay:", getMedia():IsLooping(), songAutoPlay())
            if songLooped() then
                updateTitleColor(3, title_song)
            else
                updateTitleColor(1, title_song)
            end
        else
            action_sv_stop()
            reset_ui()
        end
    else
        -- print("[core_clstates] song:", cl_song)
        if isOtherMediaValid() then
            print("[core_clstates] muting server")
            sv_seek = sv_PlayingSong:GetTime()
            mute_sv_song()
        end

        if isstring(cl_song) then
            dermaBase.main:SetTitleServerState(false)
            dermaBase.contextmedia:SetTSS(false)
            title_song = cl_song
            playSong(
                cl_song, cl_song_index, cl_isAutoPlaying, cl_isLooped, cl_seek)

            if cl_isStopped then return end
            -- print("[core-states] is loop, autoplay:",
                -- getMedia():IsLooping(), songAutoPlay())
            if songLooped() then
                updateTitleColor(3, title_song)
            else
                updateTitleColor(1, title_song)
            end
        else
            action_cl_stop()
            reset_ui()
        end
    end
end

local function pauseOnPlay()
    if !isCurrentMediaValid() then return end

    if dermaBase.main.IsServerMode() then
        if sv_PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
            sv_PlayingSong:Pause()
            sv_isPaused = true
            sv_isStopped = false
            sv_AutoplayNext = false
        end
    else
        if cl_PlayingSong:GetState() == GMOD_CHANNEL_PLAYING then
            cl_PlayingSong:Pause()
            cl_isPaused = true
            cl_isStopped = false
        end
    end
end

local function forcedPause(bool_pause)
	if !isCurrentMediaValid() then return end

    local is_server_mode = dermaBase.main.IsServerMode()
    local media = getMedia()

    if bool_pause then
        media:Pause()
        if is_server_mode then
            sv_isPaused = true
            sv_isStopped = false
            sv_AutoplayNext = false
        else
            cl_isPaused = true
            cl_isStopped = false
        end
        updateTitleColor(2, title_song)
    elseif !bool_pause and !cl_isStopped then
        media:Play()
        if is_server_mode then
            sv_isPaused = false
            sv_isStopped = false
            sv_AutoplayNext = false
        else
            cl_isPaused = false
            cl_isStopped = false
        end

        if media:IsLooping() then
            updateTitleColor(3, title_song)
        else
            updateTitleColor(1, title_song)
        end
    end
end

local function forcedStop(bool_stop)
    if !isCurrentMediaValid() then return end

    if dermaBase.main.IsServerMode() then
        sv_isStopped = bool_stop
        sv_AutoplayNext = bool_stop
        timer.Stop("gmpl_sv_guard")
    else
        cl_isStopped = bool_stop
        timer.Stop("gmpl_cl_guard")
    end
end

local function actionPauseL()
	if !isCurrentMediaValid() then return end
    local media = getMedia()

    if media:GetState() == GMOD_CHANNEL_PLAYING then
        pauseOnPlay()
        updateTitleColor(2, title_song)
    elseif media:GetState() == GMOD_CHANNEL_PAUSED and !songStopped() then
        media:Play()
        if dermaBase.main.IsServerMode() then
            sv_isPaused = false
            sv_isStopped = false
            sv_AutoplayNext = false
        else
            cl_isPaused = false
            cl_isStopped = false
        end

        if media:IsLooping() then
            updateTitleColor(3, title_song)
        else
            updateTitleColor(1, title_song)
        end
    end
end

local function actionPauseR()
    local media = getMedia()
	if IsValid(media) and media:GetState() == GMOD_CHANNEL_PLAYING then
		if media:IsLooping() then
            forced_loop(false)
			updateTitleColor(1, title_song)
		else
            forced_loop(true)
			updateTitleColor(3, title_song)
		end
	end
end

local function actionAutoPlay()
    local media = getMedia()
    print("[core-autoplay] set auto play to:", media)
	if IsValid(media) && media:GetState() == GMOD_CHANNEL_PLAYING then

		if songAutoPlay() then
            forced_autoplay(false)
		else
            forced_autoplay(true)
		end
        updateTitleColor(1, title_song)
	end
end

local function actionSeek(time)
    if !isCurrentMediaValid() then return end
    local media = getMedia()
    if media:GetState() != GMOD_CHANNEL_STALLED then
        media:SetTime(time)
    end
end

action.play			=	playSong
action.playNext     =   playSongNext
action.playServer	=	playSongServer
action.updateClient =   updateSongClient
action.updateServer =   updateSongServer
action.resume		=	resumeSong
action.sv_pause     =   action_sv_pause
action.cl_pause     =   action_cl_pause
action.sv_stop		=	action_sv_stop
action.cl_stop		=	action_cl_stop
action.sv_buffer_guard = sv_buffer_guard
action.cl_buffer_guard = cl_buffer_guard

action.pauseOnPlay  =   pauseOnPlay
action.pause		=	actionPauseL
action.loop			=	actionPauseR
action.autoplay     =   actionAutoPlay
action.setpause     =   forcedPause
action.setstop      =   forcedStop
action.setloop		=	forced_loop
action.setautoplay	=	forced_autoplay
action.seek			=	actionSeek
action.volume		=	songVol
action.clientHasControl = clientHasControl
action.clientControl = clientSetControl
action.muteServer   =  mute_sv_song

action.reset_ui		= 	reset_ui
action.kill			= 	kill
action.update		=	updateAudioObject
action.updateStates =   updateAudioStates
action.getTime		=	songTime
action.get_song_len =   songLength
action.getServerTime =	songServerTime
action.getVolume	=	volumeState

action.isMissing	=	songMissing
action.isLooped		=	songLooped
action.sv_is_autoplay = sv_is_autoplay
action.cl_is_autoplay = cl_is_autoplay
action.isAutoPlayed	=	songAutoPlay

action.hasValidity 	=	isCurrentMediaValid
action.hasState 	=	songState
action.isStopped    =   songStopped
action.sv_is_pause  =   sv_is_pause
action.cl_is_pause  =   cl_is_pause
action.isPaused     =   songPaused

action.uiPlay 		= 	uiPlay
action.uiPause      =   uiPause
action.uiAutoPlay 	= 	uiAPlay
action.uiLoop 		= 	uiLoop
action.sv_uiRefresh =   sv_tss_refresh
action.uiTitle      =   uiTitle

action.colorLoop	= 	colLoop
action.colorPause	= 	colPause
action.colorPlay	= 	colPlay
action.colorMissing =	col404

action.breakOnStop	=	breakOnStop
action.isThinking   =	isThinking
action.checkServerStop = checkServerStop
action.serverAutoPlayThink = serverAutoPlayThink

return init
