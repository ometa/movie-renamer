#!/usr/bin/env ruby

require 'cgi'
require 'net/http'
require 'uri'
require 'readline'
require 'json'

class MovieRenamer

  INPUT_DIR = '.'
  API_PREFIX = 'http'
  API_HOST = 'www.omdbapi.com'

  def run
    jobs, bad = build_rename_jobs

    unless bad.empty?
      puts "Unprocessable / Not Found"
      puts "-------------------------"
      puts bad
      puts
    end

    if jobs.empty?
      puts "Nothing to rename."
      exit 0
    end

    puts "Movies to Rename"
    puts "----------------"
    jobs.each do |job|
      puts "#{job[:old]} --> #{job[:new]}" 
    end

    val = input "Proceed with rename? (y/n)"
    if val == 'y'
      jobs.each do |job|
        File.rename job[:old], job[:new]
      end
    end
  end

  def build_rename_jobs
    movies_without_years.inject([[],[]]) do |memo, movie|
      good, bad = memo
      *name, ext = movie.split('.')
      name = name.join('.')
      metadata = get_movie_metadata(name)
      year = JSON.parse(metadata)['Year']

      if year.nil?
        bad << movie
      else
        new = "#{name} (#{year}).#{ext}"
        good << {
          old: movie,
          new: new
        }
      end
      [good, bad]
    end
  end

  def movies_without_years
    all_movies.reject { |f| f =~ /\([\d]{4}\)/ }
  end

  def all_movies
    Dir.glob(INPUT_DIR + '/*.*').map { |f| File.basename(f) }.map
  end

  def get_movie_metadata(name)
    encoded = CGI.escape(name)
    puts "Querying: #{name}"
    response = get(API_PREFIX + '://' + API_HOST + "/?t=#{encoded}&y=&plot=short&r=json")
    raise "API call failed: #{response.code}: #{response.body}" unless response.code.to_i == 200
    response.body
  end

  def get(url)
    Net::HTTP.get_response(URI.parse(url))
  end

  def input(prompt="", newline=false)
    prompt += "\n" if newline
    Readline.readline(prompt, true).squeeze(" ").strip
  end
end

mr = MovieRenamer.new
mr.run
