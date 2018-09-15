class 'AlienUpgradeChargeStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeChargeStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(1, kTechId.BioMassTwo, kTechId.Charge, kChargeResearchCost)
end

function AlienUpgradeChargeStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeCharge - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  local numberOnosOrWithOnosRes = 0

  for _, player in ientitylist(Shared.GetEntitiesWithClassname('PlayerInfoEntity')) do
    if player.teamNumber == senses.team and (player.resources >= kOnosCost or player.currentTech == kTechId.Onos) then
      numberOnosOrWithOnosRes = numberOnosOrWithOnosRes + 1
    end
  end

  if senses.debug then Log('UpgradeCharge - num onos or with res: %s', numberOnosOrWithOnosRes) end
  if numberOnosOrWithOnosRes == 0 then return kAlienStrategyScore.NotViable
  elseif numberOnosOrWithOnosRes == 1 then return kAlienStrategyScore.Average
  else return kAlienStrategyScore.Higher end
end
