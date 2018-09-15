Script.Load('lua/bots/aliencomm/AlienStrategyScore.lua')
Script.Load('lua/bots/aliencomm/AlienCommUtils.lua')
Script.Load('lua/bots/aliencomm/AlienSensedEnemyFilters.lua')
Script.Load('lua/bots/aliencomm/AlienCommanderSenses.lua')

Script.Load('lua/bots/aliencomm/AlienUpdateSensesNode.lua')
Script.Load('lua/bots/aliencomm/AlienMaybeUpdateStrategyNode.lua')
Script.Load('lua/bots/aliencomm/AlienRunStrategyNode.lua')

Script.Load('lua/bots/aliencomm/strategynodes/LoadAll.lua')

Script.Load('lua/bots/aliencomm/strategies/AlienBaseStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeBaseStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienCollectEarlyResourceNodesStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienCreateShellsStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienCreateSpursStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienCreateVeilsStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienExpensiveBiomassStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienPlaceHiveStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeBileBombStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeBoneShieldStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeChargeStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeHiveCragStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeHiveShadeStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeHiveShiftStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeLeapStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeMetabolizeEnergyStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeMetabolizeHealthStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeSporesStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeStompStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeUmbraStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeXenocideStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienWaitOnResStrategy.lua')

class 'AlienCommanderTree'

function AlienCommanderTree:Initialize()
end

function AlienCommanderTree:InitStrategies()
  local res = {
    AlienCollectEarlyResourceNodesStrategy(),
    AlienCreateShellsStrategy(),
    AlienCreateSpursStrategy(),
    AlienCreateVeilsStrategy(),
    AlienExpensiveBiomassStrategy(),
    AlienPlaceHiveStrategy(),
    AlienUpgradeBileBombStrategy(),
    AlienUpgradeBoneShieldStrategy(),
    AlienUpgradeChargeStrategy(),
    AlienUpgradeHiveCragStrategy(),
    AlienUpgradeHiveShadeStrategy(),
    AlienUpgradeHiveShiftStrategy(),
    AlienUpgradeLeapStrategy(),
    AlienUpgradeMetabolizeEnergyStrategy(),
    AlienUpgradeMetabolizeHealthStrategy(),
    AlienUpgradeSporesStrategy(),
    AlienUpgradeStompStrategy(),
    AlienUpgradeUmbraStrategy(),
    AlienUpgradeXenocideStrategy(),
    AlienWaitOnResStrategy()
  }

  for _, str in ipairs(res) do
    str:Initialize()
  end

  return res
end

function AlienCommanderTree:Create()
  local res = BehaviorTree()
  res:Initialize(SequenceNode():Setup({
    RunConcurrentNode():Setup({
        AlienUpdateSensesNode(),
        AlienMaybeUpdateStrategyNode(),
      },
      AlienRunStrategyNode()
    )
  }))
  res.context.strategies = self:InitStrategies()
  res.context.senses = AlienCommanderSenses()
  res.context.senses:Initialize()
  return res
end
