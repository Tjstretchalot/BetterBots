class 'RepeatDecorator' (BTNode)

function RepeatDecorator:Setup(child, timesOrNilForForever)
  self.child = child
  self.childStarted = false
  self.times = timesOrNilForForever
  return self
end

function RepeatDecorator:Initialize()
  BTNode.Initialize(self)

  self.child:Initialize()
end

function RepeatDecorator:Run(context)
  if not self.childStarted then
    self.childStarted = true
    self.child:Start(context)
  end

  local res = self.child:Run(context)
  if res == self.Running then return res end

  self.childStarted = false
  self.child:Finish(context, true, res)

  if res == self.Success then
    if self.times == nil then return self.Running end

    if self.timesRemaining == nil then self.timesRemaining = self.times end
    self.timesRemaining = self.timesRemaining - 1
    if self.timesRemaining <= 0 then return self.Success end
    return self.Running
  end

  return self.Failure
end

function RepeatDecorator:Finish(context, natural, res)
  if self.childStarted then
    self.child:Finish(context, false)
    self.childStarted = nil
  end

  self.timesRemaining = nil
end
