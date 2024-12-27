# frozen_string_literal: true

# name: discourse-plugin-elastic-apm
# about: Sends application traces to elastic APM server
# version: 0.0.1
# authors: Marfeel
# url: https://github.com/Marfeel/discourse-plugin-elastic-apm
# required_version: 2.7.0

enabled_site_setting :discourse_plugin_elastic_apm

gem 'domain_name', '0.5.20170404', { require: false }
gem 'http-cookie', '1.0.7', { require: false }
gem 'http-form_data', '2.2.0', { require: false }
gem 'ffi-compiler', '1.0.0', { require: false }
gem 'llhttp-ffi', '0.5.0', { require: false }
gem 'http', '5.2.0', { require: false }
gem 'elastic-apm', '4.7.3', { require: false }

module DiscourseElasticApm
  class ElasticApmMiddlewareWrapper
    def initialize(app)
      @app = app
    end

    def call(env)
      if plugin_active?
        ElasticAPM::Middleware.new(@app).call(env)
      else
        @app.call(env)
      end
    end

    private

    def plugin_active?
      SiteSetting.discourse_plugin_elastic_apm && defined?(ElasticAPM)
    end
  end

  def self.manage_elastic_apm
    if defined?(ElasticAPM) && ElasticAPM.running?
      ElasticAPM.stop
    end

    if SiteSetting.discourse_plugin_elastic_apm
      unless defined?(ElasticAPM)
        begin
          require 'elastic-apm'
        rescue LoadError => e
          Rails.logger.error "Failed to load ElasticAPM gem: #{e.message}"
          return
        end
      end

      ElasticAPM::Rails.start(
        secret_token: SiteSetting.elastic_apm_secret_token,
        log_level: SiteSetting.elastic_apm_log_level,
        service_name: SiteSetting.elastic_apm_service_name,
        server_url: SiteSetting.elastic_apm_server_url,
        transaction_sample_rate: SiteSetting.elastic_apm_transaction_sample_rate,
      )
    end
  end
end

after_initialize do
  DiscourseElasticApm.manage_elastic_apm

  DiscourseEvent.on(:site_setting_changed) do |setting, _old_value, _new_value|
    DiscourseElasticApm.manage_elastic_apm if setting.start_with?('elastic_apm_') || setting == 'discourse_plugin_elastic_apm'
  end
end

Rails.application.middleware.insert_before(0, DiscourseElasticApm::ElasticApmMiddlewareWrapper)

at_exit do
  ElasticAPM.stop if defined?(ElasticAPM) && ElasticAPM.running?
end
