
local PANEL = {}
AccessorFunc(PANEL, "m_bDefFont", "DefaultFont", FORCE_BOOL)
AccessorFunc( PANEL, "m_bSizeToContents",	"AutoSize", FORCE_BOOL)

local itemCount = 0
local categCount = 0

local checkboxTextColor = Color(0, 0, 0)

function PANEL:Init()

	self.Categories = {}
	self.Items = {}

	self:SetMouseInputEnabled( true )
	self:SetKeyboardInputEnabled( true )
	self:SetDefaultFont("default")

	self.panel = vgui.Create( "Panel", self )

	self.VBar = vgui.Create( "DSimpleScroll", self )
	self.VBar:SetZPos( 20 )

end

function PANEL:SetTextColor(checkboxTextColor_)
	checkboxTextColor = checkboxTextColor_
	for _, checkbox in pairs(self.Items) do
		checkbox:SetTextColor(checkboxTextColor)
	end
end

function PANEL:RefreshLayout(w, h)
	self:SetSize(w, h)
	self.VBar:SetScroll(self.VBar:GetScroll())
	for k, line in pairs(self.Categories) do
		self.Categories[k]:SetWide(w)
	end
end

function PANEL:RefreshCategoryLayout(w)
	self.VBar:SetScroll(self.VBar:GetScroll())
	for k, line in pairs(self.Categories) do
		self.Categories[k]:SetWide(w)
	end
end

function PANEL:SetDefaultFont(font)
	self.m_bDefFont = font
end

function PANEL:Clear()
	for k, v in pairs( self.Items ) do
		if ( IsValid(v) ) then v:Remove() end
	end
	self.Items = {}
end

/*
    Updates the settings page elements according to match the cvar values
*/
function PANEL:InvalidateItems()
	for k, checkbox in pairs(self.Items) do
	    checkbox:UpdateThink()
	end
end

function PANEL:Category( strLabel )
	local cat = vgui.Create( "DLabel", self.panel )
	cat:SetPos(0, itemCount + categCount)
	cat:SetWide(self:GetWide())
	cat:SetContentAlignment(5)
	cat:SetFont(self:GetDefaultFont())
	cat:SetText(strLabel)

	categCount = categCount + 6
	itemCount = itemCount + cat:GetTall() + categCount
	table.insert( self.Categories, cat )

	return cat
end

function PANEL:CheckBox(strLabel, adminOnly)
	local left = vgui.Create( "DBetterCheckBoxLabel", self.panel )
	left:SetPos(8, itemCount)
	left:SetFont(self:GetDefaultFont())
	left:SetAdminOnly(adminOnly)
	left:SetTextColor(checkboxTextColor)
	left:SetText( strLabel )

	itemCount = itemCount + left:GetTall()
	table.insert( self.Items, left )

	return left
end

/*
    todo:
        - no need for default check due to cvars
        - separate it to avoid bloat
*/
function PANEL:MultiCheckBox( nrChecked, strLabel, adminOnly, optionNumber )
	local multiCheck = vgui.Create( "Panel", self.panel )
	multiCheck:SetPos(8, itemCount)

	local left = vgui.Create( "DBetterCheckBoxLabel", multiCheck )
	left.Toggle = function() end
	left.box:SetVisible(false)
	left.label:SetPos(0, 0)
	left:SetFont(self:GetDefaultFont())
	left:SetAdminOnly(adminOnly)
	left:SetTextColor(checkboxTextColor)
	left:SetText( strLabel )

	multiCheck:SetSize(left:GetWide() + 100, 40)

	if optionNumber then
		for i = 1, optionNumber do
			local option = vgui.Create( "DBetterCheckBoxLabel", multiCheck )
			option:SetID(i)
			-- option.box.DoClick = option.box.ToggleOne
			-- option.Toggle = option.ToggleOne
			left:addCheckbox(i, option)
			option:SetFont(self:GetDefaultFont())
			option:SetTextColor(checkboxTextColor)
			option.y = 20
		end
		if nrChecked then
			if !isnumber(nrChecked) then nrChecked = 1 end
			left.box.child[tonumber(nrChecked)]:SetChecked(true)
		end

		 for k,optionCheckbox in pairs(left.box.child) do
			optionCheckbox.box.child = left.box.child
		 end
	end

	itemCount = itemCount + multiCheck:GetTall()
	table.insert( self.Items, left )

	return left, left.box.child
end

function PANEL:Rebuild()
end

function PANEL:OnMouseWheeled( dlta )
	if ( !IsValid( self.VBar ) ) then return end
	return self.VBar:OnMouseWheeled( dlta )
end

function PANEL:PerformLayout(w, h)
	local YPos = 0

	if IsValid( self.VBar ) then
		self.VBar:SetPos( w - 16, 0 )
		self.VBar:SetSize( 16, h)
		self.VBar:SetUp( self.VBar:GetTall(), self.panel:GetTall() )

		YPos = self.VBar:GetOffset()
		self.VBar:InvalidateLayout()
	end

	if self.VBar.Enabled then
		self.panel:SetSize( w - 16, itemCount )
	else
		self.panel:SetSize( w, itemCount )
	end

	self.panel:SetPos( 0, YPos )
end

function PANEL:PaintScroll(gripColor, gripBG)
	self.VBar.Paint = function(panel, w, h)
		if istable(gripBG) then
			surface.SetDrawColor(gripBG)
			surface.DrawRect(0, 0, w, h)
		end
		panel.btnGrip.Paint = function(panelGrip)
			surface.SetDrawColor(gripColor)
			surface.DrawRect(0, 0, w, h)
		end
	end
end

derma.DefineControl( "DOptions", "Settings Page", PANEL, "Panel" )
