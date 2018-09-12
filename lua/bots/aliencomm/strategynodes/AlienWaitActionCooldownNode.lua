class 'AlienWaitActionCooldownNode' (BTNode)

function AlienWaitActionCooldownNode:Run(context)
  if not context.actionCooldownUntil or context.senses.time > context.actionCooldownUntil then
    return self.Success
  end

  return self.Running
end
