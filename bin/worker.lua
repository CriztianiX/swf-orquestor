local SwfWorkflow = require "swf_workflow"
local ansicolors = require "ansicolors"
local worker = SwfWorkflow:new()

while true do
  print(ansicolors('%{green}+++ Poolling for activities'))
  worker:poll_for_activities()
end
