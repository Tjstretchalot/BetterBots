--- Tries to cyst the target location

class 'AlienCystLocationNode' (BTNode)

local debugCysts = false

function AlienCystLocationNode:Run(context)
  if not context.location then return self.Failure end

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

  if context.debug or debugCysts then Log('cystPoint = %s', cystPoint) end
  if not cystPoint then return self.Failure end

  local cystPoints = GetCystPoints(cystPoint, true, context.senses.team)

  if context.debug or debugCysts then Log('cystPoints = %s', cystPoints) end
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
