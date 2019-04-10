# raylib-factor
bindings for the raylib library in Factor

# How to use it
I'm working on trying to get this library into the Factor "extra" libraries.  So hopefully soon,  simply by having Factor, you will have access to this library.

This repo is mostly so I can have an easier place to make changes without having to work on a fork of Factor itself.  Of course you can use the library right now if you want by dropping the raylib folder in your factor/extra folder.

# What it is

This are complete (one exception) bindings for the Raylib library (2.0).  It also includes raygui and rayicon support which will load automatically if the dll/so you are using has those modules compiled in.

The exception is that android related structs are not included because Factor doesn't run on it.

# How to program it

A small demo or two is included to help you get an idea of how to use it.  In reality the next step of this project will be adding utility functions to make  the experience more "Factor-y".  

All "functions" are named according to the Factorish style.  This means something like InitWindow in C becomes init-window in factor.  Every function is renamed this way with the exception of the raygui module which is the same except you have to prepend "rl-" to the function name.

Have fun!
