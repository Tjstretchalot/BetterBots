class 'AlienUpgradeLeapStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeLeapStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(2, kTechId.BioMassFour, kTechId.Leap, kLeapResearchCost)
end

function AlienUpgradeLeapStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeLeap - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  return kAlienStrategyScore.Higher
end
