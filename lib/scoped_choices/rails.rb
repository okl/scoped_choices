require 'scoped_choices'

module ScopedChoices::Rails
  def self.included(base)
    base.class_eval do
      def initialize_with_scoped_choices(*args, &block)
        initialize_without_scoped_choices(*args, &block)
        @scoped_choices = Hashie::Mash.new
      end
      
      alias :initialize_without_scoped_choices :initialize
      alias :initialize :initialize_with_scoped_choices
    end
  end
  
  def from_file_with_scope(name, scope)
    root = self.respond_to?(:root) ? self.root : Rails.root
    file = root + 'config' + name
    
    settings = ScopedChoices.load_settings(file, Rails.respond_to?(:env) ? Rails.env : RAILS_ENV)
    if scope
      scoped_settings = Hashie::Mash.new
      scoped_settings.send("#{scope}=", settings)
      settings = scoped_settings
    end
    @scoped_choices.update settings

    settings.each do |key, value|
      self.send("#{key}=", value)
    end
  end
end

if defined? Rails::Application::Configuration
  Rails::Application::Configuration.send(:include, ScopedChoices::Rails)
elsif defined? Rails::Configuration
  Rails::Configuration.class_eval do
    include ScopedChoices::Rails
    include Module.new {
      def respond_to?(method)
        super or method.to_s =~ /=$/ or (method.to_s =~ /\?$/ and @scoped_choices.key?($`))
      end
      
      private
      
      def method_missing(method, *args, &block)
        if method.to_s =~ /=$/ or (method.to_s =~ /\?$/ and @scoped_choices.key?($`))
          @scoped_choices.send(method, *args)
        elsif @scoped_choices.key?(method)
          @scoped_choices[method]
        else
          super
        end
      end
    }
  end
end
