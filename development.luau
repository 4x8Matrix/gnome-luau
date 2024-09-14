local GnomeLuau = require("@src/")

local Shell = GnomeLuau:GetGnomeShell()

local Schema = Shell.schema

-- OverviewActive is READWRITE

-- while true do
-- 	Shell.schema:UpdateSchema()
-- 	print(Shell:ReadProperty("org.gnome.Shell", `OverviewActive`))
-- end

-- print(Schema:GetInterface("org.gnome.Shell.Extensions"))

local e = Shell:GetMethod(`org.gnome.Shell.Extensions`, `UninstallExtension`)
print(e(`system-monitor@gnome-shell-extensions.gcampax.github.com`))

--[[

print(listExtensions())
]]
