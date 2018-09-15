class 'AlienPlaceHiveStrategy' (AlienBaseStrategy)

function AlienPlaceHiveStrategy:GetStrategyScore(senses)
  if senses.resources < kHiveCost then return kAlienStrategyScore.NotViable end

  local foundTP = false
  for _, tp in ientitylist(Shared.GetEntitiesWithClassname('TechPoint')) do
    if tp.occupiedTeam ~= senses.team and tp.occupiedTeam ~= senses.enemyTeam then
      local safe, rsn = AlienCommUtils.IsSafeHiveDrop(senses, tp)
      if senses.debug then Log('PlaceHive - is dropping hive @ %s safe? %s (rsn = %s)', tp:GetLocationName(), safe, rsn) end
      local defended, rsn = AlienCommUtils.IsDefendedHiveDrop(senses, tp)
      if senses.debug then Log('PlaceHive - is dropping hive @ %s defended? %s (rsn = %s)', defended, rsn) end
      if safe and defended then return kAlienStrategyScore.Higher end
      local viable = safe or defended

      if viable then
        foundTP = true
        break
      end
    end
  end

  return foundTP and kAlienStrategyScore.Average or kAlienStrategyScore.NotViable
end

function AlienPlaceHiveStrategy:GetStartMessages()
  return {
    'I want to place a hive'
  }
end

function AlienPlaceHiveStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    SequenceNode():Setup({
      AlienCheckResourcesNode():Setup(kHiveCost),
      AlienTargetViableTechPointForHiveNode(),
      SelectTargetLocationNode(),
      ClearTargetNode(),
      AlienPlaceStructureNode():Setup(kTechId.Hive)
    })
  }))
  return res
end
