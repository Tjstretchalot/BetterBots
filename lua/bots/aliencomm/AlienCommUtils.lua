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

function AlienCommUtils.IsHiveUpgrading(senses, hive)
  return (hive.researchingId ~= nil and hive.researchingId ~= 1) or senses:GetIsRecentlyResearching(hive:GetId())
end

function AlienCommUtils.IsHiveUpgraded(hive)
  return GetHasTech(hive, kTechId.ShiftHive) or GetHasTech(hive, kTechId.CragHive) or GetHasTech(hive, kTechId.ShadeHive)
end

function AlienCommUtils.IsTargetMisted(senses, target)
  return #GetEntitiesForTeamWithinRange('NutrientMist', senses.team, target:GetOrigin(), NutrientMist.kSearchRange) > 0
end

AlienCommUtils.maxInfestationRange = math.max(kInfestationRadius, kHiveInfestationRadius)
function AlienCommUtils.HasNearEnoughInfester(target)
  assert(target)

  local nearbyInfesters = GetEntitiesWithMixinWithinRange('Infestation', target:GetOrigin(), AlienCommUtils.maxInfestationRange)
  for _, infester in ipairs(nearbyInfesters) do
    if AlienCommUtils.IsInfesterCloseEnough(infester:GetLocation(), infester:GetInfestationMaxRadius(), target:GetOrigin(), target:GetCoords().yAxis) and
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

function AlienCommUtils.GetRandomBuildPosition(techId, aroundPos, maxDist)
  -- originally copied from CommanderBrain
  local extents = GetExtents(techId)
  local validationFunc = LookupTechData(techId, kTechDataRequiresInfestation, nil) and GetIsPointOnInfestation or nil
  local randPos = GetRandomSpawnForCapsule(extents.y, extents.x, aroundPos, 0.01, maxDist, EntityFilterAll(), validationFunc)
  return randPos
end
