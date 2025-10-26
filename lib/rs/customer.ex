defmodule RS.Customer do
  import Journey.Node

  import RS.Helpers

  @graph_name "customer"

  def new(name, email \\ random_email(@graph_name <> "-"), timezone \\ "America/New_York") do
    customer =
      graph()
      |> Journey.start_execution()
      |> Journey.set(%{
        name: name,
        email: email,
        timezone: timezone
      })

    customer.id
  end

  def find_by_email(email) do
    Journey.list_executions(
      graph_name: @graph_name,
      filter_by: [{:email, :eq, String.downcase(email)}],
      limit: 1
    )
    |> case do
      [execution] ->
        {:ok, execution}

      [] ->
        {:error, :not_found}
    end
  end

  defp graph() do
    Journey.new_graph(
      @graph_name,
      "v1.0",
      [
        compute(:created_at, [], fn _ -> {:ok, System.system_time(:second)} end),
        input(:email),
        input(:name),
        input(:timezone)
      ],
      execution_id_prefix: @graph_name
    )
  end
end
