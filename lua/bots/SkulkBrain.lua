--- Custom skulk brain
-- Uses a behavior tree. Must be in this exact location to replace the default
-- skulk brain

Script.Load("lua/bots/BTBrain.lua")

Script.Load("lua/bots/skulk/SkulkTree.lua")

class 'SkulkBrain' (BTBrain)

function SkulkBrain:Initialize()
end

function SkulkBrain:GetExpectedClass()
  return 'Skulk'
end

function SkulkBrain:CreateTree()
  local stree = SkulkTree()
  stree:Initialize()

  return stree:Create()
end
