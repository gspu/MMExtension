local TXT = Localize{
}
table.copy(TXT, evt.str, true)

Game.MapEvtLines.Count = 0  -- Deactivate all standard events


evt.hint[1] = evt.str[1]
evt.map[1] = function()
	evt.SetDoorState{Id = 1, State = 2}         -- switch state
end

evt.hint[2] = evt.str[2]
evt.map[2] = function()
	evt.SetDoorState{Id = 2, State = 2}         -- switch state
end

evt.hint[3] = evt.str[3]
evt.map[3] = function()
	evt.SetDoorState{Id = 3, State = 2}         -- switch state
end

evt.hint[4] = evt.str[4]
evt.map[4] = function()
	evt.SetDoorState{Id = 4, State = 2}         -- switch state
end

evt.hint[5] = evt.str[5]
evt.map[5] = function()
	evt.OpenChest(1)
end

