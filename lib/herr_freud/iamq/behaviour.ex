defmodule HerrFreud.IAMQ.HTTP do
  @moduledoc "Behaviour for IAMQ HTTP client"
  @callback send(message :: map()) :: :ok | {:error, term()}
  @callback poll_inbox() :: :ok
end
