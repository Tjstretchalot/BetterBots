class 'AlienResearchInChamberNode' (BTNode)

function AlienResearchInChamberNode:Setup(techId)
  self.techId = techId
  return self
end

function AlienResearchInChamberNode:Run(context)
  if not context.targetId then return self.Failure end

  local target = Shared.GetEntity(context.targetId)
  if not target then
    context.targetId = nil
    return self.Failure
  end

  if not target:isa('EvolutionChamber') then return self.Failure end

  local techNode = GetTechTree(context.senses.team):GetTechNode(self.techId)
  local cost = techNode.cost

  if context.senses.resources < cost then return self.Failure end

  local player = context.bot:GetPlayer()
  target:SetSelected(context.senses.team, true)
  local success = player:AttemptToResearchOrUpgrade(techNode, target)
  target:SetSelected(context.senses.team, false)

  if success then
    context.senses:SetIsRecentlyResearchingUntil(context.targetId, context.senses.time + techNode.time)
    player:GetTeam():AddTeamResources(-cost)
  end

  return success and self.Success or self.Failure
end
