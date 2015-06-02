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


## Running the sample application

To run Trivial Quest on your own device, you will need to create
your own version of the game in the [Play Console](https://play.google.com/apps/publish) and copy over some information to
your Xcode project. To follow this process, perform the following steps:

1. In a terminal window, change directories to the <TrivialQuest2> directory that contains the Podfile 
and add the cocoapod project to the workspace.  To do this run `pod update`.
2. Open the TrivialQuest2 workspace: `open TrivialQuest2.xcworkspace`.
3. Open up the project settings. Select the "TrivialQuest2" target and,
  on the "Summary" tab, change the Bundle Identifier from `com.example.trivalquest2` to
  something appropriate for your Provisioning Profile. (It will probably look like
  `com.<your_company>.trivalquest`)
4. Click the "Info" tab and go down to the bottom where you see "URL Types". Expand
  this and change the "Identifier" and "URL Schemes" from `com.example.trivalquest` to
  the name you used in Step 1.
5. Create your own application in the Play Console, as described in our [Developer
  Documentation](https://developers.google.com/games/services/console/enabling). Make
  sure you follow the "iOS" instructions for creating your client ID and linking
  your application.
    * If you have already created an application (because you tested the Android version,
  for instance), you can use that application, and just add a new linked iOS client to the same
  application.
    * Again, you will be using the Bundle ID that you created in Step 1.
    * You can leave your App Store ID blank for testing purposes.
7. Copy your iOS application's OAuth 2.0 client ID from step 4 and paste it
  into `Constants.h` file by replacing the example value with your own.
8. Also copy the event IDs into Constants.h
