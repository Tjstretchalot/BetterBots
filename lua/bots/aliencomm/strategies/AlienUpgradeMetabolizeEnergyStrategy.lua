class 'AlienUpgradeMetabolizeEnergyStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeMetabolizeEnergyStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(1, kTechId.BioMassThree, kTechId.MetabolizeEnergy, kMetabolizeEnergyResearchCost)
end

function AlienUpgradeMetabolizeEnergyStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeMetabolizeEnergy - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  local numFades = Shared.GetEntitiesWithClassname('Fade'):GetSize()
  if senses.debug then Log('UpgradeMetabolizeEnergy - numFades = %s', numFades) end

  if numFades == 0 then
    local numWithFadeRes = 0
    for _, player in ientitylist(Shared.GetEntitiesWithClassname('PlayerInfoEntity')) do
      if player.teamNumber == senses.team and player.resources >= kFadeCost then
        numWithFadeRes = numWithFadeRes + 1
      end
    end

    if senses.debug then Log('UpgradeMetabolizeEnergy - numWithFadeRes = %s', numWithFadeRes) end
    if numWithFadeRes == 0 then return kAlienStrategyScore.NotViable end
  end

  return numFades > 0 and kAlienStrategyScore.Highest or kAlienStrategyScore.Lowest
end
