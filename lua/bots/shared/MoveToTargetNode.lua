--- This node moves to context.targetId

class 'MoveToTargetNode' (BTNode)

function MoveToTargetNode:Run(context)
  if not context.targetId then
    return self.Failure
  end

  local bot = context.bot
  local target = Shared.GetEntity(context.targetId)
  if target == nil then
    context.targetId = nil
    return self.Failure
  end

  local eyePos = bot:GetPlayer():GetEyePos()
  local dist = GetDistanceToTouch(eyePos, target)
  local reqDist = context.desiredTouchDistance or 1
  if GetDistanceToTouch(eyePos, target) < (context.desiredTouchDistance or 1) then
    if context.debug then Log('MoveToTargetNode target = %s; Distance close enough: %s (needed %s)', target, dist, reqDist) end
    bot:GetMotion():SetDesiredMoveTarget(nil)
    bot:GetMotion():SetDesiredViewTarget(target:GetEngagementPoint())
    return self.Success
  end
  if context.debug then Log('MoveToTargetNode target = %s, Distance too far: %s (needed %s)', target, dist, reqDist) end
  bot:GetMotion():SetDesiredMoveTarget(target:GetOrigin())
  bot:GetMotion():SetDesiredViewTarget(nil)
  return self.Running
end

function MoveToTargetNode:Finish(context, natural, res)
  context.bot:GetMotion():SetDesiredMoveTarget(nil)
end
