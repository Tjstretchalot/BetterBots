AlienSensedEnemyFilters = {}

local function _RealFilterNonThreatening(info)
  return info.blipType ~= kMinimapBlipType.Marine and
    info.blipType ~= kMinimapBlipType.JetpackMarine and
    info.blipType ~= kMinimapBlipType.Exo and
    info.blipType ~= kMinimapBlipType.Sentry and
    info.blipType ~= kMinimapBlipType.ARC and
    info.blipType ~= kMinimapBlipType.PhaseGate and
    info.blipType ~= kMinimapBlipType.InfantryPortal
end

function AlienSensedEnemyFilters.FilterNonThreatening()
  return _RealFilterNonThreatening
end
