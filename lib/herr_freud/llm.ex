defmodule HerrFreud.LLM do
  @moduledoc """
  Behaviour for LLM providers.

  Implement this behaviour to add a new LLM provider.
  """

  @type message :: %{
          required(:role) => String.t(),
          required(:content) => String.t()
        }

  @type chat_result :: {:ok, String.t()} | {:error, term()}
  @type translate_result :: {:ok, String.t()} | {:error, term()}

  @doc """
  Send a chat message and receive a response.
  """
  @callback chat(messages :: [message()], opts :: keyword()) :: chat_result()

  @doc """
  Translate text from one language to another.
  """
  @callback translate(text :: String.t(), from_lang :: String.t(), to_lang :: String.t()) ::
            translate_result()
end
