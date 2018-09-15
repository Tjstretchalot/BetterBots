class 'AlienCreateShellsStrategy' (AlienBaseStrategy)

function AlienCreateShellsStrategy:GetStrategyScore(senses)
  local teamTechTree = GetTechTree(senses.team)

  local foundCragHive = teamTechTree:GetHasTech(kTechId.CragHive)
  local numShells = #GetEntitiesForTeam('Shell', senses.team)

  if senses.debug then Log('CreateShells - crag hive? = %s, shells = %s', foundCragHive, numShells) end
  if foundCragHive and numShells < 3 then
    return kAlienStrategyScore.Higher
  end

  return kAlienStrategyScore.NotViable
end

function AlienCreateShellsStrategy:GetStartMessages(senses)
  return {
    'Getting shells'
  }
end

function AlienCreateShellsStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    SequenceNode():Setup({
      AlienCheckResourcesNode():Setup(kShellCost),
      InvertDecorator():Setup(AlienCheckEntitiesCountNode():Setup('Shell', 3)),
      RepeatUntilFailureNode():Setup(InvertDecorator():Setup(
        SequenceNode():Setup({
          AlienWaitActionCooldownNode(),
          AlienSetActionCooldownNode(),
          AlienSelectLocationForUpgradeNode():Setup(kTechId.Shell),
          AlienPlaceStructureNode():Setup(kTechId.Shell)
        })
      ))
    }),
    AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(true, 1)
  }))
  return res
end
