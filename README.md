Google Play game services - iOS Samples
=======================================
Copyright (C) 2014 Google Inc.

This project contains sample applications that demonstrate basic use cases for
Google Play Game Services.

* **Type-a-Number Challenge**: Demonstrates sign-in, leaderboards, achievements,
creating Interactive Posts to brag about one's score, showing a list of people in the
user's circles, and making calls to the  Management API to reset scores or achievements.
* **Collect All the Stars**: Demonstrates sign-in and cloud save.
* **Button-Clicker 2000**: Demonstrates real-time multiplayer using invites or quickmatch
* **TBMP Skeleton**: Demonstrates asynchronous turn-based multiplayer using invites or quickmatch
* **TrivialQuest2**: Demonstrates Events and Quests

The shared `Libraries` folder contains the frameworks and bundles required to
run these applications. Each application contains references to this folder
instead of containing separate frameworks and bundles for each project. Before
you build the samples, download the Google Play Games Services SDK and the
Google+ iOS SDK from the [Google Play Games Services downloads page](https://developers.google.com/games/services/downloads/).
and unzip the files into the **Libraries** folder of your samples directory.

**Note:** These samples are compatible with their corresponding applications in
the Android samples. This means that you can play some levels on Collect All the Stars
on your iOS device, and then pick up your Android device and continue where you left
off! For Type-a-Number, you will see your achievements and leaderboards on all
platforms, and progress obtained on one will be reflected on the others.

## Running the sample apps

Please refer to the `README` file contained within each individual application's
folder for detailed instructions on how to run these sample applications, along
with a better explanation of what all of the classes do.
