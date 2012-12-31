[homepage]: https://github.com/BarrensZeppelin/SKAuctioneer

SKAuctioneer 
============
created by Oskar Veileborg (Esaya) for the guild Absolute Zero on Al'Akir EU (Horde).    
The official development page is: [SKAuctioneer @ GitHub][homepage]

SKAuctioneer is a lightweight and 100% open-source AddOn for Suicide Kings(SK) loot distribution management in guilds and raid-teams.    
### Featuring:
   - Simple and solid item auctioning
   - Automatic player suicide
   - SK player list management interface
   - Ongoing auction status reports (no stealth auctions/no gambling)
   - Shared AddOn control (with the Access Control List)
   - Modifiable output Channel and auction run-time 
   - And a tailored loot distribution interface!

Information about SK loot system can be found here: http://www.wowwiki.com/Suicide_Kings

Usage guide
-----------

### Rules:
There are two ways of winning an item in this version of the SK ruleset:

   - Need
   
     and
	 
   - Greed

When an auction ends and at least one player has declared need on the auctioned item, SKAuctioneer will find the highest ranked player on the SK player list, name him the winner and suicide him to the bottom!

If there are no needers, but at least one greeder, SKAuctioneer will ask the greeders to roll for the item, or automatically find a random winner from the pool, based on your preference.    
**Note, that by winning an item by greed, the lucky player does not suicide to the bottom of the SK player list.**

### How-to:
Quick-slash: `/ska`

#### For the raid leader(s):
When you have loot that you want to distribute with SKAuctioneer, there are three ways of doing it:

   1. Type `/ska start [itemlink]`    
      Where `[itemlink]` is the item you want auctioned.
	  
   2. Have a player on the Access Control List type:    
      `!auction [itemlink]`    
	  in either Guild, Officer or Raid-chat.

   3. Use the SKAuctioneer loot distribution interface (in raids only)    
      This feature can be enabled by typing `/ska ldb y`

Ongoing auctions can be cancelled by writing `/ska stop` or by a player on the ACL `!cancel`.	
Refer to the guide in-game on how to perform other tasks such as setting the Channel which SKAuctioneer should use.

#### For everyone else:
Once an auction has started and the auctioned item is to your liking, do not hesitate to whisper the SKAuctioneer host your status on the item. Simply `/w [SKA Host] <need/greed>` and SKAuctioneer will automatically update your status or add you to the list of needers/greeders.    
For instance: if I wanted the item, but not enough to let go of my SK position, I would type `/w Apoulsen greed` (In this example Apoulsen is the `[SKA Host]`)    
If I were to change my mind and decide that I really wanted the item, I could just change to need by typing `/w Apoulsen need`.    
**Keep in mind**, that you can not change your status to greed after you have already needed!

Now that you know how to control the SKAuctioneer AddOn, start using it!

Help & Suggestions
------------------
If you want to contribute in any way shape or form, or if you find a bug, feel free to use the Issues tab on the [development page][homepage] on GitHub.


Changelog
---------
Any information you might gather from the GitHub commit history is the changelog!