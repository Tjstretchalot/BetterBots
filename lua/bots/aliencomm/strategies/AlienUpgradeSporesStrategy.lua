class 'AlienUpgradeSporesStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeSporesStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(2, kTechId.BioMassFour, kTechId.Spores, kSporesResearchCost)
end

function AlienUpgradeSporesStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeSpores - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  if senses.debug then Log('UpgradeSpores - have 100 res? %s', senses.resources) end
  return senses.resources > 100 and kAlienStrategyScore.Average or kAlienStrategyScore.NotViable
end
