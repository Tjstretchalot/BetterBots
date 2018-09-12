Script.Load('lua/bots/aliencomm/AlienStrategyScore.lua')
Script.Load('lua/bots/aliencomm/AlienCommUtils.lua')
Script.Load('lua/bots/aliencomm/AlienCommanderSenses.lua')

Script.Load('lua/bots/aliencomm/AlienUpdateSensesNode.lua')
Script.Load('lua/bots/aliencomm/AlienMaybeUpdateStrategyNode.lua')
Script.Load('lua/bots/aliencomm/AlienRunStrategyNode.lua')

Script.Load('lua/bots/aliencomm/strategynodes/LoadAll.lua')

Script.Load('lua/bots/aliencomm/strategies/AlienBaseStrategy.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienCollectEarlyResourceNodes.lua')
Script.Load('lua/bots/aliencomm/strategies/AlienUpgradeHiveShiftStrategy.lua')

class 'AlienCommanderTree'

function AlienCommanderTree:Initialize()
end

function AlienCommanderTree:InitStrategies()
  local res = {
    AlienCollectEarlyResourceNodes(),
    AlienUpgradeHiveShiftStrategy()
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
