--- Custom lerk brain
-- Uses a behavior tree. Must be in this exact location to replace the default
-- lerk brain

Script.Load("lua/bots/BTBrain.lua")

Script.Load("lua/bots/lerk/LerkTree.lua")

class 'LerkBrain' (BTBrain)

function LerkBrain:Initialize()
end

function LerkBrain:GetExpectedClass()
  return 'Lerk'
end

function LerkBrain:OnAssumeControl(bot, move)
  BTBrain.OnAssumeControl(self, bot, move)

  bot.suppressBotMotion = true
end

function LerkBrain:OnLoseControl(bot)
  BTBrain.OnLoseControl(self, bot)

  bot.suppressBotMotion = false
end

function LerkBrain:CreateTree()
  local ltree = LerkTree()
  ltree:Initialize()

  return ltree:Create()
end
