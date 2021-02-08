local PANEL = {}

local leftList = {}
local rightList = {}

local midPanelH = 0

local dialogWhite = Color(255, 255, 255)
local lineTextColor
local dialogRebuild = nil

function PANEL:Init()
	self.midPanel = vgui.Create("Panel", self)
	self.midPanel:Dock(TOP)
	midPanelH = self.midPanel:GetTall() - 1

	self.list1 = vgui.Create("DListView", self)
	self.list1:SetPos(0, self.midPanel:GetTall())
	self.column1 = self.list1:AddColumn( "Folders from ROOT" )

	self.list1.OnRowRightClick = function(line, lineIndex)
		if self.list1:GetLine(lineIndex):IsSelected() then
			self.list1:GetLine(lineIndex):SetSelected(false)
		end
	end

	self.list2 = vgui.Create("DListView", self)
	self.list2:SetPos(self.list1:GetWide(), 0)
	self.column2 = self.list2:AddColumn( "Active Folders" )

	self.list2.OnRowRightClick = function(line, lineIndex)
		if self.list2:GetLine(lineIndex):IsSelected() then
			self.list2:GetLine(lineIndex):SetSelected(false)
		end
	end

	self.btnRebuildMid = self.midPanel:Add("DButton")
	self.btnRebuildMid:SetSize(80, midPanelH)
	self.btnRebuildMid:SetFont("default")
	self.btnRebuildMid:SetText("Rebuild List")
	self.btnRebuildMid.DoClick = function()
		if !IsValid(dialogRebuild) then
			self:OnButtonRebuild()
		end
	end

	self.btnAddMid = self.midPanel:Add("DButton")
	self.btnAddMid:SetFont("default")
	self.btnAddMid:SetText("Add Folder")
	self.btnAddMid:SetPos(self.btnRebuildMid:GetWide(), 0)
	self.btnAddMid.DoClick = function() self:OnButtonAdd() end

	self.btnRemMid = self.midPanel:Add("DButton")
	self.btnRemMid:SetFont("default")
	self.btnRemMid:SetText("Remove Folder")
	self.btnRemMid.DoClick = function() self:OnButtonRem() end
end

function PANEL:selectFirstLine()
	if !isnumber(self.list1:GetSelectedLine()) then
		self.list1:SelectFirstItem()
	end

	if !isnumber(self.list2:GetSelectedLine()) then
		self.list2:SelectFirstItem()
	end
end

function PANEL:getLeftList()
	return self.list1
end
function PANEL:getRightList()
	return self.list2
end

function PANEL:populateLeftList()
	local stringTable = {}
	for k,v in pairs(leftList) do
		table.insert(stringTable,v:GetColumnText(1))
	end
	return stringTable
end
function PANEL:populateRightList()
	local stringTable = {}
	for k,v in pairs(rightList) do
		table.insert(stringTable,v:GetColumnText(1))
	end
	return stringTable
end


function PANEL:OnButtonRebuild()
	dialogRebuild = vgui.Create( "DFrame" )
	dialogRebuild:SetSize( 400, 200 )
	dialogRebuild:SetDeleteOnClose( true )
	dialogRebuild:ShowCloseButton(false)
	dialogRebuild:Center()
	dialogRebuild:SetTitle( "Confirm rebuilding the list folders!" )
	dialogRebuild:MoveToFront()

	dialogRebuild.Label = vgui.Create( "RichText", dialogRebuild )
	dialogRebuild.Label:SetVerticalScrollbarEnabled(false)
	dialogRebuild.Label:Dock(FILL)
	dialogRebuild.Label:InsertColorChange( dialogWhite.r, dialogWhite.g, dialogWhite.b, dialogWhite.a )
	dialogRebuild.Label:AppendText("Are you sure you want to rebuild the search list?\n\nThis could take longer depending on the amount of folders.")
	dialogRebuild.Label.Paint = function(panel)
		panel:SetFontInternal( "GModNotify" )
		panel.Paint = nil
	end

	local bottomPanel = vgui.Create("Panel", dialogRebuild)
	bottomPanel:Dock(BOTTOM)


	bottomPanel.btnNo = vgui.Create( "DButton", bottomPanel )
	bottomPanel.btnNo:Dock(RIGHT)
	bottomPanel.btnNo:DockMargin(4, 0, 0, 0)
	bottomPanel.btnNo:SetText( "No" )
    bottomPanel.btnNo:SetTextColor(Color(0, 0, 0))
	bottomPanel.btnNo:SetFont( "GModNotify" )
	bottomPanel.btnNo.Paint = function(panel, w, h)
		surface.SetDrawColor( dialogWhite )
		surface.DrawRect( 0, 0, w, h )
	end
	bottomPanel.btnNo.DoClick = function()
		dialogRebuild:Close()
	end

	bottomPanel.btnYes = vgui.Create( "DButton", bottomPanel )
	bottomPanel.btnYes:Dock(FILL)
	bottomPanel.btnYes:SetText( "YES" )
    bottomPanel.btnYes:SetTextColor(Color(0, 0, 0))
	bottomPanel.btnYes:SetFont( "GModNotify" )
	bottomPanel.btnYes.Paint = function(panel, w, h)
		surface.SetDrawColor( dialogWhite )
		surface.DrawRect( 0, 0, w, h )
	end
	bottomPanel.btnYes.DoClick = function()
		self:OnRebuild()
		dialogRebuild:Close()
	end
end

function PANEL:SetInfoColor(color)
	local col
	if istable(color) then col = color
	else col = lineTextColor end

	self.column1.Header:SetTextColor(col)
	self.column2.Header:SetTextColor(col)

	self.btnRebuildMid:SetTextColor(col)
	self.btnAddMid:SetTextColor(col)
	self.btnRemMid:SetTextColor(col)
end

function PANEL:SetTextColor(lineTextColor_)
	lineTextColor = lineTextColor_
	for _, line in pairs(self.list1.Lines) do
		line.Columns[1]:SetTextColor(lineTextColor_)
	end
	for _, line in pairs(self.list2.Lines) do
		line.Columns[1]:SetTextColor(lineTextColor_)
	end
end

function PANEL:OnRebuild()
end

function PANEL:OnButtonAdd()
	for k,v in pairs(self.list1:GetSelected()) do
		self.list2:AddLine(v:GetColumnText(1)).Columns[1]:SetTextColor(lineTextColor)
		self.list1:RemoveLine(v:GetID())
	end

	leftList, rightList =  self.list1:GetLines(), self.list2:GetLines()
	self:OnAdd()
end
function PANEL:OnAdd()
end

function PANEL:OnButtonRem()
	for k,v in pairs(self.list2:GetSelected()) do
		self.list1:AddLine(v:GetColumnText(1)).Columns[1]:SetTextColor(lineTextColor)
		self.list2:RemoveLine(v:GetID())
	end

	leftList, rightList =  self.list1:GetLines(), self.list2:GetLines()
	self:OnRemove()
end
function PANEL:OnRemove()
end


function PANEL:AddLineLeft(text)
	self.list1:AddLine(text).Columns[1]:SetTextColor(lineTextColor)
end
function PANEL:AddLineRight(text)
	self.list2:AddLine(text).Columns[1]:SetTextColor(lineTextColor)
end


function PANEL:clearLeft()
	self.list1:Clear()
end
function PANEL:clearRight()
	self.list2:Clear()
end

function PANEL:PerformLayout()
	local mainX = self:GetWide()
	local mainY = self:GetTall() - 25

	self.list1:SetSize(mainX / 2, mainY)

	self.btnAddMid:SetSize(mainX / 2, midPanelH)
	self.btnRemMid:SetPos(mainX / 2 + self.btnRebuildMid:GetWide(), 0)
	self.btnRemMid:SetSize(mainX - mainX / 2 - self.btnRebuildMid:GetWide(), midPanelH)

	self.list2:SetPos(mainX / 2, self.midPanel:GetTall())
	self.list2:SetSize(mainX - mainX / 2, mainY)
end

function PANEL:PaintList(listColor)
	self.list1.Paint = function(panel, w, h)
		surface.SetDrawColor( listColor )
		surface.DrawRect(0, 0, w, h)
	end
	self.list2.Paint = function(panel, w, h)
		surface.SetDrawColor( listColor )
		surface.DrawRect(0, 0, w, h)
	end
end

function PANEL:PaintScroll(gripColor, gripBG, arrowColor)
	self.list1.VBar.Paint = function(panel, w, h)
		if istable(gripBG) then
			surface.SetDrawColor(gripBG)
			surface.DrawRect(0, 0, w, h)
		end

		panel.btnGrip.Paint = function(panelGrip)
			surface.SetDrawColor(gripColor)
			surface.DrawRect(0, 0, w, h)
		end
		panel.btnUp.Paint = function(gripUp, wUp, hUp)
			surface.SetDrawColor( gripColor )
			surface.DrawRect(0, 0, wUp, hUp)
			surface.SetFont("Marlett")
			surface.SetTextPos(2, 2)
			surface.SetTextColor(arrowColor)
			surface.DrawText("5")
		end
		panel.btnDown.Paint = function(gripUp, wUp, hUp)
			surface.SetDrawColor( gripColor )
			surface.DrawRect(0, 0, wUp, hUp)
			surface.SetFont("Marlett")
			surface.SetTextPos(2, 1)
			surface.SetTextColor(arrowColor)
			surface.DrawText("6")
		end
	end

	self.list2.VBar.Paint = function(panel, w, h)
		if istable(gripBG) then
			surface.SetDrawColor(gripBG)
			surface.DrawRect(0, 0, w, h)
		end
		panel.btnGrip.Paint = function(panelGrip)
			surface.SetDrawColor(gripColor)
			surface.DrawRect(0, 0, w, h)
		end
		panel.btnUp.Paint = function(gripUp, wUp, hUp)
			surface.SetDrawColor( gripColor )
			surface.DrawRect(0, 0, wUp, hUp)
			surface.SetFont("Marlett")
			surface.SetTextPos(2, 2)
			if istable(arrowColor) then surface.SetTextColor(arrowColor)
			else surface.SetTextColor(Color(255, 255, 255)) end
			surface.DrawText("5")
		end
		panel.btnDown.Paint = function(gripUp, wUp, hUp)
			surface.SetDrawColor( gripColor )
			surface.DrawRect(0, 0, wUp, hUp)
			surface.SetFont("Marlett")
			surface.SetTextPos(2, 1)
			if istable(arrowColor) then surface.SetTextColor(arrowColor)
			else surface.SetTextColor(Color(255, 255, 255)) end
			surface.DrawText("6")
		end
	end
end

function PANEL:PaintColumn(bgColumn)
	self.column1.Header.Paint = function(panel, w, h)
		surface.SetDrawColor( bgColumn )
		surface.DrawRect(0, 0, w, h)
	end
	self.column2.Header.Paint = function(panel, w, h)
		surface.SetDrawColor( bgColumn )
		surface.DrawRect(0, 0, w, h)
	end
end

function PANEL:PaintHoverColumn(bgHover)
	self.column1.Header.PaintOver = function(panel, w, h)
		if panel:IsHovered() then
			surface.SetDrawColor( bgHover )
			surface.DrawRect(0, 0, w, h)
		end
	end
	self.column2.Header.PaintOver = function(panel, w, h)
		if panel:IsHovered() then
			surface.SetDrawColor( bgHover )
			surface.DrawRect(0, 0, w, h)
		end
	end
end

derma.DefineControl( "DDoubleListView", "Double List View", PANEL, "Panel" )
