class 'GorgeHealTargetNode' (BTNode)

function GorgeHealTargetNode:Run(context)
  local targetId = context.targetId
  if not targetId or targetId == Entity.invalidId then return self.Failure end

  local target = Shared.GetEntity(targetId)
  if not target or not target:GetIsAlive() then
    context.targetId = nil
    return self.Failure
  end

  if target:GetHealth() == target:GetMaxHealth() and target:GetArmor() == target:GetMaxArmor() then
    if context.debug then Log('target %s has health (%s) equal to max (%s) and armor (%s) equal to max (%s) -> success', target, target:GetHealth(), target:GetMaxHealth(), target:GetArmor(), target:GetMaxArmor()) end
    return self.Success
  end

  context.bot:GetMotion():SetDesiredViewTarget(target:GetEngagementPoint())
  context.bot:GetMotion():SetDesiredMoveTarget(target:GetOrigin())

  context.move.commands = AddMoveCommand(context.move.commands, Move.SecondaryAttack)
  return self.Running
end

function GorgeHealTargetNode:Finish(context, natural, res)
  context.bot:GetMotion():SetDesiredMoveTarget(nil)
  context.bot:GetMotion():SetDesiredViewTarget(nil)
end
