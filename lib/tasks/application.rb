module BulletTrain
  module Themes
    module Application
      def self.eject_theme(task_name, ejected_theme_name)
        theme_name = task_name.split(":")[2]
        theme_parts = theme_name.humanize.split.map {|str| str.capitalize }
        constantized_theme = theme_parts.join
        humanized_theme = theme_parts.join(" ")
        humanized_ejected_theme = ejected_theme_name.humanize.split.map {|str| str.capitalize }.join(" ")

        theme_base_path = `bundle show --paths bullet_train-themes-#{theme_name}`.chomp
        puts "Ejecting from #{humanized_theme} theme in `#{theme_base_path}`."

        puts "Ejecting Tailwind configuration into `./tailwind.#{ejected_theme_name}.config.js`."
        `cp #{theme_base_path}/tailwind.#{theme_name}.config.js #{Rails.root}/tailwind.#{ejected_theme_name}.config.js`

        puts "Ejecting Tailwind mailer configuration into `./tailwind.mailer.#{ejected_theme_name}.config.js`."
        `cp #{theme_base_path}/tailwind.mailer.#{theme_name}.config.js #{Rails.root}/tailwind.mailer.#{ejected_theme_name}.config.js`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/tailwind.mailer.#{ejected_theme_name}.config.js`

        puts "Ejecting stylesheets into `./app/assets/stylesheets/#{ejected_theme_name}`."
        `mkdir #{Rails.root}/app/assets/stylesheets`
        `cp -R #{theme_base_path}/app/assets/stylesheets/#{theme_name} #{Rails.root}/app/assets/stylesheets/#{ejected_theme_name}`
        `cp -R #{theme_base_path}/app/assets/stylesheets/#{theme_name}.tailwind.css #{Rails.root}/app/assets/stylesheets/#{ejected_theme_name}.tailwind.css`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/light/#{ejected_theme_name}/g" #{Rails.root}/app/assets/stylesheets/#{ejected_theme_name}.tailwind.css`

        puts "Ejecting JavaScript into `./app/javascript/application.#{ejected_theme_name}.js`."
        `cp #{theme_base_path}/app/javascript/application.#{theme_name}.js #{Rails.root}/app/javascript/application.#{ejected_theme_name}.js`

        puts "Ejecting all theme partials into `./app/views/themes/#{ejected_theme_name}`."
        `mkdir #{Rails.root}/app/views/themes`
        `cp -R #{theme_base_path}/app/views/themes/#{theme_name} #{Rails.root}/app/views/themes/#{ejected_theme_name}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/app/views/themes/#{ejected_theme_name}/layouts/_head.html.erb`

        puts "Cutting local `Procfile.dev` over from `#{theme_name}` to `#{ejected_theme_name}`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/Procfile.dev`

        puts "Cutting local `package.json` over from `#{theme_name}` to `#{ejected_theme_name}`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{Rails.root}/package.json`

        # Stub out the class that represents this theme and establishes its inheritance structure.
        target_path = "#{Rails.root}/app/lib/bullet_train/themes/#{ejected_theme_name}.rb"
        puts "Stubbing out a class that represents this theme in `.#{target_path}`."
        `mkdir -p #{Rails.root}/app/lib/bullet_train/themes`
        `cp #{theme_base_path}/lib/bullet_train/themes/#{theme_name}.rb #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/module #{constantized_theme}/module #{ejected_theme_name.titlecase}/g" #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/TailwindCss/#{constantized_theme}/g" #{target_path}`
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/#{theme_name}/#{ejected_theme_name}/g" #{target_path}`
        ["require", "TODO", "mattr_accessor"].each do |thing_to_remove|
          `grep -v #{thing_to_remove} #{target_path} > #{target_path}.tmp`
          `mv #{target_path}.tmp #{target_path}`
        end
        `standardrb --fix #{target_path}`

        puts "Cutting local project over from `#{theme_name}` to `#{ejected_theme_name}` in `app/helpers/application_helper.rb`."
        `sed -i #{'""' if `echo $OSTYPE`.include?("darwin")} "s/:#{theme_name}/:#{ejected_theme_name}/g" #{Rails.root}/app/helpers/application_helper.rb`

        puts "You must restart `bin/dev` at this point, because of the changes to `Procfile.dev` and `package.json`."
      end

      def self.install_theme(task_name)
        # Grab the theme name from the rake task, bullet_train:theme:light:install
        theme_name = task_name.split(":")[2]

        # Grabs the current theme from
        # def current_theme
        #   :theme_name
        # end
        current_theme_regexp = /(^    :)(.*)/
        current_theme = nil

        new_lines = []
        [
          "./app/helpers/application_helper.rb",
          "./Procfile.dev",
          "./package.json"
        ].each do |file|
          File.open(file, "r") do |f|
            new_lines = f.readlines
            new_lines = new_lines.map do |line|
              # Make sure we get the current theme before trying to replace it in any of the files.
              # We grab it from the first file in the array above.
              current_theme = line.scan(current_theme_regexp).flatten.last if line.match?(current_theme_regexp)

              line.gsub!(/#{current_theme}/, theme_name) unless current_theme.nil?
              line
            end
          end

          File.open(file, "w") do |f|
            f.puts new_lines.join
          end
        end
      end
    end
  end
end