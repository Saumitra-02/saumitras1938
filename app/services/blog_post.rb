require "kramdown"
require "open3"
require "time"

# represents one post on the blog
# title is extracted from the first H1 heading
# creates a slug from the file name
# extracts a time from the git commit timestamp
# HTML is generated from the markdown content
class BlogPost
  POST_DIRECTORY = Rails.root.join("content/posts")
  attr_reader :title, :slug, :content, :html, :published_at

  # load one article from a markdown file
  def initialize(file_path)
    @file_path = Pathname.new(file_path)
    @slug = @file_path.basename(".md").to_s
    @content = @file_path.read

    # use the first H1 as the title, fall back to the file name if no H1 exists
    @title = extract_title

    # convert markdown into HTML for rendering on the page
    @html = Kramdown::Document.new(@content).to_html

    # use the latest git commit timestamp for this file
    @published_at = git_commit_time || File.mtime(@file_path)
  end

  # return all posts, with the newest first 
  def self.all
    Dir.glob(POST_DIRECTORY.join("*.md")).map do |file_path|
      new(file_path)
    end.sort_by(&:published_at).reverse
  end

  private

  # find the first markdown H1
  def extract_title
    heading = @content.match(/^#\s+(.+?)\s*#*\s*$/)
    heading ? heading[1].strip : @slug.tr("-", " ").capitalize
  end

  # read the most recent commit timestamp for this file
  # %cI returns the commit timestamp in ISO 8601 format
  # an uncommitted file has no git timestamp, so return nil
  def git_commit_time
    stdout, status = Open3.capture2(
      "git",
      "-C", Rails.root.to_s,
      "log",
      "-1",
      "--format=%cI",
      "--",
      @file_path.relative_path_from(Rails.root).to_s
    )

    return nil unless status.success? && !stdout.strip.empty?

    Time.iso8601(stdout.strip)
  end
end