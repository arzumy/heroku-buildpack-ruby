=begin
  Originally from http://www.maxmind.com/geoipupdate.rb.html
    Purpose:
      Updates GeoIP Country (paid) database from MaxMind.com. Requires
      valid license key to work.

    Why:
      1) I hate the idea of running some weird C code ("geoipupdate")
         from cron, that's why.
      2) I don't want to run "geoipupdate" on all machines using this DB.

    Author: Wejn <wejn at box dot cz>
    License: GPLv2 (without the "latter" option)
    Requires: Ruby >= 1.8, geoip country license (to be of any value)
    TS: 20060626181500

  Butchered by Arzumy MD
=end

require "language_pack"
require "language_pack/rails3"
require 'digest/md5'
require 'open-uri'
require 'zlib'
require 'stringio'

class LanguagePack::Rails3WithGeoip < LanguagePack::Rails3
  # detects if this is a Rails 3.x app with GeoIP
  # @return [Boolean] true if it's a Rails 3.x app with GeoIP
  def self.use?
    super &&
      File.exists?("config/GeoIP.dat")
  end

  def name
    "Ruby/Rails3 with GeoIP"
  end

  def compile
    super
    update_geoip_data
  end

private

  def update_geoip_data
    content = get_result_for(current_md5sum)
    File.open(outfile, 'w') do |f|
      f.write(content)
    end
    puts "GeoIP.dat created"
  end

  def geoip_dat_url
    # using heroku labs:enable user-env-compile
    ENV['GEOIP_DAT_URL']
  end

  def outfile
    'config/GeoIP.dat'
  end

  # Fetch GeoIP country cached file
  def get_result_for(md5)
    puts "Fetching data from #{geoip_dat_url}"

    content = nil
    open(url) do |io|
      raw = io.read
      gzip_header = "\x1f\x8b".force_encoding('ASCII-8BIT')
      compr = StringIO.new(raw)
      if compr.read(2) == gzip_header
        compr.rewind
        gz = Zlib::GzipReader.new(compr)
        content = gz.read.force_encoding('ASCII-8BIT')
        gz.close
      else
        content = raw
        puts content.to_s
      end
    end
    content
  end
end