CLASS zcl_ecb_exchange_rates DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
"!  URL to ECB currency exchange rates; see https://exchangeratesapi.io/
"!  The JSON API to ECB information has been provided under MIT license by
"!  Madis Väin - https://github.com/madisvain
    CONSTANTS: gc_url TYPE string VALUE 'https://api.exchangeratesapi.io/latest'.
"!  retrieved information for display; may be omitted if processed in "dark mode"
    CLASS-DATA: g_exchange_rates TYPE cl_exchange_rates=>ty_exchange_rates.
    CLASS-DATA: g_result TYPE cl_exchange_rates=>ty_messages.
"!  method to retrieve the exchange rates from the ECB as json file
    CLASS-METHODS: get_rates RETURNING VALUE(exchangerates) TYPE string.
"!  method to process and store the currency exchange rates
    CLASS-METHODS: store_rates IMPORTING exchangerates TYPE string.
ENDCLASS.



CLASS zcl_ecb_exchange_rates IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    store_rates( get_rates(  ) ).
    out->write( data = g_exchange_rates ).
    out->write( data = g_result ).
  ENDMETHOD.


  METHOD get_rates.
    TRY.
*       use ECB API to get exchange rates
        DATA(lo_destination) = cl_http_destination_provider=>create_by_url( i_url = gc_url ).
        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
        DATA(lo_request) = lo_http_client->get_http_request( ).
        DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>get ).
        exchangerates = lo_response->get_text( ).
      CATCH cx_root INTO DATA(lx_exception).
*         perform convenient error handling; in a PoC this just works ;-)
        APPEND VALUE #( type = 'E' message = 'http error' ) TO g_result.
    ENDTRY.
  ENDMETHOD.


  METHOD store_rates.
*   rate type of current values; note: default customizing "should" work with EURX
    CONSTANTS: gc_rate_type TYPE cl_exchange_rates=>ty_exchange_rate-rate_type VALUE 'EURX'.
* local data declarations for preparing the rate storing via BAPI
    DATA: lr_data           TYPE REF TO data,
          base              TYPE string,
          date              TYPE string,
          exchange_rate     TYPE cl_exchange_rates=>ty_exchange_rate,
          rate(16)          TYPE p DECIMALS 10,
          rate_to_store(16) TYPE p DECIMALS 5,
          factor            TYPE i_exchangeratefactorsrawdata,
          l_result          TYPE cl_exchange_rates=>ty_messages.
    FIELD-SYMBOLS: <data> TYPE data,
                   <v>    TYPE data,
                   <r>    TYPE data,
                   <b>    TYPE string,
                   <d>    TYPE string,
                   <f>    TYPE f.
*   process the exchange rates retrieved from the European Central Bank's json file
    lr_data = /ui2/cl_json=>generate( EXPORTING json = exchangerates ).
    ASSIGN lr_data->* TO <data>.
    ASSIGN COMPONENT 'BASE' OF STRUCTURE <data> TO <v>.
    ASSIGN <v>->* TO <b>. " the base currency
    base = <b>.
    ASSIGN COMPONENT 'DATE' OF STRUCTURE <data> TO <v>.
    ASSIGN <v>->* TO <d>. " the validity date
    date = <d>.
    REPLACE ALL OCCURRENCES OF '-' IN date WITH ''.
    ASSIGN COMPONENT 'RATES' OF STRUCTURE <data> TO <v>.
    ASSIGN <v>->* TO <r>. " the rates
    DATA(struct_descr) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( <r> ) ).
*   process the actual rates data
    LOOP AT struct_descr->components ASSIGNING FIELD-SYMBOL(<comp_descr>).
*     assign the retrieved values
      ASSIGN COMPONENT <comp_descr>-name OF STRUCTURE <r> TO <v>.
      ASSIGN <v>->* TO <f>.
      rate = <f>.
* get rate factors and calculate exchange rate to store
      SELECT SINGLE
       exchangeratetype,
       sourcecurrency,
       targetcurrency,
       validitystartdate,
       numberofsourcecurrencyunits,
       numberoftargetcurrencyunits,
       alternativeexchangeratetype,
       altvexchangeratetypevaldtydate
        FROM i_exchangeratefactorsrawdata
       WHERE exchangeratetype = @gc_rate_type
         AND sourcecurrency = @base
         AND targetcurrency = @<comp_descr>-name
         AND validitystartdate <= @date
      INTO @factor.
      IF sy-subrc <> 0.
*       no rate is an error, skip.
        APPEND VALUE #( type = 'E' message = 'No factor found for' message_v1 = gc_rate_type message_v2 = base message_v3 = <comp_descr>-name ) TO g_result.
        CONTINUE.
      ENDIF.
      CLEAR exchange_rate.
      exchange_rate-rate_type = factor-exchangeratetype.
      exchange_rate-from_curr = factor-sourcecurrency.
      exchange_rate-to_currncy = factor-targetcurrency.
      exchange_rate-valid_from = date.
      rate_to_store = rate * factor-numberofsourcecurrencyunits / factor-numberoftargetcurrencyunits.
      exchange_rate-from_factor = factor-numberofsourcecurrencyunits.
      exchange_rate-to_factor = factor-numberoftargetcurrencyunits.
      exchange_rate-exch_rate = rate_to_store.
      APPEND exchange_rate TO g_exchange_rates.
*     provide the inversion also to allow conversion back
      SELECT SINGLE
       exchangeratetype,
       sourcecurrency,
       targetcurrency,
       validitystartdate,
       numberofsourcecurrencyunits,
       numberoftargetcurrencyunits,
       alternativeexchangeratetype,
       altvexchangeratetypevaldtydate
        FROM i_exchangeratefactorsrawdata
       WHERE exchangeratetype = @gc_rate_type
         AND sourcecurrency = @<comp_descr>-name
         AND targetcurrency = @base
         AND validitystartdate <= @date
      INTO @factor.
      IF sy-subrc <> 0.
*       no rate is an error, skip.
        APPEND VALUE #( type = 'E' message = 'No factor found for' message_v1 = gc_rate_type message_v2 = base message_v3 = <comp_descr>-name ) TO g_result.
        CONTINUE.
      ENDIF.
      CLEAR exchange_rate.
      exchange_rate-rate_type = factor-exchangeratetype.
      exchange_rate-from_curr = factor-sourcecurrency.
      exchange_rate-to_currncy = factor-targetcurrency.
      exchange_rate-valid_from = date.
*     use volume notation to rely on retrieved exchange rates
      exchange_rate-from_factor_v = factor-numberofsourcecurrencyunits.
      exchange_rate-to_factor_v = factor-numberoftargetcurrencyunits.
      rate_to_store = exchange_rate-to_factor_v * rate / exchange_rate-from_factor_v.
      exchange_rate-exch_rate_v = rate_to_store.
      APPEND exchange_rate TO g_exchange_rates.
    ENDLOOP.
*   now write the currency exchange rates
    l_result = cl_exchange_rates=>put( EXPORTING exchange_rates = g_exchange_rates ).
*   local result is used in case errors from factor retrieval should also be stored.
    APPEND LINES OF l_result TO g_result.
  ENDMETHOD.
ENDCLASS.
