--- Behavior leaf node that always fails

class 'AlwaysFailNode' (BTNode)

function AlwaysFailNode:Run(context)
  return self.Failure
end
