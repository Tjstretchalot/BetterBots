class 'AlienCommanderSenses'


local maxInfestationRange = math.max(kInfestationRadius, kHiveInfestationRadius)

function AlienCommanderSenses:Initialize()
  self.state = kGameState.NotStarted
  self.team = kTeam2Index -- todo
  self.enemyTeam = GetEnemyTeamNumber(self.team)
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

-- End public functions

function AlienCommanderSenses:DoUpdate(player, gameInfo)
  PROFILE("AlienCommanderSenses:DoUpdate")
  self.gameTime = math.max(0, math.floor(self.time) - gameInfo:GetStartTime())

  self.resources = player:GetTeam():GetTeamResources()
  self:UpdateHarvesters()
  self:UpdateUnclaimedResourcePoints()
  self:UpdateEnemies()
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
    if not info.hasInfestation then -- technically you could remove this check since you might have infestation now but not in the future
      info.willHaveInfestation = false
      local nearbyInfesters = GetEntitiesWithMixinWithinRange('Infestation', maxInfestationRange)
      for _, infester in ipairs(nearbyInfesters) do
        local dist = (harv:GetOrigin() - infester:GetOrigin()):GetLength()
        if dist < infester:GetInfestationMaxRadius() then
          if not infester:isa('Cyst') or infester:GetIsActuallyConnected() then
            info.willHaveInfestation = true
            break
          end
        end
      end
    else
      info.willHaveInfestation = true
    end
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
      for _, infester in ipairs(GetEntitiesWithMixinWithinRange('Infestation', origin, maxInfestationRange)) do
        local dist = (origin - infester:GetOrigin()):GetLength()
        if dist < infester:GetCurrentInfestationRadiusCached() then
          info.hasInfestation = true
          info.willHaveInfestation = true
          break
        end

        if not info.willHaveInfestation then
          if dist < infester:GetInfestationMaxRadius() then
            if not infester:isa('Cyst') or infester:GetIsActuallyConnected() then
              info.willHaveInfestation = true
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
    if self.time > info.lastSeen + 5 then -- do this check now to avoid blowing up size of missingIds
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
    local info = self.enemies.byId[id]
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
end
