/*
    Painter used to color the panels. Color values are shared among all
    panels
*/
local paintMethod = {}
local colors = {}
local thememode = nil

local white = Color(255, 255, 255)

local function changeTheme(thememode_)
	thememode = thememode_

	if (tobool(thememode)) then
		colors.bg = Color(15, 110, 175)
		colors.bghover = Color(230, 230, 230, 50)
		colors.text = Color(230, 230, 230)
		colors.bglist = Color(35, 35, 35)
		colors.slider = Color(0, 0, 0, 100)
	else
		colors.bg = Color(20, 150, 240)
		colors.bghover = Color(30, 30, 30, 130)
		colors.text = Color(0, 0, 0)
		colors.bglist = Color(245, 245, 245)
		colors.slider = Color(0, 0, 0, 100)
	end

	return colors
end

local function init()
	return paintMethod
end

local function paintBG(panel, color)
	panel.Paint = function(self, w, h)
		if istable(color) then
			surface.SetDrawColor( color )
		else
			surface.SetDrawColor(colors.bg)
		end
		surface.DrawRect( 0, 0, w, h )
	end
end

local function paintThemeBG(panel, color)
	paintBG(panel, colors.bglist)
end

local function paintHoverBG(panel, color)
	panel.PaintOver = function(self, w, h)
		if panel:IsHovered() then
			if istable(color) then
				surface.SetDrawColor( color )
			else
				surface.SetDrawColor( colors.bghover )
			end
			surface.DrawRect( 0, 0, w, h )
		end
	end
end

local function paintBGArea(panel, startx, starty, endx, endy)
	panel.Paint = function(self, w, h)
		surface.SetDrawColor( colors.bg )
		surface.DrawRect( startx, starty, endx, endy )
	end
end

local function paintHoverBGArea(panel)
	panel.PaintOver = function(self, w, h)
		if panel:IsHovered() then
			surface.SetDrawColor( colors.bghover )
			surface.DrawRect( startx, starty, endx, endy )
		end
	end
end

local function paintList(panel)
	panel:PaintList(colors.bglist)
end
local function paintHoverList(panel)
	panel:SetHoverBGColor(colors.bghover)
end

local function paintColumn(panel)
	panel:PaintColumn(colors.bg)
end

local function paintHoverColumn(panel, hoverColor)
	if istable(hoverColor) then panel:PaintHoverColumn(hoverColor)
	else panel:PaintHoverColumn(colors.bghover) end
end

local function paintScroll(panel, bgGrip, colorArrows)
	if istable(colorArrows) then panel:PaintScroll(colors.bg, bgGrip, colorArrows)
	else panel:PaintScroll(colors.bg, bgGrip, colors.text) end
end

local function paintSlider(panel)
	panel:SetSliderColor(colors.slider)
	panel:SetTextColor(white)
	panel.Slider.Paint(panel.Slider, panel.Slider:GetWide(), panel.Slider:GetTall())
end

local function paintText(panel)
	panel:SetTextColor(colors.text)
end

local function paintNone(table)
	if istable(table) then
		for _, panel in pairs(table) do
			panel.Paint = function() end
		end
	end
end

paintMethod.changeTheme			=	changeTheme
paintMethod.paintNone 			=	paintNone

paintMethod.paintSlider 		=	paintSlider
paintMethod.paintThemeBG 		=	paintThemeBG
paintMethod.paintScroll 		=	paintScroll

paintMethod.paintBG 			=	paintBG
paintMethod.paintHoverBG 		=	paintHoverBG
paintMethod.paintBGArea 		=	paintBGArea
paintMethod.paintHoverBGArea	=	paintHoverBGArea
paintMethod.paintText 			=	paintText

paintMethod.paintList 			=	paintList
paintMethod.paintHoverList 		=	paintHoverList
paintMethod.paintColumn 		=	paintColumn
paintMethod.paintHoverColumn 	=	paintHoverColumn

return init
