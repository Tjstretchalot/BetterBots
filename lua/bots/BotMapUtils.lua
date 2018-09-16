--- Some map information that can be calculated and stored. It is calculated
-- only once per map

-- Contains [location name] => {
--   adjacent = { string,... },
--   adjacentLookup = { string = true,... },
--   powerPointId = number or Entity.invalidId,
--   checked = boolean
-- }

local mapAdjacencyCache

local function WalkPathToFindFirstChange(startLocNm, points)
  for i=1, #points do
    local pt = points[i]
    local loc = GetLocationForPoint(pt)
    if loc then
      local locNm = loc:GetName()

      if locNm ~= startLocNm then return locNm end
    end 
  end

  return nil
end

function UrgentGetLocationName(entity)
  local locNm = entity:GetLocationName()
  if locNm ~= nil and locNm ~= '' then return locNm end

  local loc = GetLocationForPoint(entity:GetOrigin())
  assert(loc ~= nil)
  locNm = loc:GetName()
  assert(locNm ~= '')
  return locNm
end

local function LoadAdjacencyForLocationPowerpoint(powerPoint, allPowerPointsEList, powerPointLocNamesToPowerPoints)
  assert(mapAdjacencyCache)

  local startLoc = UrgentGetLocationName(powerPoint)

  mapAdjacencyCache[startLoc] = mapAdjacencyCache[startLoc] or {
    adjacent = {},
    adjacentLookup = {},
    powerPointId = powerPoint:GetId(),
    checked = true
  }

  local cache = mapAdjacencyCache[startLoc]
  cache.checked = true

  local startPoint = Pathing.GetClosestPoint(powerPoint:GetOrigin())
  for _, otherPowerPoint in ientitylist(allPowerPointsEList) do
    local endLoc = UrgentGetLocationName(otherPowerPoint)
    local endLocCache = mapAdjacencyCache[endLoc]
    if (not endLocCache or not endLocCache.checked) and not cache.adjacentLookup[endLoc] then
      local endPoint = Pathing.GetClosestPoint(otherPowerPoint:GetOrigin())

      local points = PointArray()
      local reachable = Pathing.GetPathPoints(startPoint, endPoint, points)
      if not reachable then
        Log('[BotMapUtils] Ahh! Cannot go from %s to %s ??', startLoc, endLoc)
      else
        local firstWalkThroughLoc = WalkPathToFindFirstChange(startLoc, points)
        if not firstWalkThroughLoc then
          Log('[BotMapUtils] Ahh! Path from %s to %s went through NO LOCATIONS except %s?', startLoc)
        else
          assert(firstWalkThroughLoc ~= '')
          mapAdjacencyCache[firstWalkThroughLoc] = mapAdjacencyCache[firstWalkThroughLoc] or {
            adjacent = {},
            adjacentLookup = {},
            powerPointId = powerPointLocNamesToPowerPoints[firstWalkThroughLoc]:GetId(),
            checked = false
          }
          local foundLocCache = mapAdjacencyCache[firstWalkThroughLoc]

          if not cache.adjacentLookup[firstWalkThroughLoc] then
            table.insert(cache.adjacent, firstWalkThroughLoc)
            cache.adjacentLookup[firstWalkThroughLoc] = true
            table.insert(foundLocCache.adjacent, startLoc)
            foundLocCache.adjacentLookup[startLoc] = true
          end
        end
      end
    end
  end
end

local function LoadAdjacencyMap()
  PROFILE("LoadAdjacencyMap")
  assert(not mapAdjacencyCache)
  Log('Loading adjacency info...')
  mapAdjacencyCache = {}

  local powerPointsEList = Shared.GetEntitiesWithClassname('PowerPoint')
  local powerPointsLookup = {}
  for _, pp in ientitylist(powerPointsEList) do
    local ppLocNm = UrgentGetLocationName(pp)
    powerPointsLookup[ppLocNm] = pp
  end

  for _, pp in ientitylist(powerPointsEList) do
    LoadAdjacencyForLocationPowerpoint(pp, powerPointsEList, powerPointsLookup)
  end
  Log('Finished loading adjacency info')
end

local function OnMapPostLoadComplete()
  -- Kind of hacky. This is the same hook that Server uses for initializing
  -- pathfinding, so we may be before or after it (I think arbitrarily)

  if gPathingInitialized then
    LoadAdjacencyMap()
  else
    local oldInitPathing = InitializePathing
    InitializePathing = function()
      oldInitPathing()
      LoadAdjacencyMap()
    end
  end
end

function GetAdjacentTo(locationName)
  assert(mapAdjacencyCache ~= nil)

  local cache = mapAdjacencyCache[locationName]
  assert(cache ~= nil)
  assert(cache.adjacent ~= nil)
  assert(cache.checked)

  return cache.adjacent
end

function CacheGetPowerPointForLocation(locationName)
  assert(mapAdjacencyCache ~= nil)

  local cache = mapAdjacencyCache[locationName]
  assert(cache ~= nil)
  assert(cache.checked)

  local powerPoint = Shared.GetEntity(cache.powerPointId)
  if powerPoint == nil then
    powerPoint = GetPowerPointForLocation(locationName)
    assert(powerPoint ~= nil)
    cache.powerPointId = powerPoint:GetId()
  end

  return powerPoint
end

Event.Hook('MapPostLoad', OnMapPostLoadComplete)
