local SWF = require "swf"
local config = require "config"
local dkjson = require "dkjson"
local class = require ('class')
local ActivityBase = require ('activities.activity_base')
return class.ActivityGetSegment.extends(ActivityBase) {
  run = function(self, res)
    os.execute("sleep " .. 1)
    local task_token = res.taskToken
    return self.__aws:respondActivityTaskCompleted({
      taskToken = task_token,
      result = dkjson.encode({
        next = true,
        activityType = {
          name = "activity_push_segment",
          version = "v2"
        }
      })
    })
  end
}
