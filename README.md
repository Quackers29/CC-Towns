# CC-Towns
![2023-10-11_19 57 38](https://github.com/Quackers29/CC-Towns/assets/11053436/10cdbb2f-fdda-4f29-a7a4-6d07c8116f14)

# Current State
  ### Upgrades: Completed
  List all upgrades, can set Possible upgrades per town type, can set default Base upgrades per town,
  Each Possible upgrade is listed in the Upgrades page, each can be selected to its own Display page,
  Display pages show requirements of the upgrade and list the resource Cost and Prerequisites.
  Display shows if each item is fulfilled and allows the upgrade to be made. The Duration sets the time in seconds to complete the upgrade.
  
![2023-10-11_19 57 47](https://github.com/Quackers29/CC-Towns/assets/11053436/b2893b65-7fda-4a2b-bc7b-bdf9ee95a086)

![2023-10-11_19 57 58](https://github.com/Quackers29/CC-Towns/assets/11053436/daea7423-d0cf-433d-a174-69ab5b4949c8)

![2023-10-11_19 58 42](https://github.com/Quackers29/CC-Towns/assets/11053436/cef4b9c9-e137-48b4-9a01-58a5632feb06)
  
  ### Resources: Completed
  Lists town resources, Pull in entire chest worth of resources into the town at a time, Output a stack of resources until resource depleted.
  A - Auto, inputs all and outputs selected items once a second 
  
![2023-10-11_19 59 18](https://github.com/Quackers29/CC-Towns/assets/11053436/b423425e-9673-4e9b-8cc5-58d5bea5bf74)

![2023-10-11_20 00 27](https://github.com/Quackers29/CC-Towns/assets/11053436/aa749481-3984-4151-8a08-3c0a7168f2f0)

![2023-10-11_20 01 16](https://github.com/Quackers29/CC-Towns/assets/11053436/1defc039-2001-420e-a595-b782ed4b472d)

  ### Production: Compelted
  Like Upgrades, lists all production available, can select each to a Display page, 
  Display page shows amount produced, the duration taken to make the items and the lists the resource Cost and Prerequisites.
  Once toggled on from the Display screen, outputs items until the costs run out of the max capacity is reached.

![2023-10-14_08 03 11](https://github.com/Quackers29/CC-Towns/assets/11053436/bd273309-e8aa-4f32-a724-fe69c840bd2c)

  
  ### Misc: Completed
  Randomly selected town name, town biome search (to weigh town type probability), Auto scaling of Monitor (2x3 min)
  
![2023-10-11_20 30 47](https://github.com/Quackers29/CC-Towns/assets/11053436/8b2deb60-fbae-4249-9b1e-10cf7921101d)

  ### Map 
  Rudimentary map of towns location compared to surrounding towns, can zoom in and out.
  ![2023-10-20_00 01 42](https://github.com/Quackers29/CC-Towns/assets/11053436/efccdf09-ec5f-4ad9-98a2-304cce846bfe)

  ### Villagers Import/Export
  Currently can Import/Export "Town" Villagers, summons with a visable name based on the town, kills and records name (of origin town)
  Plan to move population around towns for increased productivity / money
  ![2023-10-20_00 02 37](https://github.com/Quackers29/CC-Towns/assets/11053436/6d087930-78ba-4e55-b544-927ed80f0f59)


# Plans
  ### Production
  List of a productions, town specific production, the resources required, amount produced, rate of production and required upgrades
  ### Trade
  List of trade items from town to player between the accessible Resources and an internal list of Town Resources.
  ### Contracts
  List of all contracts possible, town randomly selects contracts to other nearby towns, generates town trade points for the town as requirements for future upgrades
  ### Stats
  Statistics of the town, trades completed, points earned, population etc
  ### Settings
  Generic settings for the town, town name etc and possibly Company takeover - Player pays to capture the town under a team name.
  
  ### Misc
  Slow auto trading of each town to surrounding towns, slow development of towns over time.


  # Installation instructions

  Server settings: command block use to true, command block output to false
  
  Place down a command computer, only accessable through /give command
  
  On the command computer, edit a file and save it so it creates a folder
  
  In this new folder locate the github repo clone
  
  Add a chest to the West side of the computer and another two blocks higher
  
  Add a monitor to the setup
  
  Restart the computer
  
  Duplicate this computer with the same id to create more towns.


