local PANEL = {}
local linePos = 0
local prevSelect = nil

local text_color = Color(255, 255, 255)
local bg_color_hover = Color(230, 230, 230, 50)

AccessorFunc( PANEL, "m_bDirty", "Dirty", FORCE_BOOL )
AccessorFunc( PANEL, "m_bSortable", "Sortable", FORCE_BOOL )

AccessorFunc( PANEL, "m_FontName", "Font" )
AccessorFunc( PANEL, "m_iHeaderHeight", "HeaderHeight" )
AccessorFunc( PANEL, "m_iDataHeight", "DataHeight" )

AccessorFunc( PANEL, "m_bHideHeaders", "HideHeaders" )

Derma_Hook( PANEL, "Paint", "Paint", "ListView" )

function PANEL:Init()
	self.m_FontName = "default"
	self.sort = false
	self.selectedK = nil
	self.m_iHeaderHeight = 0

	self:SetSortable( true )
	self:SetMouseInputEnabled( true )
	self:SetHideHeaders( false )

	self:SetHeaderHeight( 16 )
	self:SetDataHeight( 20 )

	self.Columns = {}
    /*
        The lines to be added to the panel
    */
	self.Lines = {}
	self:SetDirty( true )

	self.container = vgui.Create("Panel" ,self)
	self.panelLine = vgui.Create("Panel", self.container)

	self.VBar = vgui.Create( "DSimpleScroll", self )
	self.VBar:SetZPos( 20 )
end

function PANEL:IsEmpty()
    return table.IsEmpty(self.Lines)
end

function PANEL:RefreshLayout(w, h)
	-- The lines should be attached to a parent
	self:SetSize(w, h)
	self.VBar:SetScroll(self.VBar:GetScroll())
	for k, line in pairs(self.Lines) do
		self.Lines[k]:SetWide(w)
		self.Lines[k].Columns[0]:SetWide(w)
	end
end

function PANEL:SetHeaderHeight(val)
	self.m_iHeaderHeight = val
end
function PANEL:GetHeaderHeight()
	return self.m_iHeaderHeight
end

function PANEL:SetHideHeaders(bool)
	self.m_bHideHeaders = bool
	if bool then
		self.m_iHeaderHeight = 0
	end
end

function PANEL:SetTextColor(text_color_)
	text_color = text_color_
	for _, line in pairs(self.Lines) do
		line:SetTextColor(text_color)
	end
end

/*
    Hover bg for each item
*/
function PANEL:SetHoverBGColor(hover_color)
    bg_color_hover = hover_color
	for _, line in pairs(self.Lines) do
        line:SetHoverBG(bg_color_hover)
	end
end

function PANEL:DisableScrollbar()
	if IsValid( self.VBar) then
		self.VBar:Remove()
	end

	self.VBar = nil
end

function PANEL:ResetColor(index)
	self.Lines[index]:SetTextColor(text_color)
end

function PANEL:HighlightLine(index, color, txtcolor)
    local line = self.Lines[index]
    if !IsValid(line) then return end

	if txtcolor then
		line:SetTextColor(txtcolor)
	end
	if color then
		line.Paint = function(panel, w, h)
			surface.SetDrawColor(color)
			surface.DrawRect(0, 0, w, h)
		end
	else
		line.Paint = function() end
		self:ResetColor(index)
	end
end

function PANEL:GetLines()
	return self.Lines
end

function PANEL:AddColumn( strName )
	if self.m_bHideHeaders then return end

	local pColumn = vgui.Create( "DBetterColumn", self )
	pColumn:SetTall(self.m_iHeaderHeight)
	pColumn:SetText(strName)
	pColumn:SetTextColor(Color(255, 255, 255))
	pColumn:SetContentAlignment( 5 )
	pColumn.DoClick = function(panel)
		self.sort = !self.sort
		self:SetDirty(true)
	end
	pColumn:Dock(TOP)

	table.insert(self.Columns, pColumn)
	self:InvalidateLayout()
	return pColumn
end

function PANEL:RemoveLine( LineID )
	local Line = self:GetLine( LineID )

	self.Lines[ LineID ] = nil

	self:SetDirty( true )
	self:InvalidateLayout()

	Line:Remove()
end

function PANEL:ColumnWidth( i )
	local ctrl = self.Columns[ i ]
	if ( !ctrl ) then return 0 end

	return ctrl:GetWide()
end

function PANEL:FixColumnsLayout()
	local colHeight = self:GetDataHeight()
	local NumLines = #self.Lines + 1

	if ( NumColumns == 0 ) then return end

	local posY = 0

	if self.sort then
		for k, line in pairs(self.Lines) do
			self.Lines[NumLines - k]:SetPos(0, posY)
			posY = posY + colHeight
		end
	else
		for k, line in pairs(self.Lines) do
			self.Lines[k]:SetPos(0, posY)
			posY = posY + colHeight
		end
	end
end


function PANEL:PerformLayout(w, h)
	local YPos = 0

	if IsValid( self.VBar ) then
		self.VBar:SetPos(w - 16, 0)
		self.VBar:SetSize(16, h)

		YPos = self.VBar:GetOffset()
		if table.IsEmpty(self.Columns) then
			self.VBar:SetUp( self.VBar:GetTall(), self.panelLine:GetTall())
			self.container:SetPos(0, 0)
		else
			self.VBar:SetUp( self.VBar:GetTall(), self.panelLine:GetTall() + self.m_iHeaderHeight)
			self.container:SetPos(0, self.m_iHeaderHeight)
		end

		self.VBar:InvalidateLayout()
	end

	if self.VBar.Enabled then
		self.panelLine:SetSize( w - 16, linePos )
	else
		self.panelLine:SetSize( w, linePos )
	end
	self.container:SetSize( w, h )

	self.panelLine:SetPos( 0, YPos )
	if self:GetDirty() then
		self:SetDirty( false )
		self:FixColumnsLayout()
	end
end

function PANEL:Think()
	if self:GetDirty() then
		self:InvalidateLayout()
	end
end

function PANEL:OnScrollbarAppear()
	self:SetDirty( true )
	self:InvalidateLayout()
end

function PANEL:AddLine(strLine)
	self:SetDirty(true)
	self:InvalidateLayout()

	local Line = vgui.Create( "DBetterLine", self.panelLine )
	Line:SetFont(self.m_FontName)
	Line.BeforeMousePress = function(panel, index)
		self:BeforeMousePress(index)
	end
	Line.DoClick = function(panel, index)
		if IsValid(self.Lines[prevSelect]) then
			self.Lines[prevSelect]:SetSelected(false)
		end
		prevSelect = index
		self:DoClick(index)
	end
	Line.DoRightClick = function(panel, index, line)
		self:DoRightClick(index, line)
	end
	Line.DoDoubleClickInternal = function(panel, line)
		self:BeforeDoubleClick(line)
	end
	Line.DoDoubleClick = function(panel, index, line)
		self.selectedK = index
		self:DoDoubleClick(index, line)
	end

	Line:SetTall(self.m_iDataHeight)
	Line:SetWide(self:GetWide())

	Line:SetPos(0, linePos)
	linePos = linePos + self.m_iDataHeight

    Line:SetTextColor(text_color)
    Line:SetHoverBG(bg_color_hover)
	Line:SetColumnText( 0, strLine )

	local indexID = table.insert(self.Lines, Line)
	Line:SetID(indexID)

	return Line
end

function PANEL:OnMouseWheeled( dlta )
	if ( !IsValid( self.VBar ) ) then return end
	return self.VBar:OnMouseWheeled( dlta )
end

function PANEL:SetSelectedLine(line)
	self.selectedK = line
end

function PANEL:GetSelectedLine()
	-- for k, Line in pairs( self.Lines ) do
	-- 	if Line:IsSelected() then return k end
	-- end
	return self.selectedK
end

function PANEL:GetLine( id )
	return self.Lines[ id ]
end

function PANEL:BeforeMousePress( index )
end

function PANEL:DoClick( index )
end

function PANEL:DoRightClick( index, line )
end

function PANEL:BeforeDoubleClick( line )
end

function PANEL:DoDoubleClick( index, line )
end

function PANEL:Clear()
	for k, v in pairs( self.Lines ) do
		v:Remove()
	end

	linePos = 0
	self.Lines = {}
	self:SetDirty( true )
end

function PANEL:GetSelected()

	local ret = {}

	for k, v in pairs( self.Lines ) do
		if ( v:IsLineSelected() ) then
			table.insert( ret, v )
		end
	end

	return ret

end

function PANEL:SizeToContents()
	self:SetHeight( self.panelLine:GetTall() )
end

function PANEL:GetLineColor()
	return text_color
end

function PANEL:PaintList(listColor)
	self.container.Paint = function(panel, w, h)
		surface.SetDrawColor(listColor)
		surface.DrawRect(0, 0, w, h)
	end
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

derma.DefineControl( "DBetterListView", "Better List", PANEL, "Panel" )
