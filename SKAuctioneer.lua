local currentItem;
local takers = {};
local prefix = "[SKAuctioneer] ";

-- index 1 er højest på listen
SKAuctioneer_PlayerList = {"Emanorp", "Fluffywrath", "Bazìnga", "Sartharia", "Dreamheal", "Xitsi", "Apoulsen", "Esaya", "Korzul", "Parium"}; -- Til at starte med hardcoder jeg playerlisten, bagefter vil der komme et GUI til at sætte den op
SKAuctioneer_Channel = "GUILD";
SKAuctioneer_AuctionTime = 15; -- seconds
SKAuctioneer_ACL = {}; -- Access control list

local startAuction, endAuction, placeWant, cancelAuction, onEvent;

local auctionProgress = prefix.."Time remaining for %s: %d seconds.";

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
	local noBidsYet = prefix.."There are no current bids on %s, time remaining on auction is %d seconds";
	
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
				suicidePlayer(takers[i].name);
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

-- Remember to unschedule the "No bids have been sent"


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
					if msg:lower()=="greed" and takers[i].status = "greed" then
						SendChatMessage(alreadyGreed:format(currentItem), "WHISPER", nil, sender);
						return;
					else
						SendChatMessage(bidPlaced:format(msg:lower(), currentItem), "WHISPER", nil, sender);
						return;
					end
				end
			end
			
			-- Personen har endnu ikke budt på gearet, så vi oprætter ham i takers
			table.insert(takers, {name = sender, status = msg:lower()});
			SendChatMessage(bidPlaced:format(msg:lower(), currentItem), "WHISPER", nil, sender);
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
end
