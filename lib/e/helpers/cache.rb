class << E

  # very basic cache implementation.
  # by default the cache will be kept in memory.
  # if you want to use a different pool, set it by using `cache_pool` at class level.
  # make sure your pool behaves just like a Hash,
  # meant it responds to `[]=`, `[]`, `delete` and `clear`
  def cache_pool pool
    @cache__pool || cache_pool!(pool)
  end

  def cache_pool! pool
    return if locked?
    @cache__pool = pool
  end

  def cache_pool?
    @cache__pool ||= Hash.new
  end
end

class E

  if ::AppetiteConstants::RESPOND_TO__SOURCE_LOCATION # ruby1.9
    def cache key = nil, &proc
      key ||= proc.source_location
      cache_pool[key] || __e__.sync { cache_pool[key] = proc.call }
    end
  else # ruby1.8
    def cache key = nil, &proc
      key ||= proc.to_s.split('@').last
      cache_pool[key] || __e__.sync { cache_pool[key] = proc.call }
    end
  end

  def cache_pool
    self.class.cache_pool?
  end

  # a simple way to manage stored cache.
  # @example
  #    class App < E
  #
  #      before do
  #        if 'some condition occurred'
  #          # clearing cache only for @banners and @db_items
  #          clear_cache! :banners, :db_items
  #        end
  #        if 'some another condition occurred'
  #          # clearing all cache
  #          clear_cache!
  #        end
  #      end
  #    end
  #
  #    def index
  #      @db_items = cache :db_items do
  #        # fetching items
  #      end
  #      @banners = cache :banners do
  #        # render banners partial
  #      end
  #      # ...
  #    end
  #
  #    def products
  #      cache do
  #        # fetch and render products
  #      end
  #    end
  #  end
  #
  def clear_cache! *keys
    __e__.sync do
      keys.size == 0 ?
          cache_pool.clear :
          keys.each { |key| cache_pool.delete(key) }
    end
  end
end
