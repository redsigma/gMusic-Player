local PANEL = {}

AccessorFunc( PANEL, "ActiveButton", "ActiveButton" )

function PANEL:Init()
	self.Navigation = vgui.Create( "DScrollPanel", self )
	self.Navigation:SetWidth( 100 )
	self.Navigation:SetZPos(1)
	self.Navigation:MoveToFront()

	self.Content = vgui.Create( "Panel", self )

	self.Items = {}

	self:SetSize(self:GetParent():GetSize())
end

function PANEL:OnSideBarToggle(wide)
	--For override
end

function PANEL:ToggleSideBar()
	if self.Navigation:IsVisible() then
		self.Navigation:SetVisible(false)
		self:OnSideBarToggle(0)
		self:InvalidateLayout()
	else
		self.Navigation:SetVisible(true)
		self:OnSideBarToggle(self.Navigation:GetWide())
	end
end


function PANEL:UseButtonOnlyStyle()
	self.ButtonOnly = true
end

function PANEL:AddSheet( label, panel, material )

	if ( !IsValid( panel ) ) then return end

	local Sheet = {}

	if ( self.ButtonOnly ) then
		Sheet.Button = vgui.Create( "DImageButton", self.Navigation )
	else
		Sheet.Button = vgui.Create( "DButton", self.Navigation )
	end

	Sheet.Button:SetImage( material )
	Sheet.Button.Target = panel
	Sheet.Button:Dock( TOP )
	Sheet.Button:SetText( label )
	Sheet.Button:DockMargin( 0, 1, 0, 0 )

	Sheet.Button.DoClick = function()
		self:SetActiveButton( Sheet.Button )
	end

	Sheet.Panel = panel
	Sheet.Panel:SetParent( self.Content )
	Sheet.Panel:SetVisible( false )

	if ( self.ButtonOnly ) then
		Sheet.Button:SizeToContents()
	end

	table.insert( self.Items, Sheet )

	if ( !IsValid( self.ActiveButton ) ) then
		self:SetActiveButton( Sheet.Button )
	end

end

function PANEL:SetActiveButton( active )

	if ( self.ActiveButton == active ) then return end

	if ( self.ActiveButton && self.ActiveButton.Target ) then
		self.ActiveButton.Target:SetVisible( false )
		self.ActiveButton:SetSelected( false )
		self.ActiveButton:SetToggle( false )
	end

	self.ActiveButton = active
	active.Target:SetVisible( true )
	active:SetSelected( true )
	active:SetToggle( true )

	self.Content:InvalidateLayout()

end

function PANEL:IsVisible()
    return self.Navigation:IsVisible()
end

function PANEL:PerformLayout(width, height)
	if self.Navigation:IsVisible() then
		self.Content:SetSize(width - 100, height)
	else
		self.Content:SetSize(width, height)
	end
end

derma.DefineControl( "DSideMenu", "", PANEL, "Panel" )