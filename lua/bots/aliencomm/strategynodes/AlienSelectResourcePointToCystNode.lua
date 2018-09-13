class 'AlienSelectResourcePointToCystNode' (BTNode)

function AlienSelectResourcePointToCystNode:Setup(avoidNaturals, maxCystedAtATime)
  self.avoidNaturals = avoidNaturals or false
  self.maxCystedAtATime = maxCystedAtATime or 1
  return self
end

function AlienSelectResourcePointToCystNode:Initialize()
  BTNode.Initialize(self)
  self.avoidNaturals = self.avoidNaturals or false
  self.maxCystedAtATime = self.maxCystedAtATime or 1
end

function AlienSelectResourcePointToCystNode:Run(context)
  local numCysted = 0

  local infos = context.senses:GetUnclaimedResourcePointInfos()
  for _, info in ipairs(infos) do
    if info.hasInfestation or info.willHaveInfestation then
      numCysted = numCysted + 1
    end
  end

  if numCysted >= self.maxCystedAtATime then return self.Failure end

  local hives = {}
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname('Hive')) do
    if hive:GetIsBuilt() then
      table.insert(hives, hive)
    end
  end

  local locsToAvoid = {}

  if self.avoidNaturals then
    local enemyMainBaseName = context.senses:GetEnemyMainBaseName()
    if enemyMainBaseName ~= nil and enemyMainBaseName ~= '' then
      local adj = GetAdjacentTo(enemyMainBaseName)
      for i=1, math.min(2, #adj) do -- maximum of 2 naturals to avoid
        locsToAvoid[adj[i]] = true
      end
    end
  end

  local bestNode, bestDistSq = nil, nil
  for _, info in ipairs(infos) do
    if not info.hasInfestation and not info.willHaveInfestation then
      local ent = Shared.GetEntity(info.id)
      if ent then
        local locNm = UrgentGetLocationName(ent)
        local acceptable = #context.senses:GetKnownEnemiesInRoom(locNm) == 0 and not locsToAvoid[locNm]

        if acceptable then
          for _, hive in ipairs(hives) do
            local distSq = hive:GetOrigin():GetDistanceSquared(ent:GetOrigin())

            if not bestNode or distSq < bestDistSq then
              bestNode, bestDistSq = ent, distSq
            end
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
