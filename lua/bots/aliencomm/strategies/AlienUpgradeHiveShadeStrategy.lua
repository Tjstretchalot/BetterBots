class 'AlienUpgradeHiveShadeStrategy' (AlienBaseStrategy)

function AlienUpgradeHiveShadeStrategy:GetStrategyScore(senses)
  local foundHiveThatCanBeUpgradedShade = false

  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsBuilt() and hive:GetIsAlive()
        and not AlienCommUtils.IsHiveUpgrading(senses, hive)
        and not AlienCommUtils.IsHiveUpgraded(hive)
        and GetHiveTypeResearchAllowed(hive, kTechId.UpgradeToShadeHive) then
      foundHiveThatCanBeUpgradedShade = true
      break
    end
  end

  return foundHiveThatCanBeUpgradedShade and kAlienStrategyScore.Average or kAlienStrategyScore.NotViable
end

function AlienUpgradeHiveShadeStrategy:GetStartMessages()
  return { 'Going shade' }
end

function AlienUpgradeHiveShadeStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    InvertDecorator():Setup(AlienCheckResourcesNode():Setup(10)),
    SequenceNode():Setup({
      InvertDecorator():Setup(CheckContextFlagNode():Setup('haveUpgradedShade')),
      AlienSelectUnupgradedHiveNode(),
      AlienSetActionCooldownNode(),
      AlienUpgradeHiveNode():Setup(kTechId.UpgradeToShadeHive),
      SetContextFlagNode():Setup('haveUpgradedShade', true),
      WaitForDurationNode():Setup(1), -- takes a second for it to process upgrade
      SetContextFlagNode():Setup('forceRecheckStrategy', true)
    })
  }))
  return res
end
