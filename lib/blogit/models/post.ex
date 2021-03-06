defmodule Blogit.Models.Post do
  @moduledoc """
  Represents a post in a blog.

  Contains an unique name of the post, which identifies it,
  the raw content of the post in markdown,
  html version of the post content and meta information.

  The meta information is contained in a `Blogit.Models.Post.Meta` structure.

  Usually a post is created by invoking the `Blogit.Models.Post.from_file/2`
  function.
  This function takes a provider for access to repository, a file path and a
  repository. It uses them to read the file and generate the Post structure.

  The `Blogit.Models.Post.compile_posts/2` function is able to create a list
  of multiple Post structures using a list of files and repository.

  The module contains a set of utility methods for working with
  `Blogit.Models.Post` structures.
  """

  alias Blogit.Models.Post.Meta
  alias Blogit.RepositoryProvider, as: Repository

  @posts_folder Application.get_env(:blogit, :posts_folder, "")
  @meta_divider Application.get_env(:blogit, :meta_divider, "--------")

  @type t :: %__MODULE__{
    name: String.t, raw: String.t, html: String.t, meta: Meta.t
  }
  @enforce_keys [:name, :raw, :html, :meta]
  defstruct [:name, :raw, :html, :meta]

  @doc """
  Creates a Post structure from a file stored in a repository.

  The name of the file is used as the name of the post.
  For example the Post structure created from the file `some_post.md`
  will have `post.name == "some_post"`.

  The given file path should be located in the given repository.
  """
  @spec from_file(String.t, Repository.t) :: t
  def from_file(file_path, repository) do
    name = name_from_file(file_path)

    raw = repository.provider.read_file!(file_path, @posts_folder)
    data = String.split(raw, @meta_divider, trim: true)
           |> Enum.map(&String.trim/1)

    html =
      Earmark.as_html!(String.replace(List.last(data), ~r/^\s*\#\s*.+/, ""))

    meta =
      Meta.from_file(file_path, repository, raw, name)

    %__MODULE__{name: name, raw: raw, html: html, meta: meta}
  end

  @doc """
  Creates a map with keys the names of the posts created from parsing the
  files at the given list of paths and values the posts structures created.

  Uses from_file/2 to parse the files and create the Post structures.

  Skips all the non-markdown files as well as the ones located in the folders
  `slides/` and `pages/`
  """
  @spec compile_posts([String.t], Repository.t) :: %{atom => t}
  def compile_posts(list, repository) when is_list(list) do
    list
    |> Enum.filter(fn(f) -> String.ends_with?(f, ".md") end)
    |> Enum.reject(fn(f) -> String.starts_with?(f, "slides/") end)
    |> Enum.reject(fn(f) -> String.starts_with?(f, "pages/") end)
    |> Enum.map(fn(file) -> from_file(file, repository) end)
    |> Enum.map(fn(post) -> {String.to_atom(post.name), post} end)
    |> Enum.into(%{})
  end

  @doc """
  Retrieves unique names, which can be used as names of posts, from a list
  of file names.

  ## Examples

      iex> Blogit.Models.Post.names_from_files(["SomeFile.md", "another.md"])
      ["somefile", "another"]

      iex> Blogit.Models.Post.names_from_files(["one/two/name.md"])
      ["one_two_name"]
  """
  @spec names_from_files([String.t]) :: [String.t]
  def names_from_files(files) do
    files
    |> Enum.filter(fn(f) -> String.ends_with?(f, ".md") end)
    |> Enum.map(&name_from_file/1)
  end

  @doc """
  Sorts a list of Post structures by the given meta field.

  By default this field is `created_at`.
  Note that the sort is descending.

  ## Examples

      iex> alias Blogit.Models.Post.Meta
      iex> posts = [
      ...>   %Blogit.Models.Post{
      ...>     name: "first", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-02-14 22:23:12]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "newest", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-04-22 14:53:45]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "very old", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-03-01 07:42:56]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "last", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-04-20 12:23:12]}
      ...>   }
      ...> ]
      iex> sorted = Blogit.Models.Post.sorted(posts)
      iex> sorted |> Enum.map(fn (post) -> post.name end)
      ["newest", "last", "very old", "first"]
  """
  @spec sorted([t], atom) :: [t]
  def sorted(posts, meta_field \\ :created_at) do
    Enum.sort(posts, fn (post1, post2) ->
      Calendar.NaiveDateTime.before?(
        Map.get(post2.meta, meta_field), Map.get(post1.meta, meta_field)
      )
    end)
  end

  @doc """
  Calculates a list of tuples of three elements from the given list of posts.

  The first element of a tuple is a year.
  The second is a month number.
  The third is a counter - how many posts are created during the month
  and the year.

  The tuples are sorted from the newest to the oldest, using the years
  and the months.

  ## Examples

      iex> alias Blogit.Models.Post.Meta
      iex> posts = [
      ...>   %Blogit.Models.Post{
      ...>     name: "", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2016-04-14 22:23:12]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-04-22 14:53:45]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-02-01 07:42:56]}
      ...>   },
      ...>   %Blogit.Models.Post{
      ...>     name: "", raw: "", html: "",
      ...>     meta: %Meta{created_at: ~N[2017-04-20 12:23:12]}
      ...>   }
      ...> ]
      iex> Blogit.Models.Post.collect_by_year_and_month(posts)
      [{2017, 4, 2}, {2017, 2, 1}, {2016, 4, 1}]
  """
  @type year_month_count_result :: {pos_integer, 1..12, non_neg_integer}
  @spec collect_by_year_and_month([t]) :: [year_month_count_result]
  def collect_by_year_and_month(posts) do
    posts
    |> Enum.reduce(%{}, fn post, map ->
      year = post.meta.created_at.year
      month = post.meta.created_at.month

      month_map = Map.get(map, year, %{})
      month_count = Map.get(month_map, month, 0)
      month_map = Map.merge(month_map, %{month => (month_count + 1)})

      Map.merge(map, %{year => month_map})
    end) |> Map.to_list
    |> Enum.flat_map(fn {year, dates} ->
      Map.to_list(dates)
      |> Enum.map(fn {month, count} -> {year, month, count}end)
    end) |> Enum.sort(fn({year1, month1, _}, {year2, month2, _})->
      case (year1 == year2) do
        true -> month2 <= month1
        false -> year2 <= year1
      end
    end)
  end

  ###########
  # Private #
  ###########

  defp name_from_file(file_name) do
    file_name
    |> Path.split
    |> Enum.join("_")
    |> String.downcase
    |> String.trim_trailing(".md")
  end
end
