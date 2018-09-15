class 'AlienUpgradeHiveShiftStrategy' (AlienBaseStrategy)

function AlienUpgradeHiveShiftStrategy:GetStrategyScore(senses)
  local foundHiveThatCanBeUpgradedShift = false

  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsBuilt() and hive:GetIsAlive()
        and not AlienCommUtils.IsHiveUpgrading(senses, hive)
        and not AlienCommUtils.IsHiveUpgraded(hive)
        and GetHiveTypeResearchAllowed(hive, kTechId.UpgradeToShiftHive) then
      foundHiveThatCanBeUpgradedShift = true
      break
    end
  end

  return foundHiveThatCanBeUpgradedShift and kAlienStrategyScore.Average or kAlienStrategyScore.NotViable
end

function AlienUpgradeHiveShiftStrategy:GetStartMessages()
  return { 'Going shift' }
end

function AlienUpgradeHiveShiftStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    InvertDecorator():Setup(AlienCheckResourcesNode():Setup(10)),
    SequenceNode():Setup({
      InvertDecorator():Setup(CheckContextFlagNode():Setup('haveUpgradedShift')),
      AlienSelectUnupgradedHiveNode(),
      AlienSetActionCooldownNode(),
      AlienUpgradeHiveNode():Setup(kTechId.UpgradeToShiftHive),
      SetContextFlagNode():Setup('haveUpgradedShift', true),
      WaitForDurationNode():Setup(1), -- takes a second for it to process upgrade
      SetContextFlagNode():Setup('forceRecheckStrategy', true)
    })
  }))
  return res
end
