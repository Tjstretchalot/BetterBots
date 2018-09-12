-- Very similiar to MoveToTargetNode however there are enough differences
-- that it might be more effort than it's worth to standardize these two.
-- Notably LOS is more ambiguous in this version

class 'LerkMoveToLocationNode' (BTNode)

local CLOSE_TO_PATHFINDING_NODE_SQD_XZ = 4

function LerkMoveToLocationNode:Run(context)
  if not context.location then
    return self.Failure
  end

  local bot = context.bot

  local eyePos = bot:GetPlayer():GetEyePos()
  if eyePos:GetDistanceSquared(context.location) < 1 then
    return self.Success
  end

  local move = context.move
  local player = bot:GetPlayer()
  local time = Shared.GetTime()

  return self:DoActualMove(context, {
    bot = bot,
    move = move,
    player = player,
    origin = player:GetOrigin(),
    eyePos = eyePos,
    location = context.location,
    time = time
  })
end

function LerkMoveToLocationNode:DoActualMove(context, info)
  if self:TryDirectMoveToLocation(context, info) then return self.Running end
  if self:TryUseGeneratedPathToLocation(context, info) then return self.Running end
  if self:TryGenerateAndUsePathToLocation(context, info) then return self.Running end

  return self.Failure
end

function LerkMoveToLocationNode:TryUseGeneratedPathToLocation(context, info)
  if not context.path then return false end

  if context.path.index > #context.path.points then
    context.path = nil -- this happens from the tailcall
    return false
  end

  local currPoint = context.path.points[context.path.index]

  local moveDir = (currPoint - info.origin)
  local lenSqd = moveDir.x * moveDir.x + moveDir.z * moveDir.z

  if lenSqd < CLOSE_TO_PATHFINDING_NODE_SQD_XZ then
    context.path.index = context.path.index + 1
    return self:TryUseGeneratedPathToLocation(context, info)
  end

  self:DirectMoveTowards(context, info, Vector(currPoint.x, currPoint.y + 1, currPoint.z))
  return true
end

function LerkMoveToLocationNode:DirectMoveTowards(context, info, pt)
  LerkUtils.DirectMoveTowards(context, info.move, info.player, pt)
end

function LerkMoveToLocationNode:TryGenerateAndUsePathToLocation(context, info)
  local pathPoints = PointArray()
  local reachable = Pathing.GetPathPoints(info.origin, info.location, pathPoints)

  if not reachable then return false end

  context.path = {
    points = pathPoints,
    index = 1,
    target = info.location
  }

  return LerkMoveToLocationNode:TryUseGeneratedPathToLocation(context, info)
end

function LerkMoveToLocationNode:TryDirectMoveToLocation(context, info)
  local filter = EntityFilterOneAndIsa(info.player, 'Babbler')

  trace = Shared.TraceBox(Vector(0.4, 0.4, 0.4), info.eyePos, info.location, CollisionRep.Move, PhysicsMask.All, filter)
  if trace.fraction < 0.9 then
    return false
  end

  self:DirectMoveTowards(context, info, info.location)
  return true
end

function LerkMoveToLocationNode:Finish(context, natural, res)
  context.path = nil
end
