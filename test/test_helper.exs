ExUnit.start()

# Start the HerrFreud application for tests
try do
  HerrFreud.Application.start(:normal, [])
rescue
  _ ->
    :ok
end
