require 'sinatra'
require "sinatra/reloader" if development?
require 'rest-client'
require 'pry'
require 'pony'
require 'dotenv/load'
require 'letter_opener'

post '/check' do
  200
  # @api_key = ENV['API_KEY']
  # @form_data = params
  #
  # create_kontragent
  # update_kontragent_settlement_account
  # create_bill
  #
  # @bill_link = 'https://www.moedelo.org' + @new_bill['Online']
  #
  # unless @new_bill['Online'].nil? || @new_bill['Online'] == ''
  #   send_email
  # end
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
    JSON.parse(e.response.body)
  end
  new_ka = JSON.parse(ka_response.body)
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
    JSON.parse(e.response.body)
  end
end

def create_bill
  bill_url = 'https://restapi.moedelo.org/accounting/api/v1/sales/bill'
  doc_date = Date.today.to_s
  item_name = @form_data['ItemName']
  count = @form_data['Count']
  price = @form_data['Price']
  additional_info = @form_data['AdditionalInfo']
  contract_subject = @form_data['ContractSubject']

  bill_data = {
    "DocDate": doc_date,
    "Type": 2,
    "Status": 4,
    "KontragentId": @ka_id,
    "AdditionalInfo": additional_info,
    "ContractSubject": contract_subject,
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
    JSON.parse(e.response.body)
  end

  @new_bill = JSON.parse(bill_response.body)
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
