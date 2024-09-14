local process = require("@src/IPC/Process")

return function(interface: string, property: string, type: string, value: string)
	local object = process.new("dbus-send", {
		`--session`,
		`--dest=org.freedesktop.DBus`,
		`--type=method_call`,
		`/org/freedesktop/DBus`,
		`org.freedesktop.DBus.Properties.Set`,
		`string:{interface}`,
		`string:{property}`,
		`{type}:{value}`,
	})

	local returnedValue: string

	object:Execute(function(response)
		if not response.Ok then
			error(`IPC-SHELL: {response.Code} - {response.Error}`)
		end

		returnedValue = response.Output
	end)

	return returnedValue
end
