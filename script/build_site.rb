require "fileutils"

# The GitHub Pages project-site prefix.
# Override this with SITE_BASE_PATH when running the build.
site_base_path = ENV.fetch("SITE_BASE_PATH", "/saumitras1938")
site_base_path = "/#{site_base_path}" unless site_base_path.start_with?("/")
site_base_path = site_base_path.chomp("/")

# All generated files will be placed in dist/.
output_directory = Rails.root.join("dist")

# Remove the previous build so deleted posts don't remain published.
FileUtils.rm_rf(output_directory)
FileUtils.mkdir_p(output_directory)

# Load every Markdown post, already sorted newest first.
posts = BlogPost.all

# Copy the stylesheet into the static site's assets directory.
assets_directory = output_directory.join("assets")
FileUtils.mkdir_p(assets_directory)

FileUtils.cp(
  Rails.root.join("app/assets/stylesheets/application.css"),
  assets_directory.join("application.css")
)

# Render the homepage using the Rails view templates.
renderer = ApplicationController.renderer

homepage_html = renderer.render(
  template: "blog/index",
  layout: "layouts/static_site",
  assigns: {
    posts: posts,
    site_base_path: site_base_path
  }
)

File.write(output_directory.join("index.html"), homepage_html)

# Render one static HTML page per post.
posts.each do |post|
  post_directory = output_directory.join("posts", post.slug)
  FileUtils.mkdir_p(post_directory)

  post_html = renderer.render(
    template: "blog/show",
    layout: "layouts/static_site",
    assigns: {
      post: post,
      site_base_path: site_base_path
    }
  )

  File.write(post_directory.join("index.html"), post_html)
end

puts "Built #{posts.length} post(s) into #{output_directory}"