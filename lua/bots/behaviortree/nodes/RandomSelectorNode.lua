--- Acts like a selector except chooses randomly

class 'RandomSelectorNode' (BTNode)

function RandomSelectorNode:Setup(children)
  self.children = children
  self.current_shuffle = nil
  self.active_index = nil
  return self
end

function RandomSelectorNode:Initialize()
  BTNode.Initialize(self)

  for _, child in ipairs(self.children) do
    child:Initialize()
  end
end

function RandomSelectorNode:Run(context)
  if self.active_index then
    local child = self.children[self.current_shuffle[self.active_index]]

    local res = child:Run(context)
    if res == self.Running then return res end

    child:Finish(context, true, res)
    if res == self.Success then
      self.current_shuffle = nil
      self.active_index = nil
      return res
    end

    self.active_index = self.active_index + 1
  end

  self.active_index = self.active_index or 1
  if not self.current_shuffle then
    self.current_shuffle = {}
    for i=1, #self.children do
      table.insert(self.current_shuffle, i)
    end
    table.shuffle(self.current_shuffle)
  end

  for ind_in_shuffle = self.active_index, #self.current_shuffle do
    local child = self.children[self.current_shuffle[ind_in_shuffle]]

    child:Start(context)
    local res = child:Run(context)
    if res == self.Running then
      self.active_index = ind_in_shuffle
      return self.Running
    end

    child:Finish(context, true, res)
    if res == self.Success then
      self.active_index = nil
      self.current_shuffle = nil
      return self.Success
    end
  end

  self.active_index = nil
  self.current_shuffle = nil
  return self.Failure
end

function RandomSelectorNode:Finish(context, natural, res)
  if self.active_index then
    local child = self.children[self.current_shuffle[self.active_index]]
    child:Finish(context, false)

    self.active_index = nil
    self.current_shuffle = nil
  end
end
