--- More lerk-style movement while moving to a node

class 'LerkMoveToTargetNode' (BTNode)

local CLOSE_TO_PATHFINDING_NODE_SQD_XZ = 4

function LerkMoveToTargetNode:Start(context)
  self.lastLocation = nil
  self.stuckCounter = 0
end

function LerkMoveToTargetNode:Run(context)
  if not context.targetId then
    return self.Failure
  end

  local bot = context.bot
  local target = Shared.GetEntity(context.targetId)
  if target == nil then
    context.targetId = nil
    return self.Failure
  end

  local player = bot:GetPlayer()
  local origin = player:GetOrigin()
  local eyePos = player:GetEyePos()
  local targetEngagePoint = target.GetEngagementPoint and target:GetEngagementPoint() or target:GetOrigin()
  if self:IsCloseEnoughToTarget(player, eyePos, target) then
    LerkUtils.DirectLookTowards(context.move, player, targetEngagePoint)
    return self.Success
  end

  if self.lastLocation ~= nil then
    local dist = self.lastLocation:GetDistance(origin)

    if dist < 0.1 then
      self.stuckCounter = self.stuckCounter + 1
      if self.stuckCounter > 5 then return self.Failure end
    else
      self.stuckCounter = 0
    end
  end

  self.lastLocation = origin


  local oldLastLookDir = self.lastLookDir
  local time = Shared.GetTime()
  local move = context.move

  local res = self:DoActualMove(context, {
    bot = bot,
    move = move,
    player = player,
    origin = player:GetOrigin(),
    eyePos = eyePos,
    target = target,
    targetOrigin = target:GetOrigin(),
    targetEngagePoint = target.GetEngagementPoint and target:GetEngagementPoint() or target:GetOrigin(),
    time = time
  })


  if oldLastLookDir then
    local currLookDir = self.lastLookDir
    local smoothedDir = oldLastLookDir * 0.5 + currLookDir * 0.5
    self.lastLookDir = smoothedDir
    move.yaw = GetYawFromVector(smoothedDir) - player:GetBaseViewAngles().yaw
    move.pitch = GetPitchFromVector(smoothedDir)
  end

  return res
end

function LerkMoveToTargetNode:IsCloseEnoughToTarget(player, eyePos, target)
  if GetDistanceToTouch(eyePos, target) < 1 then return true end

  if not HasMixin(target, 'Ragdoll') then
    local distXZ = (eyePos - (target.GetEngagementPoint and target:GetEngagementPoint() or target:GetOrigin())):GetLengthXZ()
    if distXZ < 2 then return true end
    return false
  end

  local endPos = target.GetEngagementPoint and target:GetEngagementPoint() or target:GetOrigin()
  local trace = Shared.TraceRay(eyePos, endPos, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(player, 'Babbler'))
  if trace.entity ~= target then
    local extents = GetDirectedExtentsForDiameter((endPos - eyePos), 0.4)
    trace = Shared.TraceBox(extents, eyePos, endPos, CollisionRep.Move, PhysicsMask.All, EntityFilterOneAndIsa(player, 'Babbler'))
  end

  if trace.entity ~= target then return false end

  return (eyePos - trace.endPoint):GetLengthXZ() < 1.5
end

function LerkMoveToTargetNode:DoActualMove(context, info)
  if self:TryDirectMoveToTarget(context, info) then return self.Running end
  if self:TryUseGeneratedPathToTarget(context, info) then return self.Running end
  if self:TryGenerateAndUsePathToTarget(context, info) then return self.Running end

  self.lastLookDir = LerkUtils.DirectLookTowards(context.move, info.player, info.targetEngagePoint)
  return self.Failure
end

function LerkMoveToTargetNode:TryUseGeneratedPathToTarget(context, info)
  if not context.path then return false end

  if context.path.index > #context.path.points then
    context.path = nil -- this happens from the tailcall
    return false
  end

  -- todo check if path is stale

  local currPoint = context.path.points[context.path.index]

  local moveDir = (currPoint - info.origin)
  local lenSqd = moveDir.x * moveDir.x + moveDir.z * moveDir.z

  if lenSqd < CLOSE_TO_PATHFINDING_NODE_SQD_XZ then
    context.path.index = context.path.index + 1
    return self:TryUseGeneratedPathToTarget(context, info)
  end

  self:DirectMoveTowards(context, info, Vector(currPoint.x, currPoint.y + 1, currPoint.z))
  return true
end

function LerkMoveToTargetNode:DirectMoveTowards(context, info, pt, suppressWiggle)
  if not suppressWiggle then
    context.randomMoveOffset = context.randomMoveOffset or math.random() * 5.78

    local theta = math.sin(context.randomMoveOffset + Shared.GetTime() * 5.78) * 0.7
    local dist = (pt - context.bot:GetPlayer():GetEyePos()):GetLengthXZ()
    pt.y = pt.y + dist * math.tan(theta)
  end
  self.lastLookDir = LerkUtils.DirectMoveTowards(context, info.move, info.player, pt, true) -- we dont need expensive wiggling
end

function LerkMoveToTargetNode:TryGenerateAndUsePathToTarget(context, info)
  local pathPoints = PointArray()
  local reachable = Pathing.GetPathPoints(info.origin, info.targetOrigin, pathPoints)

  if not reachable then return false end

  context.path = {
    points = pathPoints,
    index = 1,
    target = info.targetOrigin
  }

  return LerkMoveToTargetNode:TryUseGeneratedPathToTarget(context, info)
end

function LerkMoveToTargetNode:TryDirectMoveToTarget(context, info)
  local filter
  if info.target.GetActiveWeapon then
    filter = EntityFilterTwoAndIsa(info.player, info.target:GetActiveWeapon(), 'Babbler')
  else
    filter = EntityFilterOneAndIsa(info.player, 'Babbler')
  end

  trace = Shared.TraceBox(Vector(0.5, 0.5, 0.5), info.eyePos, info.targetEngagePoint, CollisionRep.Move, PhysicsMask.All, filter)
  if trace.fraction < 1 and trace.entity ~= info.target then
    return false
  end

  self:DirectMoveTowards(context, info, info.targetEngagePoint, true)
  return true
end

function LerkMoveToTargetNode:Finish(context, natural, res)
  context.path = nil
end
