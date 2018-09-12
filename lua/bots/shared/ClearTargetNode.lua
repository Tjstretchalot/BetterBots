--- Clears the target

class 'ClearTargetNode' (BTNode)

function ClearTargetNode:Run(context)
  context.targetId = nil
  return self.Success
end
