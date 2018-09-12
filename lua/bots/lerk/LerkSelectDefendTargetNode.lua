--- Selects a target that might be worth defending, or an enemy that
-- is attacking a structure.
--
-- Lerks are some of the best tools for countering marine clumps walking into
-- hives until skulks get xenocide. Lerks also aren't significantly deterred
-- by jetpacks, which is a great way to knock down enemy pres during the late
-- stages of the game.

class 'LerkSelectDefendTargetNode' (BTNode)

function LerkSelectDefendTargetNode:Run(context)
  local player = context.bot:GetPlayer()
  local team = player:GetTeamNumber()
  local info = {
    bot = context.bot,
    move = context.move,
    player = player,
    team = team,
    enemyTeam = GetEnemyTeamNumber(team),
    time = Shared.GetTime(),

    checkedLocs = {},
    contestedLocs = {},
    friendlyLocs = {},
    enemyLocs = {}
  }

  context.targetId = nil
  if self:TrySelectHurtGorge(info) or self:TrySelectHurtResource(info)
      or self:TrySelectHurtHive(info) or self:TrySelectMarine(info) then
    if context.debug then Log('Defending target %s (%s)', Shared.GetEntity(info.targetId), info.targetId) end

    context.targetId = info.targetId
    return self.Success
  end

  if context.debug then Log('No defense targets found') end
  return self.Failure
end

function LerkSelectDefendTargetNode:CheckLocation(info, locNm)
  info.checkedLocs[locNm] = true

  if self:CheckLocationIsEnemy(info, locNm) then
    info.enemyLocs[locNm] = true
  elseif self:CheckLocationIsFriendly(info, locNm) then
    info.friendlyLocs[locNm] = true
  else
    info.contestedLocs[locNm] = true
  end
end

function LerkSelectDefendTargetNode:CheckLocationIsEnemy(info, locNm)
  -- We going to consider it an enemy location if the enemy has ways
  -- of reinforcing or maintaining the location. That means phase gates,
  -- ips, or armories. We would include comm stations + observatories but
  -- it's unlikely that those locations wont include pg or ip or armory
  -- AND will beacon for a lerk.

  local power = GetPowerPointForLocation(locNm)
  if power == nil or not power.powering then return false end

  local consumerIds = power:GetPowerConsumers()

  for _, consumerId in ipairs(consumerIds) do
    local consumer = Shared.GetEntity(consumerId)

    if not HasMixin(consumer, 'LOS') or consumer:GetIsSighted() or consumer.lastViewerId ~= Entity.invalidId then
      if consumer:isa('PhaseGate') or consumer:isa('InfantryPortal') or consumer:isa('Armory') then return true end
    end
  end

  consumerIds = nil

  for _, battery in ientitylist(Shared.GetEntitiesWithClassname('SentryBattery')) do
    if battery:GetLocationName() == locNm then
      -- verify this battery has been seen before
      if not HasMixin(battery, 'LOS') or battery:GetIsSighted() or battery.lastViewerId ~= Entity.invalidId then
        -- verify it has some sentries
        if #battery:GetPowerConsumers() > 0 then return true end
      end
    end

    return false
  end

  return false
end

function LerkSelectDefendTargetNode:CheckLocationIsFriendly(info, locNm)
  -- Friendly if we have a Hive, crag, shift, or harvester
  -- We'll check harvester first since typically we won't have
  -- a Hive without a harvester, though if we're echoing it
  -- out it's possible

  for _, harv in ientitylist(Shared.GetEntitiesWithClassname('Harvester')) do
    if harv:GetLocationName() == locNm then return true end
  end

  for _, crag in ientitylist(Shared.GetEntitiesWithClassname('Crag')) do
    if crag:GetLocationName() == locNm then return true end
  end

  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetLocationName() == locNm then return true end
  end

  for _, shift in ientitylist(Shared.GetEntitiesWithClassname('Shift')) do
    if shift:GetLocationName() == locNm then return true end
  end

  return false
end

function LerkSelectDefendTargetNode:IsLocationFriendly(info, locNm)
  if info.checkedLocs[locNm] then return info.friendlyLocs[locNm] or false end

  self:CheckLocation(info, locNm)
  return info.friendlyLocs[locNm] or false
end

function LerkSelectDefendTargetNode:TargetIsSuppressed(info, targetId)
  self.recentTargetIds = self.recentTargetIds or {}

  if self.recentTargetIds[targetId] then
    if info.time - self.recentTargetIds[targetId] > 30 then
      self.recentTargetIds[targetId] = nil
      return false
    end
    return true
  end

  return false
end

function LerkSelectDefendTargetNode:SuppressTarget(info, targetId)
  self.recentTargetIds = self.recentTargetIds or {}
  self.recentTargetIds[targetId] = info.time
end

function LerkSelectDefendTargetNode:SetTarget(info, targetId)
  self:SuppressTarget(info, targetId)
  info.targetId = targetId
end

function LerkSelectDefendTargetNode:TrySelectHurtGorge(info)
  for _, gorge in ientitylist(Shared.GetEntitiesWithClassname('Gorge')) do
    if self:IsLocationFriendly(info, gorge:GetLocationName()) and
       gorge:GetHealthScalar() < 0.97 and not self:TargetIsSuppressed(info, gorge:GetId()) then
      self:SetTarget(info, gorge:GetId())
      return true
    end
  end

  return false
end

function LerkSelectDefendTargetNode:TrySelectHurtHive(info)
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetHealthScalar() < 0.97 and not self:TargetIsSuppressed(info, hive:GetId()) then
      self:SetTarget(info, hive:GetId())
      return true
    end
  end
end

function LerkSelectDefendTargetNode:TrySelectHurtResource(info)
  for _, res in ientitylist(Shared.GetEntitiesWithClassname('Harvester')) do
    if res:GetHealthScalar() < 0.97 and not self:TargetIsSuppressed(info, res:GetId()) then
      self:SetTarget(info, res:GetId())
      return true
    end
  end

  return false
end

function LerkSelectDefendTargetNode:TrySelectMarine(info)
  local viableIds = {}
  for _, marine in ientitylist(Shared.GetEntitiesWithClassname('Marine')) do
    if marine:GetIsSighted() and self:IsLocationFriendly(info, marine:GetLocationName()) and not self:TargetIsSuppressed(info, marine:GetId()) then
      table.insert(viableIds, marine:GetId())
    end
  end

  if #viableIds == 0 then return false end
  self:SetTarget(info, viableIds[math.random(1, #viableIds)])
  return true
end
