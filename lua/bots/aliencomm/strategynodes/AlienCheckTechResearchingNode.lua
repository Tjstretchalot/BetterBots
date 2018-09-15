class 'AlienCheckTechResearchingNode' (BTNode)

function AlienCheckTechResearchingNode:Setup(techId)
  self.techId = techId
  return self
end

function AlienCheckTechResearchingNode:Run(context)
  local bRes = GetTechTree(context.senses.team):GetTechNode(self.techId):GetResearching()
  return bRes and self.Success or self.Failure
end
