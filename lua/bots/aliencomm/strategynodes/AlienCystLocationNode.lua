--- Tries to cyst the target location

class 'AlienCystLocationNode' (BTNode)

local debugCysts = false

function AlienCystLocationNode:Run(context)
  if not context.location then
    if context.debug then
      Log('AlienCystLocationNode -> no location, returning failure')
      Log(debug.traceback())
    end
    return self.Failure
  end

  local extents = GetExtents(kTechId.Cyst)
  local cystPoint = GetRandomSpawnForCapsule(
    extents.y, -- height
    extents.x, -- radius
    context.location + Vector(0, 1, 0), -- origin
    0, -- min range
    Cyst.kInfestationRadius, -- max range
    EntityFilterAll(),
    GetIsPointOffInfestation -- validation func
  )

  if context.debug or debugCysts then Log('Attempting to cyst %s; cystPoint = %s', GetLocationForPoint(context.location):GetName(), cystPoint) end

  if not cystPoint then
    local randPoint

    for i = 1, 10 do
      randPoint = context.location + Vector(math.random() * Cyst.kInfestationRadius, 1, math.random() * Cyst.kInfestationRadius)
      local trace = Shared.TraceRay(randPoint, randPoint + Vector(0, -5, 0), CollisionRep.Move, PhysicsMask.All, EntityFilterAll())

      if trace.endPoint then
        randPoint.y = trace.endPoint.y
        if AlienCommUtils.IsInfesterCloseEnough(randPoint, Cyst.kInfestationRadius, context.location) then
          cystPoint = randPoint
          break
        end
      end
    end

    if context.debug or debugCysts then Log('Attempting to cyst %s using random loc; cystPoint = %s', GetLocationForPoint(context.location):GetName(), cystPoint) end
  end

  if not cystPoint then return self.Failure end

  local cystPoints = GetCystPoints(cystPoint, true, context.senses.team)

  if context.debug or debugCysts then Log('cystPoints = %s', cystPoints) end

  if not cystPoints or #cystPoints == 0 then
    local randPoint

    for i = 1, 10 do
      randPoint = context.location + Vector(math.random() * Cyst.kInfestationRadius, 1, math.random() * Cyst.kInfestationRadius)
      local trace = Shared.TraceRay(randPoint, randPoint + Vector(0, -5, 0), CollisionRep.Move, PhysicsMask.All, EntityFilterAll())

      if trace.endPoint then
        randPoint.y = trace.endPoint.y
        if AlienCommUtils.IsInfesterCloseEnough(randPoint, Cyst.kInfestationRadius, context.location) then
          cystPoint = randPoint
          cystPoints = GetCystPoints(cystPoint, true, context.senses.team)

          if cystPoints and #cystPoints == 0 then
            break
          end
        end
      end
    end
  end

  if not cystPoints or #cystPoints == 0 then return self.Failure end

  local cost = #cystPoints * kCystCost
  if context.debug or debugCysts then Log('cost = %s, res = %s', cost, context.senses.resources) end
  if context.senses.resources < cost then return self.Failure end

  local com = context.bot:GetPlayer()
  local techNode = com:GetTechTree():GetTechNode(kTechId.Cyst)

  com.isBotRequestedAction = true
  local success, _ = com:ProcessTechTreeActionForEntity(
    techNode,
    cystPoint,
    Vector(0, 1, 0), -- normal
    true, -- is commander
    0, -- pickVec (?)
    com, -- entity
    nil, -- trace
    nil  -- targetId
  )

  if context.debug or debugCysts then Log('cysted point; success = %s', success) end
  return success and self.Success or self.Failure
end
