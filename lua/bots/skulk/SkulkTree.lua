Script.Load('lua/bots/skulk/SkulkSetEvolveTarget.lua')
Script.Load('lua/bots/skulk/SkulkAttackTargetNode.lua')
Script.Load('lua/bots/skulk/SkulkSetPriorityTargetNode.lua')
Script.Load('lua/bots/skulk/SkulkSetResourceTargetNode.lua')
Script.Load('lua/bots/skulk/SkulkAttackMoveToTargetNode.lua')
Script.Load('lua/bots/skulk/SkulkSelectMinimapTarget.lua')

class 'SkulkTree'

function SkulkTree:Initialize()
end

function SkulkTree:Create()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InReadyRoomNode(),
    SequenceNode():Setup({
      SkulkSetEvolveTarget(),
      SelectCurrentRoomNode(),
      HiveInRoomNode(),
      InvertDecorator():Setup(SkulkSetPriorityTargetNode()),
      EvolveNode()
    }),
    AlwaysFailDecorator():Setup(ClearTargetNode()),
    SequenceNode():Setup({
      SkulkSetPriorityTargetNode(),
      SkulkAttackTargetNode()
    }),
    RandomSelectorNode():Setup({
      SequenceNode():Setup({
        SkulkSelectMinimapTarget(),
        SkulkAttackMoveToTargetNode()
      }),
      SequenceNode():Setup({
        SkulkSetResourceTargetNode(),
        SkulkAttackMoveToTargetNode()
      }),
    }),
    SequenceNode():Setup({
      SkulkSetEvolveTarget(),
      SelectNearestHiveNode(),
      MoveToTargetNode()
    }),
    SequenceNode():Setup({
      SelectNearestCommandStationNode(),
      SkulkAttackMoveToTargetNode()
    })
  }))
  return res
end
