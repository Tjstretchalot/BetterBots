Script.Load("lua/bots/BTBrain.lua")

Script.Load("lua/bots/aliencomm/AlienCommanderTree.lua")

class 'AlienCommanderBrain' (BTBrain)

function AlienCommanderBrain:Initialize()
end

function AlienCommanderBrain:GetExpectedClass()
  return 'AlienCommander'
end

function AlienCommanderBrain:CreateTree()
  local actree = AlienCommanderTree()
  actree:Initialize()

  return actree:Create()
end
