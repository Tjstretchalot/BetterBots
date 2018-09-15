--- For the first minute or so we should just try and collect resource
-- nodes.

class 'AlienCollectEarlyResourceNodesStrategy' (AlienBaseStrategy)

local function GetStartMessages()
  return {
    'Good luck',
    'We got this, team!',
    'Don\'t blame me if we lose',
    'Remember: it\'s always the commanders fault',
    'Grabbing some early res nodes',
    'Tip: I will upgrade metabolize if someone goes fade',
    'Tip: I get bile bomb at 5 minutes',
    'Tip: I will upgrade charge once someone has onos res',
    'Tip: I won\'t place a hive if no aliens are in the room',
    'Tip: I won\'t place a hive if I know about marines in the room or adjacent rooms (unless rich)',
    'Tip: I won\'t place harvesters when marines are in the room',
    'Tip: I will spawn eggs whenever we have none in a hive location',
    'Tip: I wait 5 seconds to see how stuff pans out after spawning eggs',
    'Tip: I try to put crags near contested resource nodes',
    'Tip: I consider a resource node contested if it has been attacked and defended 3 times in 6 minutes',
    'Tip: I try to put crags near tunnels',
    'Tip: I try to put shifts near crags',
    'Tip: I ignore their naturals for the first minute or so',
    'Tip: Bot skulks will not gorge until their first death, so you can use that time to gorge if you\'d like',
    'Tip: Bot skulks will sometimes attack marine blips on the map but will otherwise attack res nodes',
    'Tip: Bot lerks are the only class that defends'
  }
end

function AlienCollectEarlyResourceNodesStrategy:GetStrategyScore(senses)
  if senses.gameTime < 80 then
    return kAlienStrategyScore.Highest
  end

  return kAlienStrategyScore.NotViable
end

function AlienCollectEarlyResourceNodesStrategy:GetStartMessages(senses)
  local startMessages = GetStartMessages()
  local res = {}
  table.insert(res, startMessages[math.random(1, #startMessages)])
  return res
end

function AlienCollectEarlyResourceNodesStrategy:CreateTree()
  local res = BehaviorTree()
  res:Initialize(SelectorNode():Setup({
    InvertDecorator():Setup(AlienWaitActionCooldownNode()),
    AlienStrategyUtils.CreateMaintenenceNode(),
    AlienStrategyUtils.CreateCystAndPlaceHarvestersNode(true, 2)
  }))
  return res
end
