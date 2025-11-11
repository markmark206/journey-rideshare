defmodule RsWeb.Live.Components.About do
  use RsWeb, :html

  @moduledoc false

  def render(assigns) do
    ~H"""
    <div id="about-service-id" class="mx-auto max-w-2xl flex justify-center px-3">
      <div class="text-sm justify-center font-mono border-1 rounded-md my-1 p-4 bg-base-100 w-full">
        <div class="py-1">
          This play-demo service is built with
          <a
            class="link link-primary"
            target="_blank"
            href="https://elixir-lang.org/"
          >
            Elixir
          </a>
          and <a
            class="link link-primary"
            target="_blank"
            href="https://www.phoenixframework.org/"
          >Phoenix LiveView</a>, with
          <a class="link link-primary" target="_blank" href="https://hexdocs.pm/journey/">hexdocs.pm/journey</a>
          providing durable executions, with persistence, scheduling, crash recovery, orchestration and analytics.
        </div>
        <div class="py-1">
          JourDash source is available on Github:
          <a
            class="link link-primary"
            target="_blank"
            href="https://github.com/markmark206/journey-food-delivery"
          >
            repo
          </a>
          |
          <a
            class="link link-primary"
            target="_blank"
            href="https://github.com/markmark206/journey-food-delivery/blob/main/lib/rs/trip/graph.ex"
          >
            graph
          </a>
        </div>
        <div class="py-1">
          Let's deliver some snacks! <span class="text-lg animate-pulse">{@item_to_deliver}</span>
        </div>
      </div>
    </div>
    """
  end
end
