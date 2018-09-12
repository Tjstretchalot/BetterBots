--- Contains utility functions for lerks

LerkUtils = {}


local function LerkCollisionFilter(lerk)
  local team = lerk:GetTeamNumber()
  local enemyTeam = GetEnemyTeamNumber(team)

  return function(ent)
    return (not HasMixin(ent, 'Team')) or (not HasMixin(ent, 'Live')) or (not HasMixin(ent, 'Ragdoll')) or
        ent:GetTeamNumber() == enemyTeam or ent == lerk or ent:isa('Babbler')
  end
end

local LerkSize = 0.4
local function PlayerWillLikelyCollideDuringMove(player, dir, debug)
  local extents = GetDirectedExtentsForDiameter(dir, LerkSize)
  local trace = Shared.TraceBox(extents, player:GetOrigin(), player:GetOrigin() + dir * 2, CollisionRep.Move, PhysicsMask.All, LerkCollisionFilter(player))
  if debug then
    Log('Player: ' .. player:GetName())
    Log('Collision trace: fraction = ' .. ToString(trace.fraction) .. ', surface = ' .. ToString(trace.surface) .. ', entity = ' .. ToString(trace.entity) .. ' at ' .. ToString(trace.endPoint))
  end
  return trace.entity == nil and trace.fraction < 0.45 or trace.fraction < 0.9
end

local function TryWiggleViewDirForMovement(player, viewDir)
  if not PlayerWillLikelyCollideDuringMove(player, viewDir) then return viewDir end

  -- first try wiggle up
  for i=1, 10 do
    local newViewDir = (viewDir + Vector(0, i * 0.1, 0)):GetUnit()
    if not PlayerWillLikelyCollideDuringMove(player, newViewDir) then return newViewDir end
  end

  -- then try wiggle down
  for i=1, 10 do
    local newViewDir = (viewDir + Vector(0, -(i * 0.1), 0)):GetUnit()
    if not PlayerWillLikelyCollideDuringMove(player, newViewDir) then return newViewDir end
  end

  -- wiggle left? D=
  for i=1, 5 do
    local newViewDir = (viewDir + Vector(i * 0.2, 0, 0)):GetUnit()
    if not PlayerWillLikelyCollideDuringMove(player, newViewDir) then return newViewDir end
  end

  -- wiggle right?
  for i=1, 5 do
    local newViewDir = (viewDir + Vector(-i * 0.2, 0, 0)):GetUnit()
    if not PlayerWillLikelyCollideDuringMove(player, newViewDir) then return newViewDir end
  end

  -- we failed :(
  --PlayerWillLikelyCollideDuringMove(player, viewDir, true)

  -- see if their current viewdoor will work
  local currViewDir = player:GetViewCoords().zAxis
  if not PlayerWillLikelyCollideDuringMove(player, currViewDir) then return currViewDir end

  -- desperation
  for i=1, 5 do
    local newViewDir = Vector(math.random(), math.random(), math.random()):GetUnit()
    if not PlayerWillLikelyCollideDuringMove(player, newViewDir) then return newViewDir end
  end

  return viewDir
end

function LerkUtils.DirectMoveTowards(context, move, player, pt, suppressWiggle)
  local lastFlap = player:GetTimeOfLastFlap() or 0
  local timeSinceLastFlap = lastFlap == 0 and 10 or Shared.GetTime() - lastFlap
  local speedScalar = player:GetSpeedScalar()
  local isOnGround = player:GetIsOnGround()
  local eyePos = player:GetEyePos()


  local viewDir = (pt - eyePos):GetUnit()
  viewDir = suppressWiggle and viewDir or TryWiggleViewDirForMovement(player, viewDir)

  move.yaw = GetYawFromVector(viewDir) - player:GetBaseViewAngles().yaw
  move.pitch = GetPitchFromVector(viewDir)
  move.move = Vector(0, 0, 1)

  if player:GetIsWallGripping() then
    return viewDir
  end

  if isOnGround then
    if math.random() < 0.5 then
      move.commands = AddMoveCommand(move.commands, Move.Jump)
    end
    return viewDir
  end

  if speedScalar < 0.9 and player.flapPressed and timeSinceLastFlap > 0.3 then
    return viewDir
  end

  move.commands = AddMoveCommand(move.commands, Move.Jump)
  return viewDir
end

function LerkUtils.DirectLookTowards(move, player, pt)
  local eyePos = player:GetEyePos()

  local viewDir = (pt - eyePos):GetUnit()
  move.yaw = GetYawFromVector(viewDir) - player:GetBaseViewAngles().yaw
  move.pitch = GetPitchFromVector(viewDir)
  move.move = Vector(0, 0, 1)

  return viewDir
end
