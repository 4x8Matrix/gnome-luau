local process = require("@src/IPC/Process")

return function()
	local object = process.new("gdbus", {
		`introspect`,
		`--session`,
		`--dest`,
		`org.gnome.Shell`,
		`--object-path`,
		`/org/gnome/Shell`,
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
