function CEPGP_IncAddonMsg(message, sender)
	if strfind(message, "CEPGP_distributing") and strfind(message, UnitName("player")) then
		local _, _, _, _, _, _, _, slot = GetItemInfo(CEPGP_DistID);
		if not slot then
			slot = string.sub(message, strfind(message, "~")+1);
		end
		if CEPGP_DistID then
			if slot then --string.len(slot) > 0 and slot ~= nil then
				local slotName = string.sub(slot, 9);
				local slotid, slotid2 = CEPGP_SlotNameToID(slotName);
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
					itemID = CEPGP_getItemID(CEPGP_getItemString(currentItem));
					itemID2 = CEPGP_getItemID(CEPGP_getItemString(currentItem2));
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
		end
		
		
	elseif strfind(message, "receiving") and strfind(message, UnitName("player")) then
		local itemID;
		local itemID2;
		if strfind(message, " ") then
			itemID = string.sub(message, strfind(message, "receiving")+10, strfind(message, " "));
			itemID2 = string.sub(message, strfind(message, " ")+1);
		else
			itemID = string.sub(message, strfind(message, "receiving")+10);
		end
		if itemID == "noitem" then
			CEPGP_itemsTable[sender] = {};
			CEPGP_UpdateLootScrollBar();
		elseif itemID == "noslot" then
			CEPGP_itemsTable[sender] = {};
			CEPGP_UpdateLootScrollBar();
		else
			local name, iString = GetItemInfo(itemID);
			if itemID2 then
				local name2, iString2 = GetItemInfo(itemID2);
				if name == nil then
					if name2 == nil then
					else
						CEPGP_itemsTable[sender] = {iString2 .. "[" .. name2 .. "]"};
					end
				else
					CEPGP_itemsTable[sender] = {iString .. "[" .. name .. "]", iString2 .. "[" .. name2 .. "]"};
				end
			else
				if name == nil then
				else
					CEPGP_itemsTable[sender] = {iString .. "[" .. name .. "]"};
				end
			end
			CEPGP_UpdateLootScrollBar();
		end
	elseif strfind(message, UnitName("player").."versioncheck") then
		
		if CEPGP_vSearch == "GUILD" then
			CEPGP_groupVersion[sender] = string.sub(message, strfind(message, " ")+1);
		else
			CEPGP_groupVersion[sender] = string.sub(message, strfind(message, " ")+1);
			CEPGP_vInfo[sender] = string.sub(message, strfind(message, " ")+1);
		end
		CEPGP_UpdateVersionScrollBar();
	elseif message == "version-check" then
		CEPGP_updateGuild();
		if CEPGP_roster[sender] then
			CEPGP_SendAddonMsg(sender .. "versioncheck " .. CEPGP_VERSION, "GUILD");
		else
			CEPGP_SendAddonMsg(sender .. "versioncheck " .. CEPGP_VERSION, "RAID");
		end
	elseif strfind(message, "version") then
		local s1, s2, s3, s4 = CEPGP_strSplit(message, "-");
		if s1 == "update" then
			CEPGP_updateGuild();
		elseif s1 == "version" then
			local ver2 = string.gsub(CEPGP_VERSION, "%.", ",");
			local v1, v2, v3 = CEPGP_strSplit(ver2..",", ",");
			local nv1, nv2, nv3 = CEPGP_strSplit(s2, ",");
			local s5 = (nv1.."."..nv2.."."..nv3)
			outMessage = "Your addon is out of date. Version " .. s5 .. " is now available for download at https://github.com/Alumian/CEPGP"
			if not CEPGP_VERSION_NOTIFIED then
				CEPGP_VERSION_NOTIFIED = true;
				if v1 > v1 then
					CEPGP_print(outMessage);
				elseif nv1 == v1 and nv2 > v2 then
					CEPGP_print(outMessage);
				elseif nv1 == v1 and nv2 == v2 and nv3 > v3 then
					CEPGP_print(outMessage);
				end
			end
		end
	elseif strfind(message, "RaidAssistLoot") and sender ~= UnitName("player") then
		if strfind(message, "RaidAssistLootDist") then
			local link = string.sub(message, 19, strfind(message, ",")-1);
			local gp = string.sub(message, strfind(message, ",")+1, strfind(message, "\\")-1);
			CEPGP_RaidAssistLootDist(link, gp);
		else
			CEPGP_RaidAssistLootClosed();
		end
		
		
	elseif strfind(message, "!need") and sender ~= UnitName("player") then-- and IsRaidOfficer()  then
		local arg2 = string.sub(message, strfind(message, ",")+1, strfind(message, "`")-1); --!need,sendername`itemID
		table.insert(CEPGP_responses, arg2);
		local slot = nil;
		CEPGP_DistID = string.sub(message, 7+string.len(UnitName("player"))+1, string.len(message));
		if CEPGP_DistID then
			_, _, _, _, _, _, _, slot = GetItemInfo(CEPGP_DistID);
		end
		CEPGP_updateGuild();
		if slot then
			CEPGP_SendAddonMsg(arg2.."-CEPGP_distributing-"..CEPGP_DistID.."~"..slot);
		else
			CEPGP_SendAddonMsg(arg2.."-CEPGP_distributing-nil~nil");
		end
	elseif strfind(message, "STANDBYEP"..UnitName("player")) then
		CEPGP_print(string.sub(message, strfind(message, ",")+1));
	elseif strfind(message, "!info"..UnitName("player")) then
		CEPGP_print(string.sub(message, 5+string.len(UnitName("player"))+1));
	elseif message == UnitName("player").."-import" then
		local lane;
		if CEPGP_raidRoster[arg4] then
			lane = "RAID";
		elseif CEPGP_roster[arg4] then
			lane = "GUILD";
		end
		CEPGP_SendAddonMsg(arg4.."-impresponse!CHANNEL~"..CHANNEL, lane);
		CEPGP_SendAddonMsg(arg4.."-impresponse!MOD~"..MOD, lane);
		CEPGP_SendAddonMsg(arg4.."-impresponse!COEF~"..COEF, lane);
		CEPGP_SendAddonMsg(arg4.."-impresponse!BASEGP~"..BASEGP, lane);
		CEPGP_SendAddonMsg(arg4.."-impresponse!WHISPERMSG~"..CEPGP_standby_whisper_msg, lane);
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
		if CEPGP_standby_byrank then --Implies result for both byrank and manual standby designation
			CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYBYRANK~1", lane);
		else
			CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYBYRANK~0", lane);
		end
		if CEPGP_standby_accept_whispers then
			CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYALLOWWHISPERS~1", lane);
		else
			CEPGP_SendAddonMsg(arg4.."-impresponse!STANDBYALLOWWHISPERS~0", lane);
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
		
	elseif strfind(message, UnitName("player")) and strfind(message, "-impresponse!") then
		local option = string.sub(message, strfind(message, "!")+1, strfind(message, "~")-1);
		
		if option == "SLOTWEIGHTS" or option == "STANDBYRANKS" or option == "EPVALS" or option == "AUTOEP" or option == "OVERRIDE" then
			local field = string.sub(message, strfind(message, "~")+1, strfind(message, "?")-1);
			local val = string.sub(message, strfind(message, "?")+1);
			if option == "SLOTWEIGHTS" then
				SLOTWEIGHTS[field] = tonumber(val);
			elseif option == "STANDBYRANKS" then
				if val == "1" then
					STANDBYRANKS[tonumber(field)][2] = true;
				else
					STANDBYRANKS[tonumber(field)][2] = false;
				end
			elseif option == "EPVALS" then
				EPVALS[field] = tonumber(val);
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
			local val = string.sub(message, strfind(message, "~")+1);
			if option == "CHANNEL" then
				CHANNEL = val;
			elseif option == "MOD" then
				MOD = tonumber(val);
			elseif option == "COEF" then
				COEF = tonumber(val);
			elseif option == "BASEGP" then
				BASEGP = tonumber(val);
			elseif option == "STANDBYBYRANK" then
				if val == "1" then
					CEPGP_standby_byrank = true;
					CEPGP_standby_manual = false;
				else
					CEPGP_standby_byrank = false;
					CEPGP_standby_manual = true;
				end
			elseif option == "STANDBYALLOWWHISPERS" then
				if val == "1" then
					CEPGP_standby_accept_whispers = true;
					CEPGP_options_standby_ep_accept_whispers_check:SetChecked(true);
				else
					CEPGP_standby_accept_whispers = false;
					CEPGP_options_standby_ep_accept_whispers_check:SetChecked(false);
				end
			elseif option == "WHISPERMSG" then
				CEPGP_standby_whisper_msg = val;
				CEPGP_options_standby_ep_message_val:SetText(val);
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
				CEPGP_button_options:OnClick();
			end
		end
		
		CEPGP_button_options:OnClick();
		
	
	elseif strfind(message, "CEPGP_TRAFFIC") then
		if sender == UnitName("player") then return; end
		local player = string.sub(message, 21, strfind(message, "ISSUER")-1);
		local issuer = string.sub(message, strfind(message, "ISSUER")+6, strfind(message, "ACTION")-1);
		local action = string.sub(message, strfind(message, "ACTION")+6, strfind(message, "EPB")-1);
		local EPB = string.sub(message, strfind(message, "EPB")+3, strfind(message, "EPA")-1);
		local EPA = string.sub(message, strfind(message, "EPA")+3, strfind(message, "GPB")-1);
		local GPB = string.sub(message, strfind(message, "GPB")+3, strfind(message, "GPA")-1);
		local GPA = string.sub(message, strfind(message, "GPA")+3, strfind(message, "ITEMID")-1);
		local itemID = string.sub(message, strfind(message, "ITEMID")+6);
		local itemLink = CEPGP_getItemLink(itemID);
		TRAFFIC[CEPGP_ntgetn(TRAFFIC)+1] = {
			[1] = player,
			[2] = issuer,
			[3] = action,
			[4] = EPB,
			[5] = EPA,
			[6] = GPB,
			[7] = GPA,
			[8] = itemLink
		};
		CEPGP_UpdateTrafficScrollBar();
	end
end

function CEPGP_SendAddonMsg(message, channel)
	if channel ~= nil then
		SendAddonMessage("CEPGP", message, string.upper(channel));
	else
		SendAddonMessage("CEPGP", message, "RAID");
	end
end

function CEPGP_ShareTraffic(player, issuer, action, EPB, EPA, GPB, GPA, itemID)
	if not player or not action then return; end
	if not itemID then
		itemID = "";
	end
	if not issuer then
		issuer = "";
	end
	if not EPB then
		EPB = "";
	end
	if not EPA then
		EPA = "";
	end
	if not GPB then
		GPB = "";
	end
	if not GPA then
		GPA = "";
	end
	if CanEditOfficerNote() then
		CEPGP_SendAddonMsg("CEPGP_TRAFFIC-PLAYER" .. player .. "ISSUER" .. issuer .. "ACTION" .. action .. "EPB" .. EPB .. "EPA" .. EPA .. "GPB" .. GPB .. "GPA" .. GPA .. "ITEMID" .. itemID, "GUILD");
	end
end