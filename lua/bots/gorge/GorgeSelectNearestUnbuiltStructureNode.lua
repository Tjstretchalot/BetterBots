class 'GorgeSelectNearestUnbuiltStructureNode' (BTNode)

function GorgeSelectNearestUnbuiltStructureNode:Run(context)
  local origin = context.bot:GetPlayer():GetOrigin()
  local bestTarget, bestDistSq = nil, nil
  for _, struct in ipairs(GetEntitiesWithMixinForTeam('Construct', context.bot:GetPlayer():GetTeamNumber())) do
    if not struct:isa('Cyst') and not struct:GetIsBuilt() then
      local distSq = origin:GetDistanceSquared(struct:GetOrigin())

      if not bestTarget or distSq < bestDistSq then
        bestTarget, bestDistSq = struct, distSq
      end
    end
  end

  if bestTarget then
    context.targetId = bestTarget:GetId()
    return self.Success
  end

  context.targetId = nil
  return self.Failure
end
