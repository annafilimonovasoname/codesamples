/**
 * @author      Anna Filimonova
 * @date        24/03/2020
 * @group       DFS-SFDC
 * @description Contact records validation
 */
public with sharing class TIP_RestContactValidator {

    /** Static map that collects all valid CMS codes and checks new records against all validated set */
    public static Map<String, String> validExtIdToAccId = new Map<String, String>();

    /** Partner record external id */
    private String partnerExtId;

    /** Record to validate */
    private TIP_Wrappers.ContactData contactRecord;

    /** Validator operator instance that implements different validations based on operation. */
    private TIP_ValidatorUtil validator;

    /** List of error messages for the record */
    private List<String> errorMsgs;

    /** Flag to show if partner is corporate or invidual */
    private Boolean isIndividual;

    /**
     * @description Creates instance of contact validator that validates 
     * a set of Contacts that belong to a single partner.
     * @param partnerExternalId partner external id
     * @param aRecord contact wrapper record to validate
     * @param operation CREATE or UPDATE
     * @param partnerType Corporate or Individual
     * @return Instance of TIP_RestContactValidator.
     */
    public TIP_RestContactValidator(String partnerExternalId, TIP_Wrappers.ContactData aRecord, String operation, String partnerType) {
        this.partnerExtId = partnerExternalId;
        this.contactRecord = aRecord;
        
        validator = TIP_ValidatorUtil.getInstance(operation);
        errorMsgs = new List<String>();
        isIndividual = CRM_Constants.INDIVIDUAL_PARTNER.equals(partnerType);
    }

    /**
     * @description Get all error messages.
     * @param -
     * @return List of logged error messages.
     */
    public List<String> getErrors() {
        return errorMsgs != null ? errorMsgs : new List<String>();
    }

    /**
     * @description Validates fields in destination records against a list of records.
     * @param -
     * @return TRUE if record is valid, FALSE if record is invalid.
     */
    public Boolean isValid() {
        return 
            checkRequiredFields() && checkFieldsFormat() && checkDuplicateExternalIdsInRequest();
    }

    /**
     * @description Checks fields format on partner contact level.
     * @param -
     * @return TRUE if record is valid (all required fields are populated), 
     *         FALSE if record is invalid (required fields are missing). 
     */
    private Boolean checkRequiredFields() {
        Map<String, Object> contactTransformed = TIP_RestHelperUtil.transformJsonToMap(JSON.serialize(contactRecord));
        TIP_RestValidationProcessor processor = new TIP_RestValidationProcessor(partnerExtId);
        List<String> missingRequiredFields = processor.getMissingRequiredFields(
            validator, contactTransformed, 
            TIP_ValidatorUtil.requiredFields_Contact, 
            TIP_ValidatorUtil.fieldsToCollect_Contact
        );
        if (!missingRequiredFields.isEmpty()) {
            errorMsgs.add(String.format(TIP_ValidatorUtil.REQ_FIELDS_MISSING_CONTACT_ERROR, 
                new List<String>{String.join(missingRequiredFields, ', ')}));
        }
        return missingRequiredFields.isEmpty();
    }

    /**
     * @description Checks required fields on working contact level.
     * @param -
     * @return TRUE if record is valid (field format valid), 
     *         FALSE if record is invalid (some fields have invalid format). 
     */
    private Boolean checkFieldsFormat() {
        List<String> invalidFields = new List<String>();
        //========DATE FIELDS===========
        if (!String.isBlank(contactRecord.validityDate) && !isDateValue(contactRecord.validityDate)) {
            invalidFields.add(TIP_Wrappers.Fields_Contact.VALIDITYDATE.name());
            errorMsgs.add(
                String.format(
                    TIP_ValidatorUtil.INVALID_DATE_FIELD_VAL, 
                    new List<String>{
                        TIP_Wrappers.Fields_Contact.VALIDITYDATE.name(), 
                        contactRecord.validityDate
                    }
                )
            );
        }

        if (!String.isBlank(contactRecord.visaValidityDate) && !isDateValue(contactRecord.visaValidityDate)) {
            invalidFields.add(TIP_Wrappers.Fields_Contact.VISAVALIDITYDATE.name());
            errorMsgs.add(
                String.format(
                    TIP_ValidatorUtil.INVALID_DATE_FIELD_VAL, 
                    new List<String>{
                        TIP_Wrappers.Fields_Contact.VISAVALIDITYDATE.name(), 
                        contactRecord.visaValidityDate
                    }
                )
            );
        }

        //========PICKLISTS===========
        List<String> salutOptions = getSalutOptions();
        List<String> countryCodeOptions = getDiallingCodeOptions();
        Map<String, List<String>> countryStateDependentOptions = getCountryStateDependentOptions();
        Map<String, String> countryNamesByISOCode = TIP_RestHelperUtil.retrieveIsoCodesMapping();

        if (!String.isBlank(contactRecord.salutation) 
            && !salutOptions.contains(contactRecord.salutation)) {
                invalidFields.add(invalidFieldPicklist(
                    TIP_Wrappers.Fields_Contact.SALUTATION, 
                    contactRecord.salutation)
                );
        }

        if (!String.isBlank(contactRecord.countryCodeMobilePhone) 
            && !countryCodeOptions.contains(contactRecord.countryCodeMobilePhone)) {
                invalidFields.add(invalidFieldPicklist(
                    TIP_Wrappers.Fields_Contact.COUNTRYCODEMOBILEPHONE, 
                    contactRecord.countryCodeMobilePhone)
                );
        }

        if (!String.isBlank(contactRecord.countryCodeOtherPhone1) 
            && !countryCodeOptions.contains(contactRecord.countryCodeOtherPhone1)) {
                invalidFields.add(invalidFieldPicklist(
                    TIP_Wrappers.Fields_Contact.COUNTRYCODEOTHERPHONE1, 
                    contactRecord.countryCodeOtherPhone1)
                );
        }

        if (!String.isBlank(contactRecord.countryCodeOtherPhone2) 
            && !countryCodeOptions.contains(contactRecord.countryCodeOtherPhone2)) {
                invalidFields.add(invalidFieldPicklist(
                    TIP_Wrappers.Fields_Contact.COUNTRYCODEOTHERPHONE2, 
                    contactRecord.countryCodeOtherPhone2)
                );
        }

        if (!String.isBlank(contactRecord.countryCodeWeChat) 
            && !countryCodeOptions.contains(contactRecord.countryCodeWeChat)) {
                invalidFields.add(invalidFieldPicklist(
                    TIP_Wrappers.Fields_Contact.COUNTRYCODEWECHAT, 
                    contactRecord.countryCodeWeChat)
                );
        }

        if (!String.isBlank(contactRecord.nationality)) {
            if (!countryNamesByISOCode.keySet().contains(contactRecord.nationality)) {
                invalidFields.add(invalidFieldPicklist(
                    TIP_Wrappers.Fields_Contact.NATIONALITY, 
                    contactRecord.nationality)
                );
            } else {
                contactRecord.nationality = countryNamesByISOCode.get(contactRecord.nationality);
                //check dependent state only for valid nationality
                if (!String.isBlank(contactRecord.state)) {
                    List<String> allowedStates = countryStateDependentOptions.get(contactRecord.nationality);
                    if (allowedStates == null && !allowedStates.contains(contactRecord.state)) {
                        invalidFields.add(invalidFieldPicklist(
                            TIP_Wrappers.Fields_Contact.STATE, 
                            contactRecord.state)
                        );
                    }
                }
            }
        }

        if (!String.isBlank(contactRecord.countryOfTaxResidence)) {
            if (!countryNamesByISOCode.keySet().contains(contactRecord.countryOfTaxResidence)) {
                invalidFields.add(invalidFieldPicklist(
                    TIP_Wrappers.Fields_Contact.COUNTRYOFTAXRESIDENCE, 
                    contactRecord.countryOfTaxResidence)
                );
            } else {
                contactRecord.countryOfTaxResidence = countryNamesByISOCode.get(contactRecord.countryOfTaxResidence);
            }
        }

        if (!isIndividual && !String.isBlank(contactRecord.role)) {
            List<String> roleOptions = getRoleOptions();
            if (!roleOptions.contains(contactRecord.role)) {
                invalidFields.add(invalidFieldPicklist(
                    TIP_Wrappers.Fields_Contact.ROLE, 
                    contactRecord.role)
                );
            }
        }

        return invalidFields.isEmpty();
    }

    /**
     * @description Checks for duplicates in working destinations from other records.
     * @param -
     * @return TRUE if record is valid (CMS codes are unique or empty), 
     *         FALSE if record is invalid (CMS codes duplicated in request).
     */
    private Boolean checkDuplicateExternalIdsInRequest() {
        String validContactExternalId = contactRecord.externalId;

        if (validExtIdToAccId.containsKey(validContactExternalId)) {
            errorMsgs.add(
                String.format(
                    TIP_ValidatorUtil.DUPLICATE_CONTACT_EXT_ID_IN_REQUEST, 
                    new List<String>{ validContactExternalId }
                )
            );
            return false;
        } else {
            validExtIdToAccId.put(validContactExternalId, partnerExtId);
        }

        return true;
    }

    /**
     * @description Sets error for specified field.
     * @param aField field label
     * @param fieldValue field value
     * @return field labelt.
     */
    private String invalidFieldPicklist(TIP_Wrappers.Fields_Contact aField, String fieldValue) {
        errorMsgs.add(
            String.format(
                TIP_ValidatorUtil.INVALID_PICKLIST_VALUE, 
                new List<String>{
                    aField.name(), 
                    fieldValue
                }
            )
        );
        return aField.name();
    }

    /**
     * @description Checks if given String is a date field.
     * @param strDate string to check
     * @return TRUE if strDate is a date value, FALSE is it is not.
     */
    private Boolean isDateValue(String strDate) {
        try {
            Date d = Date.valueOf(strDate);
            return true;
        } catch (TypeException ex) {
            return false;
        }
    } 

    /** Static picklist options to avoid SOQL in loop */

    /** Contact.Dialling_Code_Mobile_Phone__c picklist options */    
    private static  List<String> countryCodeOptions;

    /**
     * @description Get method for countryCodeOptions.
     * @param -
     * @return Contact.Dialling_Code_Mobile_Phone__c picklist options.
     */
    private static List<String> getDiallingCodeOptions() {
        if (countryCodeOptions == null) {
            countryCodeOptions = TIP_RestHelperUtil.getPicklistValues(Contact.Dialling_Code_Mobile_Phone__c);
        }
        return countryCodeOptions;
    }

    /** Contact.Role__c picklist options */    
    private static  List<String> roleOptions;

    /**
     * @description Get method for roleOptions.
     * @param -
     * @return Contact.Role__c picklist options.
     */
    private static List<String> getRoleOptions() {
        if (roleOptions == null) {
            roleOptions = TIP_RestHelperUtil.getPicklistValues(Contact.Role__c);
        }
        return roleOptions;
    }

    /** Contact.Salutation picklist options */    
    private static  List<String> salutOptions;

    /**
     * @description Get method for roleOptions.
     * @param -
     * @return Contact.Salutation picklist options.
     */
    private static List<String> getSalutOptions() {
        if (salutOptions == null) {
            salutOptions = TIP_RestHelperUtil.getPicklistValues(Contact.Salutation);
        }
        return salutOptions;
    }

    /** TIP_Working_Destination__c.Code__c picklist dependency from TIP_Working_Destination__c.Working_Destination__c */ 
    private static Map<String, List<String>> countryStateDependentOptions;

    /**
     * @description Get method for codeDependentOptions.
     * @param -
     * @return TIP_Working_Destination__c.Code__c picklist dependency from TIP_Working_Destination__c.Working_Destination__c.
     */
    private static Map<String, List<String>> getCountryStateDependentOptions() {
        if (countryStateDependentOptions == null) {
            countryStateDependentOptions = TIP_RestHelperUtil.getDependentPicklistOptions(
                'Contact', 
                'TIP_Country__c', 
                'TIP_State__c'
            );
        }
        return countryStateDependentOptions;
    }

}
