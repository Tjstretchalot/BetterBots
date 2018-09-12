--- Select the hive in the room (return success if found, false otherwise)

class 'SelectHiveInRoomNode' (BTNode)

function SelectHiveInRoomNode:Run(context)
  if not context.selectedRoomName then return self.Failure end
  for _, hive in ientitylist(Shared.GetEntitiesWithClassname("Hive")) do
    local hiveLoc = hive:GetLocationName()
    if hiveLoc == context.selectedRoomName then
      context.targetId = hive:GetId()
      return self.Success
    end
  end

  context.targetId = nil
  return self.Failure
end
