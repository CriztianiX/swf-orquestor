local SwfWorkflow = require "swf_workflow"
local ansicolors = require "ansicolors"
local decider = SwfWorkflow:new()

while true do
  print(ansicolors('%{green}+++ Poolling for decisions'))
  decider:start_execution()
end
