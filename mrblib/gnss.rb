#
# Plato::GNSS module
#
module Plato
  module GNSS
    attr_reader :gnss

    EARTH_R = 6378137.0   # Equatorial radius

    SUPPORTED_TYPES = [:GGA, :GSA, :GSV, :RMC, :VTG, :ZDA]

    # NMEA formats
    GGA = Struct.new(:utc, :latitude, :longitude, :hdr)
    VTG = Struct.new(:ttmg, :mtmg, :gsk, :gskph)
    RMC = Struct.new(:utc, :status, :latitude, :longitude, :gsk, :ttmg)

    # Satellite
    Satellite = Struct.new(:id, :elevation, :azimuth, :snr)
    
    ITEM = Struct.new(:key, :index, :type)

    GGA_ITEMS = [
      ITEM.new(:utc,      1,  :float),
      ITEM.new(:lat_raw,  2,  :float),
      ITEM.new(:ns,       3,  :raw),
      ITEM.new(:lng_raw,  4,  :float),
      ITEM.new(:ew,       5,  :raw),
      ITEM.new(:sat_cnt,  7,  :int),
      ITEM.new(:hdr,      8,  :float)
    ]
    VTG_ITEMS = [
      ITEM.new(:ttmg,     1,  :float),
      ITEM.new(:mtmg,     3,  :float),
      ITEM.new(:gsk,      5,  :float),
      ITEM.new(:gskph,    7,  :float)
    ]
    RMC_ITEMS = [
      ITEM.new(:utc,      1,  :float),
      ITEM.new(:status,   2,  :raw),
      ITEM.new(:lat_raw,  3,  :float),
      ITEM.new(:ns,       4,  :raw),
      ITEM.new(:lng_raw,  5,  :float),
      ITEM.new(:ew,       6,  :raw),
      ITEM.new(:gsk,      7,  :float),
      ITEM.new(:ttmg,     8,  :float),
      ITEM.new(:date,     9,  :int)
    ]

    # .new(types=[:RMC])
    # <description>
    #   Creates instance included GNSS module.
    # <params>
    #   types:    Array of data types
    #             (default: [:GGA, :GSA, :GSV, :RMC, :VTG, :ZDA])
    #             supported data types are
    #               :GGA, :GSA, :GSV, :RMC, :VTG, :ZDA
    def initialize(types=SUPPORTED_TYPES)
      types = [types] unless types.instance_of?(Array)
      errs = types - SUPPORTED_TYPES
      raise ArgumentError.new("un-supported type #{errs}") if errs.length > 0
      @types = types
      @gnss = {}
    end

    # gnss#parse_line(line) => [Symbol, Hash]
    # <description>
    #   Parse one line GNSS (NMNA format) data
    # <params>
    #   line:     GNSS data (NMEA format)
    # <return>
    #   [type, data]
    #     type:     data type (e.g., :GGA, :VTG, ...)
    #     data:     Hash table of parsed NMEA data
    def parse_line(line)
      return nil unless line
      return nil if line.length < 6

      # dump raw data
      puts line if $DEBUG

      # split gnss data
      items = line.chomp.tr('*', ',').split(',')
      return nil if items.nil? || items.size == 0 || items[0][0] != '$'

      type = items[0][3, 3].to_sym
      data = case type
        when :GGA;  parse_gga(items)
        when :GSA;  parse_gsa(items)
        when :GSV;  parse_gsv(items)
        when :RMC;  parse_rmc(items)
        when :VTG;  parse_vtg(items)
        when :ZDA;  parse_zda(items)
        else        nil
      end
      [type, data]
    end

    # gnss#parse(lines) => Hash
    # <descrition>
    #   Parse GNSS data (NMEA format) lines
    # <params>
    #   lines:    GNSS data lines (NMEA format)
    # <return>
    #   Hash      Hash table of GNSS data
    def parse(lines)
      lines.each_line {|line|
        _t, v = parse_line(line)
        @gnss.update(v) if v.instance_of? Hash
      }
      @gnss
    end

    # gnss#gga => GNSS::GGA
    # <description>
    #   get GGA data
    # <params>
    #   none.
    # <return>
    #   GNSS::GGA   GGA data
    def gga
      # if lat = @gnss[:lat_raw]
      #   lat = degree(lat)
      #   lat = -lat if @gnss[:ns] == 'S'
      # end
      # if lng = @gnss[:lng_raw]
      #   lng = degree(lng)
      #   lng = -lng if @gnss[:ew] == 'W'
      # end
      GGA.new(@gnss[:utc], latitude, longitude, @gnss[:hdr])
    end

    # gnss#vtg => GNSS::VTG
    # <description>
    #   get VTG data
    # <params>
    #   none.
    # <return>
    #   GNSS::VTG   VTG data
    def vtg
      VTG.new(@gnss[:ttmg], @gnss[:mtmg], @gnss[:gsk], @gnss[:gskph])
    end

    # gnss#rmc => GNSS::RMC
    # <description>
    #   get RMC data
    # <params>
    #   none.
    # <return>
    #   GNSS::RMC   RMC data
    def rmc
      RMC.new(@gnss[:utc], @gnss[:status], latitude, longitude, @gnss[:gsk], @gnss[:ttmg])
    end

    # private functinos

    def parse_items(items, params)
      v = {}
      params.each {|param|
        val = items[param.index]
        v[param.key] = case param.type
          when :float;  val.to_f
          when :int;    val.to_i
          else          val
        end
      }
      v
    end

    def parse_floats(items, params)
      v = {}
      params.each {|param|
        v[param[0]] = items[param[1]].to_f if items[param[1]].length > 0
      }
      v
    end

    def parse_ints(items, params)
      v = {}
      params.each {|param|
        v[param[0]] = items[param[1]].to_i if items[param[1]].length > 0
      }
      v
    end

    def degree(d)
      deg = (d / 100.0).to_i
      deg.to_f + (d - (deg * 100.0)) / 60.0
    end

    def latitude
      # return nil if @gnss[:ns].empty?
      if lat = @gnss[:lat_raw]
        lat = degree(lat)
        lat = -lat if @gnss[:ns] == 'S'
      end
      lat
    end

    def longitude
      # return nil if @gnss[:ew].empty?
      if lng = @gnss[:lng_raw]
        lng = degree(lng)
        lng = -lng if @gnss[:ew] == 'W'
      end
      lng
    end

    def parse_gga(items)
      return nil unless @types.include? :GGA
      # v = parse_floats(items, [
      #   [:time,     1],
      #   [:lat_raw,  2],
      #   [:lng_raw,  4],
      #   [:hdop,     8]
      # ])
      # v[:ns] = items[3] if items[3].length > 0
      # v[:ew] = items[5] if items[5].length > 0
      # if v[:lat_raw]
      #   v[:lat] = degree(v[:lat_raw])
      #   v[:lat] = -v[:lat] if v[:ns] == 'S'
      # end
      # if v[:lng_raw]
      #   v[:lng] = degree(v[:lng_raw])
      #   v[:lng] = -v[:lng] if v[:ew] == 'W'
      # end
      v = parse_items(items, GGA_ITEMS)
  # puts "parse_gga: #{v.inspect}"
      v
    end

    def parse_gsa(items)
      return nil unless @types.include? :GSA
      sat = (3..14).map {|i|
        items[i].to_i
      }
      sat.delete(0)
      {:mode => items[1], :sat_ids => sat}
    end

    def parse_gsv(items)
      return nil unless @types.include? :GSV
      msgs  = items[1].to_i
      no    = items[2].to_i
      sats  = items[3].to_i
      if no == 1
        # clear ?
      end
      cnt = no < msgs ? 4 : sats - (no - 1) * 4
      sat_map = (0...cnt).map {|i|
        Satellite.new(
          items[i * 4 + 4].to_i,
          items[i * 4 + 5].to_i,
          items[i * 4 + 6].to_i,
          items[i * 4 + 7].to_i)
      }
      # v[:type] = :GSV if v.length > 0
      {:sat => sat_map}
    end

    def parse_vtg(items)
      return nil unless @types.include? :VTG
      # v = parse_floats(items, [
      #   [:ttmg,   1],
      #   [:mtmg,   3],
      #   [:gsk,    5],
      #   [:gskph,  7]
      # ])
      v = parse_items(items, VTG_ITEMS)
  # puts "parse_vtg: #{v.inspect}"
      v
    end

    def parse_rmc(items)
      return nil unless @types.include? :RMC
      # v = parse_floats(items, [
      #   [:time,     1],
      #   [:lat_raw,  3],
      #   [:lng_raw,  5],
      #   [:gsk,      7],
      #   [:ttmg,     8],
      # ])
      # v.update(parse_ints(items, [
      #   [:date,     9]
      # ]))
      # v[:ns] = items[4] if items[4].length > 0
      # v[:ew] = items[6] if items[6].length > 0
      # if v[:lat_raw]
      #   v[:lat] = degree(v[:lat_raw])
      #   v[:lat] = -v[:lat] if v[:ns] == 'S'
      # end
      # if v[:lng_raw]
      #   v[:lng] = degree(v[:lng_raw])
      #   v[:lng] = -v[:lng] if v[:ew] == 'W'
      # end
      v = parse_items(items, RMC_ITEMS)
  # puts "parse_rmc: #{v.inspect}"
      v
    end

    def parse_zda(items)
      return nil unless @types.include? :ZDA
      v = parse_floats(items, [
        [:utc,      1]
      ])
      v.update(parse_ints(items, [
        [:day,      2],
        [:month,    3],
        [:year,     4],
        [:tzone_h,  5],
        [:tzone_m,  6],
      ]))
      # v[:type] = :ZDA if v.length > 0
  # puts "parse_zda: #{v.inspect}"
      v
    end

    # module functions

    # deg2rad(deg) #=> Float
    # convert degrees to radians
    # <params>
    #   deg:  degrees
    # <return>
    #   radians
    def deg2rad(deg)
      deg.to_f * Math::PI / 180.0
    end
    module_function :deg2rad

    # GNSS.distance(lat1, lng1, lat2, lng2) => Float
    # Calculate distance between 2 points
    # <params>
    #   lat1: Latitude #1
    #   lng1: Longitude #1
    #   lat2: Latitude #2
    #   lng2: Longitude #2
    # <return>
    #   distance between 2 points.
    def distance(lat1, lng1, lat2, lng2)
      lat1 = deg2rad(lat1)
      lng1 = deg2rad(lng1)
      lat2 = deg2rad(lat2)
      lng2 = deg2rad(lng2)

      lat_avr = (lat1 - lat2) / 2.0
      lng_avr = (lng1 - lng2) / 2.0

      EARTH_R * 2.0 * Math.asin(Math.sqrt(Math.sin(lat_avr) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(lng_avr) ** 2))
    end
    module_function :distance

  end
end
