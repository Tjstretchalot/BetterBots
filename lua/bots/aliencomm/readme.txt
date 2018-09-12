The alien commander selects one of predefined strategies (which are really
just behavior trees). However, it's important that the alien commander can
substitute for a player if a player started the game. Furthermore, how a game
is going might affect if a strategy is still viable or not, and strategies that
were previously not viable may become viable as time goes on.

When first joining and periodically thereafter, the alien commander will
loop through the available strategies and ask them if they are viable. Then
it will select the strategy with the highest "StrategyScore" value. It breaks
ties randomly, preferring to maintain the current strategy over swapping to
an equally viable strategy.

Strategies are implemented as behavior trees of their own.

---

In order to avoid redoing expensive operations and to improve integration
amongst the strategies, they all share access to an instance of
AlienCommanderSenses which is updated by the main tree at the start of
every tick.

---

Strategy tree contexts are not shared. They are passed:
  bot
  move 
  senses (AlienCommanderSenses)
