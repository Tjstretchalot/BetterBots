# Senses

The map is the most important part for tactical decisions.

## Conflicts

Most values in this section refer to a specific location.

A member of a conflict is a player who receives damage or deals damage to a
different player, or heals a ally. A member is removed from a conflict when
he does not take, deal, or heal damage for 5 seconds. If a conflict is ongoing
in a location and uninvolved members get into a conflict that is in that
location, the conflicts are merged. In other words, there is at most one
conflict per location.

A conflict ends when there are no members in it. If both or neither side has
members alive, the conflict is a draw. Otherwise, the conflict is won by the
side with live members.

The following are instantaneous values that are not filtered:

### Get ongoing conflict locations

Get a list of all locations with ongoing conflicts

### Conflict favorability

Get the favorability of a conflict in a given location. Conflict favorability is
a signed real number. A negative sign implies alien favored, a positive sign
implies marine favored, and the magnitude implies how strongly favored the
conflict is.

A conflict with a magnitude less than 1 is evenly matched, less than 2 is
slightly favored, less than 3 is favored, and 3 or more is highly favored.

Members of a conflict are the only thing that determine conflict favorability.
It is calculated as the sum of the following:

- Each marine is given 1 point
  - Add 1/3 for every 75 effective health above 125
  - Add 1/5 for every weapons upgrade (3/5 for weapons 3)
  - Add 1/2 for a jetpack
  - Add 1/3 for a shotgun
  - Add 1/4 for a flamethrower
  - Subtract 1/2 for a grenade launcher
  - Add 1/10 for every other marine
- Each exo is given 2 points
  - Add 1/5 for every weapons upgrade
  - Add 1/3 for every armor upgrade
  - Add 1/5 for every other marine
- Each skulk is given 1 point
  - Add 1/5 for every other skulk
- Each gorge is given no points
  - Add 1 if there is an onos
  - Add 1/10 for every other non-onos lifeform
- Each lerk is given 1.5 points
- Each fade is given 3.5 points
  - Add 1 for every other fade
- Each onos is given 3.5 points
  - Add 1/2 for every other non-gorge lifeform

Example encounters:

- Jetpack shotgun, Weps 2, Arm 2 vs Lerk: 0.73 (evenly matched)
- 3 Rifles, Weps 3, Arm 2 vs Onos and Gorge: 1.89 (slightly marine favored)
- 3 Rifles, Weps 3, Arm 2 vs Onos, Fade, Gorge: -2.11 (alien favored)
- 2 Rifles, Weps 2, Arm 2 vs 3 Skulks: -0.54 (evenly matched)
- 6 Rifles, Weps 3, Arm 3 vs 6 Skulks: 2.58 (marine favored)
- 1 Jetpack Rifle, 1 Exo, Weps 3, Arm 3 vs 2 Fades and a Lerk: -4.44 (highly alien favored)

### Time since conflict

The time since a conflict occurred in this location.

### Conflict streak

The number of conflicts in a row we've won (positive number) or lost (negative
number). So a streak of 3 means we've won the last 3 conflicts here. A streak of
-5 means we've lost the last 5 conflicts here.

Example table:


| Victor | Streak |
|--------|-------:|
| Marines| 1      |
| Marines| 2      |
| Aliens | -1     |
| Aliens | -2     |
| Aliens | -3     |
| Marines| 1      |
| Aliens | -1     |


---

The following statistics are analyzed by moving average filters with a window around
5 minutes.

### Conflict Frequency

The number of conflicts per minute in this location.

### Conflict Size

The number of members for conflicts in this location. This is really three
different values - number of marines in conflicts, number of aliens in
conflicts, and the sum.

### Conflict Duration

The duration of conflicts in this location.

### Conflict Effectiveness

The percentage of conflicts won by the marines, expressed as a real number from
0 to 1 (inclusive).

## Control

Controlled territory is defined simply as who has structures in a location. Cysts
are not included in control. A location with only marine structures is marine
controlled. A location with only alien structures is alien controlled. A location
with neither or both is uncontrolled.

## Equipment

It's often important to keep track of who has equipped what. This will let you
count:

- Number of marines with welders
- Number of marines with a given primary weapon
- Number of exos
- Number of jetpacks

And, to the best of our knowledge:

- Number of the various enemy lifeforms
