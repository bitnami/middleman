module Middleman
  module CoreExtensions
    module Collections
      class Paginator
        include Contracts

        Contract IsA['Middleman::Application'], IsA['Middleman::CoreExtensions::Collections::Collection'], Hash, Maybe[Proc] => Any
        def initialize(app, collection, opts={}, &block)
          @app = app
          @collection = collection
          @options = opts
          @block = block
        end

        Contract ResourceList => ResourceList
        def manipulate_resource_list(resources)
          resources
        end
      end
    end
  end
end
