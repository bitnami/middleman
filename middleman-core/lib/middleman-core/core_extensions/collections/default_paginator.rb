require 'middleman-core/core_extensions/collections/paginator'
require 'middleman-core/sitemap/extensions/proxies'
require 'middleman-core/util'

module Middleman
  module CoreExtensions
    module Collections
      class DefaultPaginator < Paginator
        def initialize(app, collection, opts={}, &block)
          super

          @paginator = @options[:per_page]
          @paginator = proc do |all_items, page_num|
            per_page = @options[:per_page]
            start_i = page_num * per_page
            end_i = start_i + per_page

            all_items[start_i...end_i]
          end if @paginator.is_a?(Fixnum)

          @paginator.call([], 0)
        end

        Contract ResourceList => ResourceList
        def manipulate_resource_list(resources)
          return resources unless @block

          sort_proc = @options[:sort] || proc { |a, b| a.destination_path <=> b.destination_path }
          sorted_collection = @collection.sort(&sort_proc)

          num_pages = 0
          grouped_items = []

          while group = @paginator.call(sorted_collection, num_pages)
            grouped_items << group
            num_pages += 1
          end

          current_start_i = 0
          output = super

          grouped_items.each_with_index do |items, i|
            num = i + 1
            meta = page_locals(num, num_pages, items.length, current_start_i)

            ctx = PaginationContext.new
            ctx.instance_exec(items.dup, num, meta.dup, num >= num_pages, &@block)
            output += ctx.all_resources(@app)

            current_start_i += items.length
          end

          output
        end

        class PaginationContext
          def initialize
            @descriptors = []
          end

          def proxy(path, target, options={})
            @descriptors << ::Middleman::Sitemap::Extensions::ProxyDescriptor.new(
              ::Middleman::Util.normalize_path(path),
              ::Middleman::Util.normalize_path(target),
              options
            )
          end

          def all_resources(app)
            @descriptors.map { |d| d.to_resource(app) }
          end
        end

        protected

        # @param [Integer] page_num the page number to generate a resource for
        # @param [Integer] num_pages Total number of pages
        # @param [Integer] per_page How many items per page
        # @param [Integer] page_start Starting index
        def page_locals(page_num, num_pages, per_page, page_start)
          # Index into collection of the last item of this page
          page_end = (page_start + per_page) - 1

          ::Middleman::Util.recursively_enhance({
            # Include the numbers, useful for displaying "Page X of Y"
            page_number: page_num,
            num_pages: num_pages,
            per_page: per_page,

            # The range of item numbers on this page
            # (1-based, for showing "Items X to Y of Z")
            page_start: page_start + 1,
            page_end: [page_end + 1, @collection.length].min,

            # Use "collection" in templates.
            collection: @collection
          })
        end
      end
    end
  end
end
