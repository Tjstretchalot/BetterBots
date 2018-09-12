--- This node moves toward context.targetLocation

class 'MoveToLocationNode' (BTNode)

function MoveToLocationNode:Run(context)
  if not context.targetLocation then return self.Failure end

  local bot = context.bot
  local dist = context.targetLocation:GetDistance(bot:GetPlayer():GetOrigin())
  if dist < 1 then
    return self.Success
  end

  bot:GetMotion():SetDesiredMoveTarget(context.targetLocation)
  bot:GetMotion():SetDesiredViewTarget(nil)
  return self.Running
end
