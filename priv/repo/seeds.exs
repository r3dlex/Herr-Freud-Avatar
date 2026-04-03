# priv/repo/seeds.exs
alias HerrFreud.Repo

if Repo.aggregate("SELECT COUNT(*) FROM interaction_styles", :count) == 0 do
  now = {{2026, 4, 3}, {0, 0, 0}} |> NaiveDateTime.new!() |> DateTime.from_naive!("UTC")

  Repo.insert_all("interaction_styles", [
    %{
      id: Ecto.UUID.generate(),
      name: "single_question",
      description: "Herr Freud listens fully, reflects briefly, then asks exactly one question. No follow-up until the next session. Best for patients who need space.",
      active: true,
      config: Jason.encode!(%{type: "single_question", follow_up_enabled: false, reflection_length: "brief"})
    },
    %{
      id: Ecto.UUID.generate(),
      name: "conversational",
      description: "Herr Freud engages in a back-and-forth exchange within the same session. Best for active processors.",
      active: false,
      config: Jason.encode!(%{type: "conversational", follow_up_enabled: true, max_turns: 10, close_on_signal: true})
    },
    %{
      id: Ecto.UUID.generate(),
      name: "structured_intake",
      description: "Herr Freud works through a configurable set of themes per session. Best for patients who benefit from structure.",
      active: false,
      config: Jason.encode!(%{type: "structured_intake", themes: ["mood", "sleep", "relationships", "work", "body"], questions_per_theme: 1})
    }
  ])
end
