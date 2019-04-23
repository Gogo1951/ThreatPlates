﻿---------------------------------------------------------------------------------------------------
-- Main file for addon Threat Plates
---------------------------------------------------------------------------------------------------
local _, Addon = ...
local ThreatPlates = Addon.ThreatPlates

---------------------------------------------------------------------------------------------------
-- Imported functions and constants
---------------------------------------------------------------------------------------------------

-- Lua APIs
local tonumber, select, pairs = tonumber, select, pairs

-- WoW APIs
local SetNamePlateFriendlyClickThrough = C_NamePlate.SetNamePlateFriendlyClickThrough
local SetNamePlateEnemyClickThrough = C_NamePlate.SetNamePlateEnemyClickThrough
local IsInInstance = IsInInstance
local GetCVar, IsAddOnLoaded = GetCVar, IsAddOnLoaded
local GetNamePlates, GetNamePlateForUnit = C_NamePlate.GetNamePlates, C_NamePlate.GetNamePlateForUnit
local C_NamePlate_SetNamePlateFriendlySize, C_NamePlate_SetNamePlateEnemySize, Lerp =  C_NamePlate.SetNamePlateFriendlySize, C_NamePlate.SetNamePlateEnemySize, Lerp
local NamePlateDriverFrame = NamePlateDriverFrame
local UnitClass, GetSpecialization = UnitClass, GetSpecialization

-- ThreatPlates APIs
local TidyPlatesThreat = TidyPlatesThreat
local LibStub = LibStub
local L = ThreatPlates.L
local Meta = Addon.Meta

---------------------------------------------------------------------------------------------------
-- Global configs and funtions
---------------------------------------------------------------------------------------------------

Addon.PlayerClass = select(2, UnitClass("player"))

ThreatPlates.Print = function(val,override)
  local db = TidyPlatesThreat.db.profile
  if override or db.verbose then
    print(Meta("titleshort")..": "..val)
  end
end

function TidyPlatesThreat:SpecName()
  local _,name,_,_,_,role = GetSpecializationInfo(GetSpecialization(false,false,1),nil,false)
  if name then
    return name
  else
    return L["Undetermined"]
  end
end

local tankRole = L["|cff00ff00tanking|r"]
local dpsRole = L["|cffff0000dpsing / healing|r"]

function TidyPlatesThreat:RoleText()
  if Addon.PlayerRoleIsTank then
    return tankRole
  else
    return dpsRole
  end
end

---------------------------------------------------------------------------------------------------
-- Functions called by TidyPlates
---------------------------------------------------------------------------------------------------

------------------
-- ADDON LOADED --
------------------

StaticPopupDialogs["TidyPlatesEnabled"] = {
  preferredIndex = STATICPOPUP_NUMDIALOGS,
  text = "|cffFFA500" .. Meta("title") .. " Warning|r \n---------------------------------------\n" ..
    L["|cff89F559Threat Plates|r is no longer a theme of |cff89F559TidyPlates|r, but a standalone addon that does no longer require TidyPlates. Please disable one of these, otherwise two overlapping nameplates will be shown for units."],
  button1 = OKAY,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
  OnAccept = function(self, _, _) end,
}

StaticPopupDialogs["IncompatibleAddon"] = {
  preferredIndex = STATICPOPUP_NUMDIALOGS,
  text = "|cffFFA500" .. Meta("title") .. " Warning|r \n---------------------------------------\n" ..
    L["You currently have two nameplate addons enabled: |cff89F559Threat Plates|r and |cff89F559%s|r. Please disable one of these, otherwise two overlapping nameplates will be shown for units."],
  button1 = OKAY,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
  OnAccept = function(self, _, _) end,
}

function TidyPlatesThreat:ReloadTheme()
  -- Castbars have to be disabled everytime we login
  if self.db.profile.settings.castbar.show or self.db.profile.settings.castbar.ShowInHeadlineView then
    Addon:EnableCastBars()
  else
    Addon:DisableCastBars()
  end

  -- Recreate all TidyPlates styles for ThreatPlates("normal", "dps", "tank", ...) - required, if theme style settings were changed
  Addon:SetThemes(self)

  -- Re-read all cached settings, ideally do not update any UI elements here
  Addon:InitializeCustomNameplates()
  Addon:UpdateSettings()
  Addon.Widgets:InitializeAllWidgets() -- UpdateSettings and enable widgets

  -- Update existing nameplates as certain settings may have changed that are not covered by ForceUpdate()
  Addon:UIScaleChanged()

  -- Do this after combat ends, not in PLAYER_ENTERING_WORLD as it won't get set if the player is on combat when
  -- that event fires.
  Addon:CallbackWhenOoC(function() Addon:SetBaseNamePlateSize() end, L["Unable to change a setting while in combat."])
  Addon:CallbackWhenOoC(function()
    local db = self.db.profile
    SetNamePlateFriendlyClickThrough(db.NamePlateFriendlyClickThrough)
    SetNamePlateEnemyClickThrough(db.NamePlateEnemyClickThrough)
  end)

  -- CVars setup for nameplates of occluded units
  if TidyPlatesThreat.db.profile.nameplate.toggle.OccludedUnits then
    Addon:CallbackWhenOoC(function()
      Addon:SetCVarsForOcclusionDetection()
    end)
  end

  Addon.CVars:OverwriteBoolProtected("nameplateResourceOnTarget", self.db.profile.PersonalNameplate.ShowResourceOnTarget)

  local frame
  for _, plate in pairs(GetNamePlates()) do
    frame = plate and plate.TPFrame
    if frame and frame.Active then
      Addon:UpdateNameplateStyle(plate, frame.unit.unitid)
    end
  end

  -- Update all UI elements (frames, textures, ...)
  Addon:UpdateAllPlates()
end

function TidyPlatesThreat:CheckForFirstStartUp()
  local db = self.db.global

  if not self.db.char.welcome then
    self.db.char.welcome = true
    -- initialize roles for all available specs (level > 10) or set to default (dps/healing)
    for index=1, GetNumSpecializations() do
      self:SetRole(ThreatPlates.SPEC_ROLES[Addon.PlayerClass][index], index)
    end

    ThreatPlates.Print(L["Welcome to |cff89f559Threat Plates|r! Additional options can be found by typing '|cff89F559/tptp|r.'"], true)
  end

  local new_version = tostring(Meta("version"))
  if db.version ~= "" and db.version ~= new_version then
    -- migrate and/or remove any old DB entries
    Addon.MigrateDatabase(db.version)
  end
  db.version = new_version

  Addon:ACTIVE_TALENT_GROUP_CHANGED()
end

function TidyPlatesThreat:CheckForIncompatibleAddons()
  -- Check for other active nameplate addons which may create all kinds of errors and doesn't make
  -- sense anyway:
  if IsAddOnLoaded("TidyPlates") then
    StaticPopup_Show("TidyPlatesEnabled", "TidyPlates")
  end
  if IsAddOnLoaded("Kui_Nameplates") then
    StaticPopup_Show("IncompatibleAddon", "KuiNameplates")
  end
  if IsAddOnLoaded("ElvUI") and ElvUI[1].private.nameplates.enable then
    StaticPopup_Show("IncompatibleAddon", "ElvUI Nameplates")
  end
  if IsAddOnLoaded("Plater") then
    StaticPopup_Show("IncompatibleAddon", "Plater Nameplates")
  end
  if IsAddOnLoaded("SpartanUI") and SUI.DB.EnabledComponents.Nameplates then
    StaticPopup_Show("IncompatibleAddon", "SpartanUI Nameplates")
  end
end

---------------------------------------------------------------------------------------------------
-- AceAddon functions: do init tasks here, like loading the Saved Variables, or setting up slash commands.
---------------------------------------------------------------------------------------------------
-- Copied from ElvUI:
function Addon:SetBaseNamePlateSize()
  local db = TidyPlatesThreat.db.profile.settings

  local width = db.frame.width
  local height = db.frame.height
  if db.frame.SyncWithHealthbar then
    -- this wont taint like NamePlateDriverFrame.SetBaseNamePlateSize
    local zeroBasedScale = tonumber(GetCVar("NamePlateVerticalScale")) - 1.0
    local horizontalScale = tonumber(GetCVar("NamePlateHorizontalScale"))

    width = (db.healthbar.width - 10) * horizontalScale
    height = (db.healthbar.height + 35) * Lerp(1.0, 1.25, zeroBasedScale)

    db.frame.width = width
    db.frame.height = height
  end

  if not TidyPlatesThreat.db.profile.ShowFriendlyBlizzardNameplates then
    C_NamePlate_SetNamePlateFriendlySize(width, height)
  end
  C_NamePlate_SetNamePlateEnemySize(width, height)

  Addon:ConfigClickableArea(false)

  --local clampedZeroBasedScale = Saturate(zeroBasedScale)
  --C_NamePlate_SetNamePlateSelfSize(baseWidth * horizontalScale * Lerp(1.1, 1.0, clampedZeroBasedScale), baseHeight)
end

-- The OnInitialize() method of your addon object is called by AceAddon when the addon is first loaded
-- by the game client. It's a good time to do things like restore saved settings (see the info on
-- AceConfig for more notes about that).
function TidyPlatesThreat:OnInitialize()
  local defaults = ThreatPlates.DEFAULT_SETTINGS

  -- change back defaults old settings if wanted preserved it the user want's to switch back
  if ThreatPlatesDB and ThreatPlatesDB.global and ThreatPlatesDB.global.DefaultsVersion == "CLASSIC" then
    -- copy default settings, so that their original values are
    defaults = ThreatPlates.GetDefaultSettingsV1(defaults)
  end

  local db = LibStub('AceDB-3.0'):New('ThreatPlatesDB', defaults, 'Default')
  self.db = db

  local RegisterCallback = db.RegisterCallback
  RegisterCallback(self, 'OnProfileChanged', 'ProfChange')
  RegisterCallback(self, 'OnProfileCopied', 'ProfChange')
  RegisterCallback(self, 'OnProfileReset', 'ProfChange')

  -- Setup Interface panel options
  local app_name = ThreatPlates.ADDON_NAME
  local dialog_name = app_name .. " Dialog"
  LibStub("AceConfig-3.0"):RegisterOptionsTable(dialog_name, ThreatPlates.GetInterfaceOptionsTable())
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions(dialog_name, ThreatPlates.ADDON_NAME)

  -- Setup chat commands
  self:RegisterChatCommand("tptp", "ChatCommand")
end

local function SetCVarHook(name, value, c)
  if name == "NamePlateVerticalScale" then
    local db = TidyPlatesThreat.db.profile.Automation
    local isInstance, instanceType = IsInInstance()

    if not NamePlateDriverFrame:IsUsingLargerNamePlateStyle() then
      -- reset to previous setting
      Addon.CVars:RestoreFromProfile("nameplateGlobalScale")
    elseif db.SmallPlatesInInstances and isInstance then
      Addon.CVars:Set("nameplateGlobalScale", 0.4)
    end
  end
end

-- The OnEnable() and OnDisable() methods of your addon object are called by AceAddon when your addon is
-- enabled/disabled by the user. Unlike OnInitialize(), this may occur multiple times without the entire
-- UI being reloaded.
-- AceAddon function: Do more initialization here, that really enables the use of your addon.
-- Register Events, Hook functions, Create Frames, Get information from the game that wasn't available in OnInitialize
function TidyPlatesThreat:OnEnable()
  TidyPlatesThreat:CheckForFirstStartUp()
  TidyPlatesThreat:CheckForIncompatibleAddons()

  TidyPlatesThreat:ReloadTheme()

  -- Get updates for changes regarding: Large Nameplates
  hooksecurefunc("SetCVar", SetCVarHook)

  Addon:EnableEvents()
end

-- Called when the addon is disabled
function TidyPlatesThreat:OnDisable()
  -- DisableEvents()

  -- Reset all CVars to its initial values
  -- Addon.CVars:RestoreAllFromProfile()
end

-----------------------------------------------------------------------------------
-- Functions for keybindings
-----------------------------------------------------------------------------------

function TidyPlatesThreat:ToggleNameplateModeFriendlyUnits()
  local db = TidyPlatesThreat.db.profile

  db.Visibility.FriendlyPlayer.UseHeadlineView = not db.Visibility.FriendlyPlayer.UseHeadlineView
  db.Visibility.FriendlyNPC.UseHeadlineView = not db.Visibility.FriendlyNPC.UseHeadlineView
  db.Visibility.FriendlyTotem.UseHeadlineView = not db.Visibility.FriendlyTotem.UseHeadlineView
  db.Visibility.FriendlyGuardian.UseHeadlineView = not db.Visibility.FriendlyGuardian.UseHeadlineView
  db.Visibility.FriendlyPet.UseHeadlineView = not db.Visibility.FriendlyPet.UseHeadlineView
  db.Visibility.FriendlyMinus.UseHeadlineView = not db.Visibility.FriendlyMinus.UseHeadlineView

  Addon:ForceUpdate()
end

function TidyPlatesThreat:ToggleNameplateModeNeutralUnits()
  local db = TidyPlatesThreat.db.profile

  db.Visibility.NeutralNPC.UseHeadlineView = not db.Visibility.NeutralNPC.UseHeadlineView
  db.Visibility.NeutralMinus.UseHeadlineView = not db.Visibility.NeutralMinus.UseHeadlineView

  Addon:ForceUpdate()
end

function TidyPlatesThreat:ToggleNameplateModeEnemyUnits()
  local db = TidyPlatesThreat.db.profile

  db.Visibility.EnemyPlayer.UseHeadlineView = not db.Visibility.EnemyPlayer.UseHeadlineView
  db.Visibility.EnemyNPC.UseHeadlineView = not db.Visibility.EnemyNPC.UseHeadlineView
  db.Visibility.EnemyTotem.UseHeadlineView = not db.Visibility.EnemyTotem.UseHeadlineView
  db.Visibility.EnemyGuardian.UseHeadlineView = not db.Visibility.EnemyGuardian.UseHeadlineView
  db.Visibility.EnemyPet.UseHeadlineView = not db.Visibility.EnemyPet.UseHeadlineView
  db.Visibility.EnemyMinus.UseHeadlineView = not db.Visibility.EnemyMinus.UseHeadlineView

  Addon:ForceUpdate()
end