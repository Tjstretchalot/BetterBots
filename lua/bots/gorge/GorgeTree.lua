Script.Load('lua/bots/lerk/LerkSetSurvivalTargetNode.lua')

Script.Load('lua/bots/gorge/GorgeHealSelfWrapper.lua')
Script.Load('lua/bots/gorge/GorgeHealTargetNode.lua')
Script.Load('lua/bots/gorge/GorgeSelectAnyHurtStructureNode.lua')
Script.Load('lua/bots/gorge/GorgeSelectNearestUnbuiltStructureNode.lua')
Script.Load('lua/bots/gorge/GorgeSelectVisibleHurtNode.lua')
Script.Load('lua/bots/gorge/GorgeSetEvolveTargetNode.lua')
Script.Load('lua/bots/gorge/GorgeSetSurvivalInstinctsNode.lua')

class 'GorgeTree'

function GorgeTree:Initialize()
end

function GorgeTree:Create()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    SequenceNode():Setup({
      GorgeSetEvolveTargetNode(),
      SelectNearestHiveNode(),
      GorgeHealSelfWrapper():Setup(MoveToTargetNode()),
      EvolveNode()
    }),
    RunDoerUnlessPredicateFailsNode():Setup(
      InvertDecorator():Setup(GorgeSetSurvivalInstinctsNode()),
      SelectorNode():Setup({
        RunDoerUnlessPredicateFailsNode():Setup(
          GorgeSelectVisibleHurtNode(),
          SequenceNode():Setup({
            GorgeHealSelfWrapper():Setup(MoveToTargetNode()),
            AlwaysSucceedDecorator():Setup(GorgeHealTargetNode())
          })
        ),
        RunDoerUnlessPredicateFailsNode():Setup(
          InvertDecorator():Setup(GorgeSelectVisibleHurtNode()),
          SelectorNode():Setup({
            SequenceNode():Setup({
              GorgeSelectNearestUnbuiltStructureNode(),
              GorgeHealSelfWrapper():Setup(MoveToTargetNode()),
              AlwaysSucceedDecorator():Setup(GorgeHealTargetNode())
            }),
            SequenceNode():Setup({
              GorgeSelectAnyHurtStructureNode(),
              GorgeHealSelfWrapper():Setup(MoveToTargetNode()),
              AlwaysSucceedDecorator():Setup(GorgeHealTargetNode())
            }),
            RunDoerUnlessPredicateFailsNode():Setup(
              InvertDecorator():Setup(SelectorNode():Setup({
                GorgeSelectNearestUnbuiltStructureNode(),
                GorgeSelectAnyHurtStructureNode(),
                InvertDecorator():Setup(SelectNearestHiveNode()) -- fix the target
              })),
              SequenceNode():Setup({
                InvertDecorator():Setup(SelectHiveInRoomNode()),
                SelectNearestHiveNode(),
                GorgeHealSelfWrapper():Setup(MoveToTargetNode())
              })
            )
          })
        ),
        GorgeHealSelfWrapper():Setup(AlwaysSucceedNode()),
      })
    ),
    RunDoerUnlessPredicateFailsNode():Setup(
      GorgeSetSurvivalInstinctsNode(),
      SequenceNode():Setup({
        LerkSetSurvivalTargetNode(),
        GorgeHealSelfWrapper():Setup(MoveToTargetNode())
      })
    )
  }))
  res.context.desiredTouchDistance = 1
  return res
end
