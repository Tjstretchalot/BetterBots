--- Selects the nearest command station

class 'SelectNearestCommandStationNode' (BTNode)

function SelectNearestCommandStationNode:Run(context)
  local origin = context.bot:GetPlayer():GetOrigin()
  local bestTarget, bestDistSq = nil, nil

  for _, cs in ientitylist(Shared.GetEntitiesWithClassname('CommandStation')) do
    if not cs.GetIsAlive or cs:GetIsAlive() then
      local dist = origin:GetDistanceSquared(cs:GetOrigin())

      if not bestTarget or dist < bestDistSq then
        bestTarget, bestDistSq = cs, dist
      end
    end
  end

  if bestTarget then
    context.targetId = bestTarget:GetId()
    return self.Success
  end

  context.targetId = nil
  return self.Failuer
end
