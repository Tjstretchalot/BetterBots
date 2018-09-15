class 'AlienUpgradeBaseStrategy' (AlienBaseStrategy)

function AlienUpgradeBaseStrategy:Setup(numberHives, biomassTechId, techId, techCost)
  self.numberHives = numberHives
  self.biomassTechId = biomassTechId
  self.techId = techId
  self.techCost = techCost
  return self
end

function AlienUpgradeBaseStrategy:GetStartMessages(senses)
  return {
    'Getting ' .. EnumToString(kTechId, self.techId)
  }
end

function AlienUpgradeBaseStrategy:AlreadyHaveUpgrade(senses)
  local techTree = GetTechTree(senses.team)
  return (techTree:GetHasTech(self.techId) or techTree:GetTechNode(self.techId):GetResearching()) and techTree:GetHasTech(self.biomassTechId)
end

function AlienUpgradeBaseStrategy:HaveEnoughHives(senses)
  -- we check to see if we already invested in the biomass before checking
  -- if we have "enough" hives
  if GetTechTree(senses.team):GetHasTech(self.biomassTechId) then
    if senses.debug then Log('%s - have biomass already', self) end
    return true
  end

  local numHives = 0
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsAlive() and hive:GetIsBuilt() then
      numHives = numHives + 1
    end
  end

  if senses.debug then Log('%s - have %s hives, want %s hives', self, numHives, self.numberHives) end
  return numHives >= self.numberHives
end

function AlienUpgradeBaseStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(false, 1),
    SequenceNode():Setup({
      InvertDecorator():Setup(AlienCheckHasTechNode():Setup(self.biomassTechId)),
      InvertDecorator():Setup(AlienCheckTechResearchingNode():Setup(self.biomassTechId)),
      AlienSelectHiveWithLowestBiomassNode(),
      AlienCheckResourcesForBiomassNode(),
      AlienSetActionCooldownNode(),
      AlienUpgradeBiomassOfTargetHiveNode()
    }),
    SequenceNode():Setup({
      AlienCheckResourcesNode():Setup(self.techCost),
      InvertDecorator():Setup(AlienCheckHasTechNode():Setup(self.techId)),
      AlienCheckHasTechNode():Setup(self.biomassTechId),
      InvertDecorator():Setup(AlienCheckTechResearchingNode():Setup(self.techId)),
      AlienSelectIdleEvoChamberNode(),
      AlienSetActionCooldownNode(),
      AlienResearchInChamberNode():Setup(self.techId)
    })
  }))
  return res
end
