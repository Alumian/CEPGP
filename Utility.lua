function CEPGP_initialise()
	_, _, _, CEPGP_ElvUI = GetAddOnInfo("ElvUI");
	getglobal("CEPGP_version_number"):SetText("Running Version: " .. CEPGP_VERSION);
	local ver2 = string.gsub(CEPGP_VERSION, "%.", ",");
	if CEPGP_notice == nil then
		CEPGP_notice = false;
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
	if CEPGP_ntgetn(AUTOEP) == 0 then
		for k, v in pairs(bossNameIndex) do
			AUTOEP[k] = true;
		end
	end
	if CEPGP_ntgetn(EPVALS) == 0 then
		for k, v in pairs(bossNameIndex) do
			EPVALS[k] = v;
		end
	end
	if CEPGP_ntgetn(SLOTWEIGHTS) == 0 then
		SLOTWEIGHTS = {
			["2HWEAPON"] = 2,
			["WEAPONMAINHAND"] = 1.5,
			["WEAPON"] = 1.5,
			["WEAPONOFFHAND"] = 0.5,
			["HOLDABLE"] = 0.5,
			["SHIELD"] = 0.5,
			["RANGED"] = 0.5,
			["RANGEDRIGHT"] = 0.5,
			["THROWN"] = 0.5,
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
			["TRINKET"] = 0.75,
			["EXCEPTION"] = 1
		}
	end
	if STANDBYPERCENT ==  nil then
		STANDBYPERCENT = 0;
	end
	if CEPGP_ntgetn(STANDBYRANKS) == 0 then
		for i = 1, 10 do
			STANDBYRANKS[i] = {};
			STANDBYRANKS[i][1] = GuildControlGetRankName(i);
			STANDBYRANKS[i][2] = false;
		end
	end
	if UnitInRaid("player") then
		for i = 1, GetNumRaidMembers() do
			name = GetRaidRosterInfo(i);
			CEPGP_raidRoster[name] = name;
		end 
	end
	
	tinsert(UISpecialFrames, "CEPGP_frame");
	tinsert(UISpecialFrames, "CEPGP_context_popup");
	tinsert(UISpecialFrames, "CEPGP_save_guild_logs");
	tinsert(UISpecialFrames, "CEPGP_restore_guild_logs");
	tinsert(UISpecialFrames, "CEPGP_settings_import");
	tinsert(UISpecialFrames, "CEPGP_override");
	tinsert(UISpecialFrames, "CEPGP_traffic");
	
	CEPGP_SendAddonMsg("version-check");
	DEFAULT_CHAT_FRAME:AddMessage("|c00FFC100Classic EPGP Version: " .. CEPGP_VERSION .. " Loaded|r");
	DEFAULT_CHAT_FRAME:AddMessage("|c00FFC100CEPGP: Currently reporting to channel - " .. CHANNEL .. "|r");
	
	if not CEPGP_notice then
		CEPGP_notice_frame:Show();
	end
end

function CEPGP_calcGP(link, quantity, id)
	local name, rarity, ilvl, itemType, subType, slot;
	if id then
		name, link, rarity, _, itemType, subType, _, slot = GetItemInfo(id);
	end
	name = string.gsub(string.gsub(string.lower(name), " ", ""), "'", "");
	ilvl = itemsIndex[name];
	if not ilvl then ilvl = 0; end
	for k, v in pairs(OVERRIDE_INDEX) do
		if name == string.gsub(string.gsub(string.lower(k), " ", ""), "'", "") then
			return OVERRIDE_INDEX[k];
		end
	end
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
		
		elseif strfind(name, "qiraji") then
			if (name == "qirajispikedhilt" or name == "qirajiornatehilt") then slot = "INVTYPE_WEAPONMAINHAND";
			elseif (name == "qirajiregaldrape" or name == "qirajimartialdrape") then slot = "INVTYPE_CLOAK";
			elseif (name == "qirajimagisterialring" or name == "qirajiceremonialring") then slot = "INVTYPE_FINGER";
			elseif (name == "imperialqirajiarmaments" or name == "imperialqirajiregalia") then slot = "INVTYPE_2HWEAPON";
			elseif (name == "qirajibindingsofcommand" or name == "qirajibindingsofdominance") then slot = "INVTYPE_WRIST";
			end
			
		elseif name == "headofossiriantheunscarred" or name == "headofonyxia" or name == "headofnefarian" or name == "eyeofcthun" then
			slot = "INVTYPE_NECK";
		elseif name == "thephylacteryofkelthuzad" or name == "heartofhakkar" then
			slot = "INVTYPE_TRINKET";
		elseif name == "huskoftheoldgod" or name == "carapaceoftheoldgod" then
			slot = "INVTYPE_CHEST";
		elseif name == "ourosintacthide" or name == "skinofthegreatsandworm" then
			slot = "INVTYPE_LEGS";
				
		--Exceptions: Items that should not carry GP but still need to be distributed
		elseif name == "splinterofatiesh"
			or name == "tomeoftranquilizingshot"
			or name == "bindingsofthewindseeker"
			or name == "resilienceofthescourge"
			or name == "fortitudeofthescourge"
			or name == "mightofthescourge" 
			or name == "powerofthescourge"
			or name == "sulfuroningot"
			or name == "matureblackdragonsinew"
			or name == "nightmareengulfedobject"
			or name == "ancientpetrifiedleaf" then
			slot = "INVTYPE_EXCEPTION";
		end
	end
	if CEPGP_debugMode then
		local quality = rarity == 0 and "Poor" or rarity == 1 and "Common" or rarity == 2 and "Uncommon" or rarity == 3 and "Rare" or rarity == 4 and "Epic" or "Legendary";
		CEPGP_print("Name: " .. name);
		CEPGP_print("Rarity: " .. quality);
		CEPGP_print("Item Type: " .. itemType);
		CEPGP_print("Subtype: " .. subType);
		CEPGP_print("Slot: " .. slot);
	end
	slot = strsub(slot,strfind(slot,"INVTYPE_")+8,string.len(slot));
	slot = SLOTWEIGHTS[slot];
	if ilvl and rarity and slot then
		return (math.floor((COEF * (2^((ilvl/26) + (rarity-4))) * slot)*MOD)*quantity);
	else
		return 0;
	end
end

function CEPGP_populateFrame(CEPGP_criteria, items, lootNum)
	local sorting = nil;
	local subframe = nil;
	if CEPGP_criteria == "name" or CEPGP_criteria == "rank" then
		SortGuildRoster(CEPGP_criteria);
	elseif CEPGP_criteria == "group" or CEPGP_criteria == "EP" or CEPGP_criteria == "GP" or CEPGP_criteria == "PR" then
		sorting = CEPGP_criteria;
	else
		sorting = "group";
	end
	if CEPGP_mode == "loot" then
		CEPGP_cleanTable();
	elseif CEPGP_mode ~= "loot" then
		CEPGP_cleanTable();
	end
	local tempItems = {};
	local total;
	if CEPGP_mode == "guild" then
		CEPGP_UpdateGuildScrollBar();
	elseif CEPGP_mode == "raid" then
		CEPGP_UpdateRaidScrollBar();
	elseif CEPGP_mode == "loot" then
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
	if CEPGP_mode == "loot" then 
		for i = 1, total do
			local texture, name, quality, gp, colour, iString, link, slot, x, quantity;
			x = i;
			texture = tempItems[i][1];
			name = tempItems[i][2];
			colour = ITEM_QUALITY_COLORS[tempItems[i][3]];
			link = tempItems[i][4];
			iString = tempItems[i][5];
			slot = tempItems[i][6];
			quantity = tempItems[i][7];
			gp = CEPGP_calcGP(link, quantity, CEPGP_getItemID(iString));
			backdrop = {bgFile = texture,};
			if _G[CEPGP_mode..'item'..i] ~= nil then
				_G[CEPGP_mode..'announce'..i]:Show();
				_G[CEPGP_mode..'announce'..i]:SetWidth(20);
				_G[CEPGP_mode..'announce'..i]:SetScript('OnClick', function() CEPGP_announce(link, x, slot, quantity) CEPGP_distribute:SetID(this:GetID()) end);
				_G[CEPGP_mode..'announce'..i]:SetID(slot);
				
				_G[CEPGP_mode..'tex'..i]:Show();
				_G[CEPGP_mode..'tex'..i]:SetBackdrop(backdrop);
				_G[CEPGP_mode..'tex'..i]:SetScript('OnEnter', function() GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT") GameTooltip:SetHyperlink(iString) GameTooltip:Show() end);
				_G[CEPGP_mode..'tex'..i]:SetScript('OnLeave', function() GameTooltip:Hide() end);
				
				_G[CEPGP_mode..'item'..i]:Show();
				_G[CEPGP_mode..'item'..i].text:SetText(link);
				_G[CEPGP_mode..'item'..i].text:SetTextColor(colour.r, colour.g, colour.b);
				_G[CEPGP_mode..'item'..i].text:SetPoint('CENTER',_G[CEPGP_mode..'item'..i]);
				_G[CEPGP_mode..'item'..i]:SetWidth(_G[CEPGP_mode..'item'..i].text:GetStringWidth());
				_G[CEPGP_mode..'item'..i]:SetScript('OnClick', function() SetItemRef(iString) end);
				
				_G[CEPGP_mode..'itemGP'..i]:SetText(gp);
				_G[CEPGP_mode..'itemGP'..i]:SetTextColor(colour.r, colour.g, colour.b);
				_G[CEPGP_mode..'itemGP'..i]:SetWidth(35);
				_G[CEPGP_mode..'itemGP'..i]:SetScript('OnEnterPressed', function() this:ClearFocus() end);
				_G[CEPGP_mode..'itemGP'..i]:SetAutoFocus(false);
				_G[CEPGP_mode..'itemGP'..i]:Show();
			else
				subframe.announce = CreateFrame('Button', CEPGP_mode..'announce'..i, subframe, 'UIPanelButtonTemplate');
				subframe.announce:SetHeight(20);
				subframe.announce:SetWidth(20);
				subframe.announce:SetScript('OnClick', function() CEPGP_announce(link, x, slot, quantity) CEPGP_distribute:SetID(this:GetID()); end);
				subframe.announce:SetID(slot);
	
				subframe.tex = CreateFrame('Button', CEPGP_mode..'tex'..i, subframe);
				subframe.tex:SetHeight(20);
				subframe.tex:SetWidth(20);
				subframe.tex:SetBackdrop(backdrop);
				subframe.tex:SetScript('OnEnter', function() GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT") GameTooltip:SetHyperlink(iString) GameTooltip:Show() end);
				subframe.tex:SetScript('OnLeave', function() GameTooltip:Hide() end);
				
				subframe.itemName = CreateFrame('Button', CEPGP_mode..'item'..i, subframe);
				subframe.itemName:SetHeight(20);
				
				subframe.itemGP = CreateFrame('EditBox', CEPGP_mode..'itemGP'..i, subframe, 'InputBoxTemplate');
				subframe.itemGP:SetHeight(20);
				subframe.itemGP:SetWidth(35);
				
				if i == 1 then
					subframe.announce:SetPoint('CENTER', _G['CEPGP_'..CEPGP_mode..'_announce'], 'BOTTOM', -10, -20);
					subframe.tex:SetPoint('LEFT', _G[CEPGP_mode..'announce'..i], 'RIGHT', 10, 0);
					subframe.itemName:SetPoint('LEFT', _G[CEPGP_mode..'tex'..i], 'RIGHT', 10, 0);
					subframe.itemGP:SetPoint('CENTER', _G['CEPGP_'..CEPGP_mode..'_GP'], 'BOTTOM', 10, -20);
				else
					subframe.announce:SetPoint('CENTER', _G[CEPGP_mode..'announce'..(i-1)], 'BOTTOM', 0, -20);
					subframe.tex:SetPoint('LEFT', _G[CEPGP_mode..'announce'..i], 'RIGHT', 10, 0);
					subframe.itemName:SetPoint('LEFT', _G[CEPGP_mode..'tex'..i], 'RIGHT', 10, 0);
					subframe.itemGP:SetPoint('CENTER', _G[CEPGP_mode..'itemGP'..(i-1)], 'BOTTOM', 0, -20);
				end
				
				subframe.tex:SetScript('OnClick', function() SetItemRef(iString) end);
				
				subframe.itemName.text = subframe.itemName:CreateFontString(CEPGP_mode..'EPGP_i'..name..'text', 'OVERLAY', 'GameFontNormal');
				subframe.itemName.text:SetPoint('CENTER', _G[CEPGP_mode..'item'..i]);
				subframe.itemName.text:SetText(link);
				subframe.itemName.text:SetTextColor(colour.r, colour.g, colour.b);
				subframe.itemName:SetWidth(subframe.itemName.text:GetStringWidth());
				subframe.itemName:SetScript('OnClick', function() SetItemRef(iString) end);
				
				subframe.itemGP:SetText(gp);
				subframe.itemGP:SetTextColor(colour.r, colour.g, colour.b);
				subframe.itemGP:SetWidth(35);
				subframe.itemGP:SetScript('OnEnterPressed', function() this:ClearFocus() end);
				subframe.itemGP:SetAutoFocus(false);
				subframe.itemGP:Show();
			end
		end
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

function CEPGP_stackTrace()
	CEPGP_print("Call stack: \n" .. debugstack(1, 5, 5));
end

function CEPGP_print(str, err)
	if not str then return; end;
	if err == nil then
		DEFAULT_CHAT_FRAME:AddMessage("|c006969FFCEPGP: " .. tostring(str) .. "|r");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|c006969FFCEPGP:|r " .. "|c00FF0000Error|r|c006969FF - " .. tostring(str) .. "|r");
	end
end

function CEPGP_cleanTable()
	local i = 1;
	while _G[CEPGP_mode..'member_name'..i] ~= nil do
		_G[CEPGP_mode..'member_group'..i].text:SetText("");
		_G[CEPGP_mode..'member_name'..i].text:SetText("");
		_G[CEPGP_mode..'member_rank'..i].text:SetText("");
		_G[CEPGP_mode..'member_EP'..i].text:SetText("");
		_G[CEPGP_mode..'member_GP'..i].text:SetText("");
		_G[CEPGP_mode..'member_PR'..i].text:SetText("");
		i = i + 1;
	end
	
	
	i = 1;
	while _G[CEPGP_mode..'item'..i] ~= nil do
		_G[CEPGP_mode..'announce'..i]:Hide();
		_G[CEPGP_mode..'tex'..i]:Hide();
		_G[CEPGP_mode..'item'..i].text:SetText("");
		_G[CEPGP_mode..'itemGP'..i]:Hide();
		i = i + 1;
	end
end

function CEPGP_toggleFrame(frame)
	for i = 1, table.getn(CEPGP_frames) do
		if CEPGP_frames[i]:GetName() == frame then
			CEPGP_frames[i]:Show();
		else
			CEPGP_frames[i]:Hide();
		end
	end
end

function CEPGP_rosterUpdate(event)
	if event == "GUILD_ROSTER_UPDATE" then
		CEPGP_roster = {};
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
				local EP, GP = CEPGP_getEPGP(officerNote, i, name);
				local PR = math.floor((EP/GP)*100)/100;
				CEPGP_roster[name] = {
				[1] = i,
				[2] = class,
				[3] = rank,
				[4] = rankIndex,
				[5] = officerNote,
				[6] = PR
				};
			end
		end
		if CEPGP_mode == "guild" then
			CEPGP_UpdateGuildScrollBar();
		elseif CEPGP_mode == "raid" then
			CEPGP_UpdateRaidScrollBar();
		end
		CEPGP_UpdateStandbyScrollBar();
	elseif event == "RAID_ROSTER_UPDATE" then
		CEPGP_vInfo = {};
		CEPGP_SendAddonMsg("version-check", "RAID");
		CEPGP_updateGuild();
		CEPGP_raidRoster = {};
		for i = 1, GetNumRaidMembers() do
			local name = GetRaidRosterInfo(i);
			if CEPGP_tContains(CEPGP_standbyRoster, name) then
				for k, v in pairs(CEPGP_standbyRoster) do
					if v == name then
						table.remove(CEPGP_standbyRoster, k);
					end
				end
				CEPGP_UpdateStandbyScrollBar();
			end
			CEPGP_raidRoster[name] = name;
		end
		if UnitInRaid("player") then
			ShowUIPanel(CEPGP_button_raid);
		else --[[ Hides the raid and loot distribution buttons if the player is not in a raid group ]]--
			HideUIPanel(CEPGP_raid);
			HideUIPanel(CEPGP_loot);
			HideUIPanel(CEPGP_button_raid);
			HideUIPanel(CEPGP_button_loot_dist);
			HideUIPanel(CEPGP_distribute_popup);
			HideUIPanel(CEPGP_context_popup);
			CEPGP_mode = "guild";
			ShowUIPanel(CEPGP_guild);
		end
		CEPGP_vInfo = {};
		CEPGP_UpdateVersionScrollBar();
		CEPGP_UpdateRaidScrollBar();
	end
end

function CEPGP_addToStandby(player)
	if not player then return; end
	player = CEPGP_standardiseString(player);
	if not CEPGP_tContains(CEPGP_roster, player, true) then
		CEPGP_print(player .. " is not a guild member", true);
		return;
	elseif CEPGP_tContains(CEPGP_standbyRoster, player) then
		CEPGP_print(player .. " is already in the standby roster", true);
		return;
	elseif CEPGP_tContains(CEPGP_raidRoster, player, true) then
		CEPGP_print(player .. " is part of the raid", true);
		return;
	else
		table.insert(CEPGP_standbyRoster, player);
		CEPGP_UpdateStandbyScrollBar();
	end
end

function CEPGP_standardiseString(value)
	--Returns the same string with the first letter as capital
	if not value then return; end
	local first = string.upper(strsub(value, 1, 1)); --The uppercase first character of the string
	local rest = strsub(value, 2, strlen(value)); --The remainder of the string
	return first .. rest;
end

function CEPGP_toggleStandbyRanks(show)
	if show and CEPGP_ntgetn(STANDBYRANKS) > 0 then
		for i = 1, 10 do
			STANDBYRANKS[i][1] = GuildControlGetRankName(i);
		end
		for i = 1, 10 do
			if STANDBYRANKS[i][1] then
				getglobal("CEPGP_options_standby_ep_rank_"..i):Show();
				getglobal("CEPGP_options_standby_ep_rank_"..i):SetText(tostring(STANDBYRANKS[i][1]));
				getglobal("CEPGP_options_standby_ep_check_rank_"..i):Show();
				if STANDBYRANKS[i][2] == true then
					getglobal("CEPGP_options_standby_ep_check_rank_"..i):SetChecked(true);
				else
					getglobal("CEPGP_options_standby_ep_check_rank_"..i):SetChecked(false);
				end
			else
				getglobal("CEPGP_options_standby_ep_rank_"..i):Hide();
				getglobal("CEPGP_options_standby_ep_check_rank_"..i):Hide();
			end
			if GuildControlGetRankName(i) == "" then
				getglobal("CEPGP_options_standby_ep_rank_"..i):Hide();
				getglobal("CEPGP_options_standby_ep_check_rank_"..i):Hide();
				getglobal("CEPGP_options_standby_ep_check_rank_"..i):SetChecked(false);
			end
		end
		CEPGP_options_standby_ep_list_button:Hide();
		CEPGP_options_standby_ep_accept_whispers_check:Hide();
		CEPGP_options_standby_ep_accept_whispers:Hide();
		CEPGP_options_standby_ep_offline_check:Hide();
		CEPGP_options_standby_ep_offline:Hide();
		CEPGP_options_standby_ep_message_val:Hide();
		CEPGP_options_standby_ep_whisper_message:Hide();
		CEPGP_options_standby_ep_byrank_check:SetChecked(true);
		CEPGP_options_standby_ep_manual_check:SetChecked(false);
	else
		for i = 1, 10 do
			getglobal("CEPGP_options_standby_ep_rank_"..i):Hide();
			getglobal("CEPGP_options_standby_ep_check_rank_"..i):Hide();
		end
		CEPGP_options_standby_ep_list_button:Show();
		CEPGP_options_standby_ep_accept_whispers_check:Show();
		CEPGP_options_standby_ep_accept_whispers:Show();
		CEPGP_options_standby_ep_offline_check:Show();
		CEPGP_options_standby_ep_offline:Show();
		CEPGP_options_standby_ep_message_val:Show();
		CEPGP_options_standby_ep_byrank_check:SetChecked(false);
		CEPGP_options_standby_ep_manual_check:SetChecked(true);
	end
end

function CEPGP_getGuildInfo(name)
	if CEPGP_tContains(CEPGP_roster, name, true) then
		return CEPGP_roster[name][1], CEPGP_roster[name][2], CEPGP_roster[name][3], CEPGP_roster[name][4], CEPGP_roster[name][5], CEPGP_roster[name][6];  -- index, Rank, RankIndex, Class, OfficerNote, PR
	else
		return nil;
	end
end

function CEPGP_getVal(str)
	local val = nil;
	val = strsub(str, strfind(str, " ")+1, string.len(str));
	return val;
end

function CEPGP_indexToName(index)
	for name,value in pairs(CEPGP_roster) do
		if value[1] == index then
			return name;
		end
	end
end

function CEPGP_nameToIndex(name)
	for key,index in pairs(CEPGP_roster) do
		if key == name then
			return index[1];
		end
	end
end

function CEPGP_getEPGP(offNote, index, name)
	if not CEPGP_checkEPGP(offNote) then
		if not index then return 0, BASEGP; end
		local EP, GP;
		--Error with player's EPGP has been detected and will attempt to be salvaged
		if string.find(offNote, '^[0-9]+,') then --EP is assumed in tact
			if string.find(offNote, ',[0-9]+') then
				EP = tonumber(strsub(offNote, 1, strfind(offNote, ",")-1));
				GP = strsub(offNote, string.find(offNote, ',[0-9]+')+1, string.find(offNote, '[^0-9,]')-1);
				if CanEditOfficerNote() == 1 then
					GuildRosterSetOfficerNote(index, EP .. "," .. GP);
					CEPGP_print("An error was found with " .. name .. "'s GP. Their EPGP has been salvaged as " .. EP .. "," .. GP .. ". Please confirm if this is correct and modify the officer note if required.");
				end
				return EP,GP;
			elseif string.find(offNote, '[0-9]+$') then
				EP = tonumber(strsub(offNote, 1, strfind(offNote, ",")-1));
				GP = strsub(offNote, string.find(offNote, '[0-9]+$'), string.len(offNote));
				if CanEditOfficerNote() == 1 then
					GuildRosterSetOfficerNote(index, EP .. "," .. GP);
					CEPGP_print("An error was found with " .. name .. "'s GP. Their EPGP has been salvaged as " .. EP .. "," .. GP .. ". Please confirm if this is correct and modify the officer note if required.");
				end
				return EP,GP;
			else
				EP = tonumber(strsub(offNote, 1, strfind(offNote, ",")-1));
				if CanEditOfficerNote() == 1 then
					GuildRosterSetOfficerNote(index, EP .. "," .. BASEGP);
					CEPGP_print("An error was found with " .. name .. "'s GP. Their EP has been retained as " .. EP .. " but their GP will need to be manually set if known.");
				end
				return EP, BASEGP;
			end
			return EP, BASEGP;
		elseif string.find(offNote, ',[0-9]+$') then --GP is assumed in tact
			GP = tonumber(strsub(offNote, strfind(offNote, ",")+1, string.len(offNote)));
			
			if string.find(offNote, '[^0-9]+,[0-9]+$') then --EP might still be intact, but characters might be padding between EP and the comma
				EP = strsub(offNote, 1, string.find(offNote, '[^0-9]+,')-1);
				if CanEditOfficerNote() == 1 then
					GuildRosterSetOfficerNote(index, EP .. "," .. GP);
					CEPGP_print("An error was found with " .. name .. "'s EP. Their EPGP has been salvaged as " .. EP .. "," .. GP .. ". Please confirm if this is correct and modify the officer note if required.");
				end
				return EP, GP;
				
			elseif string.find(offNote, '^[^0-9]+[0-9]+,[0-9]+$') then --or pheraps the error is at the start of the string?
				EP = strsub(offNote, string.find(offNote, '[0-9]+,'), string.find(offNote, ',[0-9]+$')-1);
				if CanEditOfficerNote() == 1 then
					GuildRosterSetOfficerNote(index, EP .. "," .. GP);
					CEPGP_print("An error was found with " .. name .. "'s EP. Their EPGP has been salvaged as " .. EP .. "," .. GP .. ". Please confirm if this is correct and modify the officer note if required.");
				end
				return EP, GP;
				
			else --EP cannot be salvaged
				if CanEditOfficerNote() == 1 then
					GuildRosterSetOfficerNote(index, "0," .. GP);
					CEPGP_print("An error was found with " .. name .. "'s EP. Their GP has been retained as " .. GP .. " but their EP will need to be manually set if known. For now, their EP has defaulted to 0.");
				end
				return 0, GP;
			end
		else --Neither are in tact
			GuildRosterSetOfficerNote(index, "0," .. BASEGP);
			return 0, BASEGP;
		end
	end
	local EP, GP = nil;
	EP = tonumber(strsub(offNote, 1, strfind(offNote, ",")-1));
	GP = tonumber(strsub(offNote, strfind(offNote, ",")+1, string.len(offNote)));
	return EP, GP;
end

function CEPGP_checkEPGP(note)
	if string.find(note, '^[0-9]+,[0-9]+$') then
		return true;
	else
		return false;
	end
end

function CEPGP_getItemString(link)
	if not link then
		return nil;
	end
	local itemString = string.find(link, "item[%-?%d:]+");
	itemString = strsub(link, itemString, string.len(link)-(string.len(link)-2)-6);
	return itemString;
end

function CEPGP_getItemID(iString)
	if not iString then
		return nil;
	end
	local itemString = string.sub(iString, 6, string.len(iString)-1)--"^[%-?%d:]+");
	return string.sub(itemString, 1, string.find(itemString, ":")-1);
end

function CEPGP_getItemLink(id)
	local name, _, rarity = GetItemInfo(id);
	if rarity == 0 then -- Poor
		return "\124cff9d9d9d\124Hitem:" .. id .. "::::::::110:::::\124h[" .. name .. "]\124h\124r";
	elseif rarity == 1 then -- Common
		return "\124cffffffff\124Hitem:" .. id .. "::::::::110:::::\124h[" .. name .. "]\124h\124r";
	elseif rarity == 2 then -- Uncommon
		return "\124cff1eff00\124Hitem:" .. id .. "::::::::110:::::\124h[" .. name .. "]\124h\124r";
	elseif rarity == 3 then -- Rare
		return "\124cff0070dd\124Hitem:" .. id .. "::::::::110:::::\124h[" .. name .. "]\124h\124r";
	elseif rarity == 4 then -- Epic
		return "\124cffa335ee\124Hitem:" .. id .. "::::::::110:::::\124h[" .. name .. "]\124h\124r";
	elseif rarity == 5 then -- Legendary
		return "\124cffff8000\124Hitem:" .. id .. "::::::::110:::::\124h[" .. name .. "]\124h\124r";
	end
end

function CEPGP_SlotNameToID(name)
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

function CEPGP_inOverride(itemName)
	itemName = string.gsub(string.gsub(string.gsub(string.lower(itemName), " ", ""), "'", ""), ",", "");
	for k, _ in pairs(OVERRIDE_INDEX) do
		if itemName == string.gsub(string.gsub(string.gsub(string.lower(k), " ", ""), "'", ""), ",", "") then
			return true;
		end
	end
	return false;
end

function CEPGP_tContains(t, val, bool)
	if not t then return; end
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

function CEPGP_isNumber(num)
	return not (string.find(tostring(num), '[^-0-9.]+') or string.find(tostring(num), '[^-0-9.]+$'));
end

function CEPGP_isML()
	local _, isML = GetLootMethod();
	return isML;
end

function CEPGP_updateGuild()
	if not IsInGuild() then
		HideUIPanel(CEPGP_button_guild);
		HideUIPanel(CEPGP_guild);
		return;
	else
		ShowUIPanel(CEPGP_button_guild);
		if CEPGP_ntgetn(STANDBYRANKS) > 0 then
			for i = 1, 10 do
				STANDBYRANKS[i][1] = GuildControlGetRankName(i);
			end
		end
	end
	GuildRoster();
end

function CEPGP_tSort(t, index)
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
					if CEPGP_critReverse then
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
					if CEPGP_critReverse then
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

function CEPGP_ntgetn(tbl)
	if tbl == nil then
		return 0;
	end
	local n = 0;
	for _,_ in pairs(tbl) do
		n = n + 1;
	end
	return n;
end

function CEPGP_setCriteria(x, disp)
	if CEPGP_criteria == x then
		CEPGP_critReverse = not CEPGP_critReverse
	end
	CEPGP_criteria = x;
	if disp == "Raid" then
		CEPGP_UpdateRaidScrollBar();
	elseif disp == "Guild" then
		CEPGP_UpdateGuildScrollBar();
	elseif disp == "Loot" then
		CEPGP_UpdateLootScrollBar();
	elseif disp == "Standby" then
		CEPGP_UpdateStandbyScrollBar();
	end
end

function CEPGP_toggleBossConfigFrame(fName)
	for _, frame in pairs(CEPGP_boss_config_frames) do
		if frame:GetName() ~= fName then
			frame:Hide();
		else
			frame:Show();
		end;
	end
end

function capitaliseFirstLetter(str)
	str = string.gsub(" "..str, "%W%l", string.upper):sub(2)
	return str;
end

function CEPGP_button_options_OnClick()
	CEPGP_updateGuild();
	PlaySound("gsTitleOptionExit");
	CEPGP_toggleFrame("CEPGP_options");
	CEPGP_mode = "options";
	CEPGP_options_mod_edit:SetText(tostring(MOD));
	CEPGP_options_coef_edit:SetText(tostring(COEF));
	CEPGP_options_gp_base_edit:SetText(tostring(BASEGP));
	if STANDBYEP then
		CEPGP_options_standby_ep_check:SetChecked(true);
	else
		CEPGP_options_standby_ep_check:SetChecked(false);
	end
	CEPGP_options_standby_ep_val:SetText(tostring(STANDBYPERCENT));
	if CEPGP_standby_byrank then
		CEPGP_toggleStandbyRanks(true);
	else
		CEPGP_toggleStandbyRanks(false);
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
	if CEPGP_options_standby_ep_byrank_check:GetChecked() then
		CEPGP_options_standby_ep_message_val:Hide();
		CEPGP_options_standby_ep_whisper_message:Hide();
	else
		CEPGP_options_standby_ep_message_val:Show();
		CEPGP_options_standby_ep_whisper_message:Show();
	end;
	if CEPGP_options_standby_ep_check:GetChecked() then
		CEPGP_options_standby_ep_options:Show();
	else
		CEPGP_options_standby_ep_options:Hide();
	end
	for k, v in pairs(SLOTWEIGHTS) do
		if k ~= "ROBE" and k ~= "WEAPON" and k ~= "EXCEPTION" then
			getglobal("CEPGP_options_" .. k .. "_weight"):SetText(tonumber(SLOTWEIGHTS[k]));
		end
	end
	CEPGP_populateFrame();
end

function CEPGP_UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList, search)
	if ( not frame ) then
		frame = this;
	end

	frame.menuList = menuList;

	if ( frame:GetName() ~= UIDROPDOWNMENU_OPEN_MENU ) then
		UIDROPDOWNMENU_MENU_LEVEL = 1;
	end

	-- Set the frame that's being intialized
	UIDROPDOWNMENU_INIT_MENU = frame:GetName();

	-- Hide all the buttons
	local button, dropDownList;
	for i = 1, UIDROPDOWNMENU_MAXLEVELS, 1 do
		dropDownList = getglobal("DropDownList"..i);
		if ( i >= UIDROPDOWNMENU_MENU_LEVEL or frame:GetName() ~= UIDROPDOWNMENU_OPEN_MENU ) then
			dropDownList.numButtons = 0;
			dropDownList.maxWidth = 0;
			for j=1, UIDROPDOWNMENU_MAXBUTTONS, 1 do
				button = getglobal("DropDownList"..i.."Button"..j);
				button:Hide();
			end
			dropDownList:Hide();
		end
	end
	frame:SetHeight(UIDROPDOWNMENU_BUTTON_HEIGHT * 2);
	
	-- Set the initialize function and call it.  The initFunction populates the dropdown list.
	if ( initFunction ) then
		frame.initialize = initFunction;
		initFunction(level, frame.menuList, search);
	end

	-- Change appearance based on the displayMode
	if ( displayMode == "MENU" ) then
		getglobal(frame:GetName().."Left"):Hide();
		getglobal(frame:GetName().."Middle"):Hide();
		getglobal(frame:GetName().."Right"):Hide();
		getglobal(frame:GetName().."ButtonNormalTexture"):SetTexture("");
		getglobal(frame:GetName().."ButtonDisabledTexture"):SetTexture("");
		getglobal(frame:GetName().."ButtonPushedTexture"):SetTexture("");
		getglobal(frame:GetName().."ButtonHighlightTexture"):SetTexture("");
		getglobal(frame:GetName().."Button"):ClearAllPoints();
		getglobal(frame:GetName().."Button"):SetPoint("LEFT", frame:GetName().."Text", "LEFT", -9, 0);
		getglobal(frame:GetName().."Button"):SetPoint("RIGHT", frame:GetName().."Text", "RIGHT", 6, 0);
		frame.displayMode = "MENU";
	end

end

function CEPGP_getDebugInfo()
	local info = "<details><summary>Debug Info</summary><br />";
	info = info .. "Version: " .. CEPGP_VERSION .. "<br /><br />";
	info = info .. "GP Modifier: " .. MOD .. "<br /><br />";
	info = info .. "Base GP: " .. BASEGP .. "<br /><br />";
	if STANDBYEP then
		info = info .. "Standby EP: True<br /><br />";
	else
		info = info .. "Standby EP: False<br /><br />";
	end
	if STANDBYOFFLINE then
		info = info .. "Standby Offline: True<br /><br />";
	else
		info = info .. "Standby Offline: False<br /><br />";
	end
	info = info .. "Standby Percent: " .. STANDBYPERCENT .. "<br /><br />";
		if CEPGP_standby_accept_whispers then
		info = info .. "Standby Accept Whispers: True<br /><br />";
	else
		info = info .. "Standby Accept Whispers: False<br /><br />";
	end
	if CEPGP_standby_byrank then
		info = info .. "Standby EP by Rank: True<br /><br />";
	else
		info = info .. "Standby EP by Rank: False<br /><br />";
	end
	if CEPGP_standby_manual then
		info = info .. "Standby EP Manual Delegation: True<br /><br />";
	else
		info = info .. "Standby EP Manual Delegation: False<br /><br />";
	end
	info = info .. "Standby EP Whisper Keyphrase: " .. CEPGP_standby_whisper_msg .. "<br /><br />";

	info = info .. "<details><summary>Auto EP</summary><br />";
	for k, v in pairs(AUTOEP) do
		if v then
			info = info .. "<details><summary>" .. k .. "</summary>True</details><br />";
		else
			info = info .. "<details><summary>" .. k .. "</summary>False</details><br />";
		end
	end
	info = info .. "</details><br />";
	info = info .. "<details><summary>EP Values</summary><br />";
	for k, v in pairs(EPVALS) do
		info = info .. "<details><summary>" .. k .. "</summary>" .. v .. "</details><br />";
	end
	info = info .. "</details><br />";
	info = info .. "<details><summary>Standby Guild Ranks</summary><br />";
	for k, v in pairs(STANDBYRANKS) do
		if v[1] then
			if v[2] then
				info = info .. "<details><summary>" .. v[1] .. "</summary>True</details><br />";
			else
				info = info .. "<details><summary>" .. v[1] .. "</summary>False</details><br />";
			end
		end
	end
	info = info .. "</details><br />";
	info = info .. "<details><summary>Slot Weights</summary><br />";
	for k, _ in pairs(SLOTWEIGHTS) do
		info = info .. "<details><summary>" .. k .. "</summary>" .. SLOTWEIGHTS[k] .. "</details><br />";
	end
	info = info .. "</details><br />";
	info = info .. "</details>";
	return info;
end

function CEPGP_getPlayerClass(name, index)
	if not index and not name then return; end
	local class;
	if name == "Guild" then
		return _, {r=0, g=1, b=0};
	end
	if name == "Raid" then
		return _, {r=1, g=0.10, b=0.10};
	end
	if index then
		_, _, _, _, class = GetGuildRosterInfo(index);
		return class, RAID_CLASS_COLORS[string.upper(class)];
	else
		local id = CEPGP_nameToIndex(name);
		if not id then
			return nil;
		else
			_, _, _, _, class = GetGuildRosterInfo(id);
			return class, RAID_CLASS_COLORS[string.upper(class)];
		end
	end
end