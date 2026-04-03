defmodule HerrFreud.Memory.Distiller do
  @moduledoc """
  Extracts key memory statements from a session transcript using the LLM.
  """


  @doc """
  Distill 1-3 memory statements from a session transcript.
  Returns {:ok, [memory_string]} or {:error, reason}.
  """
  def distill(transcript, _opts \\ []) do
    prompt = build_distillation_prompt(transcript)

    messages = [
      %{
        role: "system",
        content: """
        You are a therapeutic memory extractor. From the session transcript below,
        extract 1 to 3 concise, important memory statements that capture key themes,
        emotions, relationships, or insights from the session.

        Format your response as a JSON array of strings. Each string should be a
        standalone memory statement in English, no more than 2 sentences.

        Example output: ["Patient expressed ongoing conflict with their brother about boundaries.", "Patient mentioned they haven't been sleeping well for the past week."]
        """
      },
      %{role: "user", content: prompt}
    ]

    llm_mod = Application.get_env(:herr_freud, :llm_mod, HerrFreud.LLM.MiniMax)

    case apply(llm_mod, :chat, [messages, [temperature: 0.3, max_tokens: 512]]) do
      {:ok, response} ->
        parse_distillation_response(response)

      {:error, _} = error ->
        error
    end
  end

  defp build_distillation_prompt(transcript) do
    """
    Session Transcript:
    #{transcript}

    Extract the key therapeutic memories from this session.
    """
  end

  defp parse_distillation_response(response) do
    # Try to parse as JSON array
    case Jason.decode(response) do
      {:ok, memories} when is_list(memories) ->
        {:ok, Enum.map(memories, &String.trim/1)}

      _ ->
        # Fallback: try to extract lines that look like memories
        memories =
          response
          |> String.split("\n")
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.take(3)

        {:ok, memories}
    end
  end
end
