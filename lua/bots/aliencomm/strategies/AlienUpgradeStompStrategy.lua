class 'AlienUpgradeStompStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeStompStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(3, kTechId.BioMassEight, kTechId.Stomp, kStompResearchCost)
end

function AlienUpgradeStompStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeStomp - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  local numOnos = Shared.GetEntitiesWithClassname('Onos'):GetSize()
  if senses.debug then Log('UpgradeStomp - numOnos = %s', numOnos) end
  return numOnos > 0 and kAlienStrategyScore.Higher or kAlienStrategyScore.NotViable
end
