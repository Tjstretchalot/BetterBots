class 'AlienPlaceHarvesterNode' (BTNode)

function AlienPlaceHarvesterNode:Run(context)
  if not context.targetId then return self.Failure end

  local target = Shared.GetEntity(context.targetId)
  if not target then
    context.targetId = nil
    return self.Failure
  end

  local com = context.bot:GetPlayer()
  local techNode = com:GetTechTree():GetTechNode(kTechId.Harvester)

  com.isBotRequestedAction = true
  local success, _ = com:ProcessTechTreeActionForEntity(
    techNode,
    target:GetOrigin(),
    Vector(0, 1, 0), -- normal
    true, -- is commander
    0, -- pickVec (?)
    com, -- entity
    nil, -- trace
    nil  -- targetId
  )

  if context.debug then Log('placed harvester, success = %s', success) end
  return success and self.Success or self.Failure
end
