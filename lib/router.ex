defmodule Router do
  use Plug.Router
  use Plug.ErrorHandler
  import Rackla

  plug :match
  plug :dispatch

  # =========================================== #
  # Below is a collection of sample end-points. #
  # =========================================== #

  # get "/proxy" do
  #   conn.query_string
  #   |> request
  #   |> response
  # end
  #
  # get "/proxy/gzip" do
  #   conn.query_string
  #   |> request
  #   |> response(compress: true)
  # end
  #
  # get "/proxy/multi" do
  #   String.split(conn.query_string, "|")
  #   |> request
  #   |> response
  # end
  #
  # get "/proxy/set-headers" do
  #   conn.query_string
  #   |> request
  #   |> response(headers: %{"Rackla" => "CrocodilePear"})
  # end
  #
  # get "/proxy/concat-json" do
  #   conn.query_string
  #   |> request
  #   |> concatenate_json
  #   |> response
  # end
  #
  # get "/proxy/invalid-transform" do
  #   invalid_transform = fn(response) ->
  #     Dict.get!(response, :nope)
  #   end
  #
  #   conn.query_string
  #   |> request
  #   |> transform(invalid_transform)
  #   |> concatenate_json
  #   |> response
  # end
  #
  # get "/proxy/multi/concat-json" do
  #   String.split(conn.query_string, "|")
  #   |> request
  #   |> concatenate_json
  #   |> response
  # end
  #
  # get "/proxy/multi/concat-json/body-only" do
  #   String.split(conn.query_string, "|")
  #   |> request
  #   |> concatenate_json(body_only: true)
  #   |> response
  # end
  #
  # get "/proxy/transform/blanker" do
  #   blanker = fn(response) ->
  #     response
  #     |> Map.update!(:status, fn(_) -> 404 end)
  #     |> Map.update!(:headers, fn(_) -> %{} end)
  #     |> Map.update!(:body, fn(_) -> "" end)
  #     |> Map.update!(:meta, fn(_) -> %{} end)
  #   end
  #
  #   request(conn.query_string)
  #   |> transform(blanker)
  #   |> response
  # end
  #
  # get "/proxy/transform/identity" do
  #   identity = fn(response) ->
  #     response
  #     |> Map.update!(:status, fn(x) -> x end)
  #     |> Map.update!(:headers, fn(x) -> x end)
  #     |> Map.update!(:body, fn(x) -> x end)
  #     |> Map.update!(:meta, fn(x) -> x end)
  #   end
  #
  #   request(conn.query_string)
  #   |> transform(identity)
  #   |> response
  # end
  #
  # get "/proxy/transform/multi" do
  #   func_creator = fn(key) ->
  #     fn(response) ->
  #       Map.update!(response, :body, fn(body) ->
  #         body[key]
  #       end)
  #     end
  #   end
  #
  #   uris = String.split(conn.query_string, "|")
  #   funcs =
  #     ["key-a", "key-b", "key-c", "key-d"]
  #     |> Enum.map(func_creator)
  #
  #   request(uris)
  #   |> transform(funcs, json: true)
  #   |> response
  # end
  #
  # get "/temperature" do
  #   uris =
  #     String.split(conn.query_string, "|")
  #     |> Enum.map(&("http://api.openweathermap.org/data/2.5/weather?q=#{&1}"))
  #
  #   temperature_extractor = fn(item) ->
  #     Map.update!(item, :body, fn(body) ->
  #       response_body = Poison.decode!(body)
  #
  #       Map.put(%{}, response_body["name"], response_body["main"]["temp"])
  #       |> Poison.encode!
  #     end)
  #   end
  #
  #   uris
  #   |> request
  #   |> transform(temperature_extractor)
  #   |> concatenate_json(body_only: true)
  #   |> response
  # end
  #
  # # Access-token from the Instagram API is required to use this end-point.
  # get "/instagram" do
  #   require Logger
  #
  #   binary_to_img = fn(item) ->
  #     Map.update!(item, :body, fn(body) ->
  #       "<img src=\"data:image/jpeg;base64,#{Base.encode64(body)}\" height=\"150px\" width=\"150px\">"
  #     end)
  #   end
  #
  #   chunk_status =
  #     conn
  #       |> send_chunked(200)
  #       |> chunk("<!doctype html><html lang=\"en\"><head></head><body>")
  #
  #   conn =
  #     case chunk_status do
  #       {:ok, new_conn} ->
  #         new_conn
  #
  #       {:error, reason} ->
  #         Logger.error("Unable to chunk response: #{reason}")
  #         conn
  #     end
  #
  #   conn =
  #     "https://api.instagram.com/v1/users/self/feed?count=50&access_token=" <> conn.query_string
  #     |> timer("Got URL")
  #     |> request
  #     |> timer("Executed request")
  #     |> collect_response |> Enum.at(0)
  #     |> timer("Collected response")
  #     |> Map.get(:body)
  #     |> timer("Got body")
  #     |> Poison.decode!
  #     |> timer("Decoded JSON")
  #     |> Map.get("data")
  #     |> timer("Extracted data")
  #     |> Enum.map(&(&1["images"]["standard_resolution"]["url"]))
  #     |> timer("Mapped image url")
  #     |> request
  #     |> timer("Executed request")
  #     |> transform(binary_to_img)
  #     |> timer("Added transform function")
  #     |> response
  #     |> timer("Responded to query")
  #
  #   case chunk(conn, "</body></html>") do
  #     {:ok, new_conn} -> new_conn
  #
  #     {:error, reason} ->
  #       Logger.error("Unable to chunk response: #{reason}")
  #       conn
  #   end
  # end

  # =============================== #
  # API end-points used for testing #
  # =============================== #

  get "/api/json/foo-bar" do
    json = Poison.encode!(%{foo: "bar"})

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(200, json)
  end

  get "/api/json/no-header/foo-bar" do
    json = Poison.encode!(%{foo: "bar"})
    send_resp(conn, 200, json)
  end

  get "/api/text/foo-bar" do
    send_resp(conn, 200, "foo-bar")
  end

  get "/api/echo/:key/:value" do
    json = Map.put(%{foo: "bar", baz: "qux"}, key, value) |> Poison.encode!

    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(200, json)
  end

  match _ do
   send_resp(conn, 404, "end-point not found")
  end
end