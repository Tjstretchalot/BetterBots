class 'AlienUpgradeMetabolizeHealthStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeMetabolizeHealthStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(2, kTechId.BioMassFive, kTechId.MetabolizeHealth, kMetabolizeHealthResearchCost)
end

function AlienUpgradeMetabolizeHealthStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeMetabolizeHealth - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  if not GetTechTree(senses.team):GetTechNode(kTechId.MetabolizeEnergy):GetHasTech() then
    if senses.debug then Log('UpgradeMetabolizeHealth - waiting on MetabolizeEnergy') end
    return kAlienStrategyScore.NotViable
  end

  local numFades = Shared.GetEntitiesWithClassname('Fade'):GetSize()
  if senses.debug then Log('UpgradeMetabolizeHealth - numFades = %s', numFades) end
  return numFades > 0 and kAlienStrategyScore.Higher or kAlienStrategyScore.NotViable
end
