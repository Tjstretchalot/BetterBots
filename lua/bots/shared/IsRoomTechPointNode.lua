--- Determines if the selected room is a tech point

class 'IsRoomTechPointNode' (BTNode)

function IsRoomTechPointNode:Run(context)
  if not context.selectedRoomName then return self.Failure end

  for _, techPoint in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
    if techPoint:GetLocationName() == context.selectedRoomName then
      return self.Success
    end
  end

  return self.Failure
end
