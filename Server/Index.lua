-- A simple first come, first served queue: when the server is full, new connections wait on the loading screen until a slot frees up
Queue = {
	-- List of queued players
	connections = {},

	-- Message on loading screen
	queue_message = Server.GetCustomSettings().queue_message
}

Package.Export("Queue", Queue)

if (type(Queue.queue_message) ~= "string") then
	Queue.queue_message = "server is full. you are {position} of {size} in the queue"
end

local function GetMessage(position)
	return (Queue.queue_message:gsub("{position}", tostring(position)):gsub("{size}", tostring(#Queue.connections)))
end

local function ProcessQueue()
	-- Drops anyone who gave up waiting (closed the game or lost connection)
	local held = {}
	for _, connection in ipairs(Server.GetHeldConnections()) do
		held[connection.steam_id] = true
	end

	for i = #Queue.connections, 1, -1 do
		if (not held[Queue.connections[i]]) then
			table.remove(Queue.connections, i)
		end
	end

	-- Lets in as many players from the front of the line as there are free slots
	while (Queue.connections[1] and Server.ReleaseConnection(Queue.connections[1])) do
		table.remove(Queue.connections, 1)
	end

	-- Tells everyone still waiting their new position
	for position, steam_id in ipairs(Queue.connections) do
		Server.HoldConnection(steam_id, GetMessage(position))
	end
end

Server.Subscribe("PlayerConnect", function(_, _, _, steam_id)
	-- Everyone goes through the line, so the engine's own slot count decides who gets in (with a free slot, the player is let in right away)
	if (not Server.HoldConnection(steam_id, GetMessage(#Queue.connections + 1))) then return end

	table.insert(Queue.connections, steam_id)

	ProcessQueue()
end)

-- A player leaving frees a slot, so the next one in line can join right away
Server.Subscribe("PlayerDisconnect", ProcessQueue)

Package.Subscribe("Load", function()
	-- Held connections survive a package reload, so they go back in line (not necessarily in their previous order)
	for _, connection in ipairs(Server.GetHeldConnections()) do
		table.insert(Queue.connections, connection.steam_id)
	end

	-- Also checks periodically, in case a slot frees up some other way
	Timer.SetInterval(ProcessQueue, 3000)

	ProcessQueue()
end)
