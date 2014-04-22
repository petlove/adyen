# encoding: UTF-8
require 'test_helper'

class AdyenTest < Minitest::Test

  def test_hmac_base64
    assert_equal '6nItEkVpIYF+i1RwrEyQ7RHmrfU=', Adyen::Encoding.hmac_base64('bla', 'bla')
  end

  def test_gzip_base64
    encoded_str = Adyen::Encoding.gzip_base64('bla')
    assert_equal 32, encoded_str.length
  end

  def test_fmt_date
    assert Adyen::Formatter::DateTime.fmt_date(Date.today) =~ /\A\d{4}-\d{2}-\d{2}\z/
    assert Adyen::Formatter::DateTime.fmt_date('2009-01-01') =~ /\A\d{4}-\d{2}-\d{2}\z/
    assert_raises(ArgumentError) { Adyen::Formatter::DateTime.fmt_date('2009-1-1') } 
  end

  def test_fmt_time
    assert Adyen::Formatter::DateTime.fmt_time(Time.now) =~ /\A\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z\z/
    assert Adyen::Formatter::DateTime.fmt_time('2009-01-01T11:11:11Z') =~ /\A\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}Z\z/
    assert_raises(ArgumentError) { Adyen::Formatter::DateTime.fmt_time('2009-01-01 11:11:11') } 
  end
end
