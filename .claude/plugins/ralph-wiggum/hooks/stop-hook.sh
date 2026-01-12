#!/bin/bash

# Ralph Wiggum Stop Hook
# This hook checks for an active Ralph loop and feeds the prompt back to continue iteration

# Check for ralph-wiggum state file (target-based loop)
if [ -f ".claude/ralph-wiggum-state.yml" ]; then
  # Extract target from state file
  target=$(grep "^target:" .claude/ralph-wiggum-state.yml | sed 's/target: *//')
  iteration=$(grep "^iteration:" .claude/ralph-wiggum-state.yml | sed 's/iteration: *//')

  # Block and feed prompt back
  echo "BLOCK"
  echo "Ralph loop iteration $iteration for target: $target"
  echo ""
  echo "Continue improving the $target feature following the ralph-loop skill instructions."
  exit 0
fi

# Check for ralph-plan state file (plan-based loop)
if [ -f ".claude/ralph-plan-state.yml" ]; then
  # Extract plan info from state file
  plan_file=$(grep "^plan_file:" .claude/ralph-plan-state.yml | sed 's/plan_file: *//')
  current_feature=$(grep "^current_feature:" .claude/ralph-plan-state.yml | sed 's/current_feature: *//')
  current_persona=$(grep "^current_persona:" .claude/ralph-plan-state.yml | sed 's/current_persona: *//')

  # Block and feed prompt back
  echo "BLOCK"
  echo "Plan loop: Feature $current_feature, Persona pass $current_persona"
  echo ""
  echo "Continue executing the plan at $plan_file following the plan-loop skill instructions."
  exit 0
fi

# No active loop - allow normal stop
exit 0
