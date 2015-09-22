local class = require ('class')
local SWF = require("swf")

return class.ActivityBase {
  initialize = function(self)
    self.__aws = SWF
  end,
  run = function(self, data)
    print("Not implmemented")
  end
}
