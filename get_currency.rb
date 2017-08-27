require 'open-uri'
require 'nokogiri'

class ExchangeRate
  VAL = 'R01235'.freeze # код валюты для апи банка

  def initialize(date)
    @date = date.nil? ? Time.now : Time.parse(date)
  end

  def date_incorrect? # проверка на выходные банка
    @date.monday? || @date.sunday?	
  end

  def correct_date # исправление на день или два если это выходной банка
    @date = @date.wday.zero? ? @date - (60 * 60 * 24) : @date - (60 * 60 * 48)
  end

  def url
    "http://www.cbr.ru/scripts/XML_dynamic.asp?date_req1=#{@date}&date_req2=#{@date}&VAL_NM_RQ=#{VAL}"
  end

  def get_rate
    @rate = Nokogiri::HTML(open(url)).xpath('//value').text
  end

  def save_rate # писать решил в файл потому что бд для одного значения делать неадекватно
    File.write('LastVal', @rate)
  end

  def load_rate
    File.exist?('LastVal') ? File.read('LastVal') : 'Нет сохранённого курса'
  end

  def validate_date
    return load_rate if @date > Time.now

    correct_date if date_incorrect?

    @date = @date.strftime('%d/%m/%Y')
  end

  def rate
  	validate_date
  	
    3.times do |_i| # 3 раза стучимся, если необходимое значение не получено, возвращаем последнее сохранённое значение
      begin
        break unless get_rate.empty?
      rescue OpenURI::HTTPError
        next
      end
    end

    if !@rate.nil?
      save_rate
      @rate
    else
      load_rate
    end
  end
end

begin
  currency = ExchangeRate.new(ARGV[0])
  p currency.rate
rescue ArgumentError
  p 'Формат даты не верен, LastVal доллара:'
  # гружу данные не методом потому что класс не инициализировался
  p File.exist?('LastVal') ? File.read('LastVal') : 'Нет сохранённого курса'
end
