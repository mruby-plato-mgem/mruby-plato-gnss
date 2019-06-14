# Plato::GNSS module

class GPS
  include Plato::GNSS
end

LINES = <<"EOS"
$GPGGA,085120.307,3541.1493,N,13945.3994,E,1,08,1.0,6.9,M,35.9,M,,0000*5E
$GPGLL,2446.79006,N,12059.72083,E,123923.00,A,A*6C
$GPGSA,A,3,29,26,05,10,02,27,08,15,,,,,1.8,1.0,1.5*3E
$GPVTG,240.3,T,,M,000.0,N,000.0,K,A*08
$GPGSV,3,1,12,26,72,352,28,05,65,066,37,15,50,268,35,27,33,189,37*7F
$GPRMC,085120.307,A,3541.1493,N,13945.3994,E,000.0,240.3,181211,,,A*6A
$GPZDA,085120.307,13,06,2019,09,00*10
EOS

assert('Plato::GNSS', 'class') do
  assert_equal(Module, Plato::GNSS.class)
end

assert('Plato::GNSS', 'constants') do
  types = Plato::GNSS::SUPPORTED_TYPES
  assert_equal(Array, types.class)
  assert_true(types.include?(:GGA))
  assert_true(types.include?(:GSA))
  assert_true(types.include?(:GSV))
  assert_true(types.include?(:RMC))
  assert_true(types.include?(:VTG))
  assert_true(types.include?(:ZDA))
end

assert('Plato::GNSS', 'structures') do
  assert_nothing_raised {
    gga = Plato::GNSS::GGA.new
    vtg = Plato::GNSS::VTG.new
    rmc = Plato::GNSS::RMC.new
    sat = Plato::GNSS::Satellite.new
  }
end

assert('Plato::GNSS', 'new') do
  gps = GPS.new
  types = gps.instance_variable_get('@types')
  assert_equal(Plato::GNSS::SUPPORTED_TYPES, types)

  gps = GPS.new([:GGA, :VTG])
  types = gps.instance_variable_get('@types')
  assert_equal([:GGA, :VTG], types)

  gps = GPS.new(:ZDA)
  types = gps.instance_variable_get('@types')
  assert_equal([:ZDA], types)

  assert_raise(ArgumentError) {GPS.new([1])}
  assert_raise(ArgumentError) {GPS.new(:XXX)}
  assert_raise(ArgumentError) {GPS.new([:GGA, :ZZZ, :VTG])}
end

assert('Plato::GNSS', 'parse_line - GGA') do
  gps = GPS.new
  t, v = gps.parse_line('$GPGGA,085120.307,3541.1493,N,13945.3994,E,1,08,1.0,6.9,M,35.9,M,,0000*5E')
  assert_equal(:GGA, t)
  assert_float(85120.307, v[:utc])
  assert_float(3541.1493, v[:lat_raw])
  assert_equal('N', v[:ns])
  assert_float(13945.3994, v[:lng_raw])
  assert_equal('E', v[:ew])
  assert_float(1.0, v[:hdr])
end

assert('Plato::GNSS', 'parse_line - VTG') do
  gps = GPS.new
  t, v = gps.parse_line('$GPVTG,240.3,T,,M,000.0,N,000.0,K,A*08')
  assert_equal(:VTG, t)
  assert_float(240.3, v[:ttmg])
  assert_float(0.0, v[:mtmg])
  assert_float(0.0, v[:gsk])
  assert_float(0.0, v[:gskph])
end

assert('Plato::GNSS', 'parse_line - RMC') do
  gps = GPS.new
  t, v = gps.parse_line('$GPRMC,085120.307,A,3541.1493,N,13945.3994,E,000.0,240.3,181211,,,A*6A')
  assert_equal(:RMC, t)
  assert_float(85120.307, v[:utc])
  assert_float(3541.1493, v[:lat_raw])
  assert_equal('N', v[:ns])
  assert_float(13945.3994, v[:lng_raw])
  assert_equal('E', v[:ew])
  assert_float(240.3, v[:ttmg])
  assert_float(0.0, v[:gsk])
end

assert('Plato::GNSS', 'parse_line - GSA') do
  gps = GPS.new
  t, v = gps.parse_line('$GPGSA,A,3,29,26,05,10,02,27,08,15,,,,,1.8,1.0,1.5*3E')
  assert_equal(:GSA, t)
  assert_equal('A', v[:mode])
  assert_equal([29, 26, 5, 10, 2, 27, 8, 15], v[:sat_ids])
end

assert('Plato::GNSS', 'parse_line - GSV') do
  gps = GPS.new
  t, v = gps.parse_line('$GPGSV,3,1,12,26,72,352,28,05,65,066,37,15,50,268,35,27,33,189,37*7F')
  assert_equal(:GSV, t)
  sats = v[:sat]
  assert_true(sats.instance_of?(Array))
  assert_equal(4, sats.length)

  assert_equal(26, sats[0].id)
  assert_equal(72, sats[0].elevation)
  assert_equal(352, sats[0].azimuth)
  assert_equal(28, sats[0].snr)

  assert_equal(5, sats[1].id)
  assert_equal(65, sats[1].elevation)
  assert_equal(66, sats[1].azimuth)
  assert_equal(37, sats[1].snr)

  assert_equal(15, sats[2].id)
  assert_equal(50, sats[2].elevation)
  assert_equal(268, sats[2].azimuth)
  assert_equal(35, sats[2].snr)

  assert_equal(27, sats[3].id)
  assert_equal(33, sats[3].elevation)
  assert_equal(189, sats[3].azimuth)
  assert_equal(37, sats[3].snr)
end

assert('Plato::GNSS', 'parse_line - ZDA') do
  gps = GPS.new
  t, v = gps.parse_line('$GPZDA,085120.307,13,06,2019,09,00*10')
  assert_equal(:ZDA, t)
  assert_float(85120.307, v[:utc])
  assert_equal(13, v[:day])
  assert_equal(6, v[:month])
  assert_equal(2019, v[:year])
  assert_equal(9, v[:tzone_h])
  assert_equal(0, v[:tzone_m])
end

assert('Plato::GNSS', 'parse_line - un-supported') do
  gps = GPS.new
  t, v = gps.parse_line('$GPGLL,2446.79006,N,12059.72083,E,123923.00,A,A*6C')
  assert_equal(:GLL, t)
  assert_nil(v)
end

assert('Plato::GNSS', 'parse') do
  gps = GPS.new
  v = gps.parse(LINES)
  # GGA
  assert_float(85120.307, v[:utc])
  assert_float(3541.1493, v[:lat_raw])
  assert_equal('N', v[:ns])
  assert_float(13945.3994, v[:lng_raw])
  assert_equal('E', v[:ew])
  assert_float(1.0, v[:hdr])
  # VTG
  assert_float(240.3, v[:ttmg])
  assert_float(0.0, v[:mtmg])
  assert_float(0.0, v[:gsk])
  assert_float(0.0, v[:gskph])
  # GSA
  assert_equal('A', v[:mode])
  assert_equal([29, 26, 5, 10, 2, 27, 8, 15], v[:sat_ids])
  # GSV
  sats = v[:sat]
  assert_true(sats.instance_of?(Array))
  assert_equal(4, sats.length)
  # ZDA
  # assert_float(85120.307, v[:utc])
  assert_equal(13, v[:day])
  assert_equal(6, v[:month])
  assert_equal(2019, v[:year])
  assert_equal(9, v[:tzone_h])
  assert_equal(0, v[:tzone_m])
end

assert('Plato::GNSS', 'parse - filter') do
  gps = GPS.new([:GGA])
  v = gps.parse(LINES)
  # GGA
  assert_float(85120.307, v[:utc])
  assert_float(3541.1493, v[:lat_raw])
  assert_equal('N', v[:ns])
  assert_float(13945.3994, v[:lng_raw])
  assert_equal('E', v[:ew])
  assert_float(1.0, v[:hdr])
  # VTG
  assert_nil(v[:ttmg])
  assert_nil(v[:mtmg])
  assert_nil(v[:gsk])
  assert_nil(v[:gskph])
  # GSA
  assert_nil(v[:mode])
  assert_nil(v[:sat_ids])
  # GSV
  assert_nil(v[:sat])
  # ZDA
  assert_nil(v[:day])
  assert_nil(v[:month])
  assert_nil(v[:year])
  assert_nil(v[:tzone_h])
  assert_nil(v[:tzone_m])
end

assert('Plato::GNSS', 'latitude') do
  gps = GPS.new([:GGA])
  v = gps.parse('')
  v[:ns] = 'N'
  v[:lat_raw] = 3545.0
  assert_float(35.75, gps.latitude)
  v[:ns] = 'S'
  v[:lat_raw] = 4220.0
  assert_float(-42.333333333333, gps.latitude)
end

assert('Plato::GNSS', 'longitude') do
  gps = GPS.new([:GGA])
  v = gps.parse('')
  v[:ew] = 'E'
  v[:lng_raw] = 13840.0
  assert_float(138.666666666667, gps.longitude)
  v[:ew] = 'W'
  v[:lng_raw] = 12015.0
  assert_float(-120.25, gps.longitude)
end

assert('Plato::GNSS', 'gga') do
  gps = GPS.new(:GGA)
  v = gps.parse(LINES)
  gga = gps.gga
  assert_float(85120.307, gga.utc)
  assert_float(gps.latitude, gga.latitude)
  assert_float(gps.longitude, gga.longitude)
  assert_float(1.0, gga.hdr)
end

assert('Plato::GNSS', 'vtg') do
  gps = GPS.new(:VTG)
  v = gps.parse(LINES)
  vtg = gps.vtg
  assert_float(240.3, vtg.ttmg)
  assert_float(0.0, vtg.mtmg)
  assert_float(0.0, vtg.gsk)
  assert_float(0.0, vtg.gskph)
end
