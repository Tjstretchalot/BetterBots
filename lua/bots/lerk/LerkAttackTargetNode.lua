--- Handles movement and attacking the target when it's "pretty close". Expects
-- to be done inside of an attack move since it regularly fails
--
-- The lerk will fight non-stationary targets like so:
--   Maintain umbra on self, if it is possible to do so
--   Want to bite enemy if:
--     Haven't bitten recently
--     Enemy doesn't have a shotgun
--     Enemy is not a Exo in a minigun
--   Want to retreat if:
--     Bitten recently
--     Hurt recently
--   Otherwise, try to spike
--
-- The lerk will also spike when on the approach for bites. When specifically
-- spiking, the lerk will select a "hug" location that has LOS with the target.

class 'LerkAttackTargetNode' (BTNode)

function LerkAttackTargetNode:Run(context)
  if not context.targetId then return self.Success end
  local target = Shared.GetEntity(context.targetId)
  if not target or not target:GetIsAlive() then return self.Success end

  local player = context.bot:GetPlayer()
  local info = {
    bot = context.bot,
    move = context.move,
    player = player,
    target = target,

    time = Shared.GetTime(),

    origin = player:GetOrigin(),
    targetOrigin = target:GetOrigin(),

    eyePos = player:GetEyePos(),

    targetEngagePoint = target.GetEngagementPoint and target:GetEngagementPoint() or target:GetOrigin(),

    health = player:GetHealthScalar(),
    targetHealth = target:GetHealthScalar(),

    energy = player:GetEnergy(),

    viewCoords = player:GetViewCoords().zAxis,
    targetViewCoords = (target.GetViewCoords and target.GetViewAngles) and target:GetViewCoords().zAxis or Vector(0, 0, 1)
  }

  self:FetchOrInitializeFightState(context, info)

  if not self:PerformMovement(context, info) then return self.Failure end
  self:PerformAttack(context, info)

  self:UpdateFightState(context, info)
  return self.Running
end

function LerkAttackTargetNode:Start(context)
  self.state = nil -- if we die while attacking
end

function LerkAttackTargetNode:FetchOrInitializeFightState(context, info)
  if not self.state then
    self.state = {
      targetId = context.targetId,
      location = context.location,
      moveNode = nil,

      cantRetreatUntil = nil,
      cantStopRetreatingUntil = nil,
      retreating = false,
      needLOSCheck = true,
      lastLOSCheck = 0,

      spikeOnly = true,
      lastUpdatedSpikeOnly = 0,

      lastBite = 0,
      startHealth = info.health,
      lastHealth = info.health,
      startTargetHealth = info.targetHealth,
      lastTargetHealth = info.targetHealth,
      lastViewCoords = info.viewCoords,
      lastTargetViewCoords = info.targetViewCoords,
      spiking = false,
      spikingStartedAt = nil,
      spikeTargetLoc = nil
    }

    self:MaybeUpdateShouldSpikeOnly(context, info)
  end
end

function LerkAttackTargetNode:PerformMovement(context, info)
  if self:WantToUmbra(context, info) then
    -- look at the floor
    info.move.pitch = 1
    return true
  end

  if self.state.retreating and info.time >= self.state.cantStopRetreatingUntil then
    local node = LerkSetSurvivalInstinctsNode()
    node:Initialize()
    node:Start(context)
    local res = node:Run(context)
    if res == self.Running then node:Finish(context, false) else node:Finish(context, true, res) end
    if res == self.Failure then
      self.state.retreating = false
      self.state.moveNode:Finish(context, false)
      self.state.moveNode = nil
    end
  end

  if self.state.moveNode then
    local res = self.state.moveNode:Run(context)
    info.viewCoords = Angles(info.move.pitch, info.move.yaw, 0):GetCoords().zAxis
    if res == self.Running then return true end
    self.state.moveNode:Finish(context, true, res)
    self.state.moveNode = nil
    self.state.retreating = false
    context.targetId = self.state.targetId
    context.location = self.state.location
    return true
  end

  if (not self.state.cantRetreatUntil or info.time >= self.state.cantRetreatUntil) and (context.survivalInstincts.spooked or context.survivalInstincts.terrified) then
    self.state.cantRetreatUntil = info.time + 5
    self.state.cantStopRetreatingUntil = info.time + 1
    self.state.retreating = true
    self.state.needLOSCheck = true

    if not self:SelectRetreatTarget(context, info) then return false end
    self.state.moveNode = LerkMoveToTargetNode()
    self.state.moveNode:Initialize()
    self.state.moveNode:Start(context)
    return self:PerformMovement(context, info)
  end

  if self.state.needLOSCheck then
    local filter
    if info.target.GetActiveWeapon then
      filter = EntityFilterTwoAndIsa(info.player, info.target:GetActiveWeapon(), 'Babbler')
    else
      filter = EntityFilterOneAndIsa(info.player, 'Babbler')
    end

    local trace = self:GetTraceToTarget(info, info.eyePos, filter)
    if trace.fraction < 1 and trace.entity ~= info.target then
      return false
    end

    self.state.needLOSCheck = false
    self.state.lastLOSCheck = info.time
  end

  if self.state.spiking then
    if not self.state.spikingStartedAt then
      self.state.spikingStartedAt = info.time
    end

    local timeSinceLOSCheck = info.time - self.state.lastLOSCheck
    if timeSinceLOSCheck > 0.3 then
      self.state.needLOSCheck = true
    end

    -- it looks silly when they don't spike a little
    if info.time - self.state.spikingStartedAt > 0.3 and not self.state.spikeOnly and info.time - self.state.lastBite > 2 then
      self.state.spiking = false
      self.state.spikingStartedAt = nil
      self.state.spikeTargetLoc = nil
      self.state.moveNode = LerkMoveToTargetNode()
      self.state.moveNode:Initialize()
      self.state.moveNode:Start(context)
      return self:PerformMovement(context, info)
    end

    info.viewCoords = LerkUtils.DirectLookTowards(info.move, info.player, info.targetEngagePoint)

    info.move.commands = AddMoveCommand(info.move.commands, Move.Jump)

    do
      -- hug our location
      local vecToTargetSpikingLoc = self.state.spikeTargetLoc - info.eyePos

      local effectivenessOfMovingForward = info.viewCoords:DotProduct(vecToTargetSpikingLoc)
      if effectivenessOfMovingForward < -1e-4 then
        info.move.move.z = -1
      elseif effectivenessOfMovingForward > 1e-4 then
        info.move.move.z = 1
      else
        info.move.move.z = 0
      end

      local xAxisMoveDir = Angles(info.move.pitch, info.move.yaw, 0):GetCoords().xAxis
      local effectivenessOfMovingLeft = xAxisMoveDir:DotProduct(vecToTargetSpikingLoc)
      if effectivenessOfMovingLeft < -1e-4 then
        info.move.move.x = -1
      elseif effectivenessOfMovingLeft > 1e-4 then
        info.move.move.x = 1
      else
        info.move.move.x = 0
      end
    end

    return true
  end

  -- If we went to bite, we had a movenode to do that
  -- if we went to spike, self.state.spiking would have been true
  -- thus, we are just starting the fight or have just bitten

  if self.state.lastBite == 0 and not self.state.spikeOnly then
    -- just started the fight, we should bite
    self.state.moveNode = LerkMoveToTargetNode()
    self.state.moveNode:Initialize()
    self.state.moveNode:Start(context)
    return self:PerformMovement(context, info)
  end

  -- we should spike. This is a random parameter sweep for a point off the
  -- ground that has los to our target
  return self:SelectSpikingLocationAndStartMoveNode(context, info)
end

function LerkAttackTargetNode:SelectRetreatTarget(context, info)
  local node = LerkSetSurvivalTargetNode()
  node:Initialize()
  node:Start(context)
  local res = node:Run(context)
  if res == self.Running then error('LerkSetSurvivalTargetNode should be instant!') end
  node:Finish(context, true, res)
  return res == self.Success
end

function LerkAttackTargetNode:GetTraceToTarget(info, pt, filter)
  local trace = Shared.TraceRay(pt, info.targetEngagePoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
  if trace.entity ~= info.target then
    local extents = GetDirectedExtentsForDiameter(info.targetEngagePoint - pt, 0.03)
    trace = Shared.TraceBox(extents, pt, info.targetEngagePoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
  end
  return trace
end

local function LerkTraceFromMeFilter(info)
  return function(ent)
    return ent == info.player or (not HasMixin(ent, 'Ragdoll'))
  end
end

function LerkAttackTargetNode:GetTraceFromMe(info, pt)
  local trace = Shared.TraceRay(info.eyePos, pt, CollisionRep.Move, PhysicsMask.All, LerkTraceFromMeFilter(info))
  if trace.entity ~= info.target then
    local extents = GetDirectedExtentsForDiameter(pt - info.eyePos, 0.5)
    trace = Shared.TraceBox(extents, info.eyePos, pt, CollisionRep.Move, PhysicsMask.All, LerkTraceFromMeFilter(info))
  end
  return trace
end

function LerkAttackTargetNode:TryMakeValidSpikingLocation(context, info, pt)
  local yMultiplier
  local yConstant
  if math.random(1, 2) == 1 then -- it looks better when they attack from above but it has a lot of trouble with the y
    pt = Vector(pt.x, pt.y + 1, pt.z) -- main source seems to copy here so we will too. not sure if necessary
    yMultiplier = 0.3
    yConstant = 0.2
  else
    pt = Vector(pt.x, pt.y + 6, pt.z)
    yMultiplier = -0.3
    yConstant = -0.2
  end

  local xzDistToTarget = (info.targetEngagePoint - pt):GetLengthXZ()
  local xzDistFromMe = (info.eyePos - pt):GetLengthXZ()
  if xzDistToTarget >= 5 and xzDistFromMe < xzDistToTarget then
    for j = 1, 7 do
      local trace = self:GetTraceToTarget(info, pt, filter2)
      if trace.fraction == 0 or trace.fraction >= 1 or trace.entity == info.target then
        trace = self:GetTraceFromMe(info, pt)
        if trace.fraction == 0 or trace.fraction >= 1 then
          return pt
        else
          --Log('trace from me failed; fraction = %s, entity = %s, surface = %s', trace.fraction, trace.entity, trace.surface)
        end
      end

      pt = pt + Vector(0, yConstant + math.random() * yMultiplier * j, 0) -- more random after more attempts
    end
  end

  return nil
end


function LerkAttackTargetNode:SelectSpikingLocationAndStartMoveNode(context, info)
  -- random parameter sweep
  local filter1 = EntityFilterOneAndIsa(info.player, 'Babbler')

  local filter2
  if info.target:isa('Marine') then
    filter2 = EntityFilterTwoAndIsa(info.player, info.target:GetActiveWeapon(), 'Babbler')
  else
    filter2 = filter1
  end

  local trace = self:GetTraceToTarget(info, info.eyePos, filter2)
  local workingDistance
  if trace.entity == target then
    workingDistance = info.eyePos:GetDistance(trace.endPoint)
  else
    workingDistance = info.eyePos:GetDistance(info.targetEngagePoint)
  end

  local spikeEyePos
  local scanCenter, scanMinRadius, scanMaxRadius, scanIncreaseRadiusPerFail
  if workingDistance > 10 then
    local pt = self:TryMakeValidSpikingLocation(context, info, Pathing.GetClosestPoint(info.eyePos))
    if pt then
      spikeEyePos = pt
    end

    scanCenter, scanMinRadius, scanMaxRadius, scanIncreaseRadiusPerFail = info.origin, 0, 2, 1
  elseif workingDistance > 5 then
    scanCenter, scanMinRadius, scanMaxRadius, scanIncreaseRadiusPerFail = info.origin, 1, 5, 0
  else
    scanCenter, scanMinRadius, scanMaxRadius, scanIncreaseRadiusPerFail = info.targetOrigin, 5, 10, 0
  end

  if not spikeEyePos then
    for i = 1, 10 do
      local points = GetRandomPointsWithinRadius(scanCenter, scanMinRadius, scanMaxRadius, 10, 1, 1, nil, nil)

      if #points < 1 then return false end -- failed to find any random points :(

      local pt = points[1]
      pt = self:TryMakeValidSpikingLocation(context, info, pt)
      if pt then
        spikeEyePos = pt
        break
      end
    end
  end

  if not spikeEyePos then return false end -- sweep failed

  self.state.spiking = true

  self.state.spikeTargetLoc = spikeEyePos

  context.location = spikeEyePos
  self.state.moveNode = LerkDirectMoveToLocationNode()
  self.state.moveNode:Initialize()
  self.state.moveNode:Start(context)
  return self:PerformMovement(context, info)
end

function LerkAttackTargetNode:WantToUmbra(context, info)
  local lastTryUmbra = info.bot.brain.lastTryUmbra

  if info.energy < kUmbraEnergyCost then return false end
  if not GetIsTechUnlocked(info.player, kTechId.Umbra) then return false end
  if info.player:GetHasUmbra() then return false end
  if lastTryUmbra and lastTryUmbra + kUmbraDuration > info.time then return false end

  return true
end

function LerkAttackTargetNode:PerformUmbra(context, info)
  if not self:WantToUmbra(context, info) then return false end

  local wep = info.player:GetActiveWeapon()
  if wep:isa('LerkUmbra') then
    if not wep.nextAttackTime or info.time >= wep.nextAttackTime then
      info.move.commands = AddMoveCommand(info.move.commands, Move.PrimaryAttack)
      info.bot.brain.lastTryUmbra = info.time
    end
  else
    info.move.commands = AddMoveCommand(info.move.commands, Move.Weapon2)
  end

  return true
end

function LerkAttackTargetNode:PerformAttack(context, info)
  if self:PerformUmbra(context, info) then return end

  local filter = EntityFilterOneAndIsa(info.player, 'Babbler')

  local endPoint = info.eyePos + info.viewCoords * kSpikesRange
  local trace = Shared.TraceRay(info.eyePos, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
  if trace.entity ~= info.target then
    local extents = GetDirectedExtentsForDiameter(info.viewCoords, 0.03)
    trace = Shared.TraceBox(extents, info.eyePos, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
  end

  if trace.entity ~= info.target then
    return
  end

  local traceDistance = trace.endPoint:GetDistance(info.eyePos)
  local wep = info.player:GetActiveWeapon()
  if traceDistance < 1.5 then
    if not wep:isa('LerkBite') then
      info.move.commands = AddMoveCommand(info.move.commands, Move.Weapon1)
    elseif not wep.nextAttackTime or info.time >= wep.nextAttackTime then
      info.move.commands = AddMoveCommand(info.move.commands, Move.PrimaryAttack)
      self.state.lastBite = info.time
    end
  else
    if wep:GetSecondaryTechId() ~= kTechId.Spikes then
      info.move.commands = AddMoveCommand(info.move.commands, Move.Weapon1)
    else
      info.move.commands = AddMoveCommand(info.move.commands, Move.SecondaryAttack)
    end
  end
end

function LerkAttackTargetNode:UpdateFightState(context, info)
  self.state.lastHealth = info.health
  self.state.lastTargetHealth = info.targetHealth
  self.state.lastViewCoords = info.viewCoords
  self.state.lastTargetViewCoords = info.targetViewCoords
  self:MaybeUpdateShouldSpikeOnly(context, info)
end

function LerkAttackTargetNode:MaybeUpdateShouldSpikeOnly(context, info)
  if info.time - self.state.lastUpdatedSpikeOnly < 1 then return end
  self.state.lastUpdatedSpikeOnly = info.time

  local nearby = GetEntitiesWithMixinWithinRange("Live", info.origin, 21)

  if #nearby <= 2 then
    self.state.spikeOnly = self:DetermineShouldSpikeOnlyOneVOne(context, info)
    return
  end

  local team = info.player:GetTeamNumber()

  local haveCragSupport = false
  local haveShiftSupport = false

  local enemiesNearby = 0
  local alliesNearby = 0 -- this includes us!

  for _, live in ipairs(nearby) do
    if live:isa('Crag') then
      haveCragSupport = true
    elseif live:isa('Shift') then
      haveShiftSupport = true
    elseif live:isa('Alien') then
      alliesNearby = alliesNearby + 1
    elseif not live.GetIsSighted or live:GetIsSighted() then
      enemiesNearby = enemiesNearby + 1

      if live:isa('Marine') and live:GetActiveWeapon() and (live:GetActiveWeapon():isa('Shotgun') or live:GetActiveWeapon():isa('HeavyMachineGun')) then
        self.state.spikeOnly = true
        return
      end
    end
  end

  local trueNumberAllies = alliesNearby + (haveCragSupport and 1 or 0) + (haveShiftSupport and 1 or 0)

  self.state.spikeOnly = trueNumberAllies < enemiesNearby
end

function LerkAttackTargetNode:DetermineShouldSpikeOnlyOneVOne(context, info)
  if info.target:isa('Marine') then
    local wep = info.target:GetActiveWeapon()
    if not wep then return true end

    if wep:isa('HeavyMachineGun') or wep:isa('Shotgun') then return true end
  end

  return false
end

function LerkAttackTargetNode:Finish(context, natural, res)
  if self.state and self.state.moveNode then
    self.state.moveNode:Finish(context, false)
  end

  if self.state then
    context.location = self.state.location
  end

  self.state = nil
  context.targetId = nil
end
