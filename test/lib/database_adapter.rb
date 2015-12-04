ACTS_AS_SCD_DATABASE_ADAPTERS = %w(mysql2 sqlite3)

ACTS_AS_SCD_DATABASE_ADAPTERS_DESC = %{#
# ACTIVATION
# ==========
# to activate, run 'rake db:adapter:change ADAPTER={ADAPTER}'
# ==========
#
}

ACTS_AS_SCD_DATABASE_ADAPTERS_DESC_2 = %{#
# THIS FILE WAS GENERATED
# =======================
# to change the current adapter, run 'rake db:adapter:change'
# to generate new adapters, run 'rake db:adapter:generate'
# ==========
#
}

namespace :db do
  namespace :adapter do
    desc "Change the database adapter for the command 'rake test', requires valid database.yml templates inside 'test/dummy/config' (use 'rake db:adapter:generate')."
    task :change do
      if ENV["ADAPTER"].nil?
        database_adapter = 'sqlite3'
        puts "WARNING: No adapter name given...use standard database adapter: #{database_adapter} (to customize, rerun task with environment variable ADAPTER)."
      else
        database_adapter = ENV["ADAPTER"]
        puts "SUCCESS: using given database adapter: #{database_adapter}."
      end

      abort "ERROR: Please specify a (valid) database adapter to activate (via the ADAPTER environment variable #{ACTS_AS_SCD_DATABASE_ADAPTERS})." if database_adapter.nil? || !ACTS_AS_SCD_DATABASE_ADAPTERS.include?(database_adapter)

      template_file = File.join(Dir.pwd, "test", "dummy", "config", "database.yml.#{database_adapter}")
      if File.exists? template_file
        template = File.open(template_file).read
        template = template.lines.to_a[(ACTS_AS_SCD_DATABASE_ADAPTERS_DESC.count("\n"))..-1].join # strip the template comments...
        template.prepend ACTS_AS_SCD_DATABASE_ADAPTERS_DESC_2 # ... and replace with new one

        output_file = File.join(Dir.pwd, "test", "dummy", "config", "database.yml")

        output = File.new(output_file, "w")
        output.puts(template)
        output.close

        puts "SUCCESS: #{output_file} written, current database adapter for 'rake test' is set to #{database_adapter}."
        puts "...Don't forget to create the appropriate databases with 'rake db:create'." if database_adapter != 'sqlite3'
      else
        puts "ERROR: Template File '#{template_file}' not found. Nothing written. Please run 'rake db:adapter:generate'."
      end

    end

    desc "Generate database.yml.* for all common database adapters. (recommended before using 'rake db:adapter:change')."
    task :generate do
      if ENV["DATABASE"].nil?
        database_name = 'acts_as_scd'
        puts "WARNING: No database name given...use standard database name: #{database_name} (to customize, rerun task with environment variable DATABASE)."
      else
        database_name = ENV["DATABASE"]
        puts "SUCCESS: using given database name: #{database_name}."
      end

      if ENV["USERNAME"].nil?
        database_user = 'acts_as_scd'
        puts "WARNING: No database name given...use standard database name: #{database_user} (to customize, rerun task with environment variable USERNAME)."
      else
        database_user = ENV["USERNAME"]
        puts "SUCCESS: using given database name: #{database_user}."
      end

      if ENV["PASSWORD"].nil?
        database_pass = 'mysql'
        puts "WARNING: No database name given...use standard database name: #{database_pass} (to customize, rerun task with environment variable PASSWORD)."
      else
        database_pass = ENV["PASSWORD"]
        puts "SUCCESS: using given database name: #{database_pass}."
      end

      abort "ERROR: Please specify a database name (via the DATABASE environment variable, required for #{ACTS_AS_SCD_DATABASE_ADAPTERS.reject{|a|a == 'sqlite3'}}." if database_name.nil?
      abort "ERROR: Please specify a database user (via the USERNAME environment variable, required for #{ACTS_AS_SCD_DATABASE_ADAPTERS.reject('sqlite3')})." if database_user.nil?
      abort "ERROR: Please specify a database password (via the PASSWORD environment variable, required for #{ACTS_AS_SCD_DATABASE_ADAPTERS.reject('sqlite3')})." if database_user.nil?

      ACTS_AS_SCD_DATABASE_ADAPTERS.each do |database_adapter|
        puts "INFO: Generating adapter for #{database_adapter}..."

        template_file = File.join(Dir.pwd, "test", "lib", "templates", "database.yml.#{database_adapter}")

        if File.exists? template_file
          template = File.open(template_file).read
          template.prepend ACTS_AS_SCD_DATABASE_ADAPTERS_DESC
          template.gsub!("{ADAPTER}", database_adapter)
          template.gsub!("{DATABASE}", database_name)
          template.gsub!("{USERNAME}", database_user)
          template.gsub!("{PASSWORD}", database_pass)

          output_file = File.join(Dir.pwd, "test", "dummy", "config", "database.yml.#{database_adapter}")
          output = File.new(output_file, "w")
          output.puts(template)
          output.close

          puts "SUCCESS: #{output_file} written, activate with 'rake db:adapter:change ADAPTER=#{database_adapter}'."
        else
          puts "ERROR: Template File '#{template_file}' not found. Skipping #{database_adapter}..."
        end


      end
    end
  end
end
