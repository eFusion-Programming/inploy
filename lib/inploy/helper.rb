module Inploy
  module Helper
    def configuration_file
      File.open("config/deploy.rb") rescue File.open("deploy.rb") rescue nil
    end

    def skip_step?(step)
      skip_steps and skip_steps.include?(step)
    end

    def skip_steps_cmd
      " skip_steps=#{skip_steps.join(',')}" unless skip_steps.nil?
    end

    def clear_cache
      unless skip_step?('clear_cache')
        cache_dirs.each do |dir|
          run "rm -R -f #{dir}"
        end
      end
    end

    def jammit_is_installed?
      file_exists?("config/assets.yml")
    end

    def host
      hosts.first
    end

    def camelize(string)
      string.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    end

    def source_list
      list = ""
      count = 0
      env_sources.each do |src|
        count += 1
        if count == env_sources.size
          list = list + "source " + src + " "
        else
          list = list + "source " + src + " && "
        end
      end
      return list + "&& "
    end

    def application_path
      app_folder.nil? ? "#{path}/#{application}" : "#{path}/#{application}/#{app_folder}"
    end

    def application_folder
      app_folder.nil? ? application : "#{application}/#{app_folder}"
    end

    def copy_sample_files
      unless skip_step?('copy_sample_files')
        ["example", "sample", "template"].each do |extension|
          Dir.glob("config/*.#{extension}*").each do |file|
            secure_copy file, file.gsub(".#{extension}", '')
          end
        end
      end
    end

    def fetch_changes
      `git fetch`
    end

    def check_assets_and_migrations
      files = `git diff #{environment} origin/#{environment} --name-only`.gsub("\n"," ").split(" ")
      files.each do |f| 
        has_migration = f.include?("db/migrate")
        has_asset = f.include?("app/assets")
        
        if has_migration == true 
          @has_migation == true
        end

        if has_asset == true
          @has_asset == true
        end

        if has_asset == true && has_migration == true
          break
        end
      end
    end

    def migrate_database
      if @has_migration == true
        rake "db:migrate RAILS_ENV=#{environment}" unless skip_step?('migrate_database')
      end
    end

    def tasks
      `rake -T`
    end

    def update_inploy
      `bundle update inploy`
    end

    def bundle_cmd
      "bundle install #{bundler_opts}"
    end

    def bundle_install
      run bundle_cmd unless skip_step?('bundle_install')
    end

    def install_gems
      if using_bundler?
        bundle_install
      else
        rake "gems:install RAILS_ENV=#{environment}" unless skip_step?('install_gems')
      end
    end

    def update_crontab
      run "whenever --update-crontab #{application} --set 'environment=#{environment}'" if file_exists?("config/schedule.rb") unless skip_step?('update_crontab')
    end

    def notify_new_relic
      if file_exists? "vendor/plugins/newrelic_rpm/bin/newrelic_cmd" 
        run "ruby vendor/plugins/newrelic_rpm/bin/newrelic_cmd deployments"
      elsif file_exists? "config/newrelic.yml"
        run "newrelic_cmd deployments"
      end
    end
  end
end
