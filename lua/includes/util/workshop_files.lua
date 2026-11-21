
local PreviewCache = {}
local InfoCache = {}
local ListCache = {}
local WorkshopNames = {}

local function CleanWorkshopDescription( description )
	description = string.gsub( description, "%[img%]([^%]]*)%[/img%]", "" )
	description = string.gsub( description, "%[([^%]]*)%]", "" )
	return string.Trim( description )
end

local function AddStoredWorkshopItems( subscriptions )
	local existing = {}
	for _, item in ipairs( subscriptions ) do
		if ( item.wsid ~= "0" ) then existing[ item.wsid ] = item end
	end

	for _, entry in ipairs( engine.GetLocalWorkshopContent() ) do
		local item = existing[ entry.wsid ]
		if ( not item ) then
			item = entry
			item.workshop_archived = true
			subscriptions[ #subscriptions + 1 ] = item
			existing[ entry.wsid ] = item
		end

		item.local_workshop = true
		local details = WorkshopNames[ entry.wsid ]
		if ( details ) then
			item.title = details.title
			if ( details.tags and details.tags ~= "" ) then item.tags = details.tags end
		end
	end
end

if ( MENU_DLL ) then
	function HL2SBOpenStoredWorkshopPage( id )
		if ( type( id ) ~= "string" or not id:match( "^[1-9][0-9]*$" ) or #id > 20 or
			( #id == 20 and id > "18446744073709551615" ) ) then return end
		if ( isfunction( steamworks.ViewFile ) ) then
			steamworks.ViewFile( id )
		else
			gui.OpenURL( "https://steamcommunity.com/sharedfiles/filedetails/?id=" .. id )
		end
	end
end

function WorkshopFileBase( namespace, requiredtags )

	local ret = {}
	ret.HTML = nil
	local storedWorkshop = MENU_DLL and namespace == "addon" and engine.GetLocalWorkshopContent and HL2SBWorkshopInfo

	function ret:Fetch( type, offset, perpage, extratags, searchText, filter, sort )

		local tags = table.Copy( requiredtags )
		for k, v in pairs( extratags ) do
			if ( v == "" ) then continue end
			table.insert( tags, v )
		end

		if ( type == "local" ) then
			return self:FetchLocal( offset, perpage )
		end
		if ( type == "subscribed" ) then
			return self:FetchSubscribed( offset, perpage, tags, searchText, false, filter, sort )
		end
		if ( type == "subscribed_ugc" ) then
			return self:FetchSubscribed( offset, perpage, tags, searchText, true, filter, sort )
		end
		if ( type == "downloaded_ugc" ) then
			return self:FetchDownloadedUGC( offset, perpage )
		end

		local userid = "0"
		if ( type == "mine" ) then userid = "1" end

		local cachename = type .. "-" .. table.concat( tags, "/" ) .. offset .. "-" .. perpage .. "-" .. userid

		if ( type != "favorite" && ListCache[ cachename ] ) then
			self:FillFileInfo( ListCache[ cachename ] )
			return
		end

		steamworks.GetList( type, tags, offset, perpage, 0, userid, function( data )
			if ( type != "favorite" ) then ListCache[ cachename ] = data end
			self:FillFileInfo( data )
		end )

	end

	function ret:FetchSubscribed( offset, perpage, tags, searchText, isUGC, filter, sort )

		local subscriptions = {}
		if ( isUGC ) then
			subscriptions = engine.GetUserContent()
		else
			subscriptions = engine.GetAddons()
			if ( storedWorkshop ) then AddStoredWorkshopItems( subscriptions ) end
		end

		for id, e in pairs( subscriptions ) do
			if ( e.timeadded == 0 ) then e.timeadded = os.time() end
		end

		if ( sort == "title" ) then
			table.sort( subscriptions, function( a, b )
				return a.title:lower() < b.title:lower()
			end )
		elseif ( sort == "size" ) then
			table.sort( subscriptions, function( a, b )
				return a.size > b.size
			end )
		elseif ( sort == "updated" ) then
			table.sort( subscriptions, function( a, b )
				return a.updated > b.updated
			end )
		else
			table.sort( subscriptions, function( a, b )
				return a.timeadded > b.timeadded
			end )
		end

		-- First build a list of items that fit our search terms
		local searchedItems = {}
		local localFileHack = -1
		local query = searchText:lower()
		local hasQuery = searchText:Trim() ~= ""
		for id, item in pairs( subscriptions ) do

			-- This is a dirty hack for local addons, ideally should be done in engine, or not use solely IDs to identify addons
			if ( item.wsid == "0" ) then
				item.wsid = tostring( localFileHack ) -- why is this a string?
				localFileHack = localFileHack - 1
			end

			-- Search for tags
			local found = true
			for _, tag in pairs( tags ) do
				if ( not ( item.local_workshop and tag:lower() == "addon" ) and !item.tags:lower():find( tag, 1, true ) ) then found = false end
			end
			if ( !found ) then continue end

			-- Search for searchText
			if ( hasQuery and not item.title:lower():find( query, 1, true ) and
				not ( item.local_workshop and item.wsid:find( query, 1, true ) ) ) then
				continue
			end

			if ( item.workshop_archived and filter and filter ~= "" ) then continue end
			if ( filter && filter == "enabledonly" && !steamworks.ShouldMountAddon( item.wsid ) ) then
				continue
			end
			if ( filter && filter == "disabledonly" && steamworks.ShouldMountAddon( item.wsid ) ) then
				continue
			end

			searchedItems[ #searchedItems + 1 ] = item

		end

		-- Build the page!
		local data = {
			totalresults = #searchedItems,
			extraresults = {}, -- The local info about the addon
			otherresults = {}, -- The complete list of IDs that match the search query for the Addons menu UI
			results = {}
		}

		-- Add the list of all items for "select all" in the UI
		local i = 0
		for id, item in ipairs( searchedItems ) do
			if ( not item.workshop_archived ) then
				data.otherresults[ i ] = item.wsid
				i = i + 1
			end
		end

		-- Add the actual results for the requested range
		local p = 0
		while ( p < perpage ) do

			if ( searchedItems[ offset + p + 1 ] ) then

				local item = searchedItems[ offset + p + 1 ]
				table.insert( data.results, item.wsid )
				data.extraresults[ #data.results ] = item

			end

			p = p + 1

		end

		if ( storedWorkshop ) then data.numresults = #data.results end
		self:FillFileInfo( data, isUGC )

	end

	function ret:FetchDownloadedUGC( offset, perpage )

		local downloads = steamworks.GetDownloadedItems()

		-- Build the page!
		local data = {
			totalresults = #downloads,
			extraresults = {}, -- The local info about the addon
			otherresults = {}, -- The complete list of IDs that match the search query for the Addons menu UI
			results = {}
		}

		-- Add the list of all items for "select all" in the UI
		local i = 0
		for id, itemWSID in ipairs( downloads ) do
			data.otherresults[ i ] = itemWSID
			i = i + 1
		end

		-- Add the actual results for the requested range
		local p = 0
		while ( p < perpage ) do

			if ( downloads[ offset + p + 1 ] ) then

				table.insert( data.results, downloads[ offset + p + 1 ] )

			end

			p = p + 1

		end

		self:FillFileInfo( data )

	end

	function ret:RetrieveUserName( steamid, func )
		steamworks.RequestPlayerInfo( steamid, function( name )
			self.HTML:Call( namespace .. ".ReceiveUserName( \"" .. steamid:JavascriptSafe() .. "\", \"" .. name:JavascriptSafe() .. "\" )" )
			if ( func ) then func( name ) end
		end )
	end

	function ret:FillFileInfo( results, isUGC )

		--
		-- File info failed..
		--
		if ( !results ) then return end

		--
		-- Send the file index..
		--
		local json = util.TableToJSON( results, false )
		self.HTML:Call( namespace .. ".ReceiveIndex( " .. json .. " )" )

		--
		-- Request info on each file..
		--
		for k, v in pairs( results.results ) do

			local extra = results.extraresults and results.extraresults[ k ]
			if ( storedWorkshop and extra and extra.local_workshop ) then
				local html = self.HTML
				local wsid = v
				local function receive( details )
					if ( not details and not extra.workshop_archived ) then return end
					local info = { title = extra.title }
					if ( details ) then
						if ( type( details.title ) == "string" and details.title ~= "" ) then
							info.title = details.title
						end
						if ( type( details.description ) == "string" ) then
							info.description = CleanWorkshopDescription( details.description )
						end
						WorkshopNames[ wsid ] = { title = info.title, tags = type( details.tags ) == "string" and details.tags or nil }
						local ext = type( details.preview ) == "string" and
							details.preview:match( "^%.cache/workshop/" .. wsid .. "/preview%.(%a+)$" )
						if ( ext == "jpg" or ext == "png" ) then
							info.preview = details.preview
						end
					end
					if ( self.HTML ~= html or not IsValid( html ) ) then return end
					local payload = util.TableToJSON( { id = wsid, info = info }, false )
					html:Call( namespace .. ".ReceiveStoredWorkshopInfo( " .. payload .. " )" )
				end

				HL2SBWorkshopInfo( wsid, receive )
				if ( extra.workshop_archived ) then continue end
			end

			v = v:JavascriptSafe()

			--
			-- Got it cached?
			--
			if ( PreviewCache[ v ] ) then

				self.HTML:Call( namespace .. ".ReceiveImage( \"" .. v .. "\", \"" .. PreviewCache[ v ] .. "\" )" )

			end

			--
			-- Get the file information
			--
			if ( tonumber( v ) <= 0 ) then

				-- Local addon
				local extra = results.extraresults[ k ]
				if ( !extra ) then extra = {} end

				extra.ownername = "Local"
				extra.description = "Non workshop .gma addon. (" .. extra.file .. ")"
				extra.floating = true

				local jsonExtra = util.TableToJSON( extra, false )

				self.HTML:Call( namespace .. ".ReceiveFileInfo( \"" .. v .. "\", " .. jsonExtra .. " )" )
				self.HTML:Call( namespace .. ".ReceiveImage( \"" .. v .. "\", \"html/img/localaddon.png\" )" )

				-- Do not try to get votes for this one
				continue

			elseif ( InfoCache[ v ] ) then

				self.HTML:Call( namespace .. ".ReceiveFileInfo( \"" .. v .. "\", " .. InfoCache[ v ] .. " )" )

				if ( MENU_DLL ) then
					-- This could've changed..
					steamworks.FileUserInfo( v, function( info )
						if ( info.error ) then return end

						local localUI = util.TableToJSON( info, false )
						self.HTML:Call( namespace .. ".ReceiveFileUserInfo( \"" .. v .. "\", " .. localUI .. " )" )
					end )
				end

			else

				steamworks.FileInfo( v, function( result )

					if ( !result || result.error != nil ) then
						-- Try to get the title from the GetAddons(), this probably could be done more efficiently
						local title = "Offline addon"
						for id, t in pairs( isUGC && engine.GetUserContent() || engine.GetAddons() ) do
							if ( tonumber( v ) == tonumber( t.wsid ) ) then title = t.title break end
						end

						local jsonErr = util.TableToJSON( { title = title, description = "Failed to get addon info, error code " .. ( result && result.error || "unknown" ) }, false )
						self.HTML:Call( namespace .. ".ReceiveFileInfo( \"" .. v .. "\", " .. jsonErr .. " )" )
						return
					end

					if ( result.description ) then
						result.description = CleanWorkshopDescription( result.description )
					end

					if ( result.owner && ( !result.ownername || result.ownername == "" || result.ownername == "[unknown]" ) ) then
						self:RetrieveUserName( result.owner, function( name )
							result.ownername = name

							local jsonUN = util.TableToJSON( result, false )
							InfoCache[ v ] = jsonUN
						end )
					end

					local jsonFI = util.TableToJSON( result, false )
					InfoCache[ v ] = jsonFI
					self.HTML:Call( namespace .. ".ReceiveFileInfo( \"" .. v .. "\", " .. jsonFI .. " )" )

					--
					-- Now we have the preview id - get the preview image!
					--
					if ( !PreviewCache[ v ] && result.previewid ) then

						steamworks.Download( result.previewid, false, function( name )

							-- Download failed
							if ( !name ) then return end

							PreviewCache[ v ] = name:JavascriptSafe()
							self.HTML:Call( namespace .. ".ReceiveImage( \"" .. v .. "\", \"" .. PreviewCache[ v ] .. "\" )" )

						end )

					end

					if ( MENU_DLL ) then
						steamworks.FileUserInfo( v, function( info )
							if ( info.error ) then return end

							local localUI = util.TableToJSON( info, false )
							self.HTML:Call( namespace .. ".ReceiveFileUserInfo( \"" .. v .. "\", " .. localUI .. " )" )
						end )
					end

				end )
			end

		end

	end

	function ret:Publish( filename, image )

		--MsgN( "PUBLISHING ", filename )
		--MsgN( "Image ", image )

		local window = vgui.Create( "UGCPublishWindow" )
		window:Setup( namespace, filename, image, self )
		window:MakePopup()
		window:DoModal() -- We want the user to either finish this or quit

	end

	return ret

end
