class 'AlienCommanderSenses'

local needSetupHooks = false
if not gAlienSensesTable then
  gAlienSensesTable = setmetatable({}, {__mode = 'k'})

  needSetupHooks = true
end

function AlienCommanderSenses:Initialize()
  self.state = kGameState.NotStarted
  self.team = kTeam2Index -- todo
  self.enemyTeam = GetEnemyTeamNumber(self.team)

  gAlienSensesTable[self] = true
end

function AlienCommanderSenses:Update(player)
  local gameInfo = GetGameInfoEntity()
  if not gameInfo then return end

  self.state = gameInfo:GetState()
  self.time = Shared.GetTime()

  if self.state == kGameState.Started then
    self.__cleaned = false
    self:DoUpdate(player, gameInfo)
    return
  end

  if not self.__cleaned then
    self:Clean()
    self.__cleaned = true
  end
end

function AlienCommanderSenses:Clean()
  self.resources = nil
  self.nextUpdateHarvesters = nil
  self.harvesterInfos = nil
  self.nextUpdateUnclaimedRPs = nil
  self.unclaimedResourcePoints = nil
  self.nextUpdateEnemies = nil
  self.enemies = nil
  self.enemyMainBaseName = nil
  self.recentlyResearchingStructures = nil
end

-- Public functions

--- Get information for the given harvester, if we have it
--
-- Information is: {
--   id: number                   - id of the harvester
--   built: boolean               - if the harvester is built (ie GetIsBuilt)
--   underAttack: boolean         - if the harvester is taking damage,
--   attackHistory: table         - contains a list of times where the harvester was attacked (max 10 entries)
--   hasInfestation: boolean      - if the harvester currently has infestation
--   willHaveInfestation: boolean - if the harvester has a cyst close enough that it will have infestation once that cyst grows
-- }
--
-- There may be other variables in there that aren't useful outside of calculating
-- the listed variables
--
-- @tparam number id the id of the harvester you want info on
-- @treturn boolean if we have information about that harvester
-- @treturn table the information about that harvester
function AlienCommanderSenses:GetHarvesterInfoById(id)
  if not self.harvesterInfos then return false, nil end

  local info = self.harvesterInfos.lookup[id]
  if info then return true, info end
  return false, nil
end

--- Get a list of harvester information
--
-- See GetHarvesterInfoById for what each table contains
--
-- @treturn table the iterable (via ipairs) table of harvester info
function AlienCommanderSenses:GetHarvesterInfos()
  if not self.harvesterInfos then return {} end

  return self.harvesterInfos.arr
end

--- Get a list of unclaimed resource point information
--
-- Information is {
--   id: number                   - id of the resource point  (RP)
--   hasInfestation: boolean      - if the RP currently has infestation
--   willHaveInfestation: boolean - if the RP has a cyst close enough that it will have infestation once that cyst grows
-- }
--
-- @treturn table the iterable (via ipairs) table of unclaimed resource point info
function AlienCommanderSenses:GetUnclaimedResourcePointInfos()
  if not self.unclaimedResourcePoints then return {} end

  return self.unclaimedResourcePoints.arr
end

--- Get a list of all known enemies
--
-- Information is {
--   id: number,
--   blipType: number,
--   lastSeen: number,
--   location: Vector,
--   locationName: string
-- }
--
-- @treturn table the iterable (via ipairs) enemies
function AlienCommanderSenses:GetAllKnownEnemies()
  if not self.enemies then return {} end

  return self.enemies.fullArr
end

--- Get a list of known enemies by location
--
-- See GetAllKnownEnemies for what each table contains
--
-- @tparam string locationName the name of the location
-- @treturn table the iterable (via ipairs) enemies in that room
function AlienCommanderSenses:GetKnownEnemiesInRoom(locationName)
  if not self.enemies then return {} end

  return self.enemies.byLocation[location] or {}
end

--- Get the name of the location where the enemy has their "main base"
-- @treturn string name of enemy main base
function AlienCommanderSenses:GetEnemyMainBaseName()
  return self.enemyMainBaseName
end

--- Returns true if the structure with the given id is potentially still
-- researching.
--
-- This is a workaround for the time between research completing and
-- the tech tree being updated.
--
-- @tparam number structId the id of the structure
-- @treturn boolean true if still researching, false otherwise
function AlienCommanderSenses:GetIsRecentlyResearching(structId)
  if not self.recentlyResearchingStructures then return false end

  local resUntil = self.recentlyResearchingStructures[structId]
  if not resUntil then return false end

  if resUntil < self.time then
    self.recentlyResearchingStructures[structId] = nil
    return false
  end

  return true
end

--- Sets the time until the specified structure finishes researching.
--
-- @tparam number structId the id of the structure
-- @tparam number timeUntil the time at which the structure finishes (do NOT include wiggle room)
function AlienCommanderSenses:SetIsRecentlyResearchingUntil(structId, timeUntil)
  self.recentlyResearchingStructures = self.recentlyResearchingStructures or {}
  self.recentlyResearchingStructures[structId] = timeUntil + 3 -- tech tree takes a long time to update
end
-- End public functions

function AlienCommanderSenses:DoUpdate(player, gameInfo)
  PROFILE("AlienCommanderSenses:DoUpdate")
  self.gameTime = math.max(0, math.floor(self.time) - gameInfo:GetStartTime())

  self.resources = player:GetTeam():GetTeamResources()
  self:UpdateHarvesters()
  self:UpdateUnclaimedResourcePoints()
  self:UpdateEnemies()
  self:UpdateEnemyMainBase()
end

function AlienCommanderSenses:UpdateHarvesters()
  if self.nextUpdateHarvesters and self.time < self.nextUpdateHarvesters then
    return
  end

  self.harvesterInfos = self.harvesterInfos or { arr = {}, lookup = {} }

  -- we use a tiny bit of randomness because otherwise we get these ticks
  -- where we update everything for everything and in most ticks we do
  -- nothing.
  self.nextUpdateHarvesters = self.time + 0.9 + math.random() * 0.2

  local missingHarvesters = {}
  for _, info in ipairs(self.harvesterInfos.arr) do
    missingHarvesters[info.id] = true
  end

  for _, harv in ientitylist(Shared.GetEntitiesWithClassname('Harvester')) do
    local id = harv:GetId()
    local info = self.harvesterInfos.lookup[id]

    if not info then
      info = { id = id, attackHistory = {} }
      table.insert(self.harvesterInfos.arr, info)
      self.harvesterInfos.lookup[id] = info
    else
      missingHarvesters[id] = nil
    end

    info.built = harv:GetIsBuilt()

    local prevHealth = info.lastHealth or harv:GetHealth()
    local prevArmor = info.lastArmor or harv:GetArmor()

    info.lastHealth = harv:GetHealth()
    info.lastArmor = harv:GetArmor()

    local reallyUnderAttack = info.lastHealth < prevHealth or info.lastArmor < prevArmor
    local wouldListAsUnderAttack = info.underAttackUntil and self.time < info.underAttackUntil or false
    if reallyUnderAttack then
      info.underAttack = true
      info.underAttackUntil = self.time + 5

      if not wouldListAsUnderAttack then
        table.insert(info.attackHistory, self.time)

        if #info.attackHistory > 10 then
          table.remove(info.attackHistory, 1) -- not bad since its done at most once every 5 seconds
        end
      end
    else
      info.underAttack = wouldListAsUnderAttack
    end

    info.hasInfestation = harv:GetGameEffectMask(kGameEffect.OnInfestation)
    info.willHaveInfestation = info.hasInfestation or AlienCommUtils.HasNearEnoughInfester(harv)
  end

  for missingId, _ in pairs(missingHarvesters) do
    local ind = nil
    for i, inf in ipairs(self.harvesterInfos.arr) do
      if inf.id == missingId then
        ind = i
        break
      end
    end
    assert(ind ~= nil)
    table.remove(self.harvesterInfos.arr, ind)
    self.harvesterInfos.lookup[missingId] = nil
  end
end

function AlienCommanderSenses:UpdateUnclaimedResourcePoints()
  if self.nextUpdateUnclaimedRPs and self.time < self.nextUpdateUnclaimedRPs then
    return
  end

  self.unclaimedResourcePoints = self.unclaimedResourcePoints or { arr = {}, lookup = {} }
  self.nextUpdateUnclaimedRPs = self.time + 0.9 + math.random() * 0.2

  local unclRPs = self.unclaimedResourcePoints -- name is shorter

  local missingIds = {}
  for _, inf in ipairs(unclRPs.arr) do
    missingIds[inf.id] = true
  end

  for _, rp in ientitylist(Shared.GetEntitiesWithClassname('ResourcePoint')) do
    if rp.occupiedTeam ~= self.team and rp.occupiedTeam ~= self.enemyTeam then
      local id = rp:GetId()
      local info = unclRPs.lookup[id]
      if not info then
        info = { id = id }
        unclRPs.lookup[id] = info
        table.insert(unclRPs.arr, info)
      end
      missingIds[id] = nil
      info.hasInfestation = false
      info.willHaveInfestation = false
      local origin = rp:GetOrigin()
      local potentialInfesters = GetEntitiesWithMixinWithinRange('Infestation', origin, AlienCommUtils.maxInfestationRange)
      for _, infester in ipairs(potentialInfesters) do
        local infOrigin = infester:GetOrigin()
        if infester:GetIsPointOnInfestation(origin) then
          info.hasInfestation = true
          info.willHaveInfestation = true
          break
        end
      end

      if not info.hasInfestation then
        for _, infester in ipairs(potentialInfesters) do
          local curRadius = infester:GetCurrentInfestationRadiusCached()
          local maxRadius = infester:GetInfestationMaxRadius()
          if curRadius ~= maxRadius then
            if AlienCommUtils.IsInfesterCloseEnough(infester:GetOrigin(), maxRadius, origin, infester:GetCoords().yAxis) and
                (not infester:isa('Cyst') or infester:GetIsActuallyConnected()) then
              info.willHaveInfestation = true
              break
            end
          end
        end
      end
    end
  end

  for id, _ in pairs(missingIds) do
    local ind = false
    for i, inf in ipairs(unclRPs.arr) do
      if inf.id == id then
        ind = i
        break
      end
    end
    assert(ind)

    table.remove(unclRPs.arr, ind)
    unclRPs.lookup[id] = nil
  end
end

function AlienCommanderSenses:UpdateEnemies()
  if self.nextUpdateEnemies and self.time < self.nextUpdateEnemies then
    return
  end

  self.enemies = self.enemies or { fullArr = {}, byLocation = {}, byId = {} }
  self.nextUpdateEnemies = self.time + 0.9 * math.random(0.2)

  local missingIds = {}
  for _, info in ipairs(self.enemies.fullArr) do
    -- do this check now to avoid blowing up size of missingIds. We mostly
    -- prune structures and disconnected players using this
    if self.time > info.lastSeen + 30 then
      missingIds[info.id] = true
    end
  end

  for _, blip in ientitylist(Shared.GetEntitiesWithClassname('MapBlip')) do
    local ent = Shared.GetEntity(blip:GetOwnerEntityId())

    if HasMixin(ent, 'Team') and ent:GetTeamNumber() == self.enemyTeam and HasMixin(ent, 'LOS') and ent:GetIsSighted() then
      local id = ent:GetId()
      local info = self.enemies.byId[id]
      local loc = ent:GetOrigin()
      local locNm = UrgentGetLocationName(ent)

      if not info then
        info = { id = id }
        self.enemies.byLocation[locNm] = self.enemies.byLocation[locNm] or {}
        table.insert(self.enemies.fullArr, info)
        table.insert(self.enemies.byLocation[locNm], info)
        self.enemies.byId[id] = info
      end

      missingIds[id] = nil

      local success, blipType, _, _, _ = ent:GetMapBlipInfo()
      assert(success)

      info.blipType = blipType
      info.lastSeen = self.time
      info.location = loc

      if info.locationName and info.locationName ~= locNm then
        local ind = false
        for i = 1, #self.enemies.byLocation[info.locationName] do
          if self.enemies.byLocation[i].id == id then
            ind = i
            break
          end
        end
        assert(ind)
        table.remove(self.enemies.byLocation[info.locationName], ind)
      end

      info.locationName = locNm
      table.insert(self.enemies.byLocation[locNm], info)
    end
  end

  for id, _ in pairs(missingIds) do
    self:_RemoveEnemyById(id)
  end
end

function AlienCommanderSenses:_RemoveEnemyById(id)
  local info = self.enemies.byId[id]
  if not info then return end

  local ind = false
  for i = 1, #self.enemies.fullArr do
    if self.enemies.fullArr[i].id == id then
      ind = i
      break
    end
  end
  assert(ind)
  table.remove(self.enemies.fullArr, ind)

  ind = false
  for i = 1, #self.enemies.byLocation[info.locationName] do
    if self.enemies.byLocation[info.locationName][i].id == id then
      ind = i
      break
    end
  end
  assert(ind)
  table.remove(self.enemies.byLocation[info.locationName], ind)

  self.enemies.byId[id] = nil
end

function AlienCommanderSenses:OnEntityKilled(targetEnt, killer, doer, point, dir)
  if self.enemies then
    local id = targetEnt:GetId()
    if self.enemies.byId and self.enemies.byId[id] then
      self:_RemoveEnemyById(id)
    end
  end
end

function AlienCommanderSenses:UpdateEnemyMainBase()
  if self.nextUpdateEnemyMainBase and self.time < self.nextUpdateEnemyMainBase then
    return
  end

  self.nextUpdateEnemyMainBase = self.time + 15 + math.random() * 0.2

  local viableLocNms = {}
  for _, comm in ientitylist(Shared.GetEntitiesWithClassname('CommandStation')) do
    if comm:GetIsAlive() and comm:GetIsBuilt() then
      local locNm = UrgentGetLocationName(comm)
      if locNm == self.enemyMainBaseName then return end

      table.insert(viableLocNms, locNm)
    end
  end

  local ips = Shared.GetEntitiesWithClassname('InfantryPortal')
  local locsToCounts = {}
  for _, ip in ientitylist(ips) do
    local locNm = UrgentGetLocationName(ip)

    if not locsToCounts[locNm] then
      locsToCounts[locNm] = 0
    end

    locsToCounts[locNm] = locsToCounts[locNm] + 1
  end

  local bestLoc, bestLocIps = nil, nil
  for _, loc in ipairs(viableLocNms) do
    local num = locsToCounts[loc] or 0

    if not bestLoc or num > bestLocIps then
      bestLoc, bestLocIps = loc, num
    end
  end

  self.enemyMainBaseName = bestLoc or ''
end

-- hooks
if needSetupHooks then
  local function OnEntityKilled(targetEnt, killer, doer, point, dir)
    for senses, _ in pairs(gAlienSensesTable) do
      senses:OnEntityKilled(targetEnt, killer, doer, point, dir)
    end
  end

  local oldFunc = TeamDeathMessageMixin.OnEntityKilled
  function TeamDeathMessageMixin:OnEntityKilled(targetEnt, killer, doer, point, dir)
    oldFunc(self, targetEnt, killer, doer, point, dir)
    OnEntityKilled(targetEnt, killer, doer, point, dir)
  end
end
