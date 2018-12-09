local _, Addon = ...

-- Lua APIs

-- WoW APIs

-- ThreatPlates APIs
local Debug = Addon.Debug
local ThreatPlates = Addon.ThreatPlates

--------------------------------------------------------------------------------------------------
-- Local variables
---------------------------------------------------------------------------------------------------

Debug.Enabled = true

--------------------------------------------------------------------------------------------------
-- Debug Functions
---------------------------------------------------------------------------------------------------

local function Print(...)
  print (ThreatPlates.Meta("titleshort") .. "-Debug:", ...)
end

-- Function from: https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
function Debug:PrintTable(data)
  if not self.Enabled then return end

  local print_r_cache = {}

  local function sub_print_r(data,indent)
    if (print_r_cache[tostring(data)]) then
      Print(indent.."*"..tostring(data))
    else
      print_r_cache[tostring(data)]=true
      if (type(data)=="table") then
        for pos,val in pairs(data) do
          if (type(val)=="table") then
            Print(indent.."["..pos.."] => "..tostring(data).." {")
            sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
            Print(indent..string.rep(" ",string.len(pos)+6).."}")
          elseif (type(val)=="string") then
            Print(indent.."["..pos..'] => "'..val..'"')
          else
            Print(indent.."["..pos.."] => "..tostring(val))
          end
        end
      else
        Print(indent..tostring(data))
      end
    end
  end

  if (type(data)=="table") then
    Print(tostring(data).." {")
    sub_print_r(data,"  ")
    Print("}")
  else
    sub_print_r(data,"  ")
  end
end

function Debug:PrintUnit(unit, full_info)
  if not self.Enabled then return end

  Print("Unit:", unit.name)
  Print("-------------------------------------------------------------")
  for key, val in pairs(unit) do
    Print(key .. ":", val)
  end

  if full_info and unit.unitid then
    --		DEBUG("  isFriend = ", TidyPlatesUtilityInternal.IsFriend(unit.name))
    --		DEBUG("  isGuildmate = ", TidyPlatesUtilityInternal.IsGuildmate(unit.name))
    Print("  IsOtherPlayersPet = ", UnitIsOtherPlayersPet(unit))
    Print("  IsBattlePet = ", UnitIsBattlePet(unit.unitid))
    Print("  PlayerControlled = ", UnitPlayerControlled(unit.unitid))
    Print("  CanAttack = ", UnitCanAttack("player", unit.unitid))
    Print("  Reaction = ", UnitReaction("player", unit.unitid))
    local r, g, b, a = UnitSelectionColor(unit.unitid, true)
    Print("  SelectionColor: r =", ceil(r * 255), ", g =", ceil(g * 255), ", b =", ceil(b * 255), ", a =", ceil(a * 255))
  else
    Print("  <no unit id>")
  end

  Print("--------------------------------------------------------------")
end


function Debug:PrintTarget(unit)
  if not self.Enabled then return end

  if unit.isTarget then
    self:PrintUnit(unit)
  end
end