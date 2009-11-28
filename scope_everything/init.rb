#require 'migration_helper'
ActiveRecord::Base.send(:include, ActiveRecord::ScopeEverything) if defined?(ActiveRecord)

