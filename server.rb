require 'pg'
require 'sinatra'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

get '/' do
erb :index
end


get '/actors' do
  @search_array = []
  if params[:page] == nil
    @page = 1
  else
    @page = params[:page]
    @current_page = @page.to_i * 20 - 20
  end
  if params[:query]
    @query = params[:query]
    db_connection do |connection|
      @actor_list = connection.exec('SELECT actors.id, actors.name, cast_members.character FROM actors
        JOIN cast_members ON actors.id = cast_members.actor_id ORDER BY name')
    end
  else
    db_connection do |connection|
      @actor_list = connection.exec('SELECT actors.id, actors.name, COUNT(actors.id) FROM movies
        JOIN cast_members ON movies.id = cast_members.movie_id
        JOIN actors ON actors.id = cast_members.actor_id
        GROUP BY actors.id
        ORDER BY name LIMIT 20 OFFSET ($1)',[@current_page])

    end
  end

  erb :'actors/actors'
end

get '/movies' do

  @search_array = []

if params[:page] == nil
    @page = 1
  else
    @page = params[:page]
    @current_page = @page.to_i * 20 - 20
  end
  if params[:query]
    @query = params[:query]
    db_connection do |connection|
      @movie_list = connection.exec('SELECT genres.name AS genre, movies.synopsis, movies.title, movies.year, movies.rating, studios.name
       FROM movies JOIN genres ON movies.genre_id = genres.id
       JOIN studios ON movies.studio_id = studios.id
       ORDER BY movies.title')
       end
  else
    @order = params[:order]
  if params[:page] == nil
    @page = 1
  else
    @page = params[:page]
    @current_page = @page.to_i * 20 - 20
  end
    db_connection do |connection|
       @movie_list = connection.exec("SELECT genres.name AS genre, movies.title, movies.year, movies.rating, studios.name
       FROM movies JOIN genres ON movies.genre_id = genres.id
       JOIN studios ON movies.studio_id = studios.id
       ORDER BY movies.title LIMIT 20 OFFSET ($1)", [@current_page])
    end
   if @order == "title"
    db_connection do |connection|
       @movie_list = connection.exec("SELECT genres.name AS genre, movies.title, movies.year, movies.rating, studios.name
       FROM movies JOIN genres ON movies.genre_id = genres.id
       JOIN studios ON movies.studio_id = studios.id
       ORDER BY movies.title LIMIT 20 OFFSET ($1)", [@current_page])
    end
   elsif @order == "rating"
   db_connection do |connection|
       @movie_list = connection.exec('SELECT genres.name AS genre, movies.title, movies.year, movies.rating, studios.name
       FROM movies JOIN genres ON movies.genre_id = genres.id
       JOIN studios ON movies.studio_id = studios.id
       ORDER BY movies.rating LIMIT 20 OFFSET ($1)', [@current_page])
       end
   elsif @order == "year"
   db_connection do |connection|
       @movie_list = connection.exec('SELECT genres.name AS genre, movies.title, movies.year, movies.rating, studios.name
       FROM movies JOIN genres ON movies.genre_id = genres.id
       JOIN studios ON movies.studio_id = studios.id
       ORDER BY movies.year LIMIT 20 OFFSET ($1)', [@current_page])
       end
   end
  end
erb :'movies/movies'
end


get '/actors/:id' do

db_connection do |connection|
  @actor_details = connection.exec_params('SELECT actors.id, actors.name,
    movies.title, movies.year, cast_members.character FROM movies
     JOIN cast_members ON movies.id = cast_members.movie_id
     JOIN actors ON actors.id = cast_members.actor_id
     WHERE actors.id = ($1)
     ORDER BY movies.title', [params[:id]])

  end
erb :'actors/details'
end

get '/movies/:id' do

@movie_name = params[:id].gsub('_', ' ')

db_connection do |connection|
  @movie_details = connection.exec_params("SELECT actors.id, movies.title, movies.year,
     cast_members.character, movies.synopsis, genres.name AS genre, actors.name AS casting
     FROM movies
     JOIN genres ON genres.id = movies.genre_id
     JOIN cast_members ON movies.id = cast_members.movie_id
     JOIN actors ON actors.id = cast_members.actor_id
     WHERE movies.title = ($1)
     ORDER BY movies.title;", [@movie_name])
  end
erb :'movies/details'
end



