@EndUserText.label: 'Test of currency conversion'
define view entity zv_curr_conv_test
  as select from ztcurrconvtest
{
  key id,
      @Semantics.amount.currencyCode: 'CURRENCY'
      amount,
      currency,
      @EndUserText.label: 'Price (in US American Dollars)'
      @Semantics.amount.currencyCode: 'USCURRENCY'
      currency_conversion(
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('USD' as abap.cuky),
      //exchange_rate_type => 'M',
        exchange_rate_date => $session.system_date
                         )     as PriceInUSD,
      cast('USD' as abap.cuky) as USCurrency,
      @EndUserText.label: 'Price (in Australian Dollars)'
      @Semantics.amount.currencyCode: 'AUCURRENCY'
      currency_conversion(
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('AUD' as abap.cuky),
      //exchange_rate_type => 'M',
        exchange_rate_date => $session.system_date
                         )     as PriceInAUD,
      cast('AUD' as abap.cuky) as AUCurrency,
      @EndUserText.label: 'Price (in Indonesian Rupiahs)'
      @Semantics.amount.currencyCode: 'IDCURRENCY'
      currency_conversion(
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('IDR' as abap.cuky),
      //exchange_rate_type => 'M',
        exchange_rate_date => $session.system_date
                         )     as PriceInIDR,
      cast('IDR' as abap.cuky) as IDcurrency
}
