require 'tasks/application'

namespace :bullet_train do
  namespace :themes do
    namespace :light do
      desc "Fork the \"Light\" theme into your local repository."
      task :eject, [:destination] => :environment do |task, args|
        BulletTrain::Themes::Application.eject_theme(task.name, args[:destination])
      end

      desc "Publish your custom theme theme as a Ruby gem."
      task :release, [:theme_name] => :environment do |task, args|
        puts "Preparing to release your custom theme: ".blue + args[:theme_name]
        puts ""
        puts "Before we make a new Ruby gem for your theme, you'll have to set up a GitHub repository first.".blue
        puts "Hit <Return> and we'll open a browser to GitHub where you can create a new repository.".blue
        puts "Make sure you name the repository ".blue + "bullet_train-themes-#{args[:theme_name]}"
        puts ""
        puts "When you're done, copy the SSH path from the new repository and return here.".blue
        ask "We'll ask you to paste it to us in the next step."
        `#{Gem::Platform.local.os == "linux" ? "xdg-open" : "open"} https://github.com/new`

        ssh_path = ask "OK, what was the SSH path? (It should look like `git@github.com:your-account/your-new-repo.git`.)"
        puts ""
        puts "Great, you're all set.".blue
        puts "We'll take it from here, so sit back and enjoy the ride 🚄️".blue
        puts ""
        puts "Creating a Ruby gem for ".blue + "#{args[:theme_name]}..."

        Dir.mkdir("local") unless Dir.exist?("./local")
        if Dir.exist?("./local/bullet_train-themes-#{args[:theme_name]}")
          raise "You already have a repository named `bullet_train-themes-#{args[:theme_name]}` in `./local`.\n" \
            "Make sure you delete it first to create an entirely new gem."
        end
        `git clone git@github.com:bullet-train-co/bullet_train-themes-light.git ./local/bullet_train-themes-#{args[:theme_name]}`

        custom_file_replacer = BulletTrain::Themes::Light::CustomThemeFileReplacer.new(args[:theme_name])
        custom_file_replacer.replace_theme("light", args[:theme_name])

        work_tree_flag = "--work-tree=local/bullet_train-themes-#{args[:theme_name]}"
        git_dir_flag = "--git-dir=local/bullet_train-themes-#{args[:theme_name]}/.git"
        path = "./local/bullet_train-themes-#{args[:theme_name]}"

        # Set up the proper remote.
        `git #{work_tree_flag} #{git_dir_flag} remote set-url origin #{ssh_path}`
        `git #{work_tree_flag} #{git_dir_flag} add .`
        `git #{work_tree_flag} #{git_dir_flag} commit -m "Add initial files"`

        # Build the gem.
        `(cd #{path} && gem build bullet_train-themes-#{args[:theme_name]}.gemspec)`
        `git #{work_tree_flag} #{git_dir_flag} add .`
        `git #{work_tree_flag} #{git_dir_flag} commit -m "Build gem"`

        # Commit the deleted files on the main application.
        `git add .`
        `git commit -m "Remove #{args[:theme_name]} files from application"`

        # Push the gem's source code, but not the last commit in the main application.
        `git #{work_tree_flag} #{git_dir_flag} push -u origin main`

        puts ""
        puts ""
        puts "You're all set! Copy and paste the following commands to publish your gem:".blue
        puts "cd ./local/bullet_train-themes-#{args[:theme_name]}"
        puts "gem push bullet_train-themes-#{args[:theme_name]}-1.0.gem && cd ../../"
        puts ""
        puts "You may have to wait for some time until the gem can be downloaded via the Gemfile.".blue
        puts "After a few minutes, run the following command in your main application:".blue
        puts "bundle add bullet_train-themes-#{args[:theme_name]}"
        puts ""
        puts "Then you'll be ready to use your custom gem in your Bullet Train application.".blue
      end

      desc "Install this theme to your main application."
      task :install do |task|
        BulletTrain::Themes::Application.install_theme(task.name)
      end

      def ask(string)
        puts string.blue
        $stdin.gets.strip
      end

      desc "List view partials in theme that haven't changed since ejection from \"Light\"."
      task :clean, [:theme] => :environment do |task, args|
        BulletTrain::Themes::Application.clean_theme(task.name, args)
      end
    end
  end
end
