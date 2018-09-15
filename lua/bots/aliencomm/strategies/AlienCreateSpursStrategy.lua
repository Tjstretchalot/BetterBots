class 'AlienCreateSpursStrategy' (AlienBaseStrategy)

function AlienCreateSpursStrategy:GetStrategyScore(senses)
  local teamTechTree = GetTechTree(senses.team)

  local foundShiftHive = teamTechTree:GetHasTech(kTechId.ShiftHive)
  local numSpurs = #GetEntitiesForTeam('Spur', senses.team)

  if senses.debug then Log('CreateSpurs - shift hive? = %s, spurs = %s', foundShiftHive, numSpurs) end
  if foundShiftHive and numSpurs < 3 then
    return kAlienStrategyScore.Higher
  end

  return kAlienStrategyScore.NotViable
end

function AlienCreateSpursStrategy:GetStartMessages(senses)
  return {
    'Getting spurs'
  }
end

function AlienCreateSpursStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    SequenceNode():Setup({
      AlienCheckResourcesNode():Setup(kSpurCost),
      InvertDecorator():Setup(AlienCheckEntitiesCountNode():Setup('Spur', 3)),
      RepeatUntilFailureNode():Setup(InvertDecorator():Setup(
        SequenceNode():Setup({
          AlienWaitActionCooldownNode(),
          AlienSetActionCooldownNode(),
          AlienSelectLocationForUpgradeNode():Setup(kTechId.Spur),
          AlienPlaceStructureNode():Setup(kTechId.Spur)
        })
      ))
    }),
    AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(true, 1)
  }))
  return res
end
