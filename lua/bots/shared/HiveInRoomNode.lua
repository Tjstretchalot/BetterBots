--- Determines if there is a hive in the selected room

class 'HiveInRoomNode' (BTNode)

function HiveInRoomNode:Run(context)
  if not context.selectedRoomName then return self.Failure end

  for _, hive in ientitylist(Shared.GetEntitiesWithClassname("Hive")) do
    if hive:GetIsAlive() and hive:GetLocationName() == context.selectedRoomName then
      return self.Success
    end
  end

  return self.Failure
end
