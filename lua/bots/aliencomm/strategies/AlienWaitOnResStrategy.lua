class 'AlienWaitOnResStrategy' (AlienBaseStrategy)

function AlienWaitOnResStrategy:GetStrategyScore(senses)
  return kAlienStrategyScore.Lowest
end

function AlienWaitOnResStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(false, 1)
  }))
  return res
end
