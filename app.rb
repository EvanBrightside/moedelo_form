require 'sinatra'
require "sinatra/reloader" if development?
require 'rest-client'
require 'pry'
require 'pony'
require 'dotenv/load'
require 'letter_opener'

post '/check' do
  @api_key = ENV['API_KEY']
  @form_data = params

  create_kontragent
  update_kontragent_settlement_account
  create_bill

  @bill_link = 'https://www.moedelo.org' + @new_bill['Online']

  unless @new_bill['Online'].nil? || @new_bill['Online'] == ''
    send_email
  end
end

def create_kontragent
  ka_url = 'https://restapi.moedelo.org/kontragents/api/v1/kontragent'
  ka_form = case @form_data["Form"]
  when "Юр. лицо"
    'UL'
  when "ИП"
    'IP'
  else
    "Error: ka form has an invalid value (#{@form_data["Form"]})"
  end

  ka_data = {
    "Name": @form_data['Name'],
    "Type": 2,
    "Form": ka_form,
    "Inn": @form_data['Inn'],
    "Ogrn": @form_data['Ogrn'],
    "Okpo": @form_data['Okpo'],
    "Kpp": @form_data['Kpp'],
    "LegalAddress": @form_data['LegalAddress'],
    "ActualAddress": @form_data['ActualAddress']
  }
  begin
    ka_response = RestClient.post ka_url, ka_data, {content_type: :json, accept: :json, 'md-api-key': @api_key}
  rescue RestClient::ExceptionWithResponse => e
    puts JSON.parse(e.response.body)
  end
  new_ka = JSON.parse(ka_response&.body)
  @ka_id = new_ka['Id']
end

def update_kontragent_settlement_account
  ka_sa_data = {
    "Bik": @form_data['Bic'],
    "Number": @form_data['PaymentAccount']
  }

  ka_url = "https://restapi.moedelo.org/kontragents/api/v1/kontragent/#{@ka_id}/account"

  begin
    RestClient.post ka_url, ka_sa_data, {content_type: :json, accept: :json, 'md-api-key': @api_key}
  rescue RestClient::ExceptionWithResponse => e
    puts JSON.parse(e.response.body)
  end
end

def create_bill
  bill_url = 'https://restapi.moedelo.org/accounting/api/v1/sales/bill'
  doc_date = Date.today.to_s
  item_name = @form_data['ItemName'].nil? ? '' : @form_data['ItemName']
  count = @form_data['Count']
  price = @form_data['Price'].nil? ? '0' : @form_data['Price']
  additional_info = @form_data['AdditionalInfo'].nil? ? additional_info_text_data : @form_data['AdditionalInfo']
  contract_subject = @form_data['ContractSubject'].nil? ? contract_subject_text_data : @form_data['ContractSubject']

  bill_data = {
    "DocDate": doc_date,
    "Type": 2,
    "Status": 4,
    "KontragentId": @ka_id,
    "ContractSubject": contract_subject,
    "AdditionalInfo": additional_info,
    "NdsPositionType": 1,
    "UseStampAndSign": true,
    "Items": [
      {
        "Type": 2,
        "Name": item_name,
        "Count": count,
        "Unit": "шт",
        "Price": price,
        "NdsType": 0
      }
    ]
  }

  begin
    bill_response = RestClient.post bill_url, bill_data.to_json, {content_type: :json, accept: :json, 'md-api-key': @api_key}
  rescue RestClient::ExceptionWithResponse => e
    puts JSON.parse(e.response.body)
  end

  @new_bill = JSON.parse(bill_response&.body)
end

def send_email
  if Sinatra::Base.environment.to_s == 'development'
    Pony.options = {
      from: ENV['EMAIL_FROM'],
      subject: "New contract-bill",
      body: "#{@bill_link}",
      via: LetterOpener::DeliveryMethod,
      via_options: {:location => File.expand_path('../tmp/letter_opener', __FILE__)}
    }
  else
    Pony.options = {
      from: ENV['EMAIL_FROM'],
      subject: "New contract-bill",
      body: "#{@bill_link}",
      via: :smtp,
      via_options: {
        address:              ENV['SMTP_SERVER'],
        port:                 ENV['SMTP_PORT'],
        user_name:            ENV['MAIL_USER_NAME'],
        password:             ENV['MAIL_PASSWORD'],
        authentication:       :plain,
        domain:               ENV['DOMAIN'],
        enable_starttls_auto: true,
        openssl_verify_mode:  'none'
      }
    }
  end
  Pony.mail(to: @form_data['CustomerEmail'])
end

def contract_subject_text_data
  <<~INFO
    Предметом настоящего Договора является возмездное предоставление Исполнителем Услуг Заказчику.
    Исполнитель оказывает Заказчику информационно-консультативные услуги.
  INFO
end

def additional_info_text_data
  <<~INFO
    1. Оплата Услуг производится Заказчиком на основании счетов, выставленных Исполнителем, в порядке
    предварительной оплаты в размере 100% от суммы счета.

    2. Сдача-приёмка
    2.1. Исполнитель направляет Заказчику 2 экземпляра акта сдачи-приёмки, указав в каждом экземпляре
    оказанные услуги.
    2.2. Если Заказчик не вернул подписанный экземпляр акта сдачи-приёмки в течение 2 дней со дня получения или
    не направил Исполнителю его сканированную копию, указанные в нём услуги считаются оказанными в полном
    объёме и в надлежащие сроки, а результат — принятым без возражений.

    3. Обязанности и права
    3.1. Заказчик и Исполнитель обязаны:
    признавать электронные письма с адресов, указанных в реквизитах к Договору и в неотъемлемых приложениях к
    нему, а также переписку в системах обмена электронными сообщениями, аналогом собственноручной подписи,
    имеющим силу простой электронной подписи;
    при наступлении обстоятельств непреодолимой силы уведомить другую сторону о возникновении таких
    обстоятельств в течение 3 дней с момента их возникновения.
    3.2. Исполнитель вправе:
    привлекать для оказания услуг третьих лиц без дополнительного уведомления Заказчика;
    бессрочно указывать на своём веб-сайте коммерческое обозначение Заказчика, его фирменное наименование,
    логотип и товарный знак в рекламных и маркетинговых целях.

    4. Конфиденциальность
    4.1. Заказчик и Исполнитель не разглашают информацию и документы, касающиеся Договора, без
    предварительного письменного взаимного согласия в течение неограниченного срока, за исключением сведений,
    необходимых Исполнителю для заключения договоров с третьими лицами в порядке субподряда. В этом случае
    Исполнитель подписывает с такими третьими лицами соглашение о неразглашении конфиденциальной
    информации.

    5. Ответственность и обстоятельства непреодолимой силы
    5.1. Неустойка за несвоевременное исполнение обязательств — 0,1 % от стоимости Договора в день, но не
    более 10 % суммы соответствующего неисполненного обязательства. Неустойка начисляется с даты получения
    соответствующей стороной требования об оплате и перечисляется не позднее 5 дней с момента получения
    такого требования.
    5.2. Ответственность Заказчика перед Исполнителем и Исполнителя перед Заказчиком, включая реальный,
    упущенную выгоду, неустойку и иные виды ущерба, ограничены 10 % от полной стоимости Договора за весь срок
    его действия.
    5.3. Досудебный порядок урегулирования споров в течение 30 дней обязателен. При невозможности разрешить
    спор в досудебном порядке он подлежит рассмотрению в Арбитражном суде города Москвы.
    5.4. Сторона освобождается от ответственности за неисполнение или ненадлежащее исполнение своих
    обязательств вследствие обстоятельств непреодолимой силы, удостоверенных справкой Торговопромышленной палаты Российской Федерации.

    6. Действие и расторжение
    6.1. Договор вступает в силу с момента подписания и действует до полного исполнения взаимных обязательств
    Заказчика и Исполнителя.
    6.2. Каждая сторона вправе расторгнуть договор, уведомив об этом другую сторону не позднее 1 месяца до даты
    расторжения. Стороны обязаны провести взаиморасчёты не позднее даты расторжения Договора.
    6.3. При прекращении Договора предоплата не возвращается, взаимные убытки не компенсируются, взаимные
    неустойки, кроме предусмотренных Договором, не взимаются.

    7. Иные условия
    7.1. К отношениям сторон по Договору применяются нормы Гражданского кодекса Российской Федерации о
    договорах возмездного оказания услуг и об абонентских договорах.
    7.2. С даты вступления в силу Договора прекращается действие любых иных соглашений между сторонами,
    касающихся условий Договора, если они противоречат Договору.
    7.3. Если формулировки любого приложения к Договору противоречат формулировкам Договора, применяются
    формулировки приложения к Договору.

  INFO
end
