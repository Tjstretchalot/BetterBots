--- Behavior leaf node that always succeeds

class 'AlwaysSucceedNode' (BTNode)

function AlwaysSucceedNode:Run(context)
  return self.Success
end
