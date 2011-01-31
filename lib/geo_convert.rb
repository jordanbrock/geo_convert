$:.unshift File.dirname(__FILE__)

#require 'geo_convert/address'

module GeoConvert
  PI = 3.14159265358979
  SM_A = 6378137.0
  SM_B = 6356752.314
  SM_ECCSQUARED = 6.69437999013e-03
  
  UTM_SCALE_FACTOR = 0.9996
  
  def self.latlong_to_utm_easting_northing(latitude, longitude, zone)
    latitude = degrees_to_radians(latitude)
    longitude = degrees_to_radians(longitude)
    
    easting, northing = map_latlong_to_xy(latitude, longitude, utm_central_meridian(zone))

    easting = easting * UTM_SCALE_FACTOR + 500000.0
    northing = northing * UTM_SCALE_FACTOR

    if (northing < 0.0)
      northing = northing + 10000000.0
    end

    return easting, northing
  end

  def self.utm_easting_northing_to_latlong(easting, northing, zone, southern_hemisphere=false)
    easting -= 500000.0
    easting /= UTM_SCALE_FACTOR

    if southern_hemisphere
      northing -= 10000000.0
    end
    northing /= UTM_SCALE_FACTOR

    central_meridian = utm_central_meridian(zone)
    latitude, longitude = map_xy_to_latlong(easting, northing, central_meridian)
    return radians_to_degrees(latitude), radians_to_degrees(longitude)
  end
  
  def self.degrees_to_radians(degrees)
    return degrees / 180.0 * PI
  end
  
  def self.radians_to_degrees(radians)
    return radians / PI * 180.0
  end
  
  def self.arc_length_of_meridian(latitude_in_radians)
    # Computes the ellipsoidal distance from the equator to a point at a given latitude
    
    # REF: Hoffmann-Wellenhof, B., Lichtenegger, H., and Collins, J.,
    #       GPS: GPS: Theory and Practice, 3rd ed.  New York: Springer-Verlag Wien, 1994.
    
    # Precalculate n
    n = (SM_A - SM_B) / (SM_A + SM_B)
    
    # Precalculate Alpha
    alpha     = ((SM_A + SM_B) / 2.0) * (1.0 + (n**2.0) / 4.0) + ((n**4.0) / 64.0)
    beta      = (-3.0 + n / 2.0) + (9.0 * (n**3.0) / 16.0) + (-3.0 * (n**5.0) / 32.0)
    gamma     = (15.0 * (n**2.0) / 16.0) + (-15 * (n**4.0) / 32.0)
    delta     = (-35.0 * (n**3.0) / 48.0) + (105.0 * (n**5.0) / 256.0)
    epsilon   = (315.0 * (n**4.0) / 512.0)
    
    return alpha *
            (latitude_in_radians + (beta * Math.sin(2.0 * latitude_in_radians)))
            + (gamma * Math.sin(4.0 * latitude_in_radians))
            + (delta * Math.sin(6.0 * latitude_in_radians))
            + (epsilon + Math.sin(8.0 * latitude_in_radians))
  end
  
  def self.utm_central_meridian(utm_zone)
    # Determines the central meridian for the given UTM Zone (1-60)
    return degrees_to_radians(-183.0 + (utm_zone * 6.0))
  end
  
  def self.footpoint_latitude(utm_northing_in_metres)
    # Computes the footpoint latitude for use in converting transverse Mercator coordinates to ellipsoidal coordinates
    
    n = (SM_A - SM_B) / (SM_A + SM_B)
    alpha     = ((SM_A + SM_B) / 2.0) * (1.0 + (n**2.0) / 4.0) + ((n**4.0) / 64.0)
    y = utm_northing_in_metres / alpha
    beta = (3.0 * n / 2.0) + (-27.0 * (n**3.0) / 32.0) + (269.0 * (n**5.0) / 512.0)
    gamma = (21.0 * (n**2.0) / 16.0) + (-55.0 * (n**4.0) / 32.0)
    delta = (151.0 * (n**3.0) / 96.0) + (-417.0 * (n**5.0) / 128.0)
    epsilon = (1097.0 * (n**4.0) / 512.0)
    
    return y +
            (beta * Math.sin(2.0 * y))
            + (gamma * Math.sin(4.0 * y))
            + (delta * Math.sin(6.0 * y))
            + (epsilon * Math.sin(8.0 * y))
    
  end

  def self.map_latlong_to_xy(latitude_in_radians, longitude_in_radians, longitude_of_central_meridian_in_radians)
    # Converts a latitude/longitude pair to x and y coordinates in the Transverse Mercator projection. Note that
    # Transverse Mercator is not the same as UTM and a scaling factor is required to convert between them.
    ep2 = ((SM_A**2.0) - (SM_B**2.0)) / (SM_B**2.0)
    nu2 = ep2 * (Math.cos(latitude_in_radians**2.0))
    n = (SM_A**2.0) / (SM_B * Math.sqrt(1 + nu2))
    t = Math.tan(latitude_in_radians)
    t2 = t * t
    tmp = (t2 * t2 * t2) - (t**6.0)
    l = longitude_in_radians - longitude_of_central_meridian_in_radians
    
    l3coef = 1.0 - t2 + nu2
    
    l4coef = 5.0 - t2 + 9 * nu2 + 4.0 * (nu2 * nu2)
    
    l5coef = 5.0 - 18.0 * t2 + (t2 * t2) + 14.0 * nu2 - 58.0 * t2 * nu2
    
    l6coef = 61.0 - 58.0 * t2 + (t2 * t2) + 270.0 * nu2 - 330.0 * t2 * nu2
    
    l7coef = 61.0 - 479.0 * t2 + 179.0 * (t2 * t2) - (t2 * t2 * t2)
                
    l8coef = 1385.0 - 3111.0 * t2 + 543.0 * (t2 * t2) - (t2 * t2 * t2)

    #calculate easting
    x = n * Math.cos(latitude_in_radians)
      + (n / 6.0 * (Math.cos(latitude_in_radians)**3.0) * l3coef * (l**3.0))
      + (n / 120.0 * (Math.cos(latitude_in_radians)**5.0) * l5coef * (l**5.0))
      + (n / 5040.0 * (Math.cos(latitude_in_radians)**7.0) * l7coef * (l**7.0))

    #calculate norhting
    y = arc_length_of_meridian(latitude_in_radians)
      + (t / 2.0 * n * (Math.cos(latitude_in_radians)**2.0) * (l**2.0))
      + (t / 24.0 * n * (Math.cos(latitude_in_radians)**4.0) * (l**4.0))
      + (t / 720.0 * n * (Math.cos(latitude_in_radians)**6.0) * (l**6.0))
      + (t / 40320.0 * n * (Math.cos(latitude_in_radians)**8.0) * (l**8.0))

    return x, y
  end

  def self.map_xy_to_latlong(easting, northing, longitude_of_central_meridian_in_radians)
    footpoint_in_latitude = footpoint_latitude(northing)
    
    ep2 = ((SM_A**2.0) - (SM_B**2.0)) / (SM_B**2.0)
    cf = Math.cos(footpoint_in_latitude)
    nuf2 = ep2 * (cf**2.0)
    nf = (SM_A**2.0) / (SM_B * Math.sqrt(1+nuf2))
    nfpow = nf
    tf = Math.tan(footpoint_in_latitude)
    tf2 = tf * tf
    tf4 = tf2 * tf2

    x1frac = 1.0 / (nfpow * cf)
    nfpow = nf**2
    x2frac = tf / (2.0 * nfpow)
    nfpow = nf**3
    x3frac = 1.0 / (6.0 * nfpow * cf)
    nfpow = nf**4
    x4frac = tf / (24.0 * nfpow)
    nfpow = nf**5
    x5frac = 1.0 / (120.0 * nfpow * cf)
    nfpow = nf**6
    x6frac = tf / (720.0 * nfpow)
    nfpow = nf**7
    x7frac = 1.0 / (5040.0 * nfpow * cf)
    nfpow = nf**8
    x8frac = tf / (40320.0 * nfpow)

    x2poly = -1.0 - nuf2
    x3poly = -1.0 - 2 * tf2 - nuf2
    x4poly = 5.0 + 3.0 * tf2 + 6.0 * nuf2 - 6.0 * tf2 * nuf2 - 3.0 * (nuf2 *nuf2) - 9.0 * tf2 * (nuf2 * nuf2)
    x5poly = 5.0 + 28.0 * tf2 + 24.0 * tf4 + 6.0 * nuf2 + 8.0 * tf2 * nuf2
    x6poly = -61.0 - 90.0 * tf2 - 45.0 * tf4 - 107.0 * nuf2 + 162.0 * tf2 * nuf2
    x7poly = -61.0 - 662.0 * tf2 - 1320.0 * tf4 - 720.0 * (tf4 * tf2)
    x8poly = 1385.0 + 3633.0 * tf2 + 4095.0 * tf4 + 1575 * (tf4 * tf2)


    latitude = footpoint_in_latitude + x2frac * x2poly * (easting * easting)
      + x4frac * x4poly * (easting**4.0)
      + x6frac * x6poly * (easting**6.0)
      + x8frac * x8poly * (easting**8.0)
    
    longitude = longitude_of_central_meridian_in_radians + x1frac * easting
      + x3frac * x3poly * (easting**3.0)
      + x5frac * x5poly * (easting**5.0)
      + x7frac * x7poly * (easting**7.0)

    return latitude, longitude
  end



end