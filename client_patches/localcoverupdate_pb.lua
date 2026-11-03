local protobuf = require("protobuf")
local each = ipairs
module("localcoverupdate_pb")

local message = protobuf.Descriptor()
local fields = {}
for i, spec in each({{"mask", 100}, {"masters", 101}}) do
    local field = protobuf.FieldDescriptor()
    field.name = spec[1]
    field.full_name = ".LocalCoverUpdate."..spec[1]
    field.number = spec[2]
    field.index = i-1
    field.label = 1
    field.has_default_value = false
    field.default_value = ""
    field.type = 12
    field.cpp_type = 9
    fields[i] = field
end
message.name = "LocalCoverUpdate"
message.full_name = ".LocalCoverUpdate"
message.nested_types = {}
message.enum_types = {}
message.fields = fields
message.is_extendable = false
message.extensions = {}
LocalCoverUpdate = protobuf.Message(message)
