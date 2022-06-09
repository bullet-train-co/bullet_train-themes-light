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
            ejected_files_to_replace(original_theme, custom_theme).map { |file| {file_name: file, must_compare: true}} +
            default_files_to_replace(original_theme, custom_theme).map { |file| {file_name: file, must_compare: false}}

          # Replace the file contents and rename the files.
          files_to_replace.each do |custom_gem_file|
            # All of the files we want to compare against the fresh gem are in the main app.
            main_app_file = custom_gem_file[:file_name].gsub(@repo_path, ".")
            main_app_file = build_main_app_file_name(original_theme, custom_theme, main_app_file, custom_gem_file[:file_name])

            # The content in the main app should replace the cloned gem files.
            if custom_gem_file[:must_compare] && !BulletTrain::Themes::Light::FileReplacer.files_have_same_content?(custom_gem_file[:file_name], main_app_file)
              BulletTrain::Themes::Light::FileReplacer.replace_content(old: custom_gem_file[:file_name], new: main_app_file)
            end

            # Only rename file names that still have the original theme in them, i.e. - ./tailwind.config.light.js
            if(File.basename(custom_gem_file[:file_name]).match?(original_theme))
              new_file_name = main_app_file.gsub(/^\./, @repo_path)
              File.rename(custom_gem_file[:file_name], new_file_name)
            end

            # TODO: Update contents like `module Light` in each file.
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

          # TODO: We currently don't eject the mailer config when running the eject rake task.
          # files << "#{repo_path}/tailwind.mailer.#{original_theme}.config.js"

          files.flatten
        end

        # These files represent ones such as "./lib/bullet_train/themes/light.rb" which
        # aren't ejected to the developer's main app, but still need to be changed.
        def default_files_to_replace(original_theme, custom_theme)
          files = []

          # Gemspec
          files << "#{@repo_path}/bullet_train-themes-#{original_theme}.gemspec"

          # Manifest
          files << "#{@repo_path}/app/assets/config/bullet_train_themes_#{original_theme}_manifest.js"

          # lib directory file
          files << "#{@repo_path}/lib/bullet_train/themes/#{original_theme}.rb"

          # TODO: Add this file and the FileReplacer module once they're added to the main branch.

          files
        end
        
        # Since we're cloning a fresh gem, file names that contain the original
        # theme stay the same, i.e. - tailwind.light.config.js. However, the names have
        # already been changed in the main app when the original theme was ejected.
        # We build the correct string that is in the main app here to compare the
        # files' contents. Then later on we actually rename the new gem's file names.
        def build_main_app_file_name(original_theme, custom_theme, main_app_file, custom_gem_file)
          custom_gem_file_hierarchy = main_app_file.split(/\//)
          if custom_gem_file_hierarchy.last.match?(original_theme)
            custom_gem_file_hierarchy.last.gsub!(original_theme, custom_theme)
            main_app_file = custom_gem_file_hierarchy.join("/")
          end
          main_app_file
        end
      end
    end
  end
end
