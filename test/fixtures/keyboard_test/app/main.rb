def tick(args)
  args.state.detected_key_events ||= []

  # Detect common test keys
  [:a, :space, :enter, :f1].each do |key|
    if args.inputs.keyboard.key_down.send(key)
      args.state.detected_key_events << :"#{key}_down"
    end
    if args.inputs.keyboard.key_up.send(key)
      args.state.detected_key_events << :"#{key}_up"
    end
  end

  # Detect modifiers
  [:shift, :control, :alt, :meta].each do |mod|
    if args.inputs.keyboard.key_down.send(mod)
      args.state.detected_key_events << :"#{mod}_down"
    end
    if args.inputs.keyboard.key_up.send(mod)
      args.state.detected_key_events << :"#{mod}_up"
    end
  end
end
