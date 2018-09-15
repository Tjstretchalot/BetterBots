class 'AlienSelectHiveWithLowestBiomassNode' (BTNode)

function AlienSelectHiveWithLowestBiomassNode:Run(context)
  local bestHive, bestHiveBiomass = nil, nil
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsAlive() and hive:GetIsBuilt() and hive:GetBioMassLevel() < 4
        and not AlienCommUtils.IsHiveUpgrading(context.senses, hive) then
      local biomass = hive:GetBioMassLevel()
      if not bestHive or biomass < bestHiveBiomass then
        bestHive, bestHiveBiomass = hive, biomass
      end
    end
  end

  if not bestHive then
    context.targetId = nil
    return self.Failure
  end

  context.targetId = bestHive:GetId()
  return self.Success
end
