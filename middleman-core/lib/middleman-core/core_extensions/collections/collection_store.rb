require 'middleman-core/core_extensions/collections/collection'
require 'middleman-core/core_extensions/collections/grouped_collection'

module Middleman
  module CoreExtensions
    module Collections
      class CollectionStore
        extend Forwardable
        include Contracts

        def_delegator :@parent, :app

        EitherCollection = Or[Collection, GroupedCollection]
        Contract None => HashOf[Symbol, EitherCollection]
        attr_reader :collections

        def initialize(parent)
          @parent = parent
          @collections = {}
        end

        Contract ResourceList => ResourceList
        def manipulate_resource_list(resources)
          @collections.reduce(resources) do |sum, (_, collection)|
            collection.manipulate_resource_list(sum)
          end
        end

        Contract String, String => Maybe[Hash]
        def uri_match(path, template)
          matcher = ::Middleman::Util::UriTemplates.uri_template(template)
          ::Middleman::Util::UriTemplates.extract_params(matcher, ::Middleman::Util.normalize_path(path))
        end

        Contract Symbol, Or[String, Proc], Maybe[Proc], Maybe[Proc] => EitherCollection
        def add(title, where, group_by)
          where_proc = select_items(where)

          @collections[title] = if group_by
            GroupedCollection.new(self, where_proc, group_by)
          else
            Collection.new(self, where_proc)
          end
        end

        Contract Or[String, Proc] => Proc
        def select_items(where)
          where_proc = if where.is_a? String
            proc { |resource| uri_match resource.url, where }
          else
            where
          end

          proc do |resource|
            response = where_proc.call(resource)

            if response.is_a? Hash
              resource.add_metadata page: { params: response }
            end

            response
          end
        end

        # "Magically" find namespace if they exist
        #
        # @param [String] key The namespace to search for
        # @return [Hash, nil]
        def method_missing(key)
          if key?(key)
            @collections[key]
          else
            throw 'Collection not found'
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
            @collections[key]
          else
            throw 'Collection not found'
          end
        end

        def key?(key)
          @collections.key?(key)
        end

        alias_method :has_key?, :key?
      end
    end
  end
end
