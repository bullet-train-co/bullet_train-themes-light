module BulletTrain
  module Themes
    module Light
      class CustomThemeFileReplacer
        mattr_accessor :repo_path

        include BulletTrain::Themes::Light::FileReplacer

        def initialize(custom_theme)
          @repo_path = "./local/bullet_train-themes-#{custom_theme}"
        end

        def replace_theme(original_theme, custom_theme)
          # Rename the directories
          [
            "#{@repo_path}/app/assets/stylesheets/#{original_theme}/",
            "#{@repo_path}/app/views/themes/#{original_theme}/",
            "#{@repo_path}/lib/bullet_train/themes/#{original_theme}/"
          ].each do |original_directory|
            custom_directory = original_directory.gsub(/(.*)(#{original_theme})(\/$)/, '\1' + custom_theme + '\3')
            FileUtils.mv(original_directory, custom_directory)
          end

          # Only compare ejected files.
          files_to_replace = 
            ejected_files_to_replace(original_theme, custom_theme).map { |file| {file_name: file, must_compare: true} } +
            default_files_to_replace(original_theme).map { |file| {file_name: file, must_compare: false} }

          # Replace the file contents and rename the files.
          files_to_replace.each do |custom_gem_file|
            # All of the files we want to compare against the fresh gem are in the main app.
            main_app_file = custom_gem_file[:file_name].gsub(@repo_path, ".")
            main_app_file = build_main_app_file_name(original_theme, custom_theme, main_app_file, custom_gem_file[:file_name])
            custom_gem_file[:file_name] = adjust_directory_hierarchy(custom_gem_file[:file_name], original_theme)

            # The content in the main app should replace the cloned gem files.
            if custom_gem_file[:must_compare] && !BulletTrain::Themes::Light::FileReplacer.files_have_same_content?(custom_gem_file[:file_name], main_app_file)
              BulletTrain::Themes::Light::FileReplacer.replace_content(old: custom_gem_file[:file_name], new: main_app_file)
            end

            # Only rename file names that still have the original theme in them, i.e. - ./tailwind.config.light.js
            if(File.basename(custom_gem_file[:file_name]).match?(original_theme))
              main_app_file = adjust_directory_hierarchy(main_app_file, custom_theme)
              new_file_name = main_app_file.gsub(/^\./, @repo_path).gsub(original_theme, custom_theme)
              File.rename(custom_gem_file[:file_name], new_file_name)
            end
          end

          # Change the content of specific files that contain the orignal theme's string.
          # i.e. - `module Light` and `tailwind.light.config`.
          constantized_original = constantize_from_snake_case(original_theme)
          constantized_custom = constantize_from_snake_case(custom_theme)
          [
            "#{@repo_path}/app/assets/stylesheets/#{custom_theme}.tailwind.css",
            "#{@repo_path}/bin/rails",
            "#{@repo_path}/lib/bullet_train/themes/#{custom_theme}/engine.rb",
            "#{@repo_path}/lib/bullet_train/themes/#{custom_theme}/version.rb",
            "#{@repo_path}/lib/bullet_train/themes/#{custom_theme}.rb",
            "#{@repo_path}/lib/tasks/bullet_train/themes/#{custom_theme}_tasks.rake",
            "#{@repo_path}/bullet_train-themes-#{custom_theme}.gemspec",
            "#{@repo_path}/Gemfile",
            "#{@repo_path}/README.md"
          ].each do |file|
            new_lines = []
            File.open(file, "r") do |f|
              new_lines = f.readlines
              new_lines.each do |line|
                line.gsub!(original_theme, custom_theme)
                line.gsub!(constantized_original, constantized_custom)
              end
            end

            File.open(file, "w") do |f|
              f.puts new_lines.join
            end
          end

          # The contents in this specific main app file don't have the require statements which the gem
          # originally has, so we add those back after moving the main app file contents to the gem.
          new_lines = nil
          File.open("#{@repo_path}/lib/bullet_train/themes/#{custom_theme}.rb", "r") do |file|
            new_lines = file.readlines
            require_lines =
              <<~RUBY
                require "bullet_train/themes/#{custom_theme}/version"
                require "bullet_train/themes/#{custom_theme}/engine"
                require "bullet_train/themes/tailwind_css"

              RUBY
            new_lines.unshift(require_lines)
          end
          File.open("#{@repo_path}/lib/bullet_train/themes/#{custom_theme}.rb", "w") do |file|
            file.puts new_lines.flatten.join
          end

          # Since we're generating a new gem, it should be version 1.0
          File.open("#{@repo_path}/lib/bullet_train/themes/#{custom_theme}/version.rb", "r") do |file|
            new_lines = file.readlines
            new_lines = new_lines.map {|line | line.match?("VERSION") ? "      VERSION = \"1.0\"\n" : line}
          end
          File.open("#{@repo_path}/lib/bullet_train/themes/#{custom_theme}/version.rb", "w") do |file|
            file.puts new_lines.join
          end
        end

        private

        # By the time we call this method we have already updated the new gem's directories with
        # the custom theme name, but the FILE names are still the same from when they were cloned,
        # so we use `original_theme` for specific file names below.
        def ejected_files_to_replace(original_theme, custom_theme)
          files = []

          # Stylesheets
          files << Dir.glob("#{@repo_path}/app/assets/stylesheets/#{custom_theme}/**/*.css")
          files << Dir.glob("#{@repo_path}/app/assets/stylesheets/#{custom_theme}/**/*.scss")

          # Views
          files << Dir.glob("#{@repo_path}/app/views/themes/#{custom_theme}/**/*.html.erb")

          # JavaScript
          files << "#{@repo_path}/app/javascript/application.#{original_theme}.js"
          files << "#{@repo_path}/tailwind.#{original_theme}.config.js"

          # File which determines the directory order.
          files << "#{@repo_path}/app/lib/bullet_train/themes/#{original_theme}.rb"

          # The Glob up top doesn't grab the #{original_theme}.tailwind.css file, so we set that here.
          files << "#{@repo_path}/app/assets/stylesheets/#{original_theme}.tailwind.css"

          # TODO: We currently don't eject the mailer config when running the eject rake task.
          # files << "#{repo_path}/tailwind.mailer.#{original_theme}.config.js"

          files.flatten
        end

        # These files represent ones such as "./lib/bullet_train/themes/light.rb" which
        # aren't ejected to the developer's main app, but still need to be changed.
        def default_files_to_replace(original_theme)
          # TODO: Add this file and the FileReplacer module once they're added to the main branch.
          [
            "#{@repo_path}/bullet_train-themes-#{original_theme}.gemspec",
            "#{@repo_path}/app/assets/config/bullet_train_themes_#{original_theme}_manifest.js",
            "#{@repo_path}/lib/tasks/bullet_train/themes/#{original_theme}_tasks.rake"
          ]
        end
        
        # Since we're cloning a fresh gem, file names that contain the original
        # theme stay the same, i.e. - tailwind.light.config.js. However, the names have
        # already been changed in the main app when the original theme was ejected.
        # Here, we build the correct string that is in the main app to compare the
        # files' contents. Then later on we actually rename the new gem's file names.
        def build_main_app_file_name(original_theme, custom_theme, main_app_file, custom_gem_file)
          custom_gem_file_hierarchy = main_app_file.split(/\//)
          if custom_gem_file_hierarchy.last.match?(original_theme)
            custom_gem_file_hierarchy.last.gsub!(original_theme, custom_theme)
            main_app_file = custom_gem_file_hierarchy.join("/")
          end
          main_app_file
        end

        # This addresses one specific file where the hierarchy is
        # different after the file is ejected into the main application.
        def adjust_directory_hierarchy(file_name, theme_name)
          file_name.match?("lib/bullet_train/themes/#{theme_name}") ? file_name.gsub(/\/app/, "") : file_name
        end

        # i.e. - foo_bar or foo-bar to FooBar
        def constantize_from_snake_case(str)
          str.split(/[_|-]/).map(&:capitalize).join
        end
      end
    end
  end
end
