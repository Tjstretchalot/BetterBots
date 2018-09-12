Script.Load('lua/bots/behaviortree/nodes/BTNode.lua')

Script.Load('lua/bots/behaviortree/nodes/AlwaysFailNode.lua')
Script.Load('lua/bots/behaviortree/nodes/AlwaysSucceedNode.lua')
Script.Load('lua/bots/behaviortree/nodes/DebugNode.lua')
Script.Load('lua/bots/behaviortree/nodes/SelectorNode.lua')
Script.Load('lua/bots/behaviortree/nodes/SequenceNode.lua')
Script.Load('lua/bots/behaviortree/nodes/AlwaysFailDecorator.lua')
Script.Load('lua/bots/behaviortree/nodes/RandomSelectorNode.lua')
Script.Load('lua/bots/behaviortree/nodes/InvertDecorator.lua')
Script.Load('lua/bots/behaviortree/nodes/RunDoerUnlessPredicateFailsNode.lua')
Script.Load('lua/bots/behaviortree/nodes/AlwaysSucceedDecorator.lua')
Script.Load('lua/bots/behaviortree/nodes/WaitForeverNode.lua')
Script.Load('lua/bots/behaviortree/nodes/WaitForDurationNode.lua')
Script.Load('lua/bots/behaviortree/nodes/RepeatDecorator.lua')
Script.Load('lua/bots/behaviortree/nodes/RunConcurrentNode.lua')
Script.Load('lua/bots/behaviortree/nodes/RepeatUntilFailureNode.lua')

class 'BehaviorTree'

function BehaviorTree:Initialize(root)
  self.root = root
  self.context = {}

  self.root:Initialize()
end

function BehaviorTree:Start()
  self.root:Start(self.context)
end

function BehaviorTree:Run()
  self.root:Run(self.context)
end

function BehaviorTree:Finish()
  self.root:Finish(self.context, false)
end
