﻿local testMode = false;

local currentItem;
local takers = {};
local prefix = "[SKAuctioneer] ";


SKAuctioneer_Settings_Default = {
	PlayerList = {},

	Channel = "GUILD",
	
	AuctionTime = 15,
	
	ACL = {},
	
	AutoGreedRoll = true,
	
	HideWhispers = true,
	
	LDB = true,
	
	FirstRun = true
};

SKAuctioneer_Settings = SKAuctioneer_Settings_Default;

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
			if i == 1 then
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
			if i == 1 then
				greedString = greedString..greeders[i];
			elseif i+1 > #greeders then
				greedString = greedString.." and "..greeders[i];
			else 
				greedString = greedString..", "..greeders[i];
			end
		end
		greedString = greedString..".";
		-------------------------
		
		if #needers > 0 then SendChatMessage(printNeedStatus:format(needString), SKAuctioneer_Settings.Channel); end
		if #greeders > 0 then SendChatMessage(printGreedStatus:format(greedString), SKAuctioneer_Settings.Channel); end
		_Timer_Unschedule(endAuction); 	_Timer_Schedule(10, endAuction); -- Reschedule endAuction to end in 10 seconds, so people have time to react
		SendChatMessage(auctionProgress:format(currentItem, 10), SKAuctioneer_Settings.Channel);
	end
end

local function suicidePlayer(name)
	for i=1, #SKAuctioneer_Settings.PlayerList do
		if name == SKAuctioneer_Settings.PlayerList[i] then
			table.insert(SKAuctioneer_Settings.PlayerList, table.remove(SKAuctioneer_Settings.PlayerList, i));
			break;
		end
	end
end


do
	local auctionAlreadyRunning = "There is already an auction running for %s! Wait until it has ended before starting a new one.";
	local startingAuction = prefix.."Starting auction for %s, whisper me \"need\" or \"greed\" to declare your status. Remaining time: %d seconds.";
	
	function startAuction(item, starter)
		if currentItem then
			local msg = auctionAlreadyRunning:format(currentItem);
			if starter then
				SendChatMessage(msg, "WHISPER", nil, starter);
				return false;
			else
				print(msg);
				return false;
			end
		else
			currentItem = item;
			SendChatMessage(startingAuction:format(item, SKAuctioneer_Settings.AuctionTime), SKAuctioneer_Settings.Channel);
			_Timer_Schedule(SKAuctioneer_Settings.AuctionTime/2, SendChatMessage, noBidsYet:format(item, SKAuctioneer_Settings.AuctionTime/2), SKAuctioneer_Settings.Channel);
			_Timer_Schedule(SKAuctioneer_Settings.AuctionTime, endAuction);
			
			return true;
		end
	end
end

do
	local cancelled = prefix.."Auction cancelled by %s.";
	local noAuction = prefix.."There is no ongoing auction to cancel.";
	
	function cancelAuction(sender)
		if currentItem then
			currentItem = nil;
			table.wipe(takers);
			_Timer_Unschedule(SendChatMessage);
			_Timer_Unschedule(endAuction);
			_Timer_Unschedule(sendStatus);
			SendChatMessage(cancelled:format(sender or UnitName("player")), SKAuctioneer_Settings.Channel);
		else
			SendChatMessage(noAuction, "WHISPER", nil, sender);
		end
	end
end

do
	local noTakers = prefix.."Noone wants %s!";
	local greedWinner = prefix.."%s won %s by \"greed\", and thus remains at his SK position.";
	local needWinner = prefix.."%s won %s by \"need\", and thus suicides to the bottom of the SK lootlist.";
	
	function endAuction()
		if #takers == 0 then
			SendChatMessage(noTakers:format(currentItem), SKAuctioneer_Settings.Channel);
		elseif #takers == 1 then
			if takers[1].status == "greed" then
				SendChatMessage(greedWinner:format(takers[1].name, currentItem), SKAuctioneer_Settings.Channel);
			else
				SendChatMessage(needWinner:format(takers[1].name, currentItem), SKAuctioneer_Settings.Channel);
				suicidePlayer(takers[1].name);
			end
		else
			local needers = {};
			for i=1, #takers do
				if takers[i].status == "need" then
					table.insert(needers, takers[i].name);
				end
			end
			
			if #needers > 0 then -- dette stykke kode kører igennem listen fra 1 til maks og giver item til den første der optræder
				local found = false;
				for i=1, #SKAuctioneer_Settings.PlayerList do
					for u=1, #needers do
						if needers[u] == SKAuctioneer_Settings.PlayerList[i] then
							SendChatMessage(needWinner:format(needers[u], currentItem), SKAuctioneer_Settings.Channel);
							found = true;
							suicidePlayer(needers[u]);
							break;
						end
					end
					if found then break; end
				end
				if not found then print("Error: Needer not found in the PlayerList!"); end
				
			else -- kun greeders, roll!
				if SKAuctioneer_Settings.AutoGreedRoll then
					SendChatMessage(prefix.."The auction for "..currentItem.." has ended, and "..#takers.." people declared greed. SKAuctioneer will find a random winner!", SKAuctioneer_Settings.Channel);
					_Timer_Schedule(1, SendChatMessage, prefix.."The winner of "..currentItem.." is: "..takers[random(#takers)].name.."!", SKAuctioneer_Settings.Channel);
				else
					local greedString = prefix.."No need, only greed;";
					for i=1, #takers do
						if i == 1 then
							greedString = greedString.." "..takers[i].name; 
						elseif i+1 > #takers then
							greedString = greedString.." and "..takers[i].name;
						else
							greedString = greedString..", "..takers[i].name;
						end
					end
					greedString = greedString.." - /roll  for "..currentItem.." now!";
					SendChatMessage(greedString, SKAuctioneer_Settings.Channel);
				end
			end
		end
		
		table.wipe(takers);
		currentItem = nil;
	end
end

do
	local greedUnavailable = prefix.."You can no longer place/change to greed on %s since it has already been needed.";
	local bidPlaced = prefix.."Your bid of status: \"%s\" on %s has been registered and/or updated.";
	local alreadyBid = prefix.."You have already %sed on %s!";
	
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
					if (msg:lower() == "greed" and takers[i].status == "greed") or (msg:lower() == "need" and takers[i].status == "need") then
						SendChatMessage(alreadyBid:format(takers[i].status, currentItem), "WHISPER", nil, sender);
						return;
					else
						takers[i].status = msg:lower();
						SendChatMessage(bidPlaced:format(msg:lower(), currentItem), "WHISPER", nil, sender);
						
						_Timer_Extend(3, endAuction);
						_Timer_Unschedule(sendStatus);
						_Timer_Schedule(2, sendStatus);
						_Timer_Unschedule(SendChatMessage, noBidsYet:format(currentItem, SKAuctioneer_Settings.AuctionTime/2), SKAuctioneer_Settings.Channel);
						return;
					end
				end
			end
			
			-- Personen har endnu ikke budt på gearet, så vi oprætter ham i takers
			table.insert(takers, {name = sender, status = msg:lower()});
			SendChatMessage(bidPlaced:format(msg:lower(), currentItem), "WHISPER", nil, sender);
			
			_Timer_Extend(4, endAuction);
			_Timer_Unschedule(sendStatus);
			_Timer_Schedule(2, sendStatus);
			_Timer_Unschedule(SendChatMessage, noBidsYet:format(currentItem, SKAuctioneer_Settings.AuctionTime/2), SKAuctioneer_Settings.Channel);
		
		elseif SKAuctioneer_Settings.ACL[sender] then
			local cmd, arg = msg:match("^!(%w+)%s*(.*)");
			if cmd and cmd:lower() == "auction" and arg then
				startAuction(arg, sender);
			elseif cmd and cmd:lower() == "cancel" then
				cancelAuction(sender);
			end
		end
	end
end

local frame = CreateFrame("Frame");
frame:RegisterEvent("CHAT_MSG_WHISPER");
frame:RegisterEvent("CHAT_MSG_RAID");
frame:RegisterEvent("CHAT_MSG_RAID_LEADER");
frame:RegisterEvent("CHAT_MSG_OFFICER");
frame:RegisterEvent("CHAT_MSG_GUILD");
frame:RegisterEvent("CHAT_MSG_SAY");
frame:SetScript("OnEvent", onEvent);

local e = 0;
local function onUpdate(self, elapsed)
	if not SKAuctioneer_Settings.FirstRun then
		frame:SetScript("OnUpdate", nil);
	else
		e = e + elapsed;
		if e >= 2 then
			print('This seems to be the first time you have run |cFF42E80CSKAuctioneer|r, please take some time to set up your playerlist.\nYou can always do this at another time by typing "/ska playerlist"!');
			
			
			SKA_AddPlayer(UnitName("player"));
			SKA_PlayerList_Editor:Show();
			
			SKAuctioneer_Settings.FirstRun = false;
		end
	end
end

frame:SetScript("OnUpdate", onUpdate);


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
		table.insert(usage, "|cFF42E80CSKAuctioneer|r Usage Guide:");
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
		table.insert(usage, " - playerlist - Shows the Player List editing frame.");
		table.insert(usage, " - hidechat <Y/N> - Hide whispers by SKA?");
		table.insert(usage, " - ldb <Y/N> - Use the SKA Loot Distribution Interface?");
		table.insert(usage, " - autoroll <Y/N> - Should SKAuctioneer find a random winner on greeds?");
		table.insert(usage, " - reset - Sets settings back to default.");
	
	local function addToACL(...)
		for i=1, select("#", ...) do
			SKAuctioneer_Settings.ACL[select(i, ...)] = true;
		end
		print(addedToACL:format(select("#", ...)));
	end
	
	local function removeFromACL(...)
		for i=1, select("#", ...) do
			SKAuctioneer_Settings.ACL[select(i, ...)] = nil;
		end
		print(removedFromACL:format(select("#", ...)));
	end
	
	SlashCmdList["SKAuctioneer"] = function(msg)
		local cmd, arg = string.split(" ", msg);
		cmd = cmd:lower();
		
		if cmd == "start" and arg then
			startAuction(msg:match("^start%s+(.+)")) -- extract the item link
		elseif cmd == "stop" then
			cancelAuction(UnitName("player"));
		elseif cmd == "channel" then
			if arg then
				SKAuctioneer_Settings.Channel = arg:upper();
				print(setChannel:format(SKAuctioneer_Settings.Channel));
			else
				print(currChannel:format(SKAuctioneer_Settings.Channel));
			end
		elseif cmd == "time" then
			if arg and tonumber(arg) then
				SKAuctioneer_Settings.AuctionTime = tonumber(arg);
				print(setTime:format(SKAuctioneer_Settings.AuctionTime));
			else
				print(currTime:format(SKAuctioneer_Settings.AuctionTime));
			end
		elseif cmd == "acl" then
			if not arg then
				print(ACL);
				for k, v in pairs(SKAuctioneer_Settings.ACL) do
					print(k);
				end
			elseif arg:lower() == "add" then
				addToACL(select(3, string.split(" ", msg)));
			elseif arg:lower() == "remove" then
				removeFromACL(select(3, string.split(" ", msg)));
			else print("Unknown command ".. arg.."!");
			end
		elseif cmd == "playerlist" then
			SKA_BuildSF();
			SKA_PlayerList_Editor:Show();
		elseif cmd == "hidechat" and arg and (tonumber(arg) or (arg:lower()=="y" or arg:lower()=="n")) then
			if tonumber(arg) == 0 or arg:lower()=="n" then 
				SKAuctioneer_Settings.HideWhispers = false;
				print("SKA now shows chat created by auctions.");
			elseif tonumber(arg) == 1 or arg:lower()=="y" then
				SKAuctioneer_Settings.HideWhispers = true;
				print("SKA no longer shows chat created by auctions.");
			end
		elseif cmd == "ldb" and arg and (arg:lower()=="y" or arg:lower()=="n") then
			if arg:lower()=="y" then
				SKAuctioneer_Settings.LDB = true;
				print("SKA will now show the distribution interface in raids.");
			elseif arg:lower()=="n" then
				SKAuctioneer_Settings.LDB = false;
				print("SKA will no longer show the distribution interface.");
			end
		elseif cmd == "autoroll" and arg and (arg:lower()=="y" or arg:lower()=="n") then
			if arg:lower()=="y" then
				SKAuctioneer_Settings.AutoGreedRoll = true;
				print("SKA will now automatically find a random winner between greeders.");
			elseif arg:lower()=="n" then
				SKAuctioneer_Settings.AutoGreedRoll = false;
				print("SKA no longer uses Auto Greed Roll.");
			end
		elseif cmd == "reset" then
			SKAuctioneer_Settings = SKAuctioneer_Settings_Default;
			SKA_BuildSF();
			print("Settings have been reset!");
		elseif cmd == "testmode" then
			testMode = true;
			print("Testmode engaged, prepare your anus!");
		else
			for i=1, #usage do
				print(usage[i]);
			end
		end
	end
end

--	Filter Whispers created by the addon if setting is enables
local function filterOutgoing(self, event, ...)
	local msg = ...;
	return msg:sub(0, prefix:len()) == prefix and SKAuctioneer_Settings.HideWhispers, ...;
end

local function filterIncoming(self, event, ...)
	local msg = ...;
	return currentItem and (msg:lower() == "greed" or msg:lower() == "need") and SKAuctioneer_Settings.HideWhispers, ...;
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterIncoming);
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterOutgoing);


	

-- GUI STUFF BELOW:

-- Table to reuse Buttons
local LootButtonPool = {};

local function removeLootButton(f)
	f:Hide();
	table.insert(LootButtonPool, f);
end

local function newLootButton(iconTexture)
	local f = table.remove(LootButtonPool);
	
	if not f then
		f = CreateFrame("Button", nil, SKA_LootFrame_ButtonFrame, "LootButtonTemplate");
		local regions = { f:GetRegions() };
		for i=1, #regions do
			--print(regions[i]:GetName());
			if regions[i]:GetName() == "SKA_LootFrame_ButtonFrameNameFrame" then
				regions[i]:Hide();
			elseif regions[i]:GetName() == "SKA_LootFrame_ButtonFrameIconTexture" then
				regions[i]:SetTexture(iconTexture);
			end
		end
	else
		local regions = { f:GetRegions() };
		for i=1, #regions do
			--print(regions[i]:GetName());
			if regions[i]:GetName() == "SKA_LootFrame_ButtonFrameIconTexture" then
				regions[i]:SetTexture(iconTexture);
			end
		end
		f:Show();
	end

	return f;
end

local function lootFrame_OnEvent(self)
	local lootmethod, pID = GetLootMethod();
	local lootTreshold;
	if(IsInRaid() and pID) then lootTreshold = GetLootTreshold(); else lootTreshold = 0; end
	
	local validItems = 0;
	
	if (lootmethod == "master" and pID == 0 and SKAuctioneer_Settings.LDB) or testMode then
	
		if testmode then print("Opened loot. There are "..GetNumLootItems().." item(s) to loot."); end
		
		local children = { _G["SKA_LootFrame_ButtonFrame"]:GetChildren() };
		for i=1, #children do
			removeLootButton(children[i]);
		end
		
		for i=1, GetNumLootItems() do
			local lootIcon, lootName, lootQuantity, rarity, locked = GetLootSlotInfo(i);
			
			if locked ~= 1 and rarity >= lootTreshold and GetLootSlotType(i) == LOOT_SLOT_ITEM then
				local button = newLootButton(lootIcon);
				
				--Grid positioning
				button:SetPoint("TOPLEFT", "SKA_LootFrame_ButtonFrame", "TOPLEFT", ((validItems)%5)*42, -10+(floor((validItems)/5))*(-42));
				
				button:SetScript("OnClick", function(self) 
					if startAuction(GetLootSlotLink(i)) then 
						removeLootButton(self);
					end
				end);
				
				
				button:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self, "ANCHOR_CURSOR");
					GameTooltip:SetLootItem(i);
					GameTooltip:AddLine("");
					GameTooltip:AddLine("Start Auction!", 1, 0.5, 0);
					GameTooltip:Show();
				end);
				
				
				validItems = validItems + 1;
			end
		end
	end
	
	if validItems > 0 then
		SKA_LootFrame:SetHeight(58+ceil(validItems/5)*42);
		SKA_LootFrame:Show();
	else
		SKA_LootFrame:Hide();
	end
end

local lootFrame = CreateFrame("Frame", "SKA_LootFrame", LootFrame, "SKA_LootFrame_Template");
lootFrame:RegisterEvent("LOOT_OPENED");
lootFrame:SetScript("OnEvent", lootFrame_OnEvent);

SKA_PlayerList_Editor:SetFrameStrata("DIALOG");


-- Add Player popup
StaticPopupDialogs["SKA_ADD_PLAYER"] = {
	text = "Type the name of the player you want to add:",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 12,
	OnAccept = function(self)
		SKA_AddPlayer(self.editBox:GetText());
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		self.editBox:SetText("");
	end,
	EditBoxOnEnterPressed = function(self)
		SKA_AddPlayer(self:GetText());
		self:GetParent():Hide();
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
};

function SKA_ShowAddPlayerPopup()
	StaticPopup_Show("SKA_ADD_PLAYER");
end



-- Table to reuse frames
local ListItemPool = {};

local function removeListItem(f)
	f:Hide();
	table.insert(ListItemPool, f);
end

local function newListItem()
	local f = table.remove(ListItemPool);
	
	if not f then
		f = CreateFrame("Frame", nil, SKA_PlayerList_Editor_ListFrame_SF.content, "SKA_PlayerList_ListItemTemplate");
		f:SetPoint("LEFT"); f:SetPoint("RIGHT");
		f:SetHeight(25);
		
		local fString = f:CreateFontString("NameString", ARTWORK, "GameFontNormal");
		fString:SetPoint("LEFT", 70, 0);
		
		fString = f:CreateFontString("OrderString", ARTWORK, "GameFontNormal");
		fString:SetPoint("LEFT", 5, 0);
	else
		local _, b1, b2 = f:GetChildren();
		b1:Show(); b2:Show();
		f:Show();
	end

	return f;
end
---------------------------------------


-- Populate SKA_PlayerList_Editor_ListFrame
function SKA_BuildSF()
	-- Clean up current content
	local children = { SKA_PlayerList_Editor_ListFrame_SF_Content:GetChildren() };
	for i=1, #children do
		removeListItem(children[i]);
	end
	----------------------------
	
	
	-- Add new content ------------
	local height = 0;
	
	for i=1, #SKAuctioneer_Settings.PlayerList do
		local frame = newListItem();
		frame:SetPoint("TOP", frame:GetParent(), "TOP", 0, -((i-1)*frame:GetHeight()));
		
		if i == 1 then
			local _, ButtonUp, ButtonDown = frame:GetChildren();
			ButtonUp:Hide();
			if #SKAuctioneer_Settings.PlayerList == 1 then
				ButtonDown:Hide();
			end
		elseif i == #SKAuctioneer_Settings.PlayerList then
			local _, _, ButtonDown = frame:GetChildren();
			ButtonDown:Hide();
		end
		

		local NameString, OrderString = frame:GetRegions();
		
		NameString:SetText(SKAuctioneer_Settings.PlayerList[i]);
		OrderString:SetText(i..".");
	
		
		height = height + frame:GetHeight();
	end
	-------------------------------
	
	-- Update elements
	SKA_PlayerList_Editor_ListFrame_SF.content:SetHeight(height);
	SKA_UpdateSlider(SKA_PlayerList_Editor_ListFrame_SF_Content);
end



function SKA_AddPlayer(name)
	table.insert(SKAuctioneer_Settings.PlayerList, name);
	
	SKA_BuildSF();
	
	if #SKAuctioneer_Settings.PlayerList == 2 then
		SKA_BuildSF();
	end
end


function SKA_RemovePlayer(frame)	
	local NameString = frame:GetRegions();
	local name = NameString:GetText();
	
	
	for i=1, #SKAuctioneer_Settings.PlayerList do
		if name == SKAuctioneer_Settings.PlayerList[i] then
			table.remove(SKAuctioneer_Settings.PlayerList, i);
			break;
		end
	end
	
	SKA_BuildSF();
end


function SKA_SwitchPlayer(frame, switchpos)
	local NameString, OrderString = frame:GetRegions();
	local pos = tonumber(string.match(OrderString:GetText(), "^(.+)\.$"));
	
	if pos+switchpos <= 0 or pos+switchpos > #SKAuctioneer_Settings.PlayerList then return; end
	
	local name = NameString:GetText();
	
	-- Switch positions
	SKAuctioneer_Settings.PlayerList[pos] = SKAuctioneer_Settings.PlayerList[pos+switchpos];
	SKAuctioneer_Settings.PlayerList[pos+switchpos] = name;
	
	SKA_BuildSF();
end


print("Loaded |cFF42E80CSKAuctioneer|r by |cFF90E80CAbsolute Zero / Al'Akir(EU)|r");
