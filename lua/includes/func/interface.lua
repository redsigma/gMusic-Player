local cvarMediaVolume = CreateClientConVar("gmpl_vol", "100", true, false, "[gMusic Player] Sets the Volume of music player")

local interface = {}
local dermaBase = {}
local local_player = LocalPlayer()

/*
    Name of host that plays on server
*/
local server_song_host = ""
/*
    Parent anchors used for the main panel
*/
local view_ingame = nil
local view_context_menu = nil
/*
    Used to track if the player is in context menu
    note: IsWorldClicking() NOT reliable
*/
local is_context_open = false
/*
    Used to store the active anchor panel when the window is visible
*/
local anchor_parent = nil

local function init(baseMenu)
	dermaBase = baseMenu
	return interface
end

local function create_media_player()
	dermaBase.main:SetPos(16, 36)
	dermaBase.main:SetText(" gMusic Player")
	dermaBase.main:SetDraggable(true)
	dermaBase.main:SetSizable(true)

	dermaBase.contextmedia:SetText(false)
	local mainX, mainY = dermaBase.main:GetSize()

	dermaBase.musicsheet:SetPos(0,20)
	dermaBase.musicsheet.Navigation:Dock(RIGHT)
	dermaBase.musicsheet.Navigation:SetVisible(false)

	dermaBase.settingPage:Dock(FILL)
	dermaBase.settingPage:DockPadding(0, 0, 0, 10)

	dermaBase.audiodirsheet:Dock(FILL)
	dermaBase.audiodirsheet:DockMargin( 0, 0, 0, 0 )

	dermaBase.songlist:AddColumn( "Song" )

	dermaBase.labelrefresh:Dock(TOP)
	dermaBase.labelrefresh:SetHeight(44)
	dermaBase.labelrefresh.Paint = function(self, w, h)
		draw.DrawText( "Select the folders from ROOT that are going to be added. ROOT: garrysmod\\sound\\ \nIt will also add the content of the first folders found inside them.", "default", w * 0.5, h * 0.10, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
		draw.DrawText( "Right Click to deselect | (Ctrl or Shift)+Click for multiple selections", "default", w * 0.5, h * 0.66, Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	end

	dermaBase.buttonrefresh:Dock(BOTTOM)
	dermaBase.buttonrefresh:SetText("Press to refresh the Song List")
	dermaBase.buttonrefresh:SetSize(mainX / 3,30)
	dermaBase.buttonrefresh:SetVisible(false)

	dermaBase.buttonswap:SetSize(mainX / 3,30)
	dermaBase.buttonswap:SetPos(0,  dermaBase.musicsheet:GetTall() + 20)

	dermaBase.labelswap:Dock(FILL)
	dermaBase.labelswap:DockMargin(6,1,0,0)
	if #server_song_host != 0 then
		dermaBase.labelswap:SetText("Host: " .. server_song_host)
	else
		dermaBase.labelswap:SetText("No song currently playing")
	end

	local buttonTall = 30
	dermaBase.buttonstop:SetText("Stop")
	dermaBase.buttonstop:SetSize(mainX / 3, buttonTall)
	dermaBase.buttonstop:SetPos(0, dermaBase.musicsheet:GetTall() + 20)

	dermaBase.buttonpause:SetText("Pause / Loop")
	dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(), buttonTall)
	dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), dermaBase.musicsheet:GetTall() + 20)

	dermaBase.buttonplay:SetText("Play / AutoPlay")
	dermaBase.buttonplay:SetSize(mainX - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), buttonTall)
	dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), dermaBase.musicsheet:GetTall() + 20)

	dermaBase.sliderseek:SetSize(mainX - 150 , buttonTall)
	dermaBase.sliderseek:AlignBottom()
	dermaBase.sliderseek.Slider.Knob:SetHeight(dermaBase.sliderseek:GetTall())
	dermaBase.sliderseek.Slider.Knob:SetWide(5)
	dermaBase.sliderseek:ShowSeekTime()
	dermaBase.sliderseek:ShowSeekLength()

	dermaBase.slidervol:SetValue(cvarMediaVolume:GetFloat())

	dermaBase.musicsheet.Items[2].Button.DoClick = function(self)
		dermaBase.foldersearch:selectFirstLine()
		if !dermaBase.audiodirsheet:IsVisible() then
			dermaBase.musicsheet:SetActiveButton(self)
		end
	end

    dermaBase.buttonrefresh.DoClick = function(self)
        if dermaBase.cbadmindir:GetChecked() then
            if local_player:IsAdmin() then
                dermaBase.song_data.refresh_song_list()
                dermaBase.song_data.save_on_disk()
            end
        else
            dermaBase.song_data.refresh_song_list()
            dermaBase.song_data.save_on_disk()
        end
    end

	dermaBase.buttonpause.DoClick = function()
        -- if dermaBase.cbadminaccess:GetChecked() then
        if dermaBase.main.IsServerMode() then
            local playingFromOtherMode = dermaBase.main.playingFromAnotherMode()
            -- dermaBase.set_server_TSS(true)
            if !Media.hasValidity() then return end
            if dermaBase.cbadminaccess:GetChecked() then
                if local_player:IsAdmin() then
                    net.Start("sv_pause_live")
                    net.WriteBool(!Media.isPaused())
                    net.WriteDouble(Media.getServerTime())
                    net.SendToServer()
                else
                    -- print("[cl_pause] when in control but not paused")

                    -- // reset control if was playing on the other mode
                    -- if playingFromOtherMode then
                    --     -- print("[cl_pause] control disabled cuz switched from ohter mode")
                    --     -- Media.clientControl(false)
                    -- end
                    -- if !Media.hasValidity() then
                    --     if !Media.clientHasControl() then
                    --         net.Start("sv_refresh_song_state")
                    --         net.SendToServer()
                    --         Media.clientControl(true)
                    --         Media.uiPause()
                    --         return
                    --     end
                    -- elseif playingFromOtherMode then
                    --     print("[sv_pause] play from another mode -------------")
                    --     net.Start("sv_refresh_song_state")
                    --     net.SendToServer()
                    -- end
                    Media.clientControl(!Media.clientHasControl())
                    if Media.clientHasControl() then
                        -- Media.pauseOnPlay()
                        -- Media.kill(true)
                        Media.muteServer()
                        Media.uiPause()
                    else
                        -- dermaBase.buttonplay.DoClick()
                        net.Start("sv_play_live_seek_from_host")
                        net.SendToServer()
                    end

                    -- print("[cl_pause] control:", Media.clientHasControl())
                end
            else
                -- Media.pause()
                net.Start("sv_pause_live")
                net.WriteBool(!Media.isPaused())
                net.WriteDouble(Media.getServerTime())
                net.SendToServer()
                -- if Media.isPaused() then
                --     Media.pause()
                --     net.Start("sv_update_song_state")
                --     net.WriteBool(Media.isPaused())
                --     net.WriteBool(Media.isAutoplayed())
                --     net.WriteBool(Media.isLooped())
                --     net.SendToServer()
                -- else
                --     net.Start("sv_pause_live")
                --     net.WriteBool(!Media.isPaused())
                --     net.WriteDouble(Media.getServerTime())
                --     net.SendToServer()
                -- end
            end
        else
            print("[cl_pause] pause client")
            -- dermaBase.set_server_TSS(false)
            Media.pause()
        end
	end

	dermaBase.buttonplay.DoClick = function(song_path, lineIndex)
        if dermaBase.songlist:IsEmpty() then
            return
        elseif !isnumber(lineIndex) then
            lineIndex = 1;
        end

        if !isstring(song_path) then
            song_path = dermaBase.song_data.get_song(lineIndex)
        end
        if dermaBase.main.IsServerMode() then
            dermaBase.set_server_TSS(true)
            if dermaBase.cbadminaccess:GetChecked() then
                if local_player:IsAdmin() then
                    net.Start("sv_play_live")
                    net.WriteString(song_path)
                    net.WriteUInt(lineIndex, 16)
                    net.SendToServer()
                else
                    net.Start("sv_play_live_seek_from_host")
                    net.SendToServer()
                end
            else
                net.Start("sv_play_live")
                net.WriteString(song_path)
                net.WriteUInt(lineIndex, 16)
                net.SendToServer()
            end
        else
            dermaBase.set_server_TSS(false)
            if Media.hasValidity() && Media.hasState() == GMOD_CHANNEL_PAUSED  then
                Media.resume(song_path, lineIndex)
            else
                Media.play(song_path, lineIndex)
            end
            dermaBase.songlist:SetSelectedLine(lineIndex)
        end
	end

	dermaBase.buttonplay.DoRightClick = function(songFile)
        local nrLine = dermaBase.songlist:GetSelectedLine()

        if dermaBase.songlist:IsEmpty() then
            return
        elseif !isnumber(nrLine) then
            nrLine = 1;
            dermaBase.songlist:SetSelectedLine(nrLine)
        end
        if !isstring(songFile) then
            songFile = dermaBase.song_data.get_song(nrLine)
        end

        if dermaBase.main.IsServerMode() then
            if !dermaBase.mediaplayer.hasValidity() then return end

            if dermaBase.mediaplayer.hasState() == GMOD_CHANNEL_PAUSED then
                dermaBase.buttonpause.DoClick()
                return
            end
            if dermaBase.cbadminaccess:GetChecked() then
                if local_player:IsAdmin() then
                    dermaBase.mediaplayer.autoplay()
                    net.Start("sv_set_autoplay")
                    print("[autplay] is autoplay:", dermaBase.mediaplayer.isAutoPlayed())
                    net.WriteBool(dermaBase.mediaplayer.isAutoPlayed())
                    net.SendToServer()
                end
            else
                print("[cl_play] pressed right click")
                dermaBase.mediaplayer.autoplay()
                net.Start("sv_set_autoplay")
                net.WriteBool(dermaBase.mediaplayer.isAutoPlayed())
                net.SendToServer()
            end
        else
            print("\n[cl_play] Song file:", songFile)
            -- dermaBase.set_server_TSS(false)
            if dermaBase.mediaplayer.isStopped() then
                dermaBase.mediaplayer.play(songFile, nrLine, true)
            else
                if dermaBase.mediaplayer.hasState() == GMOD_CHANNEL_PAUSED then
                    dermaBase.mediaplayer.resume(songFile)
                else
                    if dermaBase.mediaplayer.isLooped() then
                        dermaBase.mediaplayer.setautoplay(true)
                        dermaBase.mediaplayer.uiAutoPlay()
                    elseif dermaBase.mediaplayer.isAutoPlayed() then
                        dermaBase.mediaplayer.setautoplay(false)
                        dermaBase.mediaplayer.uiPlay()
                    else
                        dermaBase.mediaplayer.setautoplay(true)
                        dermaBase.mediaplayer.uiAutoPlay()
                    end
                end
            end
        end
	end

    dermaBase.slidervol.OnValueChanged = function(panel, value)
		if Media.hasValidity() then
			Media.volume(panel:GetValue() / 100)
		end
	end

	dermaBase.slidervol.OnVolumeClick = function(panel, lastVolume)
		if Media.hasValidity() then
			if panel:GetMute() then
				Media.volume(0)
			else
				Media.volume(lastVolume)
			end
		end
	end

	dermaBase.songlist.DoDoubleClick = function(panel, lineIndex, line)
		songFile = dermaBase.song_data.get_song(lineIndex)
		dermaBase.buttonplay.DoClick(songFile, lineIndex)
	end

	dermaBase.sliderseek.SeekClick.OnValueChanged = function(seekClickLayer, seekSecs)
		if Media.hasValidity() then
			if dermaBase.main.IsServerMode() then
				if !dermaBase.cbadminaccess:GetChecked() then
					if Media.hasState() == GMOD_CHANNEL_PAUSED then
						Media.seek(seekSecs)
						dermaBase.sliderseek:SetTime(seekSecs)
					end
					net.Start("sv_set_seek")
					net.WriteDouble(seekSecs)
					net.SendToServer()
				elseif local_player:IsAdmin() then
					if Media.hasState() == GMOD_CHANNEL_PAUSED then
						Media.seek(seekSecs)
						dermaBase.sliderseek:SetTime(seekSecs)
					end
					net.Start("sv_set_seek")
					net.WriteDouble(seekSecs)
					net.SendToServer()
				end
			else
                -- dermaBase.set_server_TSS(false)
				if Media.hasState() != GMOD_CHANNEL_PAUSED then
					Media.seek(seekSecs)
					dermaBase.sliderseek:SetTime(seekSecs)
				end
			end
		end
	end

	dermaBase.main.OnLayoutChange = function(panel)
		local songHeight = dermaBase.musicsheet:GetTall()
		local mainTall = panel:GetTall()

		dermaBase.musicsheet:SetSize(panel:GetWide(), mainTall - 80 )
		dermaBase.songlist:RefreshLayout(panel:GetWide(), mainTall - 80 )
		if dermaBase.musicsheet.Navigation:IsVisible() then
			dermaBase.settingPage:RefreshLayout(panel:GetWide() - 100, mainTall - 80 )
		else
			dermaBase.settingPage:RefreshLayout(panel:GetWide(), mainTall - 80 )
		end

		dermaBase.buttonstop:SetSize(panel:GetWide() / 3,30)
		dermaBase.buttonstop:SetPos(0, songHeight + 20)

		dermaBase.buttonswap:SetSize(panel:GetWide() / 3,30)
		dermaBase.buttonswap:SetPos(0, songHeight + 20)

		dermaBase.buttonpause:SetSize(dermaBase.buttonstop:GetWide(), 30)
		dermaBase.buttonpause:SetPos(dermaBase.buttonstop:GetWide(), songHeight + 20)

		dermaBase.buttonplay:SetSize(panel:GetWide() - (dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide()), 30)
		dermaBase.buttonplay:SetPos(dermaBase.buttonstop:GetWide() + dermaBase.buttonpause:GetWide(), songHeight + 20)

		dermaBase.sliderseek:SetSize(panel:GetWide() - 150 ,30)
		dermaBase.slidervol:SetSize(panel:GetWide()  - dermaBase.sliderseek:GetWide() - 5, 30)
	end

	dermaBase.main.OnResizing = function()
		dermaBase.musicsheet:SetVisible(false)
	end
	dermaBase.main.AfterResizing = function()
		dermaBase.musicsheet:SetVisible(!dermaBase.musicsheet:IsVisible())
	end

	dermaBase.musicsheet.OnSideBarToggle = function(sidePanel, wide)
		dermaBase.settingPage:RefreshCategoryLayout(
            dermaBase.main:GetWide() - wide)
	end

	dermaBase.contextmedia.OnThink = function(panel)
		if Media.hasValidity() && Media.hasState() == GMOD_CHANNEL_PLAYING then
			panel:SetSeekTime(Media.getTime())
		elseif panel:IsMissing() then
			panel:SetSeekEnabled(false)
		end
	end
end

/*
    Used to parent the music player in context menu or ingame
*/
local function init_context_view(context_menu)
    view_ingame = dermaBase.main:GetParent()
    view_context_menu = context_menu
end

local function show()
    dermaBase.musicsheet:SetVisible(true)
	if dermaBase.main:IsVisible() then
        RememberCursorPosition()
        gui.EnableScreenClicker(false)
        if is_context_open then
            if anchor_parent == view_context_menu then
                dermaBase.main:SetVisible(false)
            else
                // move from outside to context area
                anchor_parent = view_context_menu
            end
        else
            if anchor_parent == view_ingame then
                dermaBase.main:SetVisible(false)
            else
                // move outside of context menu area
                gui.EnableScreenClicker(true)
                anchor_parent = view_ingame
            end
        end
        if !Media.sv_is_autoplay() && !Media.cl_is_autoplay() then
            timer.Pause("gmpl_live_core")
        end
    else
        if is_context_open then
            // open in context area
            gui.EnableScreenClicker(false)
            anchor_parent = view_context_menu
        else
            // open outside
            gui.EnableScreenClicker(true)
            anchor_parent = view_ingame
        end
        dermaBase.main:SetVisible(true)
        timer.UnPause("gmpl_live_core")
    end
    RestoreCursorPosition()
    dermaBase.main:SetParent(anchor_parent)
end

local function set_volume(var)
	cvarMediaVolume:SetString(var)
	dermaBase.slidervol:SetValue(var)
end

local function refresh_seek()
    local song_len = Media.get_song_len()
    dermaBase.sliderseek:AllowSeek(true)
    dermaBase.sliderseek:SetMax(song_len)
    dermaBase.contextmedia:SetSeekLength(song_len)
end

local function set_song_host(ply)
    if isentity(ply) && ply:IsPlayer() then
        server_song_host = ply:Nick()
        dermaBase.labelswap:SetText("Host: " .. server_song_host)
    else
        dermaBase.labelswap:SetText("No song currently playing")
    end
end

local function get_song_host()
    return server_song_host
end
------------------------------------------------------------------------------
hook.Add('OnContextMenuOpen', 'gmpl_context_open', function()
    is_context_open = true
end)
hook.Add('OnContextMenuClose', 'gmpl_context_close', function()
    is_context_open = false
end)
------------------------------------------------------------------------------
interface.build             = create_media_player
interface.init_context_view = init_context_view

interface.set_volume        = set_volume
interface.refresh_seek      = refresh_seek
interface.show              = show

interface.set_song_host     = set_song_host
interface.get_song_host     = get_song_host
return init
