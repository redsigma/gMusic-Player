local dermaBase = {}

local defaultFont = "arialDefault"
local local_player = LocalPlayer()

local function init(contextMenu, contextMargin)
    dermaBase.mediaplayer = nil
    dermaBase.painter = include("includes/modules/meth_paint.lua")()
    dermaBase.interface = include("includes/func/interface.lua")(dermaBase)
    dermaBase.song_data = include("includes/modules/meth_song.lua")(dermaBase)

	dermaBase.contextmedia = vgui.Create("DMultiButton", contextMenu)
	dermaBase.main = vgui.Create("DgMPlayerFrame")

	bottom_p                = vgui.Create("Panel", dermaBase.main)
	dermaBase.sliderseek    = vgui.Create("DSeekBar",bottom_p)
	dermaBase.slidervol     = vgui.Create("DNumSliderNoLabel", bottom_p)

	-- Buttons
	dermaBase.buttonstop    = vgui.Create("DBetterButton", dermaBase.main)
	dermaBase.buttonpause   = vgui.Create("DBetterButton", dermaBase.main)
	dermaBase.buttonplay    = vgui.Create("DBetterButton", dermaBase.main)

	-- Music List Server/Client button swap
	dermaBase.buttonswap    = vgui.Create("Panel", dermaBase.main)
	dermaBase.labelswap     = vgui.Create("DLabel", dermaBase.buttonswap)


    -- Music Dir
	dermaBase.audiodirsheet = vgui.Create("Panel", dermaBase.musicsheet_colsheet)
	dermaBase.foldersearch	= vgui.Create("DDoubleListView", dermaBase.audiodirsheet)
	dermaBase.foldersearch:SetInfoColor(Color(255, 255, 255))
	-- Music Dir refresh button
	dermaBase.labelrefresh 	= vgui.Create("Panel", dermaBase.audiodirsheet )
	dermaBase.buttonrefresh = vgui.Create("DButton", dermaBase.audiodirsheet)

	-- Music List
	dermaBase.musicsheet    = vgui.Create("DSideMenu",dermaBase.main)
	dermaBase.songlist      = vgui.Create("DBetterListView", dermaBase.musicsheet)

	-- Settings
	dermaBase.settingsheet 	= vgui.Create("Panel", dermaBase.musicsheet)
	dermaBase.settingPage  	= vgui.Create("DOptions", dermaBase.settingsheet )
	dermaBase.settingPage:SetDefaultFont(defaultFont)

	-- Settings options
	dermaBase.settingPage:Category("Server Side")
	dermaBase.cbadminaccess	= dermaBase.settingPage:CheckBox(
        "Only admins can play songs on the server", true)
	dermaBase.cbadmindir    = dermaBase.settingPage:CheckBox(
        "Only admins can select music dirs", true)

	dermaBase.settingPage:Category("Client Side")
	dermaBase.contextbutton =
        dermaBase.settingPage:CheckBox("Enable context menu button", false)
	dermaBase.hotkey        =
        dermaBase.settingPage:CheckBox("Disable F3 hotkey", false)
	dermaBase.darkmode      =
        dermaBase.settingPage:CheckBox("Enable dark mode", false)

	-- Panel
	bottom_p:DockMargin(0,0,25,0)
	bottom_p:Dock(BOTTOM)

	dermaBase.foldersearch:Dock(FILL)
	dermaBase.settingsheet:Dock(FILL)
	dermaBase.slidervol:Dock(RIGHT)

	dermaBase.contextmedia:SetPos(ScrW() - contextMargin, 0)
	dermaBase.contextmedia:SetSize(ScrW() - (ScrW() - contextMargin), 30)

	-- Visibility
	dermaBase.main:SetVisible(false)
	dermaBase.buttonswap:SetVisible(false)
	dermaBase.contextmedia:SetVisible(false)

	-- Font style
	dermaBase.songlist:SetFont(defaultFont)
	dermaBase.slidervol:SetFont(defaultFont)
	dermaBase.sliderseek:SetTextFont(defaultFont)
	dermaBase.contextmedia:SetFont(defaultFont)
	dermaBase.contextmedia:SetTextColor(Color(0, 0, 0))
    dermaBase.labelswap:SetTextColor(Color(230, 230, 230))

	dermaBase.buttonstop:SetFont(defaultFont)
	dermaBase.buttonpause:SetFont(defaultFont)
	dermaBase.buttonplay:SetFont(defaultFont)
    dermaBase.buttonrefresh:SetFont(defaultFont)
    dermaBase.labelswap:SetFont(defaultFont)

	-- Convars for checkboxes
	dermaBase.slidervol:SetConVar("gmpl_vol")
	dermaBase.cbadminaccess:SetConVar("gmpl_svadminplay", "1",
        "[gMusic Player] Allows only admins to play songs on the server")
	dermaBase.cbadmindir:SetConVar("gmpl_svadmindir", "0",
        "[gMusic Player] Only admins can select Music Dirs")
	dermaBase.contextbutton:SetConVar("gmpl_cmenu", "0",
        "[gMusic Player] Disable/Enable the context menu button")
	dermaBase.hotkey:SetConVar(
        "gmpl_nohotkey", "0", "[gMusic Player] Disable/Enable the F3 hotkey")
	dermaBase.darkmode:SetConVar(
        "gmpl_dark", "1", "[gMusic Player] Toggle dark mode theme")
	-- DO gmpl_resetsize for dumbass
	-- Do gmpl_size x y
	-- bring player to front if pressing context while already opened with f3
	-- bind F3 back to gm_showspare1 if or add some kind of F3 it's bound to gmplshow
	-- check seek with some tf2 songs it doesnt stop when reaches end
	-- text color of song item doesnt keep the right one when switching from/to dark mode
	-- Looping should work even when autoplay is on. Good for autoplay+loop combo
	-- wolf has a white bar instead of Song. Test with all vocas see if you can get the bug to appear
	-- make autoplay operational serverside similar to how is looped works
	-- find why some songs does not stop when reach end. This also blocks the autoplay when it happens.  test with tf2 and hl2 songs the short the better
	-- also try to find a way to auto invalidate the song list if you add/rem songs so you dont need to resize it a bit. Scroll doesn't appear cuz of this sometimes
	-- context button shows Label instead of song name. Also make the timer less taller
	-- it shows no host even though somebody was the host.. fix
	-- pause the song serverside if admin pause
	-- seekbar prevent stopping the sound if you still hold on the click. If you seeked to the end

    dermaBase.set_server_TSS = function(bool)
        // switch to Client/Server
        dermaBase.main:SetTitleServerState(bool)
        dermaBase.contextmedia:SetTSS(bool)
    end

    dermaBase.main.OnUpdateUI = function()
        // if sidemenu or music dir is visible
        if dermaBase.musicsheet:IsVisible() ||
            dermaBase.audiodirsheet:IsVisible() then
            if dermaBase.cbadmindir:GetChecked() then
                if dermaBase.audiodirsheet:IsVisible() &&
                    !local_player:IsAdmin() then
                    dermaBase.musicsheet:SetActiveButton(
                        dermaBase.musicsheet.Items[1].Button)
                end

                if local_player:IsAdmin() then
                    if !dermaBase.musicsheet.Items[2].Button:IsVisible() then
                        dermaBase.musicsheet.Items[2].Button:SetVisible(true)
                        dermaBase.musicsheet.Navigation:InvalidateChildren()
                    end
                elseif dermaBase.musicsheet.Items[2].Button:IsVisible() then
                    dermaBase.musicsheet.Items[2].Button:SetVisible(false)
                    dermaBase.musicsheet.Navigation:InvalidateChildren()
                end
            else
                if dermaBase.musicsheet.Items[2].Button:GetDisabled() then
                    dermaBase.musicsheet.Items[2].Button:SetEnabled(true)
                end
                if !dermaBase.musicsheet.Items[2].Button:IsVisible() then
                    dermaBase.musicsheet.Items[2].Button:SetVisible(true)
                    dermaBase.musicsheet.Navigation:InvalidateChildren()
                end
            end
        end

        if !dermaBase.main.IsServerMode() then return end

        if dermaBase.cbadminaccess:GetChecked() then
            if local_player:IsAdmin() then
                dermaBase.mediaplayer:ToggleNormalUI()
            else
                dermaBase.mediaplayer:ToggleListenUI()
            end
        else
            dermaBase.mediaplayer:ToggleNormalUI()
        end
    end

	dermaBase.main.OnSettingsClick = function(panel)
        dermaBase.musicsheet:ToggleSideBar()
	end

    dermaBase.main.OnModeChanged = function()
        local is_server_on = dermaBase.main.IsServerMode()
        dermaBase.mediaplayer.updateStates(is_server_on)

        if is_server_on then
            -- net.Start("askSongStateToServer")
            -- net.SendToServer()
        else
            dermaBase.mediaplayer:ToggleNormalUI()
		end
	end

	dermaBase.buttonpause.DoRightClick  = function()
        if dermaBase.main.IsServerMode() then
            if !dermaBase.mediaplayer.hasValidity() then return end
            if dermaBase.cbadminaccess:GetChecked() then
                if local_player:IsAdmin() then
                    Media.loop()
                    net.Start("sv_set_loop")
                    net.WriteBool(Media.isLooped())
                    net.SendToServer()
                end
            else
                Media.loop()
                net.Start("sv_set_loop")
                net.WriteBool(Media.isLooped())
                net.SendToServer()
            end
        else
            Media.loop()
        end
	end

    dermaBase.buttonstop.DoClick = function()
		if dermaBase.main.IsServerMode() then
            net.Start("sv_stop_live")
			net.SendToServer()
            Media.sv_stop()
		else
			if !Media.isMissing() then
				Media.cl_stop()
			end
		end
	end

	-- Clicks M1
	dermaBase.contextmedia.DoClick = function()
        net.Start("sv_gmpl_show")
		net.SendToServer()
	end

	-- Clicks M2
	dermaBase.contextmedia.DoRightClick = function()
		dermaBase.buttonpause.DoClick()
	end

	-- Clicks M3
	dermaBase.contextmedia.DoMiddleClick = function()
		dermaBase.buttonpause.DoRightClick()
	end

	-- Clicks M4
	dermaBase.contextmedia.DoM4Click  = function()
		dermaBase.buttonpause.DoRightClick()
	end

    dermaBase.contextmedia.OnScreenSizeChanged = function(old_width, old_height)
        dermaBase.contextmedia:SetPos(ScrW() - contextMargin, 0)
        dermaBase.contextmedia:SetSize(ScrW() - (ScrW() - contextMargin), 30)
	end

	dermaBase.contextbutton.OnCvarChange = function(panel, newVal)
        // this also runs on connect
        local val = util.StringToType(newVal, "int")
        dermaBase.contextbutton:AfterChange(val)
	end

	dermaBase.cbadminaccess.OnCvarChange = function(panel, newVal)
        -- print("admin access CVAR CHANGE")
	end
	dermaBase.cbadmindir.OnCvarChange = function(panel, newVal)
        -- print("admin dir CVAR CHANGE")
	end

	dermaBase.cbadminaccess.AfterChange = function(panel, val)
        local bVal = tobool(val)
        net.Start("toServerRefreshAccess")
		net.WriteBool(bVal)
		net.SendToServer()
        -- print("admin access AFTER CHANGE")
	end
	dermaBase.cbadmindir.AfterChange = function(panel, val)
        local bVal = tobool(val)
        net.Start("toServerRefreshAccessDir")
		net.WriteBool(bVal)
		net.SendToServer()
        -- print("admin dir AFTER CHANGE")
	end

	dermaBase.contextbutton.AfterChange = function(panel, val)
        -- print("contextbutton AFTER CHANGE", val)
		if !IsValid(contextMenu) then return end
        local bVal = tobool(val)
        -- print("Context menu set to ", bVal)
		dermaBase.contextmedia:SetVisible(bVal)
	end

	dermaBase.darkmode.AfterChange = function(panel, bVal)
		dermaBase.painter.changeTheme(bVal)
        dermaBase.painter.update_colors()

		panel.OnCvarWrong = function(panel, old, new)
			MsgC(Color(255, 90, 90),
                "Only 0 - 1 value is allowed. Keeping value " .. old .. " \n")
		end
	end

    dermaBase.painter.update_colors = function ()
        dermaBase.painter.paintNone({
            dermaBase.buttonrefresh, dermaBase.buttonstop, dermaBase.buttonpause, dermaBase.buttonplay, dermaBase.buttonaplay,
            dermaBase.musicsheet.Navigation, dermaBase.foldersearch,
            dermaBase.musicsheet, dermaBase.foldersearch.btnRebuildMid,
            dermaBase.foldersearch.btnAddMid, dermaBase.foldersearch.btnRemMid
        })
        local white = Color(255, 255, 255)
        local hoverWhite = Color(230, 230, 230, 50)

        dermaBase.buttonrefresh:SetTextColor(white)
        dermaBase.buttonstop:SetTextColor(white)
        dermaBase.buttonpause:SetTextColor(white)
        dermaBase.buttonplay:SetTextColor(white)

        dermaBase.painter.paintSlider(dermaBase.sliderseek)
        dermaBase.painter.paintSlider(dermaBase.slidervol)

        dermaBase.painter.paintBG(dermaBase.main)

        dermaBase.painter.paintBG(
            dermaBase.musicsheet.Navigation, Color(120, 120, 120))
        for k, sideItem in pairs(dermaBase.musicsheet.Items) do
            if (!sideItem.Button) then continue end
                dermaBase.painter.paintBG(
                    sideItem.Button, Color(255, 255 ,255))
                dermaBase.painter.paintHoverBG(
                    sideItem.Button, Color(0, 0, 0, 50))
                sideItem.Button:SetTextColor(Color(0, 0, 0))
        end
        dermaBase.painter.paintHoverBG(dermaBase.buttonrefresh, hoverWhite)
        dermaBase.painter.paintHoverBG(dermaBase.buttonstop, hoverWhite)
        dermaBase.painter.paintHoverBG(dermaBase.buttonpause, hoverWhite)
        dermaBase.painter.paintHoverBG(dermaBase.buttonplay, hoverWhite)

        dermaBase.painter.paintList(dermaBase.songlist)
        dermaBase.painter.paintHoverList(dermaBase.songlist)

        dermaBase.painter.paintScroll(
            dermaBase.songlist, Color(120, 120, 120))
        dermaBase.painter.paintText(dermaBase.songlist)
        if Media.hasValidity() && Media.isLooped() then
            Media.uiLoop()
        end

        dermaBase.painter.paintText(dermaBase.foldersearch)
        dermaBase.painter.paintList(dermaBase.foldersearch)
        dermaBase.painter.paintColumn(dermaBase.foldersearch)
        dermaBase.painter.paintHoverColumn(dermaBase.foldersearch, hoverWhite)
        dermaBase.painter.paintScroll(
            dermaBase.foldersearch, Color(120, 120, 120))

        dermaBase.painter.paintHoverBG(
            dermaBase.foldersearch.btnRebuildMid, hoverWhite)
        dermaBase.painter.paintHoverBG(
            dermaBase.foldersearch.btnAddMid, hoverWhite)
        dermaBase.painter.paintHoverBG(
            dermaBase.foldersearch.btnRemMid, hoverWhite)

        dermaBase.painter.paintThemeBG(dermaBase.settingsheet)
        dermaBase.painter.paintScroll(dermaBase.settingPage)
        dermaBase.painter.paintText(dermaBase.settingPage)
        for _, category in pairs(dermaBase.settingPage.Categories) do
            dermaBase.painter.paintBG(category)
            category:SetTextColor(white)
        end
    end

    dermaBase.foldersearch.OnRebuild = function(panel)
        dermaBase.song_data.rebuild_song_page()
        dermaBase.foldersearch:selectFirstLine()
    end

    dermaBase.foldersearch.OnAdd = function(panel)
        if dermaBase.cbadmindir:GetChecked() then
            if local_player:IsAdmin() then
                panel:selectFirstLine()
                dermaBase.buttonrefresh:SetVisible(true)

                dermaBase.song_data.populate_left_list()
                dermaBase.song_data.populate_right_list()
            end
        else
            panel:selectFirstLine()
            dermaBase.buttonrefresh:SetVisible(true)

            dermaBase.song_data.populate_left_list()
            dermaBase.song_data.populate_right_list()
        end
    end

    dermaBase.foldersearch.OnRemove = function(panel)
        if dermaBase.cbadmindir:GetChecked() then
            if local_player:IsAdmin() then
                panel:selectFirstLine()
                dermaBase.buttonrefresh:SetVisible(true)

                dermaBase.song_data.populate_left_list()
                dermaBase.song_data.populate_right_list()
            end
        else
            panel:selectFirstLine()
            dermaBase.buttonrefresh:SetVisible(true)

            dermaBase.song_data.populate_left_list()
            dermaBase.song_data.populate_right_list()
        end
    end

    dermaBase.foldersearch.UpdateMusicDir =
        function(panel, inactive_dirs, active_dirs)
            dermaBase.song_data.populate_left_list(inactive_dirs)
            dermaBase.song_data.populate_right_list(active_dirs)
            panel:OnRebuild()
            dermaBase.song_data.populate_song_page()
        end

    /*
        Updates the settings page checkboxes
    */
    dermaBase.InvalidateUI = function()
        dermaBase.settingPage:InvalidateItems()
    end

    dermaBase.create = function (context_menu)
        dermaBase.InvalidateUI()
        dermaBase.foldersearch.OnRebuild()
        dermaBase.song_data.populate_song_page()

        dermaBase.main:SetFont(defaultFont)
        dermaBase.musicsheet:AddSheet("Song List",dermaBase.songlist , "icon16/control_play_blue.png")
        dermaBase.musicsheet:AddSheet(" Music Dirs",dermaBase.audiodirsheet, "icon16/folder_add.png", true)
        dermaBase.musicsheet:AddSheet("Settings",dermaBase.settingsheet, "icon16/application_view_list.png")

        dermaBase.musicsheet.Items[2].Button.PaintOver = function(self,w,h)
            if self:GetDisabled() then
            surface.SetDrawColor( 0, 0, 0, 150 )
            surface.DrawRect( 0, 0, w, h )
            end
        end

        local tallOptionsPage = 0
        for k,v in pairs(dermaBase.settingPage.Items) do
            tallOptionsPage = tallOptionsPage + v:GetTall()
        end
        dermaBase.settingPage:SetSize(200, tallOptionsPage + 40)

        dermaBase.interface.build()
        dermaBase.interface.init_context_view(context_menu)
    end

return dermaBase
end

return init
