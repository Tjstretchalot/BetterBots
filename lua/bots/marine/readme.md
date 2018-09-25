# Strategy

Strategy is the long-term technique for winning the game.

Marine bots must balance the defensive, offensive, and strategic requirements
of the team. All marine strategies require coordination to be effective, so
a major goal of marine bots is to segment player behavior into one of these
strategies.

Marine bots will strongly prefer to use strategies that other players are
already performing, producing inertia. In a match with few bots, this will
cause them to follow the team. In a match with many bots, this will produce
coordination, since as soon as one or two bots switch to a more effective
strategy the rest of the bots will quickly agree and use that strategy as well.

Bots will weight strategies that other players have recently switched to much
more highly than ones they've been using a while, to prevent getting stuck
in a split between strategies. Similarly, they will prefer to stick to strategies
they've recently switched to, preventing indecision.


## Resource Control

Build extractors while denying harvesters.

Key behavior:
- Welding, building, or defending extractors.
- Shooting harvesters or cysts near harvesters


## Laning

Deny key routes or locations to aliens.

Key behavior:
- Little true map movement.

## Assault

Clear out an enemy location.

Key behavior:
- Purchasing a grenade launcher
- Proximity to other marines

# Tactics

Tactics is how and who should perform a strategy. The main consideration here
is weapon and location selection.

Given a strategy, this is the "what should I get and where should I go?"


## Shared Tactics

Some tactics are common and can be dropped into more complex tactics.

### Welding

- If we have a welder and a marine needs welding, weld them
- If we need welding and we have a welder and we have nearby marines but none have a welder, drop your welder and use the "Weld target at waypoint" voiceline
- If there is a welder on the ground and we don't have a welder and either someone else has a welder or we don't need welding, pick it up

### Med and ammo requests

- If we haven't asked for a med pack recently, ask for one if any of the following are true:
  - We just got hurt and have less than 90 health
  - We have less than 76 health and 4 or more extractors
  - We have less than 25 health and we are not in an active conflict and we are not near an armory
- If we haven't asked for ammo recently, ask for one if:
  - We have a rifle and have one or fewer complete reloads left
  - We have a shotgun but 3 or fewer bullets left for reloading
  - We have a heavy machine gun but one or fewer complete reloads left
  - We have a grenade launcher but 6 or fewer bullets left for reloading
  - We have a flamethrower but one or fewer complete reloads left

## Resource Control

Heavy weaponry is counterproductive for this strategy, so a **Rifle** is the
tool for the job. Marines should stay in groups of 2 or 3 at most. A single
welder is required per group which can be passed around.

This tactic is broken into the following categories, in increasing preference:
*Pooling*, *Defense*, *Acquisition*, and *Assault*.

### Assault

This tactic aims to kill an enemy harvester.

We enter this state if **any** of the following are true:

- We are near at least one other marine and we are at the edge of marine-control
- We are in enemy-controlled territory
- We are in uncontrolled territory which is not adjacent to marine-controlled
territory.

This tactic is performed by:

- *Shared*: Med and ammo requests
- If we can shoot and kill a harvester with our current clip, always do that.
- If in sight, shoot aggressors (skulks, lerks, fades, onos, gorge, whips, hydras)
- If in the location, shoot tunnels
- *Shared*: Welding
- If we are in a room with a harvester:  
    - If we have at least 4 extractors or conflict effectiveness in this location is below 40%, shoot it.
    - Otherwise, axe or weld the harvester.
- Choose a harvester and go to it until one of the above are true. Locations are preferred in the following:
    - Reachable without going through alien-controlled locations
    - Lower conflict frequency
    - Higher conflict effectiveness
    - Lower conflict duration

### Acquisition

This tactic aims to build an extractor.

To enter this state we must select a resource point to acquire. Valid points
are:

- Victory streak
  - Conflict streak >= 2
  - Conflict effectiveness >= 45%
- Easily defended
  - Conflict effectiveness >= 70%
- Untouched
  - Time since conflict >= 2 minutes
- Back res
  - Adjacent to marine territory but not alien territory

And **all** of the following are true.

- We can't select Assault
- We are near at least one other marine


This tactic is performed by:

- *Shared*: Med and ammo requests
- If in sight or location, shoot aggressors
- If in the location, shoot tunnels
- If in the location, shoot alien structures and cysts
- *Shared*: Welding
- If in the location, build unbuilt structures
- If in the location and we have a welder, weld hurt structures
- If we're in the target location and the extractor isn't placed
   - If we have enough tres to drop it and haven't asked for order yet, ask for order
   - Idle
- If we're not in the target location, move toward the target location

### Defense

This tactic aims to defend existing structures.

To enter this state we must select a location to defend. Valid points (in decreasing
order of preference), are:

- Critical structure under attack
  - Things like power nodes for infantry portals, infantry portals, arms lab, command chair (when only 1), advanced armory
  - Prefer defending more alien favored
- Phase gates under attack with no marines nearby
- Phase gates under attack with an active conflict which is slightly marine favored or worse
  - Prefer more marine favored
- Phase gates with no marines nearby
- Injured structures with no marines nearby

**All** of the following must be true:

- Cannot select Assault or Acquisition

This tactic is performed by:

- *Shared*: Med and ammo requests
- If in sight or location, shoot aggressors
- *Shared*: Welding
- If in the location and necessary, weld existing structures
- If in the location, build unbuilt structures
- If we're in the target location and it is still a viable defense target:
  - Idle
- If not in the target location, move to it.

### Pooling

This tactic aims to set up the conditions required for assault or acquisition.

We enter this state only if no other state fits.

This tactic is performed by:

- *Shard*: Med and ammo requests
- If in sight or location, shoot aggressors
- *Shared* Welding
- If we're in a location at the edge of marine control, idle
- If there exists a lone marine at the edge of marine control, go to him
- Select a random location at the edge of marine control and go there
