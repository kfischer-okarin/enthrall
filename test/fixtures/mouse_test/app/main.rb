def tick(args)
  args.state.detected_mouse_events ||= []
  args.state.timed_mouse_events ||= []

  detect_mouse_events(args, :left)
  detect_mouse_events(args, :middle)
  detect_mouse_events(args, :right)
end

def detect_mouse_events(args, button)
  buttons = args.inputs.mouse.buttons.send(button)
  if buttons.click
    args.state.detected_mouse_events << :"#{button}_click"
    args.state.timed_mouse_events << {event: :"#{button}_click", tick: args.state.tick_count}
  end
  if buttons.up
    args.state.detected_mouse_events << :"#{button}_up"
    args.state.timed_mouse_events << {event: :"#{button}_up", tick: args.state.tick_count}
  end
end
