local PANEL = {}

Derma_Hook( PANEL, "Paint", "Paint", "CheckBox" )
Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "CheckBox" )
Derma_Hook( PANEL, "PerformLayout", "Layout", "CheckBox" )

Derma_Install_Convar_Functions( PANEL )

function PANEL:SetValue(val)
	local bVal
	if isbool(val) then	bVal = val
	elseif isnumber(val) then bVal = tobool(val) end

    if self:IsAdminOnly() then
		if LocalPlayer():IsAdmin() then
			self:SetChecked(bVal)
			self.m_bValue = bVal

			self:UpdateConVar()
		else
            // keep old value
			self:RefreshConVar()
		end
	else
		self:SetChecked(bVal)
		self.m_bValue = bVal

		self:UpdateConVar()
	end
end

function PANEL:Init()
	self.child = {}
	self.id = 0

    self.adminOnly = false
    /*
        Store local client admin status for realtime update
    */
    self.isAdmin = nil
	self:SetSize( 15, 15 )
	self:SetText( "" )
	self.checked = false
	self.cvar = nil
end

function PANEL:addCheckbox(index, checkbox)
	self.id = index
	self.child[index] = checkbox
end

function PANEL:SetID(val)
	self.id = val
end

function PANEL:SetAdminOnly(bVal)
    self.adminOnly = bVal
end

// Only admins are allowed to click on checkbox
function PANEL:IsAdminOnly()
    return self.adminOnly
end

function PANEL:AfterChange( val )
	-- override after a value has changed
end

function PANEL:OnCvarWrong(oldValue, newValue)
	-- override if any problem happened
end

function PANEL:PersistConvar(newCvar)
	self.cvar = newCvar
	if !ConVarExists(self.cvar:GetName()) then
		self.cvar:SetInt(self.cvar:GetDefault())
	end
	cvars.AddChangeCallback(
        self.cvar:GetName(), function(convar, oldValue, newValue)
		local tmp = tonumber(newValue)
		if isnumber(tmp) then
			self:SetValue(tmp)
			self:AfterChange(tmp)
		else
			self:OnCvarWrong(oldValue, newValue)
		end
	end )
end

function PANEL:ConVarChanged(strNewValue)
	if ( !self.m_strConVar ) then return end
    self:OnCvarChange(strNewValue)
	RunConsoleCommand( self.m_strConVar, strNewValue )
end


function PANEL:UpdateConVar()
	if self:GetChecked() then
		self:ConVarChanged("1")
	else
		self:ConVarChanged("0")
	end
end

function PANEL:RefreshConVar()
	if self:GetChecked() then
		self.cvar:SetString("1")
	else
		self.cvar:SetString("0")
	end
end


function PANEL:IsEditing()
	return self.Depressed
end

function PANEL:OnCvarChange(newval)
end

function PANEL:SetChecked(bool)
	self.checked = bool
end

function PANEL:GetChecked()
	return self.checked
end

function PANEL:DoClick()
	self:Toggle()
end

function PANEL:Toggle()
	if self:GetChecked() then
		self:SetValue( false )
	else
		self:SetValue( true )
	end
end

function PANEL:ConVarNumberThink()
	if ( !self.m_strConVar ) then -- if nil return false
	 return end
	local strValue = GetConVar(self.cvar:GetName()):GetInt()

	-- In case the convar is a "nan"
	if ( strValue != strValue ) then return end
	if ( self.m_strConVarValue == strValue ) then return end

	self.m_strConVarValue = strValue
	self:SetValue(self.m_strConVarValue)
end

function PANEL:Think()
    if self:IsVisible() then
        if self:IsAdminOnly() then
            if LocalPlayer():IsAdmin() then
                if self:GetDisabled() then self:SetEnabled(true) end
            else
                if !self:GetDisabled() then self:SetEnabled(false) end
            end
        end
        self:ConVarNumberThink()
    end
end


derma.DefineControl( "DBetterCheckBox", "CheckboxCustom", PANEL, "DButton" )