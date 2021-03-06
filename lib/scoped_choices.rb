require 'hashie/mash'
require 'erb'

module ScopedChoices
  extend self
  
  def load_settings(filename, env)
    mash = Hashie::Mash.new(load_settings_hash(filename, env))
    
    with_local_settings(filename, env, '.local') do |local|
      mash.update local
    end
    
    return mash
  end
  
  def load_settings_hash(filename, env)
    yaml_content = ERB.new(IO.read(filename)).result
    yaml_load(yaml_content)[env]
  end
  
  def with_local_settings(filename, env, suffix)
    local_filename = filename.sub(/(\.\w+)?$/, "#{suffix}\\1")
    if File.exists? local_filename
      hash = load_settings_hash(local_filename, env)
      yield hash if hash
    end
  end
  
  def yaml_load(content)
    ruby_major_version = RUBY_VERSION.split('.').first.to_i
    if ruby_major_version < 2 && defined? YAML::ENGINE
      # avoid using broken Psych in 1.9.2
      old_yamler = YAML::ENGINE.yamler
      YAML::ENGINE.yamler = 'syck'
    end
    begin
      YAML::load(content)
    ensure
      if ruby_major_version < 2 && defined? YAML::ENGINE
        YAML::ENGINE.yamler = old_yamler
      end
    end
  end
end

if defined? Rails
  require 'scoped_choices/rails'
end
