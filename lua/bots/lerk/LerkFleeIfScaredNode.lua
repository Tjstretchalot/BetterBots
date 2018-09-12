--- It should be possible to do this without a separate node but the logic
-- is a bit confusing that way.
-- This node effectively manages what the lerk decides to do when it's feeling
-- "stressed".
--
-- Firstly, the lerk should try to get to a defensive location, like a crag or
-- a hive or a shift (ideally all 3). It relies on the intincts target node
-- to get us to one of those places. Once we get there, it's fight-or-die time,
-- but we retreat back to our healing node whenever our target loses line of
-- sight on us OR we get out of range of our healing target.
--
-- If we made it to a heal target and we don't have anyone attacking us, just
-- get really close to the heal target and look at it, wiggling our head in a
-- up-down motion to encourage it to heal faster and give spectators a chuckle.
--
-- If our heal target dies we retreat to another heal target.
--
-- While we're doing all this we try to smooth our view movement. Smoothing
-- of view for this type of fast movement has to be pretty lenient, so:
--   View *distance* = distance between view unit directions
--   Minimum view velocity of kViewMinimumMovementCap 1 / ms
--   View velocity increases by up to kViewMovementAcceleration 1 / ms^2 whenever we wanted to move more than that
--   View velocity increases up to kViewMaximumMovementCap 1 / ms
--   View velocity goes down kViewDecreaseProportion towards the lower of actual movement and minimum cap every tick

class 'LerkFleeIfScaredNode' (BTNode)

local kViewMinimumMovementCap = 0.025
local kViewMovementAcceleration = 0.1
local kViewMaximumMovementCap = 0.3
local kViewDecreaseProportion = 0.01

local kViewPitchSpeed = 0.1
local kViewPitchMax = 0.4

function LerkFleeIfScaredNode:Initialize()
  BTNode.Initialize(self)

  self.setInstinctsNode = LerkSetSurvivalInstinctsNode()
  self.setInstinctsNode:Initialize()

  self.setInstinctsTargetNode = LerkSetSurvivalTargetNode()
  self.setInstinctsTargetNode:Initialize()

  self.moveNode = LerkMoveToTargetNode()
  self.moveNode:Initialize()

  self.attackNode = LerkAttackTargetNode()
  self.attackNode:Initialize()

  self.setPriorityTargetNode = LerkSetPriorityTargetNode()
  self.setPriorityTargetNode:Initialize()

  self.state = nil
end

function LerkFleeIfScaredNode:Start(context)
  self.state = {
    wasScared = false,
    trappedUntil = 0,

    beingHealed = false,
    lastHealedCheck = 0,
    currentHealerId = Entity.invalidId,

    lastViewDir = context.bot:GetPlayer():GetViewCoords().zAxis,
    currViewVelocity = kViewMinimumMovementCap,

    movingTowardsInstinctsTarget = false,
    lastUpdatedInstinctsTargetHealth = 0,

    attackingAttackTarget = false,

    lastVerifiedShouldAttack = 0,

    viewBobTargetId = Entity.invalidId,
    viewBobTargetViewOffsetPitch = 0,
    viewBobDirection = 1,

    attackContext = nil,
    moveContext = nil
  }

  if context.debug then Log('LerkFleeIfScaredNode -> Start') end
end

function LerkFleeIfScaredNode:Run(context)
  local res = self:DoRun(context)
  self:SmoothViewDir(context)
  return res
end

function LerkFleeIfScaredNode:DoRun(context)
  local time = Shared.GetTime()
  local player = context.bot:GetPlayer()

  if time - self.state.lastHealedCheck > 1 then
    self:DoHealCheck(context, player)
    self.state.lastHealedCheck = time
  end

  self.setInstinctsNode:Start(context)
  local res = self.setInstinctsNode:Run(context)
  assert(res ~= self.Running)
  self.setInstinctsNode:Finish(context, true, res)

  if res == self.Failure then
    if not self.state.wasScared then
      if context.debug then Log('LerkFleeIfScaredNode not scared and havent been scared -> Failure') end
      return self.Failure
    else
      if context.debug then Log('LerkFleeIfScaredNode previously scared but not anymore -> Success') end
      return self.Success
    end
  end

  self.state.wasScared = true

  if not self.state.beingHealed then
    if self.state.movingTowardsInstinctsTarget then
      self.state.moveContext.bot = context.bot
      self.state.moveContext.move = context.move
      self.state.moveContext.survivalInstincts = context.survivalInstincts

      if context.survivalInstincts.terrified and not self.state.lastUpdatedInstinctsTargetTerrified then
        context.movingTowardsInstinctsTarget = false
        self.moveNode:Finish(self.state.moveContext, false)
        self.state.moveContext = nil
        local res = self:SetupInstinctsTarget(context, info)
        if res then return res end
      else
        local res = self.moveNode:Run(self.state.moveContext)
        if res ~= self.Running then
          self.state.movingTowardsInstinctsTarget = false
          self.moveNode:Finish(self.state.moveContext, true, res)
          self.state.moveContext = nil
        end
        return res
      end
    elseif time > self.state.trappedUntil then
      local res = self:SetupInstinctsTarget(context, info)
      if res then return res end
    else
      Log('still trapped')
    end
  end

  if time - self.state.lastVerifiedShouldAttack > 0.3 then
    self.state.lastVerifiedShouldAttack = time

    local newContext = {
      bot = context.bot,
      move = context.move,
      survivalInstincts = context.survivalInstincts
    }

    self.setPriorityTargetNode:Start(newContext)
    local res = self.setPriorityTargetNode:Run(newContext)
    assert(res ~= self.Running)
    self.setPriorityTargetNode:Finish(newContext, true, res)

    if res == self.Success then
      assert(newContext.targetId)
      if self.state.attackingAttackTarget then
        if self.state.attackContext.targetId ~= newContext.targetId then
          self.state.attackContext.bot = context.bot
          self.state.attackContext.move = context.move
          self.state.attackContext.survivalInstincts = context.survivalInstincts
          self.attackNode:Finish(self.state.attackContext, false)

          self.state.attackContext.targetId = newContext.targetId
          self.attackNode:Start(self.state.attackContext)
        end
      else
        self.state.attackContext = newContext
        self.attackNode:Start(newContext)

        self.state.attackingAttackTarget = true
      end
    elseif self.state.attackingAttackTarget then
      self.state.attackContext.bot = context.bot
      self.state.attackContext.move = context.move
      self.state.attackContext.survivalInstincts = context.survivalInstincts
      self.attackNode:Finish(self.state.attackContext, false)
      self.state.attackingAttackTarget = false
      self.state.attackContext = nil
    end
  end

  if self.state.attackingAttackTarget then
    self.state.attackContext.bot = context.bot
    self.state.attackContext.move = context.move
    self.state.attackContext.survivalInstincts = context.survivalInstincts
    local res = self.attackNode:Run(self.state.attackContext)
    if res == self.Running then return res end
    self.attackNode:Finish(self.state.attackContext, true, res)
    self.state.attackContext = nil
    self.state.attackingAttackTarget = false
  end

  if self.state.movingTowardsInstinctsTarget then
    self.state.moveContext.bot = context.bot
    self.state.moveContext.move = context.move
    self.state.moveContext.survivalInstincts = context.survivalInstincts
    local res = self.moveNode:Run(self.state.moveContext)
    if res == self.Running then return res end
    self.state.viewBobTargetId = self.state.moveContext.targetId or Entity.invalidId
    self.state.viewBobTargetViewOffsetPitch = 0

    self.moveNode:Finish(self.state.moveContext, true, res)
    self.state.moveContext = nil
    self.state.movingTowardsInstinctsTarget = false
  end

  if self.state.viewBobTargetId == Entity.invalidId and self.state.currentHealerId ~= Entity.invalidId then
    self.state.viewBobTargetId = self.state.currentHealerId
  end

  if self.state.viewBobTargetId ~= Entity.invalidId then
    local viewBobTarget = Shared.GetEntity(self.state.viewBobTargetId)

    if not viewBobTarget or not viewBobTarget:GetIsAlive() then
      self.state.viewBobTargetId = Entity.invalidId
    else
      local viewDir = (viewBobTarget:GetEngagementPoint() - player:GetEyePos()):GetUnit()
      context.move.yaw = GetYawFromVector(viewDir) - player:GetBaseViewAngles().yaw
      context.move.pitch = GetPitchFromVector(viewDir) + self.state.viewBobTargetViewOffsetPitch

      if self.state.viewBobDirection == 1 then
        self.state.viewBobTargetViewOffsetPitch = math.min(kViewPitchMax, self.state.viewBobTargetViewOffsetPitch + kViewPitchSpeed)

        if self.state.viewBobTargetViewOffsetPitch == kViewPitchMax then
          self.state.viewBobDirection = -1
        end
      else
        self.state.viewBobTargetViewOffsetPitch = math.max(-kViewPitchMax, self.state.viewBobTargetViewOffsetPitch - kViewPitchSpeed)

        if self.state.viewBobTargetViewOffsetPitch == -kViewPitchMax then
          self.state.viewBobDirection = 1
        end
      end
    end
  end

  return self.Running
end

function LerkFleeIfScaredNode:SetupInstinctsTarget(context)
  self.state.lastUpdatedInstinctsTargetTerrified = context.survivalInstincts.terrified

  local moveContext = {
    bot = context.bot,
    move = context.move,
    survivalInstincts = context.survivalInstincts
  }

  self.setInstinctsTargetNode:Start(moveContext)
  local res = self.setInstinctsTargetNode:Run(moveContext)
  assert(res ~= self.Running)
  self.setInstinctsTargetNode:Finish(moveContext, true, res)

  if res == self.Success then
    self.state.movingTowardsInstinctsTarget = true
    self.state.moveContext = moveContext
    self.moveNode:Start(moveContext)
    return self.Running
  else
    Log('trapped!')
    self.state.trappedUntil = time + 1
  end
end

function LerkFleeIfScaredNode:DoHealCheck(context, player)
  if self.state.currentHealerId ~= Entity.invalidId then
    local currentHealer = Shared.GetEntity(self.state.currentHealerId)
    if currentHealer and currentHealer:GetIsAlive() and currentHealer:GetIsBuilt() then
      local distSq = player:GetOrigin():GetDistanceSquared(currentHealer:GetOrigin())

      if currentHealer:isa('Hive') and distSq < (Hive.kHealRadius * Hive.kHealRadius) then return end
      if currentHealer:isa('Crag') and distSq < (Crag.kHealRadius * Crag.kHealRadius) then return end
    end
  end

  self.state.beingHealed = false
  self.state.currentHealerId = Entity.invalidId

  for _, hive in ipairs(GetEntitiesWithinRange('Hive', player:GetOrigin(), Hive.kHealRadius)) do
    if hive:GetIsAlive() and hive:GetIsBuilt() then
      self.state.beingHealed = true
      self.state.currentHealerId = hive:GetId()
      return
    end
  end

  for _, crag in ipairs(GetEntitiesWithinRange('Crag', player:GetOrigin(), Crag.kHealRadius)) do
    if crag:GetIsAlive() and crag:GetIsBuilt() then
      self.state.beingHealed = true
      self.state.currentHealerId = crag:GetId()
      return
    end
  end
end

function LerkFleeIfScaredNode:Finish(context, natural, res)
  if context.debug then Log('LerkFleeIfScaredNode -> Finish') end
  if self.state.movingTowardsInstinctsTarget then
    self.moveNode:Finish(self.state.moveContext, false)
  end

  if self.state.attackingAttackTarget then
    self.attackNode:Finish(self.state.attackContext, false)
  end

  self.state = nil
end

function LerkFleeIfScaredNode:SmoothViewDir(context)
  local oldViewDir = self.state.lastViewDir
  local newViewDir = Angles(context.move.pitch, context.move.yaw, 0):GetCoords().zAxis

  local lengthBetweenDirs = oldViewDir:GetDistance(newViewDir)

  if lengthBetweenDirs <= self.state.currViewVelocity then
    self.state.lastViewDir = newViewDir
    self.state.currViewVelocity = math.max(lengthBetweenDirs, kViewMinimumMovementCap) * kViewDecreaseProportion + self.state.currViewVelocity * (1 - kViewDecreaseProportion)
    return
  end

  self.state.currViewVelocity = self.state.currViewVelocity + math.min(kViewMovementAcceleration, lengthBetweenDirs - self.state.currViewVelocity)
  self.state.currViewVelocity = math.min(self.state.currViewVelocity, kViewMaximumMovementCap)

  if lengthBetweenDirs <= self.state.currViewVelocity then
    self.state.lastViewDir = newViewDir
    return
  end

  local smoothedViewDir = (newViewDir - oldViewDir):GetUnit() * self.state.currViewVelocity

  local player = context.bot:GetPlayer()
  context.move.yaw = GetYawFromVector(smoothedViewDir) - player:GetBaseViewAngles().yaw
  context.move.pitch = GetPitchFromVector(smoothedViewDir)
  self.state.lastViewDir = smoothedViewDir
end
