--- Targets a Resource Point which is not controlled by us and is not inside
-- an enemy controlled tech point.

class 'SkulkSetResourceTargetNode' (BTNode)

function SkulkSetResourceTargetNode:Run(context)
  context.targetId = nil

  local bot = context.bot
  local player = bot:GetPlayer()
  local team = player:GetTeamNumber()

  local points = {}
  for _, rp in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do
    if rp.occupiedTeam ~= team then
      table.insert(points, rp)
    end
  end

  if #points == 0 then return self.Failure end

  for _, chair in ientitylist(Shared.GetEntitiesWithClassname("CommandStation")) do
    for ind = #points, 1, -1 do
      if points[ind]:GetLocationId() == chair:GetLocationId() then
        table.remove(points, ind)
        break
      end
    end
  end

  if #points == 0 then return self.Failure end

  local choice = math.random(1, #points)
  local pt = points[choice]

  context.targetId = pt:GetId()
  return self.Success
end
