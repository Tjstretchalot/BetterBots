class 'AlienUpgradeHiveCragStrategy' (AlienBaseStrategy)

function AlienUpgradeHiveCragStrategy:GetStrategyScore(senses)
  local foundHiveThatCanBeUpgradedCrag = false

  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsBuilt() and hive:GetIsAlive()
        and not AlienCommUtils.IsHiveUpgrading(senses, hive)
        and not AlienCommUtils.IsHiveUpgraded(hive)
        and GetHiveTypeResearchAllowed(hive, kTechId.UpgradeToCragHive) then
      foundHiveThatCanBeUpgradedCrag = true
      break
    end
  end

  return foundHiveThatCanBeUpgradedCrag and kAlienStrategyScore.Average or kAlienStrategyScore.NotViable
end

function AlienUpgradeHiveCragStrategy:GetStartMessages()
  return { 'Going crag' }
end

function AlienUpgradeHiveCragStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    InvertDecorator():Setup(AlienCheckResourcesNode():Setup(10)),
    SequenceNode():Setup({
      InvertDecorator():Setup(CheckContextFlagNode():Setup('haveUpgradedCrag')),
      AlienSelectUnupgradedHiveNode(),
      AlienSetActionCooldownNode(),
      AlienUpgradeHiveNode():Setup(kTechId.UpgradeToCragHive),
      SetContextFlagNode():Setup('haveUpgradedCrag', true),
      WaitForDurationNode():Setup(1), -- takes a second for it to process upgrade
      SetContextFlagNode():Setup('forceRecheckStrategy', true)
    })
  }))
  return res
end
