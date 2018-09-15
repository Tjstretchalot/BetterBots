class 'AlienSpawnEggsAtTargetNode' (BTNode)

function AlienSpawnEggsAtTargetNode:Run(context)
  if not context.targetId then return self.Failure end
  if context.senses.resources < kShiftHatchCost then return self.Failure end

  local target = Shared.GetEntity(context.targetId)
  if not target then
    context.targetId = nil
    return self.Failure
  end

  local player = context.bot:GetPlayer()

  local success = AlienCommUtils.ExecuteTechId(player, kTechId.ShiftHatch, Vector(1, 0, 0), target)
  if context.debug or true then Log('spawned eggs in %s; success = %s', target:GetLocationName(), success) end
  return success and self.Success or self.Failure
end
