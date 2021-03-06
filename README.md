# Memory Game (soda)

This is a port of the [Mini Micro version](https://github.com/sebnozzi/minimicro-memorygame) to the [soda engine](https://github.com/JoeStrout/soda).

<img alt="Screenshot of the game" src="./soda-memory.png" width="50%" height="50%"/>

Some differences are:

* Cards are pre-rendered (instead of constructed in-game)
* When the game is over it is exited (instead of re-started)
* The needed `color` helper functions have been copied from [Mini Micro's `startup.ms`](https://github.com/JoeStrout/minimicro-sysdisk/blob/master/sys/startup.ms)

Otherwise most of the code could be directly re-utilized.
