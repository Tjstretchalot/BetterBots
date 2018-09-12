Script.Load('lua/bots/lerk/LerkUtils.lua')

Script.Load('lua/bots/lerk/LerkAttackMoveToTargetNode.lua')
Script.Load('lua/bots/lerk/LerkAttackTargetNode.lua')
Script.Load('lua/bots/lerk/LerkDirectMoveToLocationNode.lua')
Script.Load('lua/bots/lerk/LerkMoveToLocationNode.lua')
Script.Load('lua/bots/lerk/LerkMoveToTargetNode.lua')
Script.Load('lua/bots/lerk/LerkSelectAttackTargetNode.lua')
Script.Load('lua/bots/lerk/LerkSelectDefendTargetNode.lua')
Script.Load('lua/bots/lerk/LerkSetEvolveTargetNode.lua')
Script.Load('lua/bots/lerk/LerkSetPriorityTargetNode.lua')
Script.Load('lua/bots/lerk/LerkSetSurvivalInstinctsNode.lua')
Script.Load('lua/bots/lerk/LerkSetSurvivalTargetNode.lua')

Script.Load('lua/bots/lerk/LerkFleeIfScaredNode.lua')

class 'LerkTree'

function LerkTree:Initialize()
end

function LerkTree:Create()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InReadyRoomNode(),
    SequenceNode():Setup({ -- evolve
      LerkSetEvolveTargetNode(),
      SelectNearestHiveNode(),
      LerkMoveToTargetNode(),
      LerkSetEvolveTargetNode(), -- in case its changed
      EvolveNode()
    }),
    LerkFleeIfScaredNode(),
    SequenceNode():Setup({ -- attack nearby
      LerkSetPriorityTargetNode(),
      -- if we dont have los then we shouldnt actually move to attack here (better if done elsewhere). thus we
      -- do not wrap with AlwaysSucceedDecorator
      RunDoerUnlessPredicateFailsNode():Setup(InvertDecorator():Setup(LerkSetSurvivalInstinctsNode()), LerkAttackTargetNode())
    }),
    LerkFleeIfScaredNode(), -- in case it changed
    SequenceNode():Setup({
      LerkSelectDefendTargetNode(),
      AlwaysSucceedDecorator():Setup(RunDoerUnlessPredicateFailsNode():Setup(
        InvertDecorator():Setup(LerkSetSurvivalInstinctsNode()),
        LerkAttackMoveToTargetNode()
      ))
    }),
    SequenceNode():Setup({
      LerkSelectAttackTargetNode(),
      AlwaysSucceedDecorator():Setup(RunDoerUnlessPredicateFailsNode():Setup(
        InvertDecorator():Setup(LerkSetSurvivalInstinctsNode()),
        LerkAttackMoveToTargetNode()
      ))
    })
  }))
  return res
end
