class 'AlienUpgradeUmbraStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeUmbraStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(2, kTechId.BioMassFive, kTechId.Umbra, kUmbraResearchCost)
end

function AlienUpgradeUmbraStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeUmbra - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  return kAlienStrategyScore.Average
end
