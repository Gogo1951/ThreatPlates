local ADDON_NAME, NAMESPACE = ...
local ThreatPlates = NAMESPACE.ThreatPlates

---------------------------------------------------------------------------------------------------
-- Stuff fo7r handling the configuration of Threat Plates - ThreatPlatesDB
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- Imported functions and constants
---------------------------------------------------------------------------------------------------
local L = ThreatPlates.L
local RGB = ThreatPlates.RGB

---------------------------------------------------------------------------------------------------
-- Color definitions
---------------------------------------------------------------------------------------------------

ThreatPlates.COLOR_TAPPED = RGB(110, 110, 110, 1)	-- grey
ThreatPlates.COLOR_TRANSPARENT = RGB(0, 0, 0, 0, 0) -- opaque
ThreatPlates.COLOR_DC = RGB(128, 128, 128, 1) -- dray, darker than tapped color
ThreatPlates.COLOR_FRIEND = RGB(29, 39, 61) -- Blizzard friend dark blue
ThreatPlates.COLOR_GUILD = RGB(60, 168, 255) -- light blue

---------------------------------------------------------------------------------------------------
-- Global contstants for options
---------------------------------------------------------------------------------------------------

ThreatPlates.ANCHOR_POINT = { TOPLEFT = "Top Left", TOP = "Top", TOPRIGHT = "Top Right", LEFT = "Left", CENTER = "Center", RIGHT = "Right", BOTTOMLEFT = "Bottom Left", BOTTOM = "Bottom ", BOTTOMRIGHT = "Bottom Right" }
ThreatPlates.ANCHOR_POINT_SETPOINT = {
  TOPLEFT = {"TOPLEFT", "BOTTOMLEFT"},
  TOP = {"TOP", "BOTTOM"},
  TOPRIGHT = {"TOPRIGHT", "BOTTOMRIGHT"},
  LEFT = {"LEFT", "RIGHT"},
  CENTER = {"CENTER", "CENTER"},
  RIGHT = {"RIGHT", "LEFT"},
  BOTTOMLEFT = {"BOTTOMLEFT", "TOPLEFT"},
  BOTTOM = {"BOTTOM", "TOP"},
  BOTTOMRIGHT = {"BOTTOMRIGHT", "TOPRIGHT"}
}

ThreatPlates.ENEMY_TEXT_COLOR = {
  CLASS = "By Class",
  CUSTOM = "By Custom Color",
  REACTION = "By Reaction",
  HEALTH = "By Health",
}
-- "By Threat", "By Level Color", "By Normal/Elite/Boss"
ThreatPlates.FRIENDLY_TEXT_COLOR = {
  CLASS = "By Class",
  CUSTOM = "By Custom Color",
  REACTION = "By Reaction",
  HEALTH = "By Health",
}
ThreatPlates.ENEMY_SUBTEXT = {
  NONE = "None",
  HEALTH = "Percent Health",
  ROLE = "NPC Role",
  ROLE_GUILD = "NPC Role, Guild",
  ROLE_GUILD_LEVEL = "NPC Role, Guild, or Level",
  LEVEL = "Level",
  ALL = "Everything"
}
-- NPC Role, Guild, or Quest", "Quest",
ThreatPlates.FRIENDLY_SUBTEXT = {
  NONE = "None",
  HEALTH = "Percent Health",
  ROLE = "NPC Role",
  ROLE_GUILD = "NPC Role, Guild",
  ROLE_GUILD_LEVEL = "NPC Role, Guild, or Level",
  LEVEL = "Level",
  ALL = "Everything"
}
-- "NPC Role, Guild, or Quest", "Quest"

---------------------------------------------------------------------------------------------------
-- Global functions for accessing the configuration
---------------------------------------------------------------------------------------------------

local function GetUnitVisibility(unit_type)
  local unit_visibility = TidyPlatesThreat.db.profile.Visibility[unit_type]

  local show = unit_visibility.Show
  if type(show) ~= "boolean" then
    show = (GetCVar(show) == "1")
  end

  return show, unit_visibility.UseHeadlineView
end

local function SetNamePlateClickThrough(val_friendly, val_enemy)
  if InCombatLockdown() then
    ThreatPlates.Print("We're unable to change nameplate clickthrough while in combat", true)
  else
    local db = TidyPlatesThreat.db.profile

    if val_friendly ~= nil then
      db.NamePlateFriendlyClickThrough = val_friendly
      db.NamePlateEnemyClickThrough = val_enemy
    end

    C_NamePlate.SetNamePlateFriendlyClickThrough(db.NamePlateFriendlyClickThrough)
    C_NamePlate.SetNamePlateEnemyClickThrough(db.NamePlateEnemyClickThrough)
  end
end

---------------------------------------------------------------------------------------------------
-- Functions for configuration migration
---------------------------------------------------------------------------------------------------
local Defaults_V1 = {
  allowClass = false,
  friendlyClass = false,
  optionRoleDetectionAutomatic = false,
  HeadlineView = {
    width = 116,
  },
  text = {
    amount = true,
  },
  AuraWidget = {
    ModeBar = {
      Texture = "Smooth",
    },
  },
  uniqueWidget = {
    scale = 35,
    y = 24,
  },
  questWidget = {
    ON = false,
    ModeHPBar = true,
  },
  ResourceWidget  = {
    BarTexture = "Smooth"
  },
  settings = {
    elitehealthborder = {
      show = true,
    },
    healthborder = {
      texture = "TP_HealthBarOverlay",
    },
    healthbar = {
      texture = "ThreatPlatesBar",
      backdrop = "ThreatPlatesEmpty",
      BackgroundOpacity = 1,
    },
    castborder = {
      texture = "ThreatPlatesBar",
    },
    castbar = {
      texture = "ThreatPlatesBar",
    },
    name = {
      typeface = "Accidental Presidency",
      width = 116,
      size = 14,
    },
    level = {
      typeface = "Accidental Presidency",
      size = 12,
      height  = 14,
      x = 50,
      vertical  = "TOP"
    },
    customtext = {
      typeface = "Accidental Presidency",
      size = 12,
      y = 1,
    },
    spelltext = {
      typeface = "Accidental Presidency",
      size = 12,
      y = -13,
      y_hv  = -13,
    },
    eliteicon = {
      x = 64,
      y = 9,
    },
    skullicon = {
      x = 55,
    },
    raidicon = {
      y = 27,
      y_hv = 27,
    },
  },
  threat = {
    dps = {
      HIGH = 1.25,
    },
    tank = {
      LOW = 1.25,
    },
  },
}

local Defaults_V2 = {
  allowClass = true,
  friendlyClass = true,
  optionRoleDetectionAutomatic = true,
  HeadlineView = {
    width = 140,
  },
  text = {
    amount = false,
  },
  AuraWidget = {
    ModeBar = {
      Texture = "Aluminium",
    },
  },
  uniqueWidget = {
    scale = 22,
    y = 30,
  },
  questWidget = {
    ON = true,
    ModeHPBar = false,
  },
  ResourceWidget  = {
    BarTexture = "Aluminium"
  },
  settings = {
    elitehealthborder = {
      show = false,
    },
    healthborder = {
      texture = "TP_HealthBarOverlayThin",
    },
    healthbar = {
      texture = "Smooth",
      backdrop = "Smooth",
      BackgroundOpacity = 0.3,
    },
    castborder = {
      texture = "Smooth",
    },
    castbar = {
      texture = "Smooth",
    },
    name = {
      typeface = "Cabin",
      width = 140,
      size = 10,
    },
    level = {
      typeface = "Cabin",
      size = 9,
      height  = 10,
      x  = 49,
      vertical  = "CENTER"
    },
    customtext = {
      typeface = "Cabin",
      size = 9,
      y = 0,
    },
    spelltext = {
      typeface = "Cabin",
      size = 8,
      y = -14,
      y_hv  = -14,
    },
    eliteicon = {
      x = 61,
      y = 7,
    },
    skullicon = {
      x = 51,
    },
    raidicon = {
      y = 30,
      y_hv = 25,
    },
  },
  threat = {
    dps = {
      HIGH = 1.0,
    },
    tank = {
      LOW = 1.0,
    },
  },
}

local function SetDB(db, old_settings, new_settings)
  for key, old_value in pairs(old_settings) do
    if type(old_value) == "table" then
      SetDB(db[key], old_settings[key], new_settings[key])
    else
      if db[key] == new_settings[key] then -- value not changed, on new default
        db[key] = old_settings[key]
      end
    end
  end
end

local function DefaultSettingsV1()
  SetDB(TidyPlatesThreat.db.profile, Defaults_V1, Defaults_V2)
end

local function DefaultSettingsV2()
  SetDB(TidyPlatesThreat.db.profile, Defaults_V2, Defaults_V1)
end

--local function UpdateSettingValue(old_setting, key, new_setting, new_key)
--  if not new_key then
--    new_key = key
--  end
--
--  local value = old_setting[key]
--  if value then
--    if type(value) == "table" then
--      new_setting[new_key] = t.CopyTable(value)
--    else
--      new_setting[new_key] = value
--    end
--  end
--end

--local function ConvertHeadlineView(profile)
--  -- convert old entry and save it
--  if not profile.headlineView then
--    profile.headlineView = {}
--  end
--  profile.headlineView.enabled = old_value
--  -- delete old entry
--end
--
---- Entries in the config db that should be migrated and deleted
--local DEPRECATED_DB_ENTRIES = {
--  alphaFeatures = true,
--  optionSpecDetectionAutomatic = true,
--  alphaFeatureHeadlineView = ConvertHeadlineView, -- migrate to headlineView.enabled
--}
--
---- Remove all deprected Entries
---- Called whenever the addon is loaded and a new version number is detected
--local function DeleteDeprecatedEntries()
--  -- determine current addon version and compare it with the DB version
--  local db_global = TidyPlatesThreat.db.global
--
--
--  -- Profiles:
--  if db_global.version ~= tostring(ThreatPlates.Meta("version")) then
--    -- addon version is newer that the db version => check for old entries
--    for profile, profile_table in pairs(TidyPlatesThreat.db.profiles) do
--      -- iterate over all profiles
--      for key, func in pairs(DEPRECATED_DB_ENTRIES) do
--        if profile_table[key] ~= nil then
--          if DEPRECATED_DB_ENTRIES[key] == true then
--            ThreatPlates.Print ("Deleting deprecated DB entry \"" .. tostring(key) .. "\"")
--            profile_table[key] = nil
--          elseif type(DEPRECATED_DB_ENTRIES[key]) == "function" then
--            ThreatPlates.Print ("Converting deprecated DB entry \"" .. tostring(key) .. "\"")
--            DEPRECATED_DB_ENTRIES[key](profile_table)
--          end
--        end
--      end
--    end
--  end
--end

-- convert current aura widget settings to aura widget 2.0
--local function ConvertAuraWidget1(profile_name, profile)
--  local old_setting = profile.debuffWidget
--  ThreatPlates.Print (L["xxxxProfile "] .. profile_name .. L[": Converting settings from aura widget to aura widget 2.0 ..."])
--  if old_setting and not profile.AuraWidget then
--    ThreatPlates.Print (L["Profile "] .. profile_name .. L[": Converting settings from aura widget to aura widget 2.0 ..."])
--    profile.AuraWidget = {}
--    local new_setting = profile.AuraWidget
--    if not new_setting.ModeIcon then
--      new_setting.ModeIcon = {}
--    end
--
--    new_setting.scale = old_setting.scale
--    new_setting.FilterMode = old_setting.style
--    new_setting.FilterMode = old_setting.mode
--    new_setting.ModeIcon.Style = old_setting.style
--    new_setting.ShowTargetOnly = old_setting.targetOnly
--    new_setting.ShowCooldownSpiral = old_setting.cooldownSpiral
--    new_setting.ShowFriendly = old_setting.showFriendly
--    new_setting.ShowEnemy = old_setting.showEnemy
--
--    if old_setting.filter then
--      new_setting.FilterBySpell = ThreatPlates.CopyTable(old_setting.filter)
--    end
--    if old_setting.displays then
--      new_setting.FilterByType = ThreatPlates.CopyTable(old_setting.displays)
--    end
--    old_setting.ON = false
--    print ("debuffWidget: ", profile.debuffWidget.ON)
--  end
--end

--local function MigrateDatabase()
--  -- determine current addon version and compare it with the DB version
--  local db_global = TidyPlatesThreat.db.global
--
--  --  -- addon version is newer that the db version => check for old entries
--  --	if db_global.version ~= tostring(ThreatPlates.Meta("version")) then
--  -- iterate over all profiles
--  local db
--  for name, profile in pairs(TidyPlatesThreat.db.profiles) do
--    ConvertAuraWidget1(name, profile)
--  end
--  --	end
--end

-- Update the configuration file:
--  - convert deprecated settings to their new counterpart
-- Called whenever the addon is loaded and a new version number is detected
--local function UpdateConfiguration()
--  -- determine current addon version and compare it with the DB version
--  local db_global = TidyPlatesThreat.db.global
--
--  --  -- addon version is newer that the db version => check for old entries
--  --	if db_global.version ~= tostring(ThreatPlates.Meta("version")) then
--  -- iterate over all profiles
--  for name, profile in pairs(TidyPlatesThreat.db.profiles) do
--    -- ConvertAuraWidget1(name, profile)
--  end
--  --	end
--end

-----------------------------------------------------
-- External
-----------------------------------------------------

ThreatPlates.DefaultSettingsV1 = DefaultSettingsV1
ThreatPlates.DefaultSettingsV2 = DefaultSettingsV2

--ThreatPlates.UpdateConfiguration = UpdateConfiguration
--ThreatPlates.MigrateDatabase = MigrateDatabase
ThreatPlates.GetUnitVisibility = GetUnitVisibility
ThreatPlates.SetNamePlateClickThrough = SetNamePlateClickThrough