-- todo:
-- timer until someone else' (grayed out) item becomes available to everyone
-- find out why drops are sometimes not detected
-- custom sounds by rarity upon drop
-- separate settings for other people's drops
-- custom frame to customize settings

-- use with https://github.com/TehSeph/tos-addons "Colored Item Names" for colored drop nametags

local addonName = "ITEMDROPS";

_G['ADDONS'] = _G['ADDONS'] or {};
_G['ADDONS']['MIEI'] = _G['ADDONS']['MIEI'] or {}
_G['ADDONS']['MIEI'][addonName] = _G['ADDONS']['MIEI'][addonName] or {};
local g = _G['ADDONS']['MIEI'][addonName];
local acutil = require('acutil');

if not g.loaded then
	g.settings = {
		showGrade = false;				-- show item grade as text in the drop msg?
		showGroupName = false;			-- show item group name (e.g. "Recipe") in the drop msg?
		msgFilterGrade = "rare";		-- only show messages for items of this grade and above, "common" applies msgs to all objects, "off" means msgs will be off
		effectFilterGrade = "common";	-- only draw effects for items of this grade and above, , "common" applies effects to all objects, "off" means effects will be off
		nameTagFilterGrade = "common";	-- only display name tag (as if you were pressing alt) for items of this grade and above, "common" applies to all objects, "off" means name tags will be off
		alwaysShowXPCards = true;			-- always show effects and msgs for exp cards
		alwaysShowMonGems = true;			-- always show effects and msgs for monster gems
		alwaysShowCubes = true;
		showSilverNameTag = false;		-- item name tags for silver drops
		onlyMeOrParty = true;
		showPartyDrops = true;
	}

	g.itemGrades = {
		"common",	 	-- white item
		"rare", 		-- blue item
		"epic", 		-- purple item
		"legendary", 	-- orange item
		"set",			-- set piece
	};

	--F_light080_blue_loop
	--F_cleric_MagnusExorcismus_shot_burstup
	--F_magic_prison_line

	g.settings.effects ={
		["common"] = {
			name = "F_magic_prison_line_white";
			scale = 6;
		};

		["rare"] = {
			name = "F_magic_prison_line_blue";
			scale = 6;
		};

		["epic"] = {
			name = "F_magic_prison_line_dark";
			scale = 6;
		};

		["legendary"] = {
			name = "F_magic_prison_line_red";
			scale = 6;
		};
		["set"] = {
			name = "F_magic_prison_line_green";
			scale = 6;
		};
	}
end

g.settingsComment = [[%s
 Item Drops by Miei, settings file
 http://github.com/Miei/TOS-lua

showGrade			- ドロップメッセージにアイテムグレードをテキストで表示しますか？
showGroupName		- ドロップメッセージにアイテムグループ名（例"Recipe"）を表示しますか？?

msgFilterGrade		- このグレード以上のアイテムのみメッセージを表示します。"common"は全てのオブジェクトでメッセージを表示します。"off"はメッセージを非表示にします。
effectFilterGrade	- "common"、"rare"、"epic"、"legendary"、"set"、"off"に適用します。
nameTagFilterGrade	- 上記の二つのオプションと同じですが、こちらはアイテムの下のネームタグ用です。

alwaysShowXPCards		- 経験値カードをドロップした際にエフェクトとメッセージを常に表示します。
alwaysShowMonGems		- モンスタージェムをドロップした際にエフェクトとメッセージを常に表示します。

showSilverNameTag	- シルバードロップのアイテム名タグです。

onlyMeOrParty 		- falseにするとパーティの他のメンバーのドロップを表示します。
showPartyDrops		- trueにすると他のメンバーのドロップを表示します。showPartyDropsは必要ではありません。

%s

]];

g.settingsComment = string.format(g.settingsComment, "--[[", "]]");
g.settingsFileLoc = "../addons/itemdrops/settings.json";


function ITEMDROPS_3SEC()
	local g = _G["ADDONS"]["MIEI"]["ITEMDROPS"];
	local acutil = require('acutil');

	acutil.slashCommand('/drops', g.processCommand)
	g.addon:RegisterMsg("MON_ENTER_SCENE", "ITEMDROPS_ON_MON_ENTER_SCENE")

	if not g.loaded then
		local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings);
		if err then
			acutil.saveJSON(g.settingsFileLoc, g.settings);
		else
			g.settings = t;
		end
		CHAT_SYSTEM('[itemDrops:help] /drops');
		g.loaded = true;
	end
	g.myAID = session.loginInfo.GetAID();
end

function ITEMDROPS_ON_MON_ENTER_SCENE(frame, msg, str, handle)
	local g = _G['ADDONS']['MIEI']['ITEMDROPS'];

	local actor = world.GetActor(handle);
	if actor:GetObjType() == GT_ITEM then

		local selectedObjects, selectedObjectsCount = SelectObject(GetMyPCObject(), 100000, 'ALL');
		for i = 1, selectedObjectsCount do
			if GetHandle(selectedObjects[i]) == handle then
				local dropOwner = actor:GetUniqueName();
				local drawStuff = false;
				local ownerName = 'Someone';

				if g.settings.onlyMeOrParty ~= true then
					drawStuff = true;
				end

				if g.settings.showPartyDrops == true then
					local memberInfo = session.party.GetPartyMemberInfoByAID(PARTY_NORMAL, dropOwner);
					if nil ~= memberInfo then
						drawStuff = true;

						ownerName = memberInfo:GetName();
					end
				end

				if dropOwner == g.myAID then
					drawStuff = true;
					ownerName = 'You';
				end

				if drawStuff == true then
					local itemObj = GetClass("Item", selectedObjects[i].ClassName);
					local itemName = actor:GetName();
					local itemGrade = nil;
					local groupName = nil;
					local alwaysShow = false;

					if itemObj ~= nil then
						groupName = itemObj.GroupName;
						itemGrade = itemObj.ItemGrade;
						itemName = GET_FULL_NAME(itemObj);
						itemIcon = tostring(itemObj.Icon);

						local itemProp = geItemTable.GetProp(itemObj.ClassID);
						if groupName == "Recipe" then
							itemGrade = itemObj.Icon:match("misc(%d)")-1;
						elseif itemIcon:match("gem_mon") and g.settings.alwaysShowMonGems == true then
							alwaysShow = true;
						elseif itemIcon:match("item_expcard") and g.settings.alwaysShowXPCards == true then
							alwaysShow = true;
						elseif itemIcon:match("item_cube") and g.settings.alwaysShowCubes == true then
							alwaysShow = true;
						end

						if itemProp.setInfo ~= nil then
							itemGrade = 5;
						elseif tostring(itemGrade) == "None" then
							itemGrade = 1;
						end
					end

					if itemObj == nil or alwaysShow == true or g.showOrNot(g.settings.nameTagFilterGrade, itemGrade) == true then
						if itemObj == nil and g.settings.showSilverNameTag ~= true then return end
						g.drawItemFrame(handle, itemName);
					end

					if itemObj ~= nil then

						local itemGradeMsg = g.itemGrades[itemGrade];

						if alwaysShow == true or g.showOrNot(g.settings.effectFilterGrade, itemGrade) == true then
							local effect = g.settings.effects[itemGradeMsg];
							-- delay to allow the actor to finish it's falling animation..
							ReserveScript(string.format('pcall(effect.AddActorEffectByOffset(world.GetActor(%d) or 0, "%s", %d, 0))', handle, effect.name, effect.scale), 0.7);
						end

						if alwaysShow == true or g.showOrNot(g.settings.msgFilterGrade, itemGrade) == true then
							groupNameMsg = " " .. groupName:lower();
							if g.settings.showGroupName ~= true then
								groupNameMsg = '';
							end

							local itemGradeMsg = " " .. itemGradeMsg;
							if g.settings.showGrade ~= true then
								itemGradeMsg = '';
							end

							CHAT_SYSTEM(string.format("%s dropped%s%s %s", ownerName, itemGradeMsg, groupNameMsg, g.linkitem(itemObj)));
						end
					end
				end
			end
		end
	end
end

function g.showOrNot(setting, itemGrade)
	local filterGradeIndex = g.indexOf(g.itemGrades, setting);
	if filterGradeIndex == nil then
		if setting ~= "off" then
			CHAT_SYSTEM("[itemDrops] 無効なフィルターグレードです: " .. setting);
		end
		return false;
	elseif filterGradeIndex <= itemGrade then
		return true;
	end
end

function g.drawItemFrame(handle, itemName)
	local itemFrame = ui.CreateNewFrame("itembaseinfo", "itembaseinfo_" .. handle);
	--
	local nameRichText = GET_CHILD(itemFrame, "name", "ui::CRichText");
	nameRichText:SetText(itemName);

	itemFrame:SetUserValue("_AT_OFFSET_HANDLE", handle);
	itemFrame:SetUserValue("_AT_OFFSET_X", -itemFrame:GetWidth() / 2);
	itemFrame:SetUserValue("_AT_OFFSET_Y", 3);
	itemFrame:SetUserValue("_AT_OFFSET_TYPE", 1);
	itemFrame:SetUserValue("_AT_AUTODESTROY", 1);

	-- makes frame blurry, see FRAME_AUTO_POS_TO_OBJ function
	--AUTO_CAST(itemFrame);
	--itemFrame:SetFloatPosFrame(true);

	_FRAME_AUTOPOS(itemFrame);
	itemFrame:RunUpdateScript("_FRAME_AUTOPOS");

	itemFrame:ShowWindow(1);
end

function g.linkitem(itemObj)
	local imgheight = 30;
	local imgtag =  "";
	local imageName = GET_ITEM_ICON_IMAGE(itemObj);
	local imgtag = string.format("{img %s %d %d}", imageName, imgheight, imgheight);
	local properties = "";
	local itemName = GET_FULL_NAME(itemObj);

	if tostring(itemObj.RefreshScp) ~= "None" then
		_G[itemObj.RefreshScp](itemObj);
	end

	if itemObj.ClassName == 'Scroll_SkillItem' then
		local sklCls = GetClassByType("Skill", itemObj.SkillType)
		itemName = itemName .. "(" .. sklCls.Name ..")";
		properties = GetSkillItemProperiesString(itemObj);
	else
		properties = GetModifiedProperiesString(itemObj);
	end

	if properties == "" then
		properties = 'nullval'
	end

	local itemrank_num = itemObj.ItemStar

	return string.format("{a SLI %s %d}{#0000FF}%s%s{/}{/}{/}", properties, itemObj.ClassID, imgtag, itemName);
end


function g.processCommand(words)
	local g = _G["ADDONS"]["MIEI"]["ITEMDROPS"];
	local cmd = table.remove(words,1);
	local validFilterGrades = 'common, rare, epic, legendary, off';

	if not cmd then
		local msg = '/drops party on/off{nl}';
		msg = msg .. 'パーティメンバー所有のドロップを表示します{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops silver on/off{nl}';
		msg = msg .. 'シルバーのネームタグの表示のon/off切り替えます{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops msg [grade]{nl}';
		msg = msg .. 'チャットメッセージに表示するフィルターグレードを設定します{nl}';
		msg = msg .. '現在: '..g.settings.msgFilterGrade..'{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops fx [grade]{nl}';
		msg = msg .. 'エフェクトのフィルターグレードを設定します{nl}';
		msg = msg .. '現在: '..g.settings.effectFilterGrade..'{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops name [grade]{nl}';
		msg = msg .. 'ネームタグのフィルターグレードを設定します{nl}';
		msg = msg .. '現在: '..g.settings.nameTagFilterGrade..'{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. '/drops filter [grade]{nl}'
		msg = msg .. '全てのフィルターを特定のフィルターグレードに設定します{nl}';
		msg = msg .. '-----------{nl}';
		msg = msg .. 'フィルタの [grade] は以下のいずれかを使用できます:{nl}';
		msg = msg .. "| " .. validFilterGrades .. ' |{nl}';
		msg = msg .. '"off" はこの機能を無効化することを意味します'

		return ui.MsgBox(msg,"","Nope");

	elseif cmd == 'party' then
		cmd = table.remove(words,1);
		if cmd == 'on' then
			g.settings.showPartyDrops = true;
			CHAT_SYSTEM("[itemDrops] パーティメンバー所有のドロップを表示しています。")
		elseif cmd == 'off' then
			g.settings.showPartyDrops = false;
			CHAT_SYSTEM("[itemDrops] パーティメンバー所有のドロップを非表示しています。")
		end

	elseif cmd == 'cards' then
		cmd = table.remove(words,1);
		if cmd == 'on' then
			g.settings.alwaysShowXPCards = true;
			CHAT_SYSTEM("[itemDrops] 「常にカードドロップを表示」が有効化されています。")
		elseif cmd == 'off' then
			g.settings.alwaysShowXPCards = false;
			CHAT_SYSTEM("[itemDrops] 「常にカードドロップを表示」が無効化されています。")
		end

	elseif cmd == 'gems' then
		cmd = table.remove(words,1);
		if cmd == 'on' then
			g.settings.alwaysShowMonGems = true;
			CHAT_SYSTEM("[itemDrops] 「常にモンスタージェムドロップを表示」が有効化されています。")
		elseif cmd == 'off' then
			g.settings.alwaysShowMonGems = false;
			CHAT_SYSTEM("[itemDrops] 「常にモンスタージェムドロップを表示」が無効化されています。")
		end

	elseif cmd == 'silver' then
		cmd = table.remove(words,1);
		if cmd == 'on' then
			g.settings.showSilverNameTag = true;
			CHAT_SYSTEM("[itemDrops] シルバーネームタグを表示しています。")
		elseif cmd == 'off' then
			g.settings.showSilverNameTag = false;
			CHAT_SYSTEM("[itemDrops] シルバーネームタグを非表示しています。")
		end

	elseif cmd == 'filter' then
		cmd = table.remove(words,1);
		if g.checkFilterGrade(cmd) == true then -- check if valid filter grade
			g.settings.msgFilterGrade = cmd;
			g.settings.effectFilterGrade = cmd;
			g.settings.nameTagFilterGradee = cmd;
			CHAT_SYSTEM("[itemDrops] 全てのフィルタが設定されました: " .. cmd)
		else
			CHAT_SYSTEM("[itemDrops] 無効なフィルターグレードです。有効なフィルターグレードは:");
			CHAT_SYSTEM(validFilterGrades);
		end

	elseif cmd == 'msg' then
		cmd = table.remove(words,1);
		if g.checkFilterGrade(cmd) == true then -- check if valid filter grade
			g.settings.msgFilterGrade = cmd;
			CHAT_SYSTEM("[itemDrops] メッセージフィルターが設定されました: " .. cmd)
		else
			CHAT_SYSTEM("[itemDrops] 無効なフィルターグレードです。有効なフィルターグレードは:");
			CHAT_SYSTEM(validFilterGrades);
		end

	elseif cmd == 'fx' then
		cmd = table.remove(words,1);
		if g.checkFilterGrade(cmd) == true then -- check if valid filter grade
			g.settings.effectFilterGrade = cmd;
			CHAT_SYSTEM("[itemDrops] エフェクトフィルターが設定されました: " .. cmd)
		else
			CHAT_SYSTEM("[itemDrops] 無効なフィルターグレードです。有効なフィルターグレードは:");
			CHAT_SYSTEM(validFilterGrades);
		end

	elseif cmd == 'name' then
		cmd = table.remove(words,1);
		if g.checkFilterGrade(cmd) == true then -- check if valid filter grade
			g.settings.nameTagFilterGrade = cmd;
			CHAT_SYSTEM("[itemDrops] ネームタグフィルターが設定されました: " .. cmd)
		else
			CHAT_SYSTEM("[itemDrops] 無効なフィルターグレードです。有効なフィルターグレードは:");
			CHAT_SYSTEM(validFilterGrades);
		end


	else
		CHAT_SYSTEM('[itemDrops] 無効な入力です。"/drops"と入力することでヘルプを見ることができます。');
	end
	acutil.saveJSON(g.settingsFileLoc, g.settings);
end


function g.checkFilterGrade(text)
	if g.indexOf(g.itemGrades, text) ~= nil then
		return true;
	elseif text == "off" then
		return true;
	else
		return false;
	end
end

function g.indexOf( t, object )
	local result = nil;

	if "table" == type( t ) then
		for i=1,#t do
			if object == t[i] then
				result = i;
				break;
			end
		end
	end

	return result;
end

function ITEMDROPS_ON_INIT(addon, frame)
	local g = _G['ADDONS']['MIEI']['ITEMDROPS'];
	local acutil = require('acutil');
	g.addon = addon;
	g.frame = frame;

	g.addon:RegisterMsg("GAME_START_3SEC", "ITEMDROPS_3SEC");
end
