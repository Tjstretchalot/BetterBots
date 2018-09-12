--- For the first minute or so we should just try and collect resource
-- nodes.

class 'AlienCollectEarlyResourceNodes' (AlienBaseStrategy)

local swapped = false
function AlienCollectEarlyResourceNodes:GetStrategyScore(senses)
  if senses.gameTime < 80 then
    return kAlienStrategyScore.Highest
  end

  return kAlienStrategyScore.NotViable
end

function AlienCollectEarlyResourceNodes:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    InvertDecorator():Setup(AlienCheckResourcesNode():Setup(10)),
    SequenceNode():Setup({
      AlienSelectResourcePointToClaimNode(),
      AlienSetActionCooldownNode(),
      AlwaysSucceedDecorator():Setup(AlienPlaceHarvesterNode())
    }),
    SequenceNode():Setup({
      AlienSelectResourcePointToCystNode(),
      SelectTargetLocationNode(),
      ClearTargetNode(),
      AlienSetActionCooldownNode(),
      RepeatUntilFailureNode():Setup(InvertDecorator():Setup(AlienCystLocationNode())) -- this fails a *lot*
    })
  }))
  return res
end
