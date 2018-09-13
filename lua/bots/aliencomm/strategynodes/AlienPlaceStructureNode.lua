class 'AlienPlaceStructureNode' (BTNode)

function AlienPlaceStructureNode:Setup(techId)
  self.techId = techId
  return self
end

function AlienPlaceStructureNode:Initialize()
  BTNode.Initialize(self)
  assert(self.techId)
end

function AlienPlaceStructureNode:Run(context)
  if not context.location then return self.Failure end

  local com = context.bot:GetPlayer()
  local techNode = com:GetTechTree():GetTechNode(self.techId)

  com.isBotRequestedAction = true
  local success, _ = com:ProcessTechTreeActionForEntity(
    techNode,
    context.location,
    Vector(0, 1, 0), -- normal
    true, -- is commander
    0, -- pickVec (?)
    com, -- entity
    nil, -- trace
    nil  -- targetId
  )

  if context.debug then Log('placed structure %s in %s, success = %s', self.techId, GetLocationForPoint(context.location), success) end
  return success and self.Success or self.Failure
end
