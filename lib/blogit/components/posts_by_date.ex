defmodule Blogit.Components.PostsByDate do
  @moduledoc """
  A component GenServer process which can be queried from outside.

  This process handles a `:get` message which returns a list of tuples of
  three elements - `{<year>, <month>, <number-of-posts>}`. It is statistics
  data - for this year and this month the blog has N posts.

  This component is supervised by `Blogit.Components.Supervisor` and added to
  it by `Blogit.Server`. It is lazy, the first time it is queried it computes
  its state by using the `Blogit.Components.Posts` process' state.

  When the posts get updated, this process' state is reset to nil and on the
  next request to it, it is re-calculated.
  """

  use GenServer

  alias Blogit.Models.Post
  alias Blogit.Components.Posts

  @doc """
  Starts the GenServer process.

  The process is started and supervised by `Blogit.Components.Supervisor` and
  the specification of it is added by `Blogit.Server`.

  The state of the process in the beginning is nil. When the state is nil and
  `:get` message is received as a 'call', the state is computed using the
  state of the `Blogit.Components.Posts` process.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def handle_cast(:reset, _), do: {:noreply, nil}

  def handle_call(:get, _from, nil) do
    posts = GenServer.call(Posts, :all)

    posts_by_dates = Post.collect_by_year_and_month(posts)
    {:reply, posts_by_dates, posts_by_dates}
  end

  def handle_call(:get, _from, posts_by_dates) do
    {:reply, posts_by_dates, posts_by_dates}
  end
end
