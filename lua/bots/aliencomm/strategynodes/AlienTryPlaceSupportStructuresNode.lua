class 'AlienTryPlaceSupportStructuresNode' (BTNode)

function AlienTryPlaceSupportStructuresNode:Initialize()
  BTNode.Initialize(self)

  self.placeStructureNode = AlienPlaceStructureNode()
  self.placeStructureNode:Setup(15):Initialize()
end

function AlienTryPlaceSupportStructuresNode:Run(context)
  if self.cooldownUntil and self.cooldownUntil > context.senses.time then
    return self.Failure
  end

  self.cooldownUntil = context.senses.time + 4.9 + math.random() * 0.2
  local cragsE = Shared.GetEntitiesWithClassname('Crag')
  local crags = {}
  for _, crag in ientitylist(cragsE) do
    if crag:GetIsAlive() then
      table.insert(crags, crag)
    end
  end
  local shiftsE = Shared.GetEntitiesWithClassname('Shift')
  local shifts = {}
  for _, shift in ientitylist(shiftsE) do
    if shift:GetIsAlive() then
      table.insert(shifts, shift)
    end
  end

  if self:TryPlaceCragNearGorgeTunnel(context, crags, shifts) then return self.Success end
  if self:TryPlaceCragNearHive(context, crags, shifts) then return self.Success end
  if self:TryPlaceCragNearContestedResource(context, crags, shifts) then return self.Success end
  if self:TryPlaceShiftNearCrag(context, crags, shifts) then return self.Success end
  if self:TryPlaceWhipNearContestedResource(context, crags, shifts) then return self.Success end
  if self:TryPlaceContaminateNearCommandStation(context, crags, shifts) then return self.Success end

  return self.Failure
end

local function HasEffectFromAtPoint(things, pt, radius)
  local sqdHealRad = radius * radius
  for _, thing in ipairs(things) do
    local distSqd = pt:GetDistanceSquared(thing:GetOrigin())

    if distSqd < sqdHealRad then return true end
  end

  return false
end

local function AlertPlaceStructureNearPoint(self, context, location, techId)
  local player = context.bot:GetPlayer()
  local playerName = player:GetName()
  local playerLocId = player.locationId
  local playerTeamNum = player:GetTeamNumber()
  local playerTeamTyp = player:GetTeamType()
  local msg = 'Placing a ' .. EnumToString(kTechId, techId) .. ' in ' .. GetLocationForPoint(location):GetName()

  Log('\'%s\' said to team: %s', playerName, msg)
  for _, player in ipairs(GetEntitiesForTeam('Player', playerTeamNum)) do
    Server.SendNetworkMessage(player, 'Chat', BuildChatMessage(
      true, -- team only
      playerName,
      playerLocId,
      playerTeamNum,
      playerTeamTyp,
      msg
    ), true)
  end
end

local function TryPlaceStructureNearPoint(self, context, location, techId, range)
  local oldLoc = context.location
  context.location = AlienCommUtils.GetRandomBuildPosition(context.bot:GetPlayer(), techId, location, range or 10)

  self.placeStructureNode:Setup(techId)
  self.placeStructureNode:Start(context)
  local res = self.placeStructureNode:Run(context)
  self.placeStructureNode:Finish(context, res ~= self.Running, res)

  if res == self.Success then
    AlertPlaceStructureNearPoint(self, context, location, techId)
  else
    Log('failed to place a %s in %s; res = %s, self.Success = %s', EnumToString(kTechId, techId), GetLocationForPoint(location):GetName(), res, self.Success)
  end

  context.location = oldLoc
  return res == self.Success
end

function AlienTryPlaceSupportStructuresNode:TryPlaceCragNearGorgeTunnel(context, crags, shifts)
  for _, tunnel in ientitylist(Shared.GetEntitiesWithClassname('TunnelEntrance')) do
    if tunnel:GetIsBuilt() and tunnel:GetIsAlive() then
      if not HasEffectFromAtPoint(crags, tunnel:GetOrigin(), Crag.kHealRadius) then
        return TryPlaceStructureNearPoint(self, context, tunnel:GetOrigin(), kTechId.Crag)
      end
    end
  end
  return false
end

function AlienTryPlaceSupportStructuresNode:TryPlaceCragNearHive(context, crags, shifts)
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsAlive() and not HasEffectFromAtPoint(crags, hive:GetOrigin(), Crag.kHealRadius) then
      return TryPlaceStructureNearPoint(self, context, hive:GetOrigin(), kTechId.Crag)
    end
  end
  return false
end

local function CountRecentAttacksFromHistory(context, history)
  local recentAttacks = 0
  local countAfter = context.senses.time - 120
  for i=#history, 1, -1 do
    if history[i] >= countAfter then
      countAfter = history[i] - 120
      recentAttacks = recentAttacks + 1
    else
      break
    end
  end

  return recentAttacks
end

function AlienTryPlaceSupportStructuresNode:TryPlaceCragNearContestedResource(context, crags, shifts)
  for _, info in ipairs(context.senses:GetHarvesterInfos()) do
    local harv = Shared.GetEntity(info.id)
    if harv and not info.underAttack and #info.attackHistory >= 1 and not HasEffectFromAtPoint(crags, harv:GetOrigin(), Crag.kHealRadius) then
      local recentAttacks = CountRecentAttacksFromHistory(context, info.attackHistory)

      if recentAttacks >= 1 then
        return TryPlaceStructureNearPoint(self, context, harv:GetOrigin(), kTechId.Crag)
      end
    end
  end
  return false
end

function AlienTryPlaceSupportStructuresNode:TryPlaceShiftNearCrag(context, crags, shifts)
  for _, crag in ipairs(crags) do
    if not HasEffectFromAtPoint(shifts, crag:GetOrigin(), kEnergizeRange) then
      return TryPlaceStructureNearPoint(self, context, crag:GetOrigin(), kTechId.Shift)
    end
  end
  return false
end

function AlienTryPlaceSupportStructuresNode:TryPlaceWhipNearContestedResource(context, crags, shifts)
  local whips

  for _, info in ipairs(context.senses:GetHarvesterInfos()) do
    local harv = Shared.GetEntity(info.id)
    if harv and not info.underAttack and #info.attackHistory >= 1 then
      if not whips then
        whips = {}
        for _, whip in ientitylist(Shared.GetEntitiesWithClassname('Whip')) do
          if whip:GetIsAlive() then
            table.insert(whips, whip)
          end
        end
      end

      if not HasEffectFromAtPoint(whips, harv:GetOrigin(), Whip.kRange) then
        local recentAttacks = CountRecentAttacksFromHistory(context, info.attackHistory)

        if recentAttacks >= 1 then
          return TryPlaceStructureNearPoint(self, context, harv:GetOrigin(), kTechId.Whip, 7)
        end
      end
    end
  end

  return false
end

function AlienTryPlaceSupportStructuresNode:TryPlaceContaminateNearCommandStation(context, crags, shifts)
  if not GetTechTree(context.senses.team):GetTechNode(kTechId.BioMassTen):GetHasTech() then
    return false
  end

  if self.contamCooldownUntil and context.senses.time < self.contamCooldownUntil then
    return false
  end

  self.contamCooldownUntil = context.senses.time + kContaminationCooldown

  local enemyChair = nil
  for _, chair in ientitylist(Shared.GetEntitiesWithClassname('CommandStation')) do
    if chair:GetIsAlive() then
      enemyChair = chair
      break
    end
  end

  if enemyChair then
    TryPlaceStructureNearPoint(self, context, enemyChair:GetOrigin(), kTechId.Contamination, 7)
  end

  return false -- we don't want to spend the normal cooldown on contamination
end
