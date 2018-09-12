class 'SelectTargetLocationNode' (BTNode)

function SelectTargetLocationNode:Run(context)
  if not context.targetId then return self.Failure end

  local target = Shared.GetEntity(context.targetId)
  if not target then return self.Failure end

  context.location = target:GetOrigin()
  return self.Success
end
