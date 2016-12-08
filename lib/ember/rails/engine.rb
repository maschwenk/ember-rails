require 'ember/handlebars/template'
require 'active_model_serializers'
require 'sprockets/railtie'

module Ember
  module Rails
    class Engine < ::Rails::Engine
      Ember::Handlebars::Template.configure do |handlebars_config|
        config.handlebars = handlebars_config

        config.handlebars.precompile = true
        config.handlebars.templates_root = 'templates'
        config.handlebars.output_type = :global
        config.handlebars.ember_template = 'HTMLBars'
      end

      config.before_initialize do |app|
        Sprockets::Engines #force autoloading
      end
    end
  end
end
