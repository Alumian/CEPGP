function CEPGP_handleComms(event, arg1, arg2)
	CEPGP_print("abc");
	if event == "CHAT_MSG_WHISPER" and string.lower(arg1) == "need" and CEPGP_distributing then
		local duplicate = false;
		for i = 1, table.getn(CEPGP_responses) do
			if CEPGP_responses[i] == arg2 then
				duplicate = true;
				if CEPGP_debugMode then
					CEPGP_print("Duplicate entry. " .. arg2 .. " not registered (!need)");
				end
			end
		end
		if not duplicate then
			CEPGP_SendAddonMsg("!need,"..arg2.."`"..CEPGP_DistID);
			table.insert(CEPGP_responses, arg2);
			if CEPGP_debugMode then
				CEPGP_print(arg2 .. " registered (!need)");
			end
			local _, _, _, _, _, _, _, _, slot = GetItemInfo(CEPGP_DistID);
			if not slot then
				CEPGP_print("Unable to retrieve item information from the server. You will not see what the recipients are currently using", true);
			end
			CEPGP_SendAddonMsg(arg2.."-CEPGP_distributing-"..CEPGP_DistID.."~"..CEPGP_distSlot);
			local EP, GP = nil;
			local inGuild = false;
			if CEPGP_tContains(CEPGP_roster, arg2, true) then
				EP, GP = CEPGP_getEPGP(CEPGP_roster[arg2][5]);
				class = CEPGP_roster[arg2][2];
				inGuild = true;
			end
			if CEPGP_distributing then
				if inGuild then
					SendChatMessage(arg2 .. " (" .. class .. ") needs. (" .. math.floor((EP/GP)*100)/100 .. " PR)", RAID, CEPGP_LANGUAGE);
				else
					local total = GetNumRaidMembers();
					for i = 1, total do
						if arg2 == GetRaidRosterInfo(i) then
							_, _, _, _, class = GetRaidRosterInfo(i);
						end
					end
					SendChatMessage(arg2 .. " (" .. class .. ") needs. (Non-guild member)", RAID, CEPGP_LANGUAGE);
				end
			end
			if not CEPGP_vInfo[arg2] then
				CEPGP_UpdateLootScrollBar();
			end
		end
	elseif event == "CHAT_MSG_WHISPER" and string.lower(arg1) == "!info" then
		if CEPGP_getGuildInfo(arg2) ~= nil then
			local EP, GP = CEPGP_getEPGP(CEPGP_roster[arg2][5]);
			if not CEPGP_vInfo[arg2] then
				SendChatMessage("EPGP Standings - EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100, "WHISPER", CEPGP_LANGUAGE, arg2);
			else
				CEPGP_SendAddonMsg("!info" .. arg2 .. "EPGP Standings - EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100, "GUILD");
			end
		end
	elseif event == "CHAT_MSG_WHISPER" and (string.lower(arg1) == "!infoguild" or string.lower(arg1) == "!inforaid" or string.lower(arg1) == "!infoclass") then
		if CEPGP_getGuildInfo(arg2) ~= nil then
			sRoster = {};
			CEPGP_updateGuild();
			local gRoster = {};
			local rRoster = {};
			local name, unitClass, class, oNote, EP, GP;
			unitClass = CEPGP_roster[arg2][2];
			for i = 1, GetNumGuildMembers() do
				gRoster[i] = {};
				name , _, _, _, class, _, _, oNote = GetGuildRosterInfo(i);
				EP, GP = CEPGP_getEPGP(oNote);
				gRoster[i][1] = name;
				gRoster[i][2] = math.floor((EP/GP)*100)/100;
				gRoster[i][3] = class;
			end
			if string.lower(arg1) == "!infoguild" then
				if CEPGP_critReverse then
					gRoster = CEPGP_tSort(gRoster, 2);
					for i = 1, table.getn(gRoster) do
						if gRoster[i][1] == arg2 then
							if not CEPGP_vInfo[arg2] then
								SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in guild: #" .. i, "WHISPER", CEPGP_LANGUAGE, arg2);
							else
								CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in guild: #" .. i, "GUILD");
							end
						end
					end
				else
					CEPGP_critReverse = true;
					gRoster = CEPGP_tSort(gRoster, 2);
					for i = 1, table.getn(gRoster) do
						if gRoster[i][1] == arg2 then
							if not CEPGP_vInfo[arg2] then
								SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in guild: #" .. i, "WHISPER", CEPGP_LANGUAGE, arg2);
							else
								CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in guild: #" .. i, "GUILD");
							end
						end
					end
					CEPGP_critReverse = false;
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
								_, _ ,_, class, oNote = CEPGP_getGuildInfo(name);
								EP, GP = CEPGP_getEPGP(oNote);
								rRoster[count][2] = math.floor((EP/GP)*100)/100;
								count = count + 1;
							end
						end
					end
				else --Raid
					for i = 1, GetNumRaidMembers() do
						local name = GetRaidRosterInfo(i);
						for x = 1, CEPGP_ntgetn(gRoster) do
							if gRoster[x][1] == name then
								rRoster[count] = {};
								rRoster[count][1] = name;
								_, _ ,_, class, oNote = CEPGP_getGuildInfo(name);
								EP, GP = CEPGP_getEPGP(oNote);
								rRoster[count][2] = math.floor((EP/GP)*100)/100;
								count = count + 1;
							end
						end
					end
				end
				if count > 1 then
					if CEPGP_critReverse then
						rRoster = CEPGP_tSort(rRoster, 2);
						for i = 1, table.getn(rRoster) do
							if rRoster[i][1] == arg2 then
								if string.lower(arg1) == "!infoclass" then
									if not CEPGP_vInfo[arg2] then
										SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank among " .. unitClass .. "s in raid: #" .. i, "WHISPER", CEPGP_LANGUAGE, arg2);
									else
										CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank among " .. unitClass .. "s in raid: #" .. i, "GUILD");
									end
								else
									if not CEPGP_vInfo[arg2] then
										SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in raid: #" .. i, "WHISPER", CEPGP_LANGUAGE, arg2);
									else
										CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in raid: #" .. i, "GUILD");
									end
								end
							end
						end
					else
						CEPGP_critReverse = true;
						rRoster = CEPGP_tSort(rRoster, 2);
						for i = 1, table.getn(rRoster) do
							if rRoster[i][1] == arg2 then
								if string.lower(arg1) == "!infoclass" then
									if not CEPGP_vInfo[arg2] then
										SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank among " .. unitClass .. "s in raid: #" .. i, "WHISPER", CEPGP_LANGUAGE, arg2);
									else
										CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank among " .. unitClass .. "s in raid: #" .. i, "GUILD");
									end
								else
									if not CEPGP_vInfo[arg2] then
										SendChatMessage("EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in raid: #" .. i, "WHISPER", CEPGP_LANGUAGE, arg2);
									else
										CEPGP_SendAddonMsg("!info" .. arg2 .. "EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100 .. " / PR rank in raid: #" .. i, "GUILD");
									end
								end
							end
						end
						CEPGP_critReverse = false;
					end
				end
			end
		end
	end
end

function CEPGP_handleCombat(name, except)
	if name == "The Prophet Skeram" and not except then return; end
	local EP;
	local isLead;
	for i = 1, GetNumRaidMembers() do
		if UnitName("player") == GetRaidRosterInfo(i) then
			_, isLead = GetRaidRosterInfo(i);
		end
	end
	if (((GetLootMethod() == "master" and CEPGP_isML() == 0) or (GetLootMethod() == "group" and isLead == 2)) and CEPGP_ntgetn(CEPGP_roster) > 0) or CEPGP_debugMode then
		local success = CEPGP_getCombatModule(name);
		if name == "Zealot Zath" or name == "Zealot Lor'Khan" then
			name = "High Priest Thekal";
		elseif name == "Flamewaker Elite" or name == "Flamewaker Healer" then
			name = "Majordomo Executus";
		end
		EP = EPVALS[name];
		if AUTOEP[name] and EP > 0 then
			if success then
				if CEPGP_combatModule == "The Four Horsemen" or CEPGP_combatModule == "The Bug Trio" or CEPGP_combatModule == "The Twin Emperors" then
					CEPGP_AddRaidEP(EP, CEPGP_combatModule .. " have been defeated! " .. EP .. " EP has been awarded to the raid", CEPGP_combatModule);
				else
					CEPGP_AddRaidEP(EP, CEPGP_combatModule .. " has been defeated! " .. EP .. " EP has been awarded to the raid", CEPGP_combatModule);
				end
				
				if STANDBYEP then
					TRAFFIC[CEPGP_ntgetn(TRAFFIC)+1] = {"Guild", UnitName("player"), "Standby EP +" .. EP*(STANDBYPERCENT/100) .. " - " .. CEPGP_combatModule};
					CEPGP_ShareTraffic("Guild", UnitName("Player"), "Standby EP +" .. EP*(STANDBYPERCENT/100) .. " - " .. CEPGP_combatModule);
					CEPGP_UpdateTrafficScrollBar();
					if CEPGP_standby_byrank then
						for k, v in pairs(CEPGP_roster) do -- The following module handles standby EP
							if not CEPGP_tContains(CEPGP_raidRoster, k, true) then -- If the player in question is NOT in the raid group, then proceed
								local pName, rank, _, _, _, _, _, _, online = GetGuildRosterInfo(CEPGP_roster[k][1]);
								if online == 1 or STANDBYOFFLINE then
									for i = 1, table.getn(STANDBYRANKS) do
										if STANDBYRANKS[i][1] == rank then
											if STANDBYRANKS[i][2] == true then
												CEPGP_addStandbyEP(pName, EP*(STANDBYPERCENT/100), CEPGP_combatModule);
												CEPGP_print(STANDBYPERCENT);
											end
										end
									end
								end
							end
						end
					elseif CEPGP_standby_manual then
						for i = 1, table.getn(CEPGP_standbyRoster) do
							CEPGP_addStandbyEP(CEPGP_standbyRoster[i], EP*(STANDBYPERCENT/100), CEPGP_combatModule);
						end
					end
				end
			end
		end
		CEPGP_UpdateStandbyScrollBar();
	end
end

function CEPGP_getCombatModule(name)
	--Majordomo Executus
	if name == "Flamewaker Elite" or name == "Flamewaker Healer" then
		CEPGP_kills = CEPGP_kills + 1;
		if CEPGP_kills == 8 then
			CEPGP_combatModule = "Majordomo Executus";
			return true;
		else
			return false;
		end
	end
	
	--Razorgore the Untamed
	if name == "Razorgore the Untamed" then
		if CEPGP_kills == 30 then --For this encounter, CEPGP_kills is used for the eggs
			CEPGP_combatModule = "Razorgore the Untamed";
			return true;
		end
	end
	
	if name == "Zealot Lor'Khan" or name == "Zealot Zath" or name == "High Priest Thekal" then
		CEPGP_combatModule = "High Priest Thekal";
		if CEPGP_THEKAL_PARAMS["LOR'KHAN_DEAD"] and CEPGP_THEKAL_PARAMS["ZATH_DEAD"] and CEPGP_THEKAL_PARAMS["THEKAL_DEAD"] then
			return true;
		else
			if name == "Zealot Lor'Khan" then
			CEPGP_THEKAL_PARAMS["LOR'KHAN_DEAD"] = true;
		elseif name == "Zealot Zath" then
			CEPGP_THEKAL_PARAMS["ZATH_DEAD"] = true;
		else
			CEPGP_THEKAL_PARAMS["THEKAL_DEAD"] = true;
		end
			return false;
		end
	end
	
	if name == "Gri'lek" or name == "Hazza'rah" or name == "Renataki" or name == "Wushoolay" then
		CEPGP_combatModule = "The Edge of Madness";
		return true;
	end
	
	if name == "Princess Yauj" or name == "Vem" or name == "Lord Kri" then
		CEPGP_combatModule = "The Bug Trio";
		CEPGP_kills = CEPGP_kills + 1;
		if CEPGP_kills == 3 then
			return true;
		else
			return false;
		end
	end
	
	if name == "Emperor Vek'lor" or name == "Emperor Vek'nilash" then
		CEPGP_combatModule = "The Twin Emperors";
		CEPGP_kills = CEPGP_kills + 1;
		if CEPGP_kills == 2 then
			return true;
		else
			return false;
		end
	end
	
	if name == "Highlord Mograine" or name == "Thane Korth'azz" or name == "Lady Blaumeux" or name == "Sir Zeliek" then
		CEPGP_combatModule = "The Four Horsemen";
		CEPGP_kills = CEPGP_kills + 1;
		if CEPGP_kills == 4 then
			return true;
		else
			return false;
		end
	end
	
	CEPGP_combatModule = name;
	return name;
end

function CEPGP_handleLoot(event, arg1, arg2)
	if event == "LOOT_CLOSED" then
		CEPGP_distributing = false;
		CEPGP_distItemLink = nil;
		getglobal("distributing"):Hide();
		if CEPGP_mode == "loot" then
			CEPGP_cleanTable();
			if CEPGP_isML() == 0 then
				CEPGP_SendAddonMsg("RaidAssistLootClosed");
			end
			HideUIPanel(CEPGP_frame);
		end
		HideUIPanel(CEPGP_distribute_popup);
		--HideUIPanel(CEPGP_button_loot_dist);
		HideUIPanel(CEPGP_loot);
		HideUIPanel(CEPGP_distribute);
		HideUIPanel(CEPGP_loot_CEPGP_distributing);
		HideUIPanel(CEPGP_button_loot_dist);
		if UnitInRaid("player") then
			CEPGP_toggleFrame(CEPGP_raid);
		elseif GetGuildRosterInfo(1) then
			CEPGP_toggleFrame(CEPGP_guild);
		else
			HideUIPanel(CEPGP_frame);
			if CEPGP_isML() == 0 then
				distributing:Hide();
			end
		end
		
		if CEPGP_distribute:IsVisible() == 1 then
			HideUIPanel(CEPGP_distribute);
			ShowUIPanel(CEPGP_loot);
			CEPGP_responses = {};
			CEPGP_UpdateLootScrollBar();
		end
	elseif event == "LOOT_OPENED" then --and (UnitInRaid("player") or CEPGP_debugMode) then
		CEPGP_LootFrame_Update();
		ShowUIPanel(CEPGP_button_loot_dist);

	elseif event == "LOOT_SLOT_CLEARED" then
		if CEPGP_isML() == 0 then
			CEPGP_SendAddonMsg("RaidAssistLootClosed");
		end
		if CEPGP_distributing and arg1 == CEPGP_lootSlot then
			if CEPGP_distPlayer ~= "" then
				CEPGP_distributing = false;
				if CEPGP_distGP then
					SendChatMessage("Awarded " .. getglobal("CEPGP_distribute_item_name"):GetText() .. " to ".. CEPGP_distPlayer .. " for " .. CEPGP_distribute_GP_value:GetText() .. " GP", CHANNEL, CEPGP_LANGUAGE);
					CEPGP_addGP(CEPGP_distPlayer, CEPGP_distribute_GP_value:GetText(), true, CEPGP_distItemLink);
				else
					SendChatMessage("Awarded " .. getglobal("CEPGP_distribute_item_name"):GetText() .. " to ".. CEPGP_distPlayer .. " for free", CHANNEL, CEPGP_LANGUAGE);
				end
				CEPGP_distPlayer = "";
				CEPGP_distribute_popup:Hide();
				CEPGP_distribute:Hide();
				getglobal("distributing"):Hide();
				CEPGP_loot:Show();
			else
				CEPGP_distributing = false;
				SendChatMessage(getglobal("CEPGP_distribute_item_name"):GetText() .. " has been distributed without EPGP", CHANNEL, CEPGP_LANGUAGE);
				CEPGP_distribute_popup:Hide();
				CEPGP_distribute:Hide();
				getglobal("distributing"):Hide();
				CEPGP_loot:Show();
			end
		end
		CEPGP_LootFrame_Update();
	end	
end