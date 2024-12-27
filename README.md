# discourse-plugin-elastic-apm

Refer here for configuration options

https://www.elastic.co/guide/en/apm/agent/ruby/current/configuration.html

Currently, plugin just allows to configure via discourse admin dashboard the following options:

* server_url
* service_name
* secret_token
* transaction_sample_rate
* elastic_apm_log_level

In top of that, extra options can be configured via env variables or the elastic apm page itself. Agent will be pulling for config updates.

NOTE: un order to make the plugin work, rak mini profiler must be disabled. Set the following environment variables in your discourse distribution to disable it

```
DISCOURSE_LOAD_MINI_PROFILER=false
DISABLE_MINI_PROFILER=true
```