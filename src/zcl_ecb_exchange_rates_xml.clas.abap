CLASS zcl_ecb_exchange_rates_xml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
"!  URL to ECB currency exchange rates in XML format
"!  Exchange rate information is provided by the European Central Bank through their API portal
"!  Please refer to https://www.ecb.europa.eu/home/disclaimer/html/index.en.html for dsiclaimer
"!  and copyright
"!  Copyright for the entire content of this website: European Central Bank, Frankfurt am Main, Germany.
    CONSTANTS: gc_url TYPE string VALUE 'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml'.
"!   rate type of current values; note: default customizing "should" work with EURX; see method store_rates
"!    CONSTANTS: gc_rate_type TYPE cl_exchange_rates=>ty_exchange_rate-rate_type VALUE 'EURX',
"!               gc_base      TYPE cl_exchange_rates=>ty_exchange_rate-from_curr VALUE 'EUR'.
"!   type and data for XML processing
    TYPES: BEGIN OF ty_entry,
             level  TYPE i,
             parent TYPE string,
             name   TYPE string,
             attr   TYPE string,
             value  TYPE string,
           END OF ty_entry.
    CLASS-DATA: t_entry TYPE TABLE OF ty_entry.
"!   retrieved information for display; may be omitted if processed in "dark mode"
    CLASS-DATA: g_result TYPE cl_exchange_rates=>ty_messages,
                g_rates  TYPE cl_exchange_rates=>ty_exchange_rates.
"!   method to retrieve the exchange rates from the ECB as json file
    CLASS-METHODS: get_rates RETURNING VALUE(exchangerates) TYPE xstring.
"!   method to process the currency exchange rates
    CLASS-METHODS: parse_rates IMPORTING exchangerates TYPE xstring.
"!   method to store the rates in the system
    CLASS-METHODS: store_rates.
ENDCLASS.



CLASS zcl_ecb_exchange_rates_xml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    parse_rates( get_rates(  ) ).
    store_rates(  ).
    out->write( data = g_rates ).
    out->write( data = g_result ).
  ENDMETHOD.


  METHOD get_rates.
    TRY.
*       use ECB API to get exchange rates
        DATA(lo_destination) = cl_http_destination_provider=>create_by_url( i_url = gc_url ).
        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
        DATA(lo_request) = lo_http_client->get_http_request( ).
        DATA(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>get ).
        exchangerates = lo_response->get_binary( ).
      CATCH cx_root INTO DATA(lx_exception).
*         perform convenient error handling; in a PoC this just works ;-)
        APPEND VALUE #( type = 'E' message = 'http error' ) TO g_result.
    ENDTRY.
  ENDMETHOD.


  METHOD parse_rates.
    DATA: w_entry  TYPE ty_entry,
          w_parent TYPE ty_entry,
          t_stack  TYPE TABLE OF ty_entry.
    DATA(reader) = cl_sxml_string_reader=>create( exchangerates ).
    DO.
      DATA(node) = reader->read_next_node( ).
      IF node IS INITIAL.
        EXIT.
      ENDIF.
      CASE node->type.
        WHEN if_sxml_node=>co_nt_element_open.
          DATA(open_element) = CAST if_sxml_open_element( node ).
          DATA(attributes)  = open_element->get_attributes( ).
          READ TABLE t_stack WITH KEY level = w_entry-level INTO w_parent.
          IF sy-subrc = 0.
            w_entry-parent = w_parent-parent.
          ENDIF.
          w_entry-level = w_entry-level + 1.
          w_entry-name = open_element->qname-name.
          w_parent-level  = w_entry-level.
          w_parent-parent = w_entry-name.
          READ TABLE t_stack WITH KEY level = w_parent-level TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            DELETE t_stack WHERE level = w_parent-level.
          ENDIF.
          INSERT w_parent INTO TABLE t_stack.
          LOOP AT attributes INTO DATA(attribute).
            w_entry-attr  = attribute->qname-name.
            w_entry-value = attribute->get_value( ).
            APPEND w_entry TO t_entry.
          ENDLOOP.
          CONTINUE.
        WHEN if_sxml_node=>co_nt_value.
          DATA(value_node) = CAST if_sxml_value_node( node ).
          w_entry-name = open_element->qname-name.
          w_entry-value = value_node->get_value( ).
          APPEND w_entry TO t_entry.
          CONTINUE.
        WHEN if_sxml_node=>co_nt_element_close.
          w_entry-level = w_entry-level - 1.
          CONTINUE.
        WHEN OTHERS.
      ENDCASE.
    ENDDO.
  ENDMETHOD.

  METHOD store_rates.
    CONSTANTS: gc_rate_type TYPE cl_exchange_rates=>ty_exchange_rate-rate_type VALUE 'EURX',
               gc_base      TYPE cl_exchange_rates=>ty_exchange_rate-from_curr VALUE 'EUR'.

    DATA: w_entry           TYPE ty_entry,
          w_rate            TYPE cl_exchange_rates=>ty_exchange_rate,
          factor            TYPE i_exchangeratefactorsrawdata,
          rate_to_store(16) TYPE p DECIMALS 5,
          l_result          TYPE cl_exchange_rates=>ty_messages.

    LOOP AT t_entry INTO w_entry.
*     process the actual rates
      w_rate-rate_type = 'EURX'.
      w_rate-from_curr = 'EUR'.
      CASE w_entry-attr.
        WHEN 'time'.
          REPLACE ALL OCCURRENCES OF '-' IN w_entry-value WITH ''.
          w_rate-valid_from = w_entry-value.
        WHEN 'currency'.
          w_rate-to_currncy = w_entry-value.
        WHEN 'rate'.
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
             AND sourcecurrency = @gc_base
             AND targetcurrency = @w_rate-to_currncy
             AND validitystartdate <= @w_rate-valid_from
          INTO @factor.
          IF sy-subrc <> 0.
*       no rate is an error, skip.
            APPEND VALUE #( type = 'E' message = 'No factor found for' message_v1 = gc_rate_type message_v2 = gc_base message_v3 = w_rate-to_currncy ) TO g_result.
            CONTINUE.
          ENDIF.
          w_rate-from_factor = factor-numberofsourcecurrencyunits.
          w_rate-to_factor = factor-numberoftargetcurrencyunits.
          w_rate-from_factor_v = 0.
          w_rate-to_factor_v = 0.
          rate_to_store = w_entry-value * factor-numberofsourcecurrencyunits / factor-numberoftargetcurrencyunits.
          w_rate-exch_rate = rate_to_store.
          w_rate-exch_rate_v = 0.
          APPEND w_rate TO g_rates.
*         and the inverted value
          w_rate-from_curr = w_rate-to_currncy.
          w_rate-to_currncy = gc_base.
          w_rate-from_factor = 0.
          w_rate-to_factor = 0.
          w_rate-from_factor_v = factor-numberoftargetcurrencyunits.
          w_rate-to_factor_v = factor-numberofsourcecurrencyunits.
          rate_to_store = w_rate-to_factor_v * w_entry-value / w_rate-from_factor_v.
          w_rate-exch_rate   = 0.
          w_rate-exch_rate_v = rate_to_store.
          APPEND w_rate TO g_rates.
      ENDCASE.
    ENDLOOP.
*   now write the currency exchange rates
    l_result = cl_exchange_rates=>put( EXPORTING exchange_rates = g_rates ).
*   local result is used in case errors from factor retrieval should also be stored.
    APPEND LINES OF l_result TO g_result.
  ENDMETHOD.
ENDCLASS.
