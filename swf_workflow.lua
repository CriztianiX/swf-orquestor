local class = require("class")
local SWF = require("swf")
local config = require("config")
local dkjson = require "dkjson"
local ansicolors = require "ansicolors"

local activities = {
  activity_get_segment =  require("activities.activity_get_segment"):new(),
  activity_push_segment =  require("activities.activity_push_segment"):new()
}

local id = function()
  local handle = io.popen([[date +%s]])
  return string.gsub(handle:read("*a"), "\n", "")
end

return class.SwfWorkflow {
  complete_workflow_execution = function(self, task_token)
    print(ansicolors('%{cyan}+++ Workflow execution finished.'))
    status, data = SWF:respondDecisionTaskCompleted({
      taskToken = task_token,
      decisions = {
        {
          decisionType = "CompleteWorkflowExecution",
          completeWorkflowExecutionDecisionAttributes = {
            result = 'All done!'
          }
        }
      }
    })
  end,
  --
  -- Schedule a new activity task
  schedule_activity_task = function(self, task_token, activity_type)
    return SWF:respondDecisionTaskCompleted({
      taskToken = task_token,
      decisions = {
        {
          decisionType = "ScheduleActivityTask",
          scheduleActivityTaskDecisionAttributes = {
            activityId = id(),
            activityType = activity_type,
            taskList = {
              name = config.swf.task_list
            }
          }
        }
      }
    })
  end,
  -- The worker
  -- Launch the activities
  poll_for_activities = function(self)
    local ok, data = SWF:pollForActivityTask({
      domain = config.swf.domain,
      taskList = {
        name = config.swf.task_list
      }
    })

    -- Run the activity
    if ok and data.taskToken then
      local activity_name = data.activityType.name
      print(ansicolors('%{blue}+++ Running activity task ' ..
        activity_name ))
      activities[activity_name]:run(data)
    end
  end,
  -- The decider
  poll_for_decisions = function(self)
    local ok, res = SWF:pollForDecisionTask({
      domain = config.swf.domain,
      taskList = {
        name = config.swf.task_list
      },
      identify = "default",
      maximumPageSize = 50,
      reverseOrder = true
    })

    -- Start decider desicions
    if ok and res.events then
      local task_token = res.taskToken
      -- Start loop envents
      for _,event in ipairs(res.events) do
        local event_id = event.eventType
        if event_id == "ActivityTaskCompleted" then
          print(ansicolors('%{magenta}+++ Activity task completed'))
          if event.activityTaskCompletedEventAttributes and
            event.activityTaskCompletedEventAttributes.result then
              local result = dkjson.decode(event.activityTaskCompletedEventAttributes.result)
              -- Start Next Activity
              if not result.next then
                self:complete_workflow_execution(task_token)
              end

              if result.next and result.next == true then
                print(ansicolors('%{magenta}+++ Jumping workflow step'))
                self:schedule_activity_task(task_token, result.activityType)
              end
              -- End Next Activity
            end
            break
        end
        if event_id == "WorkflowExecutionStarted" then
          print(ansicolors('%{cyan}+++ workflow execution started.'))
          self:schedule_activity_task(task_token, {
            name = "activity_get_segment",
            version = "v3"
          })
          break
        end
        -- End WorkflowExecutionStarted
      end
      -- End loop events
    end
    -- End decider desicions
  end,
  start_execution = function(self)
    self:poll_for_decisions()
  end
}
