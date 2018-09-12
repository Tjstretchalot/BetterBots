class 'AlienSelectResourcePointToCystNode' (BTNode)

function AlienSelectResourcePointToCystNode:Run(context)
  local numCysted = 0

  local infos = context.senses:GetUnclaimedResourcePointInfos()
  for _, info in ipairs(infos) do
    if info.hasInfestation or info.willHaveInfestation then
      numCysted = numCysted + 1
    end
  end

  if numCysted >= 2 then return self.Failure end

  local hives = {}
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsBuilt() then
      table.insert(hives, hive)
    end
  end

  local bestNode, bestDistSq = nil, nil
  for _, info in ipairs(infos) do
    if not info.hasInfestation and not info.willHaveInfestation then
      local ent = Shared.GetEntity(info.id)
      if ent then
        local enemies = context.senses:GetKnownEnemiesInRoom(UrgentGetLocationName(ent))

        for _, hive in ipairs(hives) do
          local distSq = hive:GetOrigin():GetDistanceSquared(ent:GetOrigin())

          if not bestNode or distSq < bestDistSq then
            bestNode, bestDistSq = ent, distSq
          end
        end
      end
    end
  end

  if bestNode then
    context.targetId = bestNode:GetId()
    return self.Success
  end

  context.targetId = nil
  return self.Failure
end
