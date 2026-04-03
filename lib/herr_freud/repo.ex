defmodule HerrFreud.Repo do
  use Ecto.Repo,
    otp_app: :herr_freud,
    adapter: Ecto.Adapters.SQLite3
end
