AlienStrategyUtils = {}

function AlienStrategyUtils.CreateMaintenenceNode() -- succeeds if it does stuff, fails otherwise
  return SelectorNode():Setup({
    SequenceNode():Setup({
      AlienSelectMistableTargetNode(),
      AlwaysSucceedDecorator():Setup(RepeatUntilFailureNode():Setup(InvertDecorator():Setup(AlienCheckResourcesNode():Setup(2)))),
      AlienSetActionCooldownNode(),
      AlwaysSucceedDecorator():Setup(AlienMistTargetNode()),
    }),
    SequenceNode():Setup({
      AlienSelectRecystTargetNode(),
      SelectTargetLocationNode(),
      ClearTargetNode(),
      AlwaysSucceedDecorator():Setup(RepeatUntilFailureNode():Setup(InvertDecorator():Setup(AlienCystLocationNode()))),
      AlienSetActionCooldownNode():Setup(3.35)
    })
  })
end

function AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(avoidNaturals, maxCystedAtATime)
  return SelectorNode():Setup({
    SequenceNode():Setup({
      AlienSelectResourcePointToClaimNode(),
      AlwaysSucceedDecorator():Setup(RepeatUntilFailureNode():Setup(InvertDecorator():Setup(AlienCheckResourcesNode():Setup(kHarvesterCost)))),
      AlienSetActionCooldownNode(),
      SelectTargetLocationNode(),
      ClearTargetNode(),
      AlwaysSucceedDecorator():Setup(AlienPlaceStructureNode():Setup(kTechId.Harvester))
    }),
    SequenceNode():Setup({
      AlienSelectResourcePointToCystNode():Setup(avoidNaturals, maxCystedAtATime),
      SelectTargetLocationNode(),
      ClearTargetNode(),
      AlienSetActionCooldownNode(),
      -- checking resources >= 6 is not as accurate as checking the true cost but so much faster that it's worth it
      AlwaysSucceedDecorator():Setup(RepeatUntilFailureNode():Setup(InvertDecorator():Setup(AlienCheckResourcesNode():Setup(6)))),
      AlwaysSucceedDecorator():Setup(RepeatUntilFailureNode():Setup(InvertDecorator():Setup(AlienCystLocationNode())))
    })
  })
end
