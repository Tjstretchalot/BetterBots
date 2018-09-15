class 'AlienCreateVeilsStrategy' (AlienBaseStrategy)

function AlienCreateVeilsStrategy:GetStrategyScore(senses)
  local teamTechTree = GetTechTree(senses.team)

  local foundShadeHive = teamTechTree:GetHasTech(kTechId.ShadeHive)
  local numVeils = #GetEntitiesForTeam('Veil', senses.team)
  
  if senses.debug then Log('CreateVeils - shade hive? = %s, veils = %s', foundShadeHive, numVeils) end
  if foundShadeHive and numVeils < 3 then
    return kAlienStrategyScore.Higher
  end

  return kAlienStrategyScore.NotViable
end

function AlienCreateVeilsStrategy:GetStartMessages(senses)
  return {
    'Getting veils'
  }
end

function AlienCreateVeilsStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    SequenceNode():Setup({
      AlienCheckResourcesNode():Setup(kVeilCost),
      InvertDecorator():Setup(AlienCheckEntitiesCountNode():Setup('Veil', 3)),
      RepeatUntilFailureNode():Setup(InvertDecorator():Setup(
        SequenceNode():Setup({
          AlienWaitActionCooldownNode(),
          AlienSetActionCooldownNode(),
          AlienSelectLocationForUpgradeNode():Setup(kTechId.Veil),
          AlienPlaceStructureNode():Setup(kTechId.Veil)
        })
      ))
    }),
    AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(true, 1)
  }))
  return res
end
