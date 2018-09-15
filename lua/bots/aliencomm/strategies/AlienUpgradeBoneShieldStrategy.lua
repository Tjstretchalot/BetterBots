class 'AlienUpgradeBoneShieldStrategy' (AlienUpgradeBaseStrategy)

function AlienUpgradeBoneShieldStrategy:Initialize()
  AlienUpgradeBaseStrategy.Initialize(self)

  self:Setup(2, kTechId.BioMassSix, kTechId.BoneShield, kBoneShieldResearchCost)
end

function AlienUpgradeBoneShieldStrategy:GetStrategyScore(senses)
  if senses.debug then Log('UpgradeBoneShield - enough hives? %s, have upg? %s', self:HaveEnoughHives(senses), self:AlreadyHaveUpgrade(senses)) end
  if not self:HaveEnoughHives(senses) or self:AlreadyHaveUpgrade(senses) then
    return kAlienStrategyScore.NotViable
  end

  local numOnos = Shared.GetEntitiesWithClassname('Onos'):GetSize()
  if senses.debug then Log('UpgradeBoneShield - number onos = %s', numOnos) end
  return numOnos > 0 and kAlienStrategyScore.Higher or kAlienStrategyScore.NotViable
end
