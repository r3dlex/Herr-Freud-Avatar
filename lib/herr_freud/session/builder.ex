defmodule HerrFreud.Session.Builder do
  @moduledoc """
  Builds the system prompt for a session.
  """

  @doc """
  Build a full system prompt for the LLM.

  Args:
    - active_style: %HerrFreud.InteractionStyle{} or nil
    - patient_profile: %{key => value} map
    - memories: [%HerrFreud.Memory.Memory{}]
    - transcript: String (English transcript)
    - companion_notes: String.t() or nil
  """
  def build_system_prompt(active_style, patient_profile, memories, transcript, companion_notes \\ nil)

  def build_system_prompt(_active_style, _patient_profile, _memories, transcript, _companion_notes)
      when is_binary(transcript) and byte_size(transcript) == 0 do
    {:error, :empty_transcript}
  end

  def build_system_prompt(active_style, patient_profile, memories, transcript, companion_notes)
      when is_map(patient_profile) and is_list(memories) do
    profile_section = build_profile_section(patient_profile)
    memories_section = build_memories_section(memories)
    style_section = build_style_section(active_style)

    prompt = """
    You are Herr Freud — a therapeutic agent combining psychoanalysis, psychiatry,
    and compassionate listening. Your goal is to help the patient reach a state of
    happiness and stability.

    #{style_section}

    #{profile_section}

    #{memories_section}

    Today's diary entry (English):
    #{transcript}

    #{if companion_notes, do: "Companion notes from patient:\n#{companion_notes}", else: ""}

    Respond according to your current style. Be warm, precise, and unhurried.
    Never give medical diagnoses. Never prescribe medication. If the patient
    expresses acute crisis, respond with calm support and direct them to a
    human professional immediately.
    """

    {:ok, String.trim(prompt)}
  end

  defp build_style_section(nil) do
    "Current interaction style: single_question (default)\nA gentle, question-based approach."
  end

  defp build_style_section(%{name: name, description: desc, config: config}) do
    config_map = if is_binary(config), do: Jason.decode!(config), else: config
    type = config_map["type"] || name

    """
    Current interaction style: #{name}
    #{desc}
    Style type: #{type}
    """
  end

  defp build_profile_section(profile) when map_size(profile) == 0 do
    "Patient profile (known facts):\nNo profile information yet."
  end

  defp build_profile_section(profile) do
    entries = Enum.map_join(profile, "\n", fn {k, v} -> "  - #{k}: #{v}" end)
    "Patient profile (known facts):\n#{entries}"
  end

  defp build_memories_section([]) do
    "Memories from previous sessions:\nNo previous sessions."
  end

  defp build_memories_section(memories) do
    numbered = memories |> Enum.with_index(1) |> Enum.map_join("\n", fn {m, i} -> "#{i}. #{m.content}" end)
    "Memories from previous sessions (most relevant first):\n#{numbered}"
  end

  @doc """
  Build the nudge generation prompt.
  """
  def build_nudge_prompt(profile, recent_memories) do
    profile_section = build_profile_section(profile)
    memories_section = build_memories_section(recent_memories)

    """
    You are Herr Freud, a gentle therapeutic companion.

    The patient has not logged a session in a few days. Write a warm, non-intrusive
    nudge to encourage them to share.

    Patient profile:
    #{profile_section}

    Recent memories:
    #{memories_section}

    The nudge should:
    - Be warm and understanding, not pushy
    - Reference something specific from the profile or recent memories
    - End with a gentle, open question
    - Be no more than 3-4 sentences
    - Be in English
    """
  end
end