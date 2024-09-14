local luneProcess = require("@lune/process")

local Process = {}

Process.Interface = {}
Process.Prototype = {}

function Process.Prototype.Execute(self: Process, callback: (ProcessResult) -> ()?)
	local result = luneProcess.spawn(self.name, self.arguments)

	self.result = table.freeze({
		Ok = result.ok,
		Code = result.code,
		Output = result.stdout,
		Error = result.stderr,
	})

	if callback then
		callback(self.result :: ProcessResult)
	end
end

function Process.Interface.new(processName: string, processArguments: { string }?)
	return setmetatable(
		{
			name = processName,
			arguments = processArguments or {},
		} :: Process,
		{ __index = Process.Prototype }
	)
end

export type Process = typeof(Process.Prototype) & {
	name: string,
	arguments: { string },

	result: ProcessResult?,
}

export type ProcessResult = {
	Ok: boolean,
	Code: number,
	Output: string,
	Error: string,
}

return Process.Interface
