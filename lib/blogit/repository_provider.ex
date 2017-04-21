defmodule Blogit.RepositoryProvider do
  @type repository :: term
  @type fetch_result :: {:no_updates} | {:updates, [String.t]}
  @type file_name :: String.t
  @type timestamp :: String.t

  @callback repository() :: repository
  @callback updated_repository() :: repository
  @callback fetch(repository) :: fetch_result

  @callback local_path() :: String.t
  @callback local_files() :: [file_name]
  @callback file_in?(file_name) :: boolean

  @callback file_author(repository, file_name) :: String.t
  @callback file_created_at(repository, file_name) :: timestamp
  @callback file_updated_at(repository, file_name) :: timestamp
end