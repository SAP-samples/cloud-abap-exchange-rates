@AbapCatalog.sqlViewName: 'ZXGPVCURRTEST'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Test of currency conversion'
@ClientHandling.algorithm : #SESSION_VARIABLE
define view zxgp_currency_test
  as select from zxgpcurrtest
{
      //zxgpcurrtest
  key id,
      @Semantics.amount.currencyCode: 'CURRENCY'
      amount,
      @Semantics.currencyCode: true
      currency,
      @EndUserText.label: 'Price (in US American Dollars)'
      currency_conversion(
        client => client,
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('USD' as abap.cuky),
        exchange_rate_type => cast('M' as abap.char(4)),
        exchange_rate_date => cast($session.system_date as abap.dats)
                         ) as PriceInUSD,
      @EndUserText.label: 'Price (in Australian Dollars)'
      currency_conversion(
        client => client,
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('AUD' as abap.cuky),
        exchange_rate_type => cast('M' as abap.char(4)),
        exchange_rate_date => cast($session.system_date as abap.dats)
                         ) as PriceInAUD,
      @EndUserText.label: 'Price (in Indonesian Rupiahs)'
      currency_conversion(
        client => client,
        amount => amount,
        round => '',
        source_currency => currency,
        target_currency => cast('IDR' as abap.cuky),
        exchange_rate_type => cast('M' as abap.char(4)),
        exchange_rate_date => cast($session.system_date as abap.dats)
                         ) as PriceInIDR
}
