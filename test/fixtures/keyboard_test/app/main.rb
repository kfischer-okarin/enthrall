def tick(args)
  args.state.detected_key_events ||= []
  args.state.timed_key_events ||= []

  # Detect common test keys
  [:a, :space, :enter, :f1].each do |key|
    if args.inputs.keyboard.key_down.send(key)
      args.state.detected_key_events << :"#{key}_down"
      args.state.timed_key_events << {event: :"#{key}_down", tick: args.state.tick_count}
    end
    if args.inputs.keyboard.key_up.send(key)
      args.state.detected_key_events << :"#{key}_up"
      args.state.timed_key_events << {event: :"#{key}_up", tick: args.state.tick_count}
    end
  end

  # Detect modifiers
  [:shift, :control, :alt, :meta].each do |mod|
    if args.inputs.keyboard.key_down.send(mod)
      args.state.detected_key_events << :"#{mod}_down"
      args.state.timed_key_events << {event: :"#{mod}_down", tick: args.state.tick_count}
    end
    if args.inputs.keyboard.key_up.send(mod)
      args.state.detected_key_events << :"#{mod}_up"
      args.state.timed_key_events << {event: :"#{mod}_up", tick: args.state.tick_count}
    end
  end
end
