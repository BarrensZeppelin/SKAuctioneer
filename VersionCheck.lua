-- The idea is, that with every release the version number in this file changes, and thus does not represent the one in the SavedVariables
-- If this is the case, the SavedVariables should reset to make sure changes does not break the addon
function SKA_CheckVersion()
	local version = tonumber(GetAddOnMetadata("SKAuctioneer", "Version"));

	if SKAuctioneer_Settings.Version < version then
		local prevSettings = SKAuctioneer_Settings;
		
		SKAuctioneer_Settings = SKAuctioneer_Settings_Default;
		
		if prevSettings.Version < 2 then
			for i=1, #prevSettings.PlayerList do
				table.insert(SKAuctioneer_Settings.PlayerList, {prevSettings.PlayerList[i]});
			end
		else
			SKAuctioneer_Settings.PlayerList = prevSettings.PlayerList;
		end
		
		if prevSettings.RememberedNames then SKAuctioneer_Settings.RememberedNames = prevSettings.RememberedNames; end
		SKAuctioneer_Settings.Channel = prevSettings.Channel;
		SKAuctioneer_Settings.AuctionTime = prevSettings.AuctionTime;
		SKAuctioneer_Settings.ACL = prevSettings.ACL;
		if prevSettings.AutoGreedRoll then SKAuctioneer_Settings.AutoGreedRoll = prevSettings.AutoGreedRoll; end
		if prevSettings.HideWhispers then SKAuctioneer_Settings.HideWhispers = prevSettings.HideWhispers; end
		if prevSettings.LDB then SKAuctioneer_Settings.LDB = prevSettings.LDB; end
		if prevSettings.FirstRun then SKAuctioneer_Settings.FirstRun = prevSettings.FirstRun; end

		SKAuctioneer_Settings.Version = version;
		print("|cFF42E80CSKAuctioneer|r was successfully updated from version |cFFBF2633".. prevSettings.Version .."|r to |cFF599C00".. version .."|r\nYour settings were preserved!");
	end
end