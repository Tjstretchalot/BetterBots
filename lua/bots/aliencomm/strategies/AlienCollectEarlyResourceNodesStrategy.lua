--- For the first minute or so we should just try and collect resource
-- nodes.

class 'AlienCollectEarlyResourceNodesStrategy' (AlienBaseStrategy)

function AlienCollectEarlyResourceNodesStrategy:GetStrategyScore(senses)
  if senses.gameTime < 80 then
    return kAlienStrategyScore.Highest
  end

  return kAlienStrategyScore.NotViable
end

function AlienCollectEarlyResourceNodesStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(true, 2)
  }))
  return res
end
