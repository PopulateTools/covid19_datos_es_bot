require "net/https"
require "json"
require "cgi"

class Utils
  def self.query_places
    "select distinct(ccaa) from datadista_ccaa_covid19_confirmados_pcr_long order by ccaa ASC"
  end

  def self.query_data(autonomy)
    <<-SQL
WITH last_data_pcr AS (
  SELECT fecha::date, total::integer,
  LAG(total::integer,1) OVER (ORDER BY fecha::date) total_1,
  LAG(total::integer,2) OVER (ORDER BY fecha::date) total_2,
  LAG(total::integer,3) OVER (ORDER BY fecha::date) total_3,
  LAG(total::integer,4) OVER (ORDER BY fecha::date) total_4,
  LAG(total::integer,5) OVER (ORDER BY fecha::date) total_5,
  LAG(total::integer,6) OVER (ORDER BY fecha::date) total_6,
  LAG(total::integer,7) OVER (ORDER BY fecha::date) total_7
  FROM datadista_ccaa_covid19_confirmados_pcr_long
  where ccaa='#{autonomy}'
  order by fecha::date DESC
  LIMIT 7
)
SELECT
  *
FROM
  last_data_pcr
SQL
  end

  def self.run_query(sql)
    url = "https://demo-datos.gobify.net/api/v1/data/data?sql=#{CGI.escape(sql)}"

    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)
    parsed = JSON.parse(response.body)
    parsed['data']
  end

  def self.parse_data(data, autonomy)
    first = data[0]

    <<-ANSWER
Casos reportados el #{first['fecha']} en #{autonomy} (PCR): #{number_to_delimited(first['total'], separator: ',', delimiter: '.')}
  - Nuevos casos: #{number_to_delimited(first['total'] - first['total_1'], separator: ',', delimiter: '.')}
  - Nuevos casos hace 2 días: #{number_to_delimited(first['total_1'] - first['total_2'], separator: ',', delimiter: '.')}
  - Nuevos casos hace 3 días: #{number_to_delimited(first['total_2'] - first['total_3'], separator: ',', delimiter: '.')}
  - Nuevos casos hace 7 días: #{number_to_delimited(first['total_6'] - first['total_7'], separator: ',', delimiter: '.')}
ANSWER
  end

  def self.about_message
    <<-MESSAGE
Un proyecto de fin de semana de Fernando Blat y Populate - https://populate.tools

Sobre los datos:
- extraídos desde el Github de Datadista - https://github.com/datadista/datasets/
- alojados y servidos vía API por Gobierto Datos - https://gobierto.es/modulos/datos-abiertos/
- fechas de actualización: https://github.com/datadista/datasets/blob/master/COVID%2019/fechas.md

¿Sugerencias? Escríbeme a fernando@populate.tools
MESSAGE
  end

end
