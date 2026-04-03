defmodule HerrFreud.Memory.Session do
  use Ecto.Schema

  @primary_key {:id, :string, autogenerate: false}
  schema "sessions" do
    field :inserted_at, :utc_datetime
    field :date, :date
    field :input_mode, :string
    field :source_lang, :string
    field :raw_transcript, :string
    field :english_transcript, :string
    field :response, :string
    field :style_used, :string
    field :embedding, :binary
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    @dialyzer {:nowarn_function, encode: 2}
    def encode(struct, opts) do
      Jason.encode!(%{
        id: struct.id,
        date: struct.date,
        input_mode: struct.input_mode,
        source_lang: struct.source_lang,
        english_transcript: struct.english_transcript,
        response: struct.response,
        style_used: struct.style_used
      }, opts)
    end
  end
end
