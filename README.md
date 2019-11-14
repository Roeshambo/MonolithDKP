# MonolithDKP
[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=USXJZT2BKCYBS&currency_code=USD&source=url)

This is the development repository for Monolith DKP and may not necessarily reflect current releases on Curse or WoWI. It may also create compatibility issues with those that have older versiond depending on the features added. Back up your saved variables file prior to attempting to use to prevent any possible data loss.

Instructions: Clone and remove "-master" from the addon directory. Place in "Interface\AddOns" folder  

MonDKP is a DKP system written with intent to track all aspects of DKP and looting within WoW. Every member of the guild can have it and have full access to real-time DKP values as well as loot and DKP history.
This is my first official go at writting an addon despite 15 years of playing the game. So if any bugs or errors show their face, please let me know. Any suggestions or requests are also welcome!  
  
Features  
	- DKP Table entries provide a tooltip showing the players recently spent and earned DKP  
	- Filter the table by certain classes or show only those in your party / raid. Table columns can also be sorted by Player, Class or DKP  
	- Loot history. What item was won, by whom, from what boss/zone, and how much they spent on it. Can be filtered by player.  
	- DKP history. Comprehensive list of all players that received (or lost) dkp for each event.  
	- Bid timer displaying what is currently up for bid as well as it's minimum bid.  
  
Officer only features  
	- Bid window (opened by SHIFT+ALT clicking an item in the loot window or by typing /dkp bid [item link]) that starts bidding, collects all bids submitted, and awards the item. NOTE: Shift+Alt clicking an item only works if the item in in one of the first 4 slots of the loot window due to restrictions at the moment. If the item you wish to bid on isn't on the first page, either loot all items on that first page, close and reopen window. Or simply use /dkp bid [item link]  
	- Adjust DKP tab (awarding DKP). Also includes a DKP Decay option that reduces all entries by X% (default set in options or change on the fly in the Adjust DKP tab)   
	- Manage Tab. Used to broadcast complete tables to everyone in the guild if required as well as add/remove player entries.  
	- Shift+Click entries in the table to select multiple players to modify.  
	- Right click context menu in Loot History to reassign items (if minds are changed after awarding) which will subsequently give the DKP cost back to the initial owner and charge it to the new recipient  
	- Boss Kill Bonus auto selects the last killed boss/zone  
	- Options window has additional fields to set bonus defaults (On time bonus, boss kill bonus etc)  
  
Redundencies  
	- All entries can only be edited / added by officers in the guild (this is determined by checking Officer Note Writing permissions).  
	- If the addon is modified to grant a player access to the options available only to officers, attempting to broadcast a modified table will notify officers of this action.  
	- Every time an officer adds an entry or modifies a DKP value, the public note of the Guild Leader is changed to a time stamp. That time stamp is used to notify other users if they do or do not have the most up-to-date tables.  
  
Commands  
	/dkp ?  	- Lists all available commands  
	/dkp 		- Opens Main GUI  
	/dkp timer	- Starts a raid timer (Officers Only) IE: /dkp timer 120 Pizza Break!  
	/dkp reset 	- Resets GUI position  
	/dkp export - Exports all entries to HTML (To avoid crashing this will only export the most recent 200 loot history items and 200 DKP history items)  
	/dkp bid 	- Opens Bid Window. If you include an item link (/dkp bid [item link]) it will include that item for bid information.  
  
Recommendations  
	- Due to the volatile nature of WoW Addons and saved variables, it's recommended you back up your SavedVariables file located at "WTF\Accounts\ACCOUNT_NAME\SavedVariables\MonolithDKP.lua" at the end of every raid week to ensure all data
	  isn't lost due to somehow losing your WTF folder.  
	- Export DKP to HTML at the end of a raid week and paste into an HTML file and keep a week by week log in Discord for players to view outside of the game. This will also give you a backup of the data to reapply in the event data is lost.  
  
If you'd like to change the Monolith DKP Title image to one for your own guild, you're more than welcome to. It simply requires you replace "MonolithDKP\Media\Textures\mondkp-0title-t.tga" with your custom tga image (MUST be 256 x 64).
