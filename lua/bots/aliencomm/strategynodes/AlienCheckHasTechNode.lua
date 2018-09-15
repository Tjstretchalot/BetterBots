class 'AlienCheckHasTechNode' (BTNode)

function AlienCheckHasTechNode:Setup(techId)
  self.techId = techId
  return self
end

function AlienCheckHasTechNode:Run(context)
  local bRes = GetTechTree(context.senses.team):GetTechNode(self.techId):GetHasTech()

  return bRes and self.Success or self.Failure
end
