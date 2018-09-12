class 'AlienUpgradeHiveNode' (BTNode)

function AlienUpgradeHiveNode:Setup(techId)
  self.techId = techId
  return self
end

function AlienUpgradeHiveNode:Run(context)
  if not context.targetId then return self.Failure end

  local target = Shared.GetEntity(context.targetId)
  if not target then
    context.targetId = nil
    return self.Failure
  end

  if not target:isa('Hive') then
    return self.Failure
  end

  local success = AlienCommUtils.ExecuteTechId(com, self.techId, Vector(0, 0, 0), target)
  return success and self.Success or self.Failure
end
