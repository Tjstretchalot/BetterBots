class 'AlienMistTargetNode' (BTNode)

function AlienMistTargetNode:Run(context)
  if not context.targetId then return self.Failure end

  local target = Shared.GetEntity(context.targetId)
  if not target then
    context.targetId = nil
    return self.Failure
  end

  local player = context.bot:GetPlayer()
  AlienCommUtils.ExecuteTechId(player, kTechId.NutrientMist,
    target:GetOrigin(), player, context.targetId)
  return self.Success
end
