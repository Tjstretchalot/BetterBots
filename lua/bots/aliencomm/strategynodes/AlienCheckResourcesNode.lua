class 'AlienCheckResourcesNode' (BTNode)

function AlienCheckResourcesNode:Setup(amount)
  self.amount = amount
  return self
end

function AlienCheckResourcesNode:Run(context)
  if context.senses.resources < self.amount then
    return self.Failure
  end

  return self.Success
end
