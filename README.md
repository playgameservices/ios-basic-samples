Google Play game services - iOS Samples
=======================================
Copyright (C) 2014 Google Inc.

This project contains two sample applications that demonstrate some basic uses of 
Google Play game services. 

* **Type-a-Number Challenge**. Demonstrates sign-in, leaderboards, achievements, 
creating Interactive Posts to brag about one's score, showing a list people in the
user's circles, and making calls to the  Management API to reset scores or achievements.
* **Collect All the Stars 2**. Demonstrates sign-in and snapshot API.
* **Button-Clicker 2000**. Demonstrates real-time multiplayer using invites or quickmatch
* **TrivialQuest2**. Demonstrates how to use the Events and Quests features of Google Play Services. The sample presents a sign in button and four buttons to simulate killing monsters in-game. When you click the buttons, an event is
created and sent to Google Play Games to track what the player is doing in game.
* **TBMP Skeleton**. Demonstrates asynchronous turn-based multiplayer using invites or quickmatch

In addition, there is a shared `Libraries` folder that contains all of the 
frameworks and bundles required to run these applications. Each application 
contains references to this folder instead of containing separate frameworks 
and bundles for each project.


**Note:** These samples are compatible with their corresponding applications in 
the Android samples. This means that you can play some levels on Collect All the Stars 
on your iOS device, and then pick up your Android device and continue where you left 
off! For Type-a-Number, you will see your achievements and leaderboards on all 
platforms, and progress obtained on one will be reflected on the others.

## Running the sample apps

1. Please download Google+ iOS SDK & Google Play Games SDK from links in:
  https://developers.google.com/games/services/downloads/
  And put them into Libraries/ directory
1. Please refer to the `README` file contained within each individual application's 
folder for detailed instructions on how to run these sample applications, along
with a better explanation of what all of the classes do.
