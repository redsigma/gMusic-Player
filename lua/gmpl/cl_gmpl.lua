-- local mediaplayer = nil
local shared_settings = nil

local dermaBase = {}
local view_context_menu = nil
local contextMenuMargin = ScrW() / 5
local view_ingame = nil

surface.CreateFont( "arialDefault", {
	font = "Arial",
	extended = false,
	size = 16,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

local function createMPlayer()
    dermaBase.create(view_context_menu)
    dermaBase.painter.changeTheme(dermaBase.darkmode:GetChecked())
    dermaBase.painter.update_colors()
end

hook.Add("ContextMenuCreated", "create_context", function(context_menu)
    view_context_menu = context_menu
end)

--[[-------------------------------------------------------------------------
Runs if server not just Created
---------------------------------------------------------------------------]]--
-- net.Receive( "sendServerSettings", function()
-- 	local serverSettings = net.ReadTable()

-- 	dermaBase.cbadminaccess:SetChecked(serverSettings.admin_server_access)
-- 	dermaBase.cbadmindir:SetChecked(serverSettings.admin_dir_access)
-- end )


--[[-------------------------------------------------------------------------
First Run on server start
---------------------------------------------------------------------------]]--
net.Receive("cl_gmpl_create", function()
    dermaBase = include("includes/modules/meth_base.lua")(
        view_context_menu, contextMenuMargin)

	while !isfunction(dermaBase.main.IsVisible) do
		MsgC(Color(100, 200, 200), "[gMusic Player]", Color(255, 90, 90),
            " Failed to initialize - retrying\n" )
		dermaBase = include("includes/modules/meth_base.lua")(
            view_context_menu, contextMenuMargin)
	end
    shared_settings = include("includes/func/settings.lua")
    shared_settings:set_admin_server_access(
        dermaBase.cbadminaccess:GetChecked())
    shared_settings:set_admin_dir_access(
        dermaBase.cbadmindir:GetChecked())

    include("gmpl/cl_cvars.lua")(dermaBase)

	require("musicplayerclass")
	dermaBase.mediaplayer = Media(dermaBase)

	dermaBase.song_data.load_from_disk()
	createMPlayer()

    timer.Create("gmpl_sv_guard", 2, 0,
        dermaBase.mediaplayer.sv_buffer_guard)
    timer.Stop("gmpl_sv_guard")

    timer.Create("gmpl_cl_guard", 2, 0,
        dermaBase.mediaplayer.cl_buffer_guard)
    timer.Stop("gmpl_cl_guard")

    timer.Create("gmpl_live_core", 0.07, 0,
    dermaBase.mediaplayer.real_time_seek)
    timer.Pause("gmpl_live_core")

    -- dermaBase.mediaplayer
    -- print("\nshared settings cl_gmpl:", shared_settings)
    -- PrintTable(shared_settings)
end)


net.Receive("cl_gmpl_show", function()
	local live_host = net.ReadType()
    dermaBase.interface.set_song_host(live_host)
    dermaBase.InvalidateUI()
    dermaBase.interface.show()
end)

concommand.Add("gmplshow", function()
    dermaBase.InvalidateUI()
    dermaBase.interface.show()
end)


cvars.AddChangeCallback( "gmpl_vol", function( convar , oldValue , newValue  )
	if !istable(dermaBase.mediaplayer) then return end
	if (isnumber(util.StringToType( newValue, "Float" ))) then
		-- if istable(mediaplayer) then
        dermaBase.interface.set_volume(newValue)
		-- end
	elseif (isnumber(util.StringToType( oldValue, "Float" ))) then
		-- if istable(mediaplayer) then
            dermaBase.interface.set_volume(oldValue)
			MsgC(Color(255, 90, 90),
                "Only 0 - 100 value is allowed. Keeping value "
                .. oldValue .. "\n")
		-- end
	end
end )

-- hook.Add("OnScreenSizeChanged", "warn_users", function(old_width, old_height)
--     // Keep this warning to notice users of this bug
--      local dialog_warning = vgui.Create("DFrame")
--      dialog_warning:SetSize(350, 200)
--      dialog_warning:SetDeleteOnClose(true)
--      dialog_warning:ShowCloseButton(false)
--      dialog_warning:Center()
--      dialog_warning:SetTitle("Warning resolution changed")
--      dialog_warning:MoveToFront()

--      dialog_warning.Label = vgui.Create("RichText", dialog_warning)
--      dialog_warning.Label:SetVerticalScrollbarEnabled(false)
--      dialog_warning.Label:Dock(FILL)
--      dialog_warning.Label:InsertColorChange(255, 255, 255, 255)
--      dialog_warning.Label:AppendText(
--          "Resolution Change Detected!\n\nBecause of this, a small panel will appear in the left corner due to a bug in Gmod. Please reconnect to the server or live with it :)")
--      dialog_warning.Label.Paint = function(panel)
--          panel:SetFontInternal( "GModNotify" )
--          panel.Paint = nil
--      end

--      local bottom = vgui.Create("Panel", dialog_warning)
--      bottom:Dock(BOTTOM)

--      bottom.btn = vgui.Create("DButton", bottom)
--      bottom.btn:Dock(FILL)
--      bottom.btn:DockMargin(4, 0, 0, 0)
--      bottom.btn:SetText("I Understand")
--      bottom.btn:SetFont("GModNotify")
--      bottom.btn.Paint = function(panel, w, h)
--          surface.SetDrawColor(Color(255, 255, 255))
--          surface.DrawRect(0, 0, w, h)
--      end
--      bottom.btn.DoClick = function()
--          dialog_warning:Close()
--      end
-- end)
