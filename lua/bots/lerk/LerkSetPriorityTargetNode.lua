--- Scan nearby area and set a target

class 'LerkSetPriorityTargetNode' (BTNode)

-- Highly specific ordering is done here.
-- We prefer earlier indexes to later indexes in general, but there
-- are many exceptions near the beginning
local entityIsas = {
  'Marine', 'Exo', 'SentryBattery', 'PowerPoint',
  'PhaseGate', 'ARC', 'MAC', 'Sentry', 'Observatory', 'AdvancedArmory',
  'Armory', 'PrototypeLab', 'InfantryPortal', 'RoboticsFactory',
  'ArmsLab', 'CommandStation', 'Extractor'
}

function LerkSetPriorityTargetNode:Run(context)
  context.lastSearchPriorityTarget = context.lastSearchPriorityTarget or 0

  if context.lastSearchPriorityTarget > 0 then
    local timeSinceLastSearch = Shared.GetTime() - context.lastSearchPriorityTarget
    if timeSinceLastSearch < 1 then
      local oldTargetDied = false
      local oldTargetId = context.lastSearchPriorityTargetResultId

      if oldTargetId and oldTargetId ~= Entity.invalidId then
        local oldTarget = Shared.GetEntity(oldTargetId)
        if not oldTarget or not oldTarget.GetIsAlive or not oldTarget:GetIsAlive() then
          context.lastSearchPriorityTargetResultId = Entity.invalidId
          context.lastSearchPriorityTargetResult = self.Failure
          oldTargetDied = true
        end
      end

      if not oldTargetDied then
        context.targetId = oldTargetId
        return context.lastSearchPriorityTargetResult
      end
    end
  end

  context.lastSearchPriorityTarget = Shared.GetTime()
  local targetId = self:DoSearch(context)
  if targetId == nil then
    context.targetId = nil
    context.lastSearchPriorityTargetResultId = nil
    context.lastSearchPriorityTargetResult = self.Failure
    return self.Failure
  end

  context.targetId = targetId
  context.lastSearchPriorityTargetResultId = targetId
  context.lastSearchPriorityTargetResult = self.Success
  return self.Success
end

function LerkSetPriorityTargetNode:DoSearch(context)
  local bot = context.bot
  local player = bot:GetPlayer()
  local team = player:GetTeamNumber()
  local enemyTeam = GetEnemyTeamNumber(team)

  -- This is not necessarily invariant to the order entities return in, but
  -- that's fine. If we do want near-invariance than we have to do a partially-ordered
  -- list search and switch to 3-way comparisons which is a lot more complicated

  local bestEntity, bestInfo = nil, nil
  for _, ent in ipairs(GetEntitiesWithMixinForTeamWithinRange('Live', enemyTeam, player:GetOrigin(), 21)) do
    if ent:GetIsAlive() then
      if not ent:isa('PowerPoint') or (ent.powerState == PowerPoint.kPowerState.socketed and ent:GetIsBuilt() and ent:GetHealth() > 0) then
        local found = false
        for _, typ in ipairs(entityIsas) do
          if ent:isa(typ) then
            found = true
            break
          end
        end

        if found then
          local info = self:CreateInfo(ent)
          info.entity = ent

          if bestEntity == nil or self:IsBetterTarget(bestInfo, info, bot, player) then
            bestEntity = ent
            bestInfo = info
          end
        end
      end
    end
  end

  return bestEntity and bestEntity:GetId() or nil
end

--- Turn the given entity into an "info" object
-- for use with IsBetterTarget. Should add the entity
-- to the result.
function LerkSetPriorityTargetNode:CreateInfo(entity)
  if entity:isa('Marine') then
    return {
      hasShotgun = entity:GetActiveWeapon():isa('Shotgun'),
      hasFlamethrower = entity:GetActiveWeapon():isa('Flamethrower'),
      hasJetpack = entity:isa('JetpackMarine')
    }
  elseif entity:isa('ARC') then
    return {
      isDeployed = entity.mode == ARC.kDeployMode.Deploying or entity.mode == ARC.kDeployMode.Deployed
    }
  elseif entity:isa('Exo') then
    return {
      isMinigun = entity:GetActiveWeapon():isa('Minigun')
    }
  elseif entity:isa('InfantryPortal') then
    return {
      isSpawning = entity.queuedPlayerId ~= nil
    }
  elseif entity:isa('PowerPoint') then
    return {
      isConstructed = entity.powerState == PowerPoint.kPowerState.socketed
    }
  end

  return {}
end


function LerkSetPriorityTargetNode:IsBetterTarget(oldInfo, newInfo, bot, player)
  for _, typ in ipairs(entityIsas) do
    if oldInfo.entity:isa(typ) then
      return self['IsBetterTargetThan' .. typ](self, oldInfo, newInfo, bot, player)
    elseif newInfo.entity:isa(typ) then
      return not self['IsBetterTargetThan' .. typ](self, newInfo, oldInfo, bot, player)
    end
  end

  return false
end

function LerkSetPriorityTargetNode:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  assert(oldInfo)
  assert(newInfo)
  assert(bot)
  assert(player)
  -- prefer powered
  if HasMixin(oldInfo.entity, 'PowerConsumer') then
    oldInfo.powered = oldInfo.powered ~= nil and oldInfo.powered or oldInfo.entity:GetIsPowered()
    newInfo.powered = newInfo.powered ~= nil and oldInfo.powered or newInfo.entity:GetIsPowered()

    if oldInfo.powered and not newInfo.powered then return false end
    if not oldInfo.powered and newInfo.powered then return true end
  end

  -- prefer lower health
  oldInfo.health = oldInfo.health or oldInfo.entity:GetHealthScalar()
  newInfo.health = newInfo.health or newInfo.entity:GetHealthScalar()

  if newInfo.health < oldInfo.health then return true end
  if newInfo.health > oldInfo.health then return false end

  -- prefer closer
  oldInfo.distanceSquared = oldInfo.distanceSquared or oldInfo.entity:GetOrigin():GetDistanceSquared(player:GetEyePos())
  newInfo.distanceSquared = newInfo.distanceSquared or newInfo.entity:GetOrigin():GetDistanceSquared(player:GetEyePos())

  if newInfo.distanceSquared < oldInfo.distanceSquared then return true end
  if newInfo.distanceSquared > oldInfo.distanceSquared then return false end

  -- prefer older
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanMarine(oldInfo, newInfo, bot, player)
  if newInfo.entity:isa('Marine') then
    -- avoid shotgunners
    if oldInfo.hasShotgun and not newInfo.hasShotgun then return true end
    if not oldInfo.hasShotgun and newInfo.hasShotgun then return false end

    -- prefer jetpackers
    if oldInfo.hasJetpack and not newInfo.hasJetpack then return false end
    if not oldInfo.hasJetpack and newInfo.hasJetpack then return true end

    -- prefer flamethrowers
    if oldInfo.hasFlamethrower and not newInfo.hasFlamethrower then return false end
    if not oldInfo.hasFlamethrower and newInfo.hasFlamethrower then return true end

    -- prefer lower health
    oldInfo.health = oldInfo.health or oldInfo.entity:GetHealthScalar()
    newInfo.health = newInfo.health or newInfo.entity:GetHealthScalar()

    if oldInfo.health < newInfo.health then return false
    elseif oldInfo.health > newInfo.health then return true end

    -- prefer closer
    oldInfo.distanceSquared = oldInfo.distanceSquared or oldInfo.entity:GetEngagementPoint():GetDistanceSquared(player:GetEyePos())
    newInfo.distanceSquared = newInfo.distanceSquared or newInfo.entity:GetEngagementPoint():GetDistanceSquared(player:GetEyePos())

    if oldInfo.distanceSquared < newInfo.distanceSquared then return false
    elseif oldInfo.distanceSquared > newInfo.distanceSquared then return true end

    -- prefer older
    return false
  elseif newInfo.entity:isa('PhaseGate') then
    -- prefer marines with less than 35% health
    oldInfo.health = oldInfo.health or oldInfo.entity:GetHealthScalar()
    if oldInfo.health <= 0.35 then return false end

    -- prefer phase gates with less than 10% health
    newInfo.health = newInfo.health or newInfo.entity:GetHealthScalar()
    if newInfo.health <= 0.1 then return true end

    -- prefer marines
    return false
  elseif newInfo.entity:isa('Exo') then
    -- prefer exos with <50% health
    newInfo.health = newInfo.health or newInfo.entity:GetHealthScalar()
    if newInfo.health <= 0.5 then return true end

    -- prefer marines
    return false
  end

  -- prefer marines
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanExo(oldInfo, newInfo, bot, player)
  if newInfo.entity:isa('Exo') then
    return self:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  end

  -- prefer exo
  return false
end

local function PowerIsCritical(power)
  for _, consumerId in ipairs(power.powerConsumerIds) do
    local entity = Shared.GetEntity(consumerId)
    if entity:isa('InfantryPortal') or entity:isa('ArmsLab') then
      return true
    end
  end
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanSentryBattery(oldInfo, newInfo, bot, player)
  if not oldInfo.numberPoweredSentries then
    oldInfo.numberPoweredSentries = 0
    local sentries = GetEntitiesForTeamWithinRange('Sentry', oldInfo.entity:GetTeamNumber(), oldInfo.entity:GetOrigin(), SentryBattery.kRange)
    oldInfo.numberPoweredSentries = #sentries -- not perfectly accurate but close enough
    sentries = nil
  end

  if newInfo.entity:isa('SentryBattery') then
    if not newInfo.numberPoweredSentries then
      newInfo.numberPoweredSentries = 0
      local sentries = GetEntitiesForTeamWithinRange('Sentry', newInfo.entity:GetTeamNumber(), newInfo.entity:GetOrigin(), SentryBattery.kRange)
      newInfo.numberPoweredSentries = #sentries -- not perfectly accurate but close enough
      sentries = nil
    end

    -- prefer lower health
    oldInfo.health = oldInfo.health or oldInfo.entity:GetHealthScalar()
    newInfo.health = newInfo.health or newInfo.entity:GetHealthScalar()

    if newInfo.health < oldInfo.health then return true end
    if newInfo.health > oldInfo.health then return false end

    -- prefer more sentries
    if newInfo.numberPoweredSentries > oldInfo.numberPoweredSentries then return true end
    if newInfo.numberPoweredSentries < oldInfo.numberPoweredSentries then return false end

    -- prefer closer
    oldInfo.distanceSquared = oldInfo.distanceSquared or oldInfo.entity:GetOrigin():GetDistanceSquared(player:GetEyePos())
    newInfo.distanceSquared = newInfo.distanceSquared or newInfo.entity:GetOrigin():GetDistanceSquared(player:GetEyePos())

    if newInfo.distanceSquared < oldInfo.distanceSquared then return true end
    if newInfo.distanceSquared > oldInfo.distanceSquared then return false end

    -- prefer older
    return false
  end

  -- prefer sentry battery if has powered sentries
  if oldInfo.numberPoweredSentries > 0 then return false end

  -- prefer arc/mac over useless sentry battery
  if newInfo.entity:isa('ARC') or newInfo.entity:isa('MAC') then
    return true
  end

  -- prefer powered phasegate over useless sentry battery
  if newInfo.entity:isa('PhaseGate') and newInfo.entity:GetIsPowered() then
    return true
  end

  -- prefer critical power over useless sentry battery
  if newInfo.entity:isa('PowerPoint') then
    if newInfo.isCriticalPower == nil then newInfo.isCriticalPower = PowerIsCritical(newInfo.entity) end

    if newInfo.isCriticalPower then return true end
  end

  -- prefer the battery
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanPowerPoint(oldInfo, newInfo, bot, player)
  if oldInfo.isCriticalPower == nil then
    oldInfo.isCriticalPower = PowerIsCritical(oldInfo.entity)
  end

  if newInfo.entity:isa('PowerPoint') then
    if newInfo.isCriticalPower == nil then
      newInfo.isCriticalPower = PowerIsCritical(newInfo.entity)
    end

    -- prefer critical power
    if oldInfo.isCriticalPower and not newInfo.isCriticalPower then return false end
    if not oldInfo.isCriticalPower and newInfo.isCriticalPower then return true end

    return self:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  end

  -- prefer critical power
  if oldInfo.isCriticalPower then return false end

  -- prefer anything else
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanPhaseGate(oldInfo, newInfo, bot, player)
  if newInfo.entity:isa('PhaseGate') then
    return self:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  end

  -- prefer phase gate
  return false
end

local function ArcCanHitStuff(arc)
  local team = arc:GetTeamNumber()
  local enemyTeam = GetEnemyTeamNumber(team)

  for _, ent in ipairs(GetEntitiesWithMixinForTeamWithinRange('Live', enemyTeam, arc:GetOrigin(), ARC.kFireRange)) do
    if ent:GetIsAlive() and arc:GetCanFireAtTargetActual(ent, ent:GetOrigin()) then
      return true
    end
  end

  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanARC(oldInfo, newInfo, bot, player)
  if oldInfo.canHitStuff == nil then
    oldInfo.canHitStuff = ArcCanHitStuff(oldInfo.entity)
  end

  if newInfo.entity:isa('ARC') then
    -- prefer can hit stuff
    if newInfo.canHitStuff == nil then
      newInfo.canHitStuff = ArcCanHitStuff(newInfo.entity)
    end

    if not oldInfo.canHitStuff and newInfo.canHitStuff then return true end
    if oldInfo.canHitStuff and not newInfo.canHitStuff then return false end

    -- prefer deployed
    if not oldInfo.isDeployed and newInfo.isDeployed then return true end
    if oldInfo.isDeployed and not newInfo.isDeployed then return false end

    return self:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  end

  -- prefer arcs that can hit stuff
  if oldInfo.canHitStuff then return false end

  -- prefer other stuff to arcs that can't hit things
  return true
end

function LerkSetPriorityTargetNode:IsBetterTargetThanMAC(oldInfo, newInfo, bot, player)
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanSentry(oldInfo, newInfo, bot, player)
  if newInfo.entity:isa('Sentry') then
    return self:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  end

  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanObservatory(oldInfo, newInfo, bot, player)
  if newInfo.entity:isa('Observatory') then
    return self:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  end

  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanAdvancedArmory(oldInfo, newInfo, bot, player)
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanArmory(oldInfo, newInfo, bot, player)
  if newInfo.entity:isa('Armory') then
    return self:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  end

  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanPrototypeLab(oldInfo, newInfo, bot, player)
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanInfantryPortal(oldInfo, newInfo, bot, player)
  if newInfo.entity:isa('InfantryPortal') then
    return self:DefaultSameThingComparer(oldInfo, newInfo, bot, player)
  end

  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanRoboticsFactory(oldInfo, newInfo, bot, player)
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanArmsLab(oldInfo, newInfo, bot, player)
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanCommandStation(oldInfo, newInfo, bot, player)
  return false
end

function LerkSetPriorityTargetNode:IsBetterTargetThanExtractor(oldInfo, newInfo, bot, player)
  return false
end
