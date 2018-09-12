class 'LerkAttackMoveToTargetNode' (AttackMoveToTargetNode)

local function _CreateLerkAttackTargetNode()
  return RunConcurrentNode():Setup({ LerkSetSurvivalInstinctsNode() }, LerkAttackTargetNode())
end
function LerkAttackMoveToTargetNode:Initialize()
  self.setTargetNodeClass = LerkSetPriorityTargetNode
  self.attackTargetNodeClass = _CreateLerkAttackTargetNode
  self.moveNodeClass = LerkMoveToTargetNode
  self.scanDelay = 0.1 -- lerks move really fast so this has to be low

  AttackMoveToTargetNode.Initialize(self)
end

function LerkAttackMoveToTargetNode:Run(context)
  if context.debug then Log('HERE (16)') end
  return AttackMoveToTargetNode.Run(self, context)
end
