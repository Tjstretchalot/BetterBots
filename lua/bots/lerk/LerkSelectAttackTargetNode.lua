--- Selects a good offensive target if we can find one. This is basically
-- a random selector but encapsalates what is ultimately a single choice

class 'LerkSelectAttackTargetNode' (BTNode)

function LerkSelectAttackTargetNode:Run(context)
  context.targetId = nil

  local selectors = {
    self.TrySelectResourceNode,
    self.TrySelectOffensiveMarineBlip,
    self.TrySelectEnemyTechPoint
  }

  table.shuffle(selectors)

  for _, curr in ipairs(selectors) do
    if curr(self, context) then
      if context.debug then Log('Attacking target %s (%s)', Shared.GetEntity(context.targetId), context.targetId) end
      return self.Success
    end
  end

  if context.debug then Log('lerk found no attack targets') end
  return self.Failure
end

function LerkSelectAttackTargetNode:TrySelectResourceNode(context)
  local team = context.bot:GetPlayer():GetTeamNumber()
  local points = {}
  for _, rp in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do
    if rp.occupiedTeam ~= team then
      table.insert(points, rp)
    end
  end

  if #points == 0 then return false end

  -- unlike skulks we don't mind attack res nodes in tech points since we use
  -- a more sophisticated retreat system

  local choice = math.random(1, #points)
  local pt = points[choice]

  context.targetId = pt:GetId()
  return true
end

function LerkSelectAttackTargetNode:TrySelectOffensiveMarineBlip(context)
  -- right now this is identical to the skulk version since that is pretty
  -- offensive

  local targets = {}

  local bot = context.bot
  local player = bot:GetPlayer()
  local eyePos = player:GetEyePos()

  local bestTarget, bestDistanceSqd = nil, nil
  for _, blip in ientitylist(Shared.GetEntitiesWithClassname('MapBlip')) do
    local ent = Shared.GetEntity(blip:GetOwnerEntityId())

    if ent:isa('Marine') then
      local dist = ent:GetOrigin():GetDistanceSquared(eyePos)
      if bestTarget == nil or dist < bestDistanceSqd then
        bestTarget, bestDistanceSqd = ent, dist
      end
    end
  end

  if bestTarget ~= nil then
    context.targetId = bestTarget:GetId()
    return true
  end

  return false
end

function LerkSelectAttackTargetNode:TrySelectEnemyTechPoint(context)
  local team = context.bot:GetPlayer():GetTeamNumber()
  local points = {}
  for _, tp in ientitylist(Shared.GetEntitiesWithClassname('TechPoint')) do
    if tp.occupiedTeam ~= team then
      table.insert(points, tp)
    end
  end

  if #points == 0 then return false end

  local choice = math.random(1, #points)
  local pt = points[choice]

  context.targetId = pt:GetId()
  return true
end
