class 'AlienUpgradeXenocideStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeXenocideStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(3, kTechId.BioMassNine, kTechId.Xenocide, kXenocideResearchCost)
end

function AlienUpgradeXenocideStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeXenocide - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  return kAlienStrategyScore.Average
end
