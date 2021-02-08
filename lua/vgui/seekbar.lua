local PANEL = {}

local round = math.Round
local textColor = Color(255, 255, 255)
local slideColor = Color(0, 0, 0, 100)

function PANEL:Init()
	self.allow = true

	self.TextCurrent = self:Add("DTextEntry")
	self.TextCurrent:DockMargin(5, 0, 0, 0)
	self.TextCurrent:Dock(LEFT)
	self.TextCurrent:SetPaintBackground(false)
	self.TextCurrent:SetWide(45)
	self.TextCurrent:SetEditable(false)
	self.TextCurrent:SetVisible(false)
	self.TextCurrent.Paint = function(panel, w, h)
		if ( panel.m_bBackground ) then
			if ( panel:GetDisabled() ) then
				self.tex.TextBox_Disabled( 0, 0, w, h )
			elseif ( panel:HasFocus() ) then
				self.tex.TextBox_Focus( 0, 0, w, h )
			else
				self.tex.TextBox( 0, 0, w, h )
			end
		end
		panel:DrawTextEntryText( textColor, textColor, textColor)
	end

	self.TextLength = vgui.Create("DTextEntry", self)
	self.TextLength:Dock(RIGHT)

	self.TextLength:SetPaintBackground(false)
	self.TextLength:SetWide(45)
	self.TextLength:SetEditable(false)
	self.TextLength:SetVisible(false)
	self.TextLength.Paint = function(panel, w, h)
		if ( panel.m_bBackground ) then
			if ( panel:GetDisabled() ) then
				self.tex.TextBox_Disabled( 0, 0, w, h )
			elseif ( panel:HasFocus() ) then
				self.tex.TextBox_Focus( 0, 0, w, h )
			else
				self.tex.TextBox( 0, 0, w, h )
			end

		end
		panel:DrawTextEntryText(textColor, textColor, textColor)
	end

    local right_margin = 15
	self.Slider = self:Add("DSlider", self)
	self.Slider:SetSlideY(0)
	self.Slider:SetLockY(0)
	self.Slider.TranslateValues = function(slider, x, y) return self:TranslateSliderValues(x, y) end
	self.Slider:SetTrapInside(true)
	self.Slider:Dock(FILL)
    self.Slider:DockMargin(0, 0, right_margin, 0)
	self.Slider:SetHeight(self:GetTall())
	self.Slider.Paint = function( panel, w, h )
		surface.SetDrawColor(slideColor)
		surface.DrawRect( 0, h / 2 - 1, w, 1 )

		surface.DrawRect( w / 4, h / 2 + 3, 1, 5 )
		surface.DrawRect( w / 2, h / 2 + 3, 1, 5 )
		surface.DrawRect( w - (w / 4), h / 2 + 3, 1, 5 )
	end
	self.Slider.Knob.Paint = function(panel, w, h)
		surface.SetDrawColor( textColor )
		surface.DrawRect( 0, 5, w, self:GetTall() - 8 )
	end

	self.SeekClick = vgui.Create("DSeekBarClickLayer", self)
	self.SeekClick:Dock(FILL)
    self.SeekClick:DockMargin(0, 0, right_margin, 0)

	self.Scratch = self:Add("DNumberScratch")
	self.Scratch:SetImageVisible(false)
	self.Scratch:SetDecimals(1)
	self.Scratch:SetTextColor(textColor)
	self.Scratch:Dock(FILL)

	self:SetTime(0)
	self:SetMin(0)
	self:SetMax(0)
	self:SetText("")
	self.TextCurrent:SetValue(string.ToMinutesSeconds(0))
	self.Scratch:SetFloatValue(0)
	self.Wang = self.Scratch
end

function PANEL:isAllowed()
	return self.allow
end

function PANEL:AllowSeek(bool)
    self.allow = bool
end

function PANEL:ReleaseSeek()
    self.SeekClick:OnMouseReleased()
end

function PANEL:SetTextFont(font)
	self.TextCurrent:SetFont(font)
	self.TextLength:SetFont(font)
end

function PANEL:SetTextColor(color)
	textColor = color
	self.TextCurrent.Paint(self.TextCurrent, self.TextCurrent:GetWide(), self.TextCurrent:GetTall())
	self.TextLength.Paint(self.TextLength, self.TextLength:GetWide(), self.TextLength:GetTall())
	self.Slider.Knob.Paint(self.Slider.Knob, self.Slider.Knob:GetWide(), self.Slider.Knob:GetTall())
end

function PANEL:SetSliderColor(color)
	slideColor = color
end

function PANEL:ResetValue()
	self.TextCurrent:SetValue(string.ToMinutesSeconds(self:GetMin()))
	self:SetTime(self:GetMin())
	self:SetMax(self:GetMin())
end

function PANEL:Invisible()
	self.Slider.Knob:SetVisible(false)
	self.Slider.Paint = function() end
	self.Paint = function() end
end

function PANEL:DisableNotches()
	self.Slider:SetNotches( nil )
	return true
end

function PANEL:ShowSeekTime()
	self.TextCurrent:SetVisible(true)
end

function PANEL:ShowSeekLength()
	self.TextLength:SetVisible(true)
end

function PANEL:SetMinMax(min, max)
	self.TextLength:SetValue(string.ToMinutesSeconds(tonumber(max)))
	self.Scratch:SetMin(tonumber(min))
	self.Scratch:SetMax(tonumber(max))
	self.SeekClick:SetMin(tonumber(min))
	self.SeekClick:SetMax(tonumber(max))
	self:UpdateNotches()
end

function PANEL:GetMin()
	return self.Scratch:GetMin()
end

function PANEL:GetMax()
	return self.Scratch:GetMax()
end

function PANEL:GetRange()
	return self:GetMax() - self:GetMin()
end

function PANEL:SetMin(min)
	if (not min) then
		min = 0
	end

	self.Scratch:SetMin(tonumber(min))
	self.SeekClick:SetMin(tonumber(min))
	self:UpdateNotches()
end

function PANEL:SetMax(max)
	if (not max) then
		max = 0
	end

	self.TextLength:SetValue(string.ToMinutesSeconds(tonumber(max)))
	self.Scratch:SetMax(tonumber(max))
	self.SeekClick:SetMax(tonumber(max))
	self:UpdateNotches()
end

function PANEL:GetValue()
	return self.SeekClick:GetValue()
end

function PANEL:IsEditing()
	return self.Scratch:IsEditing() or self.TextLength:IsEditing() or self.TextCurrent:IsEditing() or self.Slider:IsEditing()
end

function PANEL:IsHovered()
	return self.Scratch:IsHovered() or self.TextLength:IsHovered() or self.TextCurrent:IsHovered() or self.Slider:IsHovered() or vgui.GetHoveredPanel() == self
end

function PANEL:ValueChanged(val)
	local tmp1 = self:GetMin()
	local tmp2 = self:GetMax()

	if val < tmp1 then
		val = tmp1
	elseif val > tmp2 then
		val = tmp2
	end

	if self.TextCurrent ~= vgui.GetKeyboardFocus() then
		self.TextCurrent:SetValue(string.ToMinutesSeconds(self.Scratch:GetFloatValue()))
	end

	local delta = self.Scratch:GetFraction(val)

	self.TextLength:SetValue(string.ToMinutesSeconds(tmp2))
	self.Slider:SetSlideX(delta)

	if round(delta, 3) == 1 then
		self.allow = false
	end

end

function PANEL:TranslateSliderValues(x, y)
	self:SetTime(self.Scratch:GetMin() + (x * self.Scratch:GetRange()))
	return self.Scratch:GetFraction(), y
end

function PANEL:SetTime( val )
	if not self.allow then return end

	val = tonumber(val)
	local tmp1 = self:GetMin()
	local tmp2 = self:GetMax()

	if (val < tmp1) then
		val = tmp1
	elseif (val > tmp2) then
		val = tmp2
	end

	self.SeekClick:SetFloatValue(val)
	self.Scratch:SetFloatValue(val)
	self.TextCurrent:SetValue(string.ToMinutesSeconds(val))

	self:ValueChanged(val)
end

function PANEL:GetSeekTime( isfloat )
	if isfloat then
		return self.Scratch:GetFloatValue()
	else
		return self.TextCurrent:GetValue()
	end
end

function PANEL:GetSeekLength( isfloat )
	if isfloat then
		return self:GetMax()
	else
		return self.TextLength:GetValue()
	end
end

function PANEL:UpdateNotches()
	if self:DisableNotches() then
		self.Slider:SetNotches(self:GetMax() / 30)
	end
end

function PANEL:PerformLayout()
	self.Scratch:SetVisible(false)
	self.Slider:StretchToParent(0, 0, 0, 0)
	self.Slider:SetSlideX(self.Scratch:GetFraction())
end

derma.DefineControl("DSeekBar", "SeekBar Panel", PANEL, "Panel")