local PANEL = {}
AccessorFunc(PANEL, "m_bIsMenuComponent", "IsMenu", FORCE_BOOL)
AccessorFunc(PANEL, "m_bDraggable", "Draggable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bSizable", "Sizable", FORCE_BOOL)
AccessorFunc(PANEL, "m_bScreenLock", "ScreenLock", FORCE_BOOL)
AccessorFunc(PANEL, "m_iMinWidth", "MinWidth")
AccessorFunc(PANEL, "m_iMinHeight", "MinHeight")

local titleMargin
/*
    Indicates if server mode is enabled
*/
local serverOn = false
local last_mode = false

local colorServerState = Color(255, 150, 0, 255)
local isTSS = false

function PANEL:Init()
	self:SetMouseInputEnabled( true )
	self:MouseCapture( true )
	self:SetFocusTopLevel(false)
	self:SetCursor("sizeall")

	self:UpdateWindowSize()

	self.TSS = vgui.Create("Panel", self)
	self.TSS:SetVisible(false)
	self.TSS:SetSize(10,20)
	self.TSS.Paint = function(panel, w, h)
		surface.SetDrawColor(colorServerState)
		surface.DrawRect(0, 0, w, h)
	end

	self.labelTitle = vgui.Create("DLabel", self)
	self.labelTitle:SetPos(0,0)
	self.labelTitle:SetFont("default")
	self.labelTitle:SetTextColor(Color(255, 255, 255))
	self.labelTitle.Paint = function(panel, w, h)
		surface.SetDrawColor(150, 150, 150, 255)
		surface.DrawRect(0, 0, w, h)
	end

	self.buttonMode = vgui.Create("DButton", self)
	self.buttonMode:SetFont("default")
	self.buttonMode:SetTextColor(Color(255,255,255))
	self.buttonMode:SetText("CLIENT")
	self.buttonMode:SetSize(60, 20)
	self.buttonMode.DoClick = function(button)
		self:SwitchMode()
	end
	self.buttonMode.Paint = function() end
	self.buttonMode.PaintOver = function(panel, w, h)
		if self.buttonMode:IsHovered() then
			surface.SetDrawColor(255, 255, 255, 30)
			surface.DrawRect(0, 0, w, h)
		end
	end

	self.buttonSettings = vgui.Create("DButton", self)
	self.buttonSettings:SetText("")
	self.buttonSettings:SetImage("icon16/cog.png")
	self.buttonSettings:SetSize(22, 20)
	self.buttonSettings.DoClick = function(button)
		self:Settings()
	end
	self.buttonSettings.Paint = function() end
	self.buttonSettings.PaintOver = function(panel, w, h)
		if self.buttonSettings:IsHovered() then
			surface.SetDrawColor(255, 255, 255, 30)
			surface.DrawRect(0, 0, w, h)
		end
	end

	self.buttonClose = vgui.Create("DButton", self)
	self.buttonClose:SetFont("default")
	self.buttonClose:SetText("X")
	self.buttonClose:SetSize(20, 20)
	self.buttonClose:SetTextColor(Color(255, 255, 255))

	self.buttonClose.DoClick = function(button)
		self:Close()
	end
	self.buttonClose.Paint = function() end
	self.buttonClose.PaintOver = function(panel, w, h)
		if self.buttonClose:IsHovered() then
			surface.SetDrawColor(255, 255, 255, 30)
			surface.DrawRect(0, 0, w, h)
		end
	end
	titleMargin = self.buttonMode:GetWide() + self.buttonSettings:GetWide() + self.buttonClose:GetWide()

	self:SetDraggable(true)
	self:SetSizable(true)
	self:SetScreenLock(false)

	self:SetText("Window")
	self:SetMinWidth(320)
	self:SetMinHeight(300)

	-- This turns off the engine drawing
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)

	self:DockPadding(0, 0, 0, 0)
end

function PANEL:SetFont(font)
	self.labelTitle:SetFont(font)
	self.buttonClose:SetFont(font)
	self.buttonMode:SetFont(font)
end

function PANEL:IsTSSEnabled()
	return isTSS
end

function PANEL:playingFromAnotherMode()
    -- print("last mode | IS server ON: ", last_mode, serverOn)
    return last_mode != serverOn
end

function PANEL:SetTSSEnabled(bool)
	if bool then
		self.labelTitle:SetPos(10,0)
	else
		self.labelTitle:SetPos(0,0)
	end
	self.TSS:SetVisible(bool)
	isTSS = bool
end

function PANEL:SetTitleServerState(selected_mode)
	if selected_mode then
		colorServerState = Color(20, 150, 240, 255)
	else
		colorServerState = Color(255, 150, 0, 255)
	end
    last_mode = selected_mode
	self.TSS.Paint = function(panel, w, h)
		surface.SetDrawColor(colorServerState)
		surface.DrawRect(0, 0, w, h)
	end
end

function PANEL:SetBGColor(r, g, b)
	self.labelTitle.Paint = function(panel, w, h)
		surface.SetDrawColor(r, g, b, 255)
		surface.DrawRect(0, 0, w, h)
	end
end

function PANEL:UpdateWindowSize()
	if (ScrW() < 800) then
		self:SetSize(500, 400)
	elseif (ScrW() > 1280) then
		self:SetSize(1160, 400 + (ScrW() / 7))
	else
		self:SetSize(ScrW() - 120, 400)
	end
end

function PANEL:OnScreenSizeChanged(old_width, old_height)
    self:UpdateWindowSize()
end

function PANEL:ShowCloseButton(bShow)
	self.btnClose:SetVisible(bShow)
end

function PANEL:GetTitle()
	return self.labelTitle:GetText()
end

function PANEL:SetText(strTitle)
	self.labelTitle:SetText(strTitle)
end

function PANEL:SetTextColor(color)
	self.labelTitle:SetTextColor(color)
end

function PANEL:Close()
	gui.EnableScreenClicker(false)
	self:SetVisible(false)
	self:OnClose()
end

function PANEL:OnClose()
end

function PANEL:SwitchMode()
	if serverOn then
			serverOn = false
			self.buttonMode:SetText("CLIENT")
			self.buttonMode.Paint = function() end
	else
			serverOn = true
			self.buttonMode:SetText("SERVER")
			self.buttonMode.Paint = function(panel, w, h)
				surface.SetDrawColor(20, 150, 240, 255)
				surface.DrawRect(0, 0, w, h)
			end
	end
	self:OnModeChanged()
end

function PANEL:IsServerMode()
	return serverOn
end

function PANEL:OnModeChanged()
end

function PANEL:Settings()
	self:OnSettingsClick()
end

function PANEL:OnSettingsClick()
end

function PANEL:Center()
	self:InvalidateLayout(true)
	self:CenterVertical()
	self:CenterHorizontal()
end

function PANEL:IsActive()
	if (self:HasFocus()) then
		return true
	end

	if (vgui.FocusedHasParent(self)) then
		return true
	end

	return false
end

function PANEL:OnResizing()
end

function PANEL:AfterResizing()
end

function PANEL:Think()
	local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
	local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

	if (self.Dragging) then
		local x = mousex - self.Dragging[1]
		local y = mousey - self.Dragging[2]

		-- Lock to screen bounds if screenlock is enabled
		if (self:GetScreenLock()) then
			x = math.Clamp(x, 0, ScrW() - self:GetWide()) - titleMargin
			y = math.Clamp(y, 0, ScrH() - self:GetTall())
		end

		self:SetPos(x, y)
	end

	if (self.Sizing) then
		local x = mousex - self.Sizing[1]
		local y = mousey - self.Sizing[2]
		local px, py = self:GetPos()

		if (x < self.m_iMinWidth) then
			x = self.m_iMinWidth
		elseif (x > ScrW() - px and self:GetScreenLock()) then
			x = ScrW() - px
		end

		if (y < self.m_iMinHeight) then
			y = self.m_iMinHeight
		elseif (y > ScrH() - py and self:GetScreenLock()) then
			y = ScrH() - py
		end

		self:SetSize(x, y)
		self:SetCursor("sizenwse")
		return
	end
	if (self.Hovered and self.m_bSizable and mousex > (self.x + self:GetWide() - 20) and mousey > (self.y + self:GetTall() - 20)) then
		self:SetCursor("sizenwse")

		return
	end

	if (self.Hovered and self:GetDraggable() and mousey < (self.y + self.labelTitle:GetTall())) then
		self:SetCursor("sizeall")
		return
	end

	self:SetCursor("arrow")

	if (self.y < 0) then
		self:SetPos(self.x, 0)
	end
    self:OnUpdateUI()
end

/*
    Callback for custom use
*/
function PANEL:OnUpdateUI()
end

function PANEL:Paint(w, h)
	derma.SkinHook("Paint", "Frame", self, w, h)
	return true
end

function PANEL:OnMousePressed()
	if (self.m_bSizable and gui.MouseX() > (self.x + self:GetWide() - 20) and gui.MouseY() > (self.y + self:GetTall() - 20)) then
		self.Sizing = {gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall()}
		self:MouseCapture(true)
		self:OnResizing()
		return
	end

	if (self:GetDraggable() and gui.MouseY() < (self.y + 24)) then
		self.Dragging = {gui.MouseX() - self.x, gui.MouseY() - self.y}
		self:MouseCapture(true)

		return
	end
end

function PANEL:IsMouseReleased()
end

function PANEL:OnMouseReleased()
	self.Dragging = nil
	if self.Sizing then
		self:AfterResizing()
	end
	self.Sizing = nil
	self:MouseCapture(false)
	self:IsMouseReleased()
end
function PANEL:HasParents(panel)
	if IsValid(panel) then
		return self:HasParent(panel)
	end
end

function PANEL:OnLayoutChange()
end

function PANEL:PerformLayout()
	self.buttonMode:SetPos(self:GetWide() - self.buttonMode:GetWide() -  self.buttonSettings:GetWide() - self.buttonClose:GetWide(), 0)
	self.buttonSettings:SetPos(self:GetWide() - self.buttonSettings:GetWide() - self.buttonClose:GetWide(), 0)
	self.buttonClose:SetPos(self:GetWide() - self.buttonClose:GetWide(), 0)
	self.labelTitle:SetSize(self:GetWide(), 20)
	self:OnLayoutChange()
end

derma.DefineControl("DgMPlayerFrame", "Music Player", PANEL, "EditablePanel")
