require 'middleman-core/sitemap/extensions/proxies'
require 'middleman-core/util'
require 'middleman-core/core_extensions/collections/collection_store'
require 'middleman-core/core_extensions/collections/collection'
require 'middleman-core/core_extensions/collections/grouped_collection'

module Middleman
  module CoreExtensions
    module Collections
      class CollectionsExtension < Extension
        # This should run after most other sitemap manipulators so that it
        # gets a chance to modify any new resources that get added.
        self.resource_list_manipulator_priority = 110

        def initialize(app, options_hash={}, &block)
          super

          @store = CollectionStore.new(self)
        end

        Contract None => Any
        def before_configuration
          app.add_to_config_context :collection, &method(:create_collection)
          app.add_to_config_context :uri_match, &@store.method(:uri_match)
        end

        EitherCollection = Or[Collection, GroupedCollection]
        # rubocop:disable ParenthesesAsGroupedExpression
        Contract ({ where: Or[String, Proc], group_by: Maybe[Proc], as: Maybe[Symbol] }) => EitherCollection
        def create_collection(options={})
          @store.add(
            options.fetch(:as, :"anonymous_collection_#{@store.collections.length + 1}"),
            options.fetch(:where),
            options.fetch(:group_by, nil)
          )
        end

        Contract ResourceList => ResourceList
        def manipulate_resource_list(resources)
          @store.manipulate_resource_list(resources)
        end

        Contract None => CollectionStore
        def collected
          @store
        end

        helpers do
          def collected
            extensions[:collections].collected
          end

          def pagination
            current_resource.data.pagination
          end
        end
      end
    end
  end
end
