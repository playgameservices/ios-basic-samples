# Trivia Quest 2 - iOS README
=======================================
Copyright (C) 2014 Google Inc.

A sample application that demonstrates the use of the Events 
and Quests features of the Google Play Games services. This 
iOS application is cross-platform compatible with the 
Android version of this sample.

## Overview

The *Trivial Quest 2* sample is a simple game that presents a 
sign-in button and four buttons to simulate killing monsters 
in-game. When players click the buttons, an event is created 
and sent to the Google Play Games services to track what 
players are doing in the game.

During gameplay, when players achieve milestones specified in 
the Quest's definition, the game receives a callback with an 
object describing the Quest reward.

## Key sample files

The following files in *Trivial Quest 2* contains sample code that 
might be of interest to developers:

* `AppDelegate` contains some basic code required to handle sign-in 
  (mainly the URL handler).

* `Constants` contains the game's client ID.

* `ViewController` contains most of the logic for signing the user in, 
   submitting events, displaying the Quests list user interface, and 
   hiding and showing various buttons.

