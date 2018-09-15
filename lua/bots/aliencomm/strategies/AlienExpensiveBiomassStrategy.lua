class 'AlienExpensiveBiomassStrategy' (AlienBaseStrategy)

function AlienExpensiveBiomassStrategy:GetStrategyScore(senses)
  if senses.resources < 120 then
    if senses.debug then Log('ExpensiveBiomass - not rich enough') end
    return kAlienStrategyScore.NotViable
  end

  local foundHiveToUpg = false
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetBioMassLevel() <= 3 then
      foundHiveToUpg = true
      break
    end
  end

  if senses.debug then Log('ExpensiveBiomass - found potential target: %s', foundHiveToUpg) end
  return foundHiveToUpg and kAlienStrategyScore.Lower or kAlienStrategyScore.NotViable
end

function AlienExpensiveBiomassStrategy:GetStartMessages(senses)
  return {
    'I feel rich so I am getting expensive biomass'
  }
end

function AlienExpensiveBiomassStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(false, 1),
    SequenceNode():Setup({
      AlienCheckResourcesNode():Setup(120),
      AlienSelectHiveWithLowestBiomassNode(),
      AlienCheckResourcesForBiomassNode(),
      AlienSetActionCooldownNode(),
      AlienUpgradeBiomassOfTargetHiveNode()
    })
  }))
  return res
end
