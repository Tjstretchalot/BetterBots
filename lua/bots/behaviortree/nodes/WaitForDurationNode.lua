class 'WaitForDurationNode' (BTNode)

function WaitForDurationNode:Setup(durSecs)
  self.duration = durSecs
  return self
end

function WaitForDurationNode:Start(context)
  self.startedAt = Shared.GetTime()
end

function WaitForDurationNode:Run(context)
  if Shared.GetTime() - self.startedAt < self.duration then
    return self.Running
  end

  return self.Success
end

function WaitForDurationNode:Finish(context, natural, res)
  self.startedAt = nil
end
