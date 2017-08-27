require 'open-uri'
require 'nokogiri'

class Exchange_Rate

  def initialize(date)

    @val = 'R01235' #код валюты для апи банка

    @date = date.nil? ? Time.now : Time.parse(date)

  end

  def date_incorrect? #проверка на выходные банка
    (@date.monday? or @date.sunday?) ? true : false
  end

  def correct_date #исправление на день или два если это выходной банка
    @date = @date.wday == 0 ? @date - ( 60 * 60 * 24 ) : @date - ( 60 * 60 * 48 )
  end 

  def get_url
    "http://www.cbr.ru/scripts/XML_dynamic.asp?date_req1=#{@date}&date_req2=#{@date}&VAL_NM_RQ=#{@val}"
  end

  def get_rate
    @rate = Nokogiri::HTML(open(get_url)).xpath('//value').text
  end

  def save_rate #писать решил в файл потому что бд для одного значения делать неадекватно
    File.write('Последний курс', @rate)
  end

  def load_rate
    File.exist?('Последний курс') ? File.read('Последний курс') : 'Нет сохранённого курса'
  end

  def rate

    if (@date > Time.now)
      return load_rate
    end

    if (date_incorrect?)
      correct_date
    end

    @date = @date.strftime("%d/%m/%Y")  

    3.times do |i| #3 раза стучимся, если необходимое значение не получено, возвращаем последнее сохранённое значение
      
      begin
        if (! get_rate.empty?)
          break
        end
      rescue OpenURI::HTTPError
        next
      end

    end

    if(! @rate.nil?)
      save_rate
      return @rate
    else 
      return load_rate
    end  

  end

end

begin
  currency = Exchange_Rate.new(ARGV[0])
  p currency.rate
rescue ArgumentError
  p 'Формат даты не верен, последний курс доллара:'
  #гружу данные не методом потому что класс не инициализировался
  p File.exist?('Последний курс') ? File.read('Последний курс') : 'Нет сохранённого курса'
end


