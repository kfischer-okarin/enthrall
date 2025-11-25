def tick(args)
  args.outputs.labels << [640, 360, "Simple Test Game", 5, 1]

  # Track clicks for testing
  if args.inputs.mouse.click
    args.state.last_click = args.inputs.mouse.click
  end
end
