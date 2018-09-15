AlienCommUtils = {}

function AlienCommUtils.ExecuteTechId(commander, techId, pos, hostEntity, targetId)
  local techNode = commander:GetTechTree():GetTechNode( techId )

  local allowed, canAfford = hostEntity:GetTechAllowed(techId, techNode, commander)
  if not (allowed and canAfford) then return end

  -- We should probably use ProcessTechTreeAction instead here...
  commander.isBotRequestedAction = true -- Hackapalooza...
  local success, keepGoing = commander:ProcessTechTreeActionForEntity(
          techNode,
          pos,
          Vector(0,1,0),  -- normal
          true,   -- isCommanderPicked
          0,  -- orientation
          hostEntity,
          nil, -- trace
          targetId
          )

  return success
end

function AlienCommUtils.IsResearching(senses, entity)
  return (entity.researchingId ~= nil and entity.researchingId ~= 1) or senses:GetIsRecentlyResearching(entity:GetId())
end

AlienCommUtils.IsHiveUpgrading = AlienCommUtils.IsResearching

function AlienCommUtils.IsHiveUpgraded(hive)
  return hive:GetTechId() ~= kTechId.Hive
end

function AlienCommUtils.IsTargetMisted(senses, target)
  return #GetEntitiesForTeamWithinRange('NutrientMist', senses.team, target:GetOrigin(), NutrientMist.kSearchRange) > 0
end

AlienCommUtils.maxInfestationRange = math.max(kInfestationRadius, kHiveInfestationRadius)
function AlienCommUtils.HasNearEnoughInfester(target)
  assert(target)

  local nearbyInfesters = GetEntitiesWithMixinWithinRange('Infestation', target:GetOrigin(), AlienCommUtils.maxInfestationRange)
  for _, infester in ipairs(nearbyInfesters) do
    if AlienCommUtils.IsInfesterCloseEnough(infester:GetOrigin(), infester:GetInfestationMaxRadius(), target:GetOrigin(), target:GetCoords().yAxis) and
        (not infester:isa('Cyst') or infester:GetIsActuallyConnected()) then
      return true
    end
  end

  return false
end

function AlienCommUtils.IsInfesterCloseEnough(infesterLoc, infesterRadius, loc, floorNormalOrNil)
  local normal = floorNormalOrNil or Vector(0, 1, 0)
  local vec = (loc - infesterLoc)
  local dist = vec:GetLength()
  local yDist = vec:DotProduct(normal)

  return dist < infesterRadius and yDist < 1
end

local function GetSignedRandom()
  if math.random() < 0.5 then
    return math.random()
  else
    return math.random() * -1
  end
end

function AlienCommUtils.GetRandomBuildPosition(commander, techId, aroundPos, maxDist)
  assert(commander)
  assert(techId)
  assert(aroundPos)
  assert(maxDist)
  local extents = GetExtents(techId)
  local validationFunc = LookupTechData(techId, kTechDataRequiresInfestation, nil) and GetIsPointOnInfestation or nil
  local randPos = GetRandomSpawnForCapsule(extents.y, extents.x, aroundPos, 0.01, maxDist, EntityFilterAll(), validationFunc)

  if randPos then
    local trace = GetCommanderPickTarget(commander, randPos, true, true, false)
    if trace.fraction ~= 1 then
      local legalBuildPosition, position, _, errorString = GetIsBuildLegal(techId, trace.endPoint, 0, kStructureSnapRadius, commander)
      if legalBuildPosition then
        randPos = position
      else
        randPos = nil
      end
    end
  end

  if not randPos then
    for i=1, 10 do
      randPos = aroundPos + Vector(GetSignedRandom() * maxDist, GetSignedRandom() * maxDist, GetSignedRandom() * maxDist)

      local trace = GetCommanderPickTarget(commander, randPos, true, true, false)
      if trace.fraction ~= 1 then
        local legalBuildPosition, position, _, errorString = GetIsBuildLegal(techId, trace.endPoint, 0, kStructureSnapRadius, commander)

        if legalBuildPosition then
          randPos = position
          break
        end
      end

      randPos = nil
    end
  end

  return randPos
end

AlienCommUtils.HiveDefenderClassnames = {
  Skulk = true, Lerk = true, Gorge = true, Onos = true, Fade = true,
  Whip = true
}
function AlienCommUtils.IsSafeHiveDrop(senses, techPoint, locNmOrNil)
  local locNm = locNmOrNil and locNmOrNil or UrgentGetLocationName(techPoint)

  local enemies = senses:GetKnownEnemiesInRoom(locNm, AlienSensedEnemyFilters.FilterNonThreatening())
  if #enemies > 0 then return false, 'there are enemies in ' .. locNm end

  for _, adjLoc in ipairs(GetAdjacentTo(locNm)) do
    enemies = senses:GetKnownEnemiesInRoom(adjLoc, AlienSensedEnemyFilters.FilterNonThreatening())
    if #enemies > 0 then return false, 'there are enemies in ' .. adjLoc end
  end

  return true, nil
end

function AlienCommUtils.IsDefendedHiveDrop(senses, techPoint, locNmOrNil)
  local locNm = locNmOrNil and locNmOrNil or UrgentGetLocationName(techPoint)

  local foundFriend = false
  for _, alien in ientitylist(Shared.GetEntitiesWithClassname('Alien')) do
    if alien:GetIsAlive()
      and AlienCommUtils.HiveDefenderClassnames[alien.classname]
      and alien:GetLocationName() == locNm then
      return true, nil
    end
  end

  return false, 'we have nobody in ' .. locNm
end

-- returns success, reason or nil (reason provided only on failure)
function AlienCommUtils.IsViableHiveDrop(senses, techPoint)
  local locNm = UrgentGetLocationName(techPoint)

  local suc, rsn = AlienCommUtils.IsDefendedHiveDrop(senses, techPoint, locNm)
  if not suc then return false, rsn end

  return AlienCommUtils.IsSafeHiveDrop(senses, techPoint, locNm)
end

-- includes manually spawned eggs
function AlienCommUtils.GetHiveHasEggs(hive)
  local locNm = hive:GetLocationName()
  local eggs = GetEntitiesForTeam("Egg", hive:GetTeamNumber())

  for index, egg in ipairs(eggs) do
    if egg:GetLocationName() == locNm and egg:GetIsAlive() and egg:GetIsFree() then
      return true
    end
  end
  return false
end
