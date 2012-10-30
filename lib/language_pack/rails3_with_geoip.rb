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
    if update_available?
      content = get_result_for(current_md5sum)
      File.open(tmpfile, 'w') do |f|
        f.write(content)
      end
      File.unlink(outfile) if FileTest.exists?(outfile)
      File.rename(tmpfile, outfile)
      puts "GeoIP.dat created"
    else
      puts "GeoIP.dat not created"
    end
  end

  def license_key
    run('echo $GEOIP_KEY')
  end

  def outfile
    'config/GeoIP.dat'
  end

  def tmpfile
    'tmp/GeoIP.dat'
  end

  def current_md5sum=(content)
    @current_md5sum ||= Digest::MD5.hexdigest(content)
  end

  def current_md5sum
    @current_md5sum
  end

  def update_available?
    omd5sum = Digest::MD5.hexdigest(File.open(outfile, 'r').read) rescue nil
    content = get_result_for(omd5sum)
    if content =~ /No new updates available/
      false
    else
      current_md5sum = content
      true
    end
  end

  # Fetch GeoIP country file from MaxMind
  def get_result_for(md5)
    url = "ht" + "tp://www.maxmind.com/app/update?"
    url += "license_key=#{license_key}&md5=#{md5}"

    puts "Fetching data from #{url}"

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