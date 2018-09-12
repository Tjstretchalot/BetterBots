class 'AlienSetActionCooldownNode' (BTNode)

function AlienSetActionCooldownNode:Setup(duration)
  self.duration = duration
  return self
end

function AlienSetActionCooldownNode:Initialize()
  BTNode.Initialize(self)
  
  self.duration = self.duration or 1.15
end

function AlienSetActionCooldownNode:Run(context)
  context.actionCooldownUntil = context.senses.time + self.duration
end
