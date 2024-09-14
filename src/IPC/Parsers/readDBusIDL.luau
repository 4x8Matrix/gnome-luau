local Stream = require("@extern/stream")

local GNOME_TYPE_MAP = table.freeze({
	["b"] = "boolean",
	["s"] = "string",
	["i"] = "int",
	["u"] = "uint",
	["v"] = "variant",
	["a"] = "array",
})

local GNOME_TYPE_TOKENS = table.freeze({
	"{",
	"}",
	"(",
	")",
})

local function readParameter(source: string): Parameter
	local parameter: any = {}
	local sourceStream = Stream.new(source)

	parameter.type = sourceStream:advanceUntil(function(char)
		return char == " "
	end)

	parameter.type = string.sub(parameter.type, 1, #parameter.type - 1)

	local isSingleType = #parameter.type == 1

	parameter.name = sourceStream:readUntilEnd()

	parameter.type = string.gsub(parameter.type, ".", function(char)
		if table.find(GNOME_TYPE_TOKENS, char) then
			return `{char} `
		end

		if not GNOME_TYPE_MAP[char] then
			warn(`Unknown type '{char}'`)
		end

		return `{GNOME_TYPE_MAP[char] or char}{isSingleType and "" or " "}`
	end)

	if string.sub(parameter.type, -1) == " " then
		parameter.type = string.sub(parameter.type, 1, #parameter.type - 1)
	end

	return parameter
end

local function readMethod(stream: Stream.Stream): Method
	local method: any = {}
	local source = stream:advanceUntil(function(char)
		return char == ";"
	end) :: string

	local sourceStream = Stream.new(source)

	method.parameters = {}

	method.name = sourceStream:advanceUntil(function(char)
		return char == "("
	end)

	while sourceStream:peek() ~= ")" do
		local stepBack = false
		local openCurlyBrackets = 0
		local param = sourceStream:advanceUntil(function(char)
			if char == "(" then
				openCurlyBrackets += 1
			end

			if char == ")" then
				if openCurlyBrackets == 0 then
					stepBack = true

					return true
				end

				openCurlyBrackets -= 1
			end

			return char == ","
		end) :: string

		local paramIn = string.sub(param, 1, 2) == "in"
		local paramOut = string.sub(param, 1, 3) == "out"

		param = string.sub(param, 1, #param - 1)

		if paramIn then
			table.insert(method.parameters, readParameter(string.sub(param, 5, #param)))
		elseif paramOut then
			method.returnedValue = readParameter(string.sub(param, 5, #param))
		else
			error(`uhhh`)
		end

		if stepBack then
			sourceStream:advance(-1)
		end

		sourceStream:trim()
	end

	method.name = string.sub(method.name, 1, #method.name - 1)

	stream:advance()
	stream:trim()

	return method
end

local function readSignal(stream: Stream.Stream): Signal
	local signal: any = {}
	local source = stream:advanceUntil(function(char)
		return char == ";"
	end) :: string

	local sourceStream = Stream.new(source)

	signal.parameters = {}

	signal.name = sourceStream:advanceUntil(function(char)
		return char == "("
	end)

	while sourceStream:peek() ~= ")" do
		local stepBack = false
		local param = sourceStream:advanceUntil(function(char)
			if char == ")" then
				stepBack = true
			end

			return char == "," or char == ")"
		end) :: string

		param = string.sub(param, 1, #param - 1)

		table.insert(signal.parameters, readParameter(param))

		if stepBack then
			sourceStream:advance(-1)
		end

		sourceStream:trim()
	end

	signal.name = string.sub(signal.name, 1, #signal.name - 1)

	stream:advance()
	stream:trim()

	return signal
end

local function readProperty(stream: Stream.Stream): Property
	local property: any = {}
	local source = stream:advanceUntil(function(char)
		return char == ";"
	end) :: string

	local sourceStream = Stream.new(source)

	property.attribute = sourceStream:advanceUntil(function(char)
		return char == " "
	end)

	property.type = sourceStream:advanceUntil(function(char)
		return char == " "
	end)

	property.name = sourceStream:advanceUntil(function(char)
		return char == " "
	end)

	sourceStream:advanceUntil(function(char)
		return char == "="
	end)

	sourceStream:advance(1)

	property.value = sourceStream:advanceUntil(function(char)
		return char == ";"
	end)

	property.attribute = string.sub(property.attribute, 1, #property.attribute - 1)
	property.name = string.sub(property.name, 1, #property.name - 1)
	property.value = string.sub(property.value, 1, #property.value - 1)

	property.type = string.sub(property.type, 1, #property.type - 1)

	local isSingleType = #property.type == 1

	property.type = string.gsub(property.type, ".", function(char)
		if table.find(GNOME_TYPE_TOKENS, char) then
			return `{char} `
		end

		if not GNOME_TYPE_MAP[char] then
			warn(`Unknown type '{char}'`)
		end

		return `{GNOME_TYPE_MAP[char] or char}{isSingleType and "" or " "}`
	end)

	if string.sub(property.type, -1) == " " then
		property.type = string.sub(property.type, 1, #property.type - 1)
	end

	if property.type == "string" then
		property.value = string.sub(property.value, 2, #property.value - 1)
	end

	property.source = nil

	stream:advance()
	stream:trim()

	return property
end

local function readInterface(stream: Stream.Stream): Interface
	local interface = {}

	interface.methods = {}
	interface.signals = {}
	interface.properties = {}

	stream:advance(9)
	stream:trim()

	local line = stream:advanceUntil(function(char)
		return char == "\n"
	end) :: string

	interface.name = string.sub(line, 1, #line - 3)

	while true do
		stream:trim()

		if stream:peek(2) == "};" then
			stream:advance(2)
			stream:trim()

			break
		elseif stream:peek(8) == "methods:" then
			stream:advance(8)
			stream:trim()

			while stream:peek(8) ~= "signals:" do
				table.insert(interface.methods, readMethod(stream))
			end
		elseif stream:peek(8) == "signals:" then
			stream:advance(8)
			stream:trim()

			while stream:peek(11) ~= "properties:" do
				table.insert(interface.signals, readSignal(stream))
			end
		elseif stream:peek(11) == "properties:" then
			stream:advance(11)
			stream:trim()

			while stream:peek(2) ~= "};" do
				table.insert(interface.properties, readProperty(stream))
			end
		else
			error(`what`)
		end
	end

	stream:trim()

	return interface
end

local function readNode(stream: Stream.Stream): Node
	local node = {}

	stream:advance(4)
	stream:trim()

	local line = stream:advanceUntil(function(char)
		return char == "\n"
	end) :: string

	node.interfaces = {}
	node.name = string.sub(line, 1, #line - 3)

	stream:trim()

	while stream:peek(9) == "interface" do
		table.insert(node.interfaces, readInterface(stream))
	end

	return node
end

export type Type = "string" | "boolean"
export type Attribute = "readonly" | "readwrite"

export type Parameter = {
	type: Type,
	name: string,
}

export type Signal = {
	name: string,
	parameters: { Parameter },
}

export type Method = {
	name: string,
	parameters: { Parameter },
	returned: Parameter?,
}

export type Property = {
	attribute: Attribute,
	type: Type,
	name: string,
	value: string,
}

export type Interface = {
	methods: { Method },
	signals: { Signal },
	properties: { Property },

	name: string,
}

export type Node = {
	interfaces: { Interface },
	name: string,
}

return function(idlSource: string)
	local stream = Stream.new(idlSource)
	local nodes = {}

	while stream:peek(4) == "node" do
		table.insert(nodes, readNode(stream))
	end

	return nodes
end
