class 'AlienUpgradeHiveShiftStrategy' (AlienBaseStrategy)

function AlienUpgradeHiveShiftStrategy:GetStrategyScore(senses)
  local foundUnupgradedHive = false
  local foundShiftHive = false

  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive.classname ~= 'Hive' then
      foundUnupgradedHive = true
    end

    if hive:isa('ShiftHive') then
      foundShiftHive = true
      break
    end
  end

  if foundShiftHive or not foundUnupgradedHive then
    return kAlienStrategyScore.NotViable
  else
    return kAlienStrategyScore.Average
  end
end


function AlienUpgradeHiveShiftStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(AlwaysSucceedNode())
  return res
end
