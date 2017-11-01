--[[ Globals ]]--
CEPGP = CreateFrame("Frame");
_G = getfenv(0);
VERSION = "1.8.1";
BUILD = "release";
mode = "guild";
recordholder = "";
distPlayer = "";
distGP = false;
lootSlot = nil;
target = nil;
CHANNEL = nil;
MOD = nil;
COEF = nil;
BASEGP = nil;
STANDBYEP = false;
STANDBYOFFLINE = false;
STANDBYPERCENT = nil;
STANDBYRANKS = {};
SLOTWEIGHTS = {};
DEFSLOTWEIGHTS = {["2HWEAPON"] = 2,["WEAPONMAINHAND"] = 1.5,["WEAPON"] = 1.5,["WEAPONOFFHAND"] = 0.5,["HOLDABLE"] = 0.5,["SHIELD"] = 0.5,["RANGED"] = 0.5,["RANGEDRIGHT"] = 0.5,["RELIC"] = 0.5,["HEAD"] = 1,["NECK"] = 0.5,["SHOULDER"] = 0.75,["CLOAK"] = 0.5,["CHEST"] = 1,["ROBE"] = 1,["WRIST"] = 0.5,["HAND"] = 0.75,["WAIST"] = 0.75,["LEGS"] = 1,["FEET"] = 0.75,["FINGER"] = 0.5,["TRINKET"] = 0.75};
distID = nil;
distSlot = nil;
debugMode = false;
critReverse = false; --Criteria reverse
distributing = false;
overwritelog = false;
override = false;
confirmrestore = false;
looting = false;
RAZORGORE_EGG_COUNT = 0;
THEKAL_PARAMS = {["ZATH_DEAD"] = false, ["LOR'KHAN_DEAD"] = false, ["THEKAL_DEAD"] = false};
criteria = 4;
kills = 0;
frames = {CEPGP_guild, CEPGP_raid, CEPGP_loot, CEPGP_distribute, CEPGP_options, CEPGP_options_page_2, CEPGP_distribute_popup, CEPGP_context_popup};
LANGUAGE = GetDefaultLanguage("player");
AUTOEP = {};
EPVALS = {};
responses = {};
itemsTable = {};
roster = {};
raidRoster = {};
vInfo = {};
vSearch = "GUILD";
groupVersion = {};
RECORDS = {};
OVERRIDE_INDEX = {};
pfUI = nil; --nil or 1


--[[ Stock function backups ]]--
LFUpdate = LootFrame_Update;
LFEvent = LootFrame_OnEvent;
CFEvent = ChatFrame_OnEvent;

function CEPGP_OnEvent()
	if event == "LOOT_OPENED" and not pfUI then
		LootFrame_OnEvent(event);
	elseif (event == "LOOT_OPENED" or event == "LOOT_CLOSED" or event == "LOOT_SLOT_CLEARED") and pfUI then
		LootFrame_OnEvent(event);
	end
	
	if event == "ADDON_LOADED" and arg1 == "CEPGP" then --arg1 = addon name
		_, _, _, pfUI = GetAddOnInfo("pfUI");
		getglobal("CEPGP_version_number"):SetText("Running Version: " .. VERSION);
		local ver2 = string.gsub(VERSION, "%.", ",");
		if BUILD == "release" then
			CEPGP_SendAddonMsg("version-"..ver2..",".."-");
		end
		if CHANNEL == nil then
			CHANNEL = "GUILD";
		end
		if MOD == nil then
			MOD = 1;
		end
		if COEF == nil then
			COEF = 0.483;
		end
		if BASEGP == nil then
			BASEGP = 1;
		end
		if ntgetn(AUTOEP) == 0 then
			for k, v in pairs(bossNameIndex) do
				AUTOEP[k] = true;
			end
		end
		if ntgetn(EPVALS) == 0 then
			for k, v in pairs(bossNameIndex) do
				EPVALS[k] = v;
			end
		end
		if ntgetn(SLOTWEIGHTS) == 0 then
			SLOTWEIGHTS = {
				["2HWEAPON"] = 2,
				["WEAPONMAINHAND"] = 1.5,
				["WEAPON"] = 1.5,
				["WEAPONOFFHAND"] = 0.5,
				["HOLDABLE"] = 0.5,
				["SHIELD"] = 0.5,
				["RANGED"] = 0.5,
				["RANGEDRIGHT"] = 0.5,
				["RELIC"] = 0.5,
				["HEAD"] = 1,
				["NECK"] = 0.5,
				["SHOULDER"] = 0.75,
				["CLOAK"] = 0.5,
				["CHEST"] = 1,
				["ROBE"] = 1,
				["WRIST"] = 0.5,
				["HAND"] = 0.75,
				["WAIST"] = 0.75,
				["LEGS"] = 1,
				["FEET"] = 0.75,
				["FINGER"] = 0.5,
				["TRINKET"] = 0.75
			}
		end
		if STANDBYPERCENT ==  nil then
			STANDBYPERCENT = 0;
		end
		if ntgetn(STANDBYRANKS) == 0 then
			for i = 1, 10 do
				STANDBYRANKS[i] = {};
				STANDBYRANKS[i][1] = GuildControlGetRankName(i);
				STANDBYRANKS[i][2] = false;
			end
		end
		if UnitInRaid("player") then
			for i = 1, GetNumRaidMembers() do
				name = GetRaidRosterInfo(i);
				raidRoster[name] = name;
			end 
		end
		CEPGP_SendAddonMsg("version-check");
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFC100Classic EPGP Version: " .. VERSION .. " Loaded|r");
		DEFAULT_CHAT_FRAME:AddMessage("|c00FFC100CEPGP: Currently reporting to channel - " .. CHANNEL .. "|r");
	
	elseif event == "CHAT_MSG_WHISPER" and string.lower(arg1) == "~need" and distributing then --arg1 = message, arg2 = player
		local duplicate = false;
		for i = 1, table.getn(responses) do
			if responses[i] == arg2 then
				duplicate = true;
				if debugMode then
					CEPGP_print("Duplicate entry. " .. arg2 .. " not registered (!need)");
				end
			end
		end
		if not duplicate then
			CEPGP_SendAddonMsg("!need,"..arg2);
			table.insert(responses, arg2);
			if debugMode then
				CEPGP_print(arg2 .. " registered (!need)");
			end
			local _, _, _, _, _, _, _, slot = GetItemInfo(distID);
			if not slot then
				CEPGP_print("Unable to retrieve item information from the server. You will not see what the recipients are currently using", true);
			end
			CEPGP_SendAddonMsg(arg2.."-distributing-"..distID.."~"..distSlot);
			local EP, GP = nil;
			local inGuild = false;
			if tContains(roster, arg2, true) then
				EP, GP = getEPGP(roster[arg2][5]);
				class = roster[arg2][2];
				inGuild = true;
			end
			if distributing then
				if inGuild then
					SendChatMessage(arg2 .. " (" .. class .. ") needs. (" .. math.floor((EP/GP)*100)/100 .. " PR)", RAID, LANGUAGE);
				else
					local total = GetNumRaidMembers();
					for i = 1, total do
						if arg2 == GetRaidRosterInfo(i) then
							_, _, _, _, class = GetRaidRosterInfo(i);
						end
					end
					SendChatMessage(arg2 .. " (" .. class .. ") needs. (Non-guild member)", RAID, LANGUAGE);
				end
			end
			if not vInfo[arg2] then
				CEPGP_UpdateLootScrollBar();
			end
		end
	elseif event == "CHAT_MSG_WHISPER" and string.lower(arg1) == "!info" then
		if getGuildInfo(arg2) ~= nil then
			local EP, GP = getEPGP(roster[arg2][5]);
			if not vInfo[arg2] then
				SendChatMessage("EPGP Standings - EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100, "WHISPER", LANGUAGE, arg2);
			else
				CEPGP_SendAddonMsg("!info" .. arg2 .. "EPGP Standings - EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100, "GUILD");
			end
		end
	elseif event == "CHAT_MSG_WHISPER" and (string.lower(arg1) == "!infoguild" or string.lower(arg1) == "!inforaid" or string.lower(arg1) == "!infoclass") then
		if getGuildInfo(arg2) ~= nil then
			sRoster = {};
			GuildRoster();
			local gRoster = {};
			local rRoster = {};
			local name, unitClass, class, oNote, EP, GP;
			unitClass = roster[arg2][2];
			for i = 1, GetNumGuildMembers() do
				gRoster[i] = {};
				name , _, _, _, class, _, _, oNote = GetGuildRosterInfo(i);
				EP, GP = getEPGP(oNote);
				gRoster[i][1] = name;
				gRoster[i][2] = math.floor((EP/GP)*100)/100;
				gRoster[i][3] = class;
			end
			if string.lower(arg1) == "!infoguild" then
				if critReverse then
					gRoster = tSort(gRoster, 2);
					for i = 1, table.getn(gRoster) do
						if gRoster[i][1] == arg2 then
							if not vInfo[arg2] then
								SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in guild: #" .. i, "WHISPER", LANGUAGE, arg2);
							else
								CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in guild: #" .. i, "GUILD");
							end
						end
					end
				else
					critReverse = true;
					gRoster = tSort(gRoster, 2);
					for i = 1, table.getn(gRoster) do
						if gRoster[i][1] == arg2 then
							if not vInfo[arg2] then
								SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in guild: #" .. i, "WHISPER", LANGUAGE, arg2);
							else
								CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in guild: #" .. i, "GUILD");
							end
						end
					end
					critReverse = false;
				end
			else
				local count = 1;
				if string.lower(arg1) == "!infoclass" then
					for i = 1, GetNumRaidMembers() do
						local name = GetRaidRosterInfo(i);
						for x = 1, table.getn(gRoster) do
							if gRoster[x][1] == name and gRoster[x][3] == unitClass then
								rRoster[count] = {};
								rRoster[count][1] = name;
								_, _ ,_, class, oNote = getGuildInfo(name);
								EP, GP = getEPGP(oNote);
								rRoster[count][2] = math.floor((EP/GP)*100)/100;
								count = count + 1;
							end
						end
					end
				else --Raid
					for i = 1, GetNumRaidMembers() do
						local name = GetRaidRosterInfo(i);
						for x = 1, ntgetn(gRoster) do
							if gRoster[x][1] == name then
								rRoster[count] = {};
								rRoster[count][1] = name;
								_, _ ,_, class, oNote = getGuildInfo(name);
								EP, GP = getEPGP(oNote);
								rRoster[count][2] = math.floor((EP/GP)*100)/100;
								count = count + 1;
							end
						end
					end
				end
				if count > 1 then
					if critReverse then
						rRoster = tSort(rRoster, 2);
						for i = 1, table.getn(rRoster) do
							if rRoster[i][1] == arg2 then
								if string.lower(arg1) == "!infoclass" then
									if not vInfo[arg2] then
										SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank among " .. unitClass .. "s in raid: #" .. i, "WHISPER", LANGUAGE, arg2);
									else
										CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank among " .. unitClass .. "s in raid: #" .. i, "GUILD");
									end
								else
									if not vInfo[arg2] then
										SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in raid: #" .. i, "WHISPER", LANGUAGE, arg2);
									else
										CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in raid: #" .. i, "GUILD");
									end
								end
							end
						end
					else
						critReverse = true;
						rRoster = tSort(rRoster, 2);
						for i = 1, table.getn(rRoster) do
							if rRoster[i][1] == arg2 then
								if string.lower(arg1) == "!infoclass" then
									if not vInfo[arg2] then
										SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank among " .. unitClass .. "s in raid: #" .. i, "WHISPER", LANGUAGE, arg2);
									else
										CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank among " .. unitClass .. "s in raid: #" .. i, "GUILD");
									end
								else
									if not vInfo[arg2] then
										SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in raid: #" .. i, "WHISPER", LANGUAGE, arg2);
									else
										CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in raid: #" .. i, "GUILD");
									end
								end
							end
						end
						critReverse = false;
					end
				end
			end
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		roster = {};
		if CanEditOfficerNote() == 1 then
			ShowUIPanel(CEPGP_guild_add_EP);
			ShowUIPanel(CEPGP_guild_decay);
			ShowUIPanel(CEPGP_guild_reset);
			ShowUIPanel(CEPGP_raid_add_EP);
			ShowUIPanel(CEPGP_button_guild_restore);
		else --[[ Hides context sensitive options if player cannot edit officer notes ]]--
			HideUIPanel(CEPGP_guild_add_EP);
			HideUIPanel(CEPGP_guild_decay);
			HideUIPanel(CEPGP_guild_reset);
			HideUIPanel(CEPGP_raid_add_EP);
			HideUIPanel(CEPGP_button_guild_restore);
		end
		for i = 1, GetNumGuildMembers() do
			local name, rank, rankIndex, _, class, _, _, officerNote = GetGuildRosterInfo(i);
			if name then
				local EP, GP = getEPGP(officerNote);
				local PR = math.floor((EP/GP)*100)/100;
				roster[name] = {
				[1] = i,
				[2] = class,
				[3] = rank,
				[4] = rankIndex,
				[5] = officerNote,
				[6] = PR
				};
			end
		end
		if mode == "guild" then
			CEPGP_UpdateGuildScrollBar();
		elseif mode == "raid" then
			CEPGP_UpdateRaidScrollBar();
		end
	elseif event == "RAID_ROSTER_UPDATE" then
		vInfo = {};
		CEPGP_SendAddonMsg("version-check", "RAID");
		GuildRoster();
		raidRoster = {};
		for i = 1, GetNumRaidMembers() do
			local name = GetRaidRosterInfo(i);
			raidRoster[name] = name;
		end
		if UnitInRaid("player") then
			ShowUIPanel(CEPGP_button_raid);
			ShowUIPanel(CEPGP_button_loot_dist);
		else --[[ Hides the raid and loot distribution buttons if the player is not in a raid group ]]--
			HideUIPanel(CEPGP_raid);
			HideUIPanel(CEPGP_loot);
			HideUIPanel(CEPGP_button_raid);
			HideUIPanel(CEPGP_button_loot_dist);
			HideUIPanel(CEPGP_distribute_popup);
			HideUIPanel(CEPGP_context_popup);
			mode = "guild";
			ShowUIPanel(CEPGP_guild);
		end
		vInfo = {};
		CEPGP_UpdateVersionScrollBar();
		CEPGP_UpdateRaidScrollBar();
	elseif event == "CHAT_MSG_MONSTER_EMOTE" then
		if arg1 == "%s is resurrected by a nearby ally!" then
			if arg2 == "Zealot Lor'Khan" then
				THEKAL_PARAMS["LOR'KHAN_DEAD"] = false;
			elseif arg2 == "High Priest Thekal" and not (THEKAL_PARAMS["LOR'KHAN_DEAD"] or THEKAL_PARAMS["ZATH_DEAD"]) then
				THEKAL_PARAMS["THEKAL_DEAD"] = false;
			elseif arg2 == "Zealot Zath" then
				THEKAL_PARAMS["ZATH_DEAD"] = false;
			end
		
		elseif arg1 == "%s casts Destroy Egg" then
			RAZORGORE_EGG_COUNT = RAZORGORE_EGG_COUNT + 1;
			this:RegisterEvent("PLAYER_REGEN_ENABLED");
		end
		
	elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
		if not strfind(arg1, " dies") then
			return;
		else
			local name = strsub(arg1, 1, strfind(arg1, " dies")-1);
			local EP;
			local isLead;
			for i = 1, GetNumRaidMembers() do
				if UnitName("player") == GetRaidRosterInfo(i) then
					_, isLead = GetRaidRosterInfo(i);
				end
			end
			if (((GetLootMethod() == "master" and isML() == 0) or (GetLootMethod() == "group" and isLead == 2)) and ntgetn(roster) > 0) or debugMode then
				if tContains(bossNameIndex, string.lower(name), true) then --[[ If the npc is in the boss name index ]]--
					EP = EPVALS[string.lower(name)]
					if AUTOEP[string.lower(name)] then
						if name == "Lord Kri" or name == "Vem" or name == "Princess Yauj" then
							this:RegisterEvent("PLAYER_REGEN_ENABLED");
							kills = kills + 1;
							if kills == 3 then
								kills = 0;
								addRaidEP(EP, "The Bug Trio have been slain! The raid has been awarded " .. EP .. " EP");
								if STANDBYEP then
								for k, v in pairs(roster) do
									if not tContains(raidRoster, k, true) then
										local pName, rank, _, _, _, _, _, _, online = GetGuildRosterInfo(roster[k][1]);
										if (STANDBYOFFLINE and online == 1) or (not STANDBYOFFLINE and online == 1) then
											for i = 1, table.getn(STANDBYRANKS) do
												if STANDBYRANKS[i][1] == rank then
													if STANDBYRANKS[i][2] == true then
														addStandbyEP(pName, EP*(STANDBYPERCENT/100), "The Bug Trio");
													end
												end
											end
										end
									end
								end
							end
						end
						elseif name == "Emperor Vek'lor" or name == "Emperor Vek'nilash" then
							this:RegisterEvent("PLAYER_REGEN_ENABLED");
							kills = kills + 1;
							if kills == 2 then
								kills = 0;
								addRaidEP(EP, "The Twin Emperors have been slain! The raid has been awarded " .. EP .. " EP");
								if STANDBYEP then
								for k, v in pairs(roster) do
									if not tContains(raidRoster, k, true) then
										local pName, rank, _, _, _, _, _, _, online = GetGuildRosterInfo(roster[k][1]);
										if (STANDBYOFFLINE and online == 1) or (not STANDBYOFFLINE and online == 1) then
											for i = 1, table.getn(STANDBYRANKS) do
												if STANDBYRANKS[i][1] == rank then
													if STANDBYRANKS[i][2] == true then
														addStandbyEP(pName, EP*(STANDBYPERCENT/100), "The Twin Emperors");
													end
												end
											end
										end
									end
								end
							end
						end
						elseif name == "Highlord Mograine" or name == "Thane Korth'azz" or name == "Lady Blaumeux" or name == "Sir Zeliek" then
							this:RegisterEvent("PLAYER_REGEN_ENABLED");
							kills = kills + 1;
							if kills == 4 then
								kills = 0;
								addRaidEP(EP, "The Four Horsemen have been slain! The raid has been awarded " .. EP .. " EP");
								if STANDBYEP then
								for k, v in pairs(roster) do
									if not tContains(raidRoster, k, true) then
										local pName, rank, _, _, _, _, _, _, online = GetGuildRosterInfo(roster[k][1]);
										if (STANDBYOFFLINE and online == 1) or (not STANDBYOFFLINE and online == 1) then
											for i = 1, table.getn(STANDBYRANKS) do
												if STANDBYRANKS[i][1] == rank then
													if STANDBYRANKS[i][2] == true then
														addStandbyEP(pName, EP*(STANDBYPERCENT/100), "The Four Horsemen");
													end
												end
											end
										end
									end
								end
							end
						end
						elseif name == "High Priest Thekal" then
							this:RegisterEvent("PLAYER_REGEN_ENABLED");
							if THEKAL_PARAMS["THEKAL_DEAD"] then
								addRaidEP(EP, name .. " has been defeated! " .. EP .. " EP has been awarded to the raid");
								if STANDBYEP then
									for k, v in pairs(roster) do
										if not tContains(raidRoster, k, true) then
											local pName, rank, _, _, _, _, _, _, online = GetGuildRosterInfo(roster[k][1]);
											if (STANDBYOFFLINE and online == 1) or (not STANDBYOFFLINE and online == 1) then
												for i = 1, table.getn(STANDBYRANKS) do
													if STANDBYRANKS[i][1] == rank then
														if STANDBYRANKS[i][2] == true then
															addStandbyEP(pName, EP*(STANDBYPERCENT/100), name);
														end
													end
												end
											end
										end
									end
								end
							else
								THEKAL_PARAMS["THEKAL_DEAD"] = true;
							end
						elseif (name ~= "Majordomo Executus" and name ~= "Razorgore the Untamed") or (name == "Razorgore the Untamed" and RAZORGORE_EGG_COUNT == 30) then
							addRaidEP(EP, name .. " has been defeated! " .. EP .. " EP has been awarded to the raid");
							if STANDBYEP then
								for k, v in pairs(roster) do
									if not tContains(raidRoster, k, true) then
										local pName, rank, _, _, _, _, _, _, online = GetGuildRosterInfo(roster[k][1]);
										if (STANDBYOFFLINE and online == 1) or (not STANDBYOFFLINE and online == 1) then
											for i = 1, table.getn(STANDBYRANKS) do
												if STANDBYRANKS[i][1] == rank then
													if STANDBYRANKS[i][2] == true then
														addStandbyEP(pName, EP*(STANDBYPERCENT/100), name);
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
				
				if name == "Flamewaker Healer" or name == "Flamewaker Elite" then
					this:RegisterEvent("PLAYER_REGEN_ENABLED");
					kills = kills + 1;
					if kills == 8 then
						kills = 0;
						addRaidEP(EP, "Majordomo Executus has been defeated! The raid has been awarded " .. EP .. " EP");
						if STANDBYEP then
							for k, v in pairs(roster) do
								if not tContains(raidRoster, k, true) then
									local pName, rank, _, _, _, _, _, _, online = GetGuildRosterInfo(roster[k][1]);
									if (STANDBYOFFLINE and online == 1) or online == 1 then
										for i = 1, table.getn(STANDBYRANKS) do
											if STANDBYRANKS[i][1] == rank then
												if STANDBYRANKS[i][2] == true then
													addStandbyEP(pName, EP*(STANDBYPERCENT/100), name);
												end
											end
										end
									end
								end
							end
						end
					end
				elseif name == "Zealot Zath" then
					this:RegisterEvent("PLAYER_REGEN_ENABLED");
					THEKAL_PARAMS["ZATH_DEAD"] = true;
				elseif name == "Zealot Lor'Khan" then
					this:RegisterEvent("PLAYER_REGEN_ENABLED");
					THEKAL_PARAMS["LOR'KHAN_DEAD"] = true;
				end
			end
		end
		
	elseif event == "PLAYER_REGEN_ENABLED" then
		kills = 0;
		RAZORGORE_EGG_COUNT = 0;
		THEKAL_PARAMS = {["ZATH_DEAD"] = false, ["LOR'KHAN_DEAD"] = false, ["THEKAL_DEAD"] = false};
		this:UnregisterEvent("PLAYER_REGEN_ENABLED");
		
	elseif (event == "CHAT_MSG_ADDON") then
		if (arg1 == "CEPGP")then
			CEPGP_IncAddonMsg(arg2, arg4);
		end
	end
end

function CEPGP_IncAddonMsg(message, sender)
	if string.find(message, "distributing") and string.find(message, UnitName("player")) then
		local name = UnitName("player");
		local slot = string.sub(message, string.find(message, "~")+1);
		if string.len(slot) > 0 and slot ~= nil then
			local slotName = string.sub(slot, 9);
			local slotid, slotid2 = slotNameToId(slotName);
			local currentItem;
			if slotid then
				currentItem = GetInventoryItemLink("player", slotid);
			end
			local currentItem2;
			if slotid2 then
				currentItem2 = GetInventoryItemLink("player", slotid2);
			end
			local itemID;
			local itemID2;
			if currentItem then
				itemID = getItemId(getItemString(currentItem));
				itemID2 = getItemId(getItemString(currentItem2));
			else
				itemID = "noitem";
			end
			if itemID2 then
				CEPGP_SendAddonMsg(sender.."-receiving-"..itemID.." "..itemID2);
			else
				CEPGP_SendAddonMsg(sender.."-receiving-"..itemID);
			end
		elseif slot == "" then
			CEPGP_SendAddonMsg(sender.."-receiving-noslot");
		elseif itemID == "noitem" then
			CEPGP_SendAddonMsg(sender.."-receiving-noitem");
		end
	elseif string.find(message, "receiving") and string.find(message, UnitName("player")) then
		local itemID;
		local itemID2;
		if string.find(message, " ") then
			itemID = string.sub(message, string.find(message, "receiving")+10, string.find(message, " "));
			itemID2 = string.sub(message, string.find(message, " ")+1);
		else
			itemID = string.sub(message, string.find(message, "receiving")+10);
		end
		if itemID == "noitem" then
			itemsTable[sender] = {};
			CEPGP_UpdateLootScrollBar();
		elseif itemID == "noslot" then
			itemsTable[sender] = {};
			CEPGP_UpdateLootScrollBar();
		else
			local name, iString = GetItemInfo(itemID);
			if itemID2 then
				local name2, iString2 = GetItemInfo(itemID2);
				if name == nil then
					if name2 == nil then
					else
						itemsTable[sender] = {iString2 .. "[" .. name2 .. "]"};
					end
				else
					itemsTable[sender] = {iString .. "[" .. name .. "]", iString2 .. "[" .. name2 .. "]"};
				end
			else
				if name == nil then
				else
					itemsTable[sender] = {iString .. "[" .. name .. "]"};
				end
			end
			CEPGP_UpdateLootScrollBar();
		end
	elseif string.find(message, UnitName("player").."versioncheck") then
		
		if vSearch == "GUILD" then
			groupVersion[sender] = string.sub(message, string.find(message, " ")+1);
		else
			groupVersion[sender] = string.sub(message, string.find(message, " ")+1);
			vInfo[sender] = string.sub(message, string.find(message, " ")+1);
		end
		CEPGP_UpdateVersionScrollBar();
	elseif message == "version-check" then
		GuildRoster();
		if roster[sender] then
			CEPGP_SendAddonMsg(sender .. "versioncheck " .. VERSION, "GUILD");
		else
			CEPGP_SendAddonMsg(sender .. "versioncheck " .. VERSION, "RAID");
		end
	elseif string.find(message, "version") then
		local s1, s2, s3, s4 = CEPGP_strSplit(message, "-");
		if s1 == "update" then
			GuildRoster();
		elseif s1 == "version" then
			local ver2 = string.gsub(VERSION, "%.", ",");
			local v1, v2, v3 = CEPGP_strSplit(ver2..",", ",");
			local nv1, nv2, nv3 = CEPGP_strSplit(s2, ",");
			local s5 = (nv1.."."..nv2.."."..nv3)
			outMessage = "Your addon is out of date. Version " .. s5 .. " is now available for download at https://github.com/Alumian/CEPGP"
			if v1 > v1 then
				CEPGP_print(outMessage);
			elseif nv1 == v1 and nv2 > v2 then
				CEPGP_print(outMessage);
			elseif nv1 == v1 and nv2 == v2 and nv3 > v3 then
				CEPGP_print(outMessage);
			end
		end
	elseif string.find(message, "RaidAssistLoot") and sender ~= UnitName("player") then
		if string.find(message, "RaidAssistLootDist") then
			local link = string.sub(message, 19, string.find(message, ",")-1);
			local gp = string.sub(message, string.find(message, ",")+1, string.find(message, "\\")-1);
			RaidAssistLootDist(link, gp);
		else
			RaidAssistLootClosed();
		end
	elseif string.find(message, "!need") and IsRaidOfficer() and sender ~= UnitName("player") then
		local arg2 = string.sub(message, string.find(message, ",")+1);
		table.insert(responses, arg2);
		local slot = nil;
		if distID then
			_, _, _, _, _, _, _, slot = GetItemInfo(distID);
		end
		GuildRoster();
		if slot then
			CEPGP_SendAddonMsg(arg2.."-distributing-"..distID.."~"..distSlot);
		else
			CEPGP_SendAddonMsg(arg2.."-distributing-nil~nil");
		end
	elseif string.find(message, "STANDBYEP"..UnitName("player")) then
		CEPGP_print(string.sub(message, string.find(message, ",")+1));
	elseif string.find(message, "!info"..UnitName("player")) then
		CEPGP_print(string.sub(message, 5+string.len(UnitName("player"))+1));
	elseif message == UnitName("player").."-import" then
		local lane;
		if raidRoster[arg4] then
			lane = "RAID";
		elseif roster[arg4] then
			lane = "GUILD";
		end
		CEPGP_SendAddonMsg(arg4.."-impresponse!CHANNEL~"..CHANNEL, lane);
		CEPGP_SendAddonMsg(arg4.."-impresponse!MOD~"..MOD, lane);
		CEPGP_SendAddonMsg(arg4.."-impresponse!COEF~"..COEF, lane);
		CEPGP_SendAddonMsg(arg4.."-impresponse!BASEGP~"..BASEGP, lane);
		if STANDBYEP then
			CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYEP~1", lane);
		else
			CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYEP~0", lane);
		end
		if STANDBYOFFLINE then
			CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYOFFLINE~1", lane);
		else
			CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYOFFLINE~0", lane);
		end
		CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYPERCENT~"..STANDBYPERCENT, lane);
		for k, v in pairs(SLOTWEIGHTS) do
			CEPGP_SendAddonMsg(arg4.."-impresponse!SLOTWEIGHTS~"..k.."?"..v, lane);
		end
		for k, v in pairs(STANDBYRANKS) do
			if STANDBYRANKS[k][2] then
				CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYRANKS~"..k.."?1", lane);
			else
				CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYRANKS~"..k.."?0", lane);
			end
		end
		for k, v in pairs(EPVALS) do
			CEPGP_SendAddonMsg(arg4.."-impresponse!EPVALS~"..k.."?"..v, lane);
		end
		for k, v in pairs(AUTOEP) do
			if AUTOEP[k] then
				CEPGP_SendAddonMsg(arg4.."-impresponse!AUTOEP~"..k.."?1", lane);
			else
				CEPGP_SendAddonMsg(arg4.."-impresponse!AUTOEP~"..k.."?0", lane);
			end
		end
		for k, v in pairs(OVERRIDE_INDEX) do
			CEPGP_SendAddonMsg(arg4.."-impresponse!OVERRIDE~"..k.."?"..v, lane);
		end
		CEPGP_SendAddonMsg(arg4.."-impresponse!COMPLETE~", lane);
		
	elseif string.find(message, UnitName("player")) and string.find(message, "-impresponse!") then
		local option = string.sub(message, string.find(message, "!")+1, string.find(message, "~")-1);
		
		if option == "SLOTWEIGHTS" or option == "STANDBYRANKS" or option == "EPVALS" or option == "AUTOEP" or option == "OVERRIDE" then
			local field = string.sub(message, string.find(message, "~")+1, string.find(message, "?")-1);
			local val = string.sub(message, string.find(message, "?")+1);
			if option == "SLOTWEIGHTS" then
				SLOTWEIGHTS[field] = val;
			elseif option == "STANDBYRANKS" then
				if val == "1" then
					STANDBYRANKS[tonumber(field)][2] = true;
				else
					STANDBYRANKS[tonumber(field)][2] = false;
				end
			elseif option == "EPVALS" then
				EPVALS[field] = val;
			elseif option == "AUTOEP" then
				if val == "1" then
					AUTOEP[field] = true;
				else
					AUTOEP[field] = false;
				end
			elseif option == "OVERRIDE" then
				OVERRIDE_INDEX[field] = val;
			end
		else
			local val = string.sub(message, string.find(message, "~")+1);
			if option == "CHANNEL" then
				CHANNEL = val;
			elseif option == "MOD" then
				MOD = tonumber(val);
			elseif option == "COEF" then
				COEF = tonumber(val);
			elseif option == "BASEGP" then
				BASEGP = tonumber(val);
			elseif option == "STANDBYEP" then
				if tonumber(val) == 1 then
					STANDBYEP = true;
				else
					STANDBYEP = false;
				end
			elseif option == "STANDBYOFFLINE" then
				if tonumber(val) == 1 then
					STANDBYOFFLINE = true;
				else
					STANDBYOFFLINE = false;
				end
			elseif option == "STANDBYPERCENT" then
				STANDBYPERCENT = tonumber(val);		
			elseif option == "COMPLETE" then
				CEPGP_UpdateOverrideScrollBar();
				CEPGP_print("Import complete");
			end
		end
		
		CEPGP_options_mod_edit:SetText(tostring(MOD));
		CEPGP_options_coef_edit:SetText(tostring(COEF));
		CEPGP_options_gp_base_edit:SetText(tostring(BASEGP));
		if STANDBYEP then
			CEPGP_options_standby_ep_check:SetChecked(true);
		else
			CEPGP_options_standby_ep_check:SetChecked(false);
		end
		CEPGP_options_standby_ep_val:SetText(tostring(STANDBYPERCENT));
		for i = 1, 10 do
			if not GuildControlGetRankName(i) then
				STANDBYRANKS[i][1] = nil;
			else
				STANDBYRANKS[i][1] = GuildControlGetRankName(i);
			end
		end
		for i = 1, 10 do
			if STANDBYRANKS[i][1] ~= nil then
				getglobal("CEPGP_options_standby_ep_rank_"..i):Show();
				getglobal("CEPGP_options_standby_ep_rank_"..i):SetText(tostring(STANDBYRANKS[i][1]));
				getglobal("CEPGP_options_standby_ep_check_rank_"..i):Show();
				if STANDBYRANKS[i][2] == true then
					getglobal("CEPGP_options_standby_ep_check_rank_"..i):SetChecked(true);
				else
					getglobal("CEPGP_options_standby_ep_check_rank_"..i):SetChecked(false);
				end
			end
			if GuildControlGetRankName(i) == nil then
				getglobal("CEPGP_options_standby_ep_rank_"..i):Hide();
				getglobal("CEPGP_options_standby_ep_check_rank_"..i):Hide();
				getglobal("CEPGP_options_standby_ep_check_rank_"..i):SetChecked(false);
			end
		end
		if STANDBYEP then
			getglobal("CEPGP_options_standby_ep_check"):SetChecked(true);
		else
			getglobal("CEPGP_options_standby_ep_check"):SetChecked(false);
		end
		if STANDBYOFFLINE then
			getglobal("CEPGP_options_standby_ep_offline_check"):SetChecked(true);
		else
			getglobal("CEPGP_options_standby_ep_offline_check"):SetChecked(false);
		end
		CEPGP_options_standby_ep_val:SetText(tostring(STANDBYPERCENT));
		for k, v in pairs(SLOTWEIGHTS) do
			if k ~= "ROBE" and k ~= "WEAPON" then
				getglobal("CEPGP_options_" .. k .. "_weight"):SetText(tonumber(SLOTWEIGHTS[k]));
			end
		end
	end
end

function CEPGP_SendAddonMsg(message, channel)
	if channel ~= nil then
		SendAddonMessage("CEPGP", message, string.upper(channel));
	else
		SendAddonMessage("CEPGP", message, "RAID");
	end
end

function CEPGP_UpdateLootScrollBar()
    local y;
    local yoffset;
    local t;
    local tSize;
    local name;
	local class;
	local rank;
	local EP;
	local GP;
	local offNote;
	local colour;
    t = {};
    tSize = table.getn(responses);
	GuildRoster();
	for x = 1, tSize do
		name = responses[x]
		if debugMode and not UnitInRaid("player") then
			class = UnitClass("player");
		end
		for i = 1, GetNumRaidMembers() do
			if name == GetRaidRosterInfo(i) then
				_, _, _, _, class = GetRaidRosterInfo(i);
			end
		end
		if tContains(roster, name, true) then
			rank = roster[name][3];
			rankIndex = roster[name][4];
			offNote = roster[name][5];
			EP, GP = getEPGP(offNote);
			PR = roster[name][6];
		end
		if not rank then
			rank = "Not in Guild";
			rankIndex = 10;
			EP = 0;
			GP = BASEGP;
			PR = 0;
		end
		t[x] = {
			[1] = name,
			[2] = class,
			[3] = rank,
			[4] = rankIndex,
			[5] = EP,
			[6] = GP,
			[7] = PR
			}
		rank = nil;
	end
	t = tSort(t, criteria)
    FauxScrollFrame_Update(DistributeScrollFrame, tSize, 18, 120);
    for y = 1, 18, 1 do
        yoffset = y + FauxScrollFrame_GetOffset(DistributeScrollFrame);
        if (yoffset <= tSize) then
            if not tContains(t, yoffset, true) then
                getglobal("LootDistButton" .. y):Hide();
            else
				name = t[yoffset][1];
				class = t[yoffset][2];
				rank = t[yoffset][3];
				EP = t[yoffset][5];
				GP = t[yoffset][6];
				PR = t[yoffset][7];
				local iString = nil;
				local iString2 = nil;
				local tex = nil;
				local tex2 = nil;
				if itemsTable[name]then
					if itemsTable[name][1] ~= nil then
						iString = itemsTable[name][1].."|r";
						_, _, _, _, _, _, _, _, tex = GetItemInfo(iString);
						if itemsTable[name][2] ~= nil then
							iString2 = itemsTable[name][2].."|r";
							_, _, _, _, _, _, _, _, tex2 = GetItemInfo(iString2);
						end
					end
				end
				if class then
					colour = RAID_CLASS_COLORS[string.upper(class)];
				else
					colour = RAID_CLASS_COLORS["WARRIOR"];
				end
				tex = {bgFile = tex,};
				tex2 = {bgFile = tex2,};
				getglobal("LootDistButton" .. y):Show();
                getglobal("LootDistButton" .. y .. "Info"):SetText(name);
                getglobal("LootDistButton" .. y .. "Info"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("LootDistButton" .. y .. "Class"):SetText(class);
                getglobal("LootDistButton" .. y .. "Class"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("LootDistButton" .. y .. "Rank"):SetText(rank);
                getglobal("LootDistButton" .. y .. "Rank"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("LootDistButton" .. y .. "EP"):SetText(EP);
                getglobal("LootDistButton" .. y .. "EP"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("LootDistButton" .. y .. "GP"):SetText(GP);
                getglobal("LootDistButton" .. y .. "GP"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("LootDistButton" .. y .. "PR"):SetText(math.floor((EP/GP)*100)/100);
                getglobal("LootDistButton" .. y .. "PR"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("LootDistButton" .. y .. "Tex"):SetBackdrop(tex);
				getglobal("LootDistButton" .. y .. "Tex2"):SetBackdrop(tex2);
				getglobal("LootDistButton" .. y .. "Tex"):SetScript('OnLeave', function()
																		GameTooltip:Hide()
																	end);
				getglobal("LootDistButton" .. y .. "Tex2"):SetScript('OnLeave', function()
																		GameTooltip:Hide()
																	end);
				if iString then
					getglobal("LootDistButton" .. y .. "Tex"):SetScript('OnEnter', function()	
																			GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
																			GameTooltip:SetHyperlink(iString)
																			GameTooltip:Show()
																		end);
					if iString2 then
						getglobal("LootDistButton" .. y .. "Tex2"):SetScript('OnEnter', function()	
														GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
														GameTooltip:SetHyperlink(iString2)
														GameTooltip:Show()
													end);				
					else
						getglobal("LootDistButton" .. y .. "Tex2"):SetScript('OnEnter', function() end);
					end
				
				else
					getglobal("LootDistButton" .. y .. "Tex"):SetScript('OnEnter', function() end);
				end
			end
        else
            getglobal("LootDistButton" .. y):Hide();
        end
    end
end

function CEPGP_UpdateGuildScrollBar()
    local x, y;
    local yoffset;
    local t;
    local tSize;
    local name;
	local class;
	local rank;
	local EP;
	local GP;
	local offNote;
	local colour;
    t = {};
	tSize = ntgetn(roster);
	for x = 1, tSize do
		name = indexToName(x);
		index, class, rank, rankIndex, offNote = getGuildInfo(name);
		EP, GP = getEPGP(offNote)
		t[x] = {
			[1] = name,
			[2] = class,
			[3] = rank,
			[4] = rankIndex,
			[5] = EP,
			[6] = GP,
			[7] = math.floor((EP/GP)*100)/100,
			[8] = 0
		}
	end
	t = tSort(t, criteria)
    FauxScrollFrame_Update(GuildScrollFrame, tSize, 18, 240);
    for y = 1, 18, 1 do
        yoffset = y + FauxScrollFrame_GetOffset(GuildScrollFrame);
        if (yoffset <= tSize) then
		    if not tContains(t, yoffset, true) then
                getglobal("GuildButton" .. y):Hide();
            else
				name = t[yoffset][1]
				class = t[yoffset][2];
				rank = t[yoffset][3];
				EP = t[yoffset][5];
				GP = t[yoffset][6];
				PR = t[yoffset][7];
				if class then
					colour = RAID_CLASS_COLORS[string.upper(class)];
				else
					colour = RAID_CLASS_COLORS["WARRIOR"];
				end
				getglobal("GuildButton" .. y .. "Info"):SetText(name);
				getglobal("GuildButton" .. y .. "Info"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("GuildButton" .. y .. "Class"):SetText(class);
				getglobal("GuildButton" .. y .. "Class"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("GuildButton" .. y .. "Rank"):SetText(rank);
				getglobal("GuildButton" .. y .. "Rank"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("GuildButton" .. y .. "EP"):SetText(EP);
				getglobal("GuildButton" .. y .. "EP"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("GuildButton" .. y .. "GP"):SetText(GP);
				getglobal("GuildButton" .. y .. "GP"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("GuildButton" .. y .. "PR"):SetText(PR);
				getglobal("GuildButton" .. y .. "PR"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("GuildButton" .. y):Show();
			end
		else
			getglobal("GuildButton" .. y):Hide();
		end
    end
end

function CEPGP_UpdateRaidScrollBar()
    local x, y;
    local yoffset;
    local t;
    local tSize;
	local group;
    local name;
	local rank;
	local EP;
	local GP;
	local offNote;
	local colour;
	t = {};
    tSize = GetNumRaidMembers();
	for x = 1, tSize do
		name, _, group, _, class = GetRaidRosterInfo(x);
		local a = getGuildInfo(name);
		if tContains(roster, name, true) then
			rank = roster[name][3];
			rankIndex = roster[name][4];
			offNote = roster[name][5];
			EP, GP = getEPGP(offNote);
			PR = roster[name][6];
		end
		if not roster[name] then
			rank = "Not in Guild";
			rankIndex = 10;
			EP = 0;
			GP = BASEGP;
			PR = 0;
		end
		t[x] = {
			[1] = name,
			[2] = class,
			[3] = rank,
			[4] = rankIndex,
			[5] = EP,
			[6] = GP,
			[7] = PR,
			[8] = group
		}
	end
	t = tSort(t, criteria)
    FauxScrollFrame_Update(RaidScrollFrame, tSize, 18, 240);
    for y = 1, 18, 1 do
        yoffset = y + FauxScrollFrame_GetOffset(RaidScrollFrame);
        if (yoffset <= tSize) then
            if not tContains(t, yoffset, true) then
                getglobal("RaidButton" .. y):Hide();
            else
				t2 = t[yoffset];
				name = t2[1];
				class = t2[2];
				rank = t2[3];
				EP = t2[5];
				GP = t2[6];
				PR = t2[7];
				group = t2[8];
				if class then
					colour = RAID_CLASS_COLORS[string.upper(class)];
				else
					colour = RAID_CLASS_COLORS["WARRIOR"];
				end
				getglobal("RaidButton" .. y .. "Group"):SetText(group);
				getglobal("RaidButton" .. y .. "Group"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("RaidButton" .. y .. "Info"):SetText(name);
				getglobal("RaidButton" .. y .. "Info"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("RaidButton" .. y .. "Rank"):SetText(rank);
				getglobal("RaidButton" .. y .. "Rank"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("RaidButton" .. y .. "EP"):SetText(EP);
				getglobal("RaidButton" .. y .. "EP"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("RaidButton" .. y .. "GP"):SetText(GP);
				getglobal("RaidButton" .. y .. "GP"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("RaidButton" .. y .. "PR"):SetText(PR);
				getglobal("RaidButton" .. y .. "PR"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("RaidButton" .. y):Show();
			end
        else
            getglobal("RaidButton" .. y):Hide();
        end
    end
end

function CEPGP_UpdateVersionScrollBar()
	local x, y;
	local yoffset;
	local t;
	local tSize;
	local name;
	local colour;
	local version;
	local online;
	t = {};
	if vSearch == "GUILD" then
		tSize = GetNumGuildMembers();
	else
		tSize = GetNumRaidMembers();
	end
	if tSize == 0 then
		for y = 1, 18, 1 do
			getglobal("versionButton" .. y):Hide();
		end
	end
	if vSearch == "GUILD" then
		for x = 1, tSize do
			name, _, _, _, class, _, _, _, online = GetGuildRosterInfo(x);
			t[x] = {
				[1] = name,
				[2] = class,
				[3] = online
			}
		end
	else
		for x = 1, tSize do
			name, _, group, _, class, _, _, online = GetRaidRosterInfo(x);
			t[x] = {
				[1] = name,
				[2] = class,
				[3] = online
			}
		end
	end
	FauxScrollFrame_Update(VersionScrollFrame, tSize, 18, 240);
	for y = 1, 18, 1 do
		yoffset = y + FauxScrollFrame_GetOffset(VersionScrollFrame);
		if (yoffset <= tSize) then
			if not tContains(t, yoffset, true) then
				getglobal("versionButton" .. y):Hide();
			else
				t2 = t[yoffset];
				name = t2[1];
				class = t2[2];
				online = t2[3];
				if groupVersion[name] then
					version = groupVersion[name];
				elseif online == 1 then
					version = "Addon not running";
				else
					version = "Offline";
				end
				if class then
					colour = RAID_CLASS_COLORS[string.upper(class)];
				else
					colour = RAID_CLASS_COLORS["WARRIOR"];
				end
				getglobal("versionButton" .. y .. "name"):SetText(name);
				getglobal("versionButton" .. y .. "name"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("versionButton" .. y .. "version"):SetText(version);
				getglobal("versionButton" .. y .. "version"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("versionButton" .. y):Show();
			end
		else
			getglobal("versionButton" .. y):Hide();
		end
	end
end

function CEPGP_UpdateOverrideScrollBar()
	if OVERRIDE_INDEX == nil then
		return;
	end
    local x, y;
    local yoffset;
    local t;
    local tSize;
    local item;
	local gp;
	local colour;
	local quality;
	t = {};
    tSize = ntgetn(OVERRIDE_INDEX);
	if tSize == 0 then
		for y = 1, 18, 1 do
			getglobal("overrideButton" .. y):Hide();
		end
	end
	local count = 1;
	for k, v in pairs(OVERRIDE_INDEX) do
		t[count] = {
			[1] = k,
			[2] = v
		};
		count = count + 1;
	end
    FauxScrollFrame_Update(overrideScrollFrame, tSize, 18, 240);
    for y = 1, 18, 1 do
        yoffset = y + FauxScrollFrame_GetOffset(overrideScrollFrame);
        if (yoffset <= tSize) then
            if not tContains(t, yoffset, true) then
                getglobal("overrideButton" .. y):Hide();
            else
				t2 = t[yoffset];
				item = t2[1];
				gp = t2[2];
				quality = t2[3];
				getglobal("overrideButton" .. y .. "item"):SetText(item);
				getglobal("overrideButton" .. y .. "item"):SetTextColor(1, 1, 1);
				getglobal("overrideButton" .. y .. "GP"):SetText(gp);
				getglobal("overrideButton" .. y .. "GP"):SetTextColor(1, 1, 1);
				getglobal("overrideButton" .. y):Show();
			end
        else
            getglobal("overrideButton" .. y):Hide();
        end
    end
end

function CEPGP_ListButton_OnClick()
	obj = this:GetName();
		
	if strfind(obj, "Delete") then
		local name = getglobal("overrideButton" .. this:GetParent():GetID() .. "item"):GetText();
		OVERRIDE_INDEX[name] = nil;
		CEPGP_print(name .. " removed from GP override");
		CEPGP_UpdateOverrideScrollBar();
		return;
	end
	
	if CanEditOfficerNote() == nil and not debugMode then
		CEPGP_print("You don't have access to modify EPGP", 1);
		return;
	end
	
	--[[ Distribution Menu ]]--
	if strfind(obj, "LootDistButton") then --A player in the distribution menu is clicked
		ShowUIPanel(CEPGP_distribute_popup);
		CEPGP_distribute_popup_title:SetText(getglobal(this:GetName() .. "Info"):GetText());
		distPlayer = getglobal(this:GetName() .. "Info"):GetText();
		CEPGP_distribute_popup:SetID(CEPGP_distribute:GetID()); --CEPGP_distribute:GetID gets the ID of the LOOT SLOT. Not the player.
	
		--[[ Guild Menu ]]--
	elseif strfind(obj, "GuildButton") then --A player from the guild menu is clicked (awards EP)
		local name = getglobal(this:GetName() .. "Info"):GetText();
		ShowUIPanel(CEPGP_context_popup);
		ShowUIPanel(CEPGP_context_amount);
		ShowUIPanel(CEPGP_context_popup_EP_check);
		ShowUIPanel(CEPGP_context_popup_GP_check);
		ShowUIPanel(CEPGP_context_popup_EP_check_text);
		ShowUIPanel(CEPGP_context_popup_GP_check_text);
		CEPGP_context_popup_EP_check:SetChecked(1);
		CEPGP_context_popup_GP_check:SetChecked(nil);
		CEPGP_context_popup_header:SetText("Guild Moderation");
		CEPGP_context_popup_title:SetText("Add EP/GP to " .. name);
		CEPGP_context_popup_desc:SetText("Adding EP");
		CEPGP_context_amount:SetText("0");
		CEPGP_context_amount:SetNumeric(true);
		CEPGP_context_popup_confirm:SetScript('OnClick', function()
															PlaySound("gsTitleOptionExit");
															HideUIPanel(CEPGP_context_popup);
															if CEPGP_context_popup_EP_check:GetChecked() then
																addEP(name, tonumber(CEPGP_context_amount:GetText()));
															else
																addGP(name, tonumber(CEPGP_context_amount:GetText()));
															end
														end);
		
	elseif strfind(obj, "CEPGP_guild_add_EP") then --Click the Add Guild EP button in the Guild menu
		ShowUIPanel(CEPGP_context_popup);
		ShowUIPanel(CEPGP_context_amount);
		ShowUIPanel(CEPGP_context_popup_EP_check);
		HideUIPanel(CEPGP_context_popup_GP_check);
		ShowUIPanel(CEPGP_context_popup_EP_check_text);
		HideUIPanel(CEPGP_context_popup_GP_check_text);
		CEPGP_context_popup_EP_check:SetChecked(1);
		CEPGP_context_popup_GP_check:SetChecked(nil);
		CEPGP_context_popup_header:SetText("Guild Moderation");
		CEPGP_context_popup_title:SetText("Add Guild EP");
		CEPGP_context_popup_desc:SetText("Adds EP to all guild members");
		CEPGP_context_amount:SetText("0");
		CEPGP_context_amount:SetNumeric(true);
		CEPGP_context_popup_confirm:SetScript('OnClick', function()
															PlaySound("gsTitleOptionExit");
															HideUIPanel(CEPGP_context_popup);
															addGuildEP(tonumber(CEPGP_context_amount:GetText()));
														end);
	
	elseif strfind(obj, "CEPGP_guild_decay") then --Click the Decay Guild EPGP button in the Guild menu
		ShowUIPanel(CEPGP_context_popup);
		ShowUIPanel(CEPGP_context_amount);
		HideUIPanel(CEPGP_context_popup_EP_check);
		HideUIPanel(CEPGP_context_popup_GP_check);
		HideUIPanel(CEPGP_context_popup_EP_check_text);
		HideUIPanel(CEPGP_context_popup_GP_check_text);
		CEPGP_context_popup_EP_check:SetChecked(nil);
		CEPGP_context_popup_GP_check:SetChecked(nil);
		CEPGP_context_popup_header:SetText("Guild Moderation");
		CEPGP_context_popup_title:SetText("Decay Guild EPGP");
		CEPGP_context_popup_desc:SetText("Decays EPGP standings by a percentage\nValid Range: 0-100");
		CEPGP_context_amount:SetText("0");
		CEPGP_context_amount:SetNumeric(true);
		CEPGP_context_popup_confirm:SetScript('OnClick', function()
															PlaySound("gsTitleOptionExit");
															HideUIPanel(CEPGP_context_popup);
															decay(tonumber(CEPGP_context_amount:GetText()));
														end);
		
	elseif strfind(obj, "CEPGP_guild_reset") then --Click the Reset All EPGP Standings button in the Guild menu
		ShowUIPanel(CEPGP_context_popup);
		HideUIPanel(CEPGP_context_amount);
		HideUIPanel(CEPGP_context_popup_EP_check);
		HideUIPanel(CEPGP_context_popup_GP_check);
		HideUIPanel(CEPGP_context_popup_EP_check_text);
		HideUIPanel(CEPGP_context_popup_GP_check_text);
		CEPGP_context_popup_EP_check:SetChecked(nil);
		CEPGP_context_popup_GP_check:SetChecked(nil);
		CEPGP_context_popup_header:SetText("Guild Moderation");
		CEPGP_context_popup_title:SetText("Reset Guild EPGP");
		CEPGP_context_popup_desc:SetText("Resets the Guild EPGP standings\n|c00FF0000Are you sure this is what you want to do?\nThis cannot be reversed!\nNote: This will report to Guild chat|r");
		CEPGP_context_popup_confirm:SetScript('OnClick', function()
															PlaySound("gsTitleOptionExit");
															HideUIPanel(CEPGP_context_popup);
															resetAll();
														end);
		
		--[[ Raid Menu ]]--
	elseif strfind(obj, "RaidButton") then --A player from the raid menu is clicked (awards EP)
		local name = getglobal(this:GetName() .. "Info"):GetText();
		if not getGuildInfo(name) then
			CEPGP_print(name .. " is not a guild member - Cannot award EP or GP", true);
			return;
		end
		ShowUIPanel(CEPGP_context_popup);
		ShowUIPanel(CEPGP_context_amount);
		ShowUIPanel(CEPGP_context_popup_EP_check);
		ShowUIPanel(CEPGP_context_popup_GP_check);
		ShowUIPanel(CEPGP_context_popup_EP_check_text);
		ShowUIPanel(CEPGP_context_popup_GP_check_text);
		CEPGP_context_popup_EP_check:SetChecked(1);
		CEPGP_context_popup_GP_check:SetChecked(nil);
		CEPGP_context_popup_header:SetText("Raid Moderation");
		CEPGP_context_popup_title:SetText("Add EP/GP to " .. name);
		CEPGP_context_popup_desc:SetText("Adding EP");
		CEPGP_context_amount:SetText("0");
		CEPGP_context_amount:SetNumeric(true);
		CEPGP_context_popup_confirm:SetScript('OnClick', function()
															PlaySound("gsTitleOptionExit");
															HideUIPanel(CEPGP_context_popup);
															if CEPGP_context_popup_EP_check:GetChecked() then
																addEP(name, tonumber(CEPGP_context_amount:GetText()));
															else
																addGP(name, tonumber(CEPGP_context_amount:GetText()));
															end
														end);
	
	elseif strfind(obj, "CEPGP_raid_add_EP") then --Click the Add Raid EP button in the Raid menu
		ShowUIPanel(CEPGP_context_popup);
		ShowUIPanel(CEPGP_context_amount);
		HideUIPanel(CEPGP_context_popup_EP_check);
		HideUIPanel(CEPGP_context_popup_GP_check);
		HideUIPanel(CEPGP_context_popup_EP_check_text);
		HideUIPanel(CEPGP_context_popup_GP_check_text);
		CEPGP_context_popup_EP_check:SetChecked(nil);
		CEPGP_context_popup_GP_check:SetChecked(nil);
		CEPGP_context_popup_header:SetText("Raid Moderation");
		CEPGP_context_popup_title:SetText("Award Raid EP");
		CEPGP_context_popup_desc:SetText("Adds an amount of EP to the entire raid");
		CEPGP_context_amount:SetText("0");
		CEPGP_context_amount:SetNumeric(true);
		CEPGP_context_popup_confirm:SetScript('OnClick', function()
															PlaySound("gsTitleOptionExit");
															HideUIPanel(CEPGP_context_popup);
															addRaidEP(tonumber(CEPGP_context_amount:GetText()));
														end);
	else
		--CEPGP_print(obj);
	end
end

function CEPGP_distribute_popup_give()
	for i = 1, 40 do
		if GetMasterLootCandidate(i) == distPlayer then
			GiveMasterLoot(lootSlot, i);
		end
	end
end

function CEPGP_distribute_popup_OnEvent(event)
	if event == "UI_ERROR_MESSAGE" and arg1 == "Inventory is full." and distPlayer ~= "" then
		CEPGP_print(distPlayer .. "'s inventory is full", 1);
		CEPGP_distribute_popup:Hide();
	elseif event == "UI_ERROR_MESSAGE" and arg1 == "You can't carry any more of those items." and distPlayer ~= "" then
		CEPGP_print(distPlayer .. " can't carry any more of this unique item", 1);
		CEPGP_distribute_popup:Hide();
	elseif event == "LOOT_SLOT_CLEARED" and arg1 == lootSlot and distPlayer ~= "" and distributing then
		distributing = false;
		if distGP then
			SendChatMessage("Awarded " .. getglobal("CEPGP_distribute_item_name"):GetText() .. " to ".. distPlayer .. " for " .. CEPGP_distribute_GP_value:GetText() .. " GP", CHANNEL, LANGUAGE);
			addGP(distPlayer, CEPGP_distribute_GP_value:GetText(), true);
		else
			SendChatMessage("Awarded " .. getglobal("CEPGP_distribute_item_name"):GetText() .. " to ".. distPlayer .. " for free", CHANNEL, LANGUAGE);
		end
		CEPGP_distribute_popup:Hide();
		CEPGP_distribute:Hide();
		CEPGP_loot:Show();
	elseif event == "LOOT_SLOT_CLEARED" and arg1 == lootSlot and distPlayer == "" and distributing then
		distributing = false;
		SendChatMessage(getglobal("CEPGP_distribute_item_name"):GetText() .. " has been distributed without EPGP", CHANNEL, LANGUAGE);
		CEPGP_distribute_popup:Hide();
		CEPGP_distribute:Hide();
		CEPGP_loot:Show();
	end
end

--[[getEPGP(Officer Note) - Working as intended
	returns EP and GP
	]]
function getEPGP(offNote)
	if not offNote or not checkEPGP then
		return 0, BASEGP;
	end
	local EP, GP = nil;
	if not checkEPGP(offNote) then
		return 0, BASEGP;
	end
	EP = tonumber(strsub(offNote, 1, strfind(offNote, ",")-1));
	GP = tonumber(strsub(offNote, strfind(offNote, ",")+1, string.len(offNote)));
	return EP, GP;
end

function ChatFrame_OnEvent(event, msg)
	CFEvent(event);
end

function LootFrame_OnEvent(event)
	if not pfUI then
		LFEvent(event);
	end
	if event == "LOOT_CLOSED" then
		distributing = false;
		if mode == "loot" then
			cleanTable();
			if isML() == 0 then
				CEPGP_SendAddonMsg("RaidAssistLootClosed");
			end
		end
		HideUIPanel(CEPGP_distribute_popup);
		HideUIPanel(CEPGP_loot_distributing);
		--HideUIPanel(CEPGP_button_loot_dist);
		HideUIPanel(CEPGP_loot);
		HideUIPanel(CEPGP_distribute);
		HideUIPanel(CEPGP_loot_distributing);
		if UnitInRaid("player") then
			toggleFrame(CEPGP_raid);
		elseif GetGuildRosterInfo(1) then
			toggleFrame(CEPGP_guild);
		else
			HideUIPanel(CEPGP_frame);
			if isML() == 0 then
				CEPGP_loot_distributing:Hide();
			end
		end
		
		if CEPGP_distribute:IsVisible() == 1 then
			HideUIPanel(CEPGP_distribute);
			ShowUIPanel(CEPGP_loot);
			responses = {};
			CEPGP_UpdateLootScrollBar();
		end
		
	elseif event == "LOOT_OPENED" and (UnitInRaid("player") or debugMode) then
		LootFrame_Update();
		ShowUIPanel(CEPGP_button_loot_dist);
	
	elseif event == "LOOT_SLOT_CLEARED" then
		if isML() == 0 then
			CEPGP_SendAddonMsg("RaidAssistLootClosed");
		end
		LootFrame_Update();
	end
end

function RaidAssistLootClosed()
	if IsRaidOfficer() and isML() == 1 then
		HideUIPanel(CEPGP_distribute_popup);
		HideUIPanel(CEPGP_distribute);
		HideUIPanel(CEPGP_loot_distributing);
		for y = 1, 18 do
			getglobal("LootDistButton"..y):Hide();
			getglobal("LootDistButton" .. y .. "Info"):SetText("");
			getglobal("LootDistButton" .. y .. "Class"):SetText("");
			getglobal("LootDistButton" .. y .. "Rank"):SetText("");
			getglobal("LootDistButton" .. y .. "EP"):SetText("");
			getglobal("LootDistButton" .. y .. "GP"):SetText("");
			getglobal("LootDistButton" .. y .. "PR"):SetText("");
			getglobal("LootDistButton" .. y .. "Tex"):SetBackdrop(nil);
			getglobal("LootDistButton" .. y .. "Tex2"):SetBackdrop(nil);
		end
	end
end

function RaidAssistLootDist(link, gp)
	if IsRaidOfficer() and isML() == 1 then
		local y = 1;
		for y = 1, 18 do
			getglobal("LootDistButton"..y):Hide();
			getglobal("LootDistButton" .. y .. "Info"):SetText("");
			getglobal("LootDistButton" .. y .. "Class"):SetText("");
			getglobal("LootDistButton" .. y .. "Rank"):SetText("");
			getglobal("LootDistButton" .. y .. "EP"):SetText("");
			getglobal("LootDistButton" .. y .. "GP"):SetText("");
			getglobal("LootDistButton" .. y .. "PR"):SetText("");
			getglobal("LootDistButton" .. y .. "Tex"):SetBackdrop(nil);
			getglobal("LootDistButton" .. y .. "Tex2"):SetBackdrop(nil);
			y = y + 1;
		end
		itemsTable = {};
		local name, iString, _, _, _, _, _, slot, tex = GetItemInfo(getItemString(link));
		distID = getItemId(iString);
		distSlot = slot;
		if not distID then
			CEPGP_print("Item not found in game cache. You must see the item in-game before item info can be retrieved and CEPGP will not be able to retrieve what items recipients are wearing in that slot", true);
		end
		tex = {bgFile = tex,};
		

		responses = {};
		ShowUIPanel(CEPGP_loot_distributing);
		_G["CEPGP_distribute_item_name"]:SetText(link);
		if iString then
			_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function() GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT") GameTooltip:SetHyperlink(iString) GameTooltip:Show() end);
			_G["CEPGP_distribute_item_tex"]:SetBackdrop(tex);
			_G["CEPGP_distribute_item_name_frame"]:SetScript('OnClick', function() SetItemRef(iString) end);
		else
			_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function() end);
		end
		_G["CEPGP_distribute_item_tex"]:SetScript('OnLeave', function() GameTooltip:Hide() end);
		_G["CEPGP_distribute_GP_value"]:SetText(gp);
	end
end

function LootFrame_Update()
	if pfUI then
		local items = {};
		local numLootItems = GetNumLootItems();
		local count = 0;
		local numSlots = 0;
		for i = 1, GetNumLootItems() do
			numSlots = numSlots + 1;
			local texture, item, quantity, quality, locked = GetLootSlotInfo(i);
			if GetLootSlotLink(i) ~= nil then
				local link = GetLootSlotLink(i);
				local itemString = string.find(link, "item[%-?%d:]+");
				itemString = strsub(link, itemString, string.len(link)-string.len(item)-6);
				items[i-count] = {
					[1] = texture,
					[2] = item,
					[3] = quality,
					[4] = GetLootSlotLink(i),
					[5] = itemString,
					[6] = i
				};
			else
				count = count + 1;
			end
		end
		for i = 1, table.getn(items) do
			if (items[i][3] == 4 or inOverride(items[i][2])) and (UnitInRaid("player") or debugMode) then
				CEPGP_frame:Show();
				mode = "loot";
				toggleFrame("CEPGP_loot");
				break;
			end
		end
		populateFrame(_, items, numSlots);
	else
		LFUpdate();
		local numLootItems = LootFrame.numLootItems;
		--Logic to determine how many items to show per page
		local numLootToShow = LOOTFRAME_NUMBUTTONS;
		if ( numLootItems > LOOTFRAME_NUMBUTTONS ) then
			numLootToShow = numLootToShow - 1;
		end
		local texture, item, quantity, quality;
		local items = {};
		local count = 0;
		for index = 1, numLootItems do--LOOTFRAME_NUMBUTTONS do
			local slot = index;
			if ( slot <= numLootItems ) then	
				if (LootSlotIsItem(slot) or LootSlotIsCoin(slot)) then
					texture, item, quantity, quality = GetLootSlotInfo(slot);
					if tostring(GetLootSlotLink(slot)) ~= "nil" then
						items[index-count] = {};
						items[index-count][1] = texture;
						items[index-count][2] = item;
						items[index-count][3] = quality;
						items[index-count][4] = GetLootSlotLink(slot);
						local link = GetLootSlotLink(index);
						local itemString = string.find(link, "item[%-?%d:]+");
						itemString = strsub(link, itemString, string.len(link)-string.len(item)-6);
						items[index-count][5] = itemString;
						items[index-count][6] = slot;
					else
						count = count + 1;
					end
				end
			end
		end
		for i = 1, table.getn(items) do
			if (items[i][3] == 4 or inOverride(item)) and (UnitInRaid("player") or debugMode) then
				CEPGP_frame:Show();
				mode = "loot";
				toggleFrame("CEPGP_loot");
				break;
			end
		end
		populateFrame(_, items, numLootItems);
	end
end

SLASH_ARG1 = "/cepgp";
function SlashCmdList.ARG(msg, editbox)
	msg = string.lower(msg);
	
	if msg == "" then
		CEPGP_print("Classic EPGP Usage");
		CEPGP_print("/cepgp |cFF80FF80show|r - |cFFFF8080Manually shows the CEPGP window|r");
		CEPGP_print("/cepgp |cFF80FF80setDefaultChannel channel|r - |cFFFF8080Sets the default channel to send confirmation messages. Default is Guild|r");
		CEPGP_print("/cepgp |cFF80FF80version|r - |cFFFF8080Checks the version of the addon everyone in your raid is running|r");
		
	elseif msg == "show" then
		populateFrame();
		ShowUIPanel(CEPGP_frame);
		toggleFrame("CEPGP_guild");
	
	elseif msg == "version" then
		vInfo = {};
		CEPGP_SendAddonMsg("version-check", vSearch);
		ShowUIPanel(CEPGP_version);
	
	elseif strfind(msg, "currentchannel") then
		CEPGP_print("Current channel to report: " .. getCurChannel());
		
	elseif strfind(msg, "debug") then
		debugMode = not debugMode;
		if debugMode then
			CEPGP_print("Debug Mode Enabled");
		else
			CEPGP_print("Debug Mode Disabled");
		end
	
	elseif strfind(msg, "setdefaultchannel") then
		if msg == "setdefaultchannel" or msg == "setdefaultchannel " then
			CEPGP_print("|cFF80FFFFPlease enter a valid  channel. Valid options are:|r");
			CEPGP_print("|cFF80FFFFsay, yell, party, raid, guild, officer|r");
			return;
		end
		local newChannel = getVal(msg);
		newChannel = strupper(newChannel);
		local valid = false;
		local channels = {"SAY","YELL","PARTY","RAID","GUILD","OFFICER"};
		local i = 1;
		while channels[i] ~= nil do
			if channels[i] == newChannel then
				valid = true;
			end
			i = i + 1;
		end
		
		if valid then
			CHANNEL = newChannel;
			CEPGP_print("Default channel set to: " .. CHANNEL);
		else
			CEPGP_print("Please enter a valid chat channel. Valid options are:");
			CEPGP_print("say, yell, party, raid, guild, officer");
		end
	else
		CEPGP_print("|cFF80FF80" .. msg .. "|r |cFFFF8080is not a valid request. Type /cepgp to check addon usage|r", true);
	end
end

--[[cleanTable() - Working as intended
	Wipes all frame texts and resets the headers when the mode is changed
]]--
function cleanTable()
	local i = 1;
	while _G[mode..'member_name'..i] ~= nil do
		_G[mode..'member_group'..i].text:SetText("");
		_G[mode..'member_name'..i].text:SetText("");
		_G[mode..'member_rank'..i].text:SetText("");
		_G[mode..'member_EP'..i].text:SetText("");
		_G[mode..'member_GP'..i].text:SetText("");
		_G[mode..'member_PR'..i].text:SetText("");
		i = i + 1;
	end
	
	
	i = 1;
	while _G[mode..'item'..i] ~= nil do
		_G[mode..'announce'..i]:Hide();
		_G[mode..'tex'..i]:Hide();
		_G[mode..'item'..i].text:SetText("");
		_G[mode..'itemGP'..i]:Hide();
		i = i + 1;
	end
end

--[[populateFrame(criteria, items) - In progress
	Populates the frames based on what mode is set.
]]--
function populateFrame(criteria, items, lootNum)
	local sorting = nil;
	local subframe = nil;
	if criteria == "name" or criteria == "rank" then
		SortGuildRoster(criteria);
	elseif criteria == "group" or criteria == "EP" or criteria == "GP" or criteria == "PR" then
		sorting = criteria;
	else
		sorting = "group";
	end
	if mode == "loot" then
		cleanTable();
	elseif mode ~= "loot" then
		cleanTable();
	end
	local tempItems = {};
	local total;
	if mode == "guild" then
		CEPGP_UpdateGuildScrollBar();
	elseif mode == "raid" then
		CEPGP_UpdateRaidScrollBar();
	elseif mode == "loot" then
		subframe = CEPGP_loot;
		local count = 0;
		if not items then
			total = 0;
		else
			local i = 1;
			local nils = 0;
			for index,value in pairs(items) do 
				tempItems[i] = value;
				i = i + 1;
				count = count + 1;
			end
		end
		total = count;
	end
	if mode == "loot" then 
		for i = 1, total do
			local texture, name, quality, gp, colour, iString, link, slot, x;
			x = i;
			texture = tempItems[i][1];
			name = tempItems[i][2];
			colour = ITEM_QUALITY_COLORS[tempItems[i][3]];
			link = tempItems[i][4];
			_, iString = GetItemInfo(tempItems[i][5]);
			slot = tempItems[i][6];
			gp = calcGP(iString);
			backdrop = {bgFile = texture,};
			if _G[mode..'item'..i] ~= nil then
				_G[mode..'announce'..i]:Show();
				_G[mode..'announce'..i]:SetWidth(20);
				_G[mode..'announce'..i]:SetScript('OnClick', function() distribute(link, x, slot) CEPGP_distribute:SetID(this:GetID()) end);
				_G[mode..'announce'..i]:SetID(slot);
				
				_G[mode..'tex'..i]:Show();
				_G[mode..'tex'..i]:SetBackdrop(backdrop);
				_G[mode..'tex'..i]:SetScript('OnEnter', function() GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT") GameTooltip:SetHyperlink(iString) GameTooltip:Show() end);
				_G[mode..'tex'..i]:SetScript('OnLeave', function() GameTooltip:Hide() end);
				
				_G[mode..'item'..i]:Show();
				_G[mode..'item'..i].text:SetText(link);
				_G[mode..'item'..i].text:SetTextColor(colour.r, colour.g, colour.b);
				_G[mode..'item'..i].text:SetPoint('CENTER',_G[mode..'item'..i]);
				_G[mode..'item'..i]:SetWidth(_G[mode..'item'..i].text:GetStringWidth());
				_G[mode..'item'..i]:SetScript('OnClick', function() SetItemRef(iString) end);
				
				_G[mode..'itemGP'..i]:SetText(gp);
				_G[mode..'itemGP'..i]:SetTextColor(colour.r, colour.g, colour.b);
				_G[mode..'itemGP'..i]:SetWidth(35);
				_G[mode..'itemGP'..i]:SetScript('OnEnterPressed', function() this:ClearFocus() end);
				_G[mode..'itemGP'..i]:SetAutoFocus(false);
				_G[mode..'itemGP'..i]:Show();
			else
				subframe.announce = CreateFrame('Button', mode..'announce'..i, subframe, 'UIPanelButtonTemplate');
				subframe.announce:SetHeight(20);
				subframe.announce:SetWidth(20);
				subframe.announce:SetScript('OnClick', function() distribute(link, x, slot) CEPGP_distribute:SetID(this:GetID()); end);
				subframe.announce:SetID(slot);
	
				subframe.tex = CreateFrame('Button', mode..'tex'..i, subframe);
				subframe.tex:SetHeight(20);
				subframe.tex:SetWidth(20);
				subframe.tex:SetBackdrop(backdrop);
				subframe.tex:SetScript('OnEnter', function() GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT") GameTooltip:SetHyperlink(iString) GameTooltip:Show() end);
				subframe.tex:SetScript('OnLeave', function() GameTooltip:Hide() end);
				
				subframe.itemName = CreateFrame('Button', mode..'item'..i, subframe);
				subframe.itemName:SetHeight(20);
				
				subframe.itemGP = CreateFrame('EditBox', mode..'itemGP'..i, subframe, 'InputBoxTemplate');
				subframe.itemGP:SetHeight(20);
				
				if i == 1 then
					subframe.announce:SetPoint('CENTER', _G['CEPGP_'..mode..'_announce'], 'BOTTOM', -10, -20);
					subframe.tex:SetPoint('LEFT', _G[mode..'announce'..i], 'RIGHT', 10, 0);
					subframe.itemName:SetPoint('LEFT', _G[mode..'tex'..i], 'RIGHT', 10, 0);
					subframe.itemGP:SetPoint('CENTER', _G['CEPGP_'..mode..'_GP'], 'BOTTOM', 10, -20);
				else
					subframe.announce:SetPoint('CENTER', _G[mode..'announce'..(i-1)], 'BOTTOM', 0, -20);
					subframe.tex:SetPoint('LEFT', _G[mode..'announce'..i], 'RIGHT', 10, 0);
					subframe.itemName:SetPoint('LEFT', _G[mode..'tex'..i], 'RIGHT', 10, 0);
					subframe.itemGP:SetPoint('CENTER', _G[mode..'itemGP'..(i-1)], 'BOTTOM', 0, -20);
				end
				
				subframe.tex:SetScript('OnClick', function() SetItemRef(iString) end);
				
				subframe.itemName.text = subframe.itemName:CreateFontString(mode..'EPGP_i'..name..'text', 'OVERLAY', 'GameFontNormal');
				subframe.itemName.text:SetPoint('CENTER', _G[mode..'item'..i]);
				subframe.itemName.text:SetText(link);
				subframe.itemName.text:SetTextColor(colour.r, colour.g, colour.b);
				subframe.itemName:SetWidth(subframe.itemName.text:GetStringWidth());
				subframe.itemName:SetScript('OnClick', function() SetItemRef(iString) end);
				
				subframe.itemGP:SetText(gp);
				subframe.itemGP:SetTextColor(colour.r, colour.g, colour.b);
				subframe.itemGP:SetWidth(25);
				subframe.itemGP:SetScript('OnEnterPressed', function() this:ClearFocus() end);
				subframe.itemGP:SetAutoFocus(false);
				subframe.itemGP:Show();
			end
		end
	end
end

--[[distribute(link) - In progress
	Calls for raid members to whisper for items
]]
function distribute(link, x, slotNum)
	itemsTable = {};
	if isML() == 0 or debugMode then
		local iString = getItemString(link);
		local name, _, _, _, _, _, _, slot, tex = GetItemInfo(iString);
		local id = getItemId(iString);
		distID = id;
		distSlot = slot;
		tex = {bgFile = tex,};
		gp = _G[mode..'itemGP'..x]:GetText();
		lootSlot = slotNum;
		responses = {};
		CEPGP_UpdateLootScrollBar();
		CEPGP_SendAddonMsg("RaidAssistLootDist"..link..","..gp.."\\"..UnitName("player"));
		local rank = 0;
		for i = 1, GetNumRaidMembers() do
			if UnitName("player") == GetRaidRosterInfo(i) then
				_, rank = GetRaidRosterInfo(i);
			end
		end
		SendChatMessage("--------------------------", RAID, LANGUAGE);
		if rank > 0 then
			SendChatMessage("NOW DISTRIBUTING: " .. link, "RAID_WARNING", LANGUAGE);
		else
			SendChatMessage("NOW DISTRIBUTING: " .. link, "RAID", LANGUAGE);
		end
		SendChatMessage("GP Value: " .. gp, RAID, LANGUAGE);
		SendChatMessage("Whisper me !need for mainspec only", RAID, LANGUAGE);
		SendChatMessage("--------------------------", RAID, LANGUAGE);
		CEPGP_distribute:Show();
		CEPGP_loot:Hide();
		_G["CEPGP_distribute_item_name"]:SetText(link);
		_G["CEPGP_distribute_item_name_frame"]:SetScript('OnClick', function() SetItemRef(iString) end);
		_G["CEPGP_distribute_item_tex"]:SetBackdrop(tex);
		_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function() GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT") GameTooltip:SetHyperlink(iString) GameTooltip:Show() end);
		_G["CEPGP_distribute_item_tex"]:SetScript('OnLeave', function() GameTooltip:Hide() end);
		_G["CEPGP_distribute_GP_value"]:SetText(gp);
		distributing = true;
	else
		CEPGP_print("You are not the Loot Master.", 1);
		return;
	end
end

function checkEPGP(note)
	if string.find(note, '[0-9]+,[0-9]+') then
		return true;
	else
		return false;
	end
end

function getItemString(link)
	if not link then
		return nil;
	end
	local itemString = string.find(link, "item[%-?%d:]+");
	itemString = strsub(link, itemString, string.len(link)-(string.len(link)-2)-6);
	return itemString;
end

function getItemId(iString)
	if not iString then
		return nil;
	end
	local itemString = string.sub(iString, 6, string.len(iString)-1)--"^[%-?%d:]+");
	return string.sub(itemString, 1, string.find(itemString, ":")-1);
end

function slotNameToId(name)
	if name == nil then
		return nil
	end
	if name == "HEAD" then
		return 1;
	elseif name == "NECK" then
		return 2;
	elseif name == "SHOULDER" then
		return 3;
	elseif name == "CHEST" or name == "ROBE" then
		return 5;
	elseif name == "WAIST" then
		return 6;
	elseif name == "LEGS" then
		return 7;
	elseif name == "FEET" then
		return 8;
	elseif name == "WRIST" then
		return 9;
	elseif name == "HAND" then
		return 10;
	elseif name == "FINGER" then
		return 11, 12;
	elseif name == "TRINKET" then
		return 13, 14;
	elseif name == "CLOAK" then
		return 15;
	elseif name == "2HWEAPON" or name == "WEAPON" or name == "WEAPONMAINHAND" or name == "WEAPONOFFHAND" or name == "SHIELD" or name == "HOLDABLE" then
		return 16, 17;
	elseif name == "RANGED" or name == "RANGEDRIGHT" or name == "RELIC" then
		return 18;
	end
end

--[[resetAll()
	Reverts the EP and GP values of all guild members to 0 and 1 respectively.
	Any new members with no EP or GP assigned will also be set to this default.
	Note: A player's GP must NEVER fall below 1
	Function Status: Working as intended
]]
function resetAll()
	if GetGuildRosterShowOffline() == nil then
		SetGuildRosterShowOffline(true);
		local total = ntgetn(roster);
		if total > 0 then
			for i = 1, total, 1 do
				GuildRosterSetOfficerNote(i, "0,"..BASEGP);
			end
		end
		SetGuildRosterShowOffline(false);
	else
		local total = ntgetn(roster);
		if total > 0 then
			for i = 1, total, 1 do
				GuildRosterSetOfficerNote(i, "0,"..BASEGP);
			end
		end
	end
	CEPGP_SendAddonMsg("update");
	SendChatMessage("All EPGP standings have been cleared!", "GUILD", LANGUAGE);
end

--[[addRaidEP(amount) - Working as intended
	Adds 'amount' EP to the whole raid group
	If a raid boss is killed, 'boss' should be parsed where name is the boss name
]]
function addRaidEP(amount, msg)
	amount = math.floor(amount);
	if not GetGuildRosterShowOffline() then
		SetGuildRosterShowOffline(true);
		local total = GetNumRaidMembers();
		if total > 0 then
			for i = 1, total do
				local name = GetRaidRosterInfo(i);
				if tContains(roster, name, true) then
					local index = getGuildInfo(name);
					if not checkEPGP(roster[name][5]) then
						GuildRosterSetOfficerNote(index, amount .. "," .. BASEGP);
					else
						EP,GP = getEPGP(roster[name][5]);
						EP = tonumber(EP);
						GP = tonumber(GP);
						EP = EP + amount;
						if GP < BASEGP then
							GP = BASEGP;
						end
						if EP < 0 then
							EP = 0;
						end
						GuildRosterSetOfficerNote(index, EP .. "," .. GP);
					end
				end
			end
		end
		SetGuildRosterShowOffline(false);
	else
		local total = GetNumRaidMembers();
		if total > 0 then
			for i = 1, total do
				local name = GetRaidRosterInfo(i);
				if tContains(roster, name, true) then
					local index = getGuildInfo(name);
					if not checkEPGP(roster[name][5]) then
						GuildRosterSetOfficerNote(index, amount .. "," .. BASEGP);
					else
						EP,GP = getEPGP(roster[name][5]);
						EP = tonumber(EP);
						GP = tonumber(GP);
						EP = EP + amount;
						if GP < BASEGP then
							GP = BASEGP;
						end
						if EP < 0 then
							EP = 0;
						end
						GuildRosterSetOfficerNote(index, EP .. "," .. GP);
					end
				end
			end
		end
	end
	if msg then
		CEPGP_SendAddonMsg("update");
		SendChatMessage(msg, "RAID", LANGUAGE);
	else
		CEPGP_SendAddonMsg("update");
		SendChatMessage(amount .. " EP awarded to all raid members", CHANNEL, LANGUAGE);
	end
end

--[[addGuildEP(amount) - Working as intended
	Adds 'amount' EP to the whole guild
]]
function addGuildEP(amount)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	if GetGuildRosterShowOffline() == nil then
		SetGuildRosterShowOffline(true);
		local total = ntgetn(roster);
		local EP, GP = nil;
		amount = math.floor(amount);
		if total > 0 then
			for name,_ in pairs(roster)do
				offNote = roster[name][5];
				index = roster[name][1];
				if offNote == "" or offNote == "Click here to set an Officer's Note" then
					CEPGP_print("Initialising EPGP values for " .. name);
					GuildRosterSetOfficerNote(index, amount .. "," .. BASEGP);
				else
					EP,GP = getEPGP(roster[name][5]);
					EP = tonumber(EP) + amount;
					GP = tonumber(GP);
					if GP < BASEGP then
						GP = BASEGP;
					end
					if EP < 0 then
						EP = 0;
					end
					GuildRosterSetOfficerNote(index, EP .. "," .. GP);
				end
			end
		end
		SetGuildRosterShowOffline(false);
	else
		local total = ntgetn(roster);
		local EP, GP = nil;
		amount = math.floor(amount);
		if total > 0 then
			for name,_ in pairs(roster)do
				offNote = roster[name][5];
				index = roster[name][1];
				if offNote == "" or offNote == "Click here to set an Officer's Note" then
					CEPGP_print("Initialising EPGP values for " .. name);
					GuildRosterSetOfficerNote(index, amount .. "," .. BASEGP);
				else
					EP,GP = getEPGP(roster[name][5]);
					EP = tonumber(EP) + amount;
					GP = tonumber(GP);
					if GP < BASEGP then
						GP = BASEGP;
					end
					if EP < 0 then
						EP = 0;
					end
					GuildRosterSetOfficerNote(index, EP .. "," .. GP);
				end
			end
		end
	end
	CEPGP_SendAddonMsg("update");
	SendChatMessage(amount .. " EP awarded to all guild members", CHANNEL, LANGUAGE);
end

function addStandbyEP(player, amount, boss)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	local EP, GP = nil;
	amount = (math.floor(amount*100))/100;
	local name = getGuildInfo(player);
	EP,GP = getEPGP(roster[player][5]);
	EP = tonumber(EP) + amount;
	GP = tonumber(GP);
	if GP < BASEGP then
		GP = BASEGP;
	end
	if EP < 0 then
		EP = 0;
	end
	if offNote == "" or offNote == "Click here to set an Officer's Note" then
		CEPGP_print("Initialising EPGP values for " .. roster[player][1]);
		GuildRosterSetOfficerNote(roster[player][1], EP .. "," .. BASEGP);
	else
		GuildRosterSetOfficerNote(roster[player][1], EP .. "," .. GP);
	end
	CEPGP_SendAddonMsg("update");
	CEPGP_SendAddonMsg("STANDBYEP"..player..",You have been awarded "..amount.." standby EP for encounter " .. boss, "GUILD");
end

--[[addGP(player, amount) - Working as intended
	Adds 'amount' GP to 'player'
	Note: Player must be part of the guild
]]
function addGP(player, amount, item)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	local EP, GP = nil;
	amount = math.floor(amount);
	if tContains(roster, player, true) then
		offNote = roster[player][5];
		index = roster[player][1];
		if offNote == "" or offNote == "Click here to set an Officer's Note" then
			CEPGP_print("Initialising EPGP values for " .. player);
			GuildRosterSetOfficerNote(index, "0," .. BASEGP);
			offNote = "0," .. BASEGP;
		end
		EP,GP = getEPGP(offNote);
		GP = tonumber(GP) + amount;
		EP = tonumber(EP);
		if GP < BASEGP then
			GP = BASEGP;
		end
		if EP < 0 then
			EP = 0;
		end
		GuildRosterSetOfficerNote(index, EP .. "," .. GP);
		CEPGP_SendAddonMsg("update");
		if not item then
			SendChatMessage(amount .. " GP added to " .. player, CHANNEL, LANGUAGE, CHANNEL);
		end
	else
		CEPGP_print("Player not found in guild roster - no GP given");
		CEPGP_print("If this was a mistake, you can manually award them GP via the CEPGP guild menu");
	end
end

--[[addEP(player, amount) - Working as intended
	Adds 'amount' EP to 'player'
	Note: Player must be part of the guild
]]
function addEP(player, amount)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	amount = math.floor(amount);
	local EP, GP = nil;
	if tContains(roster, player, true) then
		offNote = roster[player][5];
		index = roster[player][1];
		if offNote == "" or offNote == "Click here to set an Officer's Note" then
			CEPGP_print("Initialising EPGP values for " .. player);
			GuildRosterSetOfficerNote(index, "0," .. BASEGP);
			offNote = "0," .. BASEGP;
		end
		EP,GP = getEPGP(offNote);
		EP = tonumber(EP) + amount;
		GP = tonumber(GP);
		if GP < BASEGP then
			GP = BASEGP;
		end
		if EP < 0 then
			EP = 0;
		end
		GuildRosterSetOfficerNote(index, EP .. "," .. GP);
		CEPGP_SendAddonMsg("update");
		SendChatMessage(amount .. " EP added to " .. player, CHANNEL, LANGUAGE, CHANNEL);
	else
		CEPGP_print("Player not found in guild roster.", true);
	end
end

--[[EPDecay(amount) - Working as intended
	Decays the EP of the entire guild by 'amount'%
]]
function decay(amount)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	if GetGuildRosterShowOffline() == nil then
		SetGuildRosterShowOffline(true);
		GuildRoster();
		local EP, GP = nil;
		for name,_ in pairs(roster)do
			EP, GP = getEPGP(roster[name][5]);
			index = roster[name][1];
			--[[if offNote == "" then
				GuildRosterSetOfficerNote(index, 0 .. "," .. BASEGP);
			else]]
				--EP,GP = getEPGP(offNote);
				EP = math.floor(tonumber(EP)*(1-(amount/100)));
				GP = math.floor(tonumber(GP)*(1-(amount/100)));
				if GP < BASEGP then
					GP = BASEGP;
				end
				if EP < 0 then
					EP = 0;
				end
				GuildRosterSetOfficerNote(index, EP .. "," .. GP);
			--end
		end
		SetGuildRosterShowOffline(false);
	else
		GuildRoster();
		local EP, GP = nil;
		for name,_ in pairs(roster)do
			EP, GP = getEPGP(roster[name][5]);
			index = roster[name][1];
			--[[if offNote == "" then
				GuildRosterSetOfficerNote(index, 0 .. "," .. BASEGP);
			else]]
				--EP,GP = getEPGP(offNote);
				EP = math.floor(tonumber(EP)*(1-(amount/100)));
				GP = math.floor(tonumber(GP)*(1-(amount/100)));
				if GP < BASEGP then
					GP = BASEGP;
				end
				if EP < 0 then
					EP = 0;
				end
				GuildRosterSetOfficerNote(index, EP .. "," .. GP);
			--end
		end
	end
	CEPGP_SendAddonMsg("update");
	SendChatMessage("Guild EPGP decayed by " .. amount .. "%", CHANNEL, LANGUAGE, CHANNEL);
	
end

--[[calcGP(link) - Working as intended
	Calculates the GP of an item based on the item level, rarity and slot type of the item.
	GP Formula sourced from: http://www.epgpweb.com/help/gearpoints
	The formula has been altered to increase GP values by x10
]]
function calcGP(link)
	local name, _, rarity, level, _, itemType, _, slot = GetItemInfo(link);
	name = string.gsub(string.gsub(string.lower(name), " ", ""), "'", "");
	for k, v in pairs(OVERRIDE_INDEX) do
		if name == string.gsub(string.gsub(string.lower(k), " ", ""), "'", "") then
			return OVERRIDE_INDEX[k];
		end
	end
	--[[if OVERRIDE_INDEX[name] then
		return OVERRIDE_INDEX[name];
	end]]
	local GP;
	local ilvl;
	local found = false;
	for k, v in pairs(itemsIndex) do
		if name == k then
			ilvl = v;
			found = true;
		end
	end
	if not found then
		if ((slot ~= "" and level == 60 and rarity > 3) or (slot == "" and rarity > 3))
			and (itemType ~= "Blacksmithing" and itemType ~= "Tailoring" and itemType ~= "Alchemy" and itemType ~= "Leatherworking"
			and itemType ~= "Enchanting" and itemType ~= "Engineering" and itemType ~= "Mining") then
			local quality = rarity == 0 and "Poor" or rarity == 1 and "Common" or rarity == 2 and "Uncommon" or rarity == 3 and "Rare" or rarity == 4 and "Epic" or "Legendary";
			CEPGP_print("Warning: " .. name .. " not found in index! Please report this to the addon developer");
			if slot ~= "" then
				slot = strsub(slot,strfind(slot,"INVTYPE_")+8,string.len(slot));
			end
		end
		return 0;
	end
	if slot == "" then
		--Tier 3 slots
		if strfind(name, "desecrated") and rarity == 4 then
			if (name == "desecratedshoulderpads" or name == "desecratedspaulders" or name == "desecratedpauldrons") then slot = "INVTYPE_SHOULDER";
			elseif (name == "desecratedsandals" or name == "desecratedboots" or name == "desecratedsabatons") then slot = "INVTYPE_FEET";
			elseif (name == "desecratedbindings" or name == "desecratedwristguards" or name == "desecratedbracers") then slot = "INVTYPE_WRIST";
			elseif (name == "desecratedgloves" or name == "desecratedhandguards" or name == "desecratedgauntlets") then slot = "INVTYPE_HAND";
			elseif (name == "desecratedbelt" or name == "desecratedwaistguard" or name == "desecratedgirdle") then slot = "INVTYPE_WAIST";
			elseif (name == "desecratedleggings" or name == "desecratedlegguards" or name == "desecratedlegplates") then slot = "INVTYPE_LEGS";
			elseif (name == "desecratedcirclet" or name == "desecratedheadpiece" or name == "desecratedhelmet") then slot = "INVTYPE_HEAD";
			elseif name == "desecratedrobe" then slot = "INVTYPE_ROBE";
			elseif (name == "desecratedtunic" or name == "desecratedbreastplate") then slot = "INVTYPE_CHEST";
			end
			
		elseif strfind(name, "primalhakkari") and rarity == 4 then
			if (name == "primalhakkari bindings" or name == "primalhakkari armsplint" or name == "primalhakkari stanchion") then slot = "INVTYPE_WRIST";
			elseif (name == "primalhakkari girdle" or name == "primalhakkari sash" or name == "primalhakkari shawl") then slot = "INVTYPE_WAIST";
			elseif (name == "primalhakkari tabard" or name == "primalhakkari kossack" or name == "primalhakkari aegis") then slot = "INVTYPE_CHEST";
			end
				
		--Exceptions: Items that should not carry GP but still need to be distributed
		elseif name == "splinterofatiesh"
			or name == "tomeoftranquilizingshot"
			or name == "bindingsofthewindseeker"
			or name == "resilienceofthescourge"
			or name == "fortitudeofthescourge"
			or name == "mightofthescourge" 
			or name == "powerofthescourge"
			or name == "sulfuroningot" then
			slot = "INVTYPE_EXCEPTION";
		end
	end
	if debugMode then
		local quality = rarity == 0 and "Poor" or rarity == 1 and "Common" or rarity == 2 and "Uncommon" or rarity == 3 and "Rare" or rarity == 4 and "Epic" or "Legendary";
		CEPGP_print("Name: " .. name);
		CEPGP_print("Rarity: " .. quality);
		CEPGP_print("Slot: " .. slot);
	end
	if slot ~= "" and slot ~= nil then
		slot = strsub(slot,strfind(slot,"INVTYPE_")+8,string.len(slot));
		slot = SLOTWEIGHTS[slot];
	else
		slot = 1;
	end
	--local mod = {0.5, 0.75, 1, 1.5, 2} --Wrist, Neck, Back, Finger, Off-Hand, Shield, Wand, Ranged Weapon / Shoulder, Hands, Waist, Feet, Trinket / Head, Chest, Legs, / 1H weapon / 2H weapon
	--local rarity = {0, 1, 2, 3, 4, 5} --Green, Blue, Purple, Orange
	if ilvl and rarity and slot then
		return (math.floor((COEF * (2^((ilvl/26) + (rarity-4))) * slot)*MOD));
	else
		return 0;
	end
end

--[[getVal(string) - Working as intended
	Gets the value parsed when using chat commands
	Serves the same purpose as string.split in JavaScript
]]
function getVal(str)
	local val = nil;
	val = strsub(str, strfind(str, " ")+1, string.len(str));
	return val;
end

function getGuildInfo(name)
	if tContains(roster, name, true) then
		return roster[name][1], roster[name][2], roster[name][3], roster[name][4], roster[name][5], roster[name][6];  -- index, Rank, RankIndex, Class, OfficerNote, PR
	else
		return nil;
	end
end

--[[tContains(t, val, bool) - Working as intended
    Checks if table t contains value val. If bool == true then, it checks if table t has index val. Leave bool nil otherwise.
]]
function tContains(t, val, bool)
	if bool == nil then
		for _,value in pairs(t) do
			if value == val then
				return true;
			end
		end
	elseif bool == true then
		for index,_ in pairs(t) do 
			if index == val then
				return true;
			end
		end
	end
	return false;
end

function tSort(t, index)
	if not t then return; end
	local t2 = {};
	table.insert(t2, t[1]);
	table.remove(t, 1);
	local tSize = table.getn(t);
	if tSize > 0 then
		for x = 1, tSize do
			local t2Size = table.getn(t2);
			for y = 1, t2Size do
				if y < t2Size and t[1][index] ~= nil then
					if critReverse then
						if (t[1][index] >= t2[y][index]) then
							table.insert(t2, y, t[1]);
							table.remove(t, 1);
							break;
						elseif (t[1][index] < t2[y][index]) and (t[1][index] >= t2[(y + 1)][index]) then
							table.insert(t2, (y + 1), t[1]);
							table.remove(t, 1);
							break;
						end
					else
						if (t[1][index] <= t2[y][index]) then
							table.insert(t2, y, t[1]);
							table.remove(t, 1);
							break;
						elseif (t[1][index] > t2[y][index]) and (t[1][index] <= t2[(y + 1)][index]) then
							table.insert(t2, (y + 1), t[1]);
							table.remove(t, 1);
							break;
						end
					end
				elseif y == t2Size and t[1][index] ~= nil then
					if critReverse then
						if t[1][index] > t2[y][index] then
							table.insert(t2, y, t[1]);
							table.remove(t, 1);
						else
							table.insert(t2, t[1]);
							table.remove(t, 1);
						end
					else
						if t[1][index] < t2[y][index] then
							table.insert(t2, y, t[1]);
							table.remove(t, 1);
						else
							table.insert(t2, t[1]);
							table.remove(t, 1);
						end
					end
				end
			end
		end
	end
	return t2;
end

--[[ntgetn(table) - Working as intended
	table.getn clone that can handle tables which do not have numerical indexes.
]]
function ntgetn(tbl)
	if tbl == nil then
		return 0;
	end
	local n = 0;
	for _,_ in pairs(tbl) do
		n = n + 1;
	end
	return n;
end

function indexToName(i)
	for index,value in pairs(roster) do
		if value[1] == i then
			return index;
		end
	end
end

function setCriteria(x, disp)
	if criteria == x then
		critReverse = not critReverse
	end
	criteria = x;
	if disp == "Raid" then
		CEPGP_UpdateRaidScrollBar();
	elseif disp == "Guild" then
		CEPGP_UpdateGuildScrollBar();
	elseif disp == "Loot" then
		CEPGP_UpdateLootScrollBar();
	end
end
--[[CEPGP_print(string) - Working as intended
	Faster way of writing DEFAULT_CHAT_FRAME:AddMessage(string)
	I'm lazy. Sue me. Wait - Don't sue me.
]]
function CEPGP_print(str, err)
	if err == nil then
		DEFAULT_CHAT_FRAME:AddMessage("|c006969FFCEPGP: " .. tostring(str) .. "|r");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|c006969FFCEPGP:|r " .. "|c00FF0000Error|r|c006969FF - " .. tostring(str) .. "|r");
	end
end

function CEPGP_strSplit(msgStr, c)
	if not msgStr then
		return nil;
	end
	local table_str = {};
	local capture = string.format("(.-)%s", c);
	
	for v in string.gfind(msgStr, capture) do
		table.insert(table_str, v);
	end
	
	return unpack(table_str);
end


--[[ isML(player) ]]--
--[[ Returns the index of the loot master in the raid group. 
	 The main functionality of this method is it returns 0 if the local player is the loot master ]]--
function isML()
	local _, isML = GetLootMethod();
	return isML;
end

function toggleFrame(frame)
	for i = 1, table.getn(frames) do
		if frames[i]:GetName() == frame then
			frames[i]:Show();
		else
			frames[i]:Hide();
		end
	end
end

function isNumber(num)
	if string.find(tostring(num), '[0-9]+') then
		return true;
	else
		return false;
	end
end

function CEPGP_stackTrace(msg)
	CEPGP_print(msg .. "\nCall stack: \n" .. debugstack(1, 5, 5));
end

function inOverride(itemName)
	for k, _ in pairs(OVERRIDE_INDEX) do
		if string.gsub(string.lower(k), " ", "") == k then
			return true;
		end
	end
	return false;
end