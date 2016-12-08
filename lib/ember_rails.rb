require 'rails'
require 'ember/source'
require 'ember/data/source'
require 'ember/rails/engine'
require 'ember/data/active_model/adapter/source'

module Ember
  module Rails
    class Railtie < ::Rails::Railtie
      config.ember = ActiveSupport::OrderedOptions.new

      def configure_assets(app)
        config.assets.configure do |env|
          yield env
        end
      end

      initializer "ember_rails.setup_vendor_on_locale", :after => "ember_rails.setup", :group => :all do |app|
        variant = app.config.ember.variant || (::Rails.env.production? ? :production : :development)

        # Allow a local variant override
        ember_path = app.root.join("vendor/assets/ember/#{variant}")

        configure_assets app do |env|
          env.prepend_path(ember_path.to_s) if ember_path.exist?
        end
      end

      initializer "ember_rails.copy_vendor_to_local", :after => "ember_rails.setup", :group => :all do |app|
        variant = app.config.ember.variant || (::Rails.env.production? ? :production : :development)

        # Copy over the desired ember and ember-data bundled in
        # ember-source and ember-data-source to a tmp folder.
        tmp_path = app.root.join("tmp/ember-rails")
        FileUtils.mkdir_p(tmp_path)

        ember_ext = variant == :production ? ".prod.js" : ".debug.js"
        ember_data_ext = variant == :production ? ".prod.js" : ".js"

        FileUtils.cp(::Ember::Source.bundled_path_for("ember#{ember_ext}"), tmp_path.join("ember.js"))
        FileUtils.cp(::Ember::Data::Source.bundled_path_for("ember-data#{ember_data_ext}"), tmp_path.join("ember-data.js"))
        FileUtils.cp(::Ember::Data::ActiveModel::Adapter::Source.bundled_path_for("active-model-adapter.js"), tmp_path.join("active-model-adapter.js"))

        configure_assets app do |env|
          env.append_path tmp_path
        end
      end

      initializer "ember_rails.setup_vendor", :after => "ember_rails.copy_vendor_to_local", :group => :all do |app|
        configure_assets app do |env|
          env.append_path ::Ember::Source.bundled_path_for(nil)
          env.append_path ::Ember::Data::Source.bundled_path_for(nil)
          env.append_path ::Ember::Data::ActiveModel::Adapter::Source.bundled_path_for(nil)
          env.append_path File.expand_path('../', ::Handlebars::Source.bundled_path) if defined?(::Handlebars::Source)
        end
      end

      initializer "ember_rails.setup_ember_template_compiler", :after => "ember_rails.setup_vendor", :group => :all do |app|
        configure_assets app do |env|
          Ember::Handlebars::Template.setup_ember_template_compiler(env.resolve('ember-template-compiler.js'))
        end
      end

      initializer "ember_rails.setup_ember_handlebars_template", :after => "ember_rails.setup_vendor", :group => :all do |app|
        configure_assets app do |env|
          Ember::Handlebars::Template.setup env
        end
      end
    end
  end
end
