-- Selects a survival target node based on the survival instincts.
-- This may require multiple targets before returning to main base.
-- In order to achieve this, regularly scan for a survival target when
-- we have needs. It shouldn't be necessary to rescan until we've reached
-- the returned target.

class 'LerkSetSurvivalTargetNode' (BTNode)

function LerkSetSurvivalTargetNode:Run(context)
  local instincts = context.survivalInstincts

  if instincts.terrified then
    self:SelectTerrifiedSurvivalTarget(context, instincts)
    return self.Success
  end

  context.terrifiedRetreatLocationsTouched = nil

  if instincts.spooked then
    self:SelectSpookedSurvivalTarget(context, instincts)
    return self.Success
  end

  if instincts.wantHealth and instincts.wantEnergy then
    self:SelectHealthAndEnergyTarget(context, instincts)
    return self.Success
  end

  if instincts.wantHealth then
    self:SelectHealthTarget(context, instincts)
    return self.Success
  end

  if instincts.wantEnergy then
    self:SelectEnergyTarget(context, instincts)
    return self.Success
  end

  -- we don't want anything and we're not afraid, so this is a manually
  -- coded retreat which is equivalent to being spooked
  self:SelectSpookedSurvivalTarget(context, instincts)
  return self.Success
end

local function LerkGetDangerRanking(locationNm)
  -- We ignore LOS to make it seem like we have intuition. Add it in if
  -- lerks feel unkillable
  local ranking = {
    aliens = 0,
    marines = 0,
    poweredSentries = 0,
    phaseGates = 0,
    infantryPortals = 0,
    hives = 0,
    squaredDistanceToHive = math.huge
  }

  local powerPoint = nil
  for _, ent in ientitylist(Shared.GetEntitiesWithTag('Live')) do
    local entLoc = ent.GetLocationName and ent:GetLocationName() or GetLocationForPoint(ent:GetOrigin()):GetName()
    if entLoc == locationNm then
      if ent:isa('Alien') then
        ranking.aliens = ranking.aliens + 1
      elseif ent:isa('Marine') then
        ranking.marines = ranking.marines + 1
      elseif ent:isa('Sentry') and ent.attachedToBattery then
        ranking.poweredSentries = ranking.poweredSentries + 1
      elseif ent:isa('PhaseGate') then
        ranking.phaseGates = ranking.phaseGates + 1
      elseif ent:isa('InfantryPortal') then
        ranking.infantryPortals = ranking.infantryPortals + 1
      elseif ent:isa('Hive') then
        ranking.hives = ranking.hives + 1
      elseif ent:isa('PowerPoint') then
        powerPoint = ent
      end
    end
  end

  if powerPoint then
    for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
      if hive:GetIsAlive() and hive:GetIsBuilt() then
        local distSq = powerPoint:GetOrigin():GetDistanceSquared(hive:GetOrigin())

        if distSq < ranking.squaredDistanceToHive then
          ranking.squaredDistanceToHive = distSq
        end
      end
    end
  end

  return ranking
end

local function LerkIsSecondRankingLessDangerous(dangerRanking1, dangerRanking2)
  if dangerRanking1.hives > 0 and dangerRanking1.marines == 0 then
    return false
  end

  if dangerRanking2.hives > 0 and dangerRanking2.marines == 0 then
    return true
  end

  if dangerRanking1.aliens > dangerRanking1.marines then
    if dangerRanking2.aliens > dangerRanking2.marines then
      -- more aliens = more targets = we take less damage?
      return dangerRanking2.aliens > dangerRanking1.aliens
    end
    return false
  end

  if dangerRanking2.aliens > dangerRanking2.marines then return true end

  if dangerRanking1.poweredSentries == 0 and dangerRanking1.marines == 0 then
    if dangerRanking2.poweredSentries == 0 and dangerRanking2.marines == 0 then
      if dangerRanking2.aliens > dangerRanking1.aliens then return true end
      if dangerRanking1.aliens > dangerRanking2.aliens then return false end
      return dangerRanking2.squaredDistanceToHive < dangerRanking1.squaredDistanceToHive
    end
    return false
  end

  if dangerRanking2.poweredSentries == 0 and dangerRanking2.marines == 0 then return true end

  if dangerRanking1.marines == 0 then
    if dangerRanking2.marines == 0 then
      if dangerRanking2.aliens > dangerRanking1.aliens then return true end
      if dangerRanking1.aliens > dangerRanking2.aliens then return false end
      return dangerRanking2.squaredDistanceToHive < dangerRanking1.squaredDistanceToHive
    end
    return false
  end

  if dangerRanking2.marines == 0 then return true end

  if dangerRanking1.poweredSentries > 0 then
    if dangerRanking2.poweredSentries == 0 then return true end
  elseif dangerRanking2.poweredSentries > 0 then return false end

  if dangerRanking1.phaseGates > 0 or dangerRanking1.infantryPortals > 0 then
    if dangerRanking2.phaseGates == 0 and dangerRanking2.infantryPortals == 0 then return true end
  elseif dangerRanking2.phaseGates > 0 or dangerRanking2.infantryPortals > 0 then return false end

  if dangerRanking2.marines < dangerRanking1.marines then return true end
  if dangerRanking1.marines < dangerRanking2.marines then return false end

  return dangerRanking2.squaredDistanceToHive < dangerRanking1.squaredDistanceToHive
end

function LerkSetSurvivalTargetNode:SelectTerrifiedSurvivalTarget(context, instincts)
  -- when terrified we are going to choose our retreat targets one location away
  -- at a time, where possible, to go towards locations we suspect there are no
  -- enemy threats.
  --
  -- The issue with this is avoiding backtracking. it's fine to take a longer route
  -- but we need to eventually get to the destination. To ensure this happens
  -- we are going to maintain terrifiedRetreatLocationsTouched which is cleared in Run()
  -- if we aren't terrified
  --
  -- We are going to head towards less dangerous locations until we reach a hive.

  local player = context.bot:GetPlayer()
  local currLoc = player:GetLocationName()
  local currLocRanking = LerkGetDangerRanking(currLoc)

  if currLocRanking.marines == 0 and currLocRanking.hives > 0 then
    for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
      if hive:GetIsAlive() and hive:GetIsBuilt() and hive:GetLocationName() == currLoc then
        context.targetId = hive:GetId()
        return true
      end
    end
  end

  if not context.terrifiedRetreatLocationsTouched then
    Log('had to initialize retreat locations')
    context.terrifiedRetreatLocationsTouched = {}
  end

  context.terrifiedRetreatLocationsTouched[currLoc] = true

  local adjacentLocations = GetAdjacentTo(currLoc) -- cannot modify this list!

  if #adjacentLocations == 0 then
    error('found no adjacent locations to ' .. currLoc)
  end

  local viable = {}
  for _, loc in ipairs(adjacentLocations) do
    if not context.terrifiedRetreatLocationsTouched[loc] then
      table.insert(viable, loc)
    end
  end

  if #viable == 0 then
    -- no choice, just loop
    Log('had to clear retreat locations')
    context.terrifiedRetreatLocationsTouched = nil
    return self:SelectTerrifiedSurvivalTarget(context, instincts)
  end

  if context.debug then Log('Rankings and preference: ') end
  local bestLoc = viable[1]
  local bestRanking = LerkGetDangerRanking(bestLoc)
  if context.debug then Log('%s: %s', bestLoc, bestRanking) end
  for i=2, #viable do
    local ranking = LerkGetDangerRanking(viable[i])
    if context.debug then Log('%s: %s', viable[i], ranking) end
    if LerkIsSecondRankingLessDangerous(bestRanking, ranking) then
      if context.debug then Log('prefer ' .. viable[i] .. ' to ' .. bestLoc) end
      bestLoc, bestRanking = viable[i], ranking
    elseif context.debug then
      Log('dont prefer ' .. viable[i] .. ' to ' .. bestLoc)
    end
  end

  -- alright well lets go there then
  context.targetId = CacheGetPowerPointForLocation(bestLoc):GetId()
  return true
end

function LerkSetSurvivalTargetNode:SelectHealthAndEnergyTarget(context, instincts)
  local player = context.bot:GetPlayer()
  local origin = player:GetOrigin()

  local healthOptions = {}
  local energyOptions = {}

  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsAlive() and hive:GetIsBuilt() then
      table.insert(healthOptions, hive)
    end
  end

  for _, crag in ientitylist(Shared.GetEntitiesWithClassname('Crag')) do
    if crag:GetIsAlive() and crag:GetIsBuilt() then
      table.insert(healthOptions, hive)
    end
  end

  if #healthOptions == 0 then
    context.targetId = nil
    return false
  end

  for _, shift in ientitylist(Shared.GetEntitiesWithClassname('Shift')) do
    if shift:GetIsAlive() and shift:GetIsBuilt() then
      table.insert(energyOptions, shift)
    end
  end

  local healthOptionsWithNearbyEnergy = {}

  for _, hiveOrCrag in ipairs(healthOptions) do
    local healOrigin = hiveOrCrag:GetOrigin()

    for _, shift in ipairs(energyOptions) do
      local shiftOrigin = shift:GetOrigin()

      if (healOrigin - shiftOrigin):GetLengthXZ() < kEnergizeRange then
        table.insert(healthOptionsWithNearbyEnergy, hiveOrCrag)
      end
    end
  end

  if #healthOptionsWithNearbyEnergy > 0 then
    local bestTarget, bestDistSq = nil, nil
    for _, tar in ipairs(healthOptionsWithNearbyEnergy) do
      local distSq = origin:GetDistanceSquared(tar:GetOrigin())
      if bestTarget == nil or distSq < bestDistSq then
        bestTarget, bestDistSq = tar, distSq
      end
    end

    context.targetId = bestTarget:GetId()
    return true
  end

  -- can't get both health and energy in one spot, just go to the nearest health

  local bestTarget, bestDistSq = nil, nil
  for _, tar in ipairs(healthOptions) do
    local distSq = origin:GetDistanceSquared(tar:GetOrigin())
    if bestTarget == nil or distSq < bestDistSq then
      bestTarget, bestDistSq = tar, distSq
    end
  end

  context.targetId = bestTarget:GetId()
  return true
end

LerkSetSurvivalTargetNode.SelectSpookedSurvivalTarget = LerkSetSurvivalTargetNode.SelectHealthAndEnergyTarget

function LerkSetSurvivalTargetNode:SelectHealthTarget(context, instincts)
  local origin = context.bot:GetPlayer():GetOrigin()
  local bestTarget, bestDistSq = nil, nil

  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsAlive() and hive:GetIsBuilt() then
      local distSq = origin:GetDistanceSquared(hive:GetOrigin())
      if not bestTarget or distSq < bestDistSq then
        bestTarget, bestDistSq = hive, distSq
      end
    end
  end

  for _, crag in ientitylist(Shared.GetEntitiesWithClassname('Crag')) do
    if crag:GetIsAlive() and crag:GetIsBuilt() then
      local distSq = origin:GetDistanceSquared(crag:GetOrigin())
      if not bestTarget or distSq < bestDistSq then
        bestTarget, bestDistSq = crag, distSq
      end
    end
  end

  if not bestTarget then
    context.targetId = nil
    return false
  end

  context.targetId = bestTarget:GetId()
  return true
end

function LerkSetSurvivalTargetNode:SelectEnergyTarget(context, instincts)
  local origin = context.bot:GetPlayer():GetOrigin()
  local bestTarget, bestDistSq = nil, nil

  for _, shift in ientitylist(Shared.GetEntitiesWithClassname('Shift')) do
    if shift:GetIsAlive() and shift:GetIsBuilt() then
      local distSq = origin:GetDistanceSquared(shift:GetOrigin())

      if not bestTarget or distSq < bestDistSq then
        bestTarget, bestDistSq = shift, distSq
      end
    end
  end

  if bestTarget then
    context.targetId = bestTarget:GetId()
    return true
  end

  return self:SelectHealthTarget(context, instincts)
end
