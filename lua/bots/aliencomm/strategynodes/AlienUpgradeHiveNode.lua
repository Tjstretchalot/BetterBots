class 'AlienUpgradeHiveNode' (BTNode)

function AlienUpgradeHiveNode:Setup(techId)
  self.techId = techId
  return self
end

function AlienUpgradeHiveNode:Run(context)
  if not context.targetId then return self.Failure end

  local target = Shared.GetEntity(context.targetId)
  if not target then
    context.targetId = nil
    return self.Failure
  end

  if not target:isa('Hive') then
    return self.Failure
  end

  local player = context.bot:GetPlayer()
  local techNode = player:GetTechTree():GetTechNode(self.techId)
  local cost = techNode.cost

  if context.senses.resources < cost then return self.Failure end
  
  local success = player:AttemptToResearchOrUpgrade(techNode, target)

  if success then
    context.senses:SetIsRecentlyResearchingUntil(context.targetId, context.senses.time + techNode.time)
    player:GetTeam():AddTeamResources(-cost)
  end

  return success and self.Success or self.Failure
end
