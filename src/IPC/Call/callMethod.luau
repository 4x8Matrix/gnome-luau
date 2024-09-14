local process = require("@src/IPC/Process")

return function(interface: string, method: string, args: { string })
	local processArgs = {
		`call`,
		`--session`,
		`--dest=org.gnome.Shell`,
		`--object-path`,
		`/org/gnome/Shell`,
		`--method`,
		`{interface}.{method}`,
	}

	for _, argument in args do
		table.insert(processArgs, argument)
	end

	local object = process.new("gdbus", processArgs)

	local returnedValue: string

	object:Execute(function(response)
		if not response.Ok then
			error(`IPC-SHELL: {response.Code} - {response.Error}`)
		end

		returnedValue = response.Output
	end)

	return returnedValue
end
