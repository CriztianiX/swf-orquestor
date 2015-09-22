local AWS = require ('lua-aws')
local config = require("config").aws
AWS = AWS.new(config)

return AWS.SWF:api()
