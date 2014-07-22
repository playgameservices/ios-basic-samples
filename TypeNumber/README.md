# Type-a-Number Challenge

A sample application that demonstrates some simple achievements (normal, hidden,
and incremental), and leaderboards. It also demonstrates some basic G+ Platform
functionality, such as sending and receiving Interactive Posts with
Deep-Linking, and showing a list of the player's friends.

## Code

The Type-a-Number Challenge consists of a number of files that might be of interest to you:

* `AchievementManager` is in charge of telling the game service that a user has
performed whatever actions are necessary to unlock or make progress towards a
particular achievement.

* `AdminViewController` contains a few buttons that make calls to the v1Management
APIs. These allow you to reset leaderboards and achievements. Please note that even
if your game has been published, these calls can only be made by accounts on the official
Tester list.

* `AppDelegate` contains some of the code required to handle deep links (i.e.
challenges).

* `Constants.h` contains (nearly) all the constants that you will need to run
this game on your own.

* `GameModel` is the game's model. It supplies information to the
  AchievementManager and the LeaderboardManager at the appropriate moments

* `GameViewController` is the ViewController for the game itself. This
  ViewController also displays the `GPGLeaderboardController`, which displays a
  leaderboard appropriate to your game mode. It also displays challenge
  information, when appropriate.

* `InitViewController` is the main ViewConroller for the "welcome screen". You
  can see that calls made to display the GPGAchievementsController and the
  GPGLeaderboardsController are located here

* `LeaderboardManager` is in charge of telling the game service that a user has
  earned a score towards a particular leaderboard

* `MainStoryboard_iPhone|iPad.storyboard` are the main storyboards used by the
  application. I know I should probably be using a SplitViewController for the
  tablet.

* `PeopleListTVC` displays a list of the first 20 people in the players'
  circles.


## Running the sample application

To run the Type-a-Number Challenge on your own device, you will need to create
your own version of the game in the Play Console. Once you have done that,
you will create achievements and leaderboards for this game, then copy over
all client IDs, achievement IDs and leaderboard IDs to your own
`Constants.h` file. To follow this process, perform the following steps:

1. Open up your TypeNumber project settings. Select the "TypeNumber" target and,
  on the "Summary" tab, change the Bundle Identifier from `com.example.TypeNumber` to
  something appropriate for your Provisioning Profile. (It will probably look like
  `com.<your_company>.TypeNumber`)
    * If you plan on only running this on an emulator, you can leave it as-is.
2. Click the "Info" tab and go down to the bottom where you see "URL Types". Expand
  this and change the "Identifier" and "URL Schemes" from `com.example.TypeNumber` to
  whatever you used in Step 1.
3. If you have already created this application in the Play Console (because you
  have created the Android or web version of the game, for example), you can
  skip steps 4 through 7 below. All you will need to do is...
    * Link the iOS version of your game, as described in the "Link Your Platform-
      Specific Apps" section of the console documentation
    * Create a separate client ID for the iOS version of the game, as described in
      the "Create a client ID" section of the [Console Documentation](https://developers.google.com/games/services/console/enabling).
        * Use the Bundle ID that you created in Step 1.
4. Create your own application in the Play Console, as described in our [Developer
  Documentation](https://developers.google.com/games/services/console/enabling). Make
  sure you follow the "iOS" instructions for creating your client ID and linking
  your application.
    * Again, you will be using the Bundle ID that you created in Step 1.
    * You can leave the App Store ID blank for testing purposes.
5. Make a note of your client ID and application ID as described in the
  documentation
6. Create your own Achievements and Leaderboards as described in the
  [Achievements](https://developers.google.com/games/services/common/concepts/achievements)
  and [Leaderbords](https://developers.google.com/games/services/common/concepts/leaderboards)
  documentation. You are free to create your own Achievements and Leaderboards,
  but if you want to match the ones in this sample application, they are...
    * Achievements:
        * Prime: Receive a score that is a prime number
        * Bored: Play 10 games (Incremental achievement)
        * Humble: Request a score of 0
        * Don't Get Cocky, Kid: Request a score of 9999
        * OMG U R TEH UBER LEET!: Receive a score of 1337 (hidden achievement)
        * Really Bored: Play 100 games (Incremental achievement)
    * Leaderboards:
        * Hard mode
        * Easy mode
7. Feel free to use any score value for your achievements (we tended to keep
  them between 10 and 75 points per achievement). If you want placeholder icons,
  <http://lorempixel.com> is a great resource.
8. Once that's done, you'll want to replace some of the constants defined in the
  application.
    * In the `Constants.h` file, replace the following constant with your OAuth2.0
      client ID:
        * `CLIENT_ID`
    * In the same `constants.js` file, replace the following constants with the
      IDs for the corresponding achievements that you created:
        * `ACH_PRIME`
        * `ACH_BORED`
        * `ACH_HUMBLE`
        * `ACH_COCKY`
        * `ACH_LEET`
        * `ACH_REALLY_BORED`
    * Finally, replace the following constants with the IDs for the
      corresponding leaderboards that you created:
        * `LEAD_EASY`
        * `LEAD_HARD`
9. Go to your TypeNumber-info.plist file and replace the `GPGApplication` value with
  the actual Applicaton ID of your game.

That's it! Your application should be ready to run! 

## Known issues

* Performance in the PeopleListTVC seems rather poor. I think it's something I'm
  doing wrong with loading the players' images.
* iPad version isn't really designed for tablets. 
* My art skills have much room for improvement. :)
