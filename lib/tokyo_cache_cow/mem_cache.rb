require 'tokyocabinet'

class TokyoCacheCow
  class MemCache

    include TokyoCabinet

    def get(key)
      d = @cache.get(key)
      if d
        d['exptime'] = d['exptime'].to_i
        d['flags'] = d['flags'].to_i
      end
      
      if d
        if d['expires']
          if d['expires'].to_i < Time.now.to_i
            nil
          else
            delete(key)
            nil
          end
        elsif d['exptime'] == 0 || d['exptime'] > Time.now.to_i
          d
        else
          delete(key)
          nil
        end
      else
        delete(key)
        nil
      end 
    end
    
    def append(key, val)
      if d = @cache.get(key)
        d['data'] << val
        @cache.put(key, d)
        true
      else
        false
      end
    end

    def prepend(key, val)
      if d = @cache.get(key)
        d['data'][0,0] = val
        @cache.put(key, d)
        true
      else
        false
      end
    end
    
    def put(key, data)
      @cache.put(key, data)
    end

    def put_keep(key, data)
      @cache.putkeep(key, data)
    end

    def put_over(key, data)
      if d = @cache.get(key)
        if d['expires'] && d['expires'].to_i < Time.now.to_i
          nil
        else
          @cache.put(key, data)
        end
      end
    end

    def delete(key)
      @cache.delete(key)
    end

    def delete_expire(key, timeout)
      d = get(key) and put(key, d.merge({'expires' => timeout}))
    end

    def delete_match(match)
      q = TDBQRY.new(@cache)
      q.addcond('', TDBQRY::QCSTRINC, match)
      q.search
      q.searchout
    end

    def initialize(file)
      @cache = TDB::new # hash database
      @cache.open(file, TDB::OWRITER | TDB::OCREAT | TDB::OTRUNC)
      @cache.setxmsiz(500_000_000)
    end

  end

end