class 'AlienUpgradeBileBombStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeBileBombStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(1, kTechId.BioMassThree, kTechId.BileBomb, kBileBombResearchCost)
end

function AlienUpgradeBileBombStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeBileBomb - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  -- TODO make this smarter than just "do it after 5 minutes"
  if senses.debug then Log('UpgradeBileBomb - enough time has passed? %s', senses.gameTime < 300) end
  return senses.gameTime < 300 and kAlienStrategyScore.NotViable or kAlienStrategyScore.Highest
end
