local currentItem;
local takers = {};
local prefix = "[SKAuctioneer] ";

-- index 1 er højest på listen
SKAuctioneer_PlayerList = {"Emanorp", "Fluffywrath", "Bazìnga", "Sartharia", "Dreamheal", "Xitsi", "Apoulsen", "Esaya", "Korzul", "Parium"}; -- Til at starte med hardcoder jeg playerlisten, bagefter vil der komme et GUI til at sætte den op
--TEST: SKAuctioneer_PlayerList = {"Devmode", "Apoulsen"};
SKAuctioneer_Channel = "GUILD";
SKAuctioneer_AuctionTime = 15; -- seconds
SKAuctioneer_ACL = {}; -- Access control list

local startAuction, endAuction, placeWant, cancelAuction, sendStatus, onEvent;

local auctionProgress = prefix.."Time remaining for %s: %d seconds.";
local noBidsYet = prefix.."There are no current bids on %s, time remaining on auction is %d seconds";

do
	local printNeedStatus = prefix.."Need: %s";
	local printGreedStatus = prefix.."Greed: %s";
	
	function sendStatus()
		local needString = "";
		local greedString = "";
		
		needers = {}; greeders = {};
		for i=1, #takers do
			if takers[i].status == "greed" then
				table.insert(greeders, takers[i].name);
			else
				table.insert(needers, takers[i].name);
			end
		end
		
		-----------------------
		for i=1, #needers do	-- Opbyg streng for needers
			if #needers == 1 then
				needString = needString..needers[i];
			elseif i+1 > #needers then
				needString = needString.." and "..needers[i];
			else 
				needString = needString..", "..needers[i];
			end
		end
		needString = needString..".";
		------------------------
		
		------------------------
		for i=1, #greeders do	-- Opbyg streng for greeders
			if #greeders == 1 then
				greedString = greedString..greeders[i];
			elseif i+1 > #greeders then
				greedString = greedString.." and "..greeders[i];
			else 
				greedString = greedString..", "..greeders[i];
			end
		end
		greedString = greedString..".";
		-------------------------
		
		if #needers > 0 then SendChatMessage(printNeedStatus:format(needString), SKAuctioneer_Channel); end
		if #greeders > 0 then SendChatMessage(printGreedStatus:format(greedString), SKAuctioneer_Channel); end
		_Timer_Unschedule(endAuction); 	_Timer_Schedule(10, endAuction); -- Reschedule endAuction to end in 10 seconds, so people have time to react
		SendChatMessage(auctionProgress:format(currentItem, 10), SKAuctioneer_Channel);
	end
end

local function suicidePlayer(name)
	for i=1, #SKAuctioneer_PlayerList do
		if name == SKAuctioneer_PlayerList[i] then
			table.insert(SKAuctioneer_PlayerList, table.remove(SKAuctioneer_PlayerList, i));
			break;
		end
	end
end


do
	local auctionAlreadyRunning = "There is already an auction running on %s!";
	local startingAuction = prefix.."Starting auction for %s, whisper me \"need\" or \"greed\" to state your status. Remaining time: %d seconds.";
	
	function startAuction(item, starter)
		if currentItem then
			local msg = auctionAlreadyRunning:format(currentItem);
			if starter then
				SendChatMessage(msg, "WHISPER", nil, starter);
			else
				print(msg);
			end
		else
			currentItem = item;
			SendChatMessage(startingAuction:format(item, SKAuctioneer_AuctionTime), SKAuctioneer_Channel);
			_Timer_Schedule(SKAuctioneer_AuctionTime/2, SendChatMessage, noBidsYet:format(item, SKAuctioneer_AuctionTime/2), SKAuctioneer_Channel);
			_Timer_Schedule(SKAuctioneer_AuctionTime, endAuction);
		end
	end
end


do
	local noTakers = prefix.."Noone wants %s, disenchant it!";
	local greedWinner = prefix.."%s won %s by \"greed\", and thus remains at his SK position.";
	local needWinner = prefix.."%s won %s by \"need\", and thus suicides to the bottom of the SK lootlist.";
	
	function endAuction()
		if #takers == 0 then
			SendChatMessage(noTakers:format(currentItem), SKAuctioneer_Channel);
		elseif #takers == 1 then
			if takers[1].status == "greed" then
				SendChatMessage(greedWinner:format(takers[1].name, currentItem), SKAuctioneer_Channel);
			else
				SendChatMessage(needWinner:format(takers[1].name, currentItem), SKAuctioneer_Channel);
				suicidePlayer(takers[1].name);
			end
		else
			needers = {};
			for i=1, #takers do
				if takers[i].status == "need" then
					table.insert(needers, takers[i].name);
				end
			end
			
			if #needers > 0 then -- dette stykke kode kører igennem listen fra 1 til maks og giver item til den første der optræder
				for i=1, #SKAuctioneer_PlayerList do
					for u=1, #needers do
						if needers[u] == SKAuctioneer_PlayerList[i] then
							suicidePlayer(needers[u]);
							break;
						end
					end
				end
				
			else -- kun greeders, roll!
				greedString = prefix.."No need, only greed";
				for i=1, #takers do
					if i+1 > #takers then
						greedString = greedString.." and "..takers[i].name;
					else
						greedString = greedString..", "..takers[i].name;
					end
				end
				greedString = greedString.."; /roll  for "..currentItem.." now!";
				SendChatMessage(greedString, SKAuctioneer_Channel);
			end
		end
		
		table.wipe(takers);
		currentItem = nil;
	end
end

do
	local greedUnavailable = prefix.."You can no longer place/change to greed on %s since it has already been needed.";
	local bidPlaced = prefix.."Your bid of status: \"%s\" on %s has been registered and/or updated.";
	local alreadyGreed = prefix.."You have already greeded on %s!";
	
	function onEvent(self, event, msg, sender)
		if event == "CHAT_MSG_WHISPER" and currentItem and (msg:lower()=="greed" or msg:lower()=="need") then
			needers = {};
			for i=1, #takers do
				if takers[i].status == "need" then
					table.insert(needers, takers[i].name);
				end
			end
			
			if #needers > 0 and msg:lower()=="greed" then
				SendChatMessage(greedUnavailable:format(currentItem), "WHISPER", nil, sender);
				return;
			end
			
			for i=1, #takers do
				if takers[i].name == sender then
					if msg:lower() == "greed" and takers[i].status == "greed" then
						SendChatMessage(alreadyGreed:format(currentItem), "WHISPER", nil, sender);
						return;
					else
						takers[i].status = msg:lower();
						SendChatMessage(bidPlaced:format(msg:lower(), currentItem), "WHISPER", nil, sender);
						
						_Timer_Extend(3, endAuction);
						_Timer_Unschedule(sendStatus);
						_Timer_Schedule(2, sendStatus);
						_Timer_Unschedule(SendChatMessage, noBidsYet:format(currentItem, SKAuctioneer_AuctionTime/2), SKAuctioneer_Channel);
						return;
					end
				end
			end
			
			-- Personen har endnu ikke budt på gearet, så vi oprætter ham i takers
			table.insert(takers, {name = sender, status = msg:lower()});
			SendChatMessage(bidPlaced:format(msg:lower(), currentItem), "WHISPER", nil, sender);
			
			_Timer_Extend(endAuction, 3);
			_Timer_Unschedule(sendStatus);
			_Timer_Schedule(2, sendStatus);
			_Timer_Unschedule(SendChatMessage, noBidsYet:format(currentItem, SKAuctioneer_AuctionTime/2), SKAuctioneer_Channel);
		end
	end
end

local frame = CreateFrame("Frame");
frame:RegisterEvent("CHAT_MSG_WHISPER");
frame:SetScript("OnEvent", onEvent);

SLASH_SKAuctioneer1 = "/ska";
SLASH_SKAuctioneer2 = "/skauc";
SLASH_SKAuctioneer3 = "/skauctioneer";

do
	-- handle slash commands	
	local setChannel = "Channel is now \"%s\"";
	local setTime = "Auction time is now %s seconds";
	local addedToACL = "Added %s player(s) to the ACL";
	local removedFromACL = "Removed %s player(s) from the ACL";
	local currChannel = "Channel is currently set to %s";
	local currTime = "Auction time is currently set to %s seconds";
	local ACL = "Access Control List:";
	local usage = {};
		table.insert(usage, "/ska");
		table.insert(usage, " - start <item> - Starts an auction for the selected item.");
		table.insert(usage, " - stop - Cancels the current auction.");
		table.insert(usage, " - channel - Returns the current channel used by SKA.");
		table.insert(usage, " - channel <channel> - Sets the channel SKA should use.");
		table.insert(usage, " - time - Returns the current Time auctions run for.");
		table.insert(usage, " - time <time> - Adjusts the amount of time auctions run for.");
		table.insert(usage, " - acl - Returns the Access Control List.");
		table.insert(usage, " - acl add <players> - Adds <players> separated by spaces to the ACL.");
		table.insert(usage, " - acl remove <players> - Removes <players> from the ACL.");
	
	local function addToACL(...)
		for i=1, select("#", ...) do
			SKAuctioneer_ACL[select(i, ...)] = true;
		end
		print(addedToACL:format(select("#", ...)));
	end
	
	local function removeFromACL(...)
		for i=1, select("#", ...) do
			SKAuctioneer_ACL[select(i, ...)] = nil;
		end
		print(removedFromACL:format(select("#", ...)));
	end
	
	SlashCmdList["SKAuctioneer"] = function(msg)
		local cmd, arg = string.split(" ", msg);
		cmd = cmd:lower();
		
		if cmd == "start" and arg then
			startAuction(msg:match("^start%s+(.+)")) -- extract the item link
		elseif cmd == "stop" then
			cancelAuction();
		elseif cmd == "channel" then
			if arg then
				SKAuctioneer_Channel = arg:upper();
				print(setChannel:format(SKAuctioneer_Channel));
			else
				print(currChannel:format(SKAuctioneer_Channel));
			end
		elseif cmd == "time" then
			if arg and tonumber(arg) then
				SKAuctioneer_AuctionTime = tonumber(arg);
				print(setTime:format(SKAuctioneer_AuctionTime));
			else
				print(currTime:format(SKAuctioneer_AuctionTime));
			end
		elseif cmd == "acl" then
			if not arg then
				print(ACL);
				for k, v in pairs(SKAuctioneer_ACL) do
					print(k);
				end
			elseif arg:lower() == "add" then
				addToACL(select(3, string.split(" ", msg)));
			elseif arg:lower() == "remove" then
				removeFromACL(select(3, string.split(" ", msg)));
			end
		else
			for i=1, #usage do
				print(usage[i]);
			end
		end
	end
end

print("Loaded SKAuctioneer by Absolute Zero / Al'Akir(EU)");
