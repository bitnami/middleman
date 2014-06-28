require 'middleman-core/core_extensions/collections/default_paginator'

module Middleman
  module CoreExtensions
    module Collections
      class Collection
        # include Enumerable
        extend Forwardable
        include Contracts

        def_delegators :@items, :[], :each, :first, :last, :include?, :length, :each_slice, :sort, :map
        def_delegator :@store, :app

        def initialize(store, where)
          @store = store
          @where = where
          @last_sitemap_version = nil
          @items = []
          @paginators = []
        end

        Contract Or[Hash, IsA['Class']], Proc => Collection
        def paginate(pagination_descriptor, &block)
          if pagination_descriptor.is_a? Class
            @paginators << pagination_descriptor.new(app, self, {}, &block)
          else
            @paginators << DefaultPaginator.new(app, self, pagination_descriptor, &block)
          end

          self # chaining
        end

        Contract ResourceList => ResourceList
        def manipulate_resource_list(resources)
          @items = resources.select(&@where)
          @paginators.reduce(resources) do |sum, p|
            p.manipulate_resource_list(sum)
          end
        end
      end
    end
  end
end
