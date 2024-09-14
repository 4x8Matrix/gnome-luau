local Shell = require("@src/Shell")

local GnomeLuau = {}

function GnomeLuau.GetGnomeShell(_: GnomeLuau)
	return Shell.new()
end

export type GnomeLuau = typeof(GnomeLuau)

return GnomeLuau
