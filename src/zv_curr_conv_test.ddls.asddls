@AbapCatalog.sqlViewName: 'ZVCURRTEST'
@EndUserText.label: 'Test of currency conversion'
@ClientHandling.algorithm: #SESSION_VARIABLE
define view zv_curr_conv_test
  as select from ztcurrconvtest
{
  key id,
      @Semantics.amount.currencyCode: 'CURRENCY'
      amount,
      currency,
      @EndUserText.label: 'Price (in US American Dollars)'
      @Semantics.amount.currencyCode: 'USCURRENCY'
      currency_conversion(
        client => client,
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('USD' as abap.cuky),
        exchange_rate_type => 'EURX',
        exchange_rate_date => cast($session.system_date as abap.dats)
                         )         as PriceInUSD,
      cast('USD' as abap.cuky)     as USCurrency,
      @EndUserText.label: 'Price (in Australian Dollars)'
      @Semantics.amount.currencyCode: 'AUCURRENCY'
      currency_conversion(
        client => client,
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('AUD' as abap.cuky),
        exchange_rate_type => 'EURX',
        exchange_rate_date => cast($session.system_date as abap.dats)
                         )         as PriceInAUD,
      cast('AUD' as abap.cuky)     as AUCurrency,
      @EndUserText.label: 'Price (in Indonesian Rupiahs)'
      @Semantics.amount.currencyCode: 'IDCURRENCY'
      currency_conversion(
        client => client,
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('IDR' as abap.cuky),
        exchange_rate_type => 'EURX',
        exchange_rate_date => cast($session.system_date as abap.dats),
        decimal_shift => '',
        decimal_shift_back => '' ) as PriceInIDR,
      cast('IDR' as abap.cuky)     as IDcurrency
}
