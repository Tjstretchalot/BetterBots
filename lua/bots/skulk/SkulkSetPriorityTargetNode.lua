--- Sets the priority attack target (for something nearby), if one is found

class 'SkulkSetPriorityTargetNode' (BTNode)

local orderedTargetsTechPoint = {
  kMinimapBlipType.Marine,
  kMinimapBlipType.Exo,
  kMinimapBlipType.SentryBattery,
  kMinimapBlipType.PowerPoint,
  kMinimapBlipType.JetpackMarine,
  kMinimapBlipType.PhaseGate,
  kMinimapBlipType.ArmsLab,
  kMinimapBlipType.InfantryPortal,
  kMinimapBlipType.Observatory,
  kMinimapBlipType.PrototypeLab,
  kMinimapBlipType.AdvancedArmory,
  kMinimapBlipType.CommandStation
  -- won't be a controlled tech point after we bite chair
}

local tmp = {}
for ind, val in ipairs(orderedTargetsTechPoint) do
  tmp[val] = ind
end

orderedTargetsTechPoint = tmp

local orderedTargetsNoTechPoint = {
  kMinimapBlipType.Marine,
  kMinimapBlipType.SentryBattery,
  kMinimapBlipType.PhaseGate,
  kMinimapBlipType.ARC,
  kMinimapBlipType.MAC,
  kMinimapBlipType.Exo,
  kMinimapBlipType.Sentry,
  kMinimapBlipType.Extractor,
  kMinimapBlipType.Observatory,
  kMinimapBlipType.JetpackMarine,
  kMinimapBlipType.AdvancedArmory,
  kMinimapBlipType.Armory,
  kMinimapBlipType.PrototypeLab,
  kMinimapBlipType.InfantryPortal,
  kMinimapBlipType.RoboticsFactory,
  kMinimapBlipType.ArmsLab,
  kMinimapBlipType.PowerPoint
}

local tmp = {}
for ind, val in ipairs(orderedTargetsNoTechPoint) do
  tmp[val] = ind
end
orderedTargetsNoTechPoint = tmp

tmp = nil

function SkulkSetPriorityTargetNode:Run(context)
   context.lastSearchPriorityTarget = context.lastSearchPriorityTarget or 0

   local now = Shared.GetTime()
   local timeSinceSearch = now - context.lastSearchPriorityTarget
   if timeSinceSearch < 1 then
     context.targetId = nil
     return self.Failure
   end

   context.lastSearchPriorityTarget = now

   local bot = context.bot
   local player = bot:GetPlayer()
   local team = player:GetTeamNumber()
   local enemyTeam = GetEnemyTeamNumber(team)

   local eyePos = player:GetEyePos()

   local locationId = player:GetLocationId()

   -- first gotta determine if its an enemy controlled tech point
   local isTechPoint = false
   for _, ent in ipairs(GetEntitiesForTeam('CommandStation', enemyTeam)) do
     if ent:GetLocationId() == locationId then
       isTechPoint = true
       break
     end
   end

   local priorityTargets = isTechPoint and orderedTargetsTechPoint or orderedTargetsNoTechPoint

   local bestTarget, bestIndex = nil, nil
   local powerNodes = {}

   local function considerTarget(ent)
     local sighted = not ent.GetIsSighted or ent:GetIsSighted()
     if not sighted then
       local trace = Shared.TraceRay(eyePos, ent:GetEngagementPoint(), CollisionRep.LOS, PhysicsMask.All, EntityFilterOneAndIsa(player, 'Babbler'))
       if trace.fraction == 0 or trace.fraction >= 1 or trace.entity == ent then
         sighted = true
       end
     end

     if sighted then
       local success, blipType = ent:GetMapBlipInfo()
       if success then
         local ind = priorityTargets[blipType]
         if ind ~= nil and (bestTarget == nil or ind < bestIndex) then
           bestTarget, bestIndex = ent, ind
         end
       end
     end
   end

   for _, ent in ipairs(GetEntitiesWithMixinForTeamWithinRange("Live", enemyTeam, player:GetOrigin(), 21)) do
     local failedAliveCheck = not ent:GetIsAlive()
     if ent:isa('PowerPoint') then
      failedAliveCheck = ent.powerState ~= PowerPoint.kPowerState.socketed or not ent:GetIsBuilt() or ent:GetHealth() <= 0

      if not failedAliveCheck then
        table.insert(powerNodes, ent)
      end
     end

     if not failedAliveCheck and ent.GetMapBlipInfo then
       considerTarget(ent)
     end
   end

   for _, node in ipairs(powerNodes) do
     for _, consId in ipairs(node:GetPowerConsumers()) do
       local ent = Shared.GetEntity(consId)
       if HasMixin(ent, 'Live') and ent:GetIsAlive() and ent.GetMapBlipInfo then
         considerTarget(ent)
       end
     end
   end

   if not bestTarget then
     context.targetId = nil
     return self.Failure
   else
     context.targetId = bestTarget:GetId()
     return self.Success
   end
end
