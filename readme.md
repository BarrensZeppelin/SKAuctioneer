SKAuctioneer 
============
created by Oskar Veileborg (Esaya) for the guild Absolute Zero on Al'Akir EU (Horde).

SKAuctioneer is a lightweight and 100% open-source AddOn for Suicide Kings(SK) loot distribution management in guilds and raid-teams.    
### Featuring:
   - Simple and solid item auctioning
   - Automatic player suicide
   - SK player list management interface
   - Shared auction control (with the Access Control List)
   - Modifiable output Channel and auction run-time 
   - And an optional loot distribution interface!

Information about SK loot system can be found here: http://www.wowwiki.com/Suicide_Kings.

Usage guide
-----------

### Rules:
There are two ways of winning an item in this version of the SK ruleset:

   - Need
   
     and
	 
   - Greed

When an auction ends and at least one player has declared need on the auctioned item, SKAuctioneer will find the highest ranked player on the SK player list, name him the winner and suicide him to the bottom!

If there are no needers, but at least one greeder, SKAuctioneer will ask the greeders to roll for the item, or automatically find a random winner from the pool, based on your preference. Note, that by winning an item by greed, the lucky player does not suicide to the bottom of the SK player list.

### How-to:
Quick-slash: `/ska`

When you have loot that you want to distribute with SKAuctioneer, there are three ways of doing it:

   1. Type `/ska start [itemlink]`    
      Where [itemlink] is the item you want auctioned.
	  
   2. Have a player on the Access Control List type:    
      `!auction [itemlink]`    
	  in either Guild, Officer or Raid-chat.

   3. Use the SKAuctioneer loot distribution interface (in raids only)    
      This feature can be enabled by typing `/ska ldb y`

Ongoing auctions can be cancelled by writing `/ska stop` or by a player on the ACL `!cancel`.	
Refer to the guide in-game on how to perform other tasks such as setting the Channel which SKAuctioneer should use.

Now that you know how to control the SKAuctioneer AddOn, start using it!

Changelog
---------
Any information you might gather from the GitHub commit history is the changelog!