/*
    Used to store the list of songs used by the music player
*/
local songData = {}
local dermaBase = {}
local local_player = LocalPlayer()

local songsInFolder  = {}
local folderLeft = {}
local folderLeftAddon = {}
local folderRight = {}

/*
    Stores list of songs absolute paths
*/
local song_list = {}

local folderExceptions = { "ambience", "ambient", "ambient_mp3", "beams",
"buttons", "coach", "combined", "commentary", "common", "doors", "foley",
"friends", "garrysmod", "hl1", "items", "midi", "misc", "mvm", "test",
"npc", "passtime", "phx", "physics", "pl_hoodoo", "plats", "player",
"replay", "resource", "sfx", "thrusters", "tools", "ui", "vehicles", "vo",
"weapons" }

local function init(baseMenu)
    dermaBase = baseMenu
	return songData
end

local function updateSongList(table_songs)
    if table.IsEmpty(table_songs) then return end

    song_list = table_songs
    for key, filePath in pairs(song_list) do
        dermaBase.songlist:AddLine(
            string.StripExtension(string.GetFileFromFilename(filePath)))
    end
end

/*
    Get the song absolute filepath
*/
local function get_song(index)
    if table.IsEmpty(song_list) then return end
    return song_list[index]
end

local function get_current_list()
    return song_list
end

local function get_left_song_list()
    return folderLeft
end

local function get_right_song_list()
	return folderRight
end

local function populate_song_page()
	dermaBase.songlist:Clear()
    local table_songs = {}
	for k, folder in pairs(folderRight) do
        folder = string.Trim(folder)
        songsInFolder, folderLeft =
            file.Find("sound/" .. folder .. "/*", "GAME")
        local songsInFolderAddons, appendFolders =
            file.Find( "sound/" .. folder .. "/*", "WORKSHOP" )

        if IsValid(appendFolders) then
            table.Add(folderLeft, appendFolders)
        end
        if IsValid(songsInFolderAddons) then
            table.Add(songsInFolder, songsInFolderAddons)
        end

        for k, songName in pairs(songsInFolder) do
            table.insert(table_songs, "sound/" .. folder .. "/" .. songName)
        end

        for key, folderName in pairs(folderLeft) do
            // also scan within the first folders
            songsInFolder = file.Find(
                "sound/" .. folder .. "/" .. folderName .. "/*", "GAME")

            for key2, songName in pairs( songsInFolder ) do
                table.insert(table_songs, "sound/" .. folder .. "/" .. folderName .. "/" .. songName)
            end
        end
	end
    updateSongList(table_songs)
end

local function save_on_disk()
	populate_song_page()
	file.Write( "gmpl_songpath.txt", "")
	for k,v in pairs(folderRight) do
		file.Append( "gmpl_songpath.txt", v .. "\r\n")
	end
	dermaBase.audiodirsheet:InvalidateLayout(true)
end

/*
    Populates the right song dir list
*/
local function load_from_disk()
	if file.Exists( "gmpl_songpath.txt", "DATA" ) then
		local fileRead =
            string.Explode("\n", file.Read( "gmpl_songpath.txt", "DATA" ))
		for i = 1, #fileRead - 1 do
			folderRight[i] = string.TrimRight(fileRead[i])
		end
		populate_song_page()
	end
end


/*
    Discards folders that are not needed
*/
local function left_list_discard_exceptions()
    for k,v in pairs(folderLeft) do
		for j = 0, #folderExceptions do
			if v == folderExceptions[j] then
				folderLeft[k] = nil
			end
		end
	end
	for k,v in pairs(folderLeftAddon) do
		for j = 0, #folderExceptions do
			if v == folderExceptions[j] then
				folderLeftAddon[k] = nil
			end
		end
	end
	folderLeft = table.ClearKeys(folderLeft)
	folderLeftAddon = table.ClearKeys(folderLeftAddon)
end

local function populate_left_list()
	table.Empty(folderLeft)
	table.Empty(folderLeftAddon)

	songsInFolder, folderLeft = file.Find( "sound/*", "GAME" )
	songsInFolder, folderLeftAddon = file.Find( "sound/*", "WORKSHOP" )
    left_list_discard_exceptions()
end

local function sanity_check_right_list()
	for k,leftItem in pairs(folderLeft) do
		for j = 1, #folderRight do
            // remove audio dir from left list if in right list
			if rawequal(leftItem, folderRight[j]) then
				folderLeft[k] = nil
				break
			end
		end
	end

	for j = 1, #folderRight do
		local path = "sound/" .. folderRight[j]
        // this doesn't look in WORKSHOP we prove it exists using
        // folderLeftAddon
		if !file.Exists( path, "GAME" ) then
			local found = false
			for k,addonSong in pairs(folderLeftAddon) do
                // use folderLeftAddon just to check for existence
				if rawequal(addonSong, folderRight[j]) then
					found = true
                    // if it exists we only clear it from left list
					folderLeftAddon[k] = nil
				end
				if found then break end
			end
			if !found then
				folderRight[j] = nil
			end
		end
	end
    // clean left list addons after you prove above that they exist
	for k,leftItemAddon in pairs(folderLeftAddon) do
		for k2,rightItem in pairs(folderRight) do
			if rawequal(leftItemAddon, rightItem) then
				folderLeftAddon[k] = nil
				break
			end
		end
	end
end

local function populate_both_lists()
	dermaBase.foldersearch:clearLeft()
	dermaBase.foldersearch:clearRight()
    // don't add duplicates
	for k,folderAddon in pairs(folderLeftAddon) do
		for k2,folderBase in pairs(folderLeft) do
			if rawequal(folderBase, folderAddon) then
				folderLeft[k2] = nil
			end
		end
	end

	for key,foldername in pairs(folderLeftAddon) do
		dermaBase.foldersearch:AddLineLeft(foldername)
	end
	for key,foldername in pairs(folderLeft) do
		dermaBase.foldersearch:AddLineLeft(foldername)
	end
	for key,foldername in pairs(folderRight) do
		dermaBase.foldersearch:AddLineRight(foldername)
	end
end

local function rebuild_song_page()
    populate_left_list()
    sanity_check_right_list()
    populate_both_lists()
end

local function refresh_song_list()
    net.Start("sv_refresh_song_list")
    net.WriteTable(folderLeft)
    net.WriteTable(folderRight)
    net.SendToServer()
end

local function populate_left_list(song_list)
    if istable(song_list) then
        folderLeft = song_list
    else
        folderLeft = dermaBase.foldersearch:populateLeftList()
    end
end

local function populate_right_list(song_list)
    if istable(song_list) then
        folderRight = song_list
    else
        folderRight = dermaBase.foldersearch:populateRightList()
    end
end
-----------------------------------------------------------------------------
net.Receive("cl_refresh_song_list", function(length, sender)
    // update the left list in case of becoming admin
   folderLeft = net.ReadTable()
   folderRight = net.ReadTable()

   -- print("\nUpdating song list from server")
   -- print("inactive:")
   -- PrintTable(folderLeft)
   -- print("active:")
   -- PrintTable(folderRight)
   -- print("----------------------------")

   -- actionRebuild()
   rebuild_song_page()
   -- populate_song_page(folderRight)
   populate_song_page()
   dermaBase.buttonrefresh:SetVisible(false)
   dermaBase.audiodirsheet:InvalidateLayout(true)
end)
-----------------------------------------------------------------------------
songData.populate_song_page = populate_song_page
songData.rebuild_song_page  = rebuild_song_page
songData.refresh_song_list  = refresh_song_list

songData.save_on_disk       = save_on_disk
songData.load_from_disk     = load_from_disk

songData.get_song           = get_song

songData.get_left_song_list  = get_left_song_list
songData.get_right_song_list = get_right_song_list
songData.get_current_list   = get_current_list

songData.populate_left_list  = populate_left_list
songData.populate_right_list = populate_right_list
return init
