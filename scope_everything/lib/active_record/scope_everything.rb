# Automatic scoping of all records for find, create, update, count
#
# = Usage
# In config/environment.rb
#   ActiveRecord::ScopeEverything.field = 'site_id'
# In your controllers before filter or something
#   Thread.current['scope_everything_id'] = 666 # or some ID
# If you don't want to apply the scope
#   Project.without_scope do
#   -- not scope code
#   end
#
# TODO
# code replication of scope_everything_id method
# testing
module ActiveRecord
  module ScopeEverything
    mattr_accessor :_field, :association

    def self.field=(value)
      self.association = value.gsub(/_id$/, '').to_sym
      self._field = value
    end

    def self.field
      _field
    end

    def self.included(base) #:nodoc:
      super

      base.class_inheritable_accessor :scope_everything, :instance_writer => false
      base.scope_everything = true

      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method_chain :find, :scope_everything
          alias_method_chain :count, :scope_everything
          alias_method_chain :minimum, :scope_everything          
          alias_method_chain :maximum, :scope_everything          
        end
      end

      base.alias_method_chain :create, :scope_everything
      base.alias_method_chain :update, :scope_everything
      base.alias_method_chain :method_missing, :scope_everything
    end

    # scope method missing so associations work
    def method_missing_with_scope_everything(*args)
      if args.first==ScopeEverything.association
        self.class.scopes_everything
        send(ScopeEverything.association)
      else
        method_missing_without_scope_everything(*args)
      end
    end

    module ClassMethods
      # pass block to without scope to avoid scoping for a particular model
      def without_scope(&block)
        orig = self.scope_everything
        self.scope_everything = false
        yield
        self.scope_everything = orig
      end

      # includes in model the association to the scopee
      def scopes_everything
        class_eval do
          belongs_to ScopeEverything.association #, :class_name => "User", :foreign_key => "created_by"
        end
      end

      def count_with_scope_everything(*args) #:nodoc:
        t = scope_everything_id
        if scope_everything && !t.nil? && column_names.include?(ScopeEverything.field)
          with_scope(:find => {:conditions => "#{quoted_table_name}.#{ScopeEverything.field} = #{t}"}) do
            count_without_scope_everything(*args)
          end
        else
          count_without_scope_everything(*args)
        end
      end
      
      def minimum_with_scope_everything(*args) #:nodoc:
        t = scope_everything_id
        if scope_everything && !t.nil? && column_names.include?(ScopeEverything.field)
          with_scope(:find => {:conditions => "#{quoted_table_name}.#{ScopeEverything.field} = #{t}"}) do
            minimum_without_scope_everything(*args)
          end
        else
          minimum_without_scope_everything(*args)
        end
      end      
      
      def maximum_with_scope_everything(*args) #:nodoc:
        t = scope_everything_id
        if scope_everything && !t.nil? && column_names.include?(ScopeEverything.field)
          with_scope(:find => {:conditions => "#{quoted_table_name}.#{ScopeEverything.field} = #{t}"}) do
            maximum_without_scope_everything(*args)
          end
        else
          maximum_without_scope_everything(*args)
        end
      end      

      def find_with_scope_everything(*args) #:nodoc:
        t = scope_everything_id
        if scope_everything && !t.nil? && column_names.include?(ScopeEverything.field)
          with_scope(:find => {:conditions => "#{quoted_table_name}.#{ScopeEverything.field} = #{t}"}) do
            find_without_scope_everything(*args)
          end
        else
          find_without_scope_everything(*args)
        end
      end

      def scope_everything_id
        Thread.current[ScopeEverything.field]
      end
    end

    private
      def scope_everything_id
        if ScopeEverything.field
          Thread.current[ScopeEverything.field]
        end
      end

      def create_with_scope_everything #:nodoc:
        if scope_everything
          t = scope_everything_id
          unless t.nil?
            write_attribute(ScopeEverything.field, t) if respond_to?(ScopeEverything.field.to_sym) && send(ScopeEverything.field).nil?
          end
        end
        create_without_scope_everything
      end

      def update_with_scope_everything(*args) #:nodoc:
        if scope_everything && (!partial_updates? || changed?)
          t = scope_everything_id
          unless t.nil?
            write_attribute(ScopeEverything.field, t) if respond_to?(ScopeEverything.field.to_sym)
          end
        end
        update_without_scope_everything(*args)
      end
  end
end

