class 'SelectNearestHiveNode' (BTNode)

function SelectNearestHiveNode:Run(context)
  local eyePos = context.bot:GetPlayer():GetEyePos()
  local bestHive, bestDistSq = nil, nil
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname("Hive")) do
    if hive:GetIsAlive() and hive:GetIsBuilt() then
      local distSq = hive:GetOrigin():GetDistanceSquared(eyePos)
      if bestHive == nil or distSq < bestDistSq then
        bestHive = hive
        bestDistSq = distSq
      end
    end
  end
  if not bestHive then
    context.targetId = nil
    return self.Failure
  end

  context.targetId = bestHive:GetId()
  return self.Success
end
