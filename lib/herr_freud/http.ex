defmodule HerrFreud.HTTP do
  @moduledoc """
  Thin wrapper around Erlang's built-in :httpc for simple HTTP calls.
  Uses no external dependencies — :inets and :ssl are part of OTP.
  Returns {:ok, %{status: integer, body: binary}} | {:error, term}.
  """

  @ssl_opts [{:ssl, [{:verify, :verify_none}]}]

  def post(url, headers, body) when is_binary(body) do
    post(url, headers, body, [])
  end

  def post(url, headers_or_opts, body_or_nil, _opts \\ []) when is_list(headers_or_opts) do
    {headers, body} = if is_binary(body_or_nil) do
      {headers_or_opts, body_or_nil}
    else
      {headers_or_opts, body_or_nil || ""}
    end
    url_cl = to_charlist(url)
    headers_cl = to_httpc_headers(headers)
    body_cl = if is_binary(body), do: to_charlist(body), else: ~c""

    case :httpc.request(:post, {url_cl, headers_cl, ~c"application/json", body_cl}, @ssl_opts, []) do
      {:ok, {{_, status, _}, _resp_headers, resp_body}} ->
        {:ok, %{status: status, body: to_string(resp_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def post(url, opts) when is_list(opts) do
    headers = Keyword.get(opts, :headers, [])
    body = Keyword.get(opts, :body, "")
    post(url, headers, body)
  end

  def get(url, headers) when is_list(headers) do
    url_cl = to_charlist(url)
    headers_cl = to_httpc_headers(headers)

    case :httpc.request(:get, {url_cl, headers_cl}, @ssl_opts, []) do
      {:ok, {{_, status, _}, _resp_headers, resp_body}} ->
        {:ok, %{status: status, body: to_string(resp_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get(url, opts) when is_list(opts) do
    headers = Keyword.get(opts, :headers, [])
    get(url, headers)
  end

  defp to_httpc_headers(headers) do
    Enum.map(headers, fn {k, v} -> {to_charlist(k), to_charlist(v)} end)
  end
end
