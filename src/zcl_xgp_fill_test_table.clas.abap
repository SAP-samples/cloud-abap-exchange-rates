CLASS zcl_xgp_fill_test_table DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS-DATA: t TYPE TABLE OF zxgpcurrtest.
    INTERFACES if_oo_adt_classrun.
    CLASS-METHODS set_values.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_xgp_fill_test_table IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    set_values( ).
    out->write( data = t ).
  ENDMETHOD.
  METHOD set_values.
    t = VALUE #( ( id = 'EUR1' amount = 1 currency = 'EUR' )
                 ( id = 'EUR2' amount = 10 currency = 'EUR' )
                 ( id = 'EUR3' amount = 100 currency = 'EUR' )
                 ( id = 'EUR4' amount = 1000 currency = 'EUR' )
                 ( id = 'USD1' amount = 1 currency = 'USD' )
                 ( id = 'USD2' amount = 10 currency = 'USD' )
                 ( id = 'USD3' amount = 100 currency = 'USD' )
                 ( id = 'USD4' amount = 1000 currency = 'USD' )
               ).
    MODIFY zxgpcurrtest FROM TABLE @t.
  ENDMETHOD.
ENDCLASS.
