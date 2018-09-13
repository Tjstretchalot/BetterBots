class 'AlienCheckEntitiesCountNode' (BTNode)

function AlienCheckEntitiesCountNode:Setup(searchClassname, count)
  self.searchClassname = searchClassname
  self.count = count
  return self
end

function AlienCheckEntitiesCountNode:Run(context)
  return Shared.GetEntitiesWithClassname(self.searchClassname):GetSize() >= self.count and self.Success or self.Failure
end
