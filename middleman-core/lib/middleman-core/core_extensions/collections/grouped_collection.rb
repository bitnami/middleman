module Middleman
  module CoreExtensions
    module Collections
      class GroupedCollection
        extend Forwardable
        include Contracts

        def_delegator :@store, :app
        def_delegator :groups, :each

        def initialize(store, where, group_by)
          @store = store
          @where = where
          @group_by = group_by
          @last_sitemap_version = nil
          @groups = {}
        end

        Contract ResourceList => ResourceList
        def manipulate_resource_list(resources)
          resources
        end

        Contract None => HashOf[Symbol, ResourceList]
        def groups
          if @last_sitemap_version != app.sitemap.update_count
            items = app.sitemap.resources.select(&@where)

            @groups = items.each_with_object({}) do |resource, sum|
              results = Array(@group_by.call(resource)).map(&:to_s).map(&:to_sym)

              results.each do |k|
                sum[k] ||= []
                sum[k] << resource
              end
            end
          end

          @groups
        end

        # "Magically" find namespace if they exist
        #
        # @param [String] key The namespace to search for
        # @return [Hash, nil]
        def method_missing(key)
          if key?(key)
            @groups[key]
          else
            throw 'Group not found'
          end
        end

        # Needed so that method_missing makes sense
        def respond_to?(method, include_private=false)
          super || key?(method)
        end

        # Act like a hash. Return requested data, or
        # nil if data does not exist
        #
        # @param [String, Symbol] key The name of the namespace
        # @return [Hash, nil]
        def [](key)
          if key?(key)
            @groups[key]
          else
            throw 'Group not found'
          end
        end

        def key?(key)
          @groups.key?(key)
        end

        alias_method :has_key?, :key?
      end
    end
  end
end
