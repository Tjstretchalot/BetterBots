--- An attack move will scan using SkulkSetPriorityTargetNode in a custom
-- context, then if it finds nothing continue to delegate to a MoveToTargetNode,
-- otherwise attacks the target

class 'SkulkAttackMoveToTargetNode' (AttackMoveToTargetNode)

function SkulkAttackMoveToTargetNode:Initialize()
  self.setTargetNodeClass = SkulkSetPriorityTargetNode
  self.attackTargetNodeClass = SkulkAttackTargetNode
  self.moveNodeClass = MoveToTargetNode
  self.scanDelay = 0.5
  
  AttackMoveToTargetNode.Initialize(self)
end
