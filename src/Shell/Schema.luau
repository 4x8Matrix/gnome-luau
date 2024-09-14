--[[
	Schema, providing a way for introspection of the Gnome Shell in Luau.
]]

local queryShell = require("@src/IPC/Introspect/queryShell")
local readDBusIDL = require("@src/IPC/Parsers/readDBusIDL")

local Schema = {}

Schema.Interface = {}
Schema.Prototype = {}

--[[
	Returns the parsed IDL node for a specific interface.
]]
function Schema.Prototype.GetInterface(self: Schema, interfaceName: string): readDBusIDL.Interface?
	for _, interface in self.schema.interfaces do
		if interface.name == interfaceName then
			return interface
		end
	end

	return nil
end

--[[
	Returns an array (strings) of all interfaces that are available in the Gnome Shell.
]]
function Schema.Prototype.GetInterfaces(self: Schema): { string }
	local interfaces = {}

	for _, interface in self.schema.interfaces do
		table.insert(interfaces, interface.name)
	end

	return interfaces
end

--[[
	Returns an array (strings) of all properties that are available in the interface specified.
]]
function Schema.Prototype.GetInterfaceProperties(self: Schema, interfaceName: string): { string }
	local interface = self:GetInterface(interfaceName)
	local properties = {}

	assert(interface ~= nil, `Interface '{interface}' does not exist!`)

	for _, property in interface.properties do
		table.insert(properties, property.name)
	end

	return properties
end

--[[
	Returns an array (strings) of all signals that are available in the interface specified.
]]
function Schema.Prototype.GetInterfaceSignals(self: Schema, interfaceName: string): { string }
	local interface = self:GetInterface(interfaceName)
	local signals = {}

	assert(interface ~= nil, `Interface '{interface}' does not exist!`)

	for _, signal in interface.signals do
		table.insert(signals, signal.name)
	end

	return signals
end

--[[
	Returns an array (strings) of all methods that are available in the interface specified.
]]
function Schema.Prototype.GetInterfaceMethods(self: Schema, interfaceName: string): { string }
	local interface = self:GetInterface(interfaceName)
	local methods = {}

	assert(interface ~= nil, `Interface '{interface}' does not exist!`)

	for _, method in interface.methods do
		table.insert(methods, method.name)
	end

	return methods
end

--[[
	Returns the parsed IDL node for a specific property, the property is determined via the
	interfaceName & interfaceProperty provided.
]]
function Schema.Prototype.GetProperty(self: Schema, interfaceName: string, propertyName: string)
	local interface = self:GetInterface(interfaceName)

	assert(interface ~= nil, `Interface '{interface}' does not exist!`)

	local property: readDBusIDL.Property

	for _, interfaceProperty in interface.properties do
		if interfaceProperty.name == propertyName then
			property = interfaceProperty
		end
	end

	assert(property ~= nil, `Property '{propertyName}' does not exist in interface '{interface}'!`)

	return property
end

--[[
	Returns the parsed IDL node for a specific signal, the signal is determined via the
	interfaceName & signalName provided.
]]
function Schema.Prototype.GetSignal(self: Schema, interfaceName: string, signalName: string)
	local interface = self:GetInterface(interfaceName)

	assert(interface ~= nil, `Interface '{interface}' does not exist!`)

	local signal: readDBusIDL.Signal

	for _, interfaceSignal in interface.signals do
		if interfaceSignal.name == signalName then
			signal = interfaceSignal
		end
	end

	assert(signal ~= nil, `Signal '{signalName}' does not exist in interface '{interface}'!`)

	return signal
end

--[[
	Returns the parsed IDL node for a specific method, the method is determined via the
	interfaceName & methodName provided.
]]
function Schema.Prototype.GetMethod(self: Schema, interfaceName: string, methodName: string)
	local interface = self:GetInterface(interfaceName)

	assert(interface ~= nil, `Interface '{interface}' does not exist!`)

	local method: readDBusIDL.Method

	for _, interfaceMethod in interface.methods do
		if interfaceMethod.name == methodName then
			method = interfaceMethod
		end
	end

	assert(method ~= nil, `method '{methodName}' does not exist in interface '{interface}'!`)

	return method
end

--[[
	Fetch the latest Schema.
]]
function Schema.Prototype.UpdateSchema(self: Schema)
	local shellInformation = queryShell()
	local shellData = readDBusIDL(shellInformation)[1]

	self.schema = shellData
end

--[[
	Constructor for the Schema object.
]]
function Schema.Interface.new(): Schema
	local shellInformation = queryShell()
	local shellData = readDBusIDL(shellInformation)[1]

	local self = setmetatable(
		{
			schema = shellData,
		} :: Schema,
		{
			__index = Schema.Prototype,
		}
	)

	return self
end

export type Schema = typeof(Schema.Prototype) & {
	schema: readDBusIDL.Node,
}

return Schema.Interface
