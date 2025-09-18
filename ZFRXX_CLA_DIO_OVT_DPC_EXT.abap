class ZFRXX_CLA_DIO_OVT_DPC_EXT definition
  public
  inheriting from ZFRXX_CLA_DIO_OVT_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CHANGESET_BEGIN
    redefinition .
  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~CHANGESET_PROCESS
    redefinition .
protected section.

  methods EMPLOYEESSET_GET_ENTITY
    redefinition .
  methods EMPLOYEESSET_GET_ENTITYSET
    redefinition .
  methods EMPLOYEESSET_UPDATE_ENTITY
    redefinition .
  methods OVERTIMEEVENTSET_GET_ENTITY
    redefinition .
  methods OVERTIMEEVENTSET_GET_ENTITYSET
    redefinition .
  methods OVERTIMEEVENTSET_UPDATE_ENTITY
    redefinition .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZFRXX_CLA_DIO_OVT_DPC_EXT IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZFRXX_CLA_DIO_OVT_DPC_EXT->/IWBEP/IF_MGW_APPL_SRV_RUNTIME~CHANGESET_BEGIN
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_OPERATION_INFO              TYPE        /IWBEP/T_MGW_OPERATION_INFO
* | [<-->] CV_DEFER_MODE                  TYPE        XSDBOOLEAN(optional)
* | [!CX!] /IWBEP/CX_MGW_BUSI_EXCEPTION
* | [!CX!] /IWBEP/CX_MGW_TECH_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_mgw_appl_srv_runtime~changeset_begin.
    TRY.
        CALL METHOD super->/iwbep/if_mgw_appl_srv_runtime~changeset_begin
          EXPORTING
            it_operation_info = it_operation_info
          CHANGING
            cv_defer_mode     = cv_defer_mode.
      CATCH /iwbep/cx_mgw_busi_exception.
      CATCH /iwbep/cx_mgw_tech_exception.
        IF lines( it_operation_info ) > 1.
          LOOP AT it_operation_info ASSIGNING FIELD-SYMBOL(<operation>).
            IF <operation>-entity_set NS 'OvertimeEventSet'.
              RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
                EXPORTING
                  textid = /iwbep/cx_mgw_tech_exception=>changeset_default_violation
                  method = 'CHANGESET_BEGIN'.
            ENDIF.

            cv_defer_mode = 'X'.
          ENDLOOP.
        ENDIF.

    ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZFRXX_CLA_DIO_OVT_DPC_EXT->/IWBEP/IF_MGW_APPL_SRV_RUNTIME~CHANGESET_PROCESS
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_CHANGESET_REQUEST           TYPE        /IWBEP/IF_MGW_APPL_TYPES=>TY_T_CHANGESET_REQUEST
* | [<-->] CT_CHANGESET_RESPONSE          TYPE        /IWBEP/IF_MGW_APPL_TYPES=>TY_T_CHANGESET_RESPONSE
* | [!CX!] /IWBEP/CX_MGW_BUSI_EXCEPTION
* | [!CX!] /IWBEP/CX_MGW_TECH_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD /iwbep/if_mgw_appl_srv_runtime~changeset_process.
    DATA:
      lv_operation_counter  TYPE i VALUE 0,
      lr_context            TYPE REF TO /iwbep/cl_mgw_request,
      lr_entry_provider     TYPE REF TO /iwbep/if_mgw_entry_provider,
      lr_message_container  TYPE REF TO /iwbep/if_message_container,
      lr_entity_data        TYPE REF TO data,
      ls_context_details    TYPE /iwbep/if_mgw_core_srv_runtime=>ty_s_mgw_request_context,
      ls_changeset_response LIKE LINE OF ct_changeset_response.
    DATA: operation_counter TYPE i,
          ls_header         TYPE tihttpnvp.

    TYPES:
      BEGIN OF ty_s_changeset_response,
        operation_no TYPE i,
        entity_data  TYPE REF TO data,
        headers      TYPE tihttpnvp,
      END OF ty_s_changeset_response .

    FIELD-SYMBOLS:
        <fs_ls_changeset_request>  LIKE LINE OF it_changeset_request.

    operation_counter = lines( it_changeset_request ).

    LOOP AT it_changeset_request ASSIGNING <fs_ls_changeset_request>.
      lr_context          ?= <fs_ls_changeset_request>-request_context.
      lr_entry_provider    = <fs_ls_changeset_request>-entry_provider.
      lr_message_container = <fs_ls_changeset_request>-msg_container.
      ls_context_details   = lr_context->get_request_details( ).
      CASE ls_context_details-target_entity.
        WHEN 'OvertimeEvent'.
          DATA lt_navigation_path TYPE /iwbep/t_mgw_navigation_path.
          DATA er_entity TYPE zfrxx_cla_dio_ovt_mpc=>ts_overtimeevent.
          TRY.
              CALL METHOD me->overtimeeventset_update_entity
                EXPORTING
                  iv_entity_name          = 'OvertimeEvent'
                  iv_entity_set_name      = 'OvertimeEventSet'
                  iv_source_name          = 'OvertimeEvent'
                  io_data_provider        = lr_entry_provider
                  it_key_tab              = ls_context_details-key_tab
                  io_tech_request_context = lr_context
                  it_navigation_path      = lt_navigation_path
                IMPORTING
                  er_entity               = er_entity.

          ENDTRY.

          DATA ref_data TYPE REF TO data.
          copy_data_to_ref(
                           EXPORTING
                            is_data = er_entity
                          CHANGING
                             cr_data = ref_data ).



          APPEND INITIAL LINE TO ls_header ASSIGNING FIELD-SYMBOL(<header>).
          <header>-name = |Operation #{ operation_counter }|.
          <header>-value = |Performed with success|.

          INSERT VALUE ty_s_changeset_response( operation_no = operation_counter
                                                entity_data = ref_data
                                                headers = ls_header ) INTO TABLE ct_changeset_response.
          SUBTRACT 1 FROM operation_counter.
        WHEN OTHERS.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZFRXX_CLA_DIO_OVT_DPC_EXT->EMPLOYEESSET_GET_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ENTITY_NAME                 TYPE        STRING
* | [--->] IV_ENTITY_SET_NAME             TYPE        STRING
* | [--->] IV_SOURCE_NAME                 TYPE        STRING
* | [--->] IT_KEY_TAB                     TYPE        /IWBEP/T_MGW_NAME_VALUE_PAIR
* | [--->] IO_REQUEST_OBJECT              TYPE REF TO /IWBEP/IF_MGW_REQ_ENTITY(optional)
* | [--->] IO_TECH_REQUEST_CONTEXT        TYPE REF TO /IWBEP/IF_MGW_REQ_ENTITY(optional)
* | [--->] IT_NAVIGATION_PATH             TYPE        /IWBEP/T_MGW_NAVIGATION_PATH
* | [<---] ER_ENTITY                      TYPE        ZFRXX_CLA_DIO_OVT_MPC=>TS_EMPLOYEES
* | [<---] ES_RESPONSE_CONTEXT            TYPE        /IWBEP/IF_MGW_APPL_SRV_RUNTIME=>TY_S_MGW_RESPONSE_ENTITY_CNTXT
* | [!CX!] /IWBEP/CX_MGW_BUSI_EXCEPTION
* | [!CX!] /IWBEP/CX_MGW_TECH_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD employeesset_get_entity.
    DATA:  ls_entity  LIKE er_entity.

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_entity ).

    " Retrieve complete name
    DATA(ee_pernr) = CONV pernr_d( ls_entity-id ).

    SELECT pernr, nachn, vorna, cname FROM pa0002           "#EC WARNOK
      WHERE pernr EQ @ee_pernr AND
            endda EQ `99991231`
            INTO TABLE @DATA(it0002_tab).

    IF sy-subrc IS INITIAL.

      READ TABLE it0002_tab ASSIGNING FIELD-SYMBOL(<it0002>) INDEX 1. "#EC CI_NOORDER

      er_entity-id = ls_entity-id.
      er_entity-fullname = COND #( WHEN <it0002>-cname IS NOT INITIAL THEN <it0002>-cname
                                   ELSE |{ <it0002>-vorna }, { <it0002>-nachn }| ).

    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZFRXX_CLA_DIO_OVT_DPC_EXT->EMPLOYEESSET_GET_ENTITYSET
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ENTITY_NAME                 TYPE        STRING
* | [--->] IV_ENTITY_SET_NAME             TYPE        STRING
* | [--->] IV_SOURCE_NAME                 TYPE        STRING
* | [--->] IT_FILTER_SELECT_OPTIONS       TYPE        /IWBEP/T_MGW_SELECT_OPTION
* | [--->] IS_PAGING                      TYPE        /IWBEP/S_MGW_PAGING
* | [--->] IT_KEY_TAB                     TYPE        /IWBEP/T_MGW_NAME_VALUE_PAIR
* | [--->] IT_NAVIGATION_PATH             TYPE        /IWBEP/T_MGW_NAVIGATION_PATH
* | [--->] IT_ORDER                       TYPE        /IWBEP/T_MGW_SORTING_ORDER
* | [--->] IV_FILTER_STRING               TYPE        STRING
* | [--->] IV_SEARCH_STRING               TYPE        STRING
* | [--->] IO_TECH_REQUEST_CONTEXT        TYPE REF TO /IWBEP/IF_MGW_REQ_ENTITYSET(optional)
* | [<---] ET_ENTITYSET                   TYPE        ZFRXX_CLA_DIO_OVT_MPC=>TT_EMPLOYEES
* | [<---] ES_RESPONSE_CONTEXT            TYPE        /IWBEP/IF_MGW_APPL_SRV_RUNTIME=>TY_S_MGW_RESPONSE_CONTEXT
* | [!CX!] /IWBEP/CX_MGW_BUSI_EXCEPTION
* | [!CX!] /IWBEP/CX_MGW_TECH_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD employeesset_get_entityset.
    " Retrieve current manager subordinates

    "Local data declaration
    TYPES: BEGIN OF ty_output,
             pernr TYPE pernr_d,
             cname TYPE pa0002-cname,
           END OF ty_output.
    DATA: lt_orgunits_mnr TYPE objec_t,
          system_uname    TYPE sy-uname,
          mnr_pernr       TYPE pernr_d,
          lt_result_tab   TYPE tswhactor,
          lt_result_objec TYPE objec_t,
          lt_result_struc TYPE struc_t,
          output_tab      TYPE TABLE OF ty_output,
          lt_orgunits_hr  TYPE objec_t.

    system_uname = sy-uname.

    CALL FUNCTION 'BAPI_USR01DOHR_GETEMPLOYEE'
      EXPORTING
        id             = system_uname
      IMPORTING
        employeenumber = mnr_pernr.

    DATA(converted_pernr) = CONV mstbr( mnr_pernr ).

    SELECT a~pernr FROM pa0001 AS a
      INNER JOIN pa0000 AS b ON
        a~pernr EQ b~pernr AND
        b~begda LE a~endda AND
        b~endda GE a~begda
      WHERE a~mstbr EQ @converted_pernr AND
            a~begda LE @sy-datum AND
            a~endda GE @sy-datum AND
            b~stat2 EQ `3`
      ORDER BY a~pernr
      INTO TABLE @DATA(subordinates_table).

    IF sy-subrc IS INITIAL.
      DELETE ADJACENT DUPLICATES FROM subordinates_table COMPARING pernr.


      LOOP AT subordinates_table ASSIGNING FIELD-SYMBOL(<sub>).

        APPEND INITIAL LINE TO output_tab ASSIGNING FIELD-SYMBOL(<output>).
        <output>-pernr = <sub>-pernr.

      ENDLOOP.
    ELSE.
      DATA(lo_message_container) = me->mo_context->get_message_container( ).
      lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                         iv_msg_number = '013'
                                         iv_msg_id = 'ZFRPY_MES_DIO_ERR'
                                         iv_add_to_response_header = abap_true ).

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          message_container = lo_message_container.
    ENDIF.


    TRY.

        " Retrieve complete name
        SELECT pernr, nachn, vorna, cname FROM pa0002
          FOR ALL ENTRIES IN @output_tab
          WHERE pernr EQ @output_tab-pernr AND
                endda EQ `99991231`
          INTO TABLE @DATA(it0002_tab).

        IF sy-subrc IS INITIAL.
          LOOP AT it0002_tab ASSIGNING FIELD-SYMBOL(<it0002>).
            ASSIGN output_tab[ pernr = <it0002>-pernr ] TO <output>.

            IF <output> IS ASSIGNED.
              <output>-cname = COND #( WHEN <it0002>-cname IS NOT INITIAL THEN <it0002>-cname
                                       ELSE |{ <it0002>-vorna }, { <it0002>-nachn }| ).
            ENDIF.
          ENDLOOP.
        ENDIF.

*        ENDIF.
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    " Retrieve output tab
    LOOP AT output_tab ASSIGNING <output>.
      APPEND INITIAL LINE TO et_entityset ASSIGNING FIELD-SYMBOL(<entityset>).
      <entityset>-id = CONV #( <output>-pernr ).
      <entityset>-fullname = <output>-cname.
    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZFRXX_CLA_DIO_OVT_DPC_EXT->EMPLOYEESSET_UPDATE_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ENTITY_NAME                 TYPE        STRING
* | [--->] IV_ENTITY_SET_NAME             TYPE        STRING
* | [--->] IV_SOURCE_NAME                 TYPE        STRING
* | [--->] IT_KEY_TAB                     TYPE        /IWBEP/T_MGW_NAME_VALUE_PAIR
* | [--->] IO_TECH_REQUEST_CONTEXT        TYPE REF TO /IWBEP/IF_MGW_REQ_ENTITY_U(optional)
* | [--->] IT_NAVIGATION_PATH             TYPE        /IWBEP/T_MGW_NAVIGATION_PATH
* | [--->] IO_DATA_PROVIDER               TYPE REF TO /IWBEP/IF_MGW_ENTRY_PROVIDER(optional)
* | [<---] ER_ENTITY                      TYPE        ZFRXX_CLA_DIO_OVT_MPC=>TS_EMPLOYEES
* | [!CX!] /IWBEP/CX_MGW_BUSI_EXCEPTION
* | [!CX!] /IWBEP/CX_MGW_TECH_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD employeesset_update_entity.
    DATA: ot_event    LIKE er_entity,
          it_2012     TYPE pa2012,
          lv_return   TYPE bapireturn1,
          entity_keys LIKE er_entity.

    io_data_provider->read_entry_data( IMPORTING es_data = ot_event ).
    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = entity_keys ).
    DATA(lo_message_container) = me->mo_context->get_message_container( ).

    DATA(vpernr) = CONV pernr_d( ot_event-id ).

    " Take all the currently active elements for this employee
    SELECT *
        FROM pa2002
        WHERE ( subty EQ '9011' OR subty EQ '9013' ) AND sprps EQ 'X' AND pernr EQ @vpernr
        INTO TABLE @DATA(time_events).

    IF sy-subrc IS INITIAL. " Now reject all or approve all
      IF ot_event-fullname EQ 'AP'.

        LOOP AT time_events ASSIGNING FIELD-SYMBOL(<entry_2b_approved>).
          DATA(personum) = CONV pernr_d( vpernr ).

          DATA ls_p2002 TYPE p2002.
          MOVE-CORRESPONDING <entry_2b_approved> TO ls_p2002.


          CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
            EXPORTING
              number = personum.

          CALL FUNCTION 'HR_INFOTYPE_OPERATION'
            EXPORTING
              infty         = '2002'
              number        = personum
              subtype       = <entry_2b_approved>-subty
              objectid      = <entry_2b_approved>-objps
              lockindicator = <entry_2b_approved>-sprps
              validityend   = <entry_2b_approved>-endda
              validitybegin = <entry_2b_approved>-begda
              recordnumber  = <entry_2b_approved>-seqnr
              record        = ls_p2002
              operation     = 'DEL'
              tclas         = 'A'
              dialog_mode   = '0'
            IMPORTING
              return        = lv_return.

          CALL FUNCTION 'BAPI_EMPLOYEE_DEQUEUE'
            EXPORTING
              number = personum.

          "DELETE pa2002 FROM <entry_2b_approved>.

          <entry_2b_approved>-sprps = ''.
          IF lv_return-type NE 'E'.

            INSERT pa2002 FROM <entry_2b_approved>.

            COMMIT WORK.

            MOVE-CORRESPONDING ot_event TO er_entity.
          ELSE.
            lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                               iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                               iv_msg_number = `010`
                                               iv_add_to_response_header = abap_true
                                               iv_msg_v1 = CONV symsgv( <entry_2b_approved>-subty ) ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                message_container = lo_message_container.
          ENDIF.

        ENDLOOP.
      ELSEIF ot_event-fullname EQ 'RE'.

        LOOP AT time_events ASSIGNING FIELD-SYMBOL(<entry_2b_rejected>).

          personum = CONV pernr_d( <entry_2b_rejected>-pernr ).
          MOVE-CORRESPONDING <entry_2b_rejected> TO ls_p2002.


          CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
            EXPORTING
              number = personum.

          CALL FUNCTION 'HR_INFOTYPE_OPERATION'
            EXPORTING
              infty         = '2002'
              number        = personum
              subtype       = <entry_2b_rejected>-subty
              objectid      = <entry_2b_rejected>-objps
              lockindicator = <entry_2b_rejected>-sprps
              validityend   = <entry_2b_rejected>-endda
              validitybegin = <entry_2b_rejected>-begda
              recordnumber  = <entry_2b_rejected>-seqnr
              record        = ls_p2002
              operation     = 'DEL'
              tclas         = 'A'
              dialog_mode   = '0'
            IMPORTING
              return        = lv_return.

          CALL FUNCTION 'BAPI_EMPLOYEE_DEQUEUE'
            EXPORTING
              number = personum.

          "DELETE pa2002 FROM <entry_2b_rejected>.
          IF lv_return-type NE 'E'.

            " Set up the 2012 to be inserted
            it_2012-pernr = <entry_2b_rejected>-pernr.
            it_2012-subty = COND #( WHEN <entry_2b_rejected>-subty EQ '9011' THEN '$911'
                                   WHEN <entry_2b_rejected>-subty EQ '9013' THEN '$913' ).
            it_2012-endda = <entry_2b_rejected>-endda.
            it_2012-begda = <entry_2b_rejected>-begda.
            it_2012-seqnr = '000'.
            it_2012-aedtm = CONV #( sy-datum ).
            it_2012-uname = sy-uname.
            it_2012-beguz = <entry_2b_rejected>-beguz.
            it_2012-enduz = <entry_2b_rejected>-enduz.
            it_2012-ztart = it_2012-subty.
            it_2012-anzhl = CONV #( <entry_2b_rejected>-stdaz ).

            " Check SEQNR is unique
            SELECT * FROM pa2012                            "#EC WARNOK
              WHERE pernr EQ @it_2012-pernr AND
                    begda EQ @it_2012-begda AND
                    endda EQ @it_2012-endda
              ORDER BY seqnr DESCENDING
              INTO TABLE @DATA(dummy_selection).

            IF sy-subrc IS NOT INITIAL.
              TRY.
                  it_2012-seqnr = CONV #( dummy_selection[ 1 ]-seqnr + 1 ).
                CATCH cx_sy_itab_line_not_found.
              ENDTRY.
            ENDIF.

            INSERT pa2012 FROM it_2012.

            IF sy-subrc IS INITIAL.
              COMMIT WORK.
              MOVE-CORRESPONDING ot_event TO er_entity.
            ELSE.
              ROLLBACK WORK.
              lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                                 iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                                 iv_msg_number = `012`
                                                 iv_add_to_response_header = abap_true
                                                 iv_msg_v1 = CONV symsgv( <entry_2b_rejected>-subty ) ).

              RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
                EXPORTING
                  message_container = lo_message_container.

            ENDIF.
          ENDIF.
        ENDLOOP.
      ELSE. " Deletion failed
        ROLLBACK WORK.
        lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                           iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                           iv_msg_number = `012`
                                           iv_add_to_response_header = abap_true ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_message_container.
      ENDIF. " Delete 2002
    ENDIF.


  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZFRXX_CLA_DIO_OVT_DPC_EXT->OVERTIMEEVENTSET_GET_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ENTITY_NAME                 TYPE        STRING
* | [--->] IV_ENTITY_SET_NAME             TYPE        STRING
* | [--->] IV_SOURCE_NAME                 TYPE        STRING
* | [--->] IT_KEY_TAB                     TYPE        /IWBEP/T_MGW_NAME_VALUE_PAIR
* | [--->] IO_REQUEST_OBJECT              TYPE REF TO /IWBEP/IF_MGW_REQ_ENTITY(optional)
* | [--->] IO_TECH_REQUEST_CONTEXT        TYPE REF TO /IWBEP/IF_MGW_REQ_ENTITY(optional)
* | [--->] IT_NAVIGATION_PATH             TYPE        /IWBEP/T_MGW_NAVIGATION_PATH
* | [<---] ER_ENTITY                      TYPE        ZFRXX_CLA_DIO_OVT_MPC=>TS_OVERTIMEEVENT
* | [<---] ES_RESPONSE_CONTEXT            TYPE        /IWBEP/IF_MGW_APPL_SRV_RUNTIME=>TY_S_MGW_RESPONSE_ENTITY_CNTXT
* | [!CX!] /IWBEP/CX_MGW_BUSI_EXCEPTION
* | [!CX!] /IWBEP/CX_MGW_TECH_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD overtimeeventset_get_entity.
    DATA:  ls_entity  LIKE er_entity.

    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = ls_entity ).

    " Retrieve complete name
    DATA(vpernr) = CONV pernr_d( ls_entity-employeeid ).
    DATA(vsubty) = CONV subty( ls_entity-wagetype ).
    DATA(vbegda) = CONV begda( ls_entity-startday ).
    DATA(vendda) = CONV endda( ls_entity-endday ).

    SELECT SINGLE * FROM pa2002                             "#EC WARNOK
    WHERE pernr EQ @vpernr AND subty EQ @vsubty AND endda EQ @vendda AND begda EQ @vbegda
    INTO @DATA(it2002_str).

    IF sy-subrc IS INITIAL.
      er_entity-employeeid = it2002_str-pernr.
      er_entity-startday = it2002_str-begda.
      er_entity-endday = it2002_str-endda.
      er_entity-seqnum = it2002_str-seqnr.
      er_entity-starttime = CONV string( it2002_str-beguz ).
      er_entity-endtime = CONV string( it2002_str-enduz ).
      er_entity-wagetype = it2002_str-subty.
      er_entity-wagetypetext = COND #( WHEN it2002_str-subty CS '9011' THEN 'Paiement Heures'
                                       ELSE 'Récupération Heures' ).
      er_entity-approval = COND i( WHEN it2002_str-sprps EQ 'X' THEN 0
                                   ELSE 1 ). " 0 to be processed / 1 approved / 2 rejected (won't appear here).
      er_entity-numberofhours = it2002_str-stdaz.

      SELECT SINGLE vorna, nachn                            "#EC WARNOK
        FROM pa0002
        WHERE pernr EQ @vpernr AND endda GE @vbegda AND begda LE @vendda
        INTO @DATA(it0002_str).

      IF sy-subrc IS INITIAL.
        er_entity-fullname = |{ it0002_str-vorna }, { it0002_str-nachn }|.
      ENDIF.

    ENDIF.


  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZFRXX_CLA_DIO_OVT_DPC_EXT->OVERTIMEEVENTSET_GET_ENTITYSET
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ENTITY_NAME                 TYPE        STRING
* | [--->] IV_ENTITY_SET_NAME             TYPE        STRING
* | [--->] IV_SOURCE_NAME                 TYPE        STRING
* | [--->] IT_FILTER_SELECT_OPTIONS       TYPE        /IWBEP/T_MGW_SELECT_OPTION
* | [--->] IS_PAGING                      TYPE        /IWBEP/S_MGW_PAGING
* | [--->] IT_KEY_TAB                     TYPE        /IWBEP/T_MGW_NAME_VALUE_PAIR
* | [--->] IT_NAVIGATION_PATH             TYPE        /IWBEP/T_MGW_NAVIGATION_PATH
* | [--->] IT_ORDER                       TYPE        /IWBEP/T_MGW_SORTING_ORDER
* | [--->] IV_FILTER_STRING               TYPE        STRING
* | [--->] IV_SEARCH_STRING               TYPE        STRING
* | [--->] IO_TECH_REQUEST_CONTEXT        TYPE REF TO /IWBEP/IF_MGW_REQ_ENTITYSET(optional)
* | [<---] ET_ENTITYSET                   TYPE        ZFRXX_CLA_DIO_OVT_MPC=>TT_OVERTIMEEVENT
* | [<---] ES_RESPONSE_CONTEXT            TYPE        /IWBEP/IF_MGW_APPL_SRV_RUNTIME=>TY_S_MGW_RESPONSE_CONTEXT
* | [!CX!] /IWBEP/CX_MGW_BUSI_EXCEPTION
* | [!CX!] /IWBEP/CX_MGW_TECH_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD overtimeeventset_get_entityset.

    DATA: source_entityset_name TYPE /iwbep/mgw_tech_name,
          ls_employee           TYPE zfrxx_cla_dio_ovt_mpc=>ts_employees.

    source_entityset_name = io_tech_request_context->get_source_entity_set_name( ).

    IF source_entityset_name EQ 'EmployeesSet'.
      io_tech_request_context->get_converted_source_keys( IMPORTING es_key_values = ls_employee ).

      SELECT a~pernr, a~subty, a~begda, a~endda, a~beguz, a~enduz, a~seqnr, a~stdaz, b~vorna, b~nachn
      FROM pa2002 AS a INNER JOIN
           pa0002 AS b ON a~pernr = b~pernr
      WHERE a~pernr EQ @ls_employee-id AND a~sprps EQ 'X' AND b~endda EQ '99991231'
      ORDER BY a~begda DESCENDING
      INTO TABLE @DATA(time_events).
    ELSE.
      DATA: employee_set       TYPE zfrxx_cla_dio_ovt_mpc=>tt_employees,
            responsive_context TYPE /iwbep/if_mgw_appl_srv_runtime=>ty_s_mgw_response_context,
            select_options     TYPE /iwbep/t_mgw_select_option,
            range_pernr        TYPE RANGE OF pernr_d.

      TRY.
          CALL METHOD me->employeesset_get_entityset
            EXPORTING
              iv_entity_name           = iv_entity_name
              iv_entity_set_name       = iv_entity_set_name
              iv_source_name           = iv_source_name
              it_filter_select_options = it_filter_select_options
              is_paging                = is_paging
              it_key_tab               = it_key_tab
              it_navigation_path       = it_navigation_path
              it_order                 = it_order
              iv_filter_string         = iv_filter_string
              iv_search_string         = iv_search_string
              io_tech_request_context  = io_tech_request_context
            IMPORTING
              et_entityset             = employee_set
              es_response_context      = responsive_context.
        CATCH /iwbep/cx_mgw_busi_exception /iwbep/cx_mgw_tech_exception.
          EXIT.
      ENDTRY.
      DATA(num_of_employee) = lines( employee_set ).

      range_pernr[] = VALUE #( BASE range_pernr[]
                               FOR indx = 1 THEN indx + 1 WHILE indx LE num_of_employee
                               ( sign = 'I' option = 'EQ' low = employee_set[ indx ]-id high = '' ) ).


      " Application of filter
      DATA(o_filter) = io_tech_request_context->get_filter( ).
      select_options = o_filter->get_filter_select_options( ).

      " SQL Condition
      DATA(condition) = |( a~SUBTY EQ '9011' OR a~SUBTY EQ '9013' )|.
      condition = |{ condition } AND a~SPRPS EQ 'X' AND b~ENDDA EQ '99991231' AND a~PERNR IN @range_pernr|.

      LOOP AT select_options ASSIGNING FIELD-SYMBOL(<select_options>).
        CASE <select_options>-property.
          WHEN 'EMPLOYEEID'.

            " clear previous calculated subordinates, now select only by those coming on the filter
            CLEAR range_pernr[].
            MOVE-CORRESPONDING <select_options>-select_options TO range_pernr.
            "condition = condition && | AND a~PERNR IN @range_pernr|.
        ENDCASE.

      ENDLOOP.

      SELECT a~pernr, a~subty, a~begda, a~endda, a~beguz, a~enduz, a~seqnr, a~stdaz, b~vorna, b~nachn
        FROM pa2002 AS a INNER JOIN
             pa0002 AS b ON a~pernr = b~pernr
        WHERE (condition)
        ORDER BY a~pernr, a~endda, a~beguz ASCENDING
        INTO TABLE @time_events.
    ENDIF.

    DATA(entrykey_counter) = 0.
    IF time_events IS NOT INITIAL.
      LOOP AT time_events ASSIGNING FIELD-SYMBOL(<events>).
        APPEND INITIAL LINE TO et_entityset ASSIGNING FIELD-SYMBOL(<output>).

        <output>-employeeid = <events>-pernr.
        <output>-startday = <events>-begda.
        <output>-endday = <events>-endda.
        <output>-seqnum = <events>-seqnr.
        <output>-fullname = |{ <events>-vorna }, { <events>-nachn }|.
        <output>-starttime = CONV string( <events>-beguz ).
        <output>-endtime = CONV string( <events>-enduz ).
        <output>-wagetype = <events>-subty.
        <output>-wagetypetext = COND #( WHEN <events>-subty CS '9011' THEN 'Paiement Heures'
                                        ELSE 'Récupération Heures' ).
        <output>-approval = 0. " 1 approved / 2 rejected.
        <output>-numberofhours = <events>-stdaz.
        <output>-entrykey = |{ <events>-pernr }_{ entrykey_counter }|.
        ADD 1 TO entrykey_counter.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method ZFRXX_CLA_DIO_OVT_DPC_EXT->OVERTIMEEVENTSET_UPDATE_ENTITY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ENTITY_NAME                 TYPE        STRING
* | [--->] IV_ENTITY_SET_NAME             TYPE        STRING
* | [--->] IV_SOURCE_NAME                 TYPE        STRING
* | [--->] IT_KEY_TAB                     TYPE        /IWBEP/T_MGW_NAME_VALUE_PAIR
* | [--->] IO_TECH_REQUEST_CONTEXT        TYPE REF TO /IWBEP/IF_MGW_REQ_ENTITY_U(optional)
* | [--->] IT_NAVIGATION_PATH             TYPE        /IWBEP/T_MGW_NAVIGATION_PATH
* | [--->] IO_DATA_PROVIDER               TYPE REF TO /IWBEP/IF_MGW_ENTRY_PROVIDER(optional)
* | [<---] ER_ENTITY                      TYPE        ZFRXX_CLA_DIO_OVT_MPC=>TS_OVERTIMEEVENT
* | [!CX!] /IWBEP/CX_MGW_BUSI_EXCEPTION
* | [!CX!] /IWBEP/CX_MGW_TECH_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD overtimeeventset_update_entity.
    DATA: ot_event    LIKE er_entity,
          it_2012     TYPE pa2012,
          state_abkrs TYPE t569v-state,
          lv_return   TYPE bapireturn1,
          entity_keys LIKE er_entity.

    io_data_provider->read_entry_data( IMPORTING es_data = ot_event ).
    io_tech_request_context->get_converted_keys( IMPORTING es_key_values = entity_keys ).
    DATA(lo_message_container) = me->mo_context->get_message_container( ).
    DATA ls_p2002 TYPE p2002.
    DATA(vpernr) = CONV pernr_d( ot_event-employeeid ).
    DATA(vbegda) = CONV begda( ot_event-startday ).
    DATA(vendda) = CONV endda( ot_event-endday ).
    DATA(vsubty) = CONV subty( ot_event-wagetype ).
    DATA(vseqnr) = CONV subty( ot_event-seqnum ).


    IF ot_event-approval EQ 1. " Approved - remove blockage
      SELECT SINGLE * FROM pa2002                           "#EC WARNOK
        WHERE pernr EQ @vpernr AND
              endda EQ @vendda AND
              begda EQ @vbegda AND
              subty EQ @vsubty AND
              seqnr EQ @vseqnr AND
              sprps EQ 'X'
        INTO @DATA(entry_2b_approved).

      IF sy-subrc IS INITIAL.

        DATA(personum) = CONV pernr_d( entry_2b_approved-pernr ).

        MOVE-CORRESPONDING entry_2b_approved TO ls_p2002.

        " Check EE for locks
        CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
          EXPORTING
            number = personum
          IMPORTING
            return = lv_return.

        IF lv_return-type EQ 'E'.
          MESSAGE e022(zfrpy_mes_dio_err) INTO DATA(err_mess) WITH personum.
          lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                   iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                   iv_msg_number = `022`
                                   iv_msg_text = CONV #( err_mess )
                                   iv_add_to_response_header = abap_true ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_message_container.

        ELSE.
          " check py area locked
          CALL FUNCTION 'PA03_PCR_READ'
            EXPORTING
              f_abkrs = 'F0'
            IMPORTING
              f_state = state_abkrs.
          IF state_abkrs EQ 1.
            MESSAGE e023(zfrpy_mes_dio_err) INTO err_mess.
            lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                       iv_msg_id = `ZFRPY_MES_DIO_ERR`
                       iv_msg_text = CONV #( err_mess )
                       iv_msg_number = `023`
                       iv_add_to_response_header = abap_true ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                message_container = lo_message_container.
          ENDIF.
        ENDIF.

        DELETE pa2002 FROM entry_2b_approved.

        entry_2b_approved-uname = sy-uname.
        entry_2b_approved-aedtm = sy-datum.
        entry_2b_approved-sprps = ''.

*        CALL FUNCTION 'HR_INFOTYPE_OPERATION'
*          EXPORTING
*            infty         = '2002'
*            number        = personum
*            subtype       = entry_2b_approved-subty
*            objectid      = entry_2b_approved-objps
*            lockindicator = entry_2b_approved-sprps
*            validityend   = entry_2b_approved-endda
*            validitybegin = entry_2b_approved-begda
*            recordnumber  = entry_2b_approved-seqnr
*            record        = ls_p2002
*            operation     = 'DEL'
*            tclas         = 'A'
*            dialog_mode   = '0'
*          IMPORTING
*            return        = lv_return.



        "DELETE pa2002 FROM entry_2b_approved.


        IF sy-subrc IS INITIAL.
          INSERT pa2002 FROM entry_2b_approved.
          COMMIT WORK.

          MOVE-CORRESPONDING ot_event TO er_entity.
        ELSE.
          lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                             iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                             iv_msg_number = `010`
                                             iv_add_to_response_header = abap_true
                                             iv_msg_v1 = CONV symsgv( entry_2b_approved-subty ) ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_message_container.
        ENDIF.

        CALL FUNCTION 'BAPI_EMPLOYEE_DEQUEUE'
          EXPORTING
            number = personum.
      ELSE.
        lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                           iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                           iv_msg_number = `011`
                                           iv_add_to_response_header = abap_true
                                           iv_msg_v1 = CONV symsgv( entry_2b_approved-subty )
                                           iv_msg_v2 = CONV symsgv( entry_2b_approved-begda )
                                           iv_msg_v3 = CONV symsgv( entry_2b_approved-endda ) ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_message_container.


      ENDIF.

    ELSEIF ot_event-approval EQ 2. " Rejected
      SELECT SINGLE * FROM pa2002                           "#EC WARNOK
      WHERE pernr EQ @vpernr AND
            endda EQ @vendda AND
            begda EQ @vbegda AND
            subty EQ @vsubty AND
            seqnr EQ @vseqnr AND
            sprps EQ 'X'
      INTO @DATA(entry_2b_rejected).

      IF sy-subrc IS INITIAL.

        personum = CONV pernr_d( entry_2b_rejected-pernr ).

        MOVE-CORRESPONDING entry_2b_rejected TO ls_p2002.


        CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
          EXPORTING
            number = personum
          IMPORTING
            return = lv_return.

        IF lv_return-type EQ 'E'.
          MESSAGE e022(zfrpy_mes_dio_err) INTO err_mess WITH personum.
          lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                   iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                   iv_msg_number = `022`
                                   iv_msg_text = CONV #( err_mess )
                                   iv_add_to_response_header = abap_true ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_message_container.

        ELSE.
          " check py area locked
          CALL FUNCTION 'PA03_PCR_READ'
            EXPORTING
              f_abkrs = 'F0'
            IMPORTING
              f_state = state_abkrs.
          IF state_abkrs EQ 1.
            MESSAGE e023(zfrpy_mes_dio_err) INTO err_mess.
            lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                       iv_msg_id = `ZFRPY_MES_DIO_ERR`
                       iv_msg_number = `023`
                       iv_msg_text = CONV #( err_mess )
                       iv_add_to_response_header = abap_true ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                message_container = lo_message_container.
          ENDIF.
        ENDIF.
        CALL FUNCTION 'HR_INFOTYPE_OPERATION'
          EXPORTING
            infty         = '2002'
            number        = personum
            subtype       = entry_2b_rejected-subty
            objectid      = entry_2b_rejected-objps
            lockindicator = entry_2b_rejected-sprps
            validityend   = entry_2b_rejected-endda
            validitybegin = entry_2b_rejected-begda
            recordnumber  = entry_2b_rejected-seqnr
            record        = ls_p2002
            operation     = 'DEL'
            tclas         = 'A'
            dialog_mode   = '0'
          IMPORTING
            return        = lv_return.

        CALL FUNCTION 'BAPI_EMPLOYEE_DEQUEUE'
          EXPORTING
            number = personum.

        "DELETE pa2002 FROM entry_2b_rejected.
        IF lv_return-type NE 'E'.

          " Set up the 2012 to be inserted
          it_2012-pernr = entry_2b_rejected-pernr.
          it_2012-subty = COND #( WHEN entry_2b_rejected-subty EQ '9011' THEN '$911'
                                 WHEN entry_2b_rejected-subty EQ '9013' THEN '$913' ).
          it_2012-endda = entry_2b_rejected-endda.
          it_2012-begda = entry_2b_rejected-begda.
          it_2012-seqnr = entry_2b_rejected-seqnr.
          it_2012-aedtm = CONV #( sy-datum ).
          it_2012-uname = sy-uname.
          it_2012-beguz = entry_2b_rejected-beguz.
          it_2012-enduz = entry_2b_rejected-enduz.
          it_2012-ztart = it_2012-subty.
          it_2012-anzhl = CONV #( entry_2b_rejected-stdaz ).

          " Check SEQNR is unique
*          SELECT * FROM pa2012                              "#EC WARNOK
*            WHERE pernr EQ @it_2012-pernr AND
*                  begda EQ @it_2012-begda AND
*                  endda EQ @it_2012-endda
*            ORDER BY seqnr DESCENDING
*            INTO TABLE @DATA(dummy_selection).
*
*          IF sy-subrc IS NOT INITIAL.
*            TRY.
*                it_2012-seqnr = CONV #( dummy_selection[ 1 ]-seqnr + 1 ).
*              CATCH cx_sy_itab_line_not_found.
*            ENDTRY.
*          ENDIF.

          INSERT pa2012 FROM it_2012.

          IF sy-subrc IS INITIAL.
            COMMIT WORK.
            MOVE-CORRESPONDING ot_event TO er_entity.
          ELSE.
            ROLLBACK WORK.
            lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                               iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                               iv_msg_number = `012`
                                               iv_add_to_response_header = abap_true
                                               iv_msg_v1 = CONV symsgv( entry_2b_approved-subty ) ).

            RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
              EXPORTING
                message_container = lo_message_container.

          ENDIF.
        ELSE. " Deletion failed
          ROLLBACK WORK.
          lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                             iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                             iv_msg_number = `012`
                                             iv_add_to_response_header = abap_true
                                             iv_msg_v1 = CONV symsgv( entry_2b_approved-subty ) ).

          RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
            EXPORTING
              message_container = lo_message_container.
        ENDIF. " Delete 2002
      ELSE. " Cannot find an entry to delete on 2002
        lo_message_container->add_message( iv_msg_type = /iwbep/cl_cos_logger=>error
                                           iv_msg_id = `ZFRPY_MES_DIO_ERR`
                                           iv_msg_number = `011`
                                           iv_add_to_response_header = abap_true
                                           iv_msg_v1 = CONV symsgv( entry_2b_approved-subty )
                                           iv_msg_v2 = CONV symsgv( entry_2b_approved-begda )
                                           iv_msg_v3 = CONV symsgv( entry_2b_approved-endda ) ).

        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            message_container = lo_message_container.
      ENDIF. " Select 2002
    ENDIF.
  ENDMETHOD.
ENDCLASS.
