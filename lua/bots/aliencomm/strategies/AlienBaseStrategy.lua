Script.Load('lua/bots/aliencomm/strategies/AlienStrategyUtils.lua')

class 'AlienBaseStrategy'

function AlienBaseStrategy:Initialize()
  self.context = {}
end

function AlienBaseStrategy:GetStrategyScore(senses)
  error('not implemented')
end

function AlienBaseStrategy:GetStartMessages(senses)
  return {
    'Starting strategy ' .. ToString(self)
  }
end

function AlienBaseStrategy:CreateTree()
  error('not implemented')
end

function AlienBaseStrategy:Start()
  self.tree = self:CreateTree()
  self.tree.context = self.context
  self.tree:Start()
end

function AlienBaseStrategy:Run()
  self.tree:Run()
end

function AlienBaseStrategy:Finish()
  self.tree:Finish()
  self.tree = nil

  self.context = {}
end
