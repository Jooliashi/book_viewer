require "tilt/erubis"
require "sinatra"
require "sinatra/reloader" if development?

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(chapter)
    chapter.split("\n\n").each_with_index.map do |line, index|
      "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def strong(paragraph, query)
    paragraph.gsub!(query, "<strong>#{query}</strong>")
  end

  def each_chapter
    @contents.each_with_index do |name, index|
      number = index + 1
      contents = File.read("data/chp#{number}.txt")
      yield number, name, contents
    end
  end

  def paragraphs_matching(query)
    results = []

    return results if !query || query.empty?

    each_chapter do |number, name, contents|
      matches = {}
      contents.split("\n\n").each_with_index do |paragraph, index|
        if paragraph.include?(query)
          matches[index] = strong(paragraph, query)
        end
      end
      results << {number: number, name: name, paragraphs: matches} if matches.any?
    end

    results
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do

  number = params[:number].to_i
  chapter_name = @contents[number - 1]

  redirect "/" unless (1..@contents.size).cover? number
  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = in_paragraphs(File.read("data/chp#{number}.txt"))
  erb :chapter
end

not_found do
  redirect "/"
end

get "/search" do
  @results = paragraphs_matching(params[:query])
  erb :search
end
