# CommunityDKP

This is the development repository for CommunityDKP and may not necessarily reflect current releases on Curse or WoWI. It may also create compatibility issues with those that have older versiond depending on the features added. Back up your saved variables file prior to attempting to use to prevent any possible data loss.

CommunityDKP is the leading DKP Management Tool supporting a number of different loot rules including ZeroSum, Roll-Based Bidding, Minimum Value Bidding, and Statis Value Bidding. Any suggestions or requests are also welcome!  

CommunityDKP Discord Server: https://discord.gg/dXXK4vH
  
**General Features Include:**

   - Multi-Guild, Multi-Team DKP Tables allowing for management of multiple different types of DKP Tables.
   - DKP Table entries provide a tooltip showing the players recently spent and earned DKP  
   - Filter the DKP table by certain classes or show only those in your party/raid. Table columns can also be sorted by Player, Class or DKP
   - Loot History. What item was won, by whom, from what boss/zone, and how much they spent on it and can be filtered by player or item
   - DKP History. Comprehensive list of all players that received (or lost) dkp for each event.
   - Loot Pricing. Shows pricing on loot (a static price or last bid) as well as counts the number of times an item has been disenchanted.
   - Disenchant Functionality. It provides a button to track disenchants off the Bid Window.
   - Bid Timer displaying what is currently up for bid as well as the minimum bid price.
   - Raid Timer. Allowing for automatic distribution of DKP points over a set interval of time as the raid progresses.
 
**Officer Only Features:**
   - Bid window (opened by SHIFT+ALT clicking an item in the loot window or by typing /dkp bid [item link]) that starts bidding, collects all bids submitted and awards the item. NOTE: Shift+Alt clicking an item only works if the item is in one of the first 4 slots of the loot window due to restrictions at the moment. If the item you wish to bid on isn't on the first page, either loot all items on that first page, close, and reopen the window. Or simply use /dkp bid [item link] .
   - Adjust DKP tab (awarding DKP). Also includes a DKP Decay option that reduces all entries by X% (default set in options or change on the fly in the Adjust DKP tab)   
   - Award Item Window (awards an item to a play, but also allows an officer to set the min price on an item)
   - Manage Tab. Used to broadcast complete tables to everyone in the guild if required as well as add/remove player entries.  
   - Shift+Click entries in the table to select multiple players to modify.  
   - Right click context menu in Loot History to reassign items (if minds are changed after awarding) which will subsequently give the DKP cost back to the initial owner and charge it to the new recipient  
   - Boss Kill Bonus auto selects the last killed boss/zone  
   - Options window has additional fields to set bonus defaults (On time bonus, boss kill bonus etc)
 
**Guild Leader Only Features:**
   - Whitelist Settings: Setting an Officer Whitelist to specific people instead of all guild officers to manage DKP.
   - Team Management: Ability to create and rename teams that officers can then manage DKP for.
 
CommunityDKP is a community-driven collaboration born from the original MonolithDKP. It has also been completely overhauled and changed to support multiple teams, guilds, characters, and accounts. 
Forked from: https://www.curseforge.com/wow/addons/monolith-dkp

# Installation Notes
**To Upgrade from MonolithDKP 2.1.2 or higher AUTOMATICALLY:**
 - Follow prompts for migrating MonolithDKP settings to CommunityDKP
 - Once done, unload MonolithDKP.
 
## Multiple Team Import
**To Upgrade additional MonolithDKP 2.1.2 Saved Variable LUA as a Second Team**
 - Ensure you are an Officer of the Guild (can write to officer notes)
 - Follow instructions above for the first table, which will be come Team #1.
 - Make sure CommunityDKP has successfully imported your first team by running it at least once while having MonolithDKP disabled (CommunityDKP has to upgrade your DKP table schema after the initial import)
 - Exit WoW, install second MonolithDKP.lua Saved Variables (for second table)
 - Start WoW, re-enable MonolithDKP
 - Community will prompt if you want to import the table found as a Second Team.
 - Choose wisely, if confirmed, second team will be created.
 - Lather, Rinse, Repeat for additional teams.
 - Disabled MonolithDKP once done.
 - Sync all team tables to Guild (including all officers/whitelist and GM)
 - Once all tables are synced, Guild Master should rename teams as needed and perform another Guild Sync.

**To Upgrade from MonolithDKP 2.1.2 or higher MANUALLY:**
   - Copy WTF\Account\<account>\SavedVariables\MonolithDKP.lua -> WTF\Account\<account>\SavedVariables\CommunityDKP.lua
   - Open up CommunityDKP.lua and rename all instances of "MonDKP" -> "CommDKP"
   - Save and start WoW
   - Unload/Remove MonolithDKP addon
   - Login and it should work as expected.
  
## Commands  
	/dkp ?  	- Lists all available commands  
	/dkp 		- Opens Main GUI  
	/dkp timer	- Starts a raid timer (Officers Only) IE: /dkp timer 120 Pizza Break!  
	/dkp reset 	- Resets GUI position  
	/dkp export - Exports all entries to HTML (To avoid crashing this will only export the most recent 200 loot history items and 200 DKP history items)  
	/dkp bid 	- Opens Bid Window. If you include an item link (/dkp bid [item link]) it will include that item for bid information.  
  
## Recommendations  
	- Due to the volatile nature of WoW Addons and saved variables, it's recommended you back up your SavedVariables file located at "WTF\Accounts\ACCOUNT_NAME\SavedVariables\CommunityDKP.lua" at the end of every raid week to ensure all data
	  isn't lost due to somehow losing your WTF folder.  
	- Export DKP to HTML at the end of a raid week and paste into an HTML file and keep a week by week log in Discord for players to view outside of the game. This will also give you a backup of the data to reapply in the event data is lost.  
  
## Guild Branding
If you'd like to change the CommunityDKP Title image to one for your own guild, you're more than welcome to. It simply requires you replace "CommunityDKP\Media\Textures\community-dkp.tga" with your custom tga image (MUST be 256 x 64).
