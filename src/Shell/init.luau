local setProperty = require("@src/IPC/Call/setProperty")
local callMethod = require("@src/IPC/Call/callMethod")

local Schema = require("@src/Shell/Schema")

local Shell = {}

Shell.Interface = {}
Shell.Prototype = {}

function Shell.Prototype.ReadProperty(self: Shell, interfaceName: string, propertyName: string): string
	local property = self.schema:GetProperty(interfaceName, propertyName)

	return property.value
end

function Shell.Prototype.SetProperty(self: Shell, interfaceName: string, propertyName: string, value: string): string
	local property = self.schema:GetProperty(interfaceName, propertyName)

	setProperty(interfaceName, propertyName, property.type, value)

	return property.value
end

function Shell.Prototype.GetMethod(self: Shell, interfaceName: string, methodName: string): (...any) -> ...any
	local method = self.schema:GetMethod(interfaceName, methodName)

	assert(method, `Method {methodName} doesn't exist!`)

	return function(...)
		assert(
			select("#", ...) == #method.parameters,
			`Expected {#method.parameters} arguments, but got {select("#", ...)}`
		)

		local passedArguments = { ... }
		local gdbusArguments = {}

		for index, parameter in method.parameters do
			local encodedValue = passedArguments[index]

			table.insert(gdbusArguments, `{parameter.type}:{encodedValue}`)
		end

		local response = callMethod(interfaceName, methodName, gdbusArguments)

		return response
	end
end
function Shell.Interface.new(): Shell
	return setmetatable(
		{
			schema = Schema.new(),
		} :: Shell,
		{
			__index = Shell.Prototype,
		}
	)
end

export type Shell = typeof(Shell.Prototype) & {
	schema: Schema.Schema,
}

return Shell.Interface
