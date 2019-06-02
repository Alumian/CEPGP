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
	tSize = table.getn(CEPGP_responses);
	CEPGP_updateGuild();
	for x = 1, tSize do
		name = CEPGP_responses[x]
		if CEPGP_debugMode and not UnitInRaid("player") then
			class = UnitClass("player");
		end
		for i = 1, GetNumRaidMembers() do
			if name == GetRaidRosterInfo(i) then
				_, _, _, _, class = GetRaidRosterInfo(i);
			end
		end
		if CEPGP_tContains(CEPGP_roster, name, true) then
			rank = CEPGP_roster[name][3];
			rankIndex = CEPGP_roster[name][4];
			offNote = CEPGP_roster[name][5];
			EP, GP = CEPGP_getEPGP(offNote);
			PR = CEPGP_roster[name][6];
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
	t = CEPGP_tSort(t, CEPGP_criteria)
	FauxScrollFrame_Update(DistributeScrollFrame, tSize, 18, 120);
	for y = 1, 18, 1 do
		yoffset = y + FauxScrollFrame_GetOffset(DistributeScrollFrame);
		if (yoffset <= tSize) then
			if not CEPGP_tContains(t, yoffset, true) then
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
				if CEPGP_itemsTable[name]then
					if CEPGP_itemsTable[name][1] ~= nil then
						iString = CEPGP_itemsTable[name][1].."|r";
						_, _, _, _, _, _, _, _, tex = GetItemInfo(iString);
						if CEPGP_itemsTable[name][2] ~= nil then
							iString2 = CEPGP_itemsTable[name][2].."|r";
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
	tSize = CEPGP_ntgetn(CEPGP_roster);
	for x = 1, tSize do
		name = CEPGP_indexToName(x);
		index, class, rank, rankIndex, offNote = CEPGP_getGuildInfo(name);
		EP, GP = CEPGP_getEPGP(offNote)
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
	t = CEPGP_tSort(t, CEPGP_criteria)
	FauxScrollFrame_Update(GuildScrollFrame, tSize, 18, 240);
	for y = 1, 18, 1 do
		
		yoffset = y + FauxScrollFrame_GetOffset(GuildScrollFrame);
		if (yoffset <= tSize) then
			if not CEPGP_tContains(t, yoffset, true) then
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
		local a = CEPGP_getGuildInfo(name);
		if CEPGP_tContains(CEPGP_roster, name, true) then
			rank = CEPGP_roster[name][3];
			rankIndex = CEPGP_roster[name][4];
			offNote = CEPGP_roster[name][5];
			EP, GP = CEPGP_getEPGP(offNote);
			PR = CEPGP_roster[name][6];
		end
		if not CEPGP_roster[name] then
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
	t = CEPGP_tSort(t, CEPGP_criteria)
	FauxScrollFrame_Update(RaidScrollFrame, tSize, 18, 240);
	for y = 1, 18, 1 do
		yoffset = y + FauxScrollFrame_GetOffset(RaidScrollFrame);
		if (yoffset <= tSize) then
			if not CEPGP_tContains(t, yoffset, true) then
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
	if CEPGP_vSearch == "GUILD" then
		tSize = GetNumGuildMembers();
	else
		tSize = GetNumRaidMembers();
	end
	if tSize == 0 then
		for y = 1, 18, 1 do
			getglobal("versionButton" .. y):Hide();
		end
	end
	if CEPGP_vSearch == "GUILD" then
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
			if not CEPGP_tContains(t, yoffset, true) then
				getglobal("versionButton" .. y):Hide();
			else
				t2 = t[yoffset];
				name = t2[1];
				class = t2[2];
				online = t2[3];
				if CEPGP_groupVersion[name] then
					version = CEPGP_groupVersion[name];
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
	tSize = CEPGP_ntgetn(OVERRIDE_INDEX);
	if tSize == 0 then
		for y = 1, 18, 1 do
			getglobal("CEPGP_overrideButton" .. y):Hide();
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
	FauxScrollFrame_Update(CEPGP_overrideScrollFrame, tSize, 18, 240);
	for y = 1, 18, 1 do
		yoffset = y + FauxScrollFrame_GetOffset(CEPGP_overrideScrollFrame);
		if (yoffset <= tSize) then
			if not CEPGP_tContains(t, yoffset, true) then
				getglobal("CEPGP_overrideButton" .. y):Hide();
			else
				t2 = t[yoffset];
				item = t2[1];
				gp = t2[2];
				quality = t2[3];
				getglobal("CEPGP_overrideButton" .. y .. "item"):SetText(item);
				getglobal("CEPGP_overrideButton" .. y .. "GP"):SetText(gp);
				getglobal("CEPGP_overrideButton" .. y .. "GP"):SetTextColor(1, 1, 1);
				getglobal("CEPGP_overrideButton" .. y):Show();
			end
		else
			getglobal("CEPGP_overrideButton" .. y):Hide();
		end
	end
end

function CEPGP_UpdateTrafficScrollBar()
	if TRAFFIC == nil then
		return;
	end
	local yoffset;
	local tSize;
	tSize = CEPGP_ntgetn(TRAFFIC);
	FauxScrollFrame_Update(trafficScrollFrame, tSize, 18, 240);
	for y = 1, 18, 1 do
		yoffset = y + FauxScrollFrame_GetOffset(trafficScrollFrame);
		if (yoffset <= tSize) then
			local name = TRAFFIC[CEPGP_ntgetn(TRAFFIC) - (yoffset-1)][1];
			local issuer = TRAFFIC[CEPGP_ntgetn(TRAFFIC) - (yoffset-1)][2];
			local action = TRAFFIC[CEPGP_ntgetn(TRAFFIC) - (yoffset-1)][3];
			local EPB = TRAFFIC[CEPGP_ntgetn(TRAFFIC) - (yoffset-1)][4];
			local EPA = TRAFFIC[CEPGP_ntgetn(TRAFFIC) - (yoffset-1)][5];
			local GPB = TRAFFIC[CEPGP_ntgetn(TRAFFIC) - (yoffset-1)][6];
			local GPA = TRAFFIC[CEPGP_ntgetn(TRAFFIC) - (yoffset-1)][7];
			local item = TRAFFIC[CEPGP_ntgetn(TRAFFIC) - (yoffset-1)][8];
			local _, colour = CEPGP_getPlayerClass(name);
			getglobal("trafficButton" .. y .. "Name"):SetText(name);
			if colour then
				getglobal("trafficButton" .. y .. "Name"):SetTextColor(colour.r, colour.g, colour.b);
			else
				getglobal("trafficButton" .. y .. "Name"):SetTextColor(1, 1, 1);
			end
			_, colour = CEPGP_getPlayerClass(issuer);
			getglobal("trafficButton" .. y .. "Issuer"):SetText(issuer);
			if colour then
				getglobal("trafficButton" .. y .. "Issuer"):SetTextColor(colour.r, colour.g, colour.b);
			else
				getglobal("trafficButton" .. y .. "Issuer"):SetTextColor(1, 1, 1);
			end
			if item then
				getglobal("trafficButton" .. y .. "ItemName"):SetText(item);
				getglobal("trafficButton" .. y .. "ItemName"):Show();
				getglobal("trafficButton" .. y .. "Item"):SetScript('OnClick', function() SetItemRef(tostring(CEPGP_getItemString(item))) end);
			else
				getglobal("trafficButton" .. y .. "ItemName"):SetText("");
				getglobal("trafficButton" .. y .. "ItemName"):Hide();
				getglobal("trafficButton" .. y .. "Item"):SetScript('OnClick', function() end);
			end
			getglobal("trafficButton" .. y .. "Action"):SetText(action);
			getglobal("trafficButton" .. y .. "Action"):SetTextColor(1, 1, 1);
			getglobal("trafficButton" .. y .. "EPBefore"):SetText(EPB);
			getglobal("trafficButton" .. y .. "EPBefore"):SetTextColor(1, 1, 1);
			getglobal("trafficButton" .. y .. "EPAfter"):SetText(EPA);
			getglobal("trafficButton" .. y .. "EPAfter"):SetTextColor(1, 1, 1);
			getglobal("trafficButton" .. y .. "GPBefore"):SetText(GPB);
			getglobal("trafficButton" .. y .. "GPBefore"):SetTextColor(1, 1, 1);
			getglobal("trafficButton" .. y .. "GPAfter"):SetText(GPA);
			getglobal("trafficButton" .. y .. "GPAfter"):SetTextColor(1, 1, 1);
			getglobal("trafficButton" .. y):Show();
		else
			getglobal("trafficButton" .. y):Hide();
		end
	end
end

function CEPGP_UpdateStandbyScrollBar()
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
	tSize = CEPGP_ntgetn(CEPGP_standbyRoster);
	for x = 1, tSize do
		name = CEPGP_standbyRoster[x];
		index, class, rank, rankIndex, offNote = CEPGP_getGuildInfo(name);
		EP, GP = CEPGP_getEPGP(offNote)
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
	t = CEPGP_tSort(t, CEPGP_criteria)
	FauxScrollFrame_Update(CEPGP_StandbyScrollFrame, tSize, 18, 240);
	for y = 1, 18, 1 do
		yoffset = y + FauxScrollFrame_GetOffset(CEPGP_StandbyScrollFrame);
		if (yoffset <= tSize) then
			if not CEPGP_tContains(t, yoffset, true) then
				getglobal("CEPGP_StandbyButton" .. y):Hide();
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
				getglobal("CEPGP_StandbyButton" .. y .. "Info"):SetText(name);
				getglobal("CEPGP_StandbyButton" .. y .. "Info"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("CEPGP_StandbyButton" .. y .. "Class"):SetText(class);
				getglobal("CEPGP_StandbyButton" .. y .. "Class"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("CEPGP_StandbyButton" .. y .. "Rank"):SetText(rank);
				getglobal("CEPGP_StandbyButton" .. y .. "Rank"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("CEPGP_StandbyButton" .. y .. "EP"):SetText(EP);
				getglobal("CEPGP_StandbyButton" .. y .. "EP"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("CEPGP_StandbyButton" .. y .. "GP"):SetText(GP);
				getglobal("CEPGP_StandbyButton" .. y .. "GP"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("CEPGP_StandbyButton" .. y .. "PR"):SetText(PR);
				getglobal("CEPGP_StandbyButton" .. y .. "PR"):SetTextColor(colour.r, colour.g, colour.b);
				getglobal("CEPGP_StandbyButton" .. y):Show();
			end
		else
			getglobal("CEPGP_StandbyButton" .. y):Hide();
		end
	end
end