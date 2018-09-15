class 'AlienUpgradeBiomassOfTargetHiveNode' (BTNode)

function AlienUpgradeBiomassOfTargetHiveNode:Run(context)
  if not context.targetId then return self.Failure end

  local target = Shared.GetEntity(context.targetId)
  if not target then
    context.targetId = nil
    return self.Failure
  end

  if not target:isa('Hive') then return self.Failure end

  local biomass = target:GetBioMassLevel()

  local techId
  if biomass <= 1 then
    techId = kTechId.ResearchBioMassOne
  elseif biomass <= 2 then
    techId = kTechId.ResearchBioMassTwo
  elseif biomass <= 3 then
    techId = kTechId.ResearchBioMassThree
  end

  local techNode = GetTechTree(context.senses.team):GetTechNode(techId)
  local cost = techNode.cost
  local player = context.bot:GetPlayer()

  if context.senses.resources < cost then return self.Failure end

  local success = player:AttemptToResearchOrUpgrade(techNode, target)

  if success then
    context.senses:SetIsRecentlyResearchingUntil(context.targetId, context.senses.time + techNode.time)
    player:GetTeam():AddTeamResources(-cost)
  end

  return success and self.Success or self.Failure
end
