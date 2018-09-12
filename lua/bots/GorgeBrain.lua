Script.Load("lua/bots/BTBrain.lua")

Script.Load("lua/bots/gorge/GorgeTree.lua")

class 'GorgeBrain' (BTBrain)

function GorgeBrain:Initialize()
end

function GorgeBrain:GetExpectedClass()
  return 'Gorge'
end

function GorgeBrain:CreateTree()
  local gtree = GorgeTree()
  gtree:Initialize()

  return gtree:Create()
end
