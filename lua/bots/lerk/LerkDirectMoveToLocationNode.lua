class 'LerkDirectMoveToLocationNode' (BTNode)

function LerkDirectMoveToLocationNode:Start(context)
  self.lastLocation = Vector(0, 0, 0)
end

function LerkDirectMoveToLocationNode:Run(context)
  if not context.location then return self.Failure end

  local player = context.bot:GetPlayer()
  local origin = player:GetOrigin()
  local distToLoc = origin:GetDistance(context.location)

  if distToLoc < 1.5 then return self.Success end

  local movement = self.lastLocation:GetDistance(origin)
  self.lastLocation = origin

  if movement < 0.02 then
    Log('detected stuck')
    return self.Success
  end



  local desiredSpeedScalar = math.min(0.9, distToLoc / 10)
  LerkUtils.DirectLookTowards(context.move, player, context.location)

  if player:GetSpeedScalar() < desiredSpeedScalar and player.flapPressed then -- dont need to move fast when this clsoe
  else
    context.move.commands = AddMoveCommand(context.move.commands, Move.Jump)
  end

  if player:GetSpeedScalar() > desiredSpeedScalar + 0.5 then
    context.move.move = Vector(0, 0, -1)
  else
    context.move.move = Vector(0, 0, 1)
  end
end
