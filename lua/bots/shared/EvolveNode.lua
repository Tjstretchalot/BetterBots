--- Evolves an alien into evolveTargetTechIds

class 'EvolveNode' (BTNode)

function EvolveNode:Run(context)
  if not context.evolveTargetTechIds then return self.Failure end

  local bot = context.bot
  local player = bot:GetPlayer()
  local succ = player:ProcessBuyAction(context.evolveTargetTechIds)
  context.evolveTargetTechIds = nil
  return succ and self.Success or self.Failure
end
